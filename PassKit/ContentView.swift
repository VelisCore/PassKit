// PassKit.swift
// PassKit - Modern macOS App for iOS Device Tools
// Created with SwiftUI, macOS 14+
// All-in-one code file – ready to build & run

import SwiftUI
import Combine

// MARK: - App State Model

class PassKitAppModel: ObservableObject {
    // Simulated Device Connection State
    @Published var isDeviceConnected: Bool = true // Simulate connection
    @Published var deviceInfo: DeviceInfo = DeviceInfo.mock
    @Published var jailbreakVersion: String = ""
    @Published var showWelcome: Bool = true
    @Published var selectedTab: SidebarTab? = .restore
    
    // IPSW Downloader State
    @Published var ipswDevice: String = "iPhone 12"
    @Published var ipswVersion: String = "16.7.6"
    @Published var ipswDownloading: Bool = false
    @Published var ipswProgress: Double = 0
    @Published var ipswSavePath: URL? = nil
    
    // Utilities State
    @Published var isProcessingUtility: Bool = false
    @Published var processingUtility: UtilityAction? = nil
    
    // Info panel Timer
    var deviceUpdateTimer: Timer?
    
    // Mock: For state preservation
    @Published var lastSHSHBlobSavePath: URL?
    
    init() {
        // Simulate device "connect" by updating info periodically
        deviceUpdateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            // Partial (mock) updates: For actual device polling, use IOKit
            if self.isDeviceConnected {
                self.deviceInfo = DeviceInfo.mock.updatedRandom()
            }
        }
    }
}

// MARK: - Sidebar

enum SidebarTab: Hashable {
    case restore, jailbreak, shsh, ipsw, utilities, info
    
    var label: String {
        switch self {
        case .restore: return "Restore"
        case .jailbreak: return "Jailbreak"
        case .shsh: return "SHSH Blobs"
        case .ipsw: return "IPSW"
        case .utilities: return "Utilities"
        case .info: return "Device Info"
        }
    }
    
    var systemImage: String {
        switch self {
        case .restore: return "arrow.triangle.2.circlepath"
        case .jailbreak: return "lock.open"
        case .shsh: return "doc.badge.ellipsis"
        case .ipsw: return "square.and.arrow.down"
        case .utilities: return "wrench.and.screwdriver"
        case .info: return "info.circle"
        }
    }
}

// MARK: - Device Info Model

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
            name: "John's iPhone",
            model: "iPhone 12",
            modelNumber: "A2172",
            iOSVersion: "16.7.6",
            jailbroken: false,
            buildNumber: "20G123",
            ecid: "0x1234567890ABCDEF",
            dependencies: ["libimobiledevice", "ideviceinstaller", "usbmuxd"],
            systemFlags: [
                "flag_jb_enabled",
                "flag_apnonce_set",
                "flag_lwvm_support",
                "flag_usb_allowed",
                "flag_tethered_ok"
            ],
            macOSVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            macModel: "MacBookPro18,3",
            ipswPath: "\(NSHomeDirectory())/Documents/IPSWs"
        )
    }
    
    func updatedRandom() -> DeviceInfo {
        // Only iOS version or Jailbreak status might change for demo
        var new = self
        if Bool.random() {
            let frmw = ["16.7.6", "17.0", "17.3", "15.7.2"].randomElement()!
            new.iOSVersion = frmw
        }
        if Bool.random() { new.jailbroken.toggle() }
        return new
    }
}

// MARK: - Utility Actions

enum UtilityAction: String, CaseIterable, Identifiable {
    case pwnedDFU, clearNVRAM, toggleExploit, sshRamdisk, updateDateTime, dfuHelper
    
    var id: String { rawValue }
    var label: String {
        switch self {
        case .pwnedDFU: return "Enter Pwned DFU Mode"
        case .clearNVRAM: return "Clear NVRAM"
        case .toggleExploit: return "Disable/Enable Exploit"
        case .sshRamdisk: return "SSH Ramdisk"
        case .updateDateTime: return "Update DateTime"
        case .dfuHelper: return "DFU Mode Helper"
        }
    }
    
    var icon: String {
        switch self {
        case .pwnedDFU: return "cpu"
        case .clearNVRAM: return "eraser"
        case .toggleExploit: return "shield.lefthalf.filled"
        case .sshRamdisk: return "terminal"
        case .updateDateTime: return "clock"
        case .dfuHelper: return "arrow.up.arrow.down"
        }
    }
}

