import SwiftUI

// Componente de Cartão Reutilizável para o nosso novo tema
struct CardView<Content: View>: View {
    let content: Content
    
    // Permite-nos criar um cartão com qualquer conteúdo dentro
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            // *** A CORREÇÃO FINAL ESTÁ AQUI ***
            // Usando .systemGray5, que é o meio-termo perfeito.
            // Cria um contraste subtil e profissional no Modo Escuro.
            .background(Color(.systemGray5))
            .cornerRadius(16)
            // Sombra suave para dar profundidade
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// Estilo de Secção para o nosso novo layout
struct SectionHeader: View {
    let title: LocalizedStringKey
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.top)
    }
}
