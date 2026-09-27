//
//  ObjectDetailView.swift
//  Forma3D
//
//  Created by Victor Munera on 25/09/2026.
//
//  Vista de detalle para inspeccionar, manipular en 3D y exportar
//  los modelos generados con RealityKit y persistidos con SwiftData.
//

import SwiftUI
import RealityKit
import OSLog

struct ObjectDetailView: View {
    // MARK: - ViewModel
    @State private var viewModel: ObjectDetailViewModel
    
    init(object: ScannedObject) {
        _viewModel = State(initialValue: ObjectDetailViewModel(object: object))
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. Visor interactivo 3D
                modelViewerSection
                    .frame(height: 380)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                // 2. Metadatos del escaneo
                metadataSection
                
                // 3. Botones de acción / exportación
                actionSection
            }
            .padding(20)
        }
        .navigationTitle(viewModel.object.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.ignoresSafeArea())
    }
    
    // MARK: - 3D Viewer Section
    @ViewBuilder
    private var modelViewerSection: some View {
        if viewModel.isModelFileAvailable {
#if os(visionOS) || os(macOS)
            Model3D(url: viewModel.object.modelURL) { phase in
                switch phase {
                case .empty:
                    ProgressView("Cargando malla 3D...")
                        .tint(.white)
                case .success(let resolvedModel):
                    resolvedModel
                        .resizable()
                        .scaledToFit()
                        .padding(24)
                case .failure(let error):
                    ContentUnavailableView(
                        "Error al cargar",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error.localizedDescription)
                    )
                @unknown default:
                    EmptyView()
                }
            }
#else
            ZStack {
                RealityView { content in
                    do {
                        let rootAnchor = Entity()
                        rootAnchor.name = "rootAnchor"
                        
                        let modelEntity = try await Entity(contentsOf: viewModel.object.modelURL)
                        modelEntity.name = "modelEntity"
                        
                        // Centrado y escala normalizada calculados en el ViewModel
                        let initialScale = viewModel.normalize(entity: modelEntity)
                        rootAnchor.scale = SIMD3<Float>(repeating: initialScale)
                        
                        rootAnchor.addChild(modelEntity)
                        content.add(rootAnchor)
                    } catch {
                        Logger.objectDetail.error("Error cargando Entity en RealityView: \(error.localizedDescription, privacy: .public)")
                    }
                } update: { content in
                    guard let rootAnchor = content.entities.first(where: { $0.name == "rootAnchor" }) else { return }
                    
                    // Rotación y escala dirigidas por el ViewModel
                    rootAnchor.orientation = viewModel.liveOrientation
                    rootAnchor.scale = viewModel.computedScale
                } placeholder: {
                    ProgressView("Cargando modelo 3D...")
                        .tint(.white)
                }
                .contentShape(Rectangle())
                .gesture(rotationAndScaleGesture)
                
                // Guía visual interactiva
                interactionOverlay
            }
#endif
        } else {
            ContentUnavailableView(
                "Archivo no encontrado",
                systemImage: "shippingbox.and.arrow.backward",
                description: Text("El archivo USDZ no está presente en el almacenamiento local.")
            )
        }
    }
    
    private var interactionOverlay: some View {
        VStack {
            HStack {
                Spacer()
                if viewModel.isTransformed {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.resetTransform()
                        }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .transition(.scale.combined(with: .opacity))
                    .padding(12)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: "hand.draw")
                Text("Arrastra para rotar • Pellizca para zoom")
            }
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.6))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(.bottom, 12)
        }
    }
    
    // MARK: - Gestures
    private var rotationAndScaleGesture: some Gesture {
        let drag = DragGesture()
            .onChanged { value in
                viewModel.updateDragTranslation(value.translation)
            }
            .onEnded { value in
                viewModel.commitDragTranslation(value.translation)
            }
        
        let magnify = MagnifyGesture()
            .onChanged { value in
                viewModel.updateMagnification(value.magnification)
            }
            .onEnded { value in
                viewModel.commitMagnification(value.magnification)
            }
        
        return drag.simultaneously(with: magnify)
    }
    
    // MARK: - Metadata Section
    private var metadataSection: some View {
        VStack(spacing: 14) {
            metadataRow(icon: "calendar", title: "Fecha de captura", value: viewModel.object.formattedDate)
            Divider().background(Color.white.opacity(0.1))
            metadataRow(icon: "internaldrive", title: "Tamaño del archivo", value: viewModel.object.formattedFileSize)
            Divider().background(Color.white.opacity(0.1))
            metadataRow(icon: "cube.transparent", title: "Formato", value: "Universal Scene Description (.usdz)")
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func metadataRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
    }
    
    // MARK: - Action Section
    private var actionSection: some View {
        VStack(spacing: 12) {
            ShareLink(
                item: viewModel.object.modelURL,
                preview: SharePreview(viewModel.object.name, icon: Image(systemName: "cube"))
            ) {
                Label("Exportar Archivo USDZ", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }
}
