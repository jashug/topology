Require Import QArith Qcanon.

Require Import FunctionalExtensionality.

(** Non-negative rational numbers *)

Record Qnn :=
  { qnn :> Qc
  ; nonneg : qnn >= 0
  }.

Local Open Scope Z.

Theorem Zle_irrel {x y : Z} (prf1 prf2 : x <= y) :
  prf1 = prf2. 
Proof. unfold Z.le in *.
apply functional_extensionality.
intros z. contradiction.
Qed.

Local Close Scope Z.
Local Close Scope Qc.

Definition Qle_irrel {x y : Q} (prf1 prf2 : x <= y)
  : prf1 = prf2 := Zle_irrel prf1 prf2.

Local Open Scope Qc.
Definition Qcle_irrel {x y : Qc} (prf1 prf2 : x <= y)
  : prf1 = prf2 := Qle_irrel prf1 prf2.

Definition Qnnle (x y : Qnn) : Prop := x <= y.
Definition Qnnge (x y : Qnn) : Prop := x >= y.
Definition Qnnlt (x y : Qnn) : Prop := x < y.
Definition Qnngt (x y : Qnn) : Prop := x > y.

Definition Qnneq (x y : Qnn) : Prop := qnn x = qnn y.

Definition Qnnplus (x y : Qnn) : Qnn.
Proof.
refine ({| qnn := x + y |}).
replace 0 with (0 + 0) by field.
apply Qcplus_le_compat; destruct x, y; assumption.
Defined.

Definition Qnnmult (x y : Qnn) : Qnn.
Proof.
refine ({| qnn := x * y |}).
replace 0 with (0 * y) by field.
apply Qcmult_le_compat_r; apply nonneg.
Defined.

Definition Qnnzero : Qnn := Build_Qnn 0%Qc (Qcle_refl 0%Qc).

Definition Qnnone : Qnn.
Proof. apply (Build_Qnn 1%Qc). unfold Qle. simpl.
unfold Z.le. simpl. congruence.
Defined.

Theorem Qnneq_prop {x y : Qnn} :
  Qnneq x y -> x = y.
Proof. intros. destruct x, y. unfold Qnneq in H. simpl in H.
induction H. replace nonneg0 with nonneg1. reflexivity.
apply Qcle_irrel.
Qed.

Infix "<=" := Qnnle   : Qnn_scope.
Infix ">=" := Qnnge   : Qnn_scope.
Infix "<"  := Qnnlt   : Qnn_scope.
Infix ">"  := Qnngt   : Qnn_scope.
Infix "+"  := Qnnplus : Qnn_scope.
Infix "*"  := Qnnmult : Qnn_scope.
Infix "==" := Qnneq   : Qnn_scope.

Notation "'0'" := Qnnzero : Qnn_scope.
Notation "'1'" := Qnnone  : Qnn_scope.

Require Import Ring.

Local Close Scope Q.
Local Close Scope Qc.

Delimit Scope Qnn_scope with Qnn.

Local Open Scope Qnn.

(** Non-negative rational numbers form a semiring *)
Theorem Qnnsrt : semi_ring_theory 0 1
  Qnnplus Qnnmult eq.
Proof.
constructor; intros;
  match goal with
  | [  |- _ = _ ] => apply Qnneq_prop; unfold Qnneq
  end;
  try solve[simpl; field].
Qed.

Add Ring Qnn_Ring : Qnnsrt.

Theorem Qnn_zero_prop {x : Qnn} :
  x <= 0 -> x = Qnnzero.
Proof.
intros. apply Qnneq_prop. unfold Qnneq.
unfold Qnnzero. simpl. apply Qcle_antisym.
assumption. apply nonneg.
Qed.

Lemma Qnnle_refl (x : Qnn) : x <= x.
Proof. apply Qcle_refl. Qed.

Lemma Qnnle_trans {x y z : Qnn}
  : x <= y -> y <= z -> x <= z.
Proof. intros. eapply Qcle_trans; eassumption. Qed.

Lemma Qnnle_lt_trans : forall x y z : Qnn
  , x <= y -> y < z -> x < z.
Proof. intros. eapply Qcle_lt_trans; eassumption. Qed.

Lemma Qnnlt_le_trans: forall x y z : Qnn
  , x < y -> y <= z -> x < z.
Proof. intros. eapply Qclt_le_trans; eassumption. Qed.

Lemma Qnnmult_le_compat {x y x' y' : Qnn}
  : x <= x' -> y <= y' -> x * y <= x' * y'.
Proof. intros.
assert (x * y <= x' * y).
apply Qcmult_le_compat_r. assumption. apply nonneg.
eapply Qnnle_trans. eassumption.
replace (x' * y) with (y * x') by ring.
replace (x' * y') with (y' * x') by ring.
apply Qcmult_le_compat_r. assumption. apply nonneg.
Qed.

(** Nonnegative lower reals *)
(* These guys are interesting because we can have proofy
   bits in them. For example, we can create a real number
   which is 0 if P = NP and 1 if P /= NP. *)
Record LPReal :=
  { lbound :> Qnn -> Prop
  ; zeroed : lbound 0
  ; dclosed : forall q, lbound q -> forall q', q' <= q -> lbound q'
  }.

Definition LPRle (r s : LPReal) : Prop :=
  forall q, r q -> s q.

Definition LPRge (r s : LPReal) : Prop :=
  forall q, s q -> r q.

Definition LPRle_refl (r : LPReal) : LPRle r r :=
  fun _ p => p.

Definition LPRle_trans {r s t : LPReal} 
  (rs : LPRle r s) (st : LPRle s t) : LPRle r t :=
  fun q prf => (st q (rs q prf)).

Definition LPReq (r s : LPReal) : Prop :=
  LPRle r s /\ LPRle s r.

Lemma LPReq_refl (x : LPReal) : LPReq x x.
Proof. split; apply LPRle_refl. Qed.

Lemma LPReq_trans (x y z : LPReal) 
  : LPReq x y -> LPReq y z -> LPReq x z.
Proof. intros. destruct H; destruct H0; split;
  eapply LPRle_trans; eassumption.
Qed.

Lemma LPReq_compat_backwards (x y : LPReal) : x = y -> LPReq x y.
Proof. intros H; induction H; apply LPReq_refl. Qed.

Definition LPRQnn (q : Qnn) : LPReal.
Proof.
refine (
  {| lbound := fun q' => (q' <= q)%Qnn |}
).
- apply nonneg.
- intros. subst. eapply Qle_trans; eassumption.
Defined.

Definition LPRplus (x y : LPReal) : LPReal.
Proof.
refine (
  {| lbound := fun q => exists a b,
     lbound x a /\ lbound y b /\ (q <= a + b)%Qnn |}
).
- exists 0. exists 0. split. apply zeroed. split.
  apply zeroed. replace (0 + 0) with 0 by ring.
  apply Qnnle_refl.
- intros.
  destruct H as [a [b [xa [yb sum]]]].
  exists a. exists b. intuition. eapply Qnnle_trans; eassumption.
Defined.

Definition LPRmult (x y : LPReal) : LPReal.
Proof.
refine (
  {| lbound := fun q => exists a b,
     lbound x a /\ lbound y b /\ (q <= a * b)%Qnn |}
).
- exists 0. exists 0. split. apply zeroed. split.
  apply zeroed.
  replace (0 * 0) with 0 by ring. 
  apply Qnnle_refl.
- intros.
  destruct H as [a [b [xa [yb sum]]]].
  exists a. exists b. intuition. eapply Qnnle_trans; eassumption.
Defined.

Lemma LPReq_prop : forall r s, LPReq r s ->
  forall q, lbound r q <-> lbound s q.
Proof.
intros. destruct H. split. apply H. apply H0.
Qed.

Lemma LPReq_compat_OK 
  (propext : forall (x y : Prop), (x <-> y) -> x = y)
  (proof_irrel : forall (P : Prop) (x y : P), x = y)
  : forall r s, LPReq r s -> r = s. 
Proof.
intros. pose proof H as eq. destruct H.
unfold LPRle in *.
assert (lbound r = lbound s).
apply functional_extensionality.
intros q. apply propext. apply LPReq_prop.
assumption.
destruct r, s.
simpl in *. induction H1.
pose proof (proof_irrel _ zeroed0 zeroed1).
induction H1.
pose proof (proof_irrel _ dclosed0 dclosed1).
induction H1.
reflexivity.
Qed.

