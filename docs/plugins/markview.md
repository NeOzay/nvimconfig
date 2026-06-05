# markview

## Role
Rendu markdown dans les buffers (et notifications snacks), avec concealment de la syntaxe.

## Files
- Config: `lua/plugins/markview.lua`
- Fork: `OXY2DEV/markview.nvim` (dev, `~/projects/nvim-plugins/`)

## Key Behaviors
- `lazy = false` — chargé immédiatement.
- Active sur : `markdown`, `Avante`, `codecompanion`, `snacks_notif`.
- `code_blocks.style = "simple"` → pas de décoration fancy sur les blocs de code.
- `fancy_comments = true` (expérimental).
- Liste items avec `marker_minus.text = "●"`.
- Inline codes sans padding (`padding_left = ""`, `padding_right = ""`).

### Hook `hook_render`
Monkey-patche `markview.actions.render` pour :
1. Persister la config par buffer (quand `_config` est fourni → stocké, sinon → récupéré).
2. Ignorer les filetypes non-markdown sans config explicite.
Cela évite le rendu dans les fenêtres flottantes (signature help) qui ont le filetype markdown mais ne devraient pas être rendues.

### Highlight `@string.escape.markdown_inline`
- En mode Insert → restaure le highlight normal (symboles escapés visibles).
- En mode Normal/BufEnter → met fg/bg à `None` (symboles escapés invisibles).

### Intégration snacks notifier
Le notifier snacks appelle `markview.actions.render` et `set_query` directement sur chaque notification. `set_query` remplace temporairement la query markdown pour supprimer les `conceal_lines` des fence lines, redémarre le highlighter, puis restaure la query globale.

### Intégration snacks picker preview
Le preview du picker appache un `on_lines` debounced (10ms timer) qui appelle `ibl.setup_buffer` + `markview.render` si le filetype est dans `markview_fts`.

## Gotchas
- `ignore_buftypes = {}` (table vide) → markview s'applique même aux buffers `nofile`. Nécessaire pour `snacks_notif`.
- `set_query` est un workaround interne markview pour préserver les injections tout en cachant les fence lines.

## Changelog
- 2026-06-05 : Analyse initiale. Hook render, intégrations snacks documentées.
