
function Sound.Play( soundAssetOrPath, volume, pitch, pan )
    local sound = Asset.Get( soundAssetOrPath, "Sound", true )
    sound:oPlay( volume or 1, pitch or 0, pan or 0 )
end
