import Photos
import SwiftUI

/// Сервис для работы с фотобиблиотекой: загрузка активов, удаление и вычисление размера.
class PhotoLibraryService {
    private let imageManager = PHCachingImageManager()
    
    /// Запрашивает разрешение на доступ к фотобиблиотеке.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            completion(status == .authorized || status == .limited)
        }
    }
    
    /// Загружает все активы из фотобиблиотеки.
    func fetchAssets() -> PHFetchResult<PHAsset> {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(with: .image, options: fetchOptions)
    }
    
    /// Загружает изображения для указанных активов.
    func loadImages(for assets: [PHAsset], targetSize: CGSize, completion: @escaping ([(asset: PHAsset, image: UIImage)?]) -> Void) {
        var resultImages: [(asset: PHAsset, image: UIImage)?] = Array(repeating: nil, count: assets.count)
        let group = DispatchGroup()
        
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        
        for (index, asset) in assets.enumerated() {
            group.enter()
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                if let image {
                    resultImages[index] = (asset: asset, image: image)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .global(qos: .userInitiated)) {
            completion(resultImages)
        }
    }
    
    /// Вычисляет общий размер файлов для указанных активов.
    func calculateTotalSize(of assets: [PHAsset], completion: @escaping (Int64) -> Void) {
        var totalSize: Int64 = 0
        let group = DispatchGroup()
        
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        
        for asset in assets {
            group.enter()
            asset.requestContentEditingInput(with: nil) { input, _ in
                if let url = input?.fullSizeImageURL,
                   let fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 {
                    totalSize += fileSize
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(totalSize)
        }
    }
    
    /// Удаляет указанные активы из фотобиблиотеки.
    func deleteAssets(_ assets: [PHAsset], completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
}
