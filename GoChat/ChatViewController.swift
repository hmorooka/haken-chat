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
    
    //配列の初期化する
    var messages = [JSQMessage]()
    var avatarDict = [String: JSQMessagesAvatarImage]()
    
    //databaseのreferenceの設定？
    var messageRef = FIRDatabase.database().reference().child("messages")

    override func viewDidLoad() {
        super.viewDidLoad()
        //この部分の設定が？。ゆくゆくはログイン情報と紐付けて表示すると思われる。
        
        if let currentUser = FIRAuth.auth()?.currentUser{
            self.senderId = currentUser.uid
            
        if currentUser.anonymous == true{
            
            self.senderDisplayName = "anonymous"
        } else {
            self.senderDisplayName = "\(currentUser.displayName!)"
        }
        }
        //observeUsersはobserveMessagesの中で使われている
        observeMessages()
    }
    
    //以前の投稿データのユーザーを表示するメソッド
    func observeUsers(id: String){
        
        FIRDatabase.database().reference().child("users").child(id).observeEventType(.Value, withBlock: {
            snapshot in
            if let dict = snapshot.value as? [String: AnyObject]{
                
                //dictの中にあるavatarを下で定義したsetupAvatarで実行する
                let avatarUrl = dict["profileUrl"] as! String
                self.setupAvatar(avatarUrl, messageId: id)
            }
        })
    }
    
    //下で設定したavatarを使っている→？？？
    func setupAvatar(url: String, messageId: String){
        
        if url != ""{
            let fileUrl = NSURL(string: url)
            let data = NSData(contentsOfURL: fileUrl!)
            let image = UIImage(data: data!)
            let userImg = JSQMessagesAvatarImageFactory.avatarImageWithImage(image, diameter: 30)
            avatarDict[messageId] = userImg
        } else {
            avatarDict[messageId] = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "profileImage"), diameter: 30)
        }
        collectionView.reloadData()
    }
    
    //以前に入力されていたデータ（snapshot?）の値をdictに代入する→dictに入っている配列の中のキーから中身をそれぞれの定数に代入→それをメッセージ表示の時にappendで表示させる
    func observeMessages() {
        messageRef.observeEventType(.ChildAdded, withBlock:  { snapshot in
//            print(snapshot.value)
            if let dict = snapshot.value as? [String: AnyObject] {
                let mediaType = dict["MediaType"] as! String
                let senderId = dict["senderId"] as! String
                let senderName = dict["senderName"] as! String
                
                //senderIdを引数にしてユーザーを特定している
                self.observeUsers(senderId)
                
                //switch文で条件分岐。mediaTypeで判別して処理を分ける。ここで分けておかないとエラー。
                switch mediaType {
                    
                    case "TEXT":
                        let text = dict["text"] as! String
                        self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, text: text))
                    
                    case "PHOTO":
                        let fileUrl = dict["fileUrl"] as! String
                        let url = NSURL(string: fileUrl)
                        let data = NSData(contentsOfURL: url!)
                        let picture = UIImage(data: data!)
                        let photo = JSQPhotoMediaItem(image: picture)
                        self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, media: photo))
                    
                        if self.senderId == senderId {
                            photo.appliesMediaViewMaskAsOutgoing = true
                        } else {
                            photo.appliesMediaViewMaskAsOutgoing = false
                        }
                    
                    case "VIDEO":
                        let fileUrl = dict["fileUrl"] as! String
                        let video = NSURL(string: fileUrl)
                        let videoItem = JSQVideoMediaItem(fileURL: video, isReadyToPlay: true)
                        self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, media: videoItem))
                    
                        if self.senderId == senderId {
                            videoItem.appliesMediaViewMaskAsOutgoing = true
                        } else {
                            videoItem.appliesMediaViewMaskAsOutgoing = false
                        }
                    
                default:
                    print("unkwon data type")
                }
                
                //firebaseのデータベースに入れるmediaTypeの区分けで処理を変えている。これで以前までの内容に触れる事ができる。これはif文で書いた場合
//                if mediaType == "TEXT" {
//                    let text = dict["text"] as! String
//                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, text: text))
//                    
//                }else if mediaType == "PHOTO"{
//                    let fileUrl = dict["fileUrl"] as! String
//                    let url = NSURL(string: fileUrl)
//                    let data = NSData(contentsOfURL: url!)
//                    let picture = UIImage(data: data!)
//                    let photo = JSQPhotoMediaItem(image: picture)
//                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, media: photo))
//                
//                }else if mediaType == "VIDEO"{
//                    let fileUrl = dict["fileUrl"] as! String
//                    let video = NSURL(string: fileUrl)
//                    let videoItem = JSQVideoMediaItem(fileURL: video, isReadyToPlay: true)
//                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, media: videoItem))
//                }
                
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
        
        //メッセージを送り終わったらキーボードを畳む
        self.finishSendingMessage()
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
        let message = messages[indexPath.item]
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        
        if message.senderId == self.senderId {
            return bubbleFactory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
        } else {
            return bubbleFactory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
        }

    }
    
    //アバターの設定 アバターを取って来る部分
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        let message = messages[indexPath.item]
        
        return avatarDict[message.senderId]
//        return JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "profileImage"), diameter: 30)
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
        
        do {
            try FIRAuth.auth()?.signOut()
        } catch let error{
            print(error)
        }
        
        //上のsignOut()がうまく行けば nilが表示される
        print(FIRAuth.auth()?.currentUser)
        
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
    
    //写真をストレージに保存する処理,ビデオをストレージに入れる処理
    func sendMedia(picture: UIImage?, video: NSURL?) {
        print(picture)
        print(FIRStorage.storage().reference())
        
        if let picture = picture {
            let filePath = "\(FIRAuth.auth()!.currentUser!.uid)/\(NSDate.timeIntervalSinceReferenceDate())"
            print(filePath)
            let data = UIImageJPEGRepresentation(picture, 0.1)
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
            
    }else if let video = video {
        let filePath = "\(FIRAuth.auth()!.currentUser!.uid)/\(NSDate.timeIntervalSinceReferenceDate())"
        print(filePath)
        let data = NSData(contentsOfURL: video)
        let metadata = FIRStorageMetadata()
        metadata.contentType = "video/mp4"
        FIRStorage.storage().reference().child(filePath).putData(data!, metadata: metadata) { (metadata,error) in
            if error != nil {
                print(error?.localizedDescription)
                return
            }
            //metadataの中身はnameにuidが入ってたりする。
            print(metadata)
            
            let fileUrl = metadata!.downloadURLs![0].absoluteString
            
            let newMessage = self.messageRef.childByAutoId()
            let messageData = ["fileUrl": fileUrl, "senderId": self.senderId, "senderName": self.senderDisplayName, "MediaType": "VIDEO"]
            newMessage.setValue(messageData)
            }
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
            //写真をdatabaseに送ってる
            sendMedia(picture, video: nil)
        }
        else if let video = info[UIImagePickerControllerMediaURL] as? NSURL {
            //ビデオをdatabaseに送っている
            sendMedia(nil, video: video)
        }
        //写真を選択するとチャット画面に行く
        self.dismissViewControllerAnimated(true, completion: nil)
        //チャット上に画像が表示される
        collectionView.reloadData()
    }
}
