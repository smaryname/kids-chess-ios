# Kids Chess for iOS

A friendly, local two-player chess game for children ages 4–8, built with Swift and SwiftUI.

## Milestone 1

- Complete legal chess movement and captures
- Check, checkmate, and stalemate detection
- Castling, en passant, and promotion
- Tap selection with highlighted legal destinations
- Same-device alternating play and new-game action
- No accounts, backend, analytics, advertising, or external dependencies

## Project structure

- `KidsChess/Domain/ChessGame.swift` — UI-independent chess model and rules
- `KidsChess/GameViewModel.swift` — presentation state and user actions
- `KidsChess/` SwiftUI views — kid-friendly application UI
- `KidsChessTests/` — chess-rule unit tests
- `docs/decisions/` — architecture decision records

## Build and test

Open `KidsChess.xcodeproj` in Xcode 15 or newer. Select an iPhone or iPad simulator and run the `KidsChess` scheme. Run tests with Product → Test (`⌘U`). The deployment target is iOS 16.
