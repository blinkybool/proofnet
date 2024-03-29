import tactic

def Atom := ℕ

inductive FormO : Type
| pos : Atom × ℕ → FormO
| neg : Atom × ℕ → FormO
| tensor : FormO → FormO → FormO
| par : FormO → FormO → FormO

def FormO.negation : FormO → FormO
| (FormO.pos A) := FormO.neg A
| (FormO.neg A) := FormO.pos A
| (FormO.tensor A B) := FormO.par (FormO.negation A) (FormO.negation B)
| (FormO.par A B) := FormO.tensor (FormO.negation A) (FormO.negation B)

infix ` ⊗ `:70 := FormO.tensor
infix ` ⅋ `:65 := FormO.par
prefix `~` := FormO.negation

inductive Link : Type
| ax : Atom × ℕ → Link
| cut : FormO → Link
| tensor : FormO → FormO → Link
| par : FormO → FormO → Link

inductive premise : FormO → Link → Prop
| cut_pos {Ai}         : premise Ai (Link.cut Ai)
| cut_neg {Ai}         : premise (~Ai) (Link.cut Ai)
| tensor_left {Ai Bj}  : premise Ai (Link.tensor Ai Bj)
| tensor_right {Ai Bj} : premise Bj (Link.tensor Ai Bj)
| par_left {Ai Bj}     : premise Ai (Link.par Ai Bj)
| par_right {Ai Bj}    : premise Bj (Link.par Ai Bj)

inductive conclusion : FormO → Link → Prop
| ax_pos {A i}   : conclusion (FormO.pos (A,i)) (Link.ax (A,i))
| ax_neg {A i}   : conclusion (FormO.neg (A,i)) (Link.ax (A,i))
| tensor {Ai Bi} : conclusion (Ai ⊗ Bi) (Link.tensor Ai Bi)
| par {Ai Bi}    : conclusion (Ai ⊗ Bi) (Link.par Ai Bi)

inductive mem_Link (Ai : FormO) (l : Link) : Prop
| prem : premise Ai l → mem_Link
| con : conclusion Ai l → mem_Link

instance : has_mem FormO Link := ⟨mem_Link⟩

structure proof_structure : Type :=
(links : set Link)
(prem_unique : ∀ Ai : FormO, ∀ l₁ l₂ ∈ links, premise Ai l₁ → premise Ai l₂ → l₁ = l₂)
(con_unique : ∀ Ai : FormO, ∀ l₁ l₂ ∈ links, conclusion Ai l₁ → conclusion Ai l₂ → l₁ = l₂)

inductive mem_FormO_ps (Ai : FormO) (ps : proof_structure) : Prop
| mk {l} : l ∈ ps.links → Ai ∈ l → mem_FormO_ps

instance : has_mem FormO proof_structure := ⟨mem_FormO_ps⟩

@[reducible]
def dir := bool

@[pattern] def down := ff
@[pattern] def up := tt

@[pattern] def with_down (Ai : FormO) := (Ai,down)
@[pattern] def with_up (Ai : FormO) := (Ai,up)
postfix `↓`:max_plus := with_down
postfix `↑`:max_plus := with_up

@[reducible]
def switch := bool

@[reducible, pattern] def L := ff
@[reducible, pattern] def R := tt

def switching := Link → switch

@[simp]
def switch.flip {α β} (f : α → α → β) : switch → α → α → β
| L a b := f a b
| R a b := f b a

inductive steps_tensor (Ai Bi : FormO) : FormO × dir → FormO × dir → Prop
| down : steps_tensor Ai↓ (Ai ⊗ Bi)↓
| turn : steps_tensor Bi↓ Ai↑
| up : steps_tensor (Ai ⊗ Bi)↑ Bi↑

inductive steps_par (Ai Bi : FormO) : FormO × dir → FormO × dir → Prop
| down : steps_par Ai↓ (Ai ⅋ Bi)↓
| turn : steps_par Bi↓ Bi↑
| up : steps_par (Ai ⅋ Bi)↑ Ai↑

inductive steps (T : switch) : Link → FormO × dir → FormO × dir → Prop
| ax_pos  {ai} : steps (Link.ax ai) (FormO.pos ai)↑ (FormO.neg ai)↓
| ax_neg  {ai} : steps (Link.ax ai) (FormO.neg ai)↑ (FormO.pos ai)↓
| cut_pos  {Ai} : steps (Link.cut Ai) Ai↓ (~Ai)↑
| cut_neg  {Ai} : steps (Link.cut Ai) (~Ai)↓ Ai↑
| tensor {Ai Bi X Y} :
  T.flip steps_tensor Ai Bi X Y →
  steps (Link.tensor Ai Bi) X Y
