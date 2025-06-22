import Foundation

struct DeviceInfo: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var model: String
    var modelNumber: String
    var iOSVersion: String
    var jailbroken: Bool
    var buildNumber: String
    var ecid: String
    var dependencies: [String]
    var systemFlags: [String]
    var macOSVersion: String
    var macModel: String
    var ipswPath: String

    static var mock: DeviceInfo {
        DeviceInfo(
            name: "Searching...",
            model: "N/A",
            modelNumber: "N/A",
            iOSVersion: "N/A",
            jailbroken: false,
            buildNumber: "N/A",
            ecid: "N/A",
            dependencies: ["libimobiledevice", "ideviceinfo", "usbmuxd"],
            systemFlags: [],
            macOSVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            macModel: getMacModelIdentifier() ?? "Unknown",
            ipswPath: "\(NSHomeDirectory())/Documents/IPSWs"
        )
    }
}

