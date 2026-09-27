# Plan — integrer-commande-lexique

Brief : `.claude/implementation/integrer-commande-lexique.brief.md` (validé). Entrée road-map :
`integrer-commande-lexique`.

## Context

Pour obtenir le sens d'un terme en relisant un diff, il faut aujourd'hui quitter Neovim ou sourcer
à la main `~/.claude/skills/lexique/nvim/lexique.lua`, un prototype déclaré temporaire. Le chantier
fait entrer `:Lexique` dans la configuration (module `lua/lexique.lua`), y ajoute un message coloré,
un mappage `<leader>L` (terme sous le curseur / sélection) et un picker Snacks, puis retire le
prototype de `~/.claude`.

Rappels du brief :
- **Critères** : `make test-file FILE=tests/lexique/test_lexique.lua` ; complétion derrière un
  modificateur (`getcompletion("silent Lexique Sig", "cmdline")` → `{ "Signal de dérive" }`) ;
  `<leader>L` sur « dérive » de « Signal de dérive » ; picker global puis local en un appel ;
  `make test` sans régression ; prototype absent et `grep -rn 'nvim/lexique.lua' skills/lexique`
  vide dans `~/.claude`, deux dettes en `technical-debt-solde/`.
- **Hors-périmètre** : surlignage des termes dans les buffers, fenêtre flottante, modification
  d'un lexique depuis Neovim.
- **Signaux de dérive** : (1) `lua/lexique.lua` lit un `LEXIQUE.md` ou construit un chemin ;
  (2) diff `~/.claude` hors prototype / sortie CLI du picker (code, test, `SKILL.md`) / docstring /
  deux dettes ; (3) la CLI change une commande existante au lieu d'en ajouter une.
- **Incertitudes** : aucune.

Décisions prises en plan (dit) : le picker s'ouvre par `<leader>fL` **et** `:LexiquePicker` ;
`<CR>` y affiche la définition colorée et ferme le picker.

## Réutilisé

- Prototype `~/.claude/skills/lexique/nvim/lexique.lua` : `run`, `open`, `define`, `words`,
  `normalize`, `complete` — repris, pas réécrit.
- Modèle de module : `lua/chantier.lua` (`notify` à titre, `local M`), déclaré dans `lua/cmd.lua`.
- Picker : motif de `lua/plugins/snacks/picker/sources/harpoon.lua` (fonction retournée,
  `Snacks.picker.pick` avec `finder`/`format`/`confirm`), guide
  `docs/plugins/snacks-picker-custom.md`, touches `<leader>f…` dans
  `lua/plugins/snacks/picker/init.lua`.
- CLI : `servir()` / `_termes()` de `lexique-cli.py` ; tests `tests/test_cli_nvim.py` (`_cli`,
  fixture `ecrire`).
- Tests Neovim : `tests/minimal_init.lua`, `Makefile` (`make test`, `make test-file`).

## Étapes

### 1. CLI : `lexique definitions` — dans `~/.claude`

