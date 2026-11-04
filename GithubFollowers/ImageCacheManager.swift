
import UIKit

actor ImageCacheManager {

    static let shared = ImageCacheManager()

    private let cache = NSCache<NSString, UIImage>()
    private var inFlightTasks: [URL: Task<UIImage, Error>] = [:]

    private init() {
        // Limit cache memory to 50 MB
        cache.totalCostLimit = 50 * 1024 * 1024
        cache.countLimit = 150
    }

    func getImage(for url: URL) async throws -> UIImage {
        // 1. Request downsized avatars (?s=120)
        let targetURL = downsizedURL(for: url)
        let key = targetURL.absoluteString as NSString

        // 2. Check whether the image is already cached
        if let cachedImage = cache.object(forKey: key) {
            return cachedImage
        }

        // 3. De-duplicate in-flight downloads
        if let inFlightTask = inFlightTasks[targetURL] {
            return try await inFlightTask.value
        }

        // 4. Download and decode off the main thread
        let task = Task<UIImage, Error> {
            let (data, response) = try await URLSession.shared.data(from: targetURL)

            guard
                let httpResponse = response as? HTTPURLResponse,
                (200..<300).contains(httpResponse.statusCode)
            else {
                throw URLError(.badServerResponse)
            }

            // Decode image off the main thread (prepares bitmap for display)
            guard let rawImage = UIImage(data: data) else {
                throw URLError(.cannotDecodeContentData)
            }

            let decodedImage = await rawImage.byPreparingForDisplay() ?? rawImage

            // Store in NSCache with byte cost for totalCostLimit tracking
            self.cache.setObject(decodedImage, forKey: key, cost: data.count)

            return decodedImage
        }

        inFlightTasks[targetURL] = task

        do {
            let image = try await task.value
            inFlightTasks.removeValue(forKey: targetURL)
            return image
        } catch {
            inFlightTasks.removeValue(forKey: targetURL)
            throw error
        }
    }

    private func downsizedURL(for url: URL, size: Int = 120) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return url
        }
        var queryItems = components.queryItems ?? []
        queryItems.removeAll(where: { $0.name == "s" })
        queryItems.append(URLQueryItem(name: "s", value: "\(size)"))
        components.queryItems = queryItems
        return components.url ?? url
    }
}

