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
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundStyle(.orange)
                            Text("No se pudo renderizar el modelo.")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                            Text(error.localizedDescription)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding()
                    @unknown default:
                        EmptyView()
                    }
                }
                #else
                // Visor nativo RealityView para iOS 18+
                RealityView { content in
                    do {
                        let entity = try await Entity(contentsOf: object.modelURL)
                        entity.position = [0, 0, 0]
                        content.add(entity)
                    } catch {
                        print("Error cargando Entity en RealityView: \(error)")
                    }
                } placeholder: {
                    ProgressView("Cargando modelo 3D...")
                        .tint(.white)
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
            let drag = DragGesture(minimumDistance: 0)
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let pitchAngle = Float(value.translation.height) * 0.01
                    let yawAngle = Float(value.translation.width) * 0.01
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
                    currentScale = max(0.2, min(5.0, currentScale * Float(value.magnification)))
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
