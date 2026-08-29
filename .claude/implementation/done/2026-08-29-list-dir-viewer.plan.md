# Visualiser les répertoires-listes dans Neovim (`list-dir-viewer`)

## Context

Le skill `list-dir` stocke des listes sous forme de répertoires (`<liste>/.list/contract.toml` +
un `*.md` par élément, front matter TOML délimité par `+++`). Aujourd'hui ces listes ne se
consultent qu'en CLI : depuis Neovim, il n'existe aucun moyen de parcourir une liste, d'en trier
les éléments ou d'en lire le contenu d'un trait.

On ajoute un plugin local **en lecture seule** offrant trois vues enchaînées :

1. un picker des répertoires-listes trouvés sous des chemins configurés (cwd par défaut) ;
2. depuis celui-ci, un picker des éléments de la liste choisie, avec preview et tri à la volée sur
   les champs déclarés au contrat ;
3. depuis ce dernier, un buffer `nofile` par liste où tous les éléments sont concaténés en Markdown,
   chaque titre étant un lien vers le fichier de l'élément.

Brief de référence : `.claude/implementation/list-dir-viewer.brief.md` (validé le 2026-08-28).

### Contraintes structurantes (issues du brief)

- **Lecture seule.** Aucune commande d'écriture de `list-dir` (`new`, `move`, `derive`, `migrate`,
  `init`, `merge`) n'est appelée **par le plugin**.
- **Économie d'appels Python.** Chaque invocation recharge l'interpréteur. Seule `list` est
  appelée, une fois par ouverture de picker et une fois par changement de tri. `show` n'est
  **jamais** appelé : Neovim lit les fichiers lui-même.
- Le nombre d'appels Python ne doit pas croître avec le nombre d'éléments.

### Faits établis pendant l'exploration

- `list <liste> [--sort a,b]` rend une ligne par élément : `id` puis les valeurs des champs de
  `--sort`, séparées par une espace. Vérifié sur `~/.claude/.claude/implementation/todo/technical-debt`.
- **Le découpage positionnel est fragile** : une valeur `text` peut contenir des espaces, et un
  champ absent du front matter d'un élément rend une chaîne **vide**
  (`scripts/listdir/commands/list.py`, `_cell`) — la ligne porte alors deux espaces consécutives et
  toute colonne suivante se décale. On n'en demande donc **jamais plus d'une** : voir « Source des
  données » ci-dessous.
- Un champ présent mais non renseigné ressort littéralement `<OPTIONNEL>` ou `<À REMPLIR>`.
- `.list/contract.toml` n'a pas besoin d'un vrai parseur TOML : les noms de champs se lisent au
  motif `^%[fields%.([%w_]+)%]`, `name`/`description` de la liste au motif
  `^(%w+)%s*=%s*"(.*)"` — **mais seulement avant la première ligne commençant par `[`**, sans quoi
  les `description` internes aux blocs `[fields.X]` (le contrat de `technical-debt` en contient
  quatre) écrasent celle de la liste.
- `snacks.Picker.title` est mutable et `picker:refresh()` appelle `update_titles()`
  (`plugins/snacks.nvim/lua/snacks/picker/core/picker.lua:811,835`) : le champ de tri courant peut
  donc s'afficher dans le titre et se rafraîchir sans rouvrir le picker.
- Quand le prompt est vide, le matcher conserve l'ordre du finder
  (`plugins/snacks.nvim/lua/snacks/picker/config/defaults.lua:136`, `sort_empty = false`) — c'est
  ce qui rend l'ordre de `list` visible.
- La preview de fichier `.md` est déjà enrichie par markview via la config globale du picker
  (`lua/plugins/snacks/picker/init.lua:4`, table `markview_fts`) : rien à faire pour l'obtenir.
- Keymaps `<a-…>` déjà pris par snacks (`defaults.lua:238-245`, `294-300`) : `d f h i r m p w`.
  Restent libres, et retenus ici : `<A-s>`, `<A-S>`, `<A-v>`, `<A-o>`.

## Architecture

Plugin local nommé `listdir`, suivant la convention du dépôt (`plugins/<nom>/` à la racine, spec
séparée sous `lua/plugins/`), calquée sur `plugins/bookmarks/` + `lua/plugins/bookmarks.lua`.

