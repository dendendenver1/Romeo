local State = {npcs = {}, points = {}, recentPartner = nil, nextBgMsg = GetGameTimer() + math.random(Config.BackgroundMsgInterval.min, Config.BackgroundMsgInterval.max)}
local function stageFromAffection(v)
    local idx = 1
    for i = #Config.Stages, 1, -1 do
        if v >= Config.Stages[i].min then idx = i break end
    end
    return idx
end
local function getStageLabel(idx)
    return Config.Stages[idx].name
end
local function canUseCooldown(s, key, ms)
    local now = GetGameTimer()
    s.cooldowns = s.cooldowns or {}
    if not s.cooldowns[key] or now - s.cooldowns[key] >= ms then s.cooldowns[key] = now return true end
    return false
end
local function clamp(v,minv,maxv) if v < minv then return minv elseif v > maxv then return maxv else return v end end
local function applyAffection(n, delta)
    n.affection = clamp((n.affection or 0) + delta, -200, 2000)
    n.stage = stageFromAffection(n.affection)
    n.mood = clamp((n.mood or 0) + math.floor(delta/10), -5, 5)
end
local function affectionBar(n)
    local nextMin = Config.Stages[math.min(n.stage+1, #Config.Stages)].min
    local curMin = Config.Stages[n.stage].min
    local progress = 0
    if nextMin == curMin then progress = 100 else progress = clamp(math.floor(((n.affection - curMin) / (nextMin - curMin)) * 100), 0, 100) end
    return string.format("%s %d%%", getStageLabel(n.stage), progress)
end
local function crimeDislike()
    local p = PlayerPedId()
    if IsPedShooting(p) then return -30 end
    if IsPedInMeleeCombat(p) then return -25 end
    if IsPedInAnyVehicle(p, false) then
        local veh = GetVehiclePedIsIn(p, false)
        if veh ~= 0 then
            local speed = GetEntitySpeed(veh) * 3.6
            if speed > 150.0 then return -10 end
        end
    end
    return 0
end
local function nearPos(a,b,rad)
    return #(a - b) <= rad
end
local function randomLine(t)
    return t[math.random(1, #t)]
end
local function playEmote(ped, e)
    RequestAnimDict(e.dict)
    while not HasAnimDictLoaded(e.dict) do Wait(10) end
    TaskPlayAnim(ped, e.dict, e.name, 2.0, 2.0, e.dur, 1, 0.0, false, false, false)
end
local function ensureModel(model)
    if not IsModelValid(model) then return false end
    RequestModel(model)
    local t = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < t do Wait(10) end
    return HasModelLoaded(model)
end
local function spawnNPC(def)
    if State.npcs[def.id] then return State.npcs[def.id] end
    if not ensureModel(def.model) then return nil end
    local p = CreatePed(4, def.model, def.home.x, def.home.y, def.home.z, 0.0, false, true)
    SetBlockingOfNonTemporaryEvents(p, true)
    SetEntityInvincible(p, true)
    FreezeEntityPosition(p, false)
    State.npcs[def.id] = {ped = p, def = def, affection = 0, stage = 1, mood = 0, following = false, lastInteract = 0, jealousy = 0, cooldowns = {}, quest = nil}
    return State.npcs[def.id]
end
local function taskGoTo(ped, pos)
    TaskGoStraightToCoord(ped, pos.x, pos.y, pos.z, 1.3, -1, 0.0, 0.1)
end
local function ambientAct(npc)
    local ped = npc.ped
    if math.random() < 0.3 then TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_IMPATIENT", 0, true) else ClearPedTasks(ped) end
end
local function currentSlot(hour)
    if hour >= 7 and hour < 10 then return "cafe" end
    if hour >= 10 and hour < 18 then return "work" end
    if hour >= 18 and hour < 22 then return "park" end
    return "home"
end
local function updateSchedules()
    for _, def in ipairs(Config.NPCs) do
        local n = spawnNPC(def)
        if n then
            local slot = currentSlot(GetClockHours())
            local pos = def[slot]
            if pos and not nearPos(GetEntityCoords(n.ped), pos, 3.0) and not n.following then
                ClearPedTasks(n.ped)
                taskGoTo(n.ped, pos)
                if math.random() < 0.5 then ambientAct(n) end
            end
        end
    end
end
local function buildGiftOptions()
    local opts = {}
    for _,g in ipairs(Config.Gifts) do
        opts[#opts+1] = {title = g.label .. " $" .. g.cost, description = "+"..g.affection.." affection", event = "romeo:gift", args = g}
    end
    return opts
end
local function notify(t, d)
    lib.notify({title = t, description = d or "", type = "inform"})
end
local function moodGate(n)
    if n.mood and n.mood <= -3 then return true end
    return false
end
local function showNPCMenu(n)
    local items = {}
    items[#items+1] = {title = n.def.name .. " [" .. affectionBar(n) .. "]"}
    items[#items+1] = {title = "Talk", event = "romeo:talk", args = {id = n.def.id}}
    items[#items+1] = {title = n.following and "Ask to Stop Following" or "Ask to Follow", event = "romeo:follow", args = {id = n.def.id}}
    items[#items+1] = {title = "Give Gift", menu = "romeo_gift_"..n.def.id}
    items[#items+1] = {title = "Call/Text", event = "romeo:calltext", args = {id = n.def.id}}
    items[#items+1] = {title = "Plan Date", event = "romeo:date", args = {id = n.def.id}}
    lib.registerContext({id = "romeo_npc_"..n.def.id, title = n.def.name, options = items})
    lib.registerContext({id = "romeo_gift_"..n.def.id, title = "Gifts", options = buildGiftOptions()})
    lib.showContext("romeo_npc_"..n.def.id)
end
local function jealPenalty(curId)
    if State.recentPartner and State.recentPartner ~= curId then return -40 else return 0 end
end
local function talkToNPC(id)
    local n = State.npcs[id]
    if not n then return end
    if not canUseCooldown(n, "interact", Config.Cooldowns.interact) then return end
    local neg = crimeDislike() + jealPenalty(id)
    if neg < 0 then applyAffection(n, neg) notify(n.def.name, randomLine(Config.Dialogue.moodLow)) return end
    if moodGate(n) then notify(n.def.name, randomLine(Config.Dialogue.moodLow)) return end
    local line = randomLine(Config.Dialogue.greet[n.stage] or Config.Dialogue.greet[1])
    notify(n.def.name, line)
    applyAffection(n, 10)
end
local function giveGiftToNPC(id, gift)
    local n = State.npcs[id]
    if not n then return end
    if not canUseCooldown(n, "gift", Config.Cooldowns.gift) then return end
    TriggerServerEvent("romeo:purchaseGift", gift.id)
    local aff = gift.affection + (n.stage >= 4 and 10 or 0)
    applyAffection(n, aff)
    local line = aff >= 100 and randomLine(Config.Dialogue.gift.big) or randomLine(Config.Dialogue.gift.small)
    notify(n.def.name, line)
    if gift.unlock and gift.unlock.emote == "hug" then playEmote(n.ped, Config.Emotes.hug) end
    if gift.unlock and gift.unlock.emote == "selfie" then playEmote(PlayerPedId(), Config.Emotes.selfie) playEmote(n.ped, Config.Emotes.selfie) end
end
local function toggleFollow(id)
    local n = State.npcs[id]
    if not n then return end
    if not canUseCooldown(n, "followToggle", Config.Cooldowns.followToggle) then return end
    n.following = not n.following
    if n.following then
        notify(n.def.name, randomLine(Config.Dialogue.followOn))
        TaskFollowToOffsetOfEntity(n.ped, PlayerPedId(), 0.5, 0.5, 0.0, 1.5, -1, 2.0, true)
        applyAffection(n, 5)
        State.recentPartner = id
    else
        notify(n.def.name, randomLine(Config.Dialogue.followOff))
        ClearPedTasks(n.ped)
    end
end
local function callOrText(id)
    local n = State.npcs[id]
    if not n then return end
    if not canUseCooldown(n, "calltext", Config.Cooldowns.calltext) then return end
    if moodGate(n) then notify(n.def.name, randomLine(Config.Dialogue.moodLow)) return end
    local mood = n.mood or 0
    local base = {"Just checking in","What are you up to?","Miss you"}
    local happy = {"Can we hang out?","Let's go somewhere","Call me"}
    local grumpy = {"I'm busy","Later","Not now"}
    local pool = base
    if mood >= 2 then for _,v in ipairs(happy) do pool[#pool+1]=v end end
    if mood <= -1 then pool = grumpy end
    notify(n.def.name, randomLine(pool))
    applyAffection(n, 8)
end
local function planDate(id)
    local n = State.npcs[id]
    if not n then return end
    if n.stage < 2 then notify(n.def.name, "Maybe later") return end
    if n.quest then notify(n.def.name, "We already have plans") return end
    local options = {}
    for i,loc in ipairs(Config.DateLocations) do options[#options+1] = {label = loc.label, value = i} end
    local opt = lib.inputDialog("Plan Date", {{type = "select", label = "Location", options = options}})
    if not opt or not opt[1] then return end
    local c = Config.DateLocations[opt[1]]
    n.quest = {type = "date", pos = c.pos, name = c.label, started = GetGameTimer()}
    notify(n.def.name, "Meet me at "..c.label)
end
local function checkQuests()
    for _,n in pairs(State.npcs) do
        if n.quest and n.quest.type == "date" then
            local ppos = GetEntityCoords(PlayerPedId())
            if #(ppos - n.quest.pos) < 6.0 then
                notify(n.def.name, "This is nice")
                applyAffection(n, 50)
                if n.stage >= 4 then applyAffection(n, 30) end
                if math.random() < 0.5 then playEmote(n.ped, Config.Emotes.holdhands) end
                n.quest = nil
            end
        end
    end
end
local function decayAffection()
    for _,n in pairs(State.npcs) do
        applyAffection(n, Config.Decay.amount + (n.following and 8 or 0))
        if n.jealousy and n.jealousy > 0 then n.jealousy = n.jealousy - 1 end
        if n.stage >= 4 and State.recentPartner and State.recentPartner ~= n.def.id then applyAffection(n, -15) notify(n.def.name, randomLine(Config.Dialogue.jealous)) end
        if n.stage > 1 and n.mood <= -3 and n.affection < Config.Stages[n.stage].min then notify(n.def.name, "This isn't working") end
    end
end
local function randomBackground()
    if GetGameTimer() < State.nextBgMsg then return end
    State.nextBgMsg = GetGameTimer() + math.random(Config.BackgroundMsgInterval.min, Config.BackgroundMsgInterval.max)
    local picks = {}
    for _,n in pairs(State.npcs) do if n.stage >= 2 then picks[#picks+1] = n end end
    if #picks == 0 then return end
    local n = picks[math.random(1, #picks)]
    local msgs = {"Saw something funny","Thinking of you","Text me when free","I made coffee","Walk with me?"}
    notify(n.def.name, randomLine(msgs))
    applyAffection(n, 6)
end
local function setupPoints()
    for _,def in ipairs(Config.NPCs) do
        local n = spawnNPC(def)
        if n and not State.points[def.id] then
            State.points[def.id] = lib.points.new({coords = def.home, distance = Config.TextRadius})
            function State.points[def.id]:nearby()
                local p = PlayerPedId()
                local ped = n.ped
                if ped ~= 0 and #(GetEntityCoords(p) - GetEntityCoords(ped)) <= Config.TextRadius then
                    lib.showTextUI("[E] Interact: "..def.name)
                    if IsControlJustPressed(0, 38) then showNPCMenu(n) end
                else
                    lib.hideTextUI()
                end
            end
        end
    end
end
AddEventHandler("romeo:talk", function(data) if data and data.id then local id = data.id talkToNPC(id) end end)
AddEventHandler("romeo:follow", function(data) if data and data.id then local id = data.id toggleFollow(id) end end)
AddEventHandler("romeo:calltext", function(data) if data and data.id then local id = data.id callOrText(id) end end)
AddEventHandler("romeo:date", function(data) if data and data.id then local id = data.id planDate(id) end end)
AddEventHandler("romeo:gift", function(gift)
    local ped = PlayerPedId()
    local closest, dist = nil, 9999.0
    for _,n in pairs(State.npcs) do
        local d = #(GetEntityCoords(ped) - GetEntityCoords(n.ped))
        if d < dist then dist = d closest = n end
    end
    if closest and dist <= 3.0 then giveGiftToNPC(closest.def.id, gift) end
end)
CreateThread(function()
    while true do
        updateSchedules()
        checkQuests()
        randomBackground()
        Wait(Config.ScheduleTick)
    end
end)
CreateThread(function()
    setupPoints()
    while true do
        for _,n in pairs(State.npcs) do
            if n.following then
                local malus = crimeDislike()
                if malus < 0 and math.random() < 0.2 then applyAffection(n, malus) end
            end
        end
        Wait(2000)
    end
end)
CreateThread(function()
    while true do
        decayAffection()
        Wait(Config.Decay.interval)
    end
end)
RegisterCommand("romeo_buygift", function(_, args)
    local id = args[1]
    if not id then notify("Shop", "Usage: /romeo_buygift [flowers|food|jewelry]") return end
    for _,g in ipairs(Config.Gifts) do
        if g.id == id then TriggerServerEvent("romeo:buyGift", id, g.cost) notify("Shop", "Attempting purchase: "..g.label) return end
    end
    notify("Shop", "Unknown gift")
end, false)
RegisterNetEvent("romeo:serverGiftResult", function(id, success)
    if success then notify("Shop", "Purchase successful: "..id) else notify("Shop", "Purchase failed") end
end)
RegisterNetEvent('romeo:notify', function(title, description, ntype)
    lib.notify({title = title or '', description = description or '', type = ntype or 'inform'})
end)
exports('GetRelationshipState', function()
    local out = {}
    for _,n in pairs(State.npcs) do out[#out+1] = {id = n.def.id, name = n.def.name, affection = n.affection, stage = getStageLabel(n.stage), mood = n.mood} end
    return out
end)
