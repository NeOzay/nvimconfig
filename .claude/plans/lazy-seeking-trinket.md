# Thème distinct pour le terminal intégré (`term_theme`)

## Contexte

Le terminal intégré (snacks.terminal) hérite aujourd'hui aveuglément des highlights globaux
posés par le thème principal (`base46/config.lua` → `theme = "themes.sonokai"`) : `Normal`,
`terminal_color_0..15`. Impossible de lui donner une identité visuelle propre sans modifier le
thème principal.

Une première piste (namespace de highlight posé via `nvim_win_set_hl_ns` sur un `TermOpen` ad hoc,
couleurs codées en dur) a été écartée : elle contourne le moteur `base46` au lieu de s'appuyer
dessus. L'approche retenue ici fait porter la fonctionnalité par `base46` lui-même, en ajoutant une
clé de config `term_theme` (chemin de module, comme `theme`) résolue par le même mécanisme que le
thème principal — `term_theme == theme` par défaut.

L'exploration du code (voir `lua/base46/init.lua`, `loader.lua`, `palette.lua`,
`lua/themes/sonokai.lua`, `lua/highlights/snacks.lua`, `lua/plugins/snacks/terminal.lua`) a établi :

- Le thème actif est une **chaîne = chemin de module** (`M.config.theme`), résolue via
  `M.get_theme_tb(tb_type)` (`return require(M.config.theme)[tb_type]`, `base46/init.lua:41-43`).
  Aucun cache disque — seul `package.loaded` (invalidé dans `M.reload()`).
- Les couleurs ANSI du terminal (`vim.g.terminal_color_0..15`) sont **le seul** point du code déjà
  dédié au terminal : posées une fois dans `load()` (`base46/init.lua:86-92`) depuis
  `base_16_terminal` du thème actif. Elles sont globales à l'instance Nvim (contrainte native de
  `:h terminal_color_`) mais ne sont consommées que par les buffers `:terminal` — donc les résoudre
  depuis un thème différent au démarrage suffit, sans logique de bascule `TermOpen`/`TermClose`.
- Le fond/texte du widget terminal (`Normal`) n'a **aucun** highlight dédié aujourd'hui. Le pattern
  déjà utilisé dans ce repo pour un widget snacks avec ses propres couleurs est
  `lua/highlights/snacks.lua` (groupes `SnacksNormal`/`SnacksNormalNC`) + `win.wo.winhighlight`
  (table) côté config du widget (`lua/plugins/snacks/picker/init.lua:28`). On réutilise exactement
  ce pattern pour le terminal, mais en résolvant la palette depuis `term_theme` plutôt que `theme`.

## Hors-périmètre

- Créer un second thème Lua avec des couleurs réellement différentes de sonokai : ce chantier pose
  l'infrastructure `term_theme`, pas un nouveau thème. Par défaut `term_theme = nil` → aucun
  changement visuel (fallback sur `theme`). L'utilisateur pourra créer/pointer un module de thème
  distinct plus tard pour en voir l'effet.
- Toute bascule dynamique des couleurs ANSI par fenêtre/terminal (impossible nativement — un seul
  jeu de `terminal_color_N` global par instance Nvim).
- `:Base46Reload` reste global (recharge thème + term_theme ensemble) ; pas de commande de reload
  séparée pour le terminal seul.

## Implémentation

### 1. `lua/base46/init.lua`

- Ajouter au `@class Base46Config` : `---@field term_theme? string` (chemin de module ; `nil` =
  fallback sur `theme`).
- Nouvelle fonction miroir de `get_theme_tb`, mêmes `@overload` :
  ```lua
  ---@param tb_type keyof Base46Theme
  ---@return table|string|nil
  ---@overload fun(tb_type: "base_30"): Base30Table
  ---@overload fun(tb_type: "base_16"): Base16Table
  ---@overload fun(tb_type: "base_16_terminal"): Base16TerminalTable?
  ---@overload fun(tb_type: "extended_palette"): table<string, string>?
  ---@overload fun(tb_type: "polish_hl"): table<string, Base46HLTable>?
  ---@overload fun(tb_type: "type"): "dark"|"light"
  function M.get_term_theme_tb(tb_type)
      return require(M.config.term_theme or M.config.theme)[tb_type]
  end
  ```
- Dans `load()` (ligne 87) : remplacer `M.get_theme_tb("base_16_terminal")` par
  `M.get_term_theme_tb("base_16_terminal")`.
- Dans `M.reload()` (après la ligne `package.loaded[M.config.theme] = nil`) : ajouter
  `if M.config.term_theme then package.loaded[M.config.term_theme] = nil end` pour que
  `:Base46Reload` invalide aussi le thème terminal s'il diffère du thème principal.

### 2. `lua/base46/config.lua`

Ajouter à la racine de la table retournée, à côté de `theme` :
```lua
theme = "themes.sonokai",
term_theme = nil, -- nil = même thème que `theme` ; sinon chemin de module dédié au terminal
```

### 3. `lua/highlights/snacks.lua`

Ajouter, à côté du `local colors = require("base46").get_theme_tb("base_30")` existant, une
palette dédiée au terminal résolue via `term_theme`, et deux nouveaux groupes :
```lua
local term_colors = require("base46").get_term_theme_tb("base_30") ---@as Base30Table
```
```lua
TerminalNormal = { fg = term_colors.white, bg = term_colors.black },
TerminalNormalNC = { fg = term_colors.white, bg = term_colors.black },
```
Ce fichier est déjà rechargé automatiquement (match `snacks.nvim` via `LazyLoad`, cf.
`base46/loader.lua:93-104`) — aucune nouvelle plomberie de chargement nécessaire.

### 4. `lua/plugins/snacks/terminal.lua`

Dans `opts.terminal.win.wo`, ajouter le mapping `winhighlight` (même forme table que
`picker/init.lua:28`) :
```lua
wo = {
    winbar = "",
    winhighlight = {
        Normal = "TerminalNormal",
        NormalNC = "TerminalNormalNC",
        EndOfBuffer = "TerminalNormal",
    },
},
```

### 5. Documentation

- `docs/plugins/theme-highlights.md` : ajouter une note sur `term_theme` (clé de config,
  `get_term_theme_tb`, et le fait que `base_16_terminal` + `TerminalNormal*` en dépendent).
- `docs/plugins/snacks.md` (ou créer une section terminal si absente) : documenter les groupes
  `TerminalNormal`/`TerminalNormalNC` et leur lien avec `term_theme`.

## Vérification

- `:Base46Reload` ne doit produire aucune erreur (comportement par défaut inchangé, `term_theme`
  nil).
- Ouvrir le terminal (`<C-ù>`) : rendu identique à avant (fond/texte/ANSI = thème sonokai), car
  `term_theme` est `nil` par défaut.
- Test de bascule manuelle : dans `lua/base46/config.lua`, mettre temporairement
  `term_theme = "themes.sonokai"` (même module) puis `:Base46Reload` → aucune régression, les deux
  chemins (`get_theme_tb` et `get_term_theme_tb`) doivent produire un rendu identique tant qu'ils
  pointent vers le même module.
- `:Base46Integrations` doit toujours lister `snacks` comme intégration chargée.
- Vérifier `emmylua_ls` (aucun diagnostic sur les nouveaux champs/fonctions typés).
