# persistence.nvim

## Role
Sauvegarde et restauration automatique des sessions par répertoire et branche git.

## Files
- Config: `lua/plugins/persistence.lua`

## Key Behaviors
- `branch = true` → session distincte par branche git.
- Sessions dans `stdpath("state")/sessions/`.
- Auto-restore au démarrage (`VimEnter`) si aucun fichier passé en argument et si la session existe.
- Si pas de session → `persistence.stop()` pour éviter de créer une session vide.
- Si des fichiers sont passés en argument → `persistence.stop()` aussi.

### PersistenceSavePre hook
Ferme toutes les fenêtres `nofile` avant la sauvegarde (Trouble, quickfix, etc.) — évite que ces fenêtres soient restaurées dans la session suivante. Seules les fenêtres `help` sont préservées.

## Keymaps
| Touche | Action |
|--------|--------|
| `<leader>qs` | Restaurer la session du cwd |
| `<leader>qS` | Choisir une session à restaurer |
| `<leader>ql` | Restaurer la dernière session |
| `<leader>qd` | Arrêter persistence (pas de sauvegarde à la fermeture) |

## Gotchas
- L'autocmd `PersistenceSavePre` est dans le fichier plugin (pas dans autocmds.lua) — s'exécute avant la sauvegarde de session.
- `need = 1` → une session n'est sauvegardée que s'il y a au moins 1 buffer listé.

## Changelog
- 2026-06-05 : Analyse initiale. Hook PersistenceSavePre pour nettoyer les fenêtres nofile documenté.
