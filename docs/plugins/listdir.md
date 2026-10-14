# listdir

## Role

Visualisation des **répertoires-listes** du skill `list-dir` : picker des listes
du workspace → picker des éléments d'une liste (preview, tri à la volée) → document Markdown où les éléments
sont concaténés.

## Files

- Spec Lazy : `lua/plugins/listdir.lua`
- Code : `plugins/listdir/lua/listdir/`
  - `config.lua` — options et valeurs par défaut
  - `contract.lua` — lecture de `<liste>/.list/contract.toml`
  - `discover.lua` — recherche des répertoires-listes sous les chemins configurés
  - `item.lua` — lecture d'un élément (front matter + corps) : façade sur le module commun
    `lua/frontmatter.lua` de la config, qui porte le parseur et le cache sur `mtime`
  - `cli.lua` — appels de `list-dir list` et `list-dir toggle`
  - `document.lua` — document concaténé, écrit sous le cache
  - `picker/lists.lua`, `picker/items.lua` — les deux pickers Snacks
- Registres : `lua/registres.lua` (`:Dettes`, `:Roadmap`), highlights `lua/highlights/listdir.lua`
- Related : `docs/plugins/snacks-picker-custom.md`, skill `~/.claude/skills/list-dir/`

## Key Behaviors

- **Une seule écriture : `list-dir toggle`**, pour le pin de `:Dettes`. Neovim n'écrit jamais
  dans un `.md` de liste, et n'appelle aucune autre commande d'écriture (`new`, `fill`, `move`,
  `derive`, `migrate`, `init`, `merge`).
- **`list` donne l'ordre, Neovim donne le contenu.** `show` n'est jamais appelé : les titres et les
  corps sont lus directement dans les `.md`. Chaque invocation Python recharge l'interpréteur, d'où
  la règle : **un seul appel `list` par ouverture de picker et par changement de tri**, jamais un
  par élément.
- Un répertoire-liste se reconnaît à son `.list/contract.toml`. La recherche descend par
  `vim.fs.dir` sous chaque chemin de `paths` (défaut : le cwd), jusqu'à `depth` niveaux.
- **Tous les champs du contrat sont triables, `id` compris, sauf les dépréciés** (`deprecated = …`
  au contrat) : ils ne s'écrivent plus, et la fiche du picker des listes les barre. Le champ par
  défaut est `title` s'il est déclaré, sinon le premier triable. Le titre du picker affiche le champ courant et le sens
  (`demo  ↑ title`). La colonne de gauche n'est pas répétée quand la valeur triée est déjà
  affichée — tri par `title` ou par `id`.
- **Le sens passe par la CLI** (`--sort=-champ`), qui garde les Marqueurs et les valeurs absentes
  en fin dans les deux sens ; inverser relance donc un `list`. La valeur affichée en colonne vient
  du front matter (`item.read`), pas de la sortie de `list`.
- **Un Marqueur s'affiche en retrait**, générique (`<OPTIONNEL>`) ou typé (`<OPTIONNEL date>`) :
  `frontmatter.is_marker` (`lua/frontmatter.lua`) en est la seule définition, partagée avec
  `lua/chantier.lua`.
- **Le picker d'éléments s'ouvre même vide** (`show_empty`) : une liste vide dit son nom et son
  tri, et un filtre sans résultat doit pouvoir se défaire.
- La preview des éléments est le previewer fichier de Snacks : markview s'y applique déjà via la
  config globale (`lua/plugins/snacks/picker/init.lua`, `markview_fts`).

### Registres : `:Dettes` et `:Roadmap`

`lua/registres.lua` ouvre le picker d'éléments sur `<racine git>/.claude/implementation/todo/<liste>`,
réglé par les options d'extension ci-dessous — aucun picker propre.

- `:Roadmap` — la liste `road-map`, sans option.
- `:Dettes` — la liste `technical-debt` :
  - ordre : `--sort=-pin,<champ du cycle>,-date,-severite` ; une clé fixe qui porte le champ du
    cycle est omise (trier sur `date` donne `-pin,date,-severite`) ; `pin` sort du cycle ;
  - libellé des dettes épinglées en `ListDirPinned` ; sévérité en glyphe Nerd Font de 2 colonnes
    devant l'id, coloré par niveau (`ListDirSeverity<Niveau>`) — une sévérité au Marqueur compte
    pour `inconnue` ;
  - `<A-n>` restreint aux pins (`--where pin=true`) ;
  - `<A-N>` bascule le pin de la dette sous le curseur par `list-dir toggle`, oublie son entrée
    du cache (`frontmatter.forget`), rafraîchit la liste et la preview, et garde le curseur sur
    elle ;
  - titre : `technical-debt  ↑ title 22·3 pins`, `[pins]` sous filtre. Les compteurs portent sur
    tout le registre, filtre ou non, comptés en Lua sur le front matter caché.

### Options d'extension de `items.open(dir, ct, opts?)`

