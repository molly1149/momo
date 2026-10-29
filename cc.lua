-- @UE4_MASTER
-- =====================================================================
-- CONFIG
-- =====================================================================
_G.GTLMODConfig = _G.GTLMODConfig or {
    EspBox = false,
    IpadView = true,
    Btn5 = false,
    Btn6 = false,
}
-- Auto visual settings; player-tracking ESP remains disabled.
_G.GTLMODConfig.EspBox = false
_G.GTLMODConfig.IpadView = true
_G.GTLMODState = _G.GTLMODState or {
    EspLoop = 0,
    GfxLoop = 0,
    PrevGraphicsState = {},
    CustomTextData = { IpadViewFOV = 120 },
}
if not _G.GTLMODState.PrevGraphicsState then _G.GTLMODState.PrevGraphicsState = {} end
if not _G.GTLMODState.CustomTextData then _G.GTLMODState.CustomTextData = { IpadViewFOV = 120 } end

-- Anti-cheat/security reporting hooks are intentionally left untouched.


-- =====================================================================
-- CAMERA LOOP (0.35s)
-- iPad View only
-- =====================================================================
local function GfxCamLoop()
    -- iPad View (FOV)
    pcall(function()
        local pc = GameplayData.GetPlayerController()
        if not Valid(pc) then return end
        local lp = pc:GetPlayerCharacterSafety()
        if not Valid(lp) then return end
        if lp.bIsWeaponAiming then return end

        local cam = lp.ThirdPersonCameraComponent
        if not Valid(cam) then pcall(function() cam = lp.TPPCameraComponent end) end
        if not Valid(cam) then pcall(function() cam = lp.TPCameraComponent end) end
        if not Valid(cam) then return end

        local target
        if _G.GTLMODConfig.IpadView then
            target = _G.GTLMODState.CustomTextData.IpadViewFOV or 120
        else
            target = 80
        end
        if cam.FieldOfView ~= target then
            cam.FieldOfView = target
        end
    end)

    Later(0.35, GfxCamLoop)
end


-- Start the iPad View loop (only once):
pcall(function()
    Later(3.0, GfxCamLoop)
end)
