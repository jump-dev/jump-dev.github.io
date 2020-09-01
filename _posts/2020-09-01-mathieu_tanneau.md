---
layout: post
title:  "Mathieu Tanneau | Design and implementation of the interior-point solver Tulip"
date:   2020-09-01
categories: [jump-dev]
---

Mathieu Tanneau, a Ph.D. student at the Polytechnique Montréal, gave his talk
that was accepted for JuMP-dev 2020 on the design and implementation of the
interior-point solver [Tulip.jl](https://github.com/ds4dm/Tulip.jl) during
August 2020's JuMP monthly developer call.

<iframe width="560" height="315" src="https://www.youtube.com/embed/lT1DExrUZYc" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Abstract

[Tulip.jl](https://github.com/ds4dm/Tulip.jl) is an open-source linear
optimization interior-point solver written in Julia. Its main features include
the handling of arbitrary numerical precision, and its ability to exploit
specialized routines for structured linear algebra. We present Tulip's
regularized homogeneous interior-point algorithm, and outline some of the design
choices and challenges in its implementation. In particular, we will focus on
linear algebra techniques, data structures, and interfaces.