Axiom LPReq_compat : forall r s, LPReq r s -> r = s.

Theorem LPRsrt : semi_ring_theory (LPRQnn 0) (LPRQnn 1)
  LPRplus LPRmult eq.
Proof.
constructor; intros; apply LPReq_compat; unfold LPReq, LPRle;
repeat match goal with
| [ |- _ /\ _ ] => split
| [ |- forall _, _] => intros
| [ H : lbound (LPRQnn _) _ |- _ ] => simpl in H
| [ H : lbound (LPRplus _ _) _ |- _ ] => destruct H
| [ H : lbound (LPRmult _ _) _ |- _ ] => destruct H
| [ H : exists x, _ |- _ ] => destruct H
| [ H : _ /\ _ |- _ ] => destruct H
end.
- eapply dclosed; try eassumption.
  assert (x = 0).
  apply Qnn_zero_prop. assumption.
  subst.
  replace (0 + x0) with x0 in H1 by ring.
  assumption.
- simpl. exists 0. exists q. split. apply Qnnle_refl. split. assumption.
  replace (0 + q) with q by ring. apply Qnnle_refl.
- simpl. do 2 eexists. repeat split; try eassumption.
  replace (x0 + x) with (x + x0) by ring.
  assumption.
- simpl. do 2 eexists. repeat split; try eassumption.
  replace (x0 + x) with (x + x0) by ring.
  assumption.
- simpl. do 2 eexists. split.
  do 2 eexists. split. eassumption. split. eassumption.
  eapply Qnnle_refl.
  split. eassumption. eapply Qnnle_trans. eassumption.
  rewrite <- (SRadd_assoc Qnnsrt).
  apply Qcplus_le_compat. apply Qcle_refl.
  assumption.
- simpl. do 2 eexists. split. eassumption.
  split. do 2 eexists. split. eassumption. split. eassumption.
  eapply Qnnle_refl.
  eapply Qnnle_trans. eassumption.
  rewrite (SRadd_assoc Qnnsrt).
  apply Qcplus_le_compat. assumption. apply Qcle_refl.
- eapply dclosed. eassumption.
  eapply Qnnle_trans. eassumption.
  replace x0 with (1 * x0) at 2 by ring.
  apply Qcmult_le_compat_r. assumption.
  apply nonneg.
- simpl. exists 1. exists q. split. apply Qnnle_refl.
  split. assumption. replace (1 * q) with q by ring.
  apply Qnnle_refl.
- simpl. apply Qnn_zero_prop in H. subst.
  replace (0 * x0) with 0 in H1 by ring. assumption.
- apply Qnn_zero_prop in H. subst.
  simpl. exists 0. exists 0. split. apply Qnnle_refl. split.
  apply zeroed. replace (0 * 0) with 0 by ring.
  apply Qnnle_refl.
- simpl. do 2 eexists. split. eassumption. split.
  eassumption. replace (x0 * x) with (x * x0) by ring.
  assumption.
- simpl. do 2 eexists. split. eassumption. split.
  eassumption. replace (x0 * x) with (x * x0) by ring.
  assumption.
- simpl. do 2 eexists. split. do 2 eexists. split.
  eassumption. split. eassumption. eapply Qnnle_refl.
  split. eassumption. eapply Qnnle_trans. eassumption.
  rewrite <- (SRmul_assoc Qnnsrt).
  rewrite (SRmul_comm Qnnsrt).
  replace (x * (x1 * x2)) with ((x1 * x2) * x) by ring.
  apply Qcmult_le_compat_r. assumption.
  apply nonneg.
- simpl. do 2 eexists. split. eassumption. split. 
  do 2 eexists. split.
  eassumption. split. eassumption. eapply Qnnle_refl.
  eapply Qnnle_trans. eassumption.
  rewrite (SRmul_assoc Qnnsrt).
  apply Qcmult_le_compat_r. assumption.
  apply nonneg.
- simpl. do 2 eexists. split. do 2 eexists. split.
  eassumption. split. eassumption. apply Qnnle_refl.
  split. do 2 eexists. split. eassumption. split.
  eassumption. apply Qnnle_refl.
  rewrite <- (SRdistr_l Qnnsrt).
  eapply Qnnle_trans. eassumption.
  apply Qcmult_le_compat_r. eassumption. apply nonneg.
- destruct (Qccompare x2 x4) eqn:comp; 
  ((simpl; do 2 eexists; split);
   [ do 2 eexists; split; 
     [ eassumption 
     | split; [ eassumption | apply Qcle_refl ] ]
   | split ]).

  eassumption. eapply Qnnle_trans. eassumption.
  rewrite (SRdistr_l Qnnsrt).
  apply Qcplus_le_compat.
  apply Qceq_alt in comp. simpl. rewrite <- comp.
  assumption. assumption.

  apply H2. eapply Qnnle_trans. eassumption.
  rewrite (SRdistr_l Qnnsrt).
  apply Qcplus_le_compat.
  apply Qclt_alt in comp.
  apply Qclt_le_weak in comp.
  eapply Qcle_trans. eassumption.
  replace (x1 * x2) with (x2 * x1) by ring.
  replace (x1 * x4) with (x4 * x1) by ring.
  eapply Qcmult_le_compat_r. assumption. apply nonneg.
  assumption.

  apply H4. eapply Qnnle_trans. eassumption.
  rewrite (SRdistr_l Qnnsrt).
  apply Qcplus_le_compat. eassumption.
  eapply Qnnle_trans. eassumption.
  replace (x3 * x2) with (x2 * x3) by ring.
  replace (x3 * x4) with (x4 * x3) by ring.
  apply Qcmult_le_compat_r.
  apply Qcgt_alt in comp.
  apply Qclt_le_weak in comp. assumption. apply nonneg.
Qed.

Add Ring LPR_Ring : LPRsrt.

Infix "<=" := LPRle : LPR_scope.
Infix ">=" := LPRge : LPR_scope.
Infix "+" := LPRplus : LPR_scope.
Infix "*" := LPRmult : LPR_scope.

Notation "'0'" := (LPRQnn 0) : LPR_scope.
Notation "'1'" := (LPRQnn 1) : LPR_scope.

Delimit Scope LPR_scope with LPR.

Local Open Scope LPR.

Theorem LPRplus_le_compat {x y z t : LPReal}
  : (x <= y) -> (z <= t) -> (x + z <= y + t).
Proof. intros. unfold LPRle in *. intros.
simpl in *. destruct H1 as [a [b [H1 [H2 H3]]]].
do 2 eexists. split. apply H. eassumption. split. apply H0.
eassumption. assumption.
Qed.

Theorem LPRmult_le_compat {x x' y y' : LPReal}
  : x <= x' -> y <= y' -> x * y <= x' * y'.
Proof.
intros. unfold LPRle in *. intros.
simpl in *. destruct H1 as [a [b [H1 [H2 H3]]]].
do 2 eexists. split. apply H. eassumption. split.
apply H0. eassumption. assumption.
Qed.

Theorem LPRzero_min (r : LPReal) : 0 <= r.
Proof.
unfold LPRle. intros q Hq.
simpl in Hq. eapply dclosed.
apply zeroed. assumption.
Qed.

Definition LPRsup {A : Type} (f : A -> LPReal)
  : LPReal.
Proof.
refine (
  {| lbound := fun q => q = 0%Qnn \/ exists (idx : A), f idx q |}
).
- intros. left. reflexivity.
- intros. destruct H. subst. left. apply Qnn_zero_prop.
  assumption.
  right. destruct H. exists x. apply dclosed with q. assumption.
  assumption.
Defined.

Definition LPRinfinity : LPReal.
Proof. refine (
  {| lbound := fun q => True |}
); trivial.
Defined.

Theorem LPRinfinity_max (r : LPReal) : r <= LPRinfinity.
Proof.
unfold LPRle. intros. simpl. constructor.
Qed.

Lemma LPRsup_ge {A : Type} {f : A -> LPReal} {a : A} 
  : f a <= LPRsup f.
Proof. unfold LPRle. simpl. intros. right. eexists. eassumption.
Qed.

