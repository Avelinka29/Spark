//
//  SparkApp.swift
//  Spark
//
//  Created by mac on 14.06.26.
//

import GoogleSignIn
import SwiftUI

@main
struct SparkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
