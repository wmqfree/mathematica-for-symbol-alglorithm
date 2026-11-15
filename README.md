# mathematica-for-symbol-alglorithm

用 Mathematica 构建大学物理的**逐步推导本**：每一步都是一个有名字、有理由、可验证的变换。
人决定下一步做什么，机器保证这一步算得对。

当前阶段：大一大二普通物理，第一个样例是简谐振子。

## 文件

| 文件 | 内容 |
| --- | --- |
| `PhysicsDerivation.wl` | 推导引擎 |
| `examples/01-SimpleHarmonicOscillator.wl` | 简谐振子：能量守恒、角频率、相图、与 LC 电路的类比 |
| `tests/SelfCheck.wl` | 自检，应输出 4 个 `True` |

## 在 Wolfram Cloud 中使用

1. 打开 <https://www.wolframcloud.com>，新建一个 Notebook。
2. 把 `PhysicsDerivation.wl` 的全部内容粘贴进第一个单元格，按 Shift+Enter 执行。
3. 把 `tests/SelfCheck.wl` 粘贴进下一个单元格执行，确认 4 项都是 `True`。
4. 把样例文件里的每一节分别粘贴进单元格执行。

本地 Mathematica 可直接加载（文件为 UTF-8 编码）：

```mathematica
Get["PhysicsDerivation.wl", CharacterEncoding -> "UTF-8"]
```

## 一个推导长什么样

```mathematica
DerivationStart[m x''[t] == -k x[t], "牛顿第二定律 + 胡克定律"] //
  MoveAllToLeft[] //
  MultiplyBoth[x'[t], "两边同乘速度"] //
  RecognizeTotalDerivative[t, 1/2 m x'[t]^2 + 1/2 k x[t]^2] //
  IntegrateBoth[t, E0]
```

输出是一张表：步骤、式子、理由、验证（✓ 已验证，✗ 不成立，— 无需或未能自动验证）。

## 可用步骤

| 步骤 | 作用 |
| --- | --- |
| `DerivationStart[expr, 理由]` | 开始推导 |
| `MoveAllToLeft[]` | 移项成 `左边 == 0` |
| `MultiplyBoth[f]` / `DivideBoth[f]` | 两边同乘、同除 |
| `RecognizeTotalDerivative[t, F]` | 你猜 `F`，机器求导验证；省略 `F` 则由机器尝试 |
| `IntegrateBoth[t, c]` | 两边对 `t` 积分 |
| `SubstituteInto[rule]` | 代入，例如试探解 |
| `SolveFor[var, 条件]` | 解出变量，按条件舍根 |
| `CheckDimensions[<|m -> DimM, ...|>]` | 量纲检查，未登记的符号按无量纲处理 |
| `DStep[f, 理由]` | 通用步骤，自动检查前后是否等价 |
| `CurrentExpr[d]` | 取出当前式子 |
