up = true
pressed = false

function get_health(normalized)
    hearts = memory.readbyte(tonumber("0x66F"))
    partial = memory.readbyte(tonumber("0x670"))

    filled_hearts = bit.rshift(bit.lshift(hearts, 4), 4) - 32
    num_heart_containers = bit.rshift(hearts, 4) + 1

    partial_filled = 0
    if partial == 0 then
        partial_filled = 0
    elseif partial < tonumber("0x7F") then
        partial_filled = 0.5
    else
        partial_filled = 1.0
    end

    total_health = filled_hearts + partial_filled

    normalized_health = total_health / num_heart_containers

    if normalized then
        return normalized_health
    else
        return total_health
    end
end

while true do 
    -- Print input from player 1
    print(joypad.getdown(1))

    xPos = memory.readbyte(tonumber("0x70"))
    yPos = memory.readbyte(tonumber("0x84"))

    -- print(get_health())
    dead = get_health() == 0

    if dead then
        pressed = not pressed
    end

    if yPos < 100 and up then
        up = false
    end
    if yPos > 150 and not up then
        up = true
    end

    my_input = {up=up, down=not up, start=pressed}
    print(my_input)
    joypad.write(1, my_input)

    gui.text(0, 20, "(" .. xPos .. ", " .. yPos .. ")")
    -- gui.text(0, 50, yPos)
    -- joypad.write(1, {left=true})
    emu.frameadvance()
end