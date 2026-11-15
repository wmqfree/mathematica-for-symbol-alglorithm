Column[{
 DerivationStart[m x''[t] == -k x[t], "牛顿第二定律 + 胡克定律"] //
  MoveAllToLeft[] // MultiplyBoth[x'[t]] //
  RecognizeTotalDerivative[t, m x'[t]^2 + 1/2 k x[t]^2],
 DerivationStart[m x''[t] == -k x[t], "运动方程"] //
  SubstituteInto[x -> Function[t, A Cos[\[Omega] t + \[Phi]]], "试探解 x = A cos(\[Omega]t + \[Phi])"] //
  DivideBoth[A Cos[\[Omega] t + \[Phi]], "对任意时刻都成立，约去公因子"] //
  SolveFor[\[Omega], \[Omega] > 0 && k > 0 && m > 0, "解出角频率，取正根"],
 DerivationStart[Lind q''[t] == -q[t]/Cap, "LC 回路: 基尔霍夫电压定律"] //
  SubstituteInto[q -> Function[t, Q Cos[\[Omega] t + \[Phi]]]] //
  DivideBoth[Q Cos[\[Omega] t + \[Phi]], "约去公因子"] //
  SolveFor[\[Omega], \[Omega] > 0 && Lind > 0 && Cap > 0, "解出角频率，取正根"],
 DerivationStart[m x''[t] == -k x[t]] // MoveAllToLeft[] // MultiplyBoth[x'[t]] // RecognizeTotalDerivative[t]
}, Spacings -> 2]
