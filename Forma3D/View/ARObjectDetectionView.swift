//
//  ARObjectDetectionView.swift
//  Forma3D
//
//  Created by Victor Munera on 25/09/2026.
//

import SwiftUI
import RealityKit
import ARKit

@MainActor
struct ARObjectDetectionView: UIViewRepresentable {
    let scannedObjects: [ScannedObject]
    let isActive: Bool
    @Binding var triggerScan: Bool // Para ios 18 a 26.
    var onObjectDetected: ((ScannedObject) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(scannedObjects: scannedObjects, onObjectDetected: onObjectDetected)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: UIScreen.main.bounds, cameraMode: .ar, automaticallyConfigureSession: false)
        arView.renderOptions = [.disablePersonOcclusion, .disableFaceMesh]
        context.coordinator.setupSession(for: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if isActive {
            if !context.coordinator.isRunning {
                context.coordinator.resume()
            }
        } else {
            if !context.coordinator.isRunning {
                context.coordinator.pause()
            }
        }
        
        // Disparo bajo demanda
        if triggerScan {
            context.coordinator.identifyCurrentView()
            Task { @MainActor in
                triggerScan = false
            }
        }
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        coordinator.tearDown(for: uiView)
    }

    // MARK: - Coordinator
    @MainActor
    final class Coordinator: NSObject, ARSessionDelegate {
        private let scannedObjects: [ScannedObject]
        private let onObjectDetected: ((ScannedObject) -> Void)?
        private weak var arView: ARView?
        //        private var detectedObjectIDs: Set<UUID> = [] // Lo quitamos
        private(set) var isRunning = false
        
        init(scannedObjects: [ScannedObject], onObjectDetected: ((ScannedObject) -> Void)?) {
            self.scannedObjects = scannedObjects
            self.onObjectDetected = onObjectDetected
        }
        
        func setupSession(for arView: ARView) {
            self.arView = arView
            arView.session.delegate = self
            resume()
        }
        
        func resume() {
            guard let arView, ARWorldTrackingConfiguration.isSupported, !isRunning else { return }
            
            if #available(iOS 27.0, *) {
                // MARK: Camino A - iOS 27+ (Nuevo Object Tracking con .referenceobject)
                configureModernTracking(in: arView)
            } else {
                // MARK: Camino B - iOS 18-26 (ARWorldTracking estandard asistido por Vision)
                let configuration = ARWorldTrackingConfiguration()
                configuration.environmentTexturing = .automatic
                arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            }
            
            isRunning = true
            
            // Filtrar solo .arobject válidos (> 1 KB) para evitar fallos de ARArchive
            //            var referenceObjects = Set<ARReferenceObject>()
            //            for item in scannedObjects {
            //                let filePath = item.arObjectURL.path(percentEncoded: false)
            //                if let attrs = try? FileManager.default.attributesOfItem(atPath: filePath),
            //                   let size = attrs[.size] as? Int64, size > 1024,
            //                   let refObj = try? ARReferenceObject(archiveURL: item.arObjectURL) {
            //                    refObj.name = item.id.uuidString
            //                    referenceObjects.insert(refObj)
            //                }
            //            }
            //
            //            if !referenceObjects.isEmpty {
            //                configuration.detectionObjects = referenceObjects
            //            }
            //
            //            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            //            isRunning = true
        }
        
        func pause() {
            guard isRunning else { return }
            arView?.session.pause()
            isRunning = false
        }
        
        func tearDown(for arView: ARView) {
            arView.session.delegate = nil
            arView.session.pause()
            isRunning = false
        }
        
        // Identificación ejecutada al pulsar el botón del HUD
        func identifyCurrentView() {
            guard let arView else {
                print("⚠️ arView no disponible")
                return
            }
            
            guard let currentFrame = arView.session.currentFrame else {
                print("⚠️ ARFrame no disponible aún (esperando a que el tracking se estabilice)")
                return
            }
            
            let pixelBuffer = currentFrame.capturedImage
            
            Task(priority: .userInitiated) {
                let candidates = self.scannedObjects
                if let matched = await ObjectRecognitionService.shared.identifyObject(
                    from: pixelBuffer,
                    candidates: candidates
                ) {
                    onObjectDetected?(matched)
                } else {
                    print("🔍 No se encontró coincidencia con el umbral actual.")
                }
            }
        }
        
        @available(iOS 27.0, *)
        private func configureModernTracking(in arView: ARView) {
            let configuration = ARWorldTrackingConfiguration()
            configuration.environmentTexturing = .automatic
            // Espacio reservado para inyectar trackingObjects compilados desde USDZ
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
        
        // MARK: - ARSessionDelegate
        nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
            print("❌ Error en ARSession: \(error.localizedDescription)")
        }
        
        nonisolated func sessionWasInterrupted(_ session: ARSession) {
            Task { @MainActor [weak self] in
                self?.pause()
            }
        }
        
        nonisolated func sessionInterruptionEnded(_ session: ARSession) {
            Task { @MainActor [weak self] in
                self?.resume()
            }
        }
        
//        nonisolated func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
//            for anchor in anchors {
//                guard let objectAnchor = anchor as? ARObjectAnchor,
//                      let rawID = objectAnchor.referenceObject.name,
//                      let objectID = UUID(uuidString: rawID) else { continue }
//                
//                Task { @MainActor [weak self] in
//                    self?.handleDetectedObject(withID: objectID, anchor: objectAnchor)
//                }
//            }
//        }
        
//        @MainActor
//        private func handleDetectedObject(withID id: UUID, anchor: ARObjectAnchor) {
//            guard !detectedObjectIDs.contains(id),
//                  let matchedObject = scannedObjects.first(where: { $0.id == id }),
//                  let arView = self.arView else { return }
//            
//            detectedObjectIDs.insert(id)
//            onObjectDetected?(matchedObject)
//            
//            Task {
//                do {
//                    let modelEntity = try await Entity(contentsOf: matchedObject.modelURL)
//                    let anchorEntity = AnchorEntity(anchor: anchor)
//                    anchorEntity.addChild(modelEntity)
//                    arView.scene.addAnchor(anchorEntity)
//                } catch {
//                    print("Error al instanciar USDZ: \(error)")
//                }
//            }
//        }
    }
}
