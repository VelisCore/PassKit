import Foundation
import Combine
import SwiftUI

/// Manages installation of Homebrew and dependencies, with live log streaming and cancellation.
class DependencyInstaller: ObservableObject {
    @Published var installing = false
    @Published var logs: [String] = []
    @Published var finished = false
    @Published var errorMessage: String?

    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    
    private var cancellables = Set<AnyCancellable>()

    /// Starts the full installation process.
    func installAll() {
        guard !installing else { return }  // prevent double start
        
        installing = true
        logs = []
        finished = false
        errorMessage = nil

        // Build the full shell script
        let script = generateInstallScript()

        Task.detached { [weak self] in
            await self?.runShellScript(script)
        }
    }

    /// Cancels any ongoing installation.
    func cancel() {
        process?.terminate()
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


    /// Runs the given shell script and streams output asynchronously.
    private func runShellScript(_ script: String) async {
        await MainActor.run { logs.append("🚀 Starting installation...") }
        
        let process = Process()
        self.process = process
        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", script]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        self.outputPipe = outputPipe
        self.errorPipe = errorPipe
        
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        // Handle output asynchronously line by line
        func readOutput(pipe: Pipe, isError: Bool = false) {
            let handle = pipe.fileHandleForReading
            handle.readabilityHandler = { [weak self] fileHandle in
                let data = fileHandle.availableData
                guard !data.isEmpty else {
                    handle.readabilityHandler = nil
                    return
                }
                if let line = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) {
                    Task { @MainActor in
                        if isError {
                            self?.logs.append("❌ \(line)")
                        } else {
                            self?.logs.append(line)
                        }
                    }
                }
            }
        }

        readOutput(pipe: outputPipe, isError: false)
        readOutput(pipe: errorPipe, isError: true)

        do {
            try process.run()
        } catch {
            await MainActor.run {
                self.logs.append("❌ Failed to launch process: \(error.localizedDescription)")
                self.installing = false
            }
            return
        }

        // Wait until process finishes
        process.waitUntilExit()
        
        // Close readability handlers
        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil
        
        await MainActor.run {
            if process.terminationStatus == 0 {
                self.logs.append("✅ Installation completed successfully.")
            } else {
                self.logs.append("❌ Installation failed with code \(process.terminationStatus).")
                self.errorMessage = "Installation failed with code \(process.terminationStatus)."
            }
            self.finished = true
            self.installing = false
        }
    }
}