Lemma LPRsup_le {A : Type} {f : A -> LPReal} {x : LPReal} 
  : (forall (a : A), (f a <= x)) -> LPRsup f <= x.
Proof. intros. unfold LPRle in *. simpl. intros. destruct H0.
subst. apply zeroed. destruct H0. apply H with x0.
assumption.
Qed.

Lemma LPRsup_ge2 {A : Type} {f : A -> LPReal} {x : LPReal} 
  : (exists a, x <= f a) -> x <= LPRsup f.
Proof. intros. destruct H. eapply LPRle_trans. eassumption. apply LPRsup_ge.
Qed.

Lemma LPRsup_prop {A : Type} {f : A -> LPReal} {x : LPReal}
  : (forall (a : A), (f a <= x))
  -> (exists (a : A), x <= f a)
  -> LPRsup f = x.
Proof. intros. apply LPReq_compat. split. apply LPRsup_le.
assumption. eapply LPRsup_ge2. eassumption.
Qed.

Lemma LPRsup_monotonic {A : Type} (f g : A -> LPReal)
  : (forall (a : A), f a <= g a) -> LPRsup f <= LPRsup g.
Proof.
intros mono. unfold LPRle in *.
intros. simpl in *. destruct H. left. assumption.
destruct H. right. exists x. apply mono. assumption.
Qed.

Lemma LPRsup_eq_pointwise {A : Type} (f g : A -> LPReal)
  : (forall (a : A), f a = g a) -> LPRsup f = LPRsup g.
Proof.
intros mono.
apply LPReq_compat. split; apply LPRsup_monotonic;
intros; rewrite mono; apply LPRle_refl.
Qed.

Lemma LPRsup_sum {A : Type} (f g : A -> LPReal)
  : LPRsup (fun x => f x + g x) <= LPRsup f + LPRsup g.
Proof. apply LPRsup_le. intros a.
apply LPRplus_le_compat; apply LPRsup_ge.
Qed.

Lemma LPRsup_sum_lattice {A : Type} (f g : A -> LPReal)
  (le : A -> A -> Prop)
  (max : A -> A -> A)
  (maxL  : forall (a b : A), le a (max a b))
  (maxR  : forall (a b : A), le b (max a b))
  (monof : forall n m, le n m -> f n <= f m)
  (monog : forall n m, le n m -> g n <= g m)
  : LPRsup (fun x => f x + g x) = LPRsup f + LPRsup g.
Proof.
apply LPReq_compat. split; [apply LPRsup_sum | ].
unfold LPRle. intros. simpl in *.
destruct H as [a [b [pa [pb ab]]]]. destruct pa; destruct pb.
subst. left. replace (0 + 0)%Qnn with 0%Qnn in ab by ring.
apply Qnn_zero_prop. assumption. destruct H0.
right. exists x. do 2 eexists. split. apply zeroed. split.
eassumption. subst. assumption. destruct H.
right. exists x. do 2 eexists. split. eassumption. split. 
apply zeroed. subst. assumption.
destruct H; destruct H0. right. exists (max x x0).
pose proof (monof x (max x x0) (maxL x x0)).
do 2 eexists. split. apply H1. eassumption. split.
pose proof (monog x0 (max x x0) (maxR x x0)).
apply H2. eassumption. assumption.
Qed.

Lemma LPRsup_nat_ord (f g : nat -> LPReal)
  : (forall n m, (n <= m)%nat -> f n <= f m)
  -> (forall n m, (n <= m)%nat -> g n <= g m)
  -> LPRsup (fun x => f x + g x) = LPRsup f + LPRsup g.
Proof. intros. eapply LPRsup_sum_lattice; try eassumption.
apply Max.le_max_l.  apply Max.le_max_r.
Qed.

Definition LPRmax (x y : LPReal) : LPReal.
Proof. refine (
  {| lbound := fun q => x q \/ y q |}
).
- left. apply zeroed.
- intros. destruct H; [left | right]; eapply dclosed; eassumption.
Defined.

Lemma LPRmax_le_and {x y z : LPReal} 
  : x <= y -> y <= z -> LPRmax x y <= z.
Proof. intros.
unfold LPRle; simpl in *; intros; intuition.
Qed.

Lemma LPRmax_le_or {x y z : LPReal} 
  : z <= x \/ z <= y -> z <= LPRmax x y.
Proof. intros.
unfold LPRle; simpl in *; intros; intuition.
Qed.

Definition LPRmin (x y : LPReal) : LPReal.
Proof. refine (
  {| lbound := fun q => x q /\ y q |}
).
- split; apply zeroed.
- intros. destruct H; split; eapply dclosed; eassumption.
Defined.

Theorem LPRle_antisym {x y : LPReal}
  : x <= y -> y <= x -> x = y.
Proof.
intros. apply LPReq_compat. split; assumption.
Qed.

(* constant function *)
Definition K {A} (x : A) {B} (y : B) := x.

(* Here's the analogy:
  Valuation : Measure :: constructive logic : classical logic

A good reference:

Claire Jones. Probabilistic Nondeterminism. 1990. Phd Thesis.
https://www.era.lib.ed.ac.uk/handle/1842/413
*)

Record Valuation {A : Type} :=
  { val :> (A -> Prop) -> LPReal
  ; strict : val (K False) = 0
  ; monotonic : forall (U V : A -> Prop), (forall z, U z -> V z)
              -> val U <= val V
  ; modular : forall {U V},
     val U + val V = val (fun z => U z /\ V z) + val (fun z => U z \/ V z)
  }.

Arguments Valuation : clear implicits.

Definition pointwise {A B : Type} (cmp : B -> B -> Prop)
  (f g : A -> B) : Prop := forall (a : A), cmp (f a) (g a).

(** An inductive definition of simple functions. I hesitate to
    call them functions because they aren't necessarily computable.
    I'm using "max" instead of "plus", because I believe it's
    equivalent, and makes formulating certain things easier. *)
Inductive Simple {A : Type} :=
  | SStep : LPReal -> (A -> Prop) -> Simple
  | SMax : Simple -> Simple -> Simple.

Arguments Simple : clear implicits.

(* Definition of how to integrate simple functions *)
Fixpoint SimpleIntegral {A : Type} (mu : (A -> Prop) -> LPReal) 
  (s : Simple A) : LPReal := match s with
  | SStep c P => c * mu P
  | SMax f g => LPRmax (SimpleIntegral mu f) (SimpleIntegral mu g)
  end.

(* An real number which is an indicator for a logical proposition.
   It is 0 if P is false and 1 if P is true. Without a proof or
   refutation of P, you will not know which! *)
Definition LPRindicator (P : Prop) : LPReal.
Proof. refine 
( {| lbound := fun q => q = 0%Qnn \/ (P /\ (q <= 1)%Qnn) |}).
- left. reflexivity.
- intros. destruct H.
  + left. subst. apply Qnneq_prop. unfold Qnneq. 
     apply Qcle_antisym. assumption. apply nonneg.
  + right. destruct H. split. assumption. eapply Qnnle_trans;
    eassumption.
Defined.

Lemma LPRind_bounded (P : Prop) : LPRindicator P <= 1.
Proof.
unfold LPRle; intros; simpl in *. destruct H. 
subst. apply nonneg. destruct H; assumption.
Qed.

Lemma LPRind_imp (P Q : Prop) (f : P -> Q)
  : LPRindicator P <= LPRindicator Q.
Proof.
unfold LPRle; intros; simpl in *. destruct H.
left. assumption. right. destruct H. split; auto.
Qed.

Lemma LPRind_true (P : Prop) : P -> LPRindicator P = 1.
Proof. intros. apply LPReq_compat.
split.
- apply LPRind_bounded.
- unfold LPRle; intros; simpl in *. right. split; assumption.
Qed.

Lemma LPRind_false (P : Prop) : ~ P -> LPRindicator P = 0.
Proof. intros. apply LPReq_compat. 
split.
- unfold LPRle; intros; simpl in *. 
  destruct H0. subst. apply Qcle_refl. destruct H0. contradiction.
- apply LPRzero_min.
Qed.

Hint Resolve Qnnle_refl.

Lemma LPRind_scale_le {P : Prop} {x y : LPReal}
  : (P -> x <= y) -> LPRindicator P * x <= y.
