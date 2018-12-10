dead = false
math.randomseed(os.time())
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

local matrix = require('lua-matrix.lua.matrix')

num_inputs = 29
num_hidden = 50
num_outputs = 8 -- Up, Down, Left, Right, A, B, Select, Start
weights1_shape = matrix(num_inputs, num_hidden)
weights2_shape = matrix(num_hidden, num_outputs)
layer1 = matrix(1, num_hidden)
weights1 = matrix.my_random(weights1_shape, 0.001)
weights2 = matrix.my_random(weights2_shape, 0.001)
t = 0

-- Starting states:
bombState = 0
rupeeState = 0
swordState = 0
candleState = 0
bowState = false
arrowState = false
ladderState = false
powerBraceletState = false
raftState = false
whistleState = false
magicalRodState = false
magicBookState = false
boomerangState = false
clockState = false
foodState = false
killedEnemies = 0

triforcePieces = 0
move = 0
moveHistory = {}
screenHistory = {}
curHealth = 0

function calculateFitness()
    sword = memory.readbyte(tonumber("0x0657"))
    bombs = memory.readbyte(tonumber("0x0658"))
    arrow = memory.readbyte(tonumber("0x0659"))
    bow = memory.readbyte(tonumber("0x065A"))
    candle = memory.readbyte(tonumber("0x065B"))
    whistle = memory.readbyte(tonumber("0x065C"))
    food = memory.readbyte(tonumber("0x065D"))
    magicalRod = memory.readbyte(tonumber("0x065F"))
    raft = memory.readbyte(tonumber("0x0660"))
    magicBook = memory.readbyte(tonumber("0x0661"))
    ladder = memory.readbyte(tonumber("0x0663"))
    powerBracelet = memory.readbyte(tonumber("0x0665"))
    clock = memory.readbyte(tonumber("0x066C"))
    rupees = memory.readbyte(tonumber("0x066D"))
    health = get_health()
    triforce = memory.readbyte(tonumber("0x0671"))
    boomerang = memory.readbyte(tonumber("0x0674"))
    xPos = memory.readbyte(tonumber("0x70"))
    yPos = memory.readbyte(tonumber("0x84"))
    
    killed = memory.readbyte(tonumber("0x0627"))

    posFound = false
    index = 1
    fitness = 0

    while not posFound and index <= #moveHistory do
        if moveHistory[index][1] == xPos and moveHistory[index][2] == yPos then
            posFound = true
        end
        index = index + 1
    end
    --[[ 
    
    if posFound then
        fitness = fitness - 1
    else 
        fitness = fitness + 5
        move = move + 1
        if move > 200 then
            move = 1
        end
        moveHistory[move] = {xPos, yPos}
    end
    --]]

    lastMove = {xPos, yPos}
    if health < curHealth then
        fitness = fitness - 50
    end
    curHealth = health

    if sword == 1 and swordState <= 0 then
        swordState = 1
        fitness = fitness + 1000
    elseif sword == 2 and swordState <= 1 then
        swordState = 2
        fitness = fitness + 500
    elseif sword == 3 and swordState <= 2 then
        swordState = 3
        fitness = fitness + 500
    end

    if bombs > bombState then
        fitness = fitness + 20
    end
    bombState = bombs

    if arrow == 1 and arrowState <= 0 then
        arrowState = 1
        fitness = fitness + 150
    elseif arrow == 2 and arrowState <= 1 then
        arrowState = 2
        fitness = fitness + 150
    end

    if bow == 01 and not bowState then
        bowState = true
        fitness = fitness + 500
    end

    if candle == 1 and candleState <= 0 then
        candleState = 1
        fitness = fitness + 500
    elseif candle == 2 and candleState <= 1 then
        candleState = 2
        fitness = fitness + 250
    end

    if whistle == 1 and not whistleState then
        whistleState = true
        fitness = fitness + 500
    end

    if food == 1 and not foodState then
        foodState = true
        fitness = fitness + 250
    end

    if magicalRod == 1 and not magicalRodState then
        magicalRodState = true
        fitness = fitness + 500
    end

    if raft == 1 and not raftState then
        raftState = true
        fitness = fitness + 500
    end

    if magicBook == 1 and not magicBookState then
        magicBookState = true
        fitness = fitness + 500
    end

    if ladder == 1 and not ladderState then
        ladderState = false
        fitness = fitness + 500
    end

    if powerBracelet == 1 and not powerBraceletState then
        powerBraceletState = true
        fitness = fitness + 500
    end

    if clock == 1 and not clockState then
        clockState = true
        fitness = fitness + 250
    end

    if rupees > rupeeState then
        fitness = fitness + 20
    end
    rupeeState = rupees
    if triforce > triforcePieces then
        fitness = fitness + 5000
    end
    triforcePieces = triforce

    if boomerang == 1 and not boomerangState then
        boomerangState = true
        fitness = fitness + 500
    end

    if killed > killedEnemies then 
        fitness = fitness + 100
    end
    killedEnemies = killed

    return fitness

end

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

function generate_inputs(previous)
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
    time_norm = t / 216000
    -- print(time_norm)

    input = {xPos, yPos, map_x, map_y, health, has_sword, enemy1X, enemy1Y, enemy2X, enemy2Y, enemy3X, enemy3Y, enemy4X, enemy4Y, enemy5X, enemy5Y, enemy6X, enemy6Y, time_norm, frame_counter,
             previous[1], previous[2], previous[3], previous[4], previous[5], previous[6], previous[7], previous[8]}
    -- print(input)
    return input
end

function sigmoid(val)
    return 1 / (1 + math.exp(-val))
