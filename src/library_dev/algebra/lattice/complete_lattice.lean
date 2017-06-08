/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl

Theory of complete lattices.
-/
import .bounded_lattice

set_option old_structure_cmd true

universes u v w w₂
variables {α : Type u} {β : Type v} {ι : Sort w} {ι₂ : Sort w₂}

namespace set

theorem subset_union_left (s t : set α) : s ⊆ s ∪ t := λ x H, or.inl H

theorem subset_union_right (s t : set α) : t ⊆ s ∪ t := λ x H, or.inr H

end set

namespace lattice

class has_Sup (α : Type u) := (Sup : set α → α)
class has_Inf (α : Type u) := (Inf : set α → α)
def Sup [has_Sup α] : set α → α := has_Sup.Sup
def Inf [has_Inf α] : set α → α := has_Inf.Inf

class complete_lattice (α : Type u) extends bounded_lattice α, has_Sup α, has_Inf α :=
(le_Sup : ∀s, ∀a∈s, a ≤ Sup s)
(Sup_le : ∀s a, (∀b∈s, b ≤ a) → Sup s ≤ a)
(Inf_le : ∀s, ∀a∈s, Inf s ≤ a)
(le_Inf : ∀s a, (∀b∈s, a ≤ b) → a ≤ Inf s)

def supr [complete_lattice α] (s : ι → α) : α := Sup {a : α | ∃i : ι, a = s i}
def infi [complete_lattice α] (s : ι → α) : α := Inf {a : α | ∃i : ι, a = s i}

notation `⨆` binders `, ` r:(scoped f, supr f) := r
notation `⨅` binders `, ` r:(scoped f, infi f) := r

section
open set
variables [complete_lattice α] {s t : set α} {a b : α}

lemma le_Sup : a ∈ s → a ≤ Sup s         := complete_lattice.le_Sup s a
lemma Sup_le : (∀b∈s, b ≤ a) → Sup s ≤ a := complete_lattice.Sup_le s a
lemma Inf_le : a ∈ s → Inf s ≤ a         := complete_lattice.Inf_le s a
lemma le_Inf : (∀b∈s, a ≤ b) → a ≤ Inf s := complete_lattice.le_Inf s a

lemma le_Sup_of_le (hb : b ∈ s) (h : a ≤ b) : a ≤ Sup s :=
le_trans h (le_Sup hb)

lemma Inf_le_of_le (hb : b ∈ s) (h : b ≤ a) : Inf s ≤ a :=
le_trans (Inf_le hb) h

lemma Sup_le_Sup (h : s ⊆ t) : Sup s ≤ Sup t :=
Sup_le (take a, assume ha : a ∈ s, le_Sup $ h ha)

lemma Inf_le_Inf (h : s ⊆ t) : Inf t ≤ Inf s :=
le_Inf (take a, assume ha : a ∈ s, Inf_le $ h ha)

lemma le_Sup_iff : Sup s ≤ a ↔ (∀b ∈ s, b ≤ a) :=
⟨suppose Sup s ≤ a, take b, suppose b ∈ s,
  le_trans (le_Sup ‹b ∈ s›) ‹Sup s ≤ a›,
  Sup_le⟩

lemma Inf_le_iff : a ≤ Inf s ↔ (∀b ∈ s, a ≤ b) :=
⟨suppose a ≤ Inf s, take b, suppose b ∈ s,
  le_trans ‹a ≤ Inf s› (Inf_le ‹b ∈ s›),
  le_Inf⟩

-- how to state this? instead a parameter `a`, use `∃a, a ∈ s` or `s ≠ ∅`?
lemma Inf_le_Sup (h : a ∈ s) : Inf s ≤ Sup s :=
Inf_le_of_le h (le_Sup h)

lemma Sup_union {s t : set α} : Sup (s ∪ t) = Sup s ⊔ Sup t :=
le_antisymm
  (Sup_le $ take a h, or.rec_on h (le_sup_left_of_le ∘ le_Sup) (le_sup_right_of_le ∘ le_Sup))
  (sup_le (Sup_le_Sup $ subset_union_left _ _) (Sup_le_Sup $ subset_union_right _ _))

lemma Sup_inter_le {s t : set α} : Sup (s ∩ t) ≤ Sup s ⊓ Sup t :=
Sup_le (take a ⟨a_s, a_t⟩, le_inf (le_Sup a_s) (le_Sup a_t))

