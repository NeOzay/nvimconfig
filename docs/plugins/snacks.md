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
- **Preset responsive** : le preset par défaut est une fonction — `ivy_2` si `vim.o.columns < 120`, sinon `telescope`.
- Layout `telescope` custom (95% width, `max_width = 150`, 95% height, horizontal split, panneau gauche `max_width = 45`).
- **Preset `ivy_2`** : layout vertical full-screen — preview en haut, input au milieu (bordure top/bottom), list en bas (`height = 0.3`, `max_height = 10`). Conçu pour les terminaux étroits.
- **Preset `ivy_2_tall`** : hérite de `ivy_2`, modifie la list via `config` (`height = 0.6`, `max_height = 30`). Utilisé par le picker highlights sur les terminaux larges pour afficher plus de résultats.
- Icons déclarés dans `presets` (pas au niveau racine) : `selected = "+"`, `unselected = " "`.
- Win `list` : `number = false`, `relativenumber = false`, `foldcolumn = "0"`, `signcolumn = "no"`.
- Action `trouble_open` : envoie les résultats dans Trouble (`<c-q>`).
- Action `yank_text` / `yank` : copie le texte (`<c-y>`).
- Preview avec debounce 10ms qui appelle `ibl.setup_buffer` + markview si le filetype est markdown.
- `EndOfBuffer` highlight = `SnacksNormal` dans preview et list.
- `<c-j>` désactivé dans la list.
- Live grep (`<leader>fw`) force le preset `ivy_2`.
- Picker highlights (`<leader>f<C-j>`) : responsive — `ivy_2_tall` sous 120 cols, `telescope` au-dessus.

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
- `ivy_2_tall` modifie le layout via `config` (fonction qui itère `layout.layout`) car les presets héritent via `preset =` et ne peuvent pas surcharger directement une clé d'un sous-box.

## Changelog
- 2026-06-05 : Analyse initiale. Actions récursives explorer, intégrations markview/trouble documentées.
- 2026-06-11 : Layout `telescope` rendu responsive — si `vim.o.columns < 120`, bascule sur `preview = "main"` (preview dans l'arrière-plan) + panneau compact en bas, via `config`.
- 2026-06-17 : Refactor picker — preset par défaut devient une fonction responsive. Ajout presets `ivy_2` et `ivy_2_tall`. Layout `telescope` élargi (95%/150). Live grep force `ivy_2`. Highlights picker responsive `ivy_2_tall`/`telescope`.
