//
//  ARObjectDetectionView.swift
//  Forma3D
//
//  Created by Victor Munera on 25/09/2026.
//

import SwiftUI
import RealityKit
import ARKit

struct ARObjectDetectionView: UIViewRepresentable {
    let scannedObjects: [ScannedObject]
    var onObjectDetected: ((ScannedObject) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(scannedObjects: scannedObjects, onObjectDetected: onObjectDetected)
    }

    func makeUIView(context: Context) -> ARView {
        // Inicializamos con dimensiones de pantalla para que Metal monte el pipeline de cámara
        let bounds = UIScreen.main.bounds
        let arView = ARView(frame: bounds, cameraMode: .ar, automaticallyConfigureSession: false)
        
        context.coordinator.setupSession(for: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Asegura que la sesión sigue corriendo si SwiftUI reconstruye la vista
        if !context.coordinator.isRunning {
            context.coordinator.runSession()
        }
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        coordinator.pauseSession()
    }

    // MARK: - Coordinator
    @MainActor
    final class Coordinator: NSObject, ARSessionDelegate {
        private let scannedObjects: [ScannedObject]
        private let onObjectDetected: ((ScannedObject) -> Void)?
        private weak var arView: ARView?
        private var detectedObjectIDs: Set<UUID> = []
        private(set) var isRunning: Bool = false

        init(scannedObjects: [ScannedObject], onObjectDetected: ((ScannedObject) -> Void)?) {
            self.scannedObjects = scannedObjects
            self.onObjectDetected = onObjectDetected
        }

        func setupSession(for arView: ARView) {
            self.arView = arView
            arView.session.delegate = self
            runSession()
        }

        func runSession() {
            guard let arView, ARWorldTrackingConfiguration.isSupported else {
                print("⚠️ ARWorldTrackingConfiguration no está soportado en este dispositivo.")
                return
            }

            let configuration = ARWorldTrackingConfiguration()
            configuration.environmentTexturing = .automatic

            // 1. Cargar ARReferenceObjects válidos
            var referenceObjects = Set<ARReferenceObject>()
            for item in scannedObjects {
                if FileManager.default.fileExists(atPath: item.arObjectURL.path(percentEncoded: false)),
                   let refObj = try? ARReferenceObject(archiveURL: item.arObjectURL) {
                    refObj.name = item.id.uuidString
                    referenceObjects.insert(refObj)
                }
            }

            if !referenceObjects.isEmpty {
                configuration.detectionObjects = referenceObjects
                print("🎯 Detección configurada con \(referenceObjects.count) objetos de referencia.")
            } else {
                print("ℹ️ Modo AR activo sin objetos .arobject (feed de cámara en vivo).")
            }

            // 2. Arrancar la cámara
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            isRunning = true
        }

        func pauseSession() {
            arView?.session.pause()
            isRunning = false
        }

        // MARK: - ARSessionDelegate
        nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
            print("❌ Error en la sesión de ARKit: \(error.localizedDescription)")
        }

        nonisolated func sessionWasInterrupted(_ session: ARSession) {
            print("⚠️ Sesión de ARKit interrumpida")
        }

        nonisolated func sessionInterruptionEnded(_ session: ARSession) {
            Task { @MainActor in
                self.runSession()
            }
        }

        nonisolated func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let objectAnchor = anchor as? ARObjectAnchor,
                      let rawID = objectAnchor.referenceObject.name,
                      let objectID = UUID(uuidString: rawID) else { continue }

                Task { @MainActor in
                    self.handleDetectedObject(withID: objectID, anchor: objectAnchor)
                }
            }
        }

        @MainActor
        private func handleDetectedObject(withID id: UUID, anchor: ARObjectAnchor) {
            guard !detectedObjectIDs.contains(id),
                  let matchedObject = scannedObjects.first(where: { $0.id == id }),
                  let arView = self.arView else { return }

            detectedObjectIDs.insert(id)
            onObjectDetected?(matchedObject)

            Task {
                do {
                    let modelEntity = try await Entity(contentsOf: matchedObject.modelURL)
                    let anchorEntity = AnchorEntity(anchor: anchor)
                    anchorEntity.addChild(modelEntity)
                    arView.scene.addAnchor(anchorEntity)
                } catch {
                    print("Error al instanciar USDZ: \(error)")
                }
            }
        }
    }
}
