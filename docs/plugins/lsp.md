# LSP

## Role
Configuration LSP native Neovim 0.11+ via `vim.lsp.config()` / `vim.lsp.enable()`.

## Files
- Entrée: `lua/lsp/init.lua`
- Mappings: `lua/lsp/mappings.lua`
- Hover custom: `lua/lsp/hover/` (init, config, format, highlight/)
- AI rename: `lua/lsp/ai-rename.lua`
- Plugin loader: `lua/plugins/lspconfig.lua` (charge `lsp.setup()`)

## Key Behaviors
- **Pas de `nvim-lspconfig.setup()`** — utilise exclusivement `vim.lsp.config()` / `vim.lsp.enable()`.
- Config globale `vim.lsp.config("*", ...)` : capabilities blink.cmp + `root_dir` = `vim.fn.getcwd()`.
- Serveurs actifs : `emmylua_ls`, `basedpyright`, `jsonls`, `ts_ls`, `rust_analyzer`, `zshcs`. (`ty` commenté.)
- Capabilities via `blink.cmp.get_lsp_capabilities()` avec fallback manuel.
- `textDocument.diagnostic.dynamicRegistration = true`.

### on_attach
- Attache navic si `documentSymbolProvider` disponible.
- Diagnostics workspace : `workspace/diagnostic` si supporté, sinon `workspace-diagnostics` (sauf copilot et basedpyright).
- Attache les mappings LSP via `lsp.mappings.attach()`.

### Diagnostics
- Virtual text avec icônes par sévérité (`󰅙` error, `` warn, `󰋼` info, `󰌵` hint).
- Déduplication par ligne : n'affiche l'icône que pour la première occurrence de chaque sévérité sur la ligne (via `vim.b._diag_seen`).
- Float avec border `rounded`.

### Floating preview global
Monkey-patch de `vim.lsp.util.open_floating_preview` pour forcer `border = "rounded"` partout.

## Gotchas
- `root_dir` fixé au cwd — pas de détection automatique de racine projet. Intentionnel.
- `copilot_ls` est activé via `copilot-lsp` (dans `lua/plugins/copilot.lua`), pas ici.
- `jdtls` est activé dans `lua/plugins/java.lua`.
- Les configs serveurs étaient dans `lua/lsp/servers/` (supprimées, maintenant dans `lsp/` à la racine ou via emmylua_ls directement).

## Changelog
- 2026-06-05 : Analyse initiale. Architecture native 0.11+, déduplication diagnostics documentée.
