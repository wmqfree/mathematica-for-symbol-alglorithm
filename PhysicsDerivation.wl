(* ::Package:: *)

(* PhysicsDerivation: 逐步推导引擎
   每一步都是一个"有名字、有理由、可验证"的变换。
   人决定下一步做什么，机器保证这一步算得对。
   文件编码: UTF-8 *)

BeginPackage["PhysicsDerivation`"];

Derivation::usage = "Derivation[steps] 是一份推导本，steps 中每一项记录 表达式/理由/验证结果。";
DerivationStart::usage = "DerivationStart[expr, reason] 以 expr 为出发点开始一份推导。";
ShowDerivation::usage = "ShowDerivation[d] 把推导本排成 步骤 | 式子 | 理由 | 验证 的表格。";
CurrentExpr::usage = "CurrentExpr[d] 取出推导本当前(最后一步)的式子。";
DStep::usage = "DStep[f, reason] 通用步骤：对当前式子施加 f，并自动检查前后是否等价。";
MoveAllToLeft::usage = "MoveAllToLeft[] 移项：把方程写成 左边 == 0。";
MultiplyBoth::usage = "MultiplyBoth[f, reason] 方程两边同乘 f。";
DivideBoth::usage = "DivideBoth[f, reason] 方程两边同除以 f。";
RecognizeTotalDerivative::usage = "RecognizeTotalDerivative[t] 尝试把 左边==0 的左边认成对 t 的全导数；RecognizeTotalDerivative[t, F] 由你猜 F，机器求导验证。";
IntegrateBoth::usage = "IntegrateBoth[t, c] 两边对 t 积分，c 为积分常量。";
SubstituteInto::usage = "SubstituteInto[rule, reason] 把 rule 代入当前式子(如试探解)。";
SolveFor::usage = "SolveFor[var, assum, reason] 从当前方程解出 var，assum 用来舍去不合物理的根。";
CheckDimensions::usage = "CheckDimensions[<|m -> DimM, x -> DimL, t -> DimT, ...|>] 检查当前方程各项量纲是否一致。";
AssumeThat::usage = "AssumeThat[text] 记下一条建模假设，最后汇总在推导本末尾。";
State::usage = "State[eq, reason, name] 列出一条新的关系(如守恒律、本构关系)，可选地起个名字。";
NameIt::usage = "NameIt[name] 给当前式子起名字，供之后 UseRelation / Recall 引用。";
UseRelation::usage = "UseRelation[name] 把名为 name 的关系代入当前式子。";
Recall::usage = "Recall[name] 回到名为 name 的关系，从它继续推导。";
Approximate::usage = "Approximate[rule, reason, assumption] 做一次近似替换(如小角近似)，并把适用条件记入假设清单。";
ExpandSmall::usage = "ExpandSmall[dx, n] 把方程两边对小量 dx 泰勒展开并保留到 n 阶。";
TakeLimit::usage = "TakeLimit[dx -> 0] 方程两边取极限。";
DimM::usage = "质量量纲"; DimL::usage = "长度量纲"; DimT::usage = "时间量纲";

Begin["`Private`"];

Derivation::noeq = "当前式子不是方程，这一步无法施加: `1`";
Derivation::nototal = "没能自动把左边认成全导数，请用 RecognizeTotalDerivative[t, F] 给出你的猜测。";
Derivation::nosol = "没能解出 `1`。";
Derivation::norel = "找不到名为 `1` 的关系。";
Derivation::nolim = "极限没能算出来，可先用 ExpandSmall 展开。";

(* ---------- 基础 ---------- *)

DerivationStart[] := Derivation[{}];
DerivationStart[expr_, reason_ : "出发点"] :=
  Derivation[{<|"Expr" -> expr, "Reason" -> reason, "Check" -> None|>}];

