# Snacks

## Role
Suite de micro-plugins : picker, explorer, notifier, terminal, scratch. Chaque sous-module est dans `lua/plugins/snacks/`.

## Files
- Config picker (générique + agrégation keys): `lua/plugins/snacks/picker/init.lua`
- Pickers custom autonomes: `lua/plugins/snacks/picker/sources/tabpages.lua`, `lua/plugins/snacks/picker/sources/harpoon.lua`
- Config explorer: `lua/plugins/snacks/explorer.lua`
- Config notifier: `lua/plugins/snacks/notifier.lua`
- Config terminal: `lua/plugins/snacks/terminal.lua`
- Guide picker custom: `docs/plugins/snacks-picker-custom.md`

## Key Behaviors

### Picker
- **Preset responsive** : le preset par défaut est une fonction — `ivy_2` si `vim.o.columns < 120`, sinon `telescope`.
- Layout `telescope` custom (95% width, `max_width = 150`, 95% height, horizontal split, panneau gauche `max_width = 45`).
- **Preset `ivy_2`** : layout vertical full-screen — preview en haut, input au milieu (bordure top/bottom), list en bas (`height = 0.3`, `max_height = 10`). Conçu pour les terminaux étroits.
- **Preset `ivy_2_tall`** : hérite de `ivy_2`, modifie la list via `config` (`height = 0.6`, `max_height = 30`). Utilisé par le picker highlights sur les terminaux larges pour afficher plus de résultats.
- **Preset `bottom_compact`** : sans preview, compact (`width = 0.5`, `height = 0.3`, bornes `min/max_width` 60-100, `min/max_height` 8-16), ancré en bas (`row = -2`) et centré horizontalement (`col` non défini → centrage par défaut de `snacks.win`). Utilisé par le picker tabpages.
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
- Finder "fichiers > 300 lignes" (`<leader>el`) : `big_files_finder` parcourt tout l'arbre via `snacks.explorer.tree` indépendamment de l'état plié/déplié, force l'expansion, ne garde que les fichiers dépassant le seuil et leurs dossiers parents (branches vides élaguées). Affiche le nombre de lignes en suffixe (`Snacks.picker.format.file` + extension custom).