lemma Inf_union {s t : set α} : Inf (s ∪ t) = Inf s ⊓ Inf t :=
le_antisymm
  (le_inf (Inf_le_Inf $ subset_union_left _ _) (Inf_le_Inf $ subset_union_right _ _))
  (le_Inf $ take a h, or.rec_on h (inf_le_left_of_le ∘ Inf_le) (inf_le_right_of_le ∘ Inf_le))

lemma le_Inf_inter {s t : set α} : Inf s ⊔ Inf t ≤ Inf (s ∩ t) :=
le_Inf (take a ⟨a_s, a_t⟩, sup_le (Inf_le a_s) (Inf_le a_t))

@[simp]
lemma Sup_empty : Sup ∅ = (⊥ : α) :=
le_antisymm (Sup_le (take _, false.elim)) bot_le

@[simp]
lemma Inf_empty : Inf ∅ = (⊤ : α) :=
le_antisymm le_top (le_Inf (take _, false.elim))

@[simp]
lemma Sup_univ : Sup univ = (⊤ : α) :=
le_antisymm le_top (le_Sup ⟨⟩)

@[simp]
lemma Inf_univ : Inf univ = (⊥ : α) :=
le_antisymm (Inf_le ⟨⟩) bot_le

@[simp]
lemma Sup_insert {a : α} {s : set α} : Sup (insert a s) = a ⊔ Sup s :=
have Sup {b | b = a} = a,
  from le_antisymm (Sup_le $ take b b_eq, b_eq ▸ le_refl _) (le_Sup rfl),
calc Sup (insert a s) = Sup {b | b = a} ⊔ Sup s : Sup_union
                  ... = a ⊔ Sup s : by rw [this]

@[simp]
lemma Inf_insert {a : α} {s : set α} : Inf (insert a s) = a ⊓ Inf s :=
have Inf {b | b = a} = a,
  from le_antisymm (Inf_le rfl) (le_Inf $ take b b_eq, b_eq ▸ le_refl _),
calc Inf (insert a s) = Inf {b | b = a} ⊓ Inf s : Inf_union
                  ... = a ⊓ Inf s : by rw [this]

@[simp]
lemma Sup_singleton {a : α} : Sup {a} = a :=
eq.trans Sup_insert $ by simp

@[simp]
lemma Inf_singleton {a : α} : Inf {a} = a :=
eq.trans Inf_insert $ by simp

end


/- supr & infi -/

section
open set
variables [complete_lattice α] {s t : ι → α} {a b : α}

lemma le_supr (s : ι → α) (i : ι) : s i ≤ supr s :=
le_Sup ⟨i, rfl⟩

lemma le_supr_of_le (i : ι) (h : a ≤ s i) : a ≤ supr s :=
le_trans h (le_supr _ i)

lemma supr_le (h : ∀i, s i ≤ a) : supr s ≤ a :=
Sup_le $ take b ⟨i, eq⟩, eq^.symm ▸ h i

lemma supr_le_supr (h : ∀i, s i ≤ t i) : supr s ≤ supr t :=
supr_le $ take i, le_supr_of_le i (h i)

lemma supr_le_supr2 {t : ι₂ → α} (h : ∀i, ∃j, s i ≤ t j) : supr s ≤ supr t :=
supr_le $ take j, exists.elim (h j) le_supr_of_le

lemma supr_le_supr_const (h : ι → ι₂) : (⨆ i:ι, a) ≤ (⨆ j:ι₂, a) :=
supr_le $ le_supr _ ∘ h

lemma supr_le_iff : supr s ≤ a ↔ (∀i, s i ≤ a) :=
⟨suppose supr s ≤ a, take i, le_trans (le_supr _ _) this, supr_le⟩

@[congr]
lemma supr_congr_Prop {p q : Prop} {f₁ : p → α} {f₂ : q → α}
  (pq : p ↔ q) (f : ∀x, f₁ (pq^.mpr x) = f₂ x) : supr f₁ = supr f₂ :=
le_antisymm
  (supr_le_supr2 $ take j, ⟨pq^.mp j, le_of_eq $ f _⟩)
  (supr_le_supr2 $ take j, ⟨pq^.mpr j, le_of_eq $ (f j)^.symm⟩)

