# User Documentation
ExaPowerIO exports 1 function:

```@docs
ExaPowerIO.parse_matpower
```

```@docs
ExaPowerIO.PowerData
ExaPowerIO.BusData
ExaPowerIO.GenData
ExaPowerIO.BranchData
ExaPowerIO.ArcData
ExaPowerIO.StorageData
```

### Example Usage

```@meta
# otherwise we get "Downloading artifact ..." in the output and doctests fail
DocTestSetup = quote
    using ExaPowerIO
    result = parse_matpower("pglib_opf_case3_lmbd.m"; library=:pglib);
end

DocTestTeardown = quote
    # restore settings, release resources, ...
end
```

```jldoctest
julia> using ExaPowerIO

julia> result = parse_matpower("pglib_opf_case3_lmbd.m"; library=:pglib);

julia> result.version
"2"

julia> result.baseMVA
100.0

julia> result.bus
3-element Vector{BusData{Float64}}:
 BusData{Float64}(1, 3, 1.1, 0.4, 0.0, 0.0, 1, 1.0, 0.0, 240.0, 1, 1.1, 0.9)
 BusData{Float64}(2, 2, 1.1, 0.4, 0.0, 0.0, 1, 1.0, 0.0, 240.0, 1, 1.1, 0.9)
 BusData{Float64}(3, 2, 0.95, 0.5, 0.0, 0.0, 1, 1.0, 0.0, 240.0, 1, 1.1, 0.9)

julia> result.gen
3-element Vector{GenData{Float64}}:
 GenData{Float64}(1, 10.0, 0.0, 10.0, -10.0, 1.0, 100.0, 1, 20.0, 0.0, 1, true, 0.0, 0.0, 3, (1100.0, 500.0, 0.0))
 GenData{Float64}(2, 10.0, 0.0, 10.0, -10.0, 1.0, 100.0, 1, 20.0, 0.0, 2, true, 0.0, 0.0, 3, (850.0000000000001, 120.0, 0.0))
 GenData{Float64}(3, 0.0, 0.0, 10.0, -10.0, 1.0, 100.0, 1, 0.0, 0.0, 3, true, 0.0, 0.0, 3, (0.0, 0.0, 0.0))

julia> result.branch
3-element Vector{BranchData{Float64}}:
 BranchData{Float64}(1, 3, 0.065, 0.62, 0.225, 0.225, 0.0, 0.0, 90.0, 90.0, 90.0, 1.0, 0.0, 1, -0.5235987755982988, 0.5235987755982988, 1, 4, -0.16725635252492763, 1.5953682856223865, -0.16725635252492763, 1.5953682856223865, 0.16725635252492763, -1.3703682856223864, 0.16725635252492763, -1.3703682856223864)
 BranchData{Float64}(3, 2, 0.025, 0.75, 0.35, 0.35, 0.0, 0.0, 0.5, 0.5, 0.5, 1.0, 0.0, 1, -0.5235987755982988, 0.5235987755982988, 2, 5, -0.044395116537180916, 1.3318534961154274, -0.044395116537180916, 1.3318534961154274, 0.044395116537180916, -0.9818534961154274, 0.044395116537180916, -0.9818534961154274)
 BranchData{Float64}(1, 2, 0.042, 0.9, 0.15, 0.15, 0.0, 0.0, 90.0, 90.0, 90.0, 1.0, 0.0, 1, -0.5235987755982988, 0.5235987755982988, 3, 6, -0.05173917542536994, 1.1086966162579273, -0.05173917542536994, 1.1086966162579273, 0.05173917542536994, -0.9586966162579272, 0.05173917542536994, -0.9586966162579272)

julia> result.storage
StorageData{Float64}[]


```
