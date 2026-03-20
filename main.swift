import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var statusMenuItem: NSMenuItem!
    private var modelHeaderItem: NSMenuItem!
    private var toggleMenuItem: NSMenuItem!
    private var timer: Timer?
    private var ollamaRunning = false
    private var modelMenuItems: [NSMenuItem] = []
    private var modelSeparator: NSMenuItem!
    private var loadedModels: [(name: String, size: String)] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = makeSymbol(name: "eye.slash")

        let menu = NSMenu()
        menu.delegate = self

        statusMenuItem = NSMenuItem(title: "Ollama: Checking…", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        modelHeaderItem = NSMenuItem(title: "Loaded Models", action: nil, keyEquivalent: "")
        modelHeaderItem.isEnabled = false
        modelHeaderItem.isHidden = true
        menu.addItem(modelHeaderItem)

        modelSeparator = NSMenuItem.separator()
        modelSeparator.isHidden = true
        menu.addItem(modelSeparator)

        toggleMenuItem = NSMenuItem(title: "Stop Ollama", action: #selector(toggleOllama), keyEquivalent: "")
        toggleMenuItem.target = self
        menu.addItem(toggleMenuItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit LlamaWatch", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu

        refreshAll()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.refreshAll()
        }
    }

    private func refreshAll() {
        let running = isOllamaRunning()
        ollamaRunning = running
        updateIcon()
        fetchModelsAsync()
    }

    private func isOllamaRunning() -> Bool {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/ps")
        proc.arguments = ["-axo", "comm"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice
        do {
            try proc.run()
            proc.waitUntilExit()
        } catch {
            return false
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return output.split(separator: "\n").contains { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return trimmed.hasSuffix("/ollama") || trimmed == "ollama"
        }
    }

    private func fetchModelsAsync() {
        guard ollamaRunning else {
            loadedModels = []
            updateMenu()
            return
        }
        let url = URL(string: "http://localhost:11434/api/ps")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 2
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            var models: [(name: String, size: String)] = []
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let list = json["models"] as? [[String: Any]] {
                for model in list {
                    let name = model["name"] as? String ?? "unknown"
                    let sizeBytes = model["size_vram"] as? Int64 ?? model["size"] as? Int64 ?? 0
                    let sizeGB = String(format: "%.1f GB", Double(sizeBytes) / 1_073_741_824)
                    models.append((name: name, size: sizeGB))
                }
            }
            DispatchQueue.main.async {
                self?.loadedModels = models
                self?.updateMenu()
            }
        }.resume()
    }

    private func makeSymbol(name: String) -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        guard let image = NSImage(systemSymbolName: name, accessibilityDescription: "LlamaWatch") else {
            return nil
        }
        let configured = image.withSymbolConfiguration(config)
        configured?.isTemplate = true
        return configured
    }

    private func updateIcon() {
        if ollamaRunning {
            statusItem.button?.image = makeSymbol(name: "eye.fill")
        } else {
            statusItem.button?.image = makeSymbol(name: "eye.slash")
        }
    }

    private func updateMenu() {
        statusMenuItem.title = ollamaRunning ? "Ollama: Running" : "Ollama: Stopped"
        toggleMenuItem.title = ollamaRunning ? "Stop Ollama" : "Start Ollama"

        let menu = statusItem.menu!
        for item in modelMenuItems {
            menu.removeItem(item)
        }
        modelMenuItems.removeAll()

        if loadedModels.isEmpty {
            modelHeaderItem.isHidden = true
            modelSeparator.isHidden = true
        } else {
            modelHeaderItem.isHidden = false
            modelSeparator.isHidden = false
            let insertIndex = menu.index(of: modelHeaderItem) + 1
            for (i, model) in loadedModels.enumerated() {
                let item = NSMenuItem(title: "  ⏏ \(model.name)  —  \(model.size)", action: #selector(ejectModel(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = model.name
                menu.insertItem(item, at: insertIndex + i)
                modelMenuItems.append(item)
            }
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        // Just update menu from cached state — don't block with process checks
        updateMenu()
    }

    @objc private func toggleOllama() {
        let command = ollamaRunning ? "stop" : "start"
        DispatchQueue.global().async { [weak self] in
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/brew")
            proc.arguments = ["services", command, "ollama"]
            proc.standardOutput = FileHandle.nullDevice
            proc.standardError = FileHandle.nullDevice
            try? proc.run()
            proc.waitUntilExit()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self?.refreshAll()
            }
        }
    }

    @objc private func ejectModel(_ sender: NSMenuItem) {
        guard let modelName = sender.representedObject as? String else { return }
        let url = URL(string: "http://localhost:11434/api/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5
        let body: [String: Any] = ["model": modelName, "keep_alive": 0]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { [weak self] _, _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.refreshAll()
            }
        }.resume()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
