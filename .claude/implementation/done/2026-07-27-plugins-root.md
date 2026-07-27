---
slug: plugins-root
titre: Centraliser les plugins (maison + forks) sous plugins/ à la racine
branche: plugins-root
base: master
statut: terminé
session: 2
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

### Session 2 — migration du reste (9 plugins de `~/projects/nvim-plugins/`)

- [x] 6. Assainir les dépôts sources : jeter les changements de mode 644→755 (32 fichiers
  dans `harpoon` et `nvim-cokeline`)
- [x] 7. `markview.nvim` : committer les 2 fichiers modifiés + pousser vers `origin/main`
  (1 commit d'avance) — prérequis pour un SHA de submodule joignable
- [x] 8. Ajouter les forks en submodules sous `plugins/` (déplacer le dépôt existant puis
  `git submodule add <url> plugins/<nom>` pour préserver l'état local) : `snacks.nvim`,
  `lualine.nvim`, `codediff.nvim`, `harpoon`, `nvim-cokeline`, `markview.nvim` — **6 au
  final**, `statuscol.nvim` écarté après inspection (fork sans commit propre)
- [x] 9. Migrer `hover-translator` et `docstring-highlight.nvim` en suivi direct (dépôts sans
  commit ni remote) : supprimer leur `.git`, déplacer sous `plugins/`
- [x] 10. Basculer les specs Lazy : `dev = true` → `dir = vim.fn.stdpath("config") ..
  "/plugins/<nom>"` (7 forks) et corriger les `dir` de `hover-translator` /
  `docstring-highlight`
- [x] 11. Retirer le bloc `dev` de `lua/lazy-conf.lua` (plus aucun consommateur)
- [x] 12. Docs : `CLAUDE.md` (*Plugin Locations*, table) + `docs/plugins/*.md` concernés
- [x] 13. Vérification : chargement headless sans erreur, les 9 plugins actifs

## État courant

**Terminé.** Les 9 plugins tenus par l'utilisateur vivent sous `plugins/` : 6 submodules git
(`snacks.nvim`, `lualine.nvim`, `codediff.nvim`, `harpoon`, `nvim-cokeline`, `markview.nvim`)
et 3 en suivi direct (`bookmarks`, `hover-translator`, `docstring-highlight.nvim`).
**Vérification** : chargement headless OK — aucun `dir` manquant, `require` résolu pour les 9,
`git submodule status` liste 6 entrées toutes sur un SHA poussé.
**Notes** : `~/projects/nvim-plugins/` est vide. Après clone :
`git submodule update --init --recursive`.

## Journal de décisions

- **2026-07-27** — Un seul répertoire `plugins/` à la racine pour maison ET forks — uniformité
  du pattern `dir` pour toutes les specs Lazy, quel que soit le mode de suivi.
- **2026-07-27** — `dir` explicite plutôt que `dev = true` + `dev.path`, bloc `dev` supprimé de
  `lazy-conf.lua` — un seul mécanisme, chemin relatif au repo.
- **2026-07-27** — Module et spec Lazy scindés (`plugins/<nom>/lua/<nom>/init.lua` = module
  pur) — condition pour que `require("<nom>.X")` marche via le `dir` ajouté au runtimepath.
- **2026-07-27** — Forks migrés par déplacement du dépôt existant puis `git submodule add`
  plutôt que clone frais — préserve branches, remotes et travail local.
- **2026-07-27** — `hover-translator` et `docstring-highlight.nvim` en suivi direct, pas en
  submodule — dépôts sans commit ni remote, rien à suivre en amont.
- **2026-07-27** — `statuscol` reste sur l'upstream `luukvbaal`, fork écarté — son HEAD est un
  ancêtre strict de la version installée (aucun commit propre, 4 commits de retard).
