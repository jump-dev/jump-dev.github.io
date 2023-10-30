---
---

{% include figure.html image="/assets/jump-logo-with-text.svg" %}

## What is JuMP?

JuMP is a modeling language and collection of supporting packages for
mathematical optimization in [Julia](https://julialang.org).

JuMP makes it easy to formulate and solve a range of problem classes, including
linear programs, integer programs, conic programs, semidefinite programs, and
constrained nonlinear programs. Here's an example:

```julia
julia> using JuMP, Ipopt

julia> function solve_constrained_least_squares_regression(A::Matrix, b::Vector)
           m, n = size(A)
           model = Model(Ipopt.Optimizer)
           set_silent(model)
           @variable(model, x[1:n])
           @variable(model, residuals[1:m])
           @constraint(model, residuals == A * x - b)
           @constraint(model, sum(x) == 1)
           @objective(model, Min, sum(residuals.^2))
           optimize!(model)
           return value.(x)
       end
solve_constrained_least_squares_regression (generic function with 1 method)

julia> A, b = rand(10, 3), rand(10);

julia> x = solve_constrained_least_squares_regression(A, b)
3-element Vector{Float64}:
 0.4137624719002825
 0.09707679853084578
 0.48916072956887174
```

## JuMP is used...

 * to power exa-scale research into personalized medicine as part of [PerMedCoE](https://permedcoe.eu/core-applications/)
 * to solve large-scale [inventory routing problems at Renault](https://arxiv.org/abs/2209.00412),
   [schedule trains at Thales Inc.](https://www.sciencedirect.com/science/article/pii/S0191261516304830),
   [plan power grid expansion at PSR](https://juliacomputing.com/case-studies/psr/),
   and
   [route school buses](https://www.the74million.org/article/building-a-smarter-and-cheaper-school-bus-system-how-a-boston-mit-partnership-led-to-new-routes-that-are-20-more-efficient-use-400-fewer-buses-save-5-million/)
 * to teach optimization at universities around the world, including
    [MIT](https://orc.mit.edu),
    [DTU](https://www.man.dtu.dk/mathprogrammingwithjulia),
    [U. Wisconsin-Madison](https://engineering.wisc.edu/departments/industrial-systems-engineering/),
     and
    [Université de Nantes](https://www.univ-nantes.fr)
 * to build continental-scale energy system models, including
     MIT's [GenX](https://github.com/GenXProject/GenX),
     the National Renewable Energy Laboratory's [Sienna](https://www.nrel.gov/analysis/sienna.html),
     Spine's [SpineOpt](https://www.tools-for-energy-system-modelling.org),
     and TNO's [Tulipa](https://github.com/TulipaEnergy/TulipaEnergyModel.jl)
 * to write hundreds of research papers each year, on topics such as

{% include figure.html image="/assets/jump-word-cloud.png" %}

## Resources for getting started

 * Decide if you should use JuMP by reading [Should I use JuMP?](https://jump.dev/JuMP.jl/stable/should_i_use/)
 * Install JuMP and Julia by reading the [Installation Guide](https://jump.dev/JuMP.jl/stable/installation/)
 * Learn Julia by reading [Getting started with Julia](https://jump.dev/JuMP.jl/stable/tutorials/getting_started/getting_started_with_julia/)
 * Solve your first JuMP model by reading [Getting started with JuMP](https://jump.dev/JuMP.jl/stable/tutorials/getting_started/getting_started_with_JuMP/)
 * Get help by joining the [community forum](/forum)
  to search for answers to commonly asked questions.

There is a growing collection of third-party materials about JuMP. This includes
the book,
[Julia Programming for Operations Research](http://www.chkwon.net/julia/),
which covers a variety of topics on optimization, with an emphasis on solving
practical problems using JuMP and Julia.

## Get involved

Here are some things you can do to become more involved in the JuMP community:

 * Help answer questions on the [community forum](/forum)
 * Star and watch the [repository](https://github.com/jump-dev/JuMP.jl)
 * Read the [contributing guide](https://jump.dev/JuMP.jl/stable/developers/contributing/)
 * Read about our [governance structure](/pages/governance)
 * Join the [developer chatroom](/chatroom)
 * Attend [upcoming events](/pages/calendar)

## See also

The JuMP ecosystem includes [Convex.jl](https://github.com/jump-dev/Convex.jl),
an algebraic modeling language for convex optimization based on the concept of
[Disciplined Convex Programming](https://dcp.stanford.edu/).

Outside of the JuMP organization:
- [JuliaSmoothOptimizers](https://github.com/JuliaSmoothOptimizers) provides a
  collection of tools primarily designed for developing solvers for smooth
  nonlinear optimization.
- [JuliaNLSolvers](https://github.com/JuliaNLSolvers) offers implementations in
  Julia of standard standard optimization algorithms for unconstrained or
  box-constrained problems such as BFGS, Nelder-Mead, conjugate gradient, etc.
- JuliaHub lists 200+
  [optimization packages in Julia](https://juliahub.com/ui/Packages?t=optimization)!

## NumFOCUS

![NumFOCUS logo](/assets/numfocus-logo.png)

JuMP is a Sponsored Project of NumFOCUS, a 501(c)(3) nonprofit charity in the
United States. NumFOCUS provides JuMP with fiscal, legal, and administrative
support to help ensure the health and sustainability of the project. Visit
[numfocus.org](https://numfocus.org) for more information.

You can support JuMP by [donating](https://numfocus.salsalabs.org/donate-to-jump/index.html).

Donations to JuMP are managed by NumFOCUS. For donors in the United States,
your gift is tax-deductible to the extent provided by law. As with any donation,
you should consult with your tax adviser about your particular tax situation.

JuMP's largest expense is the annual JuMP-dev workshop. Donations will help us
provide travel support for JuMP-dev attendees and take advantage of other
opportunities that arise to support JuMP development.
