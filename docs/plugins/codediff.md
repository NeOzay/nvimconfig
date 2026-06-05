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