| par {Ai Bi X Y} :
  T.flip steps_par Ai Bi X Y →
  steps (Link.par Ai Bi) X Y

inductive trip (ps : proof_structure) (S : switching) : ℕ → FormO × dir → FormO × dir → Prop
| single {Ai d}    : Ai ∈ ps → trip 0 (Ai,d) (Ai,d)
| cons {X Y Z Δ n} : Δ ∈ ps.links → steps (S Δ) Δ X Y → trip n Y Z → trip (n.succ) X Z

inductive journey (ps : proof_structure) (S : switching) : ℕ → FormO × dir → FormO × dir → Type
| trip {n X Y} : trip ps S n X Y → journey 0 X Y
| chain {Ai n m X Z} : (∀ Δ ∈ ps.links, ¬premise Ai Δ) → trip ps S n X Ai↓ → journey m Ai↑ Z → journey m.succ X Z 

inductive trip2 (ps : proof_structure) (S : switching) : FormO × dir → FormO × dir → Prop
| single (Ai : FormO) (d : dir) : Ai ∈ ps → trip2 (Ai,d) (Ai,d)
| front (Ai Bi Ci : FormO) (d₁ d₂ d₃ : dir) (Δ : Link) :
  Δ ∈ ps.links → steps (S Δ) Δ (Ai,d₁) (Bi,d₂) → trip2 (Bi,d₂) (Ci, d₃) → trip2 (Ai,d₁) (Ci,d₃)
| back (Ai Bi Ci : FormO) (d₁ d₂ d₃ : dir) (Δ : Link) :
  Δ ∈ ps.links → steps (S Δ) Δ (Bi,d₂) (Ci,d₃) → trip2 (Ai,d₁) (Bi, d₂) → trip2 (Ai,d₁) (Ci,d₃)

inductive list_trip (ps : proof_structure) (S : switching) : list (FormO × dir) → Prop
| emp : list_trip []
| single (Ai : FormO) (d : dir) : Ai ∈ ps → list_trip [(Ai,d)]
| cons (Ai Bi : FormO) (d₁ d₂ : dir) (Γ : list (FormO × dir)) (Δ : Link) :
  Δ ∈ ps.links → steps (S Δ) Δ (Ai,d₁) (Bi,d₂) → list_trip ((Bi,d₂) :: Γ) → list_trip ((Ai,d₁) :: (Bi,d₂) :: Γ)

lemma not_self_dual {Ai} : (~Ai) ≠ Ai :=
  by induction Ai; rintro ⟨_⟩

lemma not_self_sub_left_tensor {Ai Bi} : Ai ≠ Ai ⊗ Bi :=
begin
  intro e,
  apply_fun FormO.sizeof at e,
  refine ne_of_lt _ e,
  rw [FormO.sizeof, nat.add_comm],
  apply nat.lt_of_succ_le,
  rw nat.add_comm, rw nat.add_comm 1,
  apply nat.le_add_right,
end

lemma not_self_sub_right_tensor {Ai Bi} : Bi ≠ Ai ⊗ Bi :=
begin
  intro e,
  apply_fun FormO.sizeof at e,
  refine ne_of_lt _ e,
  rw [FormO.sizeof, nat.add_comm],
  apply nat.lt_of_succ_le,
  rw [←nat.add_assoc],
  apply nat.le_add_right,
end

lemma not_self_sub_left_par {Ai Bi} : Ai ≠ Ai ⅋ Bi :=
begin
  intro e,
  apply_fun FormO.sizeof at e,
  refine ne_of_lt _ e,
  rw [FormO.sizeof, nat.add_comm],
  apply nat.lt_of_succ_le,
  rw nat.add_comm, rw nat.add_comm 1,
  apply nat.le_add_right,
end

lemma not_self_sub_right_par {Ai Bi} : Bi ≠ Ai ⅋ Bi :=
begin
  intro e,
  apply_fun FormO.sizeof at e,
  refine ne_of_lt _ e,
  rw [FormO.sizeof, nat.add_comm],
  apply nat.lt_of_succ_le,
  rw [←nat.add_assoc],
  apply nat.le_add_right,
end

