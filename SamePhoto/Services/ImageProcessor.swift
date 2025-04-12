import UIKit
import CoreImage

/// Сервис для обработки изображений: преобразование в градации серого и вычисление SSIM.
class ImageProcessor {
    /// Преобразует изображение в градациях серого в вектор.
    func grayscaleVector(of image: UIImage, size: CGSize) -> [Float]? {
        // Изменение размера изображения
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: size))
        guard let resized = UIGraphicsGetImageFromCurrentImageContext(),
              let cgImage = resized.cgImage else {
            return nil
        }
        
        // Преобразование в градации серого
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIPhotoEffectMono") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let output = filter.outputImage,
              let grayImage = context.createCGImage(output, from: output.extent) else {
            return nil
        }
        
        // Извлечение данных пикселей
        let width = grayImage.width
        let height = grayImage.height
        var pixels = [UInt8](repeating: 0, count: width * height)
        
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let cgContext = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: 0
        ) else {
            return nil
        }
        
        cgContext.draw(grayImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixels.map { Float($0) / 255.0 }
    }
    
    /// Вычисляет SSIM (структурное сходство) между двумя векторами.
    func calculateSSIM(_ x: [Float], _ y: [Float], width: Int, height: Int) -> Float {
        guard x.count == y.count else { return 0 }
        
        let count = Float(x.count)
        let meanX = x.reduce(0, +) / count
        let meanY = y.reduce(0, +) / count
        
        let sigmaX = sqrt(x.map { pow($0 - meanX, 2) }.reduce(0, +) / count)
        let sigmaY = sqrt(y.map { pow($0 - meanY, 2) }.reduce(0, +) / count)
        let covariance = zip(x, y).map { ($0 - meanX) * ($1 - meanY) }.reduce(0, +) / count
        
        let c1: Float = 0.01 * 0.01
        let c2: Float = 0.03 * 0.03
        
        let numerator = (2 * meanX * meanY + c1) * (2 * covariance + c2)
        let denominator = (meanX * meanX + meanY * meanY + c1) * (sigmaX * sigmaX + sigmaY * sigmaY + c2)
        
        return numerator / denominator
    }
}
