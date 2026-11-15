(* 自检: 加载 PhysicsDerivation.wl 后执行本文件，应输出 4 个 True *)
Module[{eq = m x''[t] == -k x[t], d1, d2, bad, dim},
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
  {
    "能量守恒" -> (CurrentExpr[d1] === (1/2 m x'[t]^2 + 1/2 k x[t]^2 == E0)),
    "角频率" -> TrueQ[Simplify[(\[Omega] /. First[Solve[CurrentExpr[d2], \[Omega]]]) == Sqrt[k/m], k > 0 && m > 0]],
    "错误猜测被拦下" -> (Last[First[bad]]["Check"] === False),
    "量纲一致" -> (Last[First[dim]]["Check"] === True)
  }]
