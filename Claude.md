# Documentation Configuration Neovim

## Vue d'ensemble

Configuration Neovim basée sur **NvChad v2.5**, un framework moderne qui fournit un environnement pré-configuré, performant et esthétique pour Neovim.

- **Version NvChad:** v2.5
- **Version UI:** v3.0
- **Gestionnaire de plugins:** lazy.nvim
- **Thème actuel:** sonokai (personnalisé)
- **Système de complétion:** blink.cmp (migration depuis nvim-cmp)

## Structure du projet

```
~/.config/nvim/
├── init.lua                          # Point d'entrée principal
├── lazy-lock.json                    # Verrouillage des versions de plugins
├── lua/
│   ├── chadrc.lua                    # Configuration NvChad principale
│   ├── options.lua                   # Options Vim personnalisées
│   ├── mappings.lua                  # Raccourcis clavier
│   ├── autocmds.lua                  # Auto-commandes Vim
│   ├── cmd.lua                       # Commandes personnalisées
│   ├── lazy-conf.lua                 # Configuration lazy.nvim
│   ├── lsp/                          # Configurations LSP par langage
│   │   ├── init.lua                  # Gestion centrale des LSP
│   │   ├── lua.lua                   # Config LSP Lua
│   │   ├── python.lua                # Config LSP Python
│   │   ├── json.lua                  # Config LSP JSON
│   │   └── typescript.lua            # Config LSP TypeScript
│   ├── plugins/                      # Spécifications des plugins
│   │   ├── init.lua                  # Index des plugins
│   │   ├── blink-cmp.lua             # Complétion (nouveau)
│   │   ├── persistence.lua           # Sessions (nouveau)
│   │   ├── ufo.lua                   # Folding avancé (nouveau)
│   │   ├── treesitter.lua            # Parser syntaxique
│   │   ├── lspconfig.lua             # Configuration LSP
│   │   ├── telescope.lua             # Fuzzy finder
│   │   ├── neo-tree.lua              # Explorateur de fichiers
│   │   ├── trouble.lua               # Gestionnaire diagnostics
│   │   ├── gitsigns.lua              # Indicateurs Git
│   │   ├── neogit.lua                # Interface Git (Magit-like)
│   │   ├── copilot.lua               # GitHub Copilot
│   │   ├── navic.lua                 # Barre contexte code
│   │   ├── treesitter-context.lua    # Contexte Treesitter
│   │   ├── treesitter-textobjects.lua # Objets texte
│   │   ├── aerial.lua                # Symboles flottants
│   │   ├── indent-blankline.lua      # Lignes indentation
│   │   ├── harpoon.lua               # Navigation rapide
│   │   ├── conform.lua               # Formatage de code
│   │   ├── hover.lua                 # Documentation flottante
│   │   ├── illuminate.lua            # Surlignage occurrences
│   │   ├── satellite.lua             # Scrollbar visuelle
│   │   ├── fidget.lua                # Notifications LSP
│   │   ├── diffview.lua              # Visualisation diffs
│   │   └── schemastore.lua           # Schémas JSON
│   ├── highlights/                   # Highlights personnalisés
│   │   ├── init.lua                  # Gestion des highlights
│   │   ├── diffview.lua              # Highlights DiffView
│   │   ├── neogit.lua                # Highlights Neogit
│   │   └── neo-tree.lua              # Highlights Neo-tree
│   ├── themes/
│   │   └── sonokai.lua               # Thème personnalisé
│   └── def/
│       └── cokeline.d.lua            # Définitions types
```

## Fichiers principaux

### init.lua
Point d'entrée qui :
- Configure le cache des thèmes (base46)
- Définit la touche leader (`<Space>`)
- Helper `pRequire()` pour imports sécurisés
- Bootstrap lazy.nvim (installation automatique)
- Charge NvChad, plugins, thèmes, et imports personnalisés
- Configure LSP de manière différée

### lua/chadrc.lua
Configuration NvChad :
- Thème actif : `sonokai`
- Intégrations : trouble, telescope, blankline, navic
- Highlights personnalisés pour LSP/TreeSitter, Rainbow indent, Blink.cmp

### lua/options.lua
Options Vim personnalisées :
- `wrap = false` - Pas de retour à la ligne
- `scrolloff = 5` / `sidescrolloff = 15` - Marges de scroll
- `cursorline = true` - Highlight ligne courante
- `mouse = "a"` - Support souris complet
- `exrc = true` - Exécute .nvimrc local
- `virtualedit = "block"` - Édition libre en mode bloc
- **Folding UFO** : `foldcolumn = "1"`, `foldlevel = 99`, `foldenable = true`

### lua/mappings.lua
Raccourcis clavier principaux :
- `;` → `:` - Raccourci commandes
- `<C-j>` → Inspect - Inspecteur LSP
- `gl` → Diagnostic flottant
- `<leader>o/O` → Nouvelle ligne sans insert
- `<leader>cc` → Changer mot (ciw)
- `<leader>ee` → Neo-tree float
- `<leader>ec` → Neo-tree révéler fichier
- `<F3>` → Telescope find_files
- `jk` → ESC (mode insert)

### lua/autocmds.lua
Auto-commandes :
- **CursorHold/CursorMoved** : Diagnostics flottants intelligents
- **BufWritePost** : Rafraîchir diagnostics après sauvegarde (délai 500ms)
- **BufEnter** : Demande diagnostics à l'entrée buffer
- **FileType** : Configuration Treesitter automatique (syntaxe, folding, indent)
- **VimEnter** : Restauration automatique de session (persistence.nvim)

