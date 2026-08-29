---
slug: list-dir-viewer
suivi: .claude/implementation/list-dir-viewer.md
brief: .claude/implementation/list-dir-viewer.brief.md
plan: .claude/plans/silly-wandering-hippo.md
base: master
branche: list-dir-viewer
---

# Audit — list-dir-viewer

## Audit de clôture — 2026-08-29 — commit b24bcd0

**Verdict : RÉSERVES**

Portée : `git diff master...list-dir-viewer`, 16 fichiers, +1601/-1. Arbre de travail propre au
moment de l'audit (les « ajustements 3 et 4 » que le suivi dit non commités le sont, dans b24bcd0).

### Vérifications exécutées

Fixture reconstruite selon le plan (`init` + contrat complété + deux éléments, `beta` sans
`category`), sous le scratchpad de session. `python3` 3.14.7, nvim 0.13.0-dev.

| Commande | Résultat réel |
|---|---|
| Étape 1 — `config.setup` / défauts | **OK** |
| Étape 2 — `contract.read` + `discover.find` | **OK** (description de liste non écrasée par celles des `[fields.X]`) |
| Étape 3 — `cli.list` colonne vide + `item.read` | **OK** (id découpé, `reverse` correct, front matter retiré) |
| Étape 4 — `lists.finder` / `lists.confirm` | **OK** (enchaînement niveau 1 → 2) |
| Étape 5 — `items.state` / `items.finder` | **OK** (`field == "title"`, 2 items) |
| Étape 6 — comptage d'appels Python | **OK** — 3 appels `vim.system` pour 3 runs de finder ; reverse en Lua, sans appel |
| Étape 7 — `document.render` / `open` (adaptée) | **OK** — un `## [` par élément, lien absolu, `##`→`###`, ` ``` ` respecté, buffer réutilisé |
| Étape 8 — `document.target` + mappings (adaptée) | **OK** — `<CR>`, `gf`, `q` buffer-local ; cible correcte |
| Étape 9 — `grep listdir CLAUDE.md` + doc | **OK** |
| Contrôle 2 — `git grep -nE '"(show\|merge\|new\|move\|derive\|migrate\|init)"' plugins/listdir` | **OK — aucune remontée** |
| Bout-en-bout : `<CR>` sur un lien du document | **OK** — buffer courant = `.../demo/alpha.md` |
| Tri par `id` (ajustement 1 du suivi) | **OK** — cycle `date,category,id,title`, finder rend 2 items |
| `make test` (MiniTest du dépôt) | **OK** — 60 cas, 0 fail, 0 note : aucune régression |
| `stylua --check plugins/listdir/ lua/plugins/listdir.lua` | **ÉCHEC** — 1 diff (cf. R4) |
| Contrôle 3 du plan (manuel, session Neovim interactive) | **NON EXÉCUTÉE : requiert une UI ; impossible en headless** |

Les commandes des étapes 7 et 8 ont été **adaptées** : celles du plan assertent
`buftype == "nofile"` et un nom `list-dir://demo`, périmés depuis l'ajustement 2 du suivi (document
écrit sous `stdpath("cache")`, arbitré par l'utilisateur). Assertions équivalentes substituées :
`buftype == ""`, `nomodifiable`, nom `…/listdir/demo.md`. Idem pour `maparg` → `nvim_buf_get_keymap`,
écart déjà consigné au suivi. **Le plan n'a pas été mis à jour de ces écarts** (R8).

### 1. Conformité à l'intention

