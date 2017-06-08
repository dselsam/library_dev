/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl

Defines bounded lattice type class hierarchy.

Includes the Prop and fun instances.
-/

import .basic

set_option old_structure_cmd true

universes u v
variable {α : Type u}

namespace lattice

/- Bounded lattices -/

class bounded_lattice (α : Type u) extends lattice α, order_top α, order_bot α

instance semilattice_inf_top_of_bounded_lattice (α : Type u) [bl : bounded_lattice α] : semilattice_inf_top α :=
{ bl with le_top := take x, @le_top α _ x }

instance semilattice_inf_bot_of_bounded_lattice (α : Type u) [bl : bounded_lattice α] : semilattice_inf_bot α :=
{ bl with bot_le := take x, @bot_le α _ x }

instance semilattice_sup_top_of_bounded_lattice (α : Type u) [bl : bounded_lattice α] : semilattice_sup_top α :=
{ bl with le_top := take x, @le_top α _ x }

instance semilattice_sup_bot_of_bounded_lattice (α : Type u) [bl : bounded_lattice α] : semilattice_sup_bot α :=
{ bl with bot_le := take x, @bot_le α _ x }

/- Prop instance -/
instance bounded_lattice_Prop : bounded_lattice Prop :=
{ lattice.bounded_lattice .
  le           := λa b, a → b,
  le_refl      := take _, id,
  le_trans     := take a b c f g, g ∘ f,
  le_antisymm  := take a b Hab Hba, propext ⟨Hab, Hba⟩,

  sup          := or, 
  le_sup_left  := @or.inl,
  le_sup_right := @or.inr,
  sup_le       := take a b c, or.rec,

  inf          := and,
  inf_le_left  := @and.left,
  inf_le_right := @and.right,
  le_inf       := take a b c Hab Hac Ha, and.intro (Hab Ha) (Hac Ha),

  top          := true,
  le_top       := take a Ha, true.intro,

  bot          := false,
  bot_le       := @false.elim }

section logic
variable [weak_order α]

lemma monotone_and {p q : α → Prop} (m_p : monotone p) (m_q : monotone q) :
  monotone (λx, p x ∧ q x) :=
take a b h, and.imp (m_p h) (m_q h)

lemma monotone_or {p q : α → Prop} (m_p : monotone p) (m_q : monotone q) :
  monotone (λx, p x ∨ q x) :=
take a b h, or.imp (m_p h) (m_q h)
end logic

/- Function lattices -/

/- TODO:
 * build up the lattice hierarchy for `fun`-functor piecewise. semilattic_*, bounded_lattice, lattice ...
 * can this be generalized to the dependent function space? 
-/
instance bounded_lattice_fun {α : Type u} {β : Type v} [bounded_lattice β] :
  bounded_lattice (α → β) :=
{ weak_order_fun with
  sup          := λf g a, f a ⊔ g a,
  le_sup_left  := take f g a, le_sup_left,
  le_sup_right := take f g a, le_sup_right,
  sup_le       := take f g h Hfg Hfh a, sup_le (Hfg a) (Hfh a),

  inf          := λf g a, f a ⊓ g a,
  inf_le_left  := take f g a, inf_le_left,
  inf_le_right := take f g a, inf_le_right,
  le_inf       := take f g h Hfg Hfh a, le_inf (Hfg a) (Hfh a),

  top          := λa, ⊤,
  le_top       := take f a, le_top,

  bot          := λa, ⊥,
  bot_le       := take f a, bot_le }

end lattice
