---
slug: bookmarks
titre: Plugin bookmarks maison — SQLite + Trouble + Snacks
branche: bookmarks
base: master
statut: terminé
session: 2
plan: /home/debian/.config/nvim/.claude/plans/kind-knitting-seal.md
créé: 2026-07-26
maj: 2026-07-27
---

## Objectif et périmètre

**But** : gestion de bookmarks locale au projet, persistée en SQLite (`kkharji/sqlite.lua`),
affichée triée par fichier via Trouble (commande dédiée `:Bookmarks`), avec un picker
Snacks custom (`:BookmarkPick`) en complément. UI en gutter (signe + virtual text via
extmarks), navigation next/prev, toggle rapide, resync du numéro de ligne après édition.

**Critères de réussite** : les 12 points de la section Vérification du plan passent
(chargement sans erreur, DB créée, toggle/annotation/navigation fonctionnels, survie
au déplacement de ligne, isolation par projet, Trouble et Snacks picker opérationnels,
zéro warning EmmyLua).

**Hors-périmètre** : pas de vue multi-projet simultanée, pas de sync/partage entre
machines, pas de backup automatique, pas de suite de tests automatisés.

## Étapes

- [x] 1. `lua/bookmarks/utils.lua` — `unify_path`, `project_root`
- [x] 2. `lua/bookmarks/db.lua` — couche SQLite (schéma, CRUD)
- [x] 3. `lua/bookmarks/config.lua` — config utilisateur, résolution du chemin DB
- [x] 4. `lua/bookmarks/service.lua` — CRUD orienté buffer/projet
- [x] 5. `lua/bookmarks/ui.lua` — extmarks (signe, virtual text, resync, navigation)
- [x] 6. `lua/bookmarks/trouble.lua` + `lua/bookmarks/snacks_picker.lua`
- [x] 7. `lua/bookmarks/init.lua` — setup + commandes utilisateur
- [x] 8. `lua/plugins/bookmarks.lua` + import `init.lua` + `docs/plugins/bookmarks.md`

## État courant

**Prochaine action** : chantier clôturé — voir `done/2026-07-27-bookmarks.md` après aplatissement.
**Vérification** : chargement headless (`require('plugins.bookmarks')`) sans erreur, confirmé le 2026-07-27.
Les 12 points détaillés du plan (`.claude/plans/kind-knitting-seal.md`) restent la référence
pour un test manuel complet en UI si besoin ultérieurement.
**Notes** : ancien brouillon dans `stash@{0}` (non restauré, disponible si besoin).

## Journal de décisions

- **2026-07-26** — Code déplacé de `lua/bookmarks/` + `lua/plugins/bookmarks.lua` vers
  `lua/plugins/bookmarks/` (un seul répertoire, `init.lua` = spec lazy + point d'entrée,
  modules internes requis via `plugins.bookmarks.<module>`). *Pourquoi* : demande
  explicite de l'utilisateur, aligne le plugin sur le pattern déjà utilisé pour
  `plugins/dap/` et `plugins/snacks/` (multi-fichiers colocalisés avec leur spec).
  *Rejeté* : garder un module `lua/bookmarks/` séparé de sa spec `lua/plugins/bookmarks.lua`.
- **2026-07-26** — Code du plugin directement dans `lua/bookmarks/` du repo nvim,
  pas un plugin externe sous `~/projects/nvim-plugins/`. *Pourquoi* : simplicité,
  cohérent avec la tentative précédente, pas de besoin de distribution.
  *Rejeté* : plugin séparé dev-flagged (plus "propre" mais overkill ici).
- **2026-07-26** — Un seul fichier SQLite centralisé (`stdpath('data')`), isolé par
  colonne `project_root`, plutôt qu'un `.db` par projet. *Pourquoi* : plus simple à
  gérer (pas de `.gitignore` par projet, pas de fichier à committer/ignorer).
  *Rejeté* : `.db` dans `.git/` ou `.nvim/` du projet.
- **2026-07-26** — Trouble intégré via une source enregistrée manuellement
  (`require("trouble.sources").register`) et une commande dédiée `:Bookmarks`.
  *Pourquoi* : le dossier interne de trouble.nvim est en lecture seule, et une
  commande dédiée évite d'interférer avec le picker de sources existant.
  *Rejeté* : source visible parmi diagnostics/qflist dans un picker de sources.
