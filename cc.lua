local GameplayData = require("GameLua.GameCore.Data.GameplayData")

local CONFIG = {
    NO_RECOIL = 0,        
    NO_RECOIL_ADS = 1,     
    ANTI_SHAKE = 1,       
    ALL_GUN_FOCUS = 1,     
    QUICK_SCOPE = 0,      
    QUICK_SWITCH = 0,      
    GUN_WALLBANG = 0,      
    SUPER_BULLET = 0,       
    SUPER_FIRE_RATE = 0,   
    INFINITE_AMMO = 0,    
    AIM_ASSIST = 0,         
    EXTRA_HIT_SCALE = 0     
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
        weaponEntity.AnimationKick = 0.5
    end

    if CONFIG.ALL_GUN_FOCUS == 1 then
        weaponEntity.GameDeviationAccuracy = 0.01
        weaponEntity.GameDeviationFactor = noRecoilJitter(0.08)
        ---weaponEntity.ShotGunHorizontalSpread = 0.1
        ---weaponEntity.ShotGunVerticalSpread = 0.1
    end

    if CONFIG.QUICK_SCOPE == 1 then
        weaponEntity.WeaponAimInTime = 25.0
    end

    if CONFIG.QUICK_SWITCH == 1 then
        weaponEntity.SwitchFromBackpackToIdleTime = 0.3
        weaponEntity.SwitchFromIdleToBackpackTime = 0.3
    end

    if CONFIG.GUN_WALLBANG == 1 then
        weaponEntity.WeaponBodyLength = 0.0
    end

    if CONFIG.SUPER_BULLET == 1 then
        weaponEntity.BulletNumSingleShot = 9
    end

    if CONFIG.SUPER_FIRE_RATE == 1 then
        weaponEntity.ShootInterval = 1
    end

    if CONFIG.INFINITE_AMMO == 1 then
        weaponEntity.bClipHasInfiniteBullets = true
        weaponEntity.bHasInfiniteBullets = true
    end

    if CONFIG.AIM_ASSIST == 1 and weaponEntity.AutoAimingConfig then
        local ranges = {"OuterRange", "InnerRange"}
        for _, rangeName in ipairs(ranges) do
            local cfg = weaponEntity.AutoAimingConfig[rangeName]
            if cfg then
                cfg.Speed = 11
                cfg.adsorbMaxRange = 800
                cfg.adsorbMinRange = 800
            end
        end
    end

    if CONFIG.EXTRA_HIT_SCALE > 0 then
        weaponEntity.ExtraHitPerformScale = CONFIG.EXTRA_HIT_SCALE
    end
end

local lastWeaponID = 0

local function MainTick()
    local uCon = slua_GameFrontendHUD:GetPlayerController()
    if not slua.isValid(uCon) then return end
    local currentPawn = uCon:GetCurPawn()
    if not slua.isValid(currentPawn) then return end

    local wm = currentPawn.WeaponManagerComponent
    if not wm then return end
    local weapon = wm.CurrentWeaponReplicated
    if not weapon then return end

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
    local tmr = slua_GameFrontendHUD:GetPlayerController()
    if not slua.isValid(tmr) then
        tmr = import("GameplayStatics").GetPlayerController(slua_GameFrontendHUD:GetWorld(), 0)
    end
    if not slua.isValid(tmr) then return end
    if _G.HTY_WEAPON_TIMER == tmr then return end
    _G.HTY_WEAPON_TIMER = tmr
    tmr:AddGameTimer(0.8, false, function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) then
            pc:AddGameTimer(1, true, MainTick)  
        end
    end)
end)
