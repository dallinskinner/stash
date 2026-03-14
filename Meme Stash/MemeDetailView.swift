import SwiftUI
import SwiftData

struct MemeDetailView: View {
    let meme: Meme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var image: UIImage?
    @State private var showDeleteConfirmation = false
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 60)
            }

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color(.systemGray3).opacity(0.7))
                    }
                }
                .padding()

                Spacer()

                Text(meme.savedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.bottom, 8)

                HStack {
                    Button { showShareSheet = true } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                    }
                    Spacer()
                    Button {
                        if let image {
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
            if let image {
                ActivityView(items: [image])
                    .presentationDetents([.medium, .large])
            }
        }
        .alert("Delete Meme?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(meme)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
        .task {
            let data = meme.imageData
            image = await Task.detached { UIImage(data: data) }.value
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
