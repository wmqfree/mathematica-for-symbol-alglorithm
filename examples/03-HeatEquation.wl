(* ::Package:: *)

(* 样例 03: 热传导方程 —— 同一套"微元"动作，把牛顿定律换成能量守恒
   这里同时有两条关系: 守恒律 和 本构关系(傅里叶定律)，推导时把后者代入前者 *)

(* u(x,t) 温度，q(x,t) 热流密度，cv 比热容，\[Rho] 线密度，\[Kappa] 热导率 *)

heat = DerivationStart[] //
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
  NameIt["热传导方程"]

(* 对比样例 02: 微元、展开、除以 \[CapitalDelta]x、取极限 这四步完全相同。
   区别只在时间导数的阶数: 波动方程是二阶(可逆的振荡)，热传导是一阶(不可逆的抹平) *)
