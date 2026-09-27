+++
gabarit = "brief"
slug = "integrer-commande-lexique"
titre = "Intégrer la commande `:Lexique` à la configuration Neovim"
statut = "validé"
execution = "direct"
"créé" = 2026-09-27
+++

## Intention

**Symptôme** : obtenir le sens d'un terme du lexique en relisant un diff oblige à quitter Neovim
ou à sourcer à la main un prototype déclaré temporaire.
**But** : `:Lexique` fait partie de la configuration — ouvrir le lexique local ou global, afficher
une définition, compléter les termes composés — et le prototype disparaît de `~/.claude`.

## Critères de réussite

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

## Hors-périmètre

- Surligner les termes du lexique dans les buffers.
- Afficher la définition dans une fenêtre flottante.
- Modifier un lexique depuis Neovim (ajouter, changer ou retirer un terme).

## Signaux de dérive

- `lua/lexique.lua` lit un `LEXIQUE.md` ou construit un chemin — `io.open`, `readfile`,
  `fs_stat`, `LEXIQUE` hors commentaires : Neovim refait le travail de la CLI (dit ; dépôt:
  `~/.claude/.claude/implementation/done/2026-09-27-lexique-nvim.plan.md`, signal 2)
- Le diff dans `~/.claude` déborde du prototype, de la sortie de la CLI pour le picker (code,
  test, `SKILL.md`), de la docstring de `lexique-cli.py` et des deux dettes (dit)
- Le diff de la CLI change le comportement d'une commande existante (`init`, `liste`, `session`,
  `chemin`, `termes`, `definition`) au lieu d'en ajouter une (dit)

## Contraintes connues de l'utilisateur

- **Existant** : Neovim ne lit aucun `LEXIQUE.md` ; chemins, termes et définitions viennent de la
  commande `lexique` (`chemin [--global]`, `termes`, `definition -- <terme>`) lancée dans le cwd
  (dépôt: `~/.claude/skills/lexique/nvim/lexique.lua`, entrée road-map `integrer-commande-lexique`)
- **Réutiliser** : module `lua/lexique.lua` sur le modèle de `lua/chantier.lua`, déclaré dans
  `lua/cmd.lua` (dépôt: `007bc78`, entrée road-map)
- **Décision** : projet = racine git du cwd, correspondance à la casse et aux espaces près,
  lexique malformé qui sert ses lignes valides — tranché par le chantier `lexique-nvim`
  (dépôt: `~/.claude/.claude/implementation/done/2026-09-27-lexique-nvim.md`)
- **Existant** : la complétion ne propose rien derrière un modificateur
  (`getcompletion("silent Lexique Sig", "cmdline")` → `{}`) ; à corriger dans la version intégrée
  (dépôt: dette `lexique-completion-sous-un-modificateur` de `~/.claude`)
- **Existant** : `skills/lexique/SKILL.md` et la docstring de `scripts/lexique-cli.py` citent le
  prototype ; à réécrire à sa suppression, vérifié par `grep -rn 'nvim/lexique.lua'
  skills/lexique` → rien (dépôt: dette `lexique-references-au-lua-temporaire` de `~/.claude`)
- **Décision** : le mappage qui donne la définition du terme sous le curseur fait partie du
  chantier, et prend aussi en charge la sélection en mode visuel (dit)
- **Décision** : tests en mini.test, sous `tests/` (dit)
- **Décision** : la partie `~/.claude` — suppression du prototype, réécriture de `SKILL.md` et de
  la docstring de `lexique-cli.py`, solde des deux dettes — est l'étape finale du chantier, avant
  l'aplatissement, avec son propre commit dans `~/.claude` (dit)
- **Décision** : ajouts à l'entrée road-map — le message de définition colore ses parties
  (terme, niveau, définition), et un picker Snacks liste tous les termes avec leur définition (dit)
- **Décision** : le picker tire les définitions d'une nouvelle sortie de la CLI `lexique`
  (`niveau\tterme\tdéfinition` pour tous les termes), ajoutée dans `~/.claude` avant le picker ;
  rejeté : un appel `definition` par terme (dit)
- **Décision** : en mode normal, le mappage cherche le terme dont le texte couvre le curseur dans
  la ligne ; rejeté : `<cword>` seul (dit)
- **Décision** : mappage sur `<leader>L`, en modes n et v (dit)

## Incertitudes à lever en plan

— aucune
