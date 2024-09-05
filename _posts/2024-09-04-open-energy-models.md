---
layout: post
title:  "Open Energy Modeling at JuMP-dev 2024"
date:   2024-09-01
categories: [open-energy-models]
author: "Oscar Dowson"
---

In July 2024, we held [JuMP-dev 2024](/meetings/jumpdev2024/), the 7th edition
of our annual developer workshop. As part of the workshop, we sought talks
from a number of groups who use JuMP to build open energy models. This report
is a summary of my notes from watching the energy-related talks.

### Contents

 * [Applied optimization with JuMP at SINTEF](#applied-optimization-with-jump-at-sintef)
 * [Introduction to TulipaEnergyModel.jl](#introduction-to-tulipaenergymodeljl)
 * [SpineOpt.jl: A highly adaptable modelling framework for multi-energy systems](#spineoptjl-a-highly-adaptable-modelling-framework-for-multi-energy-systems)
 * [Solving the Market-to-Market Problem in Large Scale Power Systems](#solving-the-market-to-market-problem-in-large-scale-power-systems)
 * [PiecewiseAffineApprox.jl](#piecewiseaffineapproxjl)

## Applied optimization with JuMP at SINTEF

_Speaker: Truls Flatberg @trulsf_

<iframe width="560" height="315" src="https://www.youtube.com/embed/-a9-ToFiT8E?si=rpQeHt1__-lwxjXT" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

In this [prize winning](prize/jump-dev-2024) talk, Truls discussed how they have
been using JuMP to build and solve large scale optimization models at SINTEF.

SINTEF has been an active attendees of JuMP-dev recently, speaking about
[UnitJuMP.jl](https://www.youtube.com/watch?v=JQ6_LZfYRqg) and
[SparseVariables.jl](https://www.youtube.com/watch?v=YuDvfZo9W5A) at
[JuMP-dev 2022](/meetings/juliacon2022/), and
[TimeStruct.jl](https://www.youtube.com/watch?v=Hz6AL5kClKU) and
[energy system models](https://www.youtube.com/watch?v=fARbeM8sANA) at
[JuMP-dev 2023](/meetings/jumpdev2023/).

Historically, SINTEF primarily used FICO Xpress's Mosel modeling language, with
a mix of AMPL and GAMS, but they are transitioning to JuMP for new projects. He
mentioned that a key benefit for them is the modularity of JuMP, which is in
contrast to monolithic Mosel files with _O(10⁴)_ lines of code.

One line from his talk stuck out to me: "I think [...] the step from academic
problems to more industrial problems is not the mathematics, but that they are
large scale, so [...] they have to be correct and they have to be robust." The
JuMP developers have recently been discussing how, despite making it easy for
users to formulate and solve a wide range of optimization problems, JuMP
provides little support for the users who make mistakes, or tools for advanced
users to debug problematic models. Moreover, in our experience the majority of
(expensive) human programmer time is spent, not in formulating or solving a
model, but in the debugging and testing stage of development. I have opened the
issue [JuMP#3664](https://github.com/jump-dev/JuMP.jl/issues/3664) with some
preliminary ideas for tools that we could develop to test and debug JuMP models,
and I think these would be highly useful to users.

Truls gave a shout out to a tutorial I wrote, [Design patters for large models](https://jump.dev/JuMP.jl/stable/tutorials/getting_started/design_patterns_for_larger_models/),
which I think should be required reading for anyone embarking on the development
of an industrial-scale JuMP project.

I also liked how SINTEF use and combine a number of utility packages such as
[UnitJuMP.jl](https://github.com/trulsf/UnitJuMP.jl),
[SparseVariables.jl](https://github.com/sintefore/SparseVariables.jl),
[TimeStruct.jl](https://github.com/sintefore/TimeStruct.jl), and
[MultiObjectiveAlgorithms.jl](https://github.com/jump-dev/MultiObjectiveAlgorithms.jl).
UnitJuMP.jl is particularly notable because it adds support for modeling with
variables and constraints that are attached to physical units (which is the
topic of the second oldest open issue in JuMP,  [JuMP#1350](https://github.com/jump-dev/JuMP.jl/issues/1350)).
UnitJuMP prevents common modeling errors such as missing a scale factor from
kilo- to mega-, or by using feet instead of meters. 

Finally, Truls mentioned how they use PackageCompiler to create self-contained
executables for deploying their JuMP and Julia code to customers. Initially, the
_O(400 MB)_ files caused some concern internally within SINTEF, but after
feedback from customers this has not proven to be a problem. Still, it is
something that the Julia community is working on improving.

## Introduction to TulipaEnergyModel.jl

_Speaker: Diego Tejada @datejada_

<iframe width="560" height="315" src="https://www.youtube.com/embed/r4jqVzEck28?si=ZuCMB6X3rbN2jviC" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

In this talk, Diego talked about [TulipaEnergyModel.jl](https://github.com/TulipaEnergy/TulipaEnergyModel.jl).
(His colleague, Ni Wang @gnawin, was meant to talk, but couldn't attend because of visa delays.)
The main purpose of the Tulipa model is to make investment and operational
decisions of a power system with a focus on compact formulations. The typical
problem they are interested in solving has _O(10⁶)_ variables and constraints.

Diego discussed how the first attempt at building this model had poor
performance. However, they were able to use DataFrames.jl to linearize the
indices, and then they used the community support on Discourse to achieve a
further 3.2x improvement in performance. (Abel's
[thread](https://discourse.julialang.org/t/help-improving-the-speed-of-a-dataframes-operation/107615/38)
had a rapid and enthusiastic response with 38 posts by five people.)

Users encountering performance problems with models that contain graph
structures is a reoccurring issue in JuMP. The underlying reason is that a naïve
transcription of the mathematical model often has a runtime that is
_O(|nodes| * |edges|)_ in the size of the graph. Unfortunately, many users only
find out that they need to try a different approach (like Diego's rewrite to use
DataFrames.jl) after they have a working model and they try to scale to large
problem instances. Clearly, we should do a better job at advertising this issue
to new users.

I recently added a new tutorial,
[Performance problems with sum-if formulations](https://jump.dev/JuMP.jl/stable/tutorials/getting_started/sum_if/),
that describes the cause of the scaling behavior, as well as some suggested
work-arounds. There is also the related open issue [JuMP#3438](https://github.com/jump-dev/JuMP.jl/issues/3438),
which is a request to explore how we could better integrate JuMP and
DataFrames.jl, particularly for models with the sparse index sets that arise in
the context of graphs.

Finally, Diego also mentioned that he learnt about
[ParametricOptInterface.jl](https://github.com/jump-dev/ParametricOptInterface.jl)
at the workshop. We have since worked together to add a
[new tutorial](https://jump.dev/JuMP.jl/dev/tutorials/algorithms/rolling_horizon/)
to the JuMP documentation that uses ParametricOptInterface to solve a rolling
horizon problem of a power system with battery storage.

## SpineOpt.jl: A highly adaptable modelling framework for multi-energy systems

_Speaker: Diego Tejada @datejada_

<iframe width="560" height="315" src="https://www.youtube.com/embed/_oJYwdKdW3E?si=acyE9FMitujAn8c9" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

In his second talk of the day, Diego talked about the Mopo project. The core
product of the Mopo project is the Spine Toolbox, which incudes a full suite
of modeling features, from input data pipelines, a JuMP-based modeling framework
in [SpineOpt.jl](https://github.com/spine-tools/SpineOpt.jl), and a GUI for
managing and designing computational experiments. SpineOpt.jl aims to be able to
solve integrated models of a power system on the scale of a city up to entire
continents.

One thing that slightly concerned me about Diego's talk was his mention of the
various meta-solvers that are integrated into SpineOpt. These include a "Modeling
to generate alternatives (MGA)" algorithm, a Benders decomposition framework, a
multistage solver, and a rolling horizon framework.

On one hand, the
[MGA framework in SpineOpt.jl](https://github.com/spine-tools/SpineOpt.jl/blob/7c1995010791440b14ed418fe715fe89bedc2071/src/run_spineopt_mga.jl)
is only 350 lines of Julia code, which demonstrates how easy it is to embed JuMP
models in a complicated solution algorithm. On the other hand, the MGA algorithm
seems a lot like some of the multi-objective solution algorithms that are built
into
[MultiObjectiveAlgorithms.jl](https://github.com/jump-dev/MultiObjectiveAlgorithms.jl).
Similarly, I have been developing [SDDP.jl](http://sddp.dev) for nearly 10
years. SDDP.jl is built to solve multistage stochastic optimization problems
using a form of Benders decomposition, and it is already used to solve
energy-related problems, such as the
[JADE model at the New Zealand Electricity Authority](https://www.emi.ea.govt.nz/Wholesale/Tools/JADE).
It would be useful to understand more about how SpineOpt implements these
meta-solvers, and whether it is possible to re-use common packages such as
MultiObjectiveAlgorithms.jl or SDDP.jl instead of re-coding these (complex)
algorithms from scratch. I think it is instructive to compare Truls' talk about
how SINTEF successfully re-use utility package across models instead of
re-coding from scratch.

One useful part of Diego's talk was how he linked to various issues in the
SpineOpt.jl repository. If I had to summarize the common root cause of the
issues, it is that managing the input and output of a large quantity of JuMP
models is hard! In Spine's case, a frequent use-case is solving a year of power
system operational problems at hourly resolution via a rolling horizon model of
48 hour blocks rolling forward 24 hours at each step.

Diego's experience reinforces for me the need to include rolling horizon
simulations in our set of benchmark instances that we are building in the
[jump-dev/open-energy-modeling-benchmarks](https://github.com/jump-dev/open-energy-modeling-benchmarks)
repository.

## Solving the Market-to-Market Problem in Large Scale Power Systems

<iframe width="560" height="315" src="https://www.youtube.com/embed/N-jDHickaTc?si=T7eQnTopbCCtES3X" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

100m variables and constraints

Jose has previously spoken about Sienna (nee PowerSimulations.jl) at [JuMP-dev 2019](https://www.youtube.com/watch?v=JAHjZYiIJeI) and
[JuMP-dev 2023](https://www.youtube.com/watch?v=J7VbCKsnTvQ).

## PiecewiseAffineApprox.jl

_Speaker: Lars Hellemo @hellemo_

<iframe width="560" height="315" src="https://www.youtube.com/embed/rm292x59Yjk?si=8lN8MDgFQgUvsHZq" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

In this talk, Lars presented his work on a new package,
[PiecewiseAffineApprox.jl](https://github.com/sintefore/PiecewiseAffineApprox.jl),
which automatically approximates nonlinear functions with a linearized MIP
formulation that can be used in a linear solver like HiGHS. The package is used
by SINTEF in many of their energy-related applications.

JuMP core developer @joehuchette wrote a similar package,
[PiecewiseLinearOpt.jl](https://github.com/joehuchette/PiecewiseLinearOpt.jl),
that he [presented at the first JuMP developers workshop in 2017 (video)](https://www.youtube.com/watch?v=yiWx52yVVzM).
(It's notable to see that the production quality of JuMP-dev videos is much
improved over the years.) The JuMP documentation also contains a tutorial,
[Approximating nonlinear functions](https://jump.dev/JuMP.jl/stable/tutorials/linear/piecewise_linear/),
which explains how to construct the linearizations manually.

The fact that multiple groups have now developed similar packages suggests that
there is a need for us to integrate these packages closer into JuMP. As an
immediate improvement, I have added `PiecewiseAffineApprox.jl` to the script we
use to check that new releases of JuMP do not break downstream packages in
[JuMP#3817](https://github.com/jump-dev/JuMP.jl/pull/3817). I have also opened
an issue,
[PiecewiseLinearOpt.jl#49](https://github.com/joehuchette/PiecewiseLinearOpt.jl/issues/49),
to discuss moving that package to `jump-dev`. In the medium term, it might be
helpful to combine the two packages into a single utility package that has a
broad range of functionality for constructing piecewise linear approximations.
