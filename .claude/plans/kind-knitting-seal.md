# Plugin bookmarks.nvim maison — SQLite + Trouble + Snacks

## Contexte

Reprise d'un chantier "gestion de bookmarks" démarré puis abandonné en brouillon
(stash `stash@{0}` : `init.lua` + `lua/bookmarks/{init,cache,config,logger,utils}.lua`,
mis de côté au début de cette session car l'arbre de travail n'était pas propre et
`config.lua` référençait une architecture `bookmarks.domain.service`/`bookmarks.sign`
inexistante, copiée partiellement depuis `LintaoAmons/bookmarks.nvim`).

Objectif : une gestion de bookmarks **locale au projet**, persistée en **SQLite**
(`kkharji/sqlite.lua`, nouvelle dépendance — absente du repo, aucun exemple existant
à imiter), affichée triée par fichier via **Trouble** (commande dédiée, pas une
source parmi d'autres), avec un **picker Snacks** custom en complément. UI en
gutter (signe + virtual text) via extmarks, comme dans le brouillon initial —
c'est la seule partie du brouillon à réellement réutiliser comme idée.

Le stash reste disponible (`git stash list`) si besoin de retrouver l'ancien code ;
il ne sera pas restauré ni supprimé par ce chantier.

## Portée

- Bookmarks stockés dans **un seul fichier SQLite** centralisé
  (`stdpath('data')/bookmarks.sqlite.db`, configurable via `db_dir`/`db_path`),
  isolés par colonne `project_root`. Un projet ne voit que ses propres bookmarks.
- Champs par bookmark : fichier, ligne, annotation texte libre, ligne de code
  capturée (contexte), tag/catégorie court, horodatage de création.
- UI : signe + virtual text (extmarks), navigation next/prev dans le buffer,
  toggle rapide sans annotation, resync du numéro de ligne après édition/`:w`.
- Vue Trouble triée/groupée par fichier via commande dédiée `:Bookmarks`.
- Picker Snacks custom (`:BookmarkPick`) en complément de Trouble.
- Code entièrement dans `lua/bookmarks/` du repo nvim (pas de plugin externe
  sous `~/projects/nvim-plugins/` — décision utilisateur : simplicité, cohérent
  avec la tentative précédente).

## Hors périmètre

- Pas de vue multi-projet (un seul projet actif à la fois, filtré par cwd/git root).
- Pas de synchronisation/partage de bookmarks entre machines.
- Pas de backup automatique (option laissée de côté, contrairement au brouillon
  `config.lua` qui la mentionnait).
- Pas de suite de tests automatisés (validation manuelle uniquement, cf. section Vérification).

## Étapes

1. **`lua/bookmarks/utils.lua`** — `unify_path(path)` (repris/adapté du brouillon,
   normalisation de chemin cross-OS) + `project_root()` (via `vim.fs.root(0, ".git")`,
   fallback `vim.fn.getcwd()`). Module pur, sans dépendance interne.

2. **`lua/bookmarks/db.lua`** — couche SQLite pure via `require("sqlite.db")`
   (API OOP `sqlite:open()` / `tbl:insert/select/update/delete`). Table `bookmarks` :
   `id` (PK autoincrement), `project_root`, `file`, `lnum`, `annotation`,
   `code_context`, `tag`, `created_at` (epoch), tous `text`/`integer` selon le cas.
   Index sur `(project_root, file)` (pattern d'accès dominant). API :
   `setup(db_path)`, `insert(record)`, `list_by_project(root)`, `list_by_file(root, file)`,
   `update(id, fields)`, `delete(id)`, `delete_by_file(root, file)`, `close()`.
   Erreurs via `pcall` + `vim.notify(..., ERROR)`, pas de `error()` brut ni de
   logger externe (contrairement au `logger.lua` fragile du brouillon).

3. **`lua/bookmarks/config.lua`** — `defaults` simple et cohérent (PAS de `backup`
   ni de références à des modules inexistants comme le brouillon) : `db_dir`,
   `db_path`, `signs = {icon, hl_group, annotation_hl_group}`, `default_tag`.
   `setup(opts)` fusionne via `vim.tbl_deep_extend`. `resolved_db_path()` calcule
   le chemin final (`db_path` > `db_dir/bookmarks.sqlite.db` > `stdpath('data')/...`).

4. **`lua/bookmarks/service.lua`** — CRUD orienté buffer/projet, pont entre `db.lua`
   et l'UI (aucun extmark ici) : `add(bufnr, lnum, opts)` (capture `code_context`
   via `nvim_buf_get_lines`, `file`/`project_root` via `utils`), `remove(id)`,
   `find(bufnr, lnum)`, `list_for_buffer(bufnr)`, `list_for_project()`,
   `set_annotation(id, annotation, tag)`. Inclut le garde `skip_buf` (buffer sans
   nom / buftype non vide → no-op), repris du brouillon.

5. **`lua/bookmarks/ui.lua`** — extmarks (namespace unique `bookmarks.nvim`),
   pattern du brouillon adapté à `service.lua` au lieu du cache JSON :
   `setup_autocmds()` (une fois, augroup global), `attach(bufnr)` (BufEnter,
   garde `vim.b[bufnr].bookmarks_attached`), `render_one(bufnr, record)`
   (`sign_text`/`sign_hl_group`/`virt_text` via config), resync `lnum` au
   `BufWritePost` (`nvim_buf_get_extmark_by_id`, met à jour la DB si déplacé —
   sans réécraser `code_context` original), `next(bufnr)`/`previous(bufnr)`,
   `clear_buffer(bufnr)`.

6. **`lua/bookmarks/trouble.lua`** + **`lua/bookmarks/snacks_picker.lua`** —
   - `trouble.lua` : source Trouble enregistrée manuellement (le dossier interne
     de trouble.nvim est en lecture seule, pas question d'y écrire) via
     `require("trouble.sources").register("bookmarks", M)` dans `M.register()`
     (idempotent). `M.config.modes.bookmarks = {desc, source="bookmarks.bookmarks",
     groups={{"filename", format="{file_icon} {filename} {count}"}}, sort={"filename","pos"},
     format="{text} {pos}"}`. `M.get.bookmarks(cb)` construit les `trouble.Item`
     via `require("trouble.item").new({...})` à partir de `service.list_for_project()`,
     préfixe `text` par `"[tag] "` si tag renseigné (pas de formatter custom trouble).
   - `snacks_picker.lua` : calqué sur `lua/plugins/snacks/picker/sources/harpoon.lua`
     (`Snacks.picker.pick({title, finder, format, confirm, actions, win})`),
     action `dd` pour supprimer + `picker:refresh()`.

7. **`lua/bookmarks/init.lua`** — point d'entrée public (`require("bookmarks")`) :
   `setup(opts)` enchaîne `config.setup` → `db.setup(resolved_db_path)` →
   `ui.setup_autocmds()` → `trouble.register()` → création des commandes.
   Commandes : `:Bookmarks` (ouvre Trouble mode bookmarks), `:BookmarkToggle`,
   `:BookmarkAdd [tag]` (prompt annotation), `:BookmarkAnnotate`, `:BookmarkNext`,
   `:BookmarkPrev`, `:BookmarkClear`, `:BookmarkPick` (ouvre le picker Snacks).

8. **`lua/plugins/bookmarks.lua`** + import + doc :
   - Spec lazy ancré sur la dépendance externe réelle (pas de nom de plugin
     fictif) : `{"kkharji/sqlite.lua", dependencies = {"folke/trouble.nvim"},
     lazy = false, config = function() require("bookmarks").setup({}) end,
     keys = gen_keymaps()}` — `lua/bookmarks/` est déjà sur le runtimepath
     (`stdpath('config')/lua`), aucune déclaration `dir=` nécessaire.
   - Keymaps par défaut (`gen_keymaps()`, pattern `lua/plugins/harpoon.lua`) :
     `<leader>bb` toggle, `<leader>ba` annotate, `<leader>bl` Trouble,
     `<leader>bp` Snacks picker, `]b`/`[b` next/prev (AZERTY auto via le
     monkey-patch de `vim.keymap.set`), `<leader>bx` clear.
   - Import dans `/home/debian/.config/nvim/init.lua` : `{ import = "plugins.bookmarks" }`
     entre `plugins.blink-cmp` et `plugins.cokeline` (ordre alphabétique existant).
   - `docs/plugins/bookmarks.md` suivant le template (Role/Files/Key
     Behaviors/Keymaps/Gotchas/Changelog, imiter `docs/plugins/harpoon.md`).
     Gotchas à noter : resync lnum différé au `BufWritePost`, un seul fichier
     SQLite partagé entre projets filtré par `project_root`, la source Trouble
     doit être enregistrée avant le premier `:Bookmarks` (fait dans `setup()`).

## Fichiers créés/modifiés

- `lua/bookmarks/{utils,db,config,service,ui,trouble,snacks_picker,init}.lua` (nouveaux)
- `lua/plugins/bookmarks.lua` (nouveau)
- `init.lua` (modif : ajout d'un import)
- `docs/plugins/bookmarks.md` (nouveau)

## Vérification (manuelle)

1. Chargement : redémarrer Neovim → pas d'erreur, `:messages` propre.
2. DB : `ls ~/.local/share/nvim/bookmarks.sqlite.db` créée après le premier `<leader>bb`.
3. Toggle : `<leader>bb` pose/retire le signe dans le gutter.
4. Annotation : `<leader>ba` → prompt → virtual text visible.
5. Navigation : 3 bookmarks, `]b`/`[b` sautent dans l'ordre.
6. Survie au déplacement : bookmark ligne 10, insérer 5 lignes au-dessus, `:w`
   → signe suit la ligne 14, `code_context` original inchangé en DB
   (`sqlite3 ~/.local/share/nvim/bookmarks.sqlite.db "select * from bookmarks;"`).
7. Ré-attache : fermer/rouvrir le buffer → signes réapparaissent sans doublon.
8. Isolation projet : second repo → ses bookmarks n'apparaissent pas dans le premier.
9. `:Bookmarks` (Trouble) : liste groupée par fichier, `<CR>` saute au bon endroit.
10. `:BookmarkPick` (Snacks) : liste similaire, `dd` supprime + refresh sans fermer.
11. `:BookmarkClear` : vide tous les bookmarks du fichier courant (signes + DB).
12. Diagnostics LSP/`emmylua_check` : zéro warning sur les nouvelles annotations
    `---@class Ozay.Bookmarks.*`, `@field`, `@param`, `@return`.
