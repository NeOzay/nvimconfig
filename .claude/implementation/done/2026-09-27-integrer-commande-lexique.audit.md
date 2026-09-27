---
slug: integrer-commande-lexique
---

## 2026-09-27 — clôture — `06bdc31`

**Verdict** : RÉSERVES

Diff audité : `git diff master...integrer-commande-lexique` (10 fichiers, +837, dont 507 de code,
tests et `CLAUDE.md`), plus la part `~/.claude` du chantier, `git -C ~/.claude diff ba7203e HEAD`
(commits `6654d48`, `1961188`, `43e4a90`). Brief présent, validé. Le suivi et le brief concordent,
à une décision datée près : `<leader>L` est mappé en `x` au lieu de `v` (journal du 2026-09-27).
Elle est légitime.

### Vérifications exécutées

- `make test-file FILE=tests/lexique/test_lexique.lua` → 14 cas, 0 échec.
- `make test` → 74 cas, 5 groupes, `Fails (0)`. Les tests `lsp` et `tts` sont intacts dans le diff :
  74 = 60 existants + 14 nouveaux.
- Signal 1, le `grep` du plan (étape 2) sur `lua/lexique.lua` → « signal 1 : rien ». Le même motif
  sur `lua/plugins/snacks/picker/sources/lexique.lua` → aucune ligne.
- Complétion, config réelle, depuis `~/.config/nvim` :
  - `getcompletion("silent Lexique Sig", "cmdline")` → `{ "Signal de dérive" }` ;
  - `getcompletion("Lexique Signal de ", "cmdline")` → `{ "dérive" }`.
- `<leader>L`, config réelle, headless. Un seul mappage de chaque côté (`maparg` en `n` et en `x`),
  aucun `<leader>L` ni `<leader>fL` sur `master`.
  - Curseur sur « dérive » de « un Signal de dérive ici » → message `Signal de dérive (global) : …`.
  - `vj$<leader>L` sur « le signal / de dérive » → même message, puis retour en mode `n`.
- Picker, commande du plan (étape 4) :
  `nvim --headless -c 'LexiquePicker' -c 'lua vim.defer_fn(function() print(#Snacks.picker.get()[1]:items()) … end, 1000)'`
  → **ÉCHEC, 4 fois sur 4** : `attempt to index a nil value`, aucun picker ouvert. Voir R1.
- Picker, ouvert après le démarrage (`defer_fn` → `LexiquePicker`) :
  - depuis `~/.config/nvim` → 19 items. `lexique definitions | wc -l` → 19 aussi.
  - dans un projet à lexique local (`lexique init` + `Zorglubage`) → 20 items, le premier `global`,
    le dernier `local/Zorglubage`.
- Contrôle de R1 :
  - un picker Snacks générique ouvert par `-c` → `pickers=0` (un autre essai : segfault, rc 139) ;
  - `-c 'autocmd VimEnter * ++once LexiquePicker'` → `pickers=1`.
- `cd ~/.claude/skills/lexique && ~/.claude/.venv/bin/python -m pytest scripts/tests` → 69 passés.
- `uvx ruff check scripts` → `All checks passed!`
- `uvx --with pytest basedpyright` (depuis `skills/lexique`) → 0 errors, 0 warnings, 0 notes. Sur
  un arbre extrait de `ba7203e` (`git archive`) → 0 aussi. Aucune régression.
- `test ! -e skills/lexique/nvim/lexique.lua` → absent. Le répertoire `nvim/` est absent aussi.
- `grep -rn 'nvim/lexique.lua' skills/lexique` → aucune ligne, code 1.
- `ls .claude/implementation/todo/technical-debt-solde/ | grep lexique` → les deux dettes. Elles
  ne sont plus dans `technical-debt/`.
- `list-dir validate` sur `technical-debt-solde` → 32 éléments conformes. Sur `technical-debt` → 72
  conformes.
- Signaux 2 et 3, `git -C ~/.claude diff --stat ba7203e HEAD` → 6 fichiers : le prototype
  supprimé, `SKILL.md`, `lexique-cli.py`, `test_cli_nvim.py` et les deux dettes renommées. Les
  lignes retirées de `lexique-cli.py` et du test sont toutes de docstring. `git status` dans
  `~/.claude` → propre.
