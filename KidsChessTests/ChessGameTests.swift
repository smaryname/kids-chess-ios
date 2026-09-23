import XCTest
@testable import KidsChess

final class ChessGameTests: XCTestCase {
    private func sq(_ notation: String) -> Square { Square(notation)! }
    private func piece(_ color: PieceColor, _ kind: PieceKind) -> ChessPiece { ChessPiece(color: color, kind: kind) }

    func testStartingPositionAndNormalMovement() {
        var game = ChessGame()
        XCTAssertEqual(game.board.count, 32)
        XCTAssertTrue(game.move(from: sq("e2"), to: sq("e4")))
        XCTAssertEqual(game[sq("e4")], piece(.white, .pawn))
        XCTAssertEqual(game.turn, .black)
    }

    func testIllegalMoveIsRejectedAndTurnDoesNotChange() {
        var game = ChessGame()
        XCTAssertFalse(game.move(from: sq("e2"), to: sq("e5")))
        XCTAssertEqual(game[sq("e2")], piece(.white, .pawn))
        XCTAssertEqual(game.turn, .white)
    }

    func testCapture() {
        var game = ChessGame()
        XCTAssertTrue(game.move(from: sq("e2"), to: sq("e4")))
        XCTAssertTrue(game.move(from: sq("d7"), to: sq("d5")))
        XCTAssertTrue(game.move(from: sq("e4"), to: sq("d5")))
        XCTAssertEqual(game[sq("d5")], piece(.white, .pawn))
        XCTAssertNil(game[sq("e4")])
    }

    func testCheck() {
        let game = ChessGame(board: [
            sq("e1"): piece(.white, .king), sq("e8"): piece(.black, .king), sq("e7"): piece(.white, .rook)
        ], turn: .black)
        XCTAssertEqual(game.outcome, .check(.black))
    }

    func testFoolsMateIsCheckmate() {
        var game = ChessGame()
        XCTAssertTrue(game.move(from: sq("f2"), to: sq("f3")))
        XCTAssertTrue(game.move(from: sq("e7"), to: sq("e5")))
        XCTAssertTrue(game.move(from: sq("g2"), to: sq("g4")))
        XCTAssertTrue(game.move(from: sq("d8"), to: sq("h4")))
        XCTAssertEqual(game.outcome, .checkmate(winner: .black))
    }

    func testStalemate() {
        let game = ChessGame(board: [
            sq("a8"): piece(.black, .king), sq("c6"): piece(.white, .king), sq("b6"): piece(.white, .queen)
        ], turn: .black)
        XCTAssertEqual(game.outcome, .stalemate)
    }

    func testKingSideCastlingMovesKingAndRook() {
        var game = ChessGame(board: [
            sq("e1"): piece(.white, .king), sq("h1"): piece(.white, .rook), sq("e8"): piece(.black, .king)
        ], turn: .white, castlingRights: CastlingRights(
            whiteKingSide: true, whiteQueenSide: false, blackKingSide: false, blackQueenSide: false))
        XCTAssertTrue(game.move(from: sq("e1"), to: sq("g1")))
        XCTAssertEqual(game[sq("g1")], piece(.white, .king))
        XCTAssertEqual(game[sq("f1")], piece(.white, .rook))
        XCTAssertNil(game[sq("h1")])
    }

    func testCannotCastleThroughCheck() {
        let game = ChessGame(board: [
            sq("e1"): piece(.white, .king), sq("h1"): piece(.white, .rook),
            sq("e8"): piece(.black, .king), sq("f8"): piece(.black, .rook)
        ], turn: .white, castlingRights: CastlingRights(
            whiteKingSide: true, whiteQueenSide: false, blackKingSide: false, blackQueenSide: false))
        XCTAssertFalse(game.legalMoves(from: sq("e1")).contains { $0.to == sq("g1") })
    }

    func testEnPassantIsAvailableOnlyImmediately() {
        var game = ChessGame()
        XCTAssertTrue(game.move(from: sq("e2"), to: sq("e4")))
        XCTAssertTrue(game.move(from: sq("a7"), to: sq("a6")))
        XCTAssertTrue(game.move(from: sq("e4"), to: sq("e5")))
        XCTAssertTrue(game.move(from: sq("d7"), to: sq("d5")))
        XCTAssertTrue(game.move(from: sq("e5"), to: sq("d6")))
        XCTAssertEqual(game[sq("d6")], piece(.white, .pawn))
        XCTAssertNil(game[sq("d5")])
    }

    func testPromotion() {
        var game = ChessGame(board: [
            sq("e1"): piece(.white, .king), sq("e8"): piece(.black, .king), sq("a7"): piece(.white, .pawn)
        ])
        XCTAssertTrue(game.move(from: sq("a7"), to: sq("a8"), promotion: .knight))
        XCTAssertEqual(game[sq("a8")], piece(.white, .knight))
    }

    func testPinnedPieceCannotExposeKing() {
        let game = ChessGame(board: [
            sq("e1"): piece(.white, .king), sq("e2"): piece(.white, .rook),
            sq("e8"): piece(.black, .rook), sq("a8"): piece(.black, .king)
        ])
        XCTAssertFalse(game.legalMoves(from: sq("e2")).contains { $0.to == sq("d2") })
    }
}
