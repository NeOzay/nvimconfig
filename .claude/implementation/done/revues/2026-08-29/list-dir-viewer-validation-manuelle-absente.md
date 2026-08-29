+++
id = "list-dir-viewer-validation-manuelle-absente"
title = "La validation manuelle du chantier `list-dir-viewer` n'a jamais été faite"
date = 2026-08-29
reviewed = 2026-08-29
category = "inverifiable"
+++

## Vérifié par

Aucune commande n'est exécutable, et c'est le fond du sujet : l'entrée porte un **fait historique**
— un contrôle interactif qui n'a pas eu lieu — et non un état du code. Aucune lecture du dépôt ne
peut établir qu'une session Neovim n'a pas été ouverte : l'absence de trace n'est pas une preuve,
et une trace ne serait pas produite par une session réussie.

Le seul constat vérifiable est que rien n'a changé depuis, ce qui ne dit rien du fait lui-même :

```
$ grep -rc 'ListDir' .claude/implementation/done/2026-08-29-list-dir-viewer.md
0
```

C'est exactement le cas que `categories.md` décrit sous `inverifiable` : « le constat porte un fait
historique, pas un état du code […] "personne n'a relu ce diff" ».

## Verdict

`inverifiable`. Le constat restera vrai indéfiniment — une validation qui n'a pas eu lieu à
l'époque ne peut plus avoir lieu à l'époque. Son **Pour solder** est de nature passive (« passer une
fois la chaîne complète dans une session interactive ») : il ne sera pas soldé par une commande mais
par un usage, et cet usage ne laissera pas de trace mécanique.

Le marquer évite qu'il repasse en `pertinent` à chaque revue et n'occupe la pile qui demande une
décision.

## Action

Reste au registre, `category = "inverifiable"` et `reviewed = 2026-08-29`. Les revues suivantes le
liront sans le réinstruire, sauf si son **Pour solder** devient actionnable — ce qui supposerait un
moyen d'attester la session, qui n'existe pas aujourd'hui.

## Arbitrage

<OPTIONNEL>
