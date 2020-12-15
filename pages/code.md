---
title:  "The JuMP ecosystem"
---

The JuMP project consists of the main [JuMP](https://github.com/jump-dev/JuMP.jl)
package, and a large collection of supporting Julia packages.

The JuMP source code can be found at [https://github.com/jump-dev/JuMP.jl](https://github.com/jump-dev/JuMP.jl).

## MathOptInterface

Beneath JuMP, there is an abstraction layer called MathOptInterface 
([source code](https://github.com/jump-dev/MathOptInterface.jl)). 

MathOptInterface defines an API that solvers should implement so that they can 
be used by JuMP, handles the automatic reformulation of problems via _bridges_, 
and has a large infrastructure for automatically testing solvers.

## Solvers and solver-wrappers

At the bottom of the stack, there are solvers. These packages are either 
pure-Julia implementations of optimization algorithms, or they provide a Julia
interface to external solvers (often written in C or C++). Each solver also 
implements the API defined by MathOptInterface so that it can be used from JuMP.

A non-exhaustive list of solvers available through JuMP is available in the
[JuMP documentation](https://jump.dev/JuMP.jl/stable/installation/#Getting-Solvers-1).

## JuMP extensions

JuMP extensions are Julia packages which extend JuMP's algebraic modeling language
by providing additional syntax and functionality for specific problem classes.

A non-exhaustive list of examples include:
 * [InfiniteOpt](https://github.com/pulsipher/InfiniteOpt.jl), which extends 
   JuMP to support infinite-dimensional optimization problems.
 * [SDDP.jl](https://github.com/odow/SDDP.jl), which extends JuMP to support 
   multistage stochastic programs.
 * [SumOfSquares](https://github.com/jump-dev/SumOfSquares.jl), which extends
   JuMP to support polynomial optimization.
 * [vOptGeneric.jl](https://github.com/vOptSolver/vOptGeneric.jl), which extends 
   JuMP to support multiobjective programs.
 
(This list of JuMP extensions is open to new contributions! If you know one that 
isn't listed here, tell us by making a pull-request to edit the file [code.md](https://github.com/jump-dev/jump-dev.github.io/blob/master/pages/code.md).)

## Convex.jl

An alternative to JuMP is [Convex.jl](https://jump.dev/Convex.jl/stable/). 
Convex.jl is a Julia package for disciplined convex programming, built on-top-of
MathOptInterface. Thus, it can use all of the same MathOptInterface-compatible
solvers as JuMP.
