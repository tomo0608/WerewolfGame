# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

This is a SwiftUI iOS app (iOS 17+) without a Package.swift — it uses a standard Xcode project structure.

```bash
# Build
xcodebuild -scheme WerewolfGame -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run all tests
xcodebuild -scheme WerewolfGame -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# Run a single test class
xcodebuild -scheme WerewolfGame -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WerewolfGameTests/GameManagerTests test

# Run a single test method
xcodebuild -scheme WerewolfGame -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WerewolfGameTests/GameManagerTests/testSimpleAttack test
```

## Architecture

**MVVM pattern** with SwiftUI's `@Observable` macro (iOS 17+).

### Layer Responsibilities

- **Models** (`WerewolfGame/Models/`): Pure game logic with no UI dependencies. `GameManager` is the core engine that resolves night actions, day votes, and victory conditions. `RoleType` enum defines all 11 roles with their team, species, seer/medium results, and night action capabilities.
- **ViewModel** (`GameViewModel`): Single `@Observable` class that owns a `GameManager` instance and all UI state. Orchestrates stage transitions and bridges model logic to views.
- **Views** (`WerewolfGame/Views/`): SwiftUI views organized by game phase. `ContentView` switches on `GameStage` to show the appropriate phase view.

### Game Flow (State Machine)

```
InitialSetup → RoleSetup → ConfirmSetup → NightPhase ⇄ DayPhase → GameOver
                                                                      ↓
                                                               (reset to InitialSetup)
```

**Night phase** has per-player sub-stages: handoff → roleReveal → actionSelect → actionResult → done. After all players complete, `resolveNightActions()` processes attacks/guards/curses.

**Day phase**: show night results → discussion timer → voting (batch or individual mode) → execution resolution → victory check.

### Key Game Mechanics

- **Victory**: Fox team wins if any fox survives when wolves are eliminated or dominate. Werewolf team wins when wolves ≥ villagers (by species). Villager team wins when all wolves and foxes are dead.
- **Special deaths**: Nekomata retaliates (kills random werewolf on attack, random alive player on execution). Immoralist suicides when last fox dies. Seer curse kills fox. Guard blocks attacks but not curses.
- **Teams**: Villager (6 roles), Werewolf (3 roles), Fox (2 roles).

### Testing

Tests are in `WerewolfGameTests/` using XCTest with `@testable import WerewolfGame`. Tests cover model logic only (no UI tests). Helper functions `makeGM()`, `makeGMWithRoles()`, and `assignFixedRoles()` set up game state for testing.

## Language

The app UI is entirely in Japanese (人狼ゲーム). Role names, action descriptions, and all user-facing strings are in Japanese. Code identifiers and comments are in English.
