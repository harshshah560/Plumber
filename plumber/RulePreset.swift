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
    let conditionType: RuleCondition.ConditionType

    // A static array of all our presets for the chooser view
    static let allPresets: [RulePreset] = [
        RulePreset(name: "Organize Documents",
                   description: "Sorts .pdf, .docx, .pages, .txt files.",
                   iconName: "doc.text.fill",
                   iconColor: .blue,
                   defaultExtensions: ["pdf", "docx", "doc", "pages", "txt"],
                   defaultFolderName: "Documents",
                   conditionType: .fileExtension),
                   
        RulePreset(name: "Organize Images",
                   description: "Sorts .jpg, .png, .heic, .tiff files.",
                   iconName: "photo.fill",
                   iconColor: .green,
                   defaultExtensions: ["jpg", "jpeg", "png", "gif", "heic", "tiff", "webp"],
                   defaultFolderName: "Images",
                   conditionType: .fileExtension),
                   
        RulePreset(name: "Organize Videos",
                   description: "Sorts .mov, .mp4, .mkv files.",
                   iconName: "video.fill",
                   iconColor: .orange,
                   defaultExtensions: ["mov", "mp4", "m4v", "mkv", "avi"],
                   defaultFolderName: "Videos",
                   conditionType: .fileExtension),
                   
        RulePreset(name: "Organize Archives",
                   description: "Sorts .zip, .rar, .7z files.",
                   iconName: "archivebox.fill",
                   iconColor: .purple,
                   defaultExtensions: ["zip", "rar", "7z", "tar", "gz"],
                   defaultFolderName: "Archives",
                   conditionType: .fileExtension)
    ]
}
