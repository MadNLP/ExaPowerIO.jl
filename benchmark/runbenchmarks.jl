using ExaPowerIO, BenchmarkTools, PowerModels, PGLib, Profile, PProf, Logging, JLD2

PowerModels.silence()

NUM_SAMPLES = 10
for (i, arg) in enumerate(ARGS)
    if arg == "--num-samples" || arg == "-n"
        global NUM_SAMPLES
        NUM_SAMPLES = parse(Int, ARGS[i+1])
        break
    end
end
COMPARE_PM = "--compare-pm" in ARGS
COMPARE_JLD2 = "--compare-jld2" in ARGS
PROFILE = "--profile" in ARGS
CASES = PGLib.find_pglib_case("")
@info """
Running benchmarks with settings:
num-samples: $NUM_SAMPLES
compare to PowerModels: $COMPARE_PM
compare to JLD2: $COMPARE_JLD2
output pprof file: $(PROFILE)
"""

datadir = "../data/"

function run_exapower!()
    data = Vector{ExaPowerIO.PowerData}(undef, length(CASES))
    for (i, dataset) in enumerate(CASES)
        data[i] = ExaPowerIO.parse_matpower(dataset; library=:pglib)
    end
    data
end

function run_jld2()
    for dataset in CASES
        JLD2.load(joinpath(datadir, dataset[begin:end-2] * ".jld2"))
    end
end

function run_pm()
    for dataset in CASES
        path = joinpath(PGLib.PGLib_opf, dataset[begin:end-2] * ".m")
        pm_output = PowerModels.parse_file(path)
        PowerModels.standardize_cost_terms!(pm_output, order = 2)
        PowerModels.calc_thermal_limits!(pm_output)
    end
end

@info "Precompiling"
global_logger(ConsoleLogger(stderr, Logging.Warn))  # Consistent logging level

data = run_exapower!()
COMPARE_JLD2 && run_jld2()
COMPARE_PM && run_pm()

GC.gc()
Profile.clear()
global_logger(ConsoleLogger(stderr, Logging.Info))

@info "Running ExaPowerIO:"
global_logger(ConsoleLogger(stderr, Logging.Warn))
if PROFILE
    @profile run_exapower!()
    pprof()
else
    display(@benchmark run_exapower!())
end
global_logger(ConsoleLogger(stderr, Logging.Info))

if COMPARE_JLD2
    for (i, dataset) in enumerate(CASES)
        JLD2.save(joinpath(datadir, dataset[begin:end-2] * ".jld2"), Dict("data" => data[i]))
    end
    @info "Running JLD2:"
    display(@benchmark run_jld2())
end

if COMPARE_PM
    @info "Running PowerModels:"
    display(@benchmark run_pm())
end
