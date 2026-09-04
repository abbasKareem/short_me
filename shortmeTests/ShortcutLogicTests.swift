import CoreGraphics
import Foundation
import SwiftData
import XCTest
@testable import shortme

@MainActor
final class ShortcutLogicTests: XCTestCase {
    func testSeedDataIsPersistedOnlyOnce() throws {
        let schema = Schema([ShortcutGroup.self, ShortcutItem.self])
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
        let suiteName = "ShortcutLogicTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        try SeedDataService.seedIfNeeded(in: container.mainContext, defaults: defaults)
        let seededGroups = try container.mainContext.fetch(FetchDescriptor<ShortcutGroup>())
        XCTAssertEqual(seededGroups.count, 9)
        XCTAssertEqual(seededGroups.first(where: { $0.name == "Development" })?.shortcuts.count, 5)

        let vim = try XCTUnwrap(seededGroups.first(where: { $0.name == "Vim Shortcuts" }))
        XCTAssertEqual(vim.groupType, .shortcuts)
        XCTAssertEqual(vim.shortcuts.count, 20)

        let tmux = try XCTUnwrap(seededGroups.first(where: { $0.name == "Tmux" }))
        XCTAssertEqual(tmux.groupType, .textOnly)
        XCTAssertEqual(tmux.shortcuts.count, 20)
        XCTAssertTrue(tmux.shortcuts.allSatisfy { $0.key.isEmpty })

        let workTasks = try XCTUnwrap(seededGroups.first(where: { $0.name == "Work Tasks" }))
        XCTAssertEqual(workTasks.groupType, .textOnly)
        XCTAssertEqual(workTasks.shortcuts.map(\.name), ["follow up sirwan tasks"])

        let vimium = try XCTUnwrap(seededGroups.first(where: { $0.name == "Vimium Shortcuts" }))
        XCTAssertEqual(vimium.groupType, .shortcuts)
        XCTAssertEqual(vimium.shortcuts.count, 69)

        for group in seededGroups { container.mainContext.delete(group) }
        try container.mainContext.save()
        try SeedDataService.seedIfNeeded(in: container.mainContext, defaults: defaults)
        XCTAssertTrue(try container.mainContext.fetch(FetchDescriptor<ShortcutGroup>()).isEmpty)
        XCTAssertTrue(try container.mainContext.fetch(FetchDescriptor<ShortcutItem>()).isEmpty)
    }

    func testKeyboardShortcutFormatting() {
        XCTAssertEqual(
            KeyboardShortcutFormatter.displayString(key: "P", modifiers: [.command]),
            "⌘P"
        )
        XCTAssertEqual(
            KeyboardShortcutFormatter.displayString(key: "P", modifiers: [.command, .shift]),
            "⇧⌘P"
        )
        XCTAssertEqual(
            KeyboardShortcutFormatter.displayString(key: "`", modifiers: [.control]),
            "⌃`"
        )
        XCTAssertEqual(
            KeyboardShortcutFormatter.displayString(key: "I", modifiers: [.option, .command]),
            "⌥⌘I"
        )
    }

    func testSearchMatchesNameAndFormattedShortcut() {
        XCTAssertTrue(
            ShortcutSearch.matches(
                name: "Toggle Terminal",
                key: "`",
                modifiersRawValue: ShortcutModifiers.control.rawValue,
                query: "terminal"
            )
        )
        XCTAssertTrue(
            ShortcutSearch.matches(
                name: "Quick Open",
                key: "P",
                modifiersRawValue: ShortcutModifiers.command.rawValue,
                query: "⌘P"
            )
        )
        XCTAssertFalse(
            ShortcutSearch.matches(
                name: "Quick Open",
                key: "P",
                modifiersRawValue: ShortcutModifiers.command.rawValue,
                query: "terminal"
            )
        )
    }

    func testPanelOpensRightNearLeftEdge() {
        let visibleFrame = CGRect(x: 0, y: 0, width: 1_000, height: 800)
        let button = CGRect(x: 20, y: 380, width: 28, height: 28)
        let origin = PanelPlacement.origin(
            buttonFrame: button,
            panelSize: CGSize(width: 360, height: 300),
            visibleFrame: visibleFrame
        )
        XCTAssertGreaterThan(origin.x, button.maxX)
    }

    func testPanelOpensLeftNearRightEdge() {
        let visibleFrame = CGRect(x: -1_000, y: -100, width: 1_000, height: 800)
        let button = CGRect(x: -48, y: 300, width: 28, height: 28)
        let origin = PanelPlacement.origin(
            buttonFrame: button,
            panelSize: CGSize(width: 360, height: 300),
            visibleFrame: visibleFrame
        )
        XCTAssertLessThan(origin.x, button.minX)
    }

    func testPanelIsClampedVertically() {
        let visibleFrame = CGRect(x: 0, y: 50, width: 1_000, height: 700)
        let button = CGRect(x: 500, y: 735, width: 28, height: 28)
        let panelSize = CGSize(width: 360, height: 400)
        let origin = PanelPlacement.origin(
            buttonFrame: button,
            panelSize: panelSize,
            visibleFrame: visibleFrame
        )
        XCTAssertGreaterThanOrEqual(origin.y, visibleFrame.minY)
        XCTAssertLessThanOrEqual(origin.y + panelSize.height, visibleFrame.maxY)
    }
}
