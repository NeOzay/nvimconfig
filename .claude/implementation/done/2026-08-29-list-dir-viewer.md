---
slug: list-dir-viewer
titre: Visualiser les répertoires-listes dans Neovim
branche: list-dir-viewer
base: master
statut: terminé
session: 2
execution: direct
plan: .claude/implementation/done/2026-08-29-list-dir-viewer.plan.md
brief: .claude/implementation/done/2026-08-29-list-dir-viewer.brief.md
audit: .claude/implementation/done/2026-08-29-list-dir-viewer.audit.md
créé: 2026-08-28
maj: 2026-08-29
---

## Objectif et périmètre

Repris du brief (`brief:`), pas réinventé.

**Symptôme** : les répertoires-listes du skill `list-dir` ne se consultent aujourd'hui qu'en CLI,
hors de Neovim.

**But** : « implémenter des façons de visualiser les répertoires-listes dans Neovim » — un picker
des répertoires-listes du workspace, d'où l'on ouvre un picker des éléments de la liste
sélectionnée, et un mapping ouvrant un buffer « nofile » pour cette liste.

**Critères de réussite** :
- une commande ouvre un picker listant les répertoires-listes trouvés sous les chemins configurés
  (cwd par défaut) ; `<CR>` sur l'une d'elles ouvre le picker de ses éléments
- dans le picker d'éléments : preview, `<CR>` ouvre le fichier de l'élément, et un mapping change
  le champ de tri à la volée (l'ordre affiché change en conséquence)
- un mapping du picker d'éléments ouvre un buffer `nofile` par liste, contenant tous les éléments
  concaténés en Markdown, chaque titre étant un lien vers le fichier de l'élément — `gf` (ou
  équivalent) sur ce lien ouvre le fichier
- aucun appel à `show`, `merge` ou à une commande écrivant dans la liste

**Hors-périmètre** :
- « Pour l'instant, seulement la visualisation » — aucune écriture dans les listes : pas de `new`,
  `move`, `derive`, `migrate`, `init` depuis le plugin
- Pas d'ordre manuel persistant des éléments

**Signaux de dérive** :
- si le plugin écrit dans une liste, c'est raté — la visualisation est en lecture seule
- si `show` est appelé, c'est raté : « nvim peut directement obtenir le contenu d'un élément »
- si le nombre d'appels Python croît avec le nombre d'éléments, c'est raté — `list` en rend
  beaucoup en une commande

## Étapes

- [x] 1. Squelette du plugin, spec Lazy et configuration — `plugins/listdir/lua/listdir/{init,config}.lua`, `lua/plugins/listdir.lua`, `init.lua` — vérif: étape 1 du plan
- [x] 2. Lecture du contrat et découverte des listes — `plugins/listdir/lua/listdir/{contract,discover}.lua` — vérif: étape 2 du plan
- [x] 3. Lecture d'un élément et appel de `list` — `plugins/listdir/lua/listdir/{item,cli}.lua` — vérif: étape 3 du plan
- [x] 4. Picker de niveau 1, les répertoires-listes — `plugins/listdir/lua/listdir/picker/lists.lua` — vérif: étape 4 du plan
- [x] 5. Picker de niveau 2, les éléments — `plugins/listdir/lua/listdir/picker/items.lua` — vérif: étape 5 du plan
- [x] 6. Tri à la volée — `plugins/listdir/lua/listdir/picker/items.lua` — vérif: étape 6 du plan
- [x] 7. Génération du document concaténé — `plugins/listdir/lua/listdir/document.lua` — vérif: étape 7 du plan
- [x] 8. Navigation dans le document et branchement au picker — `document.lua`, `picker/items.lua` — vérif: étape 8 du plan
- [x] 9. Documentation — `docs/plugins/listdir.md`, `CLAUDE.md` — vérif: étape 9 du plan

## État courant

