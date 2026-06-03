Build a CLI tool called "oops" — an open source bash/zsh shell assistant that fixes your last terminal command using AI.

## How it works
1. User runs a command that fails
2. User types `oops` in the terminal
3. The tool captures the last command + stderr output
4. Sends it to the configured AI provider
5. Prints the suggested fix + copies it to clipboard
6. User presses Ctrl+V and Enter

## Project structure
- Single install script (install.sh) that works with curl | bash
- Shell integration file that gets sourced in .bashrc / .zshrc
- Config file at ~/.config/oops/config (provider, model, api key)
- Works on bash and zsh

## Providers (user picks one during setup)
- Anthropic (claude models)
- OpenRouter
- Ollama (local)
- OpenCode Go

## Install flow
Running the install script should:
1. Ask which provider they want
2. Ask for API key (or base URL for Ollama)
3. Ask which model to use
4. Write config file
5. Add source line to .bashrc or .zshrc automatically

## CLI usage
- `oops` — fix last command
- `oops config` — re-run setup
- `oops model <name>` — switch model
- `oops provider <name>` — switch provider

## Requirements
- Pure bash, no python/node dependency
- Clipboard support via xclip or xsel (check which is available, fall back to just printing)
- Clean README with badges, install command, and provider setup instructions
- MIT license
- .github/workflows for basic CI (shellcheck)

## Output format
The AI should return ONLY the fixed command, nothing else. Use a strict system prompt enforcing this.

## Repo
Public GitHub repo, clean structure, ready for open source contributions.
