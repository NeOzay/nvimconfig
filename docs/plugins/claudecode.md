# claudecode.nvim

## Role
Pont entre Neovim et Claude Code (CLI dans un terminal externe) : partage de fichiers et de sélections.

## Files
- Config: `lua/plugins/claudecode.lua`

## Key Behaviors
- Usage : envoyer le buffer courant ou une sélection visuelle à Claude Code qui tourne dans un terminal séparé.
- Terminal provider : `"none"` — pas d'intégration terminal, Claude Code est lancé manuellement hors de Neovim.
- `lazy = false` — chargé immédiatement.
- `<leader>a` réservé comme préfixe "AI/Claude Code".

## Keymaps
| Touche | Mode | Action |
|--------|------|--------|
| `<leader>am` | n | Sélectionner le modèle Claude |
| `<leader>ab` | n | Ajouter le buffer courant au contexte |
| `<leader>as` | v | Envoyer la sélection à Claude |
| `<leader>as` | n (ft: explorer) | Ajouter fichier (ClaudeCodeTreeAdd) |
| `<leader>aa` | n | Accepter diff |
| `<leader>ad` | n | Refuser diff |

## Gotchas
- Les commandes de toggle terminal (`ClaudeCode`, `ClaudeCodeFocus`, `--resume`, `--continue`) sont commentées — non utilisées.

## Changelog
- 2026-06-05 : Analyse initiale. Usage clarified : communication uniquement, terminal externe.
