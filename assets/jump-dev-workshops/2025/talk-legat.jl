### A Pluto.jl notebook ###
# v0.20.21

using Markdown
using InteractiveUtils

# ╔═╡ c3229e00-5d23-4986-994f-1d19911d9a03
using PlutoUI, HypertextLiteral, PlutoTeachingTools, JuMP, HiGHS, LinearAlgebra, SparseArrays, NLPModelsIpopt, BenchmarkTools, GenOpt, MadNLP, MadNLPGPU, CUDA

# ╔═╡ 8e1d4a42-698d-469e-8c8b-b25ac806455e
md"# Introduction"

# ╔═╡ 80e60e94-0309-4513-a5af-ebce2738be11
md"""
* ExaModels and MadNLP can differentiate and solve problems on GPU
  - Winners of COIN-OR Cup 2023 and JuMP-dev 2025
* ExaModels need common structure to be grouped together but JuMP does not communicate this structure
* ExaModels tries to rebuild this structure in its JuMP interface
* [MathOptSymbolicAD](https://github.com/lanl-ansi/MathOptSymbolicAD.jl) also regroups these to save symbolic differentiation time
* We discussed on how to better integrate ExaModels in JuMP during JuMP-dev 2025 hackathon with Miles and Alexis.
"""

# ╔═╡ 87b15eed-0ddd-4814-98cf-5f7c538eeaf6
md"## Objectives"

# ╔═╡ 4630c192-5783-4cb0-addf-09ef0bc7d6be
md"""
This talk present a new JuMP/MOI extension : [GenOpt](https://github.com/blegat/GenOpt.jl) whose objectives are twofolds

1. Define an MOI interface for groups of similar constraints or sum of similar terms.
   - This decouples the work of finding these similar patterns and exploiting them
   - This can allow drastic compression of the model for simpler communication (e.g., in a cluster environment)
2. Being able to write a **single** model compatible with both ExaModels and JuMP's AD backend.
   - Automatically dismantle these groups if the solvers cannot exploit them (with bridges!)
3. Add a JuMP interface for the user to explicitly specify these groups
4. Allow existing code base to use it without much changes
"""

# ╔═╡ a3528c53-1163-456e-90f1-525119cdef4b
md"# Example"

# ╔═╡ 243d79be-f55c-4388-8f65-eecce19aefea
md"""
[Quadrotor tutorial from ExaModels](https://exanauts.github.io/ExaModels.jl/dev/quad/).
Repeated structures are:
* Similar constraints along time steps
* Sum of similar terms in the objective
"""

# ╔═╡ eef717ab-ae1f-43ff-a929-65b511d47167
md"## Example with GenOpt"

# ╔═╡ a7d672cc-3f55-496b-80c4-76e597a16bc1
md"Problem data (copy-pasted from [ExaModels' example](https://exanauts.github.io/ExaModels.jl/stable/quad/)]):"

# ╔═╡ abb9340f-167e-4b2c-bfc7-c9df0ef9319e
begin
N = 3

n = 9
p = 4
d(i, j, N) =
    (j == 1 ? 1 * sin(2 * pi / N * i) : 0.0) +
    (j == 3 ? 2 * sin(4 * pi / N * i) : 0.0) +
    (j == 5 ? 2 * i / N : 0.0)
dt = 1/N
R = fill(1 / 10, 4)
Q = [1, 0, 1, 0, 1, 0, 1, 1, 1]
Qf = [1, 0, 1, 0, 1, 0, 1, 1, 1] / dt

x0 = zeros(n)
model = Model()

@variable(model, x[1:(N+1), 1:n])
@variable(model, u[1:N, 1:p])
end

# ╔═╡ 75f362c6-e69e-4cd1-8af7-6a7b6df06f25
md"## Approach of GenOpt"

# ╔═╡ 4c421cff-464a-41e2-b884-31011d5a07ec
md"""
Users already group constraints with containers, the container receives a function and the iterators, like `Base.Generator`.
"""

# ╔═╡ d06d4bdb-a4e4-4bfd-9243-1878723d2629
@constraint(model, classical[i in 1:n], x[1, i] == x0[i])

# ╔═╡ 326db900-7214-4121-aee5-ada44cc749f2
delete(model, classical)

# ╔═╡ 5ae8f51d-ad92-4862-8980-5ae5ed7b0be3
md"`ExaModels.constraint` expect a `Base.Generator` as well so containers seems to be the right approach. We use a custom container that gives custom objects for `i` and handle interaction with `JuMP.NonlinearExpr` with **operator overloading**."

# ╔═╡ 368b603a-198c-4a4d-a14e-98a3e270e33b
begin
@constraint(
    model,
    start[i in 1:n],
    x[1, i] == x0[i],
    container = GenOpt.ParametrizedArray,
);
println(start)
end

# ╔═╡ a0758565-57dd-4d51-bd63-97b993b45617
md"## Constraints"

# ╔═╡ 33939427-62ac-4da4-8ed9-09251adb3063
begin
container = GenOpt.ParametrizedArray
@constraint(
    model,
    [i in 1:N],
    x[i+1, 1] == x[i, 1] + (x[i, 2]) * dt,
    container = container,
)
@constraint(
    model,
    [i in 1:N],
    x[i+1, 2] ==
    x[i, 2] +
    (
        u[i, 1] * cos(x[i, 7]) * sin(x[i, 8]) * cos(x[i, 9]) +
        u[i, 1] * sin(x[i, 7]) * sin(x[i, 9])
    ) * dt,
    container = container,
)
@constraint(
    model,
    [i in 1:N],
    x[i+1, 3] == x[i, 3] + (x[i, 4]) * dt,
    container = container,
)
@constraint(
    model,
    [i in 1:N],
    x[i+1, 4] ==
    x[i, 4] +
    (
        u[i, 1] * cos(x[i, 7]) * sin(x[i, 8]) * sin(x[i, 9]) -
        u[i, 1] * sin(x[i, 7]) * cos(x[i, 9])
    ) * dt,
    container = container,
)
@constraint(
    model,
    [i in 1:N],
    x[i+1, 5] == x[i, 5] + (x[i, 6]) * dt,
    container = container,
)
@constraint(
    model,
    [i in 1:N],
    x[i+1, 6] == x[i, 6] + (u[i, 1] * cos(x[i, 7]) * cos(x[i, 8]) - 9.8) * dt,
    container = container,
)
@constraint(
    model,
    [i in 1:N],
    x[i+1, 7] ==
    x[i, 7] +
    (u[i, 2] * cos(x[i, 7]) / cos(x[i, 8]) + u[i, 3] * sin(x[i, 7]) / cos(x[i, 8])) * dt,
    container = container,
)
@constraint(
    model,
    [i in 1:N],
    x[i+1, 8] == x[i, 8] + (-u[i, 2] * sin(x[i, 7]) + u[i, 3] * cos(x[i, 7])) * dt,
    container = container,
)
@constraint(
    model,
    [i in 1:N],
    x[i+1, 9] ==
    x[i, 9] +
    (
        u[i, 2] * cos(x[i, 7]) * tan(x[i, 8]) +
        u[i, 3] * sin(x[i, 7]) * tan(x[i, 8]) +
        u[i, 4]
    ) * dt,
    container = container,
)
end;

