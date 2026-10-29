-- @UE4_MASTER
_G.GTLMODConfig = _G.GTLMODConfig or { EspBox = false, IpadView = true, Btn5 = false, Btn6 = false }
_G.GTLMODConfig.EspBox = false
_G.GTLMODConfig.IpadView = true
_G.GTLMODState = _G.GTLMODState or { CustomTextData = { IpadViewFOV = 120 } }
if not _G.GTLMODState.CustomTextData then _G.GTLMODState.CustomTextData = { IpadViewFOV = 120 } end

local function getPC()
    if slua_GameFrontendHUD then
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) then return pc end
    end
    local ok, UIUtil = pcall(require, "client.common.ui_util")
    if ok and UIUtil and UIUtil.GetGameInstance then
        local ctx = UIUtil.GetGameInstance()
        local ok2, GS = pcall(import, "GameplayStatics")
        if ok2 and GS and ctx then
            local pc = GS.GetPlayerController(ctx, 0)
            if slua.isValid(pc) then return pc end
        end
    end
    return nil
end

local function findCamera(lp)
    -- 优先常见名，兜底遍历
    for _, name in ipairs({"ThirdPersonCameraComponent","TPPCameraComponent","TPCameraComponent","CameraComponent","FollowCameraComponent"}) do
        local c = lp[name]
        if slua.isValid(c) and c.FieldOfView ~= nil then return c end
    end
    local found = nil
    pcall(function()
        local comps = lp:GetComponentsByClass(import("CameraComponent"))
        if comps then
            for i = 1, #comps do
                if slua.isValid(comps[i]) and comps[i].FieldOfView ~= nil then
                    found = comps[i]; break
                end
            end
        end
    end)
    return found
end

local function GfxCamLoop()
    pcall(function()
        local pc = getPC()
        if not slua.isValid(pc) then return end
        local lp = pc:GetPlayerCharacterSafety()
        if not slua.isValid(lp) then return end
        if lp.bIsWeaponAiming then return end

        local cam = findCamera(lp)
        if not slua.isValid(cam) then
            -- 兜底：直接改 PlayerCameraManager
            local pcm = pc.PlayerCameraManager
            if slua.isValid(pcm) then
                pcm.DefaultFOV = _G.GTLMODConfig.IpadView
                    and (_G.GTLMODState.CustomTextData.IpadViewFOV or 120) or 80
            end
            return
        end

        local target = _G.GTLMODConfig.IpadView
            and (_G.GTLMODState.CustomTextData.IpadViewFOV or 120) or 80
        if cam.FieldOfView ~= target then
            cam.FieldOfView = target
        end
    end)

    local ticker = package.loaded["common.time_ticker"] or require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(0.35, GfxCamLoop)
    else
        Later(0.35, GfxCamLoop)   -- 兜底：如果你的环境确实有 Later
    end
end

pcall(function()
    local ticker = package.loaded["common.time_ticker"] or require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(3.0, GfxCamLoop)
    else
        Later(3.0, GfxCamLoop)
    end
end)