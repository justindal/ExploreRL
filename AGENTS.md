# Repository Guidelines

## Project Structure

ExploreRL is a Swift 6 SwiftUI app for on-device reinforcement-learning experiments using Gymnazo and MLX Swift. `ExploreRL/` contains the app target: keep startup in `ExploreRLApp.swift`, root navigation in `Root/`, and shared code in `Core/`. Put each capability in `Features/<Feature>/` with `Models/`, `Views/`, and `ViewModels/`; use `Views/Components/` and `Utils/` only for feature-local reusable code. Assets belong in `Assets.xcassets`.

Keep the structure clean: avoid god files, split complex views into focused components, and use MVVM. Views render state and send intents; view models coordinate work; models own data and configuration.

## Platform, Style, and Scope

Target iOS 18+ and macOS 15+ with current, non-deprecated SwiftUI APIs. Follow Swift API Design Guidelines: `PascalCase` types, `camelCase` members, four-space indentation, and concise Swifty names such as `TrainingConfig` and `TrainViewModel`. Keep changed code consistent with its neighbors; no formatter or linter is configured.

Write safe, concurrency-aware Swift. Do not add explanatory code comments; use DocC for public API documentation. Only make code changes explicitly requested. When reporting work, lead with a recommendation and the reason for it. Consult an applicable skill (especially `mlx-swift` or `swift-concurrency-pro`) and official documentation when behavior is uncertain—do not guess.

## MLX and Gymnazo Integration

MLX execution is lazy. Call `eval()` only at required materialization boundaries, and avoid unnecessary conversion between `MLXArray` and Swift arrays/scalars. Keep MLX state concurrency-isolated. Gymnazo provides environments and algorithm utilities; preserve its typed API contracts and validate changes against the related package when integration behavior changes.

## Build, Test, and Validation

Open `ExploreRL.xcodeproj` in Xcode and run the `ExploreRL` scheme on iOS or macOS. For command-line validation, use Xcode—not SwiftPM, because MLX requires Metal shader compilation:

```bash
xcodebuild -project ExploreRL.xcodeproj -scheme ExploreRL \
  -destination 'platform=macOS' build
```

After a large change, build and resolve errors before handoff. No XCTest target is currently checked in; manually verify the changed flow and add focused XCTest coverage with names such as `testSaveSession_whenArchiveIsValid_restoresConfig()`. When a test target exists, run `xcodebuild test` serially; never run Xcode tests in parallel.

## Commits and Pull Requests

Use established imperative Conventional Commit-style prefixes: `fix:`, `refactor:`, `chore:`, and `ci:`. Keep commits focused. Pull requests should describe the user-visible change, validation, linked issue when applicable, and screenshots or recordings for UI changes. Call out training behavior, persistence-format, MLX-memory, and dependency changes explicitly.
