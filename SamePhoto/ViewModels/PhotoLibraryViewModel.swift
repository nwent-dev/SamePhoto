import Photos
import SwiftUI
import Foundation

class PhotoLibraryViewModel: ObservableObject {
    // MARK: - Published свойства
    
    @Published private(set) var clusters: [ImageClusterGroup] = []
    /// Список выбранных активов.
    @Published var selectedAssets: Set<PHAsset> = []
    
    // MARK: - Константы
    
    private enum Constants {
        /// Размер миниатюры для загрузки.
        static let thumbnailSize = CGSize(width: 200, height: 200)
        /// Размер изображения для кластеризации.
        static let clusteringSize = CGSize(width: 64, height: 64)
        /// Размер пакета для обработки.
        static let batchSize = 100
        /// Порог SSIM для кластеризации.
        static let ssimThreshold: Float = 0.6
        /// Окно сравнения для кластеризации.
        static let comparisonWindow = 100
    }
    
    // MARK: - Private свойства
    
    /// Все активы из фотобиблиотеки.
    private var assets: PHFetchResult<PHAsset> = PHFetchResult()
    /// Индекс текущего пакета.
    private var currentBatchIndex = 0
    
    // MARK: - Сервисы
    
    private let photoLibraryService: PhotoLibraryService
    private let imageProcessor: ImageProcessor
    private let clusteringService: ImageClusteringService
    
    // MARK: - Инициализация
    
    init(
        photoLibraryService: PhotoLibraryService = PhotoLibraryService(),
        imageProcessor: ImageProcessor = ImageProcessor(),
        clusteringService: ImageClusteringService = ImageClusteringService()
    ) {
        self.photoLibraryService = photoLibraryService
        self.imageProcessor = imageProcessor
        self.clusteringService = clusteringService
        requestAuthorization()
    }
    
    // MARK: - Публичные методы
    
    /// Запрашивает разрешение на доступ к фотобиблиотеке и подготавливает активы при успехе.
    func requestAuthorization() {
        photoLibraryService.requestAuthorization { [weak self] authorized in
            guard authorized else {
                print("Доступ к фотобиблиотеке запрещен.")
                return
            }
            self?.fetchAssets()
        }
    }
    
    /// Переключает состояние выбора для актива.
    func toggleSelection(for asset: PHAsset) {
        if selectedAssets.contains(asset) {
            selectedAssets.remove(asset)
        } else {
            selectedAssets.insert(asset)
        }
    }
    
    /// Удаляет выбранные изображения и возвращает количество удаленных и освобожденное место.
    func deleteSelectedImages(completion: @escaping (Int, Double) -> Void) {
        let assetsToDelete = Array(selectedAssets)
        
        photoLibraryService.calculateTotalSize(of: assetsToDelete) { [weak self] totalSize in
            guard let self else { return }
            
            self.photoLibraryService.deleteAssets(assetsToDelete) { success, error in
                guard success else {
                    print("Ошибка удаления: \(error?.localizedDescription ?? "Неизвестная ошибка")")
                    return
                }
                
                let freedMB = Double(totalSize) / (1024 * 1024)
                completion(assetsToDelete.count, freedMB)
                
                self.selectedAssets.removeAll()
                self.clusters.removeAll()
                self.currentBatchIndex = 0
                self.fetchAssets()
            }
        }
    }
    
    /// Возвращает общее количество изображений во всех кластерах.
    func totalImageCount() -> Int {
        clusters.reduce(0) { $0 + $1.images.count }
    }
    
    // MARK: - Приватные методы
    
    /// Загружает активы из фотобиблиотеки.
    private func fetchAssets() {
        assets = photoLibraryService.fetchAssets()
        clusterNextBatch()
    }
    
    /// Обрабатывает следующий пакет изображений для кластеризации.
    private func clusterNextBatch() {
        guard currentBatchIndex * Constants.batchSize < assets.count else {
            return
        }
        
        let startIndex = currentBatchIndex * Constants.batchSize
        let endIndex = min(startIndex + Constants.batchSize, assets.count)
        let batchAssets = (startIndex..<endIndex).map { assets.object(at: $0) }
        currentBatchIndex += 1
        
        photoLibraryService.loadImages(for: batchAssets, targetSize: Constants.thumbnailSize) { [weak self] imageData in
            guard let self else { return }
            
            let clusteredImages = imageData.compactMap { data -> ClusteredImage? in
                guard let data else { return nil }
                return ClusteredImage(asset: data.asset, image: data.image)
            }
            
            let vectorImages = clusteringService.generateImageVectors(
                from: clusteredImages,
                size: Constants.clusteringSize,
                imageProcessor: imageProcessor
            )
            
            let newClusters = clusteringService.clusterImages(
                vectorImages,
                width: Int(Constants.clusteringSize.width),
                height: Int(Constants.clusteringSize.height),
                threshold: Constants.ssimThreshold,
                comparisonWindow: Constants.comparisonWindow,
                imageProcessor: imageProcessor
            )
            
            DispatchQueue.main.async {
                self.clusters.append(contentsOf: newClusters)
                self.clusterNextBatch()
            }
        }
    }
}
