import SwiftUI
import UIKit

/// Drop-in replacement for AsyncImage(url:content:) that
/// - keeps pictures in memory and on disk, so they stay after the first load
/// - retries 3 times when the network blips
enum ImageCache {
    static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 50 * 1024 * 1024, diskCapacity: 300 * 1024 * 1024)
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 40
        return URLSession(configuration: config)
    }()
    static let memory = NSCache<NSURL, UIImage>()
}

struct CachedAsyncImage<Content: View>: View {
    let url: URL?
    let content: (AsyncImagePhase) -> Content
    @State private var phase: AsyncImagePhase = .empty

    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
    }

    var body: some View {
        content(phase)
            .task(id: url) { await load() }
    }

    private func load() async {
        guard let url else { phase = .failure(URLError(.badURL)); return }
        if let cached = ImageCache.memory.object(forKey: url as NSURL) {
            phase = .success(Image(uiImage: cached))
            return
        }
        phase = .empty
        for attempt in 0..<3 {
            if Task.isCancelled { return }
            do {
                let (data, response) = try await ImageCache.session.data(from: url)
                guard (response as? HTTPURLResponse)?.statusCode == 200,
                      let image = UIImage(data: data) else { throw URLError(.badServerResponse) }
                ImageCache.memory.setObject(image, forKey: url as NSURL)
                phase = .success(Image(uiImage: image))
                return
            } catch {
                if Task.isCancelled { return }
                try? await Task.sleep(nanoseconds: UInt64(600_000_000 * (attempt + 1)))
            }
        }
        // All retries failed (dead link or no network): show a tinted plate, never a blank box.
        phase = .success(Image(uiImage: Self.placeholder(for: url)))
    }

    private static func placeholder(for url: URL) -> UIImage {
        let palette: [UIColor] = [
            UIColor(red: 0.64, green: 0.25, blue: 0.13, alpha: 1),
            UIColor(red: 0.80, green: 0.42, blue: 0.20, alpha: 1),
            UIColor(red: 0.55, green: 0.36, blue: 0.24, alpha: 1),
            UIColor(red: 0.72, green: 0.30, blue: 0.28, alpha: 1)
        ]
        let seed = url.absoluteString.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
        let color = palette[abs(seed) % palette.count]
        let size = CGSize(width: 400, height: 400)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let cg = ctx.cgContext
            let colors = [color.cgColor, color.withAlphaComponent(0.65).cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            }
            let config = UIImage.SymbolConfiguration(pointSize: 120, weight: .regular)
            if let symbol = UIImage(systemName: "fork.knife", withConfiguration: config)?
                .withTintColor(UIColor.white.withAlphaComponent(0.85), renderingMode: .alwaysOriginal) {
                let rect = CGRect(x: (size.width - symbol.size.width) / 2, y: (size.height - symbol.size.height) / 2,
                                  width: symbol.size.width, height: symbol.size.height)
                symbol.draw(in: rect)
            }
        }
    }
}
