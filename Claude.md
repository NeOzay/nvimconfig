# Documentation Configuration Neovim

## Vue d'ensemble

Configuration Neovim basée sur **NvChad v2.5**, un framework moderne qui fournit un environnement pré-configuré, performant et esthétique pour Neovim.

- **Version NvChad:** v2.5
- **Version UI:** v3.0
- **Gestionnaire de plugins:** lazy.nvim
- **Thème actuel:** sonokai (personnalisé)

## Structure du projet

```
~/.config/nvim/
├── init.lua                 # Point d'entrée principal
├── lazy-lock.json          # Verrouillage des versions de plugins
├── lua/
│   ├── chadrc.lua         # Configuration NvChad principale
│   ├── options.lua        # Options Vim personnalisées
│   ├── mappings.lua       # Raccourcis clavier
│   ├── autocmds.lua       # Auto-commandes Vim
│   ├── configs/           # Configurations des plugins
│   │   ├── conform.lua    # Formatage (stylua, ruff)
│   │   ├── lazy.lua       # Configuration lazy.nvim
│   │   ├── lspconfig.lua  # Configuration LSP (basedpyright, etc.)
│   │   └── neo-tree.lua   # Configuration Neo-tree
│   ├── plugins/
│   │   └── init.lua       # Spécifications des plugins
│   ├── highlights/        # Highlights personnalisés
│   │   └── neo-tree.lua   # Highlights Neo-tree pour thème Sonokai
│   └── themes/
│       └── sonokai.lua    # Thème personnalisé
```

## Fichiers principaux

### init.lua
Point d'entrée qui :
- Configure le cache des thèmes (base46)
- Définit la touche leader (`<Space>`)
- Bootstrap lazy.nvim (installation automatique)
- Charge NvChad, plugins, thèmes, et imports personnalisés
- Charge les highlights Neo-tree via `vim.schedule()` après l'initialisation du thème

### lua/chadrc.lua
Configuration NvChad :
- Thème actif : `sonokai`
- Surcharges UI : italiques pour commentaires et keywords
- Exemples commentés : dashboard, tabufline

### lua/options.lua
Options Vim personnalisées :
- `wrap = false` - Pas de retour à la ligne
- `scrolloff = 5` - Offset de scroll vertical
- `cursorline = true` - Highlight ligne courante
- `mouse = "a"` - Support souris

### lua/mappings.lua
Raccourcis clavier personnalisés (voir fichier pour la liste complète)

### lua/configs/lspconfig.lua
Configuration LSP :
- **basedpyright** (Python) : type checking standard, auto-imports, détection Poetry
- **html-lsp, css-lsp** : Support web
- Détection automatique environnements virtuels (Poetry > .venv > venv > système)

### lua/configs/conform.lua
Configuration formatage :
- **stylua** : Formatage Lua
- **ruff** : Formatage Python + organisation imports
- Format à la sauvegarde : **activé** (500ms timeout)

## Plugins principaux

### Écosystème NvChad
- **NvChad** (v2.5) - Framework
- **base46** (v3.0) - Moteur de thèmes
- **ui** (v3.0) - Composants UI
- **lazy.nvim** - Gestionnaire de plugins

### Complétion
- nvim-cmp, cmp-nvim-lsp, cmp-buffer, cmp-async-path
- LuaSnip + friendly-snippets

### Édition & Navigation
- nvim-treesitter - Coloration syntaxique
- telescope.nvim - Recherche floue
- **neo-tree.nvim** - Explorateur de fichiers moderne (avec support thème Sonokai)
- nvim-tree.lua - Explorateur de fichiers classique
- which-key.nvim - Aide raccourcis
- indent-blankline.nvim, nvim-autopairs

### Développement
- nvim-lspconfig - Configuration LSP
- conform.nvim - Formatage de code
- mason.nvim - Installateur LSP/DAP/linters
- trouble.nvim - Liste améliorée diagnostics
- gitsigns.nvim - Intégration Git

## Thème Sonokai

Thème personnalisé basé sur [Sonokai](https://github.com/sainnhe/sonokai) (variante Default), inspiré de Monokai Pro.

**Caractéristiques :**
- Dark theme haut contraste
- Support complet Treesitter et LSP semantic tokens
- Italiques pour commentaires, keywords, built-in variables
- Couleurs ANSI terminal configurées
- Intégrations complètes : Trouble, Telescope, CMP, Neo-tree, Git signs

**Fichiers :**
- `lua/themes/sonokai.lua` - Définition du thème (base_30, base_16, polish_hl)
- `lua/highlights/neo-tree.lua` - Highlights Neo-tree (chargés depuis init.lua)

**Activation :** `M.base46.theme = "sonokai"` dans `lua/chadrc.lua`

**Note :** Les highlights Neo-tree sont chargés dynamiquement via `init.lua` car base46 ne fournit pas d'intégration native pour neo-tree. Le fichier `highlights/neo-tree.lua` exporte une fonction qui applique les highlights après l'initialisation du thème.

**Palette principale :**
- Rouge (#fc5d7c) - Keywords, operators
- Vert (#9ed072) - Functions, methods
- Jaune (#e7c664) - Strings
- Cyan (#76cce0) - Types, classes
- Purple (#b39df3) - Numbers, constants
- Orange (#f39660) - Variables built-in
- Gris (#7f8490) - Commentaires

## Configuration Python

**LSP : basedpyright**
- Type checking : standard
- Auto-imports activés
- Détection automatique Poetry/venv
- Commandes : `:PyPath`, `:PyReload`

**Formatter : ruff**
- Format + organisation imports
- Compatible Black, isort
- Format on save activé

**Workflow :**
1. Le LSP détecte automatiquement l'environnement virtuel
2. Ordre de détection : `poetry env info --path` > `.venv` > `venv` > système
3. Si problème : `:PyPath` puis `:PyReload`

## Patterns et conventions

### Architecture modulaire
- Séparation `lua/` (core) et `lua/configs/` (plugins)
- Configuration isolée par plugin
- Pattern d'extension : importer défauts NvChad → ajouter personnalisations

```lua
require "nvchad.module"  -- Charger les défauts NvChad
-- add yours here!      -- Marqueur pour personnalisations
```

### Optimisations de performance
- Chargement différé par défaut pour tous les plugins
- 25+ plugins Vim par défaut désactivés
- Configuration minimale avec fonctionnalités opt-in
- Temps de démarrage minimal

## État actuel

**Fichiers modifiés :**
- `init.lua` - Chargement highlights Neo-tree
- `lua/chadrc.lua` - Thème et UI
- `lua/options.lua` - Options Vim
- `lua/plugins/init.lua` - Plugins ajoutés
- `lua/configs/lspconfig.lua` - Configuration Python
- `lua/configs/conform.lua` - Formatage activé
- `lua/themes/sonokai.lua` - Thème personnalisé

**Fichiers créés :**
- `lua/configs/neo-tree.lua` - Configuration Neo-tree complète
- `lua/configs/trouble.lua` - Configuration Trouble
- `lua/highlights/neo-tree.lua` - Highlights Neo-tree pour Sonokai

**Configuration :**
- Setup fonctionnel avec Python, web dev
- Formatage automatique activé
- Prêt pour extension selon les besoins