// MARK: - Glassmorphism Frosted Background

struct FrostBackground: View {
    var body: some View {
        VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.accentColor.opacity(0.07),
                        Color(.windowBackgroundColor).opacity(0.93)]
                    ),
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .ignoresSafeArea()
    }
}

#if os(macOS)
// Allow NSVisualEffectView with custom materials
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
#endif

// MARK: - Welcome Screen

struct WelcomeScreen: View {
    var onStart: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 36) {
            Spacer()
            // Logo/Brand
            HStack(spacing: 20) {
                Image(systemName: "key.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                    .foregroundStyle(LinearGradient(
                        colors: [Color.accentColor, .primary],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("PassKit")
                        .font(.largeTitle.bold())
                        .foregroundColor(.primary)
                        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 2)
                    Text("iOS Restoring & IPSW Toolkit")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.secondary)
                }
            }
            // Subtitle
            Text("Welcome to PassKit, a modern all-in-one utility for managing, restoring, and jailbreaking iOS devices. Fully native. Free. Sleek. Secure.")
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 60)
            Spacer()
            // Start Button
            Button(action: onStart) {
                Label("Start", systemImage: "arrow.right.circle.fill")
                    .font(.title2.bold())
                    .padding(.horizontal, 34)
                    .padding(.vertical, 16)
                    .background(
                        Capsule().fill(colorScheme == .dark
                                       ? Color.white.opacity(0.15)
                                       : Color.black.opacity(0.09))
                            .shadow(color: (colorScheme == .dark
                                            ? Color.white : Color.black).opacity(0.09), radius: 8)
                    )
                    .overlay(
                        Capsule().stroke(Color.accentColor, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
            Spacer().frame(height: 36)
        }
        .background(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.13), radius: 36, y: 18)
        )
        .transition(.asymmetric(insertion: .opacity.combined(with: .scale),
                                removal: .opacity))
        .zIndex(100)
    }
}

// MARK: - Main Content View with Sidebar

struct AppContentView: View {
    @EnvironmentObject var model: PassKitAppModel
    @Environment(\.colorScheme) var colorScheme
    
    // For adaptive sidebar behavior or compact width
    @State private var isSidebarCollapsed = false
    
    var body: some View {
        NavigationSplitView {
            List(selection: $model.selectedTab) {
                Section {
                    ForEach([SidebarTab.restore, .jailbreak, .shsh, .ipsw, .utilities, .info], id: \.self) { tab in
                        Label(tab.label, systemImage: tab.systemImage)
                            .tag(tab as SidebarTab?)
                            .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("PassKit")
            .frame(minWidth: 190, idealWidth: 210, maxWidth: 260)
        } detail: {
            // Adaptive detail content
            ZStack {
                switch model.selectedTab ?? .restore {
                case .restore: RestoreTabView()
                case .jailbreak: JailbreakTabView()
                case .shsh: SHSHTabView()
                case .ipsw: IPSWTabView()
                case .utilities: UtilitiesTabView()
                case .info: InfoTabView()
                }
            }
            .padding()
            .animation(.easeInOut(duration: 0.22), value: model.selectedTab)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.13), radius: 24, y: 21)
            )
            .padding([.horizontal, .vertical], 20)
            .scrollableIfNeeded()
        }
    }
}

extension View {
    // Scrollable modifier if vertical/horiz content could overflow (adaptive)
    func scrollableIfNeeded() -> some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: true) {
                self
                    .frame(minHeight: geo.size.height)
            }
        }
    }
}

// MARK: - Restore / Downgrade Tab

struct RestoreTabView: View {
    @EnvironmentObject var model: PassKitAppModel
    @State private var selectedRestoreOption: RestoreOption = .powdersn0w
    @State private var selectedCustomBlobFile: URL? = nil
    @State private var isPerformingRestore: Bool = false
    
