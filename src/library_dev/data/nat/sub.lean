/-
Copyright (c) 2014 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Authors: Floris van Doorn, Jeremy Avigad
Subtraction on the natural numbers, as well as min, max, and distance.
-/

namespace nat

/- interaction with inequalities -/

protected theorem le_sub_add (n m : ℕ) : n ≤ n - m + m :=
or.elim (le_total n m)
  (suppose n ≤ m, begin rw [sub_eq_zero_of_le this, zero_add], exact this end)
  (suppose m ≤ n, begin rw (nat.sub_add_cancel this) end)

protected theorem sub_eq_of_eq_add {n m k : ℕ} (h : k = n + m) : k - n = m :=
begin rw [h, nat.add_sub_cancel_left] end

protected theorem sub_le_sub_left {n m : ℕ} (h : n ≤ m) (k : ℕ) : k - m ≤ k - n :=
begin
  cases le.dest h with l hl,
  rw [-hl, -nat.sub_sub],
  apply sub_le
end

protected theorem lt_of_sub_pos {m n : ℕ} (h : n - m > 0) : m < n :=
lt_of_not_ge
  (suppose m ≥ n,
    have n - m = 0, from sub_eq_zero_of_le this,
    begin rw this at h, exact lt_irrefl _ h end)

protected theorem lt_of_sub_lt_sub_right {n m k : ℕ} (h : n - k < m - k) : n < m :=
lt_of_not_ge
  (suppose m ≤ n,
    have m - k ≤ n - k, from nat.sub_le_sub_right this _,
    not_le_of_gt h this)

protected theorem lt_of_sub_lt_sub_left {n m k : ℕ} (h : n - m < n - k) : k < m :=
lt_of_not_ge
  (suppose m ≤ k,
    have n - k ≤ n - m, from nat.sub_le_sub_left this _,
    not_le_of_gt h this)

protected theorem sub_lt_self {m n : ℕ} (h₁ : m > 0) (h₂ : n > 0) : m - n < m :=
calc
  m - n = succ (pred m) - succ (pred n) : by rw [succ_pred_eq_of_pos h₁, succ_pred_eq_of_pos h₂]
    ... = pred m - pred n               : by rw succ_sub_succ
    ... ≤ pred m                        : sub_le _ _
    ... < succ (pred m)                 : lt_succ_self _
    ... = m                             : succ_pred_eq_of_pos h₁

protected theorem le_sub_of_add_le {m n k : ℕ} (h : m + k ≤ n) : m ≤ n - k :=
calc
  m = m + k - k : by rw nat.add_sub_cancel
    ... ≤ n - k : nat.sub_le_sub_right h k

protected theorem lt_sub_of_add_lt {m n k : ℕ} (h : m + k < n) : m < n - k :=
lt_of_succ_le (nat.le_sub_of_add_le (calc
    succ m + k = succ (m + k) : by rw succ_add
           ... ≤ n            : succ_le_of_lt h))

protected theorem add_lt_of_lt_sub {m n k : ℕ} (h : m < n - k) : m + k < n :=
@nat.lt_of_sub_lt_sub_right _ _ k (by rwa nat.add_sub_cancel)

protected theorem sub_lt_of_lt_add {k n m : nat} (h₁ : k < n + m) (h₂ : n ≤ k) : k - n < m :=
have succ k ≤ n + m,   from succ_le_of_lt h₁,
have succ (k - n) ≤ m, from
  calc succ (k - n) = succ k - n : by rw (succ_sub h₂)
        ...     ≤ n + m - n      : nat.sub_le_sub_right this n
        ...     = m              : by rw nat.add_sub_cancel_left,
lt_of_succ_le this


/- distance -/

definition dist (n m : ℕ) := (n - m) + (m - n)

theorem dist.def (n m : ℕ) : dist n m = (n - m) + (m - n) := rfl

@[simp]
theorem dist_comm (n m : ℕ) : dist n m = dist m n :=
by simp [dist.def]

@[simp]
theorem dist_self (n : ℕ) : dist n n = 0 :=
by simp [dist.def, nat.sub_self]

theorem eq_of_dist_eq_zero {n m : ℕ} (h : dist n m = 0) : n = m :=
have n - m = 0, from eq_zero_of_add_eq_zero_right h,
have n ≤ m, from nat.le_of_sub_eq_zero this,
have m - n = 0, from eq_zero_of_add_eq_zero_left h,
have m ≤ n, from nat.le_of_sub_eq_zero this,
le_antisymm ‹n ≤ m› ‹m ≤ n›

