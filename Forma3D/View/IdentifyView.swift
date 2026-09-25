//
//  IdentifyView.swift
//  Forma3D
//
//  Created by Victor Munera on 20/09/2026.
//
//  Vista de identificación de objetos (Placeholder para ARKit/Vision)
//

import SwiftUI
import SwiftData

struct IdentifyView: View {
    // Consulta reactiva de todos los objetos escaneados en SwiftData
    @Query private var scannedObjects: [ScannedObject]
    @State private var identifiedObject: ScannedObject?
    @State private var isScanningActive: Bool = true

    var body: some View {
        ZStack {
            // Fondo con el visor de RealityKit
            if scannedObjects.isEmpty {
                ContentUnavailableView(
                    "Sin objetos para reconocer",
                    systemImage: "cube.transparent",
                    description: Text("Escanea y guarda primero un objeto para poder identificarlo.")
                )
            } else {
                ARObjectDetectionView(scannedObjects: scannedObjects) { detected in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        self.identifiedObject = detected
                    }
                }
                .ignoresSafeArea()
                
                // Capa de Interfaz y Guías (HUD)
                overlayHUD
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: identifiedObject)
        .navigationTitle("Identificar")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    // MARK: - Overlay HUD
    private var overlayHUD: some View {
        VStack {
            // Indicador superior de estado
            topStatusBar
                .padding(.top, 16)

            Spacer()

            // Retícula de puntería central (solo si no hay objeto detectado aún)
            if identifiedObject == nil {
                centerReticle
                Spacer()
            }

            // Tarjeta inferior con el resultado o guía
            bottomCard
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
    }

    // MARK: - Subviews
    private var topStatusBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(identifiedObject == nil ? Color.green : Color.blue)
                .frame(width: 8, height: 8)
                .opacity(0.8)

            Text(identifiedObject == nil ? "Buscando (\(scannedObjects.count) referencias)..." : "Objeto fijado")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var centerReticle: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]))
                .frame(width: 220, height: 220)

            Image(systemName: "viewfinder")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    @ViewBuilder
    private var bottomCard: some View {
        if let object = identifiedObject {
            // Tarjeta de objeto detectado
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Objeto detectado")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                            .textCase(.uppercase)

                        Text(object.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Button {
                        withAnimation {
                            identifiedObject = nil
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }

                Divider().background(Color.white.opacity(0.15))

                HStack {
                    Label(object.formattedDate, systemImage: "calendar")
                    Spacer()
                    Label(object.formattedFileSize, systemImage: "internaldrive")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            }
            .padding(18)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            // Guía de uso mientras escanea el entorno
            HStack(spacing: 10) {
                Image(systemName: "camera.metering.matrix")
                    .foregroundStyle(.white.opacity(0.8))
                Text("Apunta la cámara hacia el objeto real que escaneaste")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    NavigationStack {
        IdentifyView()
    }
}