Fichiers : `skills/lexique/scripts/lexique-cli.py`, `skills/lexique/scripts/tests/test_cli_nvim.py`,
`skills/lexique/SKILL.md` (description du front matter, ligne 6 ; section « La commande » et son
régime d'échec).

- Nouvelle sous-commande `definitions [--projet DIR]` : une ligne
  `niveau\tterme\tdéfinition` par terme, global puis local, via `servir()` ; même régime que
  `termes` (0, fautes sur stderr ; 1 si un niveau illisible, l'autre servi).
- Docstring : « six » → « sept » commandes, `definitions` rejoint `chemin`, `termes`,
  `definition` (la référence au prototype reste jusqu'à l'étape 5).
- Aucune autre commande touchée : le dispatch de `main()` n'ajoute qu'une branche.
- Tests : global puis local, ligne fautive servie à part (sur le modèle des tests `termes`).

Vérif :
```bash
cd /home/debian/.claude/skills/lexique && /home/debian/.claude/.venv/bin/python -m pytest scripts/tests && uvx ruff check scripts && uvx --with pytest basedpyright
git -C /home/debian/.claude diff --stat   # seuls les 3 fichiers ci-dessus
git -C /home/debian/.claude diff -U0 skills/lexique/scripts/lexique-cli.py | grep '^-[^-]'   # rien hors docstring
```
Commit séparé dans `~/.claude` (accord explicite), avant l'étape 4 qui en dépend.

### 2. Module `lua/lexique.lua` et `:Lexique`

Fichiers : `lua/lexique.lua` (nouveau), `lua/cmd.lua`, `tests/lexique/test_lexique.lua` (nouveau),
`CLAUDE.md` (Global Helpers, ligne à côté de `:Suivi`).

- Port du prototype en module `M` : `M.open(bang)`, `M.define(terme)`, `M.complete(arglead,
  cmdline)` ; déclaration de `:Lexique` dans `lua/cmd.lua` (callbacks en `require("lexique")`).
- **Message coloré** : `define` affiche chaque correspondance par `nvim_echo` en trois morceaux —
  terme `LexiqueTerme`, `(niveau)` `LexiqueNiveau`, définition `LexiqueDefinition` — liens
  `default = true` posés au chargement du module (`Title`, `Comment`, `Normal`). Isoler l'affichage
  d'une entrée `{ niveau, terme, definition }` en `M.echo(entry)` : le picker le réutilise.
- **Complétion sous un modificateur** : le texte tapé s'isole à partir de la position du nom
  `Lexique` dans la ligne (motif ancré sur le mot `Lexique!?` suivi d'espaces), non du début.
- En-tête du module sans mention « temporaire » ; aucune lecture de fichier (signal 1).
- Tests mini.test en enfant Neovim (`MiniTest.new_child_neovim`), démarré avec
  `tests/minimal_init.lua` puis `dofile("lua/cmd.lua")` pour déclarer les commandes, `cwd` dans un projet temporaire
  posé par `lexique init --projet` + une ligne `Zorglubage` ; CLI réelle sur le `PATH`, lexique
  global réel (comme les vérifications du prototype) :
  `:Lexique` ouvre le local ; hors lexique local, message et rien d'ouvert ; `:Lexique!` ouvre le
  global ; `:Lexique signal  de dérive` affiche le terme avec ses trois groupes (`nvim_echo`
  intercepté dans l'enfant : seuls les morceaux passés disent les groupes) ; complétion `Lexique Signal de ` → `dérive`,
  `silent Lexique Sig` → `Signal de dérive`, `Lexique Zorg` → `Zorglubage`.

Vérif :
```bash
make test-file FILE=tests/lexique/test_lexique.lua
grep -nE 'io\.open|readfile|fs_stat|fs_open|LEXIQUE|joinpath|stdpath|fs\.normalize|"/' lua/lexique.lua | grep -vE '^[0-9]+:\s*--' ; test $? -eq 1 && echo "signal 1 : rien"
```

### 3. Terme sous le curseur et `<leader>L`

Fichiers : `lua/lexique.lua`, `lua/mappings.lua`, `tests/lexique/test_lexique.lua`.

- `M.at_cursor()` : lance `lexique termes`, cherche dans la ligne courante les occurrences de
  chaque terme (casse et espaces près, comme `normalize`) et retient le plus long qui couvre la
  colonne du curseur ; aucun → notification, rien d'autre. Puis `M.define(terme)`.
- `M.selection()` : texte de la sélection (`vim.fn.getregion`, lignes jointes par une espace),
  puis `M.define`.
- `lua/mappings.lua` : `<leader>L` en `n` → `at_cursor`, en `x` → `selection`.
- Tests : ligne « un Signal de dérive ici », curseur sur « dérive » → terme `Signal de dérive` ;
  curseur hors terme → rien affiché ; sélection « signal de dérive » → définition.

Vérif : `make test-file FILE=tests/lexique/test_lexique.lua`

### 4. Picker Snacks des termes

Fichiers : `lua/plugins/snacks/picker/sources/lexique.lua` (nouveau), `lua/lexique.lua`,
`lua/plugins/snacks/picker/init.lua` (`<leader>fL`), `lua/cmd.lua` (`:LexiquePicker`),
`tests/lexique/test_lexique.lua`, `CLAUDE.md`.

- `M.entries()` : un appel `lexique definitions`, parsé en `{ niveau, terme, definition }` ;
  stderr en notification, comme `define`.
- Source : items `text = terme .. " " .. definition` (fuzzy sur les deux), `format` terme /
  niveau / définition avec les groupes de l'étape 2, pas de preview fichier ; `confirm` ferme le
  picker et appelle `M.echo(item.entry)`.
- Tests : `M.entries()` rend `Zorglubage` au niveau `local` après les termes globaux.

Vérif :
```bash
make test-file FILE=tests/lexique/test_lexique.lua
nvim --headless -c 'autocmd VimEnter * ++once LexiquePicker' -c 'lua vim.defer_fn(function() print(#Snacks.picker.get()[1]:items()) vim.cmd("qa!") end, 1500)' 2>&1 | tail -1   # > 0 (à VimEnter : un picker ouvert par -c disparaît au démarrage, audit R1)
```
Rendu visuel (colonnes, couleurs) : contrôle à l'œil en session.

### 5. Nettoyage de `~/.claude` (étape finale, avant aplatissement)

Fichiers (dans `~/.claude`) : `skills/lexique/nvim/lexique.lua` (supprimé, et son répertoire),
`skills/lexique/SKILL.md:20`, docstring de `skills/lexique/scripts/lexique-cli.py`, les deux
dettes `lexique-completion-sous-un-modificateur` et `lexique-references-au-lua-temporaire`
déplacées de `technical-debt/` vers `technical-debt-solde/` (`list-dir move`).

- `SKILL.md` et la docstring désignent `~/.config/nvim/lua/lexique.lua` comme consommateur.

Vérif :
```bash
cd /home/debian/.claude
test ! -e skills/lexique/nvim/lexique.lua && echo absent
grep -rn 'nvim/lexique.lua' skills/lexique ; test $? -eq 1 && echo "aucune référence"
ls .claude/implementation/todo/technical-debt-solde/ | grep lexique
cd skills/lexique && /home/debian/.claude/.venv/bin/python -m pytest scripts/tests
git -C /home/debian/.claude status --short   # seuls ces fichiers
```
Commit séparé dans `~/.claude` (accord explicite).

## Vérification d'ensemble

- `make test` passe (tests `lsp`, `tts` et `lexique`).
- Signal 1 : la commande `grep` de l'étape 2 ne rend rien.
- Signaux 2 et 3 : `git -C ~/.claude diff --stat <sha avant étape 1> HEAD` ne liste que les
  fichiers des étapes 1 et 5 (sha relevé au journal du suivi avant l'étape 1) ; le diff de `lexique-cli.py` n'ajoute qu'une sous-commande.
- En session réelle : `:Lexique`, `:Lexique!`, `:Lexique Suivi`, `:silent Lexique Sig<Tab>`,
  `<leader>L` sur un terme composé et sur une sélection, `<leader>fL` puis `<CR>`.