| Option | Rôle |
|---|---|
| `before`, `after` | clés de `--sort` fixes, avant et après le champ du cycle |
| `skip` | champs sortis du cycle de tri |
| `where(state)` | critères `champ=valeur` passés en `--where` |
| `decorate(entry, data)` | `{ prefix = Highlight[], label = groupe }` : morceaux devant l'id, groupe du libellé |
| `title(state)` | titre du picker ; `items.indicator(state)` en donne la forme par défaut |
| `actions`, `keys` | actions `fun(picker, state)` et touches, ajoutées à celles du picker ; une touche vaut un nom d'action ou une spécification Snacks (`{ nom, mode = … }`) |

Sans `opts`, `:ListDir` garde son comportement.

### Options

```lua
require("listdir").setup({
  paths  = { vim.fn.getcwd },  -- string ou fonction rendant un string
  depth  = 4,
  ignore = { ".git", "node_modules", ".venv", "__pycache__", "dist", "build", "target" },
  cli    = "list-dir",  -- résolue par le PATH ; sinon, son chemin
  timeout = 5000,

  -- Réglages Snacks ajoutés à chaque picker, appliqués **après** les nôtres :
  -- layout, previewer, keymaps, tout est surchargeable. Fusion profonde, donc
  -- ajouter une touche n'efface pas celles du plugin.
  pickers = {
    lists = {},  -- picker des répertoires-listes
    items = {},  -- picker des éléments d'une liste
  },
})
```

## Keymaps

| Touche | Contexte | Action |
|---|---|---|
| `<leader>fl` | normal | `:ListDir` — picker des répertoires-listes |
| `<CR>` | picker des listes | ouvre le picker des éléments |
| `<CR>` | picker des éléments | ouvre le fichier de l'élément |
| `<A-s>` / `<A-S>` | picker des éléments | champ de tri suivant / précédent |
| `<A-v>` | picker des éléments | inverse le sens du tri |
| `<A-o>` | picker des éléments | ouvre le document concaténé |
| `:Dettes` | commande | picker de la dette technique du dépôt, pins en tête |
| `:Roadmap` | commande | picker de la road-map du dépôt |
| `<A-n>` | `:Dettes` | bascule le filtre des pins |
| `<A-N>` | `:Dettes` | épingle / désépingle la dette sous le curseur |
| `<CR>`, `gf` | document | suit le lien Markdown de la ligne |
| `q` | document | ferme la fenêtre |

## Gotchas

- **De la sortie de `list`, seul l'id est lu.** Elle sépare les valeurs par une espace : une valeur
  `text` peut en contenir, et un champ **absent** du front matter d'un élément est rendu par une
  chaîne **vide** ; dès la deuxième colonne, le découpage positionnel se décale sans que rien ne le
  signale. `--sort` peut donc porter plusieurs clés — c'est la CLI qui trie —, mais toute valeur
  affichée vient de `item.read`. `list --sort=-id` répète l'id en colonne : sans effet.
- **`resume` rejoue les options de l'ouverture**, titre initial compris
  (`plugins/snacks.nvim/lua/snacks/picker/resume.lua`), alors que l'état de tri vit dans la
  closure. `on_show` recalcule le titre depuis l'état à chaque ouverture, resume compris ; le
  finder le recalcule aussi à chaque run, pour les compteurs. `source = "listdir_items"` sépare ce
  picker des autres `custom`.
- **Le cache du front matter se fie à `mtime` à la seconde** : après une écriture par la CLI, deux
  bascules dans la même seconde liraient l'ancienne valeur. `frontmatter.forget(path)` après
  chaque `toggle`.
- **Le previewer fichier de Snacks garde son contenu tant que le chemin ne change pas**
  (« re-use existing preview when path is the same », `snacks/picker/preview.lua`) : après un
  `toggle`, l'entrée réécrite restait affichée avec l'ancien `pin`. `picker.preview:refresh(picker)`
  lui fait oublier l'élément affiché, et relire le fichier.
- **Sans `show_empty`, Snacks referme un picker sans résultat** (« No results found ») : une liste
  vide ne s'ouvrait pas, et un filtre vide fermait le picker.
- **La lecture du contrat s'arrête au premier `[`** pour `name` et `description`. Sans cette borne,
  les `description = "…"` internes aux blocs `[fields.X]` écrasent celle de la liste.
- **Titres décalés dans le document.** Les sections d'un élément sont des `##`, au même niveau que
  le titre d'élément : le corps est décalé d'un niveau (`##` → `###`), **hors blocs de code** — un
  `## ` collé dans une sortie de commande est du contenu, pas un titre.
- **Touches `<a-…>` déjà prises par Snacks** : `d f h i r m p w` (`inspect`, `toggle_follow`,
  `toggle_hidden`, `toggle_ignored`, `toggle_regex`, `toggle_maximize`, `toggle_preview`,
  `cycle_win`). D'où `<A-s>`, `<A-S>`, `<A-v>`, `<A-o>`, `<A-n>`, `<A-N>`.
