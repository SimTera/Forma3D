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
    // MARK: - SwiftData & ViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScannedObject.dateScanned, order: .reverse)
    private var scannedObjects: [ScannedObject]

    @State private var viewModel = LibraryViewModel()

    // MARK: - Body
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
        .preferredColorScheme(.dark)
    }

    // MARK: - Subviews
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
        ContentUnavailableView(
            "Biblioteca Vacía",
            systemImage: "cube.transparent",
            description: Text("Escanea y modela tu primer objeto 3D para verlo aquí.")
        )
        .foregroundStyle(.white)
    }

    private var objectsList: some View {
        List {
            ForEach(scannedObjects) { object in
                NavigationLink(destination: ObjectDetailView(object: object)) {
                    objectRow(for: object)
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            .onDelete { offsets in
                if let firstIndex = offsets.first, scannedObjects.indices.contains(firstIndex) {
                    viewModel.objectPendingDeletion = scannedObjects[firstIndex]
                }
            }
        }
        .scrollContentBackground(.hidden)
        .confirmationDialog(
            "¿Eliminar modelo 3D?",
            isPresented: Binding(
                get: { viewModel.objectPendingDeletion != nil },
                set: { if !$0 { viewModel.objectPendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: viewModel.objectPendingDeletion
        ) { target in
            Button("Eliminar \"\(target.name)\"", role: .destructive) {
                viewModel.deleteObjects([target], context: modelContext)
                viewModel.objectPendingDeletion = nil
            }
            Button("Cancelar", role: .cancel) {
                viewModel.objectPendingDeletion = nil
            }
        } message: { target in
            Text("Esta acción eliminará el archivo 3D (\(target.formattedFileSize)) y todos los datos asociados de forma permanente.")
        }
        .scrollContentBackground(.hidden)
    }

    private func objectRow(for object: ScannedObject) -> some View {
        HStack(spacing: 16) {
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
}

// MARK: - Preview
#Preview {
    NavigationStack {
        LibraryView()
            .modelContainer(for: ScannedObject.self, inMemory: true)
    }
}
