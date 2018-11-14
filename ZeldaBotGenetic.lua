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
    valid_options = "abudlrs"
    for i=1,length do
        r_index = math.random(1, string.len(valid_options))
        search_string = search_string .. string.rep(string.sub(valid_options, r_index, r_index), math.random(1, 50))
    end
    print(search_string)
    return search_string
end

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
lastMove = {0,0}
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
    fitness = 0;
    if lastMove[1] ~= xPos or lastMove[2] ~= yPos then
        while not posFound and index <= table.getn(moveHistory) do
            if moveHistory[index][1] == xPos and moveHistory[index][2] == yPos then
                posFound = true
            end
            index = index + 1
        end
        if posFound then
            fitness = fitness - 1
        else 
            fitness = fitness + 2
            move = move + 1
            if move > 200 then
                move = 1
            end
            moveHistory[move] = {xPos, yPos}
        end
    end
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
-- creating savestate
save = savestate.object(1)
savestate.save(save)

-- Genetic Search Stuff
generation = 0
while true do 
    subjectInfo = {
        {searchString = "", fitness = 0},
        {searchString = "", fitness = 0},
        {searchString = "", fitness = 0},
        {searchString = "", fitness = 0},
        {searchString = "", fitness = 0},
        {searchString = "", fitness = 0},
        {searchString = "", fitness = 0},
        {searchString = "", fitness = 0}
    }

    for curSubject = 1, 8, 1 do
        search_string = ""
        -- initializing searchString for first generation
        if subjectInfo[curSubject]["searchString"] == ""
        then
            search_string = generate_random_string(500)
            subjectInfo[curSubject]["searchString"] = subjectInfo[curSubject]["searchString"] .. search_string
        end

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
        killedEnemies = 0
        -- play the round
        totalFrames = 0
        frame_index = 0
        dead = false

        -- load savestate
        savestate.load(save)

        while not dead do
            -- Print input from player 1

           
            screenScroll = memory.readbyte(tonumber("0xE8"))
            gui.text(0, 10,"Generation: " .. generation)
            gui.text(0,20,"Subject: " .. curSubject)
            -- print(screenScroll)
            dead = get_health() == 0

            if screenScroll == 255 then
                screenScroll = 0
            end
            gui.text(0, 40, "fitness: " .. subjectInfo[curSubject]["fitness"])

            if not dead and screenScroll then
                curr = string.sub(search_string, frame_index, frame_index)
                gui.text(0, 30, "Selected Button: " .. curr)
                
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
                totalFrames = totalFrames + 1
                if frame_index > string.len(search_string) then
                    frame_index = 1
                    search_string = generate_random_string(500)
                    subjectInfo[curSubject]["searchString"] = subjectInfo[curSubject]["searchString"] .. search_string
                end

                subjectInfo[curSubject]["fitness"] = subjectInfo[curSubject]["fitness"] + calculateFitness()

                -- print(my_input)
                joypad.write(1, my_input)

            end
            emu.frameadvance()
        end
        file = io.open("generation" .. tostring(generation) .. ".txt", "a")
        file:write(subjectInfo[curSubject]["fitness"] .. ":" .. string.sub(subjectInfo[curSubject]["searchString"],0,totalFrames))
        file:close()
    end
    generation = generation + 1
end