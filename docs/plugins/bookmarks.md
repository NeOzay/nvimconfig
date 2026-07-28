# Bookmarks

## Role
Plugin maison de bookmarks locaux au projet, persistés en SQLite, affichés en
gutter (signe + virtual text) et listables via Trouble ou un picker Snacks.

## Files
- Spec lazy: `lua/plugins/bookmarks.lua` — `dir = vim.fn.stdpath("config") .. "/plugins/bookmarks"`,
  `config = function() require("bookmarks").setup() end`
- Code du plugin (structure standard, hors de `lua/`): `plugins/bookmarks/lua/bookmarks/{init,utils,db,config,service,ui,note,trouble,snacks_picker}.lua`
  (requis via `bookmarks.<module>`, sans préfixe `plugins.` — le `lua/` de `plugins/bookmarks/`
  est ajouté au runtimepath par Lazy via `dir`)
- Import: `{ import = "plugins.bookmarks" }` dans `init.lua`
- Doc de suivi d'implémentation: `.claude/implementation/done/2026-07-27-bookmarks.md`
  (chantier initial, clôturé) ; migration vers ce pattern suivie dans
  `.claude/implementation/plugins-root.md`

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
- **Note multi-ligne** (`note.lua`), distincte de l'annotation courte : `<leader>bK` (ou `K`
  depuis le picker/Trouble) ouvre un popup flottant `Snacks.win`, pré-rempli avec la note
  existante (créé le bookmark au passage si absent). Le texte est sauvegardé en DB (colonne
  `note`) à la fermeture du popup, quel que soit le moyen (`q`, `<Esc>`, `:q`, `WinClosed` —
  `Snacks.win` hooke `on_close` sur l'autocmd `WinClosed`, donc toute fermeture est couverte).
  Une note vide est stockée comme `""`, jamais `nil` : `db.update` boucle sur `pairs(fields)`,
  qui saute silencieusement les clés à valeur `nil`, donc `set_note(id, nil)` ne viderait
  jamais la colonne — `nil` reste réservé à un futur appelant voulant explicitement ne pas
  toucher au champ.
- Icône de note en second `virt_text` (gutter), indépendante de l'annotation — `signs.note_icon`
  / `signs.note_hl_group`. Même icône reprise comme indicateur dans le picker Snacks (format,
  suffixe après le nom de fichier) et dans Trouble (préfixe du texte de l'item).
- `note.lua` accepte `opts.on_saved` (rappelé après la sauvegarde) : le picker Snacks
  (`picker:refresh()`) et Trouble (`view:refresh()`) s'en servent pour se rafraîchir dès la
  fermeture du popup, sans action manuelle de l'utilisateur.
- `note.lua` force `zindex = Snacks.win.zindex()` : sans ça, le popup de note s'ouvrait *sous*
  le picker Snacks (même zindex par défaut que les fenêtres flottantes déjà ouvertes).

## Keymaps
| Touche | Action |
|--------|--------|
| `<leader>bb` | Toggle rapide (ajoute sans annotation / retire) sur la ligne courante |
| `<leader>ba` | Édite l'annotation du bookmark courant (le crée si absent) |
| `<leader>bl` | `:Bookmarks` — liste Trouble triée/groupée par fichier |
| `<leader>bp` | `:BookmarkPick` — picker Snacks (`dd` pour supprimer) |
| `]b` / `[b` | Bookmark suivant / précédent dans le buffer (AZERTY auto via le monkey-patch `vim.keymap.set`) |
| `<leader>bx` | Supprime tous les bookmarks du fichier courant |
| `<leader>bK` | `:BookmarkNote` — popup de note multi-ligne (le crée si absent) |
| `K` (picker Snacks, liste) | Ouvre la note du bookmark sous le curseur |
| `<M-k>` (picker Snacks, input) | Idem, sans quitter le champ de recherche |
| `K` (Trouble, mode bookmarks) | Ouvre la note du bookmark sous le curseur |

## Gotchas
- `:BookmarkAdd [tag]` prend le tag en argument de commande, pas en prompt —
  seule l'annotation est demandée via `vim.fn.input`.
- La modification d'une annotation (`:BookmarkAnnotate` sur un bookmark existant)
  supprime puis recrée l'extmark (`ui.update_one`) : `nvim_buf_set_extmark` sans
  `id` crée toujours un nouvel extmark, jamais une mise à jour en place.
- Toutes les erreurs SQLite passent par `vim.notify(..., ERROR)` + `pcall`,
  jamais de `error()` brut ni de dépendance à un logger externe (contrairement
  à un brouillon précédent abandonné, cf. `.claude/implementation/done/2026-07-27-bookmarks.md`
  → journal de décisions).
- Les touches Alt (`<M-x>`) dans le picker Snacks doivent porter `mode = { "i", "n" }`
  explicitement pour fonctionner pendant la saisie : sans ça, le terminal envoie `ESC` puis
  la lettre pour Alt+lettre, et Neovim quitte l'insertion sur le `ESC` nu (aucun mapping
  insert-mode pour le reconstituer) avant de pouvoir déclencher l'action.
- `<C-k>`/`<C-K>` sont **déjà pris** par le picker Snacks (`list_up`, input et list —
  `snacks/picker/config/defaults.lua:252,306`) : toute action custom sur cette touche est
  silencieusement absorbée par le binding intégré. Vérifier `defaults.lua` avant de choisir
  une touche `<C-x>` custom pour un nouveau picker.
- L'alignement du texte dans une source Trouble ne peut pas reposer sur des espaces ASCII en
  tête de champ `text` : `trouble.nvim` applique `vim.trim()` avant affichage
  (`trouble/format.lua:179`), qui les supprime. Utiliser un espace insécable (`\u{00A0}`,
  invisible au pattern Lua `%s`) pour un padding qui doit survivre en tête de chaîne.

## Changelog
- 2026-07-28 : ajout de la note multi-ligne (`note.lua`, popup `Snacks.win`), distincte de
  l'annotation courte — commande `BookmarkNote`, keymap `<leader>bK`, icône gutter dédiée
  (`signs.note_icon`/`note_hl_group`), ouverture/indicateur depuis le picker Snacks et Trouble
  (`K`/`<M-k>`). Voir `.claude/implementation/done/2026-07-28-bookmarks-note.md` pour le détail
  des bugs rencontrés (vidage de note, collision de touche, alignement Trouble).
- 2026-07-27 : migration vers le pattern "plugin maison versionné dans le repo" —
  code déplacé de `lua/plugins/bookmarks/` vers `plugins/bookmarks/lua/bookmarks/`
  (structure standard de plugin), spec Lazy séparée dans `lua/plugins/bookmarks.lua`
  avec `dir` explicite. Prépare l'intégration future des plugins forkés sous le
  même répertoire `plugins/` (en submodules git, chantier séparé).
- 2026-07-26 : implémentation initiale (SQLite via `kkharji/sqlite.lua`, source
  Trouble dédiée, picker Snacks, extmarks gutter).
