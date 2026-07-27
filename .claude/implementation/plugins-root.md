---
slug: plugins-root
titre: Centraliser les plugins (maison + forks) sous plugins/ à la racine
branche: plugins-root
base: master
statut: en-cours
session: 1
plan: /home/debian/.config/nvim/.claude/plans/expressive-launching-feigenbaum.md
créé: 2026-07-27
maj: 2026-07-27
---

## Objectif et périmètre

**But** : instaurer un pattern unique pour tous les plugins tenus par l'utilisateur (maison
et forks) : un répertoire `plugins/<nom>/` à la racine du repo nvim, structure standard de
plugin Neovim (`lua/<nom>/*.lua`), référencé dans une spec Lazy séparée
(`lua/plugins/<nom>.lua`) via `dir = vim.fn.stdpath("config") .. "/plugins/<nom>"`. Les forks
deviendront des submodules git sous ce même `plugins/` (pour continuer à tirer l'upstream) ;
les plugins maison y sont suivis directement par ce repo.

**Session 1 (cette machine)** : valider le pattern sur un seul plugin — `bookmarks` — en le
migrant de `lua/plugins/bookmarks/` vers `plugins/bookmarks/` + `lua/plugins/bookmarks.lua`.

**Hors-périmètre (session 1)** : migration des forks (lualine, cokeline, harpoon,
snacks.nvim, markview) en submodules — actuellement sur une autre machine, à faire dans une
session ultérieure une fois la branche poussée. Pas de changement à `lazy-conf.lua` →
`dev.path` (bookmarks utilise `dir` explicite, pas `dev = true`). Pas de migration de
`hover-translator`/`docstring-highlight` (déjà en `dir` explicite vers
`~/projects/nvim-plugins/`, hors sujet pour l'instant).

## Étapes

- [x] 1. Déplacer les 7 fichiers feuilles de `lua/plugins/bookmarks/` vers
  `plugins/bookmarks/lua/bookmarks/` (`git mv`), requires internes `plugins.bookmarks.X` →
  `bookmarks.X`
- [x] 2. Scinder `init.lua` : module → `plugins/bookmarks/lua/bookmarks/init.lua`
  (`M.setup`), spec Lazy → nouveau `lua/plugins/bookmarks.lua` (`dir` explicite),
  suppression du dossier `lua/plugins/bookmarks/`
- [x] 3. `init.lua` racine — `{ import = "plugins.bookmarks.init" }` →
  `{ import = "plugins.bookmarks" }`
- [x] 4. Mise à jour `docs/plugins/bookmarks.md` (Files + Changelog)
- [x] 5. Mise à jour `CLAUDE.md` (table des plugins + nouvelle catégorie dans
  *Plugin Locations*)

## État courant

**Prochaine action** : chantier terminé pour la session 1 (bookmarks migré et vérifié).
Reste hors périmètre : migration des forks en submodules sur l'autre machine, une fois la
branche `plugins-root` poussée.
**Vérification** : chargement headless confirmé (`:Bookmarks`/`:BookmarkPick` existent,
aucune erreur au démarrage), `require("bookmarks").setup` résolu via `dir` ajouté au
runtimepath par Lazy.
**Notes** : les forks resteront sur l'autre machine jusqu'à ce que cette branche soit
poussée — reprise prévue dans une session distincte sur cette machine-là.

## Journal de décisions

- **2026-07-27** — Un seul répertoire `plugins/` à la racine pour maison ET forks, plutôt que
  deux racines séparées. *Pourquoi* : uniformité du pattern `dir` pour toutes les specs Lazy,
  quel que soit le mode de suivi (submodule ou direct). *Rejeté* : garder les forks sous
  `~/projects/nvim-plugins/` (hors du repo, pas de suivi Git commun).
- **2026-07-27** — `dir` explicite (`vim.fn.stdpath("config") .. "/plugins/<nom>"`) plutôt que
  `dev = true` + `dev.path` pour les plugins maison. *Pourquoi* : `dev.path` pointe vers
  `~/projects/nvim-plugins/`, hors du repo nvim ; les plugins maison vivent désormais dans le
  repo lui-même, donc un chemin relatif au repo est plus direct. *Rejeté* : déplacer
  `dev.path` vers `plugins/` du repo (impacterait aussi les forks, hors périmètre ici).
- **2026-07-27** — Scinder module et spec Lazy (bookmarks avait les deux dans le même
  `init.lua`). *Pourquoi* : nécessaire pour que `plugins/bookmarks/` ait la structure standard
  d'un plugin distribuable (`lua/bookmarks/init.lua` = module pur), condition pour que
  `require("bookmarks.X")` fonctionne une fois son `lua/` ajouté au runtimepath via `dir`.
  *Rejeté* : garder la spec Lazy dans le module lui-même (aurait cassé la convention
  "plugin autonome" visée).