theorem dist_eq_zero {n m : ℕ} (h : n = m) : dist n m = 0 :=
begin rw [h, dist_self] end

theorem dist_eq_sub_of_le {n m : ℕ} (h : n ≤ m) : dist n m = m - n :=
begin rw [dist.def, sub_eq_zero_of_le h, zero_add] end

theorem dist_eq_sub_of_ge {n m : ℕ} (h : n ≥ m) : dist n m = n - m :=
begin rw [dist_comm], apply dist_eq_sub_of_le h end

theorem dist_zero_right (n : ℕ) : dist n 0 = n :=
eq.trans (dist_eq_sub_of_ge (zero_le n)) (nat.sub_zero n)

theorem dist_zero_left (n : ℕ) : dist 0 n = n :=
eq.trans (dist_eq_sub_of_le (zero_le n)) (nat.sub_zero n)

theorem dist_add_add_right (n k m : ℕ) : dist (n + k) (m + k) = dist n m :=
calc
  dist (n + k) (m + k) = ((n + k) - (m + k)) + ((m + k)-(n + k)) : rfl
                   ... = (n - m) + ((m + k) - (n + k))   : by rw nat.add_sub_add_right
                   ... = (n - m) + (m - n)               : by rw nat.add_sub_add_right

theorem dist_add_add_left (k n m : ℕ) : dist (k + n) (k + m) = dist n m :=
begin rw [add_comm k n, add_comm k m], apply dist_add_add_right end

theorem dist_eq_intro {n m k l : ℕ} (h : n + m = k + l) : dist n k = dist l m :=
calc
  dist n k = dist (n + m) (k + m) : by rw dist_add_add_right
       ... = dist (k + l) (k + m) : by rw h
       ... = dist l m             : by rw dist_add_add_left

protected theorem sub_lt_sub_add_sub (n m k : ℕ) : n - k ≤ (n - m) + (m - k) :=
or.elim (le_total k m)
  (suppose k ≤ m,
    begin rw -nat.add_sub_assoc this, apply nat.sub_le_sub_right, apply nat.le_sub_add end)
  (suppose k ≥ m,
    begin rw [sub_eq_zero_of_le this, add_zero], apply nat.sub_le_sub_left, exact this end)

theorem dist.triangle_inequality (n m k : ℕ) : dist n k ≤ dist n m + dist m k :=
have dist n m + dist m k = (n - m) + (m - k) + ((k - m) + (m - n)), by simp [dist.def],
begin
  rw [this, dist.def], apply add_le_add, repeat { apply nat.sub_lt_sub_add_sub }
end

theorem dist_mul_right (n k m : ℕ) : dist (n * k) (m * k) = dist n m * k :=
by rw [dist.def, dist.def, right_distrib, nat.mul_sub_right_distrib, nat.mul_sub_right_distrib]

theorem dist_mul_left (k n m : ℕ) : dist (k * n) (k * m) = k * dist n m :=
by rw [mul_comm k n, mul_comm k m, dist_mul_right, mul_comm]

-- TODO(Jeremy): do when we have max and minx
--lemma dist_eq_max_sub_min {i j : nat} : dist i j = (max i j) - min i j :=
--sorry
/-
or.elim (lt_or_ge i j)
  (suppose i < j,
    by rw [max_eq_right_of_lt this, min_eq_left_of_lt this, dist_eq_sub_of_lt this])
  (suppose i ≥ j,
    by rw [max_eq_left this , min_eq_right this, dist_eq_sub_of_ge this])
-/

lemma dist_succ_succ {i j : nat} : dist (succ i) (succ j) = dist i j :=
by simp [dist.def, succ_sub_succ]

lemma dist_pos_of_ne {i j : nat} : i ≠ j → dist i j > 0 :=
assume hne, nat.lt_by_cases
  (suppose i < j,
     begin rw [dist_eq_sub_of_le (le_of_lt this)], apply nat.sub_pos_of_lt this end)
  (suppose i = j, by contradiction)
  (suppose i > j,
     begin rw [dist_eq_sub_of_ge (le_of_lt this)], apply nat.sub_pos_of_lt this end)

end nat
