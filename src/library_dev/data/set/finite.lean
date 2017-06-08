/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl

Finite sets -- assuming a classical logic.
-/
import .basic
noncomputable theory

universes u v w
variables {α : Type u} {β : Type v} {ι : Sort w}

open set lattice

namespace set

/-
local attribute [instance] classical.decidable_inhabited
local attribute [instance] classical.prop_decidable
-/

inductive finite : set α → Prop
| empty : finite ∅
| insert : ∀a s, a ∉ s → finite s → finite (insert a s) 

attribute [simp] finite.empty 

@[simp]
lemma finite_insert {a : α} {s : set α} (h : finite s) : finite (insert a s) :=
classical.by_cases
  (suppose a ∈ s, by simph)
  (suppose a ∉ s, finite.insert a s this h)

@[simp]
lemma finite_singleton {a : α} : finite ({a} : set α) :=
finite_insert finite.empty

lemma finite_union {s t : set α} (hs : finite s) (ht : finite t) : finite (s ∪ t) :=
finite.drec_on ht (by simp [hs]) $ take a t _ _, by simp; exact finite_insert

lemma finite_subset {s : set α} (hs : finite s) : ∀{t}, t ⊆ s → finite t :=
begin
  induction hs with a t' ha ht' ih,
  { intros t ht, simp [(subset_empty_iff t)^.mp ht, finite.empty] },
  { intros t ht,
    note tm : finite (t \ {a}) :=
      (ih $ show t \ {a} ⊆ t',
        from take x ⟨hxt, hna⟩, or.resolve_left (ht hxt) (by simp at hna; assumption)),
    cases (classical.em $ a ∈ t) with ha hna,
    { have finite (insert a (t \ {a})), from finite_insert tm,
      show finite t,
        by simp [ha] at this; assumption },
    { simp [sdiff_singleton_eq_same, hna] at tm, exact tm } }
end

lemma finite_image {s : set α} {f : α → β} (h : finite s) : finite (f '' s) :=
begin
  induction h with a s' hns' hs' hi,
  simp [image_empty, finite.empty],
  simp [image_insert_eq, finite_insert, hi]
end

lemma finite_sUnion {s : set (set α)} (h : finite s) : (∀t∈s, finite t) → finite (⋃₀ s) :=
begin
  induction h with a s' hns' hs' hi,
  { simp [finite.empty] },
  { intro h,
    simp,
    apply finite_union,
    { apply h, simp },
    { exact (hi $ take t ht, h _ $ mem_insert_of_mem _ ht) } }
end

end set