lemma infi_le (s : ι → α) (i : ι) : infi s ≤ s i :=
Inf_le ⟨i, rfl⟩

lemma infi_le_of_le (i : ι) (h : s i ≤ a) : infi s ≤ a :=
le_trans (infi_le _ i) h

lemma le_infi (h : ∀i, a ≤ s i) : a ≤ infi s :=
le_Inf $ take b ⟨i, eq⟩, eq^.symm ▸ h i

lemma infi_le_infi (h : ∀i, s i ≤ t i) : infi s ≤ infi t :=
le_infi $ take i, infi_le_of_le i (h i)

lemma infi_le_infi2 {t : ι₂ → α} (h : ∀j, ∃i, s i ≤ t j) : infi s ≤ infi t :=
le_infi $ take j, exists.elim (h j) infi_le_of_le

lemma infi_le_infi_const (h : ι₂ → ι) : (⨅ i:ι, a) ≤ (⨅ j:ι₂, a) :=
le_infi $ infi_le _ ∘ h

lemma le_infi_iff : a ≤ infi s ↔ (∀i, a ≤ s i) :=
⟨suppose a ≤ infi s, take i, le_trans this (infi_le _ _), le_infi⟩

@[congr]
lemma infi_congr_Prop {p q : Prop} {f₁ : p → α} {f₂ : q → α}
  (pq : p ↔ q) (f : ∀x, f₁ (pq^.mpr x) = f₂ x) : infi f₁ = infi f₂ :=
le_antisymm
  (infi_le_infi2 $ take j, ⟨pq^.mpr j, le_of_eq $ f j⟩)
  (infi_le_infi2 $ take j, ⟨pq^.mp j, le_of_eq $ (f _)^.symm⟩)

lemma infi_const {a : α} (b : ι) : (⨅ b:ι, a) = a :=
le_antisymm (Inf_le ⟨b, rfl⟩) (le_Inf $ take a' ⟨b', h⟩, h^.symm ▸ le_refl _)

lemma supr_const {a : α} (b : ι) : (⨆ b:ι, a) = a :=
le_antisymm (Sup_le $ take a' ⟨b', h⟩, h^.symm ▸ le_refl _) (le_Sup ⟨b, rfl⟩)

lemma infi_comm {f : ι → ι₂ → α} : (⨅i, ⨅j, f i j) = (⨅j, ⨅i, f i j) :=
le_antisymm
  (le_infi $ take i, le_infi $ take j, infi_le_of_le j $ infi_le _ i)
  (le_infi $ take j, le_infi $ take i, infi_le_of_le i $ infi_le _ j)

lemma supr_comm {f : ι → ι₂ → α} : (⨆i, ⨆j, f i j) = (⨆j, ⨆i, f i j) :=
le_antisymm
  (supr_le $ take i, supr_le $ take j, le_supr_of_le j $ le_supr _ i)
  (supr_le $ take j, supr_le $ take i, le_supr_of_le i $ le_supr _ j)

@[simp]
lemma infi_infi_eq_left {b : β} {f : Πx:β, x = b → α} : (⨅x, ⨅h:x = b, f x h) = f b rfl :=
le_antisymm
  (infi_le_of_le b $ infi_le _ rfl)
  (le_infi $ take b', le_infi $ take eq, match b', eq with ._, rfl := le_refl _ end)

@[simp]
lemma infi_infi_eq_right {b : β} {f : Πx:β, b = x → α} : (⨅x, ⨅h:b = x, f x h) = f b rfl :=
le_antisymm
  (infi_le_of_le b $ infi_le _ rfl)
  (le_infi $ take b', le_infi $ take eq, match b', eq with ._, rfl := le_refl _ end)

@[simp]
lemma supr_supr_eq_left {b : β} {f : Πx:β, x = b → α} : (⨆x, ⨆h : x = b, f x h) = f b rfl :=
le_antisymm
  (supr_le $ take b', supr_le $ take eq, match b', eq with ._, rfl := le_refl _ end)
  (le_supr_of_le b $ le_supr _ rfl)

@[simp]
lemma supr_supr_eq_right {b : β} {f : Πx:β, b = x → α} : (⨆x, ⨆h : b = x, f x h) = f b rfl :=
le_antisymm
  (supr_le $ take b', supr_le $ take eq, match b', eq with ._, rfl := le_refl _ end)
  (le_supr_of_le b $ le_supr _ rfl)

