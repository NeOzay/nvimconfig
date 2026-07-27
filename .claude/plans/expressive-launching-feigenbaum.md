# Migration de `bookmarks` vers le pattern "plugin maison versionné dans le repo"

## Contexte

On veut à terme suivre aussi les plugins forkés directement dans ce repo (submodules git,
pour continuer à tirer l'upstream), en plus des plugins maison déjà écrits ici. Les deux
catégories vivraient sous un même répertoire `plugins/` à la racine du repo nvim, avec la
structure standard d'un plugin Neovim autonome (`lua/<nom>/*.lua`), référencé dans une spec
Lazy via `dir` plutôt qu'embarqué dans `lua/plugins/<nom>/`.

Les plugins forkés (lualine, cokeline, harpoon, snacks.nvim, markview) restent pour l'instant
sur l'autre machine — cette partie sera traitée dans une session ultérieure une fois la
branche poussée. **Ce chantier ne migre que `bookmarks`**, pour poser et valider le pattern
avant de l'appliquer aux forks.

## Périmètre

**Fait ici** : migrer `bookmarks` de `lua/plugins/bookmarks/` vers `plugins/bookmarks/` (racine)
+ une spec Lazy `lua/plugins/bookmarks.lua`. Mettre à jour la doc.

**Hors périmètre** : forks en submodules (autre machine, chantier futur), changement de
`lazy-conf.lua` → `dev.path` (pas nécessaire pour bookmarks, qui utilise `dir` explicite et
non `dev = true`), migration de `hover-translator`/`docstring-highlight` (déjà en `dir`
explicite, pas concernés par ce pattern précis pour l'instant).

## État actuel (rappel)

`lua/plugins/bookmarks/init.lua` conflate à la fois le **module** (requires internes,
`setup()`, `create_commands()`) et la **spec Lazy** (`dir = "~"` — placeholder mort,
`dependencies`, `lazy = false`, `config = setup`, `cmd`, `keys`). Les modules internes sont
requis en `plugins.bookmarks.<module>`. Importé depuis `init.lua` racine via
`{ import = "plugins.bookmarks.init" }` (ligne 85).

## Structure cible

```
plugins/bookmarks/lua/bookmarks/
  config.lua
  db.lua
  service.lua
  ui.lua
  snacks_picker.lua
  trouble.lua
  utils.lua
  init.lua          -- module (plus la spec Lazy) : setup(), create_commands()

lua/plugins/bookmarks.lua   -- spec Lazy (remplace le dossier lua/plugins/bookmarks/)
```

`plugins/bookmarks/` a la structure standard d'un plugin Neovim (`lua/bookmarks/...`), ce qui
permet `require("bookmarks.<module>")` sans préfixe `plugins.` une fois son `lua/` ajouté au
runtimepath par lazy.nvim via `dir`.

## Étapes d'implémentation

1. **Créer `plugins/bookmarks/lua/bookmarks/`** et y déplacer (`git mv`) les 7 fichiers
   feuilles depuis `lua/plugins/bookmarks/` : `config.lua`, `db.lua`, `service.lua`, `ui.lua`,
   `snacks_picker.lua`, `trouble.lua`, `utils.lua`. Dans chacun, remplacer les requires
   internes `require("plugins.bookmarks.X")` → `require("bookmarks.X")` (fichiers concernés :
   `init.lua` — traité à part ci-dessous —, `service.lua`, `snacks_picker.lua`, `trouble.lua`,
   `ui.lua`).

2. **Scinder `lua/plugins/bookmarks/init.lua`** :
   - Déplacer vers `plugins/bookmarks/lua/bookmarks/init.lua` : les requires internes (mis à
     jour en `bookmarks.X`), `create_commands()`, `setup()`. Exposer `M.setup = setup` et
     `return M` (au lieu de retourner une spec Lazy).
   - Écrire `lua/plugins/bookmarks.lua` (nouveau fichier, remplace le dossier) avec la spec
     Lazy : garder `gen_keymaps()` tel quel (pur, pas de require du module — sûr de rester
     dans la spec), et :
     ```lua
     ---@type LazySpec
     return {
     	dir = vim.fn.stdpath("config") .. "/plugins/bookmarks",
     	dependencies = { "neozay/trouble.nvim", "kkharji/sqlite.lua" },
     	lazy = false,
     	config = function() require("bookmarks").setup() end,
     	cmd = { "Bookmarks", "BookmarkToggle", "BookmarkAdd", "BookmarkAnnotate",
     		"BookmarkNext", "BookmarkPrev", "BookmarkClear", "BookmarkPick" },
     	keys = gen_keymaps(),
     }
     ```
   - Supprimer le dossier `lua/plugins/bookmarks/` (vide après les déplacements).

3. **`init.lua` racine (L85)** : remplacer `{ import = "plugins.bookmarks.init" }` par
   `{ import = "plugins.bookmarks" }` (cohérent avec `hover-translator`/`docstring-highlight`,
   déjà en fichier unique).

4. **`docs/plugins/bookmarks.md`** : mettre à jour la section *Files* pour refléter
   `plugins/bookmarks/lua/bookmarks/*.lua` (code) + `lua/plugins/bookmarks.lua` (spec),
   requires en `bookmarks.<module>`. Ajouter une entrée *Changelog* (2026-07-27, migration
   vers le pattern "plugin maison versionné" avec `dir` explicite).

5. **`CLAUDE.md`** :
   - Table des plugins (racine) : ligne `bookmarks` → config file `plugins/bookmarks.lua`
     (spec) + `plugins/bookmarks/` (code, racine du repo).
   - Section *Plugin Locations* : ajouter une 3ᵉ catégorie, ex. :
     `**Plugins maison versionnés dans le repo** : plugins/<nom>/ à la racine (structure
     standard lua/<nom>/*.lua), spec Lazy dans lua/plugins/<nom>.lua avec
     dir = vim.fn.stdpath("config") .. "/plugins/<nom>". Suivi directement par ce repo.
     Ex. : bookmarks. (Les forks suivront plus tard le même répertoire plugins/, en
     submodules git — chantier séparé.)`

## Vérification

```bash
nvim --headless -c "lua require('bookmarks')" -c "qa"          # charge le module directement
nvim --headless -c "lua require('lazy').setup(...)" ...          # ou simplement ouvrir nvim normalement
```
- Ouvrir Neovim normalement : `:Lazy` ne doit montrer aucune erreur sur le plugin `bookmarks`.
- `:BookmarkToggle`, `:Bookmarks`, `:BookmarkPick` fonctionnent comme avant.
- `emmylua_check` (ou juste ouvrir un fichier sous `plugins/bookmarks/lua/bookmarks/` et
  vérifier l'absence de warning EmmyLua) — le workspace n'a pas de `.emmyrc.json` restrictif,
  donc `plugins/` à la racine doit être indexé sans config supplémentaire ; à confirmer en
  ouvrant un des fichiers déplacés.
- `git status` : le dossier `lua/plugins/bookmarks/` ne doit plus exister ; `git mv` doit avoir
  préservé l'historique (`git log --follow` sur un fichier déplacé).
