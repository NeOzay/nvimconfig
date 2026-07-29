---
slug: bookmark-events
titre: Événements custom bookmarks (Create/Update/Deleted) → auto-refresh Trouble
branche: bookmark-events
base: master
statut: terminé
session: 1
plan: /var/home/Benoit/.config/nvim/.claude/plans/fizzy-napping-mochi.md
créé: 2026-07-29
maj: 2026-07-29
---

## Objectif et périmètre

**But** : émettre trois events `User` (`BookmarkCreate`, `BookmarkUpdate`, `BookmarkDeleted`)
à chaque mutation de bookmark, et faire en sorte que la vue Trouble (mode `bookmarks`) se
rafraîchisse automatiquement dessus, sans callback manuel par site d'appel.

**Critères de réussite** :
- `events.emit` déclenché depuis tous les chemins de mutation (`create`, `update`, `remove`,
  `clear_buffer` dans `init.lua` + `on_close` de `note.lua`).
- Mode `bookmarks` de `trouble.lua` déclare `events = {"User BookmarkCreate", ...}` et se
  rafraîchit sans appel manuel à `view:refresh()`.
- Scénarios de vérification manuelle du plan (ajout/annotation/note/suppression/clear avec
  Trouble ouvert) tous OK.

**Hors-périmètre** : le picker Snacks (`snacks_picker.lua`) garde son mécanisme `on_saved`
manuel, inchangé — pas de mécanisme déclaratif équivalent côté Snacks.

## Étapes

- [x] 1. Créer `plugins/bookmarks/lua/bookmarks/events.lua`
- [x] 2. Émettre les events dans `init.lua` (create/update/remove/clear_buffer)
- [x] 3. Émettre `BookmarkUpdate` dans `note.lua` (on_close)
- [x] 4. Ajouter `events` déclaratif dans `trouble.lua` + retirer les `view:refresh()` redondants
- [x] 5. Mettre à jour `docs/plugins/bookmarks.md` (Key Behaviors + changelog)
- [x] 6. Vérification headless dans Neovim (create/update/remove/clear_buffer + events reçus)

## État courant

**Prochaine action** : aucune — chantier clôturé, en attente d'aplatissement sur `master`.
**Vérification faite** : script headless (`nvim --headless -u init.lua`) chargeant la vraie
config, créant/mettant à jour/supprimant des bookmarks sur un fichier de scratch, écoutant les
3 events `User` — les 5 événements attendus (2×Create, 1×Update, 1×Deleted par remove,
1×Deleted par clear_buffer avec `{bufnr=...}`) sont bien reçus avec le bon `data`. Le champ
`events` déclaratif de `trouble.lua` est bien celui attendu par trouble.nvim
(`{"User BookmarkCreate", "User BookmarkUpdate", "User BookmarkDeleted"}`). La base SQLite du
projet a été vérifiée propre après coup (le test a été nettoyé par son propre `clear_buffer`,
`list_for_project()` confirmé vide ensuite).
**Non testé manuellement** : l'auto-refresh visuel de la vue Trouble elle-même (le mécanisme
`view/section.lua:listen()` est un code trouble.nvim upstream, pas remis en cause ici — seule
la présence du champ `events` et l'émission des events ont été vérifiées). Le picker Snacks
(`:BookmarkPick`) n'a pas été testé interactivement (chemin non modifié par ce chantier).
**Notes** : arbre de travail nettoyé via `git stash push -u` avant de démarrer (voir stash
`wip avant implementation-tracker bookmark-events`) — `.gitignore` modifié + submodules
`codediff.nvim`/`lualine.nvim` non suivis, non liés à ce chantier.

## Journal de décisions

- **2026-07-29** — Un module `events.lua` dédié plutôt que dupliquer `nvim_exec_autocmds` à
  chaque site d'appel. *Pourquoi* : 5 sites d'émission (init.lua ×4, note.lua ×1), centraliser
  évite la dérive des noms de pattern. *Rejeté* : inline à chaque site (trop répétitif).
- **2026-07-29** — Consommation via le champ déclaratif `events` de trouble.nvim plutôt qu'un
  `require("trouble").refresh()` manuel après chaque mutation. *Pourquoi* : mécanisme natif déjà
  utilisé par les sources `diagnostics`/`qf` upstream, élimine le besoin de callback ad hoc.
  *Rejeté* : appel manuel `refresh()` dans chaque action (`dd`, `K`, commandes) — redondant une
  fois l'event émis.

### Décisions antérieures

(aucune)