lemma infi_inf_eq {f g : β → α} : (⨅ x, f x ⊓ g x) = (⨅ x, f x) ⊓ (⨅ x, g x) :=
le_antisymm
  (le_inf
    (le_infi $ take i, infi_le_of_le i inf_le_left)
    (le_infi $ take i, infi_le_of_le i inf_le_right))
  (le_infi $ take i, le_inf
    (inf_le_left_of_le $ infi_le _ _)
    (inf_le_right_of_le $ infi_le _ _))

lemma supr_sup_eq {f g : β → α} : (⨆ x, f x ⊔ g x) = (⨆ x, f x) ⊔ (⨆ x, g x) :=
le_antisymm
  (supr_le $ take i, sup_le
    (le_sup_left_of_le $ le_supr _ _)
    (le_sup_right_of_le $ le_supr _ _))
  (sup_le
    (supr_le $ take i, le_supr_of_le i le_sup_left)
    (supr_le $ take i, le_supr_of_le i le_sup_right))

/- supr and infi under Prop -/

@[simp]
lemma infi_false {s : false → α} : infi s = ⊤ :=
le_antisymm le_top (le_infi $ take i, false.elim i)

@[simp]
lemma supr_false {s : false → α} : supr s = ⊥ :=
le_antisymm (supr_le $ take i, false.elim i) bot_le

@[simp]
lemma infi_true {s : true → α} : infi s = s trivial :=
le_antisymm (infi_le _ _) (le_infi $ take ⟨⟩, le_refl _)

@[simp]
lemma supr_true {s : true → α} : supr s = s trivial :=
le_antisymm (supr_le $ take ⟨⟩, le_refl _) (le_supr _ _)

@[simp]
lemma infi_exists {p : ι → Prop} {f : Exists p → α} : (⨅ x, f x) = (⨅ i, ⨅ h:p i, f ⟨i, h⟩) :=
le_antisymm
  (le_infi $ take i, le_infi $ suppose p i, infi_le _ _)
  (le_infi $ take ⟨i, h⟩, infi_le_of_le i $ infi_le _ _)

@[simp]
lemma supr_exists {p : ι → Prop} {f : Exists p → α} : (⨆ x, f x) = (⨆ i, ⨆ h:p i, f ⟨i, h⟩) :=
le_antisymm
  (supr_le $ take ⟨i, h⟩, le_supr_of_le i $ le_supr (λh:p i, f ⟨i, h⟩) _)
  (supr_le $ take i, supr_le $ suppose p i, le_supr _ _)

lemma infi_and {p q : Prop} {s : p ∧ q → α} : infi s = (⨅ h₁ : p, ⨅ h₂ : q, s ⟨h₁, h₂⟩) :=
le_antisymm
  (le_infi $ take i, le_infi $ take j, infi_le _ _)
  (le_infi $ take ⟨i, h⟩, infi_le_of_le i $ infi_le _ _)

lemma supr_and {p q : Prop} {s : p ∧ q → α} : supr s = (⨆ h₁ : p, ⨆ h₂ : q, s ⟨h₁, h₂⟩) :=
le_antisymm
  (supr_le $ take ⟨i, h⟩, le_supr_of_le i $ le_supr (λj, s ⟨i, j⟩) _)
  (supr_le $ take i, supr_le $ take j, le_supr _ _)

lemma infi_or {p q : Prop} {s : p ∨ q → α} :
  infi s = (⨅ h : p, s (or.inl h)) ⊓ (⨅ h : q, s (or.inr h)) :=
le_antisymm
  (le_inf
    (infi_le_infi2 $ take j, ⟨_, le_refl _⟩)
    (infi_le_infi2 $ take j, ⟨_, le_refl _⟩))
  (le_infi $ take i, match i with
  | or.inl i := inf_le_left_of_le $ infi_le _ _
  | or.inr j := inf_le_right_of_le $ infi_le _ _
  end)

lemma supr_or {p q : Prop} {s : p ∨ q → α} :
  (⨆ x, s x) = (⨆ i, s (or.inl i)) ⊔ (⨆ j, s (or.inr j)) :=
