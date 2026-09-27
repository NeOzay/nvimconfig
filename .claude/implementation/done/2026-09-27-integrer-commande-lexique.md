+++
gabarit = "suivi"
slug = "integrer-commande-lexique"
titre = "Intégrer la commande `:Lexique` à la configuration Neovim"
branche = "integrer-commande-lexique"
base = "master"
statut = "terminé"
session = 2
lettre = "A"
execution = "direct"
plan = ".claude/implementation/done/2026-09-27-integrer-commande-lexique.plan.md"
brief = ".claude/implementation/done/2026-09-27-integrer-commande-lexique.brief.md"
audit = ".claude/implementation/done/2026-09-27-integrer-commande-lexique.audit.md"
road-map = "integrer-commande-lexique"
"créé" = 2026-09-27
maj = 2026-09-27
+++

## Objectif et périmètre

**Symptôme** : obtenir le sens d'un terme du lexique en relisant un diff oblige à quitter Neovim
ou à sourcer à la main un prototype déclaré temporaire.

**But** : `:Lexique` fait partie de la configuration — ouvrir le lexique local ou global, afficher
une définition, compléter les termes composés — et le prototype disparaît de `~/.claude`.

**Critères de réussite** :
- `make test-file FILE=tests/lexique/test_lexique.lua` passe, et couvre : `:Lexique` ouvre le
  local, `:Lexique!` le global, `:Lexique <terme>` affiche la définition à la casse et aux espaces
  près, composés compris, avec ses parties colorées ; l'absence de lexique local se dit sans rien
  ouvrir.
- `getcompletion("silent Lexique Sig", "cmdline")` → `{ "Signal de dérive" }`, et
  `getcompletion("Lexique Signal de ", "cmdline")` contient `"dérive"`.
- `<leader>L` donne la définition du terme qui couvre le curseur (« Signal de dérive », curseur
  sur « dérive ») et, en mode visuel, de la sélection.
- Le picker Snacks liste tous les termes, global puis local, avec leur définition, en un seul
  appel à la nouvelle sortie de `lexique`, couverte par un test dans `~/.claude`.
- `make test` passe (aucune régression des tests existants).
- Dans `~/.claude` : `test ! -e skills/lexique/nvim/lexique.lua` et
  `grep -rn 'nvim/lexique.lua' skills/lexique` → rien ; les deux dettes sont dans
  `technical-debt-solde/`.

**Hors-périmètre** :
- Surligner les termes du lexique dans les buffers.
- Afficher la définition dans une fenêtre flottante.
- Modifier un lexique depuis Neovim (ajouter, changer ou retirer un terme).

**Signaux de dérive** :
- `lua/lexique.lua` lit un `LEXIQUE.md` ou construit un chemin — `io.open`, `readfile`,
  `fs_stat`, `LEXIQUE` hors commentaires : Neovim refait le travail de la CLI.
- Le diff dans `~/.claude` déborde du prototype, de la sortie de la CLI pour le picker (code,
  test, `SKILL.md`), de la docstring de `lexique-cli.py` et des deux dettes.
- Le diff de la CLI change le comportement d'une commande existante (`init`, `liste`, `session`,
  `chemin`, `termes`, `definition`) au lieu d'en ajouter une.

## Étapes

