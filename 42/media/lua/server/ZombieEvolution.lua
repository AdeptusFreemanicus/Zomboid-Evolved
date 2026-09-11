local ZomboidEvolved = {}

-- The helper to change Java sandbox options
local function setOption(name, value)
local options = getSandboxOptions()
if not options then return end

    local option = options:getOptionByName(name)
    if option then
        option:setValue(value)
        else
            print("[ZomboidEvolved] Warning: Option not found -> " .. tostring(name))
            end
            end

            -- Function to clear zombies to enforce multiplier setting, only for active area in Day 0
            local function clearLoadedZombies()
            local cell = getCell()
            if not cell then return end

                local zombieList = cell:getZombieList()
                if not zombieList then return end

                    local count = zombieList:size()
                    for i = count - 1, 0, -1 do
                        local z = zombieList:get(i)
                        if z then
                            z:removeFromWorld()
                            z:removeFromSquare()
                            end
                            end
                            -- Print and count amount of zombies cleared
                            print("[ZomboidEvolved] Day 0 Purge: Removed " .. tostring(count) .. " zombies")
                            end

                            local function notifyPlayers(message)
                            if not message then return end
                                for i = 0, getNumActivePlayers() - 1 do
                                    local player = getSpecificPlayer(i)
                                    if player and not player:isDead() then
                                        player:Say(message)
                                        end
                                        end
                                        end
                                        -- Apply lore and zombie population settings, this will require enabling zombie respawn, not active if purge is off
                                        local function applySettings(modifyPop, popMultiplier, speed, strength, toughness, cognition, hearing, sight, memory, lunge, dragDown, daynnight)
                                        if modifyPop then
                                            setOption("ZombieConfig.PopulationMultiplier",popMultiplier)
                                            setOption("ZombieConfig.RespawnHours", 16.0)
                                            setOption("ZombieConfig.RespawnMultiplier", 0.2)
                                            setOption("ZombieConfig.RespawnUnseenHours", 8.0)
                                            end

                                            -- Zombie Lore evolution
                                            setOption("ZombieLore.Speed", speed)
                                            setOption("ZombieLore.Strength", strength)
                                            setOption("ZombieLore.Toughness", toughness)
                                            setOption("ZombieLore.Cognition", cognition)
                                            setOption("ZombieLore.Hearing", hearing)
                                            setOption("ZombieLore.Sight", sight)
                                            setOption("ZombieLore.Memory", memory)
                                            setOption("ZombieLore.ZombiesFenceLunge", lunge)
                                            setOption("ZombieLore.ZombiesDragDown", dragDown)
                                            setOption("ZombieLore.ActiveOnly", daynnight)

                                            local options = getSandboxOptions()
                                            options:applySettings()
                                            options:toLua()
                                            end

                                            -- A function to run as the world initializes and before zombies are placed to disable zombies from spawning
                                            local function onInitGlobalModData(isNewGame)
                                                local dayZeroPurge = true
                                                if SandboxVars and SandboxVars.ZomboidEvolved and SandboxVars.ZomboidEvolved.EnableDayZeroPurge ~= nil then
                                                    dayZeroPurge = SandboxVars.ZomboidEvolved.EnableDayZeroPurge
                                                end

                                                if dayZeroPurge and isNewGame then
                                                    setOption("ZombieConfig.PopulationStartMultiplier", 0.0)
                                                    local options = getSandboxOptions()
                                                    options:applySettings()
                                                    options:toLua()
                                                    print("[ZomboidEvolved] World Init: Set Population Start Multiplier to 0")
                                                end
                                            end

                                            -- Function to get the time and update zombie evolution
                                            function ZomboidEvolved.updateZombies()
                                            local gameTime = getGameTime()
                                            if not gameTime then return end
                                                -- World time in hours divided by 24 to get days
                                                local worldHours = gameTime:getWorldAgeHours()
                                                local days = math.floor(worldHours / 24)

                                                -- Fallback/Default values, only if none are defined, can prevent crashes
                                                local dayZeroPurge = true
                                                local showMessages = true
                                                local fastShamblerDay = 15
                                                local smartShamblerDay = 30
                                                local sprinterDay = 45
                                                local maxPop = 2.0

                                                -- Default evolution stats:
                                                local evos = {
                                                    [1] = { speed = 3, str = 3, tou = 3, cog = 3, hea = 3, sig = 3, mem = 3, lun = false, dra = false, dnn = 1 },
                                                    [2] = { speed = 2, str = 2, tou = 2, cog = 3, hea = 2, sig = 2, mem = 2, lun = false, dra = false, dnn = 1 },
                                                    [3] = { speed = 2, str = 1, tou = 1, cog = 1, hea = 1, sig = 1, mem = 1, lun = true, dra = true, dnn = 1 },
                                                    [4] = { speed = 1, str = 1, tou = 1, cog = 1, hea = 1, sig = 1, mem = 1, lun = true, dra = true, dnn = 2 },
                                                }

                                                -- Check all user custom settings
                                                if SandboxVars and SandboxVars.ZomboidEvolved then
                                                    local zVars = SandboxVars.ZomboidEvolved

                                                    -- General Settings
                                                    if zVars.ShowStageMessages ~= nil then showMessages = zVars.ShowStageMessages end
                                                        if zVars.EnableDayZeroPurge ~= nil then dayZeroPurge = zVars.EnableDayZeroPurge end
                                                            if zVars.FastShamblerDay then fastShamblerDay = zVars.FastShamblerDay end
                                                                if zVars.SmartZombieDay then smartShamblerDay = zVars.SmartZombieDay end
                                                                    if zVars.SprinterDay then sprinterDay = zVars.SprinterDay end
                                                                        if zVars.MaxPopulation then maxPop = zVars.MaxPopulation end

                                                                            -- Evolution settings
                                                                            for i = 1, 4 do
                                                                                if zVars["Evo" .. i .. "_Speed"] then evos[i].speed = zVars["Evo" .. i .. "_Speed"] end
                                                                                if zVars["Evo" .. i .. "_Strength"] then evos[i].str = zVars["Evo" .. i .. "_Strength"] end
                                                                                if zVars["Evo" .. i .. "_Toughness"] then evos[i].tou = zVars["Evo" .. i .. "_Toughness"] end
                                                                                if zVars["Evo" .. i .. "_Cognition"] then evos[i].cog = zVars["Evo" .. i .. "_Cognition"] end
                                                                                if zVars["Evo" .. i .. "_Hearing"] then evos[i].hea = zVars["Evo" .. i .. "_Hearing"] end
                                                                                if zVars["Evo" .. i .. "_Sight"] then evos[i].sig = zVars["Evo" .. i .. "_Sight"] end
                                                                                if zVars["Evo" .. i .. "_Memory"] then evos[i].mem = zVars["Evo" .. i .. "_Memory"] end
                                                                                if zVars["Evo" .. i .. "_Lunge"] then evos[i].lun = zVars["Evo" .. i .. "_Lunge"] end
                                                                                if zVars["Evo" .. i .. "_DragDown"] then evos[i].dra = zVars["Evo" .. i .. "_DragDown"] end
                                                                                if zVars["Evo" .. i .. "_ActiveOnly"] then evos[i].dnn = zVars["Evo" .. i .. "_ActiveOnly"] end
                                                                            end
                                                end


                                                -- [OLD] Check the settings defined by the user
