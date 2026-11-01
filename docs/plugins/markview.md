# markview

## Role
Rendu markdown dans les buffers (et notifications snacks), avec concealment de la syntaxe.

## Files
- Config: `lua/plugins/markview.lua`
- Fork: `NeOzay/markview.nvim` (upstream `OXY2DEV/markview.nvim`) — submodule git `plugins/markview.nvim/`

## Key Behaviors
- `cond = is_active("markview")` : chargé seulement s'il est le moteur du démarrage (`:MarkdownRenderer`, défaut sans fichier d'état). `cond` et non `enabled`, pour rester installé quand render-markdown est actif. Autre moteur : [`render-markdown.md`](render-markdown.md).
- Les autocmds d'escape (`@string.escape.markdown_inline`) sont dans `escape_highlights()`, appelée par `config` : le moteur inactif n'en laisse aucune trace.
- Active sur : `FILETYPES` de `lua/markdown_renderer/` (`markdown`, `Avante`, `codecompanion`, `snacks_notif`) pour `preview.filetypes`.
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

### Intégrations (abstraction `lua/markdown_renderer/`)
Le notifier, la preview du picker, le hover LSP et codecompanion n'appellent plus markview : ils passent par `require("markdown_renderer")` (`render_notification`, `render_preview`, `render_hover`, `attach`), qui route vers `lua/markdown_renderer/markview.lua` (le code d'origine, déplacé tel quel).

### Intégration snacks notifier
L'adaptateur appelle `markview.actions.render` et `set_query` sur chaque notification. `set_query` remplace temporairement la query markdown pour supprimer les `conceal_lines` des fence lines, redémarre le highlighter, puis restaure la query globale.

### Intégration snacks picker preview
Le preview du picker appache un `on_lines` debounced (10ms timer) qui appelle `ibl.setup_buffer` + le rendu de l'adaptateur si le filetype est dans `FILETYPES`.

## Gotchas
- `ignore_buftypes = {}` (table vide) → markview s'applique même aux buffers `nofile`. Nécessaire pour `snacks_notif`.
- `set_query` est un workaround interne markview pour préserver les injections tout en cachant les fence lines.

## Changelog
- 2026-06-05 : Analyse initiale. Hook render, intégrations snacks documentées.
- 2026-07-27 : fork migré en submodule git sous `plugins/markview.nvim/` ; la spec Lazy utilise `dir = vim.fn.stdpath("config") .. "/plugins/markview.nvim"` (plus de `dev = true`, `dev.path` supprimé de `lazy-conf.lua`).
- 2026-11-01 : spec sous `cond` lié à `:MarkdownRenderer`, intégrations migrées dans `lua/markdown_renderer/markview.lua`, autocmds d'escape déplacées dans `config`.
