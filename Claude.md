# Documentation Configuration Neovim

## Vue d'ensemble

Configuration Neovim basée sur **NvChad v2.5**, un framework moderne qui fournit un environnement pré-configuré, performant et esthétique pour Neovim.

- **Version NvChad:** v2.5
- **Version UI:** v3.0
- **Gestionnaire de plugins:** lazy.nvim
- **Thème actuel:** sonokai (personnalisé)

## Structure du projet

```
/home/droid/.config/nvim/
├── init.lua                 # Point d'entrée principal
├── lazy-lock.json          # Verrouillage des versions de plugins
├── .stylua.toml           # Configuration du formateur Lua
├── README.md              # Documentation
├── LICENSE                # Licence
├── Claude.md              # Documentation personnalisée
└── lua/
    ├── autocmds.lua       # Auto-commandes Vim
    ├── chadrc.lua         # Configuration NvChad
    ├── mappings.lua       # Raccourcis clavier personnalisés
    ├── options.lua        # Options Vim personnalisées
    ├── configs/           # Configurations des plugins
    │   ├── conform.lua    # Configuration du formatage
    │   ├── lazy.lua       # Configuration lazy.nvim
    │   └── lspconfig.lua  # Configuration des serveurs LSP
    ├── plugins/
    │   └── init.lua       # Spécifications des plugins
    └── themes/
        └── sonokai.lua    # Thème Sonokai personnalisé
```

## Fichiers principaux

### init.lua
Point d'entrée qui :
- Configure le répertoire de cache pour les thèmes (base46)
- Définit la touche leader à `<Space>`
- Bootstrap lazy.nvim (installation automatique si absent)
- Charge NvChad et les plugins utilisateur
- Charge les thèmes et la statusline
- Importe options, autocmds et mappings

### lua/chadrc.lua
Configuration principale de NvChad :
- **Thème:** sonokai (personnalisé)
- **Surcharges actives:** italiques pour commentaires et keywords
- Contient des exemples commentés pour :
  - Configuration du dashboard (nvdash)
  - Paramètres de tabufline

### lua/options.lua
Options Vim personnalisées :
- `wrap = false` - Désactive le retour à la ligne
- `scrolloff = 5` - Garde 5 lignes visibles au-dessus/en-dessous du curseur
- `sidescrolloff = 15` - Offset de défilement horizontal
- `cursorline = true` - Met en surbrillance la ligne courante
- `showmatch = true` - Affiche les parenthèses correspondantes
- `mouse = "a"` - Active la souris dans tous les modes

### lua/mappings.lua
Raccourcis clavier personnalisés :
- `;` → `:` en mode normal (accès rapide aux commandes)
- `jk` → `<ESC>` en mode insertion (échappement rapide)
- `gl` → Ouvrir diagnostic sous le curseur
- `<C-s>` pour sauvegarder (commenté)

**Trouble.nvim :**
- `<leader>xx` - Toggle diagnostics (tous les fichiers)
- `<leader>xX` - Toggle diagnostics (buffer actuel uniquement)
- `<leader>cs` - Toggle symbols (plan du document)
- `<leader>cl` - Toggle LSP definitions/references
- `<leader>xL` - Toggle location list
- `<leader>xQ` - Toggle quickfix list

## Plugins installés

### Gestionnaire de plugins
**lazy.nvim (v0.85.3)**
- Chargement différé par défaut
- Icônes personnalisées pour l'interface
- Optimisations de performance (25+ plugins Vim par défaut désactivés)

### Plugins principaux

#### Complétion
- **nvim-cmp** - Moteur de complétion
- **cmp-nvim-lsp** - Source de complétion LSP
- **cmp-buffer** - Complétion depuis le buffer
- **cmp-async-path** - Complétion de chemins
- **cmp-nvim-lua** - Complétion API Lua Neovim
- **LuaSnip + cmp_luasnip** - Moteur de snippets
- **friendly-snippets** - Collection de snippets

#### Édition
- **nvim-treesitter** - Coloration syntaxique et analyse
- **indent-blankline.nvim** - Guides d'indentation
- **nvim-autopairs** - Fermeture automatique des parenthèses
- **which-key.nvim** - Aide pour les raccourcis clavier

#### Navigation
- **telescope.nvim** - Recherche floue
- **nvim-tree.lua** - Explorateur de fichiers

#### Git
- **gitsigns.nvim** - Intégration Git

