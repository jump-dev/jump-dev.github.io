# A [recent blog post](https://www.gams.com/blog/2023/07/performance-in-optimization-models-a-comparative-analysis-of-gams-pyomo-gurobipy-and-jump)
# by GAMS demonstrated a significant performance difference between JuMP and
# GAMS on a model they call IJKLM. The purpose of this blog post is to explain
# the difference and present a different formulation with much better
# performance.

# Read the GAMS post for background on the model, as well as its mathematical
# formulation.

# ## The input data

# Input data for the model is provided in three JSON files, labeled IJK, JKL,
# and KLM.

import JSON

const DATA_DIR = joinpath(@__DIR__, "gams");

struct OriginalData
    I::Vector{String}
    IJK::Vector{Vector{Any}}
    JKL::Vector{Vector{Any}}
    KLM::Vector{Vector{Any}}

    function OriginalData(n::Int)
        return new(
            ["i$i" for i in 1:n],
            JSON.parsefile(joinpath(DATA_DIR, "data_IJK_$n.json")),
            JSON.parsefile(joinpath(DATA_DIR, "data_JKL.json")),
            JSON.parsefile(joinpath(DATA_DIR, "data_KLM.json")),
        )
    end
end

# The GAMS blog post generated a range of different sizes, but we'll just use
# the `n = 2200` case for now. You can use the code in GAMS's
# [GitHub repository](https://github.com/justine18/performance_experiment)
# to generate other sizes.

original_data = OriginalData(2_200);

# Each element in the `IJK`, `JKL`, and `KLM` vectors is a vector of `String`
# with three elements, corresponding to the I-J-K, J-K-L, or K-L-M index.

original_data.IJK[1]

# ## The _intuitive_ formulation

# The _intuitive_ formulation used by GAMS in their blog post is:

using JuMP
import Gurobi

function intuitive_formulation(data)
    x_list = [
        (i, j, k, l, m)
        for (i, j, k) in data.IJK
        for (jj, kk, l) in data.JKL if jj == j && kk == k
        for (kkk, ll, m) in data.KLM if kkk == k && ll == l
    ]
    model = Model(Gurobi.Optimizer)
    set_silent(model)
    @variable(model, x[x_list] >= 0)
    @constraint(
        model,
        [i in data.I],
        sum(
            x[(i, j, k, l, m)]
            for (ii, j, k) in data.IJK if ii == i
            for (jj, kk, l) in data.JKL if jj == j && kk == k
            for (kkk, ll, m) in data.KLM if kkk == k && ll == l
        ) >= 0
    )
    optimize!(model)
    return model
end

# On my machine it takes around 4 seconds to run:

@time intuitive_formulation(original_data);
@time intuitive_formulation(original_data);

# ## Tweaking the input data

# A typical reason for poor performance in a Julia code is type instability,
# that is, code in which the Julia compiler cannot prove the type of a variable.
#
# You can check a fuction for type stability using
# `@code_warntype intuitive_formulation(original_data)` and looking for red
# inference failures. In our example, there are a lot of issues, all stemming
# from the use of `Vector{Any}` in our data structure.

# Since we know that each element is actually a list of three `String` elements,
# we can improve things by parsing the data into a tuple instead of a vector:

function parsefile_tuple(filename::String)
    return [tuple(x...) for x in JSON.parsefile(filename)]
end

struct TupleData
    I::Vector{String}
    IJK::Vector{NTuple{3,String}}
    JKL::Vector{NTuple{3,String}}
    KLM::Vector{NTuple{3,String}}

    function TupleData(n::Int)
        return new(
            ["i$i" for i in 1:n],
            parsefile_tuple(joinpath(DATA_DIR, "data_IJK_$n.json")),
            parsefile_tuple(joinpath(DATA_DIR, "data_JKL.json")),
            parsefile_tuple(joinpath(DATA_DIR, "data_KLM.json")),
        )
    end
end

tuple_data = TupleData(2_200);

# Now if we run the intuitive formulation, it takes around 2 seconds:

@time intuitive_formulation(tuple_data);
@time intuitive_formulation(tuple_data);

# ## The _fast_ formulation

# Next, GAMS looked at ways to improve the JuMP code using feedback from
# [our community forum](https://discourse.julialang.org/t/performance-julia-jump-vs-python-pyomo/92044).

# The resulting JuMP code was:

