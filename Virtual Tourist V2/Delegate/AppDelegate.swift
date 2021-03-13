//
//  AppDelegate.swift
//  Virtual Tourist V2
//
//  Created by Norah Almaneea on 13/03/2021.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        DataController.shared.load()
        return true
    }
    
    func saveViewContext() {
        try? DataController.shared.viewContext.save()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        saveViewContext()
        
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        saveViewContext()
    }
}

