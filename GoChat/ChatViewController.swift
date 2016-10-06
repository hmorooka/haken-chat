//
//  ChatViewController.swift
//  GoChat
//
//  Created by 諸岡裕人 on 2016/10/04.
//  Copyright © 2016年 hiroto.morooka. All rights reserved.
//

import JSQMessagesViewController
import UIKit
import MobileCoreServices
import AVKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage


//JSQMessagesViewControllerを設定している:~の意味は？
class ChatViewController: JSQMessagesViewController {
    
    var messages = [JSQMessage]()
    var messageRef = FIRDatabase.database().reference().child("messages")

    override func viewDidLoad() {
        super.viewDidLoad()
        //この部分の設定が？。ゆくゆくはログイン情報と紐付けて表示すると思われる。
        self.senderId = "1"
        self.senderDisplayName = "h.morooka"

        // Do any additional setup after loading the view.
        
        //この下の２つのメッセージが保存される→消す→snapshotに過去のデータが保存？→dictionary型で表示
        //messageRef.childByAutoId().setValue("first message")
        //messageRef.childByAutoId().setValue("second message")
//        messageRef.observeEventType(FIRDataEventType.Value) { (snapshot: FIRDataSnapshot) in
//            print("test")
//            if let dict = snapshot.value as? NSDictionary {
//                print(dict)
//            }
//        }
        observeMessages()
    }
    
    //以前に入力されていたデータ（snapshot?）の値をdictに代入する→dictに入っている配列の中のキーから中身をそれぞれの定数に代入→それをメッセージ表示の時にappendで表示させる
    func observeMessages() {
        messageRef.observeEventType(.ChildAdded, withBlock:  { snapshot in
//            print(snapshot.value)
            if let dict = snapshot.value as? [String: AnyObject] {
                let MediaType = dict["MediaType"] as! String
                let senderId = dict["senderId"] as! String
                let senderName = dict["senderName"] as! String
                let text = dict["text"] as! String
                self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, text: text))
                self.collectionView.reloadData()
            }
        })
    }

    
    
    
    //入力部分。入力してsendボタンを押す、テキスト内容が出ることがコンソールで確認出来る

    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        //新しいメッセージを追加する
//        messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text))
//        collectionView.reloadData()
//        print(messages)
        
        let newMessage = messageRef.childByAutoId()
        let messageData = ["text": text, "senderId": senderId, "senderName": senderDisplayName, "MediaType": "TEXT"]
        newMessage.setValue(messageData)
    }
    
    //添付ボタンを押したことが確認できる。添付ボタンを押したときのアラート表示。
    override func didPressAccessoryButton(sender: UIButton!) {
        print("didPressAccessoryButton")
        
        //添付ボタンを押したときの大元のシートを作成。最初はここのメッセージが出てくる。
        let sheet = UIAlertController(title: "Media Messages", message: "Please select a media", preferredStyle: UIAlertControllerStyle.ActionSheet)
        //Cancelボタンが出てくる。押すと戻る。
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (alert: UIAlertAction) in
        }
        //Photo Libraryの選択肢が追加。Cancelと同じ表示。
        let photoLibrary = UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.Default) { ( alert: UIAlertAction) in
            self.getMediaForm(kUTTypeImage)
        }
        //同上
        let videoLibrary = UIAlertAction(title: "Video Library", style: UIAlertActionStyle.Default) { ( alert: UIAlertAction) in
            self.getMediaForm(kUTTypeMovie)
        }
        
        sheet.addAction(photoLibrary)
        sheet.addAction(videoLibrary)
        sheet.addAction(cancel)
        self.presentViewController(sheet, animated: true, completion: nil)
        
        //let imagePicker = UIImagePickerController()
        //imagePicker.delegate = self
        //self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    //CFStirngを使うのもポイント
    func getMediaForm(type: CFString) {
        let mediaPicker = UIImagePickerController()
        mediaPicker.delegate = self
        mediaPicker.mediaTypes = [type as String]
        self.presentViewController(mediaPicker, animated: true, completion: nil)
    }
    
    
    //アイテムごとに参照するメッセージを返す
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData!
    { return messages[indexPath.item]
    }
    
    //吹き出しの設定
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        return bubbleFactory.outgoingMessagesBubbleImageWithColor(.blackColor())
    }
    
    //アバターの設定
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    //アイテムの総数を返す
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("number of item:\(messages.count)")
        return messages.count
    }

    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) ->
     UICollectionViewCell{
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        return cell
    }
    
    //ビデオをチャット上で再生するための処理。カオスなので要復習！
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
        print("didTapMessageBubbleAtIndexPath: \(indexPath.item)")
        let message = messages[indexPath.item]
        if message.isMediaMessage {
            if let mediaItem = message.media as? JSQVideoMediaItem {
            let player = AVPlayer(URL: mediaItem.fileURL)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self.presentViewController(playerViewController, animated: true, completion: nil)
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
   
    @IBAction func logoutDidTapped(sender: AnyObject) {
        
        //Create a main storybord instance
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        //From mainstorybord instatiate a view controller
        let LogInVC = storyboard.instantiateViewControllerWithIdentifier("LogInVC") as! LogInViewController
        
        //Get the app delegate
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        //Set Navigation Contoroller as root view controller
        appDelegate.window?.rootViewController = LogInVC

    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    //写真をストレージに保存する処理
    func sendMedia(picture: UIImage?, video: NSURL?) {
        print(picture)
        print(FIRStorage.storage().reference())
        let filePath = "\(FIRAuth.auth()!.currentUser!.uid)/\(NSDate.timeIntervalSinceReferenceDate())"
        print(filePath)
        let data = UIImageJPEGRepresentation(picture!, 0.1)
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpg"
        FIRStorage.storage().reference().child(filePath).putData(data!, metadata: metadata) { (metadata,error) in
            if error != nil {
                print(error?.localizedDescription)
                return
            }
            //metadataの中身はnameにuidが入ってたりする。
            print(metadata)
            
            let fileUrl = metadata!.downloadURLs![0].absoluteString
            
            let newMessage = self.messageRef.childByAutoId()
            let messageData = ["fileUrl": fileUrl, "senderId": self.senderId, "senderName": self.senderDisplayName, "MediaType": "PHOTO"]
            newMessage.setValue(messageData)
            }
    }

}

//写真を追加、チャット上に表示する処理（inofの中にデータが入る「〜〜〜.jpg」とか）同様にビデオも。
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: AnyObject]) {
        print("did finish picking")
        //Get the image
        print(info)
        if let picture = info[UIImagePickerControllerOriginalImage] as? UIImage{
        let photo = JSQPhotoMediaItem(image: picture)
        messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, media: photo))
            
            //写真をストレージに送ってる
            sendMedia(picture, video: nil)
        }
        else if let video = info[UIImagePickerControllerMediaURL] as? NSURL {
            let videoItem = JSQVideoMediaItem(fileURL: video, isReadyToPlay: true)
            messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, media: videoItem))
        }
        //写真を選択するとチャット画面に行く
        self.dismissViewControllerAnimated(true, completion: nil)
        //チャット上に画像が表示される
        collectionView.reloadData()
    }
}
