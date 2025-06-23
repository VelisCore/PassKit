import Foundation
import Combine
import SwiftUI
import AppKit

/// Manages installation of Homebrew and dependencies, with live log streaming and cancellation.
class DependencyInstaller: ObservableObject {
    @Published var installing = false
    @Published var logs: [String] = []
    @Published var finished = false
    @Published var errorMessage: String?

    /// Starts the full installation process.
    func installAll() {
        guard !installing else { return }  // prevent double start
        installing = true
        logs = []
        finished = false
        errorMessage = nil

        let script = generateInstallScript()
        logs.append("🚀 Opening Terminal to install dependencies...")
        logs.append("Please follow the instructions and allow any prompts in the Terminal window that appears.")
        Task {
            do {
                try runCommandInTerminal(script)
                await MainActor.run {
                    self.logs.append("✅ Installation script launched in Terminal.")
                    self.finished = true
                    self.installing = false
                }
            } catch {
                await MainActor.run {
                    self.logs.append("❌ Failed to open Terminal: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    self.finished = false
                    self.installing = false
                }
            }
        }
    }

    /// Cancels any ongoing installation.
    func cancel() {
        // Without direct process control, just update state and log cancellation.
        installing = false
        logs.append("❌ Installation cancelled by user.")
    }

    // MARK: - Private methods
    
    private func generateInstallScript() -> String {
        """
        set -euo pipefail

        # Explicitly set PATH to include Homebrew and system paths
        export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

        # Install Homebrew if not installed
        if ! command -v brew >/dev/null 2>&1; then
          echo "Homebrew not found. Installing..."
          /usr/bin/env bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
          echo "Homebrew already installed."
        fi

        # Configure brew environment depending on architecture
        if [[ "$(uname -m)" == "arm64" ]]; then
          eval "$(/opt/homebrew/bin/brew shellenv)"
        else
          eval "$(/usr/local/bin/brew shellenv)"
        fi

        # Update Homebrew to latest
        brew update

        # Install dependencies
        brew install libimobiledevice usbmuxd ideviceinstaller ifuse libplist openssl
        """
    }

    /// Runs given command script in Terminal using AppleScript.
    private func runCommandInTerminal(_ script: String) throws {
        let appleScriptSource = """
        tell application "Terminal"
            activate
            do script "\(script.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "; "))"
        end tell
        """
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScriptSource) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                throw NSError(domain: "AppleScriptError", code: 1, userInfo: error as? [String: Any])
            }
        } else {
            throw NSError(domain: "AppleScriptError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create AppleScript object"])
        }
    }
}
