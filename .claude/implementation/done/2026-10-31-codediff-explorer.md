+++
gabarit = "suivi"
slug = "codediff-explorer"
titre = "Modifier le comportement de l'explorateur de fichiers de codediff, sans toucher au code source du plugin"
branche = "codediff-explorer"
base = "master"
statut = "terminé"
session = 2
lettre = "A"
"modèle" = "opus"
plan = ".claude/implementation/done/2026-10-31-codediff-explorer.plan.md"
brief = ".claude/implementation/done/2026-10-31-codediff-explorer.brief.md"
audit = ".claude/implementation/done/2026-10-31-codediff-explorer.audit"
skills = []
"créé" = 2026-10-31
maj = 2026-10-31
+++

## Objectif et périmètre

**Symptôme** : l'explorateur de codediff ne se pilote pas comme voulu — un clic simple sur un
fichier n'affiche rien (seul le double-clic ouvre), l'explorateur reste ouvert après Entrée, et
l'ancienne fermeture automatique « ne fonctionnait pas bien ».

**But** : dans un tab CodeDiff, piloter l'explorateur à la souris et au clavier — clic pour voir un
diff, Entrée pour y aller en refermant l'explorateur, `<leader>e` pour l'ouvrir, le focus ou le
fermer —, depuis la configuration seule ; d'autres comportements pourront s'ajouter.

**Critères de réussite** :

- **C1** — Un clic simple sur un fichier affiche son diff ; le focus et le curseur restent dans
  l'explorateur.
- **C2** — Un clic simple sur un dossier bascule son pli.
- **C3** — Entrée sur un fichier affiche son diff, met le focus sur le diff et ferme l'explorateur ;
  Entrée sur un dossier bascule son pli, l'explorateur reste ouvert. Le double-clic fait
  exactement la même chose qu'Entrée, sur un fichier comme sur un dossier.
- **C4** — Dans un tab CodeDiff, `<leader>e` : explorateur caché → il s'ouvre et prend le focus ;
  visible sans le focus → il prend le focus ; focus → il se ferme. `<leader>E` ne fait plus rien
  dans la vue diff. Hors d'un tab CodeDiff, `:nmap <leader>e` ne montre rien.
- **C5** — Chaque fois que l'explorateur prend le focus (`<leader>e`, changement de fenêtre, clic),
  le curseur se place sur la première lettre du nom.
