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
    
    private var scanFolderURL: URL?
    private var imagesFolderURL: URL?
    
    // MARK: - Lifecycle
    func startNewSession() {
        guard ObjectCaptureSession.isSupported else {
            errorMessage = "Object Capture no está soportado en este dispositivo (se requiere sensor LiDAR)."
            return
        }
        
        let tempDir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let imagesDir = tempDir.appending(path: "Images")
        
        do {
            try FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
            self.scanFolderURL = tempDir
            self.imagesFolderURL = imagesDir
            
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
        guard let currentSession = session,
              let imagesFolderURL = imagesFolderURL,
              let scanFolderURL = scanFolderURL else { return }
        
        // Terminar la captura sin llamar a cancel()
        currentSession.finish()
        self.session = nil
        self.isReconstructing = true
        
        let objectID = UUID()
        let relativeUSDZ = "scans/\(objectID.uuidString).usdz"
        let relativeARObject = "scans/\(objectID.uuidString).arobject"
        
        guard let appSupport = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else {
            self.errorMessage = "No se pudo acceder a Application Support."
            self.isReconstructing = false
            return
        }
        
        let scansDir = appSupport.appending(path: "scans")
        try? FileManager.default.createDirectory(at: scansDir, withIntermediateDirectories: true)
        
        let finalModelURL = appSupport.appending(path: relativeUSDZ)
        
        do {
            // Ejecución desacoplada del hilo principal
            try await runPhotogrammetry(
                inputFolder: imagesFolderURL,
                outputModelURL: finalModelURL
            )
            
            // Generar vista previa
            let previewURL = finalModelURL.deletingPathExtension().appendingPathExtension("jpg")
            if let firstImage = try? FileManager.default.contentsOfDirectory(at: imagesFolderURL, includingPropertiesForKeys: nil)
                .first(where: { $0.pathExtension.lowercased() == "jpg" || $0.pathExtension.lowercased() == "heic" }) {
                try? FileManager.default.copyItem(at: firstImage, to: previewURL)
            }
            
            // Atributos de archivo
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: finalModelURL.path(percentEncoded: false))
            let fileSizeBytes = fileAttributes[.size] as? Int64 ?? 0
            
            // Persistencia en SwiftData
            let newObject = ScannedObject(
                id: objectID,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Objeto 3D" : name,
                relativeModelPath: relativeUSDZ,
                relativeARObjectPath: relativeARObject,
                fileSizeBytes: fileSizeBytes
            )
            
            modelContext.insert(newObject)
            try modelContext.save()
            
            // Limpieza
            try? FileManager.default.removeItem(at: scanFolderURL)
            
            self.isReconstructing = false
            self.scanCompleted = true
            
        } catch {
            self.errorMessage = "Fallo en la reconstrucción: \(error.localizedDescription)"
            self.isReconstructing = false
            try? FileManager.default.removeItem(at: scanFolderURL)
        }
    }
    
    // MARK: - Background Processing
    private func runPhotogrammetry(inputFolder: URL, outputModelURL: URL) async throws {
        var config = PhotogrammetrySession.Configuration()
        config.featureSensitivity = .normal
        
        let photogrammetrySession = try PhotogrammetrySession(
            input: inputFolder,
            configuration: config
        )
        
        try photogrammetrySession.process(requests: [.modelFile(url: outputModelURL)])
        
        for try await output in photogrammetrySession.outputs {
            switch output {
            case .requestProgress(let request, let fractionComplete):
                if case .modelFile = request {
                    self.reconstructionProgress = fractionComplete
                }
            case .requestError(let request, let error):
                if case .modelFile = request {
                    throw error
                }
            case .processingComplete, .processingCancelled:
                return
            default:
                break
            }
        }
    }
}
