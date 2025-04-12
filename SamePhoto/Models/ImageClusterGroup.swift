import Photos
import SwiftUI
import CoreImage

/// Представляет группу похожих изображений.
struct ImageClusterGroup: Identifiable {
    let id = UUID()
    var images: [ClusteredImage]
}

