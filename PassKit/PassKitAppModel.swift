import Foundation
import SwiftUI
import Combine

class PassKitAppModel: ObservableObject {
    @Published var isDeviceConnected: Bool = false
    @Published var deviceReady: Bool = false
    @Published var deviceInfo: DeviceInfo = DeviceInfo.mock

    @Published var ipswDevices: [IPSWDevice] = []
    @Published var ipswFirmwares: [IPSWFirmware] = []
    
    @Published var selectedDevice: IPSWDevice?
    @Published var selectedFirmware: IPSWFirmware?

    @Published var ipswSavePath: URL?
    @Published var ipswDownloading = false
    @Published var ipswProgress: Double = 0.0

    @Published var jailbreakVersion: String = ""
    @Published var showWelcome: Bool = true
    @Published var selectedTab: SidebarTab? = .restore

    @Published var isProcessingUtility: Bool = false
    @Published var processingUtility: UtilityAction? = nil

    @Published var lastSHSHBlobSavePath: URL?

    init() {
        checkForDeviceLoop()
        Task { await loadDevices() }
    }

    private func checkForDeviceLoop() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            if let realInfo = fetchConnectedDeviceInfo() {
                DispatchQueue.main.async {
                    self.deviceInfo = realInfo
                    self.isDeviceConnected = true
                    self.deviceReady = true
                }
            } else {
                DispatchQueue.main.async {
                    self.isDeviceConnected = false
                    self.deviceReady = false
                }
            }
        }
    }

    func loadDevices() async {
        guard let url = URL(string: "https://api.ipsw.me/v4/devices") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let devices = try JSONDecoder().decode([IPSWDevice].self, from: data)
            DispatchQueue.main.async {
                self.ipswDevices = devices.sorted(by: { $0.name < $1.name })
            }
        } catch {
            print("Failed to fetch devices: \(error)")
        }
    }

    func loadFirmwares(for device: IPSWDevice) async {
        guard let url = URL(string: "https://api.ipsw.me/v4/device/\(device.identifier)?type=ipsw") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let deviceInfo = try JSONDecoder().decode(IPSWDeviceInfo.self, from: data)
            DispatchQueue.main.async {
                self.ipswFirmwares = deviceInfo.firmwares.filter { $0.signed }
            }
        } catch {
            print("Failed to fetch firmware: \(error)")
        }
    }

    func startDownload() {
        guard let firmware = selectedFirmware,
              let url = URL(string: firmware.url),
              let savePath = ipswSavePath else { return }

        let destinationURL = savePath.appendingPathComponent(url.lastPathComponent)

        Task {
            do {
                ipswDownloading = true
                ipswProgress = 0
                let (tempURL, _) = try await URLSession.shared.download(from: url)
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                DispatchQueue.main.async {
                    self.ipswDownloading = false
                    self.ipswProgress = 1.0
                }
            } catch {
                print("Download failed: \(error)")
                DispatchQueue.main.async {
                    self.ipswDownloading = false
                }
            }
        }
    }
}

