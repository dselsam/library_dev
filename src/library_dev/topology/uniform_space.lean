/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl

Theory of uniform spaces.
-/
import algebra.lattice.filter .topological_space .continuity
open set lattice filter

set_option eqn_compiler.zeta true

attribute [trans] subset.trans

universes u v w x y

section
variables {α : Type u} {β : Type v} {γ : Type w} {δ : Type x} {ι : Sort y}

def id_rel {α : Type u} := {p : α × α | p.1 = p.2}

def comp_rel {α : Type u} (r₁ r₂ : set (α×α)) :=
{p : α × α | ∃z:α, (p.1, z) ∈ r₁ ∧ (z, p.2) ∈ r₂}

@[simp] lemma swap_id_rel : prod.swap '' id_rel = @id_rel α :=
set.ext $ take ⟨a, b⟩, by simp [image_swap_eq_vimage_swap]; exact eq_comm

lemma monotone_comp_rel [weak_order β] {f g : β → set (α×α)}
  (hf : monotone f) (hg : monotone g) : monotone (λx, comp_rel (f x) (g x)) :=
take a b h p ⟨z, h₁, h₂⟩, ⟨z, hf h h₁, hg h h₂⟩

lemma prod_mk_mem_comp_rel {a b c : α} {s t : set (α×α)} (h₁ : (a, c) ∈ s) (h₂ : (c, b) ∈ t) :
  (a, b) ∈ comp_rel s t :=
⟨c, h₁, h₂⟩

@[simp] lemma id_comp_rel {r : set (α×α)} : comp_rel id_rel r = r :=
set.ext $ take ⟨a, b⟩, ⟨take ⟨a', (heq : a = a'), ha'⟩, heq.symm ▸ ha', take ha, ⟨a, rfl, ha⟩⟩

/- uniformity -/