le_antisymm
  (supr_le $ take s, match s with
  | or.inl i := le_sup_left_of_le $ le_supr _ i
  | or.inr j := le_sup_right_of_le $ le_supr _ j
  end)
  (sup_le
    (supr_le_supr2 $ take i, ⟨or.inl i, le_refl _⟩)
    (supr_le_supr2 $ take j, ⟨or.inr j, le_refl _⟩))

lemma Inf_eq_infi {s : set α} : Inf s = (⨅a ∈ s, a) :=
le_antisymm
  (le_infi $ take b, le_infi $ take h, Inf_le h)
  (le_Inf $ take b h, infi_le_of_le b $ infi_le _ h)

lemma Sup_eq_supr {s : set α} : Sup s = (⨆a ∈ s, a) :=
le_antisymm
  (Sup_le $ take b h, le_supr_of_le b $ le_supr _ h)
  (supr_le $ take b, supr_le $ take h, le_Sup h)

lemma Inf_image {s : set β} {f : β → α} : Inf (set.image f s) = (⨅ a ∈ s, f a) :=
calc Inf (set.image f s) = (⨅a, ⨅h : ∃b, b ∈ s ∧ f b = a, a) : Inf_eq_infi
                     ... = (⨅a, ⨅b, ⨅h : f b = a ∧ b ∈ s, a) : by simp
                     ... = (⨅a, ⨅b, ⨅h : a = f b, ⨅h : b ∈ s, a) : by simp [infi_and, eq_comm]
                     ... = (⨅b, ⨅a, ⨅h : a = f b, ⨅h : b ∈ s, a) : by rw [infi_comm]
                     ... = (⨅a∈s, f a) : congr_arg infi $ funext $ take x, by rw [infi_infi_eq_left]
 
lemma Sup_image {s : set β} {f : β → α} : Sup (set.image f s) = (⨆ a ∈ s, f a) :=
calc Sup (set.image f s) = (⨆a, ⨆h : ∃b, b ∈ s ∧ f b = a, a) : Sup_eq_supr
                     ... = (⨆a, ⨆b, ⨆h : f b = a ∧ b ∈ s, a) : by simp
                     ... = (⨆a, ⨆b, ⨆h : a = f b, ⨆h : b ∈ s, a) : by simp [supr_and, eq_comm]
                     ... = (⨆b, ⨆a, ⨆h : a = f b, ⨆h : b ∈ s, a) : by rw [supr_comm]
                     ... = (⨆a∈s, f a) : congr_arg supr $ funext $ take x, by rw [supr_supr_eq_left]

/- supr and infi under set constructions -/

/- should work using the simplifier! -/
@[simp]
lemma infi_emptyset {f : β → α} : (⨅ x ∈ (∅ : set β), f x) = ⊤ :=
le_antisymm le_top (le_infi $ take x, le_infi false.elim)

@[simp]
lemma supr_emptyset {f : β → α} : (⨆ x ∈ (∅ : set β), f x) = ⊥ :=
le_antisymm (supr_le $ take x, supr_le false.elim) bot_le

@[simp]
lemma infi_univ {f : β → α} : (⨅ x ∈ (univ : set β), f x) = (⨅ x, f x) :=
show (⨅ (x : β) (H : true), f x) = ⨅ (x : β), f x,
  from congr_arg infi $ funext $ take x, infi_const ⟨⟩

@[simp]
lemma supr_univ {f : β → α} : (⨆ x ∈ (univ : set β), f x) = (⨆ x, f x) :=
show (⨆ (x : β) (H : true), f x) = ⨆ (x : β), f x,
  from congr_arg supr $ funext $ take x, supr_const ⟨⟩

@[simp]
lemma infi_union {f : β → α} {s t : set β} : (⨅ x ∈ s ∪ t, f x) = (⨅x∈s, f x) ⊓ (⨅x∈t, f x) :=
calc (⨅ x ∈ s ∪ t, f x) = (⨅ x, (⨅h : x∈s, f x) ⊓ (⨅h : x∈t, f x)) : congr_arg infi $ funext $ take x, infi_or
                    ... = (⨅x∈s, f x) ⊓ (⨅x∈t, f x) : infi_inf_eq

