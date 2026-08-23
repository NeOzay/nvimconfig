# codediff.nvim

## Role
Visualisation des diffs git avec explorer de fichiers, remplace diffview.

## Files
- Config: `lua/plugins/codediff.lua`
- Fork: `NeOzay/codediff.nvim` (upstream `esmuellert/codediff.nvim`) — submodule git `plugins/codediff.nvim/`

## Key Behaviors
- Explorer à gauche, largeur 25, vue `tree`.
- Historique en bas, hauteur 16.
- `cycle_next_hunk = true` → cycle automatique entre les hunks.
- `inlay_hints` désactivés dans les vues diff.
- Focalisé sur l'explorer à l'ouverture (`initial_focus = "explorer"`).
- Layout `--inline` automatique quand `vim.o.columns < 100` (petit terminal, ex. Neovim sur
  téléphone) : les touches `<leader>gd`/`<leader>gh`/`<leader>gH` sont des fonctions Lua (pas
  des `<cmd>`) qui construisent la commande `:CodeDiff [--inline] ...` à l'appel. Le flag
  `--inline` est global à l'arbre argparse (`Arg.flag("inline"):global(true)`), donc utilisable
  aussi bien sur `CodeDiff` que `CodeDiff history`.
- L'explorer se ferme automatiquement après la sélection d'un fichier (`<CR>` ou navigation
  `]f`/`[f`), via l'autocmd `User CodeDiffFileSelect` émis par
  `codediff.ui.explorer.render` (`data = { tabpage, path, status }`). Le handler récupère
  l'explorer avec `codediff.ui.lifecycle.get_explorer(tabpage)` et appelle
  `codediff.ui.explorer.toggle_visibility(explorer)` s'il n'est pas déjà masqué (champ
  `explorer.is_hidden`). Pratique sur petit écran ; se re-rouvre avec `<leader>E`
  (`toggle_explorer`).
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
- 2026-07-27 : fork migré en submodule git sous `plugins/codediff.nvim/` ; la spec Lazy utilise `dir = vim.fn.stdpath("config") .. "/plugins/codediff.nvim"` (plus de `dev = true`, `dev.path` supprimé de `lazy-conf.lua`).
- 2026-08-23 : layout `--inline` auto sous 100 colonnes (usage mobile) + fermeture auto de l'explorer à la sélection d'un fichier (`User CodeDiffFileSelect`).
