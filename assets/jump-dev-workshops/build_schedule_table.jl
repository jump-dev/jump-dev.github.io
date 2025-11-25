import TOML

get_key(day, time) = replace("$(day):$time", ":" => "_")

function print_table(io, data, year)
    talks = data["talks"]
    day_names = data["days"]
    indices = split.([k for k in keys(talks)], "_")
    days = sort(unique(first.(indices)))
    times = sort(unique([join(i[2:3], ":") for i in indices]))
    println(io, """<table>\n<tr>\n  <th></th>""")
    for day in days
        d = get(day_names, parse(Int, day), day)
        println(io, "  <th><b>$d</b></th>")
    end
    println(io, "</tr>")
    for time in times
        println(io, "<tr>")
        println(io, """  <td class="talk-table">$time&nbsp;</td>""")
        for day in days
            content = ""
            item = get(talks, get_key(day, time), nothing)
            talk_type = ""
            if item !== nothing
                if haskey(item, "title")
                    content *= """<div class="talk-title">$(item["title"])</div>"""
                end
                if haskey(item, "speaker")
                    content *= """<div class="talk-speaker">$(item["speaker"])</div>"""
                end
                if haskey(item, "type")
                    talk_type = " talk-" * item["type"]
                end
                if haskey(item, "slides")
                    content *= """[<a href="/assets/jump-dev-workshops/$year/$(item["slides"])">slides</a>]"""
                end
                if haskey(item, "url")
                    content *= """[<a href="$(item["url"])">video</a>]"""
                end
            end
            class = "talk-table$talk_type"
            println(io, """  <td class="$class">""", content, "</td>")
        end
        println(io, "</tr>")
    end
    println(io, "</table>&nbsp;")
    return
end

function build_schedule(year::String)
    root = dirname(dirname(@__DIR__))
    data = TOML.parsefile(joinpath(@__DIR__, year, "schedule.toml"))
    filename = joinpath(root, "_includes", "jump-dev-$year-schedule.html")
    open(filename, "w") do io
        print_table(io, data, year)
    end
    return
end

if !isempty(ARGS)
    build_schedule(ARGS[1])
end

