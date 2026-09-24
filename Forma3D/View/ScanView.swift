//
//  ScanView.swift
//  3D Scanner Module
//
//  Vista de escaneo 3D (Placeholder para Object Capture API)
//

import SwiftUI

@MainActor
struct ScanView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Image(systemName: "viewfinder.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.blue)
                
                Text("Vista de Escaneo")
                    .font(.title)
                    .foregroundStyle(.white)
                
                Text("Object Capture API se integrará aquí")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .navigationTitle("Escanear")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ScanView()
    }
}
