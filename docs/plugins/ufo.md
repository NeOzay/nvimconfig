# nvim-ufo

## Role
Folds améliorés avec provider treesitter/indent et affichage virtuel du contenu plié.

## Files
- Config: `lua/plugins/ufo/init.lua`
- Handler: `lua/plugins/ufo/handler.lua`
- Actions: `lua/plugins/ufo/actions.lua`
- Render: `lua/plugins/ufo/render.lua`
- Langs: `lua/plugins/ufo/langs/` (ex: `python.lua` pour `UfoFoldDocstrings`)

## Key Behaviors
- Provider : `{ "treesitter", "indent" }` pour les buffers normaux, `""` (désactivé) pour `nofile`.
- `vim.b.ufo_fold_level` traqué manuellement par buffer pour que `zr`/`zm` soient progressifs.
- Preview avec border `rounded` et highlight `Folded`.
- Commande `:UfoFoldDocstrings` → plie les docstrings Python.
- Actions récursives : `zC` (fermer récursif), `zO` (ouvrir récursif), `zA` (toggle récursif) via `lua/plugins/ufo/actions.lua`.
- `zK` → peek fold ou LSP hover si pas de fold sous le curseur.

## Keymaps
| Touche | Action |
|--------|--------|
| `zR` | Ouvrir tous les folds (level 99) |
| `zM` | Fermer tous les folds (level 0) |
| `zr` | Ouvrir un niveau de fold |
| `zm` | Fermer un niveau de fold |
| `zC` | Fermer récursivement |
| `zO` | Ouvrir récursivement |
| `zA` | Toggle récursivement |
| `zK` | Peek fold / LSP hover |

## Gotchas
- `zR`/`zM` set `vim.b.ufo_fold_level` à 99/0 pour synchroniser l'état local.
- Sans ce tracking, `zr`/`zm` ne fonctionnent pas correctement après `zR`/`zM`.

## Changelog
- 2026-06-05 : Analyse initiale.