- **Le document n'est pas un buffer `nofile`, et c'est délibéré.** Le core de Neovim refuse
  d'attacher un serveur LSP à tout buffer dont `buftype` n'est pas vide — `runtime/lua/vim/lsp.lua`,
  « Only ever attach to buffers (including "help") that represent an actual file ». Un `nofile`
  privait donc le document de marksman. Il est écrit sous `stdpath("cache")/listdir/<liste>.md`,
  **hors du répertoire-liste**, puis ouvert en lecture seule (`readonly`, `nomodifiable`,
  `noswapfile`) ; `edit!` le recharge à chaque ouverture.
- **Deux listes homonymes partagent le même fichier de cache** : le nom du fichier ne porte que le
  nom déclaré au contrat. Le chemin réel de la liste est écrit en tête du document, ce qui lève
  l'ambiguïté sans décorer le nom du buffer.
- **L'appel à `list` est bloquant** (`vim.system():wait`, timeout 5 s). Assumé : un seul appel par
  ouverture ou changement de tri. Passer au finder asynchrone reste local à `picker/items.lua`.
- **Le picker des listes ne scanne qu'une fois par ouverture.** `M.open` passe ses entrées au
  finder via `ld_entries` ; sans cela l'arborescence est parcourue deux fois — une fois pour savoir
  s'il y a quelque chose à montrer, une fois pour le montrer — et le coût est repayé à chaque
  `refresh`. Appelé sans `ld_entries`, le finder scanne, ce qui garde les vérifications simples.
- **`depth` élevé se paie.** `vim.fs.dir` descend dans tout ; l'option `ignore` alimente son `skip`
  pour couper les répertoires qui ne contiennent jamais de `.list`. À `depth = 10` sur `$HOME`, le
  scan reste de l'ordre de la seconde, et il est **bloquant**.
- **Un chemin à parenthèses ou à espaces se met entre chevrons.** La forme `[t](/a/b (c)/d.md)`
  de CommonMark se coupe à la première parenthèse fermante : la cible devient `/a/b (c` et
  `vim.cmd.edit` ouvre un buffer vide **sans erreur**. `document.render` bascule sur la forme
  `<…>` dès que le chemin contient une espace, une parenthèse ou un chevron, et `document.target`
  lit les deux formes.
- **Une preview d'item ne s'affiche que si `preview = "preview"`.** Le préréglage par défaut de
  Snacks est le previewer fichier ; un répertoire-liste n'étant pas un fichier, le picker de
  niveau 1 restait vide malgré son `item.preview`. Ce préréglage-là est celui qui rend
  `item.preview.text` (`plugins/snacks.nvim/lua/snacks/picker/preview.lua`, `M.preview`).
- **`/plugins` est ignoré par `.gitignore`** : ajouter les fichiers d'un nouveau plugin local
  demande `git add -f`, comme pour les autres plugins du dépôt.
- Un mapping buffer-local ne se voit pas avec `vim.fn.maparg` si le buffer n'est pas courant —
  utiliser `vim.api.nvim_buf_get_keymap(buf, "n")` pour le vérifier.

## Changelog

- 2026-08-28 : création. Picker des listes, picker des éléments avec tri à la volée, document
  concaténé. Chantier `list-dir-viewer`.
- 2026-08-28 : `id` entre dans le cycle de tri ; le document passe d'un buffer `nofile` à un
  fichier écrit sous le cache, pour que marksman puisse s'y attacher.
- 2026-08-29 : le picker des listes affiche enfin sa fiche de contrat (`preview = "preview"`),
  complétée du nombre d'éléments — compté en Lua, sans appel Python.
- 2026-08-29 : option `pickers.lists` / `pickers.items` pour surcharger la configuration Snacks de
  chaque picker.
- 2026-08-29 : audit de clôture — liens Markdown des chemins à parenthèses corrigés (échec
  silencieux), formatage `stylua` rétabli, gotcha `vim.schedule` supprimé (le code ne l'a plus
  depuis le passage au fichier de cache).
- 2026-08-29 : audit (2e passe) — un seul scan par ouverture du picker des listes, et option
  `ignore` coupant `.git` / `node_modules` et consorts pendant la descente.
- 2026-09-21 : le parseur de front matter et son cache sortent de `item.lua` vers
  `lua/frontmatter.lua`, partagé avec les commandes `:Suivi`/`:Brief`/`:Plan`/`:Audit`
  (`lua/chantier.lua`). `item.lua` garde son API ; listdir dépend désormais de la config.
  Chantier `chantier-docs-commands`.
- 2026-10-14 : remis au niveau de `list-dir` — Marqueurs typés en retrait, tri typé par la CLI
  (sens compris, plusieurs clés, seul l'id lu), champs `deprecated` hors du cycle, titre juste au
  resume, picker ouvert même vide. Options d'extension de `items.open`, et `:Dettes` / `:Roadmap`
  par `lua/registres.lua`. Chantier `listdir-dettes-roadmap`.
- 2026-10-14 : `<A-N>` dans `:Dettes` bascule le pin par `list-dir toggle` — première écriture du
  plugin, la seule.
