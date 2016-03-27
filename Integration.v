Require Import Frame FrameVal LPReal.
Require Import Morphisms Ring.

Import FrameVal.ValNotation.
Local Open Scope LPR.

Generalizable All Variables.
Set Asymmetric Patterns.

(** * Integration *)

(** An inductive definition of simple functions. I hesitate to
    call them functions because they aren't necessarily computable.
    *)

Module Simple.

(** Simple functions are generated by taking indicators of open sets, and closing under
    scalar multiplication and addition *)
Inductive t `{X : F.t A} :=
  | Ind : A -> t
  | Scale : LPReal -> t -> t
  | Add : t -> t -> t.

Arguments t {A} {OA} X.

(** Definition of how to integrate simple functions *)
Fixpoint Integral `{X : F.t A} (s : t X) 
  (mu : Val.t X) : LPReal := match s with
  | Ind P => mu P
  | Scale c f => c * Integral f mu
  | Add f g => Integral f mu + Integral g mu
  end.

Delimit Scope Simple_scope with Simple.
Infix "+" := Add : Simple_scope.
Infix "*" := Scale : Simple_scope.

(** We define a partial order on simple functions according to
    whether the integral of one dominates the other for every
    possible valuation. It is potentially unclear that this
    is the best definition. *)
Definition le `{X : F.t A} (x y : t X) := 
  forall (mu : Val.t X), Integral x mu <= Integral y mu.

Definition eq `{X : F.t A} (x y : t X) := 
  forall (mu : Val.t X), Integral x mu = Integral y mu.

Instance PO `{X : F.t A} : PO.t (t X) le eq
  := PO.map Integral 
     (PO.pointwise (fun _ : Val.t X => Val.POLPR)).

Lemma int_proper1 `{X : F.t A} : Proper (Logic.eq ==> Val.eq ==> Logic.eq) (@Integral _ _ X).
Proof.
 unfold Proper, respectful. unfold eq. intros.  subst. induction y. 
 - simpl. apply H0. 
 - simpl. rewrite IHy. ring.
 - simpl. rewrite IHy1, IHy2. ring.
Qed.

Instance int_proper `{X : F.t A} : Proper (eq ==> Val.eq ==> Logic.eq) (@Integral _ _ X).
Proof.
 unfold Proper, respectful. unfold eq. intros. rewrite H.
 apply int_proper1. reflexivity. assumption.
Qed.

Lemma le_refl `{X : F.t A} : forall (x : t X), le x x.
Proof.
  apply PreO.le_refl.
Qed.

Infix "<=" := le : Simple_scope.
Infix "==" := eq : Simple_scope.

Lemma le_plus `{X : F.t A} : forall (f f' g g' : t X),
  (f <= f' -> g <= g' -> f + g <= f' + g')%Simple.
Proof.
intros. unfold le in *. intros. simpl. apply LPRplus_le_compat; auto.
Qed.

Lemma le_scale `{X : F.t A} : forall (c c' : LPReal) (f f' : t X),
  c <= c' -> (f <= f' -> c * f <= c' * f')%Simple.
Proof.
intros.  unfold le in *. intros. simpl.
apply LPRmult_le_compat. assumption. apply H0.
Qed.

