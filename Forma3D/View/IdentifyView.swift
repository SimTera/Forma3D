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
    @Environment(\.scenePhase) private var scenePhase
    @Query private var scannedObjects: [ScannedObject]
    
    @State private var viewModel = IdentifyViewModel()

    var body: some View {
        ZStack {
            if scannedObjects.isEmpty {
                emptyStateView
            } else {
                ARObjectDetectionView(
                    viewModel: viewModel.arViewModel,
                    isActive: scenePhase == .active,
                    triggerScan: $viewModel.triggerScan
                )
                .ignoresSafeArea()

                overlayHUD
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.identifiedObject)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isReadyToScan)
        .navigationTitle("Identificar")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .task(id: scannedObjects) {
            viewModel.updateCandidates(scannedObjects)
        }
    }

    // MARK: - Subviews
    private var emptyStateView: some View {
        ContentUnavailableView(
            "Sin objetos para reconocer",
            systemImage: "cube.transparent",
            description: Text("Escanea y guarda primero un objeto en la biblioteca para poder identificarlo.")
        )
    }

    private var overlayHUD: some View {
        VStack {
            topStatusBar
                .padding(.top, 16)

            Spacer()

            if viewModel.identifiedObject == nil {
                centerReticle
                Spacer()
            }

            bottomCard
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
    }

    private var topStatusBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.statusColor)
                .frame(width: 8, height: 8)

            Text(viewModel.statusText(totalReferences: scannedObjects.count))
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
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height) * 0.72

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        viewModel.isReadyToScan ? Color.white.opacity(0.5) : Color.yellow.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [10, 8])
                    )
                    .frame(width: side, height: side)

                Image(systemName: "viewfinder")
                    .font(.system(size: 44, weight: .ultraLight))
                    .foregroundStyle(viewModel.isReadyToScan ? Color.white.opacity(0.6) : Color.yellow.opacity(0.4))

                if viewModel.isProcessing {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.3)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 320)
    }

    @ViewBuilder
    private var bottomCard: some View {
        if let object = viewModel.identifiedObject {
            detectedObjectCard(for: object)
        } else {
            identifyActionButton
        }
    }

    private func detectedObjectCard(for object: ScannedObject) -> some View {
        VStack(spacing: 12) {
            NavigationLink {
                ObjectDetailView(object: object)
            } label: {
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

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(8)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
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
            }
            .buttonStyle(.plain)

            Button {
                viewModel.resetIdentification()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Escanear otra figura")
                }
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var identifyActionButton: some View {
        Button {
            viewModel.requestIdentification()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "viewfinder.circle.fill")
                    .font(.title3)
                Text(viewModel.buttonTitle)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(viewModel.isReadyToScan ? Color.orange : Color.gray.opacity(0.5))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: viewModel.isReadyToScan ? .orange.opacity(0.3) : .clear, radius: 8, y: 4)
        }
        .disabled(!viewModel.isReadyToScan)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        IdentifyView()
            .modelContainer(for: ScannedObject.self, inMemory: true)
    }
}
