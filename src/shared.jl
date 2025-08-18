const NULL_VIEW::SubString{String} = SubString("", 1, 0)
const PRINTABLE_ASCII::Int64 = 256
is_end(c::Char)::Bool = isspace(c) || c in "=;[]{}%,"
const ENDS::NTuple{256, Bool} = ntuple(i -> is_end(Char(i)), PRINTABLE_ASCII)

import Base.isspace
@inline isspace(c::UInt8)::Bool = c == UInt8(' ') || UInt8('\t') <= c <= UInt8('\r')

struct WordedString
    s :: SubString{String}
    len :: Int
end

WordedString(s::S) where S<:AbstractString = @views WordedString(s[begin:end], s[begin:end].ncodeunits)

import Base.iterate
iterate(ws :: WordedString) = iterate(ws, 1)
@inbounds function iterate(ws :: WordedString, start :: Int) :: Union{Nothing, Tuple{UnitRange{Int64}, Int}}
    if start > ws.len
        return nothing
    end
    left = start
    while left <= ws.len && isspace(@inbounds ws.s[left])
        left += 1
    end
    if left > ws.len || @inbounds ws.s[left] == '%'
        return nothing
    end
    right = left
    while right <= ws.len && !ENDS[Int8(@inbounds ws.s[right])]
        right += 1
    end
    # right is non-inclusive
    if ENDS[Int8(@inbounds ws.s[left])]
        right += 1
    end
    (left:right-1, right)
end

struct WordedStringUnchecked
    s :: SubString{String}
    len :: Int
end

WordedStringUnchecked(s::S) where S<:AbstractString = @views WordedStringUnchecked(s[begin:end], s[begin:end].ncodeunits)

import Base.iterate
iterate(ws :: WordedStringUnchecked) = iterate(ws, 1)
@inbounds function iterate(ws :: WordedStringUnchecked, start :: Int) :: Union{Nothing, Tuple{UnitRange{Int64}, Int}}
    left = start
    while isspace(codeunit(ws.s, left))
        left += 1
    end
    right = left
    while !ENDS[codeunit(ws.s, right)]
        right += 1
    end
    # right is non-inclusive
    if ENDS[codeunit(ws.s, left)]
        right += 1
    end
    (left:right-1, right)
end
