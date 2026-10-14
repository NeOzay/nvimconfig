# Plan — listdir-dettes-roadmap

## Relecture

```
VERDICT : RÉSERVES
CRITÈRES :
C1 — Registre local en v3, validate --filled sans avertissement de péremption (avec -solde, -ecarte) → Étape 1
C2 — Marqueurs typés reconnus par lua/chantier.lua et picker/items.lua ; reviewed = <OPTIONNEL date> en retrait → Étape 2 (preuve du brief déplacée, cf. Q1)
C3 — Sens inversé : Marqueur ou sans valeur en fin ; champs deprecated hors du cycle de tri → Étape 3
C4 — :Dettes : pins en tête et couleur propre ; cycle puis date décroissante puis severite décroissante, sans clé répétée ; sévérité colorée ; touche des pins ; titre avec nombre de dettes et de pins → Étapes 5, 6
C5 — Toggle du pin par list-dir set, diff limité à la ligne pin, rafraîchi en place → Étape 9 (bloquée tant que set n'existe pas)
C6 — :Roadmap ouvre le picker d'éléments sur .claude/implementation/todo/road-map → Étape 5
C7 — :Brief sur master : un → ouvert, plusieurs → picker, aucun → message ; inchangé sur une branche de chantier → Étape 7
C8 — <leader>fr rouvre avec un indicateur (« ↑ date ») conforme au tri en cours → Étape 4
C9 — Tests mini.test du listdir et de chantier.lua verts ; docs/plugins/listdir.md décrit commandes et touches → Étapes 2 à 7, 8, 9
HORS-PÉRIMÈTRE : RESPECTÉ
DÉRIVE : aucun
INCERTITUDES :
Toggle du pin dépendant de set → tranchée : tout le reste d'abord, Étape 9 en dernier, posée [!]
Solde de la dette consommateurs-des-marqueurs-generiques-hors-etat → tranchée : points Neovim corrigés à l'Étape 2, ~/.claude non touché, signalé à la Clôture
MODÈLE : opus → SOUTENU — interface de set encore inconnue (Étape 9), confrontation d'un rapport d'agent (Étape 1) ; au moindre doute, Opus
QUALITÉ :
Q1 — Étape 2 : la preuve de C2 fixée par le brief (grep sur chantier.lua et items.lua) ne montrera plus rien une fois la reconnaissance regroupée dans frontmatter.lua ; vérification réécrite sans le dire ; affichage en retrait non testé
Q2 — Étape 1 : « aucune édition à la main » contredit le geste 6 de migrations/3.md (« se corrige à la main ») ; aucune voie de correction d'une valeur fausse, fill ne réécrivant que des Marqueurs
Q3 — Étape 1 : deux commits (geste 4, et « Puis committer » au geste 8, absent du plan), un agent et un arbitrage de l'utilisateur : pas un seul tour ; coupure naturelle après le geste 4
Q4 — Étapes 4 à 6 : les tests Snacks en Neovim enfant supposent snacks.nvim au runtimepath et lancé ; ni tests/minimal_init.lua ni aucune Étape ne le prévoient
Q5 — Étape 6 : moment de mise à jour des compteurs non dit (titre posé avant refresh, finder plus tard) ; sens de « N dettes » sous le filtre des pins non tranché ; couleurs de sévérité sans vérification automatique
Q6 — Étape 8 : rumdl absent de la machine, la vérification se réduit à « relecture »
Q7 — Abandon de la convention « --sort une colonne » : hors de la lettre de S3 (seul l'id est lu), mais l'appel multi-colonnes sera visible dans le diff ; à ratifier pour éviter un arrêt en cours de route
Q8 — Fichiers de test neufs de tests/listdir/ non marqués « neuf », contrairement à tests/chantier/test_chantier.lua
```

Le bloc ci-dessus numérote les Étapes d'avant le découpage de la migration : son Étape N est
l'Étape N+1 du plan, sauf l'Étape 1, devenue les Étapes 1 et 2.

Arbitrages de l'utilisateur :

- **Q1** — preuve déplacée : `frontmatter.is_marker` reste la seule définition ; C2 se prouve par
  le grep sur `lua/frontmatter.lua` et par un test qui vérifie qu'un `reviewed = <OPTIONNEL date>`
  s'affiche en retrait dans le picker (Étape 3).
- **Q2/Q3** — la migration se coupe en deux Étapes (1 : gestes 1 à 4, commit de structure ; 2 :
  gestes 5 à 8, commit). Une valeur fausse posée par l'agent se corrige à la main dans le front
  matter, par l'agent Claude — jamais par Neovim —, comme le prescrit le geste 6.
