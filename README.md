# LlamaWatch

A tiny macOS menu bar app that keeps an eye on [Ollama](https://ollama.com).

No dock icon. No windows. Just a small eye in your menu bar that tells you everything you need to know.

## Features

- **Live status** — three distinct states at a glance:
  | SF Symbol | State |
  |-----------|-------|
  | `eye.fill` | Running — Ollama is idle |
  | `eye.circle.fill` | Generating — Ollama is actively processing a request |
  | `eye.slash` | Stopped — Ollama is not running |
- **Generation detection** — detects active inference by monitoring TCP connections to Ollama's port
- **Loaded models** — shows which models are currently in memory and their VRAM usage
- **Eject models** — click any loaded model to unload it and free up memory
- **Start / Stop** — toggle the Ollama service directly from the menu bar (via `brew services`)
- **Lightweight** — a single Swift file, no Xcode project, no dependencies, no frameworks beyond AppKit

## Screenshot

<img width="231" height="198" alt="Image" src="https://github.com/user-attachments/assets/4c6186db-850d-4ed4-b66f-c9844adc162c" />

## Requirements

- macOS 13+
- [Ollama](https://ollama.com) installed via Homebrew (`brew install ollama`)

## Install

### Download (recommended)

1. Download `LlamaWatch.zip` from the [latest release](https://github.com/L3G/LlamaWatch/releases/latest)
2. Unzip and drag `LlamaWatch.app` to `/Applications/`

### Build from source

Requires Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/L3G/LlamaWatch.git
cd LlamaWatch
make install
```

To uninstall:

```bash
make uninstall
```

### Start at Login

To have LlamaWatch launch automatically, add it in **System Settings > General > Login Items**.

## How It Works

LlamaWatch polls the system process list every 3 seconds to detect whether Ollama is running, and queries Ollama's local API (`localhost:11434/api/ps`) to list loaded models. Active generation is detected by monitoring established TCP connections to Ollama's port (11434) — when an external client has an open connection, the app switches to the "Generating" state. Stopping and starting Ollama is handled through `brew services` to properly manage the launchd service.

The entire app is a single `main.swift` file compiled with `swiftc` into a minimal `.app` bundle. No SwiftUI, no storyboards, no Xcode project — just AppKit and a shell script.

## Disclaimer

LlamaWatch is an independent project and is not affiliated with, endorsed by, or associated with the [Ollama](https://ollama.com) team in any way.

## License

MIT
