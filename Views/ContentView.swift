// Views/ContentView.swift
// Root view managing navigation between app states

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ScanViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(hex: "#0A0E1A")
                    .ignoresSafeArea(.all)

                Group {
                    switch viewModel.appState {
                    case .home:
                        HomeView()
                            .transition(.asymmetric(
                                insertion: .opacity,
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    case .scanning:
                        ScanningView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .opacity
                            ))
                    case .results:
                        ResultsView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    case .recovering:
                        RecoveringView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .opacity
                            ))
                    case .complete:
                        RecoveryCompleteView()
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.9).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: viewModel.appState)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea(.all)
        .alert("Storage Access Required", isPresented: $viewModel.isShowingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please grant access to Photos and Contacts to scan for recoverable files.")
        }
        .onAppear {
            viewModel.requestPermissions()
        }
    }
}
