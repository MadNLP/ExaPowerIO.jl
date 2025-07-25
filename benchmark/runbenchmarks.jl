CASES = [
    (Float64, "pglib_opf_case3_lmbd.m"),
    (Float64, "pglib_opf_case1803_snem.m"),
    (Float64, "pglib_opf_case118_ieee.m"),
    (Float64, "pglib_opf_case1888_rte.m"),
    (Float64, "pglib_opf_case13659_pegase.m"),
    (Float64, "pglib_opf_case1354_pegase.m"),
    (Float64, "pglib_opf_case10000_goc.m"),
    (Float64, "pglib_opf_case10192_epigrids.m"),
    (Float64, "pglib_opf_case10480_goc.m"),
    (Float64, "pglib_opf_case14_ieee.m"),
    (Float64, "pglib_opf_case162_ieee_dtc.m"),
    (Float64, "pglib_opf_case179_goc.m"),
    (Float64, "pglib_opf_case19402_goc.m"),
    (Float64, "pglib_opf_case1951_rte.m"),
    (Float64, "pglib_opf_case197_snem.m"),
    (Float64, "pglib_opf_case2000_goc.m"),
    (Float64, "pglib_opf_case200_activ.m"),
    (Float64, "pglib_opf_case20758_epigrids.m"),
    (Float64, "pglib_opf_case2312_goc.m"),
    (Float64, "pglib_opf_case2383wp_k.m"),
    (Float64, "pglib_opf_case240_pserc.m"),
    (Float64, "pglib_opf_case24464_goc.m"),
    (Float64, "pglib_opf_case24_ieee_rts.m"),
    (Float64, "pglib_opf_case2736sp_k.m"),
    (Float64, "pglib_opf_case2737sop_k.m"),
    (Float64, "pglib_opf_case2742_goc.m"),
    (Float64, "pglib_opf_case2746wop_k.m"),
    (Float64, "pglib_opf_case2746wp_k.m"),
    (Float64, "pglib_opf_case2848_rte.m"),
    (Float64, "pglib_opf_case2853_sdet.m"),
    (Float64, "pglib_opf_case2868_rte.m"),
    (Float64, "pglib_opf_case2869_pegase.m"),
    (Float64, "pglib_opf_case30000_goc.m"),
    (Float64, "pglib_opf_case300_ieee.m"),
    (Float64, "pglib_opf_case3012wp_k.m"),
    (Float64, "pglib_opf_case3022_goc.m"),
    (Float64, "pglib_opf_case30_as.m"),
    (Float64, "pglib_opf_case30_ieee.m"),
    (Float64, "pglib_opf_case3120sp_k.m"),
    (Float64, "pglib_opf_case3375wp_k.m"),
    (Float64, "pglib_opf_case3970_goc.m"),
    (Float64, "pglib_opf_case39_epri.m"),
    (Float64, "pglib_opf_case4020_goc.m"),
    (Float64, "pglib_opf_case4601_goc.m"),
    (Float64, "pglib_opf_case4619_goc.m"),
    (Float64, "pglib_opf_case4661_sdet.m"),
    (Float64, "pglib_opf_case4837_goc.m"),
    (Float64, "pglib_opf_case4917_goc.m"),
    (Float64, "pglib_opf_case500_goc.m"),
    (Float64, "pglib_opf_case5658_epigrids.m"),
    (Float64, "pglib_opf_case57_ieee.m"),
    (Float64, "pglib_opf_case588_sdet.m"),
    (Float64, "pglib_opf_case5_pjm.m"),
    (Float64, "pglib_opf_case60_c.m"),
    (Float64, "pglib_opf_case6468_rte.m"),
    (Float64, "pglib_opf_case6470_rte.m"),
    (Float64, "pglib_opf_case6495_rte.m"),
    (Float64, "pglib_opf_case6515_rte.m"),
    (Float64, "pglib_opf_case7336_epigrids.m"),
    (Float64, "pglib_opf_case73_ieee_rts.m"),
    (Float64, "pglib_opf_case78484_epigrids.m"),
    (Float64, "pglib_opf_case793_goc.m"),
    (Float64, "pglib_opf_case8387_pegase.m"),
    (Float64, "pglib_opf_case89_pegase.m"),
    (Float64, "pglib_opf_case9241_pegase.m"),
    (Float64, "pglib_opf_case9591_goc.m"),
]

using Pkg

Pkg.activate(@__DIR__)
Pkg.develop(path=dirname(@__DIR__))

using ExaPowerIO, BenchmarkTools, PowerModels, PGLib, Profile, PProf, Logging

PowerModels.silence()

NUM_SAMPLES = 10
for (i, arg) in enumerate(ARGS)
    if arg == "--num-samples" || arg == "-n"
        global NUM_SAMPLES
        NUM_SAMPLES = ARGS[i+1]
        break
    end
end
COMPARE = "--compare" in ARGS
PROFILE = "--profile" in ARGS
@info "Running benchmarks with num-samples: $NUM_SAMPLES, compare to PowerModels: $COMPARE, profile: $PROFILE"

function run_pm(dataset :: String)
    path = joinpath(PGLib.PGLib_opf, dataset)
    pm_output = PowerModels.parse_file(path)
    PowerModels.standardize_cost_terms!(pm_output, order = 2)
    PowerModels.calc_thermal_limits!(pm_output)
end

datadir = "../data/"
function display_btimed(btimed :: NamedTuple)
    display(btimed[(:time, :bytes, :alloc, :gctime)])
end

if PROFILE
    Profile.clear()
    global_logger(ConsoleLogger(stderr, Logging.Warn))
    @btime begin
        @profile begin
            for (type, dataset) in CASES
                ExaPowerIO.parse_pglib(type, Vector, dataset; out_type=NamedTuple)
            end
        end
    end
    @info "Done!"
    pprof()
else
    for (type, dataset) in CASES
        @info "ExaPowerIO.jl " * dataset
        nt = @btimed ExaPowerIO.parse_pglib(type, Vector, $dataset; out_type=NamedTuple) samples=NUM_SAMPLES
        display_btimed(nt)
        if COMPARE
            @info "PowerModels.jl " * dataset
            nt = @btimed run_pm($dataset) samples=NUM_SAMPLES
            display_btimed(nt)
        end
    end
end