# ╔═╡ 50045b20-4134-424f-aa73-84ea8161d292
md"## Objective"

# ╔═╡ 6ab07549-0166-4cc6-ae60-fa63b0d84602
begin
itr1 = [(i, j, d(i, j, N)) for i in 1:N, j in 1:n]
itr2 = [(j, d(N + 1, j, N)) for j in 1:n]
@objective(
    model,
    Min,
    lazy_sum(0.5 * R[j] * (u[i, j]^2) for i in 1:N, j in 1:p) +
    lazy_sum(0.5 * Q[it[2]] * (x[it[1], it[2]] - it[3])^2 for it in itr1) +
    lazy_sum(0.5 * Qf[it[1]] * (x[N+1, it[1]] - it[2])^2 for it in itr2),
)
end;

# ╔═╡ 5dc820bf-49c8-4bfe-9189-7d61ba503754
md"## CPU solve with MadNLP"

# ╔═╡ 2f3cee5a-8c14-481d-83d8-3a6e080e5929
begin
set_optimizer(model, () -> GenOpt.ExaOptimizer(madnlp))
optimize!(model)
end

# ╔═╡ d7a0b969-459e-4fb1-be89-c972169e8152
md"## GPU solve with MadNLP"

# ╔═╡ 695a10b8-63cb-4e29-a3bc-8852c30710b0
if CUDA.functional()
	set_optimizer(model, () -> GenOpt.ExaOptimizer(madnlp, CUDABackend()))
	optimize!(model)
end

# ╔═╡ 1ea1e950-04f9-4a21-b4a9-6b68aaf4e08e
md"# Zooming on the details"

# ╔═╡ a571ead2-d002-4c35-a1c3-af3461008196
md"## Appending values to the iterators"

# ╔═╡ 44875521-8ed5-4c84-b0ad-24238df0ca30
md"""
Explicit with ExaModels:
```julia
x0 = zeros(n)
x0s = [(i, x0[i]) for i = 1:n]
constraint(c, x[1, i] - x0 for (i, x0) in x0s)
```
Implicit in GenOpt:
```julia
@constraint(
    model,
    [i in 1:n],
    x[1, i] == x0[i],
    container = ParametrizedArray,
)
```
"""

# ╔═╡ ad6a2913-f3e6-4a88-b09b-deae7f750629
md"## Cartesian products"

# ╔═╡ 78c3e3da-c714-452d-b247-7eb956e2c530
md"""
Explicit with ExaModels:
```julia
itr0 = [(i, j, R[j]) for (i, j) in Base.product(1:N, 1:p)]
objective(c, 0.5 * R * (u[i, j]^2) for (i, j, R) in itr0)
```
Implicit in GenOpt:
```julia
@objective(
    model,
    Min,
    lazy_sum(0.5 * R[j] * (u[i, j]^2) for i in 1:N, j in 1:p) +
    ...,
)
```
"""

# ╔═╡ 3ea6c5ed-defb-4ff0-9dea-a89b6f1bdf44
md"## Array of variables"

# ╔═╡ 4a8c7fc7-b6c9-4f65-912b-47caaf42a02e
md"""
Indexing an array of variable `(x::Vector{VariableRef}[i::Iterator])`:

* We require the indices of `x` to be continuous and transform `x` into a custom struct only containing the starting index and size.
* This will not be compatible with variable reordering/deletion.
* This means that we store array nodes in `JuMP.NonlinearExpr`/`MOI.ScalarNonlinearFunction`
  - This will also be helpful for [ArrayDiff.jl](github.com/blegat/ArrayDiff.jl/) and [Convex.jl](https://github.com/jump-dev/Convex.jl)
"""

# ╔═╡ 48be9851-9dd6-4206-84aa-b9b6cd4529f3
md"# Future work"

# ╔═╡ 88b0d3fc-cdae-4704-b24a-f847509123ae
md"""
* Adding groups of terms to groups of **different** constraints:
```julia
constraint!(w, c9, a.bus => p[a.i] for a in data.arc)
constraint!(w, c10, a.bus => q[a.i] for a in data.arc)

constraint!(w, c9, g.bus => -pg[g.i] for g in data.gen)
constraint!(w, c10, g.bus => -qg[g.i] for g in data.gen)
```
* Efficient bridge from group of constraints to individual constraints using MutableArithmetics.
  - Since the groups are dismantled at the MOI level, this might fix [JuMP#1654](https://github.com/jump-dev/JuMP.jl/issues/1654)
"""

# ╔═╡ 463bb8c3-7b1c-443d-9a70-44c2ff5623f6
html"<p align=center style=\"font-size: 20px; margin-bottom: 5cm; margin-top: 5cm;\">The End</p>"

# ╔═╡ 2b17c40c-f312-420a-8ce7-90b41a9925c4
md"## Utils"

# ╔═╡ 0da26bb1-6908-46ad-b608-e4a2dbfd7b39
begin
struct Path
    path::String
end

function imgpath(path::Path)
    file = path.path
    if !('.' in file)
        file = file * ".png"
    end
    return joinpath(joinpath(@__DIR__, "images", file))
end

function img(path::Path, args...; kws...)
    return PlutoUI.LocalResource(imgpath(path), args...)
end

struct URL
    url::String
end

function save_image(url::URL, html_attributes...; name = split(url.url, '/')[end], kws...)
    path = joinpath("cache", name)
    return PlutoTeachingTools.RobustLocalResource(url.url, path, html_attributes...), path
end

function img(url::URL, args...; kws...)
    r, _ = save_image(url, args...; kws...)
    return r
end

function img(file::String, args...; kws...)
    if startswith(file, "http")
        img(URL(file), args...; kws...)
    else
        img(Path(file), args...; kws...)
    end
