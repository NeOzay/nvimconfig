+++
id = "codediff-opts-cles-inconnues"
title = "Des clés `keymaps` des opts de codediff n'existent pas dans l'upstream et n'ont aucun effet"
date = 2026-10-31
severite = "note"
chantier = "codediff-explorer"
reference = "journal du suivi, entrée « Hors périmètre : … Dans les opts »"
pin = false
reviewed = "<OPTIONNEL date>"
category = "<OPTIONNEL>"
+++

## Constat

Dans `lua/plugins/codediff/init.lua`, `keymaps.view.close`, `diffget`, `diffput`, `goto_file`,
`stage_toggle` et `keymaps.explorer.open`, `preview`, `toggle_view` ne sont pas des clés de
l'upstream v4.0.6, qui attend `quit`, `diff_get`, `diff_put`, `open_in_prev_tab`, `toggle_stage`,
`select`, `hover`, `toggle_view_mode` (`codediff/config.lua`). Les touches voulues sont
aujourd'hui celles des défauts du plugin.

Établi par : lecture de `~/.local/share/nvim/lazy/codediff.nvim/lua/codediff/config.lua`
(section `keymaps`) contre les opts de la spec.

## Pourquoi c'est gênant

Rien ne se voit tant que les défauts coïncident avec ce qui est écrit ; changer une de ces
valeurs dans les opts ne changerait rien, sans erreur.

## Pour solder

Renommer les clés selon `config.lua` de l'upstream, ou retirer celles qui répètent un défaut.
Vérifier : `:lua =require("codediff.config").options.keymaps` montre les valeurs des opts.
