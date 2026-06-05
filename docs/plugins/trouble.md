# Trouble

## Role
Liste de diagnostics, symboles LSP et références dans un panneau dédié.

## Files
- Config: `lua/plugins/trouble.lua`
- Highlights: `lua/highlights/trouble.lua`

## Key Behaviors
- Mode `diagnostics` avec format `{severity_icon} {message} {item.source} {code} {pos}`.
- Preview split à droite, taille 0.4 de la fenêtre.
- Filtre global : `HINT` exclus par défaut.
- `focus = true` → la fenêtre trouble reçoit le focus à l'ouverture.
- `follow = true` → le curseur dans trouble suit le fichier actif.
- Panneau en bas, hauteur 10.
- Intégration snacks picker : action `trouble_open` dans `lua/plugins/snacks/picker.lua` → `<c-q>` envoie les résultats dans trouble.

## Keymaps
| Touche | Action |
|--------|--------|
| `<leader>xx` | Diagnostics workspace (toggle) |
| `<leader>xX` | Diagnostics buffer courant (toggle) |
| `<leader>cs` | Symboles (toggle, focus=false) |
| `<leader>cl` | LSP defs/refs/… (toggle, position=right) |
| `<leader>xL` | Location list (toggle) |
| `<leader>xQ` | Quickfix list (toggle) |

## Gotchas
- `lazy = false` + `cmd = "Trouble"` → chargé immédiatement mais accessible via cmd.
- `auto_close = false` → ne se ferme pas quand la liste est vide.

## Changelog
- 2026-06-05 : Analyse initiale. Intégration snacks picker documentée.
