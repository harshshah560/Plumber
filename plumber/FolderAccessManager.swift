//
//  FolderAccessManager 2.swift
//  plumber
//
//  Created by Harsh Shah on 6/17/25.
//


import Foundation

class FolderAccessManager {
    private static let bookmarkDataKey = "monitoringFolderBookmark"

    static func saveBookmark(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkDataKey)
        } catch {
            print("❌ Failed to save bookmark: \(error.localizedDescription)")
        }
    }

    static func restoreAccess() -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkDataKey) else { return nil }
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale { saveBookmark(for: url) }
            
            if url.startAccessingSecurityScopedResource() {
                return url
            }
        } catch {
            print("❌ Failed to restore bookmark: \(error.localizedDescription)")
        }
        return nil
    }
}
