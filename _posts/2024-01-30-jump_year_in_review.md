---
layout: page
title:  "JuMP: the year in review (2023)"
date:   2024-01-30
---

_Author: Oscar Dowson_

At the end of last year, I gave a talk at the 55th [Operations Research Society of New Zealand](http://orsnz.org.nz)
annual conference ([slides](/assets/ORSNZ_2023.pdf)). It proved to be a good
excuse to summarize the progress we made in JuMP over the year, and, since we
didn't record the talks, the President of ORSNZ, Andrea Raith, suggested a blog
post might be in order.

Each of the following sections is a brief summary of a part of JuMP that we
improved over the past year.

 - [About JuMP](#about-jump)
 - [Nonlinear](#nonlinear)
 - [Complementarity](#complementarity)
 - [Constraint programming](#constraint-programming)
 - [Multi-objective](#multi-objective)
 - [Complex numbers](#complex-numbers)
 - [Generic numbers](#generic-numbers)
 - [Time-to-first-solve](#time-to-first-solve)
 - [Future plans](#future-planns)

## About JuMP

[JuMP](https://jump.dev) is a modeling language and collection of supporting
packages for mathematical optimization in [Julia](http://julialang.org).

JuMP makes it easy to formulate and solve a range of problem classes, including
linear programs, integer programs, conic programs, semidefinite programs, and
constrained nonlinear programs.

People use JuMP to model and solve real-world problems, including large-scale
inventory routing problems at [Renault](https://pubsonline.informs.org/doi/10.1287/trsc.2022.0342),
train scheduling at [Thales Inc.](https://www.sciencedirect.com/science/article/pii/S0191261516304830),
and school bus routing for [Boston Public Schools](https://www.the74million.org/article/building-a-smarter-and-cheaper-school-bus-system-how-a-boston-mit-partnership-led-to-new-routes-that-are-20-more-efficient-use-400-fewer-buses-save-5-million/).

A major use-case of JuMP is building continental-scale energy system models,
including MIT's [GenX](https://github.com/GenXProject/GenX), the National
Renewable Energy Laboratory's [Sienna](https://www.nrel.gov/analysis/sienna.html),
Spine's [SpineOpt.jl](https://www.tools-for-energy-system-modelling.org), and
TNO's [TulipaEnergyModel.jl](https://github.com/TulipaEnergy/TulipaEnergyModel.jl)

In academia, people use JuMP to teach optimization at universities around the
world, including [DTU](https://www.man.dtu.dk/mathprogrammingwithjulia),
[École des Ponts](https://ecoledesponts.fr), [KAIST](https://kaist.ac.kr/en/),
[MIT](https://orc.mit.edu), [PUC-Rio](http://www.puc-rio.br/english/),
[Université de Nantes](https://www.univ-nantes.fr), and
[U. Wisconsin-Madison](https://engineering.wisc.edu/departments/industrial-systems-engineering/).

## Nonlinear

I spent the past two years [working with](https://jump.dev/announcements/2022/02/21/lanl/)
[Carleton Coffrin](https://github.com/ccoffrin) and colleagues at Los Alamos
National Laboratory on a project to rewrite JuMP's nonlinear syntax.

Despite the amount of work behind the scenes over two years, the changes to
user-facing code may seem relatively trivial: instead of using the various `@NL`
macros, you can now create and use nonlinear expressions in the regular JuMP
macros, for example:
```julia
julia> using JuMP

julia> model = Model();

julia> @variable(model, x[1:2]);

julia> @objective(model, Min, exp(x[1]) - sqrt(x[2]))
exp(x[1]) - sqrt(x[2])
```

Previously unsupported features, such as array operations like broadcasting now
work just like they do for linear and quadratic expressions:
```julia
julia> @expression(model, log(sum(exp.(x))))
log(0.0 + exp(x[2]) + exp(x[1]))
```

The [JuMP documentation](https://jump.dev/JuMP.jl/stable/manual/nonlinear/) has
more examples of the new syntax.

Behind the scenes, a lot of work went in to identify a suitable data structure
for representing the nonlinear expressions, and to refactor the various parts
of JuMP and MathOptInterface, and to update solvers like Ipopt to the new
syntax. You can find out more of the details by watching talks I gave at
JuMP-dev in 2022 and 2023, both helpfully called the same thing:

 * [Improving nonlinear programming support in JuMP (2022)](https://www.youtube.com/watch?v=d_X3gj3Iz-k)
 * [Improving nonlinear programming support in JuMP (2023)](https://www.youtube.com/watch?v=6q76umkG-34)

## Complementarity

As part of the nonlinear work, we also extended JuMP to support nonlinear
complementarity problems. This addressed a long-standing feature request for
JuMP, which previously supported only linear and quadratic complementarity
constraints.

As an example, you can now build and solve complementarity problems that look
like this:
```julia
julia> using JuMP, PATHSolver

julia> function solve_insurance_problem(; pi = 0.01, L = 0.5, γ = 0.02, ρ = -1)
           U(C) = -1 / C
           MU(C) = 1 / C^2
           model = Model(PATHSolver.Optimizer)
           set_silent(model)
           @variable(model, EU, start = 1)   # Expected utilitiy
           @variable(model, EV, start = 1)   # Equivalent variation in income
           @variable(model, C_G, start = 1)  # Consumption on a good day
           @variable(model, C_B, start = 1)  # Consumption on a bad day
           @variable(model, K, start = 1)    # Coverage
           @constraints(model, begin
               (1 - pi) * U(C_G) + pi * U(C_B) - EU                     ⟂ EU
               100 * (((1 - pi) * C_G^ρ + pi * C_B^ρ)^(1 / ρ) - 1) - EV ⟂ EV
               1 - γ * K - C_G                                          ⟂ C_G
               1 - L + (1 - γ) * K - C_B                                ⟂ C_B
               γ * ((1 - pi) * MU(C_G) + pi * MU(C_B)) - pi * MU(C_B)   ⟂ K
           end)
           optimize!(model)
           return value(K)
       end
solve_insurance_problem (generic function with 1 method)

julia> solve_insurance_problem()
0.20474003534537757
```

The JuMP documentation has a [number of other examples](https://jump.dev/JuMP.jl/stable/tutorials/nonlinear/complementarity/) that demonstrate the new syntax.

The new complementarity support is helping others in the community.
[David Anthoff](https://erg.berkeley.edu/people/anthoff-david/) and colleagues
at UC Berkeley are working on [MPSGE.jl](https://github.com/anthofflab/MPSGE.jl),
a reimplementation of [Tom Rutherford's](https://windc.wisc.edu/people.html)
[MPSGE](https://www.gams.com/solvers/mpsge/index.htm) from GAMS into JuMP. Tom's
group is also looking at adopting JuMP for their [offical WiNDC model](https://github.com/uw-windc/WiNDC.jl).

## Multi-objective

This year saw the introduction of support for multi-objective programs. There
have been a few previous attempts at this, most notably [Xavier Gandibleux's](https://xgandibleux.github.io)
[vOptSolver](https://github.com/vOptSolver) project, and the [MultiJuMP.jl](https://github.com/anriseth/MultiJuMP.jl)
extension.

You can now define a multi-objective program by passing a vector of scalar
objective functions:
```julia
julia> model = Model();

julia> @variable(model, x[1:2]);

julia> @objective(model, Min, [1 + x[1], 2 * x[2]])
2-element Vector{AffExpr}:
 x[1] + 1
 2 x[2]
```

We also developed the [MultiObjectiveAlgorithms.jl](https://github.com/jump-dev/MultiObjectiveAlgorithms.jl)
(MOA) package, which implements a number of solution algorithms for multi-objective
programs.

The optimizer returns a set of points from the efficient frontier (exactly what
and now many depend on the solution algorithm), which you can access with the
`result` keyword argument to functions like `JuMP.value` and `JuMP.objective_value`.

An example is:
```julia
julia> using JuMP, HiGHS

julia> import MultiObjectiveAlgorithms as MOA

julia> function solve_biobjective_assignment()
           C1 = [5 1 4 7; 6 2 2 6; 2 8 4 4; 3 5 7 1];
           C2 = [3 6 4 2; 1 3 8 3; 5 2 2 3; 4 2 3 5];
           n = size(C2, 1)
           model = Model(() -> MOA.Optimizer(HiGHS.Optimizer));
           set_attribute(model, MOA.Algorithm(), MOA.EpsilonConstraint());
           set_silent(model)
           @variable(model, x[1:n, 1:n], Bin);
           @objective(model, Min, [sum(C1 .* x), sum(C2 .* x)])
           @constraint(model, [i = 1:n], sum(x[i, :]) == 1);
           @constraint(model, [j = 1:n], sum(x[:, j]) == 1);
           optimize!(model)
           pair(a) = a.I[1] => a.I[2]
           for i in 1:result_count(model)
               sol = pair.(findall(>(0.5), value.(x; result = i)))
               println(i, ": ", sol, " | ", objective_value(model; result = i))
           end
       end
solve_biobjective_assignment (generic function with 1 method)

julia> solve_biobjective_assignment()
1: [3 => 1, 1 => 2, 2 => 3, 4 => 4] | [6.0, 24.0]
2: [3 => 1, 2 => 2, 1 => 3, 4 => 4] | [9.0, 17.0]
3: [1 => 1, 2 => 2, 3 => 3, 4 => 4] | [12.0, 13.0]
4: [4 => 1, 2 => 2, 3 => 3, 1 => 4] | [16.0, 11.0]
5: [2 => 1, 4 => 2, 1 => 3, 3 => 4] | [19.0, 10.0]
6: [2 => 1, 4 => 2, 3 => 3, 1 => 4] | [22.0, 7.0]
```

Credit goes to [Gökhan Kof](https://github.com/kofgokhan) for contributing many
of the more advanced algorithms in MOA.jl.

## Complex numbers

Another big change over the last year or so was [Benoît Legat's](https://github.com/blegat)
work on adding complex number support to JuMP. This is a commonly requested
feature that often arises in models such as power systems.

You can now use the `ComplexPlane` syntax to add a complex-valued decision
variable to a JuMP model and use it in complex-valued equality constraints:
```julia
julia> using JuMP

julia> model = Model();

julia> @variable(model, x in ComplexPlane())
real(x) + imag(x) im

julia> @constraint(model, (1 + 2im) * x == 4 + 5im)
(1 + 2im) real(x) + (-2 + im) imag(x) = (4 + 5im)
```

At present, JuMP implements the rectangular formulation, where two real-valued
decision variables are added to the model, one each for the real and imaginary
components.

You can also create Hermian matrices via:
```julia
julia> @variable(model, H[1:3, 1:3] in HermitianPSDCone());
```

See the [documentation](https://jump.dev/JuMP.jl/stable/manual/complex/) for
more details.

## Generic numbers

In addition to complex numbers, Benoît also added a new `GenericModel{T}`
constructor, which creates a JuMP model in which the number type is `T` instead
of the default `T = Float64`.

As one example, you can now build and solve linear programs in exact rational
arithmetic:

```julia
julia> using JuMP, CDDLib

julia> model = GenericModel{Rational{BigInt}}(CDDLib.Optimizer{Rational{BigInt}});

julia> @variable(model, 1 // 7 <= x[1:2] <= 2 // 3)
2-element Vector{GenericVariableRef{Rational{BigInt}}}:
 x[1]
 x[2]

julia> @constraint(model, c1, (2 // 1) * x[1] + x[2] <= 1);

julia> @constraint(model, c2, x[1] + 3x[2] <= 9 // 4);

julia> @objective(model, Max, sum(x));

julia> optimize!(model)

julia> value.(x)
2-element Vector{Rational{BigInt}}:
 1//6
 2//3

julia> objective_value(model)
5//6
```

See the [documentation](https://jump.dev/JuMP.jl/dev/tutorials/conic/arbitrary_precision/)
for more details.

## Constraint programminng

The nonlinear improvements and generic number support combine to enable some
nice improvements to constraint programming. Although JuMP isn't a fully-fledged
constraint programming language like MiniZinc, with help from [Chris Coey](https://github.com/chriscoey),
it is now possible to build and solve models like this:

```julia
julia> using JuMP, MiniZinc

julia> model = GenericModel{Int}(() -> MiniZinc.Optimizer{Int}("chuffed"));

julia> @variable(model, 1 <= x[1:3] <= 3);

julia> @constraint(model, x in MOI.AllDifferent(3));

julia> @constraint(model, (x[1] == 2 || x[3] == 2) == true)
((x[1] == 2) || (x[3] == 2)) - 1 = 0

julia> @objective(model, Max, sum(i * x[i] for i in 1:3));

julia> optimize!(model)

julia> value.(x)
3-element Vector{Int64}:
 2
 1
 3
```

## Time-to-first-solve

Another thing that improved dramatically over the past year was the infamous
"time-to-first-solve" problem. This is the latency that users experience the
first time they solve a JuMP model in a new Julia session.

In Julia 1.6 and earlier, it was common for this latency to be greater than
15 seconds. On Julia 1.10, the latency is now around 3 seconds. Better. But we
still have room for improvement.

```raw
oscar@Oscars-MBP JuMP % julia
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.10.0 (2023-12-25)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/                   |

julia> @time using JuMP, HiGHS
  2.645880 seconds (1.17 M allocations: 82.527 MiB, 4.00% gc time, 0.85% compilation time)

julia> @time begin
         model = Model(HiGHS.Optimizer)
         set_silent(model)
         @variable(model, x >= 0)
         @variable(model, 0 <= y <= 3)
         @objective(model, Min, 12x + 20y)
         @constraint(model, c1, 6x + 8y >= 100)
         @constraint(model, c2, 7x + 12y >= 120)
         optimize!(model)
       end
  0.214786 seconds (241.91 k allocations: 16.071 MiB, 97.47% compilation time: 45% of which was recompilation)
```

## Future plans

We have big plans for this year. We will continue to improve JuMP's nonlinear
support, particularly as solvers like Gurobi and Xpress release and refine
support for MINLPs. On the feature front, a priority is adding support for
[modeling with SI units](https://github.com/jump-dev/JuMP.jl/issues/1350). And
finally, [JuMP-dev 2024](/meetings/jumpdev2024) will be held July 19-21 2024 in
Montréal.

Here's to another big year for JuMP!
