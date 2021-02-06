Config = Config or {}
Config.PlayerSlot = 51
Config.DurabilityDecraseAmount = {
    ['WEAPON_PISTOL'] = 0.3,
}



Config.Shops = {

    -- Regular shop
    {
        coords = vector3(316.3667, -200.783, 54.086),
        blip = {
            id = 52,
            name = "Shop",
            color = 5,
            scale = 0.6,
        },
        text = 'E - Open Shop',
        name = 'Shop', 
        inventory = {
            {
                name = 'bread',
                price = 15,
                count = 200
            },
            {
                name = 'WEAPON_PISTOL',
                price = 25,
                count = 1,
                metadata = { weaponlicense = 'HSN', },
            },
            {
                name = 'hsn_pistol_ammo',
                price = 1,
                count = 10,
            },
            {
                name = 'identification',
                price = 15,
                count = 1
            },
        },
    },

    -- MRPD Armoury
    {
        job = 'police',
        coords = vector3(452.27, -980.1, 30.6),
        blip = {
            id = 110,
            name = "Armoury",
            color = 29,
            scale = 0.6,
        },
        name = 'Armoury',
        inventory = {
            {
                name = 'WEAPON_PISTOL',
                price = 25,
                count = 1,
                metadata = { weaponlicense = 'POL',},
            },
            {
                name = 'hsn_pistol_ammo',
                price = 1,
                count = 10,
            },
        },
    },

}



Config.Ammos = {
    ['hsn_pistol_ammo'] = {
        count = 40,
        weapons = {
            `WEAPON_PISTOL`,
            `WEAPON_APPISTOL`,
            `WEAPON_HEAVYPISTOL`,
            `WEAPON_COMBATPISTOL`,
            `WEAPON_SNSPISTOL`,
            `WEAPON_VINTAGEPISTOL`,
        },

    },
    ['hsn_pistol_ammo_big'] = {
        count = 30,
        weapons = {
            `WEAPON_PISTOL`,
            `WEAPON_APPISTOL`,
            `WEAPON_HEAVYPISTOL`,
            `WEAPON_COMBATPISTOL`,
            `WEAPON_SNSPISTOL`,
            `WEAPON_VINTAGEPISTOL`,
        },
    },
}

