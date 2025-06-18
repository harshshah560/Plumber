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
    let conditionType: Condition.ConditionType

    static func == (lhs: RulePreset, rhs: RulePreset) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // A static array of all our presets for the chooser view
    static let allPresets: [RulePreset] = [
        RulePreset(name: "Organize Documents",
                   description: "Sorts common document files (.pdf, .docx, .txt, .pages, etc.).",
                   iconName: "doc.text.fill",
                   iconColor: Color.blue,
                   defaultExtensions: ["pdf", "docx", "doc", "pages", "txt", "md", "rtf", "csv", "xls", "xlsx", "ppt", "pptx"],
                   defaultFolderName: "Documents",
                   conditionType: .fileExtension),
                   
        RulePreset(name: "Organize Images",
                   description: "Sorts all common image files (.jpg, .png, .gif, .heic, .raw, etc.).",
                   iconName: "photo.fill",
                   iconColor: Color.green,
                   defaultExtensions: ["jpg", "jpeg", "png", "gif", "heic", "tiff", "webp", "svg", "bmp", "psd", "ai", "cr2", "nef", "arw"],
                   defaultFolderName: "Images",
                   conditionType: .fileExtension),
                   
        RulePreset(name: "Organize Videos",
                   description: "Sorts common video files (.mov, .mp4, .mkv, .avi, etc.).",
                   iconName: "video.fill",
                   iconColor: Color.orange,
                   defaultExtensions: ["mov", "mp4", "m4v", "mkv", "avi", "webm", "flv"],
                   defaultFolderName: "Videos",
                   conditionType: .fileExtension),
        
        RulePreset(name: "Organize Audio Files",
                   description: "Sorts music and audio files (.mp3, .m4a, .wav, .flac, etc.).",
                   iconName: "speaker.wave.3.fill",
                   iconColor: Color.pink,
                   defaultExtensions: ["mp3", "m4a", "wav", "flac", "aac", "ogg"],
                   defaultFolderName: "Audio",
                   conditionType: .fileExtension),
        
        RulePreset(name: "Organize Screenshots",
                   description: "Finds files starting with 'Screenshot' and moves them.",
                   iconName: "camera.viewfinder",
                   iconColor: Color.indigo,
                   defaultExtensions: [], // Not used for this condition type
                   defaultFolderName: "Screenshots",
                   conditionType: .nameBeginsWith), // This preset uses a different condition
                   
        RulePreset(name: "Organize Archives",
                   description: "Sorts compressed archive files (.zip, .rar, .7z, etc.).",
                   iconName: "archivebox.fill",
                   iconColor: Color.purple,
                   defaultExtensions: ["zip", "rar", "7z", "tar", "gz"],
                   defaultFolderName: "Archives",
                   conditionType: .fileExtension),
                   
        RulePreset(name: "Organize Developer Files",
                   description: "Sorts common source code files (.swift, .js, .py, .html, etc.).",
                   iconName: "curlybraces.square.fill",
                   iconColor: Color.cyan,
                   defaultExtensions: ["swift", "js", "ts", "html", "css", "py", "java", "cpp", "h", "cs", "go", "rb", "php"],
                   defaultFolderName: "Code",
                   conditionType: .fileExtension)
    ]
}
