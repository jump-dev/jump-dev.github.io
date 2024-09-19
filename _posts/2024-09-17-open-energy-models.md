---
layout: post
title:  "Open Energy Modeling at JuMP-dev"
date:   2024-09-17
categories: [open-energy-models]
author: "Oscar Dowson"
---

In July 2024, we held [JuMP-dev 2024](/meetings/jumpdev2024/), the seventh edition
of our annual developer workshop. As part of the workshop, we sought talks
from a number of groups who use JuMP to build open energy models.

Motivated by our [recently announced Open Energy Modeling project](/announcements/open-energy-modeling/2024/09/16/oem/),
I started writing this report as a summary of my notes from watching the energy-related
talks at JuMP-dev 2024, but, based on the [community feedback during the writing of this post](https://github.com/jump-dev/jump-dev.github.io/pull/156),
I extended the scope to talks about energy system modeling in previous years as
well.

## Summary

JuMP is a popular tool for building open energy system models.

Tools like [GenX](http://genx.mit.edu/) and [Sienna](https://www.nrel.gov/analysis/sienna.html)
have a long history of development, and they are used to analyze power systems
around the world.

The main features that energy modelers like about JuMP are:

 * Performance: Sienna has demonstrated that it is possible to build and solve
   extremely large simulation models of a power system, with _O(10⁸)_ variables
   and constraints.
 * In-memory re-solves: JuMP makes it possible to efficiently solve a model,
   change some of the parameters like variable bounds and right-hand sides, and
   then re-solve, without needing to rebuild each model from scratch or use file
   I/O. This is a critical feature for the rolling-horizon type problems that
   arise when we simulate the operations of a power system.
 * Documentation: I have put a lot of effort into developing excellent
   documentation, and we frequently add new tutorials and clarify existing parts
   in response to common user questions. Good documentation makes it easier for
   new users to onboard, and targeted tutorials make it possible to share best
   practice.
 * Support: we provide free community support on [http://jump.dev/forum](http://jump.dev/forum).
   The forum is highly active, and multiple speakers have talked about the fast
   and informative support they get from reading and asking questions.

However, there are a few common complaints and suggestions for how we could
improve JuMP in the context of energy modeling:

 * Developing efficient Julia code can be hard. Writing code like you would in
   MATLAB or Python does not result in performant Julia code. Similarly, writing
   models like you would in GAMS does not result in fast JuMP code. We need to
   better highlight these differences, particularly for new users who are
   transitioning to JuMP from other tools.
 * We need better support for sparse variables. The default `SparseAxisArray` in
   JuMP has a number of performance problems (it is really just a thin wrapper
   around `Base.Dict`). SINTEF have developed [SparseVariables.jl](https://github.com/sintefore/SparseVariables.jl).
   We will think about how we can better integrate this into JuMP.
 * We need better support for physical units. One of the most common bugs in
   energy system models related to mismatched physical units, whether that is
   data given in kilowatts instead of megawatts, or feet instead of meters.
   Pyomo has long supported physical units, and SINTEF have developed [UnitJuMP.jl](https://github.com/trulsf/UnitJuMP.jl).
   Adding support for physical units is an [open issue in JuMP (#1350)](https://github.com/jump-dev/JuMP.jl/issues/1350)
   and is on our [roadmap](https://jump.dev/JuMP.jl/stable/developers/roadmap/).
 * We need better tools for debugging JuMP models. Despite making it easy for
   users to formulate and solve a wide range of optimization problems, JuMP
   provides little support for the users who make mistakes, or tools for
   advanced users to debug problematic models. Moreover, in our experience the
   majority of (expensive) human programmer time is spent, not on formulating or
   solving a model, but on the debugging and testing stage of development. There
   is an [open issue in JuMP (#3664)](https://github.com/jump-dev/JuMP.jl/issues/3664)
   that contains some preliminary ideas for features we could add that would
   help users debug and test JuMP models.

To summarize, JuMP is a powerful tool for energy system modeling. The insights
from JuMP-dev 2024 will help guide future developments, particularly in areas
like debugging, physical units, and sparse variable support.

## Contents

This post ended up being pretty long, so here is a table of contents if you want
to JuMP (if you will) around:

 1.  [[2024] Applied optimization with JuMP at SINTEF](#2024-applied-optimization-with-jump-at-sintef)
 2.  [[2024] Introduction to TulipaEnergyModel.jl](#2024-introduction-to-tulipaenergymodeljl)
 3.  [[2024] SpineOpt.jl: A highly adaptable modelling framework for multi-energy systems](#2024-spineoptjl-a-highly-adaptable-modelling-framework-for-multi-energy-systems)
 4.  [[2024] Solving the Market-to-Market Problem in Large Scale Power Systems](#2024-solving-the-market-to-market-problem-in-large-scale-power-systems)
 5.  [[2024] PiecewiseAffineApprox.jl](#2024-piecewiseaffineapproxjl)
 6.  [[2023] How JuMP Enables Abstract Energy System Models](#2023-how-jump-enables-abstract-energy-system-models)
 7.  [[2023] TimeStruct.jl: Multi Horizon Time Modelling in JuMP](#2023-timestructjl-multi-horizon-time-modelling-in-jump)
 8.  [[2023] Designing a Flexible Energy System Model Using Multiple Dispatch](#2023-designing-a-flexible-energy-system-model-using-multiple-dispatch)
 9.  [[2022] UnitJuMP: Automatic Unit Handling in JuMP](#2022-unitjump-automatic-unit-handling-in-jump)
 10. [[2022] SparseVariables.jl: Efficient Sparse Modelling with JuMP](#2022-sparsevariablesjl-efficient-sparse-modelling-with-jump)
 11. [[2022] Benchmarking Nonlinear Optimization with AC Optimal Power Flow](#2022-benchmarking-nonlinear-optimization-with-ac-optimal-power-flow)
 12. [[2021] Modelling Australia's National Electricity Market with JuMP](#2021-modelling-australias-national-electricity-market-with-jump)
 13. [[2021] AnyMOD.jl: A Julia package for creating energy system models](#2021-anymodjl-a-julia-package-for-creating-energy-system-models)
 14. [[2021] Power Market Tool (POMATO)](#2021-power-market-tool-pomato)
 15. [[2021] UnitCommitment.jl Security-Constrained Unit Commitment in JuMP](#2021-unitcommitmentjl-security-constrained-unit-commitment-in-jump)
 16. [[2021] A Brief Introduction to InfrastructureModels](#2021-a-brief-introduction-to-infrastructuremodels)
 17. [[2019] PowerSimulations.jl](#2019-powersimulationsjl)
 18. [[2017] Stochastic programming in energy systems](#2017-stochastic-programming-in-energy-systems)
 19. [[2017] PowerModels.jl: a Brief Introduction](#2017-powermodelsjl-a-brief-introduction)

## [2024] Applied optimization with JuMP at SINTEF

_Speaker: Truls Flatberg @trulsf_

<iframe width="560" height="315" src="https://www.youtube.com/embed/-a9-ToFiT8E?si=rpQeHt1__-lwxjXT" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

In this [prize-winning](prize/jump-dev-2024) talk, Truls discussed how they have
been using JuMP to build and solve large scale optimization models at SINTEF.

Developers from SINTEF have been active attendees of JuMP-dev recently, speaking
about [UnitJuMP.jl](#2022-unitjump-automatic-unit-handling-in-jump) and
[SparseVariables.jl](#2022-sparsevariablesjl-efficient-sparse-modelling-with-jump) at
[JuMP-dev 2022](/meetings/juliacon2022/), and
[TimeStruct.jl](#2023-timestructjl-multi-horizon-time-modelling-in-jump) and
[EnergyModelsX](#2023-designing-a-flexible-energy-system-model-using-multiple-dispatch)  at
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

Truls gave a shout out to a tutorial I wrote, [Design patterns for large models](https://jump.dev/JuMP.jl/stable/tutorials/getting_started/design_patterns_for_larger_models/),
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

[_Back to contents_](#contents)

## [2024] Introduction to TulipaEnergyModel.jl

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

[_Back to contents_](#contents)

## [2024] SpineOpt.jl: A highly adaptable modelling framework for multi-energy systems

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
Similarly, I develop [SDDP.jl](http://sddp.dev), which is a generic library for
solving multistage stochastic optimization problems using a form of Benders
decomposition. SDDP.jlj is used to solve energy-related problems, such as the
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

[_Back to contents_](#contents)

## [2024] Solving the Market-to-Market Problem in Large Scale Power Systems

_Speaker: Jose Daniel Lara @jd-lara_

<iframe width="560" height="315" src="https://www.youtube.com/embed/N-jDHickaTc?si=T7eQnTopbCCtES3X" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

In this talk Jose Daniel gave an overview and spoke about recent updates to
[Sienna](https://www.nrel.gov/analysis/sienna.html) (originally named SIIP).
The talk follows his previous talks at [JuMP-dev 2019](#2019-powersimulationsjl)
and [JuMP-dev 2023](https://www.youtube.com/watch?v=J7VbCKsnTvQ).

A key feature of the Sienna set of tools is that it is designed for problems with _O(10⁸)_
variables and constraints. They are building and solving simulation models of
the Eastern Interconnection, which is one of, if not the, largest power system
in the world (it has 150,000 buses and 270,000 lines).

A key lesson that I took from Jose Daniel's talk is that they have already
encountered (and resolved or worked around) many of same issues that Diego
raised in his talk, such as how to efficiently save the large volume of data
that comes out of the simulation models.

In regard to feature requests for future versions of JuMP, Jose Daniel again
referenced the need for efficient re-solves of optimization models with
parameters. We have, over the years, experimented with a number of different
approaches in Sienna, including the now largely defunct [ParameterJuMP.jl](https://github.com/JuliaStochOpt/ParameterJuMP.jl),
the intended replacement [ParametricOptInterface.jl](https://github.com/jump-dev/ParametricOptInterface.jl),
and other work-arounds like adding new `VariableIndex in EqualTo` constraints.
Ultimately, each way has a different trade-off (and it also depends on the size
of the model that you are trying to solve), and we haven't found something that
we are completely happy with.

My main takeaways are that we should include benchmarks that use
ParametricOptInterface.jl in our [jump-dev/open-energy-modeling-benchmarks](https://github.com/jump-dev/open-energy-modeling-benchmarks)
repository, and that JuMP's ability to efficiently solve a sequence of similar
problems with some changes in the problem parameters is both a main selling
point of using JuMP over alternative tools and a current bottleneck in existing
workflows.

[_Back to contents_](#contents)

## [2024] PiecewiseAffineApprox.jl

_Speaker: Lars Hellemo @hellemo_

<iframe width="560" height="315" src="https://www.youtube.com/embed/rm292x59Yjk?si=8lN8MDgFQgUvsHZq" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

In this talk, Lars presented his work on a new package,
[PiecewiseAffineApprox.jl](https://github.com/sintefore/PiecewiseAffineApprox.jl),
which automatically approximates nonlinear functions with a linearized MIP
formulation that can be used in a linear solver like HiGHS. The package is used
by SINTEF in many of their energy-related applications.

JuMP core developer Joey Hutchette @joehuchette wrote a similar package,
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

[_Back to contents_](#contents)

## [2023] How JuMP Enables Abstract Energy System Models

_Speaker: Stefan Strömer @sstroemer_

<iframe width="560" height="315" src="https://www.youtube.com/embed/IFI-u6TiuBk?si=Jco2_udi2BcuDNuj" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

In this talk, Stefan discussed an energy system model they have been developing.
A unique feature of their model is that they want to scale from low-latency
model predictive control to continental scale models. Their approach is no-code,
with the complete input described in YAML and CSV files.

Stefan again gives an example that their initial experience with JuMP was not
good because it did not fit their object-orientated design philosophy. However,
after working with it for a while and changing their approach, they are now very
happy with it and with its performance.

Stefan also talked about the need for parameters, and how `parameter * variable`
support would be useful, but that it complicates matters. We had
[multiple](https://discourse.julialang.org/t/jump-multiplicative-parameters-for-lp/94192)
[discussions](https://discourse.julialang.org/t/moi-re-evaluate-custom-bridge-direct-model-bridging/94219)
on the community forum, and Stefan opened a [PR with over 50 comments](https://github.com/jump-dev/MathOptInterface.jl/pull/2092)
that was ultimately closed without merging. This is a tricky topic for which we
do not have a good solution.

[_Back to contents_](#contents)

## [2023] TimeStruct.jl: Multi Horizon Time Modelling in JuMP

_Speaker: Truls Flatberg @trulsf_

<iframe width="560" height="315" src="https://www.youtube.com/embed/Hz6AL5kClKU?si=X2oqhPM3OaqaNsAe" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

In this talk Truls presented his work on [TimeStruct.jl](https://github.com/sintefore/TimeStruct.jl),
(if you watch the video, the package is now registered!) which is a JuMP
extension for working with time-structured models that often arise in planning
problems.

Truls points out that a key feature of JuMP is its modularity, and how they can
invest in the development of small utility packages like TimeStruct.jl, and then
re-use the utility package across many different application models.

If you are building a JuMP model with time as a significant component, we
recommend that you try out
[TimeStruct.jl](https://github.com/sintefore/TimeStruct.jl).

[_Back to contents_](#contents)

## [2023] Designing a Flexible Energy System Model Using Multiple Dispatch

_Speaker: Julian Straus @JulStraus_

<iframe width="560" height="315" src="https://www.youtube.com/embed/fARbeM8sANA?si=tETN7GSZNzW5ZzCU" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

In this talk, Julian discusses [EnergyModelsX](https://github.com/EnergyModelsX)
that he is building at SINTEF.

I found it useful to compare the talk to Jose Daniel's
[[2019] PowerSimulations.jl](#2019-powersimulationsjl).
If multiple groups arrive at the same set of ideas, I think it demonstrates that
hierarchical models that leverage Julia's multiple dispatch is the "right" way
to build large-scale JuMP models.

This approach is the topic of my tutorial,
[Design patterns for large models](https://jump.dev/JuMP.jl/stable/tutorials/getting_started/design_patterns_for_larger_models/),
which I think should be required reading for anyone embarking on the development
of an industrial-scale JuMP project.

[_Back to contents_](#contents)

## [2022] UnitJuMP: Automatic Unit Handling in JuMP

_Speaker: Truls Flatberg @trulsf_

<iframe width="560" height="315" src="https://www.youtube.com/embed/JQ6_LZfYRqg?si=Aj1yNzNDgPodqC2u" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

In this talk Truls presented his work on UnitJuMP.jl, which is a JuMP extension
that adds support for modeling with variables and constraints that are attached
to physical units (which is the topic of the second oldest open issue in JuMP,
[JuMP#1350](https://github.com/jump-dev/JuMP.jl/issues/1350)). UnitJuMP prevents
common modeling errors such as missing a scale factor from kilo- to mega-, or by
using feet instead of meters.

Adding support for physical units is an
[open issue in JuMP (#1350)](https://github.com/jump-dev/JuMP.jl/issues/1350)
and is on our [roadmap](https://jump.dev/JuMP.jl/stable/developers/roadmap/).
For now, readers are encouraged to use and try out UnitJuMP. At some point, we
will better integrate the features of UnitJuMP into the core JuMP repository.

[_Back to contents_](#contents)

## [2022] SparseVariables.jl: Efficient Sparse Modelling with JuMP

_Speaker: Lars Hellemo @hellemo_

<iframe width="560" height="315" src="https://www.youtube.com/embed/YuDvfZo9W5A?si=A0LQR4Rus94j_1qh" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

In this talk Lars presented his work on [SparseVariables.jl](https://github.com/sintefore/SparseVariables.jl),
which is SINTEF's solution for dealing with the common problems associated with
the sparse index sets that often arise in industrial JuMP models.

For now, readers are encouraged to use and try out SparseVariables. At some
point, we should think about how to better integrate the features of
SparseVariables into the core JuMP repository.

[_Back to contents_](#contents)

## [2022] Benchmarking Nonlinear Optimization with AC Optimal Power Flow

_Speaker: Carleton Coffrin @ccoffrin_
<iframe width="560" height="315" src="https://www.youtube.com/embed/tvBNQcuU-hY?si=fSJKG_OK-RhkXAnq" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

This talk by Carleton isn't really about energy modeling, but it is about
solving nonlinear AC Optimal Power Flow problems. I'm including it here for
reader interest because it demonstrates that JuMP is a great tool for building
and solving energy-related optimization problems.

[_Back to contents_](#contents)

## [2021] Modelling Australia's National Electricity Market with JuMP

_Speaker: James Foster @jd-foster_

<iframe width="560" height="315" src="https://www.youtube.com/embed/gbSVH8Q0xq4?si=IeZgeipH3UhTTnkz" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

In this talk, James provided a general overview of developing models in JuMP. A
useful part of the talk was how he mentioned the challenge of working with
sparsely indexed parameters and variables. We just saw that SINTEF solved this
challenge by developing SparseVariables.jl. James solved the challenge by
loading the data into SQLite tables, performing the computationally intensive
transformation steps using SQL, and then outputting clean tables to DataFrames
for use in JuMP.

This is the same approach that I have taken in tutorials like
[The network multi-commodity flow problem](https://jump.dev/JuMP.jl/stable/tutorials/linear/multi_commodity_network/),
so I wonder if it would be helpful for other users if we advertised this more
widely.

James also raises the reoccurring theme that scaling up your model will present
different issues than the model design phase.

[_Back to contents_](#contents)

## [2021] AnyMOD.jl: A Julia package for creating energy system models

_Speaker: Leonard Goeke @leonardgoeke_

<iframe width="560" height="315" src="https://www.youtube.com/embed/QE_tNDER0F4?si=8TTH54xkuz88tnmY" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

In this talk, Leonard presented his work on [AnyMOD.jl](https://github.com/leonardgoeke/AnyMOD.jl).
Like Stefan's approach, AnyMOD.jl is a low-code model, in which all inputs and outputs are
via CSV files.

A unique feature of AnyMOD is that it has automatic scaling of the problem to
increase the robustness of interior point solves. This is something that JuMP
has not provided in the past, although we sometimes get it as a feature request.
I am still divided on whether this is something that we should support, because
in my experience, models that need automatic rescaling are typically "wrong" in
the sense that they are defined at the wrong level of detail (for example,
measuring costs to the nearest cent for investment problems that invest billions
of dollars over decades).

Like [[2021] Modelling Australia's National Electricity Market with JuMP](#2021-modelling-australias-national-electricity-market-with-jump),
AnyMOD uses DataFrames and SQL joins to do the various transformations required
to get the problem data into a format suitable for JuMP.

[_Back to contents_](#contents)

## [2021] Power Market Tool (POMATO)

_Speaker: Richard Weinhold @richard-weinhold_

<iframe width="560" height="315" src="https://www.youtube.com/embed/n0wmYTm6Y64?si=w9NJH0CzvC_hqPEQ" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

In this talk, Richard presented his work on [POMATO](https://github.com/richard-weinhold/pomato).
POMATO has a Python front-end, but it uses JuMP for its
[MarketModel](https://github.com/richard-weinhold/MarketModel) and
[RedundancyRemoval](https://github.com/richard-weinhold/RedundancyRemoval)
components. POMATO makes heavy use of JuMP's ability to efficiently represent
second-order cone constraints to solve a stochastic power flow problem with
chance constraints.

POMATO is a good example of a project to look at for inspiration if you want to
mix Python and Julia.

[_Back to contents_](#contents)

## [2021] UnitCommitment.jl Security-Constrained Unit Commitment in JuMP

_Speaker: Alinson Xavier @iSoron_

<iframe width="560" height="315" src="https://www.youtube.com/embed/rYUZK9kYeIY?si=zUdYsvHk_we_qbYb" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

In this talk, Alinson presented his work on
[UnitCommitment.jl](https://github.com/ANL-CEEESA/UnitCommitment.jl). The
package is a collection of data and implementations of the multi-period unit
commitment problem, which is often a core part of energy system models that
focus on the operation of a power system with sub-hourly resolution.

A key part of UnitCommitment.jl is a JSON file format for unit commitment
problems. This could be useful as we look to build a collection of benchmark
instances in [jump-dev/open-energy-modeling-benchmarks](https://github.com/jump-dev/open-energy-modeling-benchmarks).

[_Back to contents_](#contents)

## [2021] A Brief Introduction to InfrastructureModels

_Speaker: Carleton Coffrin @ccoffrin_

<iframe width="560" height="315" src="https://www.youtube.com/embed/POOt1FCA8LI?si=zJK3Pr5DQvqtYY6n" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

This is a general interest talk by Carleton isn't really about energy modeling,
but it is about the much larger suite of models around
[InfrastructureModels.jl](https://github.com/lanl-ansi/InfrastructureModels.jl)
that they are building at LANL.

If you are writing energy system models, InfrastructureModels.jl and related
packages like PowerModels.jl are a good place to look for inspiration.

[_Back to contents_](#contents)

## [2019] PowerSimulations.jl

_Speaker: Jose Daniel Lara @jd-lara_

<iframe width="560" height="315" src="https://www.youtube.com/embed/JAHjZYiIJeI?si=euyA8WzK-lEs_Pg9" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

This talk is the first talk by Jose Daniel at a JuMP-dev on PowerSimulations.jl
(now part of Sienna). I found it useful to compare this talk to
[his talk at JuMP-dev 2024](#2024-solving-the-market-to-market-problem-in-large-scale-power-systems).

Jose Daniel described how the three design principles of PowerSimulations were
flexibility, modularity, and scalability, and how all three of these were
achieved by using Julia's multiple dispatch to build different mathematical
formulations based on the input data. I found it interesting that Jose Daniel
hits upon on many of the same themes that Julian did in his 2023 talk
[[2023] Designing a Flexible Energy System Model Using Multiple Dispatch](#2023-designing-a-flexible-energy-system-model-using-multiple-dispatch).
This suggests to me that we can better share lessons learned between developers.

Jose Daniel also talks about the issue with parameters and time-series data.
Five years later and we still do not have a perfect solution to this.

Finally, Jose Daniel talked about how they wanted to scale to 50,000 buses.
Well, in his [2024 talk](#2024-solving-the-market-to-market-problem-in-large-scale-power-systems),
he mentioned that Sienna now runs on problems with 150,000 buses. It's nice to
see progress!

[_Back to contents_](#contents)

## [2017] Stochastic programming in energy systems

_Speaker: Joaquim Dias Garcia @joaquimg_

<iframe width="560" height="315" src="https://www.youtube.com/embed/HwOOww8vwyA?si=Hs065CFXrIe2kg6q" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

In this talk from the first JuMP-dev, Joaquim discussed how PSR were using JuMP
to solve a variety of energy-related models, both for research and for
industrial clients around the world.

For me, it was interesting to revisit this talk because Joaquim's discussion
about stochastic dual dynamic programming (I develop [SDDP.jl](https://sddp.dev).)
Joaquim described how they implemented some of the algorithm in JuMP, and some
in [MathProgBase](https://github.com/JuliaOpt/MathProgBase.jl). I note that many
of the missing features that drove him to do so (like the ability to delete
variables and constraints) are now first-class features in JuMP.

One pertinent feature is that Joaquim described the need for an IIS (irreducible
infeasible subsystem) solver to help debugging. At the moment, some solvers like
Gurobi and Xpress provide native support for computing an IIS, while others like
HiGHS and Ipopt do not. It would be useful to add native support for the IIS to
HiGHS, and it would also be useful to write a generic IIS solver in
MathOptInterface for optimizers that do not have native support.

[_Back to contents_](#contents)

## [2017] PowerModels.jl: a Brief Introduction

_Speaker: Carleton Coffrin @ccoffrin_

<iframe width="560" height="315" src="https://www.youtube.com/embed/W4LOKR7B4ts?si=__mZY2mAsJWTZXeD" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

This is a talk about [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl)
from the first JuMP-dev, which we held in 2017 at MIT. PowerModels.jl is one of
the oldest JuMP-related packages for power system optimization.

To me, there are two design features of PowerModels.jl which stick out, and have
changed very little over the course of PowerModels development.

First, the input data is parsed from MATPOWER files into untyped dictionaries.
This makes it easy for domain-expert users to work with, but Julia code that
operates on the input data is not type stable. This design decision is the
opposite of that chosen by [[2019] PowerSimulations.jl](#2019-powersimulationsjl).
It is an open question whether this was a good design decision. It seems to work
for PowerModels, but it may not work for larger simulation models.

Second, PowerModels makes heavy use of Julia's multiple dispatch to implement
the various relaxations and approximations of AC power flow. This decision has
proven to be a very good design choice.

[_Back to contents_](#contents)
