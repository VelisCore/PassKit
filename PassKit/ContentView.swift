import SwiftUI

struct IPSWDevice: Identifiable, Codable, Equatable, Hashable {
    var id: String { identifier }
    let name: String
    let identifier: String
}

struct IPSWFirmware: Identifiable, Codable, Equatable, Hashable {
    var id: String { buildid }
    let version: String
    let buildid: String
    let signed: Bool
    let url: String
}

struct IPSWDeviceInfo: Codable {
    let name: String
    let identifier: String
    let firmwares: [IPSWFirmware]
}

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

// MARK: - Sidebar

enum SidebarTab: Hashable {
    case restore, shsh, ipsw, utilities, info
    
    var label: String {
        switch self {
        case .restore: return "Restore"
        case .shsh: return "SHSH Blobs"
        case .ipsw: return "IPSW"
        case .utilities: return "Utilities"
        case .info: return "Device Info"
        }
    }
    
    var systemImage: String {
        switch self {
        case .restore: return "arrow.triangle.2.circlepath"
        case .shsh: return "doc.badge.ellipsis"
        case .ipsw: return "square.and.arrow.down"
        case .utilities: return "wrench.and.screwdriver"
        case .info: return "info.circle"
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
    @State private var showInstaller = false
    @StateObject private var installer = DependencyInstaller()

    var body: some View {
        VStack(spacing: 36) {
            Spacer()

            if showInstaller {
                // DEPENDENCY INSTALLER VIEW
                VStack(spacing: 20) {
                    Text("Install Required Dependencies")
                        .font(.title.bold())
                        .padding(.top)

                    List(installer.logs, id: \.self) { log in
                        Text(log)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(log.contains("❌") ? .red : .primary)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    
                                    .shadow(radius: 1)
                            )
                    }
                    .frame(height: 360)

                    if installer.installing {
                        ProgressView("Installing...")
                            .progressViewStyle(CircularProgressViewStyle())
                    }

                    Button(installer.finished ? "Done" : "Start Installation") {
                        if installer.finished {
                            showInstaller = false
                        } else {
                            installer.installAll()
                        }
                    }
                    .disabled(installer.installing)
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom)
                }

            } else {
                // WELCOME CONTENT
                HStack(spacing: 20) {
                    Image("AppIconInApp")
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
                        Text("iOS Restoring & IPSW Toolkit")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }

                Text("Welcome to PassKit, a modern all-in-one utility for managing, restoring, and jailbreaking iOS devices. Fully native. Free. Sleek. Secure.")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 60)

                Spacer()

                HStack(spacing: 16) {
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
                            .overlay(Capsule().stroke(Color.accentColor, lineWidth: 2))
                    }
                    .buttonStyle(.plain)

                    Button(action: { showInstaller = true }) {
                        Label("Install Dependencies", systemImage: "hammer.fill")
                            .font(.title2.bold())
                            .padding(.horizontal, 34)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.accentColor.opacity(0.2)))
                    }
                    .overlay(Capsule().stroke(Color.accentColor, lineWidth: 2))
                    .buttonStyle(.plain)
                }

                Spacer().frame(height: 36)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.13), radius: 36, y: 18)
        )
        .transition(.opacity.combined(with: .scale))
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
                    ForEach([SidebarTab.restore, .shsh, .ipsw, .utilities, .info], id: \.self) { tab in
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
            scrollableIfNeeded(
                ZStack {
                    switch model.selectedTab ?? .restore {
                    case .restore: RestoreTabView()
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
            )
        }
    }
}

extension View {
    // Scrollable modifier if vertical/horiz content could overflow (adaptive)
    func scrollableIfNeeded<Content: View>(_ content: Content) -> some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: true) {
                content
                    .frame(minHeight: geo.size.height)
            }
        }
    }
}

// MARK: - Restore / Downgrade Tab
struct RestoreTabView: View {
    @State private var selectedIPSWFile: URL? = nil
    @State private var isPerformingRestore: Bool = false
    @State private var restoreError: String? = nil

    func runRestore() {
        guard let ipswFile = selectedIPSWFile else { return }
        isPerformingRestore = true
        restoreError = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.launchPath = "/usr/local/bin/idevicerestore" // Update if needed!
            process.arguments = [ipswFile.path]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
            } catch {
                DispatchQueue.main.async {
                    restoreError = "Failed to start restore tool: \(error.localizedDescription)"
                    isPerformingRestore = false
                }
                return
            }

            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "(no output)"

