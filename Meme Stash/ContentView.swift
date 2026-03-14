import SwiftUI
import SwiftData

enum TimeFilter: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"

    var cutoff: Date {
        let cal = Calendar.current
        switch self {
        case .day:   return cal.startOfDay(for: .now)
        case .week:  return cal.date(byAdding: .day, value: -7, to: .now)!
        case .month: return cal.date(byAdding: .month, value: -1, to: .now)!
        }
    }
}

private struct ScrollData: Equatable {
    var offset: CGFloat
    var contentHeight: CGFloat
    var visibleHeight: CGFloat
}

struct ContentView: View {
    @Query(sort: \Meme.savedAt, order: .reverse) private var memes: [Meme]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedMeme: Meme?
    @State private var filter: TimeFilter?
    @State private var showGrid = false
    @State private var isSelecting = false
    @State private var selection: Set<UUID> = []
    @State private var showDeleteConfirmation = false
    @State private var showShareSheet = false
    @State private var showToolbar = true
    @State private var lastScrollOffset: CGFloat = 0

    private var filteredMemes: [Meme] {
        guard let filter else { return memes }
        return memes.filter { $0.savedAt >= filter.cutoff }
    }

    private var groupedMemes: [(key: String, memes: [Meme])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        var groups: [(key: String, memes: [Meme])] = []
        var currentKey = ""
        var currentGroup: [Meme] = []
        for meme in filteredMemes {
            let key = formatter.string(from: meme.savedAt)
            if key != currentKey {
                if !currentGroup.isEmpty {
                    groups.append((key: currentKey, memes: currentGroup))
                }
                currentKey = key
                currentGroup = [meme]
            } else {
                currentGroup.append(meme)
            }
        }
        if !currentGroup.isEmpty {
            groups.append((key: currentKey, memes: currentGroup))
        }
        return groups
    }

    private var selectedMemes: [Meme] {
        filteredMemes.filter { selection.contains($0.id) }
    }

    private func handleScroll(offset: CGFloat, contentHeight: CGFloat, visibleHeight: CGFloat) {
        let maxOffset = max(contentHeight - visibleHeight, 0)
        guard offset > 0 && offset < maxOffset else { return }
        let delta = offset - lastScrollOffset
        if abs(delta) > 10 {
            let scrollingDown = delta > 0
            if scrollingDown && showToolbar && !isSelecting {
                withAnimation { showToolbar = false }
            } else if !scrollingDown && !showToolbar {
                withAnimation { showToolbar = true }
            }
            lastScrollOffset = offset
        }
    }

