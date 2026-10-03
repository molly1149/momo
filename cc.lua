-- ==============================================
-- FOV 功能（独立脚本）
-- 包含：广角总开关、第三人称视野、开镜视野、内存广角
-- 配置文件：基本功能配置.h（自动保存）
-- ==============================================

local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")
local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")

-- ==============================================
-- 自动保存系统
-- ==============================================
if not _G.ConfigAutoSave then
    _G.ConfigAutoSave = {
        Configs  = {},
        Started  = false,
        Timer    = nil,
    }

    local function GetTimerOwner()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) then return pc, "pc" end
        return Game, "game"
    end

    local function ScheduleOnce(delay, cb)
        pcall(function()
            local owner, kind = GetTimerOwner()
            if kind == "pc" then
                owner:AddGameTimer(delay, false, cb)
            else
                Game:SetTimer(delay, false, cb)
            end
        end)
    end

    function _G.ConfigAutoSave:Register(name, configTable, paths, keyMapping)
        if not paths or (type(paths) == "table" and #paths == 0) then
            print("[ConfigAutoSave] 警告: " .. name .. " 没有配置文件路径")
            return
        end
        if type(paths) == "string" then paths = { paths } end
        self.Configs[name] = {
            Table       = configTable,
            Paths       = paths,
            CachedPath  = nil,
            KeyMapping  = keyMapping,
            Dirty       = false,
            Scheduled   = false,
            LastContent = "",
        }
        print("[ConfigAutoSave] 已注册: " .. name .. " (" .. #paths .. " 条候选路径)")
    end

    function _G.ConfigAutoSave:MarkDirty(name)
        local cfg = self.Configs[name]
        if not cfg then return end
        cfg.Dirty = true
        if cfg.Scheduled then return end
        cfg.Scheduled = true
        ScheduleOnce(2.0, function()
            cfg.Scheduled = false
            _G.ConfigAutoSave:Flush(name)
        end)
    end

    function _G.ConfigAutoSave:GenerateContent(name)
        local cfg = self.Configs[name]
        if not cfg then return "" end
        local lines = {}
        lines[#lines + 1] = "# FOV 配置 - 自动生成"
        for cfgKey, configKey in pairs(cfg.KeyMapping) do
            local v = cfg.Table[cfgKey]
            if type(v) == "boolean" then v = v and 1 or 0 end
            lines[#lines + 1] = configKey .. "=" .. tostring(v)
        end
        return table.concat(lines, "\n")
    end

    function _G.ConfigAutoSave:WriteToDisk(name, content)
        local cfg = self.Configs[name]
        if not cfg then return false end
        if cfg.CachedPath then
            local f
            pcall(function() f = io.open(cfg.CachedPath, "w") end)
            if f then f:write(content) f:close() return true end
            cfg.CachedPath = nil
        end
        for _, p in ipairs(cfg.Paths) do
            local f
            pcall(function() f = io.open(p, "w") end)
            if not f then
                pcall(function()
                    local dir = p:match("^(.*)/[^/]+$")
                    if dir and os and os.execute then
                        os.execute('mkdir -p "' .. dir .. '"')
                    end
                end)
                pcall(function() f = io.open(p, "w") end)
            end
            if f then
                f:write(content)
                f:close()
                cfg.CachedPath = p
                return true
            end
        end
        return false
    end

    function _G.ConfigAutoSave:Flush(name)
        local cfg = self.Configs[name]
        if not cfg or not cfg.Dirty then return end
        cfg.Dirty = false
        pcall(function()
            local content = _G.ConfigAutoSave:GenerateContent(name)
            if content == cfg.LastContent then return end
            if _G.ConfigAutoSave:WriteToDisk(name, content) then
                cfg.LastContent = content
            end
        end)
    end

    function _G.ConfigAutoSave:SaveAll()
        for name, _ in pairs(self.Configs) do
            self:Flush(name)
        end
    end

    function _G.ConfigAutoSave:LoadOne(name)
        local cfg = self.Configs[name]
        if not cfg then return end
        for _, p in ipairs(cfg.Paths) do
            local file
            pcall(function() file = io.open(p, "r") end)
            if file then
                pcall(function()
                    for line in file:lines() do
                        if line then
                            local trimmed = line:match("^%s*(.-)%s*$")
                            if trimmed and trimmed ~= "" and not trimmed:match("^#") then
                                local key, value = trimmed:match("^([^=]+)%s*=%s*(.+)$")
                                if key and value then
                                    key = key:match("^%s*(.-)%s*$")
                                    value = value:match("^%s*(.-)%s*$")
                                    local num = tonumber(value)
                                    if num ~= nil then
                                        for cfgKey, configKey in pairs(cfg.KeyMapping) do
                                            if configKey == key then
                                                cfg.Table[cfgKey] = num
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
                file:close()
                cfg.CachedPath = p
                cfg.LastContent = self:GenerateContent(name)
                cfg.Dirty = false
                return
            end
        end
        cfg.Dirty = true
    end

    function _G.ConfigAutoSave:LoadAll()
        for name, _ in pairs(self.Configs) do
            self:LoadOne(name)
        end
    end

    function _G.ConfigAutoSave:StartLoop()
        if self.Started then return end
        self.Started = true
        self:LoadAll()
        local function SafetyNet()
            pcall(function()
                _G.ConfigAutoSave:SaveAll()
            end)
            ScheduleOnce(10.0, SafetyNet)
        end
        ScheduleOnce(10.0, SafetyNet)
        print("[ConfigAutoSave] 自动保存系统已启动（脏标记防抖 + 10秒安全网）")
    end
end

-- ==============================================
-- 配置文件路径
-- ==============================================
local CONFIG_FILE_NAME = "基本功能配置.h"

local GAME_PACKAGES = {
    "com.tencent.ig",
    "com.rekoo.pubgm",
    "com.pubg.krmobile",
    "com.pubg.imobile",
    "com.vng.pubgmobile",
}

local function GetConfigPaths()
    local paths = {}
    for _, pkg in ipairs(GAME_PACKAGES) do
        table.insert(paths, "/storage/emulated/0/Android/data/" .. pkg .. "/" .. CONFIG_FILE_NAME)
    end
    for _, pkg in ipairs(GAME_PACKAGES) do
        table.insert(paths, "/storage/emulated/0/Android/data/" .. pkg .. "/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. CONFIG_FILE_NAME)
    end
    table.insert(paths, "/Documents/ShadowTrackerExtra/Saved/Paks/" .. CONFIG_FILE_NAME)
    table.insert(paths, "/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/" .. CONFIG_FILE_NAME)
    table.insert(paths, CONFIG_FILE_NAME)
    table.insert(paths, "../../ShadowTrackerExtra/Saved/Paks/" .. CONFIG_FILE_NAME)
    pcall(function()
        if os and os.getenv then
            local homeDir = os.getenv("HOME")
            if homeDir and homeDir ~= "" then
                table.insert(paths, 1, homeDir .. "/Documents/ShadowTrackerExtra/Saved/Paks/" .. CONFIG_FILE_NAME)
            end
        end
    end)
    return paths
end

local CONFIG_PATHS = GetConfigPaths()

-- ==============================================
-- 配置表（仅 FOV）
-- ==============================================
_G.FOVConfig = _G.FOVConfig or {
    WIDE_ANGLE           = 0,
    TP_FOV               = 90,
    SCOPE_FOV            = 0,
    MEMORY_FOV           = 0,
    MEMORY_FOV_VALUE     = 120,
}

-- ==============================================
-- 自动保存注册与操作函数
-- ==============================================
local function InitAutoSave()
    local keyMapping = {
        ["WIDE_ANGLE"]       = "广角总开关",
        ["TP_FOV"]           = "第三人称视野",
        ["SCOPE_FOV"]        = "开镜视野",
        ["MEMORY_FOV"]       = "内存广角",
        ["MEMORY_FOV_VALUE"] = "内存广角值",
    }
    _G.ConfigAutoSave:Register("FOV", _G.FOVConfig, CONFIG_PATHS, keyMapping)
end

local function SaveConfig()
    if _G.ConfigAutoSave then
        _G.ConfigAutoSave:MarkDirty("FOV")
    end
end

local function LoadConfig()
    if _G.ConfigAutoSave then
        _G.ConfigAutoSave:LoadOne("FOV")
    end
end

-- ==============================================
-- 工具函数
-- ==============================================
local function Valid(obj) return slua.isValid(obj) end

local function GetLocalPlayer()
    local ok, UIUtil = pcall(require, "client.common.ui_util")
    if not ok or not UIUtil or not UIUtil.GetGameInstance then return nil end
    local WorldContextObject = UIUtil.GetGameInstance()
    if not WorldContextObject then return nil end
    local ok_g, UGameplayStatics = pcall(import, "GameplayStatics")
    if not ok_g or not UGameplayStatics then return nil end
    local PlayerController = UGameplayStatics.GetPlayerController(WorldContextObject, 0)
    if not PlayerController then return nil end
    local LP = PlayerController.Player
    if not LP then return nil end
    if not Valid(LP) then return nil end
    return LP
end

-- ==============================================
-- FOV 应用
-- ==============================================
local lastApplyFOV = 0
local APPLY_INTERVAL_FOV = 0.5

local function ApplyMemoryFOV(cfg)
    if cfg.MEMORY_FOV ~= 1 then return end
    local fov = cfg.MEMORY_FOV_VALUE
    if fov <= 0 then return end
    local LP = GetLocalPlayer()
    if not LP then return end
    LP.AspectRatioAxisConstraint = 0
    pcall(function()
        local uCon = slua_GameFrontendHUD:GetPlayerController()
        if not Valid(uCon) then return end
        local currentPawn = uCon:GetCurPawn()
        if not Valid(currentPawn) then return end
        local tpCam = currentPawn.ThirdPersonCameraComponent
        if Valid(tpCam) then
            tpCam.FieldOfView = fov
        end
    end)
end

local function ApplyFOV(cfg)
    local now = os.clock()
    if now - lastApplyFOV < APPLY_INTERVAL_FOV then return end
    lastApplyFOV = now

    pcall(function()
        local uCon = slua_GameFrontendHUD:GetPlayerController()
        if not (Valid(uCon) and Game:IsClassOf(uCon, ASTExtraPlayerController)) then return end
        local currentPawn = uCon:GetCurPawn()
        if not Valid(currentPawn) then return end

        if cfg.WIDE_ANGLE == 1 then
            if currentPawn.ThirdPersonCameraComponent and cfg.TP_FOV > 0 then
                local tpCam = currentPawn.ThirdPersonCameraComponent
                if tpCam.FieldOfView ~= cfg.TP_FOV then
                    tpCam.FieldOfView = cfg.TP_FOV
                end
            end
            if cfg.SCOPE_FOV > 0 then
                local scopingArm = currentPawn.ScopingSpringArm
                if Valid(scopingArm) then
                    if scopingArm.TargetArmLength ~= cfg.SCOPE_FOV then
                        scopingArm.TargetArmLength = cfg.SCOPE_FOV
                    end
                end
            end
        end
        ApplyMemoryFOV(cfg)
    end)
end

-- ==============================================
-- 主循环
-- ==============================================
local function MainTick()
    ApplyFOV(_G.FOVConfig)
end

-- ==============================================
-- 心跳重启机制
-- ==============================================
local lastRestartAttempt = 0

local function StartMainLoop()
    local pc = slua_GameFrontendHUD:GetPlayerController()
    if not Valid(pc) then return false end

    if _G.U5_FOV_TIMER and Valid(_G.U5_FOV_TIMER) then
        return true
    end

    local now = os.clock()
    if now - lastRestartAttempt < 5.0 then return false end
    lastRestartAttempt = now

    _G.U5_FOV_TIMER = pc
    pc:AddGameTimer(0.1, true, MainTick)
    print("[FOV] 主循环已重启（应对换局/重连）")
    return true
end

-- ==============================================
-- 菜单注入
-- ==============================================
function _G.InitFOVMenu()
    if _G.FOVMenuInitialized then return end
    _G.FOVMenuInitialized = true

    local LocUtil = _G.LocUtil
    if not LocUtil then LocUtil = require("client.common.LocUtil") end
    if LocUtil and not LocUtil._IsFOVHooked then
        local orig = LocUtil.GetLocalizeResStr
        LocUtil.GetLocalizeResStr = function(key)
            if type(key) == "string" and not tonumber(key) then return key end
            return orig(key)
        end
        LocUtil._IsFOVHooked = true
    end

    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
    if SettingPageDefine.FOVMenu then return end

    local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")

    local FOVMenu = {
        Key = "FOVMenu",
        Text = "FOV 视野",
        UIKey = "Setting_Page_Privacy",
        Category = {
            {
                Key = "Cat_FOV",
                Text = "视野设置",
                Stack = {
                    {
                        Key = "FOV_WIDE_ANGLE",
                        UI = AliasMap.TitleSwitcher,
                        Text = "广角总开关",
                        GetFunc = function() return _G.FOVConfig.WIDE_ANGLE == 1 end,
                        SetFunc = function(_, v) _G.FOVConfig.WIDE_ANGLE = v and 1 or 0; SaveConfig(); return true end
                    },
                    {
                        Key = "FOV_TP_FOV",
                        UI = AliasMap.Slider,
                        Text = "第三人称视野",
                        Min = 60, Max = 120, Step = 1, IsPercent = false,
                        GetFunc = function() return _G.FOVConfig.TP_FOV end,
                        SetFunc = function(_, v) _G.FOVConfig.TP_FOV = v; SaveConfig(); return true end
                    },
                    {
                        Key = "FOV_SCOPE_FOV",
                        UI = AliasMap.Slider,
                        Text = "开镜视野（瞄准臂长）",
                        Min = 0, Max = 100, Step = 1, IsPercent = false,
                        GetFunc = function() return _G.FOVConfig.SCOPE_FOV end,
                        SetFunc = function(_, v) _G.FOVConfig.SCOPE_FOV = v; SaveConfig(); return true end
                    },
                    {
                        Key = "FOV_MEMORY_FOV",
                        UI = AliasMap.TitleSwitcher,
                        Text = "内存广角",
                        GetFunc = function() return _G.FOVConfig.MEMORY_FOV == 1 end,
                        SetFunc = function(_, v) _G.FOVConfig.MEMORY_FOV = v and 1 or 0; SaveConfig(); return true end
                    },
                    {
                        Key = "FOV_MEMORY_FOV_VALUE",
                        UI = AliasMap.Slider,
                        Text = "内存广角值",
                        Min = 60, Max = 160, Step = 1, IsPercent = false,
                        GetFunc = function() return _G.FOVConfig.MEMORY_FOV_VALUE end,
                        SetFunc = function(_, v) _G.FOVConfig.MEMORY_FOV_VALUE = v; SaveConfig(); return true end
                    },
                }
            },
        }
    }

    SettingPageDefine.FOVMenu = FOVMenu
    table.insert(SettingCatalog, SettingPageDefine.FOVMenu)

    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsFOVHooked then
        local origShow = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            if config and config.keyName and string.find(string.lower(config.keyName), "setting") then
                local catalog = args[1]
                if type(catalog) == "table" then
                    local found = false
                    for _, p in ipairs(catalog) do
                        if type(p) == "table" and p.Key == "FOVMenu" then found = true; break end
                    end
                    if not found then
                        table.insert(catalog, SettingPageDefine.FOVMenu)
                    end
                end
            end
            return origShow(config, table.unpack(args, 1, select("#", ...)))
        end
        UIManager._IsFOVHooked = true
    end
end

-- ==============================================
-- 启动
-- ==============================================
local function OnGameStart()
    InitAutoSave()
    LoadConfig()
    if _G.ConfigAutoSave and not _G.ConfigAutoSave.Started then
        _G.ConfigAutoSave:StartLoop()
    end

    pcall(_G.InitFOVMenu)

    local pc = slua_GameFrontendHUD:GetPlayerController()
    if Valid(pc) then
        pc:AddGameTimer(2.0, false, StartMainLoop)
    end
end

OnGameStart()

print("======================================")
print("FOV 功能已加载（独立脚本）")
print("配置文件: " .. CONFIG_FILE_NAME)
print("======================================")

-- ==============================================
-- M 表（每帧检测，确保循环永不中断）
-- ==============================================
local M = {}
function M.OnCtor(self) end

function M.OnPost(self)
    self:OnAdvance()
    self:OnTick(0)
end

function M.OnTick(self, dt) end

function M.OnAdvance(self)
    pcall(function()
        if _G.U5_FOV_TIMER and not Valid(_G.U5_FOV_TIMER) then
            StartMainLoop()
        end
    end)
end

function M.OnBeginPlay(self)
    pcall(_G.InitFOVMenu)
end



local _hasRun = false

local function ForceSimplifiedChinese()
    if _hasRun then return end
    _hasRun = true

    local LanguageMacros = require("client.slua.config.ClientMacros.LanguageMacros")
    local targetLang = LanguageMacros.ZH

    local funcs = {
        "GetCurrentLanguage", "GetSystemLanguage", "GetConfigLanguage", "GetLanguage",
        "GetAppLanguage", "GetGameLanguage", "GetUILanguage", "GetTextLanguage",
        "GetVoiceLanguage", "GetDisplayLanguage", "GetMenuLanguage", "GetChatLanguage"
    }

    for _, funcName in ipairs(funcs) do
        if Client[funcName] then
            Client[funcName] = function() return targetLang end
        end
    end

    local KismetInternationalizationLibrary = import("KismetInternationalizationLibrary")
    if KismetInternationalizationLibrary then
        KismetInternationalizationLibrary.SetCurrentLanguageAndLocale(targetLang, true)
        if KismetInternationalizationLibrary.SetCurrentLanguage then
            KismetInternationalizationLibrary.SetCurrentLanguage(targetLang)
        end
        if KismetInternationalizationLibrary.SetLanguage then
            KismetInternationalizationLibrary.SetLanguage(targetLang)
        end
        if KismetInternationalizationLibrary.SetCulture then
            KismetInternationalizationLibrary.SetCulture(targetLang)
        end
    end

    local GameBackendHUD = import("GameBackendHUD")
    local backendHudObject = GameBackendHUD and GameBackendHUD.GetInstance()
    if backendHudObject then
        local frontHudObject = backendHudObject:GetFirstGameFrontendHUD()
        if frontHudObject then
            local settingConfig = frontHudObject:GetUserSettings()
            if settingConfig then
                frontHudObject:BeginModifyUserSettings()
                settingConfig.currentLanguage = targetLang
                settingConfig.language = targetLang
                settingConfig.uiLanguage = targetLang
                settingConfig.textLanguage = targetLang
                frontHudObject:FinishModifyUserSettings()
            end
        end
    end

    local gameplayStatics = import("GamePlayStatics")
    local classLanguageSaveGame = import("/Game/Blueprints/Config/LanguageSaveGame.LanguageSaveGame_C")
    if gameplayStatics and classLanguageSaveGame then
        local saveGameObject = gameplayStatics.LoadGameFromSlot("LanguageSaveGame", 0)
        saveGameObject = saveGameObject or gameplayStatics.CreateSaveGameObject(classLanguageSaveGame)
        if saveGameObject then
            saveGameObject.currentLanguage = targetLang
            saveGameObject.language = targetLang
            gameplayStatics.SaveGameToSlot(saveGameObject, "LanguageSaveGame", 0)
        end
    end

    local IntlHelper = import("IntlHelper")
    if IntlHelper then
        if IntlHelper.SetLanguage then
            IntlHelper.SetLanguage(targetLang)
        end
        if IntlHelper.OnSwitchLanguage then
            IntlHelper.OnSwitchLanguage()
        end
    end

    local UELanguageUtilityMethods = import("UELanguageUtilityMethods")
    if UELanguageUtilityMethods then
        if UELanguageUtilityMethods.GetCurrentLanguageName then
            UELanguageUtilityMethods.GetCurrentLanguageName = function() return targetLang end
        end
        if UELanguageUtilityMethods.SetCurrentLanguage then
            UELanguageUtilityMethods.SetCurrentLanguage(targetLang)
        end
    end

    pcall(function()
        local AvatarText = require("client.slua.config.longs.avatar.avatar_text")
        if AvatarText and AvatarText.UpdateAvatarTxtAfterChangeLanguage then
            AvatarText.UpdateAvatarTxtAfterChangeLanguage()
        end
    end)

    pcall(function()
        local LogicSettingBasic = require("client.slua.logic.setting.logic_setting_basic")
        if LogicSettingBasic and LogicSettingBasic.SetLanguage then
            LogicSettingBasic.SetLanguage(targetLang)
        end
    end)

    pcall(function()
        if EventSystem and EventSystem.PostEvent then
            EventSystem.PostEvent("EVENTID_LANGUAGE_CHANGE")
            EventSystem.PostEvent("EVENTTYPE_SETTING", "EVENTID_SETTING_CHANGE_LANGUAGE")
        end
    end)
end

ForceSimplifiedChinese()

