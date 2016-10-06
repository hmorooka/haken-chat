//
//  Helper.swift
//  GoChat
//
//  Created by 諸岡裕人 on 2016/10/04.
//  Copyright © 2016年 hiroto.morooka. All rights reserved.
//

import Foundation
import FirebaseAuth
import UIKit
import GoogleSignIn

class Helper {
    static let helper = Helper()
    
    func LoginAnonymously() {
        print("login anonymously did tapped")
        
        //Anonymously login
        //root viewcontrollerとしてnavigation controllerをセッティングする
        FIRAuth.auth()?.signInAnonymouslyWithCompletion({ (anonymousUser: FIRUser?, error: NSError?) in
            if error == nil{
                print("UserId: \(anonymousUser!.uid)")
                
                self.switchToNavigationViewController()
                
            }else{
                print(error!.localizedDescription)
                return
            }
        })
        
        
    }
    
    //googleログイン、アカウント情報を取る
    func logInWithGoogle(authentication: GIDAuthentication){
        
        let credential = FIRGoogleAuthProvider.credentialWithIDToken(authentication.idToken, accessToken: authentication.accessToken)
        
        FIRAuth.auth()?.signInWithCredential(credential, completion: {( user: FIRUser?, error: NSError?) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }else {
                print(user?.email)
                print(user?.displayName)
                
                self.switchToNavigationViewController()
                
            }
        })
        
    }
    //画面遷移のためのメソッド
    private func switchToNavigationViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let naviVC = storyboard.instantiateViewControllerWithIdentifier("NavigationVC") as! UINavigationController
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController = naviVC
        
    }
    
    
    
    
    
    
    
    
}
