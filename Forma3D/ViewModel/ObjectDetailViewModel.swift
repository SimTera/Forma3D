//
//  ObjectDetailViewModel.swift
//  Forma3D
//
//  Created by Victor Munera on 27/09/2026.
//

import SwiftUI
import RealityKit
import simd
import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.forma3d.app"
    static let objectDetail = Logger(subsystem: subsystem, category: "ObjectDetail")
}

// MARK: - Spatial Configuration Constants
private enum SpatialConfiguration {
    static let rotationSensitivity: Float = 0.015
    static let pinchSensitivity: Float = 0.25
    static let minZoomLimit: Float = 0.4
    static let maxZoomLimit: Float = 11.0
    static let targetViewportSize: Float = 0.25 // ~25 cm virtuales
}

@MainActor
@Observable
final class ObjectDetailViewModel {
    
    // MARK: - Model Reference
    let object: ScannedObject
    
    // MARK: - Spatial & Gesture State
    var orientation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])
    var dragOffset: CGSize = .zero
    
    var baseScale: Float = 1.0
    var currentScale: Float = 1.0
    var gestureScale: Float = 1.0
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .rigid)
    
    // MARK: - Computed Properties
    var isModelFileAvailable: Bool {
        FileManager.default.fileExists(atPath: object.modelURL.path(percentEncoded: false))
    }
    
    var effectiveZoom: Float {
        currentScale * gestureScale
    }
    
    var computedScale: SIMD3<Float> {
        SIMD3<Float>(repeating: baseScale * effectiveZoom)
    }
    
    /// Indica si el usuario ha rotado o cambiado la escala respecto al estado neutral
        var isTransformed: Bool {
            orientation != simd_quatf(angle: 0, axis: [0, 1, 0]) || currentScale != 1.0 || dragOffset != .zero
        }
    
    var liveOrientation: simd_quatf {
        let pitchAngle = Float(dragOffset.height) * SpatialConfiguration.rotationSensitivity
        let yawAngle = Float(dragOffset.width) * SpatialConfiguration.rotationSensitivity
        
        let pitchQuat = simd_quatf(angle: pitchAngle, axis: [1, 0, 0])
        let yawQuat = simd_quatf(angle: yawAngle, axis: [0, 1, 0])
        
        return yawQuat * pitchQuat * orientation
    }
    
    // MARK: - Init
    init(object: ScannedObject) {
        self.object = object
        self.impactFeedback.prepare()
    }
    
    // MARK: - RealityKit Normalization
    /// Centra el pivote del modelo y calcula la escala inicial óptima para el visor.
    func normalize(entity: Entity) -> Float {
        let bounds = entity.visualBounds(relativeTo: nil)
        let center = bounds.center
        entity.position = -center
        
        let maxDimension = max(bounds.extents.x, max(bounds.extents.y, bounds.extents.z))
        guard maxDimension > 0 else { return 1.0 }
        
        let initialScale = SpatialConfiguration.targetViewportSize / maxDimension
        self.baseScale = initialScale
        return initialScale
    }
    
    // MARK: - Gesture Handling
    func updateDragTranslation(_ translation: CGSize) {
        dragOffset = translation
    }
    
    func commitDragTranslation(_ translation: CGSize) {
        let pitchAngle = Float(translation.height) * SpatialConfiguration.rotationSensitivity
        let yawAngle = Float(translation.width) * SpatialConfiguration.rotationSensitivity
        
        let pitchQuat = simd_quatf(angle: pitchAngle, axis: [1, 0, 0])
        let yawQuat = simd_quatf(angle: yawAngle, axis: [0, 1, 0])
        
        orientation = yawQuat * pitchQuat * orientation
        dragOffset = .zero
    }
    
    func updateMagnification(_ magnification: CGFloat) {
        let delta = (Float(magnification) - 1.0) * SpatialConfiguration.pinchSensitivity
        let proposedScale = 1.0 + delta
        
        // Tope elástico visual durante el pellizco
        gestureScale = max(0.5, min(3.5, proposedScale))
    }
    
    func commitMagnification(_ magnification: CGFloat) {
        let delta = (Float(magnification) - 1.0) * SpatialConfiguration.pinchSensitivity
        let appliedDelta = 1.0 + delta
        let tentativeZoom = currentScale * appliedDelta
        
        // Detección de colisión con los límites para emitir haptic
        if tentativeZoom <= SpatialConfiguration.minZoomLimit || tentativeZoom >= SpatialConfiguration.maxZoomLimit {
            impactFeedback.impactOccurred()
        }
        
        currentScale = max(SpatialConfiguration.minZoomLimit, min(SpatialConfiguration.maxZoomLimit, tentativeZoom))
        gestureScale = 1.0
    }
    
    func resetTransform() {
        orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
        dragOffset = .zero
        currentScale = 1.0
        gestureScale = 1.0
        impactFeedback.impactOccurred()
    }
}
