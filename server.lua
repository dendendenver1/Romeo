local balances = {}
local function ensureBalance(src)
    if not balances[src] then balances[src] = Config.Economy.DefaultBalance end
    return balances[src]
end
local function setBalance(src, v)
    balances[src] = v
end
local function findGift(id)
    for _,g in ipairs(Config.Gifts) do if g.id == id then return g end end
    return nil
end
RegisterNetEvent('romeo:purchaseGift', function(id)
    local src = source
    local g = findGift(id)
    if not g then TriggerClientEvent('romeo:serverGiftResult', src, id, false) return end
    if not Config.Economy.UseWallet then TriggerClientEvent('romeo:serverGiftResult', src, id, true) return end
    local bal = ensureBalance(src)
    if bal >= g.cost then setBalance(src, bal - g.cost) TriggerClientEvent('romeo:serverGiftResult', src, id, true) TriggerClientEvent('romeo:notify', src, 'Shop', ('Paid $%d'):format(g.cost), 'success') else TriggerClientEvent('romeo:serverGiftResult', src, id, false) TriggerClientEvent('romeo:notify', src, 'Shop', 'Not enough money', 'error') end
end)
RegisterNetEvent('romeo:buyGift', function(id, price)
    local src = source
    local g = findGift(id)
    if not g then TriggerClientEvent('romeo:serverGiftResult', src, id, false) return end
    if not Config.Economy.UseWallet then TriggerClientEvent('romeo:serverGiftResult', src, id, true) return end
    local bal = ensureBalance(src)
    if bal >= g.cost then setBalance(src, bal - g.cost) TriggerClientEvent('romeo:serverGiftResult', src, id, true) TriggerClientEvent('romeo:notify', src, 'Shop', ('Paid $%d'):format(g.cost), 'success') else TriggerClientEvent('romeo:serverGiftResult', src, id, false) TriggerClientEvent('romeo:notify', src, 'Shop', 'Not enough money', 'error') end
end)
AddEventHandler('playerDropped', function()
    local src = source
    balances[src] = nil
end)
if Config.Economy.Commands then
    RegisterCommand('romeo_wallet', function(src)
        local bal = ensureBalance(src)
        TriggerClientEvent('romeo:notify', src, 'Wallet', ('$%d'):format(bal), 'inform')
    end, false)
    RegisterCommand('romeo_addcash', function(src, args)
        local amt = tonumber(args[1]) or 0
        if amt <= 0 then TriggerClientEvent('romeo:notify', src, 'Wallet', 'Usage: /romeo_addcash <amount>', 'error') return end
        local bal = ensureBalance(src)
        setBalance(src, bal + amt)
        TriggerClientEvent('romeo:notify', src, 'Wallet', ('+$%d'):format(amt), 'success')
    end, false)
end
