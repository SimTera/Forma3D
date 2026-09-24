//
//  IdentifyView.swift
//  3D Scanner Module
//
//  Vista de identificación de objetos (Placeholder para ARKit/Vision)
//

import SwiftUI

@MainActor
struct IdentifyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.orange)
                
                Text("Vista de Identificación")
                    .font(.title)
                    .foregroundStyle(.white)
                
                Text("ARKit y Vision Framework se integrarán aquí")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .navigationTitle("Identificar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        IdentifyView()
    }
}
