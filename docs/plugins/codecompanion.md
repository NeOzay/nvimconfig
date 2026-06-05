# CodeCompanion

## Role
Chat IA intégré via GitHub Copilot, remplace copilot-chat.

## Files
- Config: `lua/plugins/codecompanion.lua`

## Key Behaviors
- Adapter : Copilot avec modèle `gpt-5-codex`.
- Toutes les stratégies (chat, inline, cmd) utilisent l'adapter copilot.
- Action palette via snacks (`provider = "snacks"`).
- markview s'attache automatiquement au buffer `codecompanion` via autocmd `FileType` (`:Markview attach`).
- Complétion dans le buffer codecompanion via source blink.cmp `codecompanion`.

## Keymaps
| Touche | Mode | Action |
|--------|------|--------|
| `<leader>ca` | n, v | Toggle Chat |
| `<leader>cp` | n, v | Actions Palette |
| `<leader>ci` | v | Ajouter sélection au chat |

## Gotchas
- `lazy = true` (chargé sur cmd/keys uniquement).

## Changelog
- 2026-06-05 : Analyse initiale.
