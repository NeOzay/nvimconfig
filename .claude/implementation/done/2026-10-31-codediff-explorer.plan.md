# Plan — codediff-explorer

## Relecture

```
VERDICT : NON CONFORME
CRITÈRES :
C1 (clic simple sur un fichier affiche son diff ; focus et curseur restent dans l'explorateur) → Étape 2 (+ Étape 3 pour le curseur)
C2 (clic simple sur un dossier bascule son pli) → Étape 2
C3 (Entrée sur fichier : diff, focus sur le diff, explorateur fermé ; sur dossier : bascule, reste ouvert ; double-clic identique à Entrée) → Étape 2
C4 (`<leader>e` : caché → s'ouvre et prend le focus ; visible sans focus → focus ; focus → ferme ; `<leader>E` ne fait plus rien ; hors tab CodeDiff `:nmap <leader>e` ne montre rien) → Étape 1, servi en partie : `suspendable = false` laisse `<leader>e` sur le vrai fichier affiché dans un autre tab tant que la session vit
C5 (curseur sur la première lettre du nom chaque fois que l'explorateur prend le focus) → Étape 3
C6 (code source du plugin non touché, `status --short` vides, ligne `dir` commentée) → contrôle répété à chaque Étape, mais déjà faux au départ (Q1)
C7 (doc décrit l'upstream chargé, `<leader>e`, clic, double-clic, Entrée ; plus de `<leader>b` ni `<leader>E`) → Étape 4 (vérif trop permissive, Q5)
HORS-PÉRIMÈTRE : RESPECTÉ
DÉRIVE : aucun déclenché (S3 effleuré : `<leader>e` n'est pas global, mais il fuit hors du tab par un buffer partagé, voir le constat bloquant)
INCERTITUDES : aucune
MODÈLE : opus → SOUTENU — vérification uniquement manuelle d'une course au focus asynchrone
QUALITÉ :
Q1 — C6 : l'upstream lazy renvoie déjà ` M doc/tags` (helptags de lazy) ; la vérif « vide » échoue dès l'Étape 1 et le plan ne le relève pas ; impossible à corriger sans entamer le Hors-périmètre
Q2 — le `focus_explorer = "<leader>e"` par défaut du plugin (config.lua:111, posé par set_tab_keymap) n'est mentionné nulle part dans le plan
Q3 — « la plus haute priority gagne, quel que soit l'ordre » est faux pour les claims de l'explorateur : même propriétaire et même portée, donc remplacement (slots.lua:318) ; cela marche seulement parce que keymaps.setup ne tourne qu'avant CodeDiffOpen
Q4 — saved_current_win n'est pas capturé à la sélection mais après panels.resolve + vim.schedule (refresh/init.lua:433-444) ; la conclusion tient, l'explication non
Q5 — la vérif de l'Étape 4 tolère des mentions de `<leader>b`/`<leader>E` au Changelog, alors que C7 dit « ne mentionne plus »
Q6 — « toggle de layout s'il existe » : il existe, `t` (config.lua:127)
Q7 — le contrôle headless sort avec 0 même après une erreur Lua ; « sans erreur » repose sur la lecture de la sortie
Q8 — C5 : un nom tronqué fait retomber le curseur sur le premier non-blanc (l'icône), pas sur le nom
```

Constat bloquant (hors bloc) : `set_buf_keymap(…, { suspendable = false })` sur les buffers
de diff laisse `<leader>e` sur le vrai fichier quand il est affiché dans un autre tab pendant que
la session vit (`Registry:suspend()` au `TabLeave`, `keymap/registry.lua:279`, ne retire que les
mappings suspendables).

Arbitrages de l'utilisateur :

- **Constat bloquant** — `<leader>e` se pose avec `suspendable = true` sur les buffers de diff ;
  les mappings du buffer de l'explorateur gardent `suspendable = false` (Étape 1, Conception).
