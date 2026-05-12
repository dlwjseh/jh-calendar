import SwiftUI
import SwiftData

struct Category: Identifiable {
    let id = UUID()
    var name: String
    var color: Color
    var isChecked: Bool
}

@Model
final class Folder {
    var name: String
    init(name: String) {
        self.name = name
    }
}
