---
layout: post
title: "Finding multiple feasible solutions"
date: 2021-11-02
categories: [tutorials]
author: "James Foster (@jd-foster)"
---

This tutorial demonstrates how to formulate and solve a combinatorial problem
with multiple feasible solutions. In fact, we will see how to find _all_
feasible solutions to our problem. We will also see how to enforce an
"all-different" constraint on a set of integer variables.

This post is in the same form as tutorials in the JuMP
[documentation](https://jump.dev/JuMP.jl/stable/tutorials/Getting%20started/getting_started_with_JuMP/)
but is hosted here since we depend on using some commercial solvers (Gurobi
and CPLEX) that are not currently accommodated by the JuMP GitHub repository.

## Symmetric number squares

Symmetric [number squares](https://www.futilitycloset.com/2012/12/05/number-squares/)
and their sums often arise in recreational mathematics. Here are a few examples:
```
   1 5 2 9       2 3 1 8        5 2 1 9
   5 8 3 7       3 7 9 0        2 3 8 4
+  2 3 4 0     + 1 9 5 6      + 1 8 6 7
=  9 7 0 6     = 8 0 6 4      = 9 4 7 0
```

Notice how all the digits 0 to 9 are used at least once,
the first three rows sum to the last row,
and the columns in each are the same as the corresponding rows (forming a symmetric matrix).

We will answer the question: how many such squares are there?

### Model Specifics

We start by creating a JuMP model:

````julia
using JuMP
model = Model();
````

### Setting up the model

We are going to use 4-digit numbers:

````julia
number_of_digits = 4
````

````
4
````

Let's define the index sets for our variables and constraints.
We keep track of each "place" (units, tens, one-hundreds, one-thousands):

````julia
PLACES = 0:(number_of_digits-1)
````

````
0:3
````

The number of rows of the symmetric square sums are the same as the number of
digits:

````julia
ROWS = 1:number_of_digits
````

````
1:4
````

Next, we define the model's core variables.
Here a given digit between 0 and 9 is found in the `i`-th row at the `j`-th
place:

````julia
@variable(model, 0 <= Digit[i = ROWS, j = PLACES] <= 9, Int)
````

````
2-dimensional DenseAxisArray{VariableRef,2,...} with index sets:
    Dimension 1, 1:4
    Dimension 2, 0:3
And data, a 4×4 Matrix{VariableRef}:
 Digit[1,0]  Digit[1,1]  Digit[1,2]  Digit[1,3]
 Digit[2,0]  Digit[2,1]  Digit[2,2]  Digit[2,3]
 Digit[3,0]  Digit[3,1]  Digit[3,2]  Digit[3,3]
 Digit[4,0]  Digit[4,1]  Digit[4,2]  Digit[4,3]
````

We also need a higher level "term" variable that represents the actual number
in each row:

````julia
@variable(model, Term[ROWS] >= 1, Int)
````

````
1-dimensional DenseAxisArray{VariableRef,1,...} with index sets:
    Dimension 1, 1:4
And data, a 4-element Vector{VariableRef}:
 Term[1]
 Term[2]
 Term[3]
 Term[4]
````

The lower bound of 1 is because we want to get back non-zero solutions.

Now for the constraints.

Make sure the leading digit of each row is not zero:

````julia
@constraint(model, NonZeroLead[i in ROWS], Digit[i, (number_of_digits-1)] >= 1)
````

````
1-dimensional DenseAxisArray{ConstraintRef{Model, MathOptInterface.ConstraintIndex{MathOptInterface.ScalarAffineFunction{Float64}, MathOptInterface.GreaterThan{Float64}}, ScalarShape},1,...} with index sets:
    Dimension 1, 1:4
And data, a 4-element Vector{ConstraintRef{Model, MathOptInterface.ConstraintIndex{MathOptInterface.ScalarAffineFunction{Float64}, MathOptInterface.GreaterThan{Float64}}, ScalarShape}}:
 NonZeroLead[1] : Digit[1,3] ≥ 1.0
 NonZeroLead[2] : Digit[2,3] ≥ 1.0
 NonZeroLead[3] : Digit[3,3] ≥ 1.0
 NonZeroLead[4] : Digit[4,3] ≥ 1.0
````

Define the terms from the digits:

````julia
@constraint(
    model,
    TermDef[i in ROWS],
    Term[i] == sum((10^j) * Digit[i, j] for j in PLACES)
)
````

````
1-dimensional DenseAxisArray{ConstraintRef{Model, MathOptInterface.ConstraintIndex{MathOptInterface.ScalarAffineFunction{Float64}, MathOptInterface.EqualTo{Float64}}, ScalarShape},1,...} with index sets:
    Dimension 1, 1:4
And data, a 4-element Vector{ConstraintRef{Model, MathOptInterface.ConstraintIndex{MathOptInterface.ScalarAffineFunction{Float64}, MathOptInterface.EqualTo{Float64}}, ScalarShape}}:
 TermDef[1] : -Digit[1,0] - 10 Digit[1,1] - 100 Digit[1,2] - 1000 Digit[1,3] + Term[1] = 0.0
 TermDef[2] : -Digit[2,0] - 10 Digit[2,1] - 100 Digit[2,2] - 1000 Digit[2,3] + Term[2] = 0.0
 TermDef[3] : -Digit[3,0] - 10 Digit[3,1] - 100 Digit[3,2] - 1000 Digit[3,3] + Term[3] = 0.0
 TermDef[4] : -Digit[4,0] - 10 Digit[4,1] - 100 Digit[4,2] - 1000 Digit[4,3] + Term[4] = 0.0
````

The sum of the first three terms equals the last term:

````julia
@constraint(
    model,
    SumHolds,
    Term[number_of_digits] == sum(Term[i] for i in 1:(number_of_digits-1))
)
````

````
SumHolds : -Term[1] - Term[2] - Term[3] + Term[4] = 0.0
````

The square is symmetric, that is, the sum should work either row-wise or
column-wise:

````julia
@constraint(
    model,
    Symmetry[i in ROWS, j in PLACES; i + j <= (number_of_digits - 1)],
    Digit[i, j] == Digit[number_of_digits-j, number_of_digits-i]
)
````

````
JuMP.Containers.SparseAxisArray{ConstraintRef{Model, MathOptInterface.ConstraintIndex{MathOptInterface.ScalarAffineFunction{Float64}, MathOptInterface.EqualTo{Float64}}, ScalarShape}, 2, Tuple{Int64, Int64}} with 6 entries:
  [1, 0]  =  Symmetry[1,0] : Digit[1,0] - Digit[4,3] = 0.0
  [1, 1]  =  Symmetry[1,1] : Digit[1,1] - Digit[3,3] = 0.0
  [1, 2]  =  Symmetry[1,2] : Digit[1,2] - Digit[2,3] = 0.0
  [2, 0]  =  Symmetry[2,0] : Digit[2,0] - Digit[4,2] = 0.0
  [2, 1]  =  Symmetry[2,1] : Digit[2,1] - Digit[3,2] = 0.0
  [3, 0]  =  Symmetry[3,0] : Digit[3,0] - Digit[4,1] = 0.0
````

We also want to make sure we use each digit exactly once on the diagonal or
upper triangular region. The following set, along with the collection of
binary variables and constraints, ensures this property by keeping track of
the right comparisons to make.

````julia
COMPS = [
    (i, j, k, m) for i in ROWS for j in PLACES for k in ROWS for m in PLACES
    if (
        i + j <= number_of_digits &&
        k + m <= number_of_digits &&
        (i, j) < (k, m)
    )
];

@variable(model, BinDiffs[COMPS], Bin);

@constraint(
    model,
    AllDiffLo[(i, j, k, m) in COMPS],
    Digit[i, j] <= Digit[k, m] - 1 + 42 * BinDiffs[(i, j, k, m)]
);

@constraint(
    model,
    AllDiffHi[(i, j, k, m) in COMPS],
    Digit[i, j] >= Digit[k, m] + 1 - 42 * (1 - BinDiffs[(i, j, k, m)])
);
````

Note that the constant 42 is a "big enough" number to make these valid
constraints; see [this paper](https://doi.org/10.1287/ijoc.13.2.96.10515) and
[blog](https://yetanothermathprogrammingconsultant.blogspot.com/2016/05/all-different-and-mixed-integer.html)
for more information.

We are using [Gurobi](https://github.com/jump-dev/Gurobi.jl) as the solver
because it provides the required functionality for this example
(i.e. finding multiple feasible solutions).
There is also an appendix covering [CPLEX](https://github.com/jump-dev/CPLEX.jl).

Gurobi and CPLEX are commercial solvers, that is, a paid license is needed
for those using the solvers for commercial purposes. However there are
trial and/or free licenses available for academic and student users.

````julia
import Gurobi
set_optimizer(model,Gurobi.Optimizer)
````

We then need to set specific Gurobi parameters to enable the
[multiple solution functionality](https://www.gurobi.com/documentation/9.0/refman/finding_multiple_solutions.html).

The first setting turns on the exhaustive search mode for multiple solutions:

````julia
set_optimizer_attribute(model, "PoolSearchMode", 2)
````

````
2
````

The second sets a limit for the number of solutions found:

````julia
set_optimizer_attribute(model, "PoolSolutions", 100)
````

````
100
````

Here the value 100 is an "arbitrary but large enough" whole number
for our particular model (and in general will depend on the application).

We can then call `optimize!` and view the results.

````julia
optimize!(model)
solution_summary(model)
````

````
* Solver : Gurobi

* Status
  Termination status : OPTIMAL
  Primal status      : FEASIBLE_POINT
  Dual status        : NO_SOLUTION
  Message from the solver:
  "Model was solved to optimality (subject to tolerances), and an optimal solution is available."

* Candidate solution
  Objective value      : 0.0
  Objective bound      : 0.0
  Dual objective value : 0.0

* Work counters
  Solve time (sec)   : 0.24169
  Simplex iterations : 0
  Barrier iterations : 56476
  Node count         : 7551

````

Let's check it worked:

````julia
@assert termination_status(model) == MOI.OPTIMAL
@assert primal_status(model) == MOI.FEASIBLE_POINT

value.(Digit)
````

````
2-dimensional DenseAxisArray{Float64,2,...} with index sets:
    Dimension 1, 1:4
    Dimension 2, 0:3
And data, a 4×4 Matrix{Float64}:
 9.0   3.0  1.0  5.0
 6.0  -0.0  4.0  1.0
 2.0   8.0  0.0  3.0
 7.0   2.0  6.0  9.0
````

Note the display of `Digit` is reverse of the usual order.

### Viewing the Results

Now that we have results, we can access the feasible solutions
by using the `value` function with the `result` keyword:

````julia
TermSolutions = Dict()
for i in 1:result_count(model)
    TermSolutions[i] = convert.(Int64, round.(value.(Term; result = i).data))
end
````

Here we have converted the solution to an integer after rounding off very
small numerical tolerances.

An example of one feasible solution is:

````julia
a_feasible_solution = TermSolutions[1]
````

````
4-element Vector{Int64}:
 5139
 1406
 3082
 9627
````

and we can nicely print out all the feasible solutions with

````julia
function print_solution(x::Int)
    for i in (1000, 100, 10, 1)
        y = div(x, i)
        print(y, " ")
        x -= i * y
    end
    println()
    return
end

function print_solution(x::Vector)
    print("  ")
    print_solution(x[1])
    print("  ")
    print_solution(x[2])
    print("+ ")
    print_solution(x[3])
    print("= ")
    print_solution(x[4])
end

for i in 1:result_count(model)
    @assert has_values(model; result = i)
    println("Solution $(i): ")
    print_solution(TermSolutions[i])
    print("\n")
end
````

````
Solution 1:
  5 1 3 9
  1 4 0 6
+ 3 0 8 2
= 9 6 2 7

Solution 2:
  5 1 3 9
  1 0 4 6
+ 3 4 8 7
= 9 6 7 2

Solution 3:
  2 1 4 8
  1 9 6 7
+ 4 6 3 5
= 8 7 5 0

Solution 4:
  3 2 1 6
  2 0 4 7
+ 1 4 9 5
= 6 7 5 8

Solution 5:
  1 2 3 7
  2 9 6 8
+ 3 6 4 5
= 7 8 5 0

Solution 6:
  5 2 1 9
  2 7 4 3
+ 1 4 0 6
= 9 3 6 8

Solution 7:
  1 5 2 9
  5 7 4 6
+ 2 4 0 8
= 9 6 8 3

Solution 8:
  5 2 1 9
  2 6 8 7
+ 1 8 3 4
= 9 7 4 0

Solution 9:
  2 3 1 8
  3 7 9 0
+ 1 9 5 6
= 8 0 6 4

Solution 10:
  1 2 3 7
  2 5 6 4
+ 3 6 8 9
= 7 4 9 0

Solution 11:
  2 3 1 7
  3 5 6 4
+ 1 6 0 8
= 7 4 8 9

Solution 12:
  1 3 2 7
  3 6 5 4
+ 2 5 0 8
= 7 4 8 9

Solution 13:
  3 2 1 7
  2 9 4 5
+ 1 4 0 6
= 7 5 6 8

Solution 14:
  5 2 1 9
  2 3 8 4
+ 1 8 6 7
= 9 4 7 0

Solution 15:
  1 5 2 9
  5 8 3 7
+ 2 3 4 0
= 9 7 0 6

Solution 16:
  1 2 5 9
  2 4 3 0
+ 5 3 8 7
= 9 0 7 6

Solution 17:
  1 4 2 8
  4 7 5 6
+ 2 5 0 9
= 8 6 9 3

Solution 18:
  1 2 5 9
  2 6 4 3
+ 5 4 7 8
= 9 3 8 0

Solution 19:
  2 1 4 8
  1 5 6 3
+ 4 6 7 9
= 8 3 9 0

Solution 20:
  2 1 6 9
  1 3 0 5
+ 6 0 7 4
= 9 5 4 8


````

The result is the full list of feasible solutions.
So the answer to "how many such squares are there?" turns out to be 20.

## Appendix: Using CPLEX instead...

If you have access to CPLEX instead of Gurobi, a similar workflow can
be used. Here we show how to use the low-level API functions in
[CPLEX.jl](https://github.com/jump-dev/CPLEX.jl)
to achieve the same thing as above.

````julia
##%%
import CPLEX
set_optimizer(model,CPLEX.Optimizer);
optimize!(model)
solution_summary(model)
````

````
* Solver : CPLEX

* Status
  Termination status : OPTIMAL
  Primal status      : FEASIBLE_POINT
  Dual status        : NO_SOLUTION
  Message from the solver:
  "integer optimal solution"

* Candidate solution
  Objective value      : 0.0
  Objective bound      : 0.0
  Dual objective value : 0.0

* Work counters
  Solve time (sec)   : 0.03631
  Simplex iterations : 0
  Barrier iterations : 0
  Node count         : 1244

````

The settings here turn on the exhaustive search mode for finding multiple
solutions:

````julia
set_optimizer_attribute(model, "CPX_PARAM_SOLNPOOLAGAP", 0.0)
set_optimizer_attribute(model, "CPX_PARAM_SOLNPOOLINTENSITY", 4)
set_optimizer_attribute(model, "CPX_PARAM_POPULATELIM", 100)
````

````
100
````

The third sets a limit for the number of solutions found;
again, the value 100 is an arbitrary but large enough whole number
for our particular model.

We now access the MOI backend to interface directly with the CPLEX API.

````julia
backend_model = unsafe_backend(model);
env = backend_model.env;
lp = backend_model.lp;
````

Multiple solutions are generated by CPLEX using the `populate` routine
and added to the "solution pool":

````julia
CPLEX.CPXpopulate(env, lp);
````

````

Implied bound cuts applied:  29
Mixed integer rounding cuts applied:  4
Zero-half cuts applied:  3
Gomory fractional cuts applied:  2

Root node processing (before b&c):
  Real time             =    0.02 sec. (6.34 ticks)
Parallel b&c, 12 threads:
  Real time             =    0.02 sec. (7.97 ticks)
  Sync time (average)   =    0.00 sec.
  Wait time (average)   =    0.00 sec.
                          ------------
Total (root+branch&cut) =    0.04 sec. (14.31 ticks)
CPLEX Error  1217: No solution exists.
CPLEX Error  1217: No solution exists.
Version identifier: 12.10.0.0 | 2019-11-26 | 843d4de
CPXPARAM_MIP_Pool_Intensity                      4
CPXPARAM_MIP_Limits_Populate                     100
CPXPARAM_MIP_Pool_AbsGap                         0

Populate: phase I
2 of 2 MIP starts provided solutions.
MIP start 'm1' defined initial solution with objective 0.0000.
Tried aggregator 2 times.
MIP Presolve eliminated 4 rows and 0 columns.
MIP Presolve modified 170 coefficients.
Aggregator did 10 substitutions.
Reduced MIP has 91 rows, 55 columns, and 280 nonzeros.
Reduced MIP has 45 binaries, 10 generals, 0 SOSs, and 0 indicators.
Presolve time = 0.00 sec. (0.24 ticks)
Probing fixed 3 vars, tightened 4 bounds.
Probing time = 0.00 sec. (0.08 ticks)
Tried aggregator 1 time.
MIP Presolve eliminated 3 rows and 3 columns.
MIP Presolve modified 39 coefficients.
Reduced MIP has 88 rows, 52 columns, and 268 nonzeros.
Reduced MIP has 42 binaries, 10 generals, 0 SOSs, and 0 indicators.
Presolve time = 0.00 sec. (0.11 ticks)

Root node processing (before b&c):
  Real time             =    0.00 sec. (0.52 ticks)
Parallel b&c, 12 threads:
  Real time             =    0.00 sec. (0.00 ticks)
  Sync time (average)   =    0.00 sec.
  Wait time (average)   =    0.00 sec.
                          ------------
Total (root+branch&cut) =    0.00 sec. (0.52 ticks)

Populate: phase II
Probing time = 0.00 sec. (0.06 ticks)
Clique table members: 2.
MIP emphasis: balance optimality and feasibility.
MIP search method: dynamic search.
Parallel mode: deterministic, using up to 12 threads.
Root relaxation solution time = 0.00 sec. (0.17 ticks)

        Nodes                                         Cuts/
   Node  Left     Objective  IInf  Best Integer    Best Bound    ItCnt     Gap

*     0+    0                            0.0000        0.0000             0.00%
      0     0        0.0000    19        0.0000        0.0000       43    0.00%
      0     0        0.0000    19        0.0000       Cuts: 3       65    0.00%
      0     0        0.0000    19        0.0000      Cuts: 18       83    0.00%
      0     0        0.0000    19        0.0000       Cuts: 6       86    0.00%
      0     0        0.0000    19        0.0000       Cuts: 3       92    0.00%
      0     0        0.0000    19        0.0000   ZeroHalf: 3       96    0.00%
      0     2        0.0000     7        0.0000        0.0000       96    0.00%
Elapsed time = 0.01 sec. (4.36 ticks, tree = 0.02 MB, solutions = 2)

````

The number of results should equal the above (i.e. 20):

````julia
N_results = CPLEX.CPXgetsolnpoolnumsolns(env, lp)
````

````
20
````

We can obtain the actual values of the feasible solutions as follows:

````julia
TermSolutions2 = Dict()
for sn in 0:N_results-1
    TermSolutions2[sn] = Int[]
    for i in 1:length(Term)
        col = Cint(CPLEX.column(backend_model, Term[i].index) - 1)
        x = Ref{Cdouble}()  ## Reference to the `Term` variable value
        CPLEX.CPXgetsolnpoolx(env, lp, sn, x, col, col)
        push!(TermSolutions2[sn], convert.(Int64, round.(x[])))
    end
end
````

Finally, if you have run with both CPLEX and Gurobi,
we can check the same solutions were found:

````julia
@show sort(collect(values(TermSolutions2)))
````

````
20-element Vector{Any}:
 [1237, 2564, 3689, 7490]
 [1237, 2968, 3645, 7850]
 [1259, 2430, 5387, 9076]
 [1259, 2643, 5478, 9380]
 [1327, 3654, 2508, 7489]
 [1428, 4756, 2509, 8693]
 [1529, 5746, 2408, 9683]
 [1529, 5837, 2340, 9706]
 [2148, 1563, 4679, 8390]
 [2148, 1967, 4635, 8750]
 [2169, 1305, 6074, 9548]
 [2317, 3564, 1608, 7489]
 [2318, 3790, 1956, 8064]
 [3216, 2047, 1495, 6758]
 [3217, 2945, 1406, 7568]
 [5139, 1046, 3487, 9672]
 [5139, 1406, 3082, 9627]
 [5219, 2384, 1867, 9470]
 [5219, 2687, 1834, 9740]
 [5219, 2743, 1406, 9368]
````

````julia
@show sort(collect(values(TermSolutions)))
````

````
20-element Vector{Any}:
 [1237, 2564, 3689, 7490]
 [1237, 2968, 3645, 7850]
 [1259, 2430, 5387, 9076]
 [1259, 2643, 5478, 9380]
 [1327, 3654, 2508, 7489]
 [1428, 4756, 2509, 8693]
 [1529, 5746, 2408, 9683]
 [1529, 5837, 2340, 9706]
 [2148, 1563, 4679, 8390]
 [2148, 1967, 4635, 8750]
 [2169, 1305, 6074, 9548]
 [2317, 3564, 1608, 7489]
 [2318, 3790, 1956, 8064]
 [3216, 2047, 1495, 6758]
 [3217, 2945, 1406, 7568]
 [5139, 1046, 3487, 9672]
 [5139, 1406, 3082, 9627]
 [5219, 2384, 1867, 9470]
 [5219, 2687, 1834, 9740]
 [5219, 2743, 1406, 9368]
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

