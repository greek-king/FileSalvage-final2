// Views/RecoveryViews.swift
import SwiftUI

// MARK: - Recovery Destination Sheet
struct RecoveryDestinationSheet: View {
    @EnvironmentObject var viewModel: ScanViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: "#0A0E1A").ignoresSafeArea(.all)
                VStack(spacing: 0) {
                    Text("Choose Destination")
                        .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                        .padding(.top, 28).padding(.bottom, 6)
                    Text("Where to save recovered files?")
                        .font(.system(size: 13)).foregroundColor(Color(hex: "#8892A4"))
                        .padding(.bottom, 28)

                    VStack(spacing: 12) {
                        DestinationOption(icon: "photo.on.rectangle.angled", title: "Camera Roll",
                                          subtitle: "Save photos & videos to Photos", color: "#4ECDC4") {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                viewModel.recoverSelected(to: .cameraRoll)
                            }
                        }
                        DestinationOption(icon: "folder.fill", title: "Files App",
                                          subtitle: "Save to 'Recovered Files' folder", color: "#3B82F6") {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyyMMdd_HHmmss"
                            let folderName = "Recovery_\(formatter.string(from: Date()))"
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                viewModel.recoverSelected(to: .files(folderName: folderName))
                            }
                        }
                        DestinationOption(icon: "icloud.and.arrow.up", title: "iCloud Drive",
                                          subtitle: "Sync recovered files to iCloud", color: "#A855F7") {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                viewModel.recoverSelected(to: .iCloud)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    Button(action: { dismiss() }) {
                        Text("Cancel").font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#8892A4"))
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, geo.safeAreaInsets.bottom + 16)
                }
            }
        }
        .ignoresSafeArea(.all)
    }
}

// MARK: - Destination Option
struct DestinationOption: View {
    let icon: String; let title: String; let subtitle: String; let color: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color(hex: color).opacity(0.15)).frame(width: 50, height: 50)
                    Image(systemName: icon).font(.system(size: 20)).foregroundColor(Color(hex: color))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    Text(subtitle).font(.system(size: 12)).foregroundColor(Color(hex: "#8892A4"))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#4B5563"))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#141928"))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: "#2A3352"), lineWidth: 1)))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Recovering View
struct RecoveringView: View {
    @EnvironmentObject var viewModel: ScanViewModel

    var progress: Double { viewModel.recoveryProgress?.percentage ?? 0 }

    var body: some View {
        GeometryReader { geo in
            let isSmall = geo.size.height < 700
            let orbSize: CGFloat = isSmall ? 160 : 200

            ZStack {
                Color(hex: "#0A0E1A").ignoresSafeArea(.all)

                VStack(spacing: 0) {
                    Spacer()

                    // Progress orb
                    ZStack {
                        Circle()
                            .strokeBorder(Color(hex: "#4ECDC4").opacity(0.15 + progress * 0.15), lineWidth: 2)
                            .frame(width: orbSize + 40, height: orbSize + 40)
                        Circle()
                            .strokeBorder(Color(hex: "#2A3352"), lineWidth: 1.5)
                            .frame(width: orbSize, height: orbSize)
                        ZStack {
                            Circle().fill(Color(hex: "#0D1F2D")).frame(width: orbSize - 4, height: orbSize - 4)
                            let innerSize: CGFloat = orbSize - 4
                            let fillHeight: CGFloat = innerSize * CGFloat(progress)
                            let offsetY: CGFloat = innerSize / 2 - innerSize / 2 * CGFloat(progress)
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#4ECDC4").opacity(0.3), Color(hex: "#4ECDC4").opacity(0.1)],
                                    startPoint: .bottom, endPoint: .top
                                ))
                                .frame(width: innerSize, height: fillHeight)
                                .offset(y: offsetY)
                                .clipShape(Circle())
                                .animation(.easeInOut(duration: 0.5), value: progress)

                            VStack(spacing: 4) {
                                Text("\(Int(progress * 100))%")
                                    .font(.system(size: isSmall ? 36 : 42, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Recovering")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(hex: "#4ECDC4")).tracking(1)
                            }
                        }
                        .clipShape(Circle()).frame(width: orbSize - 4, height: orbSize - 4)
                    }

                    Spacer().frame(height: isSmall ? 28 : 40)

                    if let prog = viewModel.recoveryProgress {
                        VStack(spacing: 10) {
                            Text("Recovering file...").font(.system(size: 13)).foregroundColor(Color(hex: "#6B7280"))
                            Text(prog.currentFile)
                                .font(.system(size: isSmall ? 14 : 16, weight: .semibold)).foregroundColor(.white)
                                .lineLimit(1).padding(.horizontal, 40)
                            Text("\(prog.completedCount) of \(prog.totalCount) files")
                                .font(.system(size: 12)).foregroundColor(Color(hex: "#8892A4"))
                            if !prog.failedFiles.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 11)).foregroundColor(Color(hex: "#F59E0B"))
                                    Text("\(prog.failedFiles.count) files could not be recovered")
                                        .font(.system(size: 11)).foregroundColor(Color(hex: "#F59E0B"))
                                }
                            }
                        }
                    }