### lua/cmd.lua
Commandes personnalisées :
- `:Format` - Formate le buffer (LSP)
- `:TSInstalled` - Liste parsers Treesitter
- `:LspInfo` - Info santé LSP
- `:LspLog` - Ouvre fichier log LSP

## Plugins principaux

### Écosystème NvChad
- **NvChad** (v2.5) - Framework
- **base46** (v3.0) - Moteur de thèmes
- **ui** (v3.0) - Composants UI
- **lazy.nvim** - Gestionnaire de plugins

### Complétion (blink.cmp)
- **blink.cmp** - Système de complétion haute performance
- LuaSnip + friendly-snippets
- Intégration GitHub Copilot
- Ghost text (prévisualisation transparente)
- Documentation flottante auto-show (500ms)
- Nerd font icons pour tous types

### Folding (nvim-ufo)
- Folds avec Treesitter + Indent fallback
- Handler personnalisé pour texte virtuel
- Préservation highlights LSP/Treesitter
- Keymaps : `zR` (ouvrir), `zM` (fermer), `zK` (aperçu)

### Sessions (persistence.nvim)
- Sauvegarde automatique à la sortie
- Restauration automatique au démarrage
- Keymaps :
  - `<leader>qs` - Restaurer session répertoire
  - `<leader>qS` - Sélectionner session
  - `<leader>ql` - Dernière session
  - `<leader>qd` - Désactiver persistance

### Édition & Navigation
- **nvim-treesitter** - Coloration syntaxique avancée
- **treesitter-context** - Affiche contexte parent
- **treesitter-textobjects** - Objets texte sémantiques
- **telescope.nvim** - Recherche floue
- **neo-tree.nvim** - Explorateur de fichiers moderne
- **harpoon** - Navigation rapide fichiers
- **aerial.nvim** - Symboles flottants
- **navic** - Barre de contexte navigation
- **which-key.nvim** - Aide raccourcis
- **indent-blankline.nvim** - Lignes indentation (rainbow)

### Développement
- **nvim-lspconfig** - Configuration LSP
- **conform.nvim** - Formatage de code
- **mason.nvim** - Installateur LSP/DAP/linters
- **trouble.nvim** - Liste améliorée diagnostics
- **copilot.lua** - GitHub Copilot
- **hover.nvim** - Documentation flottante
- **illuminate** - Surlignage occurrences

### Git
- **gitsigns.nvim** - Indicateurs Git en marge
- **neogit** - Interface Git (style Magit)
- **diffview.nvim** - Visualisation avancée diffs

### UI
- **satellite.nvim** - Scrollbar miniature
- **fidget.nvim** - Notifications LSP asynchrones

## Configuration LSP

### Serveurs configurés
- **Lua** (`lsp/lua.lua`) - lua_ls
- **Python** (`lsp/python.lua`) - basedpyright
- **JSON** (`lsp/json.lua`) - jsonls avec schemastore
- **TypeScript** (`lsp/typescript.lua`) - ts_ls

### Features
- Capabilities : `blink.cmp.get_lsp_capabilities()`
- Diagnostics : borders arrondis, pull/push
- On Attach : Navigation, Navic, Trouble, renommage

### Configuration Python
**LSP : basedpyright**
- Type checking : standard
- Auto-imports activés
- Détection automatique Poetry/venv
- Commandes : `:PyPath`, `:PyReload`

**Formatter : ruff**
- Format + organisation imports
- Compatible Black, isort
- Format on save activé

## Thème Sonokai

Thème personnalisé basé sur [Sonokai](https://github.com/sainnhe/sonokai) (variante Default), inspiré de Monokai Pro.

**Caractéristiques :**
- Dark theme haut contraste
- Support complet Treesitter et LSP semantic tokens
- Italiques pour commentaires, keywords, built-in variables
- Couleurs ANSI terminal configurées
- Rainbow indent : 7 couleurs (rouge, jaune, bleu, orange, vert, violet, cyan)
- Intégrations : Trouble, Telescope, Blink.cmp, Neo-tree, Git signs, Neogit, DiffView

**Fichiers :**
- `lua/themes/sonokai.lua` - Définition du thème
- `lua/highlights/` - Highlights par plugin

**Palette principale :**
- Rouge (#fc5d7c) - Keywords, operators
- Vert (#9ed072) - Functions, methods
- Jaune (#e7c664) - Strings
- Cyan (#76cce0) - Types, classes
- Purple (#b39df3) - Numbers, constants
- Orange (#f39660) - Variables built-in
- Gris (#7f8490) - Commentaires

## Patterns et conventions

### Architecture modulaire
- Séparation claire : `lua/` (core), `lua/plugins/` (plugins), `lua/lsp/` (serveurs)
- Configuration isolée par plugin/serveur
- Highlights séparés par plugin dans `lua/highlights/`

### Optimisations de performance
- Chargement différé par défaut pour tous les plugins
- 24+ plugins Vim builtin désactivés
- Configuration minimale avec fonctionnalités opt-in
- Temps de démarrage minimal

## Historique des changements

**Commits récents :**
- `d901e63` - Migration nvim-cmp → blink.cmp
- `0234563` - Réorganisation configs plugins + nouveaux plugins
- `28c49ed` - Rainbow indent + thème colors
- `2ba4c69` - Strict path resolve
- `44b95cb` - Refactor LSP configuration
