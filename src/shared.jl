const NULL_VIEW::SubString{String} = SubString("", 1, 0)
const PRINTABLE_ASCII = 256
is_end(c::Char) = isspace(c) || c in "=;[]{}%,"
const ENDS = ntuple(i -> is_end(Char(i)), PRINTABLE_ASCII)

struct WordedString
    s :: SubString{String}
    len :: Int
end

import Base.iterate
iterate(ws :: WordedString) = iterate(ws, 1)
@inbounds @views function iterate(ws :: WordedString, start :: Int) :: Union{Nothing, Tuple{SubString{String}, Int}}
    if start > ws.len
        return nothing
    end
    left = start
    while left <= ws.len && isspace(ws.s[left])
        left += 1
    end
    if left > ws.len || ws.s[left] == '%'
        return nothing
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
