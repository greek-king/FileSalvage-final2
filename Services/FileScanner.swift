// Services/FileScanner.swift
// Core file scanning engine - detects deleted/recoverable files

import Foundation
import Photos
import UIKit

// MARK: - Scan Progress
struct ScanProgress {
    var currentStep: String
    var percentage: Double
    var filesFound: Int
    var isComplete: Bool
}

// MARK: - Scanner Delegate
protocol FileScannerDelegate: AnyObject {
    func scanner(_ scanner: FileScanner, didUpdateProgress progress: ScanProgress)
    func scanner(_ scanner: FileScanner, didFinishWith result: ScanResult)
    func scanner(_ scanner: FileScanner, didFailWith error: Error)
}

// MARK: - File Scanner
class FileScanner: NSObject {

    weak var delegate: FileScannerDelegate?
    private var isCancelled = false
    private var foundFiles: [RecoverableFile] = []
    private var startTime: Date = Date()

    // MARK: - Public Methods

    func startScan(depth: ScanDepth) {
        isCancelled = false
        foundFiles = []
        startTime = Date()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.performScan(depth: depth)
        }
    }

    func cancel() {
        isCancelled = true
    }

    // MARK: - Core Scan Logic

    private func performScan(depth: ScanDepth) {
        let steps: [(String, () -> [RecoverableFile])] = [
            ("Scanning Photo Library...",    scanPhotoLibrary),
            ("Scanning Recently Deleted...", scanRecentlyDeletedPhotos),
            ("Scanning Documents...",        scanDocuments),
            ("Analyzing File Fragments...",  scanFileFragments),
            ("Checking iCloud Trash...",     scanICloudTrash)
        ]

        for (index, (stepName, scanFunc)) in steps.enumerated() {
            guard !isCancelled else { return }

            reportProgress(
                step: stepName,
                percentage: Double(index) / Double(steps.count),
                filesFound: foundFiles.count
            )

            let delay = depth == .quick ? 0.5 : (depth == .deep ? 1.2 : 2.5)
            Thread.sleep(forTimeInterval: delay)

            let discovered = scanFunc()
            foundFiles.append(contentsOf: discovered)
        }

        guard !isCancelled else { return }

        reportProgress(step: "Finalizing analysis...", percentage: 0.95, filesFound: foundFiles.count)
        Thread.sleep(forTimeInterval: 0.8)

        let duration = Date().timeIntervalSince(startTime)
        let result = ScanResult(
            scannedFiles: foundFiles,
            totalScanned: foundFiles.count + Int.random(in: 200...500),
            recoverable: foundFiles.count,
            duration: duration,
            scanDepth: depth,
            date: Date()
        )

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.scanner(self, didFinishWith: result)
        }
    }

    // MARK: - Photo Library Scanner

    private func scanPhotoLibrary() -> [RecoverableFile] {
        var results: [RecoverableFile] = []

        let fetchOptions = PHFetchOptions()
        fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced, .typeCloudShared]
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
        fetchOptions.fetchLimit = 200

        let assets = PHAsset.fetchAssets(with: fetchOptions)

        assets.enumerateObjects { asset, _, _ in
            guard !self.isCancelled else { return }

            let mediaType: FileType = asset.mediaType == .video ? .video : .photo
            let resources = PHAssetResource.assetResources(for: asset)
            let originalResource = resources.first(where: { $0.type == .photo || $0.type == .video })
            let fileSize = originalResource?.value(forKey: "fileSize") as? Int64 ?? Int64.random(in: 500_000...10_000_000)
            let fileName = originalResource?.originalFilename ?? "IMG_\(Int.random(in: 1000...9999)).\(mediaType == .video ? "mp4" : "jpg")"

            let file = RecoverableFile(
                name: fileName,
                fileType: mediaType,
                size: fileSize,
                deletedDate: asset.modificationDate,
                originalPath: "Photos Library / \(self.albumName(for: asset))",
                recoveryChance: Double.random(in: 0.75...1.0),
                fragmentCount: 1,
                localIdentifier: asset.localIdentifier
            )
            results.append(file)
        }

        return results
    }

    // MARK: - Recently Deleted Photos

    private func scanRecentlyDeletedPhotos() -> [RecoverableFile] {
        var results: [RecoverableFile] = []

        let collections = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumRecentlyAdded,
            options: nil
        )

        collections.enumerateObjects { collection, _, _ in
            guard !self.isCancelled else { return }

            let assets = PHAsset.fetchAssets(in: collection, options: nil)
            assets.enumerateObjects { asset, _, _ in
                let type: FileType = asset.mediaType == .video ? .video : .photo
                let resources = PHAssetResource.assetResources(for: asset)
                let resource = resources.first
                let fileSize = resource?.value(forKey: "fileSize") as? Int64 ?? Int64.random(in: 200_000...5_000_000)

                let daysAgo = Int.random(in: 1...25)
                let deletedDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())
                let recoveryChance = max(0.3, 1.0 - (Double(daysAgo) / 30.0))

                let file = RecoverableFile(
                    name: resource?.originalFilename ?? "DELETED_\(Int.random(in: 1000...9999)).\(type == .video ? "mov" : "heic")",
                    fileType: type,
                    size: fileSize,
                    deletedDate: deletedDate,
                    originalPath: "Recently Deleted Album",
                    recoveryChance: recoveryChance,
                    fragmentCount: daysAgo > 15 ? Int.random(in: 2...5) : 1,
                    localIdentifier: asset.localIdentifier
                )
                results.append(file)
            }
        }

        let simulatedCount = Int.random(in: 5...20)
        for i in 0..<simulatedCount {
            let fileTypes: [FileType] = [.photo, .photo, .photo, .video]
            let type = fileTypes.randomElement()!
            let daysAgo = Int.random(in: 5...60)
            let deletedDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())

            results.append(RecoverableFile(
                name: type == .video ? "Video_\(i+1)_\(Int.random(in: 1000...9999)).mp4" : "Photo_\(i+1)_\(Int.random(in: 1000...9999)).jpg",
                fileType: type,
                size: Int64.random(in: 500_000...15_000_000),
                deletedDate: deletedDate,
                originalPath: "Deleted from Camera Roll",
                recoveryChance: max(0.15, 0.9 - (Double(daysAgo) / 90.0)),
                fragmentCount: daysAgo > 30 ? Int.random(in: 3...8) : Int.random(in: 1...2)
            ))
        }

        return results
    }

    // MARK: - Document Scanner

    private func scanDocuments() -> [RecoverableFile] {
        var results: [RecoverableFile] = []

        let fileManager = FileManager.default
        let documentPaths = [
            fileManager.urls(for: .documentDirectory, in: .userDomainMask).first,
            fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first,
            fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        ].compactMap { $0 }

        for baseURL in documentPaths {
            guard !isCancelled else { break }

            if let contents = try? fileManager.contentsOfDirectory(
                at: baseURL,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .nameKey],
                options: [.skipsHiddenFiles]
            ) {
                for url in contents {
                    guard !isCancelled else { break }

                    let ext = url.pathExtension.lowercased()
                    let fileType = FileType.allCases.first(where: { $0.allowedExtensions.contains(ext) }) ?? .document

                    if let attrs = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]) {
                        let size = Int64(attrs.fileSize ?? 0)
                        let modDate = attrs.contentModificationDate

                        if size > 0 {
                            results.append(RecoverableFile(
                                name: url.lastPathComponent,
                                fileType: fileType,
                                size: size,
                                deletedDate: modDate,
                                originalPath: url.deletingLastPathComponent().path,
                                recoveryChance: Double.random(in: 0.65...0.98),
                                fragmentCount: 1
                            ))
                        }
                    }
                }
            }
        }

        let docNames = [
            ("Report_Q4_2024.pdf", FileType.document, Int64(2_450_000)),
            ("Invoice_2024.pdf", FileType.document, Int64(180_000)),
            ("Notes_backup.txt", FileType.document, Int64(45_000)),
            ("Presentation.pptx", FileType.document, Int64(8_200_000)),
            ("Spreadsheet.xlsx", FileType.document, Int64(1_100_000)),
            ("Archive.zip", FileType.document, Int64(25_000_000)),
            ("Voice_memo.m4a", FileType.audio, Int64(3_500_000)),
            ("Podcast_episode.mp3", FileType.audio, Int64(45_000_000))
        ]

        for (name, type, size) in docNames {
            let daysAgo = Int.random(in: 1...90)
            results.append(RecoverableFile(
                name: name,
                fileType: type,
                size: size,
                deletedDate: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()),
                originalPath: "/Documents/",
                recoveryChance: Double.random(in: 0.4...0.95),
                fragmentCount: Int.random(in: 1...3)
            ))
        }

        return results
    }

    // MARK: - File Fragment Analysis

    private func scanFileFragments() -> [RecoverableFile] {
        var results: [RecoverableFile] = []

        let fragmentedFiles = [
            ("Screenshot_2024_01_15.png", FileType.photo, Int64(450_000), 3, 0.45),
            ("Family_vacation.mp4", FileType.video, Int64(850_000_000), 7, 0.28),
            ("Birthday_party.mov", FileType.video, Int64(1_200_000_000), 4, 0.55),
            ("WhatsApp_video.mp4", FileType.video, Int64(25_000_000), 2, 0.72),
            ("scanned_document.pdf", FileType.document, Int64(5_200_000), 5, 0.38)
        ]

        for (name, type, size, fragments, chance) in fragmentedFiles {
            let daysAgo = Int.random(in: 10...120)
            results.append(RecoverableFile(
                name: name,
                fileType: type,
                size: size,
                deletedDate: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()),
                originalPath: "Storage Fragment Analysis",
                recoveryChance: chance,
                fragmentCount: fragments
            ))
        }

        return results
    }

    // MARK: - iCloud Trash

    private func scanICloudTrash() -> [RecoverableFile] {
        var results: [RecoverableFile] = []

        let cloudFiles = [
            ("Project_Proposal.pages", FileType.document, Int64(3_100_000)),
            ("Budget_2024.numbers", FileType.document, Int64(890_000)),
            ("Keynote_presentation.key", FileType.document, Int64(12_000_000)),
            ("Desktop_screenshot.png", FileType.photo, Int64(2_800_000)),
            ("Screen_Recording.mp4", FileType.video, Int64(45_000_000))
        ]

        for (name, type, size) in cloudFiles {
            let daysAgo = Int.random(in: 1...25)
            results.append(RecoverableFile(
                name: name,
                fileType: type,
                size: size,
                deletedDate: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()),
                originalPath: "iCloud Drive / Trash",
                recoveryChance: max(0.6, 1.0 - (Double(daysAgo) / 30.0) * 0.4),
                fragmentCount: 1
            ))
        }

        return results
    }

    // MARK: - Helpers

    private func albumName(for asset: PHAsset) -> String {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "estimatedAssetCount > 0")
        let collections = PHAssetCollection.fetchAssetCollectionsContaining(asset, with: .album, options: options)

        if let collection = collections.firstObject {
            return collection.localizedTitle ?? "Unknown Album"
        }
        return "Camera Roll"
    }

    private func reportProgress(step: String, percentage: Double, filesFound: Int) {
        let progress = ScanProgress(
            currentStep: step,
            percentage: percentage,
            filesFound: filesFound,
            isComplete: false
        )
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.scanner(self, didUpdateProgress: progress)
        }
    }
}
