# Copilot

## Role
GitHub Copilot : suggestions inline et source blink.cmp, via LSP natif Neovim 0.11+.

## Files
- Config: `lua/plugins/copilot.lua`
- LSP config: `lsp/copilot_ls.lua`
- Termux patch: `lua/utils/copilot_termux_patch.lua`

## Key Behaviors
- `copilot.lua` (zbirenbaum) avec suggestions inline activées (`auto_trigger = true`).
- NES (Next Edit Suggestion) : **activé** (`nes.enabled = true`, `auto_trigger = true`).
- `copilot-lsp` (copilotlsp-nvim) chargé en dépendance → active `copilot_ls` via `vim.lsp.enable("copilot_ls")`.
- `lsp/copilot_ls.lua` : config LSP native (`vim.lsp.config`). Handlers et init NES via `copilot-lsp.handlers` / `copilot-lsp.nes`.
- Menu blink.cmp ouvert/fermé : masque les suggestions Copilot inline (`vim.b.copilot_suggestion_hidden`) via autocmds `BlinkCmpMenuOpen`/`BlinkCmpMenuClose`.
- `blink-cmp-copilot` (giuxtaposition) : source blink distincte de `blink-copilot` (fang2hou).
- Panel Copilot désactivé (`panel.enabled = false`).
- **Termux** : `lua/utils/copilot_termux_patch.lua` appliqué via `build` lazy.nvim. Corrige deux problèmes :
  1. `process.platform === "android"` → symlink `compiled/android/arm64` → `compiled/linux/arm64`.
  2. `.node` addons NDK-incompatibles → patch `main.js` avec try/catch + stub no-op.
- `lsp/copilot_ls.lua` → `resolve_cmd()` : si `/usr/bin/env` absent (Termux), appelle `node <bin> --stdio` directement au lieu du shebang.
- `lua/lsp/init.lua` : exclusion workspace-diagnostics via `string.find(client.name, "copilot")` (couvre `copilot` et `copilot_ls`).

## Keymaps (suggestions inline)
| Touche | Action |
|--------|--------|
| `<C-i>` | Accepter suggestion / naviguer dans NES (mode normal, via copilot-lsp) |
| `<S-Right>` | Accepter mot |
| `<C-Right>` | Accepter ligne |
| `<esc>` | Rejeter |

## Gotchas
- `<C-i>` en mode normal : si `nes_state` actif → `walk_cursor_start_edit()`, sinon `apply_pending_nes() + walk_cursor_end_edit()`, sinon retourne `"<C-i>"` (tab normal).
- `vim.g.copilot_nes_debounce = 500` défini.
- Le patch Termux ne tourne qu'une fois (sentinelle `_watcher_stub_` dans `main.js`) et est idempotent sur les re-builds.

## Changelog
- 2026-06-05 : Analyse initiale. NES désactivé documenté.
- 2026-06-17 : Migration LSP natif (`lsp/copilot_ls.lua`). NES activé. Termux patch (`lua/utils/copilot_termux_patch.lua`). Exclusion workspace-diagnostics élargie à `copilot_ls`.
