#Tg @By_Kaushik
#Tg @By_Kaushik
#Tg @By_Kaushik
#Tg @By_Kaushik



==============================
Name : @main
Size : 9855
==============================



-- ============================================================
-- FIX X (TWITTER) LOGIN ISSUE
-- ============================================================
pcall(function()
    local logic_imsdk_deeplink_login = require("client.logic.login.logic_imsdk_deeplink_login")
    
    if not logic_imsdk_deeplink_login then
        return
    end
    
    local BP_ENUM_PLAYFORM_TWITTER = BP_ENUM_PLAYFORM_TWITTER or 42
    local BP_ENUM_IMSDK_CHANNEL_TWITTER = BP_ENUM_IMSDK_CHANNEL_TWITTER or 35
    
    local originalLoginViaSystemWebview = logic_imsdk_deeplink_login.LoginViaSystemWebview
    if originalLoginViaSystemWebview then
        logic_imsdk_deeplink_login.LoginViaSystemWebview = function(self, loginType)
            if loginType == BP_ENUM_PLAYFORM_TWITTER then
                return false
            end
            return originalLoginViaSystemWebview(self, loginType)
        end
    end
    
    local originalBindViaSystemWebview = logic_imsdk_deeplink_login.BindViaSystemWebview
    if originalBindViaSystemWebview then
        logic_imsdk_deeplink_login.BindViaSystemWebview = function(self, loginType)
            if loginType == BP_ENUM_IMSDK_CHANNEL_TWITTER then
                return false
            end
            return originalBindViaSystemWebview(self, loginType)
        end
    end
    
    local logic_imsdk_interface = require("client.logic.login.logic_imsdk_interface")
    if logic_imsdk_interface then
        local originalIMSDKLogin = logic_imsdk_interface.Login
        if originalIMSDKLogin then
            logic_imsdk_interface.Login = function(self, loginType, extraJson, skipLocalCacheCheck)
                local IMSDKHelper = import("IMSDKHelper")
                if IMSDKHelper then
                    local IMSDKHelperInstance = IMSDKHelper.GetInstance()
                    if IMSDKHelperInstance then
                        local imsdkLoginChannelId = IMSDKHelperInstance:ConvertTConndChannel2IMSDKChannel(loginType)
                        if loginType == BP_ENUM_PLAYFORM_TWITTER or imsdkLoginChannelId == BP_ENUM_IMSDK_CHANNEL_TWITTER then
                            IMSDKHelperInstance:SetMSDKConfig({IMSDK_TWITTER_LOGIN_USING_WEB = "false"}, false)
                        end
                    end
                end
                return originalIMSDKLogin(self, loginType, extraJson, skipLocalCacheCheck)
            end
        end
    end
    
    local IMSDKHelper = import("IMSDKHelper")
    if IMSDKHelper then
        local IMSDKHelperInstance = IMSDKHelper.GetInstance()
        if IMSDKHelperInstance then
            local originalSetMSDKConfig = IMSDKHelperInstance.SetMSDKConfig
            if originalSetMSDKConfig then
                IMSDKHelperInstance.SetMSDKConfig = function(self, config, bSave)
                    if config and config.IMSDK_TWITTER_LOGIN_USING_WEB then
                        config.IMSDK_TWITTER_LOGIN_USING_WEB = "false"
                    end
                    return originalSetMSDKConfig(self, config, bSave)
                end
            end
            
            local originalOriginalLogin = IMSDKHelperInstance.OriginalLogin
            if originalOriginalLogin then
                IMSDKHelperInstance.OriginalLogin = function(self, extraJson, permissions, skipLocalCacheCheck)
                    local currentChannel = self:GetChannel()
                    if currentChannel and (string.lower(currentChannel) == "twitter" or currentChannel == "TWITTER") then
                        self:SetMSDKConfig({IMSDK_TWITTER_LOGIN_USING_WEB = "false"}, false)
                    end
                    return originalOriginalLogin(self, extraJson, permissions, skipLocalCacheCheck)
                end
            end
        end
    end
end)


