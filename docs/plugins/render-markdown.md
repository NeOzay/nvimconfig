# render-markdown

## Role
Moteur de rendu markdown alternatif à markview (`MeanderingProgrammer/render-markdown.nvim`). Un seul des deux est chargé par démarrage, au choix de `:MarkdownRenderer`.

## Files
- Config: `lua/plugins/render-markdown.lua` (spec, `cond` lié à l'état)
- Adaptateur: `lua/markdown_renderer/render_markdown.lua`
- Highlights: `lua/highlights/render-markdown.lua` (remplace entièrement `lua/base46/integrations/render-markdown.lua`, titres compris)
- Related: `lua/markdown_renderer/` (état + abstraction), `lua/cmd.lua` (`:MarkdownRenderer`), `tests/markdown_renderer/`

## Key Behaviors
- `cond = is_active("render-markdown")` et non `enabled` : le plugin reste installé quand markview est actif, `:Lazy clean` ne le supprime pas.
- Le moteur actif est lu une fois au démarrage dans le fichier d'état (`stdpath("state")/markdown-renderer`) et figé ; `:MarkdownRenderer <moteur>` n'écrit que le moteur du prochain démarrage (pas de bascule à chaud).
- `file_types = FILETYPES` (`markdown`, `Avante`, `codecompanion`, `snacks_notif`) : la liste est partagée avec markview via `require("markdown_renderer").FILETYPES`.
- Adaptateur : `render_notification`, `render_preview`, `render_hover` appellent `require("render-markdown").render({ buf, win })` ; `attach` est sans effet (le plugin s'attache par `file_types`).
- Le rendu (`anti_conceal`, puces, cases à cocher, titres, blocs de code, `dash`) est réglé par l'utilisateur dans `opts` de la spec ; l'adaptateur n'y ajoute rien. Écart au Brief ratifié le 2026-11-01.
- Floats non demandés (signature help) : rendus avec cette config, contrairement à markview qui les ignore via `hook_render`.

## Gotchas
- **Debounce** (100 ms) : un rendu demandé pendant une mise à jour déjà lancée est ignoré. L'adaptateur rend donc deux fois (immédiat, puis 150 ms plus tard).
- **`WinScrolled`** : l'autocmd du plugin est local au buffer et Neovim ne le déclenche que pour la fenêtre courante. La preview du picker (fenêtre sans focus) ne rendait que les lignes visibles au chargement ; l'adaptateur surveille `WinScrolled` par fenêtre rendue, avec un rendu final 150 ms après le dernier défilement. Test : `tests/markdown_renderer/` (Neovim enfant avec UI — `--headless` seul ne déclenche pas `WinScrolled`).
- **Étiquette de langage des blocs de code** : `position = "right"` s'aligne sur `max(ligne la plus longue, min_width)`, pas sur la largeur de la fenêtre ; `width = "full"` ne règle que le fond.
- **Couleur de l'étiquette** (`code.highlight_language = "RenderMarkdownCodeLanguage"`) : seul `fg` agit. Le plugin empile `RenderMarkdownCodeBorder` après le groupe de langage, et la ligne de la fence en prend le fond.
- `lua/highlights/render-markdown.lua` doit redéfinir `@markup.heading.N.markdown` : il remplace l'intégration base46 en entier.

## Changelog
- 2026-11-01: ajout de render-markdown comme moteur alternatif (spec, adaptateur, highlights transposés de markview).
