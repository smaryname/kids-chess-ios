# ADR-001 — Swift + SwiftUI

- **Status:** Accepted
- **Decision:** Build the client with native Swift and SwiftUI.
- **Why:** The initial product is iOS-first. Native frameworks give direct access to Apple UI conventions, accessibility, speech, animation, haptics, and gaming capabilities while keeping the toolchain straightforward.
- **Alternatives considered:** UIKit; a cross-platform framework such as Flutter or React Native; a browser-based app.
- **Tradeoffs:** SwiftUI is concise and integrates well with iOS, but this choice does not provide a shared Android client. Some advanced controls may still require UIKit interoperability later.
- **When to reconsider:** Revisit if Android becomes a committed product target, if shared client logic becomes more valuable than native integration, or if a required interaction cannot be delivered reliably with SwiftUI.
