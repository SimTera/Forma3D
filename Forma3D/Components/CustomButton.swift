//
//  CustomButton.swift
//  Forma3D
//
//  Created by Victor Munera on 20/09/2026.
//
//  Botón personalizado reutilizable con efecto Liquid Glass
//  Diseñado para el menú principal de la aplicación
//

import SwiftUI

/// Botón con diseño estilizado y respuesta táctil para el menú principal
struct CustomButton: View {
    // MARK: - Properties
    let title: String
    let icon: String
    let gradientColors: [Color]
    let action: () -> Void
    
    // MARK: - Body
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 56, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
        }
        .buttonStyle(LiquidGlassButtonStyle(gradientColors: gradientColors))
        // Feedback háptico nativo y declarativo de SwiftUI
        .sensoryFeedback(.impact(weight: .medium), trigger: true) { _, _ in true }    }
}

// MARK: - Reusable Button Style
/// Encapsula el fondo de cristal, el gradiente, la escala y la animación al presionar
struct LiquidGlassButtonStyle: ButtonStyle {
    let gradientColors: [Color]
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                ZStack {
                    // Capa de gradiente base
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(0.85)
                    
                    // Capa de vidrio esmerilado real
                    Rectangle()
                        .fill(.ultraThinMaterial)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                // Borde sutil reflectante estilo vidrio
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: (gradientColors.first ?? .clear).opacity(0.35),
                radius: 14,
                x: 0,
                y: 8
            )
            // Reacción a la pulsación directa
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        // Fondo para ver el efecto de material
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 24) {
            CustomButton(
                title: "SCAN",
                icon: "viewfinder.circle.fill",
                gradientColors: [.blue, .cyan]
            ) {
                print("Scan pressed")
            }
            
            CustomButton(
                title: "LIBRARY",
                icon: "square.stack.3d.up.fill",
                gradientColors: [.purple, .pink]
            ) {
                print("Library pressed")
            }
            
            CustomButton(
                title: "IDENTIFY",
                icon: "sparkles.rectangle.stack.fill",
                gradientColors: [.orange, .red]
            ) {
                print("Identify pressed")
            }
        }
        .padding(24)
    }
}
