# FOR CONVENIENCE, the MATPOWER file spec
# https://matpower.app/manual/matpower/DataFileFormat.html

"""
    struct BusData{T <: Real}
        bus_i :: Int
        type :: Int
        pd :: T
        qd :: T
        gs :: T
        bs :: T
        area :: Int
        vm :: T
        va :: T
        baseKV :: T
        zone :: Int
        vmax :: T
        vmin :: T
    end
"""
struct BusData{T <: Real}
    bus_i :: Int
    type :: Int
    pd :: T
    qd :: T
    gs :: T
    bs :: T
    area :: Int
    vm :: T
    va :: T
    baseKV :: T
    zone :: Int
    vmax :: T
    vmin :: T
end

"""
    struct BranchData{T <: Real}
        f_bus :: Int
        t_bus :: Int
        br_r :: T
        br_x :: T
        b_fr :: T,
        b_to :: T,
        g_fr :: T,
        g_to :: T,
        rate_a ::T
        rate_b :: T
        rate_c :: T
        tap :: T
        shift :: T
        status :: Int
        angmin :: T
        angmax :: T
        f_idx::Int
        t_idx::Int
        c1 :: T
        c2 :: T
        c3 :: T
        c4 :: T
        c5 :: T
        c6 :: T
        c7 :: T
        c8 :: T
    end

f_bus and t_bus are indices into the PowerData.bus Vector, not bus_i values
"""
struct BranchData{T <: Real}
    f_bus :: Int
    t_bus :: Int
    br_r :: T
    br_x :: T
    b_fr :: T
    b_to :: T
    g_fr :: T
    g_to :: T
    rate_a ::T
    rate_b :: T
    rate_c :: T
    tap :: T
    shift :: T
    status :: Int
    angmin :: T
    angmax :: T
    f_idx::Int
    t_idx::Int
    c1 :: T
    c2 :: T
    c3 :: T
    c4 :: T
    c5 :: T
    c6 :: T
    c7 :: T
    c8 :: T
end
function BranchData{T}(
    f_bus::Int,
    t_bus::Int,
    br_r::T,
    br_x::T,
    b_fr::T,
    b_to::T,
    g_fr::T,
    g_to::T,
    rate_a::T,
    rate_b::T,
    rate_c::T,
    tap::T,
    shift::T,
    status::Int,
    angmin::T,
    angmax::T,
    f_idx::Int,
    t_idx::Int
) where {T<:Real}
    x = br_r + im * br_x
    xi = inv(x)
    y = ifelse(isfinite(xi), xi, zero(xi))
    g = real(y)
    b = imag(y)
    if isapprox(tap, T(0.0))
        tap = T(1.0)
    end
    tr = tap * cos(shift)
    ti = tap * sin(shift)
    ttm = tr^2 + ti^2
    c1 = (-g * tr - b * ti) / ttm
    c2 = (-b * tr + g * ti) / ttm
    c3 = (-g * tr + b * ti) / ttm
    c4 = (-b * tr - g * ti) / ttm
    c5 = (g + g_fr) / ttm
    c6 = (b + b_fr) / ttm
    c7 = (g + g_to)
    c8 = (b + b_to)
    BranchData{T}(
        f_bus,
        t_bus,
        br_r,
        br_x,
        b_fr,
        b_to,
        g_fr,
        g_to,
        rate_a,
        rate_b,
        rate_c,
        tap,
        shift,
        status,
        angmin,
        angmax,
        f_idx,
        t_idx,
        c1,
        c2,
        c3,
        c4,
        c5,
        c6,
        c7,
        c8,
    )
end

"""
    struct ArcData{T <: Real}
        bus :: Int
        rate_a :: T
    end
"""
struct ArcData{T <: Real}
    bus :: Int
    rate_a :: T
end

