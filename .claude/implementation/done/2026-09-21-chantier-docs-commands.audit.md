---
slug: chantier-docs-commands
---

## 2026-09-21 — clôture — `7783868`

**Verdict** : RÉSERVES

Brief présent et lu ; suivi, plan (`.claude/plans/stateful-knitting-valley.md`) et diff
`master...chantier-docs-commands` lus en entier (9 fichiers, +388 −74).

### Vérifications exécutées

- Étape 1 — `nvim --headless -c 'lua local i=require("listdir.item"); … print("OK")' -c q` (commande
  exacte du plan) → `OK`, code retour 0.
- Étape 2 — le script de l'auteur (`chantier-check.sh`) ne contrôle que le nom de buffer. J'ai écrit
  et lancé un script à moi (dépôt temporaire, config complète chargée, cwd hors de la config nvim,
  `vim.notify` intercepté pour relever le message). Sortie réelle :
  - `demo :Suivi` → buffer `…/.claude/implementation/demo.md`, aucun message
  - `demo :Brief` → buffer `…/demo.brief.md`, aucun message
  - `demo :Plan` (`plan = "<À REMPLIR>"`) → buffer vide, ERROR « le suivi ne renseigne pas « plan » »
  - `demo :Audit` (fichier absent) → buffer vide, ERROR « audit introuvable : .claude/implementation/demo.audit.md »
  - `demo :Brief` depuis un sous-répertoire `sub/` → buffer `…/demo.brief.md`
  - `master :Suivi`, `master :Audit` → buffer vide, WARN « aucun chantier en cours sur la branche « master » »
  - `autre :Suivi`, `autre :Brief` (un leurre `branche = "autre"` dans `done/`) → buffer vide, WARN « aucun chantier… « autre » » : `done/` bien ignoré
  - HEAD détachée `:Suivi` → buffer vide, WARN « pas de branche courante (HEAD détachée ?) »
  - `spec :Plan` (chemin `.claude/plans/a b%c.md`, espace et `%`) → buffer `…/a b%c.md` : échappement correct
  - `spec :Brief` (`brief = ""`) → buffer vide, ERROR « le suivi ne renseigne pas « brief » »
  - dépôt sans `.claude/implementation/` → WARN « aucun chantier… », pas d'erreur Lua
  - cwd hors dépôt git → WARN « pas de dépôt git dans le cwd »
- Dans ce dépôt, sur `chantier-docs-commands` : `:Suivi`, `:Brief`, `:Plan` → ouvrent respectivement
  le suivi, le brief et `.claude/plans/stateful-knitting-valley.md` ; `:Audit` → ERROR « le suivi ne
  renseigne pas « audit » » (le champ `audit` n'est pas encore au frontmatter ; le tracker l'y
  inscrit au retour du premier audit, cf. `references/audit.md`).
- Étape 3 — `git status --short` → vide (tout est commité) ; `git diff --name-only master...` ne
  porte que les fichiers de la section Fichiers du plan plus les documents du chantier.
  `grep -n frontmatter docs/plugins/listdir.md CLAUDE.md` → 3 lignes (listdir.md:17, :138 ; CLAUDE.md:43).
- `stylua --check` (binaire mason) sur `lua/chantier.lua lua/frontmatter.lua lua/cmd.lua
  plugins/listdir/lua/listdir/item.lua` → code retour 0.
- Diagnostics `emmylua_ls` (LSP de la config, relevés en headless) : `lua/chantier.lua`,
  `plugins/listdir/lua/listdir/item.lua`, `picker/items.lua`, `document.lua` → aucun.
  `lua/frontmatter.lua:52` → `param-type-mismatch` (`unquote(value)`, `string?`) : **préexistant**,
  même ligne 52 dans `item.lua` sur l'arbre `master` extrait — déplacé, pas introduit.
  `lua/cmd.lua:26,30` (`hide` indéfini) : lignes antérieures au chantier.
