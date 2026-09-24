//
//  MainMenuView.swift
//  3D Scanner Module
//
//  Vista principal del menú con navegación a las 3 funcionalidades principales
//  Utiliza Liquid Glass para un diseño moderno y fluido
//

import SwiftUI

@MainActor
struct MainMenuView: View {
    // MARK: - State Properties
    @State private var showScanView = false
    @State private var showLibraryView = false
    @State private var showIdentifyView = false
    @State private var animateTitle = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo animado con gradiente
                backgroundGradient
                
                // Contenido principal
                VStack(spacing: 0) {
                    // Header con título
                    headerView
                    
                    Spacer()
                    
                    // Botones principales con Liquid Glass
                    buttonsContainer
                    
                    Spacer()
                    
                    // Footer con información de versión
                    footerView
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationDestination(isPresented: $showScanView) {
                ScanView()
            }
            .navigationDestination(isPresented: $showLibraryView) {
                LibraryView()
            }
            .navigationDestination(isPresented: $showIdentifyView) {
                IdentifyView()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animateTitle = true
            }
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.1, blue: 0.2),
                Color(red: 0.1, green: 0.05, blue: 0.15),
                Color(red: 0.05, green: 0.05, blue: 0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 12) {
            // Icono principal
            Image(systemName: "cube.transparent.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, value: animateTitle)
                .shadow(color: .cyan.opacity(0.5), radius: 20, x: 0, y: 0)
            
            // Título
            Text("3D Scanner")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                .scaleEffect(animateTitle ? 1.0 : 0.8)
                .opacity(animateTitle ? 1.0 : 0.0)
            
            // Subtítulo
            Text("Escanea, Guarda e Identifica")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .scaleEffect(animateTitle ? 1.0 : 0.8)
                .opacity(animateTitle ? 1.0 : 0.0)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Buttons Container
    private var buttonsContainer: some View {
        VStack(spacing: 24) {
            // Botón SCAN
            CustomButton(
                title: "SCAN",
                icon: "viewfinder.circle.fill",
                gradientColors: [.blue, .cyan]
            ) {
                showScanView = true
            }
            .transition(.scale.combined(with: .opacity))
            
            // Botón LIBRARY
            CustomButton(
                title: "LIBRARY",
                icon: "square.stack.3d.up.fill",
                gradientColors: [.purple, .pink]
            ) {
                showLibraryView = true
            }
            .transition(.scale.combined(with: .opacity))
            
            // Botón IDENTIFY
            CustomButton(
                title: "IDENTIFY",
                icon: "sparkles.rectangle.stack.fill",
                gradientColors: [.orange, .red]
            ) {
                showIdentifyView = true
            }
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    // MARK: - Footer
    private var footerView: some View {
        VStack(spacing: 8) {
            Text("v1.0.0 Beta")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            
            Text("iOS 26+ • Swift 6")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Preview
//#Preview {
//    MainMenuView()
//        .modelContainer(for: ScannedObject.self, inMemory: true)
//}
