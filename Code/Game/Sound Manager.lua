
SoundManager = {
    musicVolume = 10,
    soundVolume = 10,

    categories = {
        select_node = {
            sounds = {
                { path = "Select Node/131977__juskiddink__three-chord-chimes_1", duration = 4 },
                { path = "Select Node/131977__juskiddink__three-chord-chimes_2", duration = 4 },
                { path = "Select Node/131977__juskiddink__three-chord-chimes_3", duration = 4 },
            },
        },
        
        end_level = {
            sounds = {
                { path = "End Level/FS 22267__zeuss__the-chime", duration = 3 },
            }
        },
        
        music = {
            sounds = {
                { path = "Music/FS 33987__erh__slow-atmosphere-4", duration = 42 },
                { path = "Music/FS 131979__juskiddink__chimes", duration = 56 },
                { path = "Music/FS 86277__juskiddink__chimes", duration = 124 },                                
            }
        }
    }
}

for catName, category in pairs( SoundManager.categories ) do
    category.isPlaying = false
    category.timer = Tween.Timer( 0, function() end, {
        destroyOnComplete = false,
        destroyOnSceneLoad = false
    } )
    for i=1, #category.sounds do
        local sound = category.sounds[i]
        sound.asset = CS.FindAsset(sound.path, "Sound")
    end
end



-- read a sound,
-- do not read a sound of the same category until a certain time has passed

function SoundManager.Play( category )
    if SoundManager.soundVolume <= 0 then
        return
    end
    
    local category = SoundManager.categories[ category ]
    if category.isPlaying == false then
        
        local sound = category.sounds[ math.random( #category.sounds ) ]

        sound.asset:Play( SoundManager.soundVolume )
        category.isPlaying = true
        category.timer.duration = sound.duration
        
    end
end