@[simp]
lemma supr_union {f : β → α} {s t : set β} : (⨆ x ∈ s ∪ t, f x) = (⨆x∈s, f x) ⊔ (⨆x∈t, f x) :=
calc (⨆ x ∈ s ∪ t, f x) = (⨆ x, (⨆h : x∈s, f x) ⊔ (⨆h : x∈t, f x)) : congr_arg supr $ funext $ take x, supr_or
                    ... = (⨆x∈s, f x) ⊔ (⨆x∈t, f x) : supr_sup_eq

@[simp] theorem insert_of_has_insert (x : α) (a : set α) : has_insert.insert x a = insert x a := rfl

@[simp]
lemma infi_insert {f : β → α} {s : set β} {b : β} : (⨅ x ∈ insert b s, f x) = f b ⊓ (⨅x∈s, f x) :=
eq.trans infi_union $ congr_arg (λx:α, x ⊓ (⨅x∈s, f x)) infi_infi_eq_left

@[simp]
lemma supr_insert {f : β → α} {s : set β} {b : β} : (⨆ x ∈ insert b s, f x) = f b ⊔ (⨆x∈s, f x) :=
eq.trans supr_union $ congr_arg (λx:α, x ⊔ (⨆x∈s, f x)) supr_supr_eq_left

@[simp]
lemma infi_singleton {f : β → α} {b : β} : (⨅ x ∈ (singleton b : set β), f x) = f b :=
show (⨅ x ∈ insert b (∅ : set β), f x) = f b,
  begin simp, rw [infi_const], simp, assumption end /- TODO: what to do with infi_const? -/

@[simp]
lemma supr_singleton {f : β → α} {b : β} : (⨆ x ∈ (singleton b : set β), f x) = f b :=
show (⨆ x ∈ insert b (∅ : set β), f x) = f b,
  begin simp, rw [supr_const], simp, assumption end /- TODO: what to do with supr_const? -/

/- supr and infi under Type -/

@[simp]
lemma infi_empty {s : empty → α} : infi s = ⊤ :=
le_antisymm le_top (le_infi $ take i, empty.rec_on _ i)

@[simp]
lemma supr_empty {s : empty → α} : supr s = ⊥ :=
le_antisymm (supr_le $ take i, empty.rec_on _ i) bot_le

@[simp]
lemma infi_unit {f : unit → α} : (⨅ x, f x) = f () :=
le_antisymm (infi_le _ _) (le_infi $ take ⟨⟩, le_refl _)

@[simp]
lemma supr_unit {f : unit → α} : (⨆ x, f x) = f () :=
le_antisymm (supr_le $ take ⟨⟩, le_refl _) (le_supr _ _)

lemma infi_subtype {p : ι → Prop} {f : subtype p → α} : (⨅ x, f x) = (⨅ i, ⨅ h:p i, f ⟨i, h⟩) :=
le_antisymm
  (le_infi $ take i, le_infi $ suppose p i, infi_le _ _)
  (le_infi $ take ⟨i, h⟩, infi_le_of_le i $ infi_le _ _)

lemma supr_subtype {p : ι → Prop} {f : subtype p → α} : (⨆ x, f x) = (⨆ i, ⨆ h:p i, f ⟨i, h⟩) :=
le_antisymm
  (supr_le $ take ⟨i, h⟩, le_supr_of_le i $ le_supr (λh:p i, f ⟨i, h⟩) _)
  (supr_le $ take i, supr_le $ suppose p i, le_supr _ _)

lemma infi_sigma {p : β → Type w} {f : sigma p → α} : (⨅ x, f x) = (⨅ i, ⨅ h:p i, f ⟨i, h⟩) :=
le_antisymm
  (le_infi $ take i, le_infi $ suppose p i, infi_le _ _)
  (le_infi $ take ⟨i, h⟩, infi_le_of_le i $ infi_le _ _)

lemma supr_sigma {p : β → Type w} {f : sigma p → α} : (⨆ x, f x) = (⨆ i, ⨆ h:p i, f ⟨i, h⟩) :=
le_antisymm
  (supr_le $ take ⟨i, h⟩, le_supr_of_le i $ le_supr (λh:p i, f ⟨i, h⟩) _)
  (supr_le $ take i, supr_le $ suppose p i, le_supr _ _)

lemma infi_prod {γ : Type w} {f : β × γ → α} : (⨅ x, f x) = (⨅ i, ⨅ j, f (i, j)) :=
le_antisymm
  (le_infi $ take i, le_infi $ take j, infi_le _ _)
  (le_infi $ take ⟨i, h⟩, infi_le_of_le i $ infi_le _ _)

