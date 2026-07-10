# codediff.nvim

## Role
Visualisation des diffs git avec explorer de fichiers, remplace diffview.

## Files
- Config: `lua/plugins/codediff.lua`

## Key Behaviors
- Explorer à gauche, largeur 25, vue `tree`.
- Historique en bas, hauteur 16.
- `cycle_next_hunk = true` → cycle automatique entre les hunks.
- `inlay_hints` désactivés dans les vues diff.
- Focalisé sur l'explorer à l'ouverture (`initial_focus = "explorer"`).
- Chaque diff ouvre un tab dédié, une session par tabpage dans `active_diffs` (`codediff.ui.lifecycle.session`), accessible via `codediff.ui.lifecycle.accessors` (`get_paths(tabnr)`, `get_git_context(tabnr)`, etc.). `mode` vaut `"standalone"` (un seul fichier) ou `"explorer"` (navigation git-root) ; dans les deux cas `modified_path`/`original_path` pointent vers le fichier affiché à l'instant.
- `lua/tabpage.lua` (`default_name`) détecte ces sessions via `accessors.get_paths(tabnr)` et nomme automatiquement le tab d'après le basename du fichier affiché — pas de renommage manuel nécessaire tant que l'utilisateur n'a pas fixé de nom custom (`tabname` var de tabpage).

## Keymaps
| Touche | Action |
|--------|--------|
| `<leader>gd` | Ouvrir CodeDiff |
| `<leader>gh` | Historique du fichier courant (HEAD~50) |
| `<leader>gH` | Historique global |

### Dans la vue diff
| Touche | Action |
|--------|--------|
| `q` | Fermer |
| `<leader>b` | Toggle explorer |
| `]c` / `[c` | Hunk suivant/précédent |
| `]f` / `[f` | Fichier suivant/précédent |
| `do` / `dp` | Diffget / diffput |
| `gf` | Aller au fichier |
| `-` | Stage toggle |

### Dans l'explorer
| Touche | Action |
|--------|--------|
| `<CR>` | Ouvrir |
| `K` | Preview |
| `R` | Rafraîchir |
| `i` | Toggle vue |
| `S` / `U` | Stage all / unstage all |
| `X` | Discard |

### Conflits
| Touche | Action |
|--------|--------|
| `<leader>co` | Accepter les nôtres |
| `<leader>ct` | Accepter les leurs |
| `<leader>cb` | Accepter les deux |
| `<leader>cx` | Rejeter les deux |
| `]x` / `[x` | Conflit suivant/précédent |

## Changelog
- 2026-06-05 : Analyse initiale.
- 2026-07-10 : Documentation de la détection auto des tabs CodeDiff par `lua/tabpage.lua`.
