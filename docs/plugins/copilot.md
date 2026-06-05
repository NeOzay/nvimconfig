# Copilot

## Role
GitHub Copilot : suggestions inline et source blink.cmp.

## Files
- Config: `lua/plugins/copilot.lua`

## Key Behaviors
- `copilot.lua` (zbirenbaum) avec suggestions inline activées (`auto_trigger = true`).
- NES (Next Edit Suggestion) : **désactivé** (`nes.enabled = false`).
- `copilot-lsp` (copilotlsp-nvim) chargé en dépendance → active `copilot_ls` via `vim.lsp.enable("copilot_ls")`.
- Menu blink.cmp ouvert/fermé : masque les suggestions Copilot inline (`vim.b.copilot_suggestion_hidden`) via autocmds `BlinkCmpMenuOpen`/`BlinkCmpMenuClose`.
- `blink-cmp-copilot` (giuxtaposition) : source blink distincte de `blink-copilot` (fang2hou).
- Panel Copilot désactivé (`panel.enabled = false`).

## Keymaps (suggestions inline)
| Touche | Action |
|--------|--------|
| `<tab>` | Accepter suggestion (mode normal, via copilot-lsp) |
| `<S-Right>` | Accepter mot |
| `<C-Right>` | Accepter ligne |
| `<esc>` | Rejeter |

## Gotchas
- `<tab>` en mode normal est défini par `copilot-lsp` : si `nes_state` actif → navigue dans NES, sinon → `<C-i>` (tab normal). NES est désactivé donc ce mapping agit toujours comme `<C-i>`.
- `vim.g.copilot_nes_debounce = 500` défini même si NES est désactivé.

## Changelog
- 2026-06-05 : Analyse initiale. NES désactivé documenté.
