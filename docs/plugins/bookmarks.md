# Bookmarks

## Role
Plugin maison de bookmarks locaux au projet, persistés en SQLite, affichés en
gutter (signe + virtual text) et listables via Trouble ou un picker Snacks.

## Files
- Spec lazy + point d'entrée: `lua/plugins/bookmarks/init.lua`
- Modules internes: `lua/plugins/bookmarks/{utils,db,config,service,ui,trouble,snacks_picker}.lua`
  (requis via `plugins.bookmarks.<module>`, pattern identique à `plugins/dap/` et `plugins/snacks/`)
- Import: `{ import = "plugins.bookmarks.init" }` dans `init.lua` (comme `plugins.dap.init`)
- Doc de suivi d'implémentation: `.claude/implementation/bookmarks.md`

## Key Behaviors
- Fond de ligne (`BookmarksLine`) sur les lignes marquées, via `line_hl_group`
  passé à `nvim_buf_set_extmark`. Couleur définie globalement dans
  `lua/base46/config.lua` (`hl_override.BookmarksLine`, mix rouge/noir 85%) —
  pas de fichier `lua/highlights/bookmarks.lua` séparé : le nom du plugin lazy
  ancré (`sqlite.lua`/`trouble.nvim`) ne matcherait pas "bookmarks" dans le
  système de chargement par nom (`base46/loader.lua:load_matching`), donc ce
  highlight ponctuel est déclaré directement en `hl_override` comme les signes
  DAP (`DapBreakpoint`, etc.), qui suivent le même contournement.
- Le `virt_text` de l'annotation utilise `hl_mode = "combine"` : sans ça, le
  fond du label serait opaque (`Normal`) au lieu de laisser transparaître
  `BookmarksLine` en dessous.
- Persistance : un seul fichier SQLite (`stdpath('data')/bookmarks.sqlite.db`,
  configurable via `db_dir`/`db_path`), colonne `project_root` pour isoler les
  bookmarks par projet — `:Bookmarks`/`:BookmarkPick` ne montrent que ceux du
  projet courant (racine git, sinon cwd).
- UI en extmarks (namespace `bookmarks.nvim`), pas de `sign_define`/`sign_place`
  classique : signe + virtual text (annotation ou tag) posés via
  `nvim_buf_set_extmark`.
- Ré-attache automatique au `BufEnter` (idempotent via `vim.b[bufnr].bookmarks_attached`).
- Resync du numéro de ligne au `BufWritePost` : les extmarks suivent les lignes
  déplacées, la DB est mise à jour avec le nouveau `lnum` sans jamais réécrire
  `code_context` (capturé une seule fois, à la création).
- Source Trouble enregistrée manuellement au `setup()` (`require("trouble.sources").register`)
  — le dossier interne de trouble.nvim est en lecture seule, impossible d'y
  placer un fichier `sources/bookmarks.lua` déchargé automatiquement.

## Keymaps
| Touche | Action |
|--------|--------|
| `<leader>bb` | Toggle rapide (ajoute sans annotation / retire) sur la ligne courante |
| `<leader>ba` | Édite l'annotation du bookmark courant (le crée si absent) |
| `<leader>bl` | `:Bookmarks` — liste Trouble triée/groupée par fichier |
| `<leader>bp` | `:BookmarkPick` — picker Snacks (`dd` pour supprimer) |
| `]b` / `[b` | Bookmark suivant / précédent dans le buffer (AZERTY auto via le monkey-patch `vim.keymap.set`) |
| `<leader>bx` | Supprime tous les bookmarks du fichier courant |

## Gotchas
- `:BookmarkAdd [tag]` prend le tag en argument de commande, pas en prompt —
  seule l'annotation est demandée via `vim.fn.input`.
- La modification d'une annotation (`:BookmarkAnnotate` sur un bookmark existant)
  supprime puis recrée l'extmark (`ui.update_one`) : `nvim_buf_set_extmark` sans
  `id` crée toujours un nouvel extmark, jamais une mise à jour en place.
- Toutes les erreurs SQLite passent par `vim.notify(..., ERROR)` + `pcall`,
  jamais de `error()` brut ni de dépendance à un logger externe (contrairement
  à un brouillon précédent abandonné, cf. `.claude/implementation/bookmarks.md`
  → journal de décisions).

## Changelog
- 2026-07-26 : implémentation initiale (SQLite via `kkharji/sqlite.lua`, source
  Trouble dédiée, picker Snacks, extmarks gutter).
