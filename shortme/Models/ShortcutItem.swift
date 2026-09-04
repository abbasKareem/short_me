import Foundation
import SwiftData

@Model
final class ShortcutItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var key: String
    var modifiersRawValue: Int
    var sortOrder: Int
    var createdAt: Date
    var group: ShortcutGroup?

    init(
        id: UUID = UUID(),
        name: String,
        key: String,
        modifiersRawValue: Int,
        sortOrder: Int,
        createdAt: Date = Date(),
        group: ShortcutGroup? = nil
    ) {
        self.id = id
        self.name = name
        self.key = key
        self.modifiersRawValue = modifiersRawValue
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.group = group
    }
}
