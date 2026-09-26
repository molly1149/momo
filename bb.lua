local M = {}
local GameplayStatics=import("GameplayStatics")
local GameplayData=require("GameLua.GameCore.Data.GameplayData")

local function Notify(msg)
  local s = "[New] " .. tostring(msg)
  pcall(function() if _G.LexusNotify then _G.LexusNotify(s) end end)
  pcall(function()
    local sh = import("ScriptHelperClient")
    if sh and sh.AddOnScreenDebugMessage then
      sh.AddOnScreenDebugMessage(s, -1, 3.0, {R=1,G=1,B=0,A=1}, {X=1.2, Y=1.2})
    end
  end)
  print(s)
end

local _slua = rawget(_G, "slua")

local function Valid(obj)
  if not obj then return false end
  if _slua and _slua.isValid then
    local ok, v = pcall(_slua.isValid, obj)
    if not ok or not v then return false end
  end
  return true
end

local C_GREEN = {R=0, G=255, B=0, A=255}
local C_RED = {R=255, G=0, B=0, A=255}
local C_CYAN = {R=0, G=255, B=255, A=255}
local C_YELLOW = {R=255, G=255, B=0, A=255}
local C_WHITE = {R=255, G=255, B=255, A=255}
local C_BLUE_TEXT = {R=0, G=200, B=255, A=255}
local SCALE_COLOR_V2 = {R=3, G=3, B=0, A=0}

local GLOBAL_BONE_LIST = {
    "head", "neck_01", "pelvis",
    "upperarm_r", "lowerarm_r", "hand_r",
    "upperarm_l", "lowerarm_l", "hand_l",
    "thigh_l", "calf_l", "foot_l",
    "thigh_r", "calf_r", "foot_r"
}

_G.LexusConfig = _G.LexusConfig or { 
    FakeHWID = false,
    CustomMagicBullet = false,
    AutoHead = false, 
    EspVip = false, 
    EspDistance = false, 
    EspVipPro = false, 
    EspRadar = false, 
    EspLoai5 = false, 
    EspLoai6 = false, 
    EspLoai7 = false,
    Esp7_SoLuong = true,
    Esp7_VuKhi = true,
    Esp7_TuThe = true,
    EspLoai8 = false,
    EspBomMaster = false, 
    EspItemBom = false,   
    EspActiveBom = false, 
    EspAimWarning = false,
    EspAimWarningVisCheck = false,
    EspVehicle = false,   
    EspVeh_Dacia = true,  
    EspVeh_UAZ = true,    
    EspVeh_Buggy = true,  
    EspVeh_Coupe = true,  
    EspVeh_Mirado = true, 
    EspVeh_Motor = true,  
    EspVeh_Other = true,  
    Esp3ShowName = true,
    Esp3ShowHP = true,
    EspAntenna = false, 
    EspOutline = false, 
    OutlineThickness = 10, 
    UnlockFPS = false, 
    IpadView = false, 
    IpadViewVehicle = false, 
    IpadViewScope = false,
    CustomAimbot = false, 
    CustomAimbotClose = false, 
    CustomHRecoil = false,  
    CustomVRecoil = false,  
    LessShake = false, 
    RemoveGrass = false, 
    RemoveTrees = false,  
    RemoveFog = false, 
    WhiteBody = false, 
    ColorBodyV2 = false,    
    ColorBodyV3 = false,    
    WallXuyenTuong = false, 
    ColorBodyNew = false,   
    WallVehicle = false,  
    EspItem_Master = false, 
    EspItem_AR = true,      
    EspItem_Sniper = true,  
    EspItem_SMG = true,     
    EspItem_Shotgun = true, 
    EspItem_LMG = true,
    EspItem_Pistol = true,
    EspItem_Melee = false,
    EspItem_Special = true,
    EspItem_Scope = true,   
    EspItem_Grenade = true,
    EspItem_Med = true,
    Crosshair = false,
    Accuracy = false,
    GodMode = false, 
    WallClimb = false,
    FastCar = false,
    BlackSky = false,
    AimTouchEnable = false,
    AimTouchHipIgKnock = false,
    AimTouchHipIgBot = false,
    AimTouchSGIgKnock = false,
    AimTouchSGIgBot = false,
    AimTouchHipVisCheck = false,
    AimTouchSGVisCheck = false,
    AimTouchHipfire = false,
    AimTouchSG = false,
    AimTouchSGAutoFire = false,
    AimTouchScopeAll = false,
    AimTouchScopeIgKnock = false,
    AimTouchScopeIgBot = false,
    AimTouchScopeVisCheck = false,
    AimTouchScopeSniper = false,
    AimTouchSniperIgKnock = false,
    AimTouchSniperIgBot = false,
    AimTouchSniperVisCheck = false,
    AimTouchMortar = false,
    EspFovCircle = false,
    BugManEnable = false
}

_G.LexusState = _G.LexusState or { 
    LoopToken = 0, 
    NativeESPReady = false,
    GraphicsUnlocked = false, 
    MenuStep = 0, 
    LastCmdTime = 0,
    TrackedMarks = {},
    EnemyMarks = {},
    LastAimbotCheckTime = 0, 
    CustomTextData = nil,     
    LastAimbotConfigString = "",
    MagicUpdateVersion = 1,
    LastMagicConfigHash = "",
    PrevGraphicsState = {}
}

local function SafeAddMark(id, pos, z, str, size, actor)
    local mark = nil
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
            mark = InGameMarkTools.ClientAddMapMark(id, pos, z, str, size, actor)
            if mark then _G.LexusState.TrackedMarks[mark] = true end
        end
    end)
    return mark
end

local function SafeRemoveMark(mark)
    if not mark then return end
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.HideMapMark then
            InGameMarkTools.HideMapMark(mark)
        end
        if InGameMarkTools and InGameMarkTools.RemoveMapMark then
            InGameMarkTools.RemoveMapMark(mark)
        end
    end)
    _G.LexusState.TrackedMarks[mark] = nil
end

local function GetSafeEnemyKey(enemy)
    if Valid(enemy) then
        if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
        if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
    end
    return tostring(enemy)
end

local function CheckIsAI(pawn, markData)
    if markData.AK_IS_BOT ~= nil then return markData.AK_IS_BOT, true end
    
    local isAI = false
    local hasChecked = false
    pcall(function()
        if pawn.bIsAI == true or pawn.IsAI == true then isAI = true; hasChecked = true end
        if type(pawn.IsBot) == "function" and pawn:IsBot() then isAI = true; hasChecked = true end
        
        local pState = pawn.PlayerState or (type(pawn.GetPlayerState) == "function" and pawn:GetPlayerState())
        if Valid(pState) then
            hasChecked = true
            if pState.bIsABot == true or pState.bIsBot == true then isAI = true end
            if type(pState.IsBot) == "function" and pState:IsBot() then isAI = true end
        end
        
        if not isAI then
            local name = pawn.PlayerName or (type(pawn.GetPlayerName) == "function" and pawn:GetPlayerName()) or ""
            if name ~= "" and (name:find("Cobra") or name:find("Target") or name:find("bot_") or name:find("b_")) then
                isAI = true
                hasChecked = true
            end
        end
    end)
    if hasChecked then markData.AK_IS_BOT = isAI end
    return isAI, hasChecked
end

function _G.InitializeAutoHeadHooks()
    pcall(function()
        local EAvatarDamagePosition = import("EAvatarDamagePosition")
        if not EAvatarDamagePosition then return end

        local modulesToHook = {
            "GameLua.Mod.BaseMod.Common.Weapon.ShootWeaponEntity",
            "GameLua.Logic.Weapon.ShootWeaponEntity"
        }
        
        for _, path in ipairs(modulesToHook) do
            local hitLogic = package.loaded[path]
            if hitLogic then
                local original_GetHitBodyType = hitLogic.GetHitBodyType
                hitLogic.GetHitBodyType = function(self, ImpactResult, InImpactVec)
                    if _G.LexusConfig.AutoHead then return EAvatarDamagePosition.BigHead end
                    if original_GetHitBodyType then return original_GetHitBodyType(self, ImpactResult, InImpactVec) end
                end

                local original_GetHitBodyTypeByHitPos = hitLogic.GetHitBodyTypeByHitPos
                hitLogic.GetHitBodyTypeByHitPos = function(self, InImpactVec)
                    if _G.LexusConfig.AutoHead then return EAvatarDamagePosition.BigHead end
                    if original_GetHitBodyTypeByHitPos then return original_GetHitBodyTypeByHitPos(self, InImpactVec) end
                end
            end
        end
    end)
end

