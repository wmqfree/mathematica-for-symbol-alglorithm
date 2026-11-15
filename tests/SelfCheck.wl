(* 自检: 加载 PhysicsDerivation.wl 后执行本文件，每一项都应为 True *)
Module[{eq = m x''[t] == -k x[t], d1, d2, bad, dim, wave, heat, dx = \[CapitalDelta]x},
  d1 = DerivationStart[eq] // MoveAllToLeft[] // MultiplyBoth[x'[t]] //
    RecognizeTotalDerivative[t, 1/2 m x'[t]^2 + 1/2 k x[t]^2] // IntegrateBoth[t, E0];
  d2 = DerivationStart[eq] //
    SubstituteInto[x -> Function[t, A Cos[\[Omega] t + \[Phi]]]] //
    DivideBoth[A Cos[\[Omega] t + \[Phi]]] //
    SolveFor[\[Omega], \[Omega] > 0 && k > 0 && m > 0];
  bad = DerivationStart[eq] // MoveAllToLeft[] // MultiplyBoth[x'[t]] //
    RecognizeTotalDerivative[t, m x'[t]^2 + 1/2 k x[t]^2];
  dim = DerivationStart[eq] //
    CheckDimensions[<|m -> DimM, k -> DimM/DimT^2, x -> DimL, t -> DimT|>];
  wave = DerivationStart[] //
    State[\[Rho] dx Derivative[0, 2][u][x, t] == T Sin[\[Theta][x + dx, t]] - T Sin[\[Theta][x, t]]] //
    Approximate[Sin[\[Theta][a_, b_]] :> Derivative[1, 0][u][a, b]] //
    ExpandSmall[dx, 2] // DivideBoth[dx] // TakeLimit[dx -> 0];
  heat = DerivationStart[] //
    State[q[x, t] == -\[Kappa] Derivative[1, 0][u][x, t], "", "F"] //
    State[cv \[Rho] dx Derivative[0, 1][u][x, t] == q[x, t] - q[x + dx, t]] //
    UseRelation["F"] // ExpandSmall[dx, 2] // DivideBoth[dx] // TakeLimit[dx -> 0];
  {
    "波动方程" -> (CurrentExpr[wave] === (\[Rho] Derivative[0, 2][u][x, t] == T Derivative[2, 0][u][x, t])),
    "热传导方程" -> (CurrentExpr[heat] === (cv \[Rho] Derivative[0, 1][u][x, t] == \[Kappa] Derivative[2, 0][u][x, t])),
    "能量守恒" -> (CurrentExpr[d1] === (1/2 m x'[t]^2 + 1/2 k x[t]^2 == E0)),
    "角频率" -> TrueQ[Simplify[(\[Omega] /. First[Solve[CurrentExpr[d2], \[Omega]]]) == Sqrt[k/m], k > 0 && m > 0]],
    "错误猜测被拦下" -> (Last[First[bad]]["Check"] === False),
    "量纲一致" -> (Last[First[dim]]["Check"] === True)
  }]
