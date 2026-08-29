+++
id = "registre-attribution-dans-pour-solder"
title = "La ligne d'attribution des entrées est avalée par la section « Pour solder »"
date = 2026-08-29
source = "<OPTIONNEL>"
reviewed = 2026-08-29
category = "pertinent"
+++

## Constat

Les 13 entrées migrées se terminent par « *Identifié par `implementation-auditor`, R<n> du rapport
d'audit …* ». Le découpage en sections n'ayant pas de fin de section, cette ligne appartient à
`## Pour solder`, dont elle n'est pas le contenu. Le contrat déclare pourtant un champ `source` —
« le chantier qui l'a identifiée, et où il l'a écrit » — laissé au marqueur `<OPTIONNEL>` sur les
treize, par décision de périmètre du chantier `debt-registry-migration`.

## Pourquoi c'est gênant

`list --where source=…` et `--sort source` ne rendent rien d'exploitable, alors que la donnée est
là : retrouver ce qu'un audit donné a laissé derrière lui demande de lire les treize fichiers.
Une agglomération par `merge` rend par ailleurs l'attribution comme un paragraphe du plan de
solde, ce qu'elle n'est pas.

## Pour solder

Reporter la ligne dans le champ `source` de chaque entrée qui en porte une, et la retirer du corps.
`validate` reste vert dans les deux états, `source` étant facultatif — le contrôle est donc à faire
à la lecture, entrée par entrée.

## Assumé

Le report avait été explicitement écarté du périmètre de la migration, pour qu'elle ne transforme
aucun contenu au-delà des repères de ligne. Relevé par `implementation-auditor`, R2 du rapport
d'audit `debt-registry-migration`.