    private func handleTap(_ meme: Meme) {
        if isSelecting {
            if selection.contains(meme.id) {
                selection.remove(meme.id)
            } else {
                selection.insert(meme.id)
            }
        } else {
            selectedMeme = meme
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if memes.isEmpty {
                    ContentUnavailableView(
                        "No Memes Yet",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("Share images from Safari or Photos to save them here.")
                    )
                } else if filteredMemes.isEmpty {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("No memes saved in the last \(filter!.rawValue.lowercased()).")
                    )
                } else if showGrid {
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                            ForEach(groupedMemes, id: \.key) { group in
                                Section {
                                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)], spacing: 2) {
                                        ForEach(group.memes) { meme in
                                            MemeGridItem(meme: meme, isSelecting: isSelecting, isSelected: selection.contains(meme.id))
                                                .onTapGesture { handleTap(meme) }
                                        }
                                    }
                                } header: {
                                    SectionHeader(title: group.key)
                                }
                            }
                        }
                    }
                    .onScrollGeometryChange(for: ScrollData.self) { geo in
                        ScrollData(offset: geo.contentOffset.y, contentHeight: geo.contentSize.height, visibleHeight: geo.visibleRect.height)
                    } action: { _, new in
                        handleScroll(offset: new.offset, contentHeight: new.contentHeight, visibleHeight: new.visibleHeight)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                            ForEach(groupedMemes, id: \.key) { group in
                                Section {
                                    ForEach(group.memes) { meme in
                                        MemeRow(meme: meme, isSelecting: isSelecting, isSelected: selection.contains(meme.id))
                                            .onTapGesture { handleTap(meme) }
                                    }
                                } header: {
                                    SectionHeader(title: group.key)
                                }
                            }
                        }
                    }
                    .onScrollGeometryChange(for: ScrollData.self) { geo in
                        ScrollData(offset: geo.contentOffset.y, contentHeight: geo.contentSize.height, visibleHeight: geo.visibleRect.height)
                    } action: { _, new in
                        handleScroll(offset: new.offset, contentHeight: new.contentHeight, visibleHeight: new.visibleHeight)
                    }
                }
            }
            .navigationTitle("Stash")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if isSelecting {
                        Text("\(selection.count) Selected")
                            .font(.headline)
                    } else {
                        Text("Stash")
                            .font(.custom("SpaceMono-Bold", size: 20))
                            .tracking(-0.8)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isSelecting {
                        Button("Cancel") {
                            withAnimation {
                                isSelecting = false
                                selection.removeAll()
                            }
                        }
                    } else {
                        Button {
                            withAnimation { showGrid.toggle() }
                        } label: {
                            Image(systemName: showGrid ? "list.bullet" : "square.grid.3x3")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isSelecting {
                        Button("Select All") {
                            if selection.count == filteredMemes.count {
                                selection.removeAll()
                            } else {
                                selection = Set(filteredMemes.map(\.id))
                            }
                        }
                    } else {
                        HStack(spacing: 16) {
                            if !memes.isEmpty {
                                Button {
                                    withAnimation {
                                        isSelecting = true
                                        showToolbar = true
                                        selection.removeAll()
                                    }
                                } label: {
                                    Image(systemName: "checkmark.circle")
                                }
                            }
                            Menu {
                                ForEach(TimeFilter.allCases, id: \.self) { option in
                                    Button {
                                        filter = filter == option ? nil : option
                                    } label: {
                                        if filter == option {
                                            Label(option.rawValue, systemImage: "checkmark")
                                        } else {
                                            Text(option.rawValue)
                                        }
                                    }
                                }
                                if filter != nil {
                                    Divider()
                                    Button("Show All") { filter = nil }
                                }
                                #if DEBUG
                                Divider()
                                Button("Generate Test Data") {
                                    DebugData.generateSampleMemes(in: modelContext)
                                }
                                #endif
                            } label: {
                                Image(systemName: filter != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            }
                        }
                    }
                }
            }
            .toolbarBackground(.bar, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
            .toolbarVisibility(showToolbar ? .visible : .hidden, for: .navigationBar)
            .overlay(alignment: .top) {
                if !showToolbar {
                    Rectangle()
                        .fill(.bar)
                        .ignoresSafeArea(edges: .top)
                        .frame(height: 0)
                }
            }
            if isSelecting && !selection.isEmpty {
                HStack {
                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Spacer()
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.bar)
            }
        }
        .sheet(item: $selectedMeme) { meme in
            MemeDetailView(memes: filteredMemes, currentMemeID: meme.id)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showShareSheet) {
            let images = selectedMemes.compactMap { UIImage(data: $0.imageData) }
            ActivityView(items: images)
                .presentationDetents([.medium, .large])
        }
        .alert("Delete \(selection.count) Meme\(selection.count == 1 ? "" : "s")?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                for meme in selectedMemes {
                    modelContext.delete(meme)
                }
                withAnimation {
                    selection.removeAll()
                    isSelecting = false
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }
}

private struct MemeRow: View {
    let meme: Meme
    let isSelecting: Bool
    let isSelected: Bool
    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    var body: some View {
        HStack(spacing: 0) {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .padding(.leading, 12)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            }
        }
        .task(id: meme.id) {
            guard image == nil else { return }
            let data = meme.imageData
            let scale = displayScale
            image = await Task.detached {
                ImageLoader.downsample(data: data, maxPixelSize: 500 * scale)
            }.value
        }
    }
}

private struct MemeGridItem: View {
    let meme: Meme
    let isSelecting: Bool
    let isSelected: Bool
    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    var body: some View {
        Rectangle()
            .fill(Color(.systemGray6))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isSelecting {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? .blue : .white)
                        .shadow(radius: 2)
                        .padding(6)
                        .transition(.opacity)
                }
            }
            .clipped()
            .overlay {
                if isSelecting && isSelected {
                    RoundedRectangle(cornerRadius: 0)
                        .strokeBorder(.blue, lineWidth: 3)
                }
            }
            .task(id: meme.id) {
                guard image == nil else { return }
                let data = meme.imageData
                let scale = displayScale
                image = await Task.detached {
                    ImageLoader.downsample(data: data, maxPixelSize: 140 * scale)
                }.value
            }
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)
    }
}

