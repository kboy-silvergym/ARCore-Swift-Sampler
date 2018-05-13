//
//  AppDelegate.swift
//  CloudAnchorSwift
//
//  Created by Kei Fujikawa on 2018/05/12.
//  Copyright © 2018年 Kboy. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        return true
    }

}

