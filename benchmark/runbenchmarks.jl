using Pkg

Pkg.activate(@__DIR__)
Pkg.develop(path=dirname(@__DIR__))

using ExaPowerIO, BenchmarkTools, PowerModels, PGLib

PowerModels.silence()
ExaPowerIO.silence()

function run_pm(dataset :: String)
    path = joinpath(PGLib.PGLib_opf, dataset)
    pm_output = PowerModels.parse_file(path)
    PowerModels.standardize_cost_terms!(pm_output, order = 2)
    PowerModels.calc_thermal_limits!(pm_output)
end

datadir = "../data/"
BENCH_CASES = [
     (Float16, "pglib_opf_case10000_goc.m"),
     (Float32, "pglib_opf_case10192_epigrids.m"),
     (Float64, "pglib_opf_case20758_epigrids.m"),
]
for (type, dataset) in BENCH_CASES
    @info "ExaPowerIO.jl " * dataset
    @btime ExaPowerIO.parse_pglib($type, $dataset, $datadir; out_type=NamedTuple) samples=10
    @info "PowerModels.jl " * dataset
    @btime run_pm($dataset) samples=10
end
