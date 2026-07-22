# nvim-unception

## Role
Empêche l'imbrication d'une session Nvim dans un buffer terminal (`:terminal`) : intercepte les appels `nvim` lancés depuis un terminal enfant et fait éditer le fichier par l'instance Nvim hôte à la place.

## Files
- Config: `lua/plugins/nvim-unception.lua`

## Key Behaviors
- Utilisé pour que Ctrl+G dans Claude Code (édition du prompt via `$EDITOR`) ouvre le fichier dans l'instance Nvim hôte plutôt que dans un Nvim imbriqué à l'intérieur du terminal snacks de [[claudecode]].
- `vim.g.unception_block_while_host_edits = true` — le process `nvim` lancé par le terminal enfant reste bloqué (au lieu de rendre la main immédiatement) jusqu'à ce que le buffer ouvert côté hôte soit fermé (`QuitPre`). Indispensable pour tout appel `$EDITOR` bloquant (ici Claude Code CLI, potentiellement aussi `git commit`).
- `$EDITOR=nvim` est fixé uniquement pour le terminal Claude Code, via `opts.env` dans `lua/plugins/claudecode.lua` (pas globalement dans `.zshrc`) — scope volontairement limité à ce terminal.
- Comportement par défaut : le buffer terminal est remplacé par le fichier édité dans la même fenêtre ; après `:wq`, Nvim revient au buffer alternatif de cette fenêtre (le terminal), sans config supplémentaire.
- Le fichier de prompt temporaire de Claude Code (`/tmp/claude-<uid>/claude-prompt-*.md`) est exempté de la règle readonly "hors workspace" dans `lua/autocmds.lua` (match sur le nom de fichier).

## Keymaps
- Aucun.

## Gotchas
- Les flags CLI `nvim` qui n'impliquent pas l'édition d'un fichier/dossier (ex: `-b`) peuvent ne pas se propager correctement à travers l'interception.
- **`snacks.win` reprend le buffer terminal automatiquement (`fixbuf`)** : par défaut, une fenêtre gérée par snacks.win détecte via `BufWinEnter` quand un buffer différent y apparaît et le swap vers la fenêtre "main", en restaurant son propre buffer (le terminal) à sa place (`snacks/win.lua` → `fixbuf()`). Résultat observé : le prompt atterrissait dans la fenêtre principale au lieu de la fenêtre terminal. Corrigé en passant `fixbuf = false` dans `snacks_win_opts` de [[claudecode]] — vérifié par debug que le ciblage de fenêtre côté unception (current window = fenêtre terminal) était déjà correct ; le problème venait entièrement de ce comportement de snacks, pas d'unception.

## Changelog
- 2026-07-22 : Ajout pour résoudre l'imbrication Nvim-dans-terminal-Claude-Code lors de l'édition du prompt via Ctrl+G ; exemption de la règle readonly pour les fichiers de prompt temporaires ; fix `fixbuf = false` côté claudecode.lua pour empêcher snacks.win de reprendre le buffer terminal.