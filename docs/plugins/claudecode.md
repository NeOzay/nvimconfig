# claudecode.nvim

## Role
Pont entre Neovim et Claude Code (CLI dans un terminal externe) : partage de fichiers et de sélections.

## Files
- Config: `lua/plugins/claudecode.lua`
- Highlights: `lua/highlights/claudecode.lua`

## Key Behaviors
- Usage : envoyer le buffer courant ou une sélection visuelle à Claude Code.
- Terminal provider : `"snacks"` — Claude Code tourne dans un split snacks docké à droite (`<A-c>` pour toggle, `position = "right"` dans `snacks_win_opts`).
- `lazy = false` — chargé immédiatement.
- `<leader>a` réservé comme préfixe "AI/Claude Code".
- `diff_opts.layout = "vertical"` par défaut ; le mode `"unified"` (diff inline dans un seul buffer) utilise les groupes de highlight définis dans `lua/highlights/claudecode.lua` : `ClaudeCodeInlineDiffAdd`, `ClaudeCodeInlineDiffDelete`, `ClaudeCodeInlineDiffAddSign`, `ClaudeCodeInlineDiffDeleteSign`. Bg add/delete réutilisent les couleurs `CodeDiffLineInsert`/`CodeDiffLineDelete` (base46/config.lua) pour rester cohérent avec codediff.nvim ; les signs utilisent `colors.green`/`colors.red`.
- `opts.env = { EDITOR = "nvim" }` — fixe `$EDITOR` uniquement dans le terminal Claude Code (pas globalement). Combiné à [[nvim-unception]], Ctrl+G dans Claude Code (édition du prompt) ouvre le fichier dans l'instance Nvim hôte au lieu d'imbriquer un Nvim dans le terminal.
- `snacks_win_opts.fixbuf = false` — sans ça, `snacks.win` reprend automatiquement son buffer terminal dès qu'un autre buffer apparaît dans sa fenêtre (comportement `fixbuf`, voir [[nvim-unception]] Gotchas), ce qui cassait l'édition du prompt en place via Ctrl+G.

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
