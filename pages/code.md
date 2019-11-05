---
layout: page
title:  "The JuMP ecosystem"
---

The JuMP project consists of the main [JuMP](https://github.com/juliaopt/JuMP.jl)
package, and a large collection of supporting Julia packages.

The JuMP source code can be found at [https://github.com/JuliaOpt/JuMP.jl](https://github.com/JuliaOpt/JuMP.jl).

Beneath JuMP, there is an abstraction layer called MathOptInterface ([source code](https://github.com/JuliaOpt/MathOptInterface.jl)). MathOptInterface defines an API that solvers
should implement so that they can be used by JuMP, handles the automatic
reformulation of problems via _bridges_, and has a large infrastructure for
automatically testing solvers.

At the bottom of the stack, there are solver wrappers. These packages wrap the
solvers, which are often written in C or C++, and implement the API defined by
MathOptInterface.

A non-exhaustive list of solvers available through JuMP is given by the
following table.

| Solver                                                                         | Julia Package                                                                    | License | Supports                           |
| ------------------------------------------------------------------------------ | -------------------------------------------------------------------------------- | ------- | ---------------------------------- |
| [Artelys Knitro](https://www.artelys.com/knitro)                               | [KNITRO.jl](https://github.com/JuliaOpt/KNITRO.jl)                               | Comm.   | LP, MILP, SOCP, MISOCP, NLP, MINLP |
| [Cbc](https://projects.coin-or.org/Cbc)                                        | [Cbc.jl](https://github.com/JuliaOpt/Cbc.jl)                                     | EPL     | MILP                               |
| [CDCS](https://github.com/oxfordcontrol/CDCS)                                  | [CDCS.jl](https://github.com/oxfordcontrol/CDCS.jl)                              | GPL     | LP, SOCP, SDP                      |
| [CDD](https://github.com/cddlib/cddlib)                                        | [CDDLib.jl](https://github.com/JuliaPolyhedra/CDDLib.jl)                         | GPL     | LP                                 |
| [Clp](https://projects.coin-or.org/Clp)                                        | [Clp.jl](https://github.com/JuliaOpt/Clp.jl)                                     | EPL     | LP                                 |
| [COSMO](https://github.com/oxfordcontrol/COSMO.jl)                             | [COSMO.jl](https://github.com/oxfordcontrol/COSMO.jl)                            | Apache  | LP, QP, SOCP, SDP                  |
| [CPLEX](http://www-01.ibm.com/software/commerce/optimization/cplex-optimizer/) | [CPLEX.jl](https://github.com/JuliaOpt/CPLEX.jl)                                 | Comm.   | LP, MILP, SOCP, MISOCP             |
| [CSDP](https://projects.coin-or.org/Csdp/)                                     | [CSDP.jl](https://github.com/JuliaOpt/CSDP.jl)                                   | EPL     | LP, SDP                            |
| [ECOS](https://github.com/ifa-ethz/ecos)                                       | [ECOS.jl](https://github.com/JuliaOpt/ECOS.jl)                                   | GPL     | LP, SOCP                           |
| [FICO Xpress](http://www.fico.com/en/products/fico-xpress-optimization-suite)  | [Xpress.jl](https://github.com/JuliaOpt/Xpress.jl)                               | Comm.   | LP, MILP, SOCP, MISOCP             |
| [GLPK](http://www.gnu.org/software/glpk/)                                      | [GLPK.jl](https://github.com/JuliaOpt/GLPK.jl)                                   | GPL     | LP, MILP                           |
| [Gurobi](http://gurobi.com)                                                    | [Gurobi.jl](https://github.com/JuliaOpt/Gurobi.jl)                               | Comm.   | LP, MILP, SOCP, MISOCP             |
| [Ipopt](https://projects.coin-or.org/Ipopt)                                    | [Ipopt.jl](https://github.com/JuliaOpt/Ipopt.jl)                                 | EPL     | LP, QP, NLP                        |
| [Juniper](https://github.com/lanl-ansi/Juniper.jl)                             | [Juniper.jl](https://github.com/lanl-ansi/Juniper.jl)                            | MIT     | MISOCP, MINLP                      |
| [MOSEK](http://www.mosek.com/)                                                 | [MosekTools.jl](https://github.com/JuliaOpt/MosekTools.jl)                       | Comm.   | LP, MILP, SOCP, MISOCP, SDP        |
| [OSQP](https://osqp.org/)                                                      | [OSQP.jl](https://github.com/oxfordcontrol/OSQP.jl)                              | Apache  | LP, QP                             |
| [ProxSDP](https://github.com/mariohsouto/ProxSDP.jl)                           | [ProxSDP.jl](https://github.com/mariohsouto/ProxSDP.jl)                          | MIT     | LP, SOCP, SDP                      |
| [SCIP](https://scip.zib.de/)                                                   | [SCIP.jl](https://github.com/SCIP-Interfaces/SCIP.jl)                            | ZIB     | MILP, MINLP                        |
| [SCS](https://github.com/cvxgrp/scs)                                           | [SCS.jl](https://github.com/JuliaOpt/SCS.jl)                                     | MIT     | LP, SOCP, SDP                      |
| [SDPA](http://sdpa.sourceforge.net/)                                           | [SDPA.jl](https://github.com/JuliaOpt/SDPA.jl), [SDPAFamily.jl](https://github.com/ericphanson/SDPAFamily.jl)                                   | GPL     | LP, SDP                            |
| [SDPT3](https://blog.nus.edu.sg/mattohkc/softwares/sdpt3/)                     | [SDPT3.jl](https://github.com/JuliaOpt/SDPT3.jl)                                 | GPL     | LP, SOCP, SDP                      |
| [SeDuMi](http://sedumi.ie.lehigh.edu/)                                         | [SeDuMi.jl](https://github.com/JuliaOpt/SeDuMi.jl)                               | GPL     | LP, SOCP, SDP                      |
| [Tulip](https://github.com/ds4dm/Tulip.jl)                                     | [Tulip.jl](https://github.com/ds4dm/Tulip.jl)                                    | MPL-2   | LP                                 |

Where:

-   LP = Linear programming
-   QP = Quadratic programming
-   SOCP = Second-order conic programming (including problems with convex quadratic constraints and/or objective)
-   MILP = Mixed-integer linear programming
-   NLP = Nonlinear programming
-   MINLP = Mixed-integer nonlinear programming
-   SDP = Semidefinite programming
-   MISDP = Mixed-integer semidefinite programming
