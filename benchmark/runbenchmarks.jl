CASES = [
    (Float64, "pglib_opf_case3_lmbd"),
    (Float64, "pglib_opf_case1803_snem"),
    (Float64, "pglib_opf_case118_ieee"),
    (Float64, "pglib_opf_case1888_rte"),
    (Float64, "pglib_opf_case13659_pegase"),
    (Float64, "pglib_opf_case1354_pegase"),
    (Float64, "pglib_opf_case10000_goc"),
    (Float64, "pglib_opf_case10192_epigrids"),
    (Float64, "pglib_opf_case10480_goc"),
    (Float64, "pglib_opf_case14_ieee"),
    (Float64, "pglib_opf_case162_ieee_dtc"),
    (Float64, "pglib_opf_case179_goc"),
    (Float64, "pglib_opf_case19402_goc"),
    (Float64, "pglib_opf_case1951_rte"),
    (Float64, "pglib_opf_case197_snem"),
    (Float64, "pglib_opf_case2000_goc"),
    (Float64, "pglib_opf_case200_activ"),
    (Float64, "pglib_opf_case20758_epigrids"),
    (Float64, "pglib_opf_case2312_goc"),
    (Float64, "pglib_opf_case2383wp_k"),
    (Float64, "pglib_opf_case240_pserc"),
    (Float64, "pglib_opf_case24464_goc"),
    (Float64, "pglib_opf_case24_ieee_rts"),
    (Float64, "pglib_opf_case2736sp_k"),
    (Float64, "pglib_opf_case2737sop_k"),
    (Float64, "pglib_opf_case2742_goc"),
    (Float64, "pglib_opf_case2746wop_k"),
    (Float64, "pglib_opf_case2746wp_k"),
    (Float64, "pglib_opf_case2848_rte"),
    (Float64, "pglib_opf_case2853_sdet"),
    (Float64, "pglib_opf_case2868_rte"),
    (Float64, "pglib_opf_case2869_pegase"),
    (Float64, "pglib_opf_case30000_goc"),
    (Float64, "pglib_opf_case300_ieee"),
    (Float64, "pglib_opf_case3012wp_k"),
    (Float64, "pglib_opf_case3022_goc"),
    (Float64, "pglib_opf_case30_as"),
    (Float64, "pglib_opf_case30_ieee"),
    (Float64, "pglib_opf_case3120sp_k"),
    (Float64, "pglib_opf_case3375wp_k"),
    (Float64, "pglib_opf_case3970_goc"),
    (Float64, "pglib_opf_case39_epri"),
    (Float64, "pglib_opf_case4020_goc"),
    (Float64, "pglib_opf_case4601_goc"),
    (Float64, "pglib_opf_case4619_goc"),
    (Float64, "pglib_opf_case4661_sdet"),
    (Float64, "pglib_opf_case4837_goc"),
    (Float64, "pglib_opf_case4917_goc"),
    (Float64, "pglib_opf_case500_goc"),
    (Float64, "pglib_opf_case5658_epigrids"),
    (Float64, "pglib_opf_case57_ieee"),
    (Float64, "pglib_opf_case588_sdet"),
    (Float64, "pglib_opf_case5_pjm"),
    (Float64, "pglib_opf_case60_c"),
    (Float64, "pglib_opf_case6468_rte"),
    (Float64, "pglib_opf_case6470_rte"),
    (Float64, "pglib_opf_case6495_rte"),
    (Float64, "pglib_opf_case6515_rte"),
    (Float64, "pglib_opf_case7336_epigrids"),
    (Float64, "pglib_opf_case73_ieee_rts"),
    (Float64, "pglib_opf_case78484_epigrids"),
    (Float64, "pglib_opf_case793_goc"),
    (Float64, "pglib_opf_case8387_pegase"),
    (Float64, "pglib_opf_case89_pegase"),
    (Float64, "pglib_opf_case9241_pegase"),
    (Float64, "pglib_opf_case9591_goc"),
]

using Pkg

Pkg.activate(@__DIR__)
Pkg.develop(path=dirname(@__DIR__))

using ExaPowerIO, BenchmarkTools, PowerModels, PGLib, Profile, PProf, Logging, JLD2

PowerModels.silence()

NUM_SAMPLES = 10
for (i, arg) in enumerate(ARGS)
    if arg == "--num-samples" || arg == "-n"
        global NUM_SAMPLES
        NUM_SAMPLES = ARGS[i+1]
        break
    end
end
COMPARE_PM = "--compare-pm" in ARGS
COMPARE_JLD2 = "--compare-jld2" in ARGS
PROFILE = "--profile" in ARGS
@info """
Running benchmarks with settings:
num-samples: $NUM_SAMPLES
compare to PowerModels: $COMPARE_PM
compare to JLD2: $COMPARE_JLD2
output pprof file: $PROFILE
"""

datadir = "../data/"

function run_exapower!()
    data = Vector{NamedTuple}(undef, length(CASES))
    for (i, (type, dataset)) in enumerate(CASES)
        data[i] = ExaPowerIO.parse_pglib(type, Vector, dataset; out_type=NamedTuple)
    end
    data
end

function run_jld2()
    for (_, dataset) in CASES
        JLD2.load(joinpath(datadir, dataset * ".jld2"))
    end
end

function run_pm()
    for (_, dataset) in CASES
        path = joinpath(PGLib.PGLib_opf, dataset * ".m")
        pm_output = PowerModels.parse_file(path)
        PowerModels.standardize_cost_terms!(pm_output, order = 2)
        PowerModels.calc_thermal_limits!(pm_output)
    end
end

data = []
Profile.clear()

@info "Running ExaPowerIO:"
global_logger(ConsoleLogger(stderr, Logging.Warn))
if PROFILE
    @btime (global output = @profile run_exapower!()) teardown = (global data = output)
else
    @btime (global output = run_exapower!()) teardown = (global data = output)
end
@info ("hi", length(data))
global_logger(ConsoleLogger(stderr, Logging.Info))

if COMPARE_JLD2
    for (i, (type, dataset)) in enumerate(CASES)
        JLD2.save(joinpath(datadir, dataset * ".jld2"), Dict("data" => data[i]))
    end
    @info "Running JLD2:"
    @btime run_jld2()
end

if COMPARE_PM
    @info "Running PowerModels:"
    @btime run_pm()
end
