# Theme & Highlights System

## Role
Systeme de theming multi-couche base sur Sonokai, avec highlights per-plugin charges dynamiquement via lazy.nvim.

## Files
- Theme: `lua/themes/sonokai.lua`
- base46 local fork: `lua/base46/` (init, colors, load, integrations/)
- Highlights loader: `lua/highlights/init.lua`
- Color utilities: `lua/colors_bank.lua`
- Overrides: `lua/chadrc.lua` (section `base46`)
- Per-plugin highlights: `lua/highlights/<plugin>.lua`

## Moment de chargement

Dans `init.lua`, les highlights sont charges en **dernier**, via `vim.schedule` :
1. `require("base46.load").apply()` charge les integrations, polish_hl, hl_add/hl_override, terminal colors (step 4)
2. `require("highlights")` est appele dans `vim.schedule` (step 6), ce qui initialise le loader et les autocmds
3. Les fichiers `highlights/*.lua` sont ensuite charges au fur et a mesure via les events `VeryLazy` et `LazyLoad`

## Architecture

### 4 couches de highlights (ordre d'application)

1. **Integration defaults (`lua/base46/integrations/`)**
   - `defaults.lua` : Normal, Pmenu, Cursor, Visual, Search, Lazy*, etc.
   - `syntax.lua` : Comment, Function, Keyword, String, Type, etc.
   - `treesitter.lua` : @variable, @function, @keyword, @comment, etc.
   - `lsp.lua` : LspReference*, Diagnostic*, LspInlayHint
   - `git.lua` : DiffAdd, DiffDelete, gitcommit*, etc.
   - Chaque fichier utilise la palette base_30/base_16 de sonokai.lua

2. **Theme polish (`lua/themes/sonokai.lua` → `polish_hl`)**
   - Highlights groupes par categorie (`treesitter`, `lsp`, `syntax`, `defaults`, `telescope`, `cmp`, `git`, `trouble`)
   - Surcharge les integrations defaults pour le style Sonokai specifique
   - `base46_terminal` : couleurs ANSI pour les terminaux integres

3. **Chadrc overrides (`lua/chadrc.lua` → `base46`)**
   - `hl_add` : nouveaux groupes (BlinkCmp kinds, Rainbow indent, DAP signs, etc.)
   - `hl_override` : surcharge de groupes existants (ex: `@keyword` → blue au lieu de red)
   - Syntaxe speciale base46 : `fg = { "blue", -20 }` (lightness shift), `fg = { "red", "line", 80 }` (mix 2 couleurs)

4. **Per-plugin highlights (`lua/highlights/*.lua`)**
   - Fichiers autonomes, chacun retourne une **fonction** (pas une table)
   - La fonction est appelee par `highlights/init.lua` via `loadfile()` + execution
   - Accedent aux couleurs via `require("base46").get_theme_tb("base_30")`
   - Appliquent les highlights avec `vim.api.nvim_set_hl(0, group, opts)`

### base46 local fork (`lua/base46/`)

| Fichier | Role |
|---|---|
| `init.lua` | API principale : `get_theme_tb()`, `turn_str_to_color()`, `merge_tb()` |
| `colors.lua` | Utilitaires couleur : `mix()`, `change_hex_lightness()`, `hex2rgb()`, etc. |
| `load.lua` | Chargeur : applique integrations + polish_hl + chadrc overrides + terminal colors |
| `integrations/` | Highlights de base par categorie (defaults, syntax, treesitter, lsp, git) |

Le systeme `turn_str_to_color` resout 3 syntaxes dans hl_add/hl_override :
- `"blue"` → nom palette → hex
- `{ "blue", -20 }` → changement de luminosite
- `{ "orange", "line", 80 }` → fusion de 2 couleurs (20% orange + 80% line)

### Fichiers highlights existants

| Fichier | Plugin cible | Particularites |
|---|---|---|
| `codediff.lua` | codediff | Utilise `colors_bank.bank` pour les couleurs mixees |
| `snacks.lua` | snacks.nvim | Utilise `mix_colors_group()` et `change_hex_lightness()` |
| `markview.lua` | markview.nvim | Utilise `colors_bank.bank.code_bg` |
| `neogit.lua` | neogit | ~130 groupes, le plus gros fichier highlights |
| `neo-tree.lua` | neo-tree.nvim | Git status, diagnostics, UI |