"""
    struct StorageData{T <: Real}
        storage_bus :: Int
        ps :: T
        qs :: T
        energy :: T
        energy_rating :: T
        charge_rating :: T
        discharge_rating :: T
        charge_efficiency :: T
        discharge_efficiency :: T
        thermal_rating :: T
        qmin :: T
        qmax :: T
        r :: T
        x :: T
        p_loss :: T
        q_loss :: T
        status :: Int
    end
"""
struct StorageData{T <: Real}
    storage_bus :: Int
    ps :: T
    qs :: T
    energy :: T
    energy_rating :: T
    charge_rating :: T
    discharge_rating :: T
    charge_efficiency :: T
    discharge_efficiency :: T
    thermal_rating :: T
    qmin :: T
    qmax :: T
    r :: T
    x :: T
    p_loss :: T
    q_loss :: T
    status :: Int
end

"""
    struct GenData{T <: Real}
        bus :: Int
        pg :: T
        qg :: T
        qmax :: T
        qmin :: T
        vg :: T
        mbase :: T
        status :: Int
        pmax :: T
        pmin :: T
        i :: Int
        model_poly :: Bool
        startup :: T
        shutdown :: T
        n :: Int
        c :: NTuple{3, T}
    end

bus is an index into the PowerData.bus Vector, not bus_i values
"""
struct GenData{T <: Real}
    bus :: Int
    pg :: T
    qg :: T
    qmax :: T
    qmin :: T
    vg :: T
    mbase :: T
    status :: Int
    pmax :: T
    pmin :: T
    i :: Int
    model_poly :: Bool
    startup :: T
    shutdown :: T
    n :: Int
    c :: NTuple{3, T}
end

"""
    struct Data{T <: Real}
        version :: String
        baseMVA :: T
        bus :: Vector{BusData{T}}
        gen :: Vector{GenData{T}}
        branch :: Vector{BranchData{T}}
        storage :: Vector{StorageData{T}}
    end
```version```, ```baseMVA```, ```bus```, ```gen```, ```branch```, and ```storage```
all corespond to members of the mpc object created by a matpower file.
Their fields correspond exactly with the columns of the relevant ```mpc``` member.
"""
struct PowerData{
    T <: Real,
    VBusT <: AbstractVector{BusData{T}},
    VGenT <: AbstractVector{GenData{T}},
    VBranchT <: AbstractVector{BranchData{T}},
    VStorageT <: AbstractVector{StorageData{T}},
    VArcT <: AbstractVector{ArcData{T}}
}
    version :: String
    baseMVA :: T
    bus :: VBusT
    gen :: VGenT
    branch :: VBranchT
    arc :: VArcT
    storage :: VStorageT
end

function struct_to_nt(data::PowerData)
    (
        version = data.version,
        baseMVA = data.baseMVA,
        bus = struct_to_nt.(data.bus),
        gen = struct_to_nt.(data.gen),
        branch = struct_to_nt.(data.branch),
        storage = struct_to_nt.(data.storage),
    )
end

const MATPOWER_KEYS :: Vector{String} = ["version", "baseMVA", "areas", "bus", "gencost", "gen", "branch", "storage"];
const NULL_VIEW::SubString{String} = SubString("", 1, 0)
const PRINTABLE_ASCII = 256
is_end(c::Char) = isspace(c) || c in "=;[]%"
const ENDS = ntuple(i -> is_end(Char(i)), PRINTABLE_ASCII)
const KEY_MIN_LEN = 4

struct WordedString
    s :: SubString{String}
    len :: Int
end

@inbounds @views function iter_ws(ws :: WordedString, start :: Int) :: Tuple{SubString{String}, Int}
    if start > ws.len
        return (NULL_VIEW, 0)
    end
    left = start
    while isspace(ws.s[left]) && left <= ws.len
        left += 1
    end
    if left > ws.len || ws.s[left] == '%'
        return (NULL_VIEW, 0)
    end
    right = left
    should_end = c -> ENDS[c]
    while right <= ws.len && !should_end(Int8(ws.s[right]))
        right += 1
    end
    # right is non-inclusive
    if should_end(Int8(ws.s[left]))
        right += 1
    end
    (ws.s[left:right-1], right)
end

