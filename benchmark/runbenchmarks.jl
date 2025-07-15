using Pkg

Pkg.activate(@__DIR__)
Pkg.develop(path=dirname(@__DIR__))

using ExaPowerIO, BenchmarkTools, PowerModels, PGLib

PowerModels.silence()
ExaPowerIO.silence()

NUM_SAMPLES = 10
for (i, arg) in enumerate(ARGS)
    if arg == "--num-samples"
        global NUM_SAMPLES
        NUM_SAMPLES = ARGS[i+1]
        break
    end
end
COMPARE = "--compare" in ARGS
@info "Running benchmarks with num-samples: $NUM_SAMPLES, compare to PowerModels: $COMPARE"

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
    result = @benchmark ExaPowerIO.parse_pglib($type, $dataset, $datadir; out_type=NamedTuple) samples=NUM_SAMPLES
    display(result)
    if COMPARE
        @info "PowerModels.jl " * dataset
        result = @benchmark run_pm($dataset) samples=NUM_SAMPLES
        display(result)
    end
end