### Chargement dynamique (`lua/highlights/init.lua`)

Le loader utilise 3 mecanismes complementaires :

1. **Au demarrage (`VeryLazy`)** : parcourt les plugins deja charges par lazy.nvim, matche leur nom contre les fichiers `highlights/*.lua` (sans extension), et charge les highlights correspondants.

2. **Au chargement lazy (`LazyLoad`)** : ecoute l'evenement `User LazyLoad`, matche `opt.data` (nom du plugin charge) contre les fichiers highlights disponibles.

3. **Hot-reload (`BufWritePost`)** : quand un fichier `lua/highlights/*.lua` est sauvegarde, recharge automatiquement ses highlights avec notification.

Le matching se fait par sous-chaine : le nom du fichier highlight (sans `.lua`) est cherche dans le nom du plugin via `string.find()`. Ex: `neogit.lua` matche le plugin `neogit`.

### Color utilities (`lua/colors_bank.lua`)

- `hi_pathwork(fg, bg, opts?)` : cree un groupe highlight composite (fg d'un groupe + bg d'un autre). Cache les resultats. Se re-applique automatiquement sur `ColorScheme`.
- `get_hi_attr(group, attr)` : recupere un attribut (`fg`, `bg`, etc.) d'un groupe highlight.
- `mix_colors_group(group1, group2, strength?, ground?)` : mixe les couleurs de 2 groupes (ou hex). Utilise `base46.colors.mix()`.
- `bank` : table de couleurs pre-calculees (diffs, code_bg, scratch_desc) via `mix()` sur la palette base_30.

## Palette Sonokai (base_30)

| Nom | Hex | Usage principal |
|---|---|---|
| `red` | `#fc5d7c` | Keywords, operateurs, erreurs |
| `green` | `#9ed072` | Fonctions, ajouts, succes |
| `yellow` | `#e7c664` | Strings, warnings, headings |
| `cyan/blue` | `#76cce0` | Types, info, liens |
| `purple` | `#b39df3` | Constantes, nombres, semantic tokens |
| `orange` | `#f39660` | Parametres, builtins |
| `grey_fg` | `#7f8490` | Commentaires, elements discrets |
| `black` | `#2c2e34` | Background editeur |
| `one_bg` | `#222327` | Background sidebar/gutter |
| `one_bg2` | `#363944` | Selections, hover |
| `one_bg3` | `#3b3e48` | Selections fortes |
| `line` | `#414550` | Bordures, indentation |

## Gotchas

- **Ordre des couches** : integrations defaults → polish_hl → hl_add/hl_override → highlights/*.lua (dernier gagne).
- **Matching par sous-chaine** : si un fichier highlight s'appelle `snacks.lua`, il matchera tout plugin dont le nom contient "snacks". Le `escape_pattern()` de utils.lua est utilise pour echapper les caracteres speciaux du nom de fichier.
- **Les fichiers highlights retournent une fonction**, pas une table. Le loader utilise `loadfile()` puis execute le resultat. Si le fichier retourne autre chose qu'une fonction, rien n'est applique.
- **Hot-reload** : la sauvegarde d'un fichier `highlights/*.lua` recharge instantanement les highlights — pas besoin de relancer Neovim.
- **`hi_pathwork` est cache** : les groupes composites ne sont recalcules que sur `ColorScheme`. Si on change un highlight source sans changer de theme, le cache peut etre stale.
- **chadrc utilise la syntaxe base46** pour les couleurs (noms string comme `"red"`, tuples `{ "blue", -20 }` pour lightness, tuples `{ "red", "line", 80 }` pour mix). Les fichiers `highlights/*.lua` utilisent directement les valeurs hex de `base_30`.

## Changelog
- 2026-03-22: Migration hors NvChad — fork local de base46 (init, colors, load, integrations). Suppression du systeme de cache/compilation.
- 2026-03-20: Fiche initiale documentant l'architecture complete du systeme de theming.
