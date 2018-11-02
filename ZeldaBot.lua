up = true
pressed = false
dead = false

frame_index = 0
--[[
    Possible values in the search string
    a = a button
    b = b button
    u = up button
    d = down button
    l = left button
    r = right button
    s = start
    e = select
]]
search_string = ""

function get_health(normalized)
    hearts = memory.readbyte(tonumber("0x66F"))
    partial = memory.readbyte(tonumber("0x670"))

    -- Low Nibble = how many hearts are filled. High Nibble = Number of heart containers - 1
    filled_hearts = bit.rshift(bit.lshift(hearts, 4), 4) - 32
    num_heart_containers = bit.rshift(hearts, 4) + 1

    if partial == 0 then
        partial_filled = 0
    elseif partial < tonumber("0x7F") then
        partial_filled = 0.5
    else
        partial_filled = 1.0
    end

    total_health = filled_hearts + partial_filled

    normalized_health = total_health / num_heart_containers

    -- If normalized isn't specified it is passed in as 'nil', which evaluates to false
    if normalized then
        return normalized_health
    else
        return total_health
    end
end

function generate_random_string(length)
    search_string = ""
    valid_options = "abudlr"
    for i=1,length do
        r_index = math.random(1, string.len(valid_options))
        search_string = search_string .. string.rep(string.sub(valid_options, r_index, r_index), math.random(1, 50))
    end
    print(search_string)
end

generate_random_string(100)

while not dead do

    -- Print input from player 1

    xPos = memory.readbyte(tonumber("0x70"))
    yPos = memory.readbyte(tonumber("0x84"))
    
    -- gui.text(0, 20, "(" .. xPos .. ", " .. yPos .. ")")
    
    dead = get_health() == 0

    -- if dead then
    --    pressed = not pressed
    -- end

    curr = string.sub(search_string, frame_index, frame_index)
    gui.text(0, 20, "Selected Button: " .. curr)
    
    my_input = {
        a = curr == 'a',
        b = curr == 'b',
        left = curr == 'l',
        right = curr == 'r',
        up = curr == 'u',
        down = curr == 'd',
        start = curr == 's' or pressed,
        select = curr == 'e'
    }

    frame_index = frame_index + 1
    if frame_index > string.len(search_string) then
        frame_index = 1
        generate_random_string(100)
    end

    -- print(my_input)
    joypad.write(1, my_input)

    
    emu.frameadvance()
end