lemma supr_prod {γ : Type w} {f : β × γ → α} : (⨆ x, f x) = (⨆ i, ⨆ j, f (i, j)) :=
le_antisymm
  (supr_le $ take ⟨i, h⟩, le_supr_of_le i $ le_supr (λj, f ⟨i, j⟩) _)
  (supr_le $ take i, supr_le $ take j, le_supr _ _)

lemma infi_sum {γ : Type w} {f : β ⊕ γ → α} :
  (⨅ x, f x) = (⨅ i, f (sum.inl i)) ⊓ (⨅ j, f (sum.inr j)) :=
le_antisymm
  (le_inf
    (infi_le_infi2 $ take i, ⟨_, le_refl _⟩)
    (infi_le_infi2 $ take j, ⟨_, le_refl _⟩))
  (le_infi $ take s, match s with
  | sum.inl i := inf_le_left_of_le $ infi_le _ _
  | sum.inr j := inf_le_right_of_le $ infi_le _ _
  end)

lemma supr_sum {γ : Type w} {f : β ⊕ γ → α} :
  (⨆ x, f x) = (⨆ i, f (sum.inl i)) ⊔ (⨆ j, f (sum.inr j)) :=
le_antisymm
  (supr_le $ take s, match s with
  | sum.inl i := le_sup_left_of_le $ le_supr _ i
  | sum.inr j := le_sup_right_of_le $ le_supr _ j
  end)
  (sup_le
    (supr_le_supr2 $ take i, ⟨sum.inl i, le_refl _⟩)
    (supr_le_supr2 $ take j, ⟨sum.inr j, le_refl _⟩))

end

/- Instances -/

instance complete_lattice_Prop : complete_lattice Prop :=
{ lattice.bounded_lattice_Prop with
  Sup    := λs, ∃a∈s, a,
  le_Sup := take s a h p, ⟨a, h, p⟩,
  Sup_le := take s a h ⟨b, h', p⟩, h b h' p,
  Inf    := λs, ∀a:Prop, a∈s → a,
  Inf_le := take s a h p, p a h,
  le_Inf := take s a h p b hb, h b hb p }

instance complete_lattice_fun {α : Type u} {β : Type v} [complete_lattice β] :
  complete_lattice (α → β) :=
{ lattice.bounded_lattice_fun with
  Sup    := λs a, Sup (set.image (λf : α → β, f a) s),
  le_Sup := take s f h a, le_Sup ⟨f, h, rfl⟩,
  Sup_le := take s f h a, Sup_le $ take b ⟨f', h', b_eq⟩, b_eq ▸ h _ h' a,
  Inf    := λs a, Inf (set.image (λf : α → β, f a) s),
  Inf_le := take s f h a, Inf_le ⟨f, h, rfl⟩,
  le_Inf := take s f h a, le_Inf $ take b ⟨f', h', b_eq⟩, b_eq ▸ h _ h' a }

section complete_lattice
variables [weak_order α] [complete_lattice β]

lemma monotone_Sup_of_monotone {s : set (α → β)} (m_s : ∀f∈s, monotone f) : monotone (Sup s) :=
take x y h, Sup_le $ take x' ⟨f, f_in, fx_eq⟩, le_Sup_of_le ⟨f, f_in, rfl⟩ $ fx_eq ▸ m_s _ f_in h

lemma monotone_Inf_of_monotone {s : set (α → β)} (m_s : ∀f∈s, monotone f) : monotone (Inf s) :=
take x y h, le_Inf $ take x' ⟨f, f_in, fx_eq⟩, Inf_le_of_le ⟨f, f_in, rfl⟩ $ fx_eq ▸ m_s _ f_in h

end complete_lattice

end lattice


/- Classical statements:

@[simp]
lemma Inf_eq_top : Inf s = ⊤ ↔ (∀a∈s, a = ⊤) :=
_

@[simp]
lemma infi_eq_top : infi s = ⊤ ↔ (∀i, s i = ⊤) :=
_

@[simp]
lemma Sup_eq_bot : Sup s = ⊤ ↔ (∀a∈s, a = ⊥) :=
_

@[simp]
lemma supr_eq_top : supr s = ⊤ ↔ (∀i, s i = ⊥) :=
_


-/
