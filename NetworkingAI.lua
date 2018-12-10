local socket = require('socket.core')

s = socket.udp()
s:settimeout(1)

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

    -- If normalized isn't specified it is passed in as 'nil', which evaluates to false
    if normalized then
        return total_health / num_heart_containers
    else
        return total_health
    end
end

function generate_inputs()
    has_sword = memory.readbyte(tonumber("0x0657"))
    xPos = memory.readbyte(tonumber("0x70")) / 256.0
    yPos = memory.readbyte(tonumber("0x84")) / 256.0
    map_x = (memory.readbyte(tonumber("0xEB")) % tonumber("0x10")) / 8
    map_y = math.floor(memory.readbyte(tonumber("0xEB")) / tonumber("0x10")) / 8
    health = get_health(true)
    enemy1X = memory.readbyte(tonumber("0x71")) / 256.0
    enemy1Y = memory.readbyte(tonumber("0x85")) / 256.0
    enemy2X = memory.readbyte(tonumber("0x72")) / 256.0
    enemy2Y = memory.readbyte(tonumber("0x86")) / 256.0
    enemy3X = memory.readbyte(tonumber("0x73")) / 256.0
    enemy3Y = memory.readbyte(tonumber("0x87")) / 256.0
    enemy4X = memory.readbyte(tonumber("0x74")) / 256.0
    enemy4Y = memory.readbyte(tonumber("0x88")) / 256.0
    enemy5X = memory.readbyte(tonumber("0x75")) / 256.0
    enemy5Y = memory.readbyte(tonumber("0x89")) / 256.0
    enemy6X = memory.readbyte(tonumber("0x76")) / 256.0
    enemy6Y = memory.readbyte(tonumber("0x8A")) / 256.0
    frame_counter = memory.readbyte(tonumber("0x12")) / 256.0
    -- time_norm = t / 216000
    -- print(time_norm)

    input = {xPos, yPos, map_x, map_y, health, has_sword, enemy1X, enemy1Y, enemy2X, enemy2Y, enemy3X, enemy3Y, enemy4X, enemy4Y, enemy5X, enemy5Y, enemy6X, enemy6Y, frame_counter} --time_norm, frame_counter}
    -- print(input)
    return input
end

function send_inputs()
    t = generate_inputs()
    str = "" .. t[1]
    for i=2,#t do
        str = str .. "," .. t[i]
    end
    s:sendto(str, '127.0.0.1', 3000)
    resp = s:receive()
    -- print(s:receive())
end

while true do
    send_inputs()
    emu.frameadvance() 
end

s:close()