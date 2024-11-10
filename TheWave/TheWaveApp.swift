//
//  TheWaveApp.swift
//  The Wave
//
//  Created by Tika on 09/11/2024.
//

import SwiftUI

@main
struct TheWaveApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.font, .authorVariable(size: 16))
                .environment(\.colorScheme, .dark)
        }
    }
}
