import SwiftUI

/// Вью, отображаемое после успешного удаления фотографий
struct SuccessDeleteView: View {
    // MARK: - переменные
    
    @Environment(\.dismiss) private var dismiss
    let photoCount: Int
    let freedSizeMB: Double
    
    private enum Constants {
        static let screenWidth = UIScreen.main.bounds.width
        static let screenHeight = UIScreen.main.bounds.height
        static let contentWidth = screenWidth * 0.8
        static let iconWidth = screenWidth * 0.6
        static let statIconWidth = screenWidth * 0.1
        static let timeIconWidth = screenWidth * 0.07
        static let buttonWidth = screenWidth * 0.8
        static let verticalSpacing = screenHeight * 0.05
    }
    
    // MARK: - body
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: Constants.verticalSpacing) {
                iconView
                titleView
                deletedPhotosInfo
                timeSavedInfo
                suggestionText
                dismissButton
            }
            .frame(width: Constants.contentWidth)
        }
    }
    
    // MARK: - компоненты
    
    /// Иконка в верхней части представления
    private var iconView: some View {
        Image("icon")
            .resizable()
            .scaledToFit()
            .frame(width: Constants.iconWidth)
    }
    
    /// Заголовок "Congratulations"
    private var titleView: some View {
        Text("Congratulations!")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundStyle(.black)
    }
    
    /// Информация об удаленных фотографиях и освобожденном месте
    private var deletedPhotosInfo: some View {
        HStack {
            Image("img1")
                .resizable()
                .scaledToFit()
                .frame(width: Constants.statIconWidth)
            
            VStack(alignment: .leading) {
                Text("You have delted")
                    .font(.title3)
                    .foregroundStyle(.black)
                
                HStack {
                    Text("\(photoCount) photos")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    
                    Text("(\(String(format: "%.1f", freedSizeMB)) MB)")
                        .font(.title3)
                        .foregroundStyle(.black)
                }
            }
        }
    }
    
    /// Информация о сэкономленном времени
    private var timeSavedInfo: some View {
        HStack {
            Image("img2")
                .resizable()
                .scaledToFit()
                .frame(width: Constants.timeIconWidth)
            
            VStack(alignment: .leading) {
                HStack {
                    Text("Saved")
                        .font(.title3)
                        .foregroundStyle(.black)
                    
                    Text("\(String(format: "%.1f", Double(photoCount) * 0.25)) мин")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
                
                Text("using SamePhoto")
                    .font(.title3)
                    .foregroundStyle(.black)
            }
        }
    }
    
    /// Текст с предложением просмотра видео
    private var suggestionText: some View {
        Text("Review all your videos. Sort the by size or date. See the ones that occupy the most space.")
            .foregroundStyle(.gray)
            .multilineTextAlignment(.center)
            .fontWeight(.medium)
    }
    
    /// Кнопка для закрытия
    private var dismissButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Great")
                .foregroundStyle(.white)
                .font(.title3)
                .fontWeight(.bold)
                .padding()
                .frame(width: Constants.buttonWidth)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue)
                }
        }
    }
}

#Preview {
    SuccessDeleteView(photoCount: 5, freedSizeMB: 12.3)
}