function fast_formulation(data)
    x_list = [
        (i, j, k, l, m)
        for (i, j, k) in data.IJK
        for (jj, kk, l) in data.JKL if jj == j && kk == k
        for (kkk, ll, m) in data.KLM if kkk == k && ll == l
    ]
    model = direct_model(Gurobi.Optimizer())
    set_silent(model)
    set_string_names_on_creation(model, false)
    @variable(model, x[1:length(x_list)] >= 0)
    x_expr = Dict(i => AffExpr(0.0) for i in data.I)
    for (i, index) in enumerate(x_list)
        add_to_expression!(x_expr[index[1]], x[i])
    end
    for expr in values(x_expr)
        @constraint(model, expr in MOI.GreaterThan(0.0))
    end
    optimize!(model)
    return model
end

# There are a few things to notice here:
#
#  * The use of `direct_model` instead of `Model`
#  * The disabling of string names
#  * A way to construct the left-hand side of each constraint in a single pass
#    through the list of `x` variables
#
# These improvements bring the time down to around 1 second.

@time fast_formulation(tuple_data);
@time fast_formulation(tuple_data);

# Why, then, is GAMS so much faster in their benchmark?

# The answer is the nested for-loop used to create the list of indices:

function x_list_only(data)
    return [
        (i, j, k, l, m)
        for (i, j, k) in data.IJK
        for (jj, kk, l) in data.JKL if jj == j && kk == k
        for (kkk, ll, m) in data.KLM if kkk == k && ll == l
    ]
end

@time x_list_only(tuple_data);
@time x_list_only(tuple_data);

# This takes nearly all the total time. With a little effort, we can realize
# that the for loops are equivalent to treating each of the `IJK`, `JKL`, and
# `KLM` lists as a table in a database, and then performing an inner join
# across the similar indices.

# The blog post hints at this, saying "The reason for GAMS superior performance
# in this example is the use of relational algebra." But relational algebra,
# while not built-in to JuMP, is not unique to the GAMS modeling language. In
# Julia, we can use the `DataFrames` library.

# ## The _DataFrames_ formulation

# The first step is to load the data as a dataframe instead of a list of tuples:

import DataFrames

function parsefile_dataframe(filename::String, indices)
    list = parsefile_tuple(filename)
    return DataFrames.DataFrame(
        [index => getindex.(list, i) for (i, index) in enumerate(indices)]...
    )
end

struct DataFrameData
    I::Vector{String}
    IJK::DataFrames.DataFrame
    JKL::DataFrames.DataFrame
    KLM::DataFrames.DataFrame

    function DataFrameData(n::Int)
        return new(
            ["i$i" for i in 1:n],
            parsefile_dataframe(joinpath(DATA_DIR, "data_IJK_$n.json"), (:i, :j, :k,)),
            parsefile_dataframe(joinpath(DATA_DIR, "data_JKL.json"), (:j, :k, :l)),
            parsefile_dataframe(joinpath(DATA_DIR, "data_KLM.json"), (:k, :l, :m)),
        )
    end
end

dataframe_data = DataFrameData(2_200);

# Using the dataframe datastructure, we can compactly write an equivalent JuMP
# formulation:

function dataframe_formulation(data::DataFrameData)
    ijklm = DataFrames.innerjoin(
        DataFrames.innerjoin(data.IJK, data.JKL; on = [:j, :k]),
        data.KLM;
        on = [:k, :l],
    )
    model = Model(Gurobi.Optimizer)
    set_silent(model)
    ijklm[!, :x] = @variable(model, x[1:size(ijklm, 1)] >= 0)
    for df in DataFrames.groupby(ijklm, :i)
        @constraint(model, sum(df.x) >= 0)
    end
    optimize!(model)
    return model
end

# This formulation doesn't look like the nested summation mathematics that GAMS
# originally formulated their model as, but it arguably just as readable,
# particularly if the `IJKLM` columns were meaningfully related to the business
# logic.

# This is much faster, taking just over 0.1 seconds:

@time dataframe_formulation(dataframe_data);
@time dataframe_formulation(dataframe_data);

# And we can make it slightly faster again (using much less memory) using the
# same tricks as before:

function fast_dataframe_formulation(data::DataFrameData)
    ijklm = DataFrames.innerjoin(
        DataFrames.innerjoin(data.IJK, data.JKL; on = [:j, :k]),
        data.KLM;
        on = [:k, :l],
    )
    model = direct_model(Gurobi.Optimizer())
    set_silent(model)
    set_string_names_on_creation(model, false)
    ijklm[!, :x] = @variable(model, x[1:size(ijklm, 1)] >= 0)
    for df in DataFrames.groupby(ijklm, :i)
        @constraint(model, sum(df.x) >= 0)
    end
    optimize!(model)
    return model
