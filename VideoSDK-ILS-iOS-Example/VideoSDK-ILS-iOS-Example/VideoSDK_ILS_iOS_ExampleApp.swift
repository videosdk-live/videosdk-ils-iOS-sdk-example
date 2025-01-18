//
//  VideoSDK_ILS_iOS_ExampleApp.swift
//  VideoSDK-ILS-iOS-Example
//
//  Created by Deep Bhupatkar on 18/01/25.
//

import SwiftUI

@main
struct VideoSDK_ILS_iOS_ExampleApp: App {
    init() {
           // Set the appearance globally
           UITableView.appearance().backgroundColor = .black
           UICollectionView.appearance().backgroundColor = .black
           UIScrollView.appearance().backgroundColor = .black
       }
    var body: some Scene {
        WindowGroup {
            InitialView()
                .environment(\.colorScheme, .dark) // Force dark mode
        }
    }
}