end
end

# ╔═╡ 89cfbbb0-c3a7-11f0-bea8-6b8a0e78862d
@htl("""
<p align=center style=\"font-size: 40px;\">Large Scale JuMP Models with Constraint Generators</p>
<p align=right><i>Benoît Legat</i></p>
$(img("https://jump.dev/assets/jump-dev-workshops/2025/jump-dev-nz.png", :width => 100))
$(PlutoTeachingTools.ChooseDisplayMode())
$(PlutoUI.TableOfContents(depth=1))
""")

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
GenOpt = "f2c049d8-7489-4223-990c-4f1c121a4cde"
HiGHS = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
HypertextLiteral = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
JuMP = "4076af6c-e467-56ae-b986-b466b2749572"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
MadNLP = "2621e9c9-9eb4-46b1-8089-e8c72242dfb6"
MadNLPGPU = "d72a61cc-809d-412f-99be-fd81f4b8a598"
NLPModelsIpopt = "f4238b75-b362-5c4c-b852-0801c9a21d71"
PlutoTeachingTools = "661c6b06-c737-4d37-b85c-46df65de6f69"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[compat]
BenchmarkTools = "~1.6.3"
CUDA = "~5.9.4"
GenOpt = "~0.1.0"
HiGHS = "~1.20.1"
HypertextLiteral = "~0.9.5"
JuMP = "~1.29.3"
MadNLP = "~0.8.12"
MadNLPGPU = "~0.7.16"
NLPModelsIpopt = "~0.11.0"
PlutoTeachingTools = "~0.4.6"
PlutoUI = "~0.7.75"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.2"
manifest_format = "2.0"
project_hash = "a8d7fec463426a4184c389ae61734430039133aa"