--                                                 if SandboxVars and SandboxVars.ZomboidEvolved then
--                                                     local zVars = SandboxVars.ZomboidEvolved
--                                                     if zVars.ShowStageMessages ~= nil then showMessages = zVars.ShowStageMessages end
--                                                         if zVars.EnableDayZeroPurge ~= nil then dayZeroPurge = zVars.EnableDayZeroPurge end
--                                                             if zVars.FastShamblerDay then fastShamblerDay = zVars.FastShamblerDay end
--                                                                 if zVars.SmartZombieDay then smartShamblerDay = zVars.SmartZombieDay end
--                                                                     if zVars.SprinterDay then sprinterDay = zVars.SprinterDay end
--                                                                         if zVars.MaxPopulation then maxPop = zVars.MaxPopulation end
--                                                                             end

                                                                            print("[ZomboidEvolved] Day: " .. tostring(days))

                                                                            local currentStage = 1
                                                                            local stageMessage = "I think I spotted some infected in the distance, they look slow."

                                                                            -- Day 0 (Does not trigger if purge day is off)
                                                                            if days == 0 and dayZeroPurge then
                                                                                currentStage = 0
                                                                                stageMessage = "It's so quiet, where is everyone?"
                                                                                applySettings(true, 0.0, evos[1].speed, evos[1].str, evos[1].tou, evos[1].cog, evos[1].hea, evos[1].sig, evos[1].mem, evos[1].lun, evos[1].dra, evos[1].dnn) -- Shamblers, Weak, Fragile, Basic navigation, Poor hearing, Poor Sight, Short memory, Can't Lunge, Can't Drag Down, Both Day and Night
                                                                                clearLoadedZombies()
                                                                                print("[ZomboidEvolved] Day 0: Purge Active. Population set to 0")

                                                                                -- Evolution 1: Weaklings
                                                                                elseif days < fastShamblerDay then
                                                                                    currentStage = 1
                                                                                    stageMessage = "I'm noticing more infected. They still look slow though."
                                                                                    applySettings(dayZeroPurge, 0.3, evos[1].speed, evos[1].str, evos[1].tou, evos[1].cog, evos[1].hea, evos[1].sig, evos[1].mem, evos[1].lun, evos[1].dra, evos[1].dnn) -- Shamblers, Weak, Fragile, Basic navigation, Poor hearing, Poor Sight, Short memory, Can't Lunge, Can't Drag Down, Both Day and Night
                                                                                    print("[ZomboidEvolved] Evolution 1: Weaklings, they are weak")

                                                                                    -- Evolution 2: Fledglings
                                                                                    elseif days >= fastShamblerDay and days < smartShamblerDay then
                                                                                        currentStage = 2
                                                                                        stageMessage = "I feel like the infected are moving faster now, or am I seeing things?"
                                                                                        applySettings(dayZeroPurge, 1.0, evos[2].speed, evos[2].str, evos[2].tou, evos[2].cog, evos[2].hea, evos[2].sig, evos[2].mem, evos[2].lun, evos[2].dra, evos[2].dnn) -- Fast Shamblers, Normal, Normal, Navigation, Normal hearing, Normal sight, Normal memory, Can't Lunge, Can't Drag Down, Both Day and Night
                                                                                        print("[ZomboidEvolved] Evolution 2: Fledglings, faster now")

                                                                                        -- Evolution 3: Smart ones
                                                                                        elseif days >= smartShamblerDay and days < sprinterDay then
                                                                                            currentStage = 3
                                                                                            stageMessage = "Are they even stronger now? I swear some of these doors were closed..."
                                                                                            applySettings(dayZeroPurge, math.max(1.0, maxPop * 0.75), evos[3].speed, evos[3].str, evos[3].tou, evos[3].cog, evos[3].hea, evos[3].sig, evos[3].mem, evos[3].lun, evos[3].dra, evos[3].dnn) -- Fast Shamblers, Superhuman, Tough, Open doors, Pinpoint hearing, Eagle hearing, Long memory, Can Lunge, Can Drag Down, Both Day and Night
                                                                                            print("[ZomboidEvolved] Evolution 3: Smartones, they can open doors now")

                                                                                            -- Evolution 4: Death
                                                                                            else
                                                                                                currentStage = 4
                                                                                                stageMessage = "is that infected running? IT'S RUNNING!!"
                                                                                                applySettings(dayZeroPurge, maxPop, evos[4].speed, evos[4].str, evos[4].tou, evos[4].cog, evos[4].hea, evos[4].sig, evos[4].mem, evos[4].lun, evos[4].dra, evos[4].dnn) -- Sprinters, Superhuman, Tough, Open doors, Pinpoint hearing, Eagle hearing, Long memory, Can Lunge, Can Drag Down, Night
                                                                                                end

                                                                                                -- Check if evolution has changed since last time
                                                                                                local modData = ModData.getOrCreate("ZomboidEvolvedData")
                                                                                                if modData.lastStage ~= currentStage then
                                                                                                    modData.lastStage = currentStage
                                                                                                    -- Let player know
                                                                                                    if showMessages then
                                                                                                        notifyPlayers(stageMessage)
                                                                                                        end
                                                                                                        end
                                                                                                        end

                                                                                                        -- Update on new day or game start
                                                                                                        Events.EveryDays.Add(ZomboidEvolved.updateZombies)
                                                                                                        Events.OnGameStart.Add(ZomboidEvolved.updateZombies)
                                                                                                        Events.OnInitGlobalModData.Add(onInitGlobalModData)
