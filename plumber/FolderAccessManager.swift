// FolderAccessManager.swift
import Foundation
import AppKit

class FolderAccessManager {
    private static let bookmarksKey = "folderBookmarkData"

    static func saveBookmark(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            var bookmarks = loadBookmarks()
            bookmarks[url.path] = bookmarkData
            save(bookmarks)
        } catch {
            print("❌ Failed to save bookmark for \(url.path): \(error.localizedDescription)")
        }
    }
    
    static func removeBookmark(for url: URL) {
        var bookmarks = loadBookmarks()
        if bookmarks.removeValue(forKey: url.path) != nil {
            save(bookmarks)
        }
    }

    static func restoreAllAccess() -> Int {
        let bookmarks = loadBookmarks()
        var restoredCount = 0
        for (_, data) in bookmarks {
            if restoreAccess(for: data) {
                restoredCount += 1
            }
        }
        print("✅ Restored access to \(restoredCount) of \(bookmarks.count) bookmarked folders.")
        return restoredCount
    }

    private static func restoreAccess(for data: Data) -> Bool {
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale { saveBookmark(for: url) }
            return url.startAccessingSecurityScopedResource()
        } catch {
            print("❌ Failed to restore bookmark: \(error.localizedDescription)")
            return false
        }
    }
    
    private static func loadBookmarks() -> [String: Data] {
        guard let data = UserDefaults.standard.data(forKey: bookmarksKey) else { return [:] }
        return (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String: Data]) ?? [:]
    }
    
    private static func save(_ bookmarks: [String: Data]) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: bookmarks, requiringSecureCoding: false)
            UserDefaults.standard.set(data, forKey: bookmarksKey)
        } catch {
            print("❌ Failed to save bookmarks dictionary: \(error.localizedDescription)")
        }
    }
}
