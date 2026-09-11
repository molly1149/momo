local logic_lobby_user_research = {}

-- ============================================================
-- 强制简体中文（来自原 6.lua）
-- ============================================================
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

-- ============================================================
-- logic_lobby_user_research 模块
-- ============================================================
function logic_lobby_user_research:DefineAndResetData()
  self.isLogin = true
  self.reportCache = nil
end

function logic_lobby_user_research:OnInitialize()
  -- 保证模块初始化时语言已经切换到简体中文
  ForceSimplifiedChinese()
end

function logic_lobby_user_research:RegistEvents()
  self:AddCommonEvent(EVENTTYPE_URL, BP_ENUM_MODULE_LOBBY_USER_RESEARCH, self.InLobbyCheck, self)
  self:AddCommonEvent(EVENTTYPE_INGAME, EVENTID_INGAME_ON_BATTLE_RESULT, self.OnResultDataHandler, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY, BP_ENUM_MODULE_USER_RESEARCH_INIT, self.OnResearchInit, self)
end

function logic_lobby_user_research:OnLogin(bReLogin)
  log(bWriteLog and "logic_lobby_user_research:OnLogin")
  self.isLogin = true
end

function logic_lobby_user_research:OnLogOut()
end

function logic_lobby_user_research:OnPreSwitchGameStatus(preState, nextState)
end

function logic_lobby_user_research:OnPostSwitchGameStatus(preState, nextState)
  log(bWriteLog and "logic_lobby_user_research:OnPostSwitchGameStatus preState:" .. tostring(preState) .. " nextState = " .. tostring(nextState) .. " self.isLogin:" .. tostring(self.isLogin))
  if self.checkTopUITimer then
    self:RemoveTimer(self.checkTopUITimer)
    self.checkTopUITimer = nil
  end
  if nextState == GameStatus.Lobby then
    local delayTimer = 0.1
    if preState == GameStatus.Login then
      delayTimer = 3
    end
    if self.reportTimer then
      self:RemoveTimer(self.reportTimer)
      self.reportTimer = nil
    end
    self.reportTimer = self:AddTimerOnce(delayTimer, function()
      local logic_post_switch_popup = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_post_switch_popup)
      logic_post_switch_popup:TryExecuteOne(BP_ENUM_MODULE_LOBBY_USER_RESEARCH)
    end)
  end
  if preState ~= GameStatus.Login then
    self.isLogin = false
  end
  if preState == GameStatus.Lobby then
    self.reportCache = nil
  end
end

function logic_lobby_user_research:GetMainAppID()
  local LogicUGCWOWQuestionnaire = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCWOWQuestionnaire)
  return LogicUGCWOWQuestionnaire:GetMainAppID()
end

function logic_lobby_user_research:GetMainAppName()
  local LogicUGCWOWQuestionnaire = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCWOWQuestionnaire)
  return LogicUGCWOWQuestionnaire:GetMainAppName()
end

function logic_lobby_user_research:OnResearchInit()
  if not self.reportCache then
    log(bWriteLog and "logic_lobby_user_research:OnResearchInit self.reportCache is nil")
    return
  end
  log_tree("logic_lobby_user_research:OnResearchInit self.reportCache:", self.reportCache)
  self:SendTuxReport(self.reportCache.page_id, self.reportCache.page_from, self.reportCache.map_id)
end

function logic_lobby_user_research:InLobbyCheck()
  log(bWriteLog and "logic_lobby_user_research:InLobbyCheck isLogin:" .. tostring(self.isLogin))
  if self.isLogin then
    self:OnLoginCheck()
  elseif self.result_data then
    local map_id = self.result_data.sub_mode
    self:OnFightBackLobbyCheck(map_id)
  end
  self.isLogin = false
  self.result_data = nil
end

function logic_lobby_user_research:OnResultDataHandler(_, __, result_data)
  log_tree("logic_lobby_user_research:OnResultDataHandler result_data:", result_data)
  self.result_data = result_data
  EventSystem:postEvent(EVENTTYPE_LOBBY, EVENTID_POST_SWITCH_SHOW_USER_RESEARCH_POPUP)
end

function logic_lobby_user_research:OnFightBackLobbyCheck(map_id)
  log(bWriteLog and "logic_lobby_user_research:OnFightBackLobbyCheck map_id:" .. tostring(map_id))
  self:SendTuxReport("game_lobby", "game", map_id)
end