                    Spacer()

                    Text("Please keep the app open during recovery")
                        .font(.system(size: 11)).foregroundColor(Color(hex: "#4B5563"))
                        .padding(.bottom, geo.safeAreaInsets.bottom + 24)
                }
            }
        }
        .ignoresSafeArea(.all)
    }
}

// MARK: - Recovery Complete View
struct RecoveryCompleteView: View {
    @EnvironmentObject var viewModel: ScanViewModel
    @EnvironmentObject var recoveryStore: RecoveryStore
    @State private var showRings = false
    @State private var animateCheck = false

    var result: RecoveryOperationResult? { viewModel.recoveryResult }

    var body: some View {
        GeometryReader { geo in
            let isSmall = geo.size.height < 700

            ZStack {
                Color(hex: "#0A0E1A").ignoresSafeArea(.all)

                VStack(spacing: 0) {
                    Spacer()

                    // Check animation
                    ZStack {
                        ForEach(0..<3) { i in
                            Circle()
                                .strokeBorder(Color(hex: "#10B981").opacity(showRings ? 0 : 0.25 - Double(i) * 0.07), lineWidth: 1.5)
                                .frame(width: CGFloat(90 + i * 44), height: CGFloat(90 + i * 44))
                                .scaleEffect(showRings ? CGFloat(2.2 + Double(i) * 0.3) : 1.0)
                                .animation(.easeOut(duration: 1.4).delay(Double(i) * 0.12), value: showRings)
                        }
                        ZStack {
                            Circle()
                                .fill(RadialGradient(
                                    colors: [Color(hex: "#10B981").opacity(0.25), Color(hex: "#0D1F2D")],
                                    center: .center, startRadius: 0, endRadius: 50
                                ))
                                .frame(width: 100, height: 100)
                            Circle().strokeBorder(Color(hex: "#10B981"), lineWidth: 2).frame(width: 100, height: 100)
                            Image(systemName: "checkmark")
                                .font(.system(size: isSmall ? 36 : 44, weight: .bold))
                                .foregroundColor(Color(hex: "#10B981"))
                                .scaleEffect(animateCheck ? 1.0 : 0.3)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: animateCheck)
                        }
                    }
                    .onAppear { showRings = true; animateCheck = true; saveSession() }

                    Spacer().frame(height: isSmall ? 24 : 36)

                    VStack(spacing: 8) {
                        Text("Recovery Complete!")
                            .font(.system(size: isSmall ? 24 : 28, weight: .black)).foregroundColor(.white)
                        if let result = result {
                            Text("\(result.succeededFiles.count) files successfully recovered")
                                .font(.system(size: isSmall ? 14 : 16)).foregroundColor(Color(hex: "#8892A4"))
                        }
                    }

                    Spacer().frame(height: isSmall ? 24 : 32)

                    if let result = result {
                        HStack(spacing: 10) {
                            ResultStatCard(icon: "checkmark.circle.fill",
                                           value: "\(result.succeededFiles.count)", label: "Recovered", color: "#10B981")
                            ResultStatCard(icon: "xmark.circle.fill",
                                           value: "\(result.failedFiles.count)", label: "Failed",
                                           color: result.failedFiles.isEmpty ? "#6B7280" : "#FF6B6B")
                            ResultStatCard(icon: "externaldrive.fill",
                                           value: ByteCountFormatter.string(fromByteCount: result.totalRecovered, countStyle: .file),
                                           label: "Total Size", color: "#4ECDC4")
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer()

                    VStack(spacing: 12) {
                        Button(action: viewModel.rescan) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass.circle.fill")
                                Text("Scan Again").font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient(
                                colors: [Color(hex: "#4ECDC4"), Color(hex: "#2BD9CF")],
                                startPoint: .leading, endPoint: .trailing
                            )))
                            .shadow(color: Color(hex: "#4ECDC4").opacity(0.4), radius: 15)
                        }
                        .buttonStyle(ScaleButtonStyle()).padding(.horizontal, 20)

                        Button(action: viewModel.resetToHome) {
                            Text("Done").font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "#8892A4")).padding(.vertical, 12)
                        }
                    }
                    .padding(.bottom, geo.safeAreaInsets.bottom + 20)
                }
            }
        }
        .ignoresSafeArea(.all)
    }

    private func saveSession() {
        guard let result = result else { return }
        let session = RecoverySession(
            id: UUID(), date: Date(), recoveredFiles: result.succeededFiles,
            destinationPath: result.destinationURL?.path ?? "Device",
            status: result.failedFiles.isEmpty ? .completed : .partial
        )
        recoveryStore.addSession(session)
    }
}

// MARK: - Result Stat Card
struct ResultStatCard: View {
    let icon: String; let value: String; let label: String; let color: String
    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon).font(.system(size: 20)).foregroundColor(Color(hex: color))
            Text(value).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(Color(hex: "#6B7280"))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#141928"))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "#2A3352"), lineWidth: 1)))
    }
}
