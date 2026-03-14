import SwiftUI
import SwiftData
import CoreText

@main
struct Meme_StashApp: App {

    static let container: ModelContainer = {
        let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.dallinskinner.Meme-Stash")!
            .appendingPathComponent("MemeStash.store")
        let config = ModelConfiguration(url: groupURL)
        do {
            return try ModelContainer(for: Meme.self, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    init() {
        Self.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(Self.container)
    }

    private static func registerFonts() {
        // File system sync groups may flatten or preserve directory structure
        let fontURL = Bundle.main.url(forResource: "SpaceMono-Bold", withExtension: "ttf", subdirectory: "Fonts")
            ?? Bundle.main.url(forResource: "SpaceMono-Bold", withExtension: "ttf")
        guard let fontURL else {
            print("⚠️ SpaceMono-Bold.ttf not found in bundle")
            return
        }
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }
}
