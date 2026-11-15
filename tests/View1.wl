d1 = DerivationStart[m x''[t] == -k x[t], "牛顿第二定律 + 胡克定律"] //
  CheckDimensions[<|m -> DimM, k -> DimM/DimT^2, x -> DimL, t -> DimT|>] //
  MoveAllToLeft[] //
  MultiplyBoth[x'[t], "两边同乘速度 x'(t): 力 \[Times] 速度 = 功率"] //
  RecognizeTotalDerivative[t, 1/2 m x'[t]^2 + 1/2 k x[t]^2] //
  IntegrateBoth[t, E0]