| Critère de réussite | État |
|---|---|
| Commande ouvrant un picker des listes ; `<CR>` ouvre le picker des éléments | **Atteint**, vérifié au niveau module (`lists.finder`, `lists.confirm` → `items.open`). `:ListDir` existe, `<leader>fl` sans collision dans le dépôt. Le rendu de la fenêtre Snacks n'est pas exerçable en headless (R8). |
| Picker d'éléments : preview, `<CR>` ouvre le fichier, mapping changeant le tri à la volée | **Atteint.** Preview = previewer fichier Snacks via `item.file`. `confirm` → `vim.cmd.edit`. `sort_next/prev/reverse` changent bien l'ordre rendu, un seul appel `list` par run. Le rafraîchissement visuel (`picker.title` + `picker:refresh()`) reste UI. |
| Document Markdown concaténé, titres = liens, `gf` ouvre le fichier | **Atteint et vérifié de bout en bout** — sauf chemins contenant `)` (R2). Écart assumé au brief sur le `nofile` : document écrit sous le cache, arbitré par l'utilisateur et consigné au suivi et au journal — écart **légitime**, le suivi faisant foi. |
| Aucun appel à `show`, `merge`, ni commande d'écriture | **Atteint.** `git grep` ne remonte rien ; le seul sous-processus du plugin est `list-dir.py list`. |

**Hors-périmètre** : respecté. Le plugin n'écrit que sous `stdpath("cache")/listdir/`, jamais dans
un répertoire-liste ; aucun ordre manuel persistant (l'état de tri vit dans la closure du picker).

**Signaux de dérive** : aucun matérialisé. Écriture dans une liste : non. `show` : non. Nombre
d'appels Python croissant avec le nombre d'éléments : non — mesuré à 1 appel par run de finder,
indépendamment du nombre d'éléments ; titres et corps lus en Lua avec cache sur `mtime`.

**Symptôme d'origine** : levé. Les listes se consultent depuis Neovim.

### 2. Constats

**R1 — La doc décrit un `vim.schedule` que le code n'a plus.**
`docs/plugins/listdir.md:99` : « Ouvrir le document depuis le picker passe par `vim.schedule` ».
`grep -rn "vim.schedule" plugins/listdir/` ne remonte rien : le report avait été introduit par
4e295c0 (« `picker:close()` défait les fenêtres de snacks de façon asynchrone … markview ne s'y
attache pas »), puis **retiré par b358991** sans que la gotcha soit corrigée ni le retrait justifié
au journal de décisions. Deux lectures possibles, non tranchables ici : soit le passage au fichier
réel rend le report inutile (`edit` refait naître `BufWinEnter`), soit la régression de rendu
markview décrite par 4e295c0 est revenue. Le contrôle manuel (contrôle 3 du plan, non exécuté)
est exactement celui qui trancherait.

**R2 — Lien Markdown tronqué pour tout chemin contenant `)` ; échec silencieux ensuite.**
`document.render` interpole le chemin brut : `("## [%s](%s)")`. `document.target` extrait
`%]%((.-)%)`, non gourmand. Mesuré sur une liste sous `…/dir (test)/demo` :
```
ligne : ## [Titre alpha avec espaces](/…/fixture/dir (test)/demo/alpha.md)
cible : /…/fixture/dir (test
```
`follow()` appelle alors `vim.cmd.edit` sur un chemin inexistant : Neovim ouvre un **buffer vide
sans erreur**. L'utilisateur croit avoir ouvert l'élément. Le critère « `gf` ouvre le fichier »
tient pour les chemins ordinaires, mais le chemin d'échec est muet. Réserve à lever en premier.

**R3 — `discover.find` bloque l'interface plusieurs secondes sur un cwd volumineux.**
La spec livrée (`lua/plugins/listdir.lua`) impose `depth = 10`, et `discover.find` descend par
`vim.fs.dir` sans exclure `.git`, `node_modules` ni les répertoires cachés. Mesures :
`39 ms` sur le dépôt nvim, **`4094 ms` sur `$HOME`**, à chaque `:ListDir`. Le brief ne contraint la
performance que sur les appels Python : ce n'est donc pas un critère manqué, mais un coût réel dès
que le cwd est vaste.

**R4 — Écart de formatage : `stylua --check` échoue sur `picker/lists.lua`.**
Le `vim.notify` de `M.open` (lignes 90-93) est éclaté sur quatre lignes là où stylua le veut sur
une (< 120 colonnes). Les fichiers voisins du dépôt (`lua/plugins/bookmarks.lua`,
`plugins/bookmarks/lua/bookmarks/*.lua`) passent `stylua --check` sans diff : la non-conformité est
propre à ce chantier.

**R5 — Le plan affirme à tort que le dépôt n'a pas d'infrastructure de test.**
« aucune infrastructure de test ajoutée au dépôt (il n'en a pas) » — or `Makefile` (`make test`),
`tests/minimal_init.lua`, `tests/lsp/`, `tests/tts/` existent et font tourner 60 cas MiniTest. Le
plugin livre donc zéro test alors que la convention du dépôt en fournit le cadre, et que
`contract.read`, `item.parse`, `document.render`/`shifted` sont des fonctions pures conçues pour
être vérifiables. Coût futur : chaque évolution du parseur de contrat ou du décalage de titres se
revérifiera à la main. (Le plan a été validé ainsi : constat, pas reproche de dérive.)

**R6 — Deux listes homonymes partagent le même buffer de document.**
`document.path` ne dérive le nom que de `contract.name` : ouvrir le document de deux listes `demo`
distinctes rend **le même bufnr** (vérifié). Le contenu est régénéré à chaque ouverture, donc jamais
faux dans la fenêtre active ; mais une fenêtre restée sur le premier document affiche silencieusement
le second. Limitation connue et documentée en Gotcha — réserve consignée, pas défaut caché.

**R7 — Front matter non refermé : lecture silencieusement dégradée.**
`item.parse` : si le second `+++` manque, tout le fichier est consommé comme front matter et `body`
est vide (vérifié : `fields.title = X`, `body = ""`). Aucun `err`. L'élément apparaît dans le picker
avec son titre, et sa section disparaît du document concaténé sans un mot. Les autres chemins
d'erreur du plugin sont, eux, corrects : `cli.list` distingue le code non nul (stderr remonté) de
l'exception `vim.system` (binaire absent → message explicite), et `items.finder` `notify` puis rend
une liste vide plutôt qu'une erreur Lua brute.

**R8 — Contrats de suivi désynchronisés de HEAD.**
`statut: en-cours`, « **Non commité** : les ajustements 3 et 4 » alors que b24bcd0 les porte et que
l'arbre est propre ; « **Dernier audit** : aucun ». Les commandes de vérification des étapes 7 et 8
du plan sont périmées depuis l'ajustement 2 (elles assertent `nofile` et `list-dir://`) et
échoueraient telles quelles : elles ont dû être adaptées pour cet audit. Enfin, le **contrôle 3 du
plan — validation manuelle en session interactive — reste non fait** ; c'est la seule vérification
du chantier qu'aucun outil headless ne remplace, et elle couvre précisément R1.

### 3. Qualité et dette — ce qui est bon

À décharge, et parce que la relecture ne doit pas laisser croire à un chantier fragile :
annotations Emmylua complètes et préfixées `Ozay.` conformément à `CLAUDE.md` ; commentaires
d'en-tête expliquant le *pourquoi* (colonne unique de `--sort`, borne au premier `[`, buffer non
`nofile`) et non le *quoi* ; `vim.fs.*` / `vim.api.*` préférés à `vim.fn.*` sauf là où c'est
inévitable (`stdpath`, `readfile`, `writefile`, `fnameescape`) ; `finder`/`confirm`/`state` exposés
au niveau module, ce qui est précisément ce qui a rendu cet audit exécutable ; le cache `item.lua`
invalidé sur `mtime` ; le chemin de la skill exposé en option plutôt qu'en dur ; `config.picker`
fusionnant les réglages utilisateur **par-dessus** les défauts du plugin. Aucune duplication d'un
utilitaire existant, aucune abstraction gratuite, aucun couplage nouveau hors de
`Snacks.picker.pick`. La structure suit `plugins/bookmarks/` comme le demandait le brief.

### Ce qui bloquerait la clôture

Rien de bloquant au sens du verdict : les quatre critères de réussite sont atteints et vérifiés par
exécution. Le verdict est `RÉSERVES` et non `FAVORABLE` parce que R1 (doc décrivant un code qui
n'existe plus, sur le point que le dernier correctif jugeait critique), R2 (échec silencieux du
suivi de lien) et R8 (contrôle manuel jamais effectué, suivi désynchronisé) doivent être connus
avant de trancher.

## Audit de clôture (2e passe) — 2026-08-29 — commit 97dbde6

**Verdict : RÉSERVES**

Portée : `git diff master...list-dir-viewer`, 16 fichiers, +1624/-1. Arbre de travail propre (seul
le présent rapport est non suivi). Le diff entier a été rejugé, pas seulement `b24bcd0..97dbde6`.

### Vérifications exécutées

Fixture reconstruite selon le plan (`init` + contrat complété : `title` texte requis, `date` date
requise, `category` enum optionnel + `alpha`/`beta`, `beta` sans `category`). `python3` 3.14.7,
nvim 0.13.0-dev-931.

| Commande | Résultat réel |
|---|---|
| Fixture — `list demo --sort category` | **OK** — `beta ` (colonne vide) puis `alpha a` : le cas fragile est bien exercé |
| Étape 1 — `config.setup` / défauts | **OK** |
| Étape 2 — `contract.read` + `discover.find` | **OK** |
| Étape 3 — `cli.list` colonne vide + `item.read` | **OK** |
| Étape 4 — `lists.finder` / `lists.confirm` | **OK** |
| Étape 5 — `items.state` / `items.finder` | **OK** |
| Étape 6 — comptage d'appels Python | **OK** — `n=3` pour 3 runs de finder ; reverse sans appel |
| Étape 7 — `document.render` / `open` (adaptée) | **OK** — `###` obtenu, `## pas un titre` en bloc de code préservé, `buftype=""`, `nomodifiable`, nom `…/listdir/demo.md`, buffer réutilisé |
| Étape 8 — `document.target` + mappings (adaptée) | **OK** — `<CR>`, `gf`, `q` buffer-local, cible exacte |
| Étape 9 — `grep listdir CLAUDE.md` + doc | **OK** |
| Contrôle 2 — `git grep -nE '"(show\|merge\|new\|move\|derive\|migrate\|init)"' plugins/listdir` | **OK — aucune remontée** (exit 1) |
| `make test` (MiniTest du dépôt) | **OK** — 60 cas, 0 fail, 0 note |
| `stylua --check plugins/listdir/ lua/plugins/listdir.lua` | **OK — exit 0** (R4 levée) |
| Contrôle 3 du plan (manuel, session Neovim interactive) | **NON EXÉCUTÉE : requiert une UI ; impossible en headless** |

Vérifications ciblées sur les correctifs et les chemins d'erreur :

| Contrôle | Résultat réel |
|---|---|
| R2 — bout en bout sur `…/dir (test)/demo` | **OK** — lien émis `## [Beta](</…/dir (test)/demo/beta.md>)`, `document.target` rend le chemin exact, `<CR>` ouvre le vrai fichier (9 lignes, `fs_stat` non nil) |
| R2 bis — chemin contenant `>` (`…/d>ir/demo`) | **OK** — échappé `\>` à l'écriture, ré-échappé à la lecture, cible identique au chemin source |
| R1 — `grep -rn vim.schedule plugins/listdir/` | **aucune remontée** ; la gotcha correspondante a disparu de `docs/plugins/listdir.md` |
| `cli.list` — interpréteur absent | **OK** — `nil, "échec de l'appel à list-dir : … ENOENT …"` |
| `cli.list` — champ hors contrat | **OK** — stderr remonté : « champ « nawak » non déclaré au contrat » |
| `cli.list` — dépassement de `timeout` (300 ms sur un script de 3 s) | **OK** — rend en 305 ms `nil, "list-dir a rendu le code 124"` ; pas de blocage prolongé, pas d'erreur Lua |
| R6 — `document.path` sur deux listes `demo` distinctes | **inchangé** — même fichier `~/.cache/nvim/listdir/demo.md` |
| R7 — front matter non refermé | **inchangé** — `err = nil`, `title = Gamma`, `body = ""` |
| R3 — `discover.find(depth=10)` | `32 ms` sur le dépôt nvim, **`905 ms` sur `$HOME`** (cache disque chaud ; 4094 ms mesurés à froid au premier audit) |
| **Nouveau** — comptage de `discover.find` dans `lists.open()` | **2 appels** pour une seule ouverture (cf. R9) |

Les commandes des étapes 7 et 8 restent **adaptées** pour les mêmes raisons qu'au premier audit :
celles du plan assertent `buftype == "nofile"` et un nom `list-dir://demo`, périmés depuis
l'ajustement 2 du suivi ; `maparg` remplacé par `nvim_buf_get_keymap`. **Le plan n'a toujours pas
été mis à jour de ces écarts** (R8, non levée).

### 1. Conformité à l'intention

| Critère de réussite | État |
|---|---|
| Commande ouvrant un picker des listes ; `<CR>` ouvre le picker des éléments | **Atteint**, vérifié au niveau module (`lists.finder`, `lists.confirm` → `items.open`). `:ListDir` et `<leader>fl` existent. |
| Picker d'éléments : preview, `<CR>` ouvre le fichier, mapping changeant le tri à la volée | **Atteint.** Preview = previewer fichier Snacks via `item.file` ; `confirm` → `vim.cmd.edit` ; `sort_next/prev/reverse` changent l'ordre rendu, un seul appel `list` par run. |
| Document Markdown concaténé, titres = liens, `gf` ouvre le fichier | **Atteint et vérifié de bout en bout**, y compris sur les chemins à espaces, parenthèses et chevrons (R2 levée). Écart assumé au brief sur le `nofile` : légitime, consigné au suivi et arbitré par l'utilisateur. |
| Aucun appel à `show`, `merge`, ni commande d'écriture | **Atteint.** `git grep` ne remonte rien ; le seul sous-processus est `list-dir.py list`. |

**Hors-périmètre** : respecté. Écriture uniquement sous `stdpath("cache")/listdir/`, jamais dans un
répertoire-liste ; aucun ordre manuel persistant (l'état de tri vit dans la closure du picker).

**Signaux de dérive** : aucun matérialisé. Pas d'écriture dans une liste ; pas de `show` ; nombre
d'appels Python constant (mesuré : 1 par run de finder, indépendamment du nombre d'éléments).

**Symptôme d'origine** : levé.

### 2. Suivi des constats du premier audit

| Constat | État sur 97dbde6 |
|---|---|
| **R1** — doc décrivant un `vim.schedule` absent du code | **Levée.** La gotcha a été remplacée par celle des chevrons ; `grep` confirme que le code n'a plus de `vim.schedule`. Reste que la question de fond (markview s'attache-t-il bien au document après `picker:close()` ?) n'est tranchable qu'en session interactive — elle bascule dans R8. |
| **R2** — lien tronqué sur chemin à `)`, échec silencieux | **Levée.** `document.destination` bascule sur la forme `<…>` dès qu'il y a `%s()<>`, `document.target` lit les deux formes et déséchappe. Vérifié de bout en bout sur `(` et sur `>`. |
| **R3** — `discover.find` lent sur cwd volumineux | **Non traitée** (aggravée par R9). Toujours pas d'exclusion de `.git` / `node_modules` / répertoires cachés, `depth = 10` imposé par la spec. Ce n'est pas un critère manqué — le brief ne contraint la performance que sur les appels Python — mais un coût réel dès que le cwd est vaste. |
| **R4** — `stylua --check` en échec | **Levée.** `stylua --check plugins/listdir/ lua/plugins/listdir.lua` sort 0. |
| **R5** — zéro test alors que le dépôt a `make test` | **Non traitée.** `plugins/listdir/` ne contient que `lua/`. `contract.read`, `item.parse`, `document.render`/`shifted`/`destination`/`target` sont des fonctions pures faites pour être testées ; `destination`/`target` sont précisément le genre de couple qu'une régression casserait en silence. Coût futur assumé. |
| **R6** — deux listes homonymes partagent le même document | **Non traitée**, documentée en Gotcha. Vérifiée à nouveau : `doc.path` identique pour `…/demo` et `…/dir (test)/demo`. Le contenu est régénéré à chaque ouverture, donc jamais faux dans la fenêtre active ; une fenêtre restée sur le premier document affiche silencieusement le second. |
| **R7** — front matter non refermé, lecture silencieusement dégradée | **Non traitée.** `item.read` rend `err = nil`, `fields.title` renseigné et `body = ""` : l'élément apparaît au picker et sa section disparaît du document sans un mot. Les autres chemins d'erreur sont, eux, corrects — vérifié sur binaire absent, champ hors contrat et dépassement de `timeout` (code 124, message explicite, aucun blocage au-delà du délai). |
| **R8** — contrats désynchronisés, contrôle manuel jamais fait | **Partiellement traitée.** La mention « Non commité » a disparu et `Dernier audit` est renseigné. **Restent** : `statut: en-cours` dans le frontmatter du suivi ; les commandes de vérification des étapes 7 et 8 du plan toujours périmées (elles assertent `nofile` et `list-dir://` et échoueraient telles quelles) ; et surtout le **contrôle 3 du plan — validation manuelle en session interactive — toujours non effectué**. C'est la seule vérification qu'aucun outil headless ne remplace, et elle couvre le rendu Snacks, le rafraîchissement du titre au changement de tri, et l'attachement de markview/marksman au document. |

### 3. Constat nouveau

**R9 — `discover.find()` est appelé deux fois par ouverture du picker de listes.**
`picker/lists.lua:88` scanne l'arborescence pour le test « aucune liste », puis `M.finder`
(ligne 52) la rescanne pour construire les items — mesuré : **2 appels pour un seul `:ListDir`**.
Le résultat du premier scan est déjà en main et n'est pas réutilisé. Sur un cwd vaste, cela double
exactement le coût mesuré en R3 (≈ 1,8 s sur `$HOME` au lieu de 0,9 s), et le finder étant relancé
à chaque `picker:refresh()`, tout rafraîchissement paie un scan complet de plus. Ce n'est pas une
préférence de style : c'est du travail disque redondant dans le chemin d'ouverture.

### 4. Qualité et dette — ce qui est bon

Confirmé sur cette passe : annotations Emmylua complètes et préfixées `Ozay.` ; commentaires
d'en-tête expliquant le *pourquoi* (colonne unique de `--sort`, borne au premier `[`, refus du
`nofile` par `vim.lsp`, forme `<…>` des liens) et non le *quoi* ; `vim.fs.*` / `vim.api.*` préférés
à `vim.fn.*` sauf là où c'est inévitable ; `finder`/`confirm`/`state`/`target` exposés au niveau
module, ce qui est ce qui rend cet audit exécutable ; cache `item` invalidé sur `mtime` ; chemin de
la skill exposé en option ; `config.picker` fusionnant les réglages utilisateur **par-dessus** les
défauts. La gestion d'erreur de `cli.list` couvre les trois modes de panne réels (ENOENT, code non
nul avec stderr, timeout) et aucun ne remonte en erreur Lua brute. Le correctif R2 est propre :
échappement et déséchappement symétriques, commentaire justifiant la bascule, doc mise à jour dans
la même passe. Aucune duplication d'utilitaire existant, aucune abstraction gratuite, aucun couplage
nouveau hors de `Snacks.picker.pick`.

### Ce qui bloquerait la clôture

Rien de bloquant au sens du verdict : les quatre critères de réussite sont atteints et vérifiés par
exécution, et les trois constats traités (R1, R2, R4) le sont réellement, correctifs vérifiés.
Le verdict reste `RÉSERVES` — et non `FAVORABLE` — parce que R8 laisse le **contrôle manuel du plan
jamais effectué** et le plan lui-même désynchronisé, que R7 est un chemin d'échec muet toujours
ouvert, et que R9 double un coût déjà signalé en R3. Aucun de ces points n'interdit la clôture s'ils
sont assumés explicitement ; ils ne doivent simplement pas l'être en silence.
