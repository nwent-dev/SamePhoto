import Foundation


/// Сервис для кластеризации изображений на основе их схожести.
class ImageClusteringService {
    /// Генерирует векторы для изображений.
    func generateImageVectors(from images: [ClusteredImage], size: CGSize, imageProcessor: ImageProcessor) -> [(item: ClusteredImage, vector: [Float])] {
        var vectorImages: [(item: ClusteredImage, vector: [Float])] = []
        vectorImages.reserveCapacity(images.count)
        
        DispatchQueue.concurrentPerform(iterations: images.count) { index in
            if let vector = imageProcessor.grayscaleVector(of: images[index].image, size: size) {
                DispatchQueue.global(qos: .userInitiated).sync {
                    vectorImages.append((images[index], vector))
                }
            }
        }
        
        return vectorImages
    }
    
    /// Группирует изображения в кластеры на основе схожести.
    func clusterImages(_ vectorImages: [(item: ClusteredImage, vector: [Float])], width: Int, height: Int, threshold: Float, comparisonWindow: Int, imageProcessor: ImageProcessor) -> [ImageClusterGroup] {
        var clusters: [ImageClusterGroup] = []
        var usedIndices = Set<Int>()
        
        for i in 0..<vectorImages.count {
            guard !usedIndices.contains(i) else { continue }
            
            let (itemA, vecA) = vectorImages[i]
            var currentCluster: [ClusteredImage] = [itemA]
            usedIndices.insert(i)
            
            let comparisonEnd = min(i + comparisonWindow, vectorImages.count)
            for j in (i + 1)..<comparisonEnd {
                guard !usedIndices.contains(j) else { continue }
                let (itemB, vecB) = vectorImages[j]
                
                let ssim = imageProcessor.calculateSSIM(vecA, vecB, width: width, height: height)
                
                if ssim > threshold {
                    currentCluster.append(itemB)
                    usedIndices.insert(j)
                }
            }
            
            if currentCluster.count > 1 {
                clusters.append(ImageClusterGroup(images: currentCluster))
            }
        }
        
        return clusters
    }
}
