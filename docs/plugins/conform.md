# conform.nvim

## Role
Formatage automatique à la sauvegarde.

## Files
- Config: `lua/plugins/conform.lua`

## Key Behaviors
- Formatage à `BufWritePre` avec timeout 500ms et fallback LSP.
- Lua : `stylua`.
- Python : `ruff_format` puis `ruff_organize_imports` (deux passes séquentielles).
- `ruff_format` : `ruff format --stdin-filename $FILENAME -`
- `ruff_organize_imports` : `ruff check --select I --fix --stdin-filename $FILENAME -`

## Gotchas
- Les deux formatters ruff sont des commandes shell custom (pas les presets conform) car ruff unifié nécessite des flags spécifiques.
- `lsp_fallback = true` → si aucun formatter n'est défini pour le filetype, tente le formatage LSP.

## Changelog
- 2026-06-05 : Analyse initiale.
