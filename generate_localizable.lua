local input = assert(io.open('strings_easy_to_edit.txt', 'r'))
local output = assert(io.open('Zebra/Base.lproj/Localizable.strings', 'w'))
for line in input:lines() do
    if line == '' or string.match(line, '%/%/.*') then
        output:write(line)
    else
        local s = string.match(line, '%s*(.*)')
        output:write('"'..s..'" = "'..s..'";')
    end
    output:write('\n')
end

input:close()
output:close()