- **Q5** — les compteurs gardent le total du registre, comptés en Lua sur les fichiers, sans appel
  Python ; le titre ajoute `[pins]` sous filtre ; ils se recalculent à la fin du finder, resume
  compris.
- **Q7** — ratifié : `--sort` à plusieurs clés dont seul l'id est lu n'est pas le Signal S3.

Corrigés sans arbitrage (défauts de rédaction) : Q4 (snacks au runtimepath de
`tests/minimal_init.lua`, Étape 5), Q6 (vérification de l'Étape 9 sans `rumdl`), Q8 (fichiers
marqués « neuf »).

Brief : `.claude/implementation/listdir-dettes-roadmap.brief.md` (validé). Pas d'entrée road-map
d'origine dans ce dépôt. Chantier préalable annoncé : entrée `list-dir-set` de la road-map de
`~/.claude`, qui fournit `list-dir set`.

## Context

`list-dir` a évolué (Marqueurs typés, tri typé `--sort=-champ` avec Marqueurs en fin dans les deux
sens, champs `deprecated`, `bool`, registre de dette v3 avec `pin` et `severite`) sans que le plugin
`listdir` ni `lua/chantier.lua` suivent. Le chantier les remet au niveau, migre le registre local en
v3, ajoute `:Dettes` (pins en tête et colorés, sévérité colorée, filtre des pins, compteurs, toggle
du pin par `list-dir set`) et `:Roadmap`, corrige l'indicateur de tri au resume et `:Brief` hors
chantier.

Rappels du brief :
- **Critères** : C1 registre v3 conforme ; C2 Marqueurs typés reconnus ; C3 Marqueurs en fin en sens
  inverse, `deprecated` hors cycle ; C4 `:Dettes` (ordre pin > cycle > `-date` > `-severite`,
  couleurs, filtre, compteurs) ; C5 toggle par `list-dir set`, diff réduit à la ligne `pin` ;
  C6 `:Roadmap` ; C7 `:Brief` hors chantier ; C8 indicateur juste au `<leader>fr` ; C9 tests
  mini.test verts, doc à jour.
- **Hors-périmètre** : écrire `set` dans `list-dir` ; toute écriture directe de Neovim dans une
  entrée ; touche d'ouverture du chantier d'origine.
- **Signaux de dérive** : S1 écriture Lua dans un `.md` de liste ; S2 diff dans
  `~/.claude/skills/list-dir/` ; S3 sortie multi-colonnes découpée par position ; S4 un appel
  `list-dir` par élément ; S5 picker réimplémenté au lieu de `picker/items.lua`.

### Incertitudes du brief, tranchées par le plan

- **Dépendance à `set`** : tout le reste est livré d'abord ; le toggle est la dernière Étape (10),
  posée `[!]` tant que `list-dir set` n'existe pas, et son interface se cale sur celle que le
  chantier préalable aura livrée (`list-dir help`). Le Chantier ne se clôt pas sans elle.
- **Dette `consommateurs-des-marqueurs-generiques-hors-etat`** (registre de `~/.claude`) : ce
  chantier corrige ses deux points Neovim (Étape 3) et ne touche pas `~/.claude` ; la Clôture
  signale à l'utilisateur que seul le point `dette.md` reste, pour qu'il la traite dans `~/.claude`.

## Modèle

**Opus** — le code se vérifie bien, mais l'Étape 2 délègue à `migrateur-de-liste` une migration
dont il faut confronter le rapport, et l'Étape 10 dépend d'une interface encore à écrire dans un
autre dépôt ; au moindre doute, Opus.

## Réutilisé

