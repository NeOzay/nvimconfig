---
slug: bookmarks-cleanup
titre: Nettoyage du plugin bookmarks (répétitions, API publique, bugfix)
branche: bookmarks-cleanup
base: master
statut: terminé
session: 2
plan: /home/debian/.config/nvim/.claude/plans/quiet-conjuring-lampson.md
créé: 2026-07-28
maj: 2026-07-29
---

## Objectif et périmètre

**But** : réduire les répétitions de code du plugin bookmarks (`init.lua` en particulier),
exposer une API publique pour créer/supprimer un bookmark sans passer par les commandes
utilisateur, et corriger un bug de persistance découvert pendant l'analyse.

**Critères de réussite** :
- API publique fonctionnelle sur `require("bookmarks")` — cible finale après la refonte de
  session 2 : `get`, `create`, `get_or_create`, `update`, `remove`, `toggle`, `next`,
  `previous`, `clear_buffer`, `open_note`, `list_for_buffer`, `list_for_project`.
- `db.insert()` persiste le champ `note` dès la création.
- `extmarks_by_buf` est purgé sur `BufDelete`/`BufWipeout`.
- Duplication réduite dans `init.lua`, `db.lua`, `service.lua`, `note.lua` +
  `snacks_picker.lua`/`trouble.lua` sans changement de comportement observable.

**Hors périmètre** : refonte du système de migration DB (`migrate()`), changement de schéma
au-delà du fix `note`, factorisation forcée des labels `ui.lua`/`snacks_picker.lua`/`trouble.lua`
(formats trop différents — virt_text vs texte plat), nouvelle UI.

## Étapes

- [x] 1. `utils.lua` — helper `M.notify(msg, level)` (commit: 8fb2470)
- [x] 2. `db.lua` — fix bug `note` manquant dans l'INSERT + factoriser `ensure_ready()` via
      wrapper `guarded()` + utiliser `utils.notify` (commit: 8fb2470)
- [x] 3. `service.lua` — helper interne `context(bufnr)` (root + file) (commit: 8fb2470)
- [x] 4. `note.lua` — `M.open_for_record(record, opts)` (commit: 8fb2470)
- [x] 5. `snacks_picker.lua` + `trouble.lua` — utiliser `note.open_for_record` (commit: 8fb2470)
- [x] 6. `ui.lua` — autocmd `BufDelete`/`BufWipeout` pour purger `extmarks_by_buf[bufnr]`
      (commit: 8fb2470)
- [x] 7. `init.lua` — helper `cursor_pos()` + `M.toggle` partagé avec la commande + API
      publique (`M.add`, `M.remove`, `M.find`, `M.list_for_buffer`, `M.list_for_project`)
      (commit: 8fb2470)
- [x] 8. Vérification manuelle dans Neovim (cf. section Vérification du plan)
- [x] 9. Refonte manuelle par l'utilisateur : extraction de `commands.lua`, API `create` /
      `get` / `get_or_create` / `update` / `remove(record)`, `utils.find_buf`, `dd` dans
      Trouble (commit: 106ec06)
- [x] 10. Audit de cette refonte + correction des 7 points bloquants (commit: 05fc3b3)

## État courant

**Chantier terminé** — aplati sur `master`.

**Vérification** : deux scripts headless (`nvim --headless -l`, plugin réel + sqlite.lua),
18 assertions vertes — persistance de la note dès l'insert, `virt_text` rafraîchi après
`update`, `update` sans opts, effacement d'annotation par `""`, toggle, `remove(record)`,
buffer scratch, `guarded` sur db fermée, sentinelle `cancelreturn`. Non exerçable en
headless, relu seulement : popup `:BookmarkNote`, picker Snacks, source Trouble.

**Bugs corrigés à l'audit de session 2** : `error(msg, niveau_de_log)` au lieu du niveau de
pile (8 sites) ; `error` dans `db.guarded`, appelé depuis des autocmds ; `M.update` ne
répercutait pas `opts` avant `ui.update_one` ; `pairs(nil)` sur `update` sans opts ;
`:BookmarkAnnotate` créait le bookmark avant le prompt, ne pouvait plus effacer une
annotation et ne rafraîchissait pas l'UI ; `db.insert` mutait le record de l'appelant.

**Laissé de côté** :
- `:BookmarkAdd` a perdu son prompt d'annotation ; le `tag` n'est plus réglable par commande,
  seulement via l'API. Comportement conservé tel quel, `desc` et doc alignés dessus.
- `---@diagnostic disable` global en tête de `snacks_picker.lua` et `trouble.lua`, à
  remplacer par des `disable-next-line` ciblés une fois les lignes fautives vues sous LSP.
- Double `find` de `M.toggle` (une requête DB indexée de trop).

**Notes** : `.gitignore` modifié (ligne `/plugins` commentée) est resté hors de ce chantier —
à traiter séparément.

## Journal de décisions

- **2026-07-29** — Gestion d'erreur en deux régimes : `error(msg, 0)` au `setup()` et sur les
  écritures explicites, `utils.notify` dans `db.guarded`. *Pourquoi* : `guarded` est appelé
  depuis des autocmds, où une exception se traduit par une erreur à chaque `BufEnter`.
  *Rejeté* : `error` partout (choix initial de la session 2), et `notify` partout (décision
  du chantier de 2026-07-27, désormais caduque).
- **2026-07-29** — `Ozay.Bookmarks.NewRecord` (record sans `id`) en entrée de `db.insert`.
  *Pourquoi* : supprime la sentinelle `id = -1` et la mutation `record.id = nil` de
  l'argument de l'appelant. *Rejeté* : `---@field id?` sur `Record`, qui aurait rendu `id`
  optionnel pour tous les consommateurs.
- **2026-07-29** — Toute mutation passe par `bookmarks.update`, jamais par `service.*` depuis
  un module d'UI. *Pourquoi* : `service` n'écrit qu'en DB ; court-circuiter l'API laissait
  l'extmark désynchronisé (bug de `:BookmarkAnnotate`). *Rejeté* : garder les helpers
  `set_annotation`/`set_note`, supprimés.

- **2026-07-28** — Pas de factorisation du label entre `ui.lua`, `snacks_picker.lua` et
  `trouble.lua`. *Pourquoi* : formats de sortie trop différents (virt_text chunks vs texte
  plat), l'indirection coûterait plus qu'elle n'apporterait. *Rejeté* : module
  `bookmarks/display.lua` partagé, envisagé puis abandonné en phase de plan.
- **2026-07-28** — Fix du bug `note` et de la fuite mémoire `extmarks_by_buf` inclus dans ce
  chantier plutôt que traités à part. *Pourquoi* : découverts pendant l'analyse de
  duplication, corrections petites et localisées. *Rejeté* : chantier séparé.

### Décisions antérieures

- API publique d'abord en délégation directe vers `service.lua` (`M.add = service.add`) —
  granularité déjà correcte ; abandonné en session 2 au profit d'une API qui pilote DB + UI
  (`create`/`update`/`remove`), la délégation nue laissant l'extmark désynchronisé.
