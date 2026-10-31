+++
gabarit = "brief"
slug = "codediff-explorer"
titre = "Modifier le comportement de l'explorateur de fichiers de codediff, sans toucher au code source du plugin"
statut = "validé"
"créé" = 2026-10-31
+++

## Intention

**Symptôme** : l'explorateur de codediff ne se pilote pas comme voulu — un clic simple sur un
fichier n'affiche rien (seul le double-clic ouvre), l'explorateur reste ouvert après Entrée, et
l'ancienne fermeture automatique « ne fonctionnait pas bien ».

**But** : dans un tab CodeDiff, piloter l'explorateur à la souris et au clavier — clic pour voir un
diff, Entrée pour y aller en refermant l'explorateur, `<leader>e` pour l'ouvrir, le focus ou le
fermer —, depuis la configuration seule ; d'autres comportements pourront s'ajouter.

## Critères de réussite

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
  commentée.
- **C7** — `docs/plugins/codediff.md` décrit l'upstream réellement chargé, `<leader>e`, le clic,
  le double-clic et Entrée, et ne mentionne plus `<leader>b` ni `<leader>E`.

## Hors-périmètre

- Toute modification du code source du plugin : ni l'upstream installé par lazy, ni le fork
  `plugins/codediff.nvim`.
- `<leader>e` hors d'un tab CodeDiff.
- La navigation `]f`/`[f` : l'utilisateur ne s'en sert pas, elle n'a pas de comportement à définir.

## Signaux de dérive

- **S1** — Le diff touche un fichier du plugin (upstream ou fork), ou réactive la ligne `dir`
  (dit)
- **S2** — Un délai arbitraire (`vim.defer_fn(…, N)`) attend que le plugin se stabilise, comme le
  faisait l'ancienne fermeture (dépôt: `9ed7a31`)
- **S3** — `<leader>e` est mappé globalement au lieu d'être local au buffer d'un tab CodeDiff (dit)
- **S4** — Le code recopie une fonction interne du plugin (rendu, arbre) au lieu d'appeler son API
  ou de poser un mapping par-dessus (dit)

## Contraintes connues de l'utilisateur

- **Intouchable** : le code source de codediff, upstream comme fork, ne se modifie pas (dit)
- **Existant** : la spec charge l'upstream `esmuellert/codediff.nvim` depuis lazy ; le `dir` vers le
  fork est commenté (dépôt: `lua/plugins/codediff.lua`)
- **Historique** : la fermeture de l'explorateur sur `User CodeDiffFileSelect`, différée de 50 ms,
  ne fonctionnait pas bien ; elle est commentée (dit) (dépôt: `9ed7a31`)
- **Historique** : un diff pas encore chargé prend temporairement le focus ; c'est ce qui cassait
  l'ancienne fermeture (dit)
- **Décision** : `<leader>e` n'existe que dans un tab CodeDiff ; il ouvre et focus l'explorateur,
  ou le ferme s'il a le focus (dit)
- **Décision** : un clic simple sur un fichier affiche son diff, comme `auto_open_on_cursor`, et le
  focus reste sur l'explorateur ; un clic sur un dossier bascule son pli (dit)
- **Décision** : Entrée sur un fichier met le focus sur le diff et ferme l'explorateur (dit)
- **Décision** : le double-clic a un comportement identique à Entrée (dit)
- **Décision** : quand l'explorateur prend le focus, le curseur se place sur la première lettre du
  nom du fichier ou du dossier, après l'indentation et l'icône (dit)
- **Décision** : `<leader>e` remplace `<leader>E` ; `<leader>E` n'est plus mappé dans la vue
  diff (dit)
- **Décision** : Entrée sur un dossier garde le comportement du plugin, la bascule du pli, et
  l'explorateur reste ouvert (dit)
- **Décision** : validation à la main dans Neovim, sans tests automatisés (dit)
- **Décision** : `docs/plugins/codediff.md` se met à jour — elle décrit aujourd'hui le fork en
  submodule comme chargé, et `<leader>b` comme toggle de l'explorer (dit) (dépôt:
  `docs/plugins/codediff.md`)
- **Existant** : le buffer de l'explorateur a le filetype `codediff-explorer` ; le plugin pose déjà
  `<2-LeftMouse>` et, avec `auto_open_on_cursor`, `j`/`k`/`<Down>`/`<Up>` en mappings de buffer
  (dépôt: `codediff.nvim/lua/codediff/ui/explorer/render.lua`, `keymaps.lua`)

## Incertitudes à lever en plan

— aucune
