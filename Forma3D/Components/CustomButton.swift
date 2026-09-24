//
//  CustomButton.swift
//  3D Scanner Module
//
//  Botón personalizado reutilizable con efecto Liquid Glass
//  Diseñado para el menú principal de la aplicación
//

import SwiftUI

/// Botón personalizado con efecto Liquid Glass y diseño moderno
struct CustomButton: View {
    // MARK: - Properties
    let title: String
    let icon: String
    let gradientColors: [Color]
    let action: () -> Void
    
    // Estados internos
    @State private var isPressed = false
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            action()
        }) {
            buttonContent
        }
        .buttonStyle(GlassButtonInteractionStyle(isPressed: $isPressed))
    }
    
    // MARK: - Button Content
    private var buttonContent: some View {
        VStack(spacing: 16) {
            // Icono con efecto
            Image(systemName: icon)
                .font(.system(size: 56, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
            
            // Título
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background {
            // Fondo con gradiente
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.9)
        }
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
        .shadow(color: gradientColors.first?.opacity(0.4) ?? .clear, radius: 15, x: 0, y: 8)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - Custom Button Style
/// Estilo personalizado que detecta presionado para animaciones
struct GlassButtonInteractionStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        // Fondo simulado para ver el efecto glass
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
