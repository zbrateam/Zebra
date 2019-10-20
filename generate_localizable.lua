local f = io.open('strings_easy_to_edit.txt', 'r')
for line in f:lines() do
    if line == '' or string.match(line, '%/%/.*') then
        print(line)
    else
        local s = string.match(line, '%s*(.*)')
        print('"'..s..'" = "'..s..'";')
    end
end
