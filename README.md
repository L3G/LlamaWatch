# LlamaWatch

A tiny macOS menu bar app that keeps an eye on [Ollama](https://ollama.com).

No dock icon. No windows. Just a small eye in your menu bar that tells you everything you need to know.

## Features

- **Live status** — see at a glance whether Ollama is running (`eye`) or stopped (`eye.slash`)
- **Loaded models** — shows which models are currently in memory and their VRAM usage
- **Eject models** — click any loaded model to unload it and free up memory
- **Start / Stop** — toggle the Ollama service directly from the menu bar (via `brew services`)
- **Lightweight** — a single Swift file, no Xcode project, no dependencies, no frameworks beyond AppKit

## Screenshot

```
┌─────────────────────────────┐
│  Ollama: Running            │
│─────────────────────────────│
│  Loaded Models              │
│  ⏏ qwen3:8b  —  4.9 GB     │
│─────────────────────────────│
│  Stop Ollama                │
│─────────────────────────────│
│  Quit LlamaWatch        ⌘Q  │
└─────────────────────────────┘
```

## Requirements

- macOS 13+
- [Ollama](https://ollama.com) installed via Homebrew (`brew install ollama`)
- Xcode Command Line Tools (`xcode-select --install`)

## Build & Run

```bash
git clone https://github.com/L3G/LlamaWatch.git
cd LlamaWatch
chmod +x build.sh
./build.sh
open build/LlamaWatch.app
```

That's it. The app compiles in under a second.

## Install as Login Item

To have LlamaWatch start automatically when you log in:

```bash
cp -r build/LlamaWatch.app /Applications/
```

Then go to **System Settings > General > Login Items** and add LlamaWatch.

## How It Works

LlamaWatch polls the system process list every 3 seconds to detect whether Ollama is running, and queries Ollama's local API (`localhost:11434/api/ps`) to list loaded models. Stopping and starting Ollama is handled through `brew services` to properly manage the launchd service.

The entire app is a single `main.swift` file compiled with `swiftc` into a minimal `.app` bundle. No SwiftUI, no storyboards, no Xcode project — just AppKit and a shell script.

## License

MIT