Proof.
intros. unfold LPRle; simpl in *; intros.
destruct H0 as [a [b [pa [pb ab]]]].
destruct pa. subst. assert (q = 0%Qnn).
apply Qnn_zero_prop. replace (0 * b)%Qnn with 0%Qnn in ab by ring.
assumption. subst. apply zeroed. destruct H0.
apply H in H0. apply H0. eapply dclosed. eassumption.
eapply Qnnle_trans. eassumption.
replace b with (1 * b)%Qnn at 2 by ring.
apply Qnnmult_le_compat. assumption. apply Qnnle_refl.
Qed.

(*
Lemma LPRind_scale_ge {P : Prop} {x y : LPReal}
  : (P -> x <= y) -> x <= y * LPRindicator P.
Proof.
intros. unfold LPRle; simpl in *; intros.
do 2 eexists.
destruct H0 as [a [b [pa [pb ab]]]].
destruct pa. subst. assert (q = 0%Qnn).
apply Qnn_zero_prop. replace (0 * b)%Qnn with 0%Qnn in ab by ring.
assumption. subst. apply zeroed. destruct H0.
apply H in H0. apply H0. eapply dclosed. eassumption.
eapply Qnnle_trans. eassumption.
replace b with (1 * b)%Qnn at 2 by ring.
apply Qnnmult_le_compat. assumption. apply Qnnle_refl.
Qed.
*)

Lemma LPRind_mult {U V : Prop}
  : LPRindicator (U /\ V) = LPRindicator U * LPRindicator V.
Proof.
apply LPReq_compat. 
split; unfold LPRle; simpl in *; intros.
- destruct H.
  subst. exists 0%Qnn. exists 0%Qnn. intuition. 
  replace (0 * 0)%Qnn with 0%Qnn by ring. apply Qnnle_refl.
  exists 1%Qnn. exists 1%Qnn. intuition.
- destruct H as [a [b [pa [pb ab]]]].
  intuition; subst. left.  apply Qnn_zero_prop. assumption.
  left. apply Qnn_zero_prop. 
  replace (0 * b)%Qnn with 0%Qnn in ab by ring.
  assumption.
  left. apply Qnn_zero_prop.
  replace (a * 0)%Qnn with 0%Qnn in ab by ring.
  assumption.
  right. intuition. replace 1%Qnn with (1 * 1)%Qnn by ring.
  eapply Qnnle_trans. eassumption.
  apply Qnnmult_le_compat; assumption.
Qed.

Lemma LPRind_max {U V : Prop}
  : LPRindicator (U \/ V) = LPRmax (LPRindicator U) (LPRindicator V).
Proof.
apply LPReq_compat.
split; unfold LPRle; simpl in *; intros; intuition.
Qed.

Lemma LPRind_min {U V : Prop}
  : LPRindicator (U /\ V) = LPRmin (LPRindicator U) (LPRindicator V).
Proof.
apply LPReq_compat.
split; unfold LPRle; simpl in *; intros; intuition.
Qed.

Lemma LPRind_modular {U V : Prop} :
   LPRindicator U + LPRindicator V =
   LPRindicator (U /\ V) + LPRindicator (U \/ V).
Proof.
apply LPReq_compat; split; unfold LPRle; intros q H;
  destruct H as [x [y [px [py xy]]]]; 
  destruct px; subst; destruct py; subst; simpl.
- exists 0%Qnn. exists 0%Qnn. intuition.
- exists 0%Qnn. exists 1%Qnn. intuition.
  replace (0 + 1)%Qnn with 1%Qnn by ring.
  replace (0 + y)%Qnn with y%Qnn in xy by ring.
  eapply Qnnle_trans; eassumption.
- exists 0%Qnn. exists 1%Qnn. intuition. 
  replace (0 + 1)%Qnn with 1%Qnn by ring.
  replace (x + 0)%Qnn with x%Qnn in xy by ring.
  eapply Qnnle_trans; eassumption.
- exists 1%Qnn. exists 1%Qnn. intuition. eapply Qnnle_trans.
  eassumption. apply Qcplus_le_compat; assumption.
- exists 0%Qnn. exists 0%Qnn. intuition.
- intuition. 
  exists 1%Qnn. exists 0%Qnn. intuition. 
  replace (1 + 0)%Qnn with 1%Qnn by ring.
  replace (0 + y)%Qnn with y%Qnn in xy by ring.
  eapply Qnnle_trans; eassumption.
  exists 0%Qnn. exists 1%Qnn. intuition.
  replace (0 + 1)%Qnn with 1%Qnn by ring.
  replace (0 + y)%Qnn with y%Qnn in xy by ring.
  eapply Qnnle_trans; eassumption.
- exists 1%Qnn. exists 1%Qnn. intuition.
  eapply Qnnle_trans. eassumption.
  apply Qcplus_le_compat. assumption.
  apply nonneg.
- exists 1%Qnn. exists 1%Qnn. intuition;
  (eapply Qnnle_trans; [ eassumption
  | apply Qcplus_le_compat; assumption ]).
Qed.

(* The equivalent of a Dirac delta for a given point.
   Called `unit` because Valuations form a mona, and
   this is the unit. *)
Definition unit {A : Type} (a : A) : Valuation A.
Proof. refine (
 {| val := fun P => LPRindicator (P a) |}
); intros.
- apply LPReq_compat. unfold LPReq. split.
  unfold LPRle. intros.
  destruct H. subst. simpl. apply Qcle_refl.
  destruct H. destruct H. apply LPRzero_min.
- unfold LPRle. intros q Hq. destruct Hq.
  left. assumption. right. destruct H0.
  split. apply H. assumption. assumption.
- apply LPRind_modular.
Defined.

(* Here we consider a Simple as a pointwise function, in a sense,
   by integrating against a Dirac delta. *)
Definition SimpleEval {A : Type} (f : Simple A) (x : A) : LPReal :=
  SimpleIntegral (val (unit x)) f.

Record IntegralT (A : Type) :=
  { integral : (A -> LPReal) -> Valuation A -> LPReal
  ; int_simple_sup : forall {f : A -> LPReal} {mu : Valuation A},
      integral f mu = LPRsup (fun (pr : { s | pointwise LPRle (SimpleEval s) f}) =>
      SimpleIntegral mu (proj1_sig pr))
  ; int_simple_ge : forall {s : Simple A} {f : A -> LPReal} {mu : Valuation A},
      pointwise LPRle f (SimpleEval s)
    -> integral f mu <= SimpleIntegral mu s
  ; int_monotonic : forall {f g : A -> LPReal}
     , pointwise LPRle f g -> forall (mu : Valuation A)
     , integral f mu <= integral g mu
  ; int_adds : forall {f g : A -> LPReal} {mu : Valuation A}
     , integral f mu + integral g mu = integral (fun x => f x + g x) mu
  ; int_scales : forall {f : A -> LPReal} {c : LPReal} {mu : Valuation A}
     , c * integral f mu = integral (fun x => c * f x) mu
  }.

Axiom integration : forall (A : Type), IntegralT A.

Lemma int_simple_le {A : Type} :
forall {s : Simple A} {f : A -> LPReal} {mu : Valuation A},
      pointwise LPRle (SimpleEval s) f
    ->  SimpleIntegral mu s <= integral _ (integration A) f mu.
Proof. intros.
pose (exist (fun s' => pointwise LPRle (SimpleEval s') f) s H).
eapply LPRle_trans. Focus 2.
rewrite int_simple_sup. eapply LPRsup_ge.
instantiate (1 := s0). simpl.
apply LPRle_refl.
Qed.

Lemma int_simple {A : Type} {s : Simple A} {mu : Valuation A}
  : integral _ (integration A) (SimpleEval s) mu = SimpleIntegral mu s.
Proof.
apply LPReq_compat.
split; [apply int_simple_ge | apply int_simple_le]
  ; unfold pointwise; intros a; apply LPRle_refl.
Qed.

(** Pushforward of a measure, i.e., map a function over a measure *)
Definition map {A B : Type} (f : A -> B) (v : Valuation A)
  : Valuation B.
Proof. refine (
  {| val := fun prop => val v (fun x => prop (f x)) |}
); intros.
- apply strict.
- apply monotonic. auto.
- apply modular; auto.
Defined.

