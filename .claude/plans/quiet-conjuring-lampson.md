# Nettoyage du plugin bookmarks : réduction des répétitions, API publique, bugfix

## Contexte

En observant `plugins/bookmarks/lua/bookmarks/`, l'utilisateur a repéré beaucoup de code
répétitif — en particulier dans `init.lua` — et l'absence d'une API publique pour
créer/supprimer un bookmark autrement que via les commandes utilisateur (`:BookmarkToggle`,
`:BookmarkAdd`, etc.). Une lecture complète des 9 fichiers du plugin (~900 lignes) a permis
d'identifier les duplications précises, un bug de persistance (`note` perdu à la création),
et une petite fuite mémoire (`extmarks_by_buf` jamais nettoyé à la fermeture d'un buffer).
Ce chantier régule ces trois axes en une passe cohérente.

## Périmètre

**Inclus** :
1. API publique dans `init.lua` : exposer `M.add`, `M.remove`, `M.find`, `M.toggle`,
   `M.list_for_buffer`, `M.list_for_project` en délégation directe vers `service.lua`
   (pas de couche d'abstraction supplémentaire — décision utilisateur).
2. Réduction des répétitions dans `init.lua` (helper curseur), `db.lua` (notify + garde
   connexion), `service.lua` (contexte projet/fichier), et le trio
   `ui.lua` / `snacks_picker.lua` / `trouble.lua` (construction du label, ouverture de note).
3. Fix bug : `db.insert()` ne persiste pas le champ `note`.
4. Fix fuite mémoire : `extmarks_by_buf[bufnr]` nettoyé sur `BufDelete`/`BufWipeout`.

**Hors périmètre** : refonte du système de migration DB (`migrate()`), changement de schéma
au-delà du fix `note`, nouvelle UI.

## Changements par fichier

### `lua/bookmarks/utils.lua`
Ajouter un helper de notification centralisé, réutilisé partout à la place de l'appel
`vim.notify(..., level, {title="bookmarks.nvim"})` répété (5× dans `db.lua`, 4× dans
`init.lua`, 1× dans `note.lua`) :
```lua
---@param msg string
---@param level integer
function M.notify(msg, level)
  vim.notify(msg, level, { title = "bookmarks.nvim" })
end
```

### `lua/bookmarks/db.lua`
- Remplacer les appels `vim.notify(...)` par `utils.notify(...)`.
- Fixer `M.insert()` : ajouter `note` dans la liste de colonnes et de valeurs de l'INSERT
  (actuellement absent — `service.add(bufnr, lnum, {note=...})` perd silencieusement la note
  si elle est fournie dès la création).
- Réduire la répétition du garde `ensure_ready()` : factoriser via un petit wrapper
  `local function guarded(default, fn) ... end` appelé par chaque fonction publique
  (`insert`, `list_by_project`, `list_by_file`, `update`, `delete`, `delete_by_file`), qui
  vérifie `conn` puis exécute `fn`, sinon retourne `default`. Garde le comportement actuel à
  l'identique (mêmes messages d'erreur, mêmes valeurs de retour par défaut).

### `lua/bookmarks/service.lua`
- Ajouter un helper interne `context(bufnr)` retournant `{root, file}` (regroupe
  `utils.project_root()` + `buf_file(bufnr)`), utilisé dans `add`, `find`,
  `list_for_buffer`, `clear_buffer` au lieu de recalculer les deux séparément à chaque fois.
- Garder les gardes `skip_buf` individuels (retours différents selon la fonction : `nil`,
  `{}`, rien — factoriser plus loin ajouterait de la complexité pour peu de gain).

### `lua/bookmarks/note.lua`
Ajouter `M.open_for_record(record, opts)` qui fait `vim.fn.bufadd(record.file)` +
`vim.fn.bufload(bufnr)` + `M.open(bufnr, record.lnum, opts)` — remplace le code dupliqué à
l'identique dans `snacks_picker.lua` (action `bookmark_note`) et `trouble.lua` (action `K`).

### `lua/bookmarks/snacks_picker.lua` et `lua/bookmarks/trouble.lua`
Remplacer le bloc `bufadd/bufload/note.open` par un appel à `note.open_for_record(item.bookmark, {...})`.

### `lua/bookmarks/ui.lua`
- Dans `setup_autocmds()`, ajouter un autocmd `BufDelete`/`BufWipeout` qui fait
  `extmarks_by_buf[bufnr] = nil` (le buffer est détruit, les extmarks avec lui — seule la
  table de suivi Lua doit être purgée).
- Pas de changement sur la construction du label dans `render_one` (elle produit des
  `virt_text` chunks, format différent de `snacks_picker`/`trouble` qui produisent du texte
  plat — une factorisation forcée entre les trois ajouterait une indirection sans réel gain ;
  laissé tel quel après réflexion, contrairement à l'idée initiale).

### `lua/bookmarks/init.lua`
- Ajouter un helper `local function cursor_pos() return vim.api.nvim_get_current_buf(),
  vim.api.nvim_win_get_cursor(0)[1] end`, utilisé dans `BookmarkToggle`, `BookmarkAdd`,
  `BookmarkAnnotate`, `BookmarkNote` à la place de la paire dupliquée
  `nvim_get_current_buf()` / `nvim_win_get_cursor(0)[1]`.
- Exposer l'API publique sur `M` (déléguée à `service`) :
  ```lua
  M.add = service.add
  M.remove = service.remove
  M.find = service.find
  M.list_for_buffer = service.list_for_buffer
  M.list_for_project = service.list_for_project
  ```
  Ajouter un `M.toggle(bufnr, lnum)` qui reprend la logique déjà présente dans la commande
  `BookmarkToggle` (find → remove+ui.remove_one ou add+ui.render_one), pour que la commande
  et l'API publique partagent le même code (la commande appelle `M.toggle` au lieu de
  dupliquer la logique).

## Vérification

Pas de suite de tests automatisée pour ce plugin (config Neovim personnelle). Validation
manuelle dans Neovim :
1. Ouvrir un fichier, `:BookmarkToggle` → sign + entrée DB créée ; re-toggle → supprimé.
2. `:BookmarkAdd note-test` avec annotation → vérifier persistance après `:e` (reload buffer).
3. `require("bookmarks").add(bufnr, lnum, {note="test"})` en `:lua` → vérifier en DB (ou via
   `:BookmarkPick`) que le champ `note` est bien présent dès la création (test du fix bug).
4. `:BookmarkNote` sur une ligne, écrire du texte, fermer le popup → rouvrir, vérifier que le
   texte est conservé.
5. `:BookmarkPick` et `:Bookmarks` (Trouble) → action suppression et note sur un item,
   vérifier que ça fonctionne toujours après le passage par `note.open_for_record`.
6. Ouvrir plusieurs buffers avec bookmarks, fermer certains (`:bd`) → pas de vérification
   visuelle directe possible pour la fuite mémoire corrigée, mais s'assurer qu'aucune erreur
   n'apparaît sur `BufDelete`.
7. `luacheck`/`emmylua_check` si disponible sur le repo, sinon simple relecture des
   diagnostics LSP (`emmylua_ls`) dans les fichiers modifiés.
