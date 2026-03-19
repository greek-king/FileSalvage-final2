// Views/ResultsView.swift
import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var viewModel: ScanViewModel
    @State private var showRecoverySheet = false
    @State private var searchText = ""

    var filteredAndSearched: [RecoverableFile] {
        var files = viewModel.filteredFiles
        if !searchText.isEmpty {
            files = files.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return files
    }

    var body: some View {
        GeometryReader { geo in
            let isSmall = geo.size.height < 700

            ZStack {
                Color(hex: "#0A0E1A").ignoresSafeArea(.all)

                VStack(spacing: 0) {

                    // Header
                    HStack {
                        Button(action: viewModel.resetToHome) {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left").font(.system(size: 13, weight: .semibold))
                                Text("New Scan").font(.system(size: 15))
                            }
                            .foregroundColor(Color(hex: "#4ECDC4"))
                        }
                        Spacer()
                        Text("Scan Results")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Menu {
                            Button("Select All") { viewModel.selectAll() }
                            Button("Select High Chance") { viewModel.selectHighChance() }
                            Button("Deselect All") { viewModel.deselectAll() }
                            Divider()
                            ForEach(ScanViewModel.SortOrder.allCases, id: \.self) { order in
                                Button(order.rawValue) { viewModel.sortOrder = order }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "#8892A4"))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, isSmall ? 50 : 56)
                    .padding(.bottom, 8)

                    // Summary strip
                    HStack(spacing: 10) {
                        SummaryCard(icon: "doc.text.magnifyingglass",
                                    label: "Found",
                                    value: "\(viewModel.scanResult?.scannedFiles.count ?? 0)",
                                    color: "#4ECDC4")
                        SummaryCard(icon: "clock.arrow.circlepath",
                                    label: "Scan Time",
                                    value: formatDuration(viewModel.scanResult?.duration ?? 0),
                                    color: "#A855F7")
                        SummaryCard(icon: "externaldrive.fill",
                                    label: "Size",
                                    value: ByteCountFormatter.string(
                                        fromByteCount: viewModel.scanResult?.totalRecoverableSize ?? 0,
                                        countStyle: .file),
                                    color: "#F59E0B")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Type filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All",
                                       count: viewModel.scanResult?.scannedFiles.count ?? 0,
                                       isSelected: viewModel.filterType == nil,
                                       color: "#4ECDC4") { viewModel.filterType = nil }
                            ForEach(viewModel.typeBreakdown, id: \.0) { type, count in
                                FilterChip(label: type.rawValue, count: count,
                                           isSelected: viewModel.filterType == type,
                                           color: type.color) {
                                    viewModel.filterType = (viewModel.filterType == type) ? nil : type
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 10)

                    // Toolbar
                    HStack {
                        Text(viewModel.selectedCount > 0
                             ? "\(viewModel.selectedCount) selected"
                             : "\(filteredAndSearched.count) files")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#8892A4"))
                        Spacer()
                        Menu {
                            ForEach(ScanViewModel.SortOrder.allCases, id: \.self) { order in
                                Button(order.rawValue) { viewModel.sortOrder = order }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("Sort: \(viewModel.sortOrder.rawValue)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color(hex: "#4ECDC4"))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(Color(hex: "#4ECDC4"))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Search
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").font(.system(size: 13))
                            .foregroundColor(Color(hex: "#6B7280"))
                        TextField("Search files...", text: $searchText)
                            .font(.system(size: 14)).foregroundColor(.white).tint(Color(hex: "#4ECDC4"))
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10).fill(Color(hex: "#141928"))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color(hex: "#2A3352"), lineWidth: 1))
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // File list
                    if filteredAndSearched.isEmpty {
                        Spacer()
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 44))
                            .foregroundColor(Color(hex: "#2A3352"))
                        Text("No files match your filter")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "#6B7280"))
                            .padding(.top, 8)
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 8) {
                                ForEach(filteredAndSearched) { file in
                                    FileRow(
                                        file: file,
                                        isSelected: viewModel.selectedFiles.contains(file.id),
                                        onTap: { viewModel.toggleSelection(file) }
                                    )
                                    .padding(.horizontal, 20)
                                }
                                Spacer().frame(height: viewModel.selectedCount > 0 ? 90 : 20)
                            }
                            .padding(.top, 10)
                        }
                    }

                    // Recovery bar
                    if viewModel.selectedCount > 0 {
                        VStack(spacing: 0) {
                            Divider().overlay(Color(hex: "#2A3352"))
                            HStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(viewModel.selectedCount) files selected")
                                        .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                    Text(ByteCountFormatter.string(fromByteCount: viewModel.selectedTotalSize, countStyle: .file))
                                        .font(.system(size: 11)).foregroundColor(Color(hex: "#8892A4"))
                                }
                                Spacer()
                                Button(action: { showRecoverySheet = true }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.down.circle.fill").font(.system(size: 16))
                                        Text("Recover").font(.system(size: 15, weight: .bold))
                                    }
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 24).padding(.vertical, 12)
                                    .background(Capsule().fill(LinearGradient(
                                        colors: [Color(hex: "#4ECDC4"), Color(hex: "#2BD9CF")],
                                        startPoint: .leading, endPoint: .trailing
                                    )))
                                    .shadow(color: Color(hex: "#4ECDC4").opacity(0.4), radius: 10)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                            .padding(.horizontal, 20).padding(.vertical, 14)
                            .background(Color(hex: "#0D1220"))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showRecoverySheet) { RecoveryDestinationSheet() }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds / 60)
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
        return mins > 0 ? "\(mins)m \(secs)s" : "\(secs)s"
    }
}

// MARK: - File Row
struct FileRow: View {
    let file: RecoverableFile
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color(hex: "#4ECDC4") : Color(hex: "#2A3352"), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(Color(hex: "#4ECDC4")).frame(width: 22, height: 22)
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                    }
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: file.fileType.color).opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: file.fileType.icon)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: file.fileType.color))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(file.name)
                        .font(.system(size: 13, weight: .medium)).foregroundColor(.white).lineLimit(1)
                    HStack(spacing: 6) {
                        Text(file.formattedSize)
                            .font(.system(size: 11)).foregroundColor(Color(hex: "#6B7280"))
                        if file.deletedDate != nil {
                            Text("•").foregroundColor(Color(hex: "#2A3352"))
                            Text(file.formattedDeletedDate)
                                .font(.system(size: 11)).foregroundColor(Color(hex: "#6B7280"))
                        }
                    }
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("\(Int(file.recoveryChance * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: file.recoveryChanceColor))
                    Text(file.recoveryChanceLabel)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color(hex: file.recoveryChanceColor).opacity(0.7))
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "#4ECDC4").opacity(0.07) : Color(hex: "#141928"))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isSelected ? Color(hex: "#4ECDC4").opacity(0.3) : Color(hex: "#2A3352"), lineWidth: 1))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let icon: String; let label: String; let value: String; let color: String
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(Color(hex: color))
            Text(value).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(.white)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(Color(hex: "#6B7280"))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#141928"))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "#2A3352"), lineWidth: 1)))
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String; let count: Int; let isSelected: Bool; let color: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(label).font(.system(size: 12, weight: .semibold))
                Text("\(count)").font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Capsule().fill(isSelected ? Color.black.opacity(0.2) : Color(hex: "#2A3352")))
            }
            .foregroundColor(isSelected ? .black : Color(hex: "#8892A4"))
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Capsule().fill(isSelected ? Color(hex: color) : Color(hex: "#141928"))
                .overlay(Capsule().strokeBorder(isSelected ? Color.clear : Color(hex: "#2A3352"), lineWidth: 1)))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
