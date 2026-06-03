<div align="center">

# oops

**Typed the wrong command? Just say `oops`.**

A tiny shell assistant that takes your last failed command, asks an AI to fix it,
and drops the corrected command straight onto your clipboard.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash%20%7C%20zsh-1f425f.svg)](#requirements)
[![CI](https://github.com/TheSolyboy/oops/actions/workflows/ci.yml/badge.svg)](https://github.com/TheSolyboy/oops/actions/workflows/ci.yml)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#contributing)

</div>

---

```console
$ git stahtus
git: 'stahtus' is not a git command. See 'git --help'.

$ oops
oops: re-running "git stahtus" to capture the error...
oops: asking anthropic (claude-haiku-4-5-20251001)...

git status

oops: copied to clipboard — paste with Ctrl+V (or Cmd+V) and press Enter.
```

You press <kbd>Ctrl</kbd>+<kbd>V</kbd>, then <kbd>Enter</kbd>. Done.

## How it works

1. You run a command and it fails.
2. You type **`oops`**.
3. `oops` grabs your last command, re-runs it to capture the error output, and
   sends both to your configured AI provider.
4. The AI replies with **only** the corrected command.
5. `oops` prints it and copies it to your clipboard.
6. You paste and run it.

No daemon, no telemetry, no Python or Node — just a single shell function and `curl`.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/TheSolyboy/oops/main/install.sh | bash
```

The installer will:

1. Drop the shell integration into `~/.local/share/oops/oops.sh`
2. Add a `source` line to your `~/.bashrc` or `~/.zshrc`
3. Walk you through picking a **provider**, **API key**, and **model**
4. Save your config to `~/.config/oops/config`

Then restart your shell (or `source` the file it printed) and you are ready.

<details>
<summary>Manual install (from a clone)</summary>

```sh
git clone https://github.com/TheSolyboy/oops.git
cd oops
./install.sh
```

The installer copies `oops.sh` out of the checkout instead of downloading it.

</details>

## Providers

Pick one during setup (or switch later with `oops provider <name>`).

| Provider | Needs | Notes |
| --- | --- | --- |
| **Anthropic** | API key | Claude models, e.g. `claude-haiku-4-5-20251001` |
| **OpenRouter** | API key | Any model slug, e.g. `anthropic/claude-3.5-haiku` |
| **Ollama** | base URL | Runs fully **local**, e.g. model `llama3.2` |
| **OpenCode** | base URL (+ optional key) | Any OpenAI-compatible endpoint |

Where to get a key:

- **Anthropic** — <https://console.anthropic.com/>
- **OpenRouter** — <https://openrouter.ai/keys>
- **Ollama** — nothing to buy; `ollama serve` and pull a model
- **OpenCode** — point it at your local OpenAI-compatible server

## Usage

```sh
oops                  # fix the last command that failed
oops config           # re-run the interactive setup
oops model <name>     # switch the model
oops provider <name>  # switch provider (anthropic|openrouter|ollama|opencode)
oops help             # show help
oops version          # show the version
```

## Configuration

Everything lives in `~/.config/oops/config` (mode `600`, since it holds your key):

```sh
OOPS_PROVIDER="anthropic"
OOPS_MODEL="claude-haiku-4-5-20251001"
OOPS_API_KEY="sk-..."
OOPS_BASE_URL=""        # used by Ollama / OpenCode
```

Edit it by hand, or just run `oops config` again.

## Requirements

- **bash** or **zsh**
- **curl** (required)
- **jq** (recommended — most reliable JSON parsing; a pure-bash fallback is used otherwise)
- A clipboard tool (optional, for auto-copy): `xclip`, `xsel`, `wl-clipboard`, or `pbcopy` on macOS

## Privacy

`oops` sends your failed command and its error output to the provider you choose.
If that matters to you, use **Ollama** — it runs entirely on your machine and
nothing leaves your computer.

> [!NOTE]
> To capture the error message, `oops` **re-runs your last command** (stdout and
> stderr are captured). This is harmless for typos and bad flags, but be mindful
> if your last command had side effects.

## Uninstall

```sh
rm -rf ~/.local/share/oops ~/.config/oops
```

Then remove the `# oops shell assistant` block from your `~/.bashrc` / `~/.zshrc`.

## Contributing

Issues and PRs are welcome. The whole tool is two shell scripts:

- [`oops.sh`](oops.sh) — the sourced shell integration (the `oops` function)
- [`install.sh`](install.sh) — the installer and interactive setup

CI runs [ShellCheck](https://www.shellcheck.net/) on both. Run it locally with:

```sh
shellcheck oops.sh install.sh
```

## License

[MIT](LICENSE) © Soly
