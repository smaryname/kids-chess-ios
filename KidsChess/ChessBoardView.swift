import SwiftUI

struct ChessBoardView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let squareSide = side / 8
            VStack(spacing: 0) {
                ForEach((0..<8).reversed(), id: \.self) { rank in
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { file in
                            squareView(Square(file: file, rank: rank), side: squareSide)
                        }
                    }
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.7), lineWidth: 4))
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func squareView(_ square: Square, side: CGFloat) -> some View {
        let isLight = (square.file + square.rank).isMultiple(of: 2)
        let selected = viewModel.selectedSquare == square
        let destination = viewModel.legalDestinations.contains(square)
        return Button { viewModel.tap(square) } label: {
            ZStack {
                Rectangle().fill(isLight ? Color(red: 1, green: 0.91, blue: 0.67) : Color(red: 0.43, green: 0.66, blue: 0.53))
                if selected { Rectangle().fill(Color.yellow.opacity(0.62)) }
                if destination {
                    Circle()
                        .fill(viewModel.game[square] == nil ? Color.blue.opacity(0.65) : Color.red.opacity(0.7))
                        .frame(width: viewModel.game[square] == nil ? side * 0.25 : side * 0.72)
                }
                if let piece = viewModel.game[square] {
                    Text(piece.symbol)
                        .font(.system(size: side * 0.72))
                        .minimumScaleFactor(0.5)
                        .accessibilityLabel("\(piece.color.title) \(piece.kind.rawValue) on \(square.notation)")
                }
            }
            .frame(width: side, height: side)
        }
        .buttonStyle(.plain)
        .accessibilityHint(destination ? "Double tap to move here" : "Double tap to select")
    }
}
