---
layout: post
title: "Finding multiple feasible solutions"
date: 2021-11-02
categories: [tutorials]
permalink: /blog/finding-multiple-feasible-solutions/
---

_Author: James Foster (@jd-foster)_

This tutorial demonstrates how to formulate and solve a combinatorial problem
with multiple feasible solutions. In fact, we will see how to find _all_ feasible solutions to our problem.
We will also see how to enforce an "all-different" constraint on a set of integer variables.

This post is in the same form as tutorials in the JuMP
[documentation](https://jump.dev/JuMP.jl/stable/tutorials/Getting%20started/getting_started_with_JuMP/)
but is hosted here since we depend on using some commercial solvers (Gurobi and/or CPLEX) that are not
currently accomodated by the JuMP GitHub repository.

Symmetric [number squares](https://www.futilitycloset.com/2012/12/05/number-squares/)
and their sums often arise in recreational mathematics. Here are a few examples:

````julia
         1 5 2 9       2 3 1 8        5 2 1 9
         5 8 3 7       3 7 9 0        2 3 8 4
      +  2 3 4 0     + 1 9 5 6      + 1 8 6 7
      =  9 7 0 6     = 8 0 6 4      = 9 4 7 0
````

Notice how all the digits 0 to 9 are used at least once,
the first three rows sum to the last row,
and the columns in each are the same as the corresponding rows (forming a symmetric matrix).

We will answer the question: how many such squares are there?

This tutorial uses the following packages:

````julia
using JuMP
import Gurobi
````

Here we are using [Gurobi](https://github.com/jump-dev/Gurobi.jl)
since it provides the required functionality
for this example (i.e. finding multiple feasible solutions).
Gurobi is a commercial solver, that is, a paid license is needed
for those using the solver for commercial purposes. However there are
trial and/or free licenses available for academic and student users.
There is also an appendix covering [CPLEX](https://github.com/jump-dev/CPLEX.jl).

### Model Specifics

We start by creating a JuMP model:

````julia
model = JuMP.Model(Gurobi.Optimizer)
````

We then need to set specific Gurobi parameters to enable the
[multiple solution functionality](https://www.gurobi.com/documentation/9.0/refman/finding_multiple_solutions.html).

The first setting turns on the exhaustive search mode for multiple solutions:

````julia
JuMP.set_optimizer_attribute(model, "PoolSearchMode", 2)
````

The second sets a limit for the number of solutions found:

````julia
JuMP.set_optimizer_attribute(model, "PoolSolutions", 100)
````

Here the value 100 is an "arbitrary but large enough" whole number
for our particular model (and in general will depend on the application).

### Setting up the model

We are going to use 4-digit numbers:

````julia
number_of_digits = 4
````

Let's define the index sets for our variables and constraints.
We keep track of each "place" (units, tens, one-hundreds, one-thousands):

````julia
PLACES = 0:(number_of_digits-1)
````

The number of rows of the symmetric square sums are the same as the number of digits:

````julia
ROWS = 1:number_of_digits
````

Next, we define the model's core variables.
Here a given digit between 0 and 9 is found in the `i`-th row at the `j`-th place:

````julia
@variable(model, 0 <= Digit[i = ROWS, j = PLACES] <= 9, Int)
````

We also need a higher level "term" variable that represents the actual number in each row:

````julia
@variable(model, Term[ROWS] >= 1, Int)
````

The lower bound of 1 is because we want to get back non-zero solutions.

We could define an objective function, but since this is a feasibility problem,
it can just be left unset.

Now for the constraints.

Make sure the leading digit of each row is not zero:

````julia
@constraint(model, NonZeroLead[i in ROWS], Digit[i, (number_of_digits-1)] >= 1)
````

Define the terms from the digits:

````julia
@constraint(
    model,
    TermDef[i in ROWS],
    Term[i] == sum((10^j) * Digit[i, j] for j in PLACES)
)
````

The sum of the first three terms equals the last term:

````julia
@constraint(
    model,
    SumHolds,
    Term[number_of_digits] == sum(Term[i] for i in 1:(number_of_digits-1))
)
````

The square is symmetric, that is, the sum should work either row-wise or column-wise:

````julia
@constraint(
    model,
    Symmetry[i in ROWS, j in PLACES; i + j <= (number_of_digits - 1)],
    Digit[i, j] == Digit[number_of_digits-j, number_of_digits-i]
)
````

We also want to make sure we use each digit exactly once on the diagonal or upper triangular region.
The following set, along with the collection of binary variables and constraints, ensures this property
by keeping track of the right comparisons to make.

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

Note that the constant 42 is a "big enough" number to make these valid constraints; see
[this paper](https://doi.org/10.1287/ijoc.13.2.96.10515) and
[blog](https://yetanothermathprogrammingconsultant.blogspot.com/2016/05/all-different-and-mixed-integer.html)
for more information.

We can then call `optimize!` and view the results.

````julia
optimize!(model)
solution_summary(model)
````

Let's check it worked:

````julia
@assert JuMP.termination_status(model) == MOI.OPTIMAL
@assert JuMP.primal_status(model) == MOI.FEASIBLE_POINT

value.(Digit)
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

and we can print out all the feasible solutions with

````julia
for i in 1:result_count(model)
    @assert has_values(model; result = i)
    println("Solution $(i): ")
    display(TermSolutions[i])
    print("\n")
end
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

model = JuMP.direct_model(CPLEX.Optimizer())
````

The settings here turn on the exhaustive search mode for finding multiple solutions:

````julia
JuMP.set_optimizer_attribute(model, "CPX_PARAM_SOLNPOOLAGAP", 0.0)
JuMP.set_optimizer_attribute(model, "CPX_PARAM_SOLNPOOLINTENSITY", 4)
JuMP.set_optimizer_attribute(model, "CPX_PARAM_POPULATELIM", 100)
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

Multiple solutions are generated by CPLEX using the `populate` routine
and added to the "solution pool":

````julia
CPLEX.CPXpopulate(env, lp)
````

The number of results should equal the above (i.e. 20):

````julia
N_results = CPLEX.CPXgetsolnpoolnumsolns(env, lp)
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
@assert Set(values(TermSolutions2)) == Set(values(TermSolutions))
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