end

@time fast_dataframe_formulation(dataframe_data);
@time fast_dataframe_formulation(dataframe_data);

# ## Scaling

# Let's now compare the five different formulations over a range of `n` values:

# ```julia
# import Plots
#
# function timings()
#     N = [100, 200, 400, 700, 1_100, 1_600, 2_200, 2_900]
#     time_original = Float64[]
#     time_intuitive = Float64[]
#     time_fast = Float64[]
#     time_dataframe = Float64[]
#     time_fast_dataframe = Float64[]
#     for n in N
#         ## Original model
#         original_data = OriginalData(n)
#         start = time()
#         intuitive_formulation(original_data)
#         push!(time_original, time() - start)
#         ## Tuple models
#         tuple_data = TupleData(n)
#         start = time()
#         intuitive_formulation(tuple_data)
#         push!(time_intuitive, time() - start)
#         start = time()
#         fast_formulation(tuple_data)
#         push!(time_fast, time() - start)
#         ## DataFrame models
#         dataframe_data = DataFrameData(n)
#         start = time()
#         dataframe_formulation(dataframe_data)
#         push!(time_dataframe, time() - start)
#         start = time()
#         fast_dataframe_formulation(dataframe_data)
#         push!(time_fast_dataframe, time() - start)
#     end
#     Plots.plot(
#         N,
#         [time_original time_intuitive time_fast time_dataframe time_fast_dataframe];
#         labels = ["Original" "Intuitive" "Fast" "DataFrame" "Fast DataFrame"],
#         xlabel = "N",
#         ylabel = "Solution time (s)",
#     )
#     return
# end
#
# timings()
# ```

# <img src="/assets/tutorials/gams/scaling.svg">

# The dataframe formulations are significantly better. These results demonstrate
# how benchmarking different modeling systems is difficult, and choosing an
# appropriate datastructure for a model is too. It's likely that Pyomo and
# Gurobipy would similarly benefit from using `pandas` to perform the inner join
# instead of using nested for-loop approach.

# ## Other comments

# There are a few lines in the blog post that deserve some rebuttal.

# > One of the key differences between GAMS and the other modeling frameworks
# > we’ve mentioned is that GAMS is a domain-specific language

# In our opinion, JuMP is a [domain-specific language](https://en.wikipedia.org/wiki/Domain-specific_language)
# embedded in a programming language. Indeed, a key feature of JuMP is that the
# code users write inside the modeling macros (the identifiers beginninng with
# `@` ) is not what gets executed. Instead, JuMP parses the syntax that that the
# user writes, and compiles it into a different form that is more efficient.

# > While it’s true that general-purpose programming languages offer more
# > flexibility and control, it’s important to consider the trade-offs. With
# > general-purpose languages like Python and Julia, a straightforward
# > implementation closely aligned with the mathematical formulation is often
# > self-evident and easier to implement, read, and maintain, but suffers from
# > inadequate performance.

# This point is perhaps a matter of taste and personal experience. In our
# opinion, the GAMS syntax of
#
# `ei(i).. sum((IJK(i,j,k),JKL(j,k,l),KLM(k,l,m)), x(i,j,k,l,m)) =g= 0;`
#
# is not more readable or easier to maintain than the performant
# `dataframe_formulation` implementation.  In this case, viewing the problem as
# an optimization over three sets `IJK`, `JKL`, and `KLM` is more cumbersome
# than a single joined `IJKLM` table with one variable for each row and a
# single `groupby` constraint on the `I` indices.

# > Flexibility is also a double-edged sword. While it offers many different
# > ways to accomplish a task, there is also the risk of implementing a solution
# > that is not efficient. And determining the optimal approach is a challenging
# > task in itself. All of the discussed modeling frameworks allow a more or
# > less and depending on personal taste intuitive implementation of our
# > example’s model. However, intuitive solutions do not always turn out to be
# > efficient. With additional research and effort, it is possible to find
# > alternative implementations that outperform the intuitive approach, as
# > Figure 2 presents for JuMP.

# This is a fair point. It's obviously true that the added flexibility of Julia
# increases the risk of implementing a solution that is not efficient. But this
# is true of any computational problem. Indeed, the bottleneck in this example
# relates to an inner join on two tables, which would also arise if the user was
# exploring summary statistics.
#
# A feature of Julia is that you can smoothly transition from the unoptimized
# code to the much more efficient code while staying in the same language.
