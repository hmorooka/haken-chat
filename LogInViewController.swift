//
//  LogInViewController.swift
//  GoChat
//
//  Created by 諸岡裕人 on 2016/10/04.
//  Copyright © 2016年 hiroto.morooka. All rights reserved.
//

import UIKit
import FirebaseAuth
import GoogleSignIn

//GIDSもDelegate
class LogInViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate {
    
    
    @IBOutlet weak var anonymousButton: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        anonymousButton.layer.borderWidth = 2.0
        anonymousButton.layer.borderColor = UIColor.whiteColor().CGColor
        
        //clientIDはplistから持ってくる。infoのurlの部分も２箇所記述必要
        GIDSignIn.sharedInstance().clientID = "150022186048-94ch40kuokah9j511hh9lch16ushrmgg.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
    }
    
    //viewdidappearはこの画面になるたび呼び出される
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        print(FIRAuth.auth()?.currentUser)
        
        //認証されているかどうかを確認して遷移先を選んでいる。ログイン認証されたままなら直接チャット画面に行く。
        FIRAuth.auth()?.addAuthStateDidChangeListener({ (auth: FIRAuth, user: FIRUser?) in
            if user != nil {
                print(user)
                Helper.helper.switchToNavigationViewController()
            }else{
                print("Unauthorized")
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func LoginAnonymouslyDidTapped(sender: AnyObject) {
        
        //Anonymously login
        //root viewcontrollerとしてnavigation controllerをセッティングする
        Helper.helper.LoginAnonymously()
        
    }
    
    @IBAction func googleLoginDidTapped(sender: AnyObject) {
        print("google login did tapped")
        GIDSignIn.sharedInstance().signIn()
        

    }
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!){
        if error != nil{
            print(error!.localizedDescription)
            return
        }
        print(user.authentication)
        Helper.helper.logInWithGoogle(user.authentication)

    }
    
    
}