macro iter_to_ntuple(n, iter_expr, types)
    iter_sym = gensym("iter")
    state_sym = gensym("state")
    x_syms = [gensym("x") for _ in 1:n]

    body = Expr[]
    push!(body, :($iter_sym = $(esc(iter_expr))))
    push!(body, :($state_sym = iter_ws($iter_sym, 1)))
    
    length(types.args) != n && error("types provided to @iter_to_ntuple had length $(length(types.args)) instead of $n")
    for i in 1:n
        push!(body, :($(x_syms[i]) = parse($(esc(types.args[i])), $state_sym[1])))
        if i < n
            push!(body, :($state_sym = $state_sym[2] == 0 ? (NULL_VIEW, 0) : iter_ws($iter_sym, $state_sym[2])))
        end
    end
    push!(body, Expr(:tuple, x_syms...))

    return Expr(:block, body...)
end

function get_arr_len(lines :: Vector{SubString{String}}, num_lines::Int, start::Int)::Int
    line_ind = start
    while line_ind <= num_lines
        line_ind += 1
        if lines[line_ind][1] == ']'
            return line_ind - start - 1
        end
    end
    error("Array defined on line $start was not closed")
end

@inbounds @inline @views function parse_matpower_inner(::Type{T}, ::Type{V}, fname :: String) where {T<:Real, V<:AbstractVector}
    fstring = read(open(fname), String)
    lines = split(fstring, "\n")
    in_array = false
    cur_key = ""
    bus = BusData{T}[]
    gen = GenData{T}[]
    branch = BranchData{T}[]
    storage = StorageData{T}[]
    num_lines = length(lines)

    row_num = 1
    version = ""
    baseMVA :: T = T(0.0)
    bus_map :: Vector{Int} = []
    bus_offset :: Int = 0
    line_ind = 0
    num_bus = 0
    cur_bus = 1
    for line in lines
        line_len = line.ncodeunits
        line_ind += 1
        line_len != 0 && line[1] == '%' && continue
        if in_array && line_len != 0
            if startswith(line, "];")
                if cur_key == "bus"
                    bus_offset = minimum(b -> b.bus_i, bus) - 1
                    max_bus = maximum(b -> b.bus_i, bus)
                    bus_map = [0 for _ in 1:(max_bus-bus_offset)]
                    for (i, b) in enumerate(bus)
                        bus_map[b.bus_i - bus_offset] = i
                    end
                end
                in_array = false
            elseif cur_key == "bus"
                bus_words = @iter_to_ntuple 13 WordedString(line, line_len) (Int, Int, T, T, T, T, Int, T, T, T, Int, T, T)
                bus[row_num] = BusData(
                    bus_words[1],
                    bus_words[2],
                    bus_words[3] / baseMVA,
                    bus_words[4] / baseMVA,
                    bus_words[5],
                    bus_words[6],
                    bus_words[7],
                    bus_words[8],
                    bus_words[9],
                    bus_words[10],
                    bus_words[11],
                    bus_words[12],
                    bus_words[13],
                )
            elseif cur_key == "gen"
                gen_words = @iter_to_ntuple 10 WordedString(line, line_len) (Int, T, T, T, T, T, T, Int, T, T)
                gen[row_num] = GenData(
                    bus_map[gen_words[1] - bus_offset],
                    gen_words[2] / baseMVA,
                    gen_words[3] / baseMVA,
                    gen_words[4] / baseMVA,
                    gen_words[5] / baseMVA,
                    gen_words[6],
                    gen_words[7],
                    gen_words[8],
                    gen_words[9] / baseMVA,
                    gen_words[10] / baseMVA,
                    row_num,
                    false,
                    T(0),
                    T(0),
                    0,
                    (T(0), T(0), T(0)),
                )
            elseif cur_key == "gencost"
                genc_words = @iter_to_ntuple 7 WordedString(line, line_len) (Int, T, T, Int, T, T, T)
                model_poly = genc_words[1] == 2
                n = genc_words[4]
                normalize_cost = let baseMVA = baseMVA
                    function normalize_cost(i :: Int)
                        c = genc_words[4 + i]
                        return model_poly ? baseMVA ^ (n-i) * c : c
                    end
                end
                gen[row_num] = GenData(
                    gen[row_num].bus,
                    gen[row_num].pg,
                    gen[row_num].qg,
                    gen[row_num].qmax,
                    gen[row_num].qmin,
                    gen[row_num].vg,
                    gen[row_num].mbase,
                    gen[row_num].status,
                    gen[row_num].pmax,
                    gen[row_num].pmin,
                    row_num,
                    model_poly,
                    genc_words[2],
                    genc_words[3],
                    n,
                    ntuple(normalize_cost, 3)
                )
            elseif cur_key == "branch"
                branch_words = @iter_to_ntuple 13 WordedString(line, line_len) (Int, Int, T, T, T, T, T, T, T, T, Int, T, T)
                branch[row_num] = BranchData{T}(
                    bus_map[branch_words[1] - bus_offset],
                    bus_map[branch_words[2] - bus_offset],
                    branch_words[3],
                    branch_words[4],
                    branch_words[5] / T(2.0),
                    branch_words[5] / T(2.0),
                    T(0.0),
                    T(0.0),
                    branch_words[6] / baseMVA,
                    branch_words[7] / baseMVA,
                    branch_words[8] / baseMVA,
                    branch_words[9],
                    (branch_words[10]) / T(180.0) * T(pi),
                    branch_words[11],
                    branch_words[12] / T(180.0) * T(pi),
                    branch_words[13] / T(180.0) * T(pi),
                    cur_bus,
                    cur_bus + num_bus
                )
                cur_bus += 1
            elseif cur_key == "storage"
                storage_words = @iter_to_ntuple 17 WordedString(line, line_len) (Int, T, T, T, T, T, T, T, T, T, T, T, T, T, T, T, Int)
                storage[row_num] = StorageData(
                    storage_words[1],
                    storage_words[2],
                    storage_words[3],
                    storage_words[4],
                    storage_words[5],
                    storage_words[6],
                    storage_words[7],
                    storage_words[8],
                    storage_words[9],
                    storage_words[10],
                    storage_words[11],
                    storage_words[12],
                    storage_words[13],
                    storage_words[14],
                    storage_words[15],
                    storage_words[16],
                    storage_words[17],
                )
            end
            if in_array
                row_num += 1
            end
        elseif !startswith(line, "function") && line_len > 0
            cur_key = ""
            for key in MATPOWER_KEYS
                full_name = "mpc.$key"
                if startswith(line, full_name)
                    cur_key = key
                    break
                end
            end

            if cur_key == ""
                error("Error parsing data. Invalid variable assignment on line $(line_ind).")
            end
            if cur_key == "version"
                raw_data = split(line)[3]
                version = String(raw_data[2:raw_data.ncodeunits-2])
            elseif cur_key == "baseMVA"
                word = split(line)[3]
                baseMVA = parse(T, word[1:length(word)-1]) :: T
            else
                arr_len = get_arr_len(lines, num_lines, line_ind)
                if cur_key == "bus"
                    bus = V{BusData{T}}(undef, arr_len)
                    num_bus = arr_len
                elseif cur_key == "gen"
                    gen = V{GenData{T}}(undef, arr_len)
                elseif cur_key == "branch"
                    branch = V{BranchData{T}}(undef, arr_len)
                elseif cur_key == "storage"
                    storage = V{StorageData{T}}(undef, arr_len)
                end
                in_array = true
                row_num = 1
            end
        end
    end

    has_gen = [false for _ in 1:length(bus)]
    for gen in gen
        if gen.status == 1
            has_gen[gen.bus] = true
        end
    end
    for (i, b) in enumerate(bus)
        if has_gen[i] && b.type == 1
            bus[i] = BusData(
                b.bus_i,
                2,
                b.pd,
                b.qd,
                b.gs,
                b.bs,
                b.area,
                b.vm,
                b.va,
                b.baseKV,
                b.zone,
                b.vmax,
                b.vmin
            )
        elseif !has_gen[i] && b.type == 2
            bus[i] = BusData(
                b.bus_i,
                1,
                b.pd,
                b.qd,
                b.gs,
                b.bs,
                b.area,
                b.vm,
                b.va,
                b.baseKV,
                b.zone,
                b.vmax,
                b.vmin
            )
        end
    end

    num_branch = length(branch)
    arc = V{ArcData{T}}(undef, num_branch * 2)
    for (i, b) in enumerate(branch)
        arc[i] = ArcData(i, b.rate_a)
        arc[i+num_branch] = ArcData(i, b.rate_a)
    end

    return PowerData(version, baseMVA, bus, gen, branch, arc, storage)
end
