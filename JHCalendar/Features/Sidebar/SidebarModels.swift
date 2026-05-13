import SwiftUI
import SwiftData

@Model
final class Category {
    var name: String
//    var colorHex: String
    var isChecked: Bool
    var folder: Folder?
    init(name: String, isChecked: Bool, folder: Folder? = nil) {
        self.name = name
//        self.colorHex = colorHex
        self.isChecked = isChecked
        self.folder = folder
    }
}

@Model
final class Folder {
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \Category.folder)
    var categories: [Category] = []
    init(name: String) {
        self.name = name
    }
}
