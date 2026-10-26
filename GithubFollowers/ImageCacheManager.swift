
import UIKit

final class ImageCacheManager {

    static let shared = ImageCacheManager()

    private let cache = NSCache<NSString, UIImage>()

    private init() {}

    func getImage(for url: URL) async throws -> UIImage {

        let key = url.absoluteString as NSString

        // 1. Check whether the image is already cached.
        if let cachedImage = cache.object(forKey: key) {
            return cachedImage
        }

        // 2. Download the image if it isn't cached.
        let (data, response) = try await URLSession.shared.data(from: url)

        guard
            let httpResponse = response as? HTTPURLResponse,
            (200..<300).contains(httpResponse.statusCode),
            let image = UIImage(data: data)
        else {
            throw URLError(.badServerResponse)
        }

        // 3. Save the downloaded image in memory.
        cache.setObject(image, forKey: key)

        // 4. Return the image to the caller.
        return image
    }
}

