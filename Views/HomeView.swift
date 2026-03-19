// Views/HomeView.swift
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: ScanViewModel
    @EnvironmentObject var recoveryStore: RecoveryStore
    @State private var animatePulse = false

    var body: some View {
        GeometryReader { geo in
            let isSmall = geo.size.height < 700   // iPhone SE / mini
            let isMedium = geo.size.height < 850  // iPhone standard
            let radarSize: CGFloat = isSmall ? 120 : (isMedium ? 140 : 160)
            let topPad: CGFloat = isSmall ? 50 : 60

            ZStack {
                Color(hex: "#0A0E1A").ignoresSafeArea(.all)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("FileSalvage")
                                    .font(.system(size: isSmall ? 24 : 28, weight: .black, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "#4ECDC4"), Color(hex: "#44A8B3")],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    )
                                Text("Data Recovery & Restore")
                                    .font(.system(size: isSmall ? 11 : 13, weight: .medium))
                                    .foregroundColor(Color(hex: "#8892A4"))
                            }
                            Spacer()
                            Button(action: {}) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "#141928"))
                                        .frame(width: 40, height: 40)
                                        .overlay(Circle().strokeBorder(Color(hex: "#2A3352"), lineWidth: 1))
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(hex: "#4ECDC4"))
                                }
                            }
                        }
                        .padding(.top, topPad)
                        .padding(.horizontal, 20)

                        // Radar + Scan Button
                        VStack(spacing: isSmall ? 16 : 24) {
                            ZStack {
                                ForEach(0..<3) { i in
                                    Circle()
                                        .strokeBorder(Color(hex: "#4ECDC4").opacity(0.12 - Double(i) * 0.03), lineWidth: 1)
                                        .frame(
                                            width: radarSize + CGFloat(i * 36),
                                            height: radarSize + CGFloat(i * 36)
                                        )
                                        .scaleEffect(animatePulse ? 1.04 + Double(i) * 0.01 : 1.0)
                                        .animation(
                                            .easeInOut(duration: 2.5).repeatForever(autoreverses: true)
                                                .delay(Double(i) * 0.3),
                                            value: animatePulse
                                        )
                                }

                                Button(action: viewModel.startScan) {
                                    ZStack {
                                        Circle()
                                            .fill(RadialGradient(
                                                colors: [Color(hex: "#1E3A4A"), Color(hex: "#0D1F2D")],
                                                center: .center, startRadius: 0, endRadius: radarSize / 2
                                            ))
                                            .frame(width: radarSize, height: radarSize)
                                            .overlay(
                                                Circle().strokeBorder(
                                                    LinearGradient(
                                                        colors: [Color(hex: "#4ECDC4"), Color(hex: "#1A6B75")],
                                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 2
                                                )
                                            )
                                            .shadow(color: Color(hex: "#4ECDC4").opacity(0.3), radius: 20)

                                        VStack(spacing: 6) {
                                            Image(systemName: "magnifyingglass.circle.fill")
                                                .font(.system(size: isSmall ? 28 : 36))
                                                .foregroundStyle(LinearGradient(
                                                    colors: [Color(hex: "#4ECDC4"), Color(hex: "#68E8DF")],
                                                    startPoint: .top, endPoint: .bottom
                                                ))
                                            Text("START SCAN")
                                                .font(.system(size: isSmall ? 9 : 11, weight: .bold, design: .rounded))
                                                .tracking(1.5)
                                                .foregroundColor(Color(hex: "#4ECDC4"))
                                        }
                                    }
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }

                            VStack(spacing: 5) {
                                Text("Detect Recoverable Files")
                                    .font(.system(size: isSmall ? 17 : 20, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Scan for deleted photos, videos,\ndocuments and more")
                                    .font(.system(size: isSmall ? 12 : 14))
                                    .foregroundColor(Color(hex: "#8892A4"))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(3)
                            }
                        }
                        .padding(.top, isSmall ? 24 : 32)
                        .padding(.horizontal, 20)

                        // Scan Depth
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SCAN DEPTH")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: "#8892A4"))
                                .tracking(1)
                                .padding(.horizontal, 20)

                            HStack(spacing: 10) {
                                ForEach(ScanDepth.allCases, id: \.self) { depth in
                                    DepthOptionButton(
                                        depth: depth,
                                        isSelected: viewModel.selectedDepth == depth,
                                        isSmall: isSmall,
                                        action: { viewModel.selectedDepth = depth }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, isSmall ? 20 : 28)

                        // File Types Grid
                        VStack(alignment: .leading, spacing: 10) {
                            Text("WHAT WE RECOVER")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: "#8892A4"))
                                .tracking(1)
                                .padding(.horizontal, 20)

                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                                spacing: 10
                            ) {
                                ForEach(FileType.allCases.filter { $0 != .unknown }, id: \.self) { type in
                                    FileTypeTile(fileType: type, isSmall: isSmall)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, isSmall ? 20 : 28)

                        // Recent Sessions
                        if !recoveryStore.sessions.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("RECENT SESSIONS")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(hex: "#8892A4"))
                                    .tracking(1)
                                    .padding(.horizontal, 20)

                                ForEach(recoveryStore.sessions.prefix(3)) { session in
                                    SessionRow(session: session)
                                        .padding(.horizontal, 20)
                                }
                            }
                            .padding(.top, isSmall ? 20 : 28)
                        }

                        Spacer().frame(height: 40)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
            recoveryStore.loadSessions()
        }
    }
}

