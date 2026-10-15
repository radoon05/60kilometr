Config = {
    -- Framework auto detection supported (es_extended / qb-core)
    Debug                   = true, -- set to false in production
    AllowedIdentifierNoItem = true, -- allow without item if identifier is whitelisted
    AllowedIdentifiers      = {     -- Make sure that ESX.GetPlayerData().identifier returns this or the QBCore function.. If Debug is set to true and you click the key you will see what you need to put here!
        ["char1:846ba3fe7b7f448f4c430e9f1e7e3ad23807094a"] = true,
        ["license:...."] = true,
        ["steam:123123"] = true
        -- Make sure that ESX.GetPlayerData().identifier returns this or the QBCore function.. If Debug is set to true and you click the key you will see what you need to put here!
        -- Make sure that ESX.GetPlayerData().identifier returns this or the QBCore function.. If Debug is set to true and you click the key you will see what you need to put here!
    },

    UseItem                 = false,
    ItemName                = "megaphone", -- Make sure the item exists in your server. For ESX, insert it into the items table. For Qb-Core insert it into the shared.items table.

    RequireJob              = false,       -- If true, the player must have a job to use the megaphone.
    RequiredJobs            = {            -- ["jobname"] = minimum_grade
        ["police"] = 2,
    },

    UseEmote                = true,
    EmoteName               = "megaphone",

    KeyBindMapper           = "MOUSE_BUTTON", -- or "keyboard" if the key is on a keyboard
    KeyBindDefaultParameter = "MOUSE_MIDDLE",
    KeyBindName             = "(saltychat) Use megaphone",

    AllowInVehicles         = true,

    -- NEW: name of the (paired + / -) command used with RegisterCommand / RegisterKeyMapping
    MegaphoneCommand        = "useMegaPhone",
}
