import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    var selectedGroupID: UUID?
    var searchQuery = ""
    var isShortcutPanelVisible = false

    func resetBrowser() {
        selectedGroupID = nil
        searchQuery = ""
    }
}
