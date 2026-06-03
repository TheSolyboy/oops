<div align="center">

<img src="assets/banner.svg" alt="oops — fix your last command with AI" width="760">

# oops 🫠

**Don't remember the exact flags? Type it roughly and say `oops`.**

Half-remember a command, guess at the syntax, watch it fail — then run `oops`.
It reads the *actual* error, works out what you meant, and runs the corrected
command right there in your shell. Like [`thefuck`](https://github.com/nvbn/thefuck),
but it reads the error instead of pattern-matching the command.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash%20%7C%20zsh%20%7C%20pwsh%20%7C%20cmd-1f425f.svg)](#requirements)
[![CI](https://github.com/TheSolyboy/oops/actions/workflows/ci.yml/badge.svg)](https://github.com/TheSolyboy/oops/actions/workflows/ci.yml)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#contributing)

[Install](#-install) · [Providers](#-providers) · [Usage](#-usage) · [Config](#-configuration) · [Privacy](#-privacy)

</div>

---

```console
$ tar unzip backup.tar.gz
tar: You must specify one of the '-Acdtrux', '--delete' or '--test-label' options

$ oops
oops: re-running "tar unzip backup.tar.gz" to capture the error...
oops: asking opencode (glm-5.1)...
oops: tar -xzf backup.tar.gz
Run it? [Y/n] ▏
```

Press <kbd>Enter</kbd> — the fixed command runs in your current shell. That's it.

---

## ✨ Why oops

- 🧠 **Stop memorizing flags.** Type the command how you *think* it goes. oops reads the real error and turns your guess into what you actually meant — `tar unzip x.tar.gz` → `tar -xzf x.tar.gz`, `kill 8080` → `kill $(lsof -t -i:8080)`.
- ⚡ **It runs the fix.** No copy-paste, no clipboard, no display required. Confirm with Enter and it executes in your shell — so `cd`, `sudo`, and env changes all work.
- 🔌 **Bring your own brain.** Anthropic, OpenRouter, OpenCode Go/Zen, or local Ollama — switch providers with one command.
- 🪶 **Tiny and honest.** Just shell scripts. No daemon, no Python, no Node, no telemetry.
- 🔒 **Stays local if you want.** Point it at Ollama and nothing ever leaves your machine.

---

## 🚀 Install

### macOS / Linux (bash · zsh)

```sh
curl -fsSL https://raw.githubusercontent.com/TheSolyboy/oops/main/install.sh | bash
```

It drops the integration into `~/.local/share/oops/`, adds a `source` line to your `~/.bashrc` / `~/.zshrc`, and walks you through picking a provider, key, and model.

> [!IMPORTANT]
> `curl … | bash` runs in a *subshell* and can't touch the shell you're typing in. After installing, **open a new terminal** or run `source ~/.local/share/oops/oops.sh`.

### Windows (PowerShell · CMD)

```powershell
irm https://raw.githubusercontent.com/TheSolyboy/oops/main/install.ps1 | iex
```

It drops `oops.ps1` + `oops.cmd` into `%LOCALAPPDATA%\oops`, dot-sources from your PowerShell `$PROFILE`, adds the dir to your user `PATH` (so CMD works too), and walks you through setup.

> [!IMPORTANT]
> Open a **new** PowerShell/CMD window after installing so the profile and `PATH` changes take effect.

> [!NOTE]
> If you see *"running scripts is disabled on this system"*, your execution policy is blocking local scripts. Allow them once (user-scoped, Microsoft's recommended default) and finish setup:
>
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
> oops config
> ```

<details>
<summary>Manual install (from a clone)</summary>

**macOS / Linux:**

```sh
git clone https://github.com/TheSolyboy/oops.git
cd oops
./install.sh
```

**Windows:**

```powershell
git clone https://github.com/TheSolyboy/oops.git
cd oops
.\install.ps1
```

The installer copies the scripts out of the checkout instead of downloading them.

</details>

---

## 🔌 Providers

Pick one during setup, or switch later with `oops provider <name>`.

| Provider | Needs | Notes |
| --- | --- | --- |
| **Anthropic** | API key | Claude models, e.g. `claude-haiku-4-5-20251001` |
| **OpenRouter** | API key | Any model slug, e.g. `anthropic/claude-3.5-haiku` |
| **OpenCode** | API key | OpenCode Go/Zen cloud — default `https://opencode.ai/zen/go/v1`, models like `glm-5.1` |
| **Ollama** | — | Runs fully **local**, e.g. model `llama3.2`. Nothing leaves your machine. |

**Keys:** [Anthropic](https://console.anthropic.com/) · [OpenRouter](https://openrouter.ai/keys) · [OpenCode](https://opencode.ai/auth) · Ollama needs none — just `ollama serve` and pull a model.

> [!TIP]
> OpenCode speaks plain OpenAI-compatible chat completions, so `OOPS_BASE_URL` can point at *any* compatible endpoint (vLLM, LM Studio, a proxy, etc.).

---

## 🛠 Usage

```sh
oops                  # fix the last command that failed
oops config           # re-run the interactive setup
oops model <name>     # switch the model
oops provider <name>  # switch provider (anthropic|openrouter|ollama|opencode)
oops help             # show help
oops version          # show the version
```

When oops shows a fix it asks `Run it? [Y/n]`:

- <kbd>Enter</kbd> or `y` → run it in your current shell
- anything else → cancel, nothing happens

---

## ⚙️ Configuration

Everything lives in `~/.config/oops/config` (mode `600`, since it holds your key):

```sh
OOPS_PROVIDER="opencode"
OOPS_MODEL="glm-5.1"
OOPS_API_KEY="sk-..."
OOPS_BASE_URL="https://opencode.ai/zen/go/v1"   # used by OpenCode / Ollama
```

Edit it by hand, or just run `oops config` again.

---

## 🔒 Privacy

`oops` sends your failed command and its error output to the provider you choose.
If that matters to you, use **Ollama** — it runs entirely on your machine and
nothing leaves your computer.

> [!WARNING]
> To capture the error message, `oops` **re-runs your last command** (stdout and
> stderr are captured). Harmless for typos and bad flags — but be mindful if your
> last command had side effects.

---

## 📦 Requirements

**macOS / Linux:**

- **bash** or **zsh**
- **curl** *(required)*
- **jq** *(recommended — most reliable JSON parsing; a pure-bash fallback is used otherwise)*

**Windows:**

- **Windows PowerShell 5.1** (built in) or **PowerShell 7+** — works in CMD too
- No extra dependencies; networking and JSON are handled by PowerShell

---

## 🧹 Uninstall

**macOS / Linux:**

```sh
rm -rf ~/.local/share/oops ~/.config/oops
```

Then remove the `# oops shell assistant` block from your `~/.bashrc` / `~/.zshrc`.

**Windows:**

```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\oops", "$env:APPDATA\oops"
```

Then remove the `# oops shell assistant` line from your PowerShell `$PROFILE`, and drop `%LOCALAPPDATA%\oops` from your user `PATH`.

---

## 🤝 Contributing

Issues and PRs are welcome. The tool is a handful of small scripts:

- [`oops.sh`](oops.sh) — the sourced shell integration for bash/zsh (the `oops` function)
- [`install.sh`](install.sh) — the Unix installer and interactive setup
- [`oops.ps1`](oops.ps1) — the PowerShell edition (also powers the CMD wrapper)
- [`oops.cmd`](oops.cmd) — the CMD entry point
- [`install.ps1`](install.ps1) — the Windows installer and interactive setup

CI runs [ShellCheck](https://www.shellcheck.net/) on the shell scripts. Run it locally with:

```sh
shellcheck oops.sh install.sh
```

---

## License

[MIT](LICENSE) © Soly