- **Q2** — `keymaps.view.focus_explorer = false` : seul notre `<leader>e` existe (Étape 1).
- **Q8** — nom tronqué : repli sur le premier caractère après « indentation, icône, espace »
  (Étape 3, Conception).
- **Disposition** (après relecture) — la spec devient `lua/plugins/codediff/init.lua`, le module
  `lua/plugins/codediff/explorer.lua` ; import `plugins.codediff.init` ; ligne de `CLAUDE.md`
  mise à jour à l'Étape 4.
- **Q1** — C6 accepte ` M doc/tags` dans l'upstream lazy, et rien d'autre (vérif de chaque Étape).

Corrigés sans arbitrage (défauts de rédaction) : Q3 (remplacement des claims de l'explorateur
expliqué), Q4 (moment de capture de `saved_current_win`), Q5 (vérif de l'Étape 4 sans
tolérance), Q6 (toggle de layout `t`), Q7 (contrôle headless à code de sortie).

Brief : `.claude/implementation/codediff-explorer.brief.md` (validé). Pas d'entrée road-map
d'origine.

## Context

Dans un tab CodeDiff, l'explorateur ne se pilote pas comme voulu : un clic simple n'ouvre rien
(seul `<2-LeftMouse>` est mappé par le plugin), Entrée laisse l'explorateur ouvert, et l'ancienne
fermeture automatique sur `User CodeDiffFileSelect` (commentée en `9ed7a31`) échouait parce qu'un
diff pas encore chargé prend temporairement le focus. But : clic, double-clic, Entrée et
`<leader>e` pilotent l'explorateur, depuis la configuration seule, sans toucher au plugin (C6, S1).

Le plugin chargé est l'upstream `esmuellert/codediff.nvim` (v4.0.6) dans
`~/.local/share/nvim/lazy/codediff.nvim` ; tout ce qui suit s'appuie sur son API, lue en lecture
seule.

## Ce que le plugin offre (lu, non modifié)

- `User CodeDiffOpen` — émis à la fin de la création d'une vue (`ui/view/inline_view/create.lua:63`,
  `side_by_side/create.lua:147`), après `panel.setup_explorer` ; `data = { tabpage, mode, layout }`,
  `mode == "explorer"` pour une session avec explorateur.
- `require("codediff.ui.lifecycle")` : `get_panel_view(tabpage)` → l'objet explorateur
  (`split.bufnr`, `split.winid`, `winid`, `is_hidden`, `tree`, `on_file_select(file)`) ;
  `get_session(tabpage)` ; `get_windows(tabpage)` → `original_win, modified_win` ;
  `set_buf_keymap(tabpage, bufnr, mode, lhs, rhs, opts, meta)`.
