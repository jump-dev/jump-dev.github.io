---
layout: post
title:  "An Open Energy Modeling update"
date:   2024-11-14
categories: [open-energy-modeling]
author: "Oscar Dowson, Ivet Galabova, Joaquim Dias Garcia, Julian Hall"
---

We're now two months into our [Open Energy Modeling project](/announcements/open-energy-modeling/2024/09/16/oem/).
Here's a summary of some of things that we have been up to.

If you are an open energy modeller who uses JuMP or HiGHS and you want to stay
in touch with our progress or provide us with feedback and examples, write to
`jump-highs-energy-models@googlegroups.com`. We'd love to hear how you are using
JuMP or HiGHS to solve problems related to open energy modelling.

## open-energy-modeling-benchmarks

We have made good progress on our main task of creating the
[open-energy-modeling-benchmarks](https://github.com/jump-dev/open-energy-modeling-benchmarks)
repository of benchmark instances. We now include models from [GenX](https://github.com/GenXProject/GenX.jl),
[PowerModels](https://github.com/lanl-ansi/PowerModels.jl),
[Sienna](https://github.com/nrel-sienna), and [TulipaEnergyModel](https://github.com/TulipaEnergy/TulipaEnergyModel.jl).

Now that we have the initial framework in place, our focus is shifting to
profiling each of the implementations to find improvements.

We've already started doing this with [GenX](https://github.com/GenXProject/GenX.jl/pull/773).
Our work identified the root cause of a performance problem as an [issue in MutableArithmetics.jl](https://github.com/jump-dev/MutableArithmetics.jl/issues/302)
that we have since fixed.

## Tolerances and numerical issues

One thing that has become very clear as we look at a range of energy system
models is that poor scaling and numerical issues are quite common.

Understanding the impact that problem scaling and the tolerances used within the
solver have on the final solution is an important aspect of applied optimization.

We've added a new tutorial to the JuMP documentation, [Tolerances and numerical issues](https://jump.dev/JuMP.jl/stable/tutorials/getting_started/tolerances/),
which explains how solvers like HiGHS use numerical tolerances and what can go
wrong. We encourage all modelers to read it.

## HiGHS

In the last two months we released HiGHS [v1.8.0](https://github.com/ERGO-Code/HiGHS/releases/tag/v1.8.0)
and [v1.8.1](https://github.com/ERGO-Code/HiGHS/releases/tag/v1.8.1). See the
links for the full release notes.

HiGHlights (if you will) for energy modelers include:

 * Our initial benchmarking and analysis of energy system models also exposed a
   few bugs. For example, we fixed a [segfault in the QP solver](https://github.com/ERGO-Code/HiGHS/issues/1990),
   fixed a [problem detecting unboundedness](https://github.com/ERGO-Code/HiGHS/issues/1962),
   and we fixed a [correctness issue](https://github.com/ERGO-Code/HiGHS/issues/1935)
   for badly scaled models when crossover was explicitly turned off.
 * We fixed the issue of HiGHS hanging on Windows when `threads` was set to a
   value other than `1`. In most cases, setting `threads` to a value other than
   `1` has limited performance benefits, but this will change in future releases
   as we implement a parallel MIP solver.
 * HiGHS now always computes a primal and dual unbounded ray if queried, even if
   the initial unboundedness was detected in presolve. For energy modelers, the
   dual ray is useful for implementing decomposition algorithms such as Benders
   decomposition where it shows up in the Benders feasibility cut. We rewrote
   the [Benders decomposition tutorial](https://jump.dev/JuMP.jl/stable/tutorials/algorithms/benders_decomposition/)
   in the JuMP documentation to simplify the implementation and add feasibility
   cuts; it's a good place to start if you are interested in implementing
   Benders.
 * Related to the dual ray, HiGHS now also computes the dual objective value,
   which is necessary for both Benders feasibility and optimality cuts.
 * HiGHS now computes the primal-dual integral, which is a quantitiative measure
   of solver performance. We intend to use the primal-dual integral as part of
   our benchmarking efforts of future solver performance.

## HiGHS.jl

We've had a fairly busy few months in HiGHS.jl, with frequent small releases
([v1.9.3](https://github.com/jump-dev/HiGHS.jl/releases/tag/v1.9.3),
[v1.10.0](https://github.com/jump-dev/HiGHS.jl/releases/tag/v1.10.0),
[v1.10.1](https://github.com/jump-dev/HiGHS.jl/releases/tag/v1.10.1),
[v1.10.2](https://github.com/jump-dev/HiGHS.jl/releases/tag/v1.10.2),
[v1.11.0](https://github.com/jump-dev/HiGHS.jl/releases/tag/v1.11.0),
[v1.12.0](https://github.com/jump-dev/HiGHS.jl/releases/tag/v1.12.0), and
[v1.12.1](https://github.com/jump-dev/HiGHS.jl/releases/tag/v1.12.1); see the
links for a full list of changes).

 * A big change was how we compute the dual objective value. As explained above,
   this is mostly useful for algorithms such as Benders decomposition.
   Previously, we used the default fallback in MathOptInterface. This
   implementation looped over every constraint in the model to compute the inner
   product between the set and the dual. However, due to [HiGHS.jl#207](https://github.com/jump-dev/HiGHS.jl/issues/207),
   this algorithm had unintentional `O(N^2)` scaling behavior. (We found one
   example where computing the dual objective value took over 200 seconds.) We
   fixed this issue in HiGHS.jl by manually computing the dual objective value
   using a different set of C API calls to HiGHS. (The model that took 200
   seconds to compute the dual objective value for now takes less than 0.01
   second.) Motivated by this result, Julian added support for computing the
   dual objective value to HiGHS, which was released in v1.8.1.
 * Somewhat related to the dual objective value, we also changed the definition
   of `MOI.ObjectiveBound` and `MOI.RelativeGap` for linear programs to return
   the  dual objective value as the objective bound, and the relative difference
   between the primal and dual objective values as the relative gap. This is
   useful for quantifying the quality of solutions that use the interior point
   algorithm and slightly looser optimality tolerances.
 * We improved the performance of adding a bounded variable like
   `@variable(model, l <= x <= u)` from JuMP when HiGHS is used with
   `JuMP.direct_model`. The new method of adding the variable is three times
   faster than before. This is particularly noticeable if you have a model with
   a very large number of variables, a small number of constraints, and the
   model is simple to solve.

Stay tuned for future updates!