//
//  ScanView.swift
//  Forma3D
//
//  Created by Victor Munera on 20/09/2026.
//
//  Vista de escaneo 3D con ObjectCaptureView nativo de Apple
//  Gestiona el flujo completo: detección → captura → procesamiento
//

import SwiftUI
import RealityKit
import SwiftData

struct ScanView: View {
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var viewModel = ScanViewModel()
    @State private var objectName = ""
    @State private var showSaveDialog = false

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let session = viewModel.session, !viewModel.isReconstructing {
                // Vista nativa de Apple con guías AR y feedback en tiempo real
                ObjectCaptureView(session: session)
                    .ignoresSafeArea()
                
                // Controles contextuales según estado del escaneo
                VStack {
                    Spacer()
                    
                    bottomControls(for: session)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                }
                
            } else if viewModel.isReconstructing {
                // Pantalla de procesamiento fotogramétrico
                reconstructionOverlay
                
            } else {
                // Estado inicial: cargando sesión
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
        .onChange(of: viewModel.scanCompleted) { _, newValue in
            if newValue {
                dismiss()
            }
        }
        .alert(
            "Aviso",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("Entendido") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Bottom Controls
    /// Botones contextuales que cambian según el estado de ObjectCaptureSession
    @ViewBuilder
    private func bottomControls(for session: ObjectCaptureSession) -> some View {
        switch session.state {
        case .ready:
            // Estado inicial: Usuario enfoca el objeto y fija el bounding box
            actionButton(
                title: "Fijar Objeto",
                icon: "viewfinder",
                color: .blue
            ) {
                _ = session.startDetecting()
//                session.startDetecting()
            }
            
        case .detecting:
            // Ajustando caja delimitadora: Confirmar para iniciar la captura de fotos
            actionButton(
                title: "Iniciar Escaneo",
                icon: "record.circle",
                color: .green
            ) {
                session.startCapturing()
            }
            
        case .capturing:
            // Capturando fotos: Mostrar botón de finalizar cuando complete la órbita, opcion enriquecer modelo
            if session.userCompletedScanPass {
                VStack(spacing: 12) {
                    // Opción 1: Procesar con los datos actuales
                    actionButton(
                        title: "Finalizar y Procesar",
                        icon: "checkmark.circle.fill",
                        color: .blue
                    ) {
                        showSaveDialog = true
                    }
                    
                    // Opción 2: Continuar con otra altura (por ejemplo, a 45° desde arriba)
                    actionButton(
                        title: "Capturar otro ángulo (+ Detalle)",
                        icon: "arrow.triangle.2.circlepath",
                        color: .secondary
                    ) {
                        // Inicia una nueva pasada orbital sobre la misma sesión
                        session.beginNewScanPass()
                    }
                }
            } else {
                // Durante la captura, ObjectCaptureView dibuja su propia cúpula y flechas nativas
                EmptyView()
            }
            
        default:
            EmptyView()
        }
    }
    
    // MARK: - Action Button
    /// Botón de acción reutilizable con diseño consistente
    private func actionButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    // MARK: - Reconstruction Overlay
    /// Pantalla de procesamiento fotogramétrico con barra de progreso
    private var reconstructionOverlay: some View {
        VStack(spacing: 24) {
            ProgressView(value: viewModel.reconstructionProgress, total: 1.0)
                .progressViewStyle(.linear)
                .tint(.cyan)
                .scaleEffect(x: 1.0, y: 2.0)
            
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
        .padding()
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ScanView()
            .modelContainer(for: ScannedObject.self, inMemory: true)
    }
}
