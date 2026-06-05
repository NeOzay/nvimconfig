# Java (nvim-java)

## Role
Support Java complet : LSP (jdtls), tests, DAP, Lombok.

## Files
- Config: `lua/plugins/java.lua`

## Key Behaviors
- Chargé uniquement pour `ft = "java"`.
- Lombok activé, tests Java activés, debug adapter activé.
- JDK auto-installé si nécessaire.
- `vim.lsp.enable("jdtls")` appelé dans `config` (pas via `lsp/init.lua`).
- Keymaps Java définis buffer-local via autocmd `FileType java`.

## Gotchas
- Les dépendances `nvim-java-core`, `nvim-java-test`, `nvim-java-dap` sont commentées au profit de la configuration unifiée via `nvim-java`.
- jdtls n'est pas dans la liste `M.lsp_configs` de `lsp/init.lua` — il est activé séparément ici.

## Changelog
- 2026-06-05 : Analyse initiale.
