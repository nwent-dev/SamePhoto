import Photos
import SwiftUI

struct PhotoLibraryView: View {
    // MARK: - переменные
    let height = UIScreen.main.bounds.height
    @StateObject private var viewModel = PhotoLibraryViewModel()
    @State private var showSuccessView = false
    @State private var deletedCount = 0
    @State private var freedMB = 0.0
    @State private var selectedPreviewImage: IdentifiableImage?
    
    private enum Constants {
        static let screenWidth = UIScreen.main.bounds.width
        static let screenHeight = UIScreen.main.bounds.height
        static let imageWidth = screenWidth * 0.45
        static let imageHeight = screenHeight * 0.25
        static let deleteButtonWidth = screenWidth * 0.7
        static let deleteButtonYPosition = screenHeight * 0.85
        static let iconSize = screenWidth * 0.05
    }
    
    // MARK: - body
    
    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            
            VStack(alignment: .leading) {
                headerView
                photoClustersScrollView
            }
            
            if !viewModel.selectedAssets.isEmpty {
                deleteButton
            }
        }
        .sheet(isPresented: $showSuccessView) {
            SuccessDeleteView(photoCount: deletedCount, freedSizeMB: freedMB)
        }
        .fullScreenCover(item: $selectedPreviewImage) { image in
            imagePreviewView(for: image)
        }
    }
    
    // MARK: - Приватные компоненты вью
    
    /// Заголовок с информацией о количестве фотографий и выбранных элементов.
    private var headerView: some View {
        VStack(alignment: .leading) {
            Spacer()
                .frame(height: Constants.screenHeight * 0.06)
            
            Text("Similar")
                .foregroundStyle(.white)
                .font(.title)
                .bold()
            
            HStack(spacing: 0) {
                Text("\(viewModel.totalImageCount()) ")
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                Text("photos")
                    .foregroundStyle(.white)
                Text(" • \(viewModel.selectedAssets.count) ")
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                Text("selected")
                    .foregroundStyle(.white)
            }
        }
        .padding(.leading)
    }
    
    /// Список фотографий с прокруткой.
    private var photoClustersScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(viewModel.clusters) { cluster in
                    clusterView(for: cluster)
                }
            }
            .padding(.top)
        }
        .padding(.bottom, !viewModel.selectedAssets.isEmpty ? height * 0.12 : 0)
        .background {
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .edgesIgnoringSafeArea(.bottom)
    }
    
    /// Представление отдельного кластера фотографий.
    private func clusterView(for cluster: ImageClusterGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(cluster.images.count) Similar")
                .foregroundStyle(.black)
                .font(.title)
                .bold()
                .padding(.leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(cluster.images) { image in
                        imageView(for: image)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    /// Представление отдельного изображения.
    private func imageView(for image: ClusteredImage) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Image(uiImage: image.image)
                .resizable()
                .scaledToFill()
                .frame(width: Constants.imageWidth, height: Constants.imageHeight)
                .clipped()
                .cornerRadius(10)
                .onTapGesture {
                    selectedPreviewImage = IdentifiableImage(image: image.image)
                }
            
            Button {
                viewModel.toggleSelection(for: image.asset)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray)
                        .frame(width: 28, height: 28)
                    
                    Image(viewModel.selectedAssets.contains(image.asset) ? "checkbox.fill" : "checkbox")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding(2)
                        .foregroundColor(viewModel.selectedAssets.contains(image.asset) ? .blue : .gray)
                }
                .frame(width: 40, height: 40)
            }
        }
    }
    
    /// Кнопка удаления выбранных изображений.
    private var deleteButton: some View {
        Button {
            viewModel.deleteSelectedImages { count, size in
                deletedCount = count
                freedMB = size
                showSuccessView = true
            }
        } label: {
            HStack {
                Image(systemName: "trash")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: Constants.iconSize)
                
                Text("Delete \(viewModel.selectedAssets.count) selected")
                    .foregroundStyle(.white)
                    .font(.system(size: Constants.iconSize, weight: .semibold))
            }
            .frame(width: Constants.deleteButtonWidth)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.blue)
            }
        }
        .position(x: Constants.screenWidth / 2, y: Constants.deleteButtonYPosition)
        .transition(.opacity)
        .animation(.easeInOut, value: viewModel.selectedAssets)
    }
    
    /// Полноэкранное вью для просмотра изображения.
    private func imagePreviewView(for image: IdentifiableImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Color.white.ignoresSafeArea()
            
            VStack {
                Spacer()
                Image(uiImage: image.image)
                    .resizable()
                    .scaledToFit()
                Spacer()
            }
            
            Button(action: {
                selectedPreviewImage = nil
            }) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.black)
                    .padding()
            }
        }
    }
}

#Preview {
    PhotoLibraryView()
}
