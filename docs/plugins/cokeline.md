# cokeline

## Role
Bufferline intégrée à Harpoon — affiche uniquement les buffers harponnés, triés par index.

## Files
- Config: `lua/plugins/cokeline.lua`
- Fork: `NeOzay/nvim-cokeline` (dev, `~/projects/nvim-plugins/`)

## Key Behaviors
- `filter_valid` : n'affiche QUE les buffers présents dans la liste Harpoon.
- Tri personnalisé via monkey-patch de `cokeline.buffers.get_valid_buffers` : harponnés par index, non-harponnés non affichés.
- Au démarrage (`load_harpoon_buffers`) : charge en mémoire tous les fichiers harponnés pour qu'ils apparaissent immédiatement dans la tabline.
- Réaction aux événements Harpoon (`ADD`/`REMOVE`) → `redrawtabline` via `vim.schedule`.
- Bouton fermeture/unharpoon : si le buffer est harponné → `remove_at(idx)`, sinon → `nvim_buf_delete`.
- Séparateur coloré par diagnostic : rouge si erreurs, jaune si warnings, bleu sinon.
- Index harponné affiché en orange (non-focalisé) ou bleu (focalisé).
- Underline sur le buffer focalisé (`sp = colors.blue`, `underline = true`).

## Gotchas
- `show_if_buffers_are_at_least = 0` → la tabline est toujours visible même avec 0 buffer.
- `delete_on_right_click = false` → clic droit ne supprime rien.
- `vim.fn.fnamemodify(buffer.filename, ":r")` → affiche le nom sans extension.
- Le tri par `lastused` est commenté (prévu mais pas activé).

## Changelog
- 2026-06-05 : Analyse initiale. Filtre Harpoon-only, tri par index, load_harpoon_buffers au démarrage.