// MARK: - Depth Option Button
struct DepthOptionButton: View {
    let depth: ScanDepth
    let isSelected: Bool
    var isSmall: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(hex: "#4ECDC4").opacity(0.15) : Color(hex: "#141928"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                isSelected ? Color(hex: "#4ECDC4").opacity(0.6) : Color(hex: "#2A3352"),
                                lineWidth: 1
                            )
                    )
                VStack(spacing: 4) {
                    Image(systemName: depthIcon)
                        .font(.system(size: isSmall ? 14 : 18))
                        .foregroundColor(isSelected ? Color(hex: "#4ECDC4") : Color(hex: "#4B5563"))
                    Text(depthLabel)
                        .font(.system(size: isSmall ? 9 : 10, weight: .semibold))
                        .foregroundColor(isSelected ? Color(hex: "#4ECDC4") : Color(hex: "#6B7280"))
                }
                .padding(.vertical, isSmall ? 10 : 12)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .frame(maxWidth: .infinity)
    }

    var depthIcon: String {
        switch depth {
        case .quick: return "bolt.fill"
        case .deep:  return "magnifyingglass"
        case .full:  return "scope"
        }
    }
    var depthLabel: String {
        switch depth {
        case .quick: return "QUICK"
        case .deep:  return "DEEP"
        case .full:  return "FULL"
        }
    }
}

// MARK: - File Type Tile
struct FileTypeTile: View {
    let fileType: FileType
    var isSmall: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(hex: "#141928"))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "#2A3352"), lineWidth: 1))
            .frame(height: isSmall ? 68 : 80)
            .overlay(
                VStack(spacing: 5) {
                    Image(systemName: fileType.icon)
                        .font(.system(size: isSmall ? 18 : 22))
                        .foregroundColor(Color(hex: fileType.color))
                    Text(fileType.rawValue)
                        .font(.system(size: isSmall ? 10 : 11, weight: .medium))
                        .foregroundColor(Color(hex: "#8892A4"))
                }
            )
    }
}

// MARK: - Session Row
struct SessionRow: View {
    let session: RecoverySession
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color(hex: "#141928")).frame(width: 38, height: 38)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#10B981"))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("\(session.recoveredFiles.count) files recovered")
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                Text(session.formattedDate)
                    .font(.system(size: 11)).foregroundColor(Color(hex: "#6B7280"))
            }
            Spacer()
            Text(ByteCountFormatter.string(fromByteCount: session.totalSize, countStyle: .file))
                .font(.system(size: 12, weight: .medium)).foregroundColor(Color(hex: "#4ECDC4"))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#141928"))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "#2A3352"), lineWidth: 1))
        )
    }
}
