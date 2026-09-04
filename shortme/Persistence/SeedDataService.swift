import Foundation
import SwiftData

@MainActor
enum SeedDataService {
    private struct SeedItem {
        let name: String
        let key: String
        let modifiers: ShortcutModifiers

        init(_ name: String, _ key: String = "", _ modifiers: ShortcutModifiers = []) {
            self.name = name
            self.key = key
            self.modifiers = modifiers
        }
    }

    private struct SeedGroup {
        let name: String
        let type: ShortcutGroupType
        let items: [SeedItem]
    }

    private static let seededKey = "hasSeededInitialShortcutData"
    private static let seedVersionKey = "shortcutSeedDataVersion"
    private static let currentSeedVersion = 2

    static func seedIfNeeded(in context: ModelContext, defaults: UserDefaults = .standard) throws {
        let hasInitialSeed = defaults.bool(forKey: seededKey)
        let installedVersion = defaults.integer(forKey: seedVersionKey)
        guard !hasInitialSeed || installedVersion < currentSeedVersion else { return }

        let descriptor = FetchDescriptor<ShortcutGroup>(
            sortBy: [SortDescriptor(\ShortcutGroup.sortOrder)]
        )
        let existingGroups = try context.fetch(descriptor)
        var existingNames = Set(existingGroups.map { normalizedName($0.name) })
        var nextSortOrder = (existingGroups.map(\.sortOrder).max() ?? -1) + 1

        if !hasInitialSeed && existingGroups.isEmpty {
            insert(
                groups: originalSeedGroups,
                existingNames: &existingNames,
                nextSortOrder: &nextSortOrder,
                in: context
            )
        }

        if installedVersion < currentSeedVersion {
            insert(
                groups: requestedSeedGroups,
                existingNames: &existingNames,
                nextSortOrder: &nextSortOrder,
                in: context
            )
        }

        try context.save()
        defaults.set(true, forKey: seededKey)
        defaults.set(currentSeedVersion, forKey: seedVersionKey)
    }

    private static func insert(
        groups: [SeedGroup],
        existingNames: inout Set<String>,
        nextSortOrder: inout Int,
        in context: ModelContext
    ) {
        for definition in groups where !existingNames.contains(normalizedName(definition.name)) {
            let group = ShortcutGroup(
                name: definition.name,
                sortOrder: nextSortOrder,
                groupType: definition.type
            )
            context.insert(group)

            let newestDate = Date()
            for (itemIndex, definition) in definition.items.enumerated() {
                let item = ShortcutItem(
                    name: definition.name,
                    key: definition.key,
                    modifiersRawValue: definition.modifiers.rawValue,
                    sortOrder: itemIndex,
                    createdAt: newestDate.addingTimeInterval(-Double(itemIndex))
                )
                context.insert(item)
                group.shortcuts.append(item)
            }

            existingNames.insert(normalizedName(definition.name))
            nextSortOrder += 1
        }
    }

    private static func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static let originalSeedGroups: [SeedGroup] = [
        SeedGroup(name: "Development", type: .shortcuts, items: [
            SeedItem("Open Command Palette", "P", [.shift, .command]),
            SeedItem("Quick Open", "P", [.command]),
            SeedItem("Find in Files", "F", [.shift, .command]),
            SeedItem("Toggle Terminal", "`", [.control]),
            SeedItem("Build", "B", [.shift, .command]),
        ]),
        SeedGroup(name: "Productivity", type: .shortcuts, items: [
            SeedItem("Copy", "C", [.command]),
            SeedItem("Paste", "V", [.command]),
            SeedItem("Undo", "Z", [.command]),
            SeedItem("Redo", "Z", [.shift, .command]),
        ]),
        SeedGroup(name: "Design", type: .shortcuts, items: []),
        SeedGroup(name: "System", type: .shortcuts, items: []),
        SeedGroup(name: "Custom", type: .shortcuts, items: []),
    ]

    private static let requestedSeedGroups: [SeedGroup] = [
        SeedGroup(name: "Vim Shortcuts", type: .shortcuts, items: vimShortcuts),
        SeedGroup(name: "Tmux", type: .textOnly, items: tmuxCommands),
        SeedGroup(name: "Work Tasks", type: .textOnly, items: [
            SeedItem("follow up sirwan tasks"),
        ]),
        SeedGroup(name: "Vimium Shortcuts", type: .shortcuts, items: vimiumShortcuts),
    ]

    private static let vimShortcuts: [SeedItem] = [
        SeedItem("Move left", "h"),
        SeedItem("Move down", "j"),
        SeedItem("Move up", "k"),
        SeedItem("Move right", "l"),
        SeedItem("Enter Insert mode before the cursor", "i"),
        SeedItem("Enter Insert mode after the cursor", "a"),
        SeedItem("Return to Normal mode", "escape"),
        SeedItem("Go to the start of the line", "0"),
        SeedItem("Go to the end of the line", "$"),
        SeedItem("Jump to the next word", "w"),
        SeedItem("Jump to the previous word", "b"),
        SeedItem("Go to the first line", "gg"),
        SeedItem("Go to the last line", "G"),
        SeedItem("Delete the current line", "dd"),
        SeedItem("Copy the current line", "yy"),
        SeedItem("Paste after the cursor", "p"),
        SeedItem("Undo the last change", "u"),
        SeedItem("Redo the last undone change", "R", [.control]),
        SeedItem("Save the file", ":w"),
        SeedItem("Save and quit", ":wq"),
    ]