    enum RestoreOption: String, CaseIterable, Identifiable {
        case powdersn0w, latest, custom
        var id: String { rawValue }
        var label: String {
            switch self {
            case .powdersn0w: return "powdersn0w (any iOS)"
            case .latest: return "Latest iOS (7.1.2)"
            case .custom: return "Other (use SHSH Blobs)"
            }
        }
        var icon: String {
            switch self {
            case .powdersn0w: return "flame"
            case .latest: return "star.fill"
            case .custom: return "folder.badge.plus"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Label("Restore / Downgrade", systemImage: "arrow.triangle.2.circlepath")
                    .font(.title2.bold())
                Spacer()
                    .frame(width: 16)
                if isPerformingRestore {
                    ProgressView().scaleEffect(0.85)
                }
            }
            Text("Choose your preferred method to restore or downgrade your connected iOS device. Use SHSH Blobs for custom firmware.")
                .foregroundColor(.secondary)
                .font(.subheadline)
                .padding(.bottom, 8)
            
            Picker(selection: $selectedRestoreOption, label: Text("Restore Option")) {
                ForEach(RestoreOption.allCases) { option in
                    Label(option.label, systemImage: option.icon).tag(option)
                }
            }
            .pickerStyle(RadioGroupPickerStyle())
            .padding(.horizontal, 10)
            
            if selectedRestoreOption == .custom {
                Button {
                    let panel = NSOpenPanel()
                    panel.allowedFileTypes = ["shsh", "shsh2", "plist", "blob"]
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        selectedCustomBlobFile = url
                    }
                } label: {
                    Label(
                        selectedCustomBlobFile == nil ? "Select SHSH Blob..." :
                            "Selected: \(selectedCustomBlobFile!.lastPathComponent)",
                        systemImage: "doc.badge.ellipsis"
                    )
                }
            }
            
            Spacer(minLength: 12)
            
            Button {
                isPerformingRestore = true
                // Simulate restore
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    isPerformingRestore = false
                }
            } label: {
                Label("Start Restore", systemImage: "arrow.down.circle.fill")
                    .font(.headline)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 14)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isPerformingRestore ||
                     (selectedRestoreOption == .custom && selectedCustomBlobFile == nil))
            .animation(.easeOut(duration: 0.19), value: isPerformingRestore)
            
            if isPerformingRestore {
                Text("Restoring device... Please wait.")
                    .font(.callout).foregroundColor(.primary)
                    .padding(.top, 12)
                    .transition(.opacity)
            }
            
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Jailbreak Tab

