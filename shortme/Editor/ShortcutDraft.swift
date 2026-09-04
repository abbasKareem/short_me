import Foundation

struct ShortcutDraft: Identifiable, Equatable {
    var id: UUID
    var name: String
    var key: String
    var modifiers: ShortcutModifiers
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String = "",
        key: String = "",
        modifiers: ShortcutModifiers = [],
        sortOrder: Int
    ) {
        self.id = id
        self.name = name
        self.key = key
        self.modifiers = modifiers
        self.sortOrder = sortOrder
    }
}
