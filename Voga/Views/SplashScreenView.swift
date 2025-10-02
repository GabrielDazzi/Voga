import SwiftUI

struct SplashScreenView: View {
    @Binding var isActive: Bool
    @EnvironmentObject var themeSettings: ThemeSettings
    @State private var fillOffset: CGFloat = 200
    @State private var finalOpacity: Double = 1.0
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            Text("Voga")
                .font(.system(size: 80, weight: .bold))
                .foregroundStyle(.gray.opacity(0.25))
                .overlay(
                    Text("Voga")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(themeSettings.accentColor.colorValue.gradient)
                        .mask(
                            Rectangle()
                                .frame(height: 200)
                                .offset(y: fillOffset)
                        )
                )
                .opacity(finalOpacity)
        }
        .onAppear {
            animateSplash()
        }
    }
    
    func animateSplash() {
        withAnimation(.easeInOut(duration: 2.5)) {
            fillOffset = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeIn(duration: 0.5)) {
                finalOpacity = 0.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            self.isActive = false
        }
    }
}
