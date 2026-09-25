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

struct ObjectDetailView: View {
    // MARK: - Properties
    let object: ScannedObject
    
    // MARK: - Gesture State (3D Manipulation)
        @State private var orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
        @State private var dragOffset: CGSize = .zero
        
        @State private var currentScale: Float = 1.0
        @State private var gestureScale: Float = 1.0
    
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
        .navigationTitle(object.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.ignoresSafeArea())
    }
    
    // MARK: - 3D Viewer Section (Multiplataforma)
        @ViewBuilder
        private var modelViewerSection: some View {
            if FileManager.default.fileExists(atPath: object.modelURL.path(percentEncoded: false)) {
#if os(visionOS) || os(macOS)
                // Visor nativo con volumen espacial para visionOS / macOS
                Model3D(url: object.modelURL) { phase in
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
                // Visor nativo RealityView para iOS 18+
                ZStack {
                    RealityView { content in
                        do {
                            let rootAnchor = Entity()
                            rootAnchor.name = "rootAnchor"
                            
                            let modelEntity = try await Entity(contentsOf: object.modelURL)
                            modelEntity.name = "modelEntity"
                            
                            // 1. Centrar el pivote del modelo usando su BoundingBox real
                            let bounds = modelEntity.visualBounds(relativeTo: nil)
                            let center = bounds.center
                            modelEntity.position = -center
                            
                            // 2. Normalizar escala para que quepa en el visor si es muy grande o muy pequeño
                            let maxDimension = max(bounds.extents.x, max(bounds.extents.y, bounds.extents.z))
                            if maxDimension > 0 {
                                let targetSize: Float = 0.25 // ~25 cm virtuales en pantalla
                                let baseScale = targetSize / maxDimension
                                rootAnchor.scale = SIMD3<Float>(repeating: baseScale)
                            }
                            
                            rootAnchor.addChild(modelEntity)
                            content.add(rootAnchor)
                        } catch {
                            print("Error cargando Entity en RealityView: \(error)")
                        }
                    } update: { content in
                        guard let rootAnchor = content.entities.first(where: { $0.name == "rootAnchor" }) else { return }
                        
                        // Rotación en tiempo real (inercia arrastre + orientación guardada)
                        let pitchAngle = Float(dragOffset.height) * 0.015
                        let yawAngle = Float(dragOffset.width) * 0.015
                        
                        let pitchQuat = simd_quatf(angle: pitchAngle, axis: [1, 0, 0])
                        let yawQuat = simd_quatf(angle: yawAngle, axis: [0, 1, 0])
                        
                        rootAnchor.orientation = yawQuat * pitchQuat * orientation
                        
                        // Escala reactiva
                        let effectiveScaleFactor = max(0.3, min(4.0, gestureScale))
                        let baseScale = rootAnchor.scale.x / (currentScale > 0 ? currentScale : 1.0)
                        let finalScale = baseScale * currentScale * effectiveScaleFactor
                        rootAnchor.scale = SIMD3<Float>(repeating: finalScale)
                    } placeholder: {
                        ProgressView("Cargando modelo 3D...")
                            .tint(.white)
                    }
                    .contentShape(Rectangle()) // Fuerza a toda el área a registrar toques
                    .gesture(rotationAndScaleGesture)
                    
                    // Guía visual interactiva
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "hand.draw")
                            Text("Arrastra con un dedo para rotar • Pellizca con dos para zoom")
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
                #endif
            } else {
                ContentUnavailableView(
                    "Archivo no encontrado",
                    systemImage: "shippingbox.and.arrow.backward",
                    description: Text("El archivo USDZ no está presente en el almacenamiento local.")
                )
            }
        }
    
    // MARK: - Gestures
        private var rotationAndScaleGesture: some Gesture {
            // Gesto de rotación en 2 ejes (Yaw y Pitch)
            let drag = DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let pitchAngle = Float(value.translation.height) * 0.015
                    let yawAngle = Float(value.translation.width) * 0.015
                    let pitchQuat = simd_quatf(angle: pitchAngle, axis: [1, 0, 0])
                    let yawQuat = simd_quatf(angle: yawAngle, axis: [0, 1, 0])
                    
                    // Consolidar rotación permanente
                    orientation = yawQuat * pitchQuat * orientation
                    dragOffset = .zero
                }
            
            // Gesto de magnificación / zoom
            let magnify = MagnifyGesture()
                .onChanged { value in
                    gestureScale = Float(value.magnification)
                }
                .onEnded { value in
                    currentScale = max(0.3, min(4.0, currentScale * Float(value.magnification)))
                    gestureScale = 1.0
                }
            
            // Ejecutan en paralelo para permitir rotar y ampliar simultáneamente
            return drag.simultaneously(with: magnify)
        }
    
    // MARK: - Metadata Section
    private var metadataSection: some View {
        VStack(spacing: 14) {
            metadataRow(icon: "calendar", title: "Fecha de captura", value: object.formattedDate)
            Divider().background(Color.white.opacity(0.1))
            metadataRow(icon: "internaldrive", title: "Tamaño del archivo", value: object.formattedFileSize)
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
                item: object.modelURL,
                preview: SharePreview(object.name, icon: Image(systemName: "cube"))
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
