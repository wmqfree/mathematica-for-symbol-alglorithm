(* ::Package:: *)

(* 样例 02: 从一小段弦出发，建立波动方程 —— 建模在先，求解在后
   思考链: 物理图像 -> 取微元 -> 列关系 -> 近似 -> 取极限 -> 方程 -> 求解 *)

(* ===== 第 1 节: 建模 ===== *)
(* u(x,t) 是弦在位置 x、时刻 t 的横向位移；\[Theta] 是弦与水平方向的夹角。
   取 [x, x+\[CapitalDelta]x] 这一小段，质量 \[Rho]\[CapitalDelta]x，两端各受张力 T，方向沿切线。 *)

wave = DerivationStart[] //
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
  NameIt["波动方程"]


(* ===== 第 2 节: 求解 —— 行波与波速 ===== *)
(* 猜测: 波形 f 不变，整体以速度 c 向右平移 *)

wave //
  SubstituteInto[u -> Function[{x, t}, f[x - c t]],
    "试探解: 形状不变、以速度 c 平移的波 u = f(x - ct)"] //
  DivideBoth[f''[x - c t], "约去公因子 f''"] //
  SolveFor[c, c > 0 && T > 0 && \[Rho] > 0, "解出波速，取正根"]

(* 波速只由弦本身决定(张力与线密度)，与波形 f 无关 *)


(* ===== 第 3 节: 规律识别 —— 驻波的空间部分就是简谐振子 ===== *)

wave //
  SubstituteInto[u -> Function[{x, t}, X[x] Cos[\[Omega] t]],
    "试探解: 各点同步振动 u = X(x) cos(\[Omega]t)"] //
  DivideBoth[Cos[\[Omega] t], "约去公因子"]

(* 得到 T X'' = -\[Rho]\[Omega]^2 X，与样例 01 的 m x'' = -k x 是同一个方程，
   只是自变量从时间换成了空间: 所以驻波的形状是正弦 *)
