import Foundation
import CoreServices

class DirectoryMonitor {
    var onDirectoryChange: () -> Void
    private var stream: FSEventStreamRef?
    private let path: String

    init(path: String, onChange: @escaping () -> Void) {
        self.path = path
        self.onDirectoryChange = onChange
    }

    func start() {
        var context = FSEventStreamContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        
        let callback: FSEventStreamCallback = { (stream, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
            let mySelf = Unmanaged<DirectoryMonitor>.fromOpaque(clientCallBackInfo!).takeUnretainedValue()
            DispatchQueue.main.async {
                mySelf.onDirectoryChange()
            }
        }
        
        let flags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)

        stream = FSEventStreamCreate(nil, callback, &context, [path] as CFArray, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 1.0, flags)
        
        if let stream = stream {
            // --- THIS IS THE DEFINITIVE FIX ---
            // We use the modern Swift RunLoop.Mode to get the default mode's string value
            // and cast it to the CFString type that the older C-based function requires.
            // This avoids all the previous compiler confusion.
            FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), RunLoop.Mode.default.rawValue as CFString)
            
            FSEventStreamStart(stream)
        }
    }
    
    func stop() {
        guard let stream = stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }
    
    deinit {
        stop()
    }
}
