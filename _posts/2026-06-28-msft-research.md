---
layout: post
title:  "JuMP powers foundational models for the electric grid"
date:   2026-06-28
categories: [open-energy-modeling]
author: "Oscar Dowson"
---

Microsoft Research [recently published GridSFM](https://www.microsoft.com/en-us/research/blog/gridsfm-a-new-small-foundation-model-for-the-electric-grid/),
a small foundation model for the electric grid. We were pleased to notice that
the training pipeline is powered by JuMP and [PowerModels.jl](https://lanl-ansi.github.io/PowerModels.jl/stable/).

To generate the training data for GridSFM, the Microsoft team solved hundreds of
thousands of AC optimal power flow (AC-OPF) problems across 150+ real grid
topologies. They did this using [PowerModels.jl](https://lanl-ansi.github.io/PowerModels.jl/stable/),
a Julia package for power network optimization built on JuMP, with Ipopt as the
underlying solver. Their code is open source on GitHub at [microsoft/GridSFM](https://github.com/microsoft/GridSFM/tree/1ca775fd436d7ce013a1c0ab946e61ac7ef59ad6/power_grid/US/topology_solver_pipeline).

A related project is the [GridFM DataKit](https://github.com/gridfm/gridfm-datakit),
which similarly uses JuMP and PowerModels.jl to generate training data for grid
foundation models. The team behind it have [published an arXiv paper](https://arxiv.org/pdf/2512.14658)
describing their work. An interesting aspect of GridFM DataKit is that the
front-end is a Python package, but it calls Julia and PowerModels via
[juliacall](https://juliapy.github.io/PythonCall.jl/stable/juliacall/).

It's great to see JuMP and the broader Julia ecosystem being used at this scale.

You can learn more about foundation models of the electric grid by watching the
recordings of the [5th Workshop on Foundation Models of the Electric Grid](https://gridfm.org/harvard/).

If your work uses JuMP, we'd love to hear about it. The best way to tell us is
by [opening a GitHub issue](https://github.com/jump-dev/jump-dev.github.io/issues).
