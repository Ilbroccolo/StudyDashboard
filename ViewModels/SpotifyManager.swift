import Foundation
import Combine

class SpotifyManager: ObservableObject {
    @Published var currentTrack: String = "Non in riproduzione"
    @Published var currentArtist: String = ""
    @Published var isPlaying: Bool = false
    
    private var timer: Timer?
    
    init() {
        startPolling()
    }
    
    func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.fetchCurrentTrack()
        }
    }
    
    func fetchCurrentTrack() {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                set currentName to name of current track
                set currentArtist to artist of current track
                set playerState to player state as string
                return currentName & "|||" & currentArtist & "|||" & playerState
            end tell
        else
            return "CHIUSO"
        end if
        """
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let output = appleScript.executeAndReturnError(&error)
            if let stringValue = output.stringValue {
                DispatchQueue.main.async {
                    if stringValue == "CHIUSO" {
                        self.currentTrack = "Spotify chiuso"
                        self.currentArtist = ""
                        self.isPlaying = false
                    } else {
                        let parts = stringValue.components(separatedBy: "|||")
                        if parts.count == 3 {
                            self.currentTrack = parts[0]
                            self.currentArtist = parts[1]
                            self.isPlaying = (parts[2] == "playing")
                        }
                    }
                }
            }
        }
    }
    
    func togglePlayPause() {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify" to playpause
        end if
        """
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            fetchCurrentTrack()
        }
    }
    
    func nextTrack() {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify" to next track
        end if
        """
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            fetchCurrentTrack()
        }
    }
    
    func previousTrack() {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify" to previous track
        end if
        """
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            fetchCurrentTrack()
        }
    }
}
