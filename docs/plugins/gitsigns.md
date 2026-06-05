# gitsigns

## Role
Indicateurs git dans la colonne de signes, intégrés à statuscol pour les folds colorés.

## Files
- Config: `lua/plugins/gitsigns.lua`

## Key Behaviors
- Signes personnalisés : `▐` pour add/change, `_` delete, `‾` topdelete, `~` changedelete, `┆` untracked.
- `signs_staged_enable = false` → pas de signes pour les fichiers stagés.
- Crée des highlights `FoldGit<Type>` et `CursorLineFoldGit<Type>` en combinant le bg de `FoldColumn` avec le fg de `GitSigns<Type>` → utilisés par statuscol pour colorier les fold markers selon l'état git.
- Recalcule ces highlights à chaque `ColorScheme`.
- `once = true` sur `GitSignsUpdate` → `redraw!` une seule fois au démarrage pour éviter le flash.

## Gotchas
- Les highlights `FoldGit*` sont créés par gitsigns mais **consommés par statuscol** (`lua/plugins/statuscol/folds.lua`). Si gitsigns se charge après statuscol, les highlights peuvent manquer au premier rendu.
- `preview_config` positionne la fenêtre de preview relative au curseur (row=0, col=1).

## Changelog
- 2026-06-05 : Analyse initiale. Intégration fold highlights statuscol documentée.
