local Class = require("class")
local CharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CombineClass = require("combine_class")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")

-- ============================================================
-- iPad 广角视图 (FOV 105)
-- ============================================================
_G.Mod_iPadView = _G.Mod_iPadView ~= false  -- 默认开启

local PlayerModule = {}

function PlayerModule:ctor()
end

function PlayerModule:postConstruct()
    CharacterBase._PostConstruct(self)
    self:StartAdvancedSystems()
end

function PlayerModule:receiveBeginPlay()
    CharacterBase.ReceiveBeginPlay(self)
end

function PlayerModule:receiveEndPlay(reason)
    CharacterBase.ReceiveEndPlay(self, reason)
end

function PlayerModule:startAdvancedSystems()
    if not Client then return end
    self:AddGameTimer(0.5, true, function()
        if not slua.isValid(self.Object) then return end
        local lp = GameplayData.GetPlayerCharacter()
        if not slua.isValid(lp) then return end

        -- iPad View (FOV 105)
        if _G.Mod_iPadView then
            local tpCam = self.Object.ThirdPersonCameraComponent
            if slua.isValid(tpCam)
                and not self.Object.bIsWeaponAiming
                and tpCam.FieldOfView ~= 105 then
                tpCam.FieldOfView = 105
            end
        end
    end)
end

local BRPlayerCharacterBase = Class(CharacterBase, nil, {
    ctor              = PlayerModule.ctor,
    _PostConstruct    = PlayerModule.postConstruct,
    ReceiveBeginPlay  = PlayerModule.receiveBeginPlay,
    ReceiveEndPlay    = PlayerModule.receiveEndPlay,
    StartAdvancedSystems = PlayerModule.startAdvancedSystems,
})

return CombineClass.DeclareFeature(BRPlayerCharacterBase, {
    { SkyTransition                   = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
    { CarryDeadBoxFeature             = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
    { SpecialSuitFeature              = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
    { TeleportPawnFeature             = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
    { LifterControl                   = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
    { FinalKillEffect                 = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
    { CampFeature                     = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
    { BuildSkateFeature               = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature" },
    { CommonBornlandTransformFeature  = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" }
}, "BRPlayerCharacterBase")
