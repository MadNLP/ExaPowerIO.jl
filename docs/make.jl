using Pkg
Pkg.activate(@__DIR__)
Pkg.develop(path=dirname(@__DIR__))

using Documenter, ExaPowerIO, Literate

const _PAGES = [
    "Introduction" => "index.md",
    "User Docs" => "user.md",
    "Developer Docs" => "dev.md",
]

makedocs(;
    sitename = "ExaPowerIO.jl",
    modules = [ExaPowerIO],
    remotes = nothing,
    authors = "Archim Jhunjhunwala",
    format = Documenter.HTML(
        prettyurls = true,
        sidebar_sitename = true,
        collapselevel = 1,
        repolink = "https://github.com/MadNLP/ExaPowerIO.jl/tree/main",
        edit_link = "main"
    ),
    pages = _PAGES,
    clean = false
)

deploydocs(repo = "github.com/MadNLP/ExaPowerIO.jl.git"; push_preview = true)
