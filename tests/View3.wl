Column[{
(wave = DerivationStart[] //
  AssumeThat["弦均匀、柔软，线密度 \[Rho] 为常量"] //
  AssumeThat["张力 T 处处相等，重力与阻尼可忽略"] //
  State[\[Rho] \[CapitalDelta]x Derivative[0, 2][u][x, t] ==
      T Sin[\[Theta][x + \[CapitalDelta]x, t]] - T Sin[\[Theta][x, t]],
    "对微元 [x, x+\[CapitalDelta]x] 列横向的牛顿第二定律", "微元方程"] //
  Approximate[Sin[\[Theta][a_, b_]] :> Derivative[1, 0][u][a, b],
    "小角近似: sin\[Theta] \[TildeTilde] tan\[Theta] = 弦的斜率 \[PartialD]u/\[PartialD]x",
    "小振幅: 弦的斜率远小于 1"] //
  ExpandSmall[\[CapitalDelta]x, 2] //
  DivideBoth[\[CapitalDelta]x] //
  TakeLimit[\[CapitalDelta]x -> 0, "令微元长度趋于零，高阶小量消失"] //
  NameIt["波动方程"]),
(wave //
  SubstituteInto[u -> Function[{x, t}, f[x - c t]],
    "试探解: 形状不变、以速度 c 平移的波 u = f(x - ct)"] //
  DivideBoth[f''[x - c t], "约去公因子 f''"] //
  SolveFor[c, c > 0 && T > 0 && \[Rho] > 0, "解出波速，取正根"]),
(wave //
  SubstituteInto[u -> Function[{x, t}, X[x] Cos[\[Omega] t]],
    "试探解: 各点同步振动 u = X(x) cos(\[Omega]t)"] //
  DivideBoth[Cos[\[Omega] t], "约去公因子"])
}, Spacings -> 2]
