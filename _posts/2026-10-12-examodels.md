---
layout: post
title:  "ExaModels and JuMP"
date:   2026-10-12
categories: [open-energy-modeling]
author: "The JuMP developers"
---

At JuMP-dev 2026, Sungho Shin, the developer of ExaModels, gave a talk
[Can ExaModels Power JuMP on GPUs?](https://youtu.be/67-_Xmgxf1c) In this blog
post, we answer that question, and show how you can use ExaModels with existing
JuMP models.

## Background

[ExaModels](https://github.com/madsuite-org/ExaModels.jl) is an algebraic
modeling system for nonlinear programs. It differs from JuMP in some novel ways,
including a modeling API that builds up immutable data structures, a type-based
automatic differentiation engine, and support for GPUs.

The key idea in ExaModels is that large nonlinear programs are rarely a random
collection of unrelated expressions. Instead, they tend to consist of a small
number of expression "patterns," each of which is repeated many times over
different data. For example, the power flow constraint for each line in an
electricity network has the same algebraic form with differing numeric data.
ExaModels' modeling API forces the user to provide (via Julia's generator
syntax) the expression pattern and list of input data. ExaModels compiles the
derivative code for each pattern once, and then evaluates it in parallel over
the data. This idea is similar to the ideas implemented in our
[MOI.Nonlinear.SymbolicAD](https://jump.dev/MathOptInterface.jl/stable/submodules/Nonlinear/SymbolicAD/)
submodule. The main difference is that MOI uses an interpreter, whereas
ExaModels uses the Julia type system.

Here's an example of ExaModels in action:
```julia
using ExaModels, NLPModelsIpopt
N = 1000
c = ExaCore(; concrete = Val(true))
@add_var(c, t, N + 1; lvar = -1, uvar = 1)
@add_var(c, x, N + 1; lvar = -0.05, uvar = 0.05)
@add_var(c, u, N + 1)
@add_obj(c, (u[i+1]^2 + u[i]^2) / 2N for i in 1:N)
@add_obj(c, 350 * (cos(t[i+1]) + cos(t[i])) / 2N for i in 1:N)
@add_con(c, x[i+1] - x[i] - (sin(t[i+1]) + sin(t[i])) / 2N for i in 1:N)
@add_con(c, t[i+1] - t[i] - (u[i+1] + u[i]) / 2N for i in 1:N)
m = ExaModel(c)
result = NLPModelsIpopt.ipopt(m)
result.objective  # 350.0
```
and here's the corresponding code in JuMP:
```julia
using JuMP, Ipopt
N = 1000
model = Model(Ipopt.Optimizer)
@variable(model, -1 <= t[1:(N+1)] <= 1)
@variable(model, -0.05 <= x[1:(N+1)] <= 0.05)
@variable(model, u[1:(N+1)])
@objective(model, Min,
    sum((u[i+1]^2 + u[i]^2) / 2N for i in 1:N) +
    sum(350 * (cos(t[i+1]) + cos(t[i])) / 2N for i in 1:N),
)
@constraint(model, [i in 1:N], x[i+1] - x[i] == (sin(t[i+1]) + sin(t[i])) / 2N)
@constraint(model, [i in 1:N], t[i+1] - t[i] == (u[i+1] + u[i]) / 2N)
optimize!(model)
objective_value(model)  # 350.0
```

Note how ExaModels is not a solver. Both ExaModels and JuMP end up calling
Ipopt. JuMP via Ipopt.jl, and ExaModels via NLPModelsIpopt.jl. At a high level,
the modeling APIs are similar. They both use macros. ExaModels splits the
symbolic model creation (the `ExaCore`) from the numeric model (the `ExaModel`),
and ExaModels' API is a little more restrictive. For example, constraint bounds
are given via the `lcon` and `ucon` keywords to `@add_con`, so all constraints
must be normalized to ``l \le f(x) \le u``.

Despite their similarities, rewriting a model from JuMP into ExaModels is a
pain. A better solution is to use `ExaModels.Optimizer`, which efficiently
automates the rewrite for the user.

## ExaModels.Optimizer

Use ExaModels as an intermediate layer between JuMP and a solver using
`ExaModels.Optimizer`:
```julia
using JuMP
import ExaModels, NLPModelsIpopt
model = Model(() -> ExaModels.Optimizer(NLPModelsIpopt.ipopt))
```

The first argument to `ExaModels.Optimizer` is any solver that is compatible
with [NLPModels.jl](https://github.com/JuliaSmoothOptimizers/NLPModels.jl),
such as `NLPModelsIpopt.ipopt` or `MadNLP.madnlp`.

Inside `ExaModels.Optimizer`, it takes the JuMP model, converts it into an
`ExaModels.ExaModel` object, and then passes that to NLPModelsIpopt to solve.
As part of the conversion, ExaModels detects the repeated patterns in your
JuMP model, so you do not need to write your model in a special way.

If you want the `ExaModels.ExaModel` object itself, call:
```julia
exa_model = ExaModels.ExaModel(model)
```

### What is supported

`ExaModels.Optimizer` supports a subset of the features that JuMP supports.
In particular, it supports:

 * continuous variables, with lower and upper bounds and starting values
 * parameters created with `@variable(model, p in Parameter(value))`
 * linear, quadratic, and nonlinear objectives
 * linear, quadratic, and nonlinear scalar constraints in `==`, `<=`, `>=`, and
   interval sets

ExaModels does not support integer or binary variables, vector-valued
constraints (such as conic constraints or complementarity constraints), or
user-defined operators.

## Benchmarks

On some large nonlinear programs such as AC-OPF, ExaModels and NLPModelsIpopt
can be faster than using [Ipopt.jl](https://github.com/jump-dev/Ipopt.jl).
This is because ExaModels uses a different automatic differentiation
implementation that is faster than JuMP's default on some problems.

Note that both approaches use the same Ipopt solver underneath. The only
difference is how the function and derivative evaluations (the gradient, the
Jacobian, and the Hessian of the Lagrangian) are computed.

Here's one benchmark that uses [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl)
to build an AC-OPF model of the 30,000 bus `pglib_opf_case30000_goc` instance
from [PGLib-OPF](https://github.com/power-grid-lib/pglib-opf), and then solves
it three ways:

 * with `ExaModels.Optimizer`
 * with `Ipopt.Optimizer` and JuMP's default automatic differentiation
 * with `Ipopt.Optimizer` and JuMP's [`SymbolicMode`](https://jump.dev/MathOptInterface.jl/stable/submodules/Nonlinear/reference/#MathOptInterface.Nonlinear.SymbolicMode)
   backend.

We ran the benchmark on an Apple M1 laptop with 16 GB of memory, using
Julia 1.12.7, JuMP v1.32.1, ExaModels v0.12.1, Ipopt.jl v1.16.0, and
NLPModelsIpopt v0.11.3. All three methods converged to the same locally optimal
solution:

| Method                             | Iterations | Time (s) | Objective |
| :--------------------------------- | ---------: | -------: | --------: |
| `ExaModels.Optimizer`              |        147 |      167 | 1.142e+06 |
| `Ipopt.Optimizer`                  |        164 |      249 | 1.142e+06 |
| `Ipopt.Optimizer` + `SymbolicMode` |        156 |      192 | 1.142e+06 |

`ExaModels.Optimizer` is around 1.9 times faster than `Ipopt.Optimizer` with
JuMP's default automatic differentiation, and around 1.4 times faster than
`SymbolicAD`. The methods take slightly different numbers of iterations
because each one computes derivatives with slightly different floating point
rounding.

ExaModels will not always be faster. The speed-up is largest for big models
with lots of repeated structure, which is the common case for problems like
AC-OPF and optimal control. For small models, or models without much repeated
structure, the time it takes to detect the patterns can outweigh the benefits,
and `Ipopt.Optimizer` is likely to be as fast or faster.

THe code we ran was:
```julia
using JuMP
import Downloads, ExaModels, Ipopt, NLPModelsIpopt, PowerModels
PowerModels.silence()
filename = "pglib_opf_case30000_goc.m"
Downloads.download(
    "https://raw.githubusercontent.com/power-grid-lib/pglib-opf/refs/heads/master/$filename",
    filename,
)
for optimizer in [
    () -> ExaModels.Optimizer(NLPModelsIpopt.ipopt),
    Ipopt.Optimizer,
    optimizer_with_attributes(
        Ipopt.Optimizer,
        MOI.AutomaticDifferentiationBackend() => MOI.Nonlinear.SymbolicMode(),
    ),
]
    @time PowerModels.solve_ac_opf(filename, optimizer)
end
```

## GPU solvers

The main reason to use ExaModels is that it can evaluate your model on a GPU.
When combined with [MadNLP.jl](https://github.com/MadNLP/MadNLP.jl), a
nonlinear interior-point solver written in Julia, both the model evaluation
and the linear algebra inside the solver can run entirely on the GPU, without
copying data back and forth between the host and the device.

Then, to solve a JuMP model on the GPU, pass `MadNLP.madnlp` as the solver and
`CUDA.CUDABackend()` as the second argument to `ExaModels.Optimizer`:

```julia
using JuMP
import CUDA, CUDSS, ExaModels, MadNLP, MadNLPGPU
model = Model(() -> ExaModels.Optimizer(MadNLP.madnlp, CUDA.CUDABackend()))
```

You build and query the model exactly as before. The only change is the
optimizer. The solution is copied back to the CPU at the end of the solve, so
functions like `value` and `dual` work as normal.

Note that to make the linear algebra work well on the GPU, MadNLP solves a
slightly relaxed version of your problem, and it uses a looser default
convergence tolerance of `1e-4`. If you need a more accurate solution, you can
tighten the tolerances:

```julia
set_attribute(model, "tol", 1e-7)
set_attribute(model, "bound_relax_factor", 1e-7)
```

See the [MadNLP GPU tutorial](https://madnlp.github.io/MadNLP.jl/stable/tutorials/gpu/)
for details on the trade-offs.

On an NVIDIA RTX PRO 1000, with MadNLP v0.10.1 and cuDSS v0.8.0, the GPU was
approximately 8 times faster than the CPU:

| Method                             | Iterations | Time (s) | Objective |
| :--------------------------------- | ---------: | -------: | --------: |
| `MadNLP` (default)                 |        147 |       20 | 1.113e+06 |
| `MadNLP` (1e-7)                    |        147 |       20 | 1.113e+06 |

## Can ExaModels power JuMP on GPUs?

The answer to Sungho's question is now "Yes!" If you have a large, structured,
continuous nonlinear program, to try solving your existing JuMP model on the
GPU. Even without a GPU, `ExaModels.Optimizer` can give a meaningful speed-up
over `Ipopt.Optimizer` on large problems like AC-OPF.

If you try it out, we'd love to hear about your experience. Please post on the
[community forum](https://discourse.julialang.org/c/domain/opt/13).
