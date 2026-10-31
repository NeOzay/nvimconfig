+++
id = "codediff-enveloppe-show-single-file"
title = "Le retour du focus après un fichier simple face tient à un champ interne de codediff, sans alerte s'il change"
date = 2026-10-31
severite = "avertissement"
chantier = "codediff-explorer"
reference = "R2"
pin = false
reviewed = "<OPTIONNEL date>"
category = "<OPTIONNEL>"
+++

## Constat

`restore_focus_after_single_file` (`lua/plugins/codediff/explorer.lua`) remplace à l'exécution le
champ interne `inline_view.show_single_file` de l'upstream `esmuellert/codediff.nvim`, que
`ui/view/init.lua` relit à chaque appel. L'enveloppe rend le focus que `helpers.open_real_file`
prend sans le rendre pour un fichier simple face (`??`, `A`, `D`) pas encore chargé, en layout
inline. Elle s'applique aussi hors des sessions explorateur (standalone, historique en inline).

Établi par : audits de clôture de `codediff-explorer` (`de69218`, `6cbce6d`) — sous tmux, un clic
sur un fichier `??` laisse le focus dans l'explorateur sur la v4.0.6.

## Pourquoi c'est gênant

L'upstream est mis à jour par lazy. Si le champ change de nom ou si l'appel passe ailleurs,
l'enveloppe ne s'applique plus sans rien signaler, et le focus volé revient en silence ; si le
module disparaît, `setup()` échoue au chargement. Le Gotcha de `docs/plugins/codediff.md` demande
de revérifier à chaque mise à jour, mais rien ne le déclenche.

## Pour solder

Rendre la casse visible : dans `setup()`, vérifier que `inline_view.show_single_file` est une
fonction et sinon le signaler par `vim.notify(…, vim.log.levels.WARN)` au lieu de poser
l'enveloppe ; ou figer la version de l'upstream dans la spec (`version`/`commit`). À terme,
proposer à l'upstream de rendre le focus dans `helpers.open_real_file`, puis retirer l'enveloppe.
Vérifier par un clic sur un fichier `??` non chargé en inline, focus resté dans l'explorateur.

## Assumé

Laissé à la clôture de `codediff-explorer` : l'utilisateur a choisi de traiter R1 et R3 seulement.
