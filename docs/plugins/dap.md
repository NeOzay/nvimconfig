# DAP

## Role
Débogage avec nvim-dap, UI via nvim-dap-ui, support Python et Lua (Neovim).

## Files
- Config principale: `lua/plugins/dap/init.lua`
- Breakpoints persistants: `lua/plugins/dap/breakpoints.lua`
- UI (dap-ui): `lua/plugins/dap/dapui.lua`
- UI alternative (dap-view): `lua/plugins/dap/dap-view.lua` (désactivée)

## Key Behaviors
- UI active : `rcarriga/nvim-dap-ui` (switch possible vers `igorlfs/nvim-dap-view` via constante `DEBUGUI`).
- Python via `nvim-dap-python` avec debugpy installé dans Mason (`mason/packages/debugpy/venv/bin/python`).
- Adapter Lua `nlua` (one-small-step-for-vimkind) sur `127.0.0.1:8086`.
- **Breakpoints persistants** : sauvegardés à `VimLeavePre`, rechargés à `BufReadPost` (avec délai 100ms pour attendre que dap soit chargé).
- Signes définis au `init` (pas `config`) pour être disponibles dès le démarrage (statuscol les affiche).

### Signes
| Signe | Texte | Highlight |
|-------|-------|-----------|
| DapBreakpoint | ● | DapBreakpoint |
| DapBreakpointCondition | ◐ | DapBreakpointCondition |
| DapLogPoint | ◆ | DapLogPoint |
| DapStopped | ▶ | DapStopped + DapStoppedLine |
| DapBreakpointRejected | ○ | DapBreakpointRejected |

## Keymaps
| Touche | Action |
|--------|--------|
| `<F5>` | Continue |
| (voir init.lua) | Autres contrôles de débogage |

## Gotchas
- Les signes sont définis dans `init` (avant le chargement) pour que statuscol puisse les afficher sans attendre que dap soit configuré.
- `.venv/` dans le projet est détecté automatiquement par nvim-dap-python.

## Changelog
- 2026-06-05 : Analyse initiale. Breakpoints persistants, signes au init documentés.
