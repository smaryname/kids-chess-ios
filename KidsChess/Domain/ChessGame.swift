import Foundation

enum PieceColor: String, CaseIterable, Codable {
    case white, black
    var opponent: PieceColor { self == .white ? .black : .white }
    var title: String { rawValue.capitalized }
}

enum PieceKind: String, CaseIterable, Codable, Hashable {
    case king, queen, rook, bishop, knight, pawn
}

struct ChessPiece: Equatable, Codable {
    let color: PieceColor
    let kind: PieceKind

    var symbol: String {
        switch (color, kind) {
        case (.white, .king): return "♔"
        case (.white, .queen): return "♕"
        case (.white, .rook): return "♖"
        case (.white, .bishop): return "♗"
        case (.white, .knight): return "♘"
        case (.white, .pawn): return "♙"
        case (.black, .king): return "♚"
        case (.black, .queen): return "♛"
        case (.black, .rook): return "♜"
        case (.black, .bishop): return "♝"
        case (.black, .knight): return "♞"
        case (.black, .pawn): return "♟"
        }
    }
}

struct Square: Hashable, Codable {
    let file: Int
    let rank: Int
    var isValid: Bool { (0..<8).contains(file) && (0..<8).contains(rank) }

    init(file: Int, rank: Int) {
        self.file = file
        self.rank = rank
    }

    init?(_ notation: String) {
        guard notation.count == 2,
              let fileCharacter = notation.first,
              let rankCharacter = notation.last,
              let file = "abcdefgh".firstIndex(of: fileCharacter),
              let rank = Int(String(rankCharacter)), (1...8).contains(rank) else { return nil }
        self.file = "abcdefgh".distance(from: "abcdefgh".startIndex, to: file)
        self.rank = rank - 1
    }

    var notation: String {
        let index = "abcdefgh".index("abcdefgh".startIndex, offsetBy: file)
        return "\("abcdefgh"[index])\(rank + 1)"
    }
}

struct ChessMove: Equatable {
    let from: Square
    let to: Square
    var promotion: PieceKind?
    var isCastle = false
    var isEnPassant = false
}

enum GameOutcome: Equatable {
    case playing
    case check(PieceColor)
    case checkmate(winner: PieceColor)
    case stalemate

    var isFinished: Bool {
        if case .checkmate = self { return true }
        return self == .stalemate
    }
}

struct CastlingRights: Equatable {
    var whiteKingSide = true
    var whiteQueenSide = true
    var blackKingSide = true
    var blackQueenSide = true
}

struct ChessGame {
    private(set) var board: [Square: ChessPiece]
    private(set) var turn: PieceColor
    private(set) var castlingRights: CastlingRights
    private(set) var enPassantTarget: Square?
    private(set) var outcome: GameOutcome = .playing

    init() {
        board = [:]
        turn = .white
        castlingRights = CastlingRights()
        setupStartingPosition()
        updateOutcome()
    }

    init(board: [Square: ChessPiece], turn: PieceColor = .white,
         castlingRights: CastlingRights = CastlingRights(
            whiteKingSide: false, whiteQueenSide: false,
            blackKingSide: false, blackQueenSide: false),
         enPassantTarget: Square? = nil) {
        self.board = board
        self.turn = turn
        self.castlingRights = castlingRights
        self.enPassantTarget = enPassantTarget
        updateOutcome()
    }

    subscript(square: Square) -> ChessPiece? { board[square] }

    mutating func restart() { self = ChessGame() }

    func legalMoves(from square: Square) -> [ChessMove] {
        guard let piece = board[square], piece.color == turn, !outcome.isFinished else { return [] }
        return pseudoLegalMoves(from: square, includeCastling: true).filter { move in
            var copy = self
            copy.applyUnchecked(move)
            return !copy.isKingInCheck(piece.color)
        }
    }

    func allLegalMoves(for color: PieceColor? = nil) -> [ChessMove] {
        let requestedColor = color ?? turn
        var game = self
        game.turn = requestedColor
        return game.board.keys.flatMap { game.legalMoves(from: $0) }
    }

    mutating func move(from: Square, to: Square, promotion: PieceKind = .queen) -> Bool {
        guard var selected = legalMoves(from: from).first(where: { $0.to == to }) else { return false }
        if board[from]?.kind == .pawn && (to.rank == 0 || to.rank == 7) {
            guard [.queen, .rook, .bishop, .knight].contains(promotion) else { return false }
            selected.promotion = promotion
        }
        applyUnchecked(selected)
        turn = turn.opponent
        updateOutcome()
        return true
    }

