//
//  ObjectRecognitionService.swift
//  Forma3D
//
//  Created by Victor Munera on 26/09/2026.
//

import UIKit
import Vision
import CoreImage
import SceneKit

@MainActor
final class ObjectRecognitionService {
    static let shared = ObjectRecognitionService()
    
    // Umbral de distancia de Vision: valores inferiores a 0.4 indican una coincidencia muy alta
    private let matchDistanceThreshold: Float = 0.42
    
    private init() {}
    
    /// Compara el frame actual de la cámara contra la lista de objetos escaneados
    func identifyObject(
        from pixelBuffer: CVPixelBuffer,
        candidates: [ScannedObject]
    ) async -> ScannedObject? {
        guard !candidates.isEmpty else { return nil }
        
        // 1. Extraer la huella visual del fotograma actual de la cámara
        guard let queryPrint = computeFeaturePrint(from: pixelBuffer) else {
            return nil
        }
        
        var bestMatch: ScannedObject?
        var minimumDistance: Float = Float.greatestFiniteMagnitude
        
        // 2. Comparar contra cada candidato guardado
        for candidate in candidates {
            // Buscamos la imagen de referencia (snapshot o primera foto del escaneo)
            guard let referenceImage = loadReferenceImage(for: candidate),
                  let candidatePrint = computeFeaturePrint(from: referenceImage) else {
                continue
            }
            
            var distance: Float = 0
            do {
                try queryPrint.computeDistance(&distance, to: candidatePrint)
                if distance < minimumDistance && distance <= matchDistanceThreshold {
                    minimumDistance = distance
                    bestMatch = candidate
                }
            } catch {
                print("Error calculando distancia de características: \(error)")
            }
        }
        
        if let bestMatch {
            print("🎯 Objeto reconocido con éxito: \(bestMatch.name) (distancia: \(minimumDistance))")
        }
        
        return bestMatch
    }
    
    // MARK: - Feature Print Computation
    private func computeFeaturePrint(from pixelBuffer: CVPixelBuffer) -> VNFeaturePrintObservation? {
        let request = VNGenerateImageFeaturePrintRequest()
        request.imageCropAndScaleOption = .centerCrop
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
            return request.results?.first as? VNFeaturePrintObservation
        } catch {
            return nil
        }
    }
    
    private func computeFeaturePrint(from image: UIImage) -> VNFeaturePrintObservation? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNGenerateImageFeaturePrintRequest()
        request.imageCropAndScaleOption = .centerCrop
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            return request.results?.first as? VNFeaturePrintObservation
        } catch {
            return nil
        }
    }
    
    // MARK: - Reference Image Loader
    private func loadReferenceImage(for object: ScannedObject) -> UIImage? {
        // Intentar cargar la miniatura persistida junto al USDZ
        let previewURL = object.modelURL.deletingPathExtension().appendingPathExtension("jpg")
        
        // 1. Si ya tiene el JPG guardado en disco, lo usa
        if let data = try? Data(contentsOf: previewURL), let img = UIImage(data: data) {
            return img
        }
        
        // 2. Si no tiene JPG (como la captura de ayer o un USDZ importado),
        // renderiza un snapshot del modelo USDZ al vuelo y lo guarda en disco
        if let renderedImage = renderSnapshot(from: object.modelURL) {
            if let jpegData = renderedImage.jpegData(compressionQuality: 0.8) {
                try? jpegData.write(to: previewURL)
            }
            return renderedImage
        }
        
        // Fallback: si guardas un snapshot inicial en la carpeta de capturas
        return nil
    }
    
    // MARK: - Snapshot Generator para USDZ
    private func renderSnapshot(from modelURL: URL) -> UIImage? {
        
        guard let scene = try? SCNScene(url: modelURL, options: nil) else { return nil }
        
        let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
        renderer.scene = scene
        renderer.autoenablesDefaultLighting = true
        
        let size = CGSize(width: 512, height: 512)
        return renderer.snapshot(atTime: 0, with: size, antialiasingMode: .multisampling4X)
    }
}