- Signal de dérive — `git diff master...chantier-docs-commands -- lua plugins | grep -E '^\+.*(ui\.select|picker|Snacks|writefile|io\.open)'` → aucune ligne.
- `ruff` / `basedpyright` : sans objet, aucun fichier Python dans le diff.
- `:ListDir` interactif (picker Snacks et titres affichés) → NON EXÉCUTÉE : exige une session
  Neovim interactive ; seule la façade `item.read`/`item.title` est vérifiée (étape 1).

### Conformité à l'intention

- Critère « `:Suivi`, `:Brief`, `:Plan`, `:Audit` ouvrent le document désigné par le suivi dont
  `branche` = branche courante » : atteint, vérifié (dépôt temporaire et ce dépôt). `:Audit` ouvrant
  un fichier existant est couvert par le même chemin de code que `:Brief`/`:Plan` ; il n'a pas été
  exercé avec un audit présent, faute de champ `audit` dans les suivis de test existants — couvert
  indirectement.
- Critère « document absent ou champ vide → erreur, aucun buffer » : atteint, vérifié (champ vide,
  marqueur `<À REMPLIR>`, fichier absent).
- Critère « `master` ou branche sans suivi → message, rien d'ouvert » : atteint, vérifié.
- Critère « fonctionne depuis un autre dépôt, résolu depuis le cwd » : atteint, vérifié (dépôt
  temporaire, y compris depuis un sous-répertoire).
- Contrainte « parseur de `listdir.item` extrait dans un module commun utilisé par les deux » :
  respectée — `lua/frontmatter.lua`, code déplacé à l'identique, `item.lua` en façade.
- Hors-périmètre : respecté — `done/` ignoré (vérifié par leurre), aucun sélecteur, aucune création
  de fichier.
- Signaux de dérive : aucun matérialisé.
- Symptôme d'origine : disparu — les quatre documents s'ouvrent sans navigation, plan au nom généré
  compris.

### Qualité du code