```
plugins/listdir/lua/listdir/
├── init.lua          setup(), commandes utilisateur
├── config.lua        options + valeurs par défaut
├── contract.lua      lecture de .list/contract.toml
├── discover.lua      recherche des répertoires-listes sous les chemins configurés
├── item.lua          lecture d'un élément (.md) : front matter + corps
├── cli.lua           appel de `list` et parsing des lignes
├── document.lua      buffer nofile concaténé
└── picker/
    ├── lists.lua     picker de niveau 1 (les listes)
    └── items.lua     picker de niveau 2 (les éléments)
lua/plugins/listdir.lua   spec Lazy (dir = …/plugins/listdir)
docs/plugins/listdir.md   doc plugin
```

### Source des données

**`list` donne l'ordre, Neovim donne le contenu.**

- Un seul appel `list <dir> --sort <champ>` par run du finder. Une seule colonne demandée : `id`
  est le premier token, la valeur du champ est **tout le reste de la ligne** — découpage sans
  ambiguïté, même si la valeur contient des espaces ou est vide.
- Le titre de chaque élément, et le corps pour le document, sont lus en Lua dans le fichier
  `<dir>/<id>.md` (`item.lua`), jamais par `show`. C'est explicitement ce que demande le brief
  (« nvim peut directement obtenir le contenu d'un élément »).
- `item.lua` tient un cache mémoire indexé par chemin, invalidé sur `mtime` (`vim.uv.fs_stat`) :
  rouvrir le picker ou changer le tri ne relit pas les fichiers inchangés.
- Inverser le sens du tri se fait en Lua sur la table reçue : aucun appel supplémentaire.

### Options (`config.lua`)

```lua
{
  paths = { vim.fn.getcwd },   -- chemins de recherche ; fonction ou string
  depth = 4,                   -- profondeur max de descente
  cli   = vim.fs.joinpath(vim.env.HOME, ".claude/skills/list-dir/scripts/list-dir.py"),
  python = "python3",
  timeout = 5000,              -- ms, sur l'appel `list`
}
```

`cli` est une option et non une constante : le chemin de la skill n'est pas garanti sous `~/.claude`.

### Compromis assumé — appel bloquant

`cli.list` fait `vim.system(...):wait(timeout)` : l'interface est figée le temps de l'appel, jusqu'à
`timeout` dans le pire cas. C'est délibéré — `list` est peu coûteux, le finder synchrone de snacks
est bien plus simple qu'un finder asynchrone, et un seul appel a lieu par ouverture ou changement de
tri. Si la latence se révélait gênante, le passage au finder asynchrone (`function(cb)`) est local à
`picker/items.lua`.

## Fixture de vérification

Les commandes de vérification ne doivent dépendre ni de données hors dépôt ni de comptes figés.
Chaque étape vérifiable construit d'abord une liste jetable dans le scratchpad :

```bash
FIX=/tmp/claude-1000/-home-debian--config-nvim/340b288b-d7e7-49e5-b404-c5e344f44d64/scratchpad/fixture
L="$HOME/.claude/skills/list-dir/scripts/list-dir.py"
rm -rf "$FIX" && mkdir -p "$FIX"
python3 "$L" init "$FIX/demo"
python3 "$L" new "$FIX/demo" alpha
python3 "$L" new "$FIX/demo" beta
```

Le contrat squelette produit par `init` est ensuite complété à la main (champs `title` texte requis,
`date` date requise, `category` enum optionnel) et les deux éléments renseignés — dont **un avec
`category` absent du front matter**, pour exercer le cas de la colonne vide.

> `init` et `new` sont ici lancés **par le développeur** pour fabriquer une fixture. Ce n'est pas
> une écriture du plugin : le hors-périmètre porte sur ce que le plugin appelle, et le contrôle 2
> de la vérification d'ensemble le prouve par `git grep`.

## Étapes

### 1. Squelette du plugin, spec Lazy et configuration

Créer `plugins/listdir/lua/listdir/{init,config}.lua`, la spec `lua/plugins/listdir.lua`
(`dir = vim.fn.stdpath("config") .. "/plugins/listdir"`, `cmd = { "ListDir" }`, keymap
`<leader>fl` — libre, vérifié), et ajouter `{ import = "plugins.listdir" }` au bloc d'imports
d'`init.lua` (lignes 82-129 ; ce bloc n'est pas strictement alphabétique — poser la ligne près des
autres `plugins.l*`).

`config.lua` expose `M.defaults`, `M.options` et `M.setup(opts)` (`vim.tbl_deep_extend`).
`init.lua` déclare la commande `:ListDir` qui appellera le picker de niveau 1.

Annotations Emmylua obligatoires, types préfixés `Ozay.` (`---@class Ozay.ListDir.Options`).

**Vérification** :
```bash
nvim --headless -c 'lua local c = require("listdir.config"); c.setup({}); assert(type(c.options.paths) == "table"); assert(c.options.depth == 4); print("OK")' -c qa
```

