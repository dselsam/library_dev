import clause prover_state
open expr list monad

meta def is_taut (c : cls) : tactic bool := do
qf ← cls.open_constn c c↣num_quants,
return $ list.bor (do
  l1 ← cls.get_lits qf.1, guard $ cls.lit.is_neg l1,
  l2 ← cls.get_lits qf.1, guard $ cls.lit.is_pos l2,
  [decidable.to_bool (cls.lit.formula l1 = cls.lit.formula l2)])

open tactic
example (i : Type) (p : i → i → Type) (c : i) (h : ∀ (x : i), p x c → p x c) : true := by do
h ← get_local `h, hcls ← monad.liftM (cls.mk 1 2 tt h) (infer_type h),
taut ← is_taut hcls,
when (¬taut) failed,
to_expr `(trivial) >>= apply

meta def tautology_removal_pre : resolution_prover unit :=
preprocessing_rule $ λnew, resolution_prover_of_tactic (filterM (λc, liftM bnot (is_taut c)) new)

meta def remove_duplicates_pre : resolution_prover unit :=
preprocessing_rule $ λnew,
return (rb_map.values (rb_map.of_list (list.map (λc:cls, (c↣type, c)) new)))

meta def only_pos_to_fin_pre : resolution_prover unit :=
preprocessing_rule $ take news, flip mapM news $ take new, do
match list.filter (λl : (cls.lit × ℕ), l↣1↣is_pos) new↣get_lits↣zip_with_index with
| [l] := do univ ← resolution_prover_of_tactic $ infer_univ l↣1↣formula,
            if ¬l↣1↣is_final ∧ univ = level.zero then
              resolution_prover_of_tactic (new↣focus l↣2)
            else
              return new
| _ := return new
end