section
  variable {Δ : Link}
  variable {T : switch}
  variables {Ai Bi Ci : FormO}
  variables {X Y Z : FormO × dir}

  lemma steps_tensor_unique_prev : Ai ≠ Bi → steps_tensor Ai Bi X Z → steps_tensor Ai Bi Y Z → X = Y :=
  begin
    intros nAB s₁ s₂,
    generalize_hyp e₁ : Z = Z' at s₂,
    cases s₁;
    cases s₂;
    try {refl};
    try { cases e₁, apply absurd rfl nAB};
    try {generalize_hyp e₃ : Ai ⊗ Bi = AiBi at e₁, cases e₁ },
  end

  lemma steps_tensor_unique_next : Ai ≠ Bi → steps_tensor Ai Bi X Y → steps_tensor Ai Bi X Z → Y = Z :=
  begin
    intros nAB s₁ s₂,
    generalize_hyp e₁ : X = X' at s₂,
    cases s₁;
    cases s₂;
    try {refl};
    try { cases e₁, apply absurd rfl nAB};
    try {generalize_hyp e₃ : Ai ⊗ Bi = AiBi at e₁, cases e₁ },
  end

  lemma steps_par_unique_prev : Ai ≠ Bi → steps_par Ai Bi X Z → steps_par Ai Bi Y Z → X = Y :=
  begin
    intros nAB s₁ s₂,
    generalize_hyp e₁ : Z = Z' at s₂,
    cases s₁;
    cases s₂;
    try {refl};
    try { cases e₁, apply absurd rfl nAB};
    try {generalize_hyp e₃ : Ai ⅋ Bi = AiBi at e₁, cases e₁ },
  end

  lemma steps_par_unique_next : Ai ≠ Bi → steps_par Ai Bi X Y → steps_par Ai Bi X Z → Y = Z :=
  begin
    intros nAB s₁ s₂,
    generalize_hyp e₁ : X = X' at s₂,
    cases s₁;
    cases s₂;
    try {refl};
    try { cases e₁, apply absurd rfl nAB};
    try {generalize_hyp e₃ : Ai ⅋ Bi = AiBi at e₁, cases e₁ },
  end

  theorem steps_unique_prev : steps T Δ X Z → steps T Δ Y Z → X = Y :=
  begin
    intros s₁ s₂,
    cases s₁,
    case steps.ax_pos : ai { cases s₂, refl },
    case steps.ax_neg : ai { cases s₂, refl },
    case steps.cut_pos : Ai { 
      generalize_hyp e₁ : (~Ai) = nAi at s₂,
      cases s₂, refl, apply absurd e₁ not_self_dual },
    case steps.cut_neg : Ai { 
      generalize_hyp e₁ : (Ai,up) = Aiu at s₂,
      cases s₂,
      generalize_hyp e₂ : (~Ai) = nAi at e₁,
      cases e₁, apply absurd e₂ not_self_dual, refl },
    case steps.tensor : Ai Bi X Z' t₁ {
      rcases s₂ with _ | _ | _ | _ | ⟨_,_,_,_,t₂⟩,
      cases T; simp at t₁ t₂;
      apply steps_tensor_unique_prev _ t₁ t₂,
      cases hΔ, finish,
      intro e, injection e with e1,
      exact not_self_sub_right_tensor e1,
      intro e, injection e with e1,
      exact not_self_sub_left_tensor e1,
      finish,
      intro e, injection e with e1,
      exact not_self_sub_left_tensor e1,
      intro e, injection e with e1,
      exact not_self_sub_right_tensor e1,
    },
    case steps.par : A B ai bi ci X y p₁ {
      rcases s₂ with _ | _ | _ | ⟨_,_,_,_,_,_,_,p₂⟩,
      cases T; simp at p₁ p₂;
      apply steps_par_unique_prev _ _ _ p₁ p₂;
      cases hΔ, finish,
      intro e, injection e with e1,
      exact not_self_sub_right_par e1,
      intro e, injection e with e1,
      exact not_self_sub_left_par e1,
      finish,
      intro e, injection e with e1,
      exact not_self_sub_left_par e1,
      intro e, injection e with e1,
      exact not_self_sub_right_par e1,
    },
  end

  theorem steps_unique_next : valid_link Δ → steps T Δ X Y → steps T Δ X Z → Y = Z :=
  begin
    intros hΔ s₁ s₂,
    cases s₁,
    case steps.ax : A ai ni Bi Ci d₁ {
      cases s₂ with _ _ _ Di _ d₂,
      rw dual_unique_next d₁ d₂ },
    case steps.cut : A ai ni Bi Ci d₁ {
      rcases s₂ with _ | ⟨_,_,_,Di,_,d₂⟩,
      rw dual_unique_next d₂ d₁
    },
    case steps.tensor : A B ai bi ci X y t₁ {
      rcases s₂ with _ | _ | ⟨_,_,_,_,_,_,_,t₂⟩,
      cases T; simp at t₁ t₂;
      apply steps_tensor_unique_next _ _ _ t₁ t₂;
      cases hΔ, finish,
      intro e, injection e with e1,
      exact not_self_sub_right_tensor e1,
      intro e, injection e with e1,
      exact not_self_sub_left_tensor e1,
      finish,
      intro e, injection e with e1,
      exact not_self_sub_left_tensor e1,
      intro e, injection e with e1,
      exact not_self_sub_right_tensor e1,
    },
    case steps.par : A B ai bi ci X y p₁ {
      rcases s₂ with _ | _ | _ | ⟨_,_,_,_,_,_,_,p₂⟩,
      cases T; simp at p₁ p₂;
      apply steps_par_unique_next _ _ _ p₁ p₂;
      cases hΔ, finish,
      intro e, injection e with e1,
      exact not_self_sub_right_par e1,
      intro e, injection e with e1,
      exact not_self_sub_left_par e1,
      finish,
      intro e, injection e with e1,
      exact not_self_sub_left_par e1,
      intro e, injection e with e1,
      exact not_self_sub_right_par e1,
    },
  end

  lemma con_of_steps_up :
    steps T Δ Ai↑ X → conclusion Ai Δ :=
  begin
    intros s, cases s,
    case steps.ax : A i j Ai Bi u { cases u; constructor, },
    case steps.tensor : A B i j k Ci u { cases T; cases u; constructor },
    case steps.par : A B i j k Ci u { cases T; cases u; constructor },
  end

  lemma prem_of_steps_down :
    steps T Δ Ai↓ X → premise Ai Δ :=
  begin
    intros s, cases s,
    case steps.cut : A i j Ai Bi u { cases u; constructor, },
    case steps.tensor : A B i j k Ci u { cases T; cases u; constructor },
    case steps.par : A B i j k Ci u { cases T; cases u; constructor }
  end

  lemma con_of_steps_down :
    steps T Δ X Ai↓ → conclusion Ai Δ :=
  begin
    intros s, cases s,
    case steps.ax : A i j Ai Bi u { cases u; constructor, },
    case steps.tensor : A B i j k Ci u { cases T; cases u; constructor },
    case steps.par : A B i j k Ci u { cases T; cases u; constructor },
  end

  lemma prem_of_steps_up :
    steps T Δ X Ai↑ → premise Ai Δ :=
  begin
    intros s, cases s,
    case steps.cut : A i j Ai Bi u { cases u; constructor, },
    case steps.tensor : A B i j k Ci u { cases T; cases u; constructor },
    case steps.par : A B i j k Ci u { cases T; cases u; constructor }
  end

  lemma mem_ps_of_steps_prev {ps : proof_structure} {d : dir} :
    Δ ∈ ps.links → steps T Δ (Ai,d) X → Ai ∈ ps :=
  begin
    intros hΔ s, cases d,
    case bool.ff : { exact ⟨hΔ, mem_Link.prem $ prem_of_steps_down s⟩, }, 
    case bool.tt : { exact ⟨hΔ, mem_Link.con $ con_of_steps_up s⟩, }, 
  end

  lemma mem_ps_of_steps_next {ps : proof_structure} {d : dir} :
    Δ ∈ ps.links → steps T Δ X (Bi,d) → Bi ∈ ps :=
  begin
    intros hΔ s, cases d,
    case bool.ff : { exact ⟨hΔ, mem_Link.con $ con_of_steps_down s⟩, }, 
    case bool.tt : { exact ⟨hΔ, mem_Link.prem $ prem_of_steps_up s⟩, }, 
  end

