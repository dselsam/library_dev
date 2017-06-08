/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl

Theory of complete Boolean algebras.
-/
import .complete_lattice .boolean_algebra data.set.basic

set_option old_structure_cmd true

universes u v w
variables {α : Type u} {β : Type v} {ι : Sort w}

namespace lattice

class complete_distrib_lattice α extends complete_lattice α :=
(infi_sup_le_sup_Inf : ∀a s, (⨅ b ∈ s, a ⊔ b) ≤ a ⊔ Inf s)
(inf_Sup_le_supr_inf : ∀a s, a ⊓ Sup s ≤ (⨆ b ∈ s, a ⊓ b))

section complete_distrib_lattice
variables [complete_distrib_lattice α] {a : α} {s : set α}

lemma sup_Inf_eq : a ⊔ Inf s = (⨅ b ∈ s, a ⊔ b) :=
le_antisymm
  (le_infi $ take i, le_infi $ take h, sup_le_sup (le_refl _) (Inf_le h))
  (complete_distrib_lattice.infi_sup_le_sup_Inf _ _)

lemma inf_Sup_eq : a ⊓ Sup s = (⨆ b ∈ s, a ⊓ b) :=
le_antisymm
  (complete_distrib_lattice.inf_Sup_le_supr_inf _ _)
  (supr_le $ take i, supr_le $ take h, inf_le_inf (le_refl _) (le_Sup h))

end complete_distrib_lattice

instance [d : complete_distrib_lattice α] : bounded_distrib_lattice α :=
{ d with 
  le_sup_inf := take x y z,
    calc (x ⊔ y) ⊓ (x ⊔ z) ≤ (⨅ b ∈ ({z, y} : set α), x ⊔ b) : by rw insert_of_has_insert; simp
      ... = x ⊔ Inf {z, y} : sup_Inf_eq^.symm
      ... = x ⊔ y ⊓ z : by rw insert_of_has_insert; simp }

class complete_boolean_algebra α extends boolean_algebra α, complete_distrib_lattice α

section complete_boolean_algebra
variables [complete_boolean_algebra α] {a b : α} {s : set α} {f : ι → α}

lemma neg_infi : - infi f = (⨆i, - f i) :=
le_antisymm
  (neg_le_of_neg_le $ le_infi $ take i, neg_le_of_neg_le $ le_supr (λi, - f i) i)
  (supr_le $ take i, neg_le_neg $ infi_le _ _)

lemma neg_supr : - supr f = (⨅i, - f i) :=
neg_eq_neg_of_eq (by simp [neg_infi])

lemma neg_Inf : - Inf s = (⨆i∈s, - i) :=
by simp [Inf_eq_infi, neg_infi]

lemma neg_Sup : - Sup s = (⨅i∈s, - i) :=
by simp [Sup_eq_supr, neg_supr]

end complete_boolean_algebra

end lattice
