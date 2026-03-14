import UIKit
import SwiftData
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        addSavingLabel()
        Task { await saveImagesAndDismiss() }
    }

    private func addSavingLabel() {
        let label = UILabel()
        label.text = "Saving to Meme Stash…"
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .body)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func saveImagesAndDismiss() async {
        let allImageData = await extractAllImageData()
        if !allImageData.isEmpty {
            do {
                let groupURL = FileManager.default
                    .containerURL(forSecurityApplicationGroupIdentifier: "group.com.dallinskinner.Meme-Stash")!
                    .appendingPathComponent("MemeStash.store")
                let config = ModelConfiguration(url: groupURL)
                let container = try ModelContainer(for: Meme.self, configurations: config)
                let context = ModelContext(container)
                for data in allImageData {
                    context.insert(Meme(imageData: data))
                }
                try context.save()
            } catch {
                // Swallow — don't leave user stuck in share sheet
            }
        }
        try? await Task.sleep(for: .milliseconds(300))
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func extractAllImageData() async -> [Data] {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            return []
        }

        var results: [Data] = []
        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    if let data = await loadImageData(from: provider) {
                        results.append(data)
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    if let url = await loadURL(from: provider), isImageURL(url),
                       let data = try? await URLSession.shared.data(from: url).0 {
                        results.append(data)
                    }
                }
            }
        }
        return results
    }

    private func loadImageData(from provider: NSItemProvider) async -> Data? {
        await withCheckedContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                if let data {
                    continuation.resume(returning: data)
                    return
                }
                provider.loadItem(forTypeIdentifier: UTType.image.identifier) { item, _ in
                    if let image = item as? UIImage {
                        continuation.resume(returning: image.jpegData(compressionQuality: 0.85))
                    } else if let url = item as? URL, let data = try? Data(contentsOf: url) {
                        continuation.resume(returning: data)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }

    private func loadURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier) { item, _ in
                continuation.resume(returning: item as? URL)
            }
        }
    }

    private func isImageURL(_ url: URL) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "heic", "bmp", "tiff", "tif"]
        return imageExtensions.contains(url.pathExtension.lowercased())
    }
}
