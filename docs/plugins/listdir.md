# listdir

## Role

Visualisation en lecture seule des **répertoires-listes** du skill `list-dir` : picker des listes
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
  - `cli.lua` — appel de `list-dir.py list`
  - `document.lua` — document concaténé, écrit sous le cache
  - `picker/lists.lua`, `picker/items.lua` — les deux pickers Snacks
- Related : `docs/plugins/snacks-picker-custom.md`, skill `~/.claude/skills/list-dir/`

## Key Behaviors

- **Lecture seule.** Aucune commande d'écriture de `list-dir` n'est appelée (`new`, `move`,
  `derive`, `migrate`, `init`), et `merge` non plus.
- **`list` donne l'ordre, Neovim donne le contenu.** `show` n'est jamais appelé : les titres et les
  corps sont lus directement dans les `.md`. Chaque invocation Python recharge l'interpréteur, d'où
  la règle : **un seul appel `list` par ouverture de picker et par changement de tri**, jamais un
  par élément.
- Un répertoire-liste se reconnaît à son `.list/contract.toml`. La recherche descend par
  `vim.fs.dir` sous chaque chemin de `paths` (défaut : le cwd), jusqu'à `depth` niveaux.
- **Tous les champs du contrat sont triables, `id` compris.** Le champ par défaut est `title` s'il
  est déclaré, sinon le premier du contrat. Le titre du picker affiche le champ courant et le sens
  (`demo  ↑ title`). La colonne de gauche n'est pas répétée quand la valeur triée est déjà
  affichée — tri par `title` ou par `id`.
- Inverser le sens se fait en Lua sur la table reçue — aucun appel supplémentaire.
- La preview des éléments est le previewer fichier de Snacks : markview s'y applique déjà via la
  config globale (`lua/plugins/snacks/picker/init.lua`, `markview_fts`).

### Options

```lua
require("listdir").setup({
  paths  = { vim.fn.getcwd },  -- string ou fonction rendant un string
  depth  = 4,
  ignore = { ".git", "node_modules", ".venv", "__pycache__", "dist", "build", "target" },
  cli    = vim.fs.joinpath(vim.env.HOME, ".claude/skills/list-dir/scripts/list-dir.py"),
  python = "python3",
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
| `<CR>`, `gf` | document | suit le lien Markdown de la ligne |
| `q` | document | ferme la fenêtre |

## Gotchas

- **`--sort` ne demande jamais plus d'une colonne.** La sortie de `list` sépare les valeurs par une
  espace : une valeur `text` peut en contenir, et un champ **absent** du front matter d'un élément
  est rendu par une chaîne **vide**. Dès la deuxième colonne, le découpage positionnel se décale
  sans que rien ne le signale. Avec une seule colonne, `id` est le premier token et la valeur est
  tout le reste de la ligne. C'est pour cela que le titre vient de `item.read` et non de `list`.
- **La lecture du contrat s'arrête au premier `[`** pour `name` et `description`. Sans cette borne,
  les `description = "…"` internes aux blocs `[fields.X]` écrasent celle de la liste.
- **Titres décalés dans le document.** Les sections d'un élément sont des `##`, au même niveau que
  le titre d'élément : le corps est décalé d'un niveau (`##` → `###`), **hors blocs de code** — un
  `## ` collé dans une sortie de commande est du contenu, pas un titre.
- **Touches `<a-…>` déjà prises par Snacks** : `d f h i r m p w` (`inspect`, `toggle_follow`,
  `toggle_hidden`, `toggle_ignored`, `toggle_regex`, `toggle_maximize`, `toggle_preview`,
  `cycle_win`). D'où `<A-s>`, `<A-S>`, `<A-v>`, `<A-o>`.
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