            DispatchQueue.main.async {
                isPerformingRestore = false
                if process.terminationStatus == 0 {
                    restoreError = nil
                    // Optionally display a success notification here!
                } else {
                    restoreError = "Restore failed.\n\nOutput:\n\(output)"
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Label("Restore iOS Device", systemImage: "arrow.triangle.2.circlepath")
                    .font(.title2.bold())
                Spacer()
                if isPerformingRestore {
                    ProgressView().scaleEffect(0.85)
                }
            }
            Text("Select your IPSW firmware file and restore your connected device. All data will be erased!")
                .foregroundColor(.secondary)
                .font(.subheadline)
                .padding(.bottom, 8)

            Button {
                let panel = NSOpenPanel()
                panel.allowedFileTypes = ["ipsw"]
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                if panel.runModal() == .OK, let url = panel.url {
                    selectedIPSWFile = url
                }
            } label: {
                Label(
                    selectedIPSWFile == nil ? "Select IPSW File..." :
                    "Selected: \(selectedIPSWFile!.lastPathComponent)",
                    systemImage: "doc.badge.ellipsis"
                )
            }

            Spacer(minLength: 12)

            Button {
                runRestore()
            } label: {
                Label("Start Restore", systemImage: "arrow.down.circle.fill")
                    .font(.headline)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 14)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isPerformingRestore || selectedIPSWFile == nil)
            .animation(.easeOut(duration: 0.19), value: isPerformingRestore)

            if isPerformingRestore {
                Text("Restoring device... Please wait.")
                    .font(.callout).foregroundColor(.primary)
                    .padding(.top, 12)
                    .transition(.opacity)
            }
            if let err = restoreError {
                Text(err)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.top, 10)
                    .transition(.opacity)
            }

            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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

struct IPSWTabView: View {
    @EnvironmentObject var model: PassKitAppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Label("IPSW Downloader", systemImage: "square.and.arrow.down")
                .font(.title2.bold())

            Text("Download official signed IPSW files for your selected device and firmware version.")
                .foregroundColor(.secondary)
                .font(.subheadline)

            HStack(alignment: .top, spacing: 20) {
                // MARK: - Device Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Device")
                        .font(.headline)

                    Picker("Device", selection: $model.selectedDevice) {
                        ForEach(model.ipswDevices) { device in
                            Text(device.name).tag(Optional(device))
                        }
                    }
                    .onChange(of: model.selectedDevice) { newDevice in
                        Task {
                            if let dev = newDevice {
                                await model.loadFirmwares(for: dev)
                                model.selectedFirmware = nil
                            }
                        }
                    }
                    .frame(width: 260)
                    .pickerStyle(MenuPickerStyle())

                    if let selected = model.selectedDevice {
                        Text("Identifier: \(selected.identifier)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }

                // MARK: - Firmware Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("iOS Version")
                        .font(.headline)

                    Picker("Firmware", selection: $model.selectedFirmware) {
                        ForEach(model.ipswFirmwares) { fw in
                            Text("\(fw.version) (\(fw.buildid))").tag(Optional(fw))
                        }
                    }
                    .frame(width: 260)
                    .pickerStyle(MenuPickerStyle())

                    if let fw = model.selectedFirmware {
                        Text(fw.signed ? "✅ Signed" : "❌ Unsigned")
                            .font(.footnote)
                            .foregroundColor(fw.signed ? .green : .red)
                    }
                }

                // MARK: - Save Location
                VStack(alignment: .leading, spacing: 8) {
                    Text("Save Location")
                        .font(.headline)

                    HStack {
                        Button("Choose Folder") {
                            let panel = NSOpenPanel()
                            panel.canChooseDirectories = true
                            panel.canChooseFiles = false
                            panel.allowsMultipleSelection = false
                            panel.prompt = "Choose"
                            if panel.runModal() == .OK {
                                model.ipswSavePath = panel.url
                            }
                        }
                        .buttonStyle(.bordered)

                        if let path = model.ipswSavePath {
                            Text(path.lastPathComponent)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Divider().padding(.vertical, 10)

            // MARK: - Download Button & Progress
            HStack(spacing: 14) {
                Button {
                    model.startDownload()
                } label: {
                    if model.ipswDownloading {
                        Label("Downloading...", systemImage: "arrow.down.circle")
                            .labelStyle(IconOnlyLabelStyle())
                    } else {
                        Label("Download", systemImage: "arrow.down.circle.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.ipswDownloading || model.selectedFirmware == nil || model.ipswSavePath == nil)

                if model.ipswDownloading {
                    ProgressView(value: model.ipswProgress)
                        .frame(width: 200)
                        .progressViewStyle(LinearProgressViewStyle())
                }

                Spacer()
            }

            Spacer()
        }
        .padding(30)
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