- `list-dir list --sort=k1,-k2 --where c=v` : tri typé fait par la CLI. **Seul le premier token
  (l'id, un slug) est lu** : l'ordre vient de `list`, toutes les valeurs affichées viennent du front
  matter lu en Lua (`item.read`, caché). Vérifié : `list --sort=-pin,title,-date,-severite` sur le
  registre de `~/.claude` rend les pins d'abord ; `--sort=-reviewed` laisse les Marqueurs en fin.
  Cela lève S3 sans renoncer au tri multi-clés : rien n'est découpé par position.
- `lua/frontmatter.lua` (`read`, cache `mtime`) ; `plugins/listdir/lua/listdir/{cli,contract,item}.lua` ;
  `picker/items.lua` (`M.open`, `sort_action`, `config.picker`).
- `lua/chantier.lua` (`find_suivi`, `notify`, `filled`) ; `lua/cmd.lua` (déclaration des commandes).
- Snacks : `Snacks.picker.pick`, hook `on_show` ; `plugins/snacks.nvim/lua/snacks/picker/resume.lua`
  rejoue `picker.init_opts`, d'où le titre initial au resume.
- Highlights : `lua/highlights/<plugin>.lua` (`docs/plugins/theme-highlights.md`).
- Tests : `tests/minimal_init.lua`, `Makefile` (`make test`, `make test-file FILE=…`), modèle
  `tests/lexique/test_lexique.lua` (CLI réelle sur un projet temporaire).
- Migration : `~/.claude/skills/implementation-tracker/list-dir/technical-debt/migrations/3.md`,
  agent `migrateur-de-liste`.

## Étapes

### 1. Migrer la structure du registre local de dette en v3

Fichiers : `.claude/implementation/todo/technical-debt/`, `technical-debt-solde/`,
`technical-debt-ecarte/` (contrats, `.list/semence/`, `.list/patrons/review.toml`, entrées).

`migrations/3.md`, gestes 1 à 4 : `AVANT` noté (il se reporte au Suivi pour l'Étape 2) ;
`reseed` + `migrate` + `validate --filled` des deux listes de sortie ; `reseed`, `migrate`,
`fill severite inconnue --all` du registre ; comptes égaux. L'Étape se clôt sur le **commit de
structure** que le geste 4 exige — commit d'Étape par `git-smart-commit`, type 2, avec accord —, et
son SHA (`STRUCTURE`) se reporte au Suivi.

Vérif :
```bash
for l in technical-debt technical-debt-solde technical-debt-ecarte; do
  list-dir validate .claude/implementation/todo/$l; done 2>&1 | grep -c 'périmé'   # 0
T=.claude/implementation/todo/technical-debt
[ "$(list-dir list $T | wc -l)" = "$(list-dir list $T --where severite=inconnue | wc -l)" ]
```

### 2. Reporter `source` dans `chantier` et `reference`

Fichiers : `.claude/implementation/todo/technical-debt/*.md`.

`migrations/3.md`, gestes 5 à 8 : `migrateur-de-liste` par lots de 30 avec la consigne du document
(`AVANT` et la racine absolue) ; confrontation de chaque ligne `posé` à sa citation ; une valeur que
sa citation ne justifie pas se corrige **à la main**, dans le front matter, par l'agent Claude —
jamais par Neovim — et se signale ; garde (sortie 0, depuis `STRUCTURE`) ; `validate --filled`, les
Marqueurs restants tranchés par l'utilisateur et posés par `list-dir fill --id`. Commit d'Étape.

Vérif :
```bash
for l in technical-debt technical-debt-solde technical-debt-ecarte; do
  list-dir validate .claude/implementation/todo/$l --filled || echo "ÉCHEC $l"; done 2>&1 \
  | grep -c 'périmé\|ÉCHEC'   # 0 (C1)
```
plus la garde du document, sortie 0.

### 3. Reconnaître les Marqueurs typés

Fichiers : `lua/frontmatter.lua`, `lua/chantier.lua`, `plugins/listdir/lua/listdir/picker/items.lua`,
`tests/minimal_init.lua`, `tests/listdir/test_frontmatter.lua` (neuf).

- `frontmatter.is_marker(value)` : vrai pour `^<À REMPLIR` et `^<OPTIONNEL` suivis de `>` ou d'une
  espace (forme typée). Un seul endroit.
- `chantier.lua` : `PLACEHOLDERS` remplacé par `frontmatter.is_marker` dans `filled`.
- `items.lua` : `EMPTY` réduit à `""` + `frontmatter.is_marker`.
- `tests/minimal_init.lua` : `plugins/listdir` ajouté au runtimepath.
- Tests : génériques, typés (`<OPTIONNEL date>`, `<À REMPLIR date>`), valeurs ordinaires et
  `<OPTIONNELLE>` refusées.

- Test d'affichage : `items.format` d'une entrée dont la valeur triée est `<OPTIONNEL date>` ne
  rend pas cette valeur en colonne (retrait).

Vérif : `make test-file FILE=tests/listdir/test_frontmatter.lua` ;
`grep -n 'OPTIONNEL' lua/frontmatter.lua` montre le motif typé, et
`grep -n 'OPTIONNEL\|PLACEHOLDERS\|EMPTY = {' lua/chantier.lua plugins/listdir/lua/listdir/picker/items.lua`
ne montre plus de table de chaînes exactes (C2, preuve déplacée — arbitrage Q1).

### 4. Tri typé et champs dépréciés

Fichiers : `plugins/listdir/lua/listdir/cli.lua`, `contract.lua`, `picker/items.lua`,
`picker/lists.lua`, `tests/listdir/test_cli.lua` (neuf).

- `cli.list(dir, keys, where?)` : `keys` liste de champs, `-` en tête pour décroissant, passée en
  `--sort=<k1>,<k2>` ; `where` liste de `c=v` en `--where`. Rend `{ id, path }` seulement — le
  premier token. Plus d'inversion en Lua : le sens passe par `-`, ce qui garde les Marqueurs en fin
  (C3). Un seul appel par run du finder (S4).
- `items.lua` : la valeur de la colonne vient de `item.read(path).fields[field]` (`id` → l'id).
- `contract.lua` : `Field.deprecated` (ligne `deprecated = …`) ; types documentés `bool`, `int`.
  Le cycle de tri saute les champs dépréciés ; la fiche du picker des listes les marque.
- Tests, contre la CLI réelle sur une liste temporaire semée par `list-dir init --def
  technical-debt` + `list-dir new` (dans le scratch, jamais le registre du dépôt) : ordre décroissant
  avec un Marqueur resté en fin ; `source` absent du cycle.

Vérif : `make test-file FILE=tests/listdir/test_cli.lua`.

### 5. Indicateur de tri juste au resume

Fichiers : `plugins/listdir/lua/listdir/picker/items.lua`, `tests/minimal_init.lua`,
`tests/listdir/test_items.lua` (neuf).

`tests/minimal_init.lua` : `plugins/snacks.nvim` ajouté au runtimepath et `require("snacks").setup({ picker = {} })`, pour
que les tests en Neovim enfant des Étapes 5 à 10 disposent de `Snacks.picker`.

`resume` rejoue `picker.init_opts` : le titre y est celui de l'ouverture, alors que `state` (la
closure) a gardé le tri courant. Ajouter `on_show = function(picker) picker.title = M.title(state);
picker:update_titles() end` aux options, pour que toute ouverture, resume compris, recalcule le
titre depuis `state`. Donner aussi un `source = "listdir_items"` pour que le resume ne confonde pas
ce picker avec d'autres `custom`.

Vérif : test en Neovim enfant — ouvrir, `<A-s>`, fermer, `Snacks.picker.resume()`, comparer
`picker.title` à `M.title(state)` (C8) ; `make test-file FILE=tests/listdir/test_items.lua`.

### 6. Points d'extension du picker d'éléments, et `:Roadmap`

Fichiers : `plugins/listdir/lua/listdir/picker/items.lua`, `lua/registres.lua` (neuf),
`lua/cmd.lua`, `tests/listdir/test_items.lua`.

- `items.open(dir, ct, opts?)` accepte : `before` / `after` (clés fixes avant et après le champ du
  cycle ; une clé d'`after` égale au champ courant est omise), `skip` (champs hors cycle), `where`
  (fonction de `state` rendant les filtres), `decorate(entry, data)` (highlights préfixés et
  groupe du libellé), `title(state, stats)`, `actions` et `keys` fusionnés. Sans `opts`, le
  comportement de `:ListDir` est inchangé. Pas de second picker (S5).
- `lua/registres.lua` : `root()` (racine git du cwd, comme `chantier.lua`), `M.roadmap()` ouvre
  `items.open` sur `<root>/.claude/implementation/todo/road-map` sans `opts` ; message si la liste
  est absente.
- `lua/cmd.lua` : `:Roadmap`.

Vérif : `make test-file FILE=tests/listdir/test_items.lua` (clés composées : `after` omis quand égal
au champ courant) ; `nvim --headless -c 'autocmd VimEnter * ++once Roadmap' -c 'lua
vim.defer_fn(function() print(Snacks.picker.get()[1].title) vim.cmd("qa!") end, 1500)'` affiche
`road-map  ↑ title` (C6).

### 7. `:Dettes`

Fichiers : `lua/registres.lua`, `lua/cmd.lua`, `lua/highlights/listdir.lua` (neuf),
`tests/listdir/test_registres.lua` (neuf).

- `M.dettes()` : `items.open` sur `<root>/.claude/implementation/todo/technical-debt` avec
  `before = { "-pin" }`, `after = { "-date", "-severite" }`, `skip = { "pin" }`.
- `decorate` : libellé en `ListDirPinned` si `pin == "true"` ; colonne de sévérité en
  `ListDirSeverity<Niveau>` (critique rouge, majeur orange, avertissement jaune, note gris,
  `inconnue` en retrait) — couleurs de la palette dans `lua/highlights/listdir.lua`.
- Filtre des pins : action et touche (`<A-n>`, libre chez Snacks) qui bascule `where = { "pin=true" }`
  et rafraîchit.
- `title` : `technical-debt  ↑ title  22 · 3 pins`, `[pins]` ajouté sous filtre. Les compteurs
  portent sur **tout le registre**, filtre ou non (arbitrage Q5) : comptés en Lua sur les `*.md` de
  la liste et leur front matter caché, sans appel Python. Recalculés à la fin du finder, qui pose
  le titre par `picker:update_titles()` — le titre posé avant `refresh` n'a pas encore les
  comptes ; `on_show` (Étape 5) couvre le resume.
- Test des couleurs : `decorate` d'une entrée épinglée rend `ListDirPinned` sur le libellé, et
  chaque sévérité son groupe `ListDirSeverity<Niveau>`.
- `lua/cmd.lua` : `:Dettes`.

Vérif : `make test-file FILE=tests/listdir/test_registres.lua` sur une liste temporaire v3 — pins
d'abord, puis le champ du cycle, puis `-date`, `-severite` ; filtre ; compteurs sous filtre et sans ; groupes de highlight (C4) ; décompte
headless de `:Dettes` comme à l'Étape 6.

### 8. `:Brief` hors chantier

Fichiers : `lua/chantier.lua`, `tests/chantier/test_chantier.lua` (neuf).

- `find_suivi` devient un balayage qui rend tous les suivis lus ; le suivi de la branche se tire de
  ce balayage.
- `M.open("brief")` sans suivi sur la branche : briefs hors chantier = `*.brief.md` de
  `.claude/implementation/` (pas `done/`) qu'aucun suivi ne cite en `brief` (chemins normalisés
  depuis la racine). Un → ouvert ; plusieurs → picker Snacks des fichiers (preview fichier,
  `<CR>` ouvre) ; aucun → le message actuel. Les autres champs et le cas d'une branche de chantier
  sont inchangés.
- Tests sur un dépôt git temporaire : branche sans suivi et un brief / deux briefs / brief cité par
  un suivi ; branche de chantier.

Vérif : `make test-file FILE=tests/chantier/test_chantier.lua` (C7).

### 9. Documentation

Fichiers : `docs/plugins/listdir.md`, `CLAUDE.md`, `docs/plugins/snacks.md` si le gotcha `on_show`
s'y range mieux.

- `listdir.md` : `:Dettes`, `:Roadmap`, `before`/`after`/`skip`/`where`/`decorate`, `<A-n>` ;
  Gotchas « `--sort` une colonne » réécrit (seul l'id est lu, tri multi-clés permis) et « resume
  rejoue `init_opts` » ; Changelog.
- `CLAUDE.md` : `:Dettes`, `:Roadmap`, `:Brief` hors chantier, `frontmatter.is_marker`.

Vérif : `make test` vert ; `grep -n 'Dettes\|Roadmap\|<A-n>' docs/plugins/listdir.md CLAUDE.md`
rend les nouvelles entrées ; relecture du rendu (pas de `rumdl` sur la machine).

### 10. Toggle du pin par `list-dir set` — bloquée tant que `set` n'existe pas

Fichiers : `plugins/listdir/lua/listdir/cli.lua`, `lua/frontmatter.lua`, `lua/registres.lua`,
`tests/listdir/test_registres.lua`, `docs/plugins/listdir.md`.

- Préalable : `list-dir help` liste `set` ; l'interface se reprend de son aide.
- `cli.set(dir, id, field, value)` : appel de `list-dir set`, échec nommé par `vim.notify`.
- `frontmatter.forget(path)` : le cache valide sur `mtime.sec` ; deux bascules dans la même seconde
  serviraient l'ancienne valeur. Oublier l'entrée après chaque `set`.
- Action `ld_toggle_pin` (`<A-t>`), sur l'entrée courante : `true` ↔ `false`, puis `refresh` et
  curseur gardé sur l'entrée. Aucune écriture Lua dans le `.md` (S1).
- Doc : touche et comportement.

Vérif : `make test-file FILE=tests/listdir/test_registres.lua` (bascule aller-retour sur une liste
temporaire, `git diff` limité à la ligne `pin`) (C5) ; `make test`.

## Vérification d'ensemble

`make test` ; C1 par les `validate` de l'Étape 2 ; ouverture manuelle de `:Dettes`, `:Roadmap`,
`:Brief` sur `master`, `<leader>fr` après un `<A-s>`.