- `stylua --check`, formateur du dépôt via conform, sur les fichiers touchés → un écart dans
  `lua/cmd.lua`. `lua/cmd.lua` de `master` → propre. Voir R4.

### Conformité à l'intention

- **Critère `make test-file …` et sa couverture** : atteint, vérifié. Les 14 cas couvrent :
  - `:Lexique` ouvre le local, `:Lexique!` le global ;
  - `:Lexique signal  de dérive`, à la casse et aux espaces près, composé compris, rend trois
    morceaux `LexiqueTerme` / `LexiqueNiveau` / `LexiqueDefinition` ;
  - un terme local ;
  - un terme inconnu ;
  - l'absence de lexique local : une notification, aucun buffer.
- **Critère complétion** : atteint, vérifié en config réelle et dans le test.
- **Critère `<leader>L`** : atteint, vérifié en config réelle. Les tests appellent `at_cursor()` et
  `selection()` directement. Le mappage lui-même n'est vérifié que par mon exécution headless.
- **Critère picker** : atteint, vérifié par la variante différée (19 et 20 items, global puis
  local). `M.entries()` fait un seul appel `lexique definitions`. Le test Python
  `test_definitions_global_puis_local` passe. La commande de vérification inscrite au plan, elle,
  ne passe pas :
  - **R1** — La commande headless du plan (étape 4) échoue telle qu'écrite. L'étape 4 est pourtant
    cochée `[x]` au suivi, sur « le décompte headless du picker ». La cause est dans la commande,
    pas dans le livrable : un picker Snacks ouvert par `-c`, donc avant `VimEnter`, disparaît au
    démarrage, qu'il soit générique ou celui du lexique. Ouvert à `VimEnter`, il est là. Le critère
    tient, mais la preuve que le suivi invoque n'a pas pu être obtenue par la commande qu'il cite.
    Soit elle n'a pas été exécutée, soit son échec n'a pas été relevé. Je ne tranche pas entre les
    deux. Je retiens `RÉSERVES` et non `DÉFAVORABLE` : la commande en échec ne mesure pas le
    livrable, et une commande corrigée établit le critère.
- **Critère `make test`** : atteint, vérifié.
- **Critère `~/.claude`** : atteint, vérifié. Prototype absent, `grep` vide, deux dettes en
  `technical-debt-solde/`, déplacement et preuve dans deux commits distincts, comme le demande
  `dette.md`.
- **Hors-périmètre** : respecté.
  - Aucun surlignage dans les buffers : ni `matchadd`, ni extmark.
  - La définition s'affiche par `nvim_echo`, sans fenêtre flottante. Le picker est une décision du
    brief.
  - Aucune écriture de lexique : `:Lexique` ouvre le fichier par `:edit`, comme le demande le
    critère.
- **Signaux de dérive** : aucun matérialisé.
  1. `lua/lexique.lua` ne lit ni ne localise rien : le `grep` est vide.
  2. Le diff `~/.claude` se borne aux fichiers admis.
  3. La CLI ajoute `definitions` sans toucher les autres commandes : une branche de dispatch, et
     des retraits limités à la docstring.
- **Symptôme d'origine** : disparu. `:Lexique`, la complétion, `<leader>L` et le picker sont dans
  la configuration, et le prototype à sourcer n'existe plus.

### Qualité du code

