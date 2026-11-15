(* ::Package:: *)

(* 样例 01: 简谐振子 —— 面向大一大二普通物理
   用法: 先执行 PhysicsDerivation.wl 的全部内容(或 Get 它)，
   再把下面每一节各放进一个单元格依次执行。 *)

(* ===== 第 1 节: 从牛顿定律到能量守恒 ===== *)
(* 思路: 运动方程是二阶的；两边乘速度后，左边变成一个全导数，
   积分一次就得到守恒量——机械能。 *)

d1 = DerivationStart[m x''[t] == -k x[t], "牛顿第二定律 + 胡克定律"] //
  CheckDimensions[<|m -> DimM, k -> DimM/DimT^2, x -> DimL, t -> DimT|>] //
  MoveAllToLeft[] //
  MultiplyBoth[x'[t], "两边同乘速度 x'(t): 力 \[Times] 速度 = 功率"] //
  RecognizeTotalDerivative[t, 1/2 m x'[t]^2 + 1/2 k x[t]^2] //
  IntegrateBoth[t, E0]

(* 试一试: 把上面的猜测改错，例如去掉动能项的 1/2，看机器如何指出差在哪里 *)

DerivationStart[m x''[t] == -k x[t], "牛顿第二定律 + 胡克定律"] //
  MoveAllToLeft[] //
  MultiplyBoth[x'[t]] //
  RecognizeTotalDerivative[t, m x'[t]^2 + 1/2 k x[t]^2]


(* ===== 第 2 节: 试探解与角频率 ===== *)
(* 思路: 方程说"加速度正比于负位移"，余弦函数求导两次正好回到负的自己。 *)

d2 = DerivationStart[m x''[t] == -k x[t], "运动方程"] //
  SubstituteInto[x -> Function[t, A Cos[\[Omega] t + \[Phi]]],
    "试探解 x = A cos(\[Omega]t + \[Phi])"] //
  DivideBoth[A Cos[\[Omega] t + \[Phi]], "对任意时刻都成立，约去公因子"] //
  SolveFor[\[Omega], \[Omega] > 0 && k > 0 && m > 0, "解出角频率，取正根"]

(* 注意结果里没有振幅 A: 周期与振幅无关(等时性) *)


(* ===== 第 3 节: 图像 —— 能量守恒就是相空间里的椭圆 ===== *)

(* 每条等能线是一个椭圆，能量越大椭圆越大 *)
ContourPlot[1/2 v^2 + 1/2 x^2, {x, -2, 2}, {v, -2, 2},
  Contours -> {0.1, 0.5, 1, 1.5}, ContourShading -> None,
  FrameLabel -> {"位移 x", "速度 v"}, PlotLabel -> "等能线 (m = k = 1)"]

(* 拖动参数: 左图是 x(t)，右图是同一运动在相空间里的轨迹 *)
Manipulate[
  Module[{w = Sqrt[k/m], pos, vel},
    pos[s_] := A Cos[w s]; vel[s_] := -A w Sin[w s];
    GraphicsRow[{
      Plot[pos[s], {s, 0, 10}, PlotRange -> {-2.2, 2.2},
        AxesLabel -> {"t", "x"},
        Epilog -> {Red, PointSize[Large], Point[{t, pos[t]}]}],
      ParametricPlot[{pos[s], vel[s]}, {s, 0, 2 Pi/w},
        PlotRange -> {{-2.2, 2.2}, {-10.5, 10.5}}, AspectRatio -> 1,
        AxesLabel -> {"x", "v"},
        Epilog -> {Red, PointSize[Large], Point[{pos[t], vel[t]}]}]},
      ImageSize -> 600]],
  {{A, 1, "振幅 A"}, 0.2, 2},
  {{k, 1, "劲度系数 k"}, 0.2, 5},
  {{m, 1, "质量 m"}, 0.2, 5},
  {{t, 0, "时间 t"}, 0, 10}]


(* ===== 第 4 节: 规律识别 —— LC 电路是同一个方程 ===== *)
(* 把 m 换成电感 Lind，k 换成 1/Cap，x 换成电荷 q，推导一步不改 *)

d3 = DerivationStart[Lind q''[t] == -q[t]/Cap, "LC 回路: 基尔霍夫电压定律"] //
  SubstituteInto[q -> Function[t, Q Cos[\[Omega] t + \[Phi]]],
    "试探解 q = Q cos(\[Omega]t + \[Phi])"] //
  DivideBoth[Q Cos[\[Omega] t + \[Phi]], "约去公因子"] //
  SolveFor[\[Omega], \[Omega] > 0 && Lind > 0 && Cap > 0, "解出角频率，取正根"]
