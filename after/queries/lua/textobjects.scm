;; extends
;; ── IF / ELSEIF condition ──────────────────────────────
;; ── WHILE condition ────────────────────────────────────
;; ── REPEAT UNTIL condition ─────────────────────────────
(_
  condition: ( _
               left: ((_) @condition.inner) 
  ) @condition.outer
)
(_
  condition: ( _
               right: ((_) @condition.inner)
  ) @condition.outer
)

(_
  condition: ( _
  ) @condition.inner @condition.outer
)

;; ── FOR numeric condition ──────────────────────────────
(for_numeric_clause
  start: (_) @condition.inner
  end: (_) @condition.inner
  step: (_)? @condition.inner
  ) @condition.outer

;; ── FOR generic condition ──────────────────────────────
(for_generic_clause
  (variable_list (_)) @condition.inner
  ; (expression_list (_) @condition.inner)
  ) @condition.outer

