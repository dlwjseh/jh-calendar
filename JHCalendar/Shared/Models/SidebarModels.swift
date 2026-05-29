import SwiftUI
import SwiftData

@Model
final class Category {
    var name: String
    var colorHex: String
    var isChecked: Bool
    var folder: Folder?
    
    @Relationship(deleteRule: .nullify, inverse: \Event.category)
    var events: [Event] = []
    
    init(name: String, color: Color, isChecked: Bool, folder: Folder? = nil) {
        self.name = name
        self.colorHex = color.toHex()
        self.isChecked = isChecked
        self.folder = folder
    }
    
    var color: Color {
        get { Color(hex: colorHex) }
        set { colorHex = newValue.toHex() }
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
