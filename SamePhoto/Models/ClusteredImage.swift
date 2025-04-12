import Photos
import SwiftUI
import CoreImage

/// Представляет одно изображение с связанным активом и миниатюрой.
struct ClusteredImage: Identifiable, Hashable {
    let id = UUID()
    let asset: PHAsset
    let image: UIImage
    
    static func == (lhs: ClusteredImage, rhs: ClusteredImage) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
