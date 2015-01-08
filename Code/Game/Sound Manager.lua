
SoundManager = { 
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
            },
            playedSounds = {}
        }
    }
}

local musicSoundInstance = nil


for categoryName, category in pairs( SoundManager.categories ) do
    category.isPlaying = false
    category.timer = Tween.Timer( 0, function() end, {
        destroyOnComplete = false,
        destroyOnSceneLoad = false,
        isCompleted = true,
    } )

    for i=1, #category.sounds do
        local sound = category.sounds[i]
        sound.asset = CS.FindAsset(sound.path, "Sound")
    end
end


-- read a sound,
-- do not read a sound of the same category until a certain time has passed

function SoundManager.Play( category )
    if Options.soundVolume <= 0 then
        return
    end
    
    local category = SoundManager.categories[ category ]
    
    if category.soundInstance == nil then
        local sound = category.sounds[ math.random( #category.sounds ) ]
        
        category.soundInstance = sound.asset:CreateInstance()
        category.soundInstance:SetLoop(false)
        category.soundInstance:SetPitch( math.randomrange(-0.8,0.8) )
        category.soundInstance:Play()
        
        category.volumeTweener = Tween.Tweener(Options.soundVolume, 0, 3, {
            easeType = "outSine",
            OnUpdate = function(t)
                category.soundInstance:SetVolume( t.value )
            end,
            OnComplete = function()
                category.soundInstance:Stop()
                --category.soundInstance = nil
                
                Tween.Timer(0.5, function()
                    -- this seems to prevent an exeption
                    category.soundInstance = nil
                end)
            end
        })
        
        --[[
        --if category.timer.isCompleted == true then
        sound.asset:Play( Options.soundVolume )
        category.timer.duration = 2
        category.timer:Restart()
        ]]
    end
end


function SoundManager.PlayMusic()
    if Options.musicVolume <= 0 then
        return
    end
    
    local category = SoundManager.categories["music"]
    if #category.sounds == 0 and #category.playedSounds > 0 then
        -- all music have been played once already
        category.sounds = category.playedSounds
    end
    
    if musicSoundInstance == nil and math.random(4) == 1 then       
        local id = math.random( #category.sounds )       
        local sound = category.sounds[ id ]
        
        if #category.sounds ~= #category.playedSounds then
            -- not all music have been played once yet
            -- remove the one who will play now
            -- from the pool of musics
            table.remove( category.sounds, id )
            table.insert( category.playedSounds, sound )
        end
        
        musicSoundInstance = sound.asset:CreateInstance()
        musicSoundInstance:SetLoop(false)
        musicSoundInstance:SetVolume( Options.musicVolume )
        --musicSoundInstance:SetPitch( math.randomrange(-0.2,0.2) )
        musicSoundInstance:Play()
        
        category.timer.duration = sound.duration
        --category.timer.duration = 5
        category.timer.OnComplete = function()
            musicSoundInstance:Stop()
            musicSoundInstance = nil
        end
        category.timer:Restart()
    end
end

function SoundManager.StopMusic()
    
end


function Behavior:Update()
    
end