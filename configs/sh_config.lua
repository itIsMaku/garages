ImpoundPrice = 500
GarageToGaragePrice = 100
SpawnGaragePrice = 300

ImpoundJobs = {
    'police', 'sheriff'
}

Impounds = {
    ['city'] = {
        display_name = 'Město',
        coords = vector4(402.0082, -1631.6547, 29.2919, 50.15),
        zone_radius = {
            width = 9.0,
            height = 15.0
        },
        blip = true
    },
    ['city_hayes'] = {
        display_name = 'Město - Hayes Autos',
        coords = vector4(501.3757, -1337.5782, 29.3184, 26.6561),
        zone_radius = {
            width = 10.0,
            height = 10.0
        },
        blip = true
    },
    ['paleto'] = {
        display_name = 'Paleto',
        coords = vector4(-355.4617, 6067.8594, 31.4985, 46.6080),
        zone_radius = {
            width = 10.0,
            height = 10.0
        },
        blip = true
    },
    ['sandy'] = {
        display_name = 'Sandy',
        coords = vector4(1846.9159, 3693.6558, 33.8471, 29.8795),
        zone_radius = {
            width = 7.0,
            height = 7.0
        },
        blip = true
    }
}

GarageTypesBlips = {
    ['car'] = {
        sprite = 357,
        display = 4,
        scale = 0.65,
        colour = 0,
        title = 'GARÁŽ',
        short_range = true
    },
    ['heli'] = {
        sprite = 360,
        display = 4,
        scale = 0.8,
        colour = 4,
        title = 'HANGÁR',
        short_range = true
    },
    ['boat'] = {
        sprite = 356,
        display = 4,
        scale = 0.8,
        colour = 4,
        title = 'PŘÍSTAV',
        short_range = true
    }
}
