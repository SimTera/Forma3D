//
//  LibraryView.swift
//  Forma3D
//
//  Created by Victor Munera on 20/09/2026.
//
//  Vista de biblioteca con gestión completa de objetos escaneados
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    // MARK: - SwiftData
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \ScannedObject.dateScanned, order: .reverse)
    private var scannedObjects: [ScannedObject]

    // MARK: - Body
    var body: some View {
        ZStack {
            backgroundGradient
            
            if scannedObjects.isEmpty {
                // API moderna de SwiftUI para estados vacíos
                ContentUnavailableView(
                    "Biblioteca Vacía",
                    systemImage: "cube.transparent",
                    description: Text("Escanea y modela tu primer objeto 3D para verlo aquí.")
                )
                .foregroundStyle(.white)
            } else {
                objectsList
            }
        }
        .navigationTitle("Biblioteca")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
    }

    // MARK: - Views
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

    private var objectsList: some View {
        List {
            ForEach(scannedObjects) { object in
                NavigationLink(destination: ObjectDetailView(object: object)) {
                    objectRow(for: object)
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            .onDelete(perform: deleteObjects)
        }
        .scrollContentBackground(.hidden)
    }
    
    private func objectRow(for object: ScannedObject) -> some View {
        HStack(spacing: 16) {
            // Icono o miniatura
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 54, height: 54)
                
                Image(systemName: "cube.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(object.name)
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    Text(object.formattedDate)
                    Text("•")
                    Text(object.formattedFileSize)
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions
    private func deleteObjects(at offsets: IndexSet) {
        for index in offsets {
            let object = scannedObjects[index]
            
            // 1. Borrar archivos físicos asociados en disco para no dejar huérfanos
            try? FileManager.default.removeItem(at: object.modelURL)
            try? FileManager.default.removeItem(at: object.arObjectURL)
            if let thumbURL = object.thumbnailURL {
                try? FileManager.default.removeItem(at: thumbURL)
            }
            
            // 2. Borrar registro en SwiftData
            modelContext.delete(object)
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView()
            .modelContainer(for: ScannedObject.self, inMemory: true)
    }
}