- `set_buf_keymap` passe par le registre de la session (`keymap/registry.lua`, `keymap/slots.lua`) :
  le mapping est retiré et l'ancien restauré à la fin de la session — indispensable, puisque le
  buffer modifié peut être le vrai fichier de travail. `meta.suspendable` (vrai par défaut) :
  `Registry:suspend()` (`registry.lua:279`), appelé au `TabLeave`, retire les mappings suspendables
  et `resume()` les remet au retour dans le tab. Plusieurs claims sur un même slot : une claim du
  même propriétaire et de la même portée **remplace** la précédente (`slots.lua:318`) ; sinon la
  plus haute `priority` gagne, ex æquo la plus récente. Les claims de l'explorateur sont du même
  propriétaire et de la même portée (nil) que celles du plugin : elles les remplacent, ce qui tient
  parce que `keymaps.setup` de l'explorateur ne tourne qu'une fois, dans `render.create`, avant
  `CodeDiffOpen` (la bascule de layout `t` ne recrée pas l'explorateur).
- Défauts du plugin (`config.lua:110-111`) : `toggle_explorer = "<leader>b"`,
  `focus_explorer = "<leader>e"` (focus seul, posé par `set_tab_keymap`).
- `require("codediff.ui.view.actions.panes")` : `focus_explorer({ tabpage })` (montre si caché,
  puis focus) et `toggle_explorer({ tabpage })` (bascule la visibilité) — réutilisés tels quels
  (S4).
- Chargement d'un diff : `refresh.select` passe par `panels.resolve(…)` puis `vim.schedule` puis
  `view.show` (`ui/refresh/init.lua:433-444`), qui appelle `M.update`
  (`ui/view/inline_view/update.lua:114`, idem `side_by_side/update.lua:114`). `M.update` capture
  `saved_current_win = nvim_get_current_win()` **à son entrée, après cette résolution
  asynchrone**, le rendu asynchrone
  fait `nvim_set_current_win(modified_win)` (`inline_view/render.lua:32`), puis `commit_update`
  rend le focus à `saved_current_win` s'il est encore valide. C'est la prise de focus temporaire du
  Brief.
- Nœuds de l'arbre (`ui/explorer/nodes.lua`) : fichier → `data.path` ; dossier →
  `data.type == "directory"`, `data.name` ; groupe → `data.type == "group"`. Les lignes de fichier
  commencent par `indent icône nom` (formatter `prefix` de la spec).

## Conception

La spec passe en répertoire, comme `plugins.dap`, `plugins.statuscol` et `plugins.snacks` :
`lua/plugins/codediff.lua` devient `lua/plugins/codediff/init.lua` (`git mv`), et `init.lua`
importe `plugins.codediff.init` au lieu de `plugins.codediff` — l'import du répertoire chargerait
`explorer.lua` comme une spec. Un module neuf, `lua/plugins/codediff/explorer.lua`, appelé depuis
le `config` de la spec (`require("plugins.codediff.explorer").setup()`), fait tout le travail. Les
`require("codediff…")` y sont faits dans les fonctions, jamais au chargement du module. Les types
éventuels se préfixent `Ozay.`. Aucun délai arbitraire (S2) : l'ordre des appels règle la course
au focus.

**Entrée sur un fichier (C3)** : cacher l'explorateur (`panes.toggle_explorer`), mettre le focus
sur `modified_win`, **puis** `explorer.on_file_select(node.data)`. Le focus ne bouge plus d'ici à
l'entrée de `M.update`, qui capture donc `saved_current_win = modified_win` ; et pour un
chargement déjà en cours (lancé par un clic), le
`saved_current_win` capturé est la fenêtre de l'explorateur, fermée par `split:hide()` donc
invalide, et `commit_update` ne la restaure pas. Le focus finit sur le diff dans les deux cas.

**Clic** : mappé sur `<LeftRelease>`, pas `<LeftMouse>`. Le clic natif a déjà déplacé le curseur
et le focus dans la fenêtre cliquée ; le mapping buffer-local de l'explorateur n'est consulté que
si le relâchement a lieu dans l'explorateur. Rien du clic natif n'est réimplémenté.

**Double-clic** : la séquence est `<LeftMouse> <LeftRelease> <2-LeftMouse> <2-LeftRelease>`. Le
premier relâchement a déjà fait l'effet du clic. `<2-LeftMouse>` sur un fichier fait donc
l'Entrée (diff déjà sélectionné : `refresh.select` sort tôt, sans recharger) ; sur un dossier il
ne fait **rien**, le premier relâchement ayant basculé le pli — l'effet net est celui d'Entrée,
une bascule, et non deux.

**`<leader>e` (C4)** : posé par `set_buf_keymap`, **`suspendable = true`**, sur chaque buffer de la
session à mesure qu'on y entre — autocmd `BufEnter`/`WinEnter` (par `Userautocmd`) qui, si le tab courant porte une session
en mode explorateur, réclame `<leader>e` sur le buffer courant. Une pose unique au
`CodeDiffOpen` ne suffit pas : chaque fichier sélectionné crée un nouveau buffer modifié, que le
plugin re-mappe pour ses propres touches mais pas pour les nôtres. Réclamer deux fois remplace la
claim précédente (même propriétaire, `slots.lua:318`). `suspendable = true` retire `<leader>e`
quand on quitte le tab : le vrai fichier, s'il est aussi affiché dans un autre tab, ne le porte
pas là-bas. `keymaps.view.toggle_explorer = false` supprime `<leader>E` ;
`keymaps.view.focus_explorer = false` supprime le `<leader>e` natif, pour que le nôtre soit le
seul.

**Curseur sur le nom (C5)** : autocmd `WinEnter` local au buffer de l'explorateur, plus appel
explicite après un clic. Le nom cherché est `vim.fs.basename(data.path)` (fichier), `data.name`
(dossier) ; la colonne est la première occurrence littérale dans la ligne
(`string.find(line, nom, 1, true)`) ; nom introuvable (tronqué par `truncate_priority`) →
premier caractère après « indentation, icône, espace », soit la fin de la première séquence
`%s*%S+%s` de la ligne ; groupe → premier caractère non blanc.

## Étapes

### Étape 1 — `<leader>e` dans un tab CodeDiff (C4)

Fichiers : `lua/plugins/codediff.lua` → `lua/plugins/codediff/init.lua` (`git mv`),
`lua/plugins/codediff/explorer.lua` (neuf), `init.lua` (import).

- Déplacer la spec par `git mv`, puis `{ import = "plugins.codediff.init" }` dans `init.lua`.
- Module avec `setup()` ; `config` l'appelle après `require("codediff").setup(opts)`. Retirer
  l'autocmd commentée de `config` (remplacée par ce chantier). `keymaps.view.toggle_explorer =
  false`, `keymaps.view.focus_explorer = false`.
- Action `<leader>e` : explorateur caché → `panes.focus_explorer` ; visible sans le focus →
  `panes.focus_explorer` ; focus (fenêtre courante == `split.winid`) → `panes.toggle_explorer`,
  puis focus sur `modified_win` s'il est valide.
- Autocmd `BufEnter`/`WinEnter` : `lifecycle.get_session(tab)` et `get_panel_name(tab) ==
  "explorer"` → `set_buf_keymap(tab, buf, "n", "<leader>e", action, { desc = … }, { suspendable =
  true, priority = 10 })`. Hors session : rien.

vérif : `nvim --headless -c 'lua local ok, e = pcall(function() require("plugins.codediff.explorer").setup() end); if not ok then io.stderr:write(e) vim.cmd("cq") end' -c 'qa!'` (code de sortie non nul sur erreur), puis
à la main : `:CodeDiff` dans un dépôt modifié ; `<leader>e` depuis le diff (explorateur visible,
puis caché) et depuis l'explorateur ; `<leader>E` sans effet ; après avoir changé de fichier,
`<leader>e` marche encore depuis le diff ; le vrai fichier affiché aussi dans un autre tab :
`:nmap <leader>e` vide dans cet autre tab **pendant** la session, de nouveau mappé au retour dans
le tab CodeDiff ; dans un buffer hors CodeDiff et dans le vrai fichier après fermeture de la
session (`q`), `:nmap <leader>e` vide.

### Étape 2 — Clic, double-clic et Entrée dans l'explorateur (C1, C2, C3)

Fichier : `lua/plugins/codediff/explorer.lua`.

- Sur `User CodeDiffOpen` avec `data.mode == "explorer"` : récupérer l'explorateur
  (`get_panel_view`) et poser sur `split.bufnr`, par `set_buf_keymap` (`priority = 10`,
  `suspendable = false`) :
  - `<LeftRelease>` : fichier → `on_file_select(node.data)`, focus laissé ; dossier → bascule du pli
    (`node:expand()`/`node:collapse()`, `tree:render()`) ; groupe → bascule aussi, comme `<CR>`
    natif.
  - `<CR>` : fichier → séquence Entrée de la Conception ; dossier ou groupe → bascule du pli.
  - `<2-LeftMouse>` : fichier → séquence Entrée ; dossier ou groupe → rien.
- `explorer.focus_on_select` n'a plus d'effet (il ne vit que dans le `<CR>` natif remplacé) : le
  retirer des `opts`.

vérif : headless comme à l'Étape 1, puis à la main : clic sur un fichier (diff affiché, focus et
curseur restent dans l'explorateur, y compris pour un fichier lourd dont le chargement prend le
focus) ; clic sur un dossier (pli basculé) ; Entrée sur un fichier non encore affiché et sur le
fichier déjà affiché (diff focus, explorateur fermé) ; Entrée sur un dossier (pli, explorateur
ouvert) ; double-clic sur fichier et dossier (même effet qu'Entrée) ; `j`/`k` toujours en
auto-ouverture.

### Étape 3 — Curseur sur la première lettre du nom (C5)

Fichier : `lua/plugins/codediff/explorer.lua`.

- Fonction `place_cursor(explorer)` décrite en Conception ; autocmd `WinEnter` sur `split.bufnr`
  (posée au `CodeDiffOpen`, avec le buffer elle disparaît) ; appel après le `<LeftRelease>` et
  après une bascule de pli.

vérif : headless comme à l'Étape 1, puis à la main : `<leader>e` depuis le diff, `<C-w>h`, clic sur
une ligne de fichier profonde et sur un dossier → curseur sur la première lettre du nom ; idem en
vue liste (`i`) ; ligne de groupe → premier caractère non blanc.

### Étape 4 — Documentation (C7)

Fichiers : `docs/plugins/codediff.md`, `CLAUDE.md` (ligne codediff de l'index).

- Files : spec `lua/plugins/codediff/init.lua`, upstream `esmuellert/codediff.nvim` chargé par
  lazy, `dir` vers le fork commenté ; module `lua/plugins/codediff/explorer.lua`.
- `CLAUDE.md`, index des plugins : la ligne codediff pointe sur `lua/plugins/codediff/` (spec +
  `explorer.lua`) et l'upstream lazy, plus sur `lua/plugins/codediff.lua` ni le submodule.
- Key Behaviors : retirer la fermeture auto sur `CodeDiffFileSelect` et le layout `--inline` sous
  100 colonnes (remplacé par `diff.layout = "inline"`, `9ed7a31`) ; décrire clic, double-clic,
  Entrée, `<leader>e`, curseur, et pourquoi l'ordre focus-puis-sélection.
- Keymaps : `<leader>e` (seul toggle de l'explorateur) ; explorateur : clic, double-clic,
  `<CR>`.
- Gotchas : prise de focus temporaire au chargement (`saved_current_win`), remplacement des claims
  de l'explorateur, re-pose de `<leader>e` à chaque buffer et `suspendable` au changement de tab.
- Changelog : entrée datée.

vérif : `grep -nE '<leader>(b|E)\b' docs/plugins/codediff.md` ne renvoie rien ;
`grep -n 'leader>e' docs/plugins/codediff.md` non vide ;
`grep -rn 'plugins/codediff\.lua\|codediff_explorer' CLAUDE.md docs/` ne renvoie rien.

Chaque Étape vérifie aussi C6 :
`git -C ~/.local/share/nvim/lazy/codediff.nvim status --short | grep -v '^ M doc/tags$'` vide
(`doc/tags` est l'index d'aide que lazy régénère lui-même, déjà modifié avant le chantier),
`git -C plugins/codediff.nvim status --short` vide, ligne `dir` toujours commentée.

## Vérification de bout en bout

Validation à la main dans Neovim (décision du Brief) : rejouer les vérifs des Étapes 1 à 3 dans un
même tab CodeDiff, en layout inline (défaut) puis `side-by-side` (`:CodeDiff` après avoir changé
`diff.layout`, ou toggle de layout `t`), puis fermer la session et contrôler qu'aucun de
nos mappings ne reste sur le vrai fichier.

## Modèle

Opus — la course au focus du chargement asynchrone ne se vérifie qu'à la main, sans test
automatisé, et au moindre doute le contrat dit Opus.
