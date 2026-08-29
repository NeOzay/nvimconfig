+++
id = "registre-attribution-dans-pour-solder"
title = "La ligne d'attribution des entrées est avalée par la section « Pour solder »"
date = 2026-08-29
reviewed = 2026-08-29
category = "pertinent"
+++

## Vérifié par

La ligne tombe dans `## Pour solder` sur exactement les 13 entrées migrées :

```
$ awk '/^## Pour solder/{f=1;next} /^## /{f=0} f && /Identifié par/{print FILENAME}' \
    .claude/implementation/todo/technical-debt/*.md | wc -l
13
```

Et le champ prévu pour la porter est vide sur la totalité du registre :

```
$ grep -h '^source = ' .claude/implementation/todo/technical-debt/*.md | sort | uniq -c
     16 source = "<OPTIONNEL>"
```

## Verdict

Le constat tient, et les deux chiffres sont exacts : 13 entrées portent l'attribution dans une
section qui n'est pas la sienne, et les 16 ont `source` au marqueur. Le contrat déclare bien ce
champ — c'est donc une donnée structurée disponible, laissée en prose.

`pertinent` et non `pas-une-dette` : ce n'est pas une préférence de mise en forme. Le champ existe
au contrat, `list --where source=…` est le geste que le format rend possible, et il ne rend
aujourd'hui rien d'exploitable. L'entrée porte un critère vérifiable, pas un goût.

## Action

Reste au registre avec ses deux champs de revue. À noter pour le chantier qui la soldera : le report
touche 13 fichiers et `validate` reste vert avant comme après, `source` étant facultatif — la
vérification devra donc être le `grep` ci-dessus, ramené à 0.

## Arbitrage

<OPTIONNEL>