### 2. Lecture du contrat et découverte des listes

`contract.lua` : `M.read(dir)` → `{ name, description, fields = { {name, type, required} ... } }`
ou `nil, err`. Lecture ligne à ligne de `<dir>/.list/contract.toml` (`io.lines`) ; les
méta-données (`name`, `description`) ne sont lues **qu'avant la première ligne commençant par `[`**,
puis chaque `[fields.X]` ouvre un champ dont les `type` / `required` suivants le renseignent.

`discover.lua` : `M.find(paths?, depth?)` → liste de `{ path, name, description, fields }`, triée
par `name`. Descente par `vim.fs.dir(root, { depth = depth })` ; une entrée est retenue si c'est un
répertoire `.list` dont le parent porte un `contract.toml` lisible. Dédoublonnage par chemin absolu.

**Vérification** (sur la fixture, après l'avoir construite) :
```bash
nvim --headless -c 'lua
local FIX = vim.env.FIX
local c = require("listdir.contract").read(FIX .. "/demo")
assert(c, "contrat illisible")
assert(c.name == "demo", "name incorrect : " .. tostring(c.name))
assert(not c.description:match("^l.énoncé"), "description écrasée par celle d un champ")
local names = {}; for _, f in ipairs(c.fields) do names[f.name] = f end
assert(names.title and names.title.required, "title requis manquant")
assert(names.category and names.category.type == "enum", "category enum manquant")
local found = require("listdir.discover").find({ FIX }, 3)
assert(#found == 1 and found[1].name == "demo", "découverte incorrecte")
print("OK")' -c qa
```

### 3. Lecture d'un élément et appel de `list`

`item.lua` : `M.read(path)` → `{ fields = { … }, body = string }` ou `nil, err`. Découpe le front
matter entre les deux `+++`, lit les paires `clé = valeur` (guillemets retirés, listes et dates
laissées telles quelles — on n'a besoin que de l'affichage). Cache indexé par chemin, invalidé sur
`mtime`.

`cli.lua` : `M.list(dir, field, reverse)` → `{ { id, path, value } ... }, err`.
`vim.system({ python, cli, "list", dir, "--sort", field }, { text = true }):wait(timeout)`.
Code non nul → `nil, stderr`. Parsing : `^(%S+)%s?(.*)$`. `path = vim.fs.joinpath(dir, id .. ".md")`.
`reverse` inverse la table en Lua.

**Vérification** (l'élément sans `category` doit se lire sans décalage) :
```bash
nvim --headless -c 'lua
local FIX, dir = vim.env.FIX, vim.env.FIX .. "/demo"
local items = assert(require("listdir.cli").list(dir, "category", false))
assert(#items == 2, "2 éléments attendus, " .. #items)
for _, it in ipairs(items) do
  assert(it.id:match("^%a+$"), "id mal découpé : " .. it.id)
  assert(it.path:match("/" .. it.id .. "%.md$"), "chemin incorrect : " .. it.path)
end
local rev = assert(require("listdir.cli").list(dir, "category", true))
assert(rev[1].id == items[#items].id, "reverse incorrect")
local one = assert(require("listdir.item").read(items[1].path))
assert(one.fields.title and one.fields.title ~= "", "title non lu")
assert(not one.body:match("%+%+%+"), "front matter non retiré du corps")
print("OK")' -c qa
```

### 4. Picker de niveau 1 — les répertoires-listes

`picker/lists.lua` : `M.open()` — `Snacks.picker.pick` sur le retour de `discover.find()`.

- `text` = nom de la liste ; champs custom `ld_dir`, `ld_contract`.
- `format` : nom en `SnacksPickerLabel` + description en `Comment`.
- `preview` inline (`item.preview = { text = …, ft = "markdown" }`) : nom, description et tableau
  des champs du contrat — évite d'ouvrir un fichier pour une information déjà en mémoire.
- `confirm` : `picker:close()` puis `require("listdir.picker.items").open(item.ld_dir, item.ld_contract)`.
- Aucune liste trouvée → `vim.notify` nommant les chemins fouillés, pas un picker vide.

Brancher `:ListDir` et `<leader>fl` dessus.

**Vérification** : le finder et le `confirm` sont exercés sans ouvrir de fenêtre en appelant
directement les fonctions que le picker recevra — c'est ce qui rend l'enchaînement
niveau 1 → niveau 2 automatiquement contrôlable. Les extraire en `M.finder(opts, ctx)` et
`M.confirm(picker, item)` au niveau du module, plutôt qu'en closures anonymes, est donc une
contrainte de conception de cette étape :
```bash
nvim --headless -c 'lua
require("listdir").setup({ paths = { vim.env.FIX }, depth = 3 })
assert(vim.fn.exists(":ListDir") == 2, "commande absente")
local lists = require("listdir.picker.lists")
local items = lists.finder({}, { filter = { filter = function(_, i) return i end } })
assert(#items == 1 and items[1].ld_dir:match("/demo$"), "finder niveau 1 incorrect")
assert(items[1].preview and items[1].preview.text:match("title"), "preview sans les champs")
local opened
package.loaded["listdir.picker.items"] = { open = function(d) opened = d end }
lists.confirm({ close = function() end }, items[1])
assert(opened == items[1].ld_dir, "confirm nouvre pas le picker de niveau 2")
print("OK")' -c qa
```

### 5. Picker de niveau 2 — les éléments

`picker/items.lua` : `M.open(dir, contract)`. Cette étape livre la vue **sans le tri à la volée**
(étape 6), avec un champ de tri fixe : `title` s'il est déclaré, sinon le premier champ après `id`.

- `finder` : `cli.list(dir, state.field, state.reverse)`, puis pour chaque ligne
  `item.read(path)` pour le titre → items `{ text = title, file = path, ld_id, ld_value }`,
  enfin `ctx.filter:filter(items)`. **Un appel Python par run du finder.**
- `format` : `ld_id` en `Comment`, `ld_value` en `Special` (grisée si `<OPTIONNEL>` /
  `<À REMPLIR>` / vide), puis le titre.
- `confirm` : `picker:close()` + `vim.cmd.edit(item.file)`.
- Preview : héritée du previewer fichier via `item.file` ; markview s'applique déjà.
- Erreur de `cli.list` → `vim.notify` du stderr et finder vide, jamais une erreur Lua brute.

**Vérification** (l'état est exposé pour être pilotable ; le finder est appelé hors fenêtre) :
```bash
nvim --headless -c 'lua
local dir = vim.env.FIX .. "/demo"
local contract = require("listdir.contract").read(dir)
local p = require("listdir.picker.items")
local st = p.state(dir, contract)
assert(st.field == "title", "champ de tri par défaut incorrect : " .. tostring(st.field))
local items = p.finder(st, { filter = { filter = function(_, i) return i end } })
assert(#items == 2, "2 éléments attendus")
assert(items[1].file:match("%.md$") and items[1].text ~= "", "item sans fichier ou sans titre")
print("OK")' -c qa
```

### 6. Tri à la volée

Ajouter à `picker/items.lua` les actions et leur reflet dans le titre :

- `ld_sort_next` (`<A-s>`) : champ suivant du contrat, `id` exclu.
- `ld_sort_prev` (`<A-S>`) : champ précédent.
- `ld_sort_reverse` (`<A-v>`) : bascule `state.reverse`.

Chacune met à jour `picker.title` (`"demo  ↑ title"` / `"demo  ↓ date"`) puis appelle
`picker:refresh()`, qui relance le finder — donc exactement un appel `list` — et rafraîchit les
titres via `update_titles()`.

`<A-s>`, `<A-S>` et `<A-v>` sont libres : `<a-r>` est déjà `toggle_regex` et `<a-i>`
`toggle_ignored` (`defaults.lua:242`, `:241`), à ne pas réutiliser.

**Vérification** — le comptage d'appels Python passe par le finder réel, pas par `cli.list` :
```bash
nvim --headless -c 'lua
local dir = vim.env.FIX .. "/demo"
local contract = require("listdir.contract").read(dir)
local p = require("listdir.picker.items")
local ctx = { filter = { filter = function(_, i) return i end } }
local st = p.state(dir, contract)
local n = 0
local orig = vim.system
vim.system = function(...) n = n + 1; return orig(...) end
local a = p.finder(st, ctx)
p.sort_next(st); local b = p.finder(st, ctx)
p.sort_reverse(st); local c = p.finder(st, ctx)
vim.system = orig
assert(n == 3, "un appel par run attendu, " .. n .. " pour 3 runs")
assert(st.field ~= "title", "sort_next na pas changé le champ")
assert(c[1].ld_id == b[#b].ld_id, "reverse na pas inversé lordre")
assert(#a == #b and #b == #c, "le nombre déléments varie selon le tri")
print("OK")' -c qa
```

### 7. Génération du document concaténé

`document.lua` : `M.render(dir, contract, items)` → `string[]`, fonction **pure** (d'où sa
vérifiabilité), et `M.open(dir, contract, items)` → `bufnr`.

Contenu, dans l'ordre des `items` reçus (donc le tri courant du picker) :

```markdown
# <nom de la liste>

<description>

## [<title>](<chemin absolu>)

<corps de l'élément, front matter retiré, titres décalés>
```

Les sections d'un élément sont des `##` : elles seraient au même niveau que le titre d'élément.
Les **décaler d'un niveau** (`##` → `###`), en ignorant les lignes situées à l'intérieur d'un bloc
de code — même précaution que celle appliquée par la skill dans
`~/.claude/skills/list-dir/scripts/listdir/items.py` (`outside_fences`).

Le buffer : un par liste, réutilisé — nom `list-dir://<nom-liste>`, retrouvé par `vim.fn.bufnr`.
`buftype = "nofile"`, `bufhidden = "hide"`, `swapfile = false`, `filetype = "markdown"`,
`modifiable = false` après remplissage.

**Vérification** :
```bash
nvim --headless -c 'lua
local dir = vim.env.FIX .. "/demo"
local contract = require("listdir.contract").read(dir)
local items = assert(require("listdir.cli").list(dir, "title", false))
local doc = require("listdir.document")
local text = table.concat(doc.render(dir, contract, items), "\n")
assert(select(2, text:gsub("\n## %[", "")) == #items, "un titre par élément attendu")
assert(text:find("%]%(/", 1), "lien non absolu")
assert(not text:find("%+%+%+"), "front matter non retiré")
assert(not text:find("\n## Constat"), "titres de section non décalés")
local buf = doc.open(dir, contract, items)
assert(vim.bo[buf].buftype == "nofile" and not vim.bo[buf].modifiable, "options de buffer incorrectes")
assert(vim.api.nvim_buf_get_name(buf):match("list%-dir://demo$"), "nom de buffer incorrect")
assert(doc.open(dir, contract, items) == buf, "buffer non réutilisé")
print("OK")' -c qa
```

### 8. Navigation dans le document et branchement au picker

- Mappings locaux au buffer : `<CR>` et `gf` suivent le lien Markdown sous le curseur (motif
  `%]%((.-)%)` sur la ligne courante) et ouvrent le fichier ; `q` ferme la fenêtre.
- Action `ld_document` (`<A-o>`) dans `picker/items.lua` : ferme le picker et ouvre le document
  avec les items du tri courant.

**Vérification** :
```bash
nvim --headless -c 'lua
local dir = vim.env.FIX .. "/demo"
local contract = require("listdir.contract").read(dir)
local items = assert(require("listdir.cli").list(dir, "title", false))
local doc = require("listdir.document")
local buf = doc.open(dir, contract, items)
local line
for i, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
  if l:match("^## %[") then line = i break end
end
assert(line, "aucun titre lien")
assert(doc.target(buf, line) == items[1].path, "cible du lien incorrecte")
assert(vim.fn.maparg("<CR>", "n", false, true).buffer == 1, "<CR> non mappé au buffer")
print("OK")' -c qa
```

### 9. Documentation

- Créer `docs/plugins/listdir.md` au gabarit imposé par `CLAUDE.md` (Role / Files / Key Behaviors /
  Keymaps / Gotchas / Changelog). Y consigner en Gotchas : pourquoi `--sort` ne demande **jamais**
  plus d'une colonne (valeurs à espaces et champs absents rendus vides), la lecture des
  méta-données du contrat bornée au premier `[`, le décalage `##` → `###`, les keymaps `<a-…>`
  déjà pris par snacks, et le fait que `show` et `merge` sont délibérément inutilisés.
- Ajouter la ligne `listdir` au tableau « Plugin Index » de `CLAUDE.md`.

**Vérification** :
```bash
grep -q "listdir" /home/debian/.config/nvim/CLAUDE.md && test -f /home/debian/.config/nvim/docs/plugins/listdir.md && echo OK
```

## Vérification d'ensemble

1. Toutes les commandes headless des étapes 1 à 8 passent sur la fixture.
2. `git grep -nE '"(show|merge|new|move|derive|migrate|init)"' plugins/listdir` ne remonte **rien** :
   aucune commande d'écriture ni `show` n'est appelée par le plugin (critère de réussite du brief).
3. Manuel, sur une vraie liste : `nvim` → `:ListDir` → sélection → `<A-s>` / `<A-v>` changent
   l'ordre et la colonne affichée → `<CR>` ouvre l'élément → `<A-o>` ouvre le document, où `<CR>`
   sur un titre ouvre le fichier correspondant.

## Hors périmètre (rappel du brief)

Aucune écriture dans les listes, aucun ordre manuel persistant, aucune infrastructure de test
ajoutée au dépôt (il n'en a pas).
