# statuscol

## Role
Colonne de statut personnalisée avec numéros de ligne, signes git, folds colorés et breakpoints DAP.

## Files
- Config: `lua/plugins/statuscol/init.lua`
- Segments: `lua/plugins/statuscol/segments.lua`
- Folds: `lua/plugins/statuscol/folds.lua`
- DAP handler: `lua/plugins/statuscol/dap_handler.lua`
- Conditions: `lua/plugins/statuscol/conditions.lua`

## Key Behaviors
- Dépend de `nvim-dap` (chargé en même temps).
- `folds.setup_hl()` : crée les highlights pour les fold markers colorés selon l'état git (consomme `FoldGit*` créés par gitsigns).
- `cond.setup_win_autocmd()` : gère les conditions d'affichage par type de fenêtre.
- `dap_handler.setup()` : gère l'affichage des breakpoints DAP dans la colonne.
- `clickhandlers` sur `FoldOpen`/`FoldOther` avec scroll-to-click.
- `BufWinEnter` schedulé au démarrage pour appliquer statuscol aux buffers déjà ouverts.
- Types annotés avec `---@namespace Ozay` : `Statuscol.FoldData`, `Statuscol.text.arg`.

## Gotchas
- Dépend de gitsigns pour les highlights `FoldGit*`. Si ColorScheme est déclenché avant gitsigns, recalcule via autocmd `ColorScheme`.
- `folds.with_scroll_to_click` wrapper autour des handlers builtin pour préserver la position scroll au clic.

## Changelog
- 2026-06-05 : Analyse initiale.