struct JailbreakTabView: View {
    @EnvironmentObject var model: PassKitAppModel
    @State private var isJailbreaking: Bool = false
    @FocusState private var inputFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 21) {
            Label("Jailbreak Device", systemImage: "lock.open")
                .font(.title2.bold())
            
            Text("Enter your device's current iOS version, then begin the jailbreak process. (Simulated for demo!)")
                .foregroundColor(.secondary)
                .font(.subheadline)
            
            HStack {
                Image(systemName: "gearshape")
                TextField("iOS Version (e.g. 16.7.6)", text: $model.jailbreakVersion)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 160)
                    .focused($inputFocused)
                Spacer()
            }.padding(.vertical, 7)
            
            Button {
                inputFocused = false
                isJailbreaking = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    isJailbreaking = false
                }
            } label: {
                if isJailbreaking {
                    HStack {
                        ProgressView().scaleEffect(0.8)
                        Text("Jailbreaking...")
                    }
                } else {
                    Label("Start Jailbreak", systemImage: "lock.open.fill")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(model.jailbreakVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isJailbreaking)
            .padding(.top, 5)
            
            if isJailbreaking {
                Text("Applying exploit and patching system... (simulated)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .animation(.easeInOut(duration: 0.19), value: isJailbreaking)
    }
}

// MARK: - SHSH Blobs Tab

struct SHSHTabView: View {
    @EnvironmentObject var model: PassKitAppModel
    @State private var isSavingBlobs: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Save SHSH Blobs", systemImage: "doc.badge.ellipsis")
                .font(.title2.bold())
            
            Text("Save device-specific SHSH blobs for future downgrades. Device details shown below. (Device check: simulated)")
                .foregroundColor(.secondary)
                .font(.subheadline)
            
            GroupBox {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Label("ECID", systemImage: "barcode.viewfinder")
                        Text(model.deviceInfo.ecid)
                    }
                    HStack {
                        Label("Model", systemImage: "iphone.gen3")
                        Text(model.deviceInfo.model)
                    }
                }.padding(.vertical, 5)
            }
            .groupBoxStyle(.automatic)
            .frame(maxWidth: 350)
            
            Button {
                isSavingBlobs = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    isSavingBlobs = false
                    // Simulate saving to Downloads
                    let url = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.appendingPathComponent("ios_\(model.deviceInfo.model)_shsh2")
                    model.lastSHSHBlobSavePath = url
                }
            } label: {
                HStack {
                    if isSavingBlobs { ProgressView().scaleEffect(0.7) }
                    Label(isSavingBlobs ? "Saving..." : "Save Blobs", systemImage: "square.and.arrow.down")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSavingBlobs)
            
            if let path = model.lastSHSHBlobSavePath {
                Label("Saved: \(path.lastPathComponent)", systemImage: "checkmark.seal.fill")
                    .foregroundColor(.accentColor)
                    .font(.subheadline.bold())
                    .transition(.opacity)
            }
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - IPSW Downloader Tab

struct IPSWTabView: View {
    @EnvironmentObject var model: PassKitAppModel
    
    // Simulated list of devices & OS versions
    let devices = ["iPhone 12", "iPhone 13", "iPhone 15 Pro", "iPad 9", "iPod touch 7th"]
    let iosVersions = ["15.7.2", "16.7.6", "17.0", "17.3"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Label("IPSW Downloader", systemImage: "square.and.arrow.down")
                .font(.title2.bold())
            
            Text("Download official signed IPSW files for your selected device and firmware version.")
                .foregroundColor(.secondary)
                .font(.subheadline)
            
            HStack(alignment: .center, spacing: 18) {
                // Device Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Device")
                    Picker("", selection: $model.ipswDevice) {
                        ForEach(devices, id: \.self) { device in
                            Text(device)
                        }
                    }
                    .pickerStyle(PopUpButtonPickerStyle())
                    .frame(width: 170)
                }
                // iOS Version Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("iOS Version")
                    Picker("", selection: $model.ipswVersion) {
                        ForEach(iosVersions, id: \.self) { ver in
                            Text(ver)
                        }
                    }
                    .pickerStyle(PopUpButtonPickerStyle())
                    .frame(width: 130)
                }
                // File Picker for Save Location
                VStack(alignment: .leading, spacing: 6) {
                    Text("Save Location")
                    HStack(spacing: 9) {
                        Button {
                            let panel = NSOpenPanel()
                            panel.canChooseDirectories = true
                            panel.canChooseFiles = false
                            panel.allowsMultipleSelection = false
                            panel.prompt = "Choose"
                            if panel.runModal() == .OK, let url = panel.url {
                                model.ipswSavePath = url
                            }
                        } label: {
                            Label("Choose Folder", systemImage: "folder")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        if let path = model.ipswSavePath {
                            Text(path.lastPathComponent)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            
            HStack(spacing: 14) {
                Button {
                    model.ipswDownloading = true
                    model.ipswProgress = 0.0
                    // Simulate download progress
                    Timer.scheduledTimer(withTimeInterval: 0.13, repeats: true) { timer in
                        model.ipswProgress += 0.04 + Double.random(in: 0...0.055)
                        if model.ipswProgress >= 1 {
                            model.ipswProgress = 1
                            model.ipswDownloading = false
                            timer.invalidate()
                        }
                    }
                } label: {
                    if model.ipswDownloading {
                        Label("Downloading...", systemImage: "arrow.down.circle")
                    } else {
                        Label("Download", systemImage: "arrow.down.circle.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.ipswDownloading || model.ipswSavePath == nil)
                
                if model.ipswDownloading {
                    ProgressView(value: model.ipswProgress)
                        .frame(width: 150)
                        .transition(.opacity)
                }
            }
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - Utilities Tab

struct UtilitiesTabView: View {
    @EnvironmentObject var model: PassKitAppModel
    
    // Track disables/enables for exploit toggle (persistent per launch for demo)
    @State private var exploitEnabled: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            Label("Useful Utilities", systemImage: "wrench.and.screwdriver")
                .font(.title2.bold())
            
            Text("Handy maintenance and device modes for advanced iOS operations (all operations simulated):")
                .foregroundColor(.secondary)
                .font(.subheadline)
            
            // Utility buttons grid
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 210, maximum: 260))
            ], spacing: 18) {
                UtilityButton(action: .pwnedDFU)
                UtilityButton(action: .clearNVRAM)
                UtilityButton(action: .toggleExploit, isToggle: true, isOn: exploitEnabled, onToggle: {
                    exploitEnabled.toggle()
                })
                UtilityButton(action: .sshRamdisk)
                UtilityButton(action: .updateDateTime)
                UtilityButton(action: .dfuHelper)
            }
            .disabled(model.isProcessingUtility)
            .animation(.easeOut(duration: 0.16), value: model.isProcessingUtility)
            
            if model.isProcessingUtility, let act = model.processingUtility {
                HStack {
                    ProgressView().scaleEffect(0.85)
                    Text("Processing: \(act.label)...")
                        .font(.callout)
                }
                .padding(.vertical, 13)
            }
            
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    
    @ViewBuilder
    func UtilityButton(action: UtilityAction, isToggle: Bool = false, isOn: Bool = true, onToggle: (() -> Void)? = nil) -> some View {
        if isToggle {
            Toggle(isOn: Binding(get: { isOn }, set: { v in onToggle?() })) {
                Label("\(action.label)", systemImage: action.icon)
                    .font(.headline)
            }
            .toggleStyle(.switch)
            .onChange(of: isOn) { _ in
                withAnimation {
                    model.isProcessingUtility = true
                    model.processingUtility = action
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        model.isProcessingUtility = false
                        model.processingUtility = nil
                    }
                }
            }
        } else {
            Button {
                withAnimation {
                    model.isProcessingUtility = true
                    model.processingUtility = action
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.0...2.0)) {
                    withAnimation {
                        model.isProcessingUtility = false
                        model.processingUtility = nil
                    }
                }
            } label: {
                Label(action.label, systemImage: action.icon)
                    .font(.headline)
            }
            .buttonStyle(.bordered)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.11), radius: 3, x: 0, y: 2)
        }
    }
}

// MARK: - Info Panel Tab

struct InfoTabView: View {
    @EnvironmentObject var model: PassKitAppModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 21) {
                Label("Device Info", systemImage: "info.circle")
                    .font(.title2.bold())
                    .padding(.bottom, 7)
                
                if model.isDeviceConnected {
                    InfoPanel(device: model.deviceInfo)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.thinMaterial)
                                .shadow(color: .black.opacity(0.10), radius: 6, y: 4)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    colorScheme == .dark ?
                                    Color.white.opacity(0.10) :
                                    Color.black.opacity(0.06), lineWidth: 1.2)
                        )
                } else {
                    VStack(spacing: 24) {
                        Image(systemName: "iphone.slash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 46, height: 46)
                            .foregroundColor(.gray)
                        Text("No iOS device connected")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Button("Simulate Connect") {
                            withAnimation {
                                model.isDeviceConnected = true
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 280)
                }
                
                Spacer()
            }
            .frame(maxWidth: 600, alignment: .leading)
            .padding([.horizontal, .top], 16)
            .padding(.bottom, 36)
        }
    }
}

