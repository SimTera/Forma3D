//
//  ScannerApp.swift
//  Forma3D
//
//  Created by Victor Munera on 20/09/2026.
//
//  Aplicación de escaneo 3D con soporte para Object Capture API
//  iOS 26+ | Swift 6 | Strict Concurrency


import SwiftUI
import SwiftData

@main
struct ScannerApp: App {
    var body: some Scene {
        WindowGroup {
            MainMenuView()
        }
        .modelContainer(for: ScannedObject.self)
    }
}
