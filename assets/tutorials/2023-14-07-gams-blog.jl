# # JuMP, GAMS, and the IJKLM model

# A recent blog post by GAMS demonstrated a significant performance difference
# between JuMP and GAMS on a model they call IJKLM. The purpose of this blog
# post is to explain the difference and present a different formulation with
# much better performance.

# ## The IJKLM model

# ## The input data

import JSON

struct OriginalData
    I::Vector{String}
    IJK::Vector{Vector{Any}}
    JKL::Vector{Vector{Any}}
    KLM::Vector{Vector{Any}}

    function OriginalData(n::Int)
        return new(
            ["i$i" for i in 1:n],
            JSON.parsefile("gams/data_IJK_$n.json"),
            JSON.parsefile("gams/data_JKL.json"),
            JSON.parsefile("gams/data_KLM.json"),
        )
    end
end

# ## The _intuitive_ formulation

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

original_data = OriginalData(2_200);

#-

@time intuitive_formulation(original_data)

#-

@time intuitive_formulation(original_data)

# ## Tweaking the iput data

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
            parsefile_tuple("gams/data_IJK_$n.json"),
            parsefile_tuple("gams/data_JKL.json"),
            parsefile_tuple("gams/data_KLM.json"),
        )
    end
end

tuple_data = TupleData(2_200);

#-

@time intuitive_formulation(tuple_data)

#-

@time intuitive_formulation(tuple_data)

# ## The _fast_ formulation

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

tuple_data = TupleData(2_200);

#-

@time fast_formulation(tuple_data)

#-

@time fast_formulation(tuple_data)

# ## The _DataFrames_ formulation

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
            parsefile_dataframe("gams/data_IJK_$n.json", (:i, :j, :k,)),
            parsefile_dataframe("gams/data_JKL.json", (:j, :k, :l)),
            parsefile_dataframe("gams/data_KLM.json", (:k, :l, :m)),
        )
    end
end

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

dataframe_data = DataFrameData(2_200);

#-

@time dataframe_formulation(dataframe_data)

#-

@time dataframe_formulation(dataframe_data)

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

#-

@time fast_dataframe_formulation(dataframe_data)

#-

@time fast_dataframe_formulation(dataframe_data)

# ## Conclusion
