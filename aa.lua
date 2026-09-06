local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local CONFIG = {
    NO_RECOIL = 0,        
    NO_RECOIL_ADS = 1,      
    ANTI_SHAKE = 0,        
    ALL_GUN_FOCUS = 0,      
    QUICK_SCOPE = 0,        
    QUICK_SWITCH = 0,       
    EXTRA_HIT_SCALE = 4,    
    RAINBOW_HIT = 0        
}

local function noRecoilJitter(base)
    return base + (math.random(-2, 2) * 0.01)
end

local function ApplyWeaponMods(weaponEntity)
    if not slua.isValid(weaponEntity) then return end

    if CONFIG.NO_RECOIL == 1 then
        weaponEntity.RecoilKick = noRecoilJitter(0.1)
        weaponEntity.AccessoriesVRecoilFactor = 0.2
        weaponEntity.AccessoriesHRecoilFactor = 0.2
        if weaponEntity.RecoilInfo then
            weaponEntity.RecoilInfo.VerticalRecoilMin = 0.8
            weaponEntity.RecoilInfo.VerticalRecoilMax = 1.5
            weaponEntity.RecoilInfo.RecoilSpeedVertical = 0.8
            weaponEntity.RecoilInfo.RecoilSpeedHorizontal = 0.8
            weaponEntity.RecoilInfo.VerticalRecoveryMax = 0.8
        end
        weaponEntity.RecoilModifierStand = 0.15
        weaponEntity.RecoilModifierCrouch = 0.15
        weaponEntity.RecoilModifierProne = 0.15
    end

    if CONFIG.NO_RECOIL_ADS == 1 then
        weaponEntity.RecoilKickADS = noRecoilJitter(0.1)
    end

    if CONFIG.ANTI_SHAKE == 1 then
        weaponEntity.AnimationKick = 0.2
    end

    if CONFIG.ALL_GUN_FOCUS == 1 then
        weaponEntity.GameDeviationAccuracy = 0.01
        weaponEntity.GameDeviationFactor = noRecoilJitter(0.08)

        -- weaponEntity.ShotGunHorizontalSpread = 0.1
        -- weaponEntity.ShotGunVerticalSpread = 0.1
    end

    if CONFIG.QUICK_SCOPE == 1 then
        weaponEntity.WeaponAimInTime = 25.0
    end

    if CONFIG.QUICK_SWITCH == 1 then
        weaponEntity.SwitchFromBackpackToIdleTime = 0.1
        weaponEntity.SwitchFromIdleToBackpackTime = 0.1
    end

    if CONFIG.EXTRA_HIT_SCALE > 0 then
        weaponEntity.ExtraHitPerformScale = CONFIG.EXTRA_HIT_SCALE
    end
end

local rainbowColors = {
    {r=1.0, g=0.0, b=0.0, a=1.0},
    {r=1.0, g=0.5, b=0.0, a=1.0},
    {r=1.0, g=1.0, b=0.0, a=1.0},
    {r=0.0, g=1.0, b=0.0, a=1.0},
    {r=0.0, g=0.5, b=1.0, a=1.0},
    {r=0.0, g=0.0, b=1.0, a=1.0},
    {r=0.5, g=0.0, b=1.0, a=1.0},
    {r=1.0, g=0.0, b=1.0, a=1.0},
}

local colorIndex = 1
local colorTimer = 0

