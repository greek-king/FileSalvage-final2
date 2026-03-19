// Views/ScanningView.swift
import SwiftUI

struct ScanningView: View {
    @EnvironmentObject var viewModel: ScanViewModel
    @State private var rotationAngle: Double = 0

    var body: some View {
        GeometryReader { geo in
            let isSmall = geo.size.height < 700
            let radarSize: CGFloat = isSmall ? 180 : 240

            ZStack {
                Color(hex: "#0A0E1A").ignoresSafeArea(.all)

                VStack(spacing: 0) {

                    // Header
                    HStack {
                        Button(action: viewModel.cancelScan) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                                Text("Cancel").font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(Color(hex: "#8892A4"))
                        }
                        Spacer()
                        Text(viewModel.selectedDepth.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#4ECDC4"))
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Capsule().fill(Color(hex: "#4ECDC4").opacity(0.12))
                                .overlay(Capsule().strokeBorder(Color(hex: "#4ECDC4").opacity(0.3), lineWidth: 1)))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, isSmall ? 50 : 60)

                    Spacer()

                    // Radar
                    ZStack {
                        ForEach(0..<4) { i in
                            Circle()
                                .strokeBorder(Color(hex: "#4ECDC4").opacity(0.06 + Double(i) * 0.02), lineWidth: 1)
                                .frame(width: radarSize * 0.4 + CGFloat(i) * (radarSize * 0.18),
                                       height: radarSize * 0.4 + CGFloat(i) * (radarSize * 0.18))
                        }

                        // Sweep
                        ZStack {
                            Circle()
                                .trim(from: 0, to: 0.25)
                                .stroke(
                                    AngularGradient(
                                        colors: [Color(hex: "#4ECDC4").opacity(0.5), Color.clear],
                                        center: .center,
                                        startAngle: .degrees(0), endAngle: .degrees(90)
                                    ),
                                    lineWidth: 1
                                )
                                .frame(width: radarSize * 0.83, height: radarSize * 0.83)
                                .rotationEffect(.degrees(rotationAngle))

                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#4ECDC4").opacity(0.8), Color.clear],
                                    startPoint: .center, endPoint: .trailing
                                ))
                                .frame(width: radarSize * 0.42, height: 1.5)
                                .offset(x: radarSize * 0.21)
                                .rotationEffect(.degrees(rotationAngle))
                        }
                        .onAppear {
                            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                                rotationAngle = 360
                            }
                        }

                        // Center
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#0D1F2D"))
                                .frame(width: radarSize * 0.33, height: radarSize * 0.33)
                            Circle()
                                .strokeBorder(Color(hex: "#4ECDC4").opacity(0.4), lineWidth: 1.5)
                                .frame(width: radarSize * 0.33, height: radarSize * 0.33)
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: isSmall ? 22 : 28))
                                .foregroundColor(Color(hex: "#4ECDC4"))
                        }

                        // Blips
                        if viewModel.scanProgress.filesFound > 0 {
                            ForEach(0..<min(8, viewModel.scanProgress.filesFound / 3 + 1), id: \.self) { i in
                                BlipView(index: i, radius: radarSize * 0.35)
                            }
                        }
                    }
                    .frame(width: radarSize, height: radarSize)

                    Spacer().frame(height: isSmall ? 28 : 40)

                    // Progress info
                    VStack(spacing: isSmall ? 12 : 16) {
                        Text(viewModel.scanProgress.currentStep)
                            .font(.system(size: isSmall ? 15 : 17, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .animation(.easeInOut, value: viewModel.scanProgress.currentStep)

                        GeometryReader { barGeo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6).fill(Color(hex: "#1A2035")).frame(height: 8)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(LinearGradient(
                                        colors: [Color(hex: "#4ECDC4"), Color(hex: "#2BD9CF")],
                                        startPoint: .leading, endPoint: .trailing
                                    ))
                                    .frame(
                                        width: max(8, barGeo.size.width * viewModel.scanProgress.percentage),
                                        height: 8
                                    )
                                    .animation(.easeInOut(duration: 0.3), value: viewModel.scanProgress.percentage)
                            }
                        }
                        .frame(height: 8)
                        .padding(.horizontal, 40)

                        HStack(spacing: 40) {
                            StatItem(label: "Files Found", value: "\(viewModel.scanProgress.filesFound)", color: "#4ECDC4")
                            StatItem(label: "Progress", value: "\(Int(viewModel.scanProgress.percentage * 100))%", color: "#A855F7")
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#F59E0B"))
                        Text("Keep the app open during scanning")
                            .font(.system(size: isSmall ? 11 : 12))
                            .foregroundColor(Color(hex: "#6B7280"))
                    }
                    .padding(.bottom, isSmall ? 24 : 40)
                }
            }
        }
    }
}

struct BlipView: View {
    let index: Int
    var radius: CGFloat = 70
    @State private var opacity: Double = 0

    static let angles: [Double] = [40, 110, 200, 290, 60, 160, 240, 330]

    var body: some View {
        let angle = BlipView.angles[index % BlipView.angles.count]
        let distance = radius * (0.4 + Double(index % 3) * 0.2)
        let x = CGFloat(cos(angle * .pi / 180)) * distance
        let y = CGFloat(sin(angle * .pi / 180)) * distance

        Circle()
            .fill(Color(hex: "#4ECDC4"))
            .frame(width: 6, height: 6)
            .shadow(color: Color(hex: "#4ECDC4").opacity(0.8), radius: 4)
            .opacity(opacity)
            .offset(x: x, y: y)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(Double(index) * 0.2)) {
                    opacity = 1.0
                }
            }
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let color: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: color))
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(hex: "#6B7280"))
        }
    }
}