Lemma int_monotonic_val `{X : F.t A} {f : t X}
  {mu mu' : Val.t X}
  : (mu <= mu')%Val -> Integral f mu <= Integral f mu'.
Proof. intros. induction f; simpl.
- apply H.
- apply LPRmult_le_compat. apply LPRle_refl. apply IHf.
- simpl. apply LPRplus_le_compat; assumption.
Qed.

Lemma int_adds_val `{X : F.t A} {f : t X}
  {mu mu' : Val.t X}
  : Integral f (mu + mu')%Val
  = Integral f mu + Integral f mu'.
Proof.
induction f; simpl.
- reflexivity.
- rewrite IHf. ring. 
- simpl in *. rewrite IHf1. rewrite IHf2. ring.
Qed.

Lemma int_scales_val `{X : F.t A} {c : LPReal} {f : t X}
  {mu : Val.t X}
  : Integral f (c * mu)%Val 
  = c * Integral f mu.
Proof.
induction f; simpl.
- reflexivity.
- rewrite IHf. ring. 
- simpl in *. rewrite IHf1. rewrite IHf2. ring.
Qed.

Lemma int_bottom `{X : F.t A} : forall {mu : Val.t X}
  , Integral (Ind F.bottom) mu = 0.
Proof.
intros. simpl. apply Val.strict.
Qed.

(** [map_concrete] just maps a function over all the potential opens.
    It is *not* precomposition with a continuous function.
    That is given by the following function [map], which uses the
    definition here. *)
Fixpoint map_concrete {B} `{X : F.t A} `{Y : F.t B}
  (f : A -> B) (s : t X) : t Y := match s with
  | Ind P => Ind (f P)
  | Scale c s' => Scale c (map_concrete f s')
  | Add l r => Add (map_concrete f l) (map_concrete f r)
  end.

Definition map {A B OA OB} {X : F.t A OA} {Y : F.t B OB}
  (f : F.cmap OA OB) : t Y -> t X
  := map_concrete (F.finv f).

End Simple.

(** The [RealFunc] module represents continuous functions from a locale
    to the lower real numbers. 

    To do things properly, I should have a locale of lower real numbers,
    which the requisite operations like +, *, etc. evident as
    continuous functions, but I have yet to do this. I hope to soon redefine
    the lower reals in terms of formal topology.

    Instead, I cheat here, and define a continuous function to the lower reals
    as the supremum of a monotonically increasing sequence of simple functions.
    This cheat is not so heinous, as it is in fact a theorem that every continuous
    function can be represented as such.
     *)
Module RealFunc.

  Record t {A} `{X : F.t A} :=
    { func :> nat -> Simple.t X
    ; mono : forall m n, (m <= n)%nat -> Simple.le (func m) (func n) }.

  Arguments t {A} {OA} X.

  (** Any simple function is a continuous lower-real-valued function. *)
  Definition simple `{X : F.t A} (f : Simple.t X) : t X.
  Proof. refine (
   {| func := fun _ => f |}).
  intros. apply Simple.le_refl.
  Defined.

  Definition add `{X : F.t A} (f g : t X) : t X.
  Proof. refine (
    {| func n := Simple.Add (f n) (g n) |}
  ).
  intros. unfold Simple.le. intros. 
  apply Simple.le_plus; apply mono; assumption.
  Defined.

  Infix "+" := add : RFunc_scope.
  Delimit Scope RFunc_scope with RFunc.

  Definition scale `{X : F.t A} (c : LPReal) (f : t X) : t X.
  Proof. refine (
    {| func n := Simple.Scale c (f n) |}
  ).
  intros. apply Simple.le_scale. apply LPRle_refl. apply mono. assumption.
  Defined.

  Infix "*" := scale : RFunc_scope.

  (** We can precompose a lower-real valued continuous function with
      an arbitrary continuous function. *)
  Definition map {A OA} {X : F.t A OA} {B OB} {Y : F.t B OB} (f : F.cmap OA OB) 
    (g : t Y) : t X.
  Proof. refine (
    {| func := fun i => Simple.map f (g i) |}
  ). destruct g. simpl.
  Abort.

  (** The integral of a continuous function is the supremum of the
      simple integrals of the simple functions of which it is the
      supremum. *)
  Definition integral `{X : F.t A} (f : t X) (mu : Val.t X) :=
   LPRsup (fun i => Simple.Integral (f i) mu).

  Definition le `{X : F.t A} (f g : t X) := forall (mu : Val.t X),
    integral f mu <= integral g mu.

  Definition eq `{X : F.t A} (f g : t X) := forall (mu : Val.t X),
    integral f mu = integral g mu.

  Instance PO `{X : F.t A} : PO.t (t X) le eq
    := PO.map (fun f => (fun mu => integral f mu)) 
       (PO.pointwise (fun _ : Val.t X => Val.POLPR)).

  Infix "<=" := le : RFunc_scope.
  Infix "==" := eq : RFunc_scope.

  Instance int_proper `{X : F.t A} : Proper (eq ==> Val.eq ==> Logic.eq) (@integral _ _ X).
  Proof.
   unfold Proper, respectful. unfold eq. intros. unfold integral in *.
   rewrite H. apply LPRsup_eq_pointwise. intros n. apply Simple.int_proper.
   unfold Simple.eq. reflexivity. assumption.
  Qed.

  Lemma int_simple `{X : F.t A} : forall (f : Simple.t X) (mu : Val.t X),
      integral (simple f) mu = Simple.Integral f mu.
  Proof.
    intros. unfold integral, simple. simpl. apply LPRsup_constant. exact 0%nat.
  Qed.

  Lemma int_zero `{X : F.t A} : forall {mu : Val.t X}
    , integral (simple (Simple.Ind F.bottom)) mu = 0.
  Proof.
    intros.
    rewrite int_simple. simpl.
    rewrite Val.strict. ring.
  Qed.

  Lemma int_adds `{X : F.t A} : forall (f g : t X) (mu : Val.t X),
     integral (f + g)%RFunc mu = integral f mu + integral g mu.
  Proof.
    intros. unfold integral. 
    apply LPRsup_nat_ord; intros; apply mono; assumption.
  Qed.

  Lemma le_plus `{X : F.t A} : forall (f f' g g' : t X),
    (f <= f' -> g <= g' -> f + g <= f' + g')%RFunc.
  Proof. 
    unfold le in *. intros. repeat rewrite int_adds.
    apply LPRplus_le_compat; auto.
  Qed.

  Lemma int_scales `{X : F.t A} : forall (c : LPReal) (f : t X) (mu : Val.t X)
    , integral (c * f)%RFunc mu = c * integral f mu.
  Proof.
    intros. unfold integral. rewrite LPRsup_scales. apply LPRsup_eq_pointwise.
    intros n. simpl. reflexivity.
  Qed.

Lemma int_monotonic_val `{X : F.t A} {f : t X}
  {mu mu' : Val.t X}
  : (mu <= mu')%Val -> integral f mu <= integral f mu'.
Proof. 
  intros. unfold integral. apply LPRsup_monotonic. intros.
  apply Simple.int_monotonic_val. assumption.
Qed.

Lemma int_adds_val `{X : F.t A} {f : t X}
  {mu mu' : Val.t X}
  : integral f (mu + mu')%Val 
  = integral f mu + integral f mu'.
Proof.
unfold integral. 
rewrite <- LPRsup_nat_ord by (intros; apply mono; assumption).
apply LPRsup_eq_pointwise. intros. apply Simple.int_adds_val.
Qed.

Lemma int_scales_val `{X : F.t A} {c : LPReal} {f : t X}
  {mu : Val.t X}
  : integral f (c * mu)%Val
  = c * integral f mu.
Proof.
unfold integral. rewrite LPRsup_scales. apply LPRsup_eq_pointwise.
intros. apply Simple.int_scales_val.
Qed.

(** We can recover what our real-valued continuous function evaluates to
    by integrating it against a Dirac delta. *)
Definition eval {A OA} {X : F.t A OA} (f : t X) (x : F.point OA) : LPReal :=
  integral f (Val.unit x).

End RealFunc.

(** Here is where the lying/cheating returns! I attempt to say that every Coq type
    in fact represents a topological space, where every possible subset is open.
    Therefore, every function is, by definition, continuous. The difficulty is at
    the interface with the point where I played by the rules, which is the
    real-valued functions. *)
Module SubsetVal.

Module RF := RealFunc.

(** The open sets of a type are simply its subsets, or proposition-valued
    valued functions from that type. *)
Definition O := F.subset.

Definition Val (A : Type) := Val.t (O A).

(** Here we convert from a literal point of a Coq type [a : A] to a
    localic point, which is the class of subsets which include [a]. *)
Definition point {A} (a : A) : F.point (F.subset_ops A).
 refine (
  {| F.finv := fun P => P a |}
). simpl. constructor; simpl. constructor; simpl; intros. 
- constructor; simpl; intros; firstorder.
- reflexivity.
- reflexivity.
- reflexivity.
- split; intros. exists True. exact I. exists (fun _ => True). exact I.
Defined.

(** We state as an axiom that all functions to the lower reals are continuous,
    and thus they can be represented by the [RealFunc.t] type. *)
Axiom all_cont : forall {A}, (A -> LPReal) -> RF.t (O A).

(** Furthermore, we define the behavior of the [all_cont] axiom, by saying
    that when it is evaluated at a point, we get the value we expect. *)
Axiom all_cont_point : forall A (f : A -> LPReal) (a : A), 
  RF.eval (all_cont f) (point a) = f a.

(** Finally, we state as an axiom that we can tell when a 
    lower-real valued function [f]
    is no greater than [g] in terms of the [RealFunc] definition
    (its integral is dominated for every possible valuation) by checking
    their behavior pointwise. *)
Axiom RF_pointwise : forall A (f g : RF.t (O A)),
  (forall a, RF.eval f (point a) <= RF.eval g (point a)) -> RF.le f g.

Require Finite.

Definition inject {A B}
  (f : A -> B) : Simple.t (O A) -> Simple.t (O B)
  := Simple.map_concrete (fun P b => exists a, b = f a /\ P a).

Definition fin_all_cont {A : Type} (fin : Finite.T A) (f : A -> LPReal)
  : Simple.t (O A).
Proof.
induction fin.
- exact (Simple.Ind (fun _ => False)).
- unfold O. 
  pose (Simple.Scale (f (inl I)) (@Simple.Ind _ _ (O _) 
    (fun x => x = @inl _ A I))) as v1.
  pose (inject (@inr True _) (IHfin (fun x => f (inr x)))) as v2.
  exact (Simple.Add v1 v2).
- pose (IHfin (fun a => f (Iso.to t a))) as v.
  exact (Simple.map (F.subset_map (Iso.from t)) v).
Defined.

Require Import Ring. 
Lemma inject_L : forall A B (a : A) v, Simple.Integral
     (inject inr v)
     (Val.unit (point (@inl A B a))) = 0.
Proof. intros. unfold inject. induction v; simpl.
- rewrite LPRind_false. reflexivity. unfold not. intros contra.
  destruct contra. destruct H. congruence.
- rewrite IHv. ring.
- rewrite IHv1. rewrite IHv2. ring.
Qed.

Lemma inject_R : forall A B (b : B) v, Simple.Integral
     (inject inr v)
     (Val.unit (point (@inr A B b))) = Simple.Integral v
     (Val.unit (point b)).
Proof. intros. unfold inject. induction v; simpl.
- apply LPRind_iff. split; intros.
  destruct H. destruct H. inversion H. assumption.
  exists b. split. reflexivity. assumption.
- rewrite IHv. ring.
- rewrite IHv1. rewrite IHv2. ring.
Qed.

Lemma map_point {A B OA OB} (X : F.t A OA) (Y : F.t B OB) :
  forall (f : F.cmap OA OB) (x : F.point OA),
  Val.eq (Val.map f (Val.unit x))
         (Val.unit (F.cmap_compose x f)).
Proof. 
intros. unfold Val.eq. intros. reflexivity.
Qed.

Lemma simple_int_map_point : forall {A B OA OB} (X : F.t A OA) (Y : F.t B OB)
  (f : F.cmap OA OB) s (x : F.point OA),
   Simple.Integral (Simple.map f s) (Val.unit x)
  = Simple.Integral s (Val.unit (F.cmap_compose x f)).
Proof.
intros. induction s; simpl in *. 
- reflexivity.
- rewrite <- IHs. reflexivity.
- rewrite <- IHs1. rewrite <- IHs2. reflexivity.
Qed.

Theorem fin_all_cont_point : forall {A : Type} 
  (fin : Finite.T A) (f : A -> LPReal) (a : A),
   RF.eval (RF.simple (fin_all_cont fin f)) (point a) = f a.
Proof.
intros. induction fin.
- contradiction. 
- destruct a.
  + destruct t. unfold RF.eval in *. rewrite RF.int_simple. simpl.
    rewrite LPRind_true by trivial.
    rewrite inject_L. ring.
  + unfold RF.eval in *. rewrite RF.int_simple.
    simpl. rewrite LPRind_false.
    specialize (IHfin (fun x => f (inr x)) a).
    rewrite RF.int_simple in IHfin. rewrite inject_R. 
    simpl in *. rewrite IHfin.
    ring. congruence.
-  unfold RF.eval. rewrite RF.int_simple. simpl.
   specialize (IHfin (fun a0 => f (Iso.to t a0)) (Iso.from t a)).
   simpl in IHfin. rewrite Iso.to_from in IHfin.
   unfold RF.eval in IHfin. rewrite RF.int_simple in IHfin.
   rewrite <- IHfin. simpl. rewrite simple_int_map_point.
   apply Simple.int_proper. unfold Simple.eq. reflexivity.
   apply (map_point (F.subset _) (F.subset _)).
Qed.   
 
Lemma RF_pointwise_eq : forall {A} (f g : RF.t (O A)),
  (forall a, RF.eval f (point a) = RF.eval g (point a)) -> RF.eq f g.
Proof. intros. apply PO.le_antisym; apply RF_pointwise; 
  intros; rewrite H; apply LPRle_refl.
Qed.

Lemma RF_add : forall {A} (f g : A -> LPReal),
  RF.eq (RF.add (all_cont f) (all_cont g)) (all_cont (fun x => f x + g x)).
Proof.
intros. apply RF_pointwise_eq. intros.
rewrite all_cont_point. unfold RF.eval. rewrite RF.int_adds.
apply LPRplus_eq_compat; apply all_cont_point.
Qed.

Lemma RF_add_eval : forall {A} (f g : A -> LPReal) (a : A),
    RF.eval (RF.add (all_cont f) (all_cont g)) (point a)
  = f a + g a.
Proof.
intros. unfold RF.eval. rewrite RF_add. apply all_cont_point.
Qed.

Definition integral {A} (f : A -> LPReal) (mu : Val A) : LPReal :=
  RF.integral (all_cont f) mu.

(* Theorem 3.13 of Jones 1990 *)
Theorem directed_monotone_convergence {A : Type} :
  forall (mu : Val.t (O A)) I `(JL : JoinLat.t I),
  forall (g : I -> (A -> LPReal)),
    integral (fun x => LPRsup (fun i => g i x)) mu
  = LPRsup (fun i => integral (fun x => g i x) mu).
Proof.
intros. 
Admitted.

(** The "bind" of our monad. Given a measure over the space A, and a
    function which, given a point in A, returns a measure on B,
    we can produce a measure on B by integrating over A. *)
Definition bind {A B : Type}
  (v : Val A) (f : A -> Val B)
  : Val B.
Proof. refine (
  {| Val.val := fun P => integral (fun x => Val.val (f x) P) v |}
).
- apply LPReq_compat. unfold LPReq. split.
  unfold integral. 
  rewrite <- (@RF.int_zero _ _ _ v).
  apply RF_pointwise. intros. rewrite all_cont_point. 
  rewrite Val.strict. apply LPRzero_min.
  apply LPRzero_min.
- intros. unfold integral. apply RF_pointwise. intros. 
  repeat rewrite all_cont_point. apply Val.monotonic. 
  assumption.
- intros. unfold integral. repeat rewrite <- RF.int_adds. apply RF_pointwise_eq.
  intros. unfold RF.eval. repeat rewrite RF_add. pose proof all_cont_point.
  unfold RF.eval in H. repeat rewrite H.
  apply Val.modular.
- unfold Val.ContinuousV. intros. simpl.
  unfold integral. erewrite RF.int_proper. Focus 3. unfold Val.eq. reflexivity.
  Focus 2. apply RF_pointwise_eq. intros. do 2 rewrite all_cont_point.
  eapply (Val.continuous (f a)). eassumption. apply fmono.
  pose proof @directed_monotone_convergence.
  unfold integral in H. eapply H. eassumption.
Defined.

End SubsetVal.