- [x] 1. CLI : `lexique definitions` (dans `~/.claude`) — `skills/lexique/scripts/lexique-cli.py`, `skills/lexique/scripts/tests/test_cli_nvim.py`, `skills/lexique/SKILL.md` — vérif: `cd /home/debian/.claude/skills/lexique && /home/debian/.claude/.venv/bin/python -m pytest scripts/tests && uvx ruff check scripts && uvx --with pytest basedpyright`
- [x] 2. Module `lua/lexique.lua` et `:Lexique` — `lua/lexique.lua`, `lua/cmd.lua`, `tests/lexique/test_lexique.lua`, `CLAUDE.md` — vérif: `make test-file FILE=tests/lexique/test_lexique.lua` et le `grep` du signal 1 (plan, étape 2)
- [x] 3. Terme sous le curseur et `<leader>L` — `lua/lexique.lua`, `lua/mappings.lua`, `tests/lexique/test_lexique.lua` — vérif: `make test-file FILE=tests/lexique/test_lexique.lua`
- [x] 4. Picker Snacks des termes — `lua/plugins/snacks/picker/sources/lexique.lua`, `lua/lexique.lua`, `lua/plugins/snacks/picker/init.lua`, `lua/cmd.lua`, `tests/lexique/test_lexique.lua`, `CLAUDE.md` — vérif: `make test-file FILE=tests/lexique/test_lexique.lua` et le décompte headless du picker (plan, étape 4)
- [x] 5. Nettoyage de `~/.claude` (avant aplatissement) — `skills/lexique/nvim/lexique.lua`, `skills/lexique/SKILL.md`, `skills/lexique/scripts/lexique-cli.py`, deux dettes vers `technical-debt-solde/` — vérif: commandes du plan, étape 5
- [x] 6. Réserves R2 à R6 de l'audit de clôture (ajoutée après l'audit) — `lua/lexique.lua`, `lua/cmd.lua`, `tests/lexique/test_lexique.lua`, `docs/plugins/snacks.md`, dette soldée `lexique-completion-sous-un-modificateur` de `~/.claude` — vérif: `make test`, `stylua --check` des fichiers touchés, commande headless corrigée du picker (plan, étape 4)
- [x] 7. Réserve R7 du second audit (ajoutée après l'audit) — `lua/lexique.lua`, `tests/lexique/test_lexique.lua` — vérif: `make test-file FILE=tests/lexique/test_lexique.lua`, `make test`

## État courant

**Prochaine action** : aplatissement sur `master` (`commit-chantier cloture`).

**Vérification** : `make test` ; le `grep` du signal 1 (plan, étape 2) ;
`git -C ~/.claude diff --stat ba7203e HEAD` limité aux fichiers des étapes 1 et 5.

**Dernier audit** : `a329898` — RÉSERVES — 2026-09-27

**Notes** : les étapes 1 et 5 se commitent dans `~/.claude`, chacune à part et avec accord ; le
reste sur la branche `integrer-commande-lexique` de ce dépôt.

## Journal de décisions

- **2026-09-27** — `~/.claude` part de `ba7203e` : base des contrôles des signaux 2 et 3.
  *Pourquoi* : `git show --stat` ne couvre qu'un commit. *Rejeté* : contrôle commit par commit.
- **2026-09-27** — Picker ouvert par `<leader>fL` et `:LexiquePicker` ; `<CR>` affiche la
  définition colorée. *Pourquoi* : choix de l'utilisateur en plan. *Rejeté* : insérer le terme,
  ouvrir le lexique à sa ligne (lecture de `LEXIQUE.md`, signal 1).
- **2026-09-27** — `<leader>L` en modes `n` et `x`, pas `v`. *Pourquoi* : `v` ajoute le mode
  Select, où `<leader>` n'a pas de sens (réserve Q1 ratifiée). *Rejeté* : `v` à la lettre du brief.
- **2026-09-27** — Un terme sous le curseur ne compte que borné par des non-lettres, tout octet
  non ASCII valant lettre. *Pourquoi* : « Base » ne doit pas sortir de « Database », et `%w`
  ignore « é ». *Rejeté* : `%f[%w]`, aveugle aux accents.
- **2026-09-27** — Trois audits de clôture, tous RÉSERVES : `06bdc31` (R1-R6, traitées en étape 6),
  `7ab2063` (R7 traitée en étape 7), `a329898` (R8, R9 versées au registre de dette).
  *Pourquoi* : choix de l'utilisateur à chaque verdict. *Rejeté* : un quatrième audit pour R8-R9.
- **2026-09-27** — La vérification headless du picker se fait à `VimEnter` (R1, plan corrigé).
  *Pourquoi* : un picker ouvert par `-c` disparaît au démarrage. *Rejeté* : `-c 'LexiquePicker'`.
