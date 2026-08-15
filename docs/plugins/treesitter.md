# Treesitter

## Role
Parsing syntaxique, highlights, folds, context et text-objects.

## Files
- Config: `lua/plugins/treesitter.lua`
- Context: `lua/plugins/treesitter-context.lua`
- Text-objects: `lua/plugins/treesitter-textobjects.lua`

## Key Behaviors

### nvim-treesitter (branche `main`)
- **Branche `main` obligatoire** (`branch = "main"` dans la spec) : c'est la réécriture, pas
  `master`. Requiert Neovim 0.12+.
- La branche `main` **ne fournit aucun module** : pas de `ensure_installed`, pas de
  `highlight = true`, pas de `auto_install`, pas de `fold`. `setup()` ne sert qu'à
  enregistrer `install_dir` dans le runtimepath.
- Tout est piloté depuis un unique autocmd `FileType` dans `config()` :
  - `vim.treesitter.start(buf)` pour le highlight ;
  - `foldexpr`/`foldmethod` posés via `nvim_win_call` sur chaque fenêtre affichant le
    buffer (`foldexpr` est window-local-to-buffer) ;
  - auto-install : si le parser est disponible mais absent, `install(lang):await(cb)` puis
    activation des buffers en attente. `pending` évite les installations concurrentes du
    même langage.
- Un balayage de `nvim_list_bufs()` en fin de `config()` rattrape les buffers déjà ouverts,
  qui n'émettront plus de `FileType`.

### Parsers custom
- Déclarés dans `custom_parsers` (haut de `lua/plugins/treesitter.lua`) et injectés dans
  `require("nvim-treesitter.parsers")` depuis un autocmd `User TSUpdate` — **seul** point
  d'accroche prévu par le plugin. L'autocmd est enregistrée dans `init` pour exister avant
  toute installation.
- `luadoc` pointe sur le fork `NeOzay/tree-sitter-luadoc` (branche `master`), avec
  `queries = "queries"` pour installer les queries du dépôt plutôt que celles fournies par
  nvim-treesitter.

### Emplacements
- Parsers : `stdpath('data')/site/parser/<lang>.so`
- Queries : `stdpath('data')/site/queries/<lang>/` — pour les parsers officiels, c'est un
  **symlink** vers `runtime/queries/` du plugin ; pour les parsers custom, une vraie copie.
- Révisions installées : `stdpath('data')/site/parser-info/<lang>.revision`

### treesitter-context
- Guides d'indentation rainbow intégrés dans la fenêtre de contexte.
- Lit les extmarks `indent_blankline` pour trouver la colonne du scope actif et aligner les guides.
- Highlights rainbow : `RainbowIndentGray/Red/Yellow/Blue/Orange/Green/Violet/Cyan` + variantes `Scope`.

### text-objects (treesitter-textobjects)
- Également sur `branch = "main"`. Voir `lua/plugins/treesitter-textobjects.lua` pour les mappings.

## Gotchas
- `blink-cmp-documentation` est un filetype virtuel markview enregistré comme `markdown` via `vim.treesitter.language.register` (commenté dans blink-cmp.lua).
- **`:TSUpdate` plante sur un parser sans `parser-info/<lang>.revision`** : `update()`
  fait un `assert` sur ce fichier. Un parser compilé hors de nvim-treesitter (ancien
  manager, install manuelle) doit être réinstallé avec `install(lang, { force = true })`
  pour créer son `.revision`.
- Les queries laissées dans `site/queries/` par un autre gestionnaire masquent celles du
  plugin (priorité runtimepath) et peuvent être désynchronisées du parser. À purger lors
  d'une migration.

## Changelog
- 2026-08-15 : Migration de `tree-sitter-manager.nvim` vers `nvim-treesitter` branche `main`
  (le dépôt n'est plus archivé). Highlight/folds/auto-install réimplémentés dans la spec,
  parser custom `luadoc` porté sur l'autocmd `User TSUpdate`, anciens parsers réinstallés
  pour générer leur `.revision`.
- 2026-06-05 : Analyse initiale.
