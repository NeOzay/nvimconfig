# Snacks

## Role
Suite de micro-plugins : picker, explorer, notifier, terminal, scratch. Chaque sous-module est dans `lua/plugins/snacks/`.

## Files
- Config picker: `lua/plugins/snacks/picker.lua`
- Config explorer: `lua/plugins/snacks/explorer.lua`
- Config notifier: `lua/plugins/snacks/notifier.lua`
- Guide picker custom: `docs/plugins/snacks-picker-custom.md`

## Key Behaviors

### Picker
- Layout `telescope` custom (80% width, 90% height, horizontal split).
- Action `trouble_open` : envoie les résultats dans Trouble (`<c-q>`).
- Action `yank_text` / `yank` : copie le texte (`<c-y>`).
- Preview avec debounce 10ms qui appelle `ibl.setup_buffer` + markview si le filetype est markdown.
- `EndOfBuffer` highlight = `SnacksNormal` dans preview et list.
- `<c-j>` désactivé dans la list.
- Icons : `selected = "+"`, `unselected = " "`.

### Explorer
- `replace_netrw = true`.
- Layout `telescope` avec preview activé.
- Actions custom de navigation récursive : `explorer_open_recursive`, `explorer_close_recursive`, `explorer_open_all`, `explorer_toggle_recursive`, `explorer_jump_parent`, `explorer_jump_next_parent`, `explorer_next_dir`, `explorer_prev_dir`.
- `auto_close = true`, `jump.close = true` → ferme l'explorer après navigation.
- `on_show` : synchronise le curseur picker avec la position du buffer principal.
- Vue "buffers seulement" (`<leader>eb`) : construit une liste `include_paths` avec tous les buffers chargés + leurs répertoires parents jusqu'au cwd.

### Notifier
- Timeout 5000ms.
- Notifications renduées avec markview (markdown inline dans les toasts).
- `on_win` hook : étend `winhighlight` pour couvrir `EndOfBuffer`, `StatusColumn`, `LineNr` avec la couleur de la notification.
- `conceallevel = 2` + `concealcursor = "n"` dans les fenêtres de notification.
- Picker `notifications` avec layout horizontal telescope + preview markdown avec wrap.

## Keymaps Picker
| Touche | Action |
|--------|--------|
| `<leader>fw` | Live grep |
| `<leader>fb` | Buffers |
| `<leader>ff` / `<F3>` | Find files |
| `<leader>fa` | Find all files (hidden + ignored) |
| `<leader>fo` | Recent files |
| `<leader>fz` | Lines dans le buffer courant |
| `<leader>fh` | Help |
| `<leader>fj` | Jumplist |
| `<leader>fr` | Resume dernier picker |
| `<leader>ma` | Marks |
| `<leader>cm` | Git log |
| `<leader>gt` | Git status |
| `<leader>f<C-j>` | Highlights |
| `<leader>th` | Colorschemes |

## Keymaps Explorer
| Touche | Action |
|--------|--------|
| `<leader>ee` | Explorer |
| `<leader>ea` | Explorer (hidden + ignored) |
| `<leader>ec` | Reveal fichier courant |
| `<leader>eb` | Explorer (buffers ouverts seulement) |
| `<leader>eg` | Git status picker |

### Touches dans l'explorer (list)
| Touche | Action |
|--------|--------|
| `za` | Ouvrir |
| `zA` | Toggle récursif |
| `zR` | Tout ouvrir |
| `zM` | Tout fermer |
| `zc` | Fermer |
| `zC` | Fermer récursif |
| `zo` | Ouvrir |
| `zO` | Ouvrir récursif |
| `S` | Ouvrir en split horizontal |
| `s` | Ouvrir en vsplit |
| `t` | Ouvrir dans un onglet |
| `R` | Rafraîchir |
| `]d` / `[d` | Prochain/précédent diagnostic |
| `<C-Down>` / `<C-Up>` | Prochains/précédent répertoire |
| `<S-C-Up>` / `<S-C-Down>` | Aller au répertoire parent |

## Commandes
- `:Pickers` → liste tous les pickers disponibles.
- `:Notifi` → ouvre le picker notifications.

## Gotchas
- Le picker est configuré en mode `SnacksSubmodule` (retourne `{ opts, keys }`) — pas un `LazyPluginSpec` direct.
- La vue "buffers seulement" dans l'explorer utilise `include`/`exclude` de snacks explorer, pas un filtre standard.

## Changelog
- 2026-06-05 : Analyse initiale. Actions récursives explorer, intégrations markview/trouble documentées.
