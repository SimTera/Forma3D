//
//  ARObjectDetectionView.swift
//  Forma3D
//
//  Created by Victor Munera on 25/09/2026.
//

import SwiftUI
import RealityKit
import ARKit

@MainActor
struct ARObjectDetectionView: UIViewRepresentable {
    let viewModel: ARObjectDetectionViewModel
    let isActive: Bool
    @Binding var triggerScan: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        arView.renderOptions = [.disablePersonOcclusion, .disableFaceMesh]
        viewModel.setupView(arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if isActive {
            if !viewModel.isRunning {
                viewModel.resume()
            }
        } else {
            if viewModel.isRunning {
                viewModel.pause()
            }
        }

        if triggerScan {
            viewModel.identifyCurrentView()
            Task { @MainActor in
                triggerScan = false
            }
        }
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        coordinator.viewModel.tearDown()
    }

    @MainActor
    final class Coordinator {
        let viewModel: ARObjectDetectionViewModel
        init(viewModel: ARObjectDetectionViewModel) {
            self.viewModel = viewModel
        }
    }
}

// MARK: - Preview

#Preview("AR Object Detection View") {
    struct PreviewContainer: View {
        @State private var viewModel = ARObjectDetectionViewModel()
        @State private var triggerScan = false

        var body: some View {
            ZStack {
                ARObjectDetectionView(
                    viewModel: viewModel,
                    isActive: true,
                    triggerScan: $triggerScan
                )
                .ignoresSafeArea()

                VStack {
                    Spacer()

                    Button {
                        triggerScan = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "viewfinder.circle.fill")
                                .font(.title3)
                            Text("Identificar")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .shadow(color: .orange.opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.bottom, 32)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    return PreviewContainer()
}