[[deps.AMD]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse_jll"]
git-tree-sha1 = "45a1272e3f809d36431e57ab22703c6896b8908f"
uuid = "14f7f29c-3bd6-536c-9a0b-7339e30b5a3e"
version = "0.5.3"

[[deps.ASL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6252039f98492252f9e47c312c8ffda0e3b9e78d"
uuid = "ae81ac8f-d209-56e5-92de-9978fef736f9"
version = "0.1.3+0"

[[deps.AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "d92ad398961a3ed262d8bf04a1a2b8340f915fef"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.5.0"

    [deps.AbstractFFTs.extensions]
    AbstractFFTsChainRulesCoreExt = "ChainRulesCore"
    AbstractFFTsTestExt = "Test"

    [deps.AbstractFFTs.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "7e35fca2bdfba44d797c53dfe63a51fabf39bfc0"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "4.4.0"
weakdeps = ["SparseArrays", "StaticArrays"]

    [deps.Adapt.extensions]
    AdaptSparseArraysExt = "SparseArrays"
    AdaptStaticArraysExt = "StaticArrays"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Atomix]]
deps = ["UnsafeAtomics"]
git-tree-sha1 = "29bb0eb6f578a587a49da16564705968667f5fa8"
uuid = "a9b6321e-bd34-4604-b9c9-b65b8de01458"
version = "1.1.2"

    [deps.Atomix.extensions]
    AtomixCUDAExt = "CUDA"
    AtomixMetalExt = "Metal"
    AtomixOpenCLExt = "OpenCL"
    AtomixoneAPIExt = "oneAPI"

    [deps.Atomix.weakdeps]
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    Metal = "dde4c033-4e86-420c-a63e-0dd931031962"
    OpenCL = "08131aa3-fb12-5dee-8b74-c09406e224a2"
    oneAPI = "8f75cd03-7ff8-4ecb-9b8f-daf728133b1b"

[[deps.BFloat16s]]
deps = ["LinearAlgebra", "Printf", "Random"]
git-tree-sha1 = "0a6d6d072cb5f2baeba7667023075801f6ea4a7d"
uuid = "ab4f0b2a-ad5b-11e8-123f-65d77653426b"
version = "0.6.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.BenchmarkTools]]
deps = ["Compat", "JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "7fecfb1123b8d0232218e2da0c213004ff15358d"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.6.3"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1b96ea4a01afe0ea4090c5c8039690672dd13f2e"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.9+0"

[[deps.CEnum]]
git-tree-sha1 = "389ad5c84de1ae7cf0e28e381131c98ea87d54fc"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.5.0"

[[deps.CUDA]]
deps = ["AbstractFFTs", "Adapt", "BFloat16s", "CEnum", "CUDA_Compiler_jll", "CUDA_Driver_jll", "CUDA_Runtime_Discovery", "CUDA_Runtime_jll", "Crayons", "DataFrames", "ExprTools", "GPUArrays", "GPUCompiler", "GPUToolbox", "KernelAbstractions", "LLVM", "LLVMLoopInfo", "LazyArtifacts", "Libdl", "LinearAlgebra", "Logging", "NVTX", "Preferences", "PrettyTables", "Printf", "Random", "Random123", "RandomNumbers", "Reexport", "Requires", "SparseArrays", "StaticArrays", "Statistics", "demumble_jll"]
git-tree-sha1 = "38b6a1fe14fba13cdc0a44ecd2485eb5f7e16ca0"
uuid = "052768ef-5323-5732-b1bb-66c8b64840ba"
version = "5.9.4"

    [deps.CUDA.extensions]
    ChainRulesCoreExt = "ChainRulesCore"
    EnzymeCoreExt = "EnzymeCore"
    SparseMatricesCSRExt = "SparseMatricesCSR"
    SpecialFunctionsExt = "SpecialFunctions"

    [deps.CUDA.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    EnzymeCore = "f151be2c-9106-41f4-ab19-57ee4f262869"
    SparseMatricesCSR = "a0a7dd2c-ebf4-11e9-1f05-cf50bc540ca1"
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"

[[deps.CUDA_Compiler_jll]]
deps = ["Artifacts", "CUDA_Driver_jll", "CUDA_Runtime_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "TOML"]
git-tree-sha1 = "b63428872a0f60d87832f5899369837cd930b76d"
uuid = "d1e2174e-dfdc-576e-b43e-73b79eb1aca8"
version = "0.3.0+0"

[[deps.CUDA_Driver_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "2023be0b10c56d259ea84a94dbfc021aa452f2c6"
uuid = "4ee394cb-3365-5eb0-8335-949819d2adfc"
version = "13.0.2+0"

[[deps.CUDA_Runtime_Discovery]]
deps = ["Libdl"]
git-tree-sha1 = "f9a521f52d236fe49f1028d69e549e7f2644bb72"
uuid = "1af6417a-86b4-443c-805f-a4643ffb695f"
version = "1.0.0"

[[deps.CUDA_Runtime_jll]]
deps = ["Artifacts", "CUDA_Driver_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "TOML"]
git-tree-sha1 = "92cd84e2b760e471d647153ea5efc5789fc5e8b2"
uuid = "76a88914-d11a-5bdc-97e0-2f5a05c973a2"
version = "0.19.2+0"

[[deps.CUDSS]]
deps = ["CEnum", "CUDA", "CUDSS_jll", "GPUToolbox", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "bff863cd922a9fad87b1173962a0d42068d55afb"
uuid = "45b445bb-4962-46a0-9369-b4df9d0f772e"
version = "0.6.2"

[[deps.CUDSS_jll]]
deps = ["Artifacts", "CUDA_Runtime_jll", "CompilerSupportLibraries_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "TOML"]
git-tree-sha1 = "b40ab570473a4bf8694c7922a22c2def848ccfcf"
uuid = "4889d778-9329-5762-9fec-0578a5d30366"
version = "0.7.1+0"

[[deps.CodecBzip2]]
deps = ["Bzip2_jll", "TranscodingStreams"]
git-tree-sha1 = "84990fa864b7f2b4901901ca12736e45ee79068c"
uuid = "523fee87-0ab8-5b00-afb7-3ecf72e48cfd"
version = "0.8.5"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "962834c22b66e32aa10f7611c08c8ca4e20749a9"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.8"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "67e11ee83a43eb71ddc950302c53bf33f0690dfe"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.1"
weakdeps = ["StyledStrings"]

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "37ea44092930b1811e666c3bc38065d7d87fcc74"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.13.1"

[[deps.CommonSubexpressions]]
deps = ["MacroTools"]
git-tree-sha1 = "cda2cfaebb4be89c9084adaca7dd7333369715c5"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.1"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "9d8a54ce4b17aa5bdce0ea5c34bc5e7c340d16ad"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.18.1"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.3.0+1"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "DataStructures", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrecompileTools", "PrettyTables", "Printf", "Random", "Reexport", "SentinelArrays", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "d8928e9169ff76c6281f39a659f9bca3a573f24c"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.8.1"

[[deps.DataStructures]]
deps = ["OrderedCollections"]
git-tree-sha1 = "e357641bb3e0638d353c4b29ea0e40ea644066a6"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.19.3"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.DiffResults]]
deps = ["StaticArraysCore"]
git-tree-sha1 = "782dd5f4561f5d267313f23853baaaa4c52ea621"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.1.0"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "23163d55f885173722d1e4cf0f6110cdbaf7e272"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.15.1"

[[deps.DocStringExtensions]]
git-tree-sha1 = "7442a5dfe1ebb773c29cc2962a8980f47221d76c"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.5"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.7.0"

[[deps.ExaModels]]
deps = ["NLPModels", "Printf", "SolverCore"]
git-tree-sha1 = "2a372f5f8049cc429ddd98cd89247bc51ab954d7"
uuid = "1037b233-b668-4ce9-9b63-f9f681f55dd2"
version = "0.9.2"

    [deps.ExaModels.extensions]
    ExaModelsAMDGPU = "AMDGPU"
    ExaModelsCUDA = "CUDA"
    ExaModelsIpopt = ["MathOptInterface", "NLPModelsIpopt"]
    ExaModelsJuMP = "JuMP"
    ExaModelsKernelAbstractions = "KernelAbstractions"
    ExaModelsMOI = "MathOptInterface"
    ExaModelsMadNLP = ["MadNLP", "MathOptInterface"]
    ExaModelsOneAPI = "oneAPI"
    ExaModelsOpenCL = "OpenCL"
    ExaModelsSpecialFunctions = "SpecialFunctions"

    [deps.ExaModels.weakdeps]
    AMDGPU = "21141c5a-9bdb-4563-92ae-f87d6854732e"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    Ipopt = "b6b21f68-93f8-5de0-b562-5493be1d77c9"
    JuMP = "4076af6c-e467-56ae-b986-b466b2749572"
    KernelAbstractions = "63c18a36-062a-441e-b654-da1e3ab1ce7c"
    MadNLP = "2621e9c9-9eb4-46b1-8089-e8c72242dfb6"
    MathOptInterface = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"
    NLPModelsIpopt = "f4238b75-b362-5c4c-b852-0801c9a21d71"
    OpenCL = "08131aa3-fb12-5dee-8b74-c09406e224a2"
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"
    oneAPI = "8f75cd03-7ff8-4ecb-9b8f-daf728133b1b"

[[deps.ExprTools]]
git-tree-sha1 = "27415f162e6028e81c72b82ef756bf321213b6ec"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.10"

[[deps.FastClosures]]
git-tree-sha1 = "acebe244d53ee1b461970f8910c235b259e772ef"
uuid = "9aa1b823-49e4-5ca5-8b0f-3971ec8bab6a"
version = "0.3.2"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Format]]
git-tree-sha1 = "9c68794ef81b08086aeb32eeaf33531668d5f5fc"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.7"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions"]
git-tree-sha1 = "cd33c7538e68650bd0ddbb3f5bd50a4a0fa95b50"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "1.3.0"
weakdeps = ["StaticArrays"]

    [deps.ForwardDiff.extensions]
    ForwardDiffStaticArraysExt = "StaticArrays"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"
version = "1.11.0"

[[deps.GPUArrays]]
deps = ["Adapt", "GPUArraysCore", "KernelAbstractions", "LLVM", "LinearAlgebra", "Printf", "Random", "Reexport", "ScopedValues", "Serialization", "SparseArrays", "Statistics"]
git-tree-sha1 = "515bd10e849cf34855f0eb39922ca31b8288017e"
uuid = "0c68f7d7-f131-5f86-a1c3-88cf8149b2d7"
version = "11.3.0"

    [deps.GPUArrays.extensions]
    JLD2Ext = "JLD2"

    [deps.GPUArrays.weakdeps]
    JLD2 = "033835bb-8acc-5ee8-8aae-3f567f8a3819"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "83cf05ab16a73219e5f6bd1bdfa9848fa24ac627"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.2.0"

[[deps.GPUCompiler]]
deps = ["ExprTools", "InteractiveUtils", "LLVM", "Libdl", "Logging", "PrecompileTools", "Preferences", "Scratch", "Serialization", "TOML", "Tracy", "UUIDs"]
git-tree-sha1 = "90554fe518adab1b4c8f7a04d26c414482a240ca"
uuid = "61eb1bfa-7361-4325-ad38-22787b887f55"
version = "1.7.4"

[[deps.GPUToolbox]]
deps = ["LLVM"]
git-tree-sha1 = "9e9186b09a13b7f094f87d1a9bb266d8780e1b1c"
uuid = "096a3bc2-3ced-46d0-87f4-dd12716f4bfc"
version = "1.0.0"

[[deps.GenOpt]]
deps = ["ExaModels", "JuMP", "MathOptInterface"]
git-tree-sha1 = "e84a6bf0a3464930e51ce5fe7d49580f8d604b6a"
uuid = "f2c049d8-7489-4223-990c-4f1c121a4cde"
version = "0.1.0"

[[deps.Ghostscript_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Zlib_jll"]
git-tree-sha1 = "38044a04637976140074d0b0621c1edf0eb531fd"
uuid = "61579ee1-b43e-5ca0-a5da-69d92c66a64b"
version = "9.55.1+0"

[[deps.HashArrayMappedTries]]
git-tree-sha1 = "2eaa69a7cab70a52b9687c8bf950a5a93ec895ae"
uuid = "076d061b-32b6-4027-95e0-9a2c6f6d7e74"
version = "0.2.0"

[[deps.HiGHS]]
deps = ["HiGHS_jll", "MathOptIIS", "MathOptInterface", "PrecompileTools", "SparseArrays"]
git-tree-sha1 = "7eaca80074d6389bbf83e4dfb1eaf6b3cd78d150"
uuid = "87dc4568-4c63-4d18-b0c0-bb2238e4078b"
version = "1.20.1"

[[deps.HiGHS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "METIS_jll", "OpenBLAS32_jll", "Zlib_jll"]
git-tree-sha1 = "e0539aa3405df00e963a9a56d5e903a280f328e7"
uuid = "8fd58aa0-07eb-5a78-9b36-339c94fd15ea"
version = "1.12.0+0"

[[deps.Hwloc_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "XML2_jll", "Xorg_libpciaccess_jll"]
git-tree-sha1 = "3d468106a05408f9f7b6f161d9e7715159af247b"
uuid = "e33a78d0-f292-5ffc-b300-72abe9b543c8"
version = "2.12.2+0"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "0ee181ec08df7d7c911901ea38baf16f755114dc"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "1.0.0"

[[deps.InlineStrings]]
git-tree-sha1 = "8f3d257792a522b4601c24a577954b0a8cd7334d"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.5"

    [deps.InlineStrings.extensions]
    ArrowTypesExt = "ArrowTypes"
    ParsersExt = "Parsers"

    [deps.InlineStrings.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"
    Parsers = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.InvertedIndices]]
git-tree-sha1 = "6da3c4316095de0f5ee2ebd875df8721e7e0bdbe"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.1"

[[deps.Ipopt]]
deps = ["Ipopt_jll", "LinearAlgebra", "OpenBLAS32_jll", "PrecompileTools"]
git-tree-sha1 = "b71d66023c875c28881af6749a41df3878bc3fb3"
uuid = "b6b21f68-93f8-5de0-b562-5493be1d77c9"
version = "1.13.0"
weakdeps = ["MathOptInterface"]

    [deps.Ipopt.extensions]
    IpoptMathOptInterfaceExt = "MathOptInterface"

[[deps.Ipopt_jll]]
deps = ["ASL_jll", "Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "MUMPS_seq_jll", "SPRAL_jll", "libblastrampoline_jll"]
git-tree-sha1 = "b33cbc78b8d4de87d18fcd705054a82e2999dbac"
uuid = "9cc047cb-c261-5740-88fc-0cf96f7bdcc7"
version = "300.1400.1900+0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "b2d91fe939cae05960e760110b328288867b5758"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.6"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "0533e564aae234aff59ab625543145446d8b6ec2"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.7.1"

[[deps.JSON]]
deps = ["Dates", "Logging", "Parsers", "PrecompileTools", "StructUtils", "UUIDs", "Unicode"]
git-tree-sha1 = "5b6bb73f555bc753a6153deec3717b8904f5551c"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "1.3.0"

    [deps.JSON.extensions]
    JSONArrowExt = ["ArrowTypes"]

    [deps.JSON.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"

[[deps.JSON3]]
deps = ["Dates", "Mmap", "Parsers", "PrecompileTools", "StructTypes", "UUIDs"]
git-tree-sha1 = "411eccfe8aba0814ffa0fdf4860913ed09c34975"
uuid = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
version = "1.14.3"

    [deps.JSON3.extensions]
    JSON3ArrowExt = ["ArrowTypes"]

    [deps.JSON3.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "4255f0032eafd6451d707a51d5f0248b8a165e4d"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.1.3+0"

[[deps.JuMP]]
deps = ["LinearAlgebra", "MacroTools", "MathOptInterface", "MutableArithmetics", "OrderedCollections", "PrecompileTools", "Printf", "SparseArrays"]
git-tree-sha1 = "b76f23c45d75e27e3e9cbd2ee68d8e39491052d0"
uuid = "4076af6c-e467-56ae-b986-b466b2749572"
version = "1.29.3"

    [deps.JuMP.extensions]
    JuMPDimensionalDataExt = "DimensionalData"

    [deps.JuMP.weakdeps]
    DimensionalData = "0703355e-b756-11e9-17c0-8b28908087d0"

[[deps.JuliaNVTXCallbacks_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "af433a10f3942e882d3c671aacb203e006a5808f"
uuid = "9c1d0b0a-7046-5b2e-a33f-ea22f176ac7e"
version = "0.2.1+0"

[[deps.JuliaSyntaxHighlighting]]
deps = ["StyledStrings"]
uuid = "ac6e5ff7-fb65-4e79-a425-ec3bc9c03011"
version = "1.12.0"

[[deps.KernelAbstractions]]
deps = ["Adapt", "Atomix", "InteractiveUtils", "MacroTools", "PrecompileTools", "Requires", "StaticArrays", "UUIDs"]
git-tree-sha1 = "b5a371fcd1d989d844a4354127365611ae1e305f"
uuid = "63c18a36-062a-441e-b654-da1e3ab1ce7c"
version = "0.9.39"

    [deps.KernelAbstractions.extensions]
    EnzymeExt = "EnzymeCore"
    LinearAlgebraExt = "LinearAlgebra"
    SparseArraysExt = "SparseArrays"

    [deps.KernelAbstractions.weakdeps]
    EnzymeCore = "f151be2c-9106-41f4-ab19-57ee4f262869"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.LDLFactorizations]]
deps = ["AMD", "LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "70f582b446a1c3ad82cf87e62b878668beef9d13"
uuid = "40e66cde-538c-5869-a4ad-c39174c6795b"
version = "0.10.1"

[[deps.LLVM]]
deps = ["CEnum", "LLVMExtra_jll", "Libdl", "Preferences", "Printf", "Unicode"]
git-tree-sha1 = "ce8614210409eaa54ed5968f4b50aa96da7ae543"
uuid = "929cbde3-209d-540e-8aea-75f648917ca0"
version = "9.4.4"
weakdeps = ["BFloat16s"]

    [deps.LLVM.extensions]
    BFloat16sExt = "BFloat16s"

[[deps.LLVMExtra_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl", "TOML"]
git-tree-sha1 = "8e76807afb59ebb833e9b131ebf1a8c006510f33"
uuid = "dad2f222-ce93-54a1-a47d-0025e8a3acab"
version = "0.0.38+0"

[[deps.LLVMLoopInfo]]
git-tree-sha1 = "2e5c102cfc41f48ae4740c7eca7743cc7e7b75ea"
uuid = "8b046642-f1f6-4319-8d3c-209ddc03c586"
version = "1.0.0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "dda21b8cbd6a6c40d9d02a73230f9d70fed6918c"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

[[deps.Latexify]]
deps = ["Format", "Ghostscript_jll", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Requires"]
git-tree-sha1 = "44f93c47f9cd6c7e431f2f2091fcba8f01cd7e8f"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.16.10"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    SparseArraysExt = "SparseArrays"
    SymEngineExt = "SymEngine"
    TectonicExt = "tectonic_jll"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"
    tectonic_jll = "d7dd28d6-a5e6-559c-9131-7eb760cdacc5"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"
version = "1.11.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "OpenSSL_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.15.0+0"

[[deps.LibGit2]]
deps = ["LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "OpenSSL_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.9.0+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "OpenSSL_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.3+1"

[[deps.LibTracyClient_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d2bc4e1034b2d43076b50f0e34ea094c2cb0a717"
uuid = "ad6e5548-8b26-5c9f-8ef3-ef0ad883f3a5"
version = "0.9.1+6"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "be484f5c92fad0bd8acfef35fe017900b0b73809"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.18.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.12.0"

[[deps.LinearOperators]]
deps = ["FastClosures", "LinearAlgebra", "Printf", "Requires", "SparseArrays", "TimerOutputs"]
git-tree-sha1 = "db137007d2c4ed948aa5f2518a2b451851ea8bda"
uuid = "5c8ed15e-5a4c-59e4-a42b-c7e8811fb125"
version = "2.11.0"

    [deps.LinearOperators.extensions]
    LinearOperatorsAMDGPUExt = "AMDGPU"
    LinearOperatorsCUDAExt = "CUDA"
    LinearOperatorsChainRulesCoreExt = "ChainRulesCore"
    LinearOperatorsJLArraysExt = "JLArrays"
    LinearOperatorsLDLFactorizationsExt = "LDLFactorizations"
    LinearOperatorsMetalExt = "Metal"

    [deps.LinearOperators.weakdeps]
    AMDGPU = "21141c5a-9bdb-4563-92ae-f87d6854732e"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    JLArrays = "27aeb0d3-9eb9-45fb-866b-73c2ecf80fcb"
    LDLFactorizations = "40e66cde-538c-5869-a4ad-c39174c6795b"
    Metal = "dde4c033-4e86-420c-a63e-0dd931031962"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "13ca9e2586b89836fd20cccf56e57e2b9ae7f38f"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.29"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.METIS_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "2eefa8baa858871ae7770c98c3c2a7e46daba5b4"
uuid = "d00139f3-1899-568f-a2f0-47f597d42d70"
version = "5.1.3+0"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.MUMPS_seq_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "METIS_jll", "libblastrampoline_jll"]
git-tree-sha1 = "fc0c8442887b48c15aec2b1787a5fc812a99b2fd"
uuid = "d7ed1dd3-d0ae-5e8e-bfb4-87a502085b8d"
version = "500.800.100+0"

[[deps.MacroTools]]
git-tree-sha1 = "1e0228a030642014fe5cfe68c2c0a818f9e3f522"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.16"

[[deps.MadNLP]]
deps = ["LDLFactorizations", "LinearAlgebra", "Logging", "NLPModels", "Pkg", "Printf", "SolverCore", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "6d4d80f692d35e073d6e5796ebb0a8a07963d781"
uuid = "2621e9c9-9eb4-46b1-8089-e8c72242dfb6"
version = "0.8.12"
weakdeps = ["MathOptInterface"]

    [deps.MadNLP.extensions]
    MadNLPMOI = "MathOptInterface"

[[deps.MadNLPGPU]]
deps = ["AMD", "CUDA", "CUDSS", "KernelAbstractions", "LinearAlgebra", "MadNLP", "Metis", "SparseArrays"]
git-tree-sha1 = "10fae48121a43e517566b16b41a6448e62ae6829"
uuid = "d72a61cc-809d-412f-99be-fd81f4b8a598"
version = "0.7.16"

    [deps.MadNLPGPU.extensions]
    MadNLPGPUAMDGPUExt = "AMDGPU"

    [deps.MadNLPGPU.weakdeps]
    AMDGPU = "21141c5a-9bdb-4563-92ae-f87d6854732e"

[[deps.Markdown]]
deps = ["Base64", "JuliaSyntaxHighlighting", "StyledStrings"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MathOptIIS]]
deps = ["MathOptInterface"]
git-tree-sha1 = "31d4a6353ea00603104f11384aa44dd8b7162b28"
uuid = "8c4f8055-bd93-4160-a86b-a0c04941dbff"
version = "0.1.1"

[[deps.MathOptInterface]]
deps = ["BenchmarkTools", "CodecBzip2", "CodecZlib", "DataStructures", "ForwardDiff", "JSON3", "LinearAlgebra", "MutableArithmetics", "NaNMath", "OrderedCollections", "PrecompileTools", "Printf", "SparseArrays", "SpecialFunctions", "Test"]
git-tree-sha1 = "a2cbab4256690aee457d136752c404e001f27768"
uuid = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"
version = "1.46.0"

[[deps.Metis]]
deps = ["CEnum", "LinearAlgebra", "METIS_jll", "SparseArrays"]
git-tree-sha1 = "54aca4fd53d39dcd2c3f1bef367b6921e8178628"
uuid = "2679e427-3c69-5b7f-982b-ece356f1e94b"
version = "1.5.0"

    [deps.Metis.extensions]
    MetisGraphs = "Graphs"
    MetisLightGraphs = "LightGraphs"
    MetisSimpleWeightedGraphs = ["SimpleWeightedGraphs", "Graphs"]

    [deps.Metis.weakdeps]
    Graphs = "86223c79-3864-5bf0-83f7-82e725a168b6"
    LightGraphs = "093fc24a-ae57-5d10-9952-331d41423f4d"
    SimpleWeightedGraphs = "47aef6b3-ad0c-573a-a1e2-d07658019622"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2025.5.20"

[[deps.MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "22df8573f8e7c593ac205455ca088989d0a2c7a0"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "1.6.7"

[[deps.NLPModels]]
deps = ["FastClosures", "LinearAlgebra", "LinearOperators", "Printf", "SparseArrays"]
git-tree-sha1 = "ac58082a07f0bd559292e869770d462d7ad0a7e2"
uuid = "a4795742-8479-5a88-8948-cc11e1c8c1a6"
version = "0.21.5"

[[deps.NLPModelsIpopt]]
deps = ["Ipopt", "NLPModels", "NLPModelsModifiers", "SolverCore"]
git-tree-sha1 = "4bda4cf02a6ff0a9508179503517cb905519bbf9"
uuid = "f4238b75-b362-5c4c-b852-0801c9a21d71"
version = "0.11.0"

[[deps.NLPModelsModifiers]]
deps = ["FastClosures", "LinearAlgebra", "LinearOperators", "NLPModels", "Printf", "SparseArrays"]
git-tree-sha1 = "a80505adbe42104cbbe9674591a5ccd9e9c2dfda"
uuid = "e01155f1-5c6f-4375-a9d8-616dd036575f"
version = "0.7.2"

[[deps.NVTX]]
deps = ["Colors", "JuliaNVTXCallbacks_jll", "Libdl", "NVTX_jll"]
git-tree-sha1 = "6b573a3e66decc7fc747afd1edbf083ff78c813a"
uuid = "5da4648a-3479-48b8-97b9-01cb529c0a1f"
version = "1.0.1"

[[deps.NVTX_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "af2232f69447494514c25742ba1503ec7e9877fe"
uuid = "e98f9f5b-d649-5603-91fd-7774390e6439"
version = "3.2.2+0"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "9b8215b1ee9e78a293f99797cd31375471b2bcae"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.1.3"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.3.0"

[[deps.OpenBLAS32_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "ece4587683695fe4c5f20e990da0ed7e83c351e7"
uuid = "656ef2d0-ae68-5445-9ca0-591084a874a2"
version = "0.3.29+0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.29+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.7+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.4+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1346c9208249809840c91b26703912dff463d335"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.6+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "05868e21324cede2207c6f0f466b4bfef6d5e7ee"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.1"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "7d2f8f21da5db6a806faf7b9b292296da42b2810"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.3"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.12.0"
weakdeps = ["REPL"]

    [deps.Pkg.extensions]
    REPLExt = "REPL"

[[deps.PlutoTeachingTools]]
deps = ["Downloads", "HypertextLiteral", "Latexify", "Markdown", "PlutoUI"]
git-tree-sha1 = "dacc8be63916b078b592806acd13bb5e5137d7e9"
uuid = "661c6b06-c737-4d37-b85c-46df65de6f69"
version = "0.4.6"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "db8a06ef983af758d285665a0398703eb5bc1d66"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.75"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "36d8b4b899628fb92c2749eb488d884a926614d3"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.3"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "07a921781cab75691315adc645096ed5e370cb77"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.3.3"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "0f27480397253da18fe2c12a4ba4eb9eb208bf3d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.5.0"

[[deps.PrettyTables]]
deps = ["Crayons", "LaTeXStrings", "Markdown", "PrecompileTools", "Printf", "REPL", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "c5a07210bd060d6a8491b0ccdee2fa0235fc00bf"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "3.1.2"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.Profile]]
deps = ["StyledStrings"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"
version = "1.11.0"

[[deps.REPL]]
deps = ["InteractiveUtils", "JuliaSyntaxHighlighting", "Markdown", "Sockets", "StyledStrings", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Random123]]
deps = ["Random", "RandomNumbers"]
git-tree-sha1 = "dbe5fd0b334694e905cb9fda73cd8554333c46e2"
uuid = "74087812-796a-5b5d-8853-05524746bad3"
version = "1.7.1"

[[deps.RandomNumbers]]
deps = ["Random"]
git-tree-sha1 = "c6ec94d2aaba1ab2ff983052cf6a606ca5985902"
uuid = "e6cf234a-135c-5ec9-84dd-332b85af5143"
version = "1.6.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "62389eeff14780bfe55195b7204c0d8738436d64"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.1"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SPRAL_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Hwloc_jll", "JLLWrappers", "Libdl", "METIS_jll", "libblastrampoline_jll"]
git-tree-sha1 = "4f9833187a65ead66ed1907b44d5f20606282e3f"
uuid = "319450e9-13b8-58e8-aa9f-8fd1420848ab"
version = "2025.5.20+0"

[[deps.ScopedValues]]
deps = ["HashArrayMappedTries", "Logging"]
git-tree-sha1 = "c3b2323466378a2ba15bea4b2f73b081e022f473"
uuid = "7e506255-f358-4e82-b7e4-beb19740aa63"
version = "1.5.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "9b81b8393e50b7d4e6d0a9f14e192294d3b7c109"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.3.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "712fb0231ee6f9120e005ccd56297abbc053e7e0"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.8"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.SolverCore]]
deps = ["LinearAlgebra", "NLPModels", "Printf"]
git-tree-sha1 = "03a1e0d2d39b9ebc9510f2452c0adfbe887b9cb2"
uuid = "ff4d7338-4cf1-434d-91df-b86cb86fb843"
version = "0.3.8"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "64d974c2e6fdf07f8155b5b2ca2ffa9069b608d9"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.2"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.12.0"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "f2685b435df2613e25fc10ad8c26dddb8640f547"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.6.1"

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

    [deps.SpecialFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "b8693004b385c842357406e3af647701fe783f98"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.15"

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

    [deps.StaticArrays.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6ab403037779dae8c514bad259f32a447262455a"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.4"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"
weakdeps = ["SparseArrays"]

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

[[deps.StringManipulation]]
deps = ["PrecompileTools"]
git-tree-sha1 = "a3c1536470bf8c5e02096ad4853606d7c8f62721"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.4.2"

[[deps.StructTypes]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "159331b30e94d7b11379037feeb9b690950cace8"
uuid = "856f2bd8-1eba-4b0a-8007-ebc267875bd4"
version = "1.11.0"

[[deps.StructUtils]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "79529b493a44927dd5b13dde1c7ce957c2d049e4"
uuid = "ec057cc2-7a8d-4b58-b3b3-92acb9f63b42"
version = "2.6.0"

    [deps.StructUtils.extensions]
    StructUtilsMeasurementsExt = ["Measurements"]
    StructUtilsTablesExt = ["Tables"]

    [deps.StructUtils.weakdeps]
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    Tables = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.8.3+2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "f2c1efbc8f3a609aadf318094f8fc5204bdaf344"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.12.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.TimerOutputs]]
deps = ["ExprTools", "Printf"]
git-tree-sha1 = "3748bd928e68c7c346b52125cf41fff0de6937d0"
uuid = "a759f4b9-e2f1-59dc-863e-4aeb61b1ea8f"
version = "0.5.29"

    [deps.TimerOutputs.extensions]
    FlameGraphsExt = "FlameGraphs"

    [deps.TimerOutputs.weakdeps]
    FlameGraphs = "08572546-2f56-4bcf-ba4e-bab62c3a3f89"

[[deps.Tracy]]
deps = ["ExprTools", "LibTracyClient_jll", "Libdl"]
git-tree-sha1 = "73e3ff50fd3990874c59fef0f35d10644a1487bc"
uuid = "e689c965-62c8-4b79-b2c5-8359227902fd"
version = "0.1.6"

    [deps.Tracy.extensions]
    TracyProfilerExt = "TracyProfiler_jll"

    [deps.Tracy.weakdeps]
    TracyProfiler_jll = "0c351ed6-8a68-550e-8b79-de6f926da83c"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.Tricks]]
git-tree-sha1 = "311349fd1c93a31f783f977a71e8b062a57d4101"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.13"

[[deps.URIs]]
git-tree-sha1 = "bef26fb046d031353ef97a82e3fdb6afe7f21b1a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.6.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.UnsafeAtomics]]
git-tree-sha1 = "b13c4edda90890e5b04ba24e20a310fbe6f249ff"
uuid = "013be700-e6cd-48c3-b4a1-df204f14c38f"
version = "0.3.0"
weakdeps = ["LLVM"]

    [deps.UnsafeAtomics.extensions]
    UnsafeAtomicsLLVM = ["LLVM"]

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "80d3930c6347cfce7ccf96bd3bafdf079d9c0390"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.9+0"

[[deps.Xorg_libpciaccess_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "4909eb8f1cbf6bd4b1c30dd18b2ead9019ef2fad"
uuid = "a65dc6b1-eb27-53a1-bb3e-dea574b5389e"
version = "0.18.1+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.3.1+2"

[[deps.demumble_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6498e3581023f8e530f34760d18f75a69e3a4ea8"
uuid = "1e29f10c-031c-5a83-9565-69cddfc27673"
version = "1.3.0+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.15.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.64.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.7.0+0"
"""

# ╔═╡ Cell order:
# ╟─89cfbbb0-c3a7-11f0-bea8-6b8a0e78862d
# ╟─8e1d4a42-698d-469e-8c8b-b25ac806455e
# ╟─80e60e94-0309-4513-a5af-ebce2738be11
# ╟─87b15eed-0ddd-4814-98cf-5f7c538eeaf6
# ╟─4630c192-5783-4cb0-addf-09ef0bc7d6be
# ╟─a3528c53-1163-456e-90f1-525119cdef4b
# ╟─243d79be-f55c-4388-8f65-eecce19aefea
# ╟─eef717ab-ae1f-43ff-a929-65b511d47167
# ╟─a7d672cc-3f55-496b-80c4-76e597a16bc1
# ╠═abb9340f-167e-4b2c-bfc7-c9df0ef9319e
# ╟─75f362c6-e69e-4cd1-8af7-6a7b6df06f25
# ╟─4c421cff-464a-41e2-b884-31011d5a07ec
# ╠═d06d4bdb-a4e4-4bfd-9243-1878723d2629
# ╠═326db900-7214-4121-aee5-ada44cc749f2
# ╟─5ae8f51d-ad92-4862-8980-5ae5ed7b0be3
# ╠═368b603a-198c-4a4d-a14e-98a3e270e33b
# ╟─a0758565-57dd-4d51-bd63-97b993b45617
# ╠═33939427-62ac-4da4-8ed9-09251adb3063
# ╟─50045b20-4134-424f-aa73-84ea8161d292
# ╠═6ab07549-0166-4cc6-ae60-fa63b0d84602
# ╟─5dc820bf-49c8-4bfe-9189-7d61ba503754
# ╠═2f3cee5a-8c14-481d-83d8-3a6e080e5929
# ╟─d7a0b969-459e-4fb1-be89-c972169e8152
# ╠═695a10b8-63cb-4e29-a3bc-8852c30710b0
# ╟─1ea1e950-04f9-4a21-b4a9-6b68aaf4e08e
# ╟─a571ead2-d002-4c35-a1c3-af3461008196
# ╟─44875521-8ed5-4c84-b0ad-24238df0ca30
# ╟─ad6a2913-f3e6-4a88-b09b-deae7f750629
# ╟─78c3e3da-c714-452d-b247-7eb956e2c530
# ╟─3ea6c5ed-defb-4ff0-9dea-a89b6f1bdf44
# ╟─4a8c7fc7-b6c9-4f65-912b-47caaf42a02e
# ╟─48be9851-9dd6-4206-84aa-b9b6cd4529f3
# ╟─88b0d3fc-cdae-4704-b24a-f847509123ae
# ╟─463bb8c3-7b1c-443d-9a70-44c2ff5623f6
# ╟─2b17c40c-f312-420a-8ce7-90b41a9925c4
# ╠═c3229e00-5d23-4986-994f-1d19911d9a03
# ╟─0da26bb1-6908-46ad-b608-e4a2dbfd7b39
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
