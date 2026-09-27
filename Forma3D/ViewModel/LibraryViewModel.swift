//
//  LibraryViewModel.swift
//  Forma3D
//
//  Created by Victor Munera on 27/09/2026.
//

import Foundation
import SwiftData
import OSLog

// MARK: - Dedicated Logger Extension
extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.forma3d.app"
    static let library = Logger(subsystem: subsystem, category: "Library")
}

@MainActor
@Observable
final class LibraryViewModel {
    
    // MARK: - Properties
    private let fileManager: FileManager
    
    // MARK: - Init
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    // MARK: - Business Logic
    
    /// Elimina un conjunto de objetos tanto del almacén de SwiftData como sus ficheros físicos en disco.
    func deleteObjects(at offsets: IndexSet, from objects: [ScannedObject], context: ModelContext) {
        for index in offsets {
            guard objects.indices.contains(index) else { continue }
            let object = objects[index]
            deletePhysicalFiles(for: object)
            context.delete(object)
            Logger.library.notice("ScannedObject eliminado de SwiftData: \(object.name, privacy: .public)")
        }
        
        do {
            try context.save()
        } catch {
            Logger.library.error("Error al persistir cambios tras borrado: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    /// Elimina un objeto específico directamente (por ejemplo desde menú contextual o botón de acción).
    func deleteObject(_ object: ScannedObject, context: ModelContext) {
        deletePhysicalFiles(for: object)
        context.delete(object)
        
        do {
            try context.save()
            Logger.library.notice("Objeto eliminado con éxito: \(object.name, privacy: .public)")
        } catch {
            Logger.library.error("Error al guardar tras eliminar objeto: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    // MARK: - Private Helpers
    
    private func deletePhysicalFiles(for object: ScannedObject) {
        let urlsToDelete: [URL?] = [
            object.modelURL,
            object.arObjectURL,
            object.thumbnailURL
        ]
        
        for case let url? in urlsToDelete {
            guard fileManager.fileExists(atPath: url.path()) else { continue }
            do {
                try fileManager.removeItem(at: url)
                Logger.library.debug("Fichero eliminado de disco: \(url.lastPathComponent, privacy: .public)")
            } catch {
                Logger.library.error("No se pudo eliminar el fichero \(url.lastPathComponent): \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    // MARK: - Business Logic
    
    /// Objeto que está esperando confirmación de borrado
    var objectPendingDeletion: ScannedObject?
    
    /// Elimina una lista de objetos tanto de SwiftData como de disco
    func deleteObjects(_ objects: [ScannedObject], context: ModelContext) {
        for object in objects {
            deletePhysicalFiles(for: object)
            context.delete(object)
            Logger.library.notice("Objeto eliminado: \(object.name, privacy: .public)")
        }
        
        do {
            try context.save()
        } catch {
            Logger.library.error("Error al persistir tras eliminar: \(error.localizedDescription, privacy: .public)")
        }
    }
}