### Terminal
- Split `below`, `stack = true` (empile les terminaux successifs), `height = 0.2`.
- Toggle : `<C-ù>` (n/t), `q` cache, `<C-x>` sort du mode insertion.
- **Thème distinct de l'éditeur** : `win.wo.winhighlight` mappe `Normal`/`NormalNC`/`EndOfBuffer` vers les groupes `TerminalNormal`/`TerminalNormalNC` (définis dans `lua/highlights/snacks.lua`, palette résolue via `base46.get_term_theme_tb` — voir `docs/plugins/theme-highlights.md` § Thème du terminal). Piloté par la clé `term_theme` de `lua/base46/config.lua` (`nil` = même thème que l'éditeur).
- Les couleurs ANSI (`terminal_color_0..15`) suivent aussi `term_theme` (posées une seule fois au démarrage dans `base46/init.lua`, globales à l'instance Nvim).

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
| `<leader>tt` | Tabpages |

## Keymaps Explorer
| Touche | Action |
|--------|--------|
| `<leader>ee` | Explorer |
| `<leader>ea` | Explorer (hidden + ignored) |
| `<leader>ec` | Reveal fichier courant |
| `<leader>eb` | Explorer (buffers ouverts seulement) |
| `<leader>eg` | Git status picker |
| `<leader>el` | Explorer (fichiers > 300 lignes) |

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

## Keymaps Tabpages
| Touche | Action |
|--------|--------|
| `<leader>tt` | Picker tabpages |
| `<leader>tr` | Renommer le tab courant |
| `<A-r>` / `r` (dans le picker) | Renommer le tab sous le curseur |
| `<A-d>` / `dd` (dans le picker) | Fermer le tab sous le curseur |
| `<A-n>` / `a` (dans le picker) | Nouveau tab |
| `<A-c>` / `c` (dans le picker) | Changer le cwd du tab (`:tcd`) |

### Noms de tabpages
- Aucun nom natif dans Neovim : `lua/tabpage.lua` stocke un nom custom dans `vim.t[tabnr].tabname`.
- Nom par défaut si non renommé : basename du cwd local (`:tcd`) si différent du cwd global, sinon numéro du tab (pas de fallback sur le nom du buffer).
- Affiché dans lualine (`lualine_y`, icône 󰓩) uniquement s'il y a plus d'un tabpage.

## Commandes
- `:Pickers` → liste tous les pickers disponibles.
- `:Notifi` → ouvre le picker notifications.

## Gotchas
- **ANSI du terminal non rechargées à chaud** : `g:terminal_color_0..15` (posées depuis `term_theme`, voir `theme-highlights.md`) ne sont lues par Neovim qu'au moment de `TermOpen` (`:h terminal_color_x`). `:Base46Reload` met à jour la variable globale mais un terminal déjà ouvert garde son ancienne palette ANSI. Or `q` et le toggle `<C-ù>` (`terminal.lua`) ne font que `self:hide()` — jamais de vrai `close()` — donc le job shell reste vivant et `TermOpen` ne se redéclenche jamais tant qu'on ne tue pas vraiment le terminal. **Pour voir un changement d'ANSI** : `exit` dans le shell (ou `:bd!` sur le buffer terminal) puis rouvrir avec `<C-ù>`. Le fond/texte (`TerminalNormal`/`TerminalNormalNC`) n'a pas ce problème : ce sont des groupes de highlight classiques, résolus par `winhighlight` à chaque redraw, donc rechargés à chaud normalement.
- Mode `preview = "main"` : toujours garder `{ win = "preview" }` dans le box, sinon `get_wins` (`snacks/layout.lua`) n'ouvre jamais la fenêtre de preview au premier affichage (preview vide tant qu'on n'a pas redimensionné le terminal).
- Le `wo` posé sur l'entrée `{ win = "preview" }` du box **n'est pas appliqué** en mode `preview = "main"` : la win est en `layout = false`, donc `update_win` (qui applique le `wo` du box) ne tourne jamais pour elle. Les options de fenêtre de la preview (statuscolumn, number…) doivent être posées sur `win.preview.wo` (config globale), pas sur le box.
- La statuscolumn de statuscol s'affiche dans la preview car c'est un float et l'autocmd statuscol ignore les floats (`conditions.lua` → `cfg.relative ~= ""`). On la neutralise via `win.preview.wo.statuscolumn = ""`.
- Le picker est configuré en mode `SnacksSubmodule` (retourne `{ opts, keys }`) — pas un `LazyPluginSpec` direct.
- La vue "buffers seulement" dans l'explorer utilise `include`/`exclude` de snacks explorer, pas un filtre standard.
- `ivy_2_tall` modifie le layout via `config` (fonction qui itère `layout.layout`) car les presets héritent via `preset =` et ne peuvent pas surcharger directement une clé d'un sous-box.

## Changelog
- 2026-07-22 : terminal — thème distinct de l'éditeur via `term_theme` (`base46/config.lua`), groupes `TerminalNormal`/`TerminalNormalNC` appliqués par `win.wo.winhighlight`. Gotcha documenté : ANSI non rechargées à chaud (`TermOpen`-only, terminal jamais vraiment fermé par `q`/toggle).
- 2026-07-09 : hauteur de la box du picker tabpages ajustée au nombre de tabs (`item_count + 3`, bornée par `min/max_height` de `bottom_compact`). Calculée une fois à l'ouverture — un `tab_close` pendant que le picker est ouvert ne rétrécit pas la box (le contenu de la list se met à jour via `refresh()`, pas le conteneur).
- 2026-07-09 : nouveau preset `bottom_compact` (`picker/init.lua`) — compact, centré, ancré en bas (`row = -2`). Utilisé par le picker tabpages à la place de `ivy_2` (full-screen, pensé pour d'autres pickers).
- 2026-07-09 : les floats (dont le picker) appartiennent à un seul tabpage — `nvim_set_current_tabpage` masque le picker au lieu de le suivre, ce qui déclenchait l'auto-close (`WinEnter` hors picker). `open_tabpage_picker` (dans `tabpages.lua`) est maintenant une fonction récursive : `on_change` ferme le picker (`switching = true` pour court-circuiter le revert de `on_close`), change de tab, puis rouvre un nouveau picker sur ce tab avec `on_show` repositionnant le curseur sur le même item (`preselect_tab`) et `pattern` conservant le texte tapé. `accept`/`tab_new` ne déclenchent pas de réouverture (juste `accepted = true`).
- 2026-07-09 : picker tabpages sans preview (`layout.hidden = {"preview"}`) ; navigation live (`on_change` bascule immédiatement sur le tab sous le curseur) ; annulation (`<Esc>`/`q`) restaure le tab d'origine via `on_close`, sauf si `confirm`/`tab_new` a positionné un flag `accepted`.
- 2026-07-09 : nom par défaut d'un tab non renommé remplacé par son numéro (au lieu du nom du buffer affiché). Ajout de l'action `tab_cwd` (`<A-c>`/`c`) dans le picker tabpages pour affecter un cwd local (`:tcd`) au tab sous le curseur.
- 2026-07-08 : regroupement des pickers custom sous `lua/plugins/snacks/picker/` — `picker/init.lua` (ex `picker.lua`, config générique + agrégation keys) + `picker/sources/{tabpages,harpoon}.lua`. Suppression de `lua/pickers/` (dossier fragmenté, contenait aussi `init.lua` cassé et `jumplist.lua`, doublon Telescope mort de `Snacks.picker.jumps()`). `picker.sources.explorer`/`picker.sources.notifications` restent dans `explorer.lua`/`notifier.lua` (config intrinsèque à ces features).
- 2026-07-08 : ajout gestion des tabpages — picker (`<leader>tt`, logique dans `lua/plugins/snacks/picker/sources/tabpages.lua`), rename (`<leader>tr`), nom affiché dans lualine. Logique de nommage dans `lua/tabpage.lua` (hors snacks, réutilisée par lualine).
- 2026-06-05 : Analyse initiale. Actions récursives explorer, intégrations markview/trouble documentées.
- 2026-06-11 : Layout `telescope` rendu responsive — si `vim.o.columns < 120`, bascule sur `preview = "main"` (preview dans l'arrière-plan) + panneau compact en bas, via `config`.
- 2026-06-17 : Refactor picker — preset par défaut devient une fonction responsive. Ajout presets `ivy_2` et `ivy_2_tall`. Layout `telescope` élargi (95%/150). Live grep force `ivy_2`. Highlights picker responsive `ivy_2_tall`/`telescope`.
