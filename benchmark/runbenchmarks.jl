using Pkg

Pkg.activate(@__DIR__)
Pkg.develop(path=dirname(@__DIR__))

using ExaPowerIO, BenchmarkTools, PowerModels, PGLib

PowerModels.silence()
ExaPowerIO.silence()

NUM_SAMPLES = 10
for (i, arg) in enumerate(ARGS)
    if arg == "--num-samples" || arg == "-n"
        global NUM_SAMPLES
        NUM_SAMPLES = ARGS[i+1]
        break
    end
end
COMPARE = "--compare" in ARGS
INTERMEDIATE = "--intermediate" in ARGS
@info "Running benchmarks with num-samples: $NUM_SAMPLES, compare to PowerModels: $COMPARE, benchmark intermediate steps: $INTERMEDIATE"

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

function display_btimed(btimed :: NamedTuple)
    display(btimed[(:time, :bytes, :alloc, :gctime)])
end

for (type, dataset) in BENCH_CASES
    if INTERMEDIATE
        @info "ExaPowerIO.jl: parsing $dataset to structs"
        parsed = @btimed ExaPowerIO.parse_pglib($type, $dataset, $datadir; out_type=ExaPowerIO.Data) samples=NUM_SAMPLES
        display_btimed(parsed)
        @info "ExaPowerIO.jl: converting $dataset struct to named tuple"
        result = @btimed ExaPowerIO.struct_to_nt($(parsed.value))
        display_btimed(result)
        @info "ExaPowerIO.jl: total"
        display((
            time = result.time+parsed.time,
            bytes = result.bytes+parsed.bytes,
            alloc = result.alloc+parsed.alloc,
            gctime = result.gctime+parsed.gctime
        ))
    else
        @info "ExaPowerIO.jl " * dataset
        result = @btimed ExaPowerIO.parse_pglib($type, $dataset, $datadir; out_type=NamedTuple) samples=NUM_SAMPLES
        display_btimed(result)
    end
    if COMPARE
        @info "PowerModels.jl " * dataset
        result = @btimed run_pm($dataset) samples=NUM_SAMPLES
        display_btimed(result)
    end
end