- **R1** — `lua/chantier.lua:59-70` (`find_suivi`) — si deux suivis actifs portent la même
  `branche` (chantier repris sans archiver l'ancien, copie de suivi), le premier rendu par
  `vim.fs.dir` gagne, dans un ordre non garanti, sans signalement. Cas limite non couvert par le
  brief ; conséquence : ouverture silencieuse du mauvais document.
- **R2** — `lua/chantier.lua:65` — l'erreur de `frontmatter.read` est jetée : un suivi illisible
  est sauté en silence et l'utilisateur lit « aucun chantier en cours sur la branche », message
  trompeur. Corollaire : les messages d'erreur du module commun parlent encore d'« élément »
  (vocabulaire listdir), choix assumé d'une extraction à l'identique.
- Style : conforme aux voisins (tabulations, `---@` Emmylua, types préfixés `Ozay.`, commentaires
  en français de même densité, `stylua` propre). `vim.fn.fnameescape`/`vim.fn.readfile` n'ont pas
  d'équivalent `vim.api`/`vim.fs` : pas un écart à la préférence du dépôt.

### Dette induite

- **R3** — `plugins/listdir/lua/listdir/item.lua:8` — le plugin local `listdir`, structuré comme
  un plugin autonome, dépend désormais d'un module de premier niveau de la config
  (`require("frontmatter")`, nom générique dans l'espace global des modules Lua). Décision tracée
  au journal et voulue par l'utilisateur. Coût futur : sortir `listdir` de cette config (ou le
  publier) oblige à ré-internaliser le parseur ; un plugin tiers livrant un `lua/frontmatter.lua`
  le masquerait selon l'ordre du `runtimepath`.
- **R4** — vérification d'étape 2 : le script de l'auteur ne contrôle que l'absence de buffer, pas
  la présence du message exigé par les critères ; un échec silencieux passerait. Le constat porte
  sur la vérification, pas sur le code — mes exécutions ci-dessus montrent les messages.

### Bloquants

Aucun. Les réserves tiennent à R1 (cas limite non couvert), R3 (dette assumée) et à `:ListDir`
interactif non exécuté ; le verdict plus sévère que FAVORABLE est retenu pour que l'utilisateur
tranche en connaissance de cause.

## 2026-09-21 — clôture — `2190004`

**Verdict** : RÉSERVES

Brief présent et lu ; suivi (4 étapes cochées), plan (`.claude/plans/stateful-knitting-valley.md`)
et diff `master...chantier-docs-commands` lus (10 fichiers, +502 −74) ; delta depuis l'audit
précédent (`7783868..2190004`) lu en détail : seul `lua/chantier.lua` change côté code (+17 −6).
Numérotation poursuivie après R4 de l'audit précédent, pour ne pas faire collision avec les
renvois du journal (« R2 de l'audit »).

### Vérifications exécutées

- Étape 1 — commande exacte du plan (`nvim --headless -c 'lua local i=require("listdir.item"); …
  print("OK")' -c q`) → `OK`, code retour 0.
- Étapes 2 et 4 — script à moi (dépôt temporaire hors config, config complète chargée,
  `vim.notify` intercepté, nom de buffer relevé). Sortie réelle :
  - `demo :Suivi` → `demo.md`, aucun message ; `demo :Brief` → `demo.brief.md` ; `demo :Brief`
    depuis `sub/` → `demo.brief.md`
  - `demo :Plan` (`<À REMPLIR>`) → buffer vide, ERROR « le suivi ne renseigne pas « plan » »
  - `demo :Audit` (fichier absent) → buffer vide, ERROR « audit introuvable : .claude/implementation/demo.audit.md »
  - `wa :Audit` (audit présent) → `withaudit.audit.md` : le cas laissé « couvert indirectement »
    à l'audit précédent est maintenant exercé
  - `wa :Plan` (`.claude/plans/a b%c.md`) → `a b%c.md`
  - `master :Suivi` → buffer vide, WARN « aucun chantier en cours sur la branche « master » »
  - `autre :Suivi` (leurre `branche = "autre"` dans `done/`) → buffer vide, WARN « aucun chantier… « autre » »
  - HEAD détachée `:Suivi` → buffer vide, WARN « pas de branche courante (HEAD détachée ?) »
  - **E4** — `broken.md` en `chmod 000`, `master :Suivi` → buffer vide, ERROR « aucun chantier en
    cours sur la branche « master » — suivis non lus : \n élément illisible : …/broken.md »
  - **E4** — même `broken.md` illisible, `demo :Brief` → `demo.brief.md` : un suivi illisible
    voisin n'empêche pas de trouver le bon
  - **E4** — `demo.md` lui-même en `chmod 000`, `demo :Suivi` → buffer vide, ERROR listant
    `broken.md` et `demo.md` : le cas trompeur de R2 est désormais signalé
- Dans ce dépôt, sur `chantier-docs-commands` : `:Suivi`, `:Brief`, `:Plan`, `:Audit` → ouvrent
  respectivement le suivi, le brief, `stateful-knitting-valley.md` et `chantier-docs-commands.audit.md`
  (seul message : W325 swapfile, dû à une session Neovim ouverte en parallèle).
- Étape 3 — `git status --short` → vide ; `git diff --name-only master...` → les 6 fichiers de la
  section Fichiers du plan + les 4 documents du chantier ; `grep -n frontmatter docs/plugins/listdir.md
  CLAUDE.md` → 3 lignes (listdir.md:17, :138 ; CLAUDE.md:43).
- `stylua --check` (mason) sur `lua/chantier.lua lua/frontmatter.lua lua/cmd.lua
  plugins/listdir/lua/listdir/item.lua` → code retour 0.
- Diagnostics `emmylua_ls` relevés en headless : `lua/chantier.lua` → 0 ;
  `plugins/listdir/lua/listdir/item.lua` → 0 ; `lua/frontmatter.lua:52` `param-type-mismatch`
  (préexistant, déplacé depuis `item.lua`, cf. audit précédent) ; `lua/cmd.lua:26,30` `hide`
  indéfini (antérieurs au chantier).
- Signal de dérive — `git diff master...chantier-docs-commands -- lua plugins | grep -E
  '^\+.*(ui\.select|picker|Snacks|writefile|io\.open)'` → aucune ligne (rc 1).
- `ruff` / `basedpyright` : sans objet, aucun fichier Python dans le diff.
- `:ListDir` interactif (picker Snacks, titres affichés) → NON EXÉCUTÉE : exige une session
  interactive ; la façade `item.read`/`item.title` est vérifiée (étape 1), et E4 ne touche pas listdir.

### Conformité à l'intention

- Critère « `:Suivi`, `:Brief`, `:Plan`, `:Audit` ouvrent le document désigné par le suivi dont
  `branche` = branche courante » : atteint, vérifié pour les quatre, `:Audit` avec fichier présent compris.
- Critère « document absent ou champ vide → erreur, aucun buffer » : atteint, vérifié.
- Critère « `master` ou branche sans suivi → message, rien d'ouvert » : atteint, vérifié (WARN ;
  ERROR avec la liste des suivis non lus quand il y en a).
- Critère « fonctionne depuis un autre dépôt, résolu depuis le cwd » : atteint, vérifié (dépôt
  temporaire, sous-répertoire compris).
- Contrainte « parseur extrait dans un module commun utilisé par listdir et les commandes » : respectée.
- Hors-périmètre : respecté — `done/` ignoré (leurre), aucun sélecteur, aucune création de fichier.
- Signaux de dérive : aucun matérialisé.
- Symptôme d'origine : disparu.
- Suites de l'audit précédent : R2 corrigé et vérifié (ci-dessus). R1 (deux suivis sur une même
  branche) volontairement non traité, décision datée au journal — reste un cas limite connu. R3
  (dépendance de listdir envers la config) et R4 (vérification d'auteur limitée au nom de buffer)
  inchangés ; R4 est sans conséquence ici, mes exécutions couvrant les messages.

### Qualité du code

- **R5** — `lua/chantier.lua:59,93,100` — `find_suivi` rend en second retour soit les données du
  suivi, soit la liste d'erreurs (`Ozay.Frontmatter.Data|string[]`), et `M.open` départage par deux
  `---@cast`. Correct à l'exécution et propre pour `emmylua_ls`, mais le type ne dit plus lequel
  des deux on tient : une future modification qui lit `data.fields` sans passer par la branche
  `suivi ~= nil` compilera sans alerte. Un troisième retour dédié aux erreurs aurait gardé chaque
  valeur à un seul type. Mineur.
- **R6** — `lua/chantier.lua:66` via `lua/frontmatter.lua:79-84` — le cache sur `mtime` masque un
  suivi devenu illisible après une première lecture (un `chmod` ne change pas `mtime`) : les
  données en cache continuent d'être servies. Sans effet pratique sur l'usage visé ; signalé pour
  que « illisible → signalé » ne soit pas lu comme une garantie absolue.
- Les messages ERROR réutilisent le vocabulaire listdir (« élément illisible »), déjà relevé et
  assumé à l'audit précédent.
- Style : conforme aux voisins (tabulations, Emmylua, `Ozay.`, commentaires en français, `stylua`
  propre).

### Dette induite

- Rien de nouveau depuis l'audit précédent. R3 demeure (dépendance assumée, tracée au journal).

### Bloquants

Aucun. Verdict RÉSERVES plutôt que FAVORABLE : R1 reste un cas limite ouvert par décision de
l'utilisateur, R3 une dette assumée, et `:ListDir` interactif n'a pas été exécuté — trois points
que l'utilisateur doit avoir sous les yeux avant de clore.
