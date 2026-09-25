//
//  MainMenuView.swift
//  Forma3D
//
//  Created by Victor Munera on 20/09/2026.
//
//  Vista principal del menú con navegación tipada a las 3 funcionalidades
//

import SwiftUI

// MARK: - Navigation Destinations
enum AppDestination: Hashable {
    case scan
    case library
    case identify
}

struct MainMenuView: View {
    // MARK: - Navigation State
    @State private var navigationPath = NavigationPath()
    @State private var animateHeader = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                backgroundGradient
                
                VStack(spacing: 0) {
                    headerView
                    
                    Spacer()
                    
                    buttonsContainer
                    
                    Spacer()
                    
                    footerView
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            // Navegación tipada moderna centralizada
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .scan:
                    ScanView()
                case .library:
                    LibraryView()
                case .identify:
                    IdentifyView()
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                animateHeader = true
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
            Image(systemName: "cube.transparent.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, value: animateHeader)
                .shadow(color: .cyan.opacity(0.5), radius: 20, x: 0, y: 0)
            
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
            
            Text("Escanea, Guarda e Identifica")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .scaleEffect(animateHeader ? 1.0 : 0.85)
        .opacity(animateHeader ? 1.0 : 0.0)
        .padding(.top, 20)
    }
    
    // MARK: - Buttons Container
    private var buttonsContainer: some View {
        VStack(spacing: 24) {
            CustomButton(
                title: "SCAN",
                icon: "viewfinder.circle.fill",
                gradientColors: [.blue, .cyan]
            ) {
                navigationPath.append(AppDestination.scan)
            }
            
            CustomButton(
                title: "LIBRARY",
                icon: "square.stack.3d.up.fill",
                gradientColors: [.purple, .pink]
            ) {
                navigationPath.append(AppDestination.library)
            }
            
            CustomButton(
                title: "IDENTIFY",
                icon: "sparkles.rectangle.stack.fill",
                gradientColors: [.orange, .red]
            ) {
                navigationPath.append(AppDestination.identify)
            }
        }
    }
    
    // MARK: - Footer
    private var footerView: some View {
        VStack(spacing: 4) {
            Text("v1.0.0 Beta")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            
            Text("Swift 6 • RealityKit")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Preview
#Preview {
    MainMenuView()
}

