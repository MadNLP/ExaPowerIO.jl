using Pkg
Pkg.activate(@__DIR__)
Pkg.develop(path=dirname(@__DIR__))


using Documenter, ExaPowerIO, Literate

const _PAGES = [
    "Introduction" => "index.md",
    "Developer Docs" => "dev.md",
    "User Docs" => "user.md",
]

makedocs(;
    sitename = "ExaModelsPower.jl",
    modules = [ExaPowerIO],
    remotes = nothing,
    authors = "Archim Jhunjhunwala",
    format = Documenter.HTML(
        assets = ["assets/citations.css"],
        prettyurls = true,
        sidebar_sitename = true,
        collapselevel = 1,
        repolink = "https://github.com/MadNLP/ExaPowerIO.jl/tree/main",
        edit_link = "main"
    ),
    pages = _PAGES,
    clean = false
)

# deploydocs(repo = "github.com/exanauts/ExaPowerIO.jl.git"; push_preview = true)
