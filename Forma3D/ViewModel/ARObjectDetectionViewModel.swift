//
//  ARObjectDetectionViewModel.swift
//  Forma3D
//
//  Created by Victor Munera on 27/09/2026.
//

import Foundation
import RealityKit
import ARKit
import OSLog

// MARK: - Dedicated Logger Extension
extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.forma3d.app"
    static let arDetection = Logger(subsystem: subsystem, category: "ARObjectDetection")
}

@MainActor
@Observable
final class ARObjectDetectionViewModel: NSObject {
    
    // MARK: - Observable State
    private(set) var isRunning = false
    var sessionError: String?
    var isSessionInterrupted = false
    var isProcessing = false
    
    /// Estado del tracking de ARKit en tiempo real
    var trackingState: ARCamera.TrackingState = .notAvailable
    
    /// Indica si la sesión está lista y el tracking es óptimo para capturar
    var isReadyToScan: Bool {
        guard isRunning && !isConfiguring && !isProcessing else { return false }
        if case .normal = trackingState {
            return true
        }
        return false
    }
    
    /// Mensaje descriptivo para guiar al usuario en el HUD según el estado del sensor
    var trackingStatusDescription: String {
        switch trackingState {
        case .notAvailable:
            return "Iniciando cámara..."
        case .limited(let reason):
            switch reason {
            case .initializing:
                return "Calibrando sensores..."
            case .excessiveMotion:
                return "Mueve el dispositivo más despacio"
            case .insufficientFeatures:
                return "Buscando detalles en la superficie"
            case .relocalizing:
                return "Reubicando escena..."
            @unknown default:
                return "Calibrando entorno..."
            }
        case .normal:
            return "Listo para identificar"
        }
    }
    
    // MARK: - Properties
    var scannedObjects: [ScannedObject]
    var onObjectDetected: ((ScannedObject) -> Void)?
    
    private weak var arView: ARView?
    private var isConfiguring = false
    
    // MARK: - Init
    init(
        scannedObjects: [ScannedObject] = [],
        onObjectDetected: ((ScannedObject) -> Void)? = nil
    ) {
        self.scannedObjects = scannedObjects
        self.onObjectDetected = onObjectDetected
        super.init()
    }
    
    // MARK: - Lifecycle Management
    func setupView(_ arView: ARView) {
        self.arView = arView
        arView.session.delegate = self
        Logger.arDetection.debug("ARView y delegado vinculados.")
    }
    
    func resume() {
        guard let arView, ARWorldTrackingConfiguration.isSupported, !isRunning, !isConfiguring else { return }
        isConfiguring = true
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .automatic
        
        if #available(iOS 27.0, *) {
            // Camino iOS 27+
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        } else {
            // Camino iOS 18-26
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
        
        isRunning = true
        isConfiguring = false
        isSessionInterrupted = false
        sessionError = nil
        Logger.arDetection.info("Sesión AR iniciada limpiamente.")
    }
    
    func pause() {
        guard isRunning else { return }
        arView?.session.pause()
        isRunning = false
        isConfiguring = false
        trackingState = .notAvailable
        Logger.arDetection.info("Sesión AR pausada.")
    }
    
    func tearDown() {
        arView?.session.delegate = nil
        arView?.session.pause()
        isRunning = false
        isConfiguring = false
        trackingState = .notAvailable
        arView = nil
        Logger.arDetection.info("Sesión AR desmontada y liberada.")
    }
    
    // MARK: - Recognition Trigger
    func identifyCurrentView() {
        guard let arView else {
            Logger.arDetection.warning("Intento de captura sin ARView disponible.")
            return
        }
        guard let currentFrame = arView.session.currentFrame else {
            Logger.arDetection.warning("ARFrame no disponible al disparar identificación.")
            return
        }
        
        let pixelBuffer = currentFrame.capturedImage
        isProcessing = true
        Logger.arDetection.debug("Iniciando análisis de imagen en segundo plano...")
        
        Task(priority: .userInitiated) {
            let candidates = self.scannedObjects
            let matched = await ObjectRecognitionService.shared.identifyObject(
                from: pixelBuffer,
                candidates: candidates
            )
            
            await MainActor.run {
                self.isProcessing = false
                if let matched {
                    Logger.arDetection.notice("Objeto reconocido con éxito: \(matched.name, privacy: .public)")
                    self.onObjectDetected?(matched)
                } else {
                    Logger.arDetection.notice("No se encontró coincidencia sobre los candidatos analizados.")
                }
            }
        }
    }
    
    // MARK: - Delegate Handlers
    func handleSessionError(_ error: Error) {
        sessionError = error.localizedDescription
        isRunning = false
        Logger.arDetection.error("Error crítico en ARSession: \(error.localizedDescription, privacy: .public)")
    }
    
    func handleSessionInterruption() {
        isSessionInterrupted = true
        pause()
        Logger.arDetection.warning("ARSession interrumpida por el sistema.")
    }
    
    func handleSessionInterruptionEnded() {
        isSessionInterrupted = false
        resume()
        Logger.arDetection.info("ARSession recuperada tras interrupción.")
    }
    
    func updateTrackingState(_ state: ARCamera.TrackingState) {
        self.trackingState = state
    }
}

// MARK: - ARSessionDelegate
extension ARObjectDetectionViewModel: ARSessionDelegate {
    
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let state = frame.camera.trackingState
        Task { @MainActor [weak self] in
            self?.updateTrackingState(state)
        }
    }
    
    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.handleSessionError(error)
        }
    }
    
    nonisolated func sessionWasInterrupted(_ session: ARSession) {
        Task { @MainActor [weak self] in
            self?.handleSessionInterruption()
        }
    }
    
    nonisolated func sessionInterruptionEnded(_ session: ARSession) {
        Task { @MainActor [weak self] in
            self?.handleSessionInterruptionEnded()
        }
    }
}
