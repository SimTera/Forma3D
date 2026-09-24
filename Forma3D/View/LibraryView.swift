//
//  LibraryView.swift
//  3D Scanner Module
//
//  Vista de biblioteca con SwiftData Query
//

import SwiftUI
import SwiftData

@MainActor
struct LibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ScannedObject.dateScanned, order: .reverse)
    private var scannedObjects: [ScannedObject]
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            if scannedObjects.isEmpty {
                emptyStateView
            } else {
                objectsList
            }
        }
        .navigationTitle("Biblioteca")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.15, green: 0.05, blue: 0.2),
                Color(red: 0.1, green: 0.05, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 100))
                .foregroundStyle(.purple.opacity(0.6))
            
            Text("Biblioteca Vacía")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text("Escanea tu primer objeto")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
    
    private var objectsList: some View {
        List(scannedObjects) { object in
            Text(object.name)
                .foregroundStyle(.white)
        }
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    NavigationStack {
        LibraryView()
            .modelContainer(for: ScannedObject.self, inMemory: true)
    }
}