- **C6** — Le code source du plugin n'est pas touché :
  `git -C ~/.local/share/nvim/lazy/codediff.nvim status --short` et
  `git -C plugins/codediff.nvim status --short` ne renvoient rien, et la ligne `dir` reste
  commentée. (Arbitrage du Plan : ` M doc/tags`, régénéré par lazy, est accepté dans l'upstream.)
- **C7** — `docs/plugins/codediff.md` décrit l'upstream réellement chargé, `<leader>e`, le clic,
  le double-clic et Entrée, et ne mentionne plus `<leader>b` ni `<leader>E`.

**Hors-périmètre** :

- Toute modification du code source du plugin : ni l'upstream installé par lazy, ni le fork
  `plugins/codediff.nvim`.
- `<leader>e` hors d'un tab CodeDiff.
- La navigation `]f`/`[f` : l'utilisateur ne s'en sert pas, elle n'a pas de comportement à définir.

**Signaux de dérive** :

- **S1** — Le diff touche un fichier du plugin (upstream ou fork), ou réactive la ligne `dir`.
- **S2** — Un délai arbitraire (`vim.defer_fn(…, N)`) attend que le plugin se stabilise, comme le
  faisait l'ancienne fermeture.
- **S3** — `<leader>e` est mappé globalement au lieu d'être local au buffer d'un tab CodeDiff.
- **S4** — Le code recopie une fonction interne du plugin (rendu, arbre) au lieu d'appeler son API
  ou de poser un mapping par-dessus.

## Étapes

- [x] 1. `<leader>e` dans un tab CodeDiff, spec déplacée en répertoire — `lua/plugins/codediff/init.lua` (git mv), `lua/plugins/codediff/explorer.lua`, `init.lua` — vérif: headless `require("plugins.codediff.explorer").setup()` à code de sortie, puis à la main (plan, Étape 1)
- [x] 2. Clic, double-clic et Entrée dans l'explorateur — `lua/plugins/codediff/explorer.lua`, `lua/plugins/codediff/init.lua` — clic par `vim.on_key` et non par un mapping `<LeftRelease>` (écart au plan, voir journal) — vérif: headless, clics réels sous tmux, puis à la main (plan, Étape 2)
- [x] 3. Curseur sur la première lettre du nom — `lua/plugins/codediff/explorer.lua` — repli du nom tronqué sur son plus long début (écart au plan, voir journal) — vérif: headless, clics réels sous tmux, puis à la main (plan, Étape 3)
- [x] 4. Documentation — `docs/plugins/codediff.md`, `CLAUDE.md` — vérif: `grep -nE '<leader>(b|E)\b' docs/plugins/codediff.md` vide ; `grep -rn 'plugins/codediff\.lua\|codediff_explorer' CLAUDE.md docs/` vide

## État courant

**Prochaine action** : vérification de bout en bout à la main (inline puis side-by-side `t`),
puis audit de Clôture.

**Essais headless** : config complète, `nvim --headless -c "luafile <essai>"` depuis un dépôt
jetable modifié, après un `:edit` d'un fichier existant (sinon E201 de satellite, voir journal).
Clics réels : Neovim `--listen` dans tmux, séquences SGR `\e[<0;col;rowM`/`m` par
`tmux send-keys -l` (le headless ignore `nvim_input_mouse`).
La reprise des mappings au `TabEnter` passe par `vim.schedule` : attendre avant
de lire `maparg`. Les mappings `j`/`k` du plugin ne se déclenchent que par `feedkeys(…, "mx")`.

**Vérification** : à chaque Étape, C6 —
`git -C ~/.local/share/nvim/lazy/codediff.nvim status --short | grep -v '^ M doc/tags$'` et
`git -C plugins/codediff.nvim status --short` vides ; en fin de chantier, la vérification de bout
en bout du plan, à la main, en layout inline puis side-by-side (`t`).

**Dernier audit** : 6cbce6d — FAVORABLE — 2026-10-31

**Notes** : plugin chargé = upstream `esmuellert/codediff.nvim` v4.0.6 (lazy) ; le fork
`plugins/codediff.nvim` n'est pas chargé.

## Passation

**Écrite** : session 1, après AE0

**En cours** : rien — aucune Étape commencée.

**À savoir** :
- Le tag `AE0` doit pointer sur `23b58a5` (commit E0) : un hook a empêché la session 1 de le
  poser. S'il manque (`git tag -l AE0` vide), le poser par `git tag AE0 23b58a5` avant l'Étape 1.
- Le `<leader>e` natif du plugin (`keymaps.view.focus_explorer`) et `<leader>b`
  (`toggle_explorer`) sont des défauts de `config.lua:110-111` de l'upstream : les mettre à `false`
  dans les `opts`, pas seulement retirer `<leader>E`.
- Dans le plan, le bloc `## Relecture` décrit le plan **avant** arbitrages (verdict NON CONFORME) ;
  les arbitrages qui suivent le bloc et la Conception font foi.

## Dettes écartées

<OPTIONNEL>

## Journal de décisions

- **2026-10-31** — `<leader>e` posé avec `suspendable = true` sur les buffers de diff, les mappings
  du buffer explorateur avec `suspendable = false`. *Pourquoi* : le buffer modifié peut être le
  vrai fichier, ouvert dans un autre tab ; le registre du plugin retire les mappings suspendables
  au `TabLeave`. *Rejeté* : `suspendable = false` partout (fuite hors du tab, contraire à C4).
- **2026-10-31** — Entrée : cacher l'explorateur et focus le diff **avant** `on_file_select`, sans
  délai. *Pourquoi* : `M.update` capture `saved_current_win` et le restaure en fin de chargement ;
  c'est la prise de focus temporaire qui cassait l'ancienne fermeture. *Rejeté* : fermeture
  différée sur `CodeDiffFileSelect` (S2).
- **2026-10-31** — Spec en répertoire `lua/plugins/codediff/` (`init.lua` + `explorer.lua`),
  importée par `plugins.codediff.init`. *Pourquoi* : demande de l'utilisateur ; l'import du
  répertoire chargerait `explorer.lua` comme spec.
- **2026-10-31** — `<leader>e` réclamé au `BufEnter`/`WinEnter` d'une fenêtre de la session
  (original, modifié, explorateur), filtre par fenêtre. *Pourquoi* : en chargement, le buffer neuf
  entre dans la fenêtre du diff avant que la session ne l'enregistre, puis le focus revient sans
  événement ; un flottant n'hérite pas de la claim. *Rejeté* : filtre par buffer de la session.
- **2026-10-31** — `inline_view.show_single_file` enveloppé pour rendre le focus à la fenêtre
  d'avant. *Pourquoi* : en inline, un fichier simple face (`??`, `A`, `D`) non chargé passe par
  `helpers.open_real_file`, qui focus le diff sans le rendre ; dépend d'un champ interne lu à
  chaque appel par `view/init.lua`. *Rejeté* : dette sans correctif ; délai (S2).
- **2026-10-31** — Clic simple guetté par `vim.on_key` (`<LeftRelease>` tapé ou rejoué), action au
  tour suivant si `getmousepos()` est dans l'explorateur. *Pourquoi* : le `<LeftMouse>` global de
  satellite rejoue la suite du clic par `feedkeys(…, "ni")`, sans remap. *Rejeté* : mapping
  `<LeftRelease>` (plan) ; `<LeftMouse>` local, qui perd le glisser de la barre de satellite.
- **2026-10-31** — Nom tronqué : curseur sur le plus long début du nom présent dans la ligne,
  sinon « … ». *Pourquoi* : en vue arbre la ligne commence par des traits (`├`, `│ └`), la fin
  de `%s*%S+%s` tombe sur l'icône. *Rejeté* : le repli du plan.
- **2026-10-31** — Hors périmètre, versé au registre de dette à la Clôture :
  `satellite-bufreadpre-premier-diff-codediff`, `codediff-opts-cles-inconnues` ; R2 :
  `codediff-enveloppe-show-single-file`.