#### Développement
- **nvim-lspconfig** - Configuration LSP
  - Serveurs actifs : HTML, CSS, **basedpyright (Python)**
  - Type checking : standard mode
  - Auto-import completions activées
- **conform.nvim** - Formatage de code
  - Formateurs :
    - stylua pour Lua
    - **ruff pour Python** (format + organize imports)
  - Format à la sauvegarde : **activé** (timeout 500ms)
- **mason.nvim** - Installateur LSP/DAP/linters
  - Installation automatique : basedpyright, lua-language-server, html-lsp, css-lsp, stylua, ruff
- **trouble.nvim** - Liste améliorée des diagnostics
  - Diagnostics, quickfix, location list
  - Preview automatique
  - Intégration LSP et Telescope
  - Icônes et couleurs personnalisées Sonokai
- **nvim-web-devicons** - Icônes de fichiers
- **plenary.nvim** - Bibliothèque utilitaire Lua

### Écosystème NvChad
- **NvChad** (v2.5) - Framework principal
- **base46** (v3.0) - Moteur de thèmes
- **ui** (v3.0) - Composants d'interface
- **menu, volt, minty** - Utilitaires UI

## Thème Sonokai Personnalisé

Thème personnalisé basé sur [Sonokai](https://github.com/sainnhe/sonokai) (variante Default), un schéma de couleurs à haut contraste inspiré de Monokai Pro.

### Caractéristiques
- **Palette:** Basée sur la variante Default de Sonokai, mappée exactement comme VSCode
- **Style:** Dark theme avec couleurs vibrantes et chaleureux
- **Optimisations:** Support complet de Treesitter et LSP semantic tokens
- **UI complète:** Tous les éléments UI (statusline, telescope, cmp, diagnostics, diff, etc.)
- **Terminal:** Couleurs ANSI 16 configurées selon Sonokai
- **Backgrounds:** Editor, sidebar, panel, hover, tous mappés selon VSCode
- **Italiques:** Activés pour commentaires, keywords et built-in functions
- **Base16:** Respect des conventions Base16 pour la syntaxe

### Palette de couleurs
**Syntaxe (mappée selon VSCode Sonokai):**
- **Rouge** (#fc5d7c) - Keywords, opérateurs, control flow, tags HTML
- **Orange** (#f39660) - Variables built-in (this, self) italic
- **Jaune** (#e7c664) - Strings, headings Markdown
- **Vert** (#9ed072) - Fonctions, méthodes, liens Markdown
- **Cyan** (#76cce0) - Types, classes, interfaces, attributs HTML italic
- **Purple** (#b39df3) - Nombres, constantes, booléens, escapes
- **Gris** (#7f8490) - Commentaires
- **Blanc** (#e2e2e3) - Variables, paramètres, propriétés

**UI (selon VSCode Sonokai):**
- **Editor background:** #2c2e34
- **Gutter/Line numbers background:** #181819 (darker_black - plus sombre que l'éditeur)
- **Activity bar:** #181819 (darker_black)
- **Sidebar:** #222327
- **Panel/Hover:** #30323a
- **Statusline:** #222327
- **Selection:** #3b3e48
- **Line highlight:** #30323a
- **Cursor line number:** #e2e2e3 (white) sur fond #181819
- **Line numbers:** #7f8490 (grey_fg) sur fond #181819
- **Borders:** #414550
- **Indent guides active:** #414550
- **Popup menu:** #33363f background, #3b3e48 selection
- **Badges:** #a7df78 (vibrant_green) / #85d3f2 (nord_blue)

### Highlights personnalisés (polish_hl)
**Treesitter (conforme à VSCode):**
- Variables standard en blanc (foreground)
- Variables built-in (this, self) en orange italic
- Functions en vert (toutes)
- Operators en rouge
- Keywords en rouge italic
- Constantes/nombres/booléens en purple
- String escapes en purple
- Tags HTML en rouge, attributs en cyan italic
- Properties en blanc
- Commentaires TODO/WARNING/NOTE/DANGER avec backgrounds colorés
- Markdown headings en jaune bold (tous niveaux)
- Markdown links en vert underline

**LSP:**
- Classes/namespaces/interfaces en cyan
- Enums en cyan, enumMembers en purple
- Parameters/properties/variables en blanc
- Functions/methods en vert
- Decorators en cyan

**UI (Telescope, CMP, etc.):**
- **Telescope:** Sélection #3b3e48, matching en vert, borders #414550
- **CMP:** Match en vert bold, function/method en vert, class/struct en cyan, keywords en rouge
- **Diagnostics:** Error rouge, Warning jaune, Info cyan, Hint vert
- **Gutter signs:** Git (add/change/delete) et diagnostics sur fond #181819 (darker_black)
- **Diff backgrounds:** Add #394634 (vert foncé), Change #354157 (bleu foncé), Delete #55393d (rouge foncé)
- **Search:** Background rouge #fc5d7c, IncSearch purple #b39df3
- **Visual mode:** Background #3b3e48
- **Pmenu:** Background #33363f, sélection #3b3e48
- **Float windows:** Background #30323a, border #414550

**Terminal ANSI:**
- Black: #414550
- Red: #fc5d7c
- Green: #9ed072
- Yellow: #e7c664
- Blue: #76cce0
- Magenta: #b39df3
- Cyan: #f39660 (orange dans Sonokai)
- White: #e2e2e3
- Bright colors: identiques aux normales

### Fichier de configuration
Location: `/home/droid/.config/nvim/lua/themes/sonokai.lua`

Activation: via `M.base46.theme = "sonokai"` dans `lua/chadrc.lua`

Pour revenir à un thème par défaut, modifier `theme = "nom_du_theme"` dans chadrc.lua et redémarrer Neovim ou utiliser `:Telescope themes`.

## Trouble.nvim - Liste de diagnostics améliorée

Plugin pour afficher une liste jolie et fonctionnelle des diagnostics, erreurs, warnings, et autres informations LSP.

### Fonctionnalités
- **Diagnostics** - Vue consolidée de tous les problèmes de code
- **Quickfix & Location list** - Accès rapide aux résultats de recherche
- **LSP Symbols** - Plan du document avec fonctions, classes, etc.
- **LSP References** - Toutes les références d'un symbole
- **Preview automatique** - Aperçu du code dans split
- **Filtrage** - Par buffer, sévérité, type
- **Icônes** - Visuellement clair avec icônes personnalisées
- **Intégration Sonokai** - Couleurs parfaitement intégrées au thème

### Configuration
**Fichier:** `/home/droid/.config/nvim/lua/configs/trouble.lua`

Options principales :
- Position : Bottom (10 lignes de hauteur)
- Preview automatique activé
- Auto-refresh activé
- Guides d'indentation activés
- Max 200 items affichés
- Icônes personnalisées pour tous les types

### Raccourcis clavier
- `<leader>xx` - **Diagnostics** - Tous les diagnostics du projet
- `<leader>xX` - **Buffer diagnostics** - Diagnostics du fichier actuel
- `<leader>cs` - **Symbols** - Plan du document (fonctions, classes, variables)
- `<leader>cl` - **LSP** - Définitions, références, implémentations (panneau droit)
- `<leader>xL` - **Location list** - Liste de locations
- `<leader>xQ` - **Quickfix** - Liste quickfix

### Utilisation
1. Ouvrir trouble avec un raccourci (ex: `<leader>xx`)
2. Naviguer avec `j`/`k`
3. Appuyer sur `<Enter>` pour aller au diagnostic
4. `q` pour fermer
5. `?` pour voir l'aide

### Intégration thème
Couleurs personnalisées dans `lua/themes/sonokai.lua` :
- Errors : Rouge #fc5d7c
- Warnings : Jaune #e7c664
- Info : Cyan #76cce0
- Hints : Vert #9ed072
- Fichiers : Cyan
- Counts : Purple avec background

## Configuration Python (basedpyright + ruff)

Support complet Python avec LSP moderne et formatage rapide.

### Basedpyright (LSP)
**Fichier:** `/home/droid/.config/nvim/lua/configs/lspconfig.lua`

Configuration :
- **Type checking:** standard (basic, standard, strict, off)
- **Auto-search paths:** Activé
- **Library code for types:** Activé
- **Diagnostic mode:** openFilesOnly (ou workspace)
- **Auto-import completions:** Activé
- **Détection automatique d'environnement:** Poetry, .venv, venv, ou système

Fonctionnalités :
- Complétion intelligente avec types
- Go to definition/references
- Diagnostics en temps réel
- Renommage de symboles
- Auto-imports

**Support Poetry :**
Basedpyright détecte automatiquement l'environnement virtuel Poetry du projet.
- Détection via `poetry env info --path`
- Fallback sur `.venv` local puis `venv` puis python système
- Commandes utiles :
  - `:PyPath` - Afficher le chemin Python détecté
  - `:PyReload` - Redémarrer le LSP avec le bon environnement

### Ruff (Formatter & Linter)
**Fichier:** `/home/droid/.config/nvim/lua/configs/conform.lua`

Configuration :
- **Format:** `ruff format` - Formatage rapide compatible Black
- **Organize imports:** `ruff check --select I --fix` - Organisation automatique des imports
- **Format on save:** Activé (500ms timeout)

Fonctionnalités :
- Formatage ultra-rapide (écrit en Rust)
- Organisation des imports (suppression des inutilisés, tri)
- Compatible avec Black, isort, pyupgrade
- Linting intégré (optionnel)

### Installation
Les outils sont installés automatiquement via Mason :
```vim
:Mason
```
Ou manuellement :
```bash
pip install basedpyright ruff
```

### Utilisation
- **Format manuel:** `<leader>fm` (format buffer)
- **Format auto:** Sauvegarde automatique (`<C-s>` ou `:w`)
- **Diagnostics:** `<leader>xx` (Trouble) ou `gl` (float)
- **Go to definition:** `gd`
- **References:** Via Trouble `<leader>cl`
- **Vérifier Python path:** `:PyPath`
- **Recharger LSP:** `:PyReload`

### Workflow Poetry
**1. Créer un projet Poetry :**
```bash
cd mon-projet
poetry init
poetry add numpy pandas  # Ajouter des dépendances
```

**2. Ouvrir Neovim dans le projet :**
```bash
nvim .
```

**3. Le LSP détecte automatiquement l'environnement Poetry**
- Basedpyright trouve automatiquement l'environnement virtuel
- Les imports et complétion fonctionnent avec les packages Poetry
- Type checking fonctionne avec les dépendances installées

**4. Si le LSP ne détecte pas l'environnement :**
```vim
:PyPath       " Vérifier le chemin détecté
:PyReload     " Forcer le rechargement
```

**5. Ajouter de nouvelles dépendances :**
```bash
poetry add requests
```
Puis dans Neovim :
```vim
:PyReload     " Recharger pour voir les nouvelles dépendances
```

**Structure de détection :**
1. **Poetry** - `poetry env info --path` (priorité)
2. **.venv** - Dossier `.venv` dans le projet
3. **venv** - Dossier `venv` dans le projet
4. **Système** - Python système en dernier recours

## Configuration du formatage

### StyLua (.stylua.toml)
- Indentation : 2 espaces
- Largeur de colonne : 120 caractères
- Fin de ligne : Unix
- Guillemets : doubles préférés
- Pas de parenthèses d'appel

## Patterns et conventions

### Architecture modulaire
- Séparation claire entre configurations core (`lua/`) et configurations plugins (`lua/configs/`)
- Configuration de chaque plugin isolée dans son propre fichier
- Pattern d'extension : importer les défauts NvChad, puis ajouter personnalisations

### Stratégie de chargement différé
- Tous les plugins chargés paresseusement par défaut
- Temps de démarrage minimal
- Chargement basé sur les événements

### Style de configuration
```lua
require "nvchad.module"  -- Charger les défauts NvChad
-- add yours here!      -- Marqueur pour personnalisations
```

### Optimisations de performance
- Liste agressive de plugins désactivés (25+ plugins Vim par défaut)
- Chargement différé pour tous les plugins
- Configuration minimale par défaut avec fonctionnalités opt-in

## État actuel

### Fichiers modifiés
- `lua/chadrc.lua` - Configuration du thème
- `lua/options.lua` - Options Vim personnalisées

### Configuration
- Setup minimal mais fonctionnel
- Nombreuses fonctionnalités commentées à activer selon les besoins
- Prêt pour personnalisation supplémentaire

## Prochaines étapes possibles

1. Activer le formatage à la sauvegarde dans `lua/configs/conform.lua`
2. Ajouter d'autres serveurs LSP dans `lua/configs/lspconfig.lua`
3. Personnaliser les raccourcis clavier dans `lua/mappings.lua`
4. Configurer le dashboard dans `lua/chadrc.lua`
5. Ajouter des auto-commandes personnalisées dans `lua/autocmds.lua`
