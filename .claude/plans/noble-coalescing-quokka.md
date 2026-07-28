# Notes de bookmarks (popup Snacks multi-ligne)

## Contexte

Le plugin `bookmarks` (`plugins/bookmarks/lua/bookmarks/`) a déjà une `annotation` courte
mono-ligne (`<leader>ba`, saisie via `vim.fn.input`, affichée en virtual text dans le gutter).
Le besoin : une **note** distincte, plus longue et multi-ligne (mémo libre), saisie dans un
popup flottant Snacks (`Snacks.win`) et sauvegardée à la fermeture du popup. Sur la ligne, seule
une icône indique la présence d'une note (pas le texte complet en virtual text, contrairement à
l'annotation).

Décisions actées avec l'utilisateur :
- Nouveau champ DB `note` (TEXT), distinct de `annotation`.
- Affichage : icône seule en virtual text si `note` non vide (pas le contenu).
- Popup : `Snacks.win` (buffer flottant multi-ligne), sauvegarde au `on_close`.
- `<leader>bK` crée le bookmark s'il n'existe pas encore sur la ligne (comme `<leader>ba`).

**Hors-périmètre** : pas d'affichage de la note dans le picker Snacks (`snacks_picker.lua`) ni
dans Trouble (`trouble.lua`) — seule l'icône gutter est demandée. Pourra être ajouté dans un
chantier séparé si besoin.

## Étapes

1. **Migration schéma DB** (`plugins/bookmarks/lua/bookmarks/db.lua`)
   - Ajouter `note TEXT` au `CREATE TABLE` (nouvelles installations).
   - Ajouter une migration idempotente dans `M.setup()` : vérifier via
     `PRAGMA table_info(bookmarks)` si la colonne `note` existe, sinon
     `ALTER TABLE bookmarks ADD COLUMN note TEXT` (bases existantes).
   - Étendre `---@field note? string` sur `Ozay.Bookmarks.Record`.

2. **Service** (`plugins/bookmarks/lua/bookmarks/service.lua`)
   - `M.add(bufnr, lnum, opts)` : accepter `opts.note`.
   - Nouvelle fonction `M.set_note(id, note)` (miroir de `set_annotation`, via `db.update`).

3. **Config** (`plugins/bookmarks/lua/bookmarks/config.lua`)
   - Ajouter dans `signs` : `note_icon` (ex. `"󰎚"`) et `note_hl_group` (ex. `"DiagnosticSignHint"`)
     pour l'icône gutter indiquant la présence d'une note.

4. **UI — icône gutter** (`plugins/bookmarks/lua/bookmarks/ui.lua`)
   - Dans `M.render_one` : si `record.note` non vide, ajouter un second chunk au `virt_text`
     existant (ex. `{ " " .. signs.note_icon, signs.note_hl_group }`), en plus du chunk
     annotation/tag déjà géré. `hl_mode = "combine"` déjà en place, réutilisé.
   - `M.update_one` (remove + re-render) fonctionne déjà tel quel pour rafraîchir l'icône après
     édition de note.

5. **Popup Snacks + commande** (nouveau fichier `plugins/bookmarks/lua/bookmarks/note.lua`)
   - Fonction qui : trouve/crée le bookmark sur la ligne courante (comme `BookmarkAnnotate`),
     ouvre un `Snacks.win` avec un buffer scratch (`bo = { buftype = "acwrite"|"nofile",
     filetype = "markdown" }`), pré-rempli avec la note existante (`vim.api.nvim_buf_set_lines`),
     et un `on_close` qui lit le buffer (`nvim_buf_get_lines`), joint en une chaîne, appelle
     `service.set_note(id, text)`, met à jour le record en mémoire et rappelle `ui.update_one`.
   - Titre du popup, dimensions raisonnables (ex. `width = 0.5, height = 0.4, border = "rounded"`),
     cohérent avec le style des autres popups Snacks du repo (`lua/lsp/hover/init.lua`,
     `lua/plugins/snacks/scratch.lua`).
   - Pas de distinction annuler/sauvegarder : toute fermeture (`q`, `<Esc>`, `:q`, `WinClosed`)
     déclenche la sauvegarde, conformément à la demande.

6. **Commande + keymap** (`plugins/bookmarks/lua/bookmarks/init.lua` + spec lazy)
   - Nouvelle commande `BookmarkNote` appelant `require("bookmarks.note")()`.
   - Keymap `<leader>bK` → `:BookmarkNote<CR>`, ajouté dans la spec Lazy
     (`lua/plugins/bookmarks.lua`, à côté des autres `<leader>b*`).

7. **Documentation** (`docs/plugins/bookmarks.md`)
   - Ajouter `note` dans le schéma DB documenté, la ligne keymap `<leader>bK`, et une entrée
     Changelog. Mentionner le choix "icône seule, pas de texte en virt_text" dans Key Behaviors.

## Fichiers touchés

- `plugins/bookmarks/lua/bookmarks/db.lua`
- `plugins/bookmarks/lua/bookmarks/service.lua`
- `plugins/bookmarks/lua/bookmarks/config.lua`
- `plugins/bookmarks/lua/bookmarks/ui.lua`
- `plugins/bookmarks/lua/bookmarks/note.lua` (nouveau)
- `plugins/bookmarks/lua/bookmarks/init.lua`
- `lua/plugins/bookmarks.lua` (spec lazy, keymap)
- `docs/plugins/bookmarks.md`

## Vérification

- Ouvrir Neovim sur ce repo, sur une ligne sans bookmark : `<leader>bK` → popup vide s'ouvre,
  taper du texte multi-ligne, fermer (`:q` ou `<Esc>`) → icône note apparaît dans le gutter.
- Rouvrir `<leader>bK` sur la même ligne → le texte précédent est pré-rempli, modifier, fermer →
  icône toujours présente, contenu mis à jour (vérifier via `sqlite3 <db_path> "SELECT note FROM
  bookmarks;"` ou en rouvrant le popup).
- Vérifier qu'un bookmark existant (créé via `<leader>bb` ou `<leader>ba`) sans note n'affiche pas
  l'icône, et que `<leader>ba` (annotation) continue de fonctionner indépendamment.
- Redémarrer Neovim (nouvelle session `db.setup`) sur une base SQLite déjà existante (créée avant
  ce chantier) pour vérifier que la migration `ALTER TABLE ADD COLUMN` s'exécute sans erreur.