(* 当前式子 = 最后一行带式子的记录(纯文字的假设行不算) *)
CurrentExpr[Derivation[steps_List]] :=
  With[{c = Select[steps, ! MissingQ[#["Expr"]] &]},
    If[c === {}, Missing["NoExpr"], Last[c]["Expr"]]];

append[Derivation[steps_List], expr_, reason_, check_, extra_ : <||>] :=
  Derivation[Append[steps,
    Join[<|"Expr" -> expr, "Reason" -> reason, "Check" -> check|>, extra]]];

zeroQ[e_] := TrueQ[Simplify[e] === 0] || TrueQ[Quiet[PossibleZeroQ[e]]];

eqQ[e_] := MatchQ[e, _Equal] && Length[e] == 2;

(* 当前式子是方程时，把左右两边交给 body；否则报错并原样返回 *)
withEq[d_Derivation, body_] :=
  With[{cur = CurrentExpr[d]},
    If[eqQ[cur], body[First[cur], Last[cur]],
      Message[Derivation::noeq, cur]; d]];

auto[reason_, default_] := If[reason === Automatic, default, reason];

(* ---------- 显示 ---------- *)

mark[True] := Style["\[Checkmark]", Darker[Green], Bold];
mark[False] := Style["\[Times]", Red, Bold];
mark["Approx"] := Style["\[TildeTilde]", Orange, Bold];
mark[_] := Style["\[LongDash]", Gray];

(* ----- 纸面书写习惯的显示整理(只影响显示，不改变式子本身) ----- *)

userQ[h_] := MatchQ[h, _Symbol] && Context[h] =!= "System`";
smallQ[s_] := MatchQ[s, _Symbol] && StringStartsQ[SymbolName[s], "\[CapitalDelta]"];

(* 子项此时可能已被 HoldForm 包住，先解开再数小量的幂次 *)
smallOrder[term_] := With[{t = term //. HoldForm[x_] :> x},
  Total[Quiet[Check[Exponent[t, #], 0]] & /@
    Union[Cases[t, x_Symbol /; smallQ[x], {0, Infinity}]]]];
derivOrder[term_] := Max[0,
  Cases[term, Derivative[n__] :> Total[{n}], {0, Infinity}, Heads -> True]];

(* 和式: 小量的低阶项在前，其次高阶导数在前，单独的常量放最后 *)
sortPlus[terms_List] := First /@ SortBy[
  MapIndexed[{#1, {smallOrder[#1], -derivOrder[#1], Boole[AtomQ[#1]], First[#2]}} &, terms], Last];

(* 乘积: 数字、常量符号、小量、函数与导数 *)
factorClass[x_] := Which[
  NumericQ[x], 0,
  smallQ[x] || MatchQ[x, Power[y_ /; smallQ[y], _]], 2,
  MatchQ[x, _Symbol | Power[_Symbol, _]], 1,
  True, 3];
sortTimes[fs_List] := First /@ SortBy[
  MapIndexed[{#1, {factorClass[#1], First[#2]}} &, fs], Last];

reorder[e_] := Replace[e, {
    p_Plus :> (HoldForm[Plus[##]] & @@ sortPlus[List @@ p]),
    t_Times /; FreeQ[List @@ t, _?Negative, {1}] :>
      (HoldForm[Times[##]] & @@ sortTimes[List @@ t])},
  {0, Infinity}];

tbox[e_] := ToBoxes[e, TraditionalForm];

partialForm[f_, vars_List, ns_List] := Inactive[D][f @@ vars,
  Sequence @@ Replace[Select[Transpose[{vars, ns}], Last[#] > 0 &], {v_, 1} :> v, {1}]];

(* 多元函数的偏导数写成 \[PartialD] 记号；自变量不是单个符号时，写成"在某点取值"。
   reorder 之后式子包在 HoldForm 里，所以替换结果要用 With[..., r /; True] 先算好再放进去 *)
pretty[e_, names_Association] := reorder[e] /. {
    Derivative[n__][f_][a__Symbol] /; Length[{n}] == Length[{a}] && Length[{a}] > 1 :>
      With[{r = partialForm[f, {a}, {n}]}, r /; True],
    Derivative[n__][f_][a__] /; Length[{n}] == Length[{a}] && Length[{a}] > 1 &&
        KeyExistsQ[names, f] && Length[names[f]] == Length[{a}] :>
      With[{r = DisplayForm[SubscriptBox[
          RowBox[{tbox[partialForm[f, names[f], {n}]], "\[VerticalSeparator]"}],
          RowBox[Riffle[tbox /@ {a}, ","]]]]}, r /; True]} /. {
    (* 只含一元函数时，全导数写成 d/dt *)
    Inactive[D][F_, t_Symbol] /;
        FreeQ[F, Derivative[_, __]] && FreeQ[F, (h_ /; userQ[h])[_, __]] :>
      With[{r = DisplayForm[RowBox[{FractionBox["d", RowBox[{"d", tbox[t]}]],
        RowBox[{"(", tbox[F], ")"}]}]]}, r /; True]};

(* 从整本推导里找出每个多元函数的自变量名，如 u -> {x, t} *)
argNames[exprs_List] := Association[Cases[exprs,
  (Derivative[__][f_] | f_)[a__Symbol] /; userQ[f] && Length[{a}] > 1 :> (f -> {a}),
  {0, Infinity}]];

showExpr[e_, names_] := If[MissingQ[e], "", TraditionalForm[pretty[e, names]]];

showIndex[i_, st_] := If[KeyExistsQ[st, "Label"],
  Column[{i, Style[Row[{"[", st["Label"], "]"}], Gray, Small]}, Alignment -> Center], i];

ShowDerivation[Derivation[steps_List]] :=
  With[{names = argNames[Lookup[steps, "Expr"]]}, With[{
    grid = Grid[
      Prepend[
        MapIndexed[
          {showIndex[First[#2], #1], showExpr[#1["Expr"], names], #1["Reason"], mark[#1["Check"]]} &,
          steps],
        Style[#, Bold] & /@ {"步骤", "式子", "理由", "验证"}],
      Alignment -> {{Center, Left, Left, Center}},
      Dividers -> {False, {2 -> Gray}},
      Spacings -> {2, 1.2}],
    as = DeleteDuplicates[DeleteMissing[Lookup[steps, "Assume"]]]},
    If[as === {}, grid,
      Column[{grid,
        Column[Prepend[Row[{"\[Bullet] ", #}] & /@ as,
          Style["本推导的假设与近似", Bold]]]}, Spacings -> 1.5]]]];

Format[d : Derivation[_List]] := ShowDerivation[d];

(* ---------- 通用步骤 ---------- *)

(* 方程: 新旧"左边-右边"只差一个非零常数因子 => 等价; 表达式: 差为零 => 相等 *)
equivalent[old_, new_] :=
  Which[
    eqQ[old] && eqQ[new],
      With[{a = First[old] - Last[old], b = First[new] - Last[new]},
        Which[
          zeroQ[a - b], True,
          NumericQ[Simplify[b/a]] && ! zeroQ[b], True,
          True, None]],
    eqQ[old] || eqQ[new], None,
    True, zeroQ[old - new]];

DStep[f_, reason_ : "变形"][d_Derivation] :=
  With[{old = CurrentExpr[d]},
    With[{new = f[old]}, append[d, new, reason, equivalent[old, new]]]];

(* ---------- 具名步骤 ---------- *)

MoveAllToLeft[reason_ : "移项，把所有项放到左边"][d_Derivation] :=
  withEq[d, Function[{l, r}, append[d, l - r == 0, reason, True]]];

MultiplyBoth[f_, reason_ : Automatic][d_Derivation] :=
  withEq[d, Function[{l, r},
    With[{nl = Expand[l f], nr = Expand[r f]},
      append[d, nl == nr,
        auto[reason, Row[{"两边同乘 ", TraditionalForm[f]}]],
        zeroQ[(nl - nr) - f (l - r)]]]]];

DivideBoth[f_, reason_ : Automatic][d_Derivation] :=
  withEq[d, Function[{l, r},
    With[{nl = Simplify[l/f], nr = Simplify[r/f]},
      append[d, nl == nr,
        auto[reason, Row[{"两边同除以 ", TraditionalForm[f]}]],
        zeroQ[(nl - nr) f - (l - r)]]]]];

(* 由学生给出猜测 F，机器求导验证 *)
RecognizeTotalDerivative[t_, F_, reason_ : Automatic][d_Derivation] :=
  withEq[d, Function[{l, r},
    With[{diff = Simplify[D[F, t] - (l - r)]},
      If[zeroQ[diff],
        append[d, Inactive[D][F, t] == 0,
          auto[reason, "左边恰好是一个全导数(求导验证通过)"], True],
        append[d, l == r,
          Row[{"猜测不成立: 对它求导后与左边相差 ", TraditionalForm[diff]}], False]]]]];

(* 机器自己找 F *)
RecognizeTotalDerivative[t_][d_Derivation] :=
  withEq[d, Function[{l, r},
    With[{F = Quiet[Integrate[l - r, t]]},
      If[FreeQ[F, Integrate] && zeroQ[D[F, t] - (l - r)],
        append[d, Inactive[D][F, t] == 0, "左边恰好是一个全导数", True],
        Message[Derivation::nototal]; d]]]];

IntegrateBoth[t_, c_, reason_ : Automatic][d_Derivation] :=
  withEq[d, Function[{l, r},
    If[MatchQ[l, Inactive[D][_, t]] && r === 0,
      append[d, First[l] == c,
        auto[reason, Row[{"对 ", t, " 积分: 全导数为零，括号内是常量 ", c}]], True],
      With[{nl = Quiet[Integrate[l, t]], nr = Quiet[Integrate[r, t]] + c},
        append[d, nl == nr,
          auto[reason, Row[{"两边对 ", t, " 积分"}]],
          FreeQ[{nl, nr}, Integrate] && zeroQ[D[nl - nr, t] - (l - r)]]]]]];

SubstituteInto[rule_, reason_ : Automatic][d_Derivation] :=
  append[d, CurrentExpr[d] /. rule,
    auto[reason, Row[{"代入 ", TraditionalForm[rule]}]], None];

SolveFor[var_, assum_ : True, reason_ : Automatic][d_Derivation] :=
  withEq[d, Function[{l, r},
    Module[{rules, sols, kept},
      rules = Quiet[Solve[l == r, var]];
      If[! MatchQ[rules, {{_Rule} ..}],
        Message[Derivation::nosol, var]; d,
        sols = var /. rules;
        kept = Select[sols, Simplify[assum /. var -> #, assum] =!= False &];
        If[kept === {}, kept = sols];
        append[d,
          If[Length[kept] == 1, var == First[kept], Or @@ (var == # & /@ kept)],
          auto[reason, Row[{"解出 ", var}]],
          AllTrue[kept, zeroQ[(l - r) /. var -> #] &]]]]]];

(* ---------- 建模步骤 ---------- *)

AssumeThat[text_][d_Derivation] :=
  append[d, Missing["Note"], Row[{"假设: ", text}], None, <|"Assume" -> text|>];

State[eq_, reason_ : "列出关系", name_ : None][d_Derivation] :=
  append[d, eq, reason, None, If[name === None, <||>, <|"Label" -> name|>]];

NameIt[name_][Derivation[steps_List]] :=
  Derivation[Append[Most[steps], Append[Last[steps], "Label" -> name]]];

findRelation[Derivation[steps_List], name_] :=
  SelectFirst[Reverse[steps], Lookup[#, "Label", None] === name &, Missing["NotFound"]];

(* q[x,t] == 式子 这类关系当作函数定义来代入，这样 q[x+dx,t] 也能被替换 *)
relationRule[l_ == r_] :=
  If[MatchQ[l, _Symbol[__Symbol]] && With[{h = Head[l]}, Context[h]] =!= "System`",
    With[{vs = List @@ l, body = r}, Head[l] -> (Function @@ {vs, body})],
    l -> r];

UseRelation[name_, reason_ : Automatic][d_Derivation] :=
  With[{st = findRelation[d, name], old = CurrentExpr[d]},
    If[MissingQ[st] || ! eqQ[st["Expr"]],
      Message[Derivation::norel, name]; d,
      With[{new = old /. relationRule[st["Expr"]]},
        append[d, new, auto[reason, Row[{"代入 [", name, "]"}]],
          If[new === old, None, True]]]]];

Recall[name_][d_Derivation] :=
  With[{st = findRelation[d, name]},
    If[MissingQ[st], Message[Derivation::norel, name]; d,
      append[d, st["Expr"], Row[{"回到 [", name, "]"}], None]]];

Approximate[rule_, reason_ : "近似", assumption_ : None][d_Derivation] :=
  append[d, CurrentExpr[d] /. rule, reason, "Approx",
    If[assumption === None, <||>, <|"Assume" -> assumption|>]];

ExpandSmall[dx_, n_Integer : 1, reason_ : Automatic][d_Derivation] :=
  withEq[d, Function[{l, r},
    With[{nl = Normal[Series[l, {dx, 0, n}]], nr = Normal[Series[r, {dx, 0, n}]]},
      append[d, nl == nr,
        auto[reason, Row[{"对小量 ", dx, " 泰勒展开，保留到 ", n, " 阶"}]],
        "Approx"]]]];

TakeLimit[rule_Rule, reason_ : Automatic][d_Derivation] :=
  withEq[d, Function[{l, r},
    With[{nl = Limit[l, rule], nr = Limit[r, rule]},
      If[! FreeQ[{nl, nr}, Limit],
        Message[Derivation::nolim]; d,
        append[d, nl == nr,
          auto[reason, Row[{"取极限 ", TraditionalForm[rule]}]], True]]]]];

(* ---------- 量纲检查 ---------- *)

Format[DimM] := "M"; Format[DimL] := "L"; Format[DimT] := "T";

(* 未在 dims 中登记的符号按无量纲处理 *)
dimOf[expr_, dims_Association] :=
  Module[{look, e, num},
    look[s_] := Lookup[dims, s, 1];
    e = expr /. Inactive[D][f_, v_] :> f/v;
    e = e /. Derivative[n__][f_][v__Symbol] :> look[f]/Times @@ ((look /@ {v})^{n});
    e = e /. f_Symbol[__] /; KeyExistsQ[dims, f] :> dims[f];
    e = PowerExpand[e /. Normal[dims]];
    num = e /. {DimM -> 1, DimL -> 1, DimT -> 1};
    If[zeroQ[num], e, PowerExpand[e/num]]];

terms[e_] := With[{x = Expand[e]}, DeleteCases[If[Head[x] === Plus, List @@ x, {x}], 0]];

CheckDimensions[dims_Association][d_Derivation] :=
  withEq[d, Function[{l, r},
    With[{ds = DeleteDuplicates[dimOf[#, dims] & /@ Join[terms[l], terms[r]]]},
      append[d, l == r,
        If[Length[ds] == 1,
          Row[{"量纲检查: 各项量纲均为 ", First[ds]}],
          Row[{"量纲不一致: 出现了 ", ds}]],
        Length[ds] == 1]]]];

End[];
EndPackage[];
