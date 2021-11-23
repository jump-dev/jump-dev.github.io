The source for tutorials in the `tutorials` directory of `jump-dev.github.io` are in the
same format as those in the JuMP documentation. However, they are not able to be hosted there
for particular reasons, such as relying on commercial solvers.

Tutorials within the JuMP documentation are written in Julia (.jl files)
using formatting required by the [Literate.jl](https://github.com/fredrikekre/Literate.jl)
package, in order to generate Markdown (.md) files for inclusion in the JuMP documentation.

The JuMP documentation has its own customised method for calling Literate
which include integration with the [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl)
package; this is the default mode for Literate.

A generic way of calling Literate is, for instance, 
```
using Literate
Literate.markdown("./tutorials/input_file.jl","./output_dir")
```
which results in a new Markdown file `./output_dir/input_file.md".

For the purposes of the `jump-dev` website, Literate should be set to generate Markdown 
in the CommonMark format using the `flavor` keyword
```
Literate.markdown("./tutorials/input_file.jl","./output_dir"; flavor=Literate.CommonMarkFlavor())
```
the output of which can then be rendered using Jekyll to create the website.

The Jekyll renderer requires a metadata header on blog posts of the form
```
---
layout: post
title: "Finding multiple feasible solutions"
date: 2021-11-02
categories: [tutorials]
permalink: /blog/finding-multiple-feasible-solutions/
---
```
This generates the title. Place the final .md file in the top-level directory `_posts`
and Jekyll will do the rest.