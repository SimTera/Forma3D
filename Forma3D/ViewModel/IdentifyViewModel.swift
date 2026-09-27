//
//  IdentifyViewModel.swift
//  Forma3D
//
//  Created by Victor Munera on 27/09/2026.
//

import SwiftUI
import SwiftData
import UIKit
import OSLog

@MainActor
@Observable
final class IdentifyViewModel {
    
    // MARK: - Properties
    let arViewModel: ARObjectDetectionViewModel
    
    var identifiedObject: ScannedObject?
    var triggerScan = false
    
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    
    // MARK: - Computed UI State
    var isProcessing: Bool {
        arViewModel.isProcessing
    }
    
    var isReadyToScan: Bool {
        arViewModel.isReadyToScan
    }
    
    var statusColor: Color {
        if identifiedObject != nil {
            return .blue
        }
        return isReadyToScan ? .green : .yellow
    }
    
    func statusText(totalReferences: Int) -> String {
        if identifiedObject != nil {
            return "Objeto fijado"
        }
        return "\(arViewModel.trackingStatusDescription) (\(totalReferences) referencias)"
    }
    
    var buttonTitle: String {
        if isProcessing {
            return "Analizando figura..."
        }
        if !isReadyToScan {
            return arViewModel.trackingStatusDescription
        }
        return "Identificar figura"
    }
    
    // MARK: - Init
    init(arViewModel: ARObjectDetectionViewModel? = nil) {
        self.arViewModel = arViewModel ?? ARObjectDetectionViewModel()
        self.feedbackGenerator.prepare()
        
        self.arViewModel.onObjectDetected = { [weak self] detected in
            guard let self else { return }
            self.identifiedObject = detected
            self.feedbackGenerator.notificationOccurred(.success)
        }
    }
    
    // MARK: - User Actions
    func updateCandidates(_ objects: [ScannedObject]) {
        arViewModel.scannedObjects = objects
    }
    
    func requestIdentification() {
        guard isReadyToScan else { return }
        triggerScan = true
    }
    
    func resetIdentification() {
        identifiedObject = nil
    }
}
