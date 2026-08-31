---
layout: post
title:  "MathOptAI.jl v1.0 is released"
date:   2026-08-31
categories: [releases]
author: "Oscar Dowson, Gökhan Kof, Robert Parker"
---

We're pleased to announce the v1.0 release of [MathOptAI.jl](https://github.com/lanl-ansi/MathOptAI.jl),
a library for embedding trained machine learning predictors into [JuMP](https://jump.dev)
and [ExaModels](https://github.com/madsuite-org/ExaModels.jl).

MathOptAI.jl was developed as part of our
[collaboration with Los Alamos National Laboratory](/announcements/2024/09/01/lanl/).

You can find more information about MathOptAI.jl by [reading the documentation](https://lanl-ansi.github.io/MathOptAI.jl/stable/),
[reading our paper](https://pubsonline.informs.org/doi/10.1287/ijoc.2025.1446),
or by [watching the talk](https://www.youtube.com/embed/cYBvJ158c5M?si=6gALIeJpW1DDlyGv)
Robby gave about MathOptAI.jl at JuMP-dev 2025.

Here's an example of MathOptAI.jl in action:
```julia
using JuMP, MathOptAI, Flux
predictor = Flux.Chain(Flux.Dense(28^2 => 32, Flux.relu), Flux.Dense(32 => 10), Flux.softmax);
model = Model();
@variable(model, 0 <= x[1:28^2] <= 1);
y, formulation = MathOptAI.add_predictor(model, predictor, x);
```
The return `y` is a vector of JuMP decision variables that represents the
relationship `y = predictor(x)`. Behind the scenes, MathOptAI.jl adds new
decision variables and constraints to `model` to enforce the relationship.

MathOptAI.jl supports adding predictors from a range of machine learning
libraries, including Flux.jl, Lux.jl, and PyTorch.

## Different embeddings

MathOptAI.jl supports three different ways of embedding neural networks:

1. the _full-space_ formulation adds new variables and constraints for each
   layer in the neural network. This is the default.
2. the _reduced-space_ formulation embeds `predictor(x)` as a large nonlinear
   expression (using `JuMP.@expression`) without adding any new variables or
   constraints. Pass `; reduced_space = true` to `add_predictor` to enable this
   formulation.
4. the _gray-box_ formulation uses [`MOI.VectorNonlinearOracle`](https://jump.dev/JuMP.jl/stable/moi/reference/standard_form/#MathOptInterface.VectorNonlinearOracle)
   to add the constraint `predictor(x) - y == 0` and automatically sets up
   callbacks to evaluate the function, gradient, and Hessian of
   `predictor(x)`. Pass `; gray_box = true` to `add_predictor` to enable this
   formulation.

The gray-box formulation is particularly useful when combined with PyTorch. Given
a trained PyTorch model, use `torch.save(model, "filename.pt")` to save the model
structure and weights to disk. Then, from Julia do:
```julia
using JuMP, MathOptAI, PythonCall, Ipopt
model = Model(Ipopt.Optimizer)
@variable(model, x[1:10])
predictor = MathOptAI.PytorchModel("filename.pt")
y, _ = MathOptAI.add_predictor(
    model, predictor, x; gray_box = true, device = "cuda")
```
Behind the scenes, MathOptAI.jl co-ordinates the Julia-Python communication, and
the oracles related to the predictor will be evaluated on the GPU. The gray-box
formulation enables MathOptAI.jl to embed very large neural networks into a JuMP
model becuase we never represent the predictor algebraically.

## Input Convex Neural Networks

A unique feature of MathOptAI is it's support for input convex neural networks,
which [Gökhan Kof](https://github.com/kofgokhan) has been working on as part of
the [2026 Google Summer of Code](https://summerofcode.withgoogle.com).

Input Convex Neural Networks are predictors where `predictor(x)` is a convex
function with respect to `x`. This enables the embedding `y >= predictor(x)`,
which can be simpler to implement than the strict `y == predictor(x)`.

As one example, ReLU can be implemented as an epigraph formulation with a
non-negative variable `y >= 0` and the inequality constraint `y - x >= 0`
([MathOptAI.ReLUEpigraph](https://lanl-ansi.github.io/MathOptAI.jl/stable/api/#ReLUEpigraph)),
instead of the non-smooth nonlinear constraint `y = max(0, x)`
([MathOptAI.ReLU](https://lanl-ansi.github.io/MathOptAI.jl/stable/api/#ReLU)),
or MIP formulations like [MathOptAI.ReLUSOS1](https://lanl-ansi.github.io/MathOptAI.jl/stable/api/#ReLUSOS1).

Find out more by reading [Input Convex Neural Networks with Flux.jl](https://lanl-ansi.github.io/MathOptAI.jl/stable/tutorials/input_convex/).

## How are you using MathOptAI?

If you use MathOptAI.jl, we'd love to hear about it. The best way to get in
touch is by [opening an issue](https://github.com/lanl-ansi/MathOptAI.jl/issues/new).
Tell us how you used the library, or suggest new predictors and features that we
should add.
