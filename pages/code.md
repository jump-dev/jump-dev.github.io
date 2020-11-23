---
title:  "The JuMP ecosystem"
---

The JuMP project consists of the main [JuMP](https://github.com/juliaopt/JuMP.jl)
package, and a large collection of supporting Julia packages.

The JuMP source code can be found at [https://github.com/jump-dev/JuMP.jl](https://github.com/jump-dev/JuMP.jl).

Beneath JuMP, there is an abstraction layer called MathOptInterface ([source code](https://github.com/jump-dev/MathOptInterface.jl)). MathOptInterface defines an API that solvers
should implement so that they can be used by JuMP, handles the automatic
reformulation of problems via _bridges_, and has a large infrastructure for
automatically testing solvers.

At the bottom of the stack, there are solver wrappers. These packages wrap the
solvers, which are often written in C or C++, and implement the API defined by
MathOptInterface.

A non-exhaustive list of solvers available through JuMP is available in the
[JuMP documentation](https://jump.dev/JuMP.jl/stable/installation/#Getting-Solvers-1).