**Ajustements post-plan** (2026-08-28, demandés par l'utilisateur) :
1. `id` entre dans le cycle de tri. `contract.sortable` — qui l'excluait au motif qu'il est déjà
   le départage de dernier ressort de `list` — est supprimée ; `M.state` prend `ct.fields` tel quel.
2. Le document n'est plus un buffer `nofile` mais un fichier écrit sous
   `stdpath("cache")/listdir/<liste>.md`, ouvert en lecture seule. **Écart assumé au brief**, qui
   disait « buffer nofile » : le core de Neovim n'attache aucun LSP à un buffer dont `buftype`
   n'est pas vide, ce qui privait le document de marksman. Arbitré par l'utilisateur. Le plugin
   écrit donc un fichier, mais jamais dans un répertoire-liste : le hors-périmètre « aucune
   écriture dans les listes » tient.

**Ajustements post-plan** (2026-08-29, demandés par l'utilisateur) :
3. Le picker des listes affichait une preview vide : Snacks ne rend `item.preview` que sous le
   préréglage `preview = "preview"`, le défaut étant le previewer fichier. Corrigé, et la fiche
   complétée du nombre d'éléments — compté en Lua, sans appel Python.
4. Option `pickers.lists` / `pickers.items` : réglages Snacks fusionnés par-dessus les nôtres à
   l'ouverture de chaque picker (`config.picker`).

**Prochaine action** : aucune — chantier clos. Le contrôle manuel interactif du plan
(contrôle 3) n'a jamais été exécuté ; l'utilisateur a choisi de clore sans, et le constat est au
registre de dette.
**Fixture** : construite dans le scratchpad de session (`.../scratchpad/fixture/demo`), deux
éléments dont `beta` sans `category` — la colonne vide de `list --sort category` est reproduite.
**Vérification** : les neuf commandes headless du plan, plus
`git grep -nE '"(show|merge|new|move|derive|migrate|init)"' plugins/listdir` qui doit ne rien
remonter.
**Dernier audit** : 97dbde6 — RÉSERVES — 2026-08-29. R1, R2, R4 levées ; R9 et R3 traités après
coup (50f0de3) sans troisième audit, sur arbitrage de l'utilisateur. R5, R6, R7, R8 et le scan
bloquant résiduel sont versés au registre de dette.
**Notes** : le plan a été relu par `plan-reviewer` — verdict RÉSERVES, réserves de qualité toutes
corrigées avant présentation (cf. journal). Écart plan/réel sur une seule commande de
vérification : celle de l'étape 8 utilisait `vim.fn.maparg(...).buffer`, qui ne voit les mappings
buffer-local que si le buffer est courant ; remplacée par `vim.api.nvim_buf_get_keymap`. Le
contrôle 2 de la vérification d'ensemble passe (aucune commande d'écriture ni `show`).

## Journal de décisions

- **2026-08-28** — `list` ne fournit que l'ordre et une seule colonne ; les titres et corps sont
  lus en Lua dans les `.md`. *Pourquoi* : un champ absent d'un élément rend une chaîne vide et
  décale toute colonne suivante, rendant le découpage positionnel multi-colonnes faux.
  *Rejeté* : `--sort <champ>,title`.
- **2026-08-28** — appel `list` synchrone et bloquant (`vim.system():wait`, timeout 5 s).
  *Pourquoi* : un seul appel par ouverture ou changement de tri, et le finder synchrone de snacks
  est bien plus simple. *Rejeté* : finder asynchrone, reportable si la latence gêne.
- **2026-08-28** — le document concaténé est un fichier sous `stdpath("cache")`, pas un buffer
  `nofile`. *Pourquoi* : `vim.lsp` n'attache aucun serveur à un `buftype` non vide, donc pas de
  marksman. *Rejeté* : `vim.lsp.start` manuel sur une URI `list-dir://`, que marksman ne sait pas
  rattacher à un workspace.
- **2026-08-28** — chemin du script `list-dir.py` exposé en option `cli`. *Pourquoi* : la skill
  n'est pas garantie sous `~/.claude`, et le coder en dur est une dette déjà constatée ailleurs.
- **2026-08-29** — les chemins des liens du document passent en forme `<…>` de CommonMark.
  *Pourquoi* : une parenthèse dans le chemin tronquait la cible et ouvrait un buffer vide sans
  erreur. *Rejeté* : encodage pourcent, qui aurait demandé un décodage au suivi de lien.
- **2026-08-29** — `discover.find` reçoit une liste `ignore` branchée sur le `skip` de
  `vim.fs.dir`, et le picker de listes ne scanne plus qu'une fois par ouverture (`ld_entries`).
  *Pourquoi* : le scan est synchrone et bloque l'interface. *Rejeté* : finder asynchrone, resté en
  dette.
