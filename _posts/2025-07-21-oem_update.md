---
layout: post
title:  "An Open Energy Modeling update"
date:   2025-07-21
categories: [open-energy-modeling]
author: "Oscar Dowson, Ivet Galabova, Joaquim Dias Garcia, Julian Hall, Mark Turner"
---

We're now ten months into our [Open Energy Modeling project](/announcements/open-energy-modeling/2024/09/16/oem/).
If you missed them, you can read our [November update](/open-energy-modeling/2024/11/14/oem_update)
and our [January update](/open-energy-modeling/2025/01/27/oem_update).

## Welcome, Mark

In May we welcomed [Dr. Mark Turner](https://scholar.google.com/citations?user=qyD8_b0AAAAJ&hl=en)
to the project. Mark has a Ph.D. from ZIB where he worked on SCIP. Mark's focus
is on improving the performance and reliability of the MIP solver.

## HiGHS workshop

At the end of June, we held the [2025 HiGHS workshop](https://workshop25.highs.dev).
We had 18 talks about a range of HiGHS-related topics ([view the full
schedule](https://workshop25.highs.dev/schedule) for details).

There were a number of pertinent talks for the energy community. From the JuMP
and HiGHS teams:

 * Julian gave an overview of the [state of HiGHS](https://drive.google.com/file/d/19ECB1-duVubkQTgEhcbtnENtKGQbJdXi/view)
   and gave some cautionary advice for [navigating the hype of PDLP](https://drive.google.com/file/d/1j_SYpdIlKvDMYwLgL5xi0n4ULrVj7gT4/view).
 * Filippo [introduced his new interior point solver](https://drive.google.com/file/d/1ARfYjhb4b9RRpFro8AH3TEvTDjkHaRNH/view).
   Initial benchmarks on PyPSA instances show that it is up to to 10x faster
   than the current interior point for large linear programs. It is sometimes
   slower, particularly for smaller problems, and there are some challenges with
   compiling and distributing it, so it may be some time before it becomes the
   default option in HiGHS.
 * Oscar [talked about JuMP and HiGHS](https://drive.google.com/file/d/17X4kmRFoNyV9nICkBaxgjGzyTnTrYAk-/view).
   Our usage statistics show that half of JuMP users are using HiGHS, and that
   there are over 1,000 public GitHub repositories that use HiGHS.jl.
 * Mark [talked about the MIP solver](https://drive.google.com/file/d/1JIb3aShAetSGfjt7Qj9ElisAFD0lBmvM/view)
   and shared his short-, medium-, and long-term development goals.
 * Ivet [talked about the build systems](https://drive.google.com/file/d/13lkc-7stetAaPP-0fhnNJEnAh5x2jA6x/view).
   Maintaining the various interfaces to HiGHS is no small task!

There were also two energy-related talks. Dimitris Kousoulidis talked about how
Field Energy [use HiGHS to optimize the operation of a battery](https://drive.google.com/file/d/1oHjLeYPFYRwkyiVW3nCsO6QZOycevM02/view),
and Harley Mackenzie [similarly talked about](https://drive.google.com/file/d/1IomRp_w5KIqdnlL14Wjcn3hEdR8Mg65L/view)
how they use HiGHS to optimize the operation of a battery that is co-located
with variable renewable energy. Both companies use JuMP as the modeling layer.

## JuMP-dev 2025

In November we will host [JuMP-dev 2025](meetings/jumpdev2025/) in Auckland, New
Zealand. If you are interested in energy modeling, please come along! We will
all be there, and we're very keep to hear how any feedback you have about using
JuMP and HiGHS.

## MathOptAnalyzer

A key finding from the first part of our energy modeling project is that the
instances people are solving have a range of numerical features (other than size
) that make them difficult to solve. One example are coefficients with a wide
spread of magnitudes (consider a large thermal generator with a power of 20 GW
and a solar plant in the first hour of dawn generating 0.1 MW). Other common
issues make the problem slow to build. For example, many instances have empty
rows (constraints with no variable terms) and empty columns (variables that do
not appear in a constraint). While these can be trivially presolved out by the
solver, there is a cost (in terms of memory and runtime) to adding them to a
model.

To assist modelers in diagnosing and fixing these issues, we have developed
[MathOptAnalyzer.jl](https://github.com/jump-dev/MathOptAnalyzer.jl).
MathOptAnalyzer is a Julia package that takes in a JuMP model and returns a list
of issues for analysis by the user. Use it as follows:
```
using JuMP, MathOptAnalyzer
model = Model()
# ... build model
data = ModelAnalyzer.analyze(ModelAnalyzer.Numerical.Analyzer(), model)
```

In addition to the numerical analyzer, MathOptAnalyzer can analyze a model for
feasibility, and return information on why the model is infeasible. It can also
assess whether a solution returned by the solver satistifies the primal, dual,
and optimality tolerances. This can be useful for identifying bugs in the
solver, and for validating how the solver's tolerances affect the solution.

For more information, go to [MathOptAnalyzer.jl](https://github.com/jump-dev/MathOptAnalyzer.jl).

## MathOptIIS

A common feature request to both JuMP and HiGHS is for an IIS. If a model is
infeasible, the IIS is the smallest subset of variables and constraints such
that the submodel is still infeasible. (The IIS acronym is not standardized. We
have seen Irreducible Infeasible Subsystem and Irreducibly Inconsistent Set,
amongst many others. We use IIS without attempting to define it.)

The IIS is helpful for two common operations:

1. detecting and explaining data input errors when applying an existing model to
   new data
2. detecting and explaining syntax errors (for example, a `+` instead of a `-`)
   when developing a new model.

Commercial solvers such as CPLEX, Gurobi, and Xpress all have mature IIS
solvers, and these can be accessed from JuMP via `JuMP.compute_conflict!(model)`.
However, many solvers (for example, HiGHS, Cbc, and Ipopt) do not have an IIS
solver. We have heard anecdotal evidence that many practitioners solve the
majority of their problems with HiGHS, but they still have a single Gurobi
license just so they can access the IIS.

As part of this project, we have developed [MathOptIIS.jl](https://github.com/jump-dev/MathOptIIS.jl).
MathOptIIS is a Julia package that implements an IIS solver in MathOptInterface.
It is not intended to be used directly by users (although you can). Instead, we
will add this as a dependency to existing solver wrappers like HiGHS.jl so that
`JuMP.compute_conflict!` works uniformly for solvers with native IIS support and
those without.

Simultaneously, we have been developing a native IIS solver within HiGHS. When
that is released, we will remove MathOptIIS.jl from HiGHS in favor of the native
IIS solver. Even when HiGHS have a native IIS solver, MathOptIIS will be helpful
for other solvers like Ipopt that do not have an IIS solver (and will likely
never have one).

## A parallel MIP solver

A key deliverable for our project is to add multithreading to the HiGHS MIP
solver. We have been exploring two approaches to this.

First, we have been prototyping adding deterministic parallelism to a single
HiGHS MIP solve. In this approach, we extend HiGHS to conduct multiple parallel
dives through the branch and bound tree. As the parallel dives find new
solutions and prove information about feasibility and the dual bound, they
update a shared global state. The information is shared in a deterministic
manner, so that running the parallel MIP solver will find an identical solution
to the serial MIP solver. This approach is the one taken by commercial MIP
solvers. It offers a consistent performance boost, since it is strictly superior
to the serial MIP solver. However, it requires a lot of careful engineering time
to implement. The current status of this solver is ``work in progress'' and we
do not have an expected date for its completion.

Second, we have implemented a non-deterministic concurrent MIP solver. In this
approach, we start multiple parallel instances of HiGHS in separate threads.
Each instance uses a different random seed. As the threads find new solutions,
they share this information between themselves, and the algorithm terminates
once any thread has found an optimal solution. This approach exploits the
inherent randomness in how HiGHS's presolve and how it explores the branch and
bound tree. The downside to this approach is that it is not deterministic;
repeated runs of the same model are not guaranteed to find the same optimal
solution. In our preliminary testing, the speed up that can be expected is
problem-dependent, but, with eight threads, it is common for the speedup to be
2--5 times faster. The non-deterministic concurrent MIP solver is implemented
and it will be available in the next release of HiGHS.

## Other changes

With help from Franz Wesselmann from MathWorks, we continue to find, debug, and
fix many bugs in HiGHS. The most common location for these bugs is in the HiGHS
presolve. We have also added new heuristics, such as the Feasibility Jump, and
Mark has been working to add new cutting planes. We're now at an inflection
point where we hope to see rapid improvements in the HiGHS MIP solver that
should be reflected in the Mittelmann benchmarks by the end of the year.
