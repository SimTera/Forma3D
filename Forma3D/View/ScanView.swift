//
//  ScanView.swift
//  Forma3D
//
//  Created by Victor Munera on 20/09/2026.
//
//  Vista de escaneo 3D (Placeholder para Object Capture API)
//

import SwiftUI
import RealityKit
import SwiftData

struct ScanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = ScanViewModel()
    @State private var objectName = ""
    @State private var showSaveDialog = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let session = viewModel.session, !viewModel.isReconstructing {
                // Vista estándar de Apple con guías de escaneo y feedback en pantalla
                ObjectCaptureView(session: session)
                    .ignoresSafeArea()
                
                // Controles superpuestos cuando el usuario completa la captura
                if session.userCompletedScanPass {
                    VStack {
                        Spacer()
                        
                        Button {
                            showSaveDialog = true
                        } label: {
                            Label("Finalizar y Modelar", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .padding(.horizontal, 24)
                                .padding(.bottom, 20)
                        }
                    }
                }
            } else if viewModel.isReconstructing {
                // Pantalla de procesamiento fotogramétrico
                reconstructionOverlay
            } else {
                ProgressView("Iniciando escáner...")
                    .foregroundStyle(.white)
            }
        }
        .navigationTitle("Escanear")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.startNewSession()
        }
        .alert("Guardar Escaneo", isPresented: $showSaveDialog) {
            TextField("Nombre del objeto", text: $objectName)
            Button("Procesar") {
                Task {
                    await viewModel.finishScanAndProcess(name: objectName, modelContext: modelContext)
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Introduce un nombre descriptivo para identificarlo más adelante.")
        }
        .onChange(of: viewModel.scanCompleted) { _, completed in
            if completed {
                dismiss()
            }
        }
        .alert("Aviso", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("Entendido") {
                viewModel.errorMessage = nil
                dismiss()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Reconstrucción UI
    private var reconstructionOverlay: some View {
        VStack(spacing: 24) {
            ProgressView(value: viewModel.reconstructionProgress, total: 1.0)
                .progressViewStyle(.circular)
                .scaleEffect(2.0)
                .tint(.cyan)
            
            VStack(spacing: 8) {
                Text("Generando modelo 3D...")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                Text("\(Int(viewModel.reconstructionProgress * 100))%")
                    .font(.headline)
                    .foregroundStyle(.cyan)
                
                Text("Analizando nubes de puntos y texturas volumétricas.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScanView()
            .modelContainer(for: ScannedObject.self, inMemory: true)
    }
}

