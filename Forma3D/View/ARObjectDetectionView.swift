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
        let arView = ARView(frame: .zero)
        context.coordinator.setupSession(for: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Las actualizaciones de sesión se gestionan en el Coordinator
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
    }

    // MARK: - Coordinator
    @MainActor
    final class Coordinator: NSObject, ARSessionDelegate {
        private let scannedObjects: [ScannedObject]
        private let onObjectDetected: ((ScannedObject) -> Void)?
        private weak var arView: ARView?
        private var detectedObjectIDs: Set<UUID> = []

        init(scannedObjects: [ScannedObject], onObjectDetected: ((ScannedObject) -> Void)?) {
            self.scannedObjects = scannedObjects
            self.onObjectDetected = onObjectDetected
        }

        func setupSession(for arView: ARView) {
            self.arView = arView
            arView.session.delegate = self

            let configuration = ARWorldTrackingConfiguration()

            // 1. Cargar todos los ARReferenceObject desde Application Support
            var referenceObjects = Set<ARReferenceObject>()
            for item in scannedObjects {
                if let refObj = try? ARReferenceObject(archiveURL: item.arObjectURL) {
                    // Usamos el id del item como nombre para correlacionarlo luego
                    refObj.name = item.id.uuidString
                    referenceObjects.insert(refObj)
                }
            }

            configuration.detectionObjects = referenceObjects

            // 2. Ejecutar la sesión reseteando el tracking existente
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }

        // MARK: - ARSessionDelegate
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

            // Cargar el modelo USDZ correspondiente y anclarlo sobre el objeto real
            Task {
                do {
                    let modelEntity = try await Entity(contentsOf: matchedObject.modelURL)
                    
                    // Si necesitas colisiones o físicas en sus mallas hijas:
                    // sceneEntity.generateCollisionShapes(recursive: true)
                    
                    // Crear un AnchorEntity asociado al ARObjectAnchor detectado
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
