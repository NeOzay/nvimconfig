+++
id = "license-mentionne-edge-tts"
title = "Le LICENSE du plugin mentionne une dépendance supprimée"
date = 2026-08-18
reviewed = 2026-08-29
category = "pertinent"
+++

## Vérifié par

```
$ grep -rniE 'edge|openai' plugins/tts.nvim/
plugins/tts.nvim/LICENSE:27:This software uses the library edge_tts, licensed under the GNU Lesser General Public License v3 (LGPLv3).
```

Une seule occurrence dans tout le plugin, et c'est celle que l'entrée décrit. La recherche porte sur
l'arborescence entière — code, démon, doc, tests — donc l'absence ailleurs est établie par la même
commande.

## Verdict

Le constat tient. Le backend `edge` a bien disparu du code, et le `LICENSE` est le dernier endroit
qui l'affirme encore présent : une clause légale fausse, dans un fichier suivi par le dépôt.

`pertinent` et non `pas-une-dette` : ce n'est pas une préférence de style. Un fichier de licence qui
attribue une LGPLv3 à une dépendance absente est une affirmation juridique inexacte, et le critère
de l'entrée d'origine (« affirmation fausse dans un fichier légal suivi par ce dépôt ») est
vérifiable.

## Action

Rien à écrire au registre hors les deux champs de revue. À noter pour un futur chantier : c'est la
plus facile à solder des seize, et elle débloque au passage l'entrée
`verification-etape-2-clause-perdue`, dont la clause `! grep -rqi 'openai\|edge'` échoue
aujourd'hui sur ce seul fichier.

## Arbitrage

<OPTIONNEL>
