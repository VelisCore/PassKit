import Foundation

func fetchConnectedDeviceInfo() -> DeviceInfo? {
    do {
        let (udidOutput, _) = try runShellCommand("/opt/homebrew/bin/idevice_id", args: ["-l"])
        guard let udid = udidOutput.split(separator: "\n").first else {
            return nil
        }
        let (infoOutput, _) = try runShellCommand("/opt/homebrew/bin/ideviceinfo", args: ["-u", String(udid)])

        var infoDict = [String: String]()
        for line in infoOutput.split(separator: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
            if parts.count == 2 {
                infoDict[parts[0]] = parts[1]
            }
        }

        return DeviceInfo(
            name: infoDict["DeviceName"] ?? "Unknown",
            model: infoDict["ProductType"] ?? "Unknown",
            modelNumber: infoDict["ModelNumber"] ?? "Unknown",
            iOSVersion: infoDict["ProductVersion"] ?? "Unknown",
            jailbroken: false,
            buildNumber: infoDict["BuildVersion"] ?? "Unknown",
            ecid: infoDict["UniqueChipID"] ?? "N/A",
            dependencies: ["libimobiledevice", "ideviceinfo", "usbmuxd"],
            systemFlags: [],
            macOSVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            macModel: getMacModelIdentifier() ?? "Unknown",
            ipswPath: "\(NSHomeDirectory())/Documents/IPSWs"
        )
    } catch {
        return nil
    }
}

enum ShellCommandError: Error {
    case failedToLaunch(String)
    case timedOut
    case encodingError
    case appleScriptError(String)
}

func runCommandInTerminal(_ command: String) throws {
    // Escape double quotes in the command for AppleScript
    let escapedCommand = command.replacingOccurrences(of: "\"", with: "\\\"")

    let appleScript = """
    tell application "Terminal"
        activate
        do script "\(escapedCommand)"
    end tell
    """

    var error: NSDictionary?
    if let script = NSAppleScript(source: appleScript) {
        script.executeAndReturnError(&error)
        if let error = error {
            throw ShellCommandError.appleScriptError("AppleScript error: \(error)")
        }
    } else {
        throw ShellCommandError.appleScriptError("Failed to create AppleScript")
    }
}

enum ShellCommandError1: Error {
    case failedToLaunch(String)
    case encodingError
    case timedOut
}

func runShellCommand(_ command: String, args: [String] = [], timeout: TimeInterval = 60) throws -> (output: String, errorOutput: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: command)
    process.arguments = args

    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe

    var stdoutData = Data()
    var stderrData = Data()

    // Use DispatchGroup to wait until both pipes are closed
    let group = DispatchGroup()
    
    group.enter()
    outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
        let data = fileHandle.availableData
        if data.count > 0 {
            stdoutData.append(data)
        } else {
            outputPipe.fileHandleForReading.readabilityHandler = nil
            group.leave()
        }
    }

    group.enter()
    errorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
        let data = fileHandle.availableData
        if data.count > 0 {
            stderrData.append(data)
        } else {
            errorPipe.fileHandleForReading.readabilityHandler = nil
            group.leave()
        }
    }

    do {
        try process.run()
    } catch {
        throw ShellCommandError1.failedToLaunch(error.localizedDescription)
    }

    // Wait with timeout
    let timeoutResult = group.wait(timeout: .now() + timeout)
    if timeoutResult == .timedOut {
        process.terminate()
        throw ShellCommandError1.timedOut
    }

    process.waitUntilExit()

    guard let stdoutString = String(data: stdoutData, encoding: .utf8),
          let stderrString = String(data: stderrData, encoding: .utf8) else {
        throw ShellCommandError1.encodingError
    }

    return (stdoutString, stderrString)
}

func getMacModelIdentifier() -> String? {
    var size: size_t = 0
    sysctlbyname("hw.model", nil, &size, nil, 0)
    var model = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.model", &model, &size, nil, 0)
    return String(cString: model)
}
