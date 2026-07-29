# Bookmarks

## Role
Plugin maison de bookmarks locaux au projet, persistés en SQLite, affichés en
gutter (signe + virtual text) et listables via Trouble ou un picker Snacks.

## Files
- Spec lazy: `lua/plugins/bookmarks.lua` — `dir = vim.fn.stdpath("config") .. "/plugins/bookmarks"`,
  `config = function() require("bookmarks").setup() end`
- Code du plugin (structure standard, hors de `lua/`): `plugins/bookmarks/lua/bookmarks/{init,utils,db,config,service,ui,note,events,trouble,snacks_picker}.lua`
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
  qui saute silencieusement les clés à valeur `nil`, donc `service.update(id, { note = nil })`
  ne viderait jamais la colonne — `nil` reste réservé à un appelant voulant explicitement ne
  pas toucher au champ. Même règle pour l'annotation (`:BookmarkAnnotate` écrit `""`).
- Icône de note en second `virt_text` (gutter), indépendante de l'annotation — `signs.note_icon`
  / `signs.note_hl_group`. Même icône reprise comme indicateur dans le picker Snacks (format,
  suffixe après le nom de fichier) et dans Trouble (préfixe du texte de l'item).
- `note.lua` accepte `opts.on_saved` (rappelé après la sauvegarde) : le picker Snacks
  (`picker:refresh()`) s'en sert pour se rafraîchir dès la fermeture du popup, sans action
  manuelle de l'utilisateur. Trouble n'en a plus besoin depuis les events `User` (voir plus bas).
- **Events `User`** (`events.lua`) : `BookmarkCreate`/`BookmarkUpdate`/`BookmarkDeleted` émis
  par tous les chemins de mutation de l'API publique (`create`/`update`/`remove`/`clear_buffer`
  dans `init.lua`, plus `note.lua` qui écrit la note directement par id sans passer par
  `bookmarks.update`). `data` porte le record concerné (ou `{ bufnr = ... }` pour
  `clear_buffer`, qui supprime en bloc sans record unique). La source Trouble (`trouble.lua`)
  s'y abonne via le champ déclaratif `events` d'un mode (mécanisme natif de trouble.nvim,
  `view/section.lua:listen`, déjà utilisé par les sources `diagnostics`/`qf` upstream) — plus
  besoin de `view:refresh()` manuel dans les actions `K`/`dd`.
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

## API publique
`require("bookmarks")` expose, en plus de `setup()` : `get(bufnr, lnum)`,
`create(bufnr, lnum, opts?)`, `get_or_create`, `update(bufnr, lnum, opts)`,
`remove(record)` **ou** `remove(bufnr, lnum)`, `toggle`, `next`/`previous`,
`clear_buffer`, `open_note`, `list_for_buffer`, `list_for_project`.
Ces fonctions font DB + UI ; `bookmarks.service` (couche DB seule) ne doit pas être appelé
directement depuis un module d'UI, sinon l'extmark n'est pas rafraîchi.
`update()` fusionne `opts` dans le record avant `ui.update_one` et retourne le record fusionné —
passer le record d'origine re-rendrait l'ancien label.

## Gotchas
- `:BookmarkAdd [annotation]` prend l'annotation en argument de commande (plus de prompt).
  Le `tag` n'est plus réglable par une commande — seulement via l'API
  (`bookmarks.create(bufnr, lnum, { tag = ... })`).
- `:BookmarkAnnotate` prompte **avant** de créer le bookmark : annuler par Échap ne doit
  laisser aucun résidu. L'annulation se distingue d'une saisie vide (= effacement explicite)
  par une sentinelle passée en `cancelreturn` — `vim.fn.input` retourne `""` dans les deux
  cas sinon.
- La modification d'une annotation (`:BookmarkAnnotate` sur un bookmark existant)
  supprime puis recrée l'extmark (`ui.update_one`) : `nvim_buf_set_extmark` sans
  `id` crée toujours un nouvel extmark, jamais une mise à jour en place.
- Gestion d'erreur en deux régimes depuis 2026-07-29 (la règle précédente « jamais de
  `error()` brut » ne tient plus) :
  - **`error(msg, 0)`** pour ce qui est irrécupérable et survient au `setup()` ou sur une
    écriture explicite : sqlite absent, schéma/migration en échec, `insert`/`update` en échec.
    Comme `db.setup()` précède `ui.setup_autocmds()` dans `bookmarks.setup()`, un échec de db
    empêche la création des autocmds — pas de cascade d'erreurs ensuite.
  - **`utils.notify(..., ERROR)`** dans `db.guarded` (connexion absente) : ces appels partent
    d'autocmds (`BufEnter` → `ui.attach` → `list_by_file`), où une exception donnerait un
    « Error executing lua callback » à chaque changement de buffer.
  - Le second argument d'`error` est un **niveau de pile**, pas un niveau de log : `error(msg, 0)`
    (message nu). Passer `vim.log.levels.ERROR` (= 4) préfixe le message d'une position de
    frame arbitraire.
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
- 2026-07-29 : events `User` (`BookmarkCreate`/`BookmarkUpdate`/`BookmarkDeleted`,
  `events.lua`) émis à chaque mutation. Source Trouble abonnée via le champ déclaratif
  `events` d'un mode — auto-refresh natif, suppression des `view:refresh()` manuels dans
  les actions `K`/`dd`.
- 2026-07-29 : refonte de l'API publique (`create`/`get`/`get_or_create`/`update`/`remove`),
  extraction des commandes dans `commands.lua`, `dd` dans la source Trouble, `utils.find_buf`
  (suppression depuis un picker sans buffer courant). Corrections d'audit : fusion de `opts`
  avant `ui.update_one`, prompt de `:BookmarkAnnotate` avant création, annotation effaçable,
  `error(msg, 0)`, type `Ozay.Bookmarks.NewRecord` à la place de la sentinelle `id = -1`.
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
