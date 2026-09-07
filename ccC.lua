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
