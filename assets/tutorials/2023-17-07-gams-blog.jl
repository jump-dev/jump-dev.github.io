# # JuMP, GAMS, and the IJKLM model

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
# the `n = 2200` case. You can use the code in GAMS's [GitHub repository](https://github.com/justine18/performance_experiment)
# to generate other sizes.

original_data = OriginalData(2_200);

# Each element in the `IJK`, `JKL`, and `KLM` vectors is a vector of `String`
# with three elements, corresponding to the I-J-K, J-K-L, or K-L-M index.

original_data.IJK[1]

# ## The _intuitive_ formulation

# The _intuitive_ formulation used by GAMS in their blogpost is:

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

# ## Tweaking the iput data

# The typical reason for poor performance in a Julia code is type instability,
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
#  * The disabling of string nanmes
#  * A way to construct the left-hand side of each constraint in a single pass
#    through the list of `x` variables
#
# These improvements bring the time down to around 1 second.

@time fast_formulation(tuple_data);
@time fast_formulation(tuple_data);

# Why, then, is GAMS so much faster in their benchmark?

# The answer is that we didn't consider changing the nested for-loop used to
# create the list of indices:

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

# The blogpost hints at this, saying "The reason for GAMS superior performance
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

# ## Conclusion

# Benchmarking different modeling systems is difficult, and choosing an
# appropriate datastructure for a model is too. It's likely that Pyomo and
# Gurobipy would similarly benefit from using `pandas` to perform the inner join
# instead of using nested for-loop approach.
