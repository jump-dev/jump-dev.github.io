---
layout: post
title:  "An Open Energy Modeling update"
date:   2025-01-27
categories: [open-energy-modeling]
author: "Oscar Dowson, Ivet Galabova, Joaquim Dias Garcia, Julian Hall"
---

We're now four months into our [Open Energy Modeling project](/announcements/open-energy-modeling/2024/09/16/oem/).
This blog post is a summary of some of things that we have been up to.

## Community engagement

We have increased engagement between the developers of JuMP and HiGHS and the
open energy modeling community. We have done this by holding fortnightly
stakeholder calls, publishing bi-monthly updates on the JuMP blog (like this
one), and interacting with the developers of energy modeling frameworks by
opening issues and pull requests on GitHub. As a general comment, we (the
developers of JuMP and HiGHS) now have a much better understanding of the types
of problems that are of interest to energy modelers, and these problems have
"unusual" characteristics that are not typical of the wider optimization
community.

If you are an open energy modeller who uses JuMP or HiGHS and you want to stay
in touch with our progress or provide us with feedback and examples, write to
`jump-highs-energy-models@googlegroups.com`. We'd love to hear how you are using
JuMP or HiGHS to solve problems related to open energy modelling.

## JuMP-dev

We held an energy modeling session at [JuMP-dev 2024](/meetings/jumpdev2024/),
which was held in July in Montreal, Canada. All talks from the workshop are
[available on YouTube](https://youtube.com/playlist?list=PLP8iPy9hna6TAzZJvloYK9NBD5qgFJ1PQ&feature=shared).
We [published a report](/open-energy-modeling/2024/09/19/open-energy-models/)
summarizing energy modeling talks from all past JuMP-dev workshops. We plan to
hold further sessions at the [HiGHS Workshop](https://workshop25.highs.dev) in
July and [JuMP-dev 2025](/meetings/jumpdev2025/) in November.

## open-energy-modeling-benchmarks

In collaboration with energy modelers from GenX, Sienna, Tulipa, and others, we
built [open-energy-modeling-benchmarks](https://github.com/jump-dev/open-energy-modeling-benchmarks).
This GitHub repository is both a collection of energy-focused benchmark
instances for MIP solvers, and a collection of scripts for the end-to-end
profiling of JuMP-based energy modeling frameworks.

## Open Energy Transition

We have started a collaboration with [Open Energy Transition](https://openenergytransition.org)
(OET) on their [solver-benchmark](https://github.com/open-energy-transition/solver-benchmark)
project. In particular, we have shared our benchmark instances with them and
[adopted their metadata format](https://github.com/jump-dev/open-energy-modeling-benchmarks/issues/42)
for structuring benchmarks so that OET can import any future updates to our
benchmarks with minimal effort. In addition, we have incorporated their
benchmarks from PyPSA into our analysis of HiGHS, and we have maintained a
back-and-forth dialog on how to appropriately benchmark MIP solvers. We have
also chimed in on some issues for their linopy modeling framework ([linopy#402](https://github.com/PyPSA/linopy/issues/402)).

## Profiling

We used HiGHS to profile the benchmark instances from
open-energy-modeling-benchmarks, OET, and Hans Mittelmann’s MIPLIB. These
benchmarks revealed a significant difference between the performance of HiGHS on
the general purpose MIPLIB set and the performance of HiGHS on the
energy-focused models. We will have more to share publicly at a later date.

## Performance improvements

Using the initial results of our benchmarks, we have begun implementing
performance improvements to HiGHS. As one example, a model from Tulipa that did
not solve in a time limit of 3 hours can now be solved in 250 seconds
([HiGHS#2049](https://github.com/ERGO-Code/HiGHS/issues/2049)).

## Critical bugs

Working with the developers of Sienna and Tulipa, we found and fixed a number of
critical bugs in HiGHS. This included multiple segfaults
([HiGHS#1990](https://github.com/ERGO-Code/HiGHS/issues/1990),
[HiGHS#2109](https://github.com/ERGO-Code/HiGHS/issues/2109)), a case where
HiGHS failed to detect that the problem did not have a solution
([HiGHS#1962](https://github.com/ERGO-Code/HiGHS/issues/1962)), and a case where
HiGHS returned an incorrect solution because the energy modeler was running with
a set of non-default options in an attempt to improve performance
([HiGHS#1935](https://github.com/ERGO-Code/HiGHS/issues/1935)).

As part of this work, we implemented a new way to debug the interaction of JuMP
and HiGHS that allowed us to reproduce and fix a segfault that had been
undiagnosed for one year
([HiGHS.jl#258](https://github.com/jump-dev/HiGHS.jl/issues/258)).

## GenX

Working with the developers of GenX, we identified a number of possible
performance improvements to the GenX codebase
([GenX#773](https://github.com/GenXProject/GenX.jl/pull/773)). As a result, we
made a number of changes to both GenX
([GenX#815](https://github.com/GenXProject/GenX.jl/pull/815)) and JuMP
([MutableArithmetics#302](https://github.com/jump-dev/MutableArithmetics.jl/issues/302)),
with the result that GenX models are now 12% faster to build.

## Sienna

Working with the developers of Sienna, we identified a number of performance
bottlenecks in their code and in JuMP:

 * Saving models to disk (for later reproducibility) was a critical bottleneck
   in their optimization pipeline. Since this is an uncommon operation for a
   performance sensitive application, this code in JuMP was not optimized. We
   rewrote the relevant parts of JuMP
   ([MathOptInterface#2606](https://github.com/jump-dev/MathOptInterface.jl/pull/2606),
   [MathOptInterface#2613](https://github.com/jump-dev/MathOptInterface.jl/pull/2613)).
   This lead to a 5x speedup in saving models to disk.
 * In addition to saving models to disk for reproducibility, Sienna also
   serializes the version of every package and dependency. We modified Sienna to
   use a faster code path
   ([InfrastructureSystems#423](https://github.com/NREL-Sienna/InfrastructureSystems.jl/pull/423)).
 * Sienna performed a number of redundant computations when importing
   time-series data. These computations are now performed once and then caching
   the values for future time-steps
   ([InfrastructureSystems#409](https://github.com/NREL-Sienna/InfrastructureSystems.jl/issues/409),
   [InfrastructureSystems#410](https://github.com/NREL-Sienna/InfrastructureSystems.jl/pull/410))

The net impact of these changes is that the time spent by Sienna outside of the
HiGHS solver is reduced by half. The overall benchmark time depends on the
specific model and how long HiGHS takes to solve the model. Currently, the total
runtime improvement is approximately 5% faster with 15% less memory required,
but this percentage will increase as HiGHS becomes faster.

Working with the developers of Sienna, we identified a number of common Julia
and JuMP-related anti-patterns in the Sienna code base
([PowerSimulations#1218](https://github.com/NREL-Sienna/PowerSimulations.jl/pull/1218)).
This included unnecessary array copies when indexing, suboptimal loop order
when iterating over matrices, and type stability issues when re-using variable
names within a function. Although each of these issues have a minor runtime
impact, their cumulative effect can be large, if hard to benchmark. Therefore,
our suggested best practice is to avoid these issues in the first place. In
addition to providing guidance to the Sienna developers, we will update the JuMP
documentation to better highlight these anti-patterns for the benefit of all
energy system developers ([JuMP#2348](https://github.com/jump-dev/JuMP.jl/issues/2348#issuecomment-2618076446)).

We also identified that an optional check of the input data was a critical
performance bottleneck in Sienna's optimization pipeline. The check iterated
over the data in HiGHS to identify common mistakes such as mis-matched units, or
trivially infeasible solutions such as initial generator setpoints outside their
operating bounds. The way this algorithm was implemented in HiGHS meant that the
time taken increased with the square of the problem size, so larger models were
particularly affected. We rewrote the algorithm so that the time taken now
increases linearly with problem size and, in our initial benchmarking, the check
went from taking minutes to never taking more than a few seconds
([HiGHS#2114](https://github.com/ERGO-Code/HiGHS/issues/2114)). Benchmarking
this in the context of an end-to-end run of Sienna will require a new release of
HiGHS.

## Tulipa

Working with the developers of Tulipa, we identified a bottleneck in their model
building pipeline that was caused by the informative string names of variables
and constraints used when debugging. Turning off these names when not debugging
led to a 30% decrease in the time taken to build the model
([Tulipa#936](https://github.com/TulipaEnergy/TulipaEnergyModel.jl/pull/936)).

## SpineOpt

Working with the developers of SpineOpt, we identified an issue with their code
base that leads to non-deterministic model creation
([SpineOpt#1143](https://github.com/spine-tools/SpineOpt.jl/issues/1143)). This
can mean that, all else equal, the same model solved on two different machines
can return different solutions. This can make benchmarking and reproducibility
difficult. The Spine developers are investigating.

## HiGHS.jl

The profiling of energy system models revealed that adding variables to a HiGHS
model can be a bottleneck. We implemented changes to JuMP and HiGHS.jl so that
adding bounded variables is now three times faster than before
([HiGHS.jl#248](https://github.com/jump-dev/HiGHS.jl/pull/248)).

## Other changes

We have extended the local testing of HiGHS, making it possible to run unit
tests from an external repository. The external unit tests are built with CMak
and Catch2, consistent with the ones already in HiGHS. It is also possible to
use private problem instances for additional checks, as we consider introducing
modifications to the code. A thorough analysis of updates is very helpful as we
implement more major updates to the solution algorithms. The separation of new
tests from the HiGHS code allows for more comprehensive testing with no
additional code shipped to the users, keeping the solver lightweight and easy to
integrate within other systems.

The code coverage functionality in HiGHS was updated and coverage reports are
now generated and uploaded to Codecov on each PR to our development and master
branches ([HiGHS#2112](https://github.com/ERGO-Code/HiGHS/issues/2112),
[HiGHS#2138](https://github.com/ERGO-Code/HiGHS/issues/2138)).

We have developed local benchmarking infrastructure for use during the
development of HiGHS. Running specific test sets, we record output from the
HiGHS library, as well as collecting additional debugging and development
output, to test the correctness and speed of HiGHS and any potential
improvements. For some of the experiment results presented here, a dedicated
local server was used, with no other tasks running, required for reliable timing
results. The new benchmark infrastructure will allow us to gather such results
much faster, in an automated and reproducible way.
