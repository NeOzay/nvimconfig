# Theme & Highlights System

## Role
Système de theming multi-couche basé sur Sonokai, avec highlights per-plugin chargés dynamiquement via lazy.nvim.

## Files
- Theme: `lua/themes/sonokai.lua`
- base46 local fork: `lua/base46/` (init, colors, loader, palette, config, integrations/)
- Config utilisateur: `lua/base46/config.lua` (remplace l'ancien `lua/chadrc.lua`)
- User integrations: `lua/highlights/<plugin>.lua`

## Moment de chargement

Dans `init.lua` :
1. `require("base46.load").apply()` → `base46.setup()` applique les 3 premières couches (step 4)
2. `loader.setup_autocmds()` enregistre les autocmds pour les intégrations per-plugin (step 4)
3. Les intégrations user/base46 se chargent ensuite via `LazyLoad` et hot-reload

## Architecture

### 3 couches appliquées en une passe dans `base46/init.lua → load()`

1. **Integration defaults (`lua/base46/integrations/defaults/`)**
   - `defaults.lua` : Normal, Pmenu, Cursor, Visual, Search, etc.
   - `syntax.lua` : Comment, Function, Keyword, String, Type, etc.
   - + autres fichiers dans `defaults/` (treesitter, lsp, git…)
   - Tous mergés en une seule table `all_hl` avant application.

2. **Theme polish (`lua/themes/sonokai.lua` → `polish_hl`)**
   - Highlights groupés par catégorie (`treesitter`, `lsp`, `syntax`, `defaults`, `git`, `trouble`…)
   - Mergé avec `force` par-dessus les defaults.

3. **User overrides (`lua/base46/config.lua` → `hl_override`)**
   - Overrides de groupes existants (ex: `@keyword` → blue italic).
   - Même syntaxe base46 : `"blue"`, `{ "blue", -20 }`, `{ "red", "line", 80 }`.
   - **Pas de `hl_add`** — tout passe par `hl_override` (nouveaux groupes inclus).
   - **`extended_palette`** : définit des couleurs nommées custom (ex: `Type`, `Field`, `code_bg`) utilisables dans `hl_override` et les intégrations.

Les 3 couches sont résolues via `base46.palette.resolve()` puis appliquées d'un coup avec `nvim_set_hl`.

### Per-plugin integrations (couche 4)

Chargées dynamiquement par `base46/loader.lua`. Deux sources :
- **User** : `lua/highlights/<name>.lua` — prioritaire.
- **Base46** : `lua/base46/integrations/<name>.lua` — fallback.

Lors du chargement d'une intégration (`loader.load_integration(name)`) :
1. Charge le fichier user ou base46 (retourne une **table** `Base46HLTable`).
2. Merge `polish_hl[name]` du thème si présent (user → `keep`, base46 → `force`).
3. Résout les couleurs palette.
4. Applique avec `nvim_set_hl`.

#### Déclencheurs
- **`LazyLoad`** : quand un plugin se charge, `load_matching(plugin_name)` cherche une intégration par sous-chaîne dans le nom.
- **Hot-reload (`BufWritePost`)** : sauvegarde d'un fichier `lua/highlights/*.lua` → invalide le cache require et recharge instantanément.
- **VeryLazy** : commenté (`--M.load_matching`) — non actif actuellement.

### User integrations existantes (`lua/highlights/`)

| Fichier | Plugin cible | Particularités |
|---|---|---|
| `codediff.lua` | codediff | |
| `snacks.lua` | snacks.nvim | `mix_colors_group()`, `change_hex_lightness()` |
| `markview.lua` | markview.nvim | |
| `neogit.lua` | neogit | ~130 groupes |
| `neo-tree.lua` | neo-tree.nvim | Git status, diagnostics, UI |
| `trouble.lua` | trouble.nvim | |

### base46 integrations (`lua/base46/integrations/`)
~35 intégrations pré-construites : `blink`, `dap`, `navic`, `telescope`, `neogit`, `trouble`, `markview`, etc. Les intégrations user ont la priorité si elles portent le même nom.

### base46 config (`lua/base46/config.lua`)
Remplace `chadrc.lua`. Contient :
- `theme` : chemin du thème (ex: `"themes.sonokai"`)
- `integrations` : module path des intégrations user (`"highlights"`)
- `extended_palette` : couleurs custom réutilisables dans tout le système
- `hl_override` : overrides finaux (syntaxe base46 complète)

### Color utilities (`lua/base46/colors.lua`)
- `hi_pathwork(fg, bg, opts?)` : groupe composite (fg d'un groupe + bg d'un autre). Caché, recalculé sur `ColorScheme`.
- `mix_colors_group(group1, group2, strength?, ground?)` : mixe les couleurs de 2 groupes hl.
- `mix(c1, c2, pct)`, `change_hex_lightness(hex, delta)` : utilitaires hex bas niveau.

### base46 palette (`lua/base46/palette.lua`)
- `get_palette()` : fusionne `base_30` + `base_16` + `extended_palette` thème + `extended_palette` config.
- `resolve_color(val, palette)` : résout récursivement `"name"`, `{"name", delta}`, `{"c1", "c2", pct}`.
- `resolve(tb, palette)` : applique `resolve_color` sur fg/bg/sp de toute la table.

## Syntaxe des couleurs (base46)

| Syntaxe | Effet |
|---------|-------|
| `"blue"` | Nom palette → hex |
| `{ "blue", -20 }` | Lightness shift (négatif = plus sombre) |
| `{ "orange", "line", 80 }` | Mix : 20% orange + 80% line |
| `{ { "orange", -15 }, "purple", 60 }` | Mix récursif (orange assombri + purple) |

## Commandes
- `:Base46Reload` — recharge tous les highlights et intégrations (invalide tous les caches require).
- `:Base46Integrations` — liste les intégrations chargées avec leur source (user/base46).

## Palette Sonokai (base_30)

| Nom | Hex | Usage principal |
|---|---|---|
| `red` | `#fc5d7c` | Keywords conditionnels, erreurs |
| `green` | `#9ed072` | Fonctions, ajouts, succès |
| `yellow` | `#e7c664` | Strings, warnings |
| `cyan/blue` | `#76cce0` | Types, keywords, info |
| `purple` | `#b39df3` | Modules, namespaces, semantic tokens |
| `orange` | `#f39660` | Paramètres, builtins |
| `grey_fg` | `#7f8490` | Commentaires |
| `black` | `#2c2e34` | Background éditeur |
| `one_bg` | `#222327` | Background sidebar/gutter |
| `one_bg2` | `#363944` | Sélections, hover |
| `line` | `#414550` | Bordures, indentation |

## Gotchas

- **Ordre** : defaults → polish_hl → hl_override (une passe) → puis intégrations per-plugin au LazyLoad (dernier gagne).
- **User > base46** : une intégration `lua/highlights/neogit.lua` prend la priorité sur `base46/integrations/neogit.lua`.
- **Les fichiers `highlights/*.lua` retournent une table** (plus une fonction) — le loader fait `require()` directement.
- **VeryLazy commenté** : les intégrations ne se chargent pas au démarrage pour les plugins déjà chargés. Utiliser `:Base46Reload` pour forcer.
- **`hi_pathwork` est caché** : recalculé uniquement sur `ColorScheme`, peut être stale si un highlight source change sans changement de thème.
- **`extended_palette`** peut être défini dans config ET dans le thème — config écrase le thème pour les noms en collision.

## Changelog
- 2026-06-05 : Réécriture complète. Suppression chadrc.lua → config.lua. Documentation extended_palette, loader deux sources (user/base46), tables vs fonctions, utils déplacés dans base46/colors.lua, commandes Base46Reload/Base46Integrations.
- 2026-03-22 : Migration hors NvChad — fork local de base46.
- 2026-03-20 : Fiche initiale.