-- Config save/load paths (settings)
local function GetConfigPaths(fileName)
    local paths = {
        "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/" .. fileName,
        "/com.tencent.ig/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "/com.vng.pubgmobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "/com.pubg.krmobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "/com.rekoo.pubgm/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "/com.pubg.imobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "../../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "../../../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
        fileName
    }
    pcall(function()
        if os and os.getenv then
            local homeDir = os.getenv("HOME")
            if homeDir and homeDir ~= "" then
                table.insert(paths, 1, homeDir .. "/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName)
                table.insert(paths, 2, homeDir .. "/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/" .. fileName)
            end
        end
    end)
    return paths
end

local ConfigFileName = "mod_settings.txt"
_G.LastConfigSaveStr = ""

_G.SaveModSettings = function()
    pcall(function()
        local data = "return {\nLexusConfig = {\n"
        for k, v in pairs(_G.LexusConfig or {}) do
            data = data .. "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
        end
        data = data .. "},\nCustomTextData = {\n"
        if _G.LexusState and _G.LexusState.CustomTextData then
            for k, v in pairs(_G.LexusState.CustomTextData) do
                data = data .. "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
            end
        end
        data = data .. "}\n}"
        
        if data == _G.LastConfigSaveStr then return end
        _G.LastConfigSaveStr = data

        local paths = GetConfigPaths(ConfigFileName)
        for _, path in ipairs(paths) do
            local file = io.open(path, "w")
            if file then
                file:write(data)
                file:close()
                break
            end
        end
    end)
end

_G.LoadModSettings = function()
    pcall(function()
        local paths = GetConfigPaths(ConfigFileName)
        local content = nil
        for _, path in ipairs(paths) do
            local file = io.open(path, "r")
            if file then
                content = file:read("*a")
                file:close()
                break
            end
        end

        if content then
            local func = load(content)
            if func then
                local savedData = func()
                if savedData and type(savedData) == "table" then
                    if savedData.LexusConfig then
                        for k, v in pairs(savedData.LexusConfig) do
                            _G.LexusConfig[k] = v
                        end
                    end
                    if savedData.CustomTextData then
                        _G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {}
                        for k, v in pairs(savedData.CustomTextData) do
                            _G.LexusState.CustomTextData[k] = v
                        end
                    end
                end
            end
        end
        _G.SaveModSettings() 
    end)
end

local function AutoSaveLoop()
    pcall(function() if _G.SaveModSettings then _G.SaveModSettings() end end)
    pcall(function()
        local okTicker, ticker = pcall(require, "common.time_ticker") 
        if okTicker and ticker and ticker.AddTimerOnce then 
            ticker.AddTimerOnce(3.0, AutoSaveLoop)
        end
    end)
end

if not _G.ModConfigLoaded then
    _G.LoadModSettings()
    AutoSaveLoop()
    _G.ModConfigLoaded = true
end

_G.ReadLiveConfig = function()
    if _G.SaveModSettings then _G.SaveModSettings() end
end

function _G.InitModMenuTab()
    if _G.ModMenuInitialized then return end
    _G.ModMenuInitialized = true

    local function T(vnText, enText)
        return _G.LexusLang == "EN" and enText or vnText
    end

    _G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {
        OuterSpeed = 10, InnerSpeed = 10, OuterRecoil = 0, HRecoil = 0.3, VRecoil = 0.3, MagicHead = 1.0, MagicBody = 1.0, MagicLegs = 1.0, IpadViewFOV = 120, IpadViewVehicleFOV = 120, IpadViewScopeFOV = 60,
        AimTouchHipPrio = 1, AimTouchHipBone = 1, AimTouchHipCond = 1, AimTouchHipSpeed = 50, AimTouchHipFOV = 30, AimTouchHipDist = 250,
        AimTouchSGPrio = 1, AimTouchSGBone = 2, AimTouchSGCond = 1, AimTouchSGSpeed = 80, AimTouchSGFOV = 40, AimTouchSGDist = 30,
        AimTouchScopePrio = 1, AimTouchScopeBone = 2, AimTouchScopeCond = 1, AimTouchScopeSpeed = 40, AimTouchScopeFOV = 20, AimTouchScopeDist = 300, AimTouchScopePred = 0, AimTouchScopeRecoil = 0,
        AimTouchSniperPrio = 1, AimTouchSniperBone = 1, AimTouchSniperCond = 2, AimTouchSniperSpeed = 30, AimTouchSniperFOV = 20, AimTouchSniperDist = 400, AimTouchSniperPred = 0,
        AimTouchMortarPred = 0,
        AimTouchMortarFOV = 360,
        AimTouchHipFOVColor = 7, AimTouchSGFOVColor = 1, AimTouchScopeFOVColor = 6, AimTouchSniperFOVColor = 4, AimTouchMortarFOVColor = 5,
        BugManRatio = 133,
        FastCarSpeed = 2000,
        ColorV3Hidden = 1, ColorV3Visible = 2, ColorV3Thickness = 4, OutlineColor = 4,
        EspFovCircle_Color = 7,
        Esp9_LineThick = 1, Esp9_LineVisColor = 2, Esp9_LineHidColor = 1,
        Esp9_SkelThick = 1, Esp9_SkelVisColor = 2, Esp9_SkelHidColor = 1
    }

    local LocUtil = _G.LocUtil
    if not LocUtil and package.loaded["client.common.LocUtil"] then
        LocUtil = require("client.common.LocUtil")
    end
    
    local FakeTextMap = {
        [999000] = T(" MOD VIP", "VIP MOD"),
        [999001] = T("HIỂN THỊ (ESP)", "VISUALS (ESP)"),
        [999002] = T("AIMBOT GỐC & ĐẠN", "NATIVE AIMBOT & BULLET TRACK"),
        [999003] = T("AIMBOT ROYAL - CUSTOM ( Aim Gần - Aim Scope )", "CUSTOM AIMBOT (Close & Scope)"),
        [999004] = T("HỖ TRỢ & ĐỒ HỌA", "SUPPORT & GRAPHICS")
    }

    if LocUtil and not LocUtil._IsModMenuHooked_V2 then
        local hookFuncs = {"GetLocalizeResStr", "GetText", "GetTextByID", "GetLocalText", "GetLocalizeStr"}
        for _, funcName in ipairs(hookFuncs) do
            if LocUtil[funcName] then
                local old_func = LocUtil[funcName]
                LocUtil[funcName] = function(id)
                    if FakeTextMap[id] then
                        return FakeTextMap[id]
                    end
                    if type(id) == "string" and not tonumber(id) then
                        return id
                    end
                    if old_func then
                        return old_func(id)
                    end
                    return ""
                end
            end
        end
        LocUtil._IsModMenuHooked_V2 = true
    end

    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
    
    if not SettingPageDefine.ModMenu then
        local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")
        
        local StackESP = {
            { Key = "ModMenu_ESP1", UI = AliasMap.Switcher, Text = T("ESP Loại 1 (Cảnh báo 360-Máu-Tên) ", "ESP Type 1 (360 Alert-HP-Name) "), GetFunc = function() return _G.LexusConfig.EspVip end, SetFunc = function(c,v) _G.LexusConfig.EspVip = v return true end },
            { Key = "ModMenu_ESP2", UI = AliasMap.Switcher, Text = T("ESP Loại 2 (Khoảng cách mét) ", "ESP Type 2 (Distance Meter) "), GetFunc = function() return _G.LexusConfig.EspDistance end, SetFunc = function(c,v) _G.LexusConfig.EspDistance = v return true end },
            
            { Key = "ModMenu_ESP3_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ ESP Loại 3 (Máu Dọc & Tên) ", "▶ ESP Type 3 (Vertical HP & Name) "), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.EspVipPro end, SetFunc = function(c,v) _G.LexusConfig.EspVipPro = v return true end },
            { Key = "ModMenu_ESP3_Name", UI = AliasMap.Switcher, Text = T("   Hiện Tên Người Chơi ", "   Show Player Name "), ExpandHandle = "ModMenu_ESP3_Ex", GetFunc = function() return _G.LexusConfig.Esp3ShowName end, SetFunc = function(c,v) _G.LexusConfig.Esp3ShowName = v return true end },
            { Key = "ModMenu_ESP3_HP", UI = AliasMap.Switcher, Text = T("   Hiện Thanh Máu Dọc ", "   Show Vertical HP Bar "), ExpandHandle = "ModMenu_ESP3_Ex", GetFunc = function() return _G.LexusConfig.Esp3ShowHP end, SetFunc = function(c,v) _G.LexusConfig.Esp3ShowHP = v return true end },
            
            { Key = "ModMenu_ESP4", UI = AliasMap.Switcher, Text = T("ESP Loại 4 (Radar 360) ", "ESP Type 4 (Radar 360) "), GetFunc = function() return _G.LexusConfig.EspRadar end, SetFunc = function(c,v) _G.LexusConfig.EspRadar = v return true end },
            { Key = "ModMenu_ESP5", UI = AliasMap.Switcher, Text = T("ESP Loại 5 (Khung Box) ", "ESP Type 5 (Box ESP) "), GetFunc = function() return _G.LexusConfig.EspLoai5 end, SetFunc = function(c,v) _G.LexusConfig.EspLoai5 = v return true end },
            { Key = "ModMenu_ESP6", UI = AliasMap.Switcher, Text = T("ESP Loại 6 (Xương) ", "ESP Type 6 (Skeleton) "), GetFunc = function() return _G.LexusConfig.EspLoai6 end, SetFunc = function(c,v) _G.LexusConfig.EspLoai6 = v return true end },
            { Key = "ModMenu_ESP7_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ ESP Loại 7 (Thông Tin Chi Tiết) ", "▶ ESP Type 7 (Detail Info) "), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.EspLoai7 end, SetFunc = function(c,v) _G.LexusConfig.EspLoai7 = v return true end },
            { Key = "ModMenu_ESP7_SoLuong", UI = AliasMap.Switcher, Text = T("   Hiện Số Lượng Địch Xung Quanh ", "   Show Enemies Count Around "), ExpandHandle = "ModMenu_ESP7_Ex", GetFunc = function() return _G.LexusConfig.Esp7_SoLuong end, SetFunc = function(c,v) _G.LexusConfig.Esp7_SoLuong = v return true end },
            { Key = "ModMenu_ESP7_VuKhi", UI = AliasMap.Switcher, Text = T("   Hiện Vũ Khí Địch Cầm ", "   Show Enemy Weapon "), ExpandHandle = "ModMenu_ESP7_Ex", GetFunc = function() return _G.LexusConfig.Esp7_VuKhi end, SetFunc = function(c,v) _G.LexusConfig.Esp7_VuKhi = v return true end },
            { Key = "ModMenu_ESP7_TuThe", UI = AliasMap.Switcher, Text = T("   Hiện Tư Thế (Đứng/Ngồi/Nằm) ", "   Show Posture (Stand/Crouch/Prone) "), ExpandHandle = "ModMenu_ESP7_Ex", GetFunc = function() return _G.LexusConfig.Esp7_TuThe end, SetFunc = function(c,v) _G.LexusConfig.Esp7_TuThe = v return true end },
            { Key = "ModMenu_EspAimWarning", UI = AliasMap.Switcher, Text = T("   Cảnh Báo Địch Ngắm Bắn ", "   Enemy Aim Warning "), ExpandHandle = "ModMenu_ESP7_Ex", GetFunc = function() return _G.LexusConfig.EspAimWarning end, SetFunc = function(c,v) _G.LexusConfig.EspAimWarning = v return true end },
            { Key = "ModMenu_EspAimWarning_Vis", UI = AliasMap.Switcher, Text = T("      Check Tường (Chỉ báo khi lộ diện) ", "      Visibility Check "), ExpandHandle = "ModMenu_ESP7_Ex", GetFunc = function() return _G.LexusConfig.EspAimWarningVisCheck end, SetFunc = function(c,v) _G.LexusConfig.EspAimWarningVisCheck = v return true end },
            { Key = "ModMenu_ESP8", UI = AliasMap.Switcher, Text = T("ESP Loại 8 (Thanh Máu Gắn Đầu) ", "ESP Type 8 (Head HP Bar) "), GetFunc = function() return _G.LexusConfig.EspLoai8 end, SetFunc = function(c,v) _G.LexusConfig.EspLoai8 = v return true end },
            
            { Key = "ModMenu_EspItem_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ ESP Vật Phẩm (Dưới 70m) ", "▶ Item ESP (Under 70m) "), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.EspItem_Master end, SetFunc = function(c,v) _G.LexusConfig.EspItem_Master = v return true end },
            { Key = "ModMenu_EspItem_AR", UI = AliasMap.Switcher, Text = T("   Hiện Súng AR ", "   Show AR Weapons "), ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.LexusConfig.EspItem_AR end, SetFunc = function(c,v) _G.LexusConfig.EspItem_AR = v return true end },
            { Key = "ModMenu_EspItem_Sniper", UI = AliasMap.Switcher, Text = T("   Hiện Súng Ngắm ", "   Show Sniper Rifles "), ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.LexusConfig.EspItem_Sniper end, SetFunc = function(c,v) _G.LexusConfig.EspItem_Sniper = v return true end },
            { Key = "ModMenu_EspItem_SMG", UI = AliasMap.Switcher, Text = T("   Hiện Súng SMG ", "   Show SMGs "), ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.LexusConfig.EspItem_SMG end, SetFunc = function(c,v) _G.LexusConfig.EspItem_SMG = v return true end },
            { Key = "ModMenu_EspItem_Shotgun", UI = AliasMap.Switcher, Text = T("   Hiện Shotgun ", "   Show Shotguns "), ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.LexusConfig.EspItem_Shotgun end, SetFunc = function(c,v) _G.LexusConfig.EspItem_Shotgun = v return true end },
            { Key = "ModMenu_EspItem_LMG", UI = AliasMap.Switcher, Text = T("   Hiện Súng Máy LMG ", "   Show LMGs "), ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.LexusConfig.EspItem_LMG end, SetFunc = function(c,v) _G.LexusConfig.EspItem_LMG = v return true end },
            { Key = "ModMenu_EspItem_Pistol", UI = AliasMap.Switcher, Text = T("   Hiện Súng Lục / Pháo ", "   Show Pistols / Flares "), ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.LexusConfig.EspItem_Pistol end, SetFunc = function(c,v) _G.LexusConfig.EspItem_Pistol = v return true end },
            { Key = "ModMenu_EspItem_Melee", UI = AliasMap.Switcher, Text = T("   Hiện Cận Chiến ", "   Show Melee Weapons "), ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.LexusConfig.EspItem_Melee end, SetFunc = function(c,v) _G.LexusConfig.EspItem_Melee = v return true end },
            { Key = "ModMenu_EspItem_Special", UI = AliasMap.Switcher, Text = T("   Hiện Vũ Khí Đặc Biệt ", "   Show Special Weapons "), ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.LexusConfig.EspItem_Special end, SetFunc = function(c,v) _G.LexusConfig.EspItem_Special = v return true end },
            { Key = "ModMenu_EspItem_Scope", UI = AliasMap.Switcher, Text = T("   Hiện Ống Ngắm ", "   Show Scopes "), ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.LexusConfig.EspItem_Scope end, SetFunc = function(c,v) _G.LexusConfig.EspItem_Scope = v return true end },
            { Key = "ModMenu_EspItem_Grenade", UI = AliasMap.Switcher, Text = T("   Hiện Lựu Đạn ", "   Show Grenades "), ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.LexusConfig.EspItem_Grenade end, SetFunc = function(c,v) _G.LexusConfig.EspItem_Grenade = v return true end },
            { Key = "ModMenu_EspItem_Med", UI = AliasMap.Switcher, Text = T("   Hiện Máu & Nước (Y Tế) ", "   Show Medkits/Boosters "), ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.LexusConfig.EspItem_Med end, SetFunc = function(c,v) _G.LexusConfig.EspItem_Med = v return true end },
            
            { Key = "ModMenu_ESPBom_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ Cảnh Báo & Định Vị Bom ", "▶ Grenade Warning & Tracker "), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.EspBomMaster end, SetFunc = function(c,v) _G.LexusConfig.EspBomMaster = v return true end },
            { Key = "ModMenu_ESPItemBom", UI = AliasMap.Switcher, Text = T("   Định Vị Vật Phẩm Bom Dưới Đất ", "   Show Grenades On Ground "), ExpandHandle = "ModMenu_ESPBom_Ex", GetFunc = function() return _G.LexusConfig.EspItemBom end, SetFunc = function(c,v) _G.LexusConfig.EspItemBom = v return true end },
            { Key = "ModMenu_ESPActiveBom", UI = AliasMap.Switcher, Text = T("   Cảnh Báo Địch Cầm & Ném Bom ", "   Active Grenade Warning "), ExpandHandle = "ModMenu_ESPBom_Ex", GetFunc = function() return _G.LexusConfig.EspActiveBom end, SetFunc = function(c,v) _G.LexusConfig.EspActiveBom = v return true end },
            
            { Key = "ModMenu_ESPVehicle_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ ESP Định Vị Xe ", "▶ Vehicle ESP "), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.EspVehicle end, SetFunc = function(c,v) _G.LexusConfig.EspVehicle = v return true end },
            { Key = "ModMenu_ESPVeh_Dacia", UI = AliasMap.Switcher, Text = T("   Hiện Xe Con (Dacia) ", "   Show Dacia "), ExpandHandle = "ModMenu_ESPVehicle_Ex", GetFunc = function() return _G.LexusConfig.EspVeh_Dacia end, SetFunc = function(c,v) _G.LexusConfig.EspVeh_Dacia = v return true end },
            { Key = "ModMenu_ESPVeh_UAZ", UI = AliasMap.Switcher, Text = T("   Hiện Xe Jeep (UAZ) ", "   Show UAZ "), ExpandHandle = "ModMenu_ESPVehicle_Ex", GetFunc = function() return _G.LexusConfig.EspVeh_UAZ end, SetFunc = function(c,v) _G.LexusConfig.EspVeh_UAZ = v return true end },
            { Key = "ModMenu_ESPVeh_Buggy", UI = AliasMap.Switcher, Text = T("   Hiện Xe Buggy ", "   Show Buggy "), ExpandHandle = "ModMenu_ESPVehicle_Ex", GetFunc = function() return _G.LexusConfig.EspVeh_Buggy end, SetFunc = function(c,v) _G.LexusConfig.EspVeh_Buggy = v return true end },
            { Key = "ModMenu_ESPVeh_Coupe", UI = AliasMap.Switcher, Text = T("   Hiện Xe Thể Thao (Coupe RB) ", "   Show Coupe RB "), ExpandHandle = "ModMenu_ESPVehicle_Ex", GetFunc = function() return _G.LexusConfig.EspVeh_Coupe end, SetFunc = function(c,v) _G.LexusConfig.EspVeh_Coupe = v return true end },
            { Key = "ModMenu_ESPVeh_Mirado", UI = AliasMap.Switcher, Text = T("   Hiện Xe Mirado ", "   Show Mirado "), ExpandHandle = "ModMenu_ESPVehicle_Ex", GetFunc = function() return _G.LexusConfig.EspVeh_Mirado end, SetFunc = function(c,v) _G.LexusConfig.EspVeh_Mirado = v return true end },
            { Key = "ModMenu_ESPVeh_Motor", UI = AliasMap.Switcher, Text = T("   Hiện Xe Máy (Motor/Scooter) ", "   Show Motorcycles "), ExpandHandle = "ModMenu_ESPVehicle_Ex", GetFunc = function() return _G.LexusConfig.EspVeh_Motor end, SetFunc = function(c,v) _G.LexusConfig.EspVeh_Motor = v return true end },
            { Key = "ModMenu_ESPVeh_Other", UI = AliasMap.Switcher, Text = T("   Hiện Xe Khác (Thuyền/BRDM...) ", "   Show Others (Boat/BRDM) "), ExpandHandle = "ModMenu_ESPVehicle_Ex", GetFunc = function() return _G.LexusConfig.EspVeh_Other end, SetFunc = function(c,v) _G.LexusConfig.EspVeh_Other = v return true end },
            
            { Key = "ModMenu_ESPAntenna", UI = AliasMap.Switcher, Text = T("ESP Antenna (Cột) ", "Antenna ESP "), GetFunc = function() return _G.LexusConfig.EspAntenna end, SetFunc = function(c,v) _G.LexusConfig.EspAntenna = v return true end },
            { Key = "ModMenu_ESPOutline_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ ESP Viền Địch (Bật HDR sẽ sáng) ", "▶ Outline ESP (HDR supported) "), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.EspOutline end, SetFunc = function(c,v) _G.LexusConfig.EspOutline = v return true end },
            { Key = "ModMenu_ESPOutline_Color", UI = AliasMap.Slider, Text = T("   Màu Viền (1:Đỏ 2:Lục 3:Lam 4:Vàng 5:Tím 6:Trắng) ", "   Color (1:Red 2:Grn 3:Blu 4:Ylw 5:Pur 6:Wht) "), ExpandHandle = "ModMenu_ESPOutline_Ex", MinValue = 1, MaxValue = 6, GetFunc = function() return _G.LexusState.CustomTextData.OutlineColor or 4 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.OutlineColor = v return true end },
            { Key = "ModMenu_ESPOutline_Thickness", UI = AliasMap.Slider, Text = T("   Độ Dày Viền ", "   Outline Thickness "), ExpandHandle = "ModMenu_ESPOutline_Ex", MinValue = 1, MaxValue = 20, min = 1, max = 20, GetFunc = function() return _G.LexusConfig.OutlineThickness end, SetFunc = function(c,v) _G.LexusConfig.OutlineThickness = v return true end }
        }

        local StackAimbot = {
            { Key = "ModMenu_Aimbot_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ Aimbot Xa Tùy Chỉnh", "▶ Custom Long Range Aimbot"), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.CustomAimbot end, SetFunc = function(c,v) _G.LexusConfig.CustomAimbot = v return true end },
            { Key = "ModMenu_Aimbot_Speed", UI = AliasMap.Slider, Text = T("   Tốc Độ Aimbot Xa", "   Long Range Speed"), ExpandHandle = "ModMenu_Aimbot_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.OuterSpeed end, SetFunc = function(c,v) _G.LexusState.CustomTextData.OuterSpeed = v return true end },
            { Key = "ModMenu_Aimbot_Recoil", UI = AliasMap.Slider, Text = T("   Bù Giật Ghìm Tâm", "   Recoil Compensation"), ExpandHandle = "ModMenu_Aimbot_Ex", MinValue = 0, MaxValue = 50, min = 0, max = 50, GetFunc = function() return _G.LexusState.CustomTextData.OuterRecoil or 0 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.OuterRecoil = v return true end },

            { Key = "ModMenu_AimbotClose_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ Aimbot Gần Tùy Chỉnh", "▶ Custom Close Range Aimbot"), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.CustomAimbotClose end, SetFunc = function(c,v) _G.LexusConfig.CustomAimbotClose = v return true end },
            { Key = "ModMenu_AimbotClose_Speed", UI = AliasMap.Slider, Text = T("   Tốc Độ Aimbot Gần", "   Close Range Speed"), ExpandHandle = "ModMenu_AimbotClose_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.InnerSpeed end, SetFunc = function(c,v) _G.LexusState.CustomTextData.InnerSpeed = v return true end },

            { Key = "ModMenu_Magic_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ DỄ BỊ BAN MẠNG Magic Bullet Tùy Chỉnh", "▶ (RISK BAN) Custom Magic Bullet"), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.CustomMagicBullet end, SetFunc = function(c,v) _G.LexusConfig.CustomMagicBullet = v return true end },
            { Key = "ModMenu_Magic_Head", UI = AliasMap.Slider, Text = T("   Sát Thương Đầu (0.0 - 5.0)", "   Head Damage (0.0 - 5.0)"), ExpandHandle = "ModMenu_Magic_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return math.floor(((_G.LexusState.CustomTextData.MagicHead or 1.0) / 5.0) * 100 + 0.5) end, SetFunc = function(c,v) _G.LexusState.CustomTextData.MagicHead = (v / 100.0) * 5.0 return true end },
            { Key = "ModMenu_Magic_Body", UI = AliasMap.Slider, Text = T("   Sát Thương Thân (0.0 - 5.0)", "   Body Damage (0.0 - 5.0)"), ExpandHandle = "ModMenu_Magic_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return math.floor(((_G.LexusState.CustomTextData.MagicBody or 1.0) / 5.0) * 100 + 0.5) end, SetFunc = function(c,v) _G.LexusState.CustomTextData.MagicBody = (v / 100.0) * 5.0 return true end },
            { Key = "ModMenu_Magic_Legs", UI = AliasMap.Slider, Text = T("   Sát Thương Chân (0.0 - 5.0)", "   Legs Damage (0.0 - 5.0)"), ExpandHandle = "ModMenu_Magic_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return math.floor(((_G.LexusState.CustomTextData.MagicLegs or 1.0) / 5.0) * 100 + 0.5) end, SetFunc = function(c,v) _G.LexusState.CustomTextData.MagicLegs = (v / 100.0) * 5.0 return true end },

            { Key = "ModMenu_HRecoil_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ Giảm Giật Ngang (Drop súng nhặt lại để load)", "▶ Less Horizontal Recoil (Drop/Pick weapon)"), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.CustomHRecoil end, SetFunc = function(c,v) _G.LexusConfig.CustomHRecoil = v return true end },
            { Key = "ModMenu_HRecoil_Val", UI = AliasMap.Slider, Text = T("   Chỉ Số Giật Ngang", "   Horizontal Recoil Value"), ExpandHandle = "ModMenu_HRecoil_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return math.floor((((_G.LexusState.CustomTextData.HRecoil or 0.3) - 0.3) / 4.7) * 100 + 0.5) end, SetFunc = function(c,v) _G.LexusState.CustomTextData.HRecoil = 0.3 + (v / 100.0) * 4.7 return true end },

            { Key = "ModMenu_VRecoil_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ Giảm Giật Dọc (Drop súng nhặt lại để load)", "▶ Less Vertical Recoil (Drop/Pick weapon)"), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.CustomVRecoil end, SetFunc = function(c,v) _G.LexusConfig.CustomVRecoil = v return true end },
            { Key = "ModMenu_VRecoil_Val", UI = AliasMap.Slider, Text = T("   Chỉ Số Giật Dọc", "   Vertical Recoil Value"), ExpandHandle = "ModMenu_VRecoil_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return math.floor((((_G.LexusState.CustomTextData.VRecoil or 0.3) - 0.3) / 4.7) * 100 + 0.5) end, SetFunc = function(c,v) _G.LexusState.CustomTextData.VRecoil = 0.3 + (v / 100.0) * 4.7 return true end },

            { Key = "ModMenu_LessShake", UI = AliasMap.Switcher, Text = T("Giảm Rung Nẩy Scope", "Less Scope Shake"), GetFunc = function() return _G.LexusConfig.LessShake end, SetFunc = function(c,v) _G.LexusConfig.LessShake = v return true end },
            { Key = "ModMenu_Accuracy", UI = AliasMap.Switcher, Text = T("Đạn Thẳng Tắp", "100% Accuracy"), GetFunc = function() return _G.LexusConfig.Accuracy end, SetFunc = function(c,v) _G.LexusConfig.Accuracy = v return true end },
            { Key = "ModMenu_Crosshair", UI = AliasMap.Switcher, Text = T("Tâm Súng Nhỏ", "Small Crosshair"), GetFunc = function() return _G.LexusConfig.Crosshair end, SetFunc = function(c,v) _G.LexusConfig.Crosshair = v return true end },
            { Key = "ModMenu_AutoHead", UI = AliasMap.Switcher, Text = T("Aimbot Head", "Aimbot Head"), GetFunc = function() return _G.LexusConfig.AutoHead end, SetFunc = function(c,v) _G.LexusConfig.AutoHead = v return true end },
            { Key = "ModMenu_GodMode", UI = AliasMap.Switcher, Text = T("Hủy Diệt (Bắn Siêu Nhanh)", "God Mode (Fast Shoot)"), GetFunc = function() return _G.LexusConfig.GodMode end, SetFunc = function(c,v) _G.LexusConfig.GodMode = v return true end }
        }

        local StackAimbotV2 = {
            { Key = "ModMenu_AT_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ Bật Aimbot Roy & Custom", "▶ Enable Custom Aimbot V2"), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.AimTouchEnable end, SetFunc = function(c,v) _G.LexusConfig.AimTouchEnable = v return true end },
            { Key = "ModMenu_FovCircle_Main", UI = AliasMap.Switcher, Text = T("▶ HIỂN THỊ VÒNG FOV AIMBOT TREN MÀN HÌNH", "▶ SHOW AIMBOT FOV CIRCLE"), GetFunc = function() return _G.LexusConfig.EspFovCircle end, SetFunc = function(c,v) _G.LexusConfig.EspFovCircle = v return true end },
            
            { Key = "ModMenu_AT_Hip_Ex", UI = AliasMap.TitleSwitcher, Text = T("   ▶ Aimbot Tâm Trắng", "   ▶ Hipfire Aimbot"), ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.AimTouchHipfire end, SetFunc = function(c,v) _G.LexusConfig.AimTouchHipfire = v return true end },
            { Key = "ModMenu_AT_Hip_IgKnock", UI = AliasMap.Switcher, Text = T("      Bỏ Qua Địch Knock", "      Ignore Knocked"), ExpandHandle = "ModMenu_AT_Hip_Ex", GetFunc = function() return _G.LexusConfig.AimTouchHipIgKnock end, SetFunc = function(c,v) _G.LexusConfig.AimTouchHipIgKnock = v return true end },
            { Key = "ModMenu_AT_Hip_IgBot", UI = AliasMap.Switcher, Text = T("      Bỏ Qua Bot", "      Ignore Bots"), ExpandHandle = "ModMenu_AT_Hip_Ex", GetFunc = function() return _G.LexusConfig.AimTouchHipIgBot end, SetFunc = function(c,v) _G.LexusConfig.AimTouchHipIgBot = v return true end },
            { Key = "ModMenu_AT_Hip_Vis", UI = AliasMap.Switcher, Text = T("      Check Tường (VisCheck)", "      Visibility Check"), ExpandHandle = "ModMenu_AT_Hip_Ex", GetFunc = function() return _G.LexusConfig.AimTouchHipVisCheck end, SetFunc = function(c,v) _G.LexusConfig.AimTouchHipVisCheck = v return true end },
            { Key = "ModMenu_AT_Hip_Prio", UI = AliasMap.Slider, Text = T("      Ưu Tiên (1:Tâm 2:Gần 3:HP)", "      Priority (1:Crosshair 2:Distance 3:HP)"), ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchHipPrio or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.LexusState.CustomTextData.AimTouchHipPrio = val return true end },
            { Key = "ModMenu_AT_Hip_Bone", UI = AliasMap.Slider, Text = T("      Vị Trí (1:Đầu 2:Ngực 3:Bụng 4:Hông)", "      Bone (1:Head 2:Chest 3:Stomach 4:Pelvis)"), ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchHipBone or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.LexusState.CustomTextData.AimTouchHipBone = val return true end },
            { Key = "ModMenu_AT_Hip_Cond", UI = AliasMap.Slider, Text = T("      Điều Kiện (1:Bắn mới Aim, 2:Luôn Aim)", "      Trigger (1:On Fire, 2:Always)"), ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 2, min = 1, max = 2, Min = 1, Max = 2, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchHipCond or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 2 then val = 2 end; _G.LexusState.CustomTextData.AimTouchHipCond = val return true end },
            { Key = "ModMenu_AT_Hip_Spd", UI = AliasMap.Slider, Text = T("      Độ Mượt / Tốc Độ (1-100)", "      Smoothness / Speed (1-100)"), ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchHipSpeed or 50 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchHipSpeed = v return true end },
            { Key = "ModMenu_AT_Hip_Dist", UI = AliasMap.Slider, Text = T("      Khoảng Cách (1-500m)", "      Distance Limit (1-500m)"), ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return math.floor((_G.LexusState.CustomTextData.AimTouchHipDist or 250) / 5) end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchHipDist = v * 5 return true end },
            { Key = "ModMenu_AT_Hip_FOV", UI = AliasMap.Slider, Text = T("      Vòng FOV (1-100)", "      FOV Radius (1-100)"), ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchHipFOV or 30 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchHipFOV = v return true end },
            { Key = "ModMenu_AT_Hip_FOVColor", UI = AliasMap.Slider, Text = T("      Màu Vòng FOV Tâm Trắng (1-7)", "      Circle Color (1-7)"), ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 7, min = 1, max = 7, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchHipFOVColor or 7 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchHipFOVColor = v return true end },

            { Key = "ModMenu_AT_SG_Ex", UI = AliasMap.TitleSwitcher, Text = T("   ▶ Aimbot Shotgun", "   ▶ Shotgun Aimbot"), ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.AimTouchSG end, SetFunc = function(c,v) _G.LexusConfig.AimTouchSG = v return true end },
            { Key = "ModMenu_AT_SG_AutoFire", UI = AliasMap.Switcher, Text = T("      Tự Động Bắn", "      Auto Fire"), ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.LexusConfig.AimTouchSGAutoFire end, SetFunc = function(c,v) _G.LexusConfig.AimTouchSGAutoFire = v return true end },
            { Key = "ModMenu_AT_SG_IgKnock", UI = AliasMap.Switcher, Text = T("      Bỏ Qua Địch Knock", "      Ignore Knocked"), ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.LexusConfig.AimTouchSGIgKnock end, SetFunc = function(c,v) _G.LexusConfig.AimTouchSGIgKnock = v return true end },
            { Key = "ModMenu_AT_SG_IgBot", UI = AliasMap.Switcher, Text = T("      Bỏ Qua Bot", "      Ignore Bots"), ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.LexusConfig.AimTouchSGIgBot end, SetFunc = function(c,v) _G.LexusConfig.AimTouchSGIgBot = v return true end },
            { Key = "ModMenu_AT_SG_Vis", UI = AliasMap.Switcher, Text = T("      Check Tường (VisCheck)", "      Visibility Check"), ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.LexusConfig.AimTouchSGVisCheck end, SetFunc = function(c,v) _G.LexusConfig.AimTouchSGVisCheck = v return true end },
            { Key = "ModMenu_AT_SG_Prio", UI = AliasMap.Slider, Text = T("      Ưu Tiên (1:Tâm 2:Gần 3:HP)", "      Priority (1:Crosshair 2:Distance 3:HP)"), ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSGPrio or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.LexusState.CustomTextData.AimTouchSGPrio = val return true end },
            { Key = "ModMenu_AT_SG_Bone", UI = AliasMap.Slider, Text = T("      Vị Trí (1:Đầu 2:Ngực 3:Bụng 4:Hông)", "      Bone (1:Head 2:Chest 3:Stomach 4:Pelvis)"), ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSGBone or 2 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.LexusState.CustomTextData.AimTouchSGBone = val return true end },
            { Key = "ModMenu_AT_SG_Cond", UI = AliasMap.Slider, Text = T("      Điều Kiện (1:Bắn mới Aim, 2:Luôn Aim)", "      Trigger (1:On Fire, 2:Always)"), ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 2, min = 1, max = 2, Min = 1, Max = 2, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSGCond or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 2 then val = 2 end; _G.LexusState.CustomTextData.AimTouchSGCond = val return true end },
            { Key = "ModMenu_AT_SG_Spd", UI = AliasMap.Slider, Text = T("      Độ Mượt / Tốc Độ (1-100)", "      Smoothness / Speed (1-100)"), ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSGSpeed or 80 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchSGSpeed = v return true end },
            { Key = "ModMenu_AT_SG_Dist", UI = AliasMap.Slider, Text = T("      Khoảng Cách (1-100m)", "      Distance Limit (1-100m)"), ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSGDist or 30 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchSGDist = v return true end },
            { Key = "ModMenu_AT_SG_FOV", UI = AliasMap.Slider, Text = T("      Vòng FOV (1-100)", "      FOV Radius (1-100)"), ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSGFOV or 40 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchSGFOV = v return true end },
            { Key = "ModMenu_AT_SG_FOVColor", UI = AliasMap.Slider, Text = T("      Màu Vòng FOV Shotgun (1-7)", "      Circle Color (1-7)"), ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 7, min = 1, max = 7, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSGFOVColor or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchSGFOVColor = v return true end },
            
            { Key = "ModMenu_AT_ScopeAll_Ex", UI = AliasMap.TitleSwitcher, Text = T("   ▶ Aimbot Mở Scope", "   ▶ Scope Aimbot"), ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.AimTouchScopeAll end, SetFunc = function(c,v) _G.LexusConfig.AimTouchScopeAll = v return true end },
            { Key = "ModMenu_AT_ScopeAll_IgKnock", UI = AliasMap.Switcher, Text = T("      Bỏ Qua Địch Knock", "      Ignore Knocked"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", GetFunc = function() return _G.LexusConfig.AimTouchScopeIgKnock end, SetFunc = function(c,v) _G.LexusConfig.AimTouchScopeIgKnock = v return true end },
            { Key = "ModMenu_AT_ScopeAll_IgBot", UI = AliasMap.Switcher, Text = T("      Bỏ Qua Bot", "      Ignore Bots"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", GetFunc = function() return _G.LexusConfig.AimTouchScopeIgBot end, SetFunc = function(c,v) _G.LexusConfig.AimTouchScopeIgBot = v return true end },
            { Key = "ModMenu_AT_ScopeAll_Vis", UI = AliasMap.Switcher, Text = T("      Check Tường (VisCheck)", "      Visibility Check"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", GetFunc = function() return _G.LexusConfig.AimTouchScopeVisCheck end, SetFunc = function(c,v) _G.LexusConfig.AimTouchScopeVisCheck = v return true end },
            { Key = "ModMenu_AT_ScopeAll_Prio", UI = AliasMap.Slider, Text = T("      Ưu Tiên (1:Tâm 2:Gần 3:HP)", "      Priority (1:Crosshair 2:Distance 3:HP)"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchScopePrio or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.LexusState.CustomTextData.AimTouchScopePrio = val return true end },
            { Key = "ModMenu_AT_ScopeAll_Bone", UI = AliasMap.Slider, Text = T("      Vị Trí (1:Đầu 2:Ngực 3:Bụng 4:Hông)", "      Bone (1:Head 2:Chest 3:Stomach 4:Pelvis)"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchScopeBone or 2 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.LexusState.CustomTextData.AimTouchScopeBone = val return true end },
            { Key = "ModMenu_AT_ScopeAll_Cond", UI = AliasMap.Slider, Text = T("      Điều Kiện (1:Bắn mới Aim, 2:Luôn Aim)", "      Trigger (1:On Fire, 2:Always)"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 2, min = 1, max = 2, Min = 1, Max = 2, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchScopeCond or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 2 then val = 2 end; _G.LexusState.CustomTextData.AimTouchScopeCond = val return true end },
            { Key = "ModMenu_AT_ScopeAll_Spd", UI = AliasMap.Slider, Text = T("      Độ Mượt / Tốc Độ (1-100)", "      Smoothness / Speed (1-100)"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchScopeSpeed or 40 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchScopeSpeed = v return true end },
            { Key = "ModMenu_AT_ScopeAll_Dist", UI = AliasMap.Slider, Text = T("      Khoảng Cách (1-500m)", "      Distance Limit (1-500m)"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return math.floor((_G.LexusState.CustomTextData.AimTouchScopeDist or 300) / 5) end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchScopeDist = v * 5 return true end },
            { Key = "ModMenu_AT_ScopeAll_Pred", UI = AliasMap.Slider, Text = T("      Dự Đoán Hướng Chạy", "      Prediction Value"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchScopePred or 0 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchScopePred = v return true end },
            { Key = "ModMenu_AT_ScopeAll_Recoil", UI = AliasMap.Slider, Text = T("      Bù Giật Tự Động", "      Auto Recoil Comp."), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 0, MaxValue = 50, min = 0, max = 50, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchScopeRecoil or 0 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchScopeRecoil = v return true end },
            { Key = "ModMenu_AT_ScopeAll_FOV", UI = AliasMap.Slider, Text = T("      Vòng FOV (1-100)", "      FOV Radius (1-100)"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchScopeFOV or 20 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchScopeFOV = v return true end },
            { Key = "ModMenu_AT_ScopeAll_FOVColor", UI = AliasMap.Slider, Text = T("      Màu Vòng FOV Scope (1-7)", "      Circle Color (1-7)"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 7, min = 1, max = 7, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchScopeFOVColor or 6 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchScopeFOVColor = v return true end },

            { Key = "ModMenu_AT_Sniper_Ex", UI = AliasMap.TitleSwitcher, Text = T("   ▶ Aimbot Mở Scope (Súng Ngắm/Tỉa)", "   ▶ Sniper Aimbot"), ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.AimTouchScopeSniper end, SetFunc = function(c,v) _G.LexusConfig.AimTouchScopeSniper = v return true end },
            { Key = "ModMenu_AT_Sniper_IgKnock", UI = AliasMap.Switcher, Text = T("      Bỏ Qua Địch Knock", "      Ignore Knocked"), ExpandHandle = "ModMenu_AT_Sniper_Ex", GetFunc = function() return _G.LexusConfig.AimTouchSniperIgKnock end, SetFunc = function(c,v) _G.LexusConfig.AimTouchSniperIgKnock = v return true end },
            { Key = "ModMenu_AT_Sniper_IgBot", UI = AliasMap.Switcher, Text = T("      Bỏ Qua Bot", "      Ignore Bots"), ExpandHandle = "ModMenu_AT_Sniper_Ex", GetFunc = function() return _G.LexusConfig.AimTouchSniperIgBot end, SetFunc = function(c,v) _G.LexusConfig.AimTouchSniperIgBot = v return true end },
            { Key = "ModMenu_AT_Sniper_Vis", UI = AliasMap.Switcher, Text = T("      Check Tường (VisCheck)", "      Visibility Check"), ExpandHandle = "ModMenu_AT_Sniper_Ex", GetFunc = function() return _G.LexusConfig.AimTouchSniperVisCheck end, SetFunc = function(c,v) _G.LexusConfig.AimTouchSniperVisCheck = v return true end },
            { Key = "ModMenu_AT_Sniper_Prio", UI = AliasMap.Slider, Text = T("      Ưu Tiên (1:Tâm 2:Gần 3:HP)", "      Priority (1:Crosshair 2:Distance 3:HP)"), ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSniperPrio or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.LexusState.CustomTextData.AimTouchSniperPrio = val return true end },
            { Key = "ModMenu_AT_Sniper_Bone", UI = AliasMap.Slider, Text = T("      Vị Trí (1:Đầu 2:Ngực 3:Bụng 4:Hông)", "      Bone (1:Head 2:Chest 3:Stomach 4:Pelvis)"), ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSniperBone or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.LexusState.CustomTextData.AimTouchSniperBone = val return true end },
            { Key = "ModMenu_AT_Sniper_Cond", UI = AliasMap.Slider, Text = T("      Điều Kiện (1:Bắn mới Aim, 2:Luôn Aim)", "      Trigger (1:On Fire, 2:Always)"), ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 2, min = 1, max = 2, Min = 1, Max = 2, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSniperCond or 2 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 2 then val = 2 end; _G.LexusState.CustomTextData.AimTouchSniperCond = val return true end },
            { Key = "ModMenu_AT_Sniper_Spd", UI = AliasMap.Slider, Text = T("      Độ Mượt / Tốc Độ (1-100)", "      Smoothness / Speed (1-100)"), ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSniperSpeed or 30 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchSniperSpeed = v return true end },
            { Key = "ModMenu_AT_Sniper_Dist", UI = AliasMap.Slider, Text = T("      Khoảng Cách (1-500m)", "      Distance Limit (1-500m)"), ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return math.floor((_G.LexusState.CustomTextData.AimTouchSniperDist or 400) / 5) end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchSniperDist = v * 5 return true end },
            { Key = "ModMenu_AT_Sniper_Pred", UI = AliasMap.Slider, Text = T("      Dự Đoán Hướng Chạy (0-100)", "      Prediction Value (0-100)"), ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSniperPred or 0 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchSniperPred = v return true end },
            { Key = "ModMenu_AT_Sniper_FOV", UI = AliasMap.Slider, Text = T("      Vòng FOV (1-100)", "      FOV Radius (1-100)"), ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSniperFOV or 20 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchSniperFOV = v return true end },
            { Key = "ModMenu_AT_Sniper_FOVColor", UI = AliasMap.Slider, Text = T("      Màu Vòng FOV Ngắm/Tỉa (1-7)", "      Circle Color (1-7)"), ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 7, min = 1, max = 7, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSniperFOVColor or 4 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchSniperFOVColor = v return true end },

            { Key = "ModMenu_AT_Mortar_Ex", UI = AliasMap.TitleSwitcher, Text = T("   ▶ Aimbot Súng Cối (Mortar)", "   ▶ Mortar Aimbot"), ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.AimTouchMortar end, SetFunc = function(c,v) _G.LexusConfig.AimTouchMortar = v return true end },
            { Key = "ModMenu_AT_Mortar_Pred", UI = AliasMap.Slider, Text = T("      Dự Đoán Hướng Chạy (0-100)", "      Prediction Value (0-100)"), ExpandHandle = "ModMenu_AT_Mortar_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchMortarPred or 0 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchMortarPred = v return true end },
            { Key = "ModMenu_AT_Mortar_FOV", UI = AliasMap.Slider, Text = T("      Vòng FOV (1-360)", "      FOV Radius (1-360)"), ExpandHandle = "ModMenu_AT_Mortar_Ex", MinValue = 1, MaxValue = 360, min = 1, max = 360, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchMortarFOV or 360 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchMortarFOV = v return true end },
            { Key = "ModMenu_AT_Mortar_FOVColor", UI = AliasMap.Slider, Text = T("      Màu Vòng FOV Cối (1-7)", "      Circle Color (1-7)"), ExpandHandle = "ModMenu_AT_Mortar_Ex", MinValue = 1, MaxValue = 7, min = 1, max = 7, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchMortarFOVColor or 5 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchMortarFOVColor = v return true end }
        }

        local StackCombat = {
            { Key = "ModMenu_FakeHWID", UI = AliasMap.Switcher, Text = T("Đổi HWID Ảo (Chống Ghim ID Thiết Bị)", "Fake HWID (Anti-Ban)"), GetFunc = function() return _G.LexusConfig.FakeHWID end, SetFunc = function(c,v) _G.LexusConfig.FakeHWID = v return true end },
            
            { Key = "ModMenu_Ipad_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ Ipad View", "▶ Ipad View"), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.IpadView end, SetFunc = function(c,v) _G.LexusConfig.IpadView = v return true end },
            { Key = "ModMenu_Ipad_FOV", UI = AliasMap.Slider, Text = T("   Góc Nhìn FOV", "   FOV Value"), ExpandHandle = "ModMenu_Ipad_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return (_G.LexusState.CustomTextData.IpadViewFOV or 120) - 90 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.IpadViewFOV = 90 + v return true end },

            { Key = "ModMenu_IpadVeh_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ Ipad View Lái Xe", "▶ Ipad View Vehicle"), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.IpadViewVehicle end, SetFunc = function(c,v) _G.LexusConfig.IpadViewVehicle = v return true end },
            { Key = "ModMenu_IpadVeh_FOV", UI = AliasMap.Slider, Text = T("   FOV Khi Lái Xe", "   Vehicle FOV Value"), ExpandHandle = "ModMenu_IpadVeh_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return (_G.LexusState.CustomTextData.IpadViewVehicleFOV or 120) - 90 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.IpadViewVehicleFOV = 90 + v return true end },

            { Key = "ModMenu_IpadScope_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ Ipad View Khi Mở Scope", "▶ Ipad View Scope"), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.IpadViewScope end, SetFunc = function(c,v) _G.LexusConfig.IpadViewScope = v return true end },
            { Key = "ModMenu_IpadScope_FOV", UI = AliasMap.Slider, Text = T("   FOV Khi Mở Scope (30-120)", "   Scope FOV (30-120)"), ExpandHandle = "ModMenu_IpadScope_Ex", MinValue = 30, MaxValue = 120, min = 30, max = 120, GetFunc = function() return _G.LexusState.CustomTextData.IpadViewScopeFOV or 60 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.IpadViewScopeFOV = v return true end },

            { Key = "ModMenu_BugMan_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ Kéo Dãn Màn Hình (Nhân Vật Mập)", "▶ Screen Stretch (Fat Body)"), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.BugManEnable end, SetFunc = function(c,v) _G.LexusConfig.BugManEnable = v return true end },
            { Key = "ModMenu_BugMan_Ratio", UI = AliasMap.Slider, Text = T("   Độ Kéo Dãn", "   Stretch Ratio"), ExpandHandle = "ModMenu_BugMan_Ex", MinValue = 110, MaxValue = 200, min = 110, max = 200, GetFunc = function() return _G.LexusState.CustomTextData.BugManRatio or 133 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.BugManRatio = v return true end },

            { Key = "ModMenu_165FPS", UI = AliasMap.Switcher, Text = T("Mở Khóa 165 FPS", "Unlock 165 FPS"), GetFunc = function() return _G.LexusConfig.UnlockFPS end, SetFunc = function(c,v) _G.LexusConfig.UnlockFPS = v; if v then _G.LexusState.GraphicsUnlocked = false end return true end },
            
            { Key = "ModMenu_WallXuyenTuong", UI = AliasMap.Switcher, Text = T("Wall Xuyên Tường V1 (Chỉ nhìn xuyên)", "Wallhack V1 (See through)"), GetFunc = function() return _G.LexusConfig.WallXuyenTuong end, SetFunc = function(c,v) _G.LexusConfig.WallXuyenTuong = v return true end },
            { Key = "ModMenu_ColorBodyV2", UI = AliasMap.Switcher, Text = T("Tô Màu Địch V2 (Chams Cơ Bản)", "Chams V2 (Basic Color)"), GetFunc = function() return _G.LexusConfig.ColorBodyV2 end, SetFunc = function(c,v) _G.LexusConfig.ColorBodyV2 = v return true end },
            { Key = "ModMenu_ColorBodyNew", UI = AliasMap.Switcher, Text = T("WALL MÀU NEW (Xanh/Đỏ Sáng Engine)", "NEW ENGINE CHAMS (Red/Green)"), GetFunc = function() return _G.LexusConfig.ColorBodyNew end, SetFunc = function(c,v) _G.LexusConfig.ColorBodyNew = v return true end },
            { Key = "ModMenu_ColorBodyV3_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ WALL V2 + MÀU V3 (Tùy Chỉnh Màu)", "▶ WALL V2 + CHAMS V3 (Custom)"), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.ColorBodyV3 end, SetFunc = function(c,v) _G.LexusConfig.ColorBodyV3 = v return true end },
            { Key = "ModMenu_V3_Hidden", UI = AliasMap.Slider, Text = T("   Màu Sau Tường (1:Đỏ 2:Lục 3:Lam 4:Vàng 5:Tím 6:Trắng)", "   Hidden Color (1:Red 2:Grn 3:Blu 4:Ylw 5:Pur 6:Wht)"), ExpandHandle = "ModMenu_ColorBodyV3_Ex", MinValue = 1, MaxValue = 6, GetFunc = function() return _G.LexusState.CustomTextData.ColorV3Hidden or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.ColorV3Hidden = v return true end },
            { Key = "ModMenu_V3_Vis", UI = AliasMap.Slider, Text = T("   Màu Lộ Diện (1:Đỏ 2:Lục 3:Lam 4:Vàng 5:Tím 6:Trắng)", "   Visible Color (1:Red 2:Grn 3:Blu 4:Ylw 5:Pur 6:Wht)"), ExpandHandle = "ModMenu_ColorBodyV3_Ex", MinValue = 1, MaxValue = 6, GetFunc = function() return _G.LexusState.CustomTextData.ColorV3Visible or 2 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.ColorV3Visible = v return true end },
            { Key = "ModMenu_V3_Thick", UI = AliasMap.Slider, Text = T("   Độ Dày Viền HDR Lộ Diện", "   HDR Outline Thickness"), ExpandHandle = "ModMenu_ColorBodyV3_Ex", MinValue = 1, MaxValue = 20, GetFunc = function() return _G.LexusState.CustomTextData.ColorV3Thickness or 4 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.ColorV3Thickness = v return true end },
            
            { Key = "ModMenu_WallVehicle", UI = AliasMap.Switcher, Text = T("Wall Phương Tiện", "Vehicle Wallhack"), GetFunc = function() return _G.LexusConfig.WallVehicle end, SetFunc = function(c,v) _G.LexusConfig.WallVehicle = v return true end },

            { Key = "ModMenu_WhiteBody", UI = AliasMap.Switcher, Text = T("Người Trắng", "White Body"), GetFunc = function() return _G.LexusConfig.WhiteBody end, SetFunc = function(c,v) _G.LexusConfig.WhiteBody = v return true end },
            { Key = "ModMenu_BlackSky", UI = AliasMap.Switcher, Text = T("Trời Tối (Black Sky)", "Black Sky"), GetFunc = function() return _G.LexusConfig.BlackSky end, SetFunc = function(c,v) _G.LexusConfig.BlackSky = v return true end },
            { Key = "ModMenu_RemoveFog", UI = AliasMap.Switcher, Text = T("Xóa Sương Mù", "Remove Fog"), GetFunc = function() return _G.LexusConfig.RemoveFog end, SetFunc = function(c,v) _G.LexusConfig.RemoveFog = v return true end },
            { Key = "ModMenu_RemoveGrass", UI = AliasMap.Switcher, Text = T("Xóa Cỏ", "Remove Grass"), GetFunc = function() return _G.LexusConfig.RemoveGrass end, SetFunc = function(c,v) _G.LexusConfig.RemoveGrass = v return true end },
            { Key = "ModMenu_RemoveTrees", UI = AliasMap.Switcher, Text = T("Xóa Cây", "Remove Trees"), GetFunc = function() return _G.LexusConfig.RemoveTrees end, SetFunc = function(c,v) _G.LexusConfig.RemoveTrees = v return true end },
            { Key = "ModMenu_WallClimb", UI = AliasMap.Switcher, Text = T("Leo Tường", "Wall Climb"), GetFunc = function() return _G.LexusConfig.WallClimb end, SetFunc = function(c,v) _G.LexusConfig.WallClimb = v return true end },
            { Key = "ModMenu_FastCar_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ Xe Nhanh Bay", "▶ Fast Car / Flying Car"), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.FastCar end, SetFunc = function(c,v) _G.LexusConfig.FastCar = v return true end },
            { Key = "ModMenu_FastCar_Speed", UI = AliasMap.Slider, Text = T("   Tốc Độ Xe Mức (1-100)", "   Car Speed Limit (1-100)"), ExpandHandle = "ModMenu_FastCar_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return math.floor((_G.LexusState.CustomTextData.FastCarSpeed or 3000) / 60) end, SetFunc = function(c,v) _G.LexusState.CustomTextData.FastCarSpeed = v * 60 return true end }
        }

        local menuCategories = {
            { Key = "Cat_ESP", Text = 999001, Stack = StackESP },
            { Key = "Cat_Aimbot", Text = 999002, Stack = StackAimbot },
            { Key = "Cat_AimbotV2", Text = 999003, Stack = StackAimbotV2 },
            { Key = "Cat_Combat", Text = 999004, Stack = StackCombat }
        }

        SettingPageDefine.ModMenu = {
            Key = "ModMenu",
            Text = 999000, 
            UIKey = "Setting_Page_Privacy", 
            Category = menuCategories
        }
        
        table.insert(SettingCatalog, 1, SettingPageDefine.ModMenu)
    end

    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsModMenuHooked then
        local old_ShowUI = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            local n = select('#', ...) 
            
            if config and config.keyName then
                local lowerKeyName = string.lower(config.keyName)
                if string.find(lowerKeyName, "setting_main") and not string.find(lowerKeyName, "custom") then
                    local catalog = args[1]
                    if type(catalog) == "table" and catalog[1] and type(catalog[1]) == "table" and catalog[1].Key then
                        local hasModMenu = false
                        for _, page in ipairs(catalog) do
                            if type(page) == "table" and page.Key == "ModMenu" then
                                hasModMenu = true
                                break
                            end
                        end
                        if not hasModMenu then
                            table.insert(catalog, 1, SettingPageDefine.ModMenu)
                        end
                    end
                end
            end
            local table_unpack = table.unpack or unpack
            return old_ShowUI(config, table_unpack(args, 1, n))
        end
        UIManager._IsModMenuHooked = true
    end
end

local function ShowLexusVIPMenu() 
    if _G.LexusMenuAlreadyShown then return end
    if _G.LexusState.MenuStep ~= 0 then return end

    pcall(function()
        local Msg = require("client.slua.logic.common.logic_common_msg_box")
        if not Msg or not Msg.Show then return end

        local function Step_Welcome()
            local title = _G.LexusLang == "EN" and "WELCOME TO VIP MOD" or "CHÀO MỪNG"
            local content = _G.LexusLang == "EN" 
                and "The VIP MENU is now inside Game Settings!\nIMPORTANT: Enable fewer features to avoid lag. Play safe!" 
                or "MENU VIP đã có trong Cài Đặt game!\nBẬT ÍT CHỨC NĂNG THÔI LAG LẮM, BẮN KỸ TÍ LÀ SAFE"
            local btn1 = _G.LexusLang == "EN" and "OPEN GAME MENU" or "MỞ MENU TRONG GAME"
            local btn2 = _G.LexusLang == "EN" and "CLOSE" or "ĐÓNG"

            Msg.Show(1, title, content, 
            function() 
                _G.InitModMenuTab()
                if _G.LexusLang == "EN" then
                    Notify("VIP MOD MENU ADDED!\nOpen Settings (Gear icon) -> VIP MOD MENU to toggle features.")
                else
                    Notify("ĐÃ THÊM 'VIP MOD MENU' VÀO PHẦN CÀI ĐẶT CỦA GAME!\nMở Cài Đặt (Răng Cưa) -> VIP MOD MENU để bật/tắt.")
                end
                _G.LexusState.MenuStep = 99
                _G.LexusMenuAlreadyShown = true
            end, 
            function() 
                _G.LexusState.MenuStep = 99
                _G.LexusMenuAlreadyShown = true
            end, btn1, btn2)
        end

        local function Step_SelectLanguage()
            Msg.Show(2, "SELECT LANGUAGE / CHỌN NGÔN NGỮ", "Please select your preferred language.\nVui lòng chọn ngôn ngữ bạn muốn sử dụng.",
            function()
                _G.LexusLang = "VN"
                Step_Welcome()
            end,
            function()
                _G.LexusLang = "EN"
                Step_Welcome()
            end, "TIẾNG VIỆT", "ENGLISH")
        end

        local function Step_LegalNotice()
            local legal_title = "Thông Báo - Announcement"
            local legal_content = "HÃY LƯỚT XUỐNG ĐỂ ĐỌC ĐẦY ĐỦ - SCROLL DOWN TO READ THE FULL ARTICLE\n\nESP V2  = Văng Game Một Số Máy ( Game crashes on some devices )\nMAGIC BULLET = RISK BAN X\nGLOBAL = SAFE ✓( AN TOÀN )\nVNG = SAFE ✓( AN TOÀN )\nKOREA = SAFR ✓(AN TOÀN)\nTAIWAN = SAFE ✓( AN TOÀN )\n\nHãy cẩn thận đừng giao dịch mua bán với người lạ."
            local legal_btnOK = "Đồng Ý (Agree)"
            local legal_btnCancel = "Hủy (cancel)"

            local legal_msg = require("client.slua.logic.common.logic_common_legal_msg")
            if not legal_msg then
                Step_SelectLanguage()
                return
            end
            
            legal_msg.ShowOnePopUI({
                tabType = 0,
                title = legal_title,
                content = legal_content,
                tipsText = nil,
                btnOKText = legal_btnOK,
                btnCancelText = legal_btnCancel, 
                acceptFunc = function()
                    Step_SelectLanguage()
                end,
                refuseFunc = function()
                    Step_SelectLanguage()
                end
            })
        end

        _G.LexusState.MenuStep = 1
        Step_LegalNotice() 
    end)
end

-- ========================================== 
-- LOGIC MỞ KHÓA 165 FPS VÀ UI IPAD VIEW 
-- ========================================== 
local function InitializeGraphicsUnlock() 
    if _G.LexusState.GraphicsUnlocked then return end

    pcall(function()
        local SettingCfg = require("client.logic.setting.setting_config")
        local GraphicSettingDB = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        if SettingCfg then
            if SettingCfg.TpViewValue then SettingCfg.TpViewValue.max = 160 end
            if SettingCfg.FpViewValue then SettingCfg.FpViewValue.max = 160 end
        end
        if GraphicSettingDB then
            if GraphicSettingDB.TpViewValue then GraphicSettingDB.TpViewValue.max = 160 end
        end
    end)

    pcall(function()
        local logic_setting_graphics = require("client.slua.logic.setting.logic_setting_graphics")
        local GSC_FPS = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
        local GSC_FPSFT = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
        local GraphicSettingDB = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        
        local KismetMathLibrary = import("KismetMathLibrary") or _G.KismetMathLibrary
        local FLinearColor = import("LinearColor") or _G.FLinearColor

        if logic_setting_graphics then
            local old_SetFPS = logic_setting_graphics.SetFPS
            function logic_setting_graphics.SetFPS(gameInstance, FPSLevel)
                if old_SetFPS then old_SetFPS(gameInstance, FPSLevel) end
                if FPSLevel == 8 then 
                    gameInstance:ExecuteCMD("t.MaxFPS", "165")
                    gameInstance:ExecuteCMD("r.FrameRateLimit", "165")
                end
            end
        end

        if GSC_FPS and GSC_FPS.__inner_impl then
            local fps_impl = GSC_FPS.__inner_impl
            function fps_impl:GetMaxFPSLevel() return 8, 8 end
            function fps_impl:InitRealSupportFPS()
                local RealSupportFPS = {}
                for i = 1, 8 do RealSupportFPS[i] = {true, true} end
                if GraphicSettingDB then GraphicSettingDB:UpdateUIData(GraphicSettingDB.RealSupportFPS, RealSupportFPS, false) end
                return RealSupportFPS
            end
            function fps_impl:UpdateSelectedFPSState(selectedLevel)
                if not slua.isValid(self.UIRoot) then return end
                for level = 2, 8 do
                    local name = "NodeFps" .. (({[2]=20,[3]=25,[4]=30,[5]=40,[6]=60,[7]=90,[8]=120})[level] or 120)
                    local widget = self.UIRoot[name]
                    if slua.isValid(widget) then
                        widget:SetIsEnabled(true) 
                        pcall(function() widget:SetRenderOpacity(1.0) end)
                        local switcher = self.UIRoot["WidgetSwitcher_" .. level]
                        if slua.isValid(switcher) then 
                            switcher:SetActiveWidgetIndex(level == selectedLevel and 0 or 1) 
                        end
                    end
                end
            end
        end

        if GSC_FPSFT and GSC_FPSFT.__inner_impl then
            local ft_impl = GSC_FPSFT.__inner_impl
            local NMinFPS, NStep = 90, 5
            local function clamp(value, min, max)
                if value < min then return min end
                if max < value then return max end
                return value
            end
            local function lerp(a, b, t) return a + (b - a) * t end
            local function _getColorByPercent(start, finish, percent)
                if not FLinearColor then return nil end
                return FLinearColor(lerp(start.R, finish.R, percent), lerp(start.G, finish.G, percent), lerp(start.B, finish.B, percent), lerp(start.A, finish.A, percent))
            end
            
            ft_impl.InitFPSFTValue165 = function(self)
                local itemRoot = self.UIRoot
                local FPSFineTuneSwitch = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
                local FPSFineTuneNum = 165
                if FPSFineTuneSwitch then
                    FPSFineTuneNum = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum) or 165
                    itemRoot.Slider_screen3:SetLocked(false)
                end
                local FPSFineTunePer = (FPSFineTuneNum - NMinFPS) / (165 - NMinFPS)
                
                itemRoot.Veihclescreen3:SetText(tostring(FPSFineTuneNum))
                itemRoot.Slider_screen3:SetValue(FPSFineTunePer)
                itemRoot.ProgressBar_screen3:SetPercent(FPSFineTunePer)
            end

            ft_impl.OnFPSFTValueChange3 = function(self, FPSFineTuneNum)
                GraphicSettingDB:UpdateUIData(GraphicSettingDB.FPSFineTuneNum, FPSFineTuneNum)
                if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
                if self:GetParentUI() then self:GetParentUI():SetDirty(true) end
                local gameInstance = GraphicSettingDB.GetGameInstance and GraphicSettingDB.GetGameInstance()
                if gameInstance then
                    gameInstance:ExecuteCMD("t.MaxFPS", tostring(FPSFineTuneNum))
                    gameInstance:ExecuteCMD("r.FrameRateLimit", tostring(FPSFineTuneNum))
                end
            end

            ft_impl.OnFPSFTSliderValueChange3 = function(self, value)
                if GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch) and KismetMathLibrary then
                    local FPSFineTuneNum = KismetMathLibrary.FCeil(value * (165 - NMinFPS) / NStep) * NStep + NMinFPS
                    self:OnFPSFTValueChange3(clamp(FPSFineTuneNum, NMinFPS, 165))
                end
            end
            
            ft_impl.OnFPSFTAdd = ft_impl.OnFPSFTAdd3
            ft_impl.OnFPSFTMinus = ft_impl.OnFPSFTMinus3
            ft_impl.OnFPSFTAdd2 = ft_impl.OnFPSFTAdd3
            ft_impl.OnFPSFTMinus2 = ft_impl.OnFPSFTMinus3
            ft_impl.OnFPSFTSliderValueChange = ft_impl.OnFPSFTSliderValueChange3
            ft_impl.OnFPSFTSliderValueChange2 = ft_impl.OnFPSFTSliderValueChange3
        end
    end)
    _G.LexusState.GraphicsUnlocked = true
    Notify("Graphics & FPS 165Hz Unlocked")
end

local function InitializeNativeESP() 
    if _G.LexusState.NativeESPReady then return end
    pcall(function() 
        local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools") 
        local currentMarkCfg = GamePlayTools.GetCurrentConfig("ScreenMarkConfig") 
        local function ApplyCfg(cfg)
            if not cfg then return end 
            if cfg[1006] then 
                cfg[1006].bBindBlocked = true;
                cfg[1006].bBindOutScreen = true; 
                cfg[1006].MaxWidgetNum = 99
                cfg[1006].MaxShowDistance = 6000000; 
                cfg[1006].bScaleByDistance = false
                cfg[1006].BindSocketName = "root"; 
                cfg[1006].bUseLuaWorldSocketName = true
                cfg[1006].WorldPositionOffset = FVector(0, 0, -30) 
            end 
            cfg[8888] = { 
                UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                MaxWidgetNum = 99, 
                MaxShowDistance = 6000000, 
                bBindOutScreen = true,
                bBindBlocked = true, 
                bIsBindingActor = true,
                BindSocketName = "head",
                bUseLuaWorldSocketName = true, 
                WorldPositionOffset = FVector(0, 0, 30),
                bNeedPreLoad = true,
                Priority = 2 
            } 
            cfg[9999] = { 
                UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                MaxWidgetNum = 99, 
                MaxShowDistance = 6000000, 
                bBindOutScreen = true,
                bBindBlocked = true, 
                bIsBindingActor = true, 
                BindSocketName = "head",
                bUseLuaWorldSocketName = true, 
                WorldPositionOffset = FVector(0, 0, 50),
                bNeedPreLoad = true, 
                Priority = 2 
            } 
        end 
        ApplyCfg(currentMarkCfg) 
        for k, cfg in pairs(package.loaded) do 
            if type(k) == "string" and string.find(k, "ScreenMarkConfig") and type(cfg) == "table" then 
                ApplyCfg(cfg) 
            end 
        end 
    end)
    _G.LexusState.NativeESPReady = true 
    Notify("Native ESP System Initialized") 
end

local function GetAllSkeletalMeshes(enemy, markData)
    local curTime = os.clock()
    if markData and markData.CachedMeshes and markData.CachedMeshTime and (curTime - markData.CachedMeshTime < 0.5) then
        local validMeshes = {}
        for _, cachedMesh in ipairs(markData.CachedMeshes) do
            local isPendingKill = false
            pcall(function() if type(cachedMesh.IsPendingKill) == "function" then isPendingKill = cachedMesh:IsPendingKill() end end)
            
            if Valid(cachedMesh) and not isPendingKill then 
                table.insert(validMeshes, cachedMesh) 
            end
        end
        markData.CachedMeshes = validMeshes
        return validMeshes
    end

    local meshes = {}
    if Valid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
    pcall(function()
        local SkeletalMeshClass = import("SkeletalMeshComponent")
        if SkeletalMeshClass and type(enemy.GetComponentsByClass) == "function" then
            local childs = enemy:GetComponentsByClass(SkeletalMeshClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for i = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(i-1) or childs[i]
                    if Valid(comp) and comp ~= enemy.Mesh then
                        table.insert(meshes, comp)
                    end
                end
            end
        end
    end)
    if markData then
        markData.CachedMeshes = meshes
        markData.CachedMeshTime = curTime
    end
    return meshes
end

local function UndoWallXuyenTuong(enemy, markData)
    pcall(function()
        if markData.WallhackApplied then
            local meshes = GetAllSkeletalMeshes(enemy, markData)
            for _, mesh in ipairs(meshes) do
                if Valid(mesh) then
                    pcall(function() if type(mesh.SetRenderCustomDepth) == "function" then mesh:SetRenderCustomDepth(false) end end)
                    for i = 0, 10 do 
                        local matInterface = mesh:GetMaterial(i)
                        if Valid(matInterface) then
                            local baseMat = matInterface:GetBaseMaterial()
                            if Valid(baseMat) then baseMat.bDisableDepthTest = false end
                        end
                    end
                end
            end
            markData.WallhackApplied = false
        end
    end)
end

local function ApplyWallXuyenTuong(enemy, markData)
    pcall(function()
        local meshes = GetAllSkeletalMeshes(enemy, markData)
        for _, mesh in ipairs(meshes) do
            if Valid(mesh) then 
                pcall(function()
                    if type(mesh.SetRenderCustomDepth) == "function" then
                        mesh:SetRenderCustomDepth(true)
                    end
                    if type(mesh.SetCustomDepthStencilValue) == "function" then
                        mesh:SetCustomDepthStencilValue(252) 
                    end
                end)
                for i = 0, 10 do 
                    local matInterface = mesh:GetMaterial(i)
                    if not Valid(matInterface) then break end
                    local baseMat = matInterface:GetBaseMaterial()
                    if Valid(baseMat) then
                        baseMat.bDisableDepthTest = true
                        baseMat.BlendMode = 2 
                    end
                end
            end
        end
    end)
end

local function ApplyColorBodyV2(enemy, pc, markData)
    pcall(function()
        local meshes = GetAllSkeletalMeshes(enemy, markData)
        if #meshes == 0 then return end
        
        local curTime = os.clock()
        if markData.LastVisCheckTime == nil or (curTime - markData.LastVisCheckTime) > 0.3 then
            markData.LastVisCheckTime = curTime
            local isHidden = true
            pcall(function()
                if Valid(pc) and type(pc.LineOfSightTo) == "function" then
                    if pc:LineOfSightTo(enemy) then isHidden = false else isHidden = true end
                end
            end)
            markData.CachedHiddenState = isHidden
        end
        
        local hidden = markData.CachedHiddenState
        if hidden == nil then hidden = true end
        
        local cData = _G.LexusState.CustomTextData or {}
        local hiddenColor = {R = cData.HiddenR or 150, G = cData.HiddenG or 0, B = cData.HiddenB or 0, A = cData.HiddenA or 25}
        local visibleColor = {R = cData.VisibleR or 0, G = cData.VisibleG or 150, B = cData.VisibleB or 0, A = cData.VisibleA or 25}
        
        local finalColor = hidden and hiddenColor or visibleColor
        local colorHash = string.format("%d_%d_%d_%d", finalColor.R, finalColor.G, finalColor.B, finalColor.A)
        local currentMeshCount = #meshes
        local isMeshChanged = (markData.LastMeshCount ~= currentMeshCount)
        
        if not isMeshChanged and markData.LastHiddenState == hidden and markData.LastColorHash == colorHash then return end
        
        if isMeshChanged and markData.MIDs then
            markData.MIDs = {}
        end

        markData.LastHiddenState = hidden
        markData.LastMeshCount = currentMeshCount
        markData.LastColorHash = colorHash
        markData.ColorApplied = true
        
        for meshIndex, mesh in ipairs(meshes) do
            if Valid(mesh) then
                pcall(function()
                    mesh.LDMaxDrawDistance = -99999
                    mesh.MaxDrawDistanceOffset = -99999
                    mesh.CachedMaxDrawDistance = -99999
                    mesh.UseScopeDistanceCulling = true
                    mesh.PrimitiveShadingStrategy = 1
                    mesh.ShadingRate = 6
                end)
                for i = 0, 10 do
                    local matInterface = mesh:GetMaterial(i)
                    if not Valid(matInterface) then break end
                    local baseMat = matInterface:GetBaseMaterial()
                    if Valid(baseMat) then
                        local matName = tostring(baseMat)
                        if string.find(matName, "Master_Mask", 1, true) then
                            if not markData.MIDs then markData.MIDs = {} end
                            local meshKey = "Mesh_" .. tostring(meshIndex)
                            
                            if not markData.MIDs[meshKey] then markData.MIDs[meshKey] = {} end
                            local mid = markData.MIDs[meshKey][i]
                            if not Valid(mid) then
                                mid = mesh:CreateAndSetMaterialInstanceDynamic(i)
                                markData.MIDs[meshKey][i] = mid
                            end
                            if Valid(mid) then
                                mid:SetVectorParameterValue("颜色", finalColor)
                                mid:SetVectorParameterValue("Extra Light Color", finalColor)
                                mid:SetVectorParameterValue("Para_Color", finalColor)
                                mid:SetVectorParameterValue("Para_ColorTint", finalColor)
                                mid:SetVectorParameterValue("Para_Color_1", finalColor)
                                mid:SetVectorParameterValue("Tint", finalColor)
                                mid:SetVectorParameterValue("Color", finalColor)
                                mid:SetVectorParameterValue("BaseColor", finalColor)
                                mid:SetVectorParameterValue("BodyColor", finalColor)
                                mid:SetVectorParameterValue("MainColor", finalColor)
                                mid:SetVectorParameterValue("DiffuseColor", finalColor)
                                mid:SetVectorParameterValue("EmissiveColor", finalColor)
                                mid:SetVectorParameterValue("ParaScaleOffset", SCALE_COLOR_V2)
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function UndoColorBodyV2(enemy, markData)
    pcall(function()
        if markData.ColorApplied then
            local meshes = GetAllSkeletalMeshes(enemy, markData)
            for meshIndex, mesh in ipairs(meshes) do
                if Valid(mesh) then
                    pcall(function()
                        mesh.PrimitiveShadingStrategy = 0
                        mesh.ShadingRate = 1
                    end)
                    local meshKey = "Mesh_" .. tostring(meshIndex)
                    if markData.MIDs and markData.MIDs[meshKey] then
                        for i, mid in pairs(markData.MIDs[meshKey]) do
                            if Valid(mid) then
                                local defC = {R=1, G=1, B=1, A=1}
                                mid:SetVectorParameterValue("颜色", defC)
                                mid:SetVectorParameterValue("Extra Light Color", defC)
                                mid:SetVectorParameterValue("Para_Color", defC)
                                mid:SetVectorParameterValue("Para_ColorTint", defC)
                                mid:SetVectorParameterValue("Para_Color_1", defC)
                                mid:SetVectorParameterValue("Tint", defC)
                                mid:SetVectorParameterValue("Color", defC)
                                mid:SetVectorParameterValue("BaseColor", defC)
                                mid:SetVectorParameterValue("BodyColor", defC)
                                mid:SetVectorParameterValue("MainColor", defC)
                                mid:SetVectorParameterValue("DiffuseColor", defC)
                                mid:SetVectorParameterValue("EmissiveColor", defC)
                            end
                        end
                    end
                end
            end
            markData.ColorApplied = false
            markData.LastColorHash = ""
            markData.LastHiddenState = nil
        end
    end)
end

local function ApplyColorBodyV3(enemy, markData)
    pcall(function()
        local meshes = GetAllSkeletalMeshes(enemy, markData)
        if #meshes == 0 then return end
        
        local cData = _G.LexusState.CustomTextData or {}
        local hidChoice = cData.ColorV3Hidden or 1
        local visChoice = cData.ColorV3Visible or 2
        local v3Thick = cData.ColorV3Thickness or 4
        
        local currentHash = string.format("%d_%d_%d", hidChoice, visChoice, v3Thick)
        local colorChanged = (markData.LastColorV3Hash ~= currentHash)
        markData.LastColorV3Hash = currentHash

        local function GetColorRGB(choice)
            if choice == 1 then return 255, 0, 0 end
            if choice == 2 then return 0, 255, 0 end
            if choice == 3 then return 0, 0, 255 end
            if choice == 4 then return 255, 255, 0 end
            if choice == 5 then return 255, 0, 255 end
            if choice == 6 then return 255, 255, 255 end
            return 255, 0, 0
        end

        local hR, hG, hB = GetColorRGB(hidChoice)
        local vR, vG, vB = GetColorRGB(visChoice)

        local invisColor = { R=hR, G=hG, B=hB, A=255, r=hR, g=hG, b=hB, a=255 }
        
        local glowIntensity = 80.0 
        local LinearColorClass = import("LinearColor") or _G.FLinearColor
        local visColor = LinearColorClass and LinearColorClass((vR/255)*glowIntensity, (vG/255)*glowIntensity, (vB/255)*glowIntensity, 1.0) or { R=vR*glowIntensity, G=vG*glowIntensity, B=vB*glowIntensity, A=255 }
        local scale = { R=3.0, G=3.0, B=0.0, A=0.0, r=3.0, g=3.0, b=0.0, a=0.0 }
        
        markData.MIDs_V3 = markData.MIDs_V3 or {}

        for meshIndex, comp in ipairs(meshes) do
            if Valid(comp) then
                local compKey = "MeshV3_" .. tostring(meshIndex)
                markData.MIDs_V3[compKey] = markData.MIDs_V3[compKey] or {}
                
                pcall(function()
                    if comp.PrimitiveShadingStrategy ~= 1 then
                        comp.UseScopeDistanceCulling = false 
                        comp.PrimitiveShadingStrategy = 1
                        comp.ShadingRate = 6
                    end
                end)
                
                for i = 0, 10 do
                    local matInterface = comp:GetMaterial(i)
                    if not Valid(matInterface) then break end
                    
                    local baseMat = matInterface:GetBaseMaterial()
                    if Valid(baseMat) then
                        if baseMat.bDisableDepthTest ~= true then baseMat.bDisableDepthTest = true end
                        if baseMat.BlendMode ~= 2 then baseMat.BlendMode = 2 end
                    end
                    
                    local currentCached = markData.MIDs_V3[compKey][i]
                    local needUpdateColor = false
                    
                    if not Valid(currentCached) then
                        local newMid = comp:CreateAndSetMaterialInstanceDynamic(i)
                        if Valid(newMid) then 
                            markData.MIDs_V3[compKey][i] = newMid
                            currentCached = newMid
                            needUpdateColor = true
                        end
                    elseif colorChanged then
                        needUpdateColor = true
                    end
                    
                    if Valid(currentCached) and needUpdateColor then
                        pcall(function()
                            currentCached:SetVectorParameterValue("颜色", invisColor)
                            currentCached:SetVectorParameterValue("Extra Light Color", invisColor)
                            currentCached:SetVectorParameterValue("Para_Color", invisColor)
                            currentCached:SetVectorParameterValue("Para_ColorTint", invisColor)
                            currentCached:SetVectorParameterValue("Para_Color_1", invisColor)
                            currentCached:SetVectorParameterValue("Tint", invisColor)
                            currentCached:SetVectorParameterValue("Color", invisColor)
                            currentCached:SetVectorParameterValue("BaseColor", invisColor)
                            currentCached:SetVectorParameterValue("BodyColor", invisColor)
                            currentCached:SetVectorParameterValue("MainColor", invisColor)
                            currentCached:SetVectorParameterValue("DiffuseColor", invisColor)
                            currentCached:SetVectorParameterValue("EmissiveColor", invisColor)
                            currentCached:SetVectorParameterValue("CustomColor", invisColor)
                            currentCached:SetVectorParameterValue("OverlayColor", invisColor)
                            currentCached:SetVectorParameterValue("GlowColor", invisColor)
                            currentCached:SetVectorParameterValue("EdgeColor", invisColor)
                            currentCached:SetVectorParameterValue("LightColor", invisColor)
                            currentCached:SetVectorParameterValue("OutlineColor", invisColor)
                            currentCached:SetVectorParameterValue("ParaScaleOffset", scale)
                            currentCached:SetScalarParameterValue("Opacity", 0.7)
                            currentCached:SetScalarParameterValue("Alpha", 0.7)
                            currentCached:SetScalarParameterValue("GlowIntensity", 1.0)
                            currentCached:SetScalarParameterValue("Intensity", 1.0)
                        end)
                    end
                end
                
                pcall(function()
                    if comp.SetDrawIdeaOutline then
                        comp:SetDrawIdeaOutline(true)
                        if comp.OverrideIdeaOutlineColor then comp:OverrideIdeaOutlineColor(true, visColor) end
                        if comp.OverrideIdeaOutlineThickness then comp:OverrideIdeaOutlineThickness(true, v3Thick) end
                    end
                end)
            end
        end
        markData.ColorV3Applied = true
    end)
end

local function UndoColorBodyV3(enemy, markData)
    pcall(function()
        if markData.ColorV3Applied then
            local meshes = GetAllSkeletalMeshes(enemy, markData)
            for meshIndex, comp in ipairs(meshes) do
                if Valid(comp) then
                    pcall(function()
                        comp.PrimitiveShadingStrategy = 0
                        comp.ShadingRate = 1
                    end)
                    
                    for i = 0, 10 do
                        local s, matInterface = pcall(function() return comp:GetMaterial(i) end)
                        if s and Valid(matInterface) then
                            local s2, baseMat = pcall(function() return matInterface:GetBaseMaterial() end)
                            if s2 and Valid(baseMat) then
                                baseMat.bDisableDepthTest = false
                                baseMat.BlendMode = 1
                            end
                        end
                    end
                    
                    local compKey = "MeshV3_" .. tostring(meshIndex)
                    if markData.MIDs_V3 and markData.MIDs_V3[compKey] then
                        for i, mid in pairs(markData.MIDs_V3[compKey]) do
                            if Valid(mid) then
                                pcall(function()
                                    local defC = {R=1, G=1, B=1, A=1, r=1, g=1, b=1, a=1}
                                    mid:SetVectorParameterValue("颜色", defC)
                                    mid:SetVectorParameterValue("Extra Light Color", defC)
                                    mid:SetVectorParameterValue("Para_Color", defC)
                                    mid:SetVectorParameterValue("Tint", defC)
                                    mid:SetVectorParameterValue("BaseColor", defC)
                                    mid:SetVectorParameterValue("Color", defC)
                                end)
                            end
                        end
                    end
                    
                    pcall(function()
                        if comp.SetDrawIdeaOutline then
                            comp:SetDrawIdeaOutline(false)
                        end
                    end)
                end
            end
            markData.ColorV3Applied = false
            markData.LastMeshCountV3 = 0
            if markData.MIDs_V3 then markData.MIDs_V3 = nil end
        end
    end)
end

local function ApplyColorBodyNew(enemy, markData)
    pcall(function()
        if not _G.ConsoleNewWallReady then
            local KismetSystemLibrary = import("KismetSystemLibrary")
            local world = slua.getWorld()
            if KismetSystemLibrary and world then
                KismetSystemLibrary.ExecuteConsoleCommand(world, "r.EnableDrawDyeingColor 1")
                KismetSystemLibrary.ExecuteConsoleCommand(world, "r.CustomDepth 3")
                KismetSystemLibrary.ExecuteConsoleCommand(world, "r.IdeaOutline.Enable 1")
                KismetSystemLibrary.ExecuteConsoleCommand(world, "r.Highlight.Enable 1")
                _G.ConsoleNewWallReady = true
            end
        end

        local meshes = GetAllSkeletalMeshes(enemy, markData)
        
        local weapon = nil
        pcall(function() weapon = enemy:GetCurrentWeapon() end)
        if slua.isValid(weapon) and slua.isValid(weapon.Mesh) then
            table.insert(meshes, weapon.Mesh)
        end

        local isBot = markData.AK_IS_BOT or false
        local currentMeshCount = #meshes
        
        local stateHash = (isBot and "BOT" or "PLAYER") .. "_" .. tostring(currentMeshCount)
        
        if markData.LastColorNewHash == stateHash and markData.ColorNewApplied then
            return
        end
        
        markData.LastColorNewHash = stateHash
        markData.ColorNewApplied = true

        local LinearColorClass = import("LinearColor") or _G.FLinearColor
        local c_vis = LinearColorClass and LinearColorClass(0, 100, 0, 1) or {R=0, G=100, B=0, A=1}
        local c_occ = LinearColorClass and LinearColorClass(100, 0, 0, 1) or {R=100, G=0, B=0, A=1}
        local c_bVis = LinearColorClass and LinearColorClass(49, 48, 0, 100) or {R=49, G=48, B=0, A=100}
        local c_bOcc = LinearColorClass and LinearColorClass(9, 1.5, 45, 100) or {R=9, G=1.5, B=45, A=100}

        local visColor = isBot and c_bVis or c_vis
        local occColor = isBot and c_bOcc or c_occ

        for _, mesh in ipairs(meshes) do
            if Valid(mesh) then
                pcall(function()
                    if type(mesh.SetDrawDyeing) == "function" then
                        mesh:SetDrawDyeing(true)
                        mesh:SetDrawDyeingMode(1)
                        mesh:SetVisibleDyeingColor(visColor)
                        mesh:SetOccludedDyeingColor(occColor)
                        mesh:SetDyeingColorFadeDistance(99999.0)
                        mesh:SetDyeingColorMinMaxDistance(0.0, 99999.0)
                        mesh:SetDrawHighlight(true)
                        mesh:OverrideHighlightColor(visColor)
                        mesh:SetHighlightCanBeOccluded(false)
                        mesh:SetDrawIdeaOutline(true)
                        mesh:SetIdeaOutlineNew(true)
                        mesh:SetIdeaOutlineOcclusionHighlight(true)
                        mesh:OverrideIdeaOutlineColor(visColor)
                        mesh:SetIdeaOutlineOcclusionColor(occColor)
                        mesh:OverrideIdeaOutlineThickness(20.0)
                        mesh:SetIdeaOverrideOutlineAndOcclusion(true)
                        mesh:SetRenderCustomDepth(true)
                        mesh:SetCustomDepthStencilValue(255)
                    end
                end)
            end
        end
    end)
end

local function UndoColorBodyNew(enemy, markData)
    pcall(function()
        if markData.ColorNewApplied then
            local meshes = GetAllSkeletalMeshes(enemy, markData)
            local weapon = nil
            pcall(function() weapon = enemy:GetCurrentWeapon() end)
            if slua.isValid(weapon) and slua.isValid(weapon.Mesh) then
                table.insert(meshes, weapon.Mesh)
            end

            for _, mesh in ipairs(meshes) do
                if Valid(mesh) then
                    pcall(function()
                        if type(mesh.SetDrawDyeing) == "function" then
                            mesh:SetDrawDyeing(false)
                            mesh:SetDrawHighlight(false)
                            mesh:SetDrawIdeaOutline(false)
                            mesh:SetRenderCustomDepth(false)
                        end
                    end)
                end
            end
            markData.ColorNewApplied = false
            markData.LastColorNewHash = ""
        end
    end)
end

-- ========================================== 
-- HỆ THỐNG AIMBOT V2 
-- ========================================== 
_G.GetEnemyTargetsFromActors = function(radius)
    local result = {}
    local player = GameplayData.GetPlayerCharacter()

    if not slua.isValid(player) then
        return result
    end

    local allCharacters = {}
    if GameplayData.GetAllPlayerCharacters then
        allCharacters = GameplayData.GetAllPlayerCharacters()
    elseif GameplayData.GameCharacters then
        for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end
    end

    local myTeam = player:GetTeamID()

    for _, actor in pairs(allCharacters) do
        if slua.isValid(actor) and actor ~= player and actor.GetTeamID and actor:IsAlive() then
            if actor:GetTeamID() ~= myTeam then
                local dist = player:GetDistanceTo(actor)
                if dist <= radius then
                    table.insert(result, actor)
                end
            end
        end
    end
    return result
end

_G.AimTouch = function()
    pcall(function()
        if not _G.LexusConfig.AimTouchEnable then return end
        
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
        
        local pc = player:GetPlayerControllerSafety()
        if not slua.isValid(pc) then return end
        
        local isFiring = player.bIsWeaponFiring
        local isADS = player.bIsGunADS
        
        local weapon = player.WeaponManagerComponent and player.WeaponManagerComponent.CurrentWeaponReplicated
        if not weapon and type(player.GetCurrentShootWeapon) == "function" then
            weapon = player:GetCurrentShootWeapon()
        end
        
        local isShotgun = false
        local isSniper = false
        local isMortar = false
        local currentAmmo = 1
        
        if slua.isValid(weapon) then
            local wID = type(weapon.GetWeaponID) == "function" and weapon:GetWeaponID() or 0
            local wName = type(weapon.GetWeaponName) == "function" and weapon:GetWeaponName() or ""
            
            if (wID >= 1030000 and wID < 1040000) or wName:find("S686") or wName:find("S1897") or wName:find("S12K") or wName:find("DBS") or wName:find("M1014") then 
                isShotgun = true 
            end
            
            if wName:find("Kar98") or wName:find("M24") or wName:find("AWM") or wName:find("Mosin") or wName:find("Win94") or wName:find("AMR") or wName:find("SKS") or wName:find("SLR") or wName:find("Mini") or wName:find("QBU") or wName:find("Mk12") or wName:find("VSS") or wName:find("M1") or wName:find("DSR") then
                isSniper = true
            end

            if wName:lower():find("mortar") or wName:lower():find("cối") then
                isMortar = true
            end
            
            if type(weapon.GetCurrentAmmo) == "function" then
                currentAmmo = weapon:GetCurrentAmmo()
            elseif weapon.ShootWeaponComponent and type(weapon.ShootWeaponComponent.GetCurrentAmmo) == "function" then
                currentAmmo = weapon.ShootWeaponComponent:GetCurrentAmmo()
            elseif weapon.CurrentAmmo ~= nil then
                currentAmmo = weapon.CurrentAmmo
            end
        end

        if _G.LexusState.IsAutoFiring then
            pcall(function()
                player.bIsWeaponFiring = false
                if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(false) end
                if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(false) end
                local wepMgr = player.WeaponManagerComponent
                if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = false end
            end)
            _G.LexusState.IsAutoFiring = false
        end

        if isShotgun and currentAmmo <= 0 then
            return
        end

        local cond = 2
        local prioMode = 1
        local boneIdx = 1
        local speedVal = 50
        local fovVal = 30
        local maxDistMeters = 50
        local useVisCheck = false
        local igKnock = false
        local igBot = false
        local predVal = 0 
        local recoilCompVal = 0 

        if isMortar and _G.LexusConfig.AimTouchMortar then
            local isPlaced = false
            pcall(function()
                if weapon and weapon.MortarState == 2 then isPlaced = true end
            end)
            if not isPlaced then return end

            cond = 2 
            prioMode = 1  
            boneIdx = 4 
            speedVal = 100 
            fovVal = _G.LexusState.CustomTextData.AimTouchMortarFOV or 360 
            maxDistMeters = 2000 
            useVisCheck = false 
            igKnock = false
            igBot = false
            predVal = _G.LexusState.CustomTextData.AimTouchMortarPred or 0 
            
        elseif isShotgun and _G.LexusConfig.AimTouchSG then
            cond = _G.LexusState.CustomTextData.AimTouchSGCond or 1
            if _G.LexusConfig.AimTouchSGAutoFire then cond = 2 end
            if cond == 1 and not isFiring then return end
            prioMode = _G.LexusState.CustomTextData.AimTouchSGPrio or 1
            boneIdx = _G.LexusState.CustomTextData.AimTouchSGBone or 2
            speedVal = _G.LexusState.CustomTextData.AimTouchSGSpeed or 80
            fovVal = _G.LexusState.CustomTextData.AimTouchSGFOV or 40
            maxDistMeters = _G.LexusState.CustomTextData.AimTouchSGDist or 30
            useVisCheck = _G.LexusConfig.AimTouchSGVisCheck
            igKnock = _G.LexusConfig.AimTouchSGIgKnock
            igBot = _G.LexusConfig.AimTouchSGIgBot
            
        elseif isADS then
            if isSniper and _G.LexusConfig.AimTouchScopeSniper then
                cond = _G.LexusState.CustomTextData.AimTouchSniperCond or 2
                if cond == 1 and not isFiring then return end
                prioMode = _G.LexusState.CustomTextData.AimTouchSniperPrio or 1
                boneIdx = _G.LexusState.CustomTextData.AimTouchSniperBone or 1
                speedVal = _G.LexusState.CustomTextData.AimTouchSniperSpeed or 30
                fovVal = _G.LexusState.CustomTextData.AimTouchSniperFOV or 20
                maxDistMeters = _G.LexusState.CustomTextData.AimTouchSniperDist or 400
                useVisCheck = _G.LexusConfig.AimTouchSniperVisCheck
                igKnock = _G.LexusConfig.AimTouchSniperIgKnock
                igBot = _G.LexusConfig.AimTouchSniperIgBot
                predVal = _G.LexusState.CustomTextData.AimTouchSniperPred or 0
            elseif _G.LexusConfig.AimTouchScopeAll then
                cond = _G.LexusState.CustomTextData.AimTouchScopeCond or 1
                if cond == 1 and not isFiring then return end
                prioMode = _G.LexusState.CustomTextData.AimTouchScopePrio or 1
                boneIdx = _G.LexusState.CustomTextData.AimTouchScopeBone or 2
                speedVal = _G.LexusState.CustomTextData.AimTouchScopeSpeed or 40
                fovVal = _G.LexusState.CustomTextData.AimTouchScopeFOV or 20
                maxDistMeters = _G.LexusState.CustomTextData.AimTouchScopeDist or 300
                useVisCheck = _G.LexusConfig.AimTouchScopeVisCheck
                igKnock = _G.LexusConfig.AimTouchScopeIgKnock
                igBot = _G.LexusConfig.AimTouchScopeIgBot
                predVal = _G.LexusState.CustomTextData.AimTouchScopePred or 0
                recoilCompVal = _G.LexusState.CustomTextData.AimTouchScopeRecoil or 0
            else
                return
            end
        else
            if not _G.LexusConfig.AimTouchHipfire then return end
            cond = _G.LexusState.CustomTextData.AimTouchHipCond or 1
            if cond == 1 and not isFiring then return end 
            prioMode = _G.LexusState.CustomTextData.AimTouchHipPrio or 1
            boneIdx = _G.LexusState.CustomTextData.AimTouchHipBone or 1
            speedVal = _G.LexusState.CustomTextData.AimTouchHipSpeed or 50
            fovVal = _G.LexusState.CustomTextData.AimTouchHipFOV or 30
            maxDistMeters = _G.LexusState.CustomTextData.AimTouchHipDist or 250
            useVisCheck = _G.LexusConfig.AimTouchHipVisCheck
            igKnock = _G.LexusConfig.AimTouchHipIgKnock
            igBot = _G.LexusConfig.AimTouchHipIgBot
        end

        local currentMaxDist = maxDistMeters * 100 

        local enemies = _G.GetEnemyTargetsFromActors(currentMaxDist)
        if not enemies or #enemies == 0 then return end
        
        local FVector2D = import("Vector2D")
        local UGameplayStatics = import("GameplayStatics")
        local KismetMathLibrary = import("KismetMathLibrary")
        
        local camManager = UGameplayStatics.GetPlayerCameraManager(pc, 0)
        if not slua.isValid(camManager) then return end
        
        local camLoc = camManager:GetCameraLocation()
        if not camLoc then return end
        
        local ui_util = require("client.common.ui_util")
        if not ui_util then return end
        
        local viewportSize = ui_util.GetViewportSize()
        if not viewportSize then return end
        
        local centerX = viewportSize.X * 0.5
        local centerY = viewportSize.Y * 0.5
        
        local FOV_RADIUS = (fovVal / 100.0) * (viewportSize.X / 2.0)
        
        local bestTarget = nil
        local bestScore = 99999999 
        
        local selBoneName = "head"
        if boneIdx == 1 then selBoneName = "head"
        elseif boneIdx == 2 then selBoneName = "spine_03"
        elseif boneIdx == 3 then selBoneName = "spine_01"
        elseif boneIdx == 4 then selBoneName = "pelvis" end

        for i, target in ipairs(enemies) do
            if not slua.isValid(target) then goto continue end
            
            pcall(function()
                if slua.isValid(target.Mesh) then
                    target.Mesh.MeshComponentUpdateFlag = 0
                end
            end)
            
            if igKnock and target.HealthStatus == 1 then goto continue end
            
            if igBot then
                local tIsBot = false
                if target.bIsAI == true or target.IsAI == true then tIsBot = true end
                local pState = target.PlayerState
                if slua.isValid(pState) and (pState.bIsABot or pState.bIsBot) then tIsBot = true end
                if tIsBot then goto continue end
            end
            
            if useVisCheck then
                local curTime = os.clock()
                local tId = type(target.GetUniqueID) == "function" and target:GetUniqueID() or tostring(target)
                _G.AimTouchVisCache = _G.AimTouchVisCache or {}
                if not _G.AimTouchVisCache[tId] or (curTime - _G.AimTouchVisCache[tId].time) > 0.2 then
                    local isHidden = true
                    pcall(function() if pc:LineOfSightTo(target) then isHidden = false end end)
                    _G.AimTouchVisCache[tId] = { hidden = isHidden, time = curTime }
                end
                if _G.AimTouchVisCache[tId].hidden then goto continue end
            end
            
            local tPos = target:GetBonePos(selBoneName, {X=0, Y=0, Z=0})
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then
                if type(target.GetSocketLocation) == "function" then
                    tPos = target:GetSocketLocation(selBoneName)
                end
            end
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then
                if type(target.K2_GetActorLocation) == "function" then
                    tPos = target:K2_GetActorLocation()
                    if tPos then
                        if boneIdx == 1 then tPos.Z = tPos.Z + 70
                        elseif boneIdx == 2 then tPos.Z = tPos.Z + 40
                        elseif boneIdx == 3 then tPos.Z = tPos.Z + 20 end
                    end
                end
            end
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then goto continue end
            
            local screen = FVector2D()
            local success = pc:ProjectWorldLocationToScreen(tPos, screen, false)
            if not success or screen.X <= 0 or screen.Y <= 0 then goto continue end
            
            local dx = screen.X - centerX
            local dy = screen.Y - centerY
            local distScreen = math.sqrt(dx*dx + dy*dy)
            
            if distScreen > FOV_RADIUS then goto continue end
            
            local currentScore = distScreen
            if prioMode == 2 then currentScore = player:GetDistanceTo(target)
            elseif prioMode == 3 then currentScore = target.Health or 100
            elseif prioMode == 4 then 
                local hp = target.Health or 100
                local maxhp = target.HealthMax or 100
                if maxhp <= 0 then maxhp = 100 end
                currentScore = hp / maxhp
            end
            
            if currentScore < bestScore then
                bestScore = currentScore
                bestTarget = target
            end
            
            ::continue::
        end
        
        if not slua.isValid(bestTarget) then return end
        
        local finalBonePos = bestTarget:GetBonePos(selBoneName, {X=0, Y=0, Z=0})
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then
            if type(bestTarget.GetSocketLocation) == "function" then
                finalBonePos = bestTarget:GetSocketLocation(selBoneName)
            end
        end
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then
            if type(bestTarget.K2_GetActorLocation) == "function" then
                finalBonePos = bestTarget:K2_GetActorLocation()
                if finalBonePos then
                    if boneIdx == 1 then finalBonePos.Z = finalBonePos.Z + 70
                    elseif boneIdx == 2 then finalBonePos.Z = finalBonePos.Z + 40
                    elseif boneIdx == 3 then finalBonePos.Z = finalBonePos.Z + 20 end
                end
            end
        end
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then return end
        
        local tVelocity = nil
        pcall(function()
            if type(bestTarget.GetVelocity) == "function" then
                tVelocity = bestTarget:GetVelocity()
            end
        end)

        if isMortar and _G.LexusConfig.AimTouchMortar and predVal > 0 then
            pcall(function()
                if tVelocity and (tVelocity.X ~= 0 or tVelocity.Y ~= 0) then
                    local approxDist = player:GetDistanceTo(bestTarget) / 100.0
                    local approxToF = approxDist / 100.0 
                    local predScale = predVal / 50.0
                    finalBonePos.X = finalBonePos.X + (tVelocity.X * approxToF * predScale)
                    finalBonePos.Y = finalBonePos.Y + (tVelocity.Y * approxToF * predScale)
                end
            end)
        end

        if not isMortar and predVal > 0 then
            pcall(function()
                if tVelocity and (tVelocity.X ~= 0 or tVelocity.Y ~= 0) then
                    local distToEnemy = player:GetDistanceTo(bestTarget) / 100.0
                    local ToF = (distToEnemy / 800.0) * (predVal / 50.0) 
                    finalBonePos.X = finalBonePos.X + (tVelocity.X * ToF)
                    finalBonePos.Y = finalBonePos.Y + (tVelocity.Y * ToF)
                end
            end)
        end

        local rot = KismetMathLibrary.FindLookAtRotation(camLoc, finalBonePos)
        if not rot then return end
        
        local currentRot = pc:GetControlRotation()
        if not currentRot then return end
        
        local deltaYaw = rot.Yaw - currentRot.Yaw
        local deltaPitch = rot.Pitch - currentRot.Pitch
        
        if isADS then
            local camRot = nil
            if type(camManager.GetCameraRotation) == "function" then
                camRot = camManager:GetCameraRotation()
            end
            if camRot then
                deltaYaw = deltaYaw - (camRot.Yaw - currentRot.Yaw)
                deltaPitch = deltaPitch - (camRot.Pitch - currentRot.Pitch)
            end
        end

        if deltaYaw > 180 then deltaYaw = deltaYaw - 360 end
        if deltaYaw < -180 then deltaYaw = deltaYaw + 360 end
        if deltaPitch > 180 then deltaPitch = deltaPitch - 360 end
        if deltaPitch < -180 then deltaPitch = deltaPitch + 360 end
        
        local smoothFactor = 0.0
        if speedVal >= 100 then
            smoothFactor = 1.0
        else
            smoothFactor = (speedVal / 100.0) * 0.3
            if smoothFactor < 0.01 then smoothFactor = 0.01 end
        end
        
        local finalPitch = currentRot.Pitch + (deltaPitch * smoothFactor)
        local finalYaw = currentRot.Yaw + (deltaYaw * smoothFactor)
        
        if recoilCompVal > 0 and isFiring then
            local pullDownForce = (recoilCompVal / 50.0) * 1.5 
            finalPitch = finalPitch - pullDownForce
        end
        
        if isMortar and _G.LexusConfig.AimTouchMortar then
            local targetPos = { X = finalBonePos.X, Y = finalBonePos.Y, Z = finalBonePos.Z }
            local launchPos = camLoc
            pcall(function()
                if player.K2_GetActorLocation then
                    local pLoc = player:K2_GetActorLocation()
                    if pLoc then 
                        launchPos = { X = pLoc.X, Y = pLoc.Y, Z = pLoc.Z + 50 } 
                    end
                end
            end)

            local function CalcMortarTrajectory(V, G, tX, tY, tZ)
                local mDx = math.sqrt((tX - launchPos.X)^2 + (tY - launchPos.Y)^2) - 80 
                if mDx < 500 then mDx = 500 end 
                local mDy = tZ - launchPos.Z
                
                local minVSq = G * (mDy + math.sqrt(mDx*mDx + mDy*mDy))
                if (V * V) < minVSq then
                    V = math.sqrt(minVSq) + 100 
                end

                local v2 = V * V
                local root = v2*v2 - G*(G*mDx*mDx + 2*mDy*v2)
                
                if root >= 0 then
                    local angleRad = math.atan((v2 + math.sqrt(root)) / (G * mDx))
                    local deg = math.deg(angleRad)
                    if deg >= 35 and deg <= 89.5 then 
                        return true, deg, mDx / (V * math.cos(angleRad)), mDx
                    end
                end
                return false, 45, 0, mDx
            end

            local vNear, gNear = 9070, 980 * 2.8   
            local vFar, gFar = 12520, 980 * 4.0    
            local vUltra, gUltra = 16800, 980 * 4.5 
            
            local isValid, physAngle, ToF, finalDx = false, 45, 0, 0
            
            local okNear, angNear, tofNear, dxN = CalcMortarTrajectory(vNear, gNear, targetPos.X, targetPos.Y, targetPos.Z)
            local okFar, angFar, tofFar, dxF = CalcMortarTrajectory(vFar, gFar, targetPos.X, targetPos.Y, targetPos.Z)
            local okUltra, angUltra, tofUltra, dxU = CalcMortarTrajectory(vUltra, gUltra, targetPos.X, targetPos.Y, targetPos.Z)

            if okNear and dxN <= 25000 then
                isValid, physAngle, ToF, finalDx = okNear, angNear, tofNear, dxN
            elseif okFar and dxF <= 40000 then
                isValid, physAngle, ToF, finalDx = okFar, angFar, tofFar, dxF
            elseif okUltra then
                isValid, physAngle, ToF, finalDx = okUltra, angUltra, tofUltra, dxU
            elseif okNear then
                isValid, physAngle, ToF, finalDx = okNear, angNear, tofNear, dxN
            end

            local targetCameraPitch = ((physAngle - 45) / 43.0) * 90.0 - 60.0
            local targetCameraYaw = rot.Yaw

            local deltaPitchMortar = targetCameraPitch - currentRot.Pitch
            local deltaYawMortar = targetCameraYaw - currentRot.Yaw

            if deltaPitchMortar > 180 then deltaPitchMortar = deltaPitchMortar - 360 end
            if deltaPitchMortar < -180 then deltaPitchMortar = deltaPitchMortar + 360 end
            if deltaYawMortar > 180 then deltaYawMortar = deltaYawMortar - 360 end
            if deltaYawMortar < -180 then deltaYawMortar = deltaYawMortar + 360 end
            
            finalPitch = currentRot.Pitch + (deltaPitchMortar * smoothFactor)
            finalYaw = currentRot.Yaw + (deltaYawMortar * smoothFactor)
        end

        local finalRot = { Pitch = finalPitch, Yaw = finalYaw, Roll = 0 }
        pc:SetControlRotation(finalRot, "AimTouch")
        
        if isShotgun and _G.LexusConfig.AimTouchSGAutoFire then
            pcall(function()
                local distToTarget = player:GetDistanceTo(bestTarget) / 100
                if distToTarget <= maxDistMeters then
                    player.bIsWeaponFiring = true
                    if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(true) end
                    if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(true) end
                    local wepMgr = player.WeaponManagerComponent
                    if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = true end
                    
                    local currentWep = player:GetCurrentWeapon()
                    if slua.isValid(currentWep) and type(currentWep.StartFire) == "function" then 
                        currentWep:StartFire() 
                    end
                    _G.LexusState.IsAutoFiring = true
                end
            end)
        end
    end)
end

-- ========================================== 
-- HỆ THỐNG WALL & ESP VẬT PHẨM/PHƯƠNG TIỆN 
-- ========================================== 
local C_AR      = {R = 255, G = 255, B = 0, A = 255}
local C_SMG     = {R = 0, G = 255, B = 255, A = 255}
local C_Sniper  = {R = 255, G = 0, B = 0, A = 255}
local C_Shotgun = {R = 0, G = 255, B = 0, A = 255}
local C_LMG     = {R = 255, G = 255, B = 255, A = 255}
local C_Pistol  = {R = 200, G = 200, B = 200, A = 255}
local C_Special = {R = 255, G = 0, B = 255, A = 255}
local C_Melee   = {R = 150, G = 150, B = 150, A = 255}
local C_Scope   = {R = 0, G = 0, B = 255, A = 255}
local C_Grenade = {R = 255, G = 165, B = 0, A = 255}
local C_Med     = {R = 50, G = 255, B = 50, A = 255}

local ItemDatabase = {
    [101001] = { name = "AKM", cat = "AR", color = C_AR }, [101002] = { name = "M16A4", cat = "AR", color = C_AR },
    [101003] = { name = "SCAR-L", cat = "AR", color = C_AR }, [101004] = { name = "M416", cat = "AR", color = C_AR },
    [101005] = { name = "Groza", cat = "AR", color = C_AR }, [101006] = { name = "AUG", cat = "AR", color = C_AR },
    [101007] = { name = "QBZ", cat = "AR", color = C_AR }, [101008] = { name = "M762", cat = "AR", color = C_AR },
    [101009] = { name = "Mk47 Mutant", cat = "AR", color = C_AR }, [101010] = { name = "G36C", cat = "AR", color = C_AR },
    [101011] = { name = "AC-VAL", cat = "AR", color = C_AR }, [101012] = { name = "Honey Badger", cat = "AR", color = C_AR },
    [101100] = { name = "FAMAS", cat = "AR", color = C_AR }, [101101] = { name = "ASM Abakan AR", cat = "AR", color = C_AR },
    [101102] = { name = "ACE32", cat = "AR", color = C_AR },
    [102001] = { name = "UZI", cat = "SMG", color = C_SMG }, [102002] = { name = "UMP45", cat = "SMG", color = C_SMG },
    [102003] = { name = "Vector", cat = "SMG", color = C_SMG }, [102004] = { name = "Thompson SMG", cat = "SMG", color = C_SMG },
    [102005] = { name = "PP-19 Bizon", cat = "SMG", color = C_SMG }, [102007] = { name = "MP5K", cat = "SMG", color = C_SMG },
    [102008] = { name = "JS9", cat = "SMG", color = C_SMG }, [102105] = { name = "P90", cat = "SMG", color = C_SMG },
    [103001] = { name = "Kar98K", cat = "Sniper", color = C_Sniper }, [103002] = { name = "M24", cat = "Sniper", color = C_Sniper },
    [103003] = { name = "AWM", cat = "Sniper", color = C_Sniper }, [103004] = { name = "SKS", cat = "Sniper", color = C_Sniper },
    [103005] = { name = "VSS", cat = "Sniper", color = C_Sniper }, [103006] = { name = "Mini14", cat = "Sniper", color = C_Sniper },
    [103007] = { name = "Mk14", cat = "Sniper", color = C_Sniper }, [103008] = { name = "Win94", cat = "Sniper", color = C_Sniper },
    [103009] = { name = "SLR", cat = "Sniper", color = C_Sniper }, [103010] = { name = "QBU", cat = "Sniper", color = C_Sniper },
    [103011] = { name = "Mosin Nagant", cat = "Sniper", color = C_Sniper }, [103012] = { name = "AMR", cat = "Sniper", color = C_Sniper },
    [103100] = { name = "Mk12", cat = "Sniper", color = C_Sniper }, [103101] = { name = "TR-2A Air Gun", cat = "Sniper", color = C_Sniper },
    [103102] = { name = "DSR", cat = "Sniper", color = C_Sniper }, [103103] = { name = "Sniper Rifle", cat = "Sniper", color = C_Sniper },
    [103104] = { name = "Sniper Rifle", cat = "Sniper", color = C_Sniper }, [103105] = { name = "SR", cat = "Sniper", color = C_Sniper },
    [104001] = { name = "S686", cat = "Shotgun", color = C_Shotgun }, [104002] = { name = "S1897", cat = "Shotgun", color = C_Shotgun },
    [104003] = { name = "S12K", cat = "Shotgun", color = C_Shotgun }, [104004] = { name = "DBS", cat = "Shotgun", color = C_Shotgun },
    [104100] = { name = "SPAS-12", cat = "Shotgun", color = C_Shotgun }, [104101] = { name = "M1014", cat = "Shotgun", color = C_Shotgun },
    [104102] = { name = "NS2000", cat = "Shotgun", color = C_Shotgun },
    [105001] = { name = "M249", cat = "LMG", color = C_LMG }, [105002] = { name = "DP-28", cat = "LMG", color = C_LMG },
    [105003] = { name = "M134", cat = "LMG", color = C_LMG }, [105010] = { name = "MG3", cat = "LMG", color = C_LMG },
    [105101] = { name = "Gatling", cat = "LMG", color = C_LMG }, [105115] = { name = "Lib Gatling MG", cat = "LMG", color = C_LMG },
    [105004] = { name = "Flamethrower", cat = "LMG", color = C_LMG }, [105006] = { name = "M2 Fixed MG", cat = "LMG", color = C_LMG },
    [105007] = { name = "Gatling Fixed MG", cat = "LMG", color = C_LMG }, [105008] = { name = "Mounted Flamethrower", cat = "LMG", color = C_LMG },
    [105009] = { name = "M2 Mounted MG", cat = "LMG", color = C_LMG }, [105102] = { name = "Vehicle SG", cat = "LMG", color = C_LMG },
    [105103] = { name = "RPG", cat = "LMG", color = C_LMG }, [105104] = { name = "RPG", cat = "LMG", color = C_LMG },
    [105105] = { name = "PowPow MG", cat = "LMG", color = C_LMG }, [105106] = { name = "Tank Cannon", cat = "LMG", color = C_LMG },
    [105107] = { name = "Tank MG", cat = "LMG", color = C_LMG }, [105108] = { name = "Tank Flare Gun", cat = "LMG", color = C_LMG },
    [105116] = { name = "Lib Autocannon", cat = "LMG", color = C_LMG }, [105117] = { name = "Jet Missile", cat = "LMG", color = C_LMG },
    [105118] = { name = "Jet Autocannon", cat = "LMG", color = C_LMG },
    [106001] = { name = "P92", cat = "Pistol", color = C_Pistol }, [106002] = { name = "P1911", cat = "Pistol", color = C_Pistol },
    [106003] = { name = "R1895", cat = "Pistol", color = C_Pistol }, [106004] = { name = "P18C", cat = "Pistol", color = C_Pistol },
    [106005] = { name = "R45", cat = "Pistol", color = C_Pistol }, [106006] = { name = "Sawed-off", cat = "Pistol", color = C_Pistol },
    [106008] = { name = "Skorpion", cat = "Pistol", color = C_Pistol }, [106010] = { name = "Desert Eagle", cat = "Pistol", color = C_Pistol },
    [106007] = { name = "Flare Gun", cat = "Pistol", color = C_Pistol }, [106009] = { name = "Flare Gun", cat = "Pistol", color = C_Pistol },
    [106011] = { name = "Dual MP7", cat = "Pistol", color = C_Pistol }, [106012] = { name = "Welding Gun", cat = "Pistol", color = C_Pistol },
    [106013] = { name = "Stun Gun", cat = "Pistol", color = C_Pistol }, [106101] = { name = "Vehicle Flare", cat = "Pistol", color = C_Pistol },
    [106103] = { name = "Flare Gun", cat = "Pistol", color = C_Pistol }, [106106] = { name = "Flare (Empty)", cat = "Pistol", color = C_Pistol },
    [106107] = { name = "Respawn Flare", cat = "Pistol", color = C_Pistol }, [106203] = { name = "Magnet Gun", cat = "Pistol", color = C_Pistol },
    [107011] = { name = "Súng Cối", cat = "Special", color = C_Special }, [307006] = { name = "Đạn Cối", cat = "Special", color = C_Special },
    [107001] = { name = "Crossbow", cat = "Special", color = C_Special }, [107002] = { name = "RPG-7", cat = "Special", color = C_Special },
    [107003] = { name = "Riot shield", cat = "Special", color = C_Special }, [107004] = { name = "Combat Drone", cat = "Special", color = C_Special },
    [107005] = { name = "Panzerfaust", cat = "Special", color = C_Special }, [107006] = { name = "RPG-7", cat = "Special", color = C_Special },
    [107007] = { name = "Tactical Crossbow", cat = "Special", color = C_Special }, [107008] = { name = "Explosive Bow", cat = "Special", color = C_Special },
    [107009] = { name = "Explosive Bow", cat = "Special", color = C_Special }, [107010] = { name = "M79 Smoke Launcher", cat = "Special", color = C_Special },
    [107019] = { name = "Atlas Gauntlet", cat = "Special", color = C_Special }, [107020] = { name = "Explosive Crossbow", cat = "Special", color = C_Special },
    [107021] = { name = "Mercury Hammer", cat = "Special", color = C_Special }, [107022] = { name = "Fishbones Rocket", cat = "Special", color = C_Special },
    [107092] = { name = "MGL", cat = "Special", color = C_Special }, [107093] = { name = "M202 Quad RPG", cat = "Special", color = C_Special },
    [107094] = { name = "AT4-A Laser Missile", cat = "Special", color = C_Special }, [107095] = { name = "M202 Quad RPG", cat = "Special", color = C_Special },
    [107096] = { name = "M79 Sawed-off", cat = "Special", color = C_Special }, [107097] = { name = "M79", cat = "Special", color = C_Special },
    [107098] = { name = "MGL", cat = "Special", color = C_Special }, [107099] = { name = "M3E1-A", cat = "Special", color = C_Special },
    [108001] = { name = "Machete", cat = "Melee", color = C_Melee }, [108002] = { name = "Crowbar", cat = "Melee", color = C_Melee },
    [108003] = { name = "Sickle", cat = "Melee", color = C_Melee }, [108004] = { name = "Pan", cat = "Melee", color = C_Melee },
    [108005] = { name = "Dagger", cat = "Melee", color = C_Melee }, [108006] = { name = "Mutation Blade", cat = "Melee", color = C_Melee },
    [108007] = { name = "Mutation Gauntlets", cat = "Melee", color = C_Melee },
    [203001] = { name = "Red Dot Sight", cat = "Scope", color = C_Scope }, [203002] = { name = "Holographic Sight", cat = "Scope", color = C_Scope },
    [203003] = { name = "2x Scope", cat = "Scope", color = C_Scope }, [203004] = { name = "4x Scope", cat = "Scope", color = C_Scope },
    [203005] = { name = "8x Scope", cat = "Scope", color = C_Scope }, [203014] = { name = "3x Scope", cat = "Scope", color = C_Scope },
    [203015] = { name = "6x Scope", cat = "Scope", color = C_Scope },
    [602001] = { name = "Stun Grenade", cat = "Grenade", color = C_Grenade }, [602002] = { name = "Smoke Grenade", cat = "Grenade", color = C_Grenade },
    [602003] = { name = "Molotov", cat = "Grenade", color = C_Grenade }, [602004] = { name = "Frag Grenade", cat = "Grenade", color = C_Grenade },
    [601001] = { name = "Nước Tăng Lực", cat = "Med", color = C_Med }, [601002] = { name = "Tiêm Adrenaline", cat = "Med", color = C_Med },
    [601003] = { name = "Thuốc Giảm Đau", cat = "Med", color = C_Med }, [601004] = { name = "Băng Gạc", cat = "Med", color = C_Med },
    [601005] = { name = "Bộ Sơ Cứu", cat = "Med", color = C_Med }, [601006] = { name = "Bộ Cứu Thương", cat = "Med", color = C_Med },
    [601009] = { name = "Băng Gạc Nhanh", cat = "Med", color = C_Med }, [601010] = { name = "Sơ Cứu Nhanh", cat = "Med", color = C_Med },
    [601011] = { name = "Băng Gạc QĐ", cat = "Med", color = C_Med }, [601012] = { name = "Nước Đậm Đặc", cat = "Med", color = C_Med },
    [601020] = { name = "Băng Gạc", cat = "Med", color = C_Med }, [601021] = { name = "Bộ Sơ Cứu", cat = "Med", color = C_Med },
    [601022] = { name = "Bộ Cứu Thương", cat = "Med", color = C_Med }, [601023] = { name = "Tiêm Adrenaline", cat = "Med", color = C_Med },
    [601061] = { name = "Bộ Cứu Thương", cat = "Med", color = C_Med }, [601077] = { name = "Sơ Cứu Chiến Thuật", cat = "Med", color = C_Med },
    [601078] = { name = "Sơ Cứu Toàn Năng", cat = "Med", color = C_Med }, [601079] = { name = "Cứu Thương Toàn Năng", cat = "Med", color = C_Med },
    [601080] = { name = "Băng Gạc QĐ", cat = "Med", color = C_Med }, [601081] = { name = "Nước Đậm Đặc", cat = "Med", color = C_Med },
    [601084] = { name = "Sơ Cứu Nhanh", cat = "Med", color = C_Med }, [601085] = { name = "Cứu Thương Nhanh", cat = "Med", color = C_Med },
    [601095] = { name = "Máy AED (Hồi Sinh)", cat = "Med", color = C_Med }, [601096] = { name = "Chuẩn Bị Chiến Đấu", cat = "Med", color = C_Med },
    [602054] = { name = "Tiếp Tế Y Tế", cat = "Med", color = C_Med }, [602069] = { name = "Cứu Trợ Khẩn Cấp", cat = "Med", color = C_Med }
}

_G.CachedItems = {}
_G.LastScanItemTime = 0
_G.AppliedVehicleWall = {}
_G.AppliedItemESP = {}

_G.RunOptimizedItemAndVehicleESP = function(pc)
    local curTime = os.clock()

    if curTime - _G.LastScanItemTime > 1.0 then
        _G.LastScanItemTime = curTime
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end

        if _G.LexusConfig.WallVehicle then
            local ASTExtraVehicleBase = import("STExtraVehicleBase")
            if ASTExtraVehicleBase then
                local Actors = Game:GetActorsByClass(ASTExtraVehicleBase)
                if Actors then
                    local count = Actors:Num() or 0
                    for i = 0, count - 1 do
                        local vehicle = Actors:Get(i)
                        if slua.isValid(vehicle) and vehicle.GetMesh then
                            local dist = player:GetDistanceTo(vehicle)
                            if dist <= 200000 then 
                                local vId = tostring(vehicle)
                                if not _G.AppliedVehicleWall[vId] then
                                    local mesh = vehicle:GetMesh()
                                    if slua.isValid(mesh) then
                                        local matInterface = mesh:GetMaterial(0)
                                        if slua.isValid(matInterface) then
                                            local baseMat = matInterface:GetBaseMaterial()
                                            if slua.isValid(baseMat) then
                                                baseMat.bDisableDepthTest = true
                                                baseMat.BlendMode = 2
                                                _G.AppliedVehicleWall[vId] = true
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else _G.AppliedVehicleWall = {} end

        if _G.LexusConfig.EspItem_Master then
            local APickUpWrapperActor = import("PickUpWrapperActor") or import("STPickupWrapperActor")
            if APickUpWrapperActor then
                local Actors = Game:GetActorsByClass(APickUpWrapperActor)
                _G.CachedItems = {}
                if Actors then
                    local count = Actors:Num() or 0
                    for i = 0, count - 1 do
                        local item = Actors:Get(i)
                        
                        local isPendingKill = false
                        pcall(function() if type(item.IsPendingKill) == "function" then isPendingKill = item:IsPendingKill() end end)

                        if slua.isValid(item) and not item.bHidden and not isPendingKill then
                            local dist = player:GetDistanceTo(item)
                            if dist <= 7000 then
                                local itemId = item.DefineID and item.DefineID.TypeSpecificID or item.DefineId
                                local itemData = ItemDatabase[itemId]
                                
                                if itemData then
                                    local isShow = false
                                    if itemData.cat == "AR" and _G.LexusConfig.EspItem_AR then isShow = true
                                    elseif itemData.cat == "Sniper" and _G.LexusConfig.EspItem_Sniper then isShow = true
                                    elseif itemData.cat == "SMG" and _G.LexusConfig.EspItem_SMG then isShow = true
                                    elseif itemData.cat == "Shotgun" and _G.LexusConfig.EspItem_Shotgun then isShow = true
                                    elseif itemData.cat == "LMG" and _G.LexusConfig.EspItem_LMG then isShow = true
                                    elseif itemData.cat == "Pistol" and _G.LexusConfig.EspItem_Pistol then isShow = true
                                    elseif itemData.cat == "Melee" and _G.LexusConfig.EspItem_Melee then isShow = true
                                    elseif itemData.cat == "Special" and _G.LexusConfig.EspItem_Special then isShow = true
                                    elseif itemData.cat == "Grenade" and _G.LexusConfig.EspItem_Grenade then isShow = true
                                    elseif itemData.cat == "Scope" and _G.LexusConfig.EspItem_Scope then isShow = true
                                    elseif itemData.cat == "Med" and _G.LexusConfig.EspItem_Med then isShow = true
                                    end

                                    if isShow then
                                        table.insert(_G.CachedItems, item)

                                        local iId = tostring(item)
                                        if not _G.AppliedItemESP[iId] then
                                            local meshes = {}
                                            if item.GetPickupMesh then
                                                local pMesh = item:GetPickupMesh()
                                                if slua.isValid(pMesh) then table.insert(meshes, pMesh) end
                                            end
                                            local childs = item:GetComponentsByClass(import("StaticMeshComponent"))
                                            if childs then
                                                for _, v in pairs(childs) do
                                                    if slua.isValid(v) then table.insert(meshes, v) end
                                                end
                                            end
                                            for _, mesh in pairs(meshes) do
                                                pcall(function() mesh:SetRenderCustomDepth(true) end)
                                                for mi = 0, 8 do
                                                    local mid = mesh:CreateAndSetMaterialInstanceDynamic(mi)
                                                    if slua.isValid(mid) then
                                                        local colorVisible = {R = 50, G = 50, B = 0, A = 10}
                                                        pcall(function()
                                                            mid:SetVectorParameterValue("LightColor", colorVisible)
                                                            mid:SetVectorParameterValue("ParaScaleOffset", {R = 3, G = 3, B = 0, A = 0})
                                                            mid:SetScalarParameterValue("RimLight", 999)
                                                            mid:SetScalarParameterValue("Brightness", 999)
                                                            mid:SetScalarParameterValue("Exposure", 999)
                                                        end)
                                                    end
                                                end
                                            end
                                            _G.AppliedItemESP[iId] = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else 
            _G.AppliedItemESP = {}
            _G.CachedItems = {}
        end
    end

    if _G.LexusConfig.EspItem_Master and slua.isValid(pc) and pc.MyHUD then
        local hud = pc.MyHUD
        local player = GameplayData.GetPlayerCharacter()
        for _, item in ipairs(_G.CachedItems) do
            if slua.isValid(item) and not item.bHidden then
                local itemId = item.DefineID and item.DefineID.TypeSpecificID or item.DefineId
                if itemId and ItemDatabase[itemId] then
                    local itemData = ItemDatabase[itemId]
                    local dist = (player.GetDistanceTo and player:GetDistanceTo(item) or 0) / 100
                    local displayText = string.format("%s [%.0fm]", itemData.name, dist)
                    local textColor = {R = itemData.color.R, G = itemData.color.G, B = itemData.color.B, A = 255}
                    hud:AddDebugText(
                        displayText, item, 0.06, 
                        {X=0, Y=0, Z=50}, {X=0, Y=0, Z=50}, 
                        textColor, true, false, true, nil, 0.8, true
                    )
                end
            end
        end
    end
end

-- ========================================== 
-- UI WIDGET ĐẾM ĐỊCH & KHOẢNG CÁCH 
-- ========================================== 
local BTN_BP = "/Game/UMG/UI_BP/Common/BaseComponent/CommonBaseComponent_TextButton_UIBP.CommonBaseComponent_TextButton_UIBP"
local EnemyCounterWidget = nil
local WarningTargetWidget = nil
local LastCounterTime = 0

function _G.CleanUpEnemyCounterWidget()
    if EnemyCounterWidget and slua.isValid(EnemyCounterWidget) then
        EnemyCounterWidget:RemoveFromParent()
    end
    EnemyCounterWidget = nil

    if WarningTargetWidget and slua.isValid(WarningTargetWidget) then
        WarningTargetWidget:RemoveFromParent()
    end
    WarningTargetWidget = nil
end

local function CreateEnemyCounterWidget()
    if EnemyCounterWidget then
        if slua.isValid(EnemyCounterWidget) then return EnemyCounterWidget else EnemyCounterWidget = nil end
    end

    pcall(function()
        local btn = slua.loadUI(BTN_BP)
        if not btn or not slua.isValid(btn) then return end
        require("game_frontend_hud").AddToContainer(UIContainers.Top, btn, 10500)
        
        if btn.RichText_Content then
            btn.RichText_Content:SetText("Kẻ Địch: 0  |  Gần Nhất: 0m")
            local fontInfo = btn.RichText_Content.Font
            if fontInfo then fontInfo.Size = 16 btn.RichText_Content:SetFont(fontInfo) end
        end
        
        local WidgetLayoutLibrary = import("WidgetLayoutLibrary")
        local slot = WidgetLayoutLibrary.SlotAsCanvasSlot(btn)
        if slot then
            slot:SetAnchors(FAnchors(0.5, 0, 0.5, 0))
            slot:SetAlignment(FVector2D(0.5, 0))
            slot:SetPosition(FVector2D(0, 30))
            slot:SetSize(FVector2D(240, 36))
        end
        btn:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        EnemyCounterWidget = btn
    end)
    return EnemyCounterWidget
end

local function CreateWarningTargetWidget()
    if WarningTargetWidget then
        if slua.isValid(WarningTargetWidget) then return WarningTargetWidget else WarningTargetWidget = nil end
    end

    pcall(function()
        local btn = slua.loadUI(BTN_BP)
        if not btn or not slua.isValid(btn) then return end
        require("game_frontend_hud").AddToContainer(UIContainers.Top, btn, 10501)
        
        if btn.RichText_Content then
            btn.RichText_Content:SetText("ĐỊCH ĐANG NHÌN VỀ PHÍA BẠN")
            local fontInfo = btn.RichText_Content.Font
            if fontInfo then fontInfo.Size = 18 btn.RichText_Content:SetFont(fontInfo) end
        end
        
        local WidgetLayoutLibrary = import("WidgetLayoutLibrary")
        local slot = WidgetLayoutLibrary.SlotAsCanvasSlot(btn)
        if slot then
            slot:SetAnchors(FAnchors(0.5, 0, 0.5, 0))
            slot:SetAlignment(FVector2D(0.5, 0))
            slot:SetPosition(FVector2D(0, 75))
            slot:SetSize(FVector2D(260, 36))
        end
        btn:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        WarningTargetWidget = btn
    end)
    return WarningTargetWidget
end

local function _M_DrawCounter()
    pcall(function()
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then 
            if EnemyCounterWidget and slua.isValid(EnemyCounterWidget) then
                EnemyCounterWidget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
            if WarningTargetWidget and slua.isValid(WarningTargetWidget) then
                WarningTargetWidget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
            return 
        end

        local widgetCounter = CreateEnemyCounterWidget()
        local widgetWarning = CreateWarningTargetWidget()

        if widgetCounter and slua.isValid(widgetCounter) then
            widgetCounter:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end

        local curTime = os.clock()
        if (curTime - LastCounterTime) > 0.5 then
            LastCounterTime = curTime
            
            local myTeam = player.TeamID or (type(player.GetTeamID) == "function" and player:GetTeamID()) or 0
            local count = 0
            local nearest = 9999
            local isBeingTargeted = false
            
            local KismetMathLibrary = import("KismetMathLibrary")
            local pc = player:GetPlayerControllerSafety()

            local allCharacters = {}
            if GameplayData.GetAllPlayerCharacters then
                allCharacters = GameplayData.GetAllPlayerCharacters()
            elseif GameplayData.GameCharacters then
                for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end
            end

            for _, tPawn in pairs(allCharacters) do
                if slua.isValid(tPawn) and tPawn ~= player then
                    local isAlive = false
                    if tPawn.HealthStatus ~= nil then
                        isAlive = (tPawn.HealthStatus ~= 2)
                    else
                        isAlive = (tPawn.Health or 0) > 0 or (type(tPawn.IsAlive) == "function" and tPawn:IsAlive())
                    end
                    
                    if isAlive then
                        local tTeam = tPawn.TeamID or (type(tPawn.GetTeamID) == "function" and tPawn:GetTeamID()) or 0
                        if tTeam ~= myTeam then
                            count = count + 1
                            local d = math.floor(player:GetDistanceTo(tPawn) / 100)
                            if d < nearest then nearest = d end
                            
                            if _G.LexusConfig.EspAimWarning and not isBeingTargeted and d < 400 then
                                local eLoc = type(tPawn.K2_GetActorLocation) == "function" and tPawn:K2_GetActorLocation()
                                local pLoc = type(player.K2_GetActorLocation) == "function" and player:K2_GetActorLocation()
                                
                                if eLoc and pLoc and KismetMathLibrary then
                                    local lookRot = KismetMathLibrary.FindLookAtRotation(eLoc, pLoc)
                                    local eRot = nil
                                    
                                    if type(tPawn.GetControlRotation) == "function" then
                                        eRot = tPawn:GetControlRotation()
                                    elseif type(tPawn.GetActorRotation) == "function" then
                                        eRot = tPawn:GetActorRotation()
                                    end
                                    
                                    if eRot and lookRot then
                                        local dYaw = math.abs(eRot.Yaw - lookRot.Yaw)
                                        if dYaw > 180 then dYaw = 360 - dYaw end
                                        
                                        local dPitch = math.abs(eRot.Pitch - lookRot.Pitch)
                                        if dPitch > 180 then dPitch = 360 - dPitch end
                                        
                                        if dYaw < 15 and dPitch < 20 then
                                            if _G.LexusConfig.EspAimWarningVisCheck then
                                                if slua.isValid(pc) and type(pc.LineOfSightTo) == "function" then
                                                    if pc:LineOfSightTo(tPawn) then
                                                        isBeingTargeted = true
                                                    end
                                                end
                                            else
                                                isBeingTargeted = true
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if widgetCounter and widgetCounter.RichText_Content then
                widgetCounter.RichText_Content:SetText(string.format("Địch Xung Quanh: %d  |  Gần Nhất: %dm", count, count > 0 and nearest or 0))
            end

            if widgetWarning and slua.isValid(widgetWarning) then
                if _G.LexusConfig.EspAimWarning and isBeingTargeted then
                    widgetWarning:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                else
                    widgetWarning:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                end
            end
        end
    end)
end

-- ==========================================
-- VÒNG FOV AIMBOT V2
-- ==========================================
_G.FovCircleOverlay = {
    Container = nil,
    WidgetSlot = nil,
    Lines = {},
    NumSegments = 45,
    Thickness = 1.5,  
    LastRadius = -1,
    LastColor = -1,
    LastCX = -1,
    LastCY = -1,
    PrecalcMath = nil
}

local function GetFOVColor(idx)
    if idx == 1 then return 1.0, 0.0, 0.0 end
    if idx == 2 then return 0.0, 1.0, 0.0 end
    if idx == 3 then return 0.0, 0.0, 1.0 end
    if idx == 4 then return 1.0, 1.0, 0.0 end
    if idx == 5 then return 0.65, 0.15, 1.0 end
    if idx == 6 then return 0.0, 1.0, 1.0 end
    if idx == 7 then return 1.0, 1.0, 1.0 end
    return 1.0, 1.0, 1.0 
end

function _G.FovCircleOverlay.Create()
    if _G.FovCircleOverlay.Container and slua.isValid(_G.FovCircleOverlay.Container) then return true end
    
    local ParentCanvas = nil
    pcall(function()
        local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        local MainUI = InGameUITools.GetMainControlBaseUI()
        if slua.isValid(MainUI) then
            if slua.isValid(MainUI.CanvasPanel_0) then ParentCanvas = MainUI.CanvasPanel_0
            elseif slua.isValid(MainUI.CanvasPanel_42) then ParentCanvas = MainUI.CanvasPanel_42 end
        end
    end)
    
    if not ParentCanvas or not slua.isValid(ParentCanvas) then return false end

    local Container = nil
    pcall(function() Container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", ParentCanvas) end)
    if not Container or not slua.isValid(Container) then return false end

    local FVector2D = import("Vector2D") or _G.FVector2D
    
    for i = 1, _G.FovCircleOverlay.NumSegments do
        local border = nil
        pcall(function() border = CGame:NewObjectFromPath("/Script/UMG.Border", Container) end)
        if border and slua.isValid(border) then
            pcall(function() 
                border.RenderTransformPivot = FVector2D(0, 0.5)
                border:SetRenderTransformPivot(FVector2D(0, 0.5)) 
                border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            local slot = Container:AddChildToCanvas(border)
            if slot then
                pcall(function() slot:SetAlignment(FVector2D(0, 0.5)) end)
            end
            _G.FovCircleOverlay.Lines[i] = { widget = border, slot = slot }
        end
    end

    local MainSlot = nil
    pcall(function() MainSlot = ParentCanvas:AddChildToCanvas(Container) end)
    if MainSlot then
        pcall(function()
            MainSlot:SetAutoSize(false)
            MainSlot:SetSize(FVector2D(0, 0))
            MainSlot:SetZOrder(995)
            MainSlot:SetAlignment(FVector2D(0, 0))
            MainSlot:SetPosition(FVector2D(0, 0))
        end)
    end
    _G.FovCircleOverlay.Container = Container
    _G.FovCircleOverlay.WidgetSlot = MainSlot
    return true
end

function _G.FovCircleOverlay.Update(pc, player)
    if not _G.LexusConfig.EspFovCircle then
        if _G.FovCircleOverlay.Container and slua.isValid(_G.FovCircleOverlay.Container) then
            pcall(function() _G.FovCircleOverlay.Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
            _G.FovCircleOverlay.LastRadius = -1
        end
        return
    end

    local fovVal = 30
    local colIdx = 7
    
    local cData = _G.LexusState.CustomTextData
    local WEAPON_TYPE = _G.__AimTouch_WeaponType or "NORMAL"
    local isADS = player.bIsGunADS or false

    if WEAPON_TYPE == "MORTAR" then
        fovVal = cData.AimTouchMortarFOV or 360
        colIdx = tonumber(cData.AimTouchMortarFOVColor) or 5
    elseif WEAPON_TYPE == "SHOTGUN" then
        fovVal = cData.AimTouchSGFOV or 40
        colIdx = tonumber(cData.AimTouchSGFOVColor) or 1
    elseif isADS then
        if WEAPON_TYPE == "SNIPER" then
            fovVal = cData.AimTouchSniperFOV or 20
            colIdx = tonumber(cData.AimTouchSniperFOVColor) or 4
        else
            fovVal = cData.AimTouchScopeFOV or 30
            colIdx = tonumber(cData.AimTouchScopeFOVColor) or 6
        end
    else
        fovVal = cData.AimTouchHipFOV or 30
        colIdx = tonumber(cData.AimTouchHipFOVColor) or 7
    end

    local rawCX = _G.__AimTouch_CenterX or 960
    local rawCY = _G.__AimTouch_CenterY or 540
    local vpX = _G.__AimTouch_ViewportX or 1920

    local centerX = rawCX
    local centerY = rawCY
    local scaleX = 1.0

    pcall(function()
        local parentCanvas = _G.FovCircleOverlay.Container:GetParent()
        if not slua.isValid(parentCanvas) then return end
        local cg = parentCanvas:GetCachedGeometry()
        if not cg then return end
        
        local SBL = import("SlateBlueprintLibrary") or import("/Script/UMG.SlateBlueprintLibrary")
        local WLL = import("WidgetLayoutLibrary") or import("/Script/UMG.WidgetLayoutLibrary")
        local FVector2D = import("Vector2D") or _G.FVector2D

        local success = false
        if SBL and SBL.AbsoluteToLocal then
            local pt0 = SBL.AbsoluteToLocal(cg, FVector2D(0, 0))
            local pt1 = SBL.AbsoluteToLocal(cg, FVector2D(100, 100))
            local centerPt = SBL.AbsoluteToLocal(cg, FVector2D(rawCX, rawCY))
            if pt0 and pt1 and centerPt then
                centerX = centerPt.X
                centerY = centerPt.Y
                scaleX = (pt1.X - pt0.X) / 100.0
                success = true
            end
        end

        if not success and WLL and WLL.ScreenToWidgetLocal then
            local pt0 = FVector2D(0, 0)
            local pt1 = FVector2D(0, 0)
            local centerPt = FVector2D(0, 0)
            WLL.ScreenToWidgetLocal(pc, cg, FVector2D(0, 0), pt0)
            WLL.ScreenToWidgetLocal(pc, cg, FVector2D(100, 100), pt1)
            WLL.ScreenToWidgetLocal(pc, cg, FVector2D(rawCX, rawCY), centerPt)
            
            centerX = centerPt.X
            centerY = centerPt.Y
            scaleX = (pt1.X - pt0.X) / 100.0
            success = true
        end
        
        if not success and WLL and WLL.GetViewportScale then
            local scale = WLL.GetViewportScale(pc)
            if scale and scale > 0 then
                scaleX = 1.0 / scale
                centerX = rawCX * scaleX
                centerY = rawCY * scaleX
            end
        end
    end)

    local rawRadius = (fovVal / 100.0) * (vpX / 2.0)
    local targetRadius = rawRadius * scaleX

    if _G.FovCircleOverlay.Container and slua.isValid(_G.FovCircleOverlay.Container) then
        local parent = nil
        pcall(function() parent = _G.FovCircleOverlay.Container:GetParent() end)
        if not parent or not slua.isValid(parent) then
            _G.FovCircleOverlay.Container = nil
        end
    end

    if not _G.FovCircleOverlay.Create() then return end
    pcall(function() _G.FovCircleOverlay.Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)

    if math.abs(_G.FovCircleOverlay.LastRadius - targetRadius) < 0.5 
       and _G.FovCircleOverlay.LastColor == colIdx 
       and math.abs(_G.FovCircleOverlay.LastCX - centerX) < 0.5 
       and math.abs(_G.FovCircleOverlay.LastCY - centerY) < 0.5 then
        return
    end

    _G.FovCircleOverlay.LastRadius = targetRadius
    _G.FovCircleOverlay.LastColor = colIdx
    _G.FovCircleOverlay.LastCX = centerX
    _G.FovCircleOverlay.LastCY = centerY

    local FLinearColor = import("LinearColor") or _G.FLinearColor
    local r, g, b = GetFOVColor(colIdx)
    local dim = 0.55 
    local color = FLinearColor and FLinearColor(r * dim, g * dim, b * dim, 1.0) or {R=r*dim*255, G=g*dim*255, B=b*dim*255, A=255}

    local numSegments = _G.FovCircleOverlay.NumSegments

    if not _G.FovCircleOverlay.PrecalcMath then
        _G.FovCircleOverlay.PrecalcMath = {}
        local angleStep = 360.0 / numSegments
        local math_cos = math.cos
        local math_sin = math.sin
        local math_rad = math.rad
        local math_atan2 = math.atan2 or math.atan
        
        for i = 1, numSegments do
            local angle1 = math_rad((i - 1) * angleStep)
            local angle2 = math_rad(i * angleStep)
            local c1, s1 = math_cos(angle1), math_sin(angle1)
            local c2, s2 = math_cos(angle2), math_sin(angle2)
            
            local dx_unit = c2 - c1
            local dy_unit = s2 - s1
            local dist_unit = math.sqrt(dx_unit*dx_unit + dy_unit*dy_unit)
            local angleDeg = math.deg(math_atan2(dy_unit, dx_unit))
            
            _G.FovCircleOverlay.PrecalcMath[i] = {
                c1 = c1, s1 = s1,
                dist_unit = dist_unit,
                angleDeg = angleDeg
            }
        end
    end

    pcall(function()
        local FVector2D = import("Vector2D") or _G.FVector2D
        for i = 1, numSegments do
            local mathData = _G.FovCircleOverlay.PrecalcMath[i]
            
            local x1 = targetRadius * mathData.c1
            local y1 = targetRadius * mathData.s1
            local dist = targetRadius * mathData.dist_unit

            local line = _G.FovCircleOverlay.Lines[i]
            if line and line.slot and slua.isValid(line.slot) then
                line.slot:SetPosition(FVector2D(centerX + x1, centerY + y1))
                line.slot:SetSize(FVector2D(dist + 0.8, _G.FovCircleOverlay.Thickness))
                line.widget:SetRenderAngle(mathData.angleDeg)
                line.widget:SetBrushColor(color)
            end
        end
    end)
end

function _G.CleanUpFovCircleOverlay()
    if _G.FovCircleOverlay and _G.FovCircleOverlay.Container and slua.isValid(_G.FovCircleOverlay.Container) then
        pcall(function() _G.FovCircleOverlay.Container:RemoveFromParent() end)
        pcall(function() _G.FovCircleOverlay.Container:ConditionalBeginDestroy() end)
    end
    if _G.FovCircleOverlay then
        _G.FovCircleOverlay.Container = nil
        _G.FovCircleOverlay.WidgetSlot = nil
        _G.FovCircleOverlay.LastRadius = -1
    end
end


-- ========================================== 
-- VÒNG LẶP CHÍNH 
-- ========================================== 
local function MainLoop()
    pcall(function()
        local SystemLib = import("KismetSystemLibrary")
        if SystemLib and not _G.FakeHWID_Hooked then
            _G.Original_GetDeviceId = SystemLib.GetDeviceId

            SystemLib.GetDeviceId = function(...)
                if _G.LexusConfig.FakeHWID then
                    if not _G.FakeHWID_String then
                        local chars = "0123456789abcdef"
                        local hwid = ""
                        for i = 1, 32 do 
                            hwid = hwid .. chars:sub(math.random(1, 16), math.random(1, 16)) 
                        end
                        _G.FakeHWID_String = hwid
                    end
                    return _G.FakeHWID_String
                end
                
                if _G.Original_GetDeviceId then return _G.Original_GetDeviceId(...) end
                return "UNKNOWN"
            end
            _G.FakeHWID_Hooked = true
        end
    end)

    _G.GetOriginalHWID = function()
        if _G.Original_GetDeviceId then
            return tostring(_G.Original_GetDeviceId())
        end
        local SystemLib = import("KismetSystemLibrary")
        if SystemLib and type(SystemLib.GetDeviceId) == "function" then
            return tostring(SystemLib.GetDeviceId())
        end
        return "UNKNOWN_DEVICE"
    end

    if _G.LexusState.CustomTextData == nil then 
        _G.LexusState.CustomTextData = {OuterSpeed = 10, InnerSpeed = 10, HRecoil = 0.3, VRecoil = 0.3, MagicHead = 1.0, MagicBody = 1.0, MagicLegs = 1.0, IpadViewFOV = 120, IpadViewVehicleFOV = 120, IpadViewScopeFOV = 100, AimTouchHipPrio = 1, AimTouchHipBone = 1, AimTouchHipCond = 1, AimTouchHipSpeed = 50, AimTouchHipFOV = 30, AimTouchHipDist = 250, AimTouchSGPrio = 1, AimTouchSGBone = 2, AimTouchSGCond = 1, AimTouchSGSpeed = 80, AimTouchSGFOV = 40, AimTouchSGDist = 30, AimTouchScopePrio = 1, AimTouchScopeBone = 2, AimTouchScopeCond = 1, AimTouchScopeSpeed = 40, AimTouchScopeFOV = 20, AimTouchScopeDist = 300, AimTouchSniperPrio = 1, AimTouchSniperBone = 1, AimTouchSniperCond = 2, AimTouchSniperSpeed = 30, AimTouchSniperFOV = 20, AimTouchSniperDist = 400, FastCarSpeed = 2000}
    end

    local okData, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData") 
    if not okData or not GameplayData then return end 
    local pc = GameplayData.GetPlayerController() 
    local localPlayer = nil
    if Valid(pc) then localPlayer = pc:GetPlayerCharacterSafety() end 

    if not Valid(localPlayer) then 
        if _G.LexusState.TrackedMarks then
            for markId, _ in pairs(_G.LexusState.TrackedMarks) do SafeRemoveMark(markId) end
        end
        
        _G.AppliedVehicleWall = {}
        _G.AppliedItemESP = {}
        _G.CachedItems = {}
        _G.CachedVehicles = {}
        _G.CachedActiveBombs = {}
        _G.CachedItemBombs = {}
        _G.AimTouchVisCache = {}
        _G.ActiveBombTimers = {}
        _G.BombCache = setmetatable({}, { __mode = "k" })
        _G.NonBombCache = setmetatable({}, { __mode = "k" })
        
        _G.LexusState.TrackedMarks = {} 
        for key, data in pairs(_G.LexusState.EnemyMarks) do
            if data and data.MIDs then
                for meshStr, midTable in pairs(data.MIDs) do
                    for k, _ in pairs(midTable) do midTable[k] = nil end
                end
            end
            if data and data.MIDs_V3 then
                for meshStr, midTable in pairs(data.MIDs_V3) do
                    for k, _ in pairs(midTable) do midTable[k] = nil end
                end
            end
        end
        
        _G.LexusState.EnemyMarks = {}
        _G.AK_OrigHitboxes = {}
        _G.AK_ModdedPhysAssets = {}
        _G.LexusState.PrevGraphicsState = {}
        
        if _G.CleanUpEnemyCounterWidget then _G.CleanUpEnemyCounterWidget() end
        if _G.CleanUpFovCircleOverlay then _G.CleanUpFovCircleOverlay() end
        return 
    end

    local Cached_PPM = nil
    pcall(function() Cached_PPM = import("PostProcessManager").GetInstance() end)
    local Cached_SecurityCommonUtils = nil
    pcall(function() Cached_SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils") end)
    local Cached_MyHUD = pc and pc.MyHUD or nil

    if _G.LexusConfig.UnlockFPS then InitializeGraphicsUnlock() end
    InitializeNativeESP()
    ShowLexusVIPMenu()
  
    if _G.LexusConfig.WallVehicle or _G.LexusConfig.EspItem_Master then
        _G.RunOptimizedItemAndVehicleESP(pc)
    end
    
    pcall(function()
        local isAiming = false
        if localPlayer.bIsWeaponAiming or localPlayer.bIsGunADS then isAiming = true end

        local currentVehicle = localPlayer.CurrentVehicle or (type(localPlayer.GetVehicle) == "function" and localPlayer:GetVehicle())
        local isInVehicle = Valid(currentVehicle) or localPlayer.bIsInVehicle
        local uTPPCam = localPlayer.ThirdPersonCameraComponent
        local uVehCam = localPlayer.VehicleCameraComponent
        local camMgr = pc.PlayerCameraManager

        if isAiming then
            if _G.LexusConfig.IpadViewScope and _G.LexusState.CustomTextData then
                local targetScope = _G.LexusState.CustomTextData.IpadViewScopeFOV or 60
                if type(pc.FOV) == "function" then pc:FOV(targetScope) end
                if Valid(camMgr) then
                    camMgr.DefaultFOV = targetScope
                    if type(camMgr.SetFOV) == "function" then camMgr:SetFOV(targetScope) end
                end
            else
                if type(pc.FOV) == "function" then pc:FOV(0) end
                if Valid(camMgr) and type(camMgr.UnlockFOV) == "function" then camMgr:UnlockFOV() end
            end
            return
        end

        if not isInVehicle or not _G.LexusConfig.IpadViewVehicle then
            if type(pc.FOV) == "function" then pc:FOV(0) end
            if Valid(camMgr) and type(camMgr.UnlockFOV) == "function" then camMgr:UnlockFOV() end
        end

        if not isInVehicle then
            if _G.LexusConfig.IpadView and _G.LexusState.CustomTextData then
                local targetTPP = _G.LexusState.CustomTextData.IpadViewFOV or 120
                if Valid(uTPPCam) and uTPPCam.FieldOfView ~= targetTPP then 
                    uTPPCam.FieldOfView = targetTPP 
                end
            else
                if Valid(uTPPCam) and uTPPCam.FieldOfView ~= 90 then 
                    uTPPCam.FieldOfView = 90 
                end
            end
        end

        if isInVehicle then
            if _G.LexusConfig.IpadViewVehicle and _G.LexusState.CustomTextData then
                local targetVeh = _G.LexusState.CustomTextData.IpadViewVehicleFOV or 120
                
                if Valid(uVehCam) and uVehCam.FieldOfView ~= targetVeh then 
                    uVehCam.FieldOfView = targetVeh 
                end
                
                if targetVeh > 90 then
                    if type(pc.FOV) == "function" then pc:FOV(targetVeh) end
                    if Valid(camMgr) then
                        camMgr.DefaultFOV = targetVeh
                        if type(camMgr.SetFOV) == "function" then camMgr:SetFOV(targetVeh) end
                    end
                end
            else
                if Valid(uVehCam) and uVehCam.FieldOfView ~= 90 then 
                    uVehCam.FieldOfView = 90 
                end
            end
        end
    end)

    pcall(function()
        local ui_util = require("client.common.ui_util")
        if ui_util then
            local vp = ui_util.GetViewportSize()
            if vp then
                _G.__AimTouch_ViewportX = vp.X
                _G.__AimTouch_CenterX = vp.X * 0.5
                _G.__AimTouch_CenterY = vp.Y * 0.5
            end
        end
        
        local wName = ""
        local weapon = localPlayer.WeaponManagerComponent and localPlayer.WeaponManagerComponent.CurrentWeaponReplicated
        if not weapon and type(localPlayer.GetCurrentShootWeapon) == "function" then
            weapon = localPlayer:GetCurrentShootWeapon()
        end
        if slua.isValid(weapon) then
            wName = type(weapon.GetWeaponName) == "function" and weapon:GetWeaponName() or ""
            local wID = type(weapon.GetWeaponID) == "function" and weapon:GetWeaponID() or 0
            if (wID >= 1030000 and wID < 1040000) or wName:find("S686") or wName:find("S1897") or wName:find("S12") or wName:find("DBS") or wName:find("M1014") then 
                _G.__AimTouch_WeaponType = "SHOTGUN"
            elseif wName:find("Kar98") or wName:find("M24") or wName:find("AWM") or wName:find("Mosin") or wName:find("Win94") or wName:find("AMR") or wName:find("SKS") or wName:find("SLR") or wName:find("Mini") or wName:find("Mk14") or wName:find("QBU") or wName:find("Mk12") or wName:find("VSS") then
                _G.__AimTouch_WeaponType = "SNIPER"
            elseif wName:lower():find("mortar") or wName:lower():find("cối") then
                _G.__AimTouch_WeaponType = "MORTAR"
            else
                _G.__AimTouch_WeaponType = "NORMAL"
            end
        end
    end)

    if _G.LexusConfig.AimTouchEnable then
        _G.AimTouch()
    end

    if _G.FovCircleOverlay then
        pcall(function() _G.FovCircleOverlay.Update(pc, localPlayer) end)
    end

    pcall(function()
        if _G.LexusConfig.CustomAimbot and localPlayer.bIsWeaponFiring and localPlayer.bIsGunADS then
            local outerRecoilVal = _G.LexusState.CustomTextData.OuterRecoil or 0
            if outerRecoilVal > 0 then
                local curTime = os.clock()
                
                if not _G.RecoilTargetCacheTime or (curTime - _G.RecoilTargetCacheTime) > 0.2 then
                    _G.RecoilTargetCacheTime = curTime
                    _G.HasRecoilTargetCached = false
                    
                    local ui_util = require("client.common.ui_util")
                    if ui_util then
                        local viewportSize = ui_util.GetViewportSize()
                        if viewportSize then
                            local centerX = viewportSize.X * 0.5
                            local centerY = viewportSize.Y * 0.5
                            local FOV_RADIUS = (6 / 100.0) * (viewportSize.X / 2.0) 
                            
                            local enemies = _G.GetEnemyTargetsFromActors(40000) 
                            if enemies and #enemies > 0 then
                                local FVector2D = import("Vector2D")
                                for _, target in ipairs(enemies) do
                                    if slua.isValid(target) and target.HealthStatus ~= 1 then 
                                        local tPos = type(target.K2_GetActorLocation) == "function" and target:K2_GetActorLocation() or nil
                                        if tPos then
                                            local screen = FVector2D()
                                            if pc:ProjectWorldLocationToScreen(tPos, screen, false) and screen.X > 0 and screen.Y > 0 then
                                                local dx = screen.X - centerX
                                                local dy = screen.Y - centerY
                                                if math.sqrt(dx*dx + dy*dy) <= FOV_RADIUS then
                                                    _G.HasRecoilTargetCached = true
                                                    break 
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                if _G.HasRecoilTargetCached then
                    local currentRot = pc:GetControlRotation()
                    if currentRot then
                        local pullDownForce = (outerRecoilVal / 50.0) * 1.5
                        currentRot.Pitch = currentRot.Pitch - pullDownForce
                        pc:SetControlRotation(currentRot, "CustomAimbotRecoil")
                    end
                end
            end
        else
            _G.HasRecoilTargetCached = false
        end
    end)

    pcall(function()
        if Valid(pc) then
            if pc.HiggsBoson then pc.HiggsBoson.bMHActive = false; pc.HiggsBoson.bCallPreReplication = false end
            if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive = false; pc.HiggsBosonComponent.bCallPreReplication = false end
        end
    end)

    pcall(function()
        local autoComp = localPlayer.AutoAimComp
        if Valid(autoComp) then
            if not _G.LexusState.OrigAutoAimCompCached then
                _G.LexusState.OrigAutoAimCompCached = {
                    bOnlyHitHead = autoComp.bOnlyHitHead,
                    HeadBoneName = autoComp.HeadBoneName,
                    Bones = autoComp.Bones,
                    ChestBoneName = autoComp.ChestBoneName,
                    PelvisBoneName = autoComp.PelvisBoneName,
                    HeadPriority = autoComp.AimAssistConfig and autoComp.AimAssistConfig.HeadPriority,
                    ChestPriority = autoComp.AimAssistConfig and autoComp.AimAssistConfig.ChestPriority,
                    PelvisPriority = autoComp.AimAssistConfig and autoComp.AimAssistConfig.PelvisPriority
                }
            end
            
            if _G.LexusConfig.AutoHead then
                autoComp.bOnlyHitHead = true
                autoComp.HeadBoneName = "Head"
                pcall(function() autoComp.Bones = {"Head"} end)
                autoComp.ChestBoneName = "Head"
                autoComp.PelvisBoneName = "Head"
                if autoComp.AimAssistConfig then
                    autoComp.AimAssistConfig.HeadPriority = 100
                    autoComp.AimAssistConfig.ChestPriority = 100
                    autoComp.AimAssistConfig.PelvisPriority = 100
                end
            else
                local orig = _G.LexusState.OrigAutoAimCompCached
                autoComp.bOnlyHitHead = orig.bOnlyHitHead
                autoComp.HeadBoneName = orig.HeadBoneName
                pcall(function() autoComp.Bones = orig.Bones or {"Spine_01", "Pelvis", "Head"} end)
                autoComp.ChestBoneName = orig.ChestBoneName
                autoComp.PelvisBoneName = orig.PelvisBoneName
                if autoComp.AimAssistConfig then
                    autoComp.AimAssistConfig.HeadPriority = orig.HeadPriority or 1
                    autoComp.AimAssistConfig.ChestPriority = orig.ChestPriority or 1
                    autoComp.AimAssistConfig.PelvisPriority = orig.PelvisPriority or 1
                end
            end
        end
    end)

    if _G.LexusConfig.WallClimb then
        pcall(function()
            local charMove = localPlayer.CharacterMovement
            if Valid(charMove) then
                if not _G.LexusState.WallClimbOriginals then
                    _G.LexusState.WallClimbOriginals = { WalkableFloorAngle = charMove.WalkableFloorAngle, MaxStepHeight = charMove.MaxStepHeight }
                end
                charMove.WalkableFloorAngle = 199.0
                charMove.MaxStepHeight = 999.0
                _G.LexusState.WallClimbApplied = true
            end
        end)
    elseif _G.LexusState.WallClimbApplied then
        pcall(function()
            local charMove = localPlayer.CharacterMovement
            if Valid(charMove) and _G.LexusState.WallClimbOriginals then
                charMove.WalkableFloorAngle = _G.LexusState.WallClimbOriginals.WalkableFloorAngle or 50.0
                charMove.MaxStepHeight = _G.LexusState.WallClimbOriginals.MaxStepHeight or 45.0
            end
        end)
        _G.LexusState.WallClimbApplied = false
    end

    if _G.LexusConfig.FastCar then
        pcall(function()
            local currentVehicle = localPlayer.CurrentVehicle or (type(localPlayer.GetVehicle) == "function" and localPlayer:GetVehicle())
            if Valid(currentVehicle) then
                local rootComp = currentVehicle.RootComponent or (type(currentVehicle.K2_GetRootComponent) == "function" and currentVehicle:K2_GetRootComponent())
                
                if Valid(rootComp) and type(rootComp.SetAllPhysicsLinearVelocity) == "function" then
                    local isAccelerating = false
                    local moveComp = currentVehicle.VehicleMovement or currentVehicle.MovementComponent
                    if Valid(moveComp) then
                        local throttle = moveComp.ThrottleInput or 0
                        if type(moveComp.GetThrottleInput) == "function" then
                            throttle = moveComp:GetThrottleInput()
                        end
                        if throttle > 0.05 or throttle < -0.05 then 
                            isAccelerating = true
                        end
                    end
                    if currentVehicle.bIsPressingGas or (currentVehicle.Throttle and currentVehicle.Throttle ~= 0) then
                        isAccelerating = true
                    end

                    local currentVel = nil
                    if type(currentVehicle.GetVelocity) == "function" then
                        currentVel = currentVehicle:GetVelocity()
                    elseif type(rootComp.GetPhysicsLinearVelocity) == "function" then
                        currentVel = rootComp:GetPhysicsLinearVelocity()
                    elseif rootComp.ComponentVelocity then
                        currentVel = rootComp.ComponentVelocity
                    end

                    if currentVel then
                        local currentSpeed = math.sqrt(currentVel.X^2 + currentVel.Y^2)
                        local minSpeedToBoost = 50.0   
                        local maxSpeed = _G.LexusState.CustomTextData.FastCarSpeed or 3000.0        
                        local accelFactor = 1.5
                        local brakeFactor = 0.85       
                        
                        if currentSpeed > minSpeedToBoost then
                            local dirX = currentVel.X / currentSpeed
                            local dirY = currentVel.Y / currentSpeed
                            
                            if isAccelerating then
                                local targetSpeed = currentSpeed * accelFactor
                                if targetSpeed > maxSpeed then targetSpeed = maxSpeed end
                                local newX = dirX * targetSpeed
                                local newY = dirY * targetSpeed
                                local newZ = currentVel.Z 
                                rootComp:SetAllPhysicsLinearVelocity(FVector(newX, newY, newZ), false)
                            else
                                local targetSpeed = currentSpeed * brakeFactor
                                if targetSpeed > minSpeedToBoost then
                                    local newX = dirX * targetSpeed
                                    local newY = dirY * targetSpeed
                                    local newZ = currentVel.Z 
                                    rootComp:SetAllPhysicsLinearVelocity(FVector(newX, newY, newZ), false)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    local now = os.clock()
    pcall(function()
        local lsg = require("client.slua.logic.setting.logic_setting_graphics")
        local gi = lsg.GetGameInstance()
        if gi then
            if _G.LexusConfig.RemoveGrass and not _G.LexusState.PrevGraphicsState.RemoveGrass then
                gi:ExecuteCMD("grass.DensityScale", "0")
                gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
                _G.LexusState.PrevGraphicsState.RemoveGrass = true
            elseif not _G.LexusConfig.RemoveGrass and _G.LexusState.PrevGraphicsState.RemoveGrass then
                gi:ExecuteCMD("grass.DensityScale", "1")
                gi:ExecuteCMD("grass.DiscardDataOnLoad", "0")
                _G.LexusState.PrevGraphicsState.RemoveGrass = false
            end

            if _G.LexusConfig.RemoveTrees and not _G.LexusState.PrevGraphicsState.RemoveTrees then
                gi:ExecuteCMD("foliage.DensityScale", "0")
                gi:ExecuteCMD("r.Foliage.DensityScale", "0")
                gi:ExecuteCMD("foliage.MinimumScreenSize", "10000")
                gi:ExecuteCMD("r.DisableTreeRender", "1")
                _G.LexusState.PrevGraphicsState.RemoveTrees = true
            elseif not _G.LexusConfig.RemoveTrees and _G.LexusState.PrevGraphicsState.RemoveTrees then
                gi:ExecuteCMD("foliage.DensityScale", "1")
                gi:ExecuteCMD("r.Foliage.DensityScale", "1")
                gi:ExecuteCMD("foliage.MinimumScreenSize", "0.0001")
                gi:ExecuteCMD("r.DisableTreeRender", "0")
                _G.LexusState.PrevGraphicsState.RemoveTrees = false
            end
            
            if _G.LexusConfig.RemoveFog and not _G.LexusState.PrevGraphicsState.RemoveFog then
                gi:ExecuteCMD("r.SkyAtmosphere", "1") 
                gi:ExecuteCMD("r.Fog", "0")           
                gi:ExecuteCMD("r.VolumetricFog", "0") 
                _G.LexusState.PrevGraphicsState.RemoveFog = true
            elseif not _G.LexusConfig.RemoveFog and _G.LexusState.PrevGraphicsState.RemoveFog then
                gi:ExecuteCMD("r.SkyAtmosphere", "1") 
                gi:ExecuteCMD("r.Fog", "1")           
                gi:ExecuteCMD("r.VolumetricFog", "1") 
                _G.LexusState.PrevGraphicsState.RemoveFog = false
            end
            
            if _G.LexusConfig.WhiteBody and not _G.LexusState.PrevGraphicsState.WhiteBody then
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "2")
                gi:ExecuteCMD("r.CharacterDiffusePower", "5")
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "100")
                _G.LexusState.PrevGraphicsState.WhiteBody = true
            elseif not _G.LexusConfig.WhiteBody and _G.LexusState.PrevGraphicsState.WhiteBody then
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "0")
                gi:ExecuteCMD("r.CharacterDiffusePower", "1")
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "1")
                _G.LexusState.PrevGraphicsState.WhiteBody = false
            end
            
            if _G.LexusConfig.ColorBodyV2 and not _G.LexusState.PrevGraphicsState.ColorBodyV2 then
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "4")
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "200")
                gi:ExecuteCMD("r.CharacterDiffusePower", "200")
                _G.LexusState.PrevGraphicsState.ColorBodyV2 = true
            elseif not _G.LexusConfig.ColorBodyV2 and _G.LexusState.PrevGraphicsState.ColorBodyV2 then
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "1")
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "0")
                gi:ExecuteCMD("r.CharacterDiffusePower", "1")
                _G.LexusState.PrevGraphicsState.ColorBodyV2 = false
            end
            
            if _G.LexusConfig.BlackSky and not _G.LexusState.PrevGraphicsState.BlackSky then
                gi:ExecuteCMD("r.CylinderMaxDrawHeight", "9999")
                _G.LexusState.PrevGraphicsState.BlackSky = true
            elseif not _G.LexusConfig.BlackSky and _G.LexusState.PrevGraphicsState.BlackSky then
                gi:ExecuteCMD("r.CylinderMaxDrawHeight", "0000")
                _G.LexusState.PrevGraphicsState.BlackSky = false
            end
        end
    end)

    pcall(function()
        local weapon = nil
        pcall(function()
            local weaponManager = localPlayer.WeaponManagerComponent
            if Valid(weaponManager) and type(weaponManager.GetCurrentWeapon) == "function" then
                weapon = weaponManager:GetCurrentWeapon()
            end
        end)
        if not Valid(weapon) then
            if type(localPlayer.GetCurrentShootWeapon) == "function" then weapon = localPlayer:GetCurrentShootWeapon()
            elseif type(localPlayer.GetCurrentWeapon) == "function" then weapon = localPlayer:GetCurrentWeapon() end
        end

        if Valid(weapon) then
            local entities = {}
            if Valid(weapon.ShootWeaponEntity_GEN_VARIABLE) then table.insert(entities, weapon.ShootWeaponEntity_GEN_VARIABLE) end
            if Valid(weapon.ShootWeaponEntity) then table.insert(entities, weapon.ShootWeaponEntity) end
            if Valid(weapon.ShootWeaponComponent) and Valid(weapon.ShootWeaponComponent.ShootWeaponEntityComponent) then 
                table.insert(entities, weapon.ShootWeaponComponent.ShootWeaponEntityComponent) 
            end

            for _, entity in ipairs(entities) do
                local anyWeaponModOn = _G.LexusConfig.CustomHRecoil or _G.LexusConfig.CustomVRecoil or _G.LexusConfig.LessShake or _G.LexusConfig.Accuracy or _G.LexusConfig.Crosshair or _G.LexusConfig.GodMode or _G.LexusConfig.AutoHead or _G.LexusConfig.CustomAimbot or _G.LexusConfig.CustomAimbotClose

                if anyWeaponModOn then
                    if not entity.OriginalStatsCached then
                        entity.OriginalStatsCached = {
                            GameDeviationFactor = entity.GameDeviationFactor,
                            GameDeviationAccuracy = entity.GameDeviationAccuracy,
                            BulletFireSpeed = entity.BulletFireSpeed,
                            ShootInterval = entity.ShootInterval,
                            BaseDamage = entity.BaseDamage,
                            AccessoriesHRecoilFactor = entity.AccessoriesHRecoilFactor,
                            AccessoriesVRecoilFactor = entity.AccessoriesVRecoilFactor,
                            RecoilKick = entity.RecoilKick,
                            RecoilKickADS = entity.RecoilKickADS,
                            AnimationKick = entity.AnimationKick
                        }
                    end
                    
                    if _G.LexusConfig.CustomHRecoil then entity.AccessoriesHRecoilFactor = _G.LexusState.CustomTextData.HRecoil or 0.3 end
                    if _G.LexusConfig.CustomVRecoil then entity.AccessoriesVRecoilFactor = _G.LexusState.CustomTextData.VRecoil or 0.3 end
                    if _G.LexusConfig.LessShake then entity.RecoilKick = 0.0; entity.RecoilKickADS = 0.0; entity.AnimationKick = 0.0 end
                    if _G.LexusConfig.Accuracy then entity.GameDeviationAccuracy = 0.0 end
                    if _G.LexusConfig.Crosshair then entity.GameDeviationFactor = 0.0 end
                    if _G.LexusConfig.GodMode then entity.BulletFireSpeed = 500000.0; entity.ShootInterval = 0.001; entity.BaseDamage = 60000.0 end
                    
                    if entity.AutoAimingConfig then
                        if not entity.OriginalAutoAimCached then
                            entity.OriginalAutoAimCached = {
                                OuterSpeed = entity.AutoAimingConfig.OuterRange and entity.AutoAimingConfig.OuterRange.Speed,
                                InnerSpeed = entity.AutoAimingConfig.InnerRange and entity.AutoAimingConfig.InnerRange.Speed
                            }
                        end
                        
                        if _G.LexusConfig.AutoHead then
                            pcall(function() entity.AutoAimingConfig.Bones = { "Head", "Head", "Head" } end)
                        end
                        
                        if _G.LexusConfig.CustomAimbot then
                            local speed = _G.LexusState.CustomTextData.OuterSpeed or 10
                            if entity.AutoAimingConfig.OuterRange then
                                entity.AutoAimingConfig.OuterRange.Speed = speed
                                entity.AutoAimingConfig.OuterRange.RangeRate = 4.5
                                entity.AutoAimingConfig.OuterRange.SpeedRate = 1.3
                                entity.AutoAimingConfig.OuterRange.RangeRateSight = 1.8
                                entity.AutoAimingConfig.OuterRange.SpeedRateSight = 2.2
                                entity.AutoAimingConfig.OuterRange.CrouchRate = 1.1
                                entity.AutoAimingConfig.OuterRange.ProneRate = 1.0
                                entity.AutoAimingConfig.OuterRange.DyingRate = 0.0
                            end
                            if entity.AutoAimingConfig.InnerRange then
                                entity.AutoAimingConfig.InnerRange.Speed = speed
                                entity.AutoAimingConfig.InnerRange.RangeRate = 4.5
                                entity.AutoAimingConfig.InnerRange.SpeedRate = 1.3
                                entity.AutoAimingConfig.InnerRange.RangeRateSight = 1.8
                                entity.AutoAimingConfig.InnerRange.SpeedRateSight = 2.2
                                entity.AutoAimingConfig.InnerRange.CrouchRate = 1.1
                                entity.AutoAimingConfig.InnerRange.ProneRate = 1.0
                                entity.AutoAimingConfig.InnerRange.DyingRate = 0.0
                            end
                        elseif _G.LexusConfig.CustomAimbotClose then
                            local speed = _G.LexusState.CustomTextData.InnerSpeed or 10
                            if entity.AutoAimingConfig.OuterRange then
                                entity.AutoAimingConfig.OuterRange.Speed = speed
                                entity.AutoAimingConfig.OuterRange.DyingRate = 0.0
                            end
                            if entity.AutoAimingConfig.InnerRange then
                                entity.AutoAimingConfig.InnerRange.Speed = speed
                                entity.AutoAimingConfig.InnerRange.DyingRate = 0.0
                            end
                        end
                    end
                    
                    entity.LexusWeaponModsActive = true

                elseif entity.LexusWeaponModsActive then
                    if entity.OriginalStatsCached then
                        local orig = entity.OriginalStatsCached
                        entity.GameDeviationFactor = orig.GameDeviationFactor
                        entity.GameDeviationAccuracy = orig.GameDeviationAccuracy
                        entity.BulletFireSpeed = orig.BulletFireSpeed
                        entity.ShootInterval = orig.ShootInterval
                        entity.BaseDamage = orig.BaseDamage
                        entity.AccessoriesHRecoilFactor = orig.AccessoriesHRecoilFactor
                        entity.AccessoriesVRecoilFactor = orig.AccessoriesVRecoilFactor
                        entity.RecoilKick = orig.RecoilKick
                        entity.RecoilKickADS = orig.RecoilKickADS
                        entity.AnimationKick = orig.AnimationKick
                    end
                    if entity.AutoAimingConfig and entity.OriginalAutoAimCached then
                        pcall(function() entity.AutoAimingConfig.Bones = { "Spine_01", "Pelvis", "Head" } end)
                        if entity.AutoAimingConfig.OuterRange and entity.OriginalAutoAimCached.OuterSpeed then
                            entity.AutoAimingConfig.OuterRange.Speed = entity.OriginalAutoAimCached.OuterSpeed
                        end
                        if entity.AutoAimingConfig.InnerRange and entity.OriginalAutoAimCached.InnerSpeed then
                            entity.AutoAimingConfig.InnerRange.Speed = entity.OriginalAutoAimCached.InnerSpeed
                        end
                    end
                    entity.LexusWeaponModsActive = false
                end
            end
        end
    end)

    local mHead_Global, mBody_Global, mLegs_Global = 1.0, 1.0, 1.0
    local runInject_Global = false
    
    pcall(function()
        if _G.LexusConfig.CustomMagicBullet then
            runInject_Global = true
            mHead_Global = 1.0; mBody_Global = 1.0; mLegs_Global = 1.0
            if _G.LexusState.CustomTextData then
                local cData = _G.LexusState.CustomTextData
                if cData.MagicHead ~= nil then mHead_Global = tonumber(cData.MagicHead) or mHead_Global end
                if cData.MagicBody ~= nil then mBody_Global = tonumber(cData.MagicBody) or mBody_Global end
                if cData.MagicLegs ~= nil then mLegs_Global = tonumber(cData.MagicLegs) or mLegs_Global end
            end
        elseif _G.LexusConfig.MagicBullet then
            runInject_Global = true
            mHead_Global = 1.05; mBody_Global = 1.0; mLegs_Global = 1.0
        end

        if runInject_Global then
            local currentMagicHash = "M_"..tostring(mHead_Global).."_"..tostring(mBody_Global).."_"..tostring(mLegs_Global)
            if _G.LexusState.LastMagicConfigHash ~= currentMagicHash then
                _G.LexusState.MagicUpdateVersion = (_G.LexusState.MagicUpdateVersion or 0) + 1
                _G.LexusState.LastMagicConfigHash = currentMagicHash
            end
        else
            if _G.LexusState.LastMagicConfigHash ~= "OFF" then
                _G.LexusState.MagicUpdateVersion = (_G.LexusState.MagicUpdateVersion or 0) + 1
                _G.LexusState.LastMagicConfigHash = "OFF"
            end
        end
    end)

    pcall(function()
        local allCharacters = {}
        if GameplayData.GetAllPlayerCharacters then allCharacters = GameplayData.GetAllPlayerCharacters()
        elseif GameplayData.GameCharacters then for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end end
        
        local currentValidKeys = {}
        for _, enemy in pairs(allCharacters) do
            if Valid(enemy) and enemy ~= localPlayer then
                currentValidKeys[GetSafeEnemyKey(enemy)] = true
            end
        end
        
        for key, data in pairs(_G.LexusState.EnemyMarks) do
            if not currentValidKeys[key] then
                SafeRemoveMark(data.radarMark)
                SafeRemoveMark(data.hpMark)
                SafeRemoveMark(data.distMark)
                
                if _G.AimTouchVisCache and _G.AimTouchVisCache[key] then
                    _G.AimTouchVisCache[key] = nil
                end
                
                if data.MIDs then
                    for meshStr, midTable in pairs(data.MIDs) do
                        for k, _ in pairs(midTable) do
                            midTable[k] = nil
                        end
                    end
                    data.MIDs = nil
                end
                if data.MIDs_V3 then
                    for meshStr, midTable in pairs(data.MIDs_V3) do
                        for k, _ in pairs(midTable) do
                            midTable[k] = nil
                        end
                    end
                    data.MIDs_V3 = nil
                end
                
                data.enemy = nil
                data.CachedMeshes = nil
                _G.LexusState.EnemyMarks[key] = nil
            end
        end

        local realCount = 0
        local aiCount = 0

        local function GetFirstElemSafe(elemArray)
            if elemArray and type(elemArray.Num) == "function" and elemArray:Num() > 0 then
                if type(elemArray.Get) == "function" then return elemArray:Get(0) end
            elseif elemArray and type(elemArray) == "table" and #elemArray > 0 then
                return elemArray[1]
            end
            return nil
        end

        local BoneScaleMap = {
            ["head"] = mHead_Global, ["neck_01"] = mHead_Global,
            ["pelvis"] = mBody_Global, ["spine_01"] = mBody_Global, ["spine_02"] = mBody_Global, ["spine_03"] = mBody_Global,
            ["thigh_l"] = mLegs_Global, ["thigh_r"] = mLegs_Global, 
            ["calf_l"] = mLegs_Global, ["calf_r"] = mLegs_Global,   
            ["foot_l"] = mLegs_Global, ["foot_r"] = mLegs_Global    
        }
        
        local mLoc = nil
        pcall(function() if type(localPlayer.K2_GetActorLocation) == "function" then mLoc = localPlayer:K2_GetActorLocation() end end)

        for _, enemy in pairs(allCharacters) do
            if Valid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
                local bIsReallyDead = false
                pcall(function()
                    if type(enemy.IsDead) == "function" then bIsReallyDead = enemy:IsDead()
                    elseif enemy.bIsDead ~= nil then bIsReallyDead = enemy.bIsDead
                    elseif enemy.bIsDeadFlag ~= nil then bIsReallyDead = enemy.bIsDeadFlag end
                    if enemy.HealthStatus ~= nil and enemy.HealthStatus == 2 then bIsReallyDead = true end
                end)

                local eKey = GetSafeEnemyKey(enemy)
                _G.LexusState.EnemyMarks[eKey] = _G.LexusState.EnemyMarks[eKey] or { enemy = enemy }
                local markData = _G.LexusState.EnemyMarks[eKey]
                markData.enemy = enemy 

                if not bIsReallyDead then
                    if markData.lastEnemyActor ~= enemy then
                        if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
                        if markData.hpMark8 then SafeRemoveMark(markData.hpMark8); markData.hpMark8 = nil end
                        if markData.distMark then SafeRemoveMark(markData.distMark); markData.distMark = nil end
                        if markData.radarMark then SafeRemoveMark(markData.radarMark); markData.radarMark = nil end
                        
                        markData.lastEnemyActor = enemy
                        markData.LastUIComp = nil
                        markData.LastFrameUIState = nil
                    end
                    
                    local eMesh = nil
                    pcall(function() eMesh = enemy.Mesh or (type(enemy.getAvatarComponent2) == "function" and enemy:getAvatarComponent2() or nil) end)
                    local aLoc = nil
                    pcall(function() if type(enemy.K2_GetActorLocation) == "function" then aLoc = enemy:K2_GetActorLocation() end end)
                    
                    local isBotResult, isStateLoaded = CheckIsAI(enemy, markData)
                    local isBot = markData.AK_IS_BOT or false

                    local currentMeshCount = 0
                    if Valid(eMesh) then
                        local tempMeshes = GetAllSkeletalMeshes(enemy, markData)
                        currentMeshCount = #tempMeshes
                    end
                    local isMeshChanged = (markData.LastMeshCountWall ~= currentMeshCount)

                    if _G.LexusConfig.WallXuyenTuong then
                        if isMeshChanged or not markData.WallhackApplied then
                            ApplyWallXuyenTuong(enemy, markData)
                            markData.WallhackApplied = true
                            markData.LastMeshCountWall = currentMeshCount
                        end
                    else
                        UndoWallXuyenTuong(enemy, markData)
                    end

                    if _G.LexusConfig.ColorBodyV2 then 
                        ApplyColorBodyV2(enemy, pc, markData) 
                    else
                        UndoColorBodyV2(enemy, markData)
                    end
                    
                    if _G.LexusConfig.ColorBodyV3 then 
                        ApplyColorBodyV3(enemy, markData)
                    else
                        UndoColorBodyV3(enemy, markData)
                    end
                    if _G.LexusConfig.ColorBodyNew then 
                        ApplyColorBodyNew(enemy, markData)
                    else
                        UndoColorBodyNew(enemy, markData)
                    end

                    pcall(function()
                        if Valid(eMesh) then
                            local targetScale = 1.0
                            if _G.LexusConfig.BugManEnable and _G.LexusState.CustomTextData then
                                targetScale = 177.0 / (_G.LexusState.CustomTextData.BugManRatio or 133)
                                if targetScale < 1.0 then targetScale = 1.0 end
                                if targetScale > 2.0 then targetScale = 2.0 end
                            end
                            
                            if markData.LastFatScale ~= targetScale then
                                eMesh:SetRelativeScale3D(FVector(targetScale, targetScale, 1.0))
                                markData.LastFatScale = targetScale
                            end
                        end
                    end)

                    pcall(function()
                        local EnemyMesh = eMesh
                        if slua.isValid(EnemyMesh) then
                            local uniqueID = type(enemy.GetUniqueID) == "function" and enemy:GetUniqueID() or tostring(enemy.PlayerKey or enemy)
                            
                            if markData.MagicBulletHash == _G.LexusState.LastMagicConfigHash and markData.MagicTargetID == uniqueID then
                                return 
                            end

                            local PhysicsAsset = EnemyMesh.PhysicsAssetOverride
                            if not slua.isValid(PhysicsAsset) and EnemyMesh.SkeletalMesh then PhysicsAsset = EnemyMesh.SkeletalMesh.PhysicsAsset end

                            if slua.isValid(PhysicsAsset) and PhysicsAsset.SkeletalBodySetups then
                                if not _G.AK_ModdedPhysAssets then _G.AK_ModdedPhysAssets = {} end
                                local PhysAssetName = "DefaultPhys"
                                pcall(function() PhysAssetName = PhysicsAsset:GetName() end)
                                
                                if _G.AK_ModdedPhysAssets[PhysAssetName] ~= _G.LexusState.LastMagicConfigHash then
                                    
                                    if not _G.AK_OrigHitboxes then _G.AK_OrigHitboxes = {} end
                                    if not _G.AK_OrigHitboxes[PhysAssetName] then _G.AK_OrigHitboxes[PhysAssetName] = {} end
                                    local OrigHitboxData = _G.AK_OrigHitboxes[PhysAssetName]

                                    local SkeletalBodySetups = PhysicsAsset.SkeletalBodySetups
                                    local numSetups = type(SkeletalBodySetups.Num) == "function" and SkeletalBodySetups:Num() or #SkeletalBodySetups
                                    local limit = numSetups > 50 and 50 or numSetups

                                    for i = 1, limit do 
                                        local BodySetup = type(SkeletalBodySetups.Get) == "function" and SkeletalBodySetups:Get(i-1) or SkeletalBodySetups[i]
                                        if slua.isValid(BodySetup) then
                                            local LowerBoneName = string.lower(tostring(BodySetup.BoneName))
                                            local MatchedBoneKey = nil
                                            for k, _ in pairs(BoneScaleMap) do
                                                if string.find(LowerBoneName, k, 1, true) then MatchedBoneKey = k break end
                                            end

                                            if MatchedBoneKey then
                                                local TargetScale = 1.0 
                                                if runInject_Global then TargetScale = BoneScaleMap[MatchedBoneKey] end
                                                
                                                local AggGeom = BodySetup.AggGeom
                                                
                                                local BoxElems = AggGeom and AggGeom.BoxElems or BodySetup.BoxElems
                                                local SphereElems = AggGeom and AggGeom.SphereElems or BodySetup.SphereElems
                                                local SphylElems = AggGeom and AggGeom.SphylElems or BodySetup.SphylElems

                                                local BoxElem = GetFirstElemSafe(BoxElems)
                                                local SphereElem = GetFirstElemSafe(SphereElems)
                                                local SphylElem = GetFirstElemSafe(SphylElems)

                                                if not OrigHitboxData[MatchedBoneKey] then
                                                    OrigHitboxData[MatchedBoneKey] = { Box = nil, Sphere = nil, Sphyl = nil }
                                                    if BoxElem then OrigHitboxData[MatchedBoneKey].Box = { X = BoxElem.X, Y = BoxElem.Y, Z = BoxElem.Z } end
                                                    if SphereElem then OrigHitboxData[MatchedBoneKey].Sphere = { Radius = SphereElem.Radius } end
                                                    if SphylElem then OrigHitboxData[MatchedBoneKey].Sphyl = { Radius = SphylElem.Radius, Length = SphylElem.Length } end
                                                end

                                                local OrigElemData = OrigHitboxData[MatchedBoneKey]

                                                if OrigElemData.Box and BoxElem then
                                                    BoxElem.X = OrigElemData.Box.X * TargetScale
                                                    BoxElem.Y = OrigElemData.Box.Y * TargetScale
                                                    BoxElem.Z = OrigElemData.Box.Z * TargetScale
                                                    if type(BoxElems.Set) == "function" then BoxElems:Set(0, BoxElem) else BoxElems[1] = BoxElem end
                                                    if AggGeom then AggGeom.BoxElems = BoxElems; BodySetup.AggGeom = AggGeom else BodySetup.BoxElems = BoxElems end
                                                end

                                                if OrigElemData.Sphere and SphereElem then
                                                    SphereElem.Radius = OrigElemData.Sphere.Radius * TargetScale
                                                    if type(SphereElems.Set) == "function" then SphereElems:Set(0, SphereElem) else SphereElems[1] = SphereElem end
                                                    if AggGeom then AggGeom.SphereElems = SphereElems; BodySetup.AggGeom = AggGeom else BodySetup.SphereElems = SphereElems end
                                                end

                                                if OrigElemData.Sphyl and SphylElem then
                                                    SphylElem.Radius = OrigElemData.Sphyl.Radius * TargetScale
                                                    SphylElem.Length = OrigElemData.Sphyl.Length * TargetScale
                                                    if type(SphylElems.Set) == "function" then SphylElems:Set(0, SphylElem) else SphylElems[1] = SphylElem end
                                                    if AggGeom then AggGeom.SphylElems = SphylElems; BodySetup.AggGeom = AggGeom else BodySetup.SphylElems = SphylElems end
                                                end
                                            end
                                        end
                                    end
                                    _G.AK_ModdedPhysAssets[PhysAssetName] = _G.LexusState.LastMagicConfigHash
                                end
                                
                                if EnemyMesh.SetPhysicsAsset then EnemyMesh:SetPhysicsAsset(PhysicsAsset) end
                                EnemyMesh.PhysicsAssetOverride = PhysicsAsset
                                
                                markData.MagicBulletHash = _G.LexusState.LastMagicConfigHash
                                markData.MagicTargetID = uniqueID
                            end
                        end
                    end)

                    local distM = 0
                    pcall(function() distM = localPlayer:GetDistanceTo(enemy) / 100 end)

                    local currentHp, maxHp = 100, 100
                    local showFrameUI = _G.LexusConfig.EspLoai5 or _G.LexusConfig.EspVipPro or _G.LexusConfig.EspVip
                    
                    if showFrameUI then
                        pcall(function()
                            if enemy.Health then currentHp = enemy.Health elseif type(enemy.GetHealth) == "function" then currentHp = enemy:GetHealth() end
                            if enemy.HealthMax then maxHp = enemy.HealthMax elseif type(enemy.GetHealthMax) == "function" then maxHp = enemy:GetHealthMax() end
                        end)
                        if maxHp <= 0 then maxHp = 100 end
                    end
                    local hpRatio = currentHp / maxHp

                    if _G.LexusConfig.EspAntenna then
                        pcall(function()
                            local MyHUD = Cached_MyHUD
                            if Valid(MyHUD) and distM <= 400 then
                                local loopCount = 8  
                                local zStep = 1000     
                                local baseZ = 105     
                                local topZ = baseZ + (loopCount * zStep)
                                for i = 1, loopCount do
                                    local zOffset = baseZ + (i * zStep)
                                    MyHUD:AddDebugText("|", enemy, 0.06,
                                        {X=0, Y=0, Z=zOffset}, {X=0, Y=0, Z=zOffset},
                                        C_GREEN, true, false, true, nil, 1.2, true)
                                end
                                MyHUD:AddDebugText("I", enemy, 0.06,
                                        {X=0, Y=0, Z=topZ + 60}, {X=0, Y=0, Z=topZ + 60},
                                        C_GREEN, true, false, true, nil, 1.5, true)
                            end
                        end)
                    end

                    if _G.LexusConfig.EspLoai6 then
                        pcall(function()
                            local curTime = os.clock()
                            if markData.LastEsp6Time == nil or (curTime - markData.LastEsp6Time) >= 0.05 then
                                markData.LastEsp6Time = curTime
                                
                                local MyHUD = Cached_MyHUD
                                if Valid(MyHUD) and Valid(eMesh) and aLoc then
                                    if distM <= 250 then
                                        if type(eMesh.GetSocketLocation) == "function" then
                                            for _, bName in ipairs(GLOBAL_BONE_LIST) do
                                                if distM > 50 and (bName ~= "head" and bName ~= "pelvis" and bName ~= "neck_01") then
                                                else
                                                    local wLoc = eMesh:GetSocketLocation(bName)
                                                    if wLoc then
                                                        local offset = {X = wLoc.X - aLoc.X, Y = wLoc.Y - aLoc.Y, Z = wLoc.Z - aLoc.Z}
                                                        
                                                        local mark = "▪"
                                                        local fixedSize = 0.25 
                                                        local color = C_CYAN
                                                        
                                                        if bName == "head" then 
                                                            mark = "●"
                                                            fixedSize = 0.45
                                                            color = C_RED
                                                        elseif bName == "pelvis" or bName == "neck_01" then 
                                                            mark = "▪"
                                                            fixedSize = 0.35
                                                            color = C_YELLOW 
                                                        end
                                                        
                                                        MyHUD:AddDebugText(mark, enemy, 0.06, offset, offset, color, true, false, true, nil, fixedSize, true)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                    end

                    if _G.LexusConfig.EspLoai7 then
                        pcall(function()
                            local MyHUD = Cached_MyHUD
                            if Valid(MyHUD) then
                                if distM <= 600 then if isBot then aiCount = aiCount + 1 else realCount = realCount + 1 end end
                                
                                if distM <= 400 then
                                    local stateText = ""
                                    
                                    if _G.LexusConfig.Esp7_TuThe then
                                        local pose = nil
                                        if enemy.PoseState then pose = enemy.PoseState
                                        elseif type(enemy.GetPoseState) == "function" then pose = enemy:GetPoseState() end
                                        
                                        if pose == 0 or pose == "Stand" then stateText = "Đứng"
                                        elseif pose == 1 or pose == "Crouch" then stateText = "Ngồi"
                                        elseif pose == 2 or pose == "Prone" then stateText = "Nằm"
                                        else stateText = "Đứng" end
                                    end
                                    
                                    if _G.LexusConfig.Esp7_VuKhi then
                                        local curTime = os.clock()
                                        if markData.AK_LAST_WEP_TIME == nil or curTime > markData.AK_LAST_WEP_TIME + 1.5 then
                                            local eWeapon = nil
                                            if enemy.CurrentWeapon then eWeapon = enemy.CurrentWeapon
                                            elseif type(enemy.GetCurrentWeapon) == "function" then eWeapon = enemy:GetCurrentWeapon()
                                            elseif enemy.WeaponManagerComponent then eWeapon = enemy.WeaponManagerComponent.CurrentWeaponReplicated end
                                            
                                            local weaponName = "Tay Không"
                                            if Valid(eWeapon) then if type(eWeapon.GetWeaponName) == "function" then weaponName = eWeapon:GetWeaponName() end end
                                            markData.AK_CACHED_WEP_NAME = tostring(weaponName)
                                            markData.AK_LAST_WEP_TIME = curTime
                                        end

                                        if stateText ~= "" then
                                            stateText = stateText .. " - " .. (markData.AK_CACHED_WEP_NAME or "Tay Không")
                                        else
                                            stateText = (markData.AK_CACHED_WEP_NAME or "Tay Không")
                                        end
                                    end

                                    if stateText ~= "" then
                                        local textColor = isBot and C_CYAN or C_YELLOW
                                        local dynamicScale = math.max(0.5, 0.8 - (distM / 400))
                                        MyHUD:AddDebugText(stateText, enemy, 0.06, {X=0, Y=0, Z=100}, {X=0, Y=0, Z=100}, textColor, true, false, true, nil, dynamicScale, true)
                                    end
                                end
                            end
                        end)
                    end

                    if showFrameUI then
                        pcall(function()
                            local SecurityCommonUtils = Cached_SecurityCommonUtils
                            local show = true
                            if enemy.HealthStatus and SecurityCommonUtils and SecurityCommonUtils.IsHealthStatusAlive then 
                                if not SecurityCommonUtils.IsHealthStatusAlive(enemy.HealthStatus) then show = false end
                            end
                            if show and mLoc then
                                if aLoc and SecurityCommonUtils and SecurityCommonUtils.IsVector then
                                    if SecurityCommonUtils.IsVector(aLoc) and SecurityCommonUtils.IsVector(mLoc) then
                                        if aLoc.Z >= 150000 or FVector.Dist2D(mLoc, aLoc) > 50000 then show = false end
                                    end
                                end
                            end
                            if show then
                                if enemy.Replay_IsEnemyFrameUIExisted and not enemy:Replay_IsEnemyFrameUIExisted() then enemy:Replay_CreateEnemyFrameUI(true, true) end
                                if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(true) end
                                if enemy.Replay_UpdateEnemyFrameUI then enemy:Replay_UpdateEnemyFrameUI(hpRatio) end
                                
                                local uiComp = enemy.EnemyFrameUI or (type(enemy.GetEnemyFrameUI) == "function" and enemy:GetEnemyFrameUI())
                                if Valid(uiComp) then
                                    if markData.LastFrameUIState ~= "VISIBLE" then
                                        if type(uiComp.SetVisibility) == "function" then uiComp:SetVisibility(0) end
                                        if type(uiComp.SetHiddenInGame) == "function" then uiComp:SetHiddenInGame(false) end
                                        markData.LastFrameUIState = "VISIBLE"
                                    end
                                end
                            end
                        end)
                    else
                        pcall(function()
                            if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(false) end
                            local uiComp = enemy.EnemyFrameUI or (type(enemy.GetEnemyFrameUI) == "function" and enemy:GetEnemyFrameUI())
                            if Valid(uiComp) then
                                if markData.LastFrameUIState ~= "HIDDEN" then
                                    if type(uiComp.SetVisibility) == "function" then uiComp:SetVisibility(2) end
                                    if type(uiComp.SetHiddenInGame) == "function" then uiComp:SetHiddenInGame(true) end
                                    markData.LastFrameUIState = "HIDDEN"
                                end
                            end
                        end)
                    end

                    if _G.LexusConfig.EspVipPro then
                        pcall(function()
                            local hud = Cached_MyHUD
                            if Valid(hud) and hud.AddDebugText then
                                if distM <= 400 then
                                    local dynamicScale = math.max(0.55, 0.95 - (distM / 400))
                                    local hpPercent = hpRatio
                                    local isKnock = (currentHp <= 0 and enemy.HealthStatus == 1)
                                    
                                    local hpColor = C_GREEN
                                    if hpPercent < 0.3 then hpColor = C_RED
                                    elseif hpPercent < 0.7 then hpColor = C_YELLOW end
                                    if isKnock then hpColor = C_RED end
                                    
                                    if _G.LexusConfig.Esp3ShowName then
                                        local enemyName = "Enemy"
                                        pcall(function() if enemy.PlayerName then enemyName = enemy.PlayerName elseif type(enemy.GetPlayerName) == "function" then enemyName = enemy:GetPlayerName() end end)
                                        if enemyName == "" then enemyName = "Enemy" end
                                        if isKnock then enemyName = "KNOCK: " .. enemyName end
                                        hud:AddDebugText(enemyName, enemy, 0.06, {X=0, Y=0, Z=-370}, {X=0, Y=0, Z=-370}, C_WHITE, true, false, true, nil, dynamicScale * 1.1, true)
                                    end
                                    
                                    if _G.LexusConfig.Esp3ShowHP then
                                        if not isKnock then
                                            local segments = 6
                                            local filled = math.floor(hpPercent * segments)
                                            local startZ = 20
                                            local spacing = 10.0 * dynamicScale 
                                            for j = 1, segments do
                                                local color = (j <= filled) and hpColor or {R=30,G=30,B=30,A=180}
                                                hud:AddDebugText("█", enemy, 0.06, {X=0, Y=-115, Z=startZ + (j * spacing)}, {X=0, Y=-115, Z=startZ + (j * spacing)}, color, true, false, true, nil, dynamicScale * 1.2, true)
                                            end
                                            hud:AddDebugText(string.format("%d%%", math.floor(hpPercent * 100)), enemy, 0.06, {X=0, Y=-60, Z=startZ - 12}, {X=0, Y=-60, Z=startZ - 12}, hpColor, true, false, true, nil, dynamicScale * 0.8, true)
                                        else
                                            hud:AddDebugText("DOWN", enemy, 0.06, {X=0, Y=-115, Z=50}, {X=0, Y=-115, Z=50}, C_RED, true, false, true, nil, dynamicScale * 1.0, true)
                                        end
                                    end
                                end
                            end
                        end)
                    end

                    if _G.LexusConfig.EspDistance then
                        pcall(function()
                            local hud = Cached_MyHUD
                            if Valid(hud) and hud.AddDebugText then
                                if distM <= 400 then
                                    local dynamicScale = math.max(0.55, 0.95 - (distM / 400))
                                    hud:AddDebugText(string.format("[%dm]", math.floor(distM)), enemy, 0.06, {X=0, Y=115, Z=20}, {X=0, Y=115, Z=20}, C_BLUE_TEXT, true, false, true, nil, dynamicScale * 1.5, true)
                                end
                            end
                        end)
                    end

                    if _G.LexusConfig.EspVip then
                        if markData.hpMark == nil then markData.hpMark = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                        if markData.distMark == nil then markData.distMark = SafeAddMark(9999, FVector(0,0,0), 0, "", 4, enemy) end
                    else
                        if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
                        if markData.distMark then SafeRemoveMark(markData.distMark); markData.distMark = nil end
                    end

                    if _G.LexusConfig.EspLoai8 then
                        if markData.hpMark8 == nil then markData.hpMark8 = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                    else
                        if markData.hpMark8 then SafeRemoveMark(markData.hpMark8); markData.hpMark8 = nil end
                    end
                    
                    if _G.LexusConfig.EspRadar then
                        if not markData.radarMark or markData.radarMark == 0 then 
                            markData.radarMark = SafeAddMark(8888, FVector(0,0,0), 0, "", 4, enemy) 
                        end
                    else
                        if markData.radarMark and markData.radarMark ~= 0 then
                            SafeRemoveMark(markData.radarMark)
                            markData.radarMark = nil
                        end
                    end
                    
                    if _G.LexusConfig.EspOutline then
                        pcall(function()
                            local outColorChoice = _G.LexusState.CustomTextData.OutlineColor or 4
                            local outThick = _G.LexusConfig.OutlineThickness or 10
                            local outlineHash = string.format("%d_%d", outThick, outColorChoice)
                            
                            local meshes = GetAllSkeletalMeshes(enemy, markData)
                            local currentMeshCount = #meshes
                            
                            if markData.OutlineState ~= outlineHash or markData.LastMeshCountOutline ~= currentMeshCount then
                                
                                local r, g, b = 255, 255, 0
                                if outColorChoice == 1 then r, g, b = 255, 0, 0
                                elseif outColorChoice == 2 then r, g, b = 0, 255, 0
                                elseif outColorChoice == 3 then r, g, b = 0, 0, 255
                                elseif outColorChoice == 4 then r, g, b = 255, 255, 0
                                elseif outColorChoice == 5 then r, g, b = 255, 0, 255
                                elseif outColorChoice == 6 then r, g, b = 255, 255, 255 end

                                local glowIntensity = 80.0
                                local LinearColorClass = import("LinearColor") or _G.FLinearColor
                                local glowDynamic = LinearColorClass and LinearColorClass((r/255) * glowIntensity, (g/255) * glowIntensity, (b/255) * glowIntensity, 1.0) or { R = r * glowIntensity, G = g * glowIntensity, B = b * glowIntensity, A = 255 }

                                for _, comp in ipairs(meshes) do
                                    if Valid(comp) then
                                        pcall(function()
                                            comp.UseScopeDistanceCulling = false 
                                            comp.PrimitiveShadingStrategy = 1
                                            comp.ShadingRate = 6
                                        end)

                                        if comp.SetDrawIdeaOutline then
                                            comp:SetDrawIdeaOutline(true)
                                            if comp.OverrideIdeaOutlineColor then
                                                comp:OverrideIdeaOutlineColor(true, glowDynamic)
                                            end
                                            if comp.OverrideIdeaOutlineThickness then
                                                comp:OverrideIdeaOutlineThickness(true, _G.LexusConfig.OutlineThickness)
                                            end
                                        end
                                    end
                                end
                                markData.OutlineState = outlineHash
                                markData.LastMeshCountOutline = currentMeshCount
                            end
                        end)
                    else
                        pcall(function()
                            if markData.OutlineState ~= "OFF" then
                                local meshes = GetAllSkeletalMeshes(enemy, markData)
                                for _, comp in ipairs(meshes) do
                                    if Valid(comp) then
                                        pcall(function()
                                            comp.PrimitiveShadingStrategy = 0
                                            comp.ShadingRate = 1
                                        end)
                                        
                                        if comp.SetDrawIdeaOutline then
                                            comp:SetDrawIdeaOutline(false)
                                        end
                                    end
                                end
                                markData.OutlineState = "OFF"
                                markData.LastMeshCountOutline = 0
                            end
                        end)
                    end

                else
                    if not markData.IsCleanedUp then
                        SafeRemoveMark(markData.radarMark)
                        markData.radarMark = nil
                        SafeRemoveMark(markData.hpMark)
                        markData.hpMark = nil
                        SafeRemoveMark(markData.hpMark8)
                        markData.hpMark8 = nil
                        SafeRemoveMark(markData.distMark)
                        markData.distMark = nil
                        
                        if markData.MIDs then
                            for meshStr, midTable in pairs(markData.MIDs) do
                                for k, _ in pairs(midTable) do midTable[k] = nil end
                            end
                            markData.MIDs = nil
                        end
                        
                        if markData.MIDs_V3 then
                            for meshStr, midTable in pairs(markData.MIDs_V3) do
                                for k, _ in pairs(midTable) do midTable[k] = nil end
                            end
                            markData.MIDs_V3 = nil
                        end
                        
                        pcall(function()
                            local eObj = markData.enemy
                            if Valid(eObj) then 
                                if eObj.Replay_SetVisiableOfFrameUI then eObj:Replay_SetVisiableOfFrameUI(false) end
                                local uiComp = eObj.EnemyFrameUI or (type(eObj.GetEnemyFrameUI) == "function" and eObj:GetEnemyFrameUI())
                                if Valid(uiComp) then
                                    if type(uiComp.SetVisibility) == "function" then uiComp:SetVisibility(2) end 
                                    if type(uiComp.SetHiddenInGame) == "function" then uiComp:SetHiddenInGame(true) end
                                end
                            end
                            
                            local PPM = Cached_PPM
                            local avatarComp = Valid(eObj) and (type(eObj.getAvatarComponent2) == "function") and eObj:getAvatarComponent2() or nil
                            if Valid(avatarComp) and Valid(PPM) then PPM:EnableAvatarOutline(avatarComp, false) end
                        end)

                        markData.IsCleanedUp = true
                    end
                end
            end
        end

        if _G.LexusConfig.EspLoai7 and _G.LexusConfig.Esp7_SoLuong then
            _M_DrawCounter()
        else
            if EnemyCounterWidget and slua.isValid(EnemyCounterWidget) then
                EnemyCounterWidget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
        end

        if _G.LexusConfig.EspBomMaster and (_G.LexusConfig.EspItemBom or _G.LexusConfig.EspActiveBom) then
            pcall(function()
                local MyHUD = Cached_MyHUD
                if Valid(MyHUD) then
                    if not _G.CachedGameplayStatics then _G.CachedGameplayStatics = import("GameplayStatics") end
                    if not _G.CachedActorClass_ForBomb then _G.CachedActorClass_ForBomb = import("Actor") end 
                    if not _G.CachedProjArray then _G.CachedProjArray = slua.Array(UEnums.EPropertyClass.Object, _G.CachedActorClass_ForBomb) end
                    
                    if not _G.ActorBombCacheInit then
                        _G.NonBombCache = setmetatable({}, { __mode = "k" })
                        _G.BombCache = setmetatable({}, { __mode = "k" })
                        _G.ActorBombCacheInit = true
                    end
                    
                    local ui_util = require("client.common.ui_util")
                    local gameInstance = ui_util and ui_util.GetGameInstance()
                    
                    if gameInstance and _G.CachedGameplayStatics then
                        local curTime = os.clock()
                        
                        if not _G.LastBombScanTime or (curTime - _G.LastBombScanTime) > 0.5 then
                            _G.LastBombScanTime = curTime
                            local allActors = _G.CachedGameplayStatics.GetAllActorsOfClass(gameInstance, _G.CachedActorClass_ForBomb, _G.CachedProjArray)
                            
                            local activeBombs = {}
                            local itemBombs = {}
                            
                            if allActors then
                                for _, actor in pairs(allActors) do
                                    if slua.isValid(actor) and not actor.bHidden and not actor.bTearOff then
                                        
                                        if not _G.NonBombCache[actor] then
                                            local bType = 0
                                            local isItem = false
                                            local isKnownBomb = _G.BombCache[actor]
                                            
                                            if isKnownBomb then
                                                bType = isKnownBomb.type
                                                isItem = isKnownBomb.isItem
                                            else
                                                local nameLower = nil
                                                pcall(function() nameLower = string.lower(type(actor.GetName) == "function" and actor:GetName() or tostring(actor)) end)
                                                
                                                if nameLower then
                                                    if string.find(nameLower, "m79") or string.find(nameLower, "launcher") then bType = 5
                                                    elseif string.find(nameLower, "smoke") then bType = 2
                                                    elseif string.find(nameLower, "burn") or string.find(nameLower, "molotov") then bType = 3
                                                    elseif string.find(nameLower, "flash") or string.find(nameLower, "stun") then bType = 4
                                                    elseif string.find(nameLower, "grenade") then bType = 1 end
                                                    
                                                    if bType > 0 then
                                                        if string.find(nameLower, "projectile") or string.find(nameLower, "thrown") then
                                                            isItem = false
                                                        else
                                                            isItem = true
                                                            local shouldAdd = true
                                                            if bType == 3 and not (string.find(nameLower, "pickup") or string.find(nameLower, "wrapper") or string.find(nameLower, "weapon")) then
                                                                shouldAdd = false
                                                            elseif bType == 5 then
                                                                local attachParent = nil
                                                                pcall(function() if type(actor.GetAttachParentActor) == "function" then attachParent = actor:GetAttachParentActor() end end)
                                                                if slua.isValid(attachParent) then
                                                                    local isHolding = false
                                                                    pcall(function()
                                                                        local curWeapon = type(attachParent.GetCurrentWeapon) == "function" and attachParent:GetCurrentWeapon() or attachParent.CurrentWeapon
                                                                        if curWeapon == actor then isHolding = true end
                                                                    end)
                                                                    if not isHolding then shouldAdd = false end
                                                                end
                                                            end
                                                            if not shouldAdd then bType = 0 end
                                                        end
                                                    end
                                                end
                                                
                                                if bType > 0 then
                                                    _G.BombCache[actor] = { type = bType, isItem = isItem }
                                                else
                                                    _G.NonBombCache[actor] = true
                                                end
                                            end
                                            
                                            if bType > 0 then
                                                local isPendingKill = false
                                                pcall(function() if type(actor.IsPendingKill) == "function" then isPendingKill = actor:IsPendingKill() end end)
                                                
                                                if not isPendingKill then
                                                    if isItem then
                                                        table.insert(itemBombs, {act = actor, type = bType})
                                                    else
                                                        table.insert(activeBombs, {act = actor, type = bType})
                                                    end
                                                else
                                                    _G.BombCache[actor] = nil
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            _G.CachedActiveBombs = activeBombs
                            _G.CachedItemBombs = itemBombs
                        end

                        local curGameTime = 0
                        pcall(function() curGameTime = _G.CachedGameplayStatics.GetTimeSeconds(gameInstance) end)

                        local function DrawBombs(bombList, isItem, maxDist)
                            if not bombList then return end
                            for _, item in ipairs(bombList) do
                                local bomb = item.act
                                local bType = item.type
                                
                                if slua.isValid(bomb) and not bomb.bHidden then
                                    local distM = 0
                                    pcall(function() distM = localPlayer:GetDistanceTo(bomb) / 100 end)
                                    
                                    if distM > 0 and distM <= maxDist then
                                        local displayName = ""
                                        local bombColor = C_WHITE
                                        local zOffset = isItem and 15 or 25
                                        
                                        if bType == 1 then displayName = "Boom"; bombColor = isItem and {R=255, G=100, B=100, A=255} or C_RED
                                        elseif bType == 2 then displayName = "KHÓI"; bombColor = isItem and {R=200, G=200, B=200, A=255} or C_WHITE
                                        elseif bType == 3 then displayName = "LỬA"; bombColor = isItem and {R=255, G=160, B=50, A=255} or {R=255, G=100, B=0, A=255}
                                        elseif bType == 4 then displayName = "MÙ"; bombColor = isItem and {R=150, G=255, B=255, A=255} or C_CYAN
                                        elseif bType == 5 then displayName = "ĐẠN KHÓI"; bombColor = isItem and {R=150, G=255, B=150, A=255} or {R=100, G=255, B=100, A=255} end
                                        
                                        local text = string.format("%s [%dm]", displayName, math.floor(distM))
                                        local shouldTimerRun = not isItem 
                                        
                                        if isItem then pcall(function() if bomb.bIsPinPulled or bomb.bPinPulled or (type(bomb.IsPinPulled) == "function" and bomb:IsPinPulled()) then shouldTimerRun = true end end) end

                                        if shouldTimerRun and curGameTime > 0 then
                                            local timeLeft = -1
                                            pcall(function() if bomb.ExplosionTime then timeLeft = bomb.ExplosionTime - curGameTime elseif bomb.ExplodeTime then timeLeft = bomb.ExplodeTime - curGameTime end end)
                                            
                                            if timeLeft == -1 or timeLeft > 100 then
                                                _G.ActiveBombTimers = _G.ActiveBombTimers or {}
                                                local bombId = tostring(bomb)
                                                if not _G.ActiveBombTimers[bombId] then _G.ActiveBombTimers[bombId] = curGameTime end
                                                local elapsed = curGameTime - _G.ActiveBombTimers[bombId]
                                                local maxTime = (bType == 1 and 7.0) or (bType == 2 and 45.0) or (bType == 3 and 12.0) or (bType == 4 and 5.0) or 45.0
                                                timeLeft = maxTime - elapsed
                                            end
                                            
                                            if timeLeft < 0 then timeLeft = 0 end
                                            if timeLeft > 0.1 then text = string.format("%s (%.1fs)", text, timeLeft) end
                                        end
                                        
                                        local dynamicScale = math.max(0.6, 1.1 - (distM / maxDist))
                                        MyHUD:AddDebugText(text, bomb, 0.06, {X=0, Y=0, Z=zOffset}, {X=0, Y=0, Z=zOffset}, bombColor, true, false, true, nil, dynamicScale, true)
                                    end
                                end
                            end
                        end
                        
                        if not _G.LastClearTimer or (curTime - _G.LastClearTimer) > 1.0 then
                            _G.LastClearTimer = curTime
                            pcall(function() if _G.ActiveBombTimers then for k, v in pairs(_G.ActiveBombTimers) do if (curGameTime - v) > 60.0 then _G.ActiveBombTimers[k] = nil end end end end)
                        end

                        if _G.LexusConfig.EspItemBom then DrawBombs(_G.CachedItemBombs, true, 50) end
                        if _G.LexusConfig.EspActiveBom then DrawBombs(_G.CachedActiveBombs, false, 150) end
                    end
                end
            end)
        end

        if _G.LexusConfig.EspVehicle then
            pcall(function()
                local MyHUD = Cached_MyHUD
                if Valid(MyHUD) then
                    if not _G.CachedGameplayStatics then _G.CachedGameplayStatics = import("GameplayStatics") end
                    if not _G.CachedActorClass_ForVehicle then _G.CachedActorClass_ForVehicle = import("STExtraVehicleBase") end 
                    if not _G.CachedVehicleArray then _G.CachedVehicleArray = slua.Array(UEnums.EPropertyClass.Object, _G.CachedActorClass_ForVehicle) end
                    
                    local ui_util = require("client.common.ui_util")
                    local gameInstance = ui_util and ui_util.GetGameInstance()
                    
                    if gameInstance and _G.CachedGameplayStatics then
                        local curTime = os.clock()

                        if not _G.LastVehicleScanTime or (curTime - _G.LastVehicleScanTime) > 1.0 then
                            _G.LastVehicleScanTime = curTime
                            local allVehicles = _G.CachedGameplayStatics.GetAllActorsOfClass(gameInstance, _G.CachedActorClass_ForVehicle, _G.CachedVehicleArray)
                            
                            local activeVehicles = {}
                            if allVehicles then
                                for _, veh in pairs(allVehicles) do
                                    if slua.isValid(veh) and not veh.bHidden and not veh.bTearOff then
                                        local isPendingKill = false
                                        pcall(function() if type(veh.IsPendingKill) == "function" then isPendingKill = veh:IsPendingKill() end end)
                                        
                                        if not isPendingKill then
                                            local vehName = "Xe"
                                            local hasDriver = false
                                            
                                            pcall(function()
                                                if type(veh.GetVehicleName) == "function" then vehName = veh:GetVehicleName() elseif veh.VehicleName then vehName = veh.VehicleName end
                                                local driver = type(veh.GetDriver) == "function" and veh:GetDriver() or nil
                                                if slua.isValid(driver) then hasDriver = true end
                                            end)
                                            
                                            local nameLower = string.lower(tostring(vehName) .. tostring(veh))
                                            local displayName = "Xe"
                                            if string.find(nameLower, "uaz") then displayName = "UAZ"
                                            elseif string.find(nameLower, "dacia") then displayName = "Dacia"
                                            elseif string.find(nameLower, "buggy") then displayName = "Buggy"
                                            elseif string.find(nameLower, "mirado") then displayName = "Mirado"
                                            elseif string.find(nameLower, "bike") or string.find(nameLower, "motor") then displayName = "Motor"
                                            elseif string.find(nameLower, "scooter") then displayName = "Scooter"
                                            elseif string.find(nameLower, "coupe") then displayName = "Coupe RB"
                                            elseif string.find(nameLower, "brdm") then displayName = "BRDM"
                                            elseif string.find(nameLower, "boat") or string.find(nameLower, "aquarail") then displayName = "Thuyền"
                                            elseif string.find(nameLower, "glider") then displayName = "Tàu lượn"
                                            else displayName = "Xe (" .. string.sub(vehName, 1, 8) .. ")" end

                                            table.insert(activeVehicles, {act = veh, name = displayName, hasDriver = hasDriver})
                                        end
                                    end
                                end
                            end
                            _G.CachedVehicles = activeVehicles
                        end

                        if _G.CachedVehicles then
                            for _, item in ipairs(_G.CachedVehicles) do
                                local veh = item.act
                                if slua.isValid(veh) and not veh.bHidden then
                                    local isShow = false
                                    if item.name == "Dacia" then isShow = _G.LexusConfig.EspVeh_Dacia
                                    elseif item.name == "UAZ" then isShow = _G.LexusConfig.EspVeh_UAZ
                                    elseif item.name == "Buggy" then isShow = _G.LexusConfig.EspVeh_Buggy
                                    elseif item.name == "Coupe RB" then isShow = _G.LexusConfig.EspVeh_Coupe
                                    elseif item.name == "Mirado" then isShow = _G.LexusConfig.EspVeh_Mirado
                                    elseif item.name == "Motor" or item.name == "Scooter" then isShow = _G.LexusConfig.EspVeh_Motor
                                    else isShow = _G.LexusConfig.EspVeh_Other end

                                    if isShow then
                                        local distM = 0
                                        pcall(function() distM = localPlayer:GetDistanceTo(veh) / 100 end)
                                        
                                        if distM > 0 and distM <= 300 then
                                            local text = string.format("%s [%dm]", item.name, math.floor(distM))
                                            local vehColor = item.hasDriver and {R=255, G=50, B=50, A=255} or {R=0, G=255, B=150, A=255}
                                            local dynamicScale = math.max(0.6, 1.1 - (distM / 500))
                                            
                                            MyHUD:AddDebugText(text, veh, 0.06, {X=0, Y=0, Z=50}, {X=0, Y=0, Z=50}, vehColor, true, false, true, nil, dynamicScale, true)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end

    end)
end

_G.LexusState.LoopToken = (_G.LexusState.LoopToken or 0) + 1 
local myToken = _G.LexusState.LoopToken

local function FastTick() 
    if myToken ~= _G.LexusState.LoopToken then return end
    pcall(MainLoop) 
    local okTicker, ticker = pcall(require, "common.time_ticker") 
    if okTicker and ticker and ticker.AddTimerOnce then 
        ticker.AddTimerOnce(0.01, FastTick) 
    end 
end

FastTick() 
Notify("Bạn Đang Chơi Mod Vvip")

-- ===================================================================================
-- SYSTEM HOOKS
-- ===================================================================================
local function InitAllModSystems()
    pcall(function()
        if _G.InitializeAutoHeadHooks then _G.InitializeAutoHeadHooks() end
    end)

    local GameplayData = package.loaded["GameLua.GameCore.Data.GameplayData"] or require("GameLua.GameCore.Data.GameplayData")
    if not GameplayData then return end

    pcall(function()
        local LocalPlayer = GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
        if slua.isValid(LocalPlayer) then
            if LocalPlayer.bHasShownDevNotice == nil then
                LocalPlayer.bHasShownDevNotice = false 
                LocalPlayer.bHasShownExpiredNotice = false 
                LocalPlayer.bIsDeadFlag = false
            end
        end
    end)
end

pcall(function() 
    require("common.time_ticker").AddTimerOnce(0.5, InitAllModSystems) 
end)

function M.OnBeginPlay(self)
end
return M