Lemma qredistribute : forall andLq andRq orLq orRq,
    andLq + andRq + (orLq + orRq)
 = (andLq + orLq) + (andRq + orRq).
Proof. intros. ring. Qed.

Lemma LPRplus_eq_compat : forall x y x' y',
  x = x' -> y = y' -> x + y = x' + y'.
Proof. intros. subst. reflexivity. Qed.

(** The sum of two valuations *)
Definition add {A : Type} (ValL ValR : Valuation A) : Valuation A.
Proof. refine (
  {| val := fun P => ValL P + ValR P |}
); intros.
- rewrite strict. rewrite strict. ring.
- apply LPRplus_le_compat; apply monotonic; assumption.
- rewrite qredistribute. 
  rewrite (qredistribute (ValL (fun z => U z /\ V z))).
  apply LPRplus_eq_compat; apply modular.
Defined.

Lemma LPRmult_eq_compat : forall x y x' y',
  x = x' -> y = y' -> x * y = x' * y'.
Proof. intros. subst. reflexivity. Qed.

(* Scale a valuation by a constant *)
Definition scale {A : Type} (c : LPReal) 
  (Val : Valuation A) : Valuation A.
Proof. refine (
  {| val := fun P => c * Val P |}
); intros.
- rewrite strict. ring.
- apply LPRmult_le_compat. apply LPRle_refl.
  apply monotonic; assumption.
- replace (c * Val U + c * Val V) with (c * (Val U + Val V)) by ring.
  replace (c * Val _ + c * Val _) 
  with (c * (Val (fun z : A => U z /\ V z) + Val (fun z : A => U z \/ V z))) by ring.
  apply LPRmult_eq_compat. reflexivity.
  apply modular.
Qed.

(* The valuation which is 0 everywhere *)
Definition zeroVal {A : Type} : Valuation A.
Proof. refine (
  {| val := fun P => 0 |}
).
- reflexivity.
- intros. apply LPRle_refl.
- intros. reflexivity.
Defined.

Definition Valle {A : Type} (val1 val2 : Valuation A) : Prop :=
  forall (P : A -> Prop), val1 P <= val2 P.

Lemma Valle_refl {A : Type} (val : Valuation A) : Valle val val.
Proof. unfold Valle. intros. apply LPRle_refl. Qed.

Lemma Valle_trans {A : Type} (x y z : Valuation A)
  : Valle x y -> Valle y z -> Valle x z.
Proof. intros. unfold Valle in *. intros P.
eapply LPRle_trans. apply H. apply H0.
Qed.

Definition Valeq {A : Type} (val1 val2 : Valuation A) : Prop :=
  forall (P : A -> Prop), val1 P = val2 P.

Lemma Valle_antisym {A : Type} (x y : Valuation A)
  : Valle x y -> Valle y x -> Valeq x y.
Proof. intros. unfold Valle, Valeq in *. intros.
apply LPRle_antisym. apply H. apply H0.
Qed.

Lemma Valeq_compat_OK 
  (proof_irrel : forall (P : Prop) (x y : P), x = y)
  { A : Type }
  : forall (mu nu : Valuation A), Valeq mu nu -> mu = nu. 
Proof.
intros.
unfold Valeq in *.
destruct mu, nu. simpl in *.
assert (val0 = val1).
apply functional_extensionality. assumption.
induction H0.
pose proof (proof_irrel _ strict0 strict1).
induction H0.
pose proof (proof_irrel _ monotonic0 monotonic1).
induction H0.
pose proof (proof_irrel _ modular0 modular1).
induction H0.
reflexivity.
Qed.

Axiom Valeq_compat : forall (A : Type) (mu nu : Valuation A)
  , Valeq mu nu -> mu = nu.

Lemma Valplus_comm {A : Type} : forall {x y : Valuation A}
  , add x y = add y x.
Proof.
intros. apply Valeq_compat.
unfold Valeq. intros. simpl. ring.
Qed.

Lemma integral_zero {A : Type} : forall {mu : Valuation A} (c : LPReal)
  , integral A (integration A) (SimpleEval (SStep c (K False))) mu = 0.
Proof.
intros.
rewrite int_simple. simpl. 
replace (mu (K False)) with 0. ring. symmetry. apply strict.
Qed.

(* If two functions are equal at every point, then
   they integrate to the same thing. *)
Lemma int_pointwise_eq {A : Type} : 
  forall (f g : A -> LPReal), pointwise LPReq f g ->
  forall (mu : Valuation A),
  integral _ (integration A) f mu = integral _ (integration A) g mu.
Proof.
intros. apply LPReq_compat. unfold pointwise in H.
unfold LPReq. split; apply int_monotonic; unfold pointwise;
apply H.
Qed.

(** The "bind" of our monad. Given a measure over the space A, and a
    function which, given a point in A, returns a measure on B,
    we can produce a measure on B by integrating over A. *)
Definition bind {A B : Type}
  (v : Valuation A) (f : A -> Valuation B)
  : Valuation B.
Proof. refine (
  {| val := fun P => integral A (integration A) (fun x => (f x) P) v |}
).
- apply LPReq_compat. unfold LPReq. split.
  erewrite <- integral_zero.
  apply int_monotonic.
  unfold pointwise. intros.
  instantiate (1 := 0).
  rewrite strict. apply LPRzero_min.
  apply LPRzero_min.
- intros. apply int_monotonic.
  unfold pointwise. intros.
  apply monotonic. assumption.
- intros. do 2 rewrite int_adds. apply int_pointwise_eq.
  unfold pointwise. intros a.
  assert (
((f a) U + (f a) V) =
((f a) (fun z : B => U z /\ V z) + (f a) (fun z : B => U z \/ V z))
). apply modular. rewrite H. split; apply LPRle_refl.
Defined.

(* Product measures. That is, the joint distribute for two
   independent measures. *)
Definition product {A B : Type}
  (muA : Valuation A) (muB : Valuation B)
  : Valuation (A * B) := 
  bind muA (fun a => map (fun b => (a, b)) muB).

Theorem int_dirac_simple {A : Type} {s : Simple A} {a : A} :
 SimpleIntegral (unit a) s = SimpleEval s a.
Proof.
unfold SimpleEval. induction s; simpl; reflexivity.
Qed.

Theorem int_indicator {A : Type} {P : A -> Prop} {mu : Valuation A}
  : integral A (integration A) (fun x => LPRindicator (P x)) mu = mu P.
Proof.
rewrite int_pointwise_eq with (g := SimpleEval (SStep 1 P)).
rewrite int_simple. simpl. ring.
unfold SimpleEval. simpl. 
unfold pointwise. intros. apply LPReq_compat_backwards. ring.
Qed.


Theorem int_dirac_test {A : Type} {f : A -> LPReal} {a : A}
  (s : Simple A)
  : pointwise LPRle (SimpleEval s) f
  -> integral A (integration A) (SimpleEval s) (unit a) <= f a.
Proof.
intros. rewrite int_simple. rewrite int_dirac_simple. apply H. 
Qed.

Lemma undo_proj1sig {A : Type} {B : A -> Prop} 
  (a : A) (b : B a) : proj1_sig (exist _ a b) = a.
Proof. reflexivity. Qed.

(* Integrating a function over a Dirac delta results in
   simply the function value at that point. *)
Theorem int_dirac {A : Type} {f : A -> LPReal} {a : A}
  : integral A (integration A) f (unit a) = f a.
Proof.
intros.
pose (s := SStep (f a) (fun a' => a = a')).
 rewrite int_simple_sup. eapply LPRsup_prop.
- intros pr. destruct pr. simpl. 
  replace (fun P => LPRindicator (P a)) with (val (unit a)) by reflexivity.
  rewrite int_dirac_simple. apply p.
- eexists. rewrite undo_proj1sig.
  instantiate (1 := s).
  rewrite int_dirac_simple. unfold SimpleEval; simpl.
  rewrite LPRind_true by reflexivity.
  replace (f a * 1) with (f a) by ring.
  apply LPRle_refl.
  Grab Existential Variables.
  simpl. unfold pointwise. intros. unfold SimpleEval.
  simpl. rewrite (SRmul_comm LPRsrt). apply LPRind_scale_le.
  intros H. induction H. apply LPRle_refl.
