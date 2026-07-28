---
slug: bookmarks-note
titre: Notes de bookmarks (popup Snacks multi-ligne)
branche: bookmarks-note
base: master
statut: terminé
session: 2
plan: /var/home/Benoit/.config/nvim/.claude/plans/noble-coalescing-quokka.md
créé: 2026-07-27
maj: 2026-07-28
---

## Objectif et périmètre

**But** : ajouter une note multi-ligne à un bookmark, distincte de l'annotation courte
existante (`<leader>ba`). `<leader>bK` ouvre un popup flottant Snacks (`Snacks.win`)
pré-rempli avec la note existante, sauvegardée automatiquement à la fermeture du popup.
Une icône (pas le texte) s'affiche en virtual text sur la ligne si une note est présente.

**Critères de réussite** :
- `<leader>bK` sur une ligne sans bookmark crée le bookmark et ouvre le popup vide.
- Fermer le popup (`q`, `<Esc>`, `:q`, `WinClosed`) sauvegarde le texte en DB (colonne `note`).
- Rouvrir `<leader>bK` sur le même bookmark pré-remplit le texte précédent.
- Icône gutter visible uniquement si `note` non vide ; indépendante de l'annotation existante.
- Migration `ALTER TABLE ADD COLUMN note` idempotente sur une base SQLite déjà existante.

**Hors-périmètre** : affichage du contenu de la note (texte) dans le picker Snacks
(`snacks_picker.lua`) et dans Trouble (`trouble.lua`) — seule l'icône gutter l'indique.
Ouvrir le popup de note (`note.lua`) avec `K` depuis ces deux vues fait partie du périmètre
(ajouté le 2026-07-28, voir journal).

## Étapes

- [x] 1. Migration schéma DB (`db.lua`) — colonne `note`, `PRAGMA table_info` + `ALTER TABLE` (commit: e9986a7)
- [x] 2. Service (`service.lua`) — `opts.note` sur `add`, nouvelle fonction `set_note` (commit: 275d184)
- [x] 3. Config (`config.lua`) — `signs.note_icon` / `signs.note_hl_group` (commit: 358b7e9)
- [x] 4. UI (`ui.lua`) — second chunk `virt_text` icône si `record.note` non vide (commit: 3dbf8a3)
- [x] 5. Popup Snacks (`note.lua`, nouveau) — `Snacks.win` + `on_close` sauvegarde (commit: 7ea708f)
- [x] 6. Commande `BookmarkNote` + keymap `<leader>bK` (`init.lua` + `lua/plugins/bookmarks.lua`) (commit: 7ea708f)
- [x] 7. Keymap `K` dans `snacks_picker.lua` et `trouble.lua` — ouvre `note.lua` sur l'entrée courante,
      indicateur (icône) de présence de note dans les deux, zindex du popup corrigé (au-dessus du picker) (commit: 7ea708f)
- [x] 8. Documentation (`docs/plugins/bookmarks.md`)

## État courant

**Prochaine action** : aucune — chantier clôturé, branche aplatie dans `master`.
**Vérification** : voir section "Vérification" du plan `noble-coalescing-quokka.md`.
**Notes** : note_icon final = `md-feather` (`󰛓`, U+F06D3), choisi parmi options nerd-font
(fountain_pen, pen_fancy, pen_nib, feather) après recherche dans la police installée.
Bug corrigé : `db.update` ignore les clés à `nil` (`pairs` les saute), donc `set_note(id, nil)`
ne vidait jamais la colonne. `note.lua` passe désormais `""` (jamais `nil`) à la fermeture du
popup ; `nil` reste réservé à un futur appelant qui voudrait ne pas toucher au champ.
`note.lua` accepte `opts.on_saved` (rappelé après sauvegarde) ; picker (`picker:refresh()`) et
Trouble (`view:refresh()`) l'utilisent pour se rafraîchir à la fermeture du popup.
Bug corrigé : `<C-k>`/`<C-K>` dans le picker Snacks entrait en collision avec le binding
intégré `list_up` (`<c-k>`, input **et** list — `snacks/picker/config/defaults.lua:252,306`),
empêchant `bookmark_note` de se déclencher. Remplacé par `K` en list.
Second bug corrigé : `<M-k>` en input ne fonctionnait pas non plus — sans `mode = {"i","n"}`
explicite, le terminal envoie ESC puis `k` pour Alt+k, et Neovim quitte l'insert sur le ESC nu
avant de pouvoir reconstituer la touche Alt (ambiguïté classique). Testé d'abord avec `<C-y>`
(sans ambiguïté sur Ctrl) puis confirmé que `<M-k>` fonctionne en ajoutant `mode = {"i","n"}`
explicite — solution finale retenue. Le `K` de Trouble n'a pas ce conflit (aucun binding par
défaut dessus).
**Note** : `<M-d>` (bookmark_delete, input) a probablement le même défaut (pas de `mode`
explicite) — préexistant à ce chantier, pas corrigé sans confirmation de l'utilisateur.
Alignement Trouble corrigé (2 passes) : d'abord padding dynamique via `strdisplaywidth`, puis
bug réel trouvé — `trouble.nvim` fait `vim.trim()` sur le champ `text` avant affichage
(`format.lua:179`), qui ne reconnaît que les espaces ASCII et bouffe donc le padding en tête
de chaîne des entrées sans note. Remplacé par des espaces insécables (`\u{00A0}`), invisibles
à `vim.trim` (pattern Lua `%s`), pour le padding uniquement (`trouble.lua`).

## Journal de décisions

- **2026-07-27** — Champ `note` distinct de `annotation`, pas de fusion. *Pourquoi* : usages
  différents (annotation courte visible en permanence vs mémo long consultable à la demande).
  *Rejeté* : réutiliser `annotation` avec saisie popup (aurait mélangé les deux besoins).
- **2026-07-27** — Icône seule en virt_text, pas le contenu de la note. *Pourquoi* : demande
  explicite de l'utilisateur, évite d'alourdir le gutter avec du texte long. *Rejeté* : afficher
  un extrait tronqué comme pour l'annotation.
- **2026-07-28** — Périmètre élargi : keymap `K` dans picker Snacks et Trouble pour ouvrir le
  popup de note. *Pourquoi* : demande explicite de l'utilisateur, distincte de l'affichage du
  texte (toujours hors-périmètre). *Rejeté* : nouvelle implémentation séparée — trop lié au même
  code (`note.lua`) pour justifier un second chantier.

### Décisions antérieures

—
