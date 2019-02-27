//
//  AppDelegate.swift
//  formants_iOS
//
//  Created by asd on 13/01/2019.
//  Copyright © 2019 voicesync. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {        global.audioIn.stopRecording()    }
    func applicationDidEnterBackground(_ application: UIApplication) {        global.audioIn.stopRecording()    }
    func applicationWillEnterForeground(_ application: UIApplication) {    }
    func applicationDidBecomeActive(_ application: UIApplication) {       global.audioIn.startRecording()    }

    func applicationWillTerminate(_ application: UIApplication) {
        global.audioIn.stopRecording()
        global.audioIn.end()
    }
}