// MARK: - Info Panel Component

struct InfoPanel: View {
    let device: DeviceInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(device.name, systemImage: "iphone.gen3")
                .font(.title3.bold())
            HStack {
                Label("Model", systemImage: "info.square")
                Text("\(device.model) (\(device.modelNumber))").bold()
            }
            HStack {
                Label("iOS Version", systemImage: "applelogo")
                Text("\(device.iOSVersion) (\(device.buildNumber))")
            }
            HStack {
                Label("Jailbroken", systemImage: "lock.slash")
                Text(device.jailbroken ? "Yes" : "No")
                    .foregroundStyle(device.jailbroken ? Color.pink : Color.secondary)
            }
            Divider().padding(.vertical, 4)
            HStack {
                Label("ECID", systemImage: "barcode.viewfinder")
                Text(device.ecid)
            }
            // Dependencies - horizontal chips
            HStack {
                Label("Deps", systemImage: "externaldrive.connected.to.line.below")
                ForEach(device.dependencies, id: \.self) { dep in
                    Text(dep)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2.7)
                        .background(
                            Capsule().fill(Color.accentColor.opacity(0.17))
                        )
                        .font(.caption.bold())
                }
            }
            // System Flags
            VStack(alignment: .leading, spacing: 0) {
                Label("System Flags", systemImage: "flag")
                HStack {
                    ForEach(device.systemFlags, id: \.self) { flag in
                        Text(flag)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.quaternary))
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                    }
                }
            }
            Divider()
                .padding(.vertical, 4)
            HStack {
                Label("macOS", systemImage: "macwindow")
                Text(device.macOSVersion)
            }
            HStack {
                Label("Mac Model", systemImage: "desktopcomputer")
                Text(device.macModel)
            }
            HStack {
                Label("IPSW Path", systemImage: "internaldrive")
                Text(device.ipswPath).font(.footnote)
            }
        }
        .font(.body)
        .padding(.vertical, 3)
        .animation(.easeInOut(duration: 0.15), value: device)
    }
}