local function ApplyRainbowHit()

    colorTimer = colorTimer + 0.1  
    if colorTimer >= 2.0 then
        colorTimer = 0
        colorIndex = (colorIndex % #rainbowColors) + 1
    end

    local currentColor = rainbowColors[colorIndex]
    local linearColor = FLinearColor(currentColor.r, currentColor.g, currentColor.b, currentColor.a)

    local playerController = slua_GameFrontendHUD:GetPlayerController()
    if not slua.isValid(playerController) then return end

    pcall(function()
        -- HitEffectComponent
        local hitComp = playerController.HitEffectComponent
        if slua.isValid(hitComp) then
            if hitComp.SetHitColor then hitComp:SetHitColor(linearColor) end
            if hitComp.SetBodyHitColor then hitComp:SetBodyHitColor(linearColor) end
            if hitComp.SetHeadHitColor then hitComp:SetHeadHitColor(linearColor) end
            hitComp.HitColor = linearColor
            hitComp.BodyHitColor = linearColor
            hitComp.HeadHitColor = linearColor
            hitComp.HitEffectScale = 120
        end

        -- MyHUD
        local myHUD = playerController.MyHUD
        if slua.isValid(myHUD) then
            if myHUD.SetHitColor then myHUD:SetHitColor(linearColor) end
            myHUD.HitColor = linearColor
            myHUD.BodyHitColor = linearColor
            myHUD.HeadHitColor = linearColor
            myHUD.HitEffectIntensity = 120
            myHUD.HitMarkerScale = 120
            if myHUD.HitPerform then
                local hp = myHUD.HitPerform
                if hp.SetHitBodyDrawColor then hp:SetHitBodyDrawColor(linearColor) end
                if hp.SetHitHeadDrawColor then hp:SetHitHeadDrawColor(linearColor) end
                hp.HitBodyDrawColor = linearColor
                hp.HitHeadDrawColor = linearColor
                hp.HitEffectScale = 120
            end
        end

        -- DamageDisplay
        local dmgDisplay = playerController.DamageDisplayComponent
        if slua.isValid(dmgDisplay) then
            if dmgDisplay.SetHitColor then dmgDisplay:SetHitColor(linearColor) end
            dmgDisplay.HitColor = linearColor
        end

        -- BattleHUD
        local battleHUD = playerController.BattleHUD
        if slua.isValid(battleHUD) then
            if battleHUD.SetHitEffectColor then battleHUD:SetHitEffectColor(linearColor) end
            battleHUD.HitEffectColor = linearColor
        end


        if playerController.SetHitEffectColor then
            playerController:SetHitEffectColor(linearColor)
        end


        local localPlayer = GameplayData.GetPlayerCharacter()
        if slua.isValid(localPlayer) then
            local wm = localPlayer.WeaponManagerComponent
            if slua.isValid(wm) then
                local weapon = wm.CurrentWeaponReplicated
                if slua.isValid(weapon) then
                    local shootEffect = weapon.ShootWeaponEffectComp
                    if slua.isValid(shootEffect) then
                        if shootEffect.SetHitEffectColor then shootEffect:SetHitEffectColor(linearColor) end
                        shootEffect.HitEffectColor = linearColor
                        shootEffect.HitEffectScale = 40.0
                    end
                end
            end
        end
    end)
end

local lastWeaponID = 0

local function MainTick()
    local uCon = slua_GameFrontendHUD:GetPlayerController()
    if not slua.isValid(uCon) then return end
    local currentPawn = uCon:GetCurPawn()
    if not slua.isValid(currentPawn) then return end


    if CONFIG.RAINBOW_HIT == 1 then
        ApplyRainbowHit()
    end

    local wm = currentPawn.WeaponManagerComponent
    if not slua.isValid(wm) then return end
    local weapon = wm.CurrentWeaponReplicated
    if not slua.isValid(weapon) then return end

    local entity = weapon.ShootWeaponEntityComp
    if not slua.isValid(entity) then return end

    local currentWeaponID = weapon:GetWeaponID()
    if currentWeaponID ~= lastWeaponID then
        lastWeaponID = currentWeaponID
        ApplyWeaponMods(entity)
    else
        ApplyWeaponMods(entity)
    end
end


pcall(function()
    local pc = slua_GameFrontendHUD:GetPlayerController()
    if not slua.isValid(pc) then
        pc = import("GameplayStatics").GetPlayerController(slua_GameFrontendHUD:GetWorld(), 0)
    end
    if not slua.isValid(pc) then return end

    if _G.HTY_WEAPON_TIMER and slua.isValid(_G.HTY_WEAPON_TIMER) then
        return
    end

    pc:AddGameTimer(0.8, false, function()
        local pc2 = slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc2) then
            _G.HTY_WEAPON_TIMER = pc2  
            pc2:AddGameTimer(0.1, true, MainTick)  
        end
    end)
end)