    private static let tmuxCommands: [SeedItem] = [
        SeedItem("Ctrl + b then %: Split the pane vertically"),
        SeedItem("Ctrl + b then \u{22}: Split the pane horizontally"),
        SeedItem("Ctrl + b then c: Create a new window"),
        SeedItem("Ctrl + b then n: Go to the next window"),
        SeedItem("Ctrl + b then p: Go to the previous window"),
        SeedItem("Ctrl + b then 0-9: Switch to a numbered window"),
        SeedItem("Ctrl + b then ,: Rename the current window"),
        SeedItem("Ctrl + b then &: Close the current window"),
        SeedItem("Ctrl + b then x: Close the active pane"),
        SeedItem("Ctrl + b then o: Move to the next pane"),
        SeedItem("Ctrl + b then ;: Move to the previously active pane"),
        SeedItem("Ctrl + b then Arrow key: Move focus to another pane"),
        SeedItem("Ctrl + b then q, then a number: Jump to a numbered pane"),
        SeedItem("Ctrl + b then z: Toggle zoom for the active pane"),
        SeedItem("Ctrl + b then {: Move the active pane left"),
        SeedItem("Ctrl + b then }: Move the active pane right"),
        SeedItem("Ctrl + b then [: Enter copy mode"),
        SeedItem("Ctrl + b then ]: Paste the copied buffer"),
        SeedItem("Ctrl + b then d: Detach from the current session"),
        SeedItem("Ctrl + b then s: Choose a session"),
    ]

    // Current default mappings from Vimium's official commands.js.
    private static let vimiumShortcuts: [SeedItem] = [
        SeedItem("Scroll down", "j"),
        SeedItem("Scroll up", "k"),
        SeedItem("Scroll left", "h"),
        SeedItem("Scroll right", "l"),
        SeedItem("Scroll to the top", "gg"),
        SeedItem("Scroll to the bottom", "G"),
        SeedItem("Scroll all the way left", "zH"),
        SeedItem("Scroll all the way right", "zL"),
        SeedItem("Scroll down", "E", [.control]),
        SeedItem("Scroll up", "Y", [.control]),
        SeedItem("Scroll down half a page", "d"),
        SeedItem("Scroll up half a page", "u"),
        SeedItem("Reload the page", "r"),
        SeedItem("Reload the page without cache", "R"),
        SeedItem("Copy the current URL", "yy"),
        SeedItem("Open the copied URL in the current tab", "p"),
        SeedItem("Open the copied URL in a new tab", "P"),
        SeedItem("Focus the first text input", "gi"),
        SeedItem("Follow the previous-page link", "[["),
        SeedItem("Follow the next-page link", "]]"),
        SeedItem("Focus the next frame", "gf"),
        SeedItem("Focus the main frame", "gF"),
        SeedItem("Go up one level in the URL", "gu"),
        SeedItem("Go to the root of the URL", "gU"),
        SeedItem("Enter Insert mode", "i"),
        SeedItem("Enter Visual mode", "v"),
        SeedItem("Enter Visual Line mode", "V"),
        SeedItem("Open a link in the current tab", "f"),
        SeedItem("Open a link in a new tab", "F"),
        SeedItem("Open multiple links in new tabs", "F", [.option]),
        SeedItem("Copy a link URL", "yf"),
        SeedItem("Enter Find mode", "/"),
        SeedItem("Find the next match", "n"),
        SeedItem("Find the previous match", "N"),
        SeedItem("Find the selected text", "*"),
        SeedItem("Find the selected text backwards", "#"),
        SeedItem("Open a URL, bookmark, or history entry", "o"),
        SeedItem("Open a URL, bookmark, or history entry in a new tab", "O"),
        SeedItem("Search open tabs", "T"),
        SeedItem("Open a bookmark", "b"),
        SeedItem("Open a bookmark in a new tab", "B"),
        SeedItem("Open a Vimium command", ":"),
        SeedItem("Edit the current URL", "ge"),
        SeedItem("Edit the current URL and open it in a new tab", "gE"),
        SeedItem("Go back in history", "H"),
        SeedItem("Go forward in history", "L"),
        SeedItem("Go to the next tab", "K"),
        SeedItem("Go to the previous tab", "J"),
        SeedItem("Go to the next tab", "gt"),
        SeedItem("Go to the previous tab", "gT"),
        SeedItem("Go to the previously visited tab", "^"),
        SeedItem("Move the tab left", "<<"),
        SeedItem("Move the tab right", ">>"),
        SeedItem("Go to the first tab", "g0"),
        SeedItem("Go to the last tab", "g$"),
        SeedItem("Move the tab to a new window", "W"),
        SeedItem("Create a new tab", "t"),
        SeedItem("Duplicate the current tab", "yt"),
        SeedItem("Close the current tab", "x"),
        SeedItem("Restore the closed tab", "X"),
        SeedItem("Toggle pinning for the current tab", "P", [.option]),
        SeedItem("Toggle muting for the current tab", "M", [.option]),
        SeedItem("Zoom in", "zi"),
        SeedItem("Zoom out", "zo"),
        SeedItem("Reset zoom", "z0"),
        SeedItem("Create a mark, then type its letter", "m"),
        SeedItem("Jump to a mark, then type its letter", "`"),
        SeedItem("Show Vimium help", "?"),
        SeedItem("Toggle the page source view", "gs"),
    ]
}
