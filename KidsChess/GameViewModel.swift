import SwiftUI

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var game = ChessGame()
    @Published var selectedSquare: Square?
    @Published var promotionRequest: PromotionRequest?

    struct PromotionRequest: Identifiable {
        let id = UUID()
        let from: Square
        let to: Square
    }

    var legalDestinations: Set<Square> {
        guard let selectedSquare else { return [] }
        return Set(game.legalMoves(from: selectedSquare).map(\.to))
    }

    var statusText: String {
        switch game.outcome {
        case .playing: return "\(game.turn.title)’s turn"
        case .check(let color): return "\(color.title) is in check!"
        case .checkmate(let winner): return "Checkmate — \(winner.title) wins!"
        case .stalemate: return "Stalemate — it’s a draw"
        }
    }

    func tap(_ square: Square) {
        if let selectedSquare, legalDestinations.contains(square) {
            if game[selectedSquare]?.kind == .pawn && (square.rank == 0 || square.rank == 7) {
                promotionRequest = PromotionRequest(from: selectedSquare, to: square)
            } else {
                _ = game.move(from: selectedSquare, to: square)
                self.selectedSquare = nil
            }
        } else if game[square]?.color == game.turn {
            selectedSquare = square
        } else {
            selectedSquare = nil
        }
    }

    func promote(to kind: PieceKind) {
        guard let request = promotionRequest else { return }
        _ = game.move(from: request.from, to: request.to, promotion: kind)
        selectedSquare = nil
        promotionRequest = nil
    }

    func restart() {
        game.restart()
        selectedSquare = nil
        promotionRequest = nil
    }
}
