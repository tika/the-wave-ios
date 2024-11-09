//
//  TheWaveApp.swift
//  The Wave
//
//  Created by Tika on 09/11/2024.
//

import SwiftUI

@main
struct TheWaveApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.colorScheme, .dark)
        }
    }
}