end

function feedforward(inputs)
    input_matrix = matrix(1, #inputs)
    for i=1, #inputs do
        input_matrix[1][i] = inputs[i]
    end

    layer1 = matrix.replace(matrix.mul(input_matrix, weights1), sigmoid)
    outputs = matrix.replace(matrix.mul(layer1, weights2), sigmoid)

    return outputs
end

function backprop(outputs, fitness)
    -- Error term for output layer
    error = 2 * (sigmoid(fitness) - 0.5)
    d_weights2 = matrix(num_hidden, num_outputs)
    for i=1,#d_weights2 do
        for j=1,#d_weights2[1] do
            d_weights2[i][j] = 0.3 * error * outputs[1][j]
        end
    end

    -- Error term for hidden layer
    d_weights1 = matrix(num_inputs, num_hidden)
    for i=1,#d_weights1 do -- num_inputs
        for j=1,#d_weights1[1] do -- num_hidden
            s = 0
            for k=1,num_hidden do
                s = s + error * weights1[i][k]
            end 
            
            -- I don't think this math is correct. See page 653 of Artificial Intelligence for Games
            error2 = layer1[1][i] * (1 - layer1[1][i]) * s
            d_weights1[i][j] = 0.3 * error2 * layer1[1][i]
        end
    end

    weights2 = weights2 + d_weights2
    weights1 = weights1 + d_weights1
end

function draw_brain(x, y, weights)
    h = #weights
    w = #weights[1]
    gui.line(x, y, x + w + 2, y)
    gui.line(x + w + 2, y, x + w + 2, y + h + 2)
    gui.line(x + w + 2, y + h + 2, x, y + h + 2)
    gui.line(x, y + h + 2, x, y)
    avg_col = 0
    for i=1,h do
        for j=1,w do
            col = weights[i][j] * 255
            avg_col = avg_col + col
            gui.pixel(x + j + 1, y + i + 1, {col, col, col})
        end
    end

    print(avg_col / (w * h))
end

function regenerate_NN()
    layer1 = matrix(1, num_hidden)
    weights1 = matrix.my_random(weights1_shape, 100)
    weights2 = matrix.my_random(weights2_shape, 100)
end

function draw_output(x, y, t)
    h = 20
    for i=1, #t do
        -- print(t[i])
        gui.rect(x + i * 6, y, x + i * 6 + 4, y - t[i] * h, 'white')
    end
end

-- creating savestate
save = savestate.object(1)
savestate.save(save)

last_pos = {0, 0}
move_timer = 0
fitness = 0
previous_fitness = 0
previous_outputs = {0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5}

move_counter = 0

emu.speedmode("turbo")

while true do

    -- Print input from player 1
    game_state = memory.readbyte(tonumber("0x12"))
    if game_state == 11 then game_state = 5 end
    if game_state == 5 then
        xPos = memory.readbyte(tonumber("0x70"))
        yPos = memory.readbyte(tonumber("0x84"))
        if xPos ~= last_pos[1] or yPos ~= last_pos[2] then
            last_pos = {xPos, yPos}
            move_timer = 0
        end

        if move_counter == 0 then
            NN_output = feedforward(generate_inputs(previous_outputs))
            move_counter = math.random(2, 4)
        else
            move_counter = move_counter - 1
        end
        draw_output(170, 45, NN_output[1])

        if t % 100 == 0 then
            print(NN_output[1])
            print()
        end

        max_val = 0
        curr = 0
    
        x = 0
        -- We don't want the AI to press select (or start at this time)
        for i=1,num_outputs-2 do
            previous_outputs[i] = NN_output[1][i]
            x = x + NN_output[1][i]
            --[[
            if NN_output[1][i] > max_val then
                max_val = NN_output[1][i]
                curr = i
            end 
            --]]
        end

        val = math.random() * x
        base = 0
        for i=1,num_outputs-2 do
            if val < base + NN_output[1][i] then
                curr = i
                break
            end
            base = base + NN_output[1][i]
        end
        
    
        my_input = {
            a = curr == 1,
            b = curr == 2,
            left = curr == 3,
            right = curr == 4,
            up = curr == 5,
            down = curr == 6,
            start = curr == 7,
            select = curr == 8
        }
    
        t = t + 1
        move_timer = move_timer + 1
    
        --[[
        for i=1,num_outputs do
            print(i .. ": " .. NN_output[1][i])
        end
        print()
        --]]
        joypad.write(1, my_input)
    
    
        fitness = fitness + calculateFitness()

        gui.text(0, 20, "Selected Button: " .. curr)
        gui.text(0, 30, "Current Fitness: " .. fitness)
        gui.text(0, 40, "Previous Fitness: " .. previous_fitness)
        -- draw_brain(20, 20, weights2)
    end
    
    emu.frameadvance()

    dead = get_health() == 0
    if dead or move_timer > 600 or t > 60 * 60 * 60 then
        if move_timer > 600 then
            fitness = fitness - 10
        end
        previous_fitness = fitness
        backprop(NN_output, fitness)
        savestate.load(save)
        print("LOADED")
        move_timer = 0
        t = 0
        fitness = 0

        -- reset states
        swordState = 0
        candleState = 0
        bowState = false
        arrowState = false
        ladderState = false
        powerBraceletState = false
        raftState = false
        whistleState = false
        magicalRodState = false
        magicBookState = false
        boomerangState = 0
        clockState = false
        foodState = false

        triforcePieces = 0
        moveHistory = {}
        screenHistory = {}
        curHealth = 0
        move = 0
        killedEnemies = 0

        --gui.savescreenshot()
    end
end