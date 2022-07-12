---
layout: post
title:  "RelationalAI sponsors constraint programming support in JuMP"
date:   2022-07-12
categories: [announcements]
---

The [JuMP Steering Committee](/pages/governance/#steering-committee) is pleased
to announce that we, through [NumFOCUS](https://numfocus.org), have signed an
agreement with [RelationalAI](https://relational.ai) to improve constraint
programming support in JuMP.

Constraint programming is a goal of the [post-1.0 JuMP roadmap](https://jump.dev/JuMP.jl/stable/developers/roadmap/),
and we [gave an update on our progress last year](/blog/constraint-programming-update/).

The three main goals of this new work are to officially integrate constraint
programming sets into MathOptInterface, to provide maintained support for
constraint programming solvers, and to write bridges from constraint programming
sets into mixed-integer linear programming formulations.

We're tracking the status of these goals in [MathOptInterface.jl issue #1805](https://github.com/jump-dev/MathOptInterface.jl/issues/1805).

The first person being funded is [Dr. Oscar Dowson](https://github.com/odow), a
core contributor to JuMP, and also a member of the Steering Committee.

### Work to-date

We have already made significant progress, adding the following ten new sets to
MathOptInterface:

 * [MOI.AllDifferent](https://jump.dev/MathOptInterface.jl/stable/reference/standard_form/#MathOptInterface.AllDifferent)
 * [MOI.BinPacking](https://jump.dev/MathOptInterface.jl/stable/reference/standard_form/#MathOptInterface.BinPacking)
 * [MOI.Circuit](https://jump.dev/MathOptInterface.jl/stable/reference/standard_form/#MathOptInterface.Circuit)
 * [MOI.CountAtLeast](https://jump.dev/MathOptInterface.jl/stable/reference/standard_form/#MathOptInterface.CountAtLeast)
 * [MOI.CountBelongs](https://jump.dev/MathOptInterface.jl/stable/reference/standard_form/#MathOptInterface.CountBelongs)
 * [MOI.CountDistinct](https://jump.dev/MathOptInterface.jl/stable/reference/standard_form/#MathOptInterface.CountDistinct)
 * [MOI.CountGreaterThan](https://jump.dev/MathOptInterface.jl/stable/reference/standard_form/#MathOptInterface.CountGreaterThan)
 * [MOI.Cumulative](https://jump.dev/MathOptInterface.jl/stable/reference/standard_form/#MathOptInterface.Cumulative)
 * [MOI.Path](https://jump.dev/MathOptInterface.jl/stable/reference/standard_form/#MathOptInterface.Path)
 * [MOI.Table](https://jump.dev/MathOptInterface.jl/stable/reference/standard_form/#MathOptInterface.Table)

along with bridges from the sets to mixed-integer linear programming
formulations.

### Example

This work was released in MathOptInterface v1.6.0, so they're ready to use now
in JuMP and MathOptInterface. Here's an example using the `AllDifferent` set to
solve a Sudoku puzzle with HiGHS:

```julia
using JuMP, HiGHS

function solve_sudoku(grid, optimizer)
    model = Model(optimizer)
    @variable(model, 1 <= x[1:9, 1:9] <= 9, Int)
    @constraint(model, [i = 1:9], x[i, :] in MOI.AllDifferent(9))
    @constraint(model, [j = 1:9], x[:, j] in MOI.AllDifferent(9))
    for i in (0, 3, 6), j in (0, 3, 6)
        @constraint(model, vec(x[i.+(1:3), j.+(1:3)]) in MOI.AllDifferent(9))
    end
    for i in 1:9, j in 1:9
        if grid[i, j] != 0
            fix(x[i, j], grid[i, j]; force = true)
        end
    end
    optimize!(model)
    return round.(Int, value.(x))
end

grid = [
    5 3 0 0 7 0 0 0 0
    6 0 0 1 9 5 0 0 0
    0 9 8 0 0 0 0 6 0
    8 0 0 0 6 0 0 0 3
    4 0 0 8 0 3 0 0 1
    7 0 0 0 2 0 0 0 6
    0 6 0 0 0 0 2 8 0
    0 0 0 4 1 9 0 0 5
    0 0 0 0 8 0 0 7 9
]

julia> solve_sudoku(
           grid,
           optimizer_with_attributes(HiGHS.Optimizer, "presolve" => "off"),
       )
9×9 Matrix{Int64}:
 5  3  4  6  7  8  9  1  2
 6  7  2  1  9  5  3  4  8
 1  9  8  3  4  2  5  6  7
 8  5  9  7  6  1  4  2  3
 4  2  6  8  5  3  7  9  1
 7  1  3  9  2  4  8  5  6
 9  6  1  5  3  7  2  8  4
 2  8  7  4  1  9  6  3  5
 3  4  5  2  8  6  1  7  9
```

### MiniZinc.jl

We've also written and released the [MiniZinc.jl](https://github.com/jump-dev/MiniZinc.jl)
package, which is an interface from JuMP to the [MiniZinc modeling language](https://www.minizinc.org).

MiniZinc supports a range of constraint programming solvers, and so you can
solve the same Sudoku problem using the [Chuffed](https://github.com/chuffed/chuffed)
constraint programming solver as follows:

```julia
using MiniZinc

julia> solve_sudoku(grid, () -> MiniZinc.Optimizer{Float64}(MiniZinc.Chuffed()))
9×9 Matrix{Int64}:
 5  3  4  6  7  8  9  1  2
 6  7  2  1  9  5  3  4  8
 1  9  8  3  4  2  5  6  7
 8  5  9  7  6  1  4  2  3
 4  2  6  8  5  3  7  9  1
 7  1  3  9  2  4  8  5  6
 9  6  1  5  3  7  2  8  4
 2  8  7  4  1  9  6  3  5
 3  4  5  2  8  6  1  7  9
```

### Next-steps

We still have a bit more work to go. We want to add support for reified
constraints, improve the tutorials and documentation, and investigate ways that
we can connect JuMP and MathOptInterface to boolean satisfiability solvers.

_Miles Lubin, Juan Pablo Vielma, Carleton Coffrin and Changhyun Kwon._

(Per our [conflict of interest policy](/pages/governance/#conflict-of-interest),
Oscar, who is funded by the grant, recused himself from Steering Committee votes
on this agreement.)
