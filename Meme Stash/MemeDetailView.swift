import SwiftUI
import SwiftData

struct MemeDetailView: View {
    let memes: [Meme]
    @State var currentMemeID: Meme.ID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteConfirmation = false
    @State private var showShareSheet = false
    @State private var loadedImages: [UUID: UIImage] = [:]

    private var currentMeme: Meme? {
        memes.first { $0.id == currentMemeID }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentMemeID) {
                ForEach(memes) { meme in
                    MemePageView(meme: meme, loadedImages: $loadedImages)
                        .tag(meme.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .gray)
                    }
                }
                .padding()

                Spacer()

                if let currentMeme {
                    Text(currentMeme.savedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .padding(.bottom, 8)
                }

                HStack {
                    Button { showShareSheet = true } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                    }
                    Spacer()
                    Button {
                        if let image = loadedImages[currentMemeID] {
                            UIPasteboard.general.image = image
                        }
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 18))
                    }
                    Spacer()
                    Button { showDeleteConfirmation = true } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                    }
                    .tint(.red)
                }
                .tint(.white)
                .padding(.horizontal, 40)
                .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = loadedImages[currentMemeID] {
                ActivityView(items: [image])
                    .presentationDetents([.medium, .large])
            }
        }
        .alert("Delete Meme?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let meme = currentMeme {
                    modelContext.delete(meme)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }
}

private struct MemePageView: View {
    let meme: Meme
    @Binding var loadedImages: [UUID: UIImage]

    var body: some View {
        Color.clear
            .overlay {
                if let image = loadedImages[meme.id] {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(.vertical, 60)
                }
            }
            .task {
            guard loadedImages[meme.id] == nil else { return }
            let data = meme.imageData
            let image = await Task.detached { UIImage(data: data) }.value
            if let image {
                loadedImages[meme.id] = image
            }
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
