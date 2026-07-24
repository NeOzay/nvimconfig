---
slug: claudecode-terminal-provider
titre: Provider terminal custom pour claudecode.nvim (snacks)
branche: claudecode-terminal-provider
base: master
statut: terminé
session: 1
plan: /var/home/Benoit/.config/nvim/.claude/plans/effervescent-dreaming-russell.md
créé: 2026-07-23
maj: 2026-07-24
---

## Objectif et périmètre

**But** : remplacer le hack `snacks_win_opts.fixbuf = false` + autocmd `QuitPre` de réparation
(`lua/autocmds.lua`) par un provider terminal custom pour `coder/claudecode.nvim`, basé sur
`Snacks.terminal`/`Snacks.win`, qui possède son propre suivi buf/win au lieu de subir celui de
snacks. Ajoute deux comportements : persistance de la taille du terminal entre les toggles, et
protection de la fenêtre terminal (seuls le buffer terminal et le buffer de prompt Ctrl+G peuvent
y apparaître).

**Critères de réussite** : les 6 points de la section Vérification du plan passent en usage réel
(pas de suite de tests automatisée dans ce repo).

**Hors-périmètre** :
- Contournement "climbing cursor" (destroy+recreate de fenêtre) — seulement si constaté.
- Providers `native`/`external`/`none` de claudecode.nvim — non touchés.
- Comportement diff (`diff_opts`) — inchangé.
- Support multi-session Claude — hors périmètre.

## Étapes

- [x] 1. Créer `lua/plugins/claudecode/terminal.lua` (provider custom : `term_buf` stable,
      `guard_window()` BufWinEnter dédié, persistance taille via `last_win_size`,
      `open/close/simple_toggle/focus_toggle/get_active_bufnr/is_available/setup`)
      (commit: bd02236)
- [x] 2. Convertir `lua/plugins/claudecode.lua` → `lua/plugins/claudecode/init.lua` (brancher le
      provider, retirer `snacks_win_opts.fixbuf = false` + commentaire, retirer `keys.hide`
      redondant avec le keymap global `<A-c>` n/t qui contournait le wrapper de taille)
      (commit: bd02236)
- [x] 3. Mettre à jour `init.lua` racine (`plugins.claudecode` → `plugins.claudecode.init`)
      (commit: bd02236)
- [x] 4. Supprimer les blocs `TermOpen`/`QuitPre` devenus inutiles dans `lua/autocmds.lua`
      (cache `claude_terminal_bufnr` + réparation) — vérifié via chargement headless
      (`nvim --headless -u init.lua`) : provider accepté sans warning, aucune erreur.
      (commit: bd02236)
- [x] 5. Vérification manuelle dans Neovim (6 points du plan) — **tous confirmés fonctionnels par
      l'utilisateur**. Trois bugs trouvés et corrigés en cours de route : conflit `guard_window()`/
      `BufWinEnter` interne de snacks + statuscolumn pas prêt au premier show (fuite winhighlight),
      `E211` à la fermeture du prompt (buffer jamais wipe par nvim-unception), `nvim_feedkeys("GA")`
      non idempotent (texte "GA" inséré littéralement) — voir Journal de décisions.
      (commit: 07c4663)
- [x] 6. Mettre à jour `docs/plugins/claudecode.md`, `docs/plugins/nvim-unception.md` et l'index
      `CLAUDE.md` (nouveau mécanisme, gotchas historiques marqués résolus) (commit: bd02236)
- [x] 7. (Hors plan initial, ajouté en cours de route) `M.reset_size()` + keymap `<leader>aR` —
      réinitialise `last_win_size` et redessine la fenêtre à chaud si visible. Validé par
      l'utilisateur. (commit: 07c4663)

## État courant

**Implémentation terminée** — les 7 étapes sont cochées, tous les points de vérification confirmés
par l'utilisateur en usage réel.

## Journal de décisions

- `reconcile_terminal_window()` sur `QuitPre` différé — nvim-unception échange avec la fenêtre
  suivante, pas forcément `terminal.win`, après restauration Ctrl+G.
- `guard_window()` délègue à `terminal:fixbuf()` (méthode native de `snacks.win`) plutôt que
  réimplémenter l'éjection à la main — élimine la fuite `winhighlight`/`statuscolumn` à la source.
  Approches intermédiaires essayées et abandonnées : éjection réactive maison, `'winfixbuf'`
  (trop strict, cassait cokeline), "laisser faire + réparer + rouvrir via show()".
- L'autocmd `BufWinEnter` interne que `snacks.win` recrée à chaque `show()` est explicitement
  supprimée (`setup_terminal_events()`) pour ne laisser que `guard_window()` actif — les deux
  géraient le même événement, cause de la fuite winhighlight observée en usage réel.
- `statuscol.nvim` chargé en `lazy = false` — pas prêt au premier `show()` du terminal, contribuait
  à la confusion autour du bug winhighlight.
- `last_win_size = nil` ajouté aux handlers `TermClose`/`BufWipeout` — sans ça la taille capturée
  fuitait vers une future instance recréée avec une géométrie différente.
- Fix `E211` à la fermeture du prompt Ctrl+G : `nvim-unception` ne wipe jamais le buffer prompt, et
  le CLI Claude supprime le fichier tmp dès qu'il l'a lu — le buffer chargé restant se fait piéger
  par le balayage de timestamps de Neovim. `nvim_buf_delete` différé, seulement si le quit a abouti.
- Auto-insert à l'ouverture du prompt Ctrl+G et au retour dans le terminal via des appels API
  idempotents (`normal!`/`startinsert!`) plutôt que `nvim_feedkeys("GA")`, qui insérait le texte
  littéral "GA" en cas de ré-entrance du handler `BufWinEnter` (`nested = true`).
- `M.reset_size()` + keymap `<leader>aR` (hors plan initial, ajouté en cours de route) — redessine
  la fenêtre à chaud (`vertical resize`/`resize` direct) car `snacks.win` n'expose pas d'API de
  redimensionnement à chaud pour un split déjà ouvert. Type custom `Ozay.ClaudeCodeTerminalProvider`
  ajouté pour documenter ce champ côté emmylua_ls.
- Root-fix initial : suivi buf/win interne au provider (augroup dédié, `term_buf` stable), plus de
  hack externe dans `autocmds.lua`.
- Contournement "climbing cursor" du provider de référence non porté préventivement — pas de bug
  observé chez nous.
- Emplacement `lua/plugins/claudecode/terminal.lua` — convention du repo pour plugins
  multi-fichiers (`dap/`, `statuscol/`, `snacks/`, `ufo/`).
