import Foundation
import SwiftUI

struct RulePreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let iconName: String
    let iconColor: Color
    let defaultExtensions: [String]
    let defaultFolderName: String
    // FIX: Renamed from RuleCondition.ConditionType
    let conditionType: Condition.ConditionType

    // FIX: Manually conform to Equatable and Hashable since Color is not Hashable
    static func == (lhs: RulePreset, rhs: RulePreset) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // A static array of all our presets for the chooser view
    static let allPresets: [RulePreset] = [
        RulePreset(name: "Organize Documents",
                   description: "Sorts .pdf, .docx, .pages, .txt files.",
                   iconName: "doc.text.fill",
                   // FIX: Explicitly use Color type
                   iconColor: Color.blue,
                   defaultExtensions: ["pdf", "docx", "doc", "pages", "txt", "md"],
                   defaultFolderName: "Documents",
                   // FIX: Use the correct ConditionType enum
                   conditionType: .fileExtension),
                   
        RulePreset(name: "Organize Images",
                   description: "Sorts .jpg, .png, .heic, .tiff files.",
                   iconName: "photo.fill",
                   iconColor: Color.green,
                   defaultExtensions: ["jpg", "jpeg", "png", "gif", "heic", "tiff", "webp"],
                   defaultFolderName: "Images",
                   conditionType: .fileExtension),
                   
        RulePreset(name: "Organize Videos",
                   description: "Sorts .mov, .mp4, .mkv files.",
                   iconName: "video.fill",
                   iconColor: Color.orange,
                   defaultExtensions: ["mov", "mp4", "m4v", "mkv", "avi"],
                   defaultFolderName: "Videos",
                   conditionType: .fileExtension),
                   
        RulePreset(name: "Organize Archives",
                   description: "Sorts .zip, .rar, .7z files.",
                   iconName: "archivebox.fill",
                   iconColor: Color.purple,
                   defaultExtensions: ["zip", "rar", "7z", "tar", "gz"],
                   defaultFolderName: "Archives",
                   conditionType: .fileExtension)
    ]
}
