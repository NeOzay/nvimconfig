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
- `snacks_win_opts.fixbuf = false` — sans ça, `snacks.win` reprend automatiquement son buffer terminal dès qu'un autre buffer apparaît dans sa fenêtre (comportement `fixbuf`, voir [[nvim-unception]] Gotchas), ce qui cassait l'édition du prompt en place via Ctrl+G. Contrepartie : voir Gotchas, `fixbuf = false` corrompt le suivi interne du terminal par snacks après un Ctrl+G, compensé par un autocmd dans `lua/autocmds.lua`.
- `diff_opts.hide_terminal_in_new_tab = false` — le terminal reste visible dans l'onglet diff (layout source | diff | terminal).

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
- **`fixbuf = false` corrompt le suivi interne du terminal par snacks après un Ctrl+G — cause racine identifiée après plusieurs correctifs infructueux.** `snacks/win.lua` → `M:fixbuf()` est appelé sur `BufWinEnter` de la fenêtre terminal gérée par snacks (`self.win`). Avec `fixbuf = false`, au lieu de restaurer le buffer terminal, il fait `self.buf = buf` (ligne ~946) : la fenêtre **adopte définitivement** le nouveau buffer (celui du prompt Ctrl+G) comme étant "son" buffer terminal. La restauration visuelle qui suit (par [[nvim-unception]], `split` + `buffer` + `wincmd x`) ne répare jamais ce champ interne puisqu'elle manipule les fenêtres directement sans passer par l'API de snacks — même si la fenêtre réaffiche visuellement le terminal, `self.buf` reste pointé sur le buffer du prompt. Or `claudecode/terminal/snacks.lua` → `get_active_bufnr()` lit exactement ce champ (`terminal.buf`). Conséquence observée : l'auto-attache du terminal dans l'onglet diff affiche le buffer du prompt au lieu du terminal, et `<A-c>` bascule vers le prompt plutôt que vers le terminal — de façon permanente, jusqu'au redémarrage de Neovim.
  - Fix dans `lua/autocmds.lua` : un cache indépendant (`claude_terminal_bufnr`, alimenté par un autocmd `TermOpen` au moment de la création du terminal, donc jamais corrompu) sert de source de vérité. Sur `QuitPre` du fichier de prompt, après `vim.schedule` (donc une fois `:quit` et la restauration d'unception terminés), on répare `self.buf` via l'API publique `set_buf()` de snacks (accessible via `require("claudecode.terminal.snacks")._get_terminal_for_test()`, qui malgré son nom retourne l'instance réelle utilisée en production) et on corrige visuellement toute fenêtre encore bloquée sur le buffer du prompt, dans tous les onglets.
  - Deux pistes explorées puis abandonnées avant d'identifier cette cause : (1) `hide_terminal_in_new_tab = true` pour éviter le layout diff à 3 fenêtres — évitait le symptôme mais sacrifiait la visibilité du terminal pendant la review ; (2) forcer `nvim_win_set_buf` vers `get_active_terminal_bufnr()` sur `QuitPre` — inefficace car cette fonction lit elle-même le champ déjà corrompu (`terminal.buf`), d'où le diagnostic "0 fenêtre corrigée" alors que le bug persistait.

## Changelog
- 2026-06-05 : Analyse initiale. Usage clarified : communication uniquement, terminal externe.
- 2026-07-22 : Identifié et corrigé la cause racine du terminal qui reste bloqué sur le buffer du prompt après Ctrl+G : `fixbuf = false` fait adopter le buffer du prompt en permanence par l'objet `snacks.win` (`self.buf`). Fix dans `lua/autocmds.lua` (cache `TermOpen` + réparation via `snacks.win:set_buf()` sur `QuitPre`), `hide_terminal_in_new_tab` reste `false`.
