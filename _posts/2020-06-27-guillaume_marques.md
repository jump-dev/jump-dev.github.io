---
layout: post
title:  "Guillaume Marques | Design and features of Coluna.jl"
date:   2020-06-27
categories: [jump-dev]
---

Guillaume Marques, a Ph.D. student at the Université de Bordeaux, gave his talk
that was accepted for JuMP-dev 2020 on the design and features of the [Coluna.jl](https://github.com/atoptima/Coluna.jl)
package during June 2020's JuMP monthly developer call.

<iframe width="560" height="315" src="https://www.youtube.com/embed/Elfgz9vgkPE" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Abstract

Coluna.jl is a branch-and-cut-and-price framework written in Julia. The user introduces a
formulation of his problem using JuMP and BlockDecomposition which is then reformulated by
Coluna based on the annotations provided through BlockDecomposition. Then, the framework
optimises the reformulation using the algorithm chosen by the user. We aim Coluna to be very
flexible. Coluna thus provides an interface and atomic algorithmic routines to let the user
develop his own optimisation procedures. Moreover, we built Coluna on top of
MathOptInterface as we may optimise parts of reformulations with MILP solvers. We will
present the design of the package and some features through few classic problems of
operations research.

