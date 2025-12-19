//  Created by Jonathan Nobels on 2025-12-16.
//

import SwiftUI
import WebKit

struct BrowserView: View {
    @ObservedObject var model: BrowserViewModel

    // Transient overlay state
    @State private var showNavErrorOverlay: Bool = false
    @State private var navErrorURLText: String = ""
    @State private var overlayTask: Task<Void, Never>?

    // Bookmark editor presentation
    @State private var showingBookmarkEditor: Bool = false
    @State private var pendingBookmarkURLString: String = ""
    @State private var pendingBookmarkName: String = ""

    init(model: BrowserViewModel) {
        self.model = model
    }

    var body: some View {
        ZStack {
            WebView(model.page)
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        BrowserNavigator(model: model, onAddBookmark: { showingBookmarkEditor = true })
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }

            if showNavErrorOverlay {
                VStack(spacing: 8) {
                    Text("Unable to load")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if !navErrorURLText.isEmpty {
                        Text(navErrorURLText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(maxWidth: 260)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
                .shadow(radius: 8)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showNavErrorOverlay)
        .onChange(of: model.navError?.url) { _, newURL in
            // When a nav error occurs (model sets (error, url)), show overlay for 2 seconds.
            guard let failedURL = newURL else { return }
            navErrorURLText = failedURL.absoluteString

            // Cancel any existing overlay timer to avoid overlap
            overlayTask?.cancel()
            showNavErrorOverlay = true

            overlayTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if !Task.isCancelled {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showNavErrorOverlay = false
                    }
                }
            }
        }
        .onDisappear {
            overlayTask?.cancel()
        }
        .sheet(isPresented: $showingBookmarkEditor) {
            BookmarkEditor(
                dismissAction: { showingBookmarkEditor = false },
                initialName: model.page.backForwardList.currentItem?.title ?? "",
                initialURLString: model.page.backForwardList.currentItem?.url.absoluteString ?? ""
            )
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            Text("Connecting to your Tailnet...")
            ProgressView()
        }
    }
}
