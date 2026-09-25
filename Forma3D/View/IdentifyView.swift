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

    var body: some View {
        ZStack(alignment: .bottom) {
            // Fondo con el visor de RealityKit
            if scannedObjects.isEmpty {
                ContentUnavailableView(
                    "Sin objetos para reconocer",
                    systemImage: "cube.transparent",
                    description: Text("Escanea y guarda primero un objeto para poder identificarlo.")
                )
            } else {
                ARObjectDetectionView(scannedObjects: scannedObjects) { detected in
                    identifiedObject = detected
                }
                .ignoresSafeArea()
            }

            // HUD flotante al detectar un objeto
            if let identifiedObject {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Objeto detectado")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                        .textCase(.uppercase)

                    Text(identifiedObject.name)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Escaneado el \(identifiedObject.formattedDate)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: identifiedObject)
        .navigationTitle("Identificar")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    NavigationStack {
        IdentifyView()
    }
}

