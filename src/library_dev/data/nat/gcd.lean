/-
Copyright (c) 2014 Jeremy Avigad. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jeremy Avigad, Leonardo de Moura

Definitions and properties of gcd, lcm, and coprime.
-/
import .dvd

open well_founded decidable prod

namespace nat

/- gcd -/

def gcd.F : Π (y : ℕ), (Π (y' : ℕ), y' < y → nat → nat) → nat → nat
| 0        f x := x
| (succ y) f x := f (x % succ y) (mod_lt _ $ succ_pos _) (succ y)

def gcd (x y : nat) := fix lt_wf gcd.F y x

@[simp] theorem gcd_zero_right (x : nat) : gcd x 0 = x := congr_fun (fix_eq lt_wf gcd.F 0) x

@[simp] theorem gcd_succ (x y : nat) : gcd x (succ y) = gcd (succ y) (x % succ y) :=
congr_fun (fix_eq lt_wf gcd.F (succ y)) x

theorem gcd_one_right (n : ℕ) : gcd n 1 = 1 :=
eq.trans (gcd_succ n 0) (by rw [mod_one, gcd_zero_right])

theorem gcd_def (x : ℕ) : Π (y : ℕ), gcd x y = if y = 0 then x else gcd y (x % y)
| 0        := gcd_zero_right _
| (succ y) := (gcd_succ x y).trans (if_neg (succ_ne_zero y)).symm

theorem gcd_self : Π (n : ℕ), gcd n n = n
| 0         := gcd_zero_right _
| (succ n₁) := (gcd_succ (succ n₁) n₁).trans (by rw [mod_self, gcd_zero_right])

theorem gcd_zero_left : Π (n : ℕ), gcd 0 n = n
| 0         := gcd_zero_right _
| (succ n₁) := (gcd_succ 0 n₁).trans (by rw [zero_mod, gcd_zero_right])

theorem gcd_rec (m : ℕ) : Π (n : ℕ), gcd m n = gcd n (m % n)
| 0         := by rw [mod_zero, gcd_zero_left, gcd_zero_right]
| (succ n₁) := gcd_succ _ _

@[elab_as_eliminator]
theorem gcd.induction {P : ℕ → ℕ → Prop}
                   (m n : ℕ)
                   (H0 : ∀m, P m 0)
                   (H1 : ∀m n, 0 < n → P n (m % n) → P m n) :
                 P m n :=
@induction _ _ lt_wf (λn, ∀m, P m n) n (λk IH,
  by {induction k with k ih, exact H0,
      exact λm, H1 _ _ (succ_pos _) (IH _ (mod_lt _ (succ_pos _)) _)}) m

theorem gcd_dvd (m n : ℕ) : (gcd m n ∣ m) ∧ (gcd m n ∣ n) :=
gcd.induction m n
  (λm, by rw gcd_zero_right; exact ⟨dvd_refl m, dvd_zero m⟩)
  (λm n npos, by rw -gcd_rec; exact λ ⟨IH₁, IH₂⟩, ⟨(dvd_mod_iff IH₁).1 IH₂, IH₁⟩)

theorem gcd_dvd_left (m n : ℕ) : gcd m n ∣ m := (gcd_dvd m n).left

theorem gcd_dvd_right (m n : ℕ) : gcd m n ∣ n := (gcd_dvd m n).right

theorem dvd_gcd {m n k : ℕ} : k ∣ m → k ∣ n → k ∣ gcd m n :=
gcd.induction m n (λm km _, by rw gcd_zero_right; exact km)
  (λm n npos IH H1 H2, by rw gcd_rec; exact IH H2 ((dvd_mod_iff H2).2 H1))

theorem gcd_comm (m n : ℕ) : gcd m n = gcd n m :=
dvd.antisymm
  (dvd_gcd (gcd_dvd_right m n) (gcd_dvd_left m n))
  (dvd_gcd (gcd_dvd_right n m) (gcd_dvd_left n m))

theorem gcd_assoc (m n k : ℕ) : gcd (gcd m n) k = gcd m (gcd n k) :=
dvd.antisymm
  (dvd_gcd
    (dvd.trans (gcd_dvd_left (gcd m n) k) (gcd_dvd_left m n))
    (dvd_gcd (dvd.trans (gcd_dvd_left (gcd m n) k) (gcd_dvd_right m n)) (gcd_dvd_right (gcd m n) k)))
  (dvd_gcd
    (dvd_gcd (gcd_dvd_left m (gcd n k)) (dvd.trans (gcd_dvd_right m (gcd n k)) (gcd_dvd_left n k)))
    (dvd.trans (gcd_dvd_right m (gcd n k)) (gcd_dvd_right n k)))

theorem gcd_one_left (m : ℕ) : gcd 1 m = 1 :=
eq.trans (gcd_comm 1 m) $ gcd_one_right m

theorem gcd_mul_left (m n k : ℕ) : gcd (m * n) (m * k) = m * gcd n k :=
gcd.induction n k
  (λn, by repeat {rw mul_zero <|> rw gcd_zero_right})
  (λn k H IH, by rwa [-mul_mod_mul_left, -gcd_rec, -gcd_rec] at IH)

theorem gcd_mul_right (m n k : ℕ) : gcd (m * n) (k * n) = gcd m k * n :=
by rw [mul_comm m n, mul_comm k n, mul_comm (gcd m k) n, gcd_mul_left]

theorem gcd_pos_of_pos_left {m : ℕ} (n : ℕ) (mpos : m > 0) : gcd m n > 0 :=
pos_of_dvd_of_pos (gcd_dvd_left m n) mpos

theorem gcd_pos_of_pos_right (m : ℕ) {n : ℕ} (npos : n > 0) : gcd m n > 0 :=
pos_of_dvd_of_pos (gcd_dvd_right m n) npos

theorem eq_zero_of_gcd_eq_zero_left {m n : ℕ} (H : gcd m n = 0) : m = 0 :=
or.elim (eq_zero_or_pos m) id
  (assume H1 : m > 0, absurd (eq.symm H) (ne_of_lt (gcd_pos_of_pos_left _ H1)))

theorem eq_zero_of_gcd_eq_zero_right {m n : ℕ} (H : gcd m n = 0) : n = 0 :=
by rw gcd_comm at H; exact eq_zero_of_gcd_eq_zero_left H

theorem gcd_div {m n k : ℕ} (H1 : k ∣ m) (H2 : k ∣ n) :
  gcd (m / k) (n / k) = gcd m n / k :=
or.elim (eq_zero_or_pos k)
  (λk0, by rw [k0, nat.div_zero, nat.div_zero, nat.div_zero, gcd_zero_right])
  (λH3, nat.eq_of_mul_eq_mul_right H3 $ by rw [
    nat.div_mul_cancel (dvd_gcd H1 H2), -gcd_mul_right,
    nat.div_mul_cancel H1, nat.div_mul_cancel H2])

theorem gcd_dvd_gcd_of_dvd_left {m k : ℕ} (n : ℕ) (H : m ∣ k) : gcd m n ∣ gcd k n :=
dvd_gcd (dvd.trans (gcd_dvd_left m n) H) (gcd_dvd_right m n)

theorem gcd_dvd_gcd_of_dvd_right {m k : ℕ} (n : ℕ) (H : m ∣ k) : gcd n m ∣ gcd n k :=
dvd_gcd (gcd_dvd_left n m) (dvd.trans (gcd_dvd_right n m) H)

theorem gcd_dvd_gcd_mul_left (m n k : ℕ) : gcd m n ∣ gcd (k * m) n :=
gcd_dvd_gcd_of_dvd_left _ (dvd_mul_left _ _)

theorem gcd_dvd_gcd_mul_right (m n k : ℕ) : gcd m n ∣ gcd (m * k) n :=
gcd_dvd_gcd_of_dvd_left _ (dvd_mul_right _ _)

theorem gcd_dvd_gcd_mul_left_right (m n k : ℕ) : gcd m n ∣ gcd m (k * n) :=
gcd_dvd_gcd_of_dvd_right _ (dvd_mul_left _ _)

theorem gcd_dvd_gcd_mul_right_right (m n k : ℕ) : gcd m n ∣ gcd m (n * k) :=
gcd_dvd_gcd_of_dvd_right _ (dvd_mul_right _ _)

/- lcm -/

def lcm (m n : ℕ) : ℕ := m * n / (gcd m n)

theorem lcm_comm (m n : ℕ) : lcm m n = lcm n m :=
by delta lcm; rw [mul_comm, gcd_comm]

theorem lcm_zero_left (m : ℕ) : lcm 0 m = 0 :=
by delta lcm; rw [zero_mul, nat.zero_div]

theorem lcm_zero_right (m : ℕ) : lcm m 0 = 0 := lcm_comm 0 m ▸ lcm_zero_left m

theorem lcm_one_left (m : ℕ) : lcm 1 m = m :=
by delta lcm; rw [one_mul, gcd_one_left, nat.div_one]

theorem lcm_one_right (m : ℕ) : lcm m 1 = m := lcm_comm 1 m ▸ lcm_one_left m

theorem lcm_self (m : ℕ) : lcm m m = m :=
or.elim (eq_zero_or_pos m)
  (λh, by rw [h, lcm_zero_left])
  (λh, by delta lcm; rw [gcd_self, nat.mul_div_cancel _ h])

theorem dvd_lcm_left (m n : ℕ) : m ∣ lcm m n :=
dvd.intro (n / gcd m n) (nat.mul_div_assoc _ $ gcd_dvd_right m n).symm

theorem dvd_lcm_right (m n : ℕ) : n ∣ lcm m n :=
lcm_comm n m ▸ dvd_lcm_left n m

theorem gcd_mul_lcm (m n : ℕ) : gcd m n * lcm m n = m * n :=
by delta lcm; rw [nat.mul_div_cancel' (dvd.trans (gcd_dvd_left m n) (dvd_mul_right m n))]

theorem lcm_dvd {m n k : ℕ} (H1 : m ∣ k) (H2 : n ∣ k) : lcm m n ∣ k :=
or.elim (eq_zero_or_pos k)
  (λh, by rw h; exact dvd_zero _)
  (λkpos, dvd_of_mul_dvd_mul_left (gcd_pos_of_pos_left n (pos_of_dvd_of_pos H1 kpos)) $
    by rw [gcd_mul_lcm, -gcd_mul_right, mul_comm n k];
       exact dvd_gcd (mul_dvd_mul_left _ H2) (mul_dvd_mul_right H1 _))

theorem lcm.assoc (m n k : ℕ) : lcm (lcm m n) k = lcm m (lcm n k) :=
dvd.antisymm
  (lcm_dvd
    (lcm_dvd (dvd_lcm_left m (lcm n k)) (dvd.trans (dvd_lcm_left n k) (dvd_lcm_right m (lcm n k))))
    (dvd.trans (dvd_lcm_right n k) (dvd_lcm_right m (lcm n k))))
  (lcm_dvd
    (dvd.trans (dvd_lcm_left m n) (dvd_lcm_left (lcm m n) k))
    (lcm_dvd (dvd.trans (dvd_lcm_right m n) (dvd_lcm_left (lcm m n) k)) (dvd_lcm_right (lcm m n) k)))

/- coprime -/

@[reducible] def coprime (m n : ℕ) : Prop := gcd m n = 1

lemma gcd_eq_one_of_coprime {m n : ℕ} : coprime m n → gcd m n = 1 :=
λ h, h

theorem coprime_swap {m n : ℕ} (H : coprime n m) : coprime m n :=
eq.trans (gcd_comm m n) H

theorem coprime_of_dvd {m n : ℕ} (H : ∀ k > 1, k ∣ m → ¬ k ∣ n) : coprime m n :=
or.elim (eq_zero_or_pos (gcd m n))
  (λg0, by rw [eq_zero_of_gcd_eq_zero_left g0, eq_zero_of_gcd_eq_zero_right g0] at H; exact false.elim
    (H 2 dec_trivial (dvd_zero _) (dvd_zero _)))
  (λ(g1 : 1 ≤ _), eq.symm $ (lt_or_eq_of_le g1).resolve_left $ λg2,
    H _ g2 (gcd_dvd_left _ _) (gcd_dvd_right _ _))

theorem coprime_of_dvd' {m n : ℕ} (H : ∀ k, k ∣ m → k ∣ n → k ∣ 1) : coprime m n :=
coprime_of_dvd $ λk kl km kn, not_le_of_gt kl $ le_of_dvd zero_lt_one (H k km kn)

theorem dvd_of_coprime_of_dvd_mul_right {m n k : ℕ} (H1 : coprime k n) (H2 : k ∣ m * n) : k ∣ m :=
let t := dvd_gcd (dvd_mul_left k m) H2 in
by rwa [gcd_mul_left, gcd_eq_one_of_coprime H1, mul_one] at t

theorem dvd_of_coprime_of_dvd_mul_left {m n k : ℕ} (H1 : coprime k m) (H2 : k ∣ m * n) : k ∣ n :=
by rw mul_comm at H2; exact dvd_of_coprime_of_dvd_mul_right H1 H2

theorem gcd_mul_left_cancel_of_coprime {k : ℕ} (m : ℕ) {n : ℕ} (H : coprime k n) :
   gcd (k * m) n = gcd m n :=
have H1 : gcd (gcd (k * m) n) k = 1,
by rw [gcd_assoc, gcd_eq_one_of_coprime (coprime_swap H), gcd_one_right],
dvd.antisymm
  (dvd_gcd (dvd_of_coprime_of_dvd_mul_left H1 (gcd_dvd_left _ _)) (gcd_dvd_right _ _))
  (gcd_dvd_gcd_mul_left _ _ _)

theorem gcd_mul_right_cancel_of_coprime (m : ℕ) {k n : ℕ} (H : coprime k n) :
   gcd (m * k) n = gcd m n :=
by rw [mul_comm m k, gcd_mul_left_cancel_of_coprime m H]

theorem gcd_mul_left_cancel_of_coprime_right {k m : ℕ} (n : ℕ) (H : coprime k m) :
   gcd m (k * n) = gcd m n :=
by rw [gcd_comm m n, gcd_comm m (k * n), gcd_mul_left_cancel_of_coprime n H]

theorem gcd_mul_right_cancel_of_coprime_right {k m : ℕ} (n : ℕ) (H : coprime k m) :
   gcd m (n * k) = gcd m n :=
by rw [mul_comm n k, gcd_mul_left_cancel_of_coprime_right n H]

theorem coprime_div_gcd_div_gcd {m n : ℕ} (H : gcd m n > 0) :
  coprime (m / gcd m n) (n / gcd m n) :=
by delta coprime; rw [gcd_div (gcd_dvd_left m n) (gcd_dvd_right m n), nat.div_self H]

theorem not_coprime_of_dvd_of_dvd {m n d : ℕ} (dgt1 : d > 1) (Hm : d ∣ m) (Hn : d ∣ n) :
  ¬ coprime m n :=
λ (co : gcd m n = 1),
not_lt_of_ge (le_of_dvd zero_lt_one $ by rw -co; exact dvd_gcd Hm Hn) dgt1

theorem exists_coprime {m n : ℕ} (H : gcd m n > 0) :
  exists m' n', coprime m' n' ∧ m = m' * gcd m n ∧ n = n' * gcd m n :=
⟨_, _, coprime_div_gcd_div_gcd H,
  (nat.div_mul_cancel (gcd_dvd_left m n)).symm,
  (nat.div_mul_cancel (gcd_dvd_right m n)).symm⟩

theorem coprime_mul {m n k : ℕ} (H1 : coprime m k) (H2 : coprime n k) : coprime (m * n) k :=
eq.trans (gcd_mul_left_cancel_of_coprime n H1) H2

theorem coprime_mul_right {k m n : ℕ} (H1 : coprime k m) (H2 : coprime k n) : coprime k (m * n) :=
coprime_swap (coprime_mul (coprime_swap H1) (coprime_swap H2))

theorem coprime_of_coprime_dvd_left {m k n : ℕ} (H1 : m ∣ k) (H2 : coprime k n) : coprime m n :=
eq_one_of_dvd_one (by delta coprime at H2; rw -H2; exact gcd_dvd_gcd_of_dvd_left _ H1)

theorem coprime_of_coprime_dvd_right {m k n : ℕ} (H1 : n ∣ m) (H2 : coprime k m) : coprime k n :=
coprime_swap $ coprime_of_coprime_dvd_left H1 $ coprime_swap H2

theorem coprime_of_coprime_mul_left {k m n : ℕ} (H : coprime (k * m) n) : coprime m n :=
coprime_of_coprime_dvd_left (dvd_mul_left _ _) H

theorem coprime_of_coprime_mul_right {k m n : ℕ} (H : coprime (m * k) n) : coprime m n :=
coprime_of_coprime_dvd_left (dvd_mul_right _ _) H

theorem coprime_of_coprime_mul_left_right {k m n : ℕ} (H : coprime m (k * n)) : coprime m n :=
coprime_of_coprime_dvd_right (dvd_mul_left _ _) H

theorem coprime_of_coprime_mul_right_right {k m n : ℕ} (H : coprime m (n * k)) : coprime m n :=
coprime_of_coprime_dvd_right (dvd_mul_right _ _) H

theorem comprime_one_left : ∀ n, coprime 1 n := gcd_one_left

theorem comprime_one_right : ∀ n, coprime n 1 := gcd_one_right

theorem coprime_pow_left {m k : ℕ} (n : ℕ) (H1 : coprime m k) : coprime (m ^ n) k :=
nat.rec_on n (comprime_one_left _) (λn IH, coprime_mul IH H1)

theorem coprime_pow_right {m k : ℕ} (n : ℕ) (H1 : coprime k m) : coprime k (m ^ n) :=
coprime_swap $ coprime_pow_left n $ coprime_swap H1

theorem coprime_pow {k l : ℕ} (m n : ℕ) (H1 : coprime k l) : coprime (k ^ m) (l ^ n) :=
coprime_pow_right _ $ coprime_pow_left _ H1

theorem exists_eq_prod_and_dvd_and_dvd {m n k : nat} (H : k ∣ m * n) :
  ∃ m' n', k = m' * n' ∧ m' ∣ m ∧ n' ∣ n :=
or.elim (eq_zero_or_pos (gcd k m))
  (λg0, ⟨0, n,
    by rw [zero_mul, eq_zero_of_gcd_eq_zero_left g0],
    by rw [eq_zero_of_gcd_eq_zero_right g0]; apply dvd_zero, dvd_refl _⟩)
  (λgpos, let hd := (nat.mul_div_cancel' (gcd_dvd_left k m)).symm in
     ⟨_, _, hd, gcd_dvd_right _ _,
    dvd_of_mul_dvd_mul_left gpos $ by rw [-hd, -gcd_mul_right]; exact
      dvd_gcd (dvd_mul_right _ _) H⟩)

end nat