Qed. 

(* We get what we would expect if we take the product of a
   Dirac delta with another distribution. *)
Theorem unitProdId {A B : Type}
  (a : A) (muB : Valuation B) (P : (A * B) -> Prop)
  : product (unit a) muB P = muB (fun b => P (a, b)).
Proof. simpl. rewrite int_dirac. reflexivity. Qed.

(* Product measures factor in the expected way. *)
Theorem product_prop {A B : Type}
  (muA : Valuation A)
  (muB : Valuation B)
  (PA : A -> Prop) (PB : B -> Prop)
  : (product muA muB) (fun p => let (x, y) := p in PA x /\ PB y)
  = muA PA * muB PB.
Proof. simpl.
rewrite <- int_indicator.
rewrite (SRmul_comm LPRsrt).
rewrite int_scales.
apply int_pointwise_eq. unfold pointwise.
intros a.
do 2 rewrite <- int_indicator.
rewrite (SRmul_comm LPRsrt).
rewrite int_scales.
eapply LPReq_compat_backwards.
apply int_pointwise_eq.
unfold pointwise. intros.
rewrite LPRind_mult.
apply LPReq_refl.
Qed.

(** WARNING: Work in progress from here on out! *)

Require Vector.

(** An n-fold IID product of a given measure. *)
Fixpoint product_n {A : Type} (v : Valuation A)
  (n : nat) : Valuation (Vector.t A n) := match n with
  | 0 => unit (Vector.nil A)
  | S n' => bind v (fun x => map (Vector.cons A x n') (product_n v n'))
  end.

Require Streams.

Fixpoint take_n {A : Type} (s : Streams.Stream A) (n : nat)
  : Vector.t A n := match n, s with
  | 0, _ => Vector.nil A
  | S n', Streams.Cons x xs => Vector.cons A x n' (take_n xs n')
end.

(* Restrict a property of streams to a property of vectors of length n.
   The property is true for a vector of length in if the property is
   true for ALL streams which begin with that finite prefix. *)
Definition restrictToVec {A : Type} (P : Streams.Stream A -> Prop)
  (n : nat) (x : Vector.t A n) : Prop :=
  forall (s : Streams.Stream A), take_n s n = x -> P s.

Lemma restrictToVecBot {A : Type} {n : nat}
  (nonempty : A)
  : forall xs, ~ (@restrictToVec A (K False) n xs).
Proof.
admit. 
Qed.

Lemma restrictToVecMonotonicP {A : Type} {n : nat}
  : forall { U V : Streams.Stream A -> Prop }
  , (forall (s : Streams.Stream A), U s -> V s)
  -> forall xs, restrictToVec U n xs -> restrictToVec V n xs.
Proof.
intros. unfold restrictToVec in *.
intros s take. apply H. apply H0. assumption.
Qed.

Lemma restrictToVecMonotonicN {A : Type} : 
 forall (v : Valuation A) (U : Streams.Stream A -> Prop),
 v (K True) = 1 ->
 forall n m : nat,
 (n <= m)%nat ->
 (product_n v n) (restrictToVec U n) <=
 (product_n v m) (restrictToVec U m).
Proof. intros. generalize dependent U.
induction H0; intros. apply LPRle_refl.
simpl.
eapply LPRle_trans. apply IHle.
rewrite <- int_indicator in H.
replace ((product_n v m) (restrictToVec U m))
   with ((product_n v m) (restrictToVec U m) * 1) by ring.
rewrite <- H.
rewrite int_scales.
apply int_monotonic.
unfold pointwise. intros a. unfold K.
rewrite LPRind_true by trivial.
replace ((product_n v m) (restrictToVec U m) * 1)
   with ((product_n v m) (restrictToVec U m)) by ring.
(* should see that we can snoc instead of cons and get the
   same measure *)
apply monotonic. intros.
admit.
Qed.

(* An infinite product measure, generated by considering finite
   products and taking the limit. *)
Theorem inf_product {A : Type} (v : Valuation A)
  (nonempty : A)
  (vIsProb : v (K True) = 1)
  : Valuation (Streams.Stream A).
Proof.
refine (
  {| val := fun P => LPRsup (fun n => (product_n v n) (restrictToVec P n))
  |}
); intros.
- apply LPReq_compat. split; [| apply LPRzero_min].
  unfold LPRle. simpl. intros. destruct H. subst.
  apply Qnnle_refl. destruct H.
  apply (monotonic _ _ (K False)) in H.
  rewrite (strict (product_n v x)) in H.
  simpl in H. assumption.
  apply restrictToVecBot.
  apply nonempty.
- apply LPRsup_monotonic.
  intros n. induction n; simpl.
  + apply LPRind_imp.
    unfold restrictToVec. intros H1.
    intros. apply H. apply H1. apply H0.
  + apply int_monotonic. unfold pointwise.
    intros a. apply monotonic. intros.
    eapply restrictToVecMonotonicP. eassumption.
    assumption.
- do 2 (rewrite <- LPRsup_nat_ord; 
  try (apply restrictToVecMonotonicN);
  try assumption).
  apply LPRsup_eq_pointwise.
  intros idx.
  (* apply modular. *)
  admit.
Defined.

(** A datatype for partial computations. We will use this
    to allow definitions of measures which might not be guaranteed
    to terminate. For example, consider the geometric distribution,
    where we might worry that we keep getting "heads". *)
CoInductive Partial {A : Type} : Type :=
 | Now : A -> Partial
 | Later : Partial -> Partial.

(** We can use this to loop. *)
CoFixpoint loop {A : Type} := @Later A loop.

Arguments Partial : clear implicits.

(** The nth iteration of the fixpoint of a functional on
    measures *)
Fixpoint fixn {A : Type}
  (f : Valuation A -> Valuation A) (n : nat)
  : Valuation A
  := match n with
  | 0 => zeroVal
  | S n' => f (fixn f n')
  end.

(* Run a partial computation for n steps, returning the value if
   we got a value in that many steps or fewer. *)
Fixpoint runPartial {A : Type} (px : Partial A)
  (n : nat) : option A := match px with
  | Now x => Some x
  | Later px' => match n with
    | 0 => None
    | S n' => runPartial px n'
    end 
  end.

(* Transform a property of values of A to a property of partial computations
   which may return an A, where the new property is true only if the computation
   indeed eventually returns a value for which the original property was true. *)
Definition partialize {A : Type} (P : A -> Prop)
  (px : Partial A) : Prop := exists n, match runPartial px n with
  | None => False
  | Some x => P x
  end.

Lemma partial_now {A : Type} (a : A) (n : nat)
  : runPartial (Now a) n = Some a.
Proof. induction n; unfold runPartial; intuition. Qed. 

Lemma partial_mono {A : Type} : forall (m n : nat) (px : Partial A)
  (a : A), (m <= n)%nat -> runPartial px m = Some a -> runPartial px n = Some a.
Proof.
intros. induction H. assumption. simpl. rewrite IHle.
  destruct px. simpl in *. rewrite partial_now in H0. assumption.
  reflexivity.
Qed.

Lemma partialize_and {A : Type} {U V : A -> Prop}
  (propext : forall (P Q : Prop), (P <-> Q) -> P = Q)
  : partialize (fun z => U z /\ V z) 
  = fun z => partialize U z /\ partialize V z.
Proof. apply functional_extensionality.
intros. apply propext. split; intros;
unfold partialize in *. destruct H;
split; exists x0; destruct (runPartial x x0); intuition.
destruct H. destruct H. destruct H0.
exists (max x0 x1). destruct (runPartial x x0) eqn:p0;
  destruct (runPartial x x1) eqn:p1; try contradiction.
  apply partial_mono with (n := max x0 x1) in p0.
  apply partial_mono with (n := max x0 x1) in p1.
  rewrite p0 in p1. injection p1. intros. subst.
  rewrite p0. split; assumption.
  apply Max.le_max_r. apply Max.le_max_l.
Qed.

Lemma partialize_or {A : Type} {U V : A -> Prop}
  (propext : forall (P Q : Prop), (P <-> Q) -> P = Q)
  : partialize (fun z => U z \/ V z) 
  = fun z => partialize U z \/ partialize V z.
Proof. apply functional_extensionality.
intros. apply propext. split; intros;
unfold partialize in *. destruct H.
destruct (runPartial x x0) eqn:partial.
destruct H; [left | right]; exists x0;
rewrite partial; assumption. contradiction.
destruct H; destruct H; exists x0;
destruct (runPartial x x0) eqn:partial; intuition.
Qed.

(** We can convert a measure on [Partial A]s to a measure on 
    [A]s by essentially just setting measure 0 to any of the
    values which never terminated. *)
Definition partialValuation {A : Type}
  (propext : forall (P Q : Prop), (P <-> Q) -> P = Q)
  (v : Valuation (Partial A))
  : Valuation A.
Proof. refine (
  {| val := fun P => v (partialize P) |}
).
- apply LPReq_compat. split. 
  + erewrite <- strict.
    apply monotonic. intros. unfold partialize, K in *.
    destruct H. destruct (runPartial z x); assumption.
  + apply LPRzero_min.
- intros.
  apply monotonic. intros z PU.
  unfold partialize in *. destruct PU.
  exists x. destruct (runPartial z x). apply H; assumption.
  assumption.
- intros. rewrite partialize_and. rewrite partialize_or.
  apply modular.
  apply propext. apply propext.
Defined.

(* If our valuation functional is monotonic, then the
   fixpoint is nondecreasing. *)
Lemma fixnmono {A : Type}
  (f : Valuation A -> Valuation A)
  (fmono : forall u v, Valle u v -> Valle (f u) (f v))
  : forall (n : nat), Valle (fixn f n) (fixn f (S n)).
Proof. intros. induction n.
simpl. unfold Valle; intros. simpl. apply LPRzero_min.
simpl. apply fmono. assumption.
Qed.

Lemma fixnmono2 {A : Type}
  (f : Valuation A -> Valuation A)
  (fmono : forall u v, Valle u v -> Valle (f u) (f v))
  : forall (m n : nat), (m <= n)%nat -> Valle (fixn f m) (fixn f n).
Proof. intros. induction H. apply Valle_refl. 
eapply Valle_trans. eassumption. apply fixnmono. assumption.
Qed.

(** If we have a valuation functional which is monotonic, we can take
    its fixpoint! *)
Definition fixValuation {A : Type}
  (propext : forall (P Q : Prop), (P <-> Q) -> P = Q)
  (f : Valuation A -> Valuation A)
  (fmono : forall u v, Valle u v -> Valle (f u) (f v))
  : Valuation A.
Proof. refine (
  {| val := fun P => LPRsup (fun n => (fixn f n) P) |}
).
- apply LPReq_compat. split. 
  + apply LPRsup_le. intros. erewrite <- strict.
    apply monotonic. intros. assumption. 
  + apply LPRzero_min.
- intros. apply LPRsup_monotonic. intros n.
  apply monotonic. assumption. 
- intros.
  rewrite <- LPRsup_nat_ord by (intros; apply fixnmono2; assumption).
  rewrite <- LPRsup_nat_ord by (intros; apply fixnmono2; assumption).
  apply LPRsup_eq_pointwise. intros.
  apply modular.
Defined.

Lemma fixValuation_subProb {A : Type}
  (propext : forall (P Q : Prop), (P <-> Q) -> P = Q)
  (f : Valuation A -> Valuation A)
  (fmono : forall u v, Valle u v -> Valle (f u) (f v))
  (fbounded : forall v, val v (K True) <= 1 -> f v (K True) <= 1)
  : (fixValuation propext f fmono) (K True) <= 1.
Proof. simpl. apply LPRsup_le.
intros n. induction n. simpl. apply LPRzero_min.
simpl. apply fbounded. assumption.
Qed.

(** The functional which corresponds to rejection sampling. *)
Definition rejectionFunc {A : Type} (v : Valuation A)
  (pred : A -> bool) 
  (f : Valuation A) : Valuation A :=
  bind v (fun a => if pred a
    then unit a
    else f).

(** This functional is indeed monotonic. *)
Lemma rejectionFunc_mono {A : Type} (v : Valuation A)
  (pred : A -> bool)
  : let f := rejectionFunc v pred 
    in forall mu1 mu2, Valle mu1 mu2 -> Valle (f mu1) (f mu2).
Proof. 
intros. unfold Valle in *. intros P. simpl.
apply int_monotonic. unfold pointwise. intros a.
destruct (pred a). apply LPRle_refl. apply H.
Qed.

(** Modify a measure by rejection sampling. *)
Definition rejection {A : Type} (v : Valuation A)
  (pred : A -> bool) 
  (propext : forall (P Q : Prop), (P <-> Q) -> P = Q)
  : Valuation A
  := fixValuation propext (rejectionFunc v pred)
     (rejectionFunc_mono v pred).

(** Rejection sampling gives a sub-probability distribution: the
    total measure is no greater than 1. It might be 0, though,
    if the predicate we use for rejection occurs with probability 0. *)
Definition rejection_subProb {A : Type} (v : Valuation A)
  (pred : A -> bool) 
  (vProb : v (K True) = 1)
  (predPos : ~ (v (fun x => pred x = true) <= 0))
  (propext : forall (P Q : Prop), (P <-> Q) -> P = Q)
  : (rejection v pred propext) (K True) <= 1.
Proof.
apply fixValuation_subProb. intros. unfold rejectionFunc.
simpl. rewrite <- vProb. rewrite <- int_indicator.
apply int_monotonic. unfold pointwise. unfold K.
intros. destruct (pred a). simpl.
apply LPRind_imp. trivial.
rewrite LPRind_true by trivial. apply H.
Qed.

(** This is clearly wrong; this is just the zero measure. I even
    prove my wrongness a little bit further down. *)
Definition inf_productFunc {A : Type} (v : Valuation A)
  (f : Valuation (Streams.Stream A)) : Valuation (Streams.Stream A)
  := bind v (fun x => map (Streams.Cons x) f).

Lemma inf_productFunc_mono {A : Type} (v : Valuation A)
  : forall mu1 mu2, Valle mu1 mu2 -> Valle (inf_productFunc v mu1) (inf_productFunc v mu2).
Proof. 
intros. unfold Valle in *. intros P. simpl.
apply int_monotonic. unfold pointwise. intros a.
apply H.
Qed.

Definition inf_product' {A : Type} (v : Valuation A)
  (propext : forall (P Q : Prop), (P <-> Q) -> P = Q)
  : Valuation (Streams.Stream A)
  := fixValuation propext (inf_productFunc v) (inf_productFunc_mono v).

Lemma inf_product'_wrong {A : Type} (v : Valuation A)
  (propext : forall (P Q : Prop), (P <-> Q) -> P = Q)
  : inf_product' v propext = zeroVal.
Proof.
apply Valeq_compat. unfold Valeq. intros P.
simpl. apply LPReq_compat. split.
apply LPRsup_le. intros n. generalize dependent P. induction n; intros.
simpl. apply LPRle_refl. simpl.
rewrite <- strict with v.
rewrite <- int_indicator. apply int_monotonic.
unfold pointwise. unfold K.
rewrite LPRind_false by intuition.
intros a. apply IHn. apply LPRzero_min.
Qed.

(** A data type for random samplers. [R] is the type of the random seed,
    and [A] is the type for which values are sampled. Our correctness property
    says that if we are given a seed which comes from the distribution [random]
    and then apply the sampling function [sample], the result is distributed as
    a new random seed distributed as [random] and a value of [A] distributed
    according to the measure [mu], and these two results are independent. *)
Record Sampler {R A : Type} (random : Valuation R) (mu : Valuation A)
  : Type :=
  { sample     :> R -> R * A
  ; sample_ind :  map sample random = product random mu
  }.

(** Samplers, too, form a monad, and here's the (very boring) unit. *)
Definition sunit {R A : Type} (random : Valuation R)
  (a : A) : Sampler random (unit a).
Proof. refine (
  {| sample := fun r => (r, a) |}
).
apply Valeq_compat. unfold Valeq. intros. simpl.
rewrite <- int_indicator. apply int_pointwise_eq.
unfold pointwise. intros r. apply LPReq_compat_backwards.
reflexivity.
Defined.

Lemma map_compose {A B C : Type} (mu : Valuation A)
  (g : B -> C) (f : A -> B)
  : map (fun x => g (f x)) mu = map g (map f mu).
Proof.
apply Valeq_compat. unfold Valeq. intros P.
simpl. reflexivity.
Qed.

Definition join {A : Type} (mu : Valuation (Valuation A))
  : Valuation A.
Proof. refine (
  {| val := fun P => integral _ (integration _) (fun vA => val vA P) mu |}
).
- replace 0 with (0 * mu (K True)) by ring.
  rewrite <- int_indicator.
  rewrite int_scales.
  apply int_pointwise_eq. unfold pointwise. intros v.
  rewrite strict. apply LPReq_compat_backwards. ring.
- intros. apply int_monotonic. unfold pointwise.
  intros. apply monotonic. assumption.
- intros. rewrite int_adds. rewrite int_adds.
  apply int_pointwise_eq. unfold pointwise; intros.
  apply LPReq_compat_backwards. apply modular.
Defined.

(** Fubini's theorem about iterated integrals. It's likely _wrong_ as stated
    here, but it sure is useful! *)
Lemma fubini {A B : Type} (f : (A * B) -> LPReal)
  (muA : Valuation A) (muB : Valuation B)
 : integral A (integration A) (fun a => integral B (integration B) (fun b => f (a, b)) muB) muA
 = integral B (integration B) (fun b => integral A (integration A) (fun a => f (a, b)) muA) muB.
Proof.
Admitted.

(** If we believe the statement of Fubini's theorem above, then
    we have a bind operation on random samplers! *)
Definition sbind {R A B : Type} (random : Valuation R)
  (mu : Valuation A) (smu : Sampler random mu) 
  (f : A -> Valuation B) (sf : forall a, Sampler random (f a))
  : Sampler random (bind mu f).
Proof. 
pose (func := fun p : (R * A) => sf (snd p) (fst p)).
refine (
  {| sample := fun r => func (smu r) |}
).
rewrite map_compose.
rewrite (sample_ind _ _ smu).
apply Valeq_compat. unfold Valeq. intros. simpl.
pose (func2 := fun p => (f (snd p)) (fun b => P (fst p, b))).
assert (
 (fun x : R =>
      integral A (integration A)
        (fun x0 : A => (f x0) (fun x1 : B => P (x, x1))) mu)
 = 
 (fun x : R =>
      integral A (integration A)
        (fun x0 : A => func2 (x, x0)) mu)
).
apply functional_extensionality. intros r.
reflexivity. rewrite H.
rewrite fubini.
assert (
(fun x : R => mu (fun x0 : A => P (func (x, x0))))
= 
(fun x : R => integral A (integration A) (fun x0 : A => LPRindicator (P (func (x, x0)))) mu)
).
apply functional_extensionality. intros.
rewrite int_indicator. reflexivity.
rewrite H0.
pose (func3 := fun (p : R * A) => LPRindicator (P (func p))).
assert (
     (fun x : R =>
      integral A (integration A)
        (fun x0 : A => LPRindicator (P (func (x, x0)))) mu)
=
     (fun x : R =>
      integral A (integration A)
        (fun x0 : A => func3 (x, x0)) mu)
).
apply functional_extensionality. intros. reflexivity.
rewrite H1.
rewrite fubini.
apply int_pointwise_eq. unfold pointwise. intros a.
apply LPReq_compat_backwards.
pose proof (sample_ind _ _ (sf a)).
unfold func3, func2. simpl.
assert (forall P, (map (sf a) random) P = (product random (f a)) P).
intros. rewrite H2. reflexivity.
simpl in H3.
rewrite int_indicator. apply H3.
Defined.

Lemma streamTl {A : Type} (mu : Valuation A)
  (nonempty : A)
  (mu1 : mu (K True) = 1)
  : map (@Streams.tl A) (inf_product mu nonempty mu1) = 
    inf_product mu nonempty mu1.
Proof.
apply Valeq_compat. unfold Valeq. intros P.
simpl. apply LPReq_compat. 
split; apply LPRsup_le; intros n;
apply LPRsup_ge2. 
- admit.
- admit.
Qed.

Definition streamSampler {A : Type} (mu : Valuation A)
  (nonempty : A) (mu1 : mu (K True) = 1)
  : Sampler (inf_product mu nonempty mu1) mu.
Proof. refine (
  {| sample := fun r => match r with
     | Streams.Cons a r' => (r', a)
     end
  |}
). apply Valeq_compat. unfold Valeq. intros P.
Abort.

(* Random samplers which may diverge. *)
Record PSampler {R A : Type} (propext : forall P Q, (P <-> Q) -> P = Q)
  (random : Valuation R) (mu : Valuation A)
  : Type :=
  { psample     :> R -> Partial (R * A)
  ; psample_ind :  partialValuation propext (map psample random) = product random mu
  }.

Lemma partialValNow {A : Type} propext (mu : Valuation A)
  : partialValuation propext (map Now mu) = mu.
Proof.
apply Valeq_compat. unfold Valeq; intros.
simpl.
replace ((fun x : A => partialize P (Now x))) with P.
reflexivity.
apply functional_extensionality. simpl. intros x.
apply propext. split; intros. unfold partialize.
exists 0%nat. simpl. assumption.
unfold partialize in H. destruct H.
rewrite partial_now in H. assumption.
Qed.

(* Any total sampler can be considered as a partial sampler. *)
Definition partializeSampler {R A : Type}
  propext {random : Valuation R} {mu : Valuation A}
  (f : Sampler random mu)
  : PSampler propext random mu.
Proof.
refine (
  {| psample := fun r => Now (f r) |}
).
rewrite map_compose. rewrite (sample_ind _ _ f).
apply partialValNow.
Defined.

Lemma partialLoop {A : Type} : forall n, runPartial loop n = (@None A).
intros. induction n. simpl. reflexivity.
simpl. apply IHn.
Qed.

Definition zeroPSampler {R A : Type} propext
  {random : Valuation R}
  : PSampler propext random (@zeroVal A).
Proof. refine (
  {| psample := fun r => loop |}
).
apply Valeq_compat. unfold Valeq. intros P.
simpl. rewrite <- (LPRind_false False) by auto.
rewrite int_indicator. 
replace (partialize P loop) with False. reflexivity.
apply propext. split; intros. contradiction.
unfold partialize in H. destruct H. rewrite partialLoop in H.
assumption.
Defined.

(** The notion of a measure being dominated by another will be important
    for defining PDFs. The is also sometimes called absolute continuity. *)
Definition DominatedBy {A : Type} (mu nu : Valuation A) :=
  forall (P : A -> Prop), nu P = 0 -> nu P = 0.

Lemma DominatedBy_refl {A : Type} (mu : Valuation A)
  : DominatedBy mu mu.
Proof. unfold DominatedBy. auto. Qed.

Lemma DominatedBy_trans {A : Type} (u v w : Valuation A)
  : DominatedBy u v -> DominatedBy v w -> DominatedBy u w.
Proof. unfold DominatedBy. auto. Qed.

(** The function [pdf] represents a PDF of [mu] given with respect to
    [lambda]. In general, we might thing of [mu] as something funny, whereas
    [lambda] might be something nice and easy to integrate over, such as
    Lebesgue measure on the interval. *)
Record PDF {A B : Type} (lambda : Valuation A) (mu : Valuation B) : Type :=
  { pdf :> A -> LPReal
  ; pdf_integrates : forall (P : B -> Prop),
    integral _ (integration _) pdf lambda = mu P
  }.

(**  The Radon-Nikodym theorem looks something like this below... *)
Definition Radon_Nikodym_statement :=
  forall (A : Type) (mu lambda : Valuation A)
  , DominatedBy mu lambda -> PDF lambda mu.

(** If we have PDFs for two measures, we naturally get a PDF for their
    product measure. *)
Definition product_PDF {A A' B B': Type} 
  {lambda1 : Valuation A} {lambda2 : Valuation B}
  {mu : Valuation A'} {nu : Valuation B'}
  (pdfmu : PDF lambda1 mu) (pdfnu : PDF lambda2 nu)
  : PDF (product lambda1 lambda2) (product mu nu).
Proof. refine (
  {| pdf := fun p : A * B => let (x, y) := p in pdfmu x * pdfnu y |}
).
Abort.