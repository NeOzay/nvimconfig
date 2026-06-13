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
- Preview responsive : la fonction `config` du layout `telescope` (réévaluée à l'ouverture et sur `VimResized`) bascule sur `preview = "main"` quand `vim.o.columns < 120`. La preview s'affiche alors dans la fenêtre d'arrière-plan (buffer courant) et le picker devient un panneau compact en bas (`box = "vertical"`, `height = 0.4`, `position = "bottom"`) pour garder l'arrière-plan visible. La win `preview` doit **rester listée dans le box** même dans ce mode : snacks la marque `layout = false` (`relative = "win"`) donc elle n'occupe pas de place, mais `get_wins` ne parcourt que la structure du box — sans cette entrée la fenêtre de preview n'est jamais ouverte au premier affichage et la preview reste vide jusqu'à un cycle de resize (cf. preset `ivy_split`).
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
- Mode `preview = "main"` : toujours garder `{ win = "preview" }` dans le box, sinon `get_wins` (`snacks/layout.lua`) n'ouvre jamais la fenêtre de preview au premier affichage (preview vide tant qu'on n'a pas redimensionné le terminal).
- Le `wo` posé sur l'entrée `{ win = "preview" }` du box **n'est pas appliqué** en mode `preview = "main"` : la win est en `layout = false`, donc `update_win` (qui applique le `wo` du box) ne tourne jamais pour elle. Les options de fenêtre de la preview (statuscolumn, number…) doivent être posées sur `win.preview.wo` (config globale), pas sur le box.
- La statuscolumn de statuscol s'affiche dans la preview car c'est un float et l'autocmd statuscol ignore les floats (`conditions.lua` → `cfg.relative ~= ""`). On la neutralise via `win.preview.wo.statuscolumn = ""`.
- Le picker est configuré en mode `SnacksSubmodule` (retourne `{ opts, keys }`) — pas un `LazyPluginSpec` direct.
- La vue "buffers seulement" dans l'explorer utilise `include`/`exclude` de snacks explorer, pas un filtre standard.

## Changelog
- 2026-06-05 : Analyse initiale. Actions récursives explorer, intégrations markview/trouble documentées.
- 2026-06-11 : Layout `telescope` rendu responsive — si `vim.o.columns < 120`, bascule sur `preview = "main"` (preview dans l'arrière-plan) + panneau compact en bas, via `config`.
