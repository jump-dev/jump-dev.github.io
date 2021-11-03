---
layout: post
title: "Finding multiple feasible solutions"
date: 2021-11-02
categories: [tutorials]
---
_Author: James Foster (@jd-foster)_

This tutorial demonstrates how to formulate and solve a combinatorial problem
with multiple feasible solutions. In fact, we will see how to find _all_
feasible solutions to our problem. We will also see how to enforce an
"all-different" constraint on a set of integer variables.

This post is in the same form as tutorials in the JuMP
[documentation](https://jump.dev/JuMP.jl/stable/tutorials/Getting%20started/getting_started_with_JuMP/)
but is hosted here since we depend on using some commercial solvers (Gurobi
and CPLEX) that are not currently accomodated by the JuMP GitHub repository.

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

This tutorial uses the following packages:

````julia
using JuMP
import Gurobi
````

We are using [Gurobi](https://github.com/jump-dev/Gurobi.jl) because it
provides the required functionality for this example (i.e. finding multiple
feasible solutions).

Gurobi is a commercial solver, that is, a paid license is needed
for those using the solver for commercial purposes. However there are
trial and/or free licenses available for academic and student users.
There is also an appendix covering [CPLEX](https://github.com/jump-dev/CPLEX.jl).

### Model Specifics

We start by creating a JuMP model:

````julia
model = Model(Gurobi.Optimizer)
````

````
A JuMP Model
Feasibility problem with:
Variables: 0
Model mode: AUTOMATIC
CachingOptimizer state: EMPTY_OPTIMIZER
Solver name: Gurobi
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
2-dimensional DenseAxisArray{JuMP.VariableRef,2,...} with index sets:
    Dimension 1, 1:4
    Dimension 2, 0:3
And data, a 4×4 Matrix{JuMP.VariableRef}:
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
1-dimensional DenseAxisArray{JuMP.VariableRef,1,...} with index sets:
    Dimension 1, 1:4
And data, a 4-element Vector{JuMP.VariableRef}:
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
1-dimensional DenseAxisArray{JuMP.ConstraintRef{JuMP.Model, MathOptInterface.ConstraintIndex{MathOptInterface.ScalarAffineFunction{Float64}, MathOptInterface.GreaterThan{Float64}}, JuMP.ScalarShape},1,...} with index sets:
    Dimension 1, 1:4
And data, a 4-element Vector{JuMP.ConstraintRef{JuMP.Model, MathOptInterface.ConstraintIndex{MathOptInterface.ScalarAffineFunction{Float64}, MathOptInterface.GreaterThan{Float64}}, JuMP.ScalarShape}}:
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
1-dimensional DenseAxisArray{JuMP.ConstraintRef{JuMP.Model, MathOptInterface.ConstraintIndex{MathOptInterface.ScalarAffineFunction{Float64}, MathOptInterface.EqualTo{Float64}}, JuMP.ScalarShape},1,...} with index sets:
    Dimension 1, 1:4
And data, a 4-element Vector{JuMP.ConstraintRef{JuMP.Model, MathOptInterface.ConstraintIndex{MathOptInterface.ScalarAffineFunction{Float64}, MathOptInterface.EqualTo{Float64}}, JuMP.ScalarShape}}:
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
JuMP.Containers.SparseAxisArray{JuMP.ConstraintRef{JuMP.Model, MathOptInterface.ConstraintIndex{MathOptInterface.ScalarAffineFunction{Float64}, MathOptInterface.EqualTo{Float64}}, JuMP.ScalarShape}, 2, Tuple{Int64, Int64}} with 6 entries:
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
]

@variable(model, BinDiffs[COMPS], Bin)

@constraint(
    model,
    AllDiffLo[(i, j, k, m) in COMPS],
    Digit[i, j] <= Digit[k, m] - 1 + 42 * BinDiffs[(i, j, k, m)]
)

@constraint(
    model,
    AllDiffHi[(i, j, k, m) in COMPS],
    Digit[i, j] >= Digit[k, m] + 1 - 42 * (1 - BinDiffs[(i, j, k, m)])
)
````

````
1-dimensional DenseAxisArray{JuMP.ConstraintRef{JuMP.Model, MathOptInterface.ConstraintIndex{MathOptInterface.ScalarAffineFunction{Float64}, MathOptInterface.GreaterThan{Float64}}, JuMP.ScalarShape},1,...} with index sets:
    Dimension 1, [(1, 0, 1, 1), (1, 0, 1, 2), (1, 0, 1, 3), (1, 0, 2, 0), (1, 0, 2, 1), (1, 0, 2, 2), (1, 0, 3, 0), (1, 0, 3, 1), (1, 0, 4, 0), (1, 1, 1, 2)  …  (2, 1, 2, 2), (2, 1, 3, 0), (2, 1, 3, 1), (2, 1, 4, 0), (2, 2, 3, 0), (2, 2, 3, 1), (2, 2, 4, 0), (3, 0, 3, 1), (3, 0, 4, 0), (3, 1, 4, 0)]
And data, a 45-element Vector{JuMP.ConstraintRef{JuMP.Model, MathOptInterface.ConstraintIndex{MathOptInterface.ScalarAffineFunction{Float64}, MathOptInterface.GreaterThan{Float64}}, JuMP.ScalarShape}}:
 AllDiffHi[(1, 0, 1, 1)] : Digit[1,0] - Digit[1,1] - 42 BinDiffs[(1, 0, 1, 1)] ≥ -41.0
 AllDiffHi[(1, 0, 1, 2)] : Digit[1,0] - Digit[1,2] - 42 BinDiffs[(1, 0, 1, 2)] ≥ -41.0
 AllDiffHi[(1, 0, 1, 3)] : Digit[1,0] - Digit[1,3] - 42 BinDiffs[(1, 0, 1, 3)] ≥ -41.0
 AllDiffHi[(1, 0, 2, 0)] : Digit[1,0] - Digit[2,0] - 42 BinDiffs[(1, 0, 2, 0)] ≥ -41.0
 AllDiffHi[(1, 0, 2, 1)] : Digit[1,0] - Digit[2,1] - 42 BinDiffs[(1, 0, 2, 1)] ≥ -41.0
 AllDiffHi[(1, 0, 2, 2)] : Digit[1,0] - Digit[2,2] - 42 BinDiffs[(1, 0, 2, 2)] ≥ -41.0
 AllDiffHi[(1, 0, 3, 0)] : Digit[1,0] - Digit[3,0] - 42 BinDiffs[(1, 0, 3, 0)] ≥ -41.0
 AllDiffHi[(1, 0, 3, 1)] : Digit[1,0] - Digit[3,1] - 42 BinDiffs[(1, 0, 3, 1)] ≥ -41.0
 AllDiffHi[(1, 0, 4, 0)] : Digit[1,0] - Digit[4,0] - 42 BinDiffs[(1, 0, 4, 0)] ≥ -41.0
 AllDiffHi[(1, 1, 1, 2)] : Digit[1,1] - Digit[1,2] - 42 BinDiffs[(1, 1, 1, 2)] ≥ -41.0
 AllDiffHi[(1, 1, 1, 3)] : Digit[1,1] - Digit[1,3] - 42 BinDiffs[(1, 1, 1, 3)] ≥ -41.0
 AllDiffHi[(1, 1, 2, 0)] : -Digit[2,0] + Digit[1,1] - 42 BinDiffs[(1, 1, 2, 0)] ≥ -41.0
 AllDiffHi[(1, 1, 2, 1)] : Digit[1,1] - Digit[2,1] - 42 BinDiffs[(1, 1, 2, 1)] ≥ -41.0
 AllDiffHi[(1, 1, 2, 2)] : Digit[1,1] - Digit[2,2] - 42 BinDiffs[(1, 1, 2, 2)] ≥ -41.0
 AllDiffHi[(1, 1, 3, 0)] : -Digit[3,0] + Digit[1,1] - 42 BinDiffs[(1, 1, 3, 0)] ≥ -41.0
 AllDiffHi[(1, 1, 3, 1)] : Digit[1,1] - Digit[3,1] - 42 BinDiffs[(1, 1, 3, 1)] ≥ -41.0
 AllDiffHi[(1, 1, 4, 0)] : -Digit[4,0] + Digit[1,1] - 42 BinDiffs[(1, 1, 4, 0)] ≥ -41.0
 AllDiffHi[(1, 2, 1, 3)] : Digit[1,2] - Digit[1,3] - 42 BinDiffs[(1, 2, 1, 3)] ≥ -41.0
 AllDiffHi[(1, 2, 2, 0)] : -Digit[2,0] + Digit[1,2] - 42 BinDiffs[(1, 2, 2, 0)] ≥ -41.0
 AllDiffHi[(1, 2, 2, 1)] : -Digit[2,1] + Digit[1,2] - 42 BinDiffs[(1, 2, 2, 1)] ≥ -41.0
 AllDiffHi[(1, 2, 2, 2)] : Digit[1,2] - Digit[2,2] - 42 BinDiffs[(1, 2, 2, 2)] ≥ -41.0
 AllDiffHi[(1, 2, 3, 0)] : -Digit[3,0] + Digit[1,2] - 42 BinDiffs[(1, 2, 3, 0)] ≥ -41.0
 AllDiffHi[(1, 2, 3, 1)] : -Digit[3,1] + Digit[1,2] - 42 BinDiffs[(1, 2, 3, 1)] ≥ -41.0
 AllDiffHi[(1, 2, 4, 0)] : -Digit[4,0] + Digit[1,2] - 42 BinDiffs[(1, 2, 4, 0)] ≥ -41.0
 AllDiffHi[(1, 3, 2, 0)] : -Digit[2,0] + Digit[1,3] - 42 BinDiffs[(1, 3, 2, 0)] ≥ -41.0
 AllDiffHi[(1, 3, 2, 1)] : -Digit[2,1] + Digit[1,3] - 42 BinDiffs[(1, 3, 2, 1)] ≥ -41.0
 AllDiffHi[(1, 3, 2, 2)] : -Digit[2,2] + Digit[1,3] - 42 BinDiffs[(1, 3, 2, 2)] ≥ -41.0
 AllDiffHi[(1, 3, 3, 0)] : -Digit[3,0] + Digit[1,3] - 42 BinDiffs[(1, 3, 3, 0)] ≥ -41.0
 AllDiffHi[(1, 3, 3, 1)] : -Digit[3,1] + Digit[1,3] - 42 BinDiffs[(1, 3, 3, 1)] ≥ -41.0
 AllDiffHi[(1, 3, 4, 0)] : -Digit[4,0] + Digit[1,3] - 42 BinDiffs[(1, 3, 4, 0)] ≥ -41.0
 AllDiffHi[(2, 0, 2, 1)] : Digit[2,0] - Digit[2,1] - 42 BinDiffs[(2, 0, 2, 1)] ≥ -41.0
 AllDiffHi[(2, 0, 2, 2)] : Digit[2,0] - Digit[2,2] - 42 BinDiffs[(2, 0, 2, 2)] ≥ -41.0
 AllDiffHi[(2, 0, 3, 0)] : Digit[2,0] - Digit[3,0] - 42 BinDiffs[(2, 0, 3, 0)] ≥ -41.0
 AllDiffHi[(2, 0, 3, 1)] : Digit[2,0] - Digit[3,1] - 42 BinDiffs[(2, 0, 3, 1)] ≥ -41.0
 AllDiffHi[(2, 0, 4, 0)] : Digit[2,0] - Digit[4,0] - 42 BinDiffs[(2, 0, 4, 0)] ≥ -41.0
 AllDiffHi[(2, 1, 2, 2)] : Digit[2,1] - Digit[2,2] - 42 BinDiffs[(2, 1, 2, 2)] ≥ -41.0
 AllDiffHi[(2, 1, 3, 0)] : -Digit[3,0] + Digit[2,1] - 42 BinDiffs[(2, 1, 3, 0)] ≥ -41.0
 AllDiffHi[(2, 1, 3, 1)] : Digit[2,1] - Digit[3,1] - 42 BinDiffs[(2, 1, 3, 1)] ≥ -41.0
 AllDiffHi[(2, 1, 4, 0)] : -Digit[4,0] + Digit[2,1] - 42 BinDiffs[(2, 1, 4, 0)] ≥ -41.0
 AllDiffHi[(2, 2, 3, 0)] : -Digit[3,0] + Digit[2,2] - 42 BinDiffs[(2, 2, 3, 0)] ≥ -41.0
 AllDiffHi[(2, 2, 3, 1)] : -Digit[3,1] + Digit[2,2] - 42 BinDiffs[(2, 2, 3, 1)] ≥ -41.0
 AllDiffHi[(2, 2, 4, 0)] : -Digit[4,0] + Digit[2,2] - 42 BinDiffs[(2, 2, 4, 0)] ≥ -41.0
 AllDiffHi[(3, 0, 3, 1)] : Digit[3,0] - Digit[3,1] - 42 BinDiffs[(3, 0, 3, 1)] ≥ -41.0
 AllDiffHi[(3, 0, 4, 0)] : Digit[3,0] - Digit[4,0] - 42 BinDiffs[(3, 0, 4, 0)] ≥ -41.0
 AllDiffHi[(3, 1, 4, 0)] : -Digit[4,0] + Digit[3,1] - 42 BinDiffs[(3, 1, 4, 0)] ≥ -41.0
````

Note that the constant 42 is a "big enough" number to make these valid
constraints; see [this paper](https://doi.org/10.1287/ijoc.13.2.96.10515) and
[blog](https://yetanothermathprogrammingconsultant.blogspot.com/2016/05/all-different-and-mixed-integer.html)
for more information.

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
  Solve time (sec)   : 0.32207
  Simplex iterations : 0
  Barrier iterations : 47287
  Node count         : 5677

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

and we can print out all the feasible solutions with

````julia
for i in 1:result_count(model)
    @assert has_values(model; result = i)
    println("Solution $(i): ")
    println(TermSolutions[i])
    print("\n")
end
````

````
Solution 1: 
[5139, 1406, 3082, 9627]

Solution 2: 
[3217, 2945, 1406, 7568]

Solution 3: 
[5219, 2687, 1834, 9740]

Solution 4: 
[5219, 2384, 1867, 9470]

Solution 5: 
[1529, 5746, 2408, 9683]

Solution 6: 
[1529, 5837, 2340, 9706]

Solution 7: 
[2169, 1305, 6074, 9548]

Solution 8: 
[1259, 2430, 5387, 9076]

Solution 9: 
[2148, 1967, 4635, 8750]

Solution 10: 
[1237, 2968, 3645, 7850]

Solution 11: 
[1428, 4756, 2509, 8693]

Solution 12: 
[5139, 1046, 3487, 9672]

Solution 13: 
[1259, 2643, 5478, 9380]

Solution 14: 
[2317, 3564, 1608, 7489]

Solution 15: 
[1327, 3654, 2508, 7489]

Solution 16: 
[5219, 2743, 1406, 9368]

Solution 17: 
[2148, 1563, 4679, 8390]

Solution 18: 
[3216, 2047, 1495, 6758]

Solution 19: 
[1237, 2564, 3689, 7490]

Solution 20: 
[2318, 3790, 1956, 8064]


````

The result is the full list of feasible solutions.
So the answer to "how many such squares are there?" turns out to be 20.

## Appendix: Using CPLEX instead...

If you have access to CPLEX instead of Gurobi, a similar workflow can
be used. Here we show how to use the low-level API functions in
[CPLEX.jl](https://github.com/jump-dev/CPLEX.jl)
to achieve the same thing as above.

````julia
using JuMP
import CPLEX

model = direct_model(CPLEX.Optimizer())
````

````
A JuMP Model
Feasibility problem with:
Variables: 0
Model mode: DIRECT
Solver name: CPLEX
````

The settings here turn on the exhaustive search mode for finding multiple
solutions:

````julia
set_optimizer_attribute(model, "CPX_PARAM_SOLNPOOLAGAP", 0.0)
set_optimizer_attribute(model, "CPX_PARAM_SOLNPOOLINTENSITY", 4)
set_optimizer_attribute(model, "CPX_PARAM_POPULATELIM", 100)
````

The third sets a limit for the number of solutions found;
again, the value 100 is an arbitrary but large enough whole number
for our particular model.

Now create all the model constraints as above, and optimize!

We now access the MOI backend to interface directly with the CPLEX API.

````julia
backend_model = backend(model)
env = backend_model.env
lp = backend_model.lp
````

````
Ptr{Nothing} @0x00007fb6bae1bd50
````

Multiple solutions are generated by CPLEX using the `populate` routine
and added to the "solution pool":

````julia
CPLEX.CPXpopulate(env, lp)
````

````
3003
````

The number of results should equal the above (i.e. 20):

````julia
N_results = CPLEX.CPXgetsolnpoolnumsolns(env, lp)
````

````
0
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
Set(values(TermSolutions2))
````

````
Set{Any}()
````

````julia
@show Set(values(TermSolutions))
````

````
Set{Any} with 20 elements:
  [1237, 2968, 3645, 7850]
  [5219, 2743, 1406, 9368]
  [2318, 3790, 1956, 8064]
  [5219, 2384, 1867, 9470]
  [2317, 3564, 1608, 7489]
  [5139, 1046, 3487, 9672]
  [2148, 1563, 4679, 8390]
  [5139, 1406, 3082, 9627]
  [3216, 2047, 1495, 6758]
  [1237, 2564, 3689, 7490]
  [1327, 3654, 2508, 7489]
  [1259, 2430, 5387, 9076]
  [1428, 4756, 2509, 8693]
  [2148, 1967, 4635, 8750]
  [5219, 2687, 1834, 9740]
  [1259, 2643, 5478, 9380]
  [1529, 5746, 2408, 9683]
  [1529, 5837, 2340, 9706]
  [2169, 1305, 6074, 9548]
  [3217, 2945, 1406, 7568]
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