end

section
  variable {ps : proof_structure}
  variable {S : switching}
  variables {X Y Z : FormO × dir}
  variables {n m : ℕ}

  theorem link_unique_of_steps_prev {Δ₁ Δ₂} :
    Δ₁ ∈ ps.links → Δ₂ ∈ ps.links → steps (S Δ₁) Δ₁ X Y → steps (S Δ₂) Δ₂ X Z → Δ₁ = Δ₂ :=
  begin
    intros v₁ v₂ s₁ s₂,
    rcases X with ⟨Ai,⟨_|_⟩⟩,
      apply ps.prem_unique Ai _ _ v₁ v₂ (prem_of_steps_down s₁) (prem_of_steps_down s₂),
    apply ps.con_unique Ai _ _ v₁ v₂ (con_of_steps_up s₁) (con_of_steps_up s₂),
  end

  theorem link_unique_of_steps_next {Δ₁ Δ₂} :
    Δ₁ ∈ ps.links → Δ₂ ∈ ps.links → steps (S Δ₁) Δ₁ X Z → steps (S Δ₂) Δ₂ Y Z → Δ₁ = Δ₂ :=
  begin
    intros v₁ v₂ s₁ s₂,
    rcases Z with ⟨Ci,⟨_|_⟩⟩,
      apply ps.con_unique Ci _ _ v₁ v₂ (con_of_steps_down s₁) (con_of_steps_down s₂),
    apply ps.prem_unique Ci _ _ v₁ v₂ (prem_of_steps_up s₁) (prem_of_steps_up s₂),
  end

  def trip.rcons {Δ} : Δ ∈ ps.links → trip ps S n X Y → steps (S Δ) Δ Y Z → trip ps S n.succ X Z :=
  begin
    revert X Y Z,
    apply nat.strong_induction_on n,
    intros n ih,
    rintros X Y Z hΔ tXY sYZ,
    cases tXY,
    case trip.single : Ai d hA { 
      apply trip.cons hΔ sYZ,
      cases Z with Ci d', simp,
      apply trip.single,
      apply mem_ps_of_steps_next hΔ sYZ,
    },
    case trip.cons : _ W _ Δ' k hΔ' sXW tWY {
      apply trip.cons hΔ' sXW, simp,
      apply ih k (lt_add_one k) hΔ tWY sYZ },
    
  end

  def trip.concat : trip ps S n X Y → trip ps S m Y Z → trip ps S (n + m) X Z :=
  begin
    revert X Y Z n,
    induction m,
    case nat.zero : {
      intros X Y Z _ tXY tYZ,
      cases tYZ,
      exact tXY,
    },
    case nat.succ : m ih {
      intros X Y Z n tXY tYZ,
      rw [nat.add_succ, nat.add_comm, ←nat.add_succ, nat.add_comm],
      cases tYZ with _ _ _ _ W _ Δ' _ hΔ' sYW tWZ,
      apply ih _ tWZ,
      apply trip.rcons hΔ' tXY sYW }
  end

  theorem trip_unique_start : trip ps S n X Z → trip ps S n Y Z → X = Y :=
  begin
    intros tX tY,
    revert X Y,
    induction n,
    case nat.zero : { intros, cases tX; cases tY, refl},
    case nat.succ : n ih {
      rintros X Y tX tY,
      rcases tX with _ | ⟨_,X',_,Δ,_,hΔ,sX,tX'⟩,
      rcases tY with _ | ⟨_,Y',_,Δ',_,hΔ',sY,tY'⟩,
      have : Y' = X', by exact ih tY' tX',
      rw this at sY,
      have : Δ' = Δ, apply link_unique_of_steps_next hΔ' hΔ sY sX,
      rw this at sY,
      exact steps_unique_prev (ps.valid Δ hΔ) sX sY,
      }
  end

  lemma trip_exists_rcons : trip ps S n.succ X Z → ∃ Y Δ, ∃ hΔ : Δ ∈ ps.links, ∃ tXY : trip ps S n X Y, steps (S Δ) Δ Y Z :=
  begin
    revert X,
    induction n,
    case nat.zero : {
      intros X tXZ, cases tXZ with _ _ _ _ Y _ Δ _ hΔ sXY tYZ,
      use X, use Δ, refine ⟨hΔ,_⟩,
      constructor,
      cases X with Ai d,
      constructor,
      apply mem_ps_of_steps_prev hΔ sXY,
      cases tYZ, assumption,
      },
    case nat.succ : n ih {
      intros X tXZ, cases tXZ with _ _ _ _ Y _ Δ _ hΔ sXY tYZ,
      specialize ih tYZ,
      rcases ih with ⟨Y',Δ',hΔ',tYY',sY'Z⟩,
      exact ⟨Y',Δ',hΔ',trip.cons hΔ sXY tYY',sY'Z⟩,
    }
  end

  theorem trip_unique_stop : trip ps S n X Y → trip ps S n X Z → Y = Z :=
  begin
    revert Y Z,
    induction n,
    case nat.zero : { intros _ _ tXY tXZ, cases tXY, cases tXZ, refl },
    case nat.succ : n ih {
      intros Y Z tXY tXZ,
      rcases (trip_exists_rcons tXY) with ⟨U,Δ₁,hΔ₁,tXU, sUY⟩,
      rcases (trip_exists_rcons tXZ) with ⟨V,Δ₂,hΔ₂,tXV, sVZ⟩,
      have : V = U, apply ih tXV tXU,
      rw this at sVZ,
      have : Δ₂ = Δ₁, apply link_unique_of_steps_prev hΔ₂ hΔ₁ sVZ sUY,
      rw this at sVZ,
      apply steps_unique_next (ps.valid Δ₁ hΔ₁) sUY sVZ,
      }
  end

end

