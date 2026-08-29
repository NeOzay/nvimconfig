+++
id = "verification-etape-2-clause-perdue"
title = "La vérification de l'étape 2 a perdu une clause du plan"
date = 2026-08-18
source = "<OPTIONNEL>"
reviewed = "<OPTIONNEL>"
category = "<OPTIONNEL>"
+++

## Constat

L'étape 2 du suivi `tts-piper` a laissé tomber la clause `! grep -rqi 'openai\|edge'` que portait le
plan. Rejouée à l'audit, elle échouerait aujourd'hui, sur `LICENSE` seul. La réserve du
`plan-reviewer` sur l'étape 4 (démon + unit systemd + doc pour une seule vérification de présence)
est du même ordre : assumée, jamais levée.

## Pourquoi c'est gênant

Un lecteur ultérieur ne peut pas distinguer un assouplissement raisonné d'un oubli ; l'écart n'est
justifié ni dans l'étape ni au journal.

## Pour solder

Au prochain chantier sur ce plugin, justifier l'écart au journal ou rétablir la clause une fois le
`LICENSE` corrigé.

*Identifié par `implementation-auditor`, R9 du rapport d'audit `tts-piper`.*

## Assumé

<OPTIONNEL>
