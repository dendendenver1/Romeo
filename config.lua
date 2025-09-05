Config = {}
Config.ResourceName = 'Romeo'
Config.Stages = {
    {name = 'Acquaintance', min = 0},
    {name = 'Friend', min = 200},
    {name = 'Close Friend', min = 500},
    {name = 'Romantic', min = 900},
    {name = 'Official Partner', min = 1400}
}
Config.Gifts = {
    {id = 'flowers', label = 'Flowers', affection = 60, cost = 150, unlock = {emote = 'hug'}},
    {id = 'food', label = 'Gourmet Food', affection = 40, cost = 100},
    {id = 'jewelry', label = 'Jewelry', affection = 120, cost = 1000, unlock = {emote = 'selfie'}}
}
Config.Cooldowns = {interact = 5000, gift = 15000, calltext = 20000, followToggle = 5000, miniEvent = 600000}
Config.Decay = {interval = 600000, amount = -10}
Config.ScheduleTick = 15000
Config.TextRadius = 3.0
Config.BackgroundMsgInterval = {min = 240000, max = 420000}
Config.Economy = {UseWallet = true, DefaultBalance = 1000, Commands = true}
Config.DateLocations = {
    {label = 'Cafe', pos = vec3(-628.12, 239.51, 81.88)},
    {label = 'Park', pos = vec3(-841.34, -1253.52, 6.93)},
    {label = 'Scenic', pos = vec3(-424.48, 1123.89, 325.85)}
}
Config.NPCs = {
    {id = 'npc_amy', name = 'Amy', model = `a_f_y_hipster_04`, home = vec3(-1503.44, -553.12, 32.71), work = vec3(-553.27, -916.51, 23.89), cafe = vec3(-628.12, 239.51, 81.88), park = vec3(-1371.27, -496.14, 33.16)},
    {id = 'npc_lucas', name = 'Lucas', model = `a_m_m_business_01`, home = vec3(-106.53, -8.74, 70.52), work = vec3(-270.11, -957.28, 31.22), cafe = vec3(-612.83, -107.61, 41.01), park = vec3(-841.34, -1253.52, 6.93)},
    {id = 'npc_sophia', name = 'Sophia', model = `a_f_y_beach_01`, home = vec3(-1025.12, -265.33, 36.91), work = vec3(-621.21, 37.15, 93.12), cafe = vec3(-150.23, -880.21, 30.25), park = vec3(-720.41, -1080.55, 10.34)},
    {id = 'npc_jason', name = 'Jason', model = `a_m_m_farmer_01`, home = vec3(-210.11, -1438.44, 31.11), work = vec3(-401.21, 6183.55, 31.47), cafe = vec3(-344.12, -827.23, 30.58), park = vec3(-95.12, -180.44, 31.22)},
    {id = 'npc_maria', name = 'Maria', model = `a_f_y_soucent_02`, home = vec3(120.33, -1040.12, 29.21), work = vec3(-250.14, -975.41, 31.34), cafe = vec3(-550.23, -180.41, 38.11), park = vec3(-770.11, -1300.22, 6.82)},
    {id = 'npc_daniel', name = 'Daniel', model = `a_m_y_hipster_02`, home = vec3(-500.12, -1200.33, 17.25), work = vec3(-300.12, -900.44, 31.35), cafe = vec3(-620.12, -100.44, 37.22), park = vec3(-810.33, -1300.11, 7.44)}
}

Config.Emotes = {
    hug = {dict = 'mp_ped_interaction', name = 'handshake_guy_a', dur = 3500},
    selfie = {dict = 'cellphone@self', name = 'cellphone_selfie', dur = 6000},
    holdhands = {dict = 'missfam5_yoga', name = 'a2_pose', dur = 5000}
}
Config.Dialogue = {
    greet = {
        [1] = {'Hi', 'Hey there', 'Nice to meet you'},
        [2] = {'Good to see you', 'Hey friend', 'You came'},
        [3] = {'You always show up', 'Missed you', 'Walking together?'},
        [4] = {'I was thinking of you', 'Call me more', 'Date night?'},
        [5] = {'My favorite person', 'Where to, love?', 'Hold my hand'}
    },
    gift = {small = {'Thank you', 'Sweet of you', 'I like it'}, big = {'Wow', 'You spoil me', 'This is special'}},
    moodLow = {'I need space', 'Not now', 'You upset me'},
    followOn = {'I\'ll come with you', 'Lead the way', 'I\'m with you'},
    followOff = {'I\'ll wait here', 'Catch you later', 'Text me'},
    jealous = {'Who was that?', 'Are you seeing others?', 'That hurt'}
}
