import SwiftUI

struct Category: Identifiable {
    let id = UUID()
    var name: String
    var color: Color
    var isChecked: Bool
}

struct Folder: Identifiable {
    let id = UUID()
    var name: String
    var categories: [Category]
}

extension Folder {
    static let sample: [Folder] = [
        Folder(name: "iCloud", categories: [
            Category(name: "집", color: .red, isChecked: true),
            Category(name: "직장", color: .yellow, isChecked: true)
        ]),
        Folder(name: "기타", categories: [
            Category(name: "예정된 미리 알림", color: .blue, isChecked: false),
            Category(name: "생일", color: .orange, isChecked: true),
            Category(name: "대한민국 공휴일", color: .purple, isChecked: true),
            Category(name: "Siri 제안", color: .brown, isChecked: false)
        ])
    ]
}
