//
//  ScannedObject.swift
//  3D Scanner Module
//
//  Modelo de datos para objetos 3D escaneados
//  Utiliza SwiftData para persistencia
//

import Foundation
import SwiftData

@Model
final class ScannedObject {
    /// Identificador único del objeto
    var id: UUID
    
    /// Nombre asignado por el usuario
    var name: String
    
    /// Fecha de escaneo
    var dateScanned: Date
    
    /// Ruta al archivo USDZ del modelo 3D
    var modelPath: String
    
    /// Ruta a la imagen miniatura (opcional)
    var thumbnailPath: String?
    
    /// Etiquetas para categorizar el objeto
    var tags: [String]
    
    /// Descripción adicional del objeto
    var objectDescription: String?
    
    /// Tamaño aproximado del objeto en MB
    var fileSize: Double
    
    init(
        id: UUID = UUID(),
        name: String,
        dateScanned: Date = Date(),
        modelPath: String,
        thumbnailPath: String? = nil,
        tags: [String] = [],
        objectDescription: String? = nil,
        fileSize: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.dateScanned = dateScanned
        self.modelPath = modelPath
        self.thumbnailPath = thumbnailPath
        self.tags = tags
        self.objectDescription = objectDescription
        self.fileSize = fileSize
    }
}

// MARK: - Computed Properties
extension ScannedObject {
    /// Formatea el tamaño del archivo para mostrar
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize * 1_000_000))
    }
    
    /// Formatea la fecha de escaneo
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dateScanned)
    }
}
