# ADR-002 — Local-first MVP

- **Status:** Accepted
- **Decision:** Keep Milestone 1 entirely on-device, with no backend or user accounts.
- **Why:** Two children play together on the same device. Local state provides the simplest implementation, strong privacy, no operating infrastructure, offline play, and faster product experimentation.
- **Alternatives considered:** A hosted game service; peer-to-peer networking; account-backed cloud synchronization.
- **Tradeoffs:** Games and progress do not synchronize across devices, there is no remote multiplayer, and reinstalling the app discards transient game state. These capabilities are outside the MVP goal.
- **When to reconsider:** Revisit when online multiplayer, cross-device synchronization, durable child profiles, shared parent dashboards, or cloud backup becomes an approved requirement.
