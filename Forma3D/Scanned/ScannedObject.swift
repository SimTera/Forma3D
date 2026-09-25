//
//  ScannedObject.swift
//  Forma3D
//
//  Created by Victor Munera on 20/09/2026.
//
//  Modelo de datos para objetos 3D escaneados
//  Utiliza SwiftData para persistencia
//

import Foundation
import SwiftData

@Model
final class ScannedObject {
    // MARK: - Persistent Properties
    
    /// Identificador único con restricción de unicidad en base de datos
    /// Garantiza que no haya duplicados y permite upserts seguros
    @Attribute(.unique)
    var id: UUID
    
    /// Nombre del objeto asignado por el usuario
    var name: String
    
    /// Fecha y hora del escaneo
    var dateScanned: Date
    
    /// Ruta relativa al archivo USDZ (ej: "scans/UUID.usdz")
    /// Para visualización 3D en RealityKit
    var relativeModelPath: String
    
    /// Ruta relativa al archivo .arobject (ej: "scans/UUID.arobject")
    /// Para detección con ARKit (ARReferenceObject)
    var relativeARObjectPath: String
    
    /// Ruta relativa a la miniatura (opcional, ej: "thumbnails/UUID.jpg")
    var relativeThumbnailPath: String?
    
    /// Etiquetas para categorización y búsqueda
    var tags: [String]
    
    /// Descripción adicional del objeto
    var objectDescription: String?
    
    /// Tamaño exacto del archivo USDZ en bytes
    /// Almacenado como Int64 para precisión exacta con FileManager
    var fileSizeBytes: Int64

    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        name: String,
        dateScanned: Date = .now,
        relativeModelPath: String,
        relativeARObjectPath: String,
        relativeThumbnailPath: String? = nil,
        tags: [String] = [],
        objectDescription: String? = nil,
        fileSizeBytes: Int64 = 0
    ) {
        self.id = id
        self.name = name
        self.dateScanned = dateScanned
        self.relativeModelPath = relativeModelPath
        self.relativeARObjectPath = relativeARObjectPath
        self.relativeThumbnailPath = relativeThumbnailPath
        self.tags = tags
        self.objectDescription = objectDescription
        self.fileSizeBytes = fileSizeBytes
    }
}

// MARK: - URL Resolution
extension ScannedObject {
    
    /// Directorio base en Application Support asegurando su creación en disco
    private static var storageDirectory: URL {
        do {
            return try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true // Crea la carpeta en el sandbox si aún no existe
            )
        } catch {
            fatalError("No se pudo obtener o crear Application Support: \(error)")
        }
    }
    
    /// URL absoluta del modelo USDZ para RealityKit
    var modelURL: URL {
        Self.storageDirectory.appending(path: relativeModelPath)
    }
    
    /// URL absoluta del ARReferenceObject para detección en ARKit
    var arObjectURL: URL {
        Self.storageDirectory.appending(path: relativeARObjectPath)
    }
    
    /// URL absoluta de la miniatura si existe
    var thumbnailURL: URL? {
        guard let relativeThumbnailPath else { return nil }
        return Self.storageDirectory.appending(path: relativeThumbnailPath)
    }
}

// MARK: - Formatted Display
extension ScannedObject {
    
    /// Tamaño del archivo formateado para mostrar (ej: "25.5 MB")
    var formattedFileSize: String {
        fileSizeBytes.formatted(.byteCount(style: .file))
    }
    
    /// Fecha de escaneo formateada para mostrar (ej: "25 sep 2026, 14:30")
    var formattedDate: String {
        dateScanned.formatted(date: .abbreviated, time: .shortened)
    }
}