function logic_lobby_user_research:OnLoginCheck()
  log(bWriteLog and "logic_lobby_user_research:OnLoginCheck")
  self:SendTuxReport("game_lobby", "login")
end

function logic_lobby_user_research:SendTuxReport(page_id, page_from, map_id)
  log(bWriteLog and string.format("logic_lobby_user_research:SendTuxReport page_id:%s, page_from:%s, map_id:%s", page_id, page_from, map_id))
  local mainAppId = self:GetMainAppID()
  if not mainAppId then
    self.reportCache = {
      page_id = page_id,
      page_from = page_from,
      map_id = map_id
    }
    log(bWriteLog and "logic_lobby_user_research:SendTuxReport mainAppId is nil")
    return
  end
  local map_id_str = map_id and tostring(map_id) or nil
  local content = {
    event_code = "page_in",
    params = {
      page_id = page_id,
      page_from = page_from,
      map_id = map_id_str
    }
  }
  local data = {
    type = "tuxReport",
    content = json.encode(content)
  }
  local HostedProtoBridge = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.HostedProtoBridge)
  HostedProtoBridge:SendMessage(nil, data, mainAppId)
end

function logic_lobby_user_research:OntuxShowEntrance(data, appType)
  self.tuxData = data.tuxData
  local LoadingSystem = require("client.slua.logic.loading.logic_loading")
  local isLoading = LoadingSystem.IsShowing()
  local sceneId = tonumber(data.tuxData.sceneId)
  local code = 0
  if sceneId == 17 and GameStatus.IsInLobbyOrMainCity() then
    code = 0
  elseif sceneId == 18 and not isLoading and not GameStatus.IsInLobbyOrMainCity() then
    code = 0
  else
    code = -1
  end
  log(bWriteLog and "logic_lobby_user_research:OntuxShowEntrance code = ", code)
  self:OnSendtuxSetupUI(code)
  if code == 0 then
    UIManager.ShowUI(UIManager.UI_Config.Common_Placeholder_UIBP, {
      close_timer = 3.5,
      open_callback = function(commonPlaceholderUIBP)
        self:OnInitTuxUI()
        if self.pandoraCheckTimer then
          self:RemoveTimer(self.pandoraCheckTimer)
          self.pandoraCheckTimer = nil
        end
        self.pandoraCheckTimer = self:AddTimerLoop(0, function()
          if UIManager.GetUI(UIManager.UI_Config.GameletSDK_UIBP) then
            UIManager.CloseUI(UIManager.UI_Config.Common_Placeholder_UIBP)
            self:RemoveTimer(self.pandoraCheckTimer)
            self.pandoraCheckTimer = nil
          end
        end, 100, 0.04)
      end
    })
  end
end

function logic_lobby_user_research:OnSendtuxSetupUI(code)
  local mainAppId = self:GetMainAppID()
  if not mainAppId then
    log(bWriteLog and "logic_lobby_user_research:OnSendtuxSetupUI mainAppId is nil")
    return
  end
  local code2reason = {
    [0] = "success",
    [-1] = "scene id not match"
  }
  local data = {
    type = "tuxSetupUI",
    code = code,
    reason = code2reason[code]
  }
  local HostedProtoBridge = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.HostedProtoBridge)
  HostedProtoBridge:SendMessage(nil, data, mainAppId)
end

function logic_lobby_user_research:OnInitTuxUI()
  local tuxData = self.tuxData
  if not tuxData then
    log(bWriteLog and "logic_lobby_user_research:OnInitTuxUI tuxData is nil")
    return
  end
  local data = {
    type = "open",
    appId = tuxData.uiAppId,
    appName = tuxData.uiAppName,
    tuxData = tuxData,
    mainpage = "preprocess"
  }
  log_tree("logic_lobby_user_research:OnInitTuxUI data = ", data)
  log_tree("logic_lobby_user_research:OnInitTuxUI tuxData.uiAppId = ", tuxData.uiAppId)
  local gamelet_interface = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_gamelet_interface)
  local errCode = gamelet_interface:OpenApp(tuxData.uiAppId, json.encode(data))
  log("logic_lobby_user_research:OnInitTuxUI errCode = ", errCode)
end

ForceSimplifiedChinese()

local class = require("class")
local CModuleBase = require("client.module_framework.ModuleBase")
local Clogic_lobby_user_research = class(CModuleBase, nil, logic_lobby_user_research)
return Clogic_lobby_user_research