    func isKingInCheck(_ color: PieceColor) -> Bool {
        guard let kingSquare = board.first(where: { $0.value == ChessPiece(color: color, kind: .king) })?.key else {
            return true
        }
        return isSquareAttacked(kingSquare, by: color.opponent)
    }

    func isSquareAttacked(_ square: Square, by attacker: PieceColor) -> Bool {
        for (origin, piece) in board where piece.color == attacker {
            if piece.kind == .pawn {
                let direction = attacker == .white ? 1 : -1
                if [Square(file: origin.file - 1, rank: origin.rank + direction),
                    Square(file: origin.file + 1, rank: origin.rank + direction)].contains(square) { return true }
            } else if pseudoLegalMoves(from: origin, includeCastling: false).contains(where: { $0.to == square }) {
                return true
            }
        }
        return false
    }

    private mutating func setupStartingPosition() {
        let backRank: [PieceKind] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]
        for file in 0..<8 {
            board[Square(file: file, rank: 0)] = ChessPiece(color: .white, kind: backRank[file])
            board[Square(file: file, rank: 1)] = ChessPiece(color: .white, kind: .pawn)
            board[Square(file: file, rank: 6)] = ChessPiece(color: .black, kind: .pawn)
            board[Square(file: file, rank: 7)] = ChessPiece(color: .black, kind: backRank[file])
        }
    }

    private func pseudoLegalMoves(from origin: Square, includeCastling: Bool) -> [ChessMove] {
        guard let piece = board[origin] else { return [] }
        switch piece.kind {
        case .pawn: return pawnMoves(from: origin, color: piece.color)
        case .knight: return jumpMoves(from: origin, color: piece.color,
            offsets: [(1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1), (-2, 1), (-1, 2)])
        case .bishop: return slidingMoves(from: origin, color: piece.color,
            directions: [(1, 1), (1, -1), (-1, 1), (-1, -1)])
        case .rook: return slidingMoves(from: origin, color: piece.color,
            directions: [(1, 0), (-1, 0), (0, 1), (0, -1)])
        case .queen: return slidingMoves(from: origin, color: piece.color,
            directions: [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)])
        case .king:
            var moves = jumpMoves(from: origin, color: piece.color,
                offsets: [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)])
            if includeCastling { moves += castleMoves(color: piece.color) }
            return moves
        }
    }

    private func pawnMoves(from origin: Square, color: PieceColor) -> [ChessMove] {
        let direction = color == .white ? 1 : -1
        let startRank = color == .white ? 1 : 6
        var moves: [ChessMove] = []
        let one = Square(file: origin.file, rank: origin.rank + direction)
        if one.isValid && board[one] == nil {
            moves.append(ChessMove(from: origin, to: one))
            let two = Square(file: origin.file, rank: origin.rank + 2 * direction)
            if origin.rank == startRank && board[two] == nil { moves.append(ChessMove(from: origin, to: two)) }
        }
        for fileOffset in [-1, 1] {
            let target = Square(file: origin.file + fileOffset, rank: origin.rank + direction)
            guard target.isValid else { continue }
            if let captured = board[target], captured.color != color {
                moves.append(ChessMove(from: origin, to: target))
            } else if target == enPassantTarget {
                let capturedSquare = Square(file: target.file, rank: origin.rank)
                if board[capturedSquare] == ChessPiece(color: color.opponent, kind: .pawn) {
                    moves.append(ChessMove(from: origin, to: target, isEnPassant: true))
                }
            }
        }
        return moves
    }

    private func jumpMoves(from origin: Square, color: PieceColor, offsets: [(Int, Int)]) -> [ChessMove] {
        offsets.compactMap { file, rank in
            let target = Square(file: origin.file + file, rank: origin.rank + rank)
            guard target.isValid, board[target]?.color != color else { return nil }
            return ChessMove(from: origin, to: target)
        }
    }

    private func slidingMoves(from origin: Square, color: PieceColor, directions: [(Int, Int)]) -> [ChessMove] {
        var moves: [ChessMove] = []
        for (fileStep, rankStep) in directions {
            var target = Square(file: origin.file + fileStep, rank: origin.rank + rankStep)
            while target.isValid {
                if let occupant = board[target] {
                    if occupant.color != color { moves.append(ChessMove(from: origin, to: target)) }
                    break
                }
                moves.append(ChessMove(from: origin, to: target))
                target = Square(file: target.file + fileStep, rank: target.rank + rankStep)
            }
        }
        return moves
    }

    private func castleMoves(color: PieceColor) -> [ChessMove] {
        let rank = color == .white ? 0 : 7
        let king = Square(file: 4, rank: rank)
        guard board[king] == ChessPiece(color: color, kind: .king), !isKingInCheck(color) else { return [] }
        var moves: [ChessMove] = []
        let kingSide = color == .white ? castlingRights.whiteKingSide : castlingRights.blackKingSide
        if kingSide,
           board[Square(file: 7, rank: rank)] == ChessPiece(color: color, kind: .rook),
           board[Square(file: 5, rank: rank)] == nil, board[Square(file: 6, rank: rank)] == nil,
           !isSquareAttacked(Square(file: 5, rank: rank), by: color.opponent),
           !isSquareAttacked(Square(file: 6, rank: rank), by: color.opponent) {
            moves.append(ChessMove(from: king, to: Square(file: 6, rank: rank), isCastle: true))
        }
        let queenSide = color == .white ? castlingRights.whiteQueenSide : castlingRights.blackQueenSide
        if queenSide,
           board[Square(file: 0, rank: rank)] == ChessPiece(color: color, kind: .rook),
           board[Square(file: 1, rank: rank)] == nil, board[Square(file: 2, rank: rank)] == nil,
           board[Square(file: 3, rank: rank)] == nil,
           !isSquareAttacked(Square(file: 3, rank: rank), by: color.opponent),
           !isSquareAttacked(Square(file: 2, rank: rank), by: color.opponent) {
            moves.append(ChessMove(from: king, to: Square(file: 2, rank: rank), isCastle: true))
        }
        return moves
    }

    private mutating func applyUnchecked(_ move: ChessMove) {
        guard var piece = board.removeValue(forKey: move.from) else { return }
        let previousTarget = enPassantTarget
        enPassantTarget = nil
        if move.isEnPassant {
            board.removeValue(forKey: Square(file: move.to.file, rank: move.from.rank))
        }
        if move.isCastle {
            let rookFromFile = move.to.file == 6 ? 7 : 0
            let rookToFile = move.to.file == 6 ? 5 : 3
            let rookFrom = Square(file: rookFromFile, rank: move.from.rank)
            let rookTo = Square(file: rookToFile, rank: move.from.rank)
            board[rookTo] = board.removeValue(forKey: rookFrom)
        }
        if piece.kind == .pawn && abs(move.to.rank - move.from.rank) == 2 {
            enPassantTarget = Square(file: move.from.file, rank: (move.from.rank + move.to.rank) / 2)
        } else if piece.kind == .pawn && move.to == previousTarget && move.from.file != move.to.file && board[move.to] == nil {
            board.removeValue(forKey: Square(file: move.to.file, rank: move.from.rank))
        }
        updateCastlingRights(piece: piece, from: move.from, capturedAt: move.to)
        if let promotion = move.promotion { piece = ChessPiece(color: piece.color, kind: promotion) }
        board[move.to] = piece
    }

    private mutating func updateCastlingRights(piece: ChessPiece, from: Square, capturedAt: Square) {
        if piece.kind == .king {
            if piece.color == .white { castlingRights.whiteKingSide = false; castlingRights.whiteQueenSide = false }
            else { castlingRights.blackKingSide = false; castlingRights.blackQueenSide = false }
        }
        let corners: [(Square, WritableKeyPath<CastlingRights, Bool>)] = [
            (Square(file: 0, rank: 0), \.whiteQueenSide), (Square(file: 7, rank: 0), \.whiteKingSide),
            (Square(file: 0, rank: 7), \.blackQueenSide), (Square(file: 7, rank: 7), \.blackKingSide)
        ]
        for (corner, keyPath) in corners where from == corner || capturedAt == corner {
            castlingRights[keyPath: keyPath] = false
        }
    }

    private mutating func updateOutcome() {
        let hasMoves = !allLegalMoves(for: turn).isEmpty
        let inCheck = isKingInCheck(turn)
        if hasMoves { outcome = inCheck ? .check(turn) : .playing }
        else { outcome = inCheck ? .checkmate(winner: turn.opponent) : .stalemate }
    }
}
