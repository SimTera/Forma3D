//
//  ScanViewModel.swift
//  Forma3D
//
//  Created by Victor Munera on 25/09/2026.
//

import SwiftUI
import RealityKit
import SwiftData
import ARKit

@MainActor
@Observable
final class ScanViewModel {
    // MARK: - State
    var session: ObjectCaptureSession?
    var isReconstructing = false
    var reconstructionProgress: Double = 0.0
    var scanCompleted = false
    var errorMessage: String?
    
    // Directorios temporales de trabajo
    private var scanFolderURL: URL?
    private var imagesFolderURL: URL?
    
    // MARK: - Lifecycle
    func startNewSession() {
        guard ObjectCaptureSession.isSupported else {
            errorMessage = "Object Capture no está soportado en este dispositivo (se requiere sensor LiDAR)."
            return
        }
        
        // 1. Crear carpeta temporal para los fotogramas del escaneo
        let tempDir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let imagesDir = tempDir.appending(path: "Images")
        
        do {
            try FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
            self.scanFolderURL = tempDir
            self.imagesFolderURL = imagesDir
            
            // 2. Iniciar sesión nativa de RealityKit
            var configuration = ObjectCaptureSession.Configuration()
            configuration.checkpointDirectory = tempDir.appending(path: "Snapshots")
            
            let newSession = ObjectCaptureSession()
            newSession.start(imagesDirectory: imagesDir, configuration: configuration)
            self.session = newSession
        } catch {
            errorMessage = "Error al inicializar sesión: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Reconstruction & Persistence
    func finishScanAndProcess(name: String, modelContext: ModelContext) async {
        guard let session, let imagesFolderURL, let scanFolderURL else { return }
        
        // Finalizar la captura
        session.finish()
        isReconstructing = true
        
        let objectID = UUID()
        let relativeUSDZ = "scans/\(objectID.uuidString).usdz"
        let relativeARObject = "scans/\(objectID.uuidString).arobject"
        
        guard let appSupport = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else {
            errorMessage = "No se pudo acceder a Application Support."
            isReconstructing = false
            return
        }
        
        let scansDir = appSupport.appending(path: "scans")
        try? FileManager.default.createDirectory(at: scansDir, withIntermediateDirectories: true)
        
        let finalModelURL = appSupport.appending(path: relativeUSDZ)
        let finalARObjectURL = appSupport.appending(path: relativeARObject)
        
        do {
            // 1. Fotogrametría / Reconstrucción del USDZ
            var config = PhotogrammetrySession.Configuration()
            config.featureSensitivity = .normal
            
            let photogrammetrySession = try PhotogrammetrySession(
                input: imagesFolderURL,
                configuration: config
            )
            
            try photogrammetrySession.process(requests: [.modelFile(url: finalModelURL)])
            
            // Monitorizar outputs del procesamiento fotogramétrico
            processingLoop: for try await output in photogrammetrySession.outputs {
                switch output {
                case .requestProgress(let request, let fractionComplete):
                    if case .modelFile = request {
                        self.reconstructionProgress = fractionComplete
                    }
                    
                case .requestComplete(let request, let result):
                    if case .modelFile = request, case .modelFile(let url) = result {
                        print("✅ Modelo USDZ generado correctamente en: \(url.path)")
                    }
                    
                case .inputComplete:
                    print("📸 Input de imágenes procesado")
                    
                case .processingComplete:
                    print("✅ Procesamiento fotogramétrico completado")
                    break processingLoop
                    
                case .requestError(let request, let error):
                    if case .modelFile = request {
                        throw error
                    }
                    
                case .processingCancelled:
                    print("⚠️ Procesamiento cancelado")
                    break processingLoop
                    
                case .invalidSample(id: let id, reason: let reason):
                    print("⚠️ Muestra inválida [\(id)]: \(reason)")
                    
                case .skippedSample(id: let id):
                    print("⚠️ Muestra omitida [\(id)]")
                    
                case .automaticDownsampling:
                    print("ℹ️ Reducción de resolución automática")
                    
                case .requestProgressInfo:
                    break
                    
                case .stitchingIncomplete:
                    print("⚠️ Reconstrucción incompleta en ciertas áreas")
                    
                @unknown default:
                    break
                }
            }
            
            // 1. Guardar miniatura de referencia para el fallback de Vision (iOS 18–26)
            let previewURL = finalModelURL.deletingPathExtension().appendingPathExtension("jpg")
            if let firstImage = try? FileManager.default.contentsOfDirectory(at: imagesFolderURL, includingPropertiesForKeys: nil)
                .first(where: { $0.pathExtension.lowercased() == "jpg" || $0.pathExtension.lowercased() == "heic" }) {
                try? FileManager.default.copyItem(at: firstImage, to: previewURL)
            }
            
            // 2. Persistencia del ancla ARObject
            if !FileManager.default.fileExists(atPath: finalARObjectURL.path(percentEncoded: false)) {
                FileManager.default.createFile(
                    atPath: finalARObjectURL.path(percentEncoded: false),
                    contents: Data(),
                    attributes: nil
                )
            }
            
            // 3. Tamaño en bytes del archivo USDZ generado
            let fileAttributes = try FileManager.default.attributesOfItem(
                atPath: finalModelURL.path(percentEncoded: false)
            )
            let fileSizeBytes = fileAttributes[.size] as? Int64 ?? 0
            
            // 4. Guardar entidad en SwiftData
            let newObject = ScannedObject(
                id: objectID,
                name: name.isEmpty ? "Objeto 3D" : name,
                relativeModelPath: relativeUSDZ,
                relativeARObjectPath: relativeARObject,
                fileSizeBytes: fileSizeBytes
            )
            await MainActor.run {
                modelContext.insert(newObject)
                do {
                    try modelContext.save()
                    print("💾 Objeto guardado con éxito en SwiftData: \(newObject.name)")
                } catch {
                    print("❌ Error guardando en SwiftData: \(error)")
                }
                
                self.isReconstructing = false
                self.scanCompleted = true
            }
            
            // 5. Limpieza de temporales
            try? FileManager.default.removeItem(at: scanFolderURL)
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Fallo en la reconstrucción: \(error.localizedDescription)"
                self.isReconstructing = false
            }
        }
    }
}
