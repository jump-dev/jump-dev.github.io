---
layout: post
title:  "NumFOCUS small development grant: adding complex number support to JuMP"
date:   2022-04-19
categories: [announcements]
---

The [JuMP Steering Committee](/pages/governance/#steering-committee) is pleased
to announce that we have received a
[small development grant](https://numfocus.org/programs/small-development-grants)
from [NumFOCUS](https://numfocus.org) to add complex number support to JuMP.

Currently, JuMP and MathOptInterface are limited to formulating optimization
problems with real-valued decision variables. However, complex numbers appear in
a variety of industrial optimization problems. The most important of these is
the AC optimal power flow problem (AC-OPF), which is used world-wide to optimize
the operations of electrical power grids. Currently, users in JuMP are forced to
decompose their problem into the real and complex parts. This leads to a
duplication in which twice as many variables are needed, reducing readability
and increasing the likelihood of bugs.

The lack of complex number support has been a common source of complaint for
users of JuMP, and many users leave JuMP for alternative tools which have
complex-number support. In addition, this has prevented users moving to JuMP
from proprietary solutions such as MATLAB.

The person being funded is [Dr. Benoît Legat](https://github.com/blegat), a core
contributor to JuMP, and the project builds upon his work developing
[ComplexOptInterface.jl](https://github.com/jump-dev/ComplexOptInterface.jl).

The grant has three key deliverables:

 * Improve ComplexOptInterface.jl from a proof-of-concept into a robust,
   production-ready library
 * Integrate ComplexOptInterface into MathOptInterface and document
 * Integrate ComplexOptInterface into JuMP and document.

Benoît will be working on a part-time basis over the coming year, and will
present an update during [JuMP-dev 2022](/meetings/juliacon2022/).

_Miles Lubin, Juan Pablo Vielma, Carleton Coffrin, Oscar Dowson and Changhyun Kwon._
