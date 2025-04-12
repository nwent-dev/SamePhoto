import Photos
import SwiftUI

/// Представляет изображение с уникальным идентификатором.
struct IdentifiableImage: Identifiable, Equatable {
    let id = UUID()
    let image: UIImage
}
