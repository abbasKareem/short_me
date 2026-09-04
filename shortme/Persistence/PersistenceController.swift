import Foundation
import SwiftData

@MainActor
final class PersistenceController {
    let container: ModelContainer
    let startupError: Error?

    init() {
        let schema = Schema([ShortcutGroup.self, ShortcutItem.self])
        do {
            container = try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            )
            startupError = nil
        } catch {
            startupError = error
            do {
                container = try ModelContainer(
                    for: schema,
                    configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                )
            } catch {
                preconditionFailure("Unable to create even an in-memory model container: \(error)")
            }
        }
    }
}
