# Use this script to rebuild the tutorial posts.

using Literate

files = Dict(
    # "2021-11-02-tutorial-multi-jdf.jl" => "Finding multiple feasible solutions",
    "2023-07-15-gams-blog.jl" => "JuMP, GAMS, and the IJKLM model",
)

output_dir = joinpath(@__DIR__, "..", "..", "_posts")
for (file, title) in files
    Literate.markdown(
        file,
        output_dir;
        execute  = true,
        flavor = Literate.CommonMarkFlavor(),
    )
    filename = joinpath(output_dir, replace(file, ".jl" => ".md"))
    content = """
    ---
    layout: post
    title: "$(title)"
    date: $(file[1:10])
    categories: [tutorials]
    ---
    """ * read(filename, String)
    write(filename, content)
end

