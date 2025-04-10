# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Test Commands
- Build: Use Xcode (⌘B) or `xcodebuild -project MRIQuantSim.xcodeproj -scheme MRIQuantSim`
- Run: Use Xcode (⌘R) or `xcodebuild -project MRIQuantSim.xcodeproj -scheme MRIQuantSim run`
- Test all: Use Xcode (⌘U) or `xcodebuild test -project MRIQuantSim.xcodeproj -scheme MRIQuantSim`
- Test single: Use Test Navigator in Xcode or `xcodebuild test -project MRIQuantSim.xcodeproj -scheme MRIQuantSim -only-testing:MRIQuantSimTests/[TestClassName]/[testMethodName]`

## Code Style Guidelines
- Swift version: Swift 6.0 for app, Swift 5.0 for tests
- Types: Use PascalCase for types (`ContentView`, `Item`)
- Variables/Functions: Use camelCase (`addItem()`, `timestamp`)
- Views: SwiftUI views as structs conforming to `View` protocol
- Imports: Group imports at top (`SwiftUI`, `Foundation`, `SwiftData`)
- Error handling: Use Swift's do-catch pattern; `fatalError()` only for critical failures
- Models: Use SwiftData `@Model` annotation for persistence
- View models: Use `@Observable` for reactive state
- Testing: Use XCTest framework with proper setup/teardown methods

Always build and test changes before submitting PRs.
