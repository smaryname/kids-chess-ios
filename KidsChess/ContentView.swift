import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.48, green: 0.79, blue: 0.95), Color(red: 0.68, green: 0.48, blue: 0.88)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                Text("♟ Kids Chess")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text(viewModel.statusText)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(.black.opacity(0.22), in: Capsule())
                    .accessibilityIdentifier("gameStatus")
                ChessBoardView(viewModel: viewModel)
                    .padding(.horizontal)
                Button {
                    viewModel.restart()
                } label: {
                    Label("New Game", systemImage: "arrow.counterclockwise")
                        .font(.headline).padding(.horizontal, 24).padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .accessibilityIdentifier("newGameButton")
            }
            .padding(.vertical)
        }
        .confirmationDialog("Choose your new piece", isPresented: Binding(
            get: { viewModel.promotionRequest != nil },
            set: { if !$0 { viewModel.promotionRequest = nil } }
        ), titleVisibility: .visible) {
            ForEach([PieceKind.queen, .rook, .bishop, .knight], id: \.self) { kind in
                Button(kind.rawValue.capitalized) { viewModel.promote(to: kind) }
            }
        }
    }
}
