# Treesitter

## Role
Parsing syntaxique, highlights, indentation, context et text-objects.

## Files
- Config: `lua/plugins/treesitter.lua`
- Context: `lua/plugins/treesitter-context.lua`
- Text-objects: `lua/plugins/treesitter-textobjects.lua`

## Key Behaviors

### treesitter-context
- Guides d'indentation rainbow intégrés dans la fenêtre de contexte.
- Lit les extmarks `indent_blankline` pour trouver la colonne du scope actif et aligner les guides.
- Highlights rainbow : `RainbowIndentGray/Red/Yellow/Blue/Orange/Green/Violet/Cyan` + variantes `Scope`.

### text-objects (treesitter-textobjects)
- Voir `lua/plugins/treesitter-textobjects.lua` pour les mappings.

## Gotchas
- `blink-cmp-documentation` est un filetype virtuel markview enregistré comme `markdown` via `vim.treesitter.language.register` (commenté dans blink-cmp.lua).

## Changelog
- 2026-06-05 : Analyse initiale.
