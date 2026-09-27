//
//  ObjectRecognitionService.swift
//  Forma3D
//
//  Created by Victor Munera on 26/09/2026.
//

import UIKit
import Vision
import QuickLookThumbnailing
//import CoreImage
//import SceneKit

@MainActor
final class ObjectRecognitionService {
    static let shared = ObjectRecognitionService()
    
    // Umbral de distancia de Vision:
        // 0.0 - 0.4: Casi idéntico pixel a pixel (misma foto)
        // 0.5 - 0.72: Mismo objeto tridimensional bajo diferente luz y ángulo
        // > 0.8: Objetos completamente distintos
        private let matchDistanceThreshold: Float = 0.72
    
    private init() {}
    
    /// Compara el frame actual de la cámara contra la lista de objetos escaneados
    func identifyObject(
        from pixelBuffer: CVPixelBuffer,
        candidates: [ScannedObject]
    ) async -> ScannedObject? {
        guard !candidates.isEmpty else {
            print("⚠️ No hay objetos candidatos en la biblioteca.")
            return nil
        }
        
        // 1. Extraer la huella visual del fotograma actual de la cámara
        guard let queryPrint = computeFeaturePrint(from: pixelBuffer) else {
            print("❌ No se pudo extraer la huella visual del fotograma de cámara.")
            return nil
        }
        
        var bestMatch: ScannedObject?
        var minimumDistance: Float = Float.greatestFiniteMagnitude
        
        // 2. Comparar contra cada candidato guardado
        for candidate in candidates {
            // Buscamos la imagen de referencia (snapshot o primera foto del escaneo)
            guard let referenceImage = await loadReferenceImage(for: candidate),
                  let candidatePrint = computeFeaturePrint(from: referenceImage) else {
                print("⚠️ No se pudo obtener imagen de referencia para: \(candidate.name)")
                continue
            }
            
            var distance: Float = 0
            do {
                try queryPrint.computeDistance(&distance, to: candidatePrint)
                print("📊 Distancia con '\(candidate.name)': \(distance) (Umbral: \(matchDistanceThreshold))")
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
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        do {
            try handler.perform([request])
            return request.results?.first as? VNFeaturePrintObservation
        } catch {
            print("Error en FeaturePrint de cámara: \(error)")
            return nil
        }
    }
    
    private func computeFeaturePrint(from image: UIImage) -> VNFeaturePrintObservation? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNGenerateImageFeaturePrintRequest()
        request.imageCropAndScaleOption = .centerCrop
        
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        do {
            try handler.perform([request])
            return request.results?.first as? VNFeaturePrintObservation
        } catch {
            print("Error en FeaturePrint de imagen: \(error)")
            return nil
        }
    }
    
    // MARK: - Reference Image Loader
    private func loadReferenceImage(for object: ScannedObject) async -> UIImage? {
        // Intentar cargar la miniatura persistida junto al USDZ
        let previewURL = object.modelURL.deletingPathExtension().appendingPathExtension("jpg")
        
        // 1. Si ya tiene el JPG guardado en disco, lo usa
        if let data = try? Data(contentsOf: previewURL), let img = UIImage(data: data) {
            return img
        }
        
        // 2. Generar miniatura nativa del USDZ con QuickLookThumbnailing
        let size = CGSize(width: 512, height: 512)
        let request = QLThumbnailGenerator.Request(
            fileAt: object.modelURL,
            size: size,
            scale: UIScreen.main.scale,
            representationTypes: .all
        )
        
        do {
            let thumbnail = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            let uiImage = thumbnail.uiImage
            if let jpegData = uiImage.jpegData(compressionQuality: 0.85) {
                try? jpegData.write(to: previewURL)
            }
            return uiImage
        } catch {
            print("❌ Error generando thumbnail para USDZ: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Snapshot Generator para USDZ
//    private func renderSnapshot(from modelURL: URL) -> UIImage? {
//        
//        guard let scene = try? SCNScene(url: modelURL, options: nil) else { return nil }
//        
//        let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
//        renderer.scene = scene
//        renderer.autoenablesDefaultLighting = true
//        
//        let size = CGSize(width: 512, height: 512)
//        return renderer.snapshot(atTime: 0, with: size, antialiasingMode: .multisampling4X)
//    }
}
