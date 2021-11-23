```@meta
EditURL = "<unknown>/docs/src/tutorials/linear/multiple_feasible_solutions.jl"
```

# Finding multiple feasible solutions

**Author**: James Foster (@jd-foster)

This brief tutorial demonstrates how to formulate and solve a combinatorial problem
with multiple solutions. In fact, we will see how to find _all_ feasible solutions to our problem.
We will also see how to enforce an "all-different" constraint on a set of integer variables.

We start with some objects from recreational mathematics that could be called **"symmetric square sums"**.
Here are a few examples (inspired by [Number Squares](https://www.futilitycloset.com/2012/12/05/number-squares/)):

````@example multiple_feasible_solutions
"""
    1529      2318      5219
    5837      3790      2384
    2340      1956      1867
  + ____    + ____    + ____
    9706      8064      9470
"""
````

Notice how all the digits 0 to 9 are used at least once,
the first three rows sum to the last row,
and the columns in each are the same as the corresponding rows (forming a symmetric matrix).

We might ask: how many such squares are there?
In this tutorial, we will find out the answer
and see how to go about answering this and similar questions.

This tutorial uses the following packages:

````@example multiple_feasible_solutions
using JuMP
import Gurobi
````

Here we are using [Gurobi](https://github.com/jump-dev/Gurobi.jl)
since it provides the required functionality
for this example (i.e. finding multiple feasible solutions).
Gurobi is a commercial solver, that is, a paid license is needed
for those using the solver for commercial purposes. However there are
trial and/or free licenses available for academic and student users.

## Model Specifics

````@example multiple_feasible_solutions
solver = Gurobi.Optimizer
model = JuMP.Model(solver)
````

We need to set specific Gurobi parameters to enable the
[multiple solution functionality](https://www.gurobi.com/documentation/9.0/refman/finding_multiple_solutions.html).

The first setting turns on the exhaustive search mode for multiple solutions:

````@example multiple_feasible_solutions
JuMP.set_optimizer_attribute(model, "PoolSearchMode", 2)
````

The second sets a limit for the number of solutions found.
Here the value 100 is an arbitrary but large enough whole number
for our particular model (but will depend on the application in general).

````@example multiple_feasible_solutions
JuMP.set_optimizer_attribute(model, "PoolSolutions", 100)
````

## Setting up the model:

We are going to use 4-digit numbers:

````@example multiple_feasible_solutions
number_of_digits = 4
````

Let's define the index sets for our variables and constraints.
We keep track of each "place" (units, tens, one-hundreds, one-thousands):

````@example multiple_feasible_solutions
PLACES = 0:(number_of_digits-1)
````

The number of rows of the symmetric square sums are the same as the number of digits:

````@example multiple_feasible_solutions
ROWS = 1:number_of_digits
````

Next, we define the model's core variables.
Here a given digit between 0 and 9 is found in the `i`-th row at the `j`-th place:

````@example multiple_feasible_solutions
@variable(model, 0 <= Digit[i = ROWS, j = PLACES] <= 9, Int)
````

We also need a higher level "term" variable that represents the actual number in each row:

````@example multiple_feasible_solutions
@variable(model, Term[ROWS] >= 1, Int)
````

The lower bound of 1 is because we want to get back non-zero solutions.

Defining the objective function,
since this is a feasibility problem, it can just be set to 0:

````@example multiple_feasible_solutions
@objective(model, Max, 0)
````

Make sure the leading digit of each row is not zero:

````@example multiple_feasible_solutions
@constraint(model, NonZeroLead[i in ROWS], Digit[i, (number_of_digits-1)] >= 1)
````

Define the terms from the digits:

````@example multiple_feasible_solutions
@constraint(
    model,
    TermDef[i in ROWS],
    Term[i] == sum((10^j) * Digit[i, j] for j in PLACES)
)
````

The sum of the first three terms equals the last term:

````@example multiple_feasible_solutions
@constraint(
    model,
    SumHolds,
    Term[number_of_digits] == sum(Term[i] for i in 1:(number_of_digits-1))
)
````

The square is symmetric, that is, the sum should work either row-wise or column-wise:

````@example multiple_feasible_solutions
@constraint(
    model,
    Symmetry[i in ROWS, j in PLACES; i + j <= (number_of_digits - 1)],
    Digit[i, j] == Digit[number_of_digits-j, number_of_digits-i]
)
````

We also want to make sure we use each digit exactly once on the diagonal or upper triangular region.
The following set, along with the collection of binary variables and constraints, ensures this property.

````@example multiple_feasible_solutions
COMPS = [
    (i, j, k, m) for i in ROWS for j in PLACES for k in ROWS for
    m in PLACES if (
        i + j <= number_of_digits &&
        k + m <= number_of_digits &&
        (i, j) < (k, m)
    )
]

@variable(model, BinDiffs[COMPS], Bin)

@constraint(
    model,
    AllDiffLo[(i, j, k, m) in COMPS],
    Digit[i, j] <= Digit[k, m] - 1 + 50 * BinDiffs[(i, j, k, m)]
)

@constraint(
    model,
    AllDiffHi[(i, j, k, m) in COMPS],
    Digit[i, j] >= Digit[k, m] + 1 - 50 * (1 - BinDiffs[(i, j, k, m)])
)
````

Note that the constant 50 is a "big enough" number to make these valid constraints; see
[this paper](https://doi.org/10.1287/ijoc.13.2.96.10515) and
[blog](https://yetanothermathprogrammingconsultant.blogspot.com/2016/05/all-different-and-mixed-integer.html)
for more information.

We can then call `optimize!` and view the results.

````@example multiple_feasible_solutions
optimize!(model)
````

Let's check it worked:

````@example multiple_feasible_solutions
@assert JuMP.termination_status(model) == MOI.OPTIMAL
@assert JuMP.primal_status(model) == MOI.FEASIBLE_POINT

JuMP.objective_value(model)
JuMP.value.(Digit,) |> show
````

Note the display of `Digit` is reverse of the usual order.

### Viewing the Results

Now that we have results, we can print out the feasible solutions found:

````@example multiple_feasible_solutions
TermSolutions = Dict()
for i in 1:result_count(model)
    TermSolutions[i] = convert.(Int64, round.(value.(Term; result = i).data))
end

an_optimal_solution = display(TermSolutions[1])
optimal_objective = objective_value(model; result = 1)
for i in 1:result_count(model)
    @assert has_values(model; result = i)
    println("Solution $(i): ")
    display(TermSolutions[i])
    print("\n")
end
````

The result is the full list of feasible solutions.
The answer to "how many such squares are there?" turns out to be 20.

## Appendix: Using CPLEX instead...

If you have access to CPLEX instead of Gurobi, a similar workflow can
be used. Here we show how to use the low-level API functions in CPLEX.jl
to acheive the same thing as above.

````@example multiple_feasible_solutions
using JuMP
using CPLEX

model = JuMP.direct_model(CPLEX.Optimizer())
````

The settings here turn on the exhaustive search mode for finding multiple solutions:

````@example multiple_feasible_solutions
JuMP.set_optimizer_attribute(model, "CPX_PARAM_SOLNPOOLAGAP", 0.0)
JuMP.set_optimizer_attribute(model, "CPX_PARAM_SOLNPOOLINTENSITY", 4)
````

The second sets a limit for the number of solutions found.
Here the value 1000 is an arbitrary but large enough whole number
for our particular model (but will depend on the application in general).

````@example multiple_feasible_solutions
JuMP.set_optimizer_attribute(model, "CPX_PARAM_POPULATELIM", 1000)
````

Now create all the model constraints as above, and optimize!

We now access the MOI backend to interface with the CPLEX API.

````@example multiple_feasible_solutions
backend_model = backend(model)
env = backend_model.env
lp = backend_model.lp
````

Multiple solutions are generated by CPLEX using the `populate` routine
and added to the "solution pool":

````@example multiple_feasible_solutions
CPLEX.CPXpopulate(env, lp)
````

The number of results should equal the above (i.e. 20):

````@example multiple_feasible_solutions
N_results = CPLEX.CPXgetsolnpoolnumsolns(env, lp)
````

We can obtain the actual values of the feasible solutions as follows:

````@example multiple_feasible_solutions
TermSolutions2 = Dict()
for sn in 0:N_results-1
    TermSolutions2[sn] = Int[]
    for i in 1:length(Term)
        col = Cint(CPLEX.column(backend_model, Term[i].index) - 1)
        begin_col = col
        end_col = col

        x = Ref{Cdouble}()  ## Reference to the `Term` variable value
        CPLEX.CPXgetsolnpoolx(env, lp, sn, x, begin_col, end_col)

        push!(TermSolutions2[sn], convert.(Int64, round.(x[])))
    end
end
````

Finally, if you have run with both CPLEX and Gurobi,
we can check the same solutions were found:

````@example multiple_feasible_solutions
@assert Set(values(TermSolutions2)) == Set(values(TermSolutions))
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