class uniform_space (α : Type u) :=
(uniformity : filter (α × α))
(refl       : principal id_rel ≤ uniformity)
(symm       : prod.swap <$> uniformity ≤ uniformity)
(comp       : uniformity^.lift' (λs, comp_rel s s) ≤ uniformity)

lemma uniform_space_eq {u₁ u₂ : uniform_space α} (h : u₁.uniformity = u₂.uniformity) : u₁ = u₂ :=
begin
  cases u₁ with a, cases u₂ with b,
  assert h' : a = b, assumption,
  clear h,
  subst h'
end

section uniform_space
variables [uniform_space α]

def uniformity : filter (α × α) := uniform_space.uniformity α

lemma refl_le_uniformity : principal id_rel ≤ @uniformity α _ :=
uniform_space.refl α

lemma refl_mem_uniformity {x : α} {s : set (α × α)} (h : s ∈ (@uniformity α _).sets) :
  (x, x) ∈ s :=
refl_le_uniformity h rfl

lemma symm_le_uniformity : map (@prod.swap α α) uniformity ≤ uniformity :=
uniform_space.symm α

lemma comp_le_uniformity :
  uniformity^.lift' (λs:set (α×α), comp_rel s s) ≤ uniformity :=
uniform_space.comp α

lemma comp_mem_uniformity_sets {s : set (α × α)} (hs : s ∈ (@uniformity α _).sets) :
  ∃t∈(@uniformity α _).sets, comp_rel t t ⊆ s :=
have s ∈ (uniformity^.lift' (λt:set (α×α), comp_rel t t)).sets,
  from comp_le_uniformity hs,
(mem_lift'_iff $ monotone_comp_rel monotone_id monotone_id).mp this

lemma symm_of_uniformity {s : set (α × α)} (hs : s ∈ (@uniformity α _).sets) :
  ∃t∈(@uniformity α _).sets, (∀a b, (a, b) ∈ t → (b, a) ∈ t) ∧ t ⊆ s :=
have vimage prod.swap s ∈ (@uniformity α _).sets, from symm_le_uniformity hs,
⟨s ∩ vimage prod.swap s, inter_mem_sets hs this, take a b ⟨h₁, h₂⟩, ⟨h₂, h₁⟩, inter_subset_left _ _⟩

lemma comp_symm_of_uniformity {s : set (α × α)} (hs : s ∈ (@uniformity α _).sets) :
  ∃t∈(@uniformity α _).sets, (∀{a b}, (a, b) ∈ t → (b, a) ∈ t) ∧ comp_rel t t ⊆ s :=
let ⟨t, ht₁, ht₂⟩ := comp_mem_uniformity_sets hs in
let ⟨t', ht', ht'₁, ht'₂⟩ := symm_of_uniformity ht₁ in
⟨t', ht', ht'₁, subset.trans (monotone_comp_rel monotone_id monotone_id ht'₂) ht₂⟩

lemma uniformity_le_symm : uniformity ≤ map (@prod.swap α α) uniformity :=
calc uniformity = id <$> uniformity : (functor.id_map _)^.symm
  ... = (prod.swap.{u u} ∘ prod.swap) <$> uniformity :
    congr_arg (λf : (α×α)→(α×α), f <$> uniformity) (by apply funext; intro x; cases x; refl)
  ... = (map prod.swap ∘ map prod.swap) uniformity :
    congr map_compose rfl
  ... ≤ prod.swap.{u u} <$> uniformity : map_mono symm_le_uniformity

lemma uniformity_eq_symm : uniformity = (@prod.swap α α) <$> uniformity :=
le_antisymm uniformity_le_symm symm_le_uniformity

lemma uniformity_lift_le_swap {g : set (α×α) → filter β} {f : filter β} (hg : monotone g)
  (h : uniformity^.lift (λs, g (vimage prod.swap s)) ≤ f) : uniformity^.lift g ≤ f :=
le_trans
  (lift_mono uniformity_le_symm (le_refl _))
  (by rw [map_lift_eq2 hg, image_swap_eq_vimage_swap]; exact h)

lemma uniformity_lift_le_comp {f : set (α×α) → filter β} (h : monotone f):
  uniformity.lift (λs, f (comp_rel s s)) ≤ uniformity.lift f :=
calc uniformity.lift (λs, f (comp_rel s s)) =
    (uniformity.lift' (λs:set (α×α), comp_rel s s))^.lift f :
  begin
    rw [lift_lift'_assoc],
    exact monotone_comp_rel monotone_id monotone_id,
    exact h
  end
  ... ≤ uniformity.lift f : lift_mono comp_le_uniformity (le_refl _)

lemma comp_le_uniformity3 :
  uniformity^.lift' (λs:set (α×α), comp_rel s (comp_rel s s)) ≤ uniformity :=
calc uniformity.lift' (λd, comp_rel d (comp_rel d d)) =
  uniformity.lift (λs, uniformity.lift' (λt:set(α×α), comp_rel s (comp_rel t t))) :
  begin
    rw [lift_lift'_same_eq_lift'],
    exact (take x, monotone_comp_rel monotone_const $ monotone_comp_rel monotone_id monotone_id),
    exact (take x, monotone_comp_rel monotone_id monotone_const),
  end
  ... ≤ uniformity.lift (λs, uniformity.lift' (λt:set(α×α), comp_rel s t)) :
    lift_mono' $ take s hs, @uniformity_lift_le_comp α _ _ (principal ∘ comp_rel s) $
      monotone_comp (monotone_comp_rel monotone_const monotone_id) monotone_principal
  ... = uniformity.lift' (λs:set(α×α), comp_rel s s) :
    lift_lift'_same_eq_lift'
      (take s, monotone_comp_rel monotone_const monotone_id)
      (take s, monotone_comp_rel monotone_id monotone_const)
  ... ≤ uniformity : comp_le_uniformity

instance uniform_space.to_topological_space : topological_space α :=
{ open'       := λs, ∀x∈s, { p : α × α | p.1 = x → p.2 ∈ s } ∈ (uniformity.sets : set (set (α×α))),
  open_univ   := by simp; intros; apply univ_mem_sets,
  open_inter  := take s t hs ht x ⟨xs, xt⟩,
    uniformity.upwards_sets (inter_mem_sets (hs x xs) (ht x xt)) $
      take p ⟨ps, pt⟩ h, ⟨ps h, pt h⟩,
  open_sUnion := take s hs x ⟨t, ts, xt⟩,
    uniformity.upwards_sets (hs t ts x xt) $
      take p ph h, ⟨t, ts, ph h⟩ }

lemma mem_nhds_uniformity_iff {x : α} {s : set α} :
  (s ∈ (nhds x).sets) ↔ ({p : α × α | p.1 = x → p.2 ∈ s} ∈ (@uniformity α _).sets) :=
⟨ begin
    simp [mem_nhds_sets_iff],
    exact take ⟨t, ht, ts, xt⟩, uniformity.upwards_sets (ht x xt) $
      take ⟨x', y⟩ h eq, ts $ h eq
  end,

  take hs,
  mem_nhds_sets_iff.mpr $ ⟨{x | {p : α × α | p.1 = x → p.2 ∈ s} ∈ (@uniformity α _).sets},
    take x', assume hx' : {p : α × α | p.fst = x' → p.snd ∈ s} ∈ (@uniformity α _).sets,
      refl_mem_uniformity hx' rfl,
    take x' hx',
      let ⟨t, ht, tr⟩ := comp_mem_uniformity_sets hx' in
      uniformity.upwards_sets ht $
      take ⟨a, b⟩ hp' (eq : a = x'),
      have hp : (x', b) ∈ t, from eq ▸ hp',
      show {p : α × α | p.fst = b → p.snd ∈ s} ∈ (@uniformity α _).sets,
        from uniformity.upwards_sets ht $
          take ⟨a, b'⟩ hp' (heq : a = b),
          have (b, b') ∈ t, from heq ▸ hp',
          have (x', b') ∈ comp_rel t t, from ⟨b, hp, this⟩,
          show b' ∈ s,
            from tr this rfl,
    hs⟩⟩

lemma nhds_eq_uniformity {x : α} :
  nhds x = uniformity^.lift' (λs:set (α×α), {y | (x, y) ∈ s}) :=
filter_eq $ set.ext $ take s,
  begin
    rw [mem_lift'_iff], tactic.swap, apply monotone_vimage,
    simp [mem_nhds_uniformity_iff],
    exact ⟨take h, ⟨_, h, take y h, h rfl⟩,
      take ⟨t, h₁, h₂⟩,
      uniformity.upwards_sets h₁ $
      take ⟨x', y⟩ hp (eq : x' = x), h₂ $
      show (x, y) ∈ t, from eq ▸ hp⟩
  end

lemma mem_nhds_left {x : α} {s : set (α×α)} (h : s ∈ (uniformity.sets : set (set (α×α)))) :
  {y : α | (x, y) ∈ s} ∈ (nhds x)^.sets :=
have nhds x ≤ principal {y : α | (x, y) ∈ s},
  by rw [nhds_eq_uniformity]; exact infi_le_of_le s (infi_le _ h),
by simp at this; assumption

lemma mem_nhds_right {y : α} {s : set (α×α)} (h : s ∈ (uniformity.sets : set (set (α×α)))) :
  {x : α | (x, y) ∈ s} ∈ (nhds y)^.sets :=
mem_nhds_left (symm_le_uniformity h)

lemma lift_nhds_left {x : α} {g : set α → filter β} (hg : monotone g) :
  (nhds x)^.lift g = uniformity^.lift (λs:set (α×α), g {y | (x, y) ∈ s}) :=
eq.trans
  begin
    rw [nhds_eq_uniformity],
    exact (filter.lift_assoc $ monotone_comp monotone_vimage $ monotone_comp monotone_vimage monotone_principal)
  end
  (congr_arg _ $ funext $ take s, filter.lift_principal hg)

lemma lift_nhds_right {x : α} {g : set α → filter β} (hg : monotone g) :
  (nhds x)^.lift g = uniformity^.lift (λs:set (α×α), g {y | (y, x) ∈ s}) :=
calc (nhds x)^.lift g = uniformity^.lift (λs:set (α×α), g {y | (x, y) ∈ s}) : lift_nhds_left hg
  ... = ((@prod.swap α α) <$> uniformity)^.lift (λs:set (α×α), g {y | (x, y) ∈ s}) : by rw [-uniformity_eq_symm]
  ... = uniformity^.lift (λs:set (α×α), g {y | (x, y) ∈ image prod.swap s}) :
    map_lift_eq2 $ monotone_comp monotone_vimage hg
  ... = _ : by simp [image_swap_eq_vimage_swap]

lemma nhds_nhds_eq_uniformity_uniformity_prod {a b : α} :
  filter.prod (nhds a) (nhds b) =
  uniformity^.lift (λs:set (α×α), uniformity^.lift' (λt:set (α×α),
    set.prod {y : α | (y, a) ∈ s} {y : α | (b, y) ∈ t})) :=
show (nhds a)^.lift (λs:set α, (nhds b)^.lift (λt:set α, principal (set.prod s t))) = _,
begin
  rw [lift_nhds_right],
  apply congr_arg, apply funext, intro s,
  rw [lift_nhds_left],
  refl,
  exact monotone_comp (monotone_prod monotone_const monotone_id) monotone_principal,
  exact (monotone_lift' monotone_const $ monotone_lam $
    take x, monotone_prod monotone_id monotone_const)
end

lemma nhds_eq_uniformity_prod {a b : α} :
  nhds (a, b) =
  uniformity^.lift' (λs:set (α×α), set.prod {y : α | (y, a) ∈ s} {y : α | (b, y) ∈ s}) :=
begin
  rw [nhds_prod_eq, nhds_nhds_eq_uniformity_uniformity_prod, lift_lift'_same_eq_lift'],
  { intro s, exact monotone_prod monotone_const monotone_vimage },
  { intro t, exact monotone_prod monotone_vimage monotone_const }
end

lemma nhdset_of_mem_uniformity {d : set (α×α)} (s : set (α×α)) (hd : d ∈ (@uniformity α _).sets) :
  ∃(t : set (α×α)), open' t ∧ s ⊆ t ∧ t ⊆ {p | ∃x y, (p.1, x) ∈ d ∧ (x, y) ∈ s ∧ (y, p.2) ∈ d} :=
let cl_d := {p:α×α | ∃x y, (p.1, x) ∈ d ∧ (x, y) ∈ s ∧ (y, p.2) ∈ d} in
have ∀p ∈ s, ∃t ⊆ cl_d, open' t ∧ p ∈ t, from
  take ⟨x, y⟩ hp, mem_nhds_sets_iff.mp $
  show cl_d ∈ (nhds (x, y)).sets,
  begin
    rw [nhds_eq_uniformity_prod, mem_lift'_iff],
    exact ⟨d, hd, take ⟨a, b⟩ ⟨ha, hb⟩, ⟨x, y, ha, hp, hb⟩⟩,
    exact monotone_prod monotone_vimage monotone_vimage
  end,
have ∃t:(Π(p:α×α) (h:p ∈ s), set (α×α)),
    ∀p, ∀h:p ∈ s, t p h ⊆ cl_d ∧ open' (t p h) ∧ p ∈ t p h,
  by simp [classical.skolem] at this; simp; assumption,
match this with
| ⟨t, ht⟩ :=
  ⟨(⋃ p:α×α, ⋃ h : p ∈ s, t p h : set (α×α)),
    open_Union $ take (p:α×α), open_Union $ take hp, (ht p hp).right.left,
    take ⟨a, b⟩ hp, begin simp; exact ⟨a, b, hp, (ht (a,b) hp).right.right⟩ end,
    Union_subset $ take p, Union_subset $ take hp, (ht p hp).left⟩
end

lemma closure_eq_inter_uniformity {t : set (α×α)} :
  closure t = (⋂ d∈(@uniformity α _).sets, comp_rel d (comp_rel t d)) :=
set.ext $ take ⟨a, b⟩,
calc (a, b) ∈ closure t ↔ (nhds (a, b) ⊓ principal t ≠ ⊥) : by simp [closure_eq_nhds]
  ... ↔ (((@prod.swap α α) <$> uniformity).lift'
      (λ (s : set (α × α)), set.prod {x : α | (x, a) ∈ s} {y : α | (b, y) ∈ s}) ⊓ principal t ≠ ⊥) :
    by rw [-uniformity_eq_symm, nhds_eq_uniformity_prod]
  ... ↔ ((map (@prod.swap α α) uniformity).lift'
      (λ (s : set (α × α)), set.prod {x : α | (x, a) ∈ s} {y : α | (b, y) ∈ s}) ⊓ principal t ≠ ⊥) :
    by refl
  ... ↔ (uniformity.lift'
      (λ (s : set (α × α)), set.prod {y : α | (a, y) ∈ s} {x : α | (x, b) ∈ s}) ⊓ principal t ≠ ⊥) :
  begin
    rw [map_lift'_eq2],
    simp [image_swap_eq_vimage_swap, function.comp],
    exact monotone_prod monotone_vimage monotone_vimage
  end
  ... ↔ (∀s∈(@uniformity α _).sets, ∃x, x ∈ set.prod {y : α | (a, y) ∈ s} {x : α | (x, b) ∈ s} ∩ t) :
  begin
    rw [lift'_inf_principal_eq, lift'_neq_bot_iff],
    apply forall_congr, intro s, rw [ne_empty_iff_exists_mem],
    exact monotone_inter (monotone_prod monotone_vimage monotone_vimage) monotone_const
  end
  ... ↔ (∀s∈(@uniformity α _).sets, (a, b) ∈ comp_rel s (comp_rel t s)) :
    forall_congr $ take s, forall_congr $ take hs,
    ⟨take ⟨⟨x, y⟩, ⟨⟨hx, hy⟩, hxyt⟩⟩, ⟨x, hx, y, hxyt, hy⟩,
      take ⟨x, hx, y, hxyt, hy⟩, ⟨⟨x, y⟩, ⟨⟨hx, hy⟩, hxyt⟩⟩⟩
  ... ↔ _ : by simp

lemma uniformity_eq_uniformity_closure : (@uniformity α _) = uniformity.lift' closure :=
le_antisymm
  (le_infi $ take s, le_infi $ take hs, by simp; exact uniformity.upwards_sets hs subset_closure)
  (calc uniformity.lift' closure ≤ uniformity.lift' (λd, comp_rel d (comp_rel d d)) :
      lift'_mono' (by intros s hs; rw [closure_eq_inter_uniformity]; exact bInter_subset_of_mem hs)
    ... ≤ uniformity : comp_le_uniformity3)

lemma uniformity_eq_uniformity_interior : (@uniformity α _) = uniformity.lift' interior :=
le_antisymm
  (le_infi $ take d, le_infi $ take hd,
    let ⟨s, hs, hs_comp⟩ := (mem_lift'_iff $
      monotone_comp_rel monotone_id $ monotone_comp_rel monotone_id monotone_id).mp (comp_le_uniformity3 hd) in
    let ⟨t, ht, hst, ht_comp⟩ := nhdset_of_mem_uniformity s hs in
    have s ⊆ interior d, from
      calc s ⊆ t : hst
       ... ⊆ interior d : (subset_interior_iff_subset_of_open ht).mpr $
        take x, suppose x ∈ t, let ⟨x, y, h₁, h₂, h₃⟩ := ht_comp this in hs_comp ⟨x, h₁, y, h₂, h₃⟩,
    have interior d ∈ (@uniformity α _).sets,
      from (@uniformity α _).upwards_sets hs $ this,
    by simp [this])
  (take s hs, (uniformity.lift' interior).upwards_sets (mem_lift' hs) interior_subset)

lemma interior_mem_uniformity {s : set (α × α)} (hs : s ∈ (@uniformity α _).sets) :
  interior s ∈ (@uniformity α _).sets :=
by rw [uniformity_eq_uniformity_interior]; exact mem_lift' hs

/- uniform continuity -/

definition uniform_continuous [uniform_space β] (f : α → β) :=
filter.map (λx:α×α, (f x.1, f x.2)) uniformity ≤ uniformity

definition uniform_embedding [uniform_space β] (f : α → β) :=
(∀a₁ a₂, f a₁ = f a₂ → a₁ = a₂) ∧
vmap (λx:α×α, (f x.1, f x.2)) uniformity = uniformity

lemma uniform_continuous_of_embedding [uniform_space β] {f : α → β}
  (hf : uniform_embedding f) : uniform_continuous f :=
by simp [uniform_continuous, hf.right.symm]; exact take s hs, ⟨s, hs, subset.refl _⟩

lemma continuous_of_uniform [uniform_space β] {f : α → β}
  (hf : uniform_continuous f) : continuous f :=
continuous_iff_towards.mpr $ take a,
calc map f (nhds a) ≤
    (map (λp:α×α, (f p.1, f p.2)) uniformity).lift' (λs:set (β×β), {y | (f a, y) ∈ s}) :
  begin
    rw [nhds_eq_uniformity, map_lift'_eq, map_lift'_eq2],
    exact (lift'_mono' $ take s hs b ⟨a', (ha' : (_, a') ∈ s), a'_eq⟩,
      ⟨(a, a'), ha', show (f a, f a') = (f a, b), from a'_eq ▸ rfl⟩),
    exact monotone_vimage,
    exact monotone_vimage
  end
  ... ≤ nhds (f a) :
    by rw [nhds_eq_uniformity]; exact lift'_mono hf (le_refl _)

/- cauchy filters -/
definition cauchy (f : filter α) := f ≠ ⊥ ∧ filter.prod f f ≤ uniformity

lemma cauchy_downwards {f g : filter α} (h_c : cauchy f) (hg : g ≠ ⊥) (h_le : g ≤ f) : cauchy g :=
⟨hg, le_trans (filter.prod_mono h_le h_le) h_c.right⟩

lemma cauchy_nhds {a : α} : cauchy (nhds a) :=
⟨nhds_neq_bot,
  calc filter.prod (nhds a) (nhds a) =
    uniformity^.lift (λs:set (α×α), uniformity^.lift' (λt:set(α×α),
      set.prod {y : α | (y, a) ∈ s} {y : α | (a, y) ∈ t})) : nhds_nhds_eq_uniformity_uniformity_prod
    ... ≤ uniformity^.lift' (λs:set (α×α), comp_rel s s) :
      le_infi $ take s, le_infi $ take hs,
      infi_le_of_le s $ infi_le_of_le hs $ infi_le_of_le s $ infi_le_of_le hs $
      principal_mono.mpr $
      take ⟨x, y⟩ ⟨(hx : (x, a) ∈ s), (hy : (a, y) ∈ s)⟩, ⟨a, hx, hy⟩
    ... ≤ uniformity : comp_le_uniformity⟩

lemma cauchy_pure {a : α} : cauchy (pure a) :=
cauchy_downwards cauchy_nhds
  (show principal {a} ≠ ⊥, by simp)
  (return_le_nhds a)

lemma le_nhds_of_cauchy_adhp {f : filter α} {x : α} (hf : cauchy f)
  (adhs : f ⊓ nhds x ≠ ⊥) : f ≤ nhds x :=
have ∀s∈f.sets, x ∈ closure s,
begin
  intros s hs,
  simp [closure_eq_nhds, inf_comm],
  exact take h', adhs $ bot_unique $ h' ▸ inf_le_inf (by simp; exact hs) (le_refl _)
end,
calc f ≤ f.lift' (λs:set α, {y | x ∈ closure s ∧ y ∈ closure s}) :
    le_infi $ take s, le_infi $ take hs,
    begin
      rw [-forall_sets_neq_empty_iff_neq_bot] at adhs,
      simp [this s hs],
      exact f.upwards_sets hs subset_closure
    end
  ... ≤ f.lift' (λs:set α, {y | (x, y) ∈ closure (set.prod s s)}) :
    by simp [closure_prod_eq]; exact le_refl _
  ... = (filter.prod f f).lift' (λs:set (α×α), {y | (x, y) ∈ closure s}) :
  begin
    rw [prod_same_eq],
    rw [lift'_lift'_assoc],
    exact monotone_prod monotone_id monotone_id,
    exact monotone_comp (take s t h x h', closure_mono h h') monotone_vimage
  end
  ... ≤ uniformity.lift' (λs:set (α×α), {y | (x, y) ∈ closure s}) : lift'_mono hf.right (le_refl _)
  ... = (uniformity.lift' closure).lift' (λs:set (α×α), {y | (x, y) ∈ s}) :
  begin
    rw [lift'_lift'_assoc],
    exact take s t h, closure_mono h,
    exact monotone_vimage
  end
  ... = uniformity.lift' (λs:set (α×α), {y | (x, y) ∈ s}) :
    by rw [-uniformity_eq_uniformity_closure]
  ... = nhds x :
    by rw [nhds_eq_uniformity]

lemma le_nhds_iff_adhp_of_cauchy {f : filter α} {x : α} (hf : cauchy f) :
  f ≤ nhds x ↔ f ⊓ nhds x ≠ ⊥ :=
⟨take h, (inf_of_le_left h).symm ▸ hf.left,
  le_nhds_of_cauchy_adhp hf⟩

lemma cauchy_map [uniform_space β] {f : filter α} {m : α → β}
  (hm : uniform_continuous m) (hf : cauchy f) : cauchy (map m f) :=
⟨have f ≠ ⊥, from hf.left, by simp; assumption,
  calc filter.prod (map m f) (map m f) =
          map (λp:α×α, (m p.1, m p.2)) (filter.prod f f) : filter.prod_map_map_eq
    ... ≤ map (λp:α×α, (m p.1, m p.2)) uniformity : map_mono hf.right
    ... ≤ uniformity : hm⟩

lemma cauchy_vmap [uniform_space β] {f : filter β} {m : α → β}
  (hm : vmap (λp:α×α, (m p.1, m p.2)) uniformity ≤ uniformity)
  (hf : cauchy f) (hb : vmap m f ≠ ⊥) : cauchy (vmap m f) :=
⟨hb,
  calc filter.prod (vmap m f) (vmap m f) =
          vmap (λp:α×α, (m p.1, m p.2)) (filter.prod f f) : filter.prod_vmap_vmap_eq
    ... ≤ vmap (λp:α×α, (m p.1, m p.2)) uniformity : vmap_mono hf.right
    ... ≤ uniformity : hm⟩

/- separated uniformity -/

protected def separation_rel (α : Type u) [uniform_space α] :=
(⋂₀ (@uniformity α _).sets)

lemma separated_equiv : equivalence (λx y, (x, y) ∈ separation_rel α) :=
⟨take x, take s, refl_mem_uniformity,
  take x y, take h (s : set (α×α)) hs,
    have vimage prod.swap s ∈ (@uniformity α _).sets,
      from symm_le_uniformity hs,
    h _ this,
  take x y z (hxy : (x, y) ∈ separation_rel α) (hyz : (y, z) ∈ separation_rel α)
      s (hs : s ∈ (@uniformity α _).sets),
    let ⟨t, ht, (h_ts : comp_rel t t ⊆ s)⟩ := comp_mem_uniformity_sets hs in
    h_ts $ show (x, z) ∈ comp_rel t t,
      from ⟨y, hxy t ht, hyz t ht⟩⟩

protected def separation_setoid (α : Type u) [uniform_space α] : setoid α :=
⟨λx y, (x, y) ∈ separation_rel α, separated_equiv⟩

@[class]
definition separated (α : Type u) [uniform_space α] :=
separation_rel α = id_rel

instance separated_t2 [s : separated α] : t2_space α :=
⟨take x y, assume h : x ≠ y,
have separation_rel α = id_rel,
  from s,
have (x, y) ∉ separation_rel α,
  by simp [this]; exact h,
let ⟨d, hd, (hxy : (x, y) ∉ d)⟩ := classical.bexists_not_of_not_bforall this in
let ⟨d', hd', (hd'd' : comp_rel d' d' ⊆ d)⟩ := comp_mem_uniformity_sets hd in
have {y | (x, y) ∈ d'} ∈ (nhds x).sets,
  from mem_nhds_left hd',
let ⟨u, hu₁, hu₂, hu₃⟩ := mem_nhds_sets_iff.mp this in
have {x | (x, y) ∈ d'} ∈ (nhds y).sets,
  from mem_nhds_right hd',
let ⟨v, hv₁, hv₂, hv₃⟩ := mem_nhds_sets_iff.mp this in
have u ∩ v = ∅, from
  eq_empty_of_subset_empty $
  take z ⟨(h₁ : z ∈ u), (h₂ : z ∈ v)⟩,
  have (x, y) ∈ comp_rel d' d', from ⟨z, hu₁ h₁, hv₁ h₂⟩,
  hxy $ hd'd' this,
⟨u, v, hu₂, hv₂, hu₃, hv₃, this⟩⟩

/- totally bounded -/
def totally_bounded (s : set α) : Prop :=
∀d ∈ (@uniformity α _).sets, ∃t : set α, finite t ∧ s ⊆ (⋃y∈t, {x | (x,y) ∈ d})

lemma cauchy_of_totally_bounded_of_ultrafilter {s : set α} {f : filter α}
  (hs : totally_bounded s) (hf : ultrafilter f) (h : f ≤ principal s) : cauchy f :=
⟨hf.left, take t ht,
  let ⟨t', ht'₁, ht'_symm, ht'_t⟩ := comp_symm_of_uniformity ht in
  let ⟨i, hi, hs_union⟩ := hs t' ht'₁ in
  have (⋃y∈i, {x | (x,y) ∈ t'}) ∈ f.sets,
    from f.upwards_sets (le_principal_iff.mp h) hs_union,
  have ∃y∈i, {x | (x,y) ∈ t'} ∈ f.sets,
    from mem_of_finite_Union_ultrafilter hf hi this,
  let ⟨y, hy, hif⟩ := this in
  have set.prod {x | (x,y) ∈ t'} {x | (x,y) ∈ t'} ⊆ comp_rel t' t',
    from take ⟨x₁, x₂⟩ ⟨(h₁ : (x₁, y) ∈ t'), (h₂ : (x₂, y) ∈ t')⟩,
      ⟨y, h₁, ht'_symm h₂⟩,
  (filter.prod f f).upwards_sets (prod_mem_prod hif hif) (subset.trans this ht'_t)⟩

lemma totally_bounded_iff_filter {s : set α} :
  totally_bounded s ↔ (∀f, f ≠ ⊥ → f ≤ principal s → ∃c ≤ f, cauchy c) :=
⟨suppose totally_bounded s, take f hf hs,
  ⟨ultrafilter_of f, ultrafilter_of_le,
    cauchy_of_totally_bounded_of_ultrafilter this
      (ultrafilter_ultrafilter_of hf) (le_trans ultrafilter_of_le hs)⟩,

  assume h : ∀f, f ≠ ⊥ → f ≤ principal s → ∃c ≤ f, cauchy c, take d hd,
  classical.by_contradiction $ take hs,
  have hd_cover : ∀{t:set α}, finite t → ¬ s ⊆ (⋃y∈t, {x | (x,y) ∈ d}),
    by simp [not_exists_iff_forall_not, classical.not_and_iff, not_or_iff_implies] at hs;
       assumption,
  let
    f := ⨅t:{t : set α // finite t}, principal (s - (⋃y∈t.val, {x | (x,y) ∈ d})),
    ⟨a, ha⟩ := @exists_mem_of_ne_empty α s
      (take h, hd_cover finite.empty $ h.symm ▸ empty_subset _)
  in
  have f ≠ ⊥,
    from infi_neq_bot_of_directed ⟨a⟩
      (take ⟨t₁, ht₁⟩ ⟨t₂, ht₂⟩, ⟨⟨t₁ ∪ t₂, finite_union ht₁ ht₂⟩,
        principal_mono.mpr $ diff_right_antimono $ Union_subset_Union $
          take t, Union_subset_Union_const or.inl,
        principal_mono.mpr $ diff_right_antimono $ Union_subset_Union $
          take t, Union_subset_Union_const or.inr⟩)
      (take ⟨t, ht⟩, by simp [diff_neq_empty]; exact hd_cover ht),
  have f ≤ principal s, from infi_le_of_le ⟨∅, finite.empty⟩ $ by simp; exact subset.refl s,
  let
    ⟨c, (hc₁ : c ≤ f), (hc₂ : cauchy c)⟩ := h f ‹f ≠ ⊥› this,
    ⟨m, hm, (hmd : set.prod m m ⊆ d)⟩ := (@mem_prod_same_iff α d c).mp $ hc₂.right hd
  in
  have c ≤ principal s, from le_trans ‹c ≤ f› this,
  have m ∩ s ∈ c.sets, from inter_mem_sets hm $ le_principal_iff.mp this,
  let ⟨y, hym, hys⟩ := inhabited_of_mem_sets hc₂.left this in
  let ys := (⋃y'∈({y}:set α), {x | (x, y') ∈ d}) in
  have m ⊆ ys,
    from take y' hy', by dsimp; simp; exact @hmd (y', y) ⟨hy', hym⟩,
  have c ≤ principal (s - ys),
    from le_trans hc₁ $ infi_le_of_le ⟨{y}, finite_insert finite.empty⟩ $ le_refl _,
  have (s - ys) ∩ (m ∩ s) ∈ c.sets,
    from inter_mem_sets (le_principal_iff.mp this) ‹m ∩ s ∈ c.sets›,
  have ∅ ∈ c.sets,
    from c.upwards_sets this $ take x ⟨⟨hxs, hxys⟩, hxm, _⟩, hxys $ ‹m ⊆ ys› hxm,
  hc₂.left $ empty_in_sets_eq_bot.mp this⟩

lemma totally_bounded_iff_ultrafilter {s : set α} :
  totally_bounded s ↔ (∀f, ultrafilter f → f ≤ principal s → cauchy f) :=
⟨take hs f, cauchy_of_totally_bounded_of_ultrafilter hs,
  take h, totally_bounded_iff_filter.mpr $ take f hf hfs,
  have cauchy (ultrafilter_of f),
    from h (ultrafilter_of f) (ultrafilter_ultrafilter_of hf) (le_trans ultrafilter_of_le hfs),
  ⟨ultrafilter_of f, ultrafilter_of_le, this⟩⟩

lemma compact_of_totally_bounded_complete {s : set α}
  (ht : totally_bounded s) (hc : ∀{f:filter α}, cauchy f → f ≤ principal s → ∃x∈s, f ≤ nhds x) :
  compact s :=
begin
  rw [compact_iff_ultrafilter_le_nhds],
  rw [totally_bounded_iff_ultrafilter] at ht,
  exact take f hf hfs, hc (ht _ hf hfs) hfs
end

/- complete space -/
class complete_space (α : Type u) [uniform_space α] : Prop :=
(complete : ∀{f:filter α}, cauchy f → ∃x, f ≤ nhds x)

lemma complete_of_closed [complete_space α] {s : set α} {f : filter α}
  (h : closed s) (hf : cauchy f) (hfs : f ≤ principal s) : ∃x∈s, f ≤ nhds x :=
let ⟨x, hx⟩ := complete_space.complete hf in
have x ∈ s, from closed_iff_nhds.mp h x $ neq_bot_of_le_neq_bot hf.left $
  le_inf hx hfs,
⟨x, this, hx⟩

lemma compact_of_totally_bounded_closed [complete_space α] {s : set α}
  (ht : totally_bounded s) (hc : closed s) : compact s :=
@compact_of_totally_bounded_complete α _ s ht $ take f, complete_of_closed hc

lemma complete_space_extension [uniform_space β] {m : β → α}
  (hm : uniform_embedding m)
  (dense : ∀x, x ∈ closure (m '' univ))
  (h : ∀f:filter β, cauchy f → ∃x:α, map m f ≤ nhds x) :
  complete_space α :=
⟨take (f : filter α), assume hf : cauchy f,
let
  p : set (α × α) → set α → set α := λs t, {y : α| ∃x:α, x ∈ t ∧ (x, y) ∈ s},
  g := uniformity.lift (λs, f^.lift' (p s))
in
have mp₀ : monotone p,
  from take a b h t s ⟨x, xs, xa⟩, ⟨x, xs, h xa⟩,
have mp₁ : ∀{s}, monotone (p s),
  from take s a b h x ⟨y, ya, yxs⟩, ⟨y, h ya, yxs⟩,

have f ≤ g, from
  le_infi $ take s, le_infi $ take hs, le_infi $ take t, le_infi $ take ht,
  le_principal_iff.mpr $
  f.upwards_sets ht $ take x hx, ⟨x, hx, refl_mem_uniformity hs⟩,

have g ≠ ⊥, from neq_bot_of_le_neq_bot hf.left this,

have vmap m g ≠ ⊥, from vmap_neq_bot $ take t ht,
  let ⟨t', ht', ht_mem⟩ := (mem_lift_iff $ monotone_lift' monotone_const mp₀).mp ht in
  let ⟨t'', ht'', ht'_sub⟩ := (mem_lift'_iff mp₁).mp ht_mem in
  let ⟨x, (hx : x ∈ t'')⟩ := inhabited_of_mem_sets hf.left ht'' in
  have h₀ : nhds x ⊓ principal (m '' univ) ≠ ⊥,
    by simp [closure_eq_nhds] at dense; exact dense x,
  have h₁ : {y | (x, y) ∈ t'} ∈ (nhds x ⊓ principal (m '' univ)).sets,
    from @mem_inf_sets_of_left α (nhds x) (principal (m '' univ)) _ $ mem_nhds_left ht',
  have h₂ : m '' univ ∈ (nhds x ⊓ principal (m '' univ)).sets,
    from @mem_inf_sets_of_right α (nhds x) (principal (m '' univ)) _ $ subset.refl _,
  have {y | (x, y) ∈ t'} ∩ m '' univ ∈ (nhds x ⊓ principal (m '' univ)).sets,
    from @inter_mem_sets α (nhds x ⊓ principal (m '' univ)) _ _ h₁ h₂,
  let ⟨y, xyt', b, _, b_eq⟩ := inhabited_of_mem_sets h₀ this in
  ⟨b, b_eq.symm ▸ ht'_sub ⟨x, hx, xyt'⟩⟩,

have cauchy g, from
  ⟨‹g ≠ ⊥›, take s hs,
  let
    ⟨s₁, hs₁, (comp_s₁ : comp_rel s₁ s₁ ⊆ s)⟩ := comp_mem_uniformity_sets hs,
    ⟨s₂, hs₂, (comp_s₂ : comp_rel s₂ s₂ ⊆ s₁)⟩ := comp_mem_uniformity_sets hs₁,
    ⟨t, ht, (prod_t : set.prod t t ⊆ s₂)⟩ := mem_prod_same_iff.mp (hf.right hs₂)
  in
  have hg₁ : p (vimage prod.swap s₁) t ∈ g.sets,
    from mem_lift (symm_le_uniformity hs₁) $ @mem_lift' α α f _ t ht,
  have hg₂ : p s₂ t ∈ g.sets,
    from mem_lift hs₂ $ @mem_lift' α α f _ t ht,
  have hg : set.prod (p (vimage prod.swap s₁) t) (p s₂ t) ∈ (filter.prod g g).sets,
    from @prod_mem_prod α α _ _ g g hg₁ hg₂,
  (filter.prod g g).upwards_sets hg
    (take ⟨a, b⟩ ⟨⟨c₁, c₁t, (hc₁ : (a, c₁) ∈ s₁)⟩, ⟨c₂, c₂t, (hc₂ : (c₂, b) ∈ s₂)⟩⟩,
      have (c₁, c₂) ∈ set.prod t t, from ⟨c₁t, c₂t⟩,
      comp_s₁ $ prod_mk_mem_comp_rel hc₁ $
      comp_s₂ $ prod_mk_mem_comp_rel (prod_t this) hc₂)⟩,

have cauchy (filter.vmap m g),
  from cauchy_vmap (le_of_eq hm.right) ‹cauchy g› (by assumption),

let ⟨x, (hx : map m (filter.vmap m g) ≤ nhds x)⟩ := h _ this in
have map m (filter.vmap m g) ⊓ nhds x ≠ ⊥,
  from (le_nhds_iff_adhp_of_cauchy (cauchy_map (uniform_continuous_of_embedding hm) this)).mp hx,
have g ⊓ nhds x ≠ ⊥,
  from neq_bot_of_le_neq_bot this (inf_le_inf (take s hs, ⟨s, hs, subset.refl _⟩) (le_refl _)),

⟨x, calc f ≤ g : by assumption
  ... ≤ nhds x : le_nhds_of_cauchy_adhp ‹cauchy g› this⟩⟩

/- separation space -/
section separation_space

local attribute [instance] separation_setoid

instance : uniform_space (quotient (separation_setoid α)) :=
{ uniform_space .
  uniformity := map (λp:(α×α), (⟦p.1⟧, ⟦p.2⟧)) uniformity,
  refl  := take s hs ⟨a, b⟩ (h : a = b),
    have ∀a:α, (a, a) ∈ vimage (λ (p : α × α), (⟦p.fst⟧, ⟦p.snd⟧)) s,
      from take a, refl_mem_uniformity hs,
    h ▸ quotient.induction_on a this,
  symm  :=
    have prod.swap ∘ (λ (p : α × α), (⟦p.fst⟧, ⟦p.snd⟧)) =
      (λ (p : α × α), (⟦p.fst⟧, ⟦p.snd⟧)) ∘ prod.swap,
      from funext $ take ⟨a, b⟩, rfl,
    calc (map prod.swap ∘ map (λp:(α×α), (⟦p.1⟧, ⟦p.2⟧))) uniformity =
            (map (λp:(α×α), (⟦p.1⟧, ⟦p.2⟧)) ∘ map prod.swap) uniformity : by simp [map_compose, this]
      ... ≤ map (λp:(α×α), (⟦p.1⟧, ⟦p.2⟧)) uniformity : map_mono symm_le_uniformity,
  comp := calc (map (λ (p : α × α), (⟦p.fst⟧, ⟦p.snd⟧)) uniformity).lift' (λs, comp_rel s s) =
          uniformity.lift' ((λs, comp_rel s s) ∘ image (λ (p : α × α), (⟦p.fst⟧, ⟦p.snd⟧))) :
      map_lift'_eq2 $ monotone_comp_rel monotone_id monotone_id
    ... ≤ uniformity.lift' (image (λ (p : α × α), (⟦p.fst⟧, ⟦p.snd⟧)) ∘ (λs:set (α×α), comp_rel s (comp_rel s s))) :
      lift'_mono' $ take s hs ⟨a, b⟩ ⟨c, ⟨⟨a₁, a₂⟩, ha, a_eq⟩, ⟨⟨b₁, b₂⟩, hb, b_eq⟩⟩,
      begin
        simp at a_eq,
        simp at b_eq,
        assert h : ⟦a₂⟧ = ⟦b₁⟧, { rw [a_eq.right, b_eq.left] },
        note h : (a₂, b₁) ∈ separation_rel α := quotient.exact h,
        simp [function.comp, set.image, comp_rel],
        exact ⟨a₁, a_eq.left, b₂, b_eq.right, a₂, ha, b₁, h s hs, hb⟩
      end
    ... = map (λp:(α×α), (⟦p.1⟧, ⟦p.2⟧)) (uniformity.lift' (λs:set (α×α), comp_rel s (comp_rel s s))) :
      by rw [map_lift'_eq];
        exact monotone_comp_rel monotone_id (monotone_comp_rel monotone_id monotone_id)
    ... ≤ map (λp:(α×α), (⟦p.1⟧, ⟦p.2⟧)) uniformity :
      map_mono comp_le_uniformity3 }

lemma uniform_continuous_quotient_mk :
  uniform_continuous (quotient.mk : α → quotient (separation_setoid α)) :=
le_refl _

lemma vmap_quotient_le_uniformity : vmap (λ (p : α × α), (⟦p.fst⟧, ⟦p.snd⟧)) uniformity ≤ uniformity :=
take t' ht',
let ⟨t, ht, tt_t'⟩ := comp_mem_uniformity_sets ht' in
let ⟨s, hs, ss_t⟩ := comp_mem_uniformity_sets ht in
⟨(λp:α×α, (⟦p.1⟧, ⟦p.2⟧)) '' s,
  (@uniformity α _).upwards_sets hs $ take x hx, ⟨x, hx, rfl⟩,
  take ⟨a₁, a₂⟩ ⟨⟨b₁, b₂⟩, hb, ab_eq⟩,
  have ⟦b₁⟧ = ⟦a₁⟧ ∧ ⟦b₂⟧ = ⟦a₂⟧, from prod.mk.inj ab_eq,
  have b₁ ≈ a₁ ∧ b₂ ≈ a₂, from and.imp quotient.exact quotient.exact this,
  have ab₁ : (a₁, b₁) ∈ t, from (setoid.symm this.left) t ht,
  have ba₂ : (b₂, a₂) ∈ s, from this.right s hs,
  tt_t' ⟨b₁, show ((a₁, a₂).1, b₁) ∈ t, from ab₁,
    ss_t ⟨b₂, show ((b₁, a₂).1, b₂) ∈ s, from hb, ba₂⟩⟩⟩

lemma complete_space_separation [h : complete_space α] :
  complete_space (quotient (separation_setoid α)) :=
⟨take f, assume hf : cauchy f,
  have cauchy (vmap (λx, ⟦x⟧) f), from
    cauchy_vmap vmap_quotient_le_uniformity hf $
      vmap_neq_bot_of_surj hf.left $ take b, quotient.exists_rep _,
  let ⟨x, (hx : vmap (λx, ⟦x⟧) f ≤ nhds x)⟩ := complete_space.complete this in
  ⟨⟦x⟧, calc f ≤ map (λx, ⟦x⟧) (vmap (λx, ⟦x⟧) f) : le_map_vmap $ take b, quotient.exists_rep _
    ... ≤ map (λx, ⟦x⟧) (nhds x) : map_mono hx
    ... ≤ _ : continuous_iff_towards.mp (continuous_of_uniform uniform_continuous_quotient_mk) _⟩⟩

end separation_space

noncomputable def uniformly_extend [uniform_space γ] [nonempty γ]
  (emb : β → α) (f : β → γ) (a : α) : γ :=
classical.epsilon $ λc, map f (vmap emb (nhds a)) ≤ nhds c

section uniform_extension

variables
  [uniform_space β]
  [uniform_space γ]
  {e : β → α}
  (h_e : uniform_embedding e)
  (h_dense : ∀x, x ∈ closure (e '' univ))
  {f : β → γ}
  (h_f : uniform_continuous f)

local notation `ψ` := uniformly_extend e f

include h_dense h_e

private lemma vmap_e_neq_empty {a : α} : vmap e (nhds a) ≠ ⊥ :=
forall_sets_neq_empty_iff_neq_bot.mp $
have neq_bot : nhds a ⊓ principal (e '' univ) ≠ ⊥,
  by simp [closure_eq_nhds] at h_dense; exact h_dense a,
take s ⟨t, ht, (hs : vimage e t ⊆ s)⟩,
have h₁ : t ∈ (nhds a ⊓ principal (e '' univ)).sets,
  from @mem_inf_sets_of_left α (nhds a) (principal (e '' univ)) t ht,
have h₂ : e '' univ ∈ (nhds a ⊓ principal (e '' univ)).sets,
  from @mem_inf_sets_of_right α (nhds a) (principal (e '' univ)) _ $ subset.refl _,
have t ∩ e '' univ ∈ (nhds a ⊓ principal (e '' univ)).sets,
  from @inter_mem_sets α (nhds a ⊓ principal (e '' univ)) _ _ h₁ h₂,
let ⟨x, ⟨hx₁, y, hy, y_eq⟩⟩ := inhabited_of_mem_sets neq_bot this in
ne_empty_of_mem $ hs $ show e y ∈ t, from y_eq.symm ▸ hx₁

include h_f

lemma uniformly_extend_spec [nonempty γ] [complete_space γ] {a : α} :
  map f (vmap e (nhds a)) ≤ nhds (ψ a) :=
have cauchy (nhds a), from cauchy_nhds,
have cauchy (vmap e (nhds a)), from
  cauchy_vmap (le_of_eq h_e.right) this $ vmap_e_neq_empty h_e h_dense,
have cauchy (map f (vmap e (nhds a))), from
  cauchy_map h_f this,
have ∃c, map f (vmap e (nhds a)) ≤ nhds c,
  from complete_space.complete this,
classical.epsilon_spec this

lemma uniformly_extend_unique [nonempty γ] [cγ : complete_space γ] [sγ : separated γ] {a : α} {c : γ}
   (h : map f (vmap e (nhds a)) ≤ nhds c) : ψ a = c :=
have map f (vmap e (nhds a)) ≤ nhds (ψ a) ⊓ nhds c,
  from le_inf (@uniformly_extend_spec α β γ _ _ _ _ h_e h_dense f h_f _ cγ a) h,
  -- why does the elaborator not find cγ?
have nhds (uniformly_extend e f a) ⊓ nhds c ≠ ⊥,
  from neq_bot_of_le_neq_bot (by simp [map_eq_bot_iff]; exact vmap_e_neq_empty h_e h_dense) this,
@eq_of_nhds_neq_bot _ _ (@separated_t2 _ _ sγ) _ _ this

lemma uniformly_extend_of_emb [nonempty γ] [cγ : complete_space γ] [sγ : separated γ] {b : β} :
  ψ (e b) = f b :=
@uniformly_extend_unique α β γ _ _ _ e h_e h_dense f h_f _ cγ sγ (e b) (f b) $
have vmap e (nhds (e b)) ≤ nhds b,
  begin
    simp [nhds_eq_uniformity],
    rw [vmap_lift'_eq],
    simp [vimage, function.comp],
    rw [-h_e.right],
    rw [vmap_lift'_eq2],
    exact le_refl _,
    exact monotone_vimage,
    exact monotone_vimage
  end,
calc map f (vmap e (nhds (e b))) ≤ map f (nhds b) : map_mono this
  ... ≤ nhds (f b) : continuous_iff_towards.mp (continuous_of_uniform h_f) b

lemma uniform_continuous_uniformly_extend [nonempty γ] [cγ : complete_space γ] [sγ : separated γ] :
  uniform_continuous ψ :=
take d hd,
let ⟨s, hs, (hs_comp : comp_rel s (comp_rel s s) ⊆ d)⟩ := (mem_lift'_iff $
  monotone_comp_rel monotone_id $ monotone_comp_rel monotone_id monotone_id).mp (comp_le_uniformity3 hd) in
have vimage (λp:β×β, (f p.1, f p.2)) s ∈ (@uniformity β _).sets,
  from h_f hs,
have vimage (λp:β×β, (f p.1, f p.2)) s ∈ (vmap (λx:β×β, (e x.1, e x.2)) uniformity).sets,
  by rw [h_e.right.symm] at this; assumption,
let ⟨t, ht, (ts : ∀p:(β×β), (e p.1, e p.2) ∈ t → (f p.1, f p.2) ∈ s)⟩ := this in
show vimage (λp:(α×α), (ψ p.1, ψ p.2)) d ∈ uniformity.sets, from
  (@uniformity α _).upwards_sets (interior_mem_uniformity ht) $
  take ⟨x₁, x₂⟩ hx_t,
  have nhds (x₁, x₂) ≤ principal (interior t),
    from open_iff_nhds.mp open_interior (x₁, x₂) hx_t,
  have interior t ∈ (filter.prod (nhds x₁) (nhds x₂)).sets,
    by rw [nhds_prod_eq, le_principal_iff] at this; assumption,
  let ⟨m₁, hm₁, m₂, hm₂, (hm : set.prod m₁ m₂ ⊆ interior t)⟩ := mem_prod_iff.mp this in
  have nb : ∀{x}, map f (vmap e (nhds x)) ≠ ⊥,
    from take x hx, by rw [map_eq_bot_iff] at hx; exact vmap_e_neq_empty h_e h_dense hx,
  have (f '' vimage e m₁) ∩ {y | (ψ x₁, y) ∈ s } ∈ (map f (vmap e (nhds x₁))).sets,
    from inter_mem_sets (image_mem_map $ vimage_mem_vmap $ hm₁)
      (uniformly_extend_spec h_e h_dense h_f $ mem_nhds_left hs),
  let ⟨a, ha₁, ha₂⟩ := inhabited_of_mem_sets nb this in
  have (f '' vimage e m₂) ∩ {x | (x, ψ x₂) ∈ s } ∈ (map f (vmap e (nhds x₂))).sets,
    from inter_mem_sets (image_mem_map $ vimage_mem_vmap $ hm₂)
      (uniformly_extend_spec h_e h_dense h_f $ mem_nhds_right hs),
  let ⟨b, hb₁, hb₂⟩ := inhabited_of_mem_sets nb this in
  have set.prod (vimage e m₁) (vimage e m₂) ⊆ vimage (λp:(β×β), (f p.1, f p.2)) s,
    from calc vimage (λp:(β×β), (e p.1, e p.2)) (set.prod m₁ m₂) ⊆ vimage (λp:(β×β), (e p.1, e p.2)) (interior t) :
        vimage_mono hm
    ... ⊆ vimage (λp:(β×β), (e p.1, e p.2)) t : vimage_mono interior_subset
    ... ⊆ vimage (λp:(β×β), (f p.1, f p.2)) s : ts,
  have set.prod (f '' vimage e m₁) (f '' vimage e m₂) ⊆ s,
    from calc set.prod (f '' vimage e m₁) (f '' vimage e m₂) =
      (λp:(β×β), (f p.1, f p.2)) '' (set.prod (vimage e m₁) (vimage e m₂)) : prod_image_image_eq
    ... ⊆ (λp:(β×β), (f p.1, f p.2)) '' vimage (λp:(β×β), (f p.1, f p.2)) s : mono_image this
    ... ⊆ s : image_subset_iff_subset_vimage.mpr $ subset.refl _,
  have (a, b) ∈ s, from @this (a, b) ⟨ha₁, hb₁⟩,
  hs_comp $ show (ψ x₁, ψ x₂) ∈ comp_rel s (comp_rel s s),
    from ⟨a, ha₂, ⟨b, this, hb₂⟩⟩

end uniform_extension
end uniform_space
end

/-- Space of Cauchy filters

This is essentially the completion of a uniform space. The embeddings are the neighbourhood filters.
This space is not minimal, the separated uniform space (i.e. quotiented on the intersection of all
entourages) is necessary for this.
-/
def Cauchy (α : Type u) [uniform_space α] : Type u := { f : filter α // cauchy f }

namespace Cauchy

section
parameters {α : Type u} [uniform_space α]

def gen (s : set (α × α)) : set (Cauchy α × Cauchy α) :=
{p | s ∈ (filter.prod (p.1^.val) (p.2^.val))^.sets }

lemma monotone_gen : monotone gen :=
monotone_set_of $ take p, @monotone_mem_sets (α×α) (filter.prod (p.1^.val) (p.2^.val))

private lemma symm_gen : map prod.swap (uniformity^.lift' gen) ≤ uniformity^.lift' gen :=
calc map prod.swap (uniformity^.lift' gen) =
  uniformity^.lift' (λs:set (α×α), {p | s ∈ (filter.prod (p.2^.val) (p.1^.val))^.sets }) :
  begin
    delta gen,
    simp [map_lift'_eq, monotone_set_of, monotone_mem_sets,
          function.comp, image_swap_eq_vimage_swap]
  end
  ... ≤ uniformity^.lift' gen :
    uniformity_lift_le_swap
      (monotone_comp (monotone_set_of $ take p,
        @monotone_mem_sets (α×α) ((filter.prod ((p.2).val) ((p.1).val)))) monotone_principal)
      begin
        note h := λ(p:Cauchy α×Cauchy α), @filter.prod_comm _ _ (p.2.val) (p.1.val),
        simp [function.comp, h],
        exact le_refl _
      end

private lemma comp_rel_gen_gen_subset_gen_comp_rel {s t : set (α×α)} : comp_rel (gen s) (gen t) ⊆
  (gen (comp_rel s t) : set (Cauchy α × Cauchy α)) :=
take ⟨f, g⟩ ⟨h, h₁, h₂⟩,
let ⟨t₁, (ht₁ : t₁ ∈ f.val.sets), t₂, (ht₂ : t₂ ∈ h.val.sets), (h₁ : set.prod t₁ t₂ ⊆ s)⟩ :=
  mem_prod_iff^.mp h₁ in
let ⟨t₃, (ht₃ : t₃ ∈ h.val.sets), t₄, (ht₄ : t₄ ∈ g.val.sets), (h₂ : set.prod t₃ t₄ ⊆ t)⟩ :=
  mem_prod_iff^.mp h₂ in
have t₂ ∩ t₃ ∈ h.val.sets,
  from inter_mem_sets ht₂ ht₃,
let ⟨x, xt₂, xt₃⟩ :=
  inhabited_of_mem_sets (h.property.left) this in
(filter.prod f^.val g^.val).upwards_sets
  (prod_mem_prod ht₁ ht₄)
  (take ⟨a, b⟩ ⟨(ha : a ∈ t₁), (hb : b ∈ t₄)⟩,
    ⟨x,
      h₁ (show (a, x) ∈ set.prod t₁ t₂, from ⟨ha, xt₂⟩),
      h₂ (show (x, b) ∈ set.prod t₃ t₄, from ⟨xt₃, hb⟩)⟩)

private lemma comp_gen :
  (uniformity^.lift' gen)^.lift' (λs, comp_rel s s) ≤ uniformity^.lift' gen :=
calc (uniformity^.lift' gen)^.lift' (λs, comp_rel s s) =
    uniformity^.lift' (λs, comp_rel (gen s) (gen s)) :
  begin
    rw [lift'_lift'_assoc],
    exact monotone_gen,
    exact (monotone_comp_rel monotone_id monotone_id)
  end
  ... ≤ uniformity^.lift' (λs, gen $ comp_rel s s) :
    lift'_mono' $ take s hs, comp_rel_gen_gen_subset_gen_comp_rel
  ... = (uniformity^.lift' $ λs:set(α×α), comp_rel s s)^.lift' gen :
  begin
    rw [lift'_lift'_assoc],
    exact (monotone_comp_rel monotone_id monotone_id),
    exact monotone_gen
  end
  ... ≤ uniformity^.lift' gen : lift'_mono comp_le_uniformity (le_refl _)

instance completion_space : uniform_space (Cauchy α) :=
{ uniformity := uniformity^.lift' gen,
  refl       := principal_le_lift' $ take s hs ⟨a, b⟩ (a_eq_b : a = b),
    a_eq_b ▸ a^.property^.right hs,
  symm       := symm_gen,
  comp      := comp_gen }

def pure_cauchy (a : α) : Cauchy α :=
⟨pure a, cauchy_pure⟩

lemma uniform_embedding_pure_cauchy : uniform_embedding (pure_cauchy : α → Cauchy α) :=
⟨take a₁ a₂ h,
  have (pure_cauchy a₁).val = (pure_cauchy a₂).val, from congr_arg _ h,
  have {a₁} = ({a₂} : set α),
    from principal_eq_iff_eq.mp this,
  by simp at this; assumption,

  have (vimage (λ (x : α × α), (pure_cauchy (x.fst), pure_cauchy (x.snd))) ∘ gen) = id,
    from funext $ take s, set.ext $ take ⟨a₁, a₂⟩,
      by simp [vimage, gen, pure_cauchy, prod_principal_principal],
  calc vmap (λ (x : α × α), (pure_cauchy (x.fst), pure_cauchy (x.snd))) (uniformity^.lift' gen) =
          uniformity^.lift' (vimage (λ (x : α × α), (pure_cauchy (x.fst), pure_cauchy (x.snd))) ∘ gen) :
      vmap_lift'_eq monotone_gen
    ... = uniformity : by simp [this]⟩

lemma pure_cauchy_dense : ∀x, x ∈ closure (pure_cauchy '' univ) :=
take f,
have h_ex : ∀s∈(@uniformity (Cauchy α) _).sets, ∃y:α, (f, pure_cauchy y) ∈ s, from
  take s hs,
  let ⟨t'', ht''₁, (ht''₂ : gen t'' ⊆ s)⟩ := (mem_lift'_iff monotone_gen).mp hs in
  let ⟨t', ht'₁, ht'₂⟩ := comp_mem_uniformity_sets ht''₁ in
  have t' ∈ (filter.prod (f.val) (f.val)).sets,
    from f.property.right ht'₁,
  let ⟨t, ht, (h : set.prod t t ⊆ t')⟩ := mem_prod_same_iff.mp this in
  let ⟨x, (hx : x ∈ t)⟩ := inhabited_of_mem_sets f.property.left ht in
  have t'' ∈ (filter.prod f.val (pure x)).sets,
    from mem_prod_iff.mpr ⟨t, ht, {y:α | (x, y) ∈ t'},
      take y, begin simp, intro h, simp [h], exact refl_mem_uniformity ht'₁ end,
      take ⟨a, b⟩ ⟨(h₁ : a ∈ t), (h₂ : (x, b) ∈ t')⟩,
        ht'₂ $ prod_mk_mem_comp_rel (@h (a, x) ⟨h₁, hx⟩) h₂⟩,
  ⟨x, ht''₂ $ by dsimp [gen]; exact this⟩,
begin
  simp [closure_eq_nhds, nhds_eq_uniformity, lift'_inf_principal_eq],
  exact (lift'_neq_bot_iff $ monotone_inter monotone_const monotone_vimage).mpr
    (take s hs,
      let ⟨y, hy⟩ := h_ex s hs in
      have pure_cauchy y ∈ pure_cauchy '' univ ∩ {y : Cauchy α | (f, y) ∈ s},
        from ⟨mem_image_of_mem _ $ mem_univ y, hy⟩,
      ne_empty_of_mem this)
end

instance : complete_space (Cauchy α) :=
complete_space_extension
  uniform_embedding_pure_cauchy
  pure_cauchy_dense $
  take f hf,
  let f' : Cauchy α := ⟨f, hf⟩ in
  have map pure_cauchy f ≤ uniformity.lift' (vimage (prod.mk f')),
    from le_lift' $ take s hs,
    let ⟨t, ht₁, (ht₂ : gen t ⊆ s)⟩ := (mem_lift'_iff monotone_gen).mp hs in
    let ⟨t', ht', (h : set.prod t' t' ⊆ t)⟩ := mem_prod_same_iff.mp (hf.right ht₁) in
    have t' ⊆ { y : α | (f', pure_cauchy y) ∈ gen t },
      from take x hx, (filter.prod f (pure x)).upwards_sets (prod_mem_prod ht' $ mem_pure hx) h,
    f.upwards_sets ht' $ subset.trans this (vimage_mono ht₂),
  ⟨f', by simp [nhds_eq_uniformity]; assumption⟩

end

end Cauchy

section constructions
variables {α : Type u} {β : Type v}

instance : weak_order (uniform_space α) :=
{ weak_order .
  le          := λt s, s^.uniformity ≤ t^.uniformity,
  le_antisymm := take t s h₁ h₂, uniform_space_eq $ le_antisymm h₂ h₁,
  le_refl     := take t, le_refl _,
  le_trans    := take a b c h₁ h₂, @le_trans _ _ c^.uniformity b^.uniformity a^.uniformity h₂ h₁ }

instance : has_Sup (uniform_space α) :=
⟨take s, {
  uniformity := (⨅u∈s, @uniformity α u),
  refl       := le_infi $ take u, le_infi $ take hu, u.refl,
  symm       := le_infi $ take u, le_infi $ take hu,
    le_trans (map_mono $ infi_le_of_le _ $ infi_le _ hu) u.symm,
  comp       := le_infi $ take u, le_infi $ take hu,
    le_trans (lift'_mono (infi_le_of_le _ $ infi_le _ hu) $ le_refl _) u.comp }⟩

private lemma le_Sup {tt : set (uniform_space α)} {t : uniform_space α} (h : t ∈ tt) :
  t ≤ Sup tt :=
show (⨅u∈tt, @uniformity α u) ≤ t.uniformity,
  from infi_le_of_le t $ infi_le _ h

private lemma Sup_le {tt : set (uniform_space α)} {t : uniform_space α} (h : ∀t'∈tt, t' ≤ t) :
  Sup tt ≤ t :=
show t.uniformity ≤ (⨅u∈tt, @uniformity α u),
  from le_infi $ take t', le_infi $ take ht', h t' ht'

instance : has_bot (uniform_space α) :=
⟨{ uniformity := ⊤, refl := le_top, symm := le_top, comp := le_top }⟩

instance : has_top (uniform_space α) :=
⟨{ uniformity := principal id_rel,
  refl        := le_refl _,
  symm        := by simp; apply subset.refl,
  comp        :=
  begin
    rw [lift'_principal],
    { simp, apply subset.refl },
    exact monotone_comp_rel monotone_id monotone_id
  end}⟩

instance : complete_lattice (uniform_space α) :=
{ uniform_space.weak_order with
  sup           := λa b, Sup {a, b},
  le_sup_left   := take a b, le_Sup $ by simp,
  le_sup_right  := take a b, le_Sup $ by simp,
  sup_le        := take a b c h₁ h₂, Sup_le $ take t',
    begin simp, intro h, cases h with h h, repeat { subst h; assumption } end,
  inf           := λa b, Sup {x | x ≤ a ∧ x ≤ b},
  le_inf        := take a b c h₁ h₂, le_Sup ⟨h₁, h₂⟩,
  inf_le_left   := take a b, Sup_le $ take x ⟨ha, hb⟩, ha,
  inf_le_right  := take a b, Sup_le $ take x ⟨ha, hb⟩, hb,
  top           := ⊤,
  le_top        := take u, u.refl,
  bot           := ⊥,
  bot_le        := take a, show a.uniformity ≤ ⊤, from le_top,
  Sup           := Sup,
  le_Sup        := take s u, le_Sup,
  Sup_le        := take s u, Sup_le,
  Inf           := λtt, Sup {t | ∀t'∈tt, t ≤ t'},
  le_Inf        := take s a hs, le_Sup hs,
  Inf_le        := take s a ha, Sup_le $ take u hs, hs _ ha }

instance inhabited_uniform_space : inhabited (uniform_space α) := ⟨⊤⟩

def uniform_space.vmap (f : α → β) (u : uniform_space β) : uniform_space α :=
{ uniformity := u.uniformity.vmap (λp:α×α, (f p.1, f p.2)),
  refl := le_trans (by simp; exact take ⟨a, b⟩ (h : a = b), h ▸ rfl) (vmap_mono u.refl),
  symm := le_trans
    (by simp [map_swap_vmap_swap_eq, vmap_vmap_comp, function.comp]; exact le_refl _)
    (vmap_mono u.symm),
  comp := le_trans
    begin
      rw [vmap_lift'_eq, vmap_lift'_eq2],
      exact (lift'_mono' $ take s hs ⟨a₁, a₂⟩ ⟨x, h₁, h₂⟩, ⟨f x, h₁, h₂⟩),
      repeat { exact monotone_comp_rel monotone_id monotone_id }
    end
    (vmap_mono u.comp) }

lemma uniform_continuous_vmap {f : α → β} {u : uniform_space β} :
  @uniform_continuous α β (uniform_space.vmap f u) u f :=
map_vmap_le

lemma to_topological_space_vmap {f : α → β} {u : uniform_space β} :
  (uniform_space.vmap f u).to_topological_space = topological_space.induced f u.to_topological_space :=
eq_of_nhds_eq_nhds $ take a,
begin
  simp [nhds_induced_eq_vmap, nhds_eq_uniformity, nhds_eq_uniformity],
  change vmap f (uniformity.lift' (vimage (λb, (f a, b)))) =
      (u.uniformity.vmap (λp:α×α, (f p.1, f p.2))).lift' (vimage (λa', (a, a'))),
  rw [vmap_lift'_eq monotone_vimage, vmap_lift'_eq2 monotone_vimage],
  exact rfl
end

instance : uniform_space empty := ⊤
instance : uniform_space unit := ⊤
instance : uniform_space bool := ⊤
instance : uniform_space ℕ := ⊤
instance : uniform_space ℤ := ⊤

instance {p : α → Prop} [t : uniform_space α] : uniform_space (subtype p) :=
uniform_space.vmap subtype.val t

instance [t₁ : uniform_space α] [t₂ : uniform_space β] : uniform_space (α × β) :=
uniform_space.vmap prod.fst t₁ ⊔ uniform_space.vmap prod.snd t₂

/- a similar product space is possible on the function space (uniformity of pointwise convergence),
  but we want to have the uniformity of uniform convergence on function spaces -/

lemma to_topological_space_mono {u₁ u₂ : uniform_space α} (h : u₁ ≤ u₂) :
  u₁.to_topological_space ≤ u₂.to_topological_space :=
le_of_nhds_le_nhds $ take a,
  by rw [@nhds_eq_uniformity α u₁ a, @nhds_eq_uniformity α u₂ a]; exact (lift'_mono h $ le_refl _)

lemma supr_uniformity {ι : Sort v} {u : ι → uniform_space α} :
  (supr u).uniformity = (⨅i, (u i).uniformity) :=
show (⨅a (h : ∃i:ι, a = u i), a.uniformity) = _, from
le_antisymm
  (le_infi $ take i, infi_le_of_le (u i) $ infi_le _ ⟨i, rfl⟩)
  (le_infi $ take a, le_infi $ take ⟨i, (ha : a = u i)⟩, ha.symm ▸ infi_le _ _)

lemma to_topological_space_top : (⊤ : uniform_space α).to_topological_space = ⊤ :=
top_unique $ take s hs x hx ⟨a₁, a₂⟩ (h₁ : a₁ = a₂) (h₂ : a₁ = x),
  h₁ ▸ h₂.symm ▸ hx

lemma to_topological_space_bot : (⊥ : uniform_space α).to_topological_space = ⊥ :=
bot_unique $ take s hs, classical.by_cases
  (suppose s = ∅, this.symm ▸ @open_empty _ ⊥)
  (suppose s ≠ ∅,
    let ⟨x, hx⟩ := exists_mem_of_ne_empty this in
    have univ ⊆ _,
      from hs x hx,
    have s = univ,
      from top_unique $ take y hy, @this (x, y) ⟨⟩ rfl,
    this.symm ▸ @open_univ _ ⊥)

lemma to_topological_space_supr {ι : Sort v} {u : ι → uniform_space α} :
  (supr u).to_topological_space = (⨆i, (u i).to_topological_space) :=
classical.by_cases
  (assume h : nonempty ι,
    eq_of_nhds_eq_nhds $ take a,
    begin
      rw [nhds_supr, nhds_eq_uniformity],
      change _ = (supr u).uniformity.lift' (vimage $ prod.mk a),
      begin
        rw [supr_uniformity, lift'_infi],
        exact (congr_arg _ $ funext $ take i, @nhds_eq_uniformity α (u i) a),
        exact h,
        exact take a b, rfl
      end
    end)
  (suppose ¬ nonempty ι,
    le_antisymm
      (have supr u = ⊥, from bot_unique $ supr_le $ take i, (this ⟨i⟩).elim,
        have (supr u).to_topological_space = ⊥,
          from this.symm ▸ to_topological_space_bot,
        this.symm ▸ bot_le)
      (supr_le $ take i, to_topological_space_mono $ le_supr _ _))

end constructions