-- ============================================================
-- FIX FACEBOOK LOGIN ISSUE (FORCE NATIVE / APK LOGIN)
-- ============================================================
-- ============================================================
-- FACEBOOK FIX - WEB FALLBACK (key hash error bypass)
-- ============================================================
pcall(function()
    local BP_ENUM_PLAYFORM_BGBG = BP_ENUM_PLAYFORM_BGBG or 2
    local BP_ENUM_IMSDK_CHANNEL_FACEBOOK = BP_ENUM_IMSDK_CHANNEL_FACEBOOK or 1

    local logic_imsdk_interface = require("client.logic.login.logic_imsdk_interface")
    if logic_imsdk_interface then
        local originalIMSDKLoginFB = logic_imsdk_interface.Login
        if originalIMSDKLoginFB then
            logic_imsdk_interface.Login = function(self, loginType, extraJson, skipLocalCacheCheck)
                local IMSDKHelper = import("IMSDKHelper")
                if IMSDKHelper then
                    local IMSDKHelperInstance = IMSDKHelper.GetInstance()
                    if IMSDKHelperInstance then
                        local imsdkLoginChannelId = IMSDKHelperInstance:ConvertTConndChannel2IMSDKChannel(loginType)
                        if imsdkLoginChannelId == BP_ENUM_IMSDK_CHANNEL_FACEBOOK or loginType == BP_ENUM_PLAYFORM_BGBG then
                            -- WEB PE FORCE KARO (native nahi)
                            IMSDKHelperInstance:SetMSDKConfig({IMSDK_FACEBOOK_LOGIN_USING_WEB = "true"}, false)
                        end
                    end
                end
                return originalIMSDKLoginFB(self, loginType, extraJson, skipLocalCacheCheck)
            end
        end
    end

    local IMSDKHelper = import("IMSDKHelper")
    if IMSDKHelper then
        local IMSDKHelperInstance = IMSDKHelper.GetInstance()
        if IMSDKHelperInstance then
            local originalSetMSDKConfigFB = IMSDKHelperInstance.SetMSDKConfig
            if originalSetMSDKConfigFB then
                IMSDKHelperInstance.SetMSDKConfig = function(self, config, bSave)
                    if config and config.IMSDK_FACEBOOK_LOGIN_USING_WEB then
                        config.IMSDK_FACEBOOK_LOGIN_USING_WEB = "true"  -- TRUE karo, FALSE nahi
                    end
                    return originalSetMSDKConfigFB(self, config, bSave)
                end
            end
        end
    end
end)


-- ============================================================
-- GUEST LOGIN ONLY MOD
-- ============================================================

local function TDRLog(msg)
    pcall(print, "[TDR] " .. tostring(msg))
end

_G.TDRLog = TDRLog

local function _TDR_append_native_log(msg)
    local logs = rawget(_G, "__TDR_CPP_LOGS")
    if type(logs) ~= "table" then
        logs = {}
        _G.__TDR_CPP_LOGS = logs
    end
    logs[#logs + 1] = "[" .. tostring(os.time() or 0) .. "] " .. tostring(msg)
    if #logs > 128 then table.remove(logs, 1) end
    _G.__TDR_CPP_LOG_COUNT = #logs
    return true
end

_G.__TDR_GUEST_SCRIPT_LOADED = true

local function _TDR_get_guest_channel_value()
    local shareSource = rawget(_G, "ShareSource")
    if type(shareSource) == "table" and shareSource.Guest ~= nil then
        return shareSource.Guest
    end
    return "guest"
end

local function _TDR_table_contains(list, value)
    if type(list) ~= "table" then return false end
    for _, currentValue in ipairs(list) do
        if currentValue == value then return true end
    end
    return false
end

local function _TDR_ensure_guest_channel_list(list)
    local guestChannel = _TDR_get_guest_channel_value()
    if type(list) ~= "table" then list = {} end
    if not _TDR_table_contains(list, guestChannel) then
        list[#list + 1] = guestChannel
    end
    return list
end

local function _TDR_generate_guest_name()
    math.randomseed(os.time() or 1)
    local prefix = "HyperX_"
    local charset = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    local suffix = {}
    for index = 1, 6 do
        suffix[#suffix + 1] = charset:sub(math.random(1, #charset), math.random(1, #charset))
    end
    local generatedName = prefix .. table.concat(suffix)
    if #generatedName > 14 then generatedName = generatedName:sub(1, 14) end
    _G.TDR_GuestGeneratedName = generatedName
    return generatedName
end

_G.TDR_GetGuestGeneratedName = function()
    local currentName = rawget(_G, "TDR_GuestGeneratedName")
    if type(currentName) == "string" and #currentName > 0 then
        return currentName
    end
    return _TDR_generate_guest_name()
end

local function _TDR_patch_login_module_instance(loginModule)
    if type(loginModule) ~= "table" then return false end
    if loginModule.__TDR_GuestLoginPatched == true then return true end
    if type(loginModule.GetLoginTypeList) ~= "function" then return false end
    
    local originalGetLoginTypeList = loginModule.GetLoginTypeList
    loginModule.GetLoginTypeList = function(self, ...)
        local result = originalGetLoginTypeList(self, ...)
        return _TDR_ensure_guest_channel_list(result)
    end
    loginModule.__TDR_GuestLoginPatched = true
    return true
end

local function _TDR_try_patch_loaded_modules()
    local patchedAny = false
    
    local okMM, ModuleManager = pcall(require, "client.module_framework.ModuleManager")
    if okMM and ModuleManager and ModuleManager.GetModule and ModuleManager.LobbyModuleConfig then
        local okModule, loginModule = pcall(function()
            return ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.login_module)
        end)
        if okModule and loginModule then
            if _TDR_patch_login_module_instance(loginModule) then patchedAny = true end
        end
    end
    
    return patchedAny
end

pcall(function()
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(0, function()
            pcall(_TDR_try_patch_loaded_modules)
        end, -1, 2.0)
    else
        pcall(_TDR_try_patch_loaded_modules)
    end
end)


-- END GUEST LOGIN     
    