- **R2** — `lua/lexique.lua:224`, `:234`, `:239`. Quand le motif `%f[%w]Lexique!?%s+` ne trouve
  pas le nom de la commande et que `arglead` n'est pas vide, `before` vaut `-1`. `table.concat(…,
  " ", 0)` lève alors une erreur. C'est le cas de `getcompletion("5Lexique Sig", "cmdline")` →
  `E5108: … lexique.lua:239: invalid value (nil) at index 0 in table for 'concat'`, soit une trace
  Lua sur `<Tab>` : le chiffre de portée colle au nom et défait la frontière `%f[%w]`. La commande
  n'admet pas de portée, donc l'impact est faible. Mais le repli `or ""` promet un résultat vide,
  et c'est une erreur qui sort.
  Voisin : `Lexique! Sig<Tab>` propose des termes que la commande refuse ensuite (« `!` … ne prend
  pas de terme »).
- **R3** — `lua/lexique.lua:192-201`. `at_cursor()` ignore `res.code` et `res.stderr` de `lexique
  termes`. `define()` et `entries()` les notifient. Si un lexique est illisible et qu'aucun terme
  ne couvre le curseur, l'utilisateur ne lit que « aucun terme du lexique sous le curseur » : la
  faute réelle est tue. C'est un chemin d'échec silencieux, qui contredit le régime « fautes sur
  stderr » que la CLI documente pour `termes`.
- **R4** — `lua/cmd.lua:41`. La ligne `vim.notify(…)` dépasse la largeur de `stylua` : `stylua
  --check` la reformaterait sur cinq lignes. `lua/cmd.lua` de `master` passe le même contrôle.
  C'est un écart de style introduit dans un fichier jusque-là conforme au formateur du dépôt
  (`lua/plugins/conform.lua`). Les autres fichiers nouveaux passent.

Le reste est dans le style des voisins :
- en-tête `---` et `notify` à titre, comme `lua/chantier.lua` ;
- types préfixés `Ozay.` ;
- source de picker calquée sur `harpoon.lua`.

Les liens de surbrillance survivent à un `:colorscheme` (vérifié).

### Dette induite

- **R5** — `docs/plugins/snacks.md` n'a pas bougé. Sa ligne 8 liste les pickers autonomes
  (`tabpages`, `harpoon`) sans le nouveau `sources/lexique.lua`. Sa table de touches ignore
  `<leader>fL`. `CLAUDE.md` demande de mettre à jour la doc d'un plugin sur lequel on travaille.
  Coût : le prochain qui lira ce fichier pour trouver les sources custom ne verra pas celle-ci.
  Elle n'est mentionnée que dans `CLAUDE.md` (Global Helpers).
- **R6** — La preuve de solde de `lexique-completion-sous-un-modificateur`, dans `~/.claude`,
  cite « `AE4` = `10a8193` ». Ce tag et ce commit disparaissent à l'aplatissement : `git branch
  -D` et `git tag -d` y sont prévus par `aplatissement.md`. Un fichier versionné d'un autre dépôt
  gardera donc une référence morte. Et le correctif est entré à `AE2` (`2fd17b0`), pas à `AE4`.
  La commande et la sortie consignées restent valides et suffisent à établir le solde. Seule la
  référence de commit est éphémère.
- Léger, sans numéro : `define()` et `entries()` dupliquent la même boucle, à savoir parser les
  lignes puis notifier le stderr selon `code` (`:106-115` et `:126-134`). Le coût est faible tant
  qu'il n'y a que deux appelants.

### Bloquants

Aucun. R1 à R6 sont à trancher par l'utilisateur avant la clôture : clore avec, ou traiter
d'abord.

## 2026-09-27 — clôture — `7ab2063`

**Verdict** : RÉSERVES

Diff audité : `git diff master...integrer-commande-lexique`, soit 8 fichiers hors `.claude/`, +546
−1. Delta depuis l'audit précédent : `git diff 06bdc31 7ab2063`, l'étape 6. S'y ajoute la part
`~/.claude` du chantier, `git -C ~/.claude diff ba7203e HEAD`, avec les commits `6654d48`,
`1961188`, `43e4a90` et `e76d24b` (nouveau).

Le brief est présent et validé. Le suivi concorde avec lui. L'étape 6 a été ajoutée après l'audit
`06bdc31` et datée au journal : c'est un périmètre légitime.

Les constats de cette section sont numérotés à partir de **R7**. R1 à R6 restent ceux de l'audit
`06bdc31`, ci-dessus.

### Vérifications exécutées

- `make test-file FILE=tests/lexique/test_lexique.lua` → 17 cas, `Fails (0) and Notes (0)`.
- `make test` → 77 cas, 5 groupes, `Fails (0) and Notes (0)`. 77 = 60 existants + 17 lexique.
- Signal 1 : le `grep` du plan (étape 2) sur `lua/lexique.lua` rend « signal 1 : rien ». Le même
  motif sur `sources/lexique.lua` ne rend aucune ligne (rc 1).
- `stylua --check` sur les 6 fichiers Lua touchés (`lua/lexique.lua`, `lua/cmd.lua`,
  `lua/mappings.lua`, `picker/init.lua`, `sources/lexique.lua`, le test) → rc 0.
- Complétion, config réelle, depuis `~/.config/nvim` :
  - `silent Lexique Sig` → `{ "Signal de dérive" }` ;
  - `Lexique Signal de ` → `{ "dérive" }` ;
  - `5Lexique Sig` → `{ "Signal de dérive" }` : plus de trace Lua ;
  - `Lexique! Sig` → `{}` ;
  - `Lexique Zzz` → `{}` ;
  - `Lexique ` → les 19 termes globaux.
- La commande de preuve de la dette `lexique-completion-sous-un-modificateur`, exécutée telle
  qu'écrite, rend `{ "Signal de dérive" }`.
- Picker, avec la commande corrigée du plan (étape 4) : 3 fois sur 3, la sortie est `19` suivi
  d'une ligne de log ClaudeCode, rc 0. `lexique definitions | wc -l` rend 19 aussi.
- Picker dans un projet à lexique local (`lexique init --projet` + `Zorglubage`) : 20 items. Le
  premier est `global`, le dernier `local/Zorglubage`.
- `<leader>L` en config réelle, headless, par `nvim_feedkeys(" L")` avec leader = espace :
  - `maparg` : un mappage en `n` (`mappings.lua:23`) et un en `x` (`mappings.lua:26`) ;
  - curseur sur « dérive » de « un Signal de dérive ici » → `Signal de dérive{LexiqueTerme}
    (global) : {LexiqueNiveau}Indice…{LexiqueDefinition}` ;
  - `vj$ L` sur « le signal / de dérive » → même définition, puis retour en mode `n`.
- `<leader>L` dans un projet dont le lexique local n'est pas en UTF-8, curseur sur « dérive » :
  la définition s'affiche, mais la même faute est notifiée **deux fois**, d'abord au niveau 4
  (ERROR) puis au niveau 3 (WARN). Voir R7.
- `~/.claude/skills/lexique` :
  - `pytest scripts/tests` → 69 passés ;
  - `uvx ruff check scripts` → `All checks passed!` ;
  - `uvx --with pytest basedpyright` → 0 errors, 0 warnings, 0 notes. Sans erreur sur HEAD, une
    régression est exclue : la comparaison à la base est sans objet.
- `test ! -e skills/lexique/nvim/lexique.lua` → absent. Le répertoire `nvim/` a disparu aussi.
- `grep -rn 'nvim/lexique.lua' skills/lexique` → aucune ligne, rc 1.
- `ls technical-debt-solde/ | grep lexique` → les deux dettes. Elles ne sont plus dans
  `technical-debt/`, qui ne garde que deux autres dettes `lexique-*`, étrangères au chantier.
- `list-dir validate` → 32 éléments conformes dans `technical-debt-solde`, 72 dans
  `technical-debt`.
- Signaux 2 et 3 : `git -C ~/.claude diff --stat ba7203e HEAD` → 6 fichiers, les mêmes qu'à
  l'audit précédent. `e76d24b` ne touche qu'une dette soldée, et `git diff --stat 43e4a90 HEAD`
  le confirme. Dans `lexique-cli.py` et le test, les seules lignes retirées sont de docstring.
  `git status` de `~/.claude` → propre.
- Hors-périmètre : `grep` de `matchadd|extmark|nvim_open_win|nvim_buf_set_lines|writefile` sur
  les deux modules → rien (rc 1).

### Conformité à l'intention

- **Critère `make test-file …` et sa couverture** : atteint, vérifié. Les 17 cas couvrent ce que
  le critère énumère :
  - `:Lexique` ouvre le local, `:Lexique!` le global ;
  - la définition à la casse et aux espaces près, composés compris, en trois groupes ;
  - l'absence de lexique local se dit sans rien ouvrir.
- **Critère complétion** : atteint, vérifié en config réelle et dans le test.
- **Critère `<leader>L`** : atteint, vérifié en config réelle, par la touche elle-même, en `n`
  comme en `x`.
- **Critère picker** : atteint, vérifié. Il affiche 19 termes, ou 20 avec un lexique local, global
  puis local. `M.entries()` fait un seul appel `lexique definitions`, couvert par
  `test_cli_nvim.py`.
- **Critère `make test`** : atteint, vérifié.
- **Critère `~/.claude`** : atteint, vérifié.
- **Hors-périmètre** : respecté. Le diff n'ajoute ni surlignage, ni fenêtre flottante, ni
  écriture de lexique.
- **Signaux de dérive** : aucun ne s'est matérialisé.
  1. Le `grep` du signal 1 est vide.
  2. Le diff `~/.claude` s'en tient aux fichiers admis.
  3. La CLI n'ajoute qu'une commande.
- **Symptôme d'origine** : disparu.

Sort des réserves de l'audit `06bdc31` :
- **R1**, la commande du picker : levée. Le plan est corrigé (lancement à `VimEnter`), la décision
  est au journal, et la commande passe (19).
- **R2**, la complétion sur `5Lexique Sig` : levée. `%f[%a]` remplace `%f[%w]`, `typed == nil`
  rend `{}`, et `!` rend `{}`. Deux tests couvrent ces cas.
- **R3**, la faute tue sous le curseur : levée pour le cas « aucun terme sous le curseur », qu'un
  test couvre. Le correctif introduit R7.
- **R4**, `stylua` : levée. `lua/cmd.lua` repasse `stylua --check`.
- **R5**, la doc Snacks : levée. `docs/plugins/snacks.md` ajoute la source, `<leader>fL`,
  `:LexiquePicker`, une gotcha headless et une entrée de changelog.
- **R6**, la référence éphémère : levée. `e76d24b` remplace `AE4` = `10a8193` par
  `~/.config/nvim/lua/lexique.lua`, `M.complete`. L'autre dette cite `1961188`, un commit du
  `master` de `~/.claude` qui survit à l'aplatissement.
- La duplication `define()` / `entries()`, notée sans numéro, est résorbée par `report()`.

### Qualité du code

- **R7** — `lua/lexique.lua:200` et `:121`. Le correctif de R3 fait notifier la faute par
  `at_cursor()`, qui appelle ensuite `define()`, qui la notifie à son tour. Quand un terme couvre
  le curseur et qu'un niveau est illisible, la même faute sort donc deux fois :
  - la première en ERROR, car `termes` sort en code 1 ;
  - la seconde en WARN, car `definition` sort en code 0 avec du stderr.

  Constaté en config réelle. Le test ajouté ne couvre que le cas où aucun terme n'est sous le
  curseur, où la faute ne sort qu'une fois. L'impact est faible : un doublon de notification, avec
  deux niveaux pour une même cause. C'est pourtant un défaut que le chantier introduit dans un
  chemin d'échec. Il faudrait ne notifier qu'au dernier appel, ou taire le stderr de `termes`
  quand un terme est trouvé.

Pour le reste, rien à signaler :
- `report()` suit le style du module (`---` et `notify` à titre) ;
- les tests suivent le style des cas voisins.

### Dette induite

- **R8** — La commande du picker, dans le plan (étape 4) et dans `docs/plugins/snacks.md`, se
  lit par `tail -1`. Sa dernière ligne colle le décompte au log de ClaudeCode :
  `19[ClaudeCode] [init] [INFO] …`. Le « > 0 » se juge donc à l'œil, pas par une comparaison.
  C'est une fragilité de même nature que celle qui a produit R1 : une commande de preuve dont la
  sortie ne dit pas nettement si elle passe. Coût futur : le premier plugin qui changera l'ordre
  des messages de sortie rendra cette commande illisible sans qu'elle échoue.

### Bloquants

Aucun. R7 et R8 sont mineurs : l'utilisateur tranche entre clore avec eux, en les portant au
registre de dette, et les traiter d'abord.

## 2026-09-27 — clôture — `a329898`

**Verdict** : RÉSERVES

Diff audité : `git diff master...integrer-commande-lexique`, soit 12 fichiers, dont 8 hors
`.claude/`. Delta depuis l'audit précédent : `git diff 7ab2063 a329898`, l'étape 7, qui touche
`lua/lexique.lua` (+3 −2) et `tests/lexique/test_lexique.lua` (+10). S'y ajoute la part
`~/.claude` du chantier, `git -C ~/.claude diff ba7203e HEAD`. Elle n'a pas bougé depuis
`e76d24b`.

Le brief est présent et validé. Le suivi concorde avec lui. L'étape 7 a été ajoutée après l'audit
`7ab2063` et datée au journal : c'est un périmètre légitime. Le journal consigne aussi que R8 est
laissée au registre de dette, sur décision de l'utilisateur.

Les constats nouveaux sont numérotés à partir de **R9**. R1 à R8 restent ceux des audits
précédents.

### Vérifications exécutées

- `make test-file FILE=tests/lexique/test_lexique.lua` → 18 cas, `Fails (0) and Notes (0)`, rc 0.
- `make test` → 78 cas, 5 groupes, `Fails (0) and Notes (0)`. 78 = 60 existants + 18 lexique.
- Signal 1 : le `grep` du plan (étape 2) sur `lua/lexique.lua` rend « signal 1 : rien ». Le même
  motif sur `sources/lexique.lua` ne rend aucune ligne (rc 1).
- Hors-périmètre : le `grep` de `matchadd|extmark|nvim_open_win|nvim_buf_set_lines|writefile`
  sur les deux modules ne rend rien (rc 1).
- `stylua --check` (binaire mason, absent du `PATH`) sur les 6 fichiers Lua touchés → rc 0.
- Complétion, config réelle, depuis `~/.config/nvim`, à `VimEnter` :
  - `silent Lexique Sig` → `{ "Signal de dérive" }` ;
  - `Lexique Signal de ` → `{ "dérive" }` ;
  - `5Lexique Sig` → `{ "Signal de dérive" }` ;
  - `Lexique! Sig` → `{}`.
- La commande de preuve de la dette soldée `lexique-completion-sous-un-modificateur`, exécutée
  telle qu'écrite, rend `{ "Signal de dérive" }`.
- `<leader>L`, config réelle, headless, par `nvim_feedkeys` de la touche elle-même :
  - en `n`, curseur sur « dérive » de « un Signal de dérive ici » → `Signal de
    dérive{LexiqueTerme} (global) : {LexiqueNiveau}Indice…`, puis mode `n` ;
  - en `x`, `vj$<leader>L` sur « le signal / de dérive » → même définition, puis mode `n` ;
  - dans un projet à lexique local illisible (pas en UTF-8), curseur sur « dérive » → la
    définition, et **une seule** notification de la faute, au niveau 3 (WARN) ;
  - même projet, curseur sur « ici » → la faute au niveau 4 (ERROR), puis « aucun terme du lexique
    sous le curseur ».
- Picker, commande du plan (étape 4), 3 fois → `19[ClaudeCode] [init] [INFO] …`, rc 0.
  `lexique definitions | wc -l` → 19.
- Picker dans un projet à lexique local (`lexique init --projet` + `Zorglubage`) → 20 items. Le
  premier est `global`, le dernier `local/Zorglubage`.
- `~/.claude/skills/lexique` :
  - `pytest scripts/tests` → 69 passés ;
  - `uvx ruff check scripts` → `All checks passed!` ;
  - `uvx --with pytest basedpyright` → 0 errors, 0 warnings, 0 notes. Sans erreur sur HEAD, une
    régression est exclue : la comparaison à la base est sans objet.
- `test ! -e skills/lexique/nvim/lexique.lua` → absent. Le répertoire `nvim/` a disparu aussi.
- `grep -rn 'nvim/lexique.lua' skills/lexique` → aucune ligne, rc 1.
- `ls technical-debt-solde/ | grep lexique` → les deux dettes. `technical-debt/` ne garde que
  `lexique-blocs-de-code-imbriques` et `lexique-home-versionne-par-git`, étrangères au chantier.
- `list-dir validate` → 32 éléments conformes dans `technical-debt-solde`, 72 dans
  `technical-debt`.
- Signaux 2 et 3 : `git -C ~/.claude diff --stat ba7203e HEAD` → 6 fichiers, les mêmes qu'aux
  audits précédents. Les lignes retirées de `lexique-cli.py` et de `test_cli_nvim.py` sont toutes
  de docstring. `git status` de `~/.claude` → propre.

### Conformité à l'intention

- **Critère `make test-file …` et sa couverture** : atteint, vérifié. Les 18 cas couvrent ce que
  le critère énumère :
  - `:Lexique` ouvre le local, `:Lexique!` le global ;
  - la définition à la casse et aux espaces près, composés compris, en trois groupes ;
  - l'absence de lexique local se dit sans rien ouvrir.
- **Critère complétion** : atteint, vérifié en config réelle et dans le test.
- **Critère `<leader>L`** : atteint, vérifié en config réelle par la touche, en `n` comme en `x`.
  Le mode `x` au lieu de `v` est une décision datée du journal.
- **Critère picker** : atteint, vérifié. Il affiche 19 termes, ou 20 avec un lexique local, global
  puis local. `M.entries()` fait un seul appel `lexique definitions`, couvert par
  `test_cli_nvim.py`.
- **Critère `make test`** : atteint, vérifié.
- **Critère `~/.claude`** : atteint, vérifié.
- **Hors-périmètre** : respecté. Le diff n'ajoute ni surlignage, ni fenêtre flottante, ni
  écriture de lexique.
- **Signaux de dérive** : aucun ne s'est matérialisé.
  1. Le `grep` du signal 1 est vide.
  2. Le diff `~/.claude` s'en tient aux fichiers admis.
  3. La CLI n'ajoute qu'une commande.
- **Symptôme d'origine** : disparu.

Sort des réserves de l'audit `7ab2063` :
- **R7**, la faute notifiée deux fois : levée. `report(res)` ne sort plus dans `at_cursor()` que
  si aucun terme ne couvre le curseur. Quand un terme est trouvé, c'est `define()` qui notifie.
  Le nouveau cas « sur un terme, un lexique illisible ne se dit qu'une fois » le couvre, et je l'ai
  constaté en config réelle.
  Effet de bord, sans défaut : dans ce cas, la faute sort en WARN, régime de `definition` (code 0),
  et non plus en ERROR. C'est le régime que la CLI documente pour cette commande.
- **R8**, la commande du picker lue par `tail -1` : **ouverte**. Elle est inchangée, dans le plan
  (étape 4) comme dans `docs/plugins/snacks.md`, et sa sortie colle toujours le décompte au log de
  ClaudeCode. Le journal la destine au registre de dette à la clôture. Elle reste une réserve
  jusqu'à ce que l'entrée soit écrite au registre.

### Qualité du code

- **R9** — `lua/lexique.lua:170` et `:182`. `covering()` cherche dans `vim.fn.tolower(line)` mais
  compare la position trouvée à la colonne du curseur, prise dans la ligne d'origine. Or
  `tolower` ne garde pas toujours la longueur en octets : « ẞ » (3 octets) devient « ß » (2), et
  « Ⱥ » (2) devient « ⱥ » (3). Après un tel caractère, les deux décalages divergent. Constaté :
  - sur « ẞ Signal de dérive », curseur sur le dernier octet de « dérive », `at_cursor()` rend
    « aucun terme du lexique sous le curseur » ;
  - sur « X Signal de dérive », même position, il rend la définition.

  L'impact est marginal : il faut l'un de ces rares caractères plus tôt sur la même ligne, et
  l'erreur n'est que d'un octet par caractère, au bord du terme. Aucun critère ne vise ce cas. Je
  le signale comme cas limite non couvert, pas comme défaut de correction.

Pour le reste, rien à signaler. Le commentaire ajouté par l'étape 7 dit pourquoi la faute n'est
notifiée qu'à cet endroit, dans le style du module. Le cas de test suit celui du cas voisin.

### Dette induite

Rien de nouveau. R8 reste ouverte (voir plus haut).

### Bloquants

Aucun. Deux réserves restent ouvertes, et aucune n'interdit la clôture :
- R8 : à porter au registre de dette, comme le journal le prévoit ;
- R9 : à trancher par l'utilisateur, soit la porter au registre, soit l'accepter.
