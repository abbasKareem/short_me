import Foundation
import SwiftData

enum ShortcutGroupType: String, CaseIterable, Identifiable {
    case shortcuts = "Shortcuts"
    case textOnly = "Text only"

    var id: String { rawValue }
}

@Model
final class ShortcutGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    var sortOrder: Int
    var createdAt: Date
    var typeRawValue: String = ShortcutGroupType.shortcuts.rawValue
    @Relationship(deleteRule: .cascade, inverse: \ShortcutItem.group)
    var shortcuts: [ShortcutItem]

    var groupType: ShortcutGroupType {
        get { ShortcutGroupType(rawValue: typeRawValue) ?? .shortcuts }
        set { typeRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int,
        createdAt: Date = Date(),
        groupType: ShortcutGroupType = .shortcuts,
        shortcuts: [ShortcutItem] = []
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        typeRawValue = groupType.rawValue
        self.shortcuts = shortcuts
    }
}
