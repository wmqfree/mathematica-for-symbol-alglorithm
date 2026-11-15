Column[{
(heat = DerivationStart[] //
  AssumeThat["细杆均匀，侧面绝热，热量只沿杆的方向流动"] //
  State[q[x, t] == -\[Kappa] Derivative[1, 0][u][x, t],
    "傅里叶定律: 热流正比于温度梯度，由高温流向低温", "傅里叶定律"] //
  State[cv \[Rho] \[CapitalDelta]x Derivative[0, 1][u][x, t] ==
      q[x, t] - q[x + \[CapitalDelta]x, t],
    "微元 [x, x+\[CapitalDelta]x] 的能量守恒: 内能增加率 = 左端流入 - 右端流出", "能量守恒"] //
  UseRelation["傅里叶定律"] //
  ExpandSmall[\[CapitalDelta]x, 2] //
  DivideBoth[\[CapitalDelta]x] //
  TakeLimit[\[CapitalDelta]x -> 0, "令微元长度趋于零，高阶小量消失"] //
  NameIt["热传导方程"])
}, Spacings -> 2]
