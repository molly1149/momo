local SUPPORTED_PACKAGES = {
    ["com.tencent.ig"]           = "Global",
    ["com.pubg.krmobile"]        = "Korea",
    ["com.vng.pubgmobile"]       = "Vietnam",
    ["com.rekoo.pubgm"]          = "Taiwan",
    ["com.pubg.imobile"]         = "BGMI",
    ["com.pubg.krmobile.ig"]     = "Korea-Alt",
    ["com.tencent.tmgp.pubgmhd"] = "CN",
    ["com.tencent.tmgp.pubgm"]   = "CN-Alt",
}

local packageName = nil
local gameRegion = "Unknown"

pcall(function()
    local KSL = import("KismetSystemLibrary")
    if KSL and KSL.GetGameBundleId then
        packageName = KSL:GetGameBundleId()
    end
end)

if not packageName and io and io.open then
    local probes = {
        "com.tencent.ig", "com.pubg.krmobile", "com.vng.pubgmobile",
        "com.rekoo.pubgm", "com.pubg.imobile", "com.tencent.tmgp.pubgmhd",
        "com.tencent.tmgp.pubgm"
    }
    pcall(function()
        for _, pkg in ipairs(probes) do
            local f = io.open("//storage/emulated/0/Android/data/" .. pkg .. "/", "r")
            if f then f:close() packageName = pkg break end
        end
    end)
end

if not packageName then
    packageName = "com.tencent.ig"
end

gameRegion = SUPPORTED_PACKAGES[packageName] or "Unknown"
pcall(function()
    print("[RJ MOD] Package: " .. packageName .. " (" .. gameRegion .. ")")
end)

local PATHS = {
    PubgData  = "//storage/emulated/0/Android/data/" .. packageName .. "/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/",
    Paks      = nil,
    SaveGames = nil,
    Cache     = nil,
}
PATHS.Paks      = PATHS.PubgData .. "Paks/"
PATHS.SaveGames = PATHS.PubgData .. "SaveGames/"
PATHS.Cache     = PATHS.PubgData .. "image_download_mgr/temporary/Daliy/imgdownload_20713/"

-- =========================================================================
-- [SECTION 1] BRPlayerCharacterBase RPC 声明表
-- =========================================================================
local BRPlayerCharacterBase = { ServerRPC = {}, ClientRPC = {}, MulticastRPC = {} }
BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = { Reliable = true, Params = { UEnums.EPropertyClass.Object } }
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = { Reliable = true, Params = { UEnums.EPropertyClass.Bool } }
BRPlayerCharacterBase.ClientRPC.ClientRPC_TriggerHighlightMoment = { Reliable = true, Params = { UEnums.EPropertyClass.UInt32, UEnums.EPropertyClass.UInt32 } }

-- =========================================================================
-- [SECTION 2] imports / safe helpers / 32bit
-- =========================================================================
local ENetRole = nil
pcall(function() ENetRole = import("ENetRole") end)

local EPawnState = nil
pcall(function() EPawnState = import("EPawnState") end)

local GameplayData = nil
pcall(function() GameplayData = require("GameLua.GameCore.Data.GameplayData") end)

local GamePlayTools = nil
pcall(function() GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools") end)

local function safeRequire(...)
    local ok, result = pcall(require, ...)
    if ok and result then return result end
    return nil
end

local function safeTryModule(paths)
    for _, p in ipairs(paths) do
        local m = safeRequire(p)
        if m then return m, p end
    end
    return nil, nil
end

local function safeImport(name)
    local ok, result = pcall(import, name)
    if ok and result then return result end
    return nil
end

local IS_32BIT = false
pcall(function()
    if jit and jit.arch then
        IS_32BIT = (jit.arch == "x86" or jit.arch == "arm")
    else
        local probe = collectgarbage("count")
        IS_32BIT = (probe > 0 and tostring(2^31) ~= "2147483648")
    end
end)

-- =========================================================================
-- [SECTION 3] AKMOD BYPASS (原 BRPlayerCharacterBase.lua 搬来)
-- =========================================================================
local function AKMOD_INSTALL()
    local function SafeHook(moduleName, funcName, hookFunc)
        pcall(function()
            local mod = package.loaded[moduleName] or (type(_G[moduleName]) == "table" and _G[moduleName])
            if mod and mod[funcName] then
                mod[funcName] = hookFunc
            end
        end)
    end

    -- 1. LobbyHandler: 关 posidon, hades/zeus 回空加密
    pcall(function()
        local LobbyHandler = package.loaded["client.network.Protocol.LobbyHandler"] or _G.LobbyHandler
        if not LobbyHandler then return end

        LobbyHandler.on_posidon_update_ntf = function(res_list) end

        LobbyHandler.on_on_hades_update_ntf = function(check_list)
            pcall(function()
                local magic = "7vu#CH5aJjs1Jjj5"
                local packed_chk_list = slua.LuaArchiverEncode(LuaStateWrapper, {})
                local encrypt_data = Client.Tea2Encrypt(packed_chk_list, magic)
                LobbyHandler.send_on_hades_update_rsp(encrypt_data)
            end)
        end

        LobbyHandler.on_on_zeus_update_ntf = function(check_list, reason)
            pcall(function()
                local magic = "7vu#CH5aJjs1Jjj5"
                local packed_chk_list = slua.LuaArchiverEncode(LuaStateWrapper, {})
                local encrypt_data = Client.Tea2Encrypt(packed_chk_list, magic)
                LobbyHandler.send_on_zeus_update_rsp(encrypt_data, reason)
            end)
        end
    end)

    -- 2. login_module: 关 PakMonitorStart
    pcall(function()
        local login_module = package.loaded["client.logic.login.login_module"]
        if login_module then
            login_module.PakMonitorStart = function(self, EnableMode) end
        end
    end)

    -- 3. Tss + Gokuba + crew_safety
    pcall(function()
        if _G.Tss then
            _G.Tss.GetUserTag4Lua            = function() return "" end
            _G.Tss.GetDeviceFeature          = function() return "VALID_DEVICE" end
            _G.Tss.EigenArrayObfuscationVerify = function() return "VALID" end
            _G.Tss.SendEigeninfoData         = function() return 0 end
            _G.Tss.SaveSendEigeninfoCode     = function() end
        end

        local GokubaLogic = package.loaded["GameLua.Mod.BaseMod.Client.Security.Gokuba"] or _G.GokubaLogic
        if GokubaLogic then
            GokubaLogic.ForwardFeature = function()
                local tbResult = { [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0 }
                if NetUtil and NetUtil.SendPkg then
                    NetUtil.SendPkg("battle_client_sync_allstar_auth_check_result_req", tbResult)
                end
            end
        end

        local crew_safety = package.loaded["client.slua.umg.complaint.crew_safety_detection_base"]
        if crew_safety then
            crew_safety.PerformCheckWithObfuscation = function(self)
                self:SendCheckResult("SAFE_OBFUSCATION")
            end
            crew_safety.PerformCheckWithoutObfuscation = function(self)
                self:SendCheckResult({ [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0 })
            end
        end
    end)

    -- 4. GameplayCallbacks + blacklist NetUtil
    pcall(function()
        local GC = _G.GameplayCallbacks
        if GC then
            local DoNothing = function() end
            GC.ReportPlayerIP                = DoNothing
            GC.SendClientStats               = DoNothing
            GC.ReportPlayerFramePingRecord   = DoNothing
            GC.OnDSConnectionSaturated       = DoNothing
            GC.ReportDSNetSaturation         = DoNothing
            GC.ReportNetContinuousSaturate   = DoNothing
            GC.ReportDSNetRate               = DoNothing
            GC.SendDSErrorLogToLobby         = DoNothing
            GC.SendDSHawkEyePatrolLogToLobby = DoNothing

            GC.SendTssSdkAntiDataToLobby = function(GameID, Uid, Data, DataLen, NetworkStatus)
                if NetUtil and NetUtil.SendPacket then
                    local safeFlow = { ErrorCode = 0, ReportLog = 0 }
                    NetUtil.SendPacket("on_tss_sdk_anti_data", Uid, "", 0, NetworkStatus, safeFlow)
                end
            end
        end

        if _G.NetUtil and not _G.NetUtil._AKHooked then
            local orig_SendPacket = _G.NetUtil.SendPacket
            local orig_SendPkg    = _G.NetUtil.SendPkg
            local Blacklist = {
                ["report_unrealnet_exception"]            = true,
                ["report_dh_calc_key_error"]              = true,
                ["report_client_net_continuous_saturate"] = true,
                ["report_player_ip"]                      = true,
                ["report_unrealnet_clientstats"]          = true,
                ["shutdown_after_error"]                  = true,
                ["report_unrealnet_event"]                = true,
                ["on_tss_sdk_anti_data"]                  = true,
                ["report_tss_sdk_anti_data"]              = true,
            }

            _G.NetUtil.SendPacket = function(msgName, ...)
                if Blacklist[msgName] then return nil end
                return orig_SendPacket(msgName, ...)
            end

            _G.NetUtil.SendPkg = function(msgName, ...)
                if Blacklist[msgName] then return nil end
                return orig_SendPkg(msgName, ...)
            end

            _G.NetUtil._AKHooked = true
        end
    end)

    -- 5. puffer_common: 清空 kick-out list
    pcall(function()
        local puffer_common = package.loaded["client.slua.logic.download.puffer.logic_puffer_common"]
        if puffer_common then
            puffer_common._GetKickOutList   = function() return {} end
            puffer_common.HandleKickOutList = function(hashList) end
        end
    end)

    -- 6. NetUtil: SendTss / OnTssRsp / check_dh_packet_key
    pcall(function()
        if not _G.NetUtil then return end
        if _G.NetUtil._AK_NetUtilHooked then return end
        _G.NetUtil._AK_NetUtilHooked = true

        _G.NetUtil.SendTss  = function() end
        _G.NetUtil.OnTssRsp = function(datalen, data) end

        _G.NetUtil.check_dh_packet_key = function(packet_key, svr_packet_key_md5, from, dh_ext_info, bReportDSInfo) end
    end)

    -- 7. UnrealNet: 关 report exception
    pcall(function()
        if not _G.UnrealNet then return end
        if _G.UnrealNet._AK_UnrealHooked then return end
        _G.UnrealNet._AK_UnrealHooked = true

        local DoNothing = function() end
        _G.UnrealNet.HandleNetworkExceptionReport  = DoNothing
        _G.UnrealNet.HandleNetworkConnectionClosed = DoNothing
        _G.UnrealNet.HandleSpectateException       = DoNothing
        _G.UnrealNet.RepListMismatchDetectTrigger  = DoNothing
        _G.UnrealNet.HandleBattleExceptionReport   = DoNothing
    end)

    -- 8. Tss extra: 关 SendEigeninfo
    pcall(function()
        local _HookRegistry = _G._AKMODPUBG_HookRegistry or {}
        _G._AKMODPUBG_HookRegistry = _HookRegistry

        local function _AKMODPUBG_HOOK(tbl, key, wrapperFactory)
            if type(tbl) ~= "table" then return end
            local orig = tbl[key]
            if orig and _HookRegistry[orig] then return end
            local newFn = wrapperFactory(orig)
            if type(orig) == "function" then
                _HookRegistry[newFn] = _HookRegistry[orig] or orig
            end
            tbl[key] = newFn
        end

        local m = _G.Tss
        if m then
            _AKMODPUBG_HOOK(m, "SendEigeninfo", function() return function() end end)
        end
    end)

    -- 9. NetUtil: OnTick 安全保护 (SendTss 已关)
    pcall(function()
        if not _G.NetUtil then return end
        if _G.NetUtil._AK_OnTickHooked then return end
        _G.NetUtil._AK_OnTickHooked = true
    end)

    -- 10. 二次黑名单 (SendPacket)
    pcall(function()
        if not _G.NetUtil then return end
        if _G.NetUtil._AK_SendPacketHooked then return end
        _G.NetUtil._AK_SendPacketHooked = true

        local orig_SendPacket = _G.NetUtil.SendPacket
        if type(orig_SendPacket) ~= "function" then return end

        local Blacklist2 = {
            ["report_unrealnet_exception"]            = true,
            ["report_dh_calc_key_error"]              = true,
            ["report_client_net_continuous_saturate"] = true,
            ["report_player_ip"]                      = true,
            ["report_unrealnet_clientstats"]          = true,
            ["shutdown_after_error"]                  = true,
            ["report_unrealnet_event"]                = true,
            ["on_tss_sdk_anti_data"]                  = true,
            ["report_tss_sdk_anti_data"]              = true,
        }

        _G.NetUtil.SendPacket = function(msgName, ...)
            if Blacklist2[msgName] then return nil end
            return orig_SendPacket(msgName, ...)
        end
    end)
end

pcall(AKMOD_INSTALL)

pcall(function()
    if _G._AKMOD_TimerStarted then return end
    _G._AKMOD_TimerStarted = true
    local ticker = package.loaded["common.time_ticker"] or require("common.time_ticker")
    if ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(0, function()
            pcall(AKMOD_INSTALL)
        end, -1, 5.0)
    end
end)

-- =========================================================================
-- [SECTION 4] bb.lua 通用 bypass helpers
-- =========================================================================
local function nop()       return true end
local function retFalse()  return false end
local function retZero()   return 0 end
local function retEmpty()  return {} end
local function retTrue()   return true end
local function retEmptyStr() return "" end
local function retNil()    return nil end

local SAFE_KEYWORDS = {
    "bat", "twilight", "transform", "vampire", "hunter", "bloodline",
    "chakra", "jutsu", "naruto", "spider", "kurama", "hero",
    "skill", "ability", "emote", "item", "use", "pickup",
    "vehicle", "weapon", "character", "pawn", "player",
    "revive", "respawn", "death", "damage", "health",
    "attach", "detach", "state", "movement", "camera",
    "animation", "montage", "mesh", "skeletal",
    "chat", "message", "input", "key", "button",
}

local function isSafeName(name)
    if not name then return false end
    local lower = string.lower(tostring(name))
    for _, kw in ipairs(SAFE_KEYWORDS) do
        if string.find(lower, kw, 1, true) then
            return true
        end
    end
    return false
end

_G.RJ_IsSafeName = isSafeName

local function patchModule(module, funcs, replacement)
    if not module then return 0 end
    local count = 0
    pcall(function()
        for _, fn in ipairs(funcs) do
            if type(module[fn]) == "function" and not isSafeName(fn) then
                module[fn] = replacement or nop
                count = count + 1
            end
        end
    end)
    return count
end

-- =========================================================================
-- [SECTION 5] Layer 1-20 bypass
-- =========================================================================

-- === Layer 1: Core Higgs / TSS / ACE ===
local function InitializeCoreBypass()
    pcall(function()
        local TssSdk = _G.TssSdk or package.loaded["TssSdk"]
        if TssSdk then
            for _, k in ipairs({"OnRecvData","SendReportInfo","ReportException","ReportData","UploadLog","SendAntiData","ReportGameStart","ReportGameEnd","ReportCrash","ReportViolation","ReportSuspicious","ReportBan","ReportKick","ReportWarning","ReportInfo","ReportDebug","ReportError","ReportFatal","ReportMemory","ReportProcess","ReportModule","ReportThread","ReportFile","ReportNetwork","ReportDevice","ReportSystem","ReportGame","ReportUser","ReportAccount","ReportSession","ReportPerformance","ReportBattery","ReportTemperature","ReportFPS","ReportPing","ReportPacket","ReportCheat","ReportHack","ReportMod","ReportInject","ReportDebugger","ReportEmulator","ReportRoot","ReportJailbreak","ReportVM","ReportHook","ReportPatch","ReportTamper","ReportCorrupt","ReportInvalid","ReportSpoof","ReportFake","ReportClone","ReportDuplicate","ReportConflict","ReportOverlap","ReportMismatch","ReportInconsistent","ReportUnexpected","ReportUnknown"}) do
                pcall(function() TssSdk[k] = nop end)
            end
            TssSdk.ScanMemory           = retTrue
            TssSdk.IsEmulator           = retFalse
            TssSdk.GetTssSdkReportInfo  = retEmptyStr
            TssSdk.CheckIntegrity       = retTrue
            TssSdk.VerifySignature      = retTrue
            TssSdk.CollectEvidence      = retNil
            TssSdk.GetModuleHash        = function() return "82918E1FE1BE4186CFD2F1286951B2A0" end
            TssSdk.VerifyModule         = retTrue
            TssSdk.ScanProcess          = retEmpty
        end

        local ace = _G.ace or package.loaded["libace.so"]
        if ace then
            patchModule(ace, {"ReportData","ReportViolation","KickPlayer","BanPlayer","SendReport","ReportCheat","ReportHack","ReportMod","ReportInject","ReportHook","ReportPatch","ReportTamper","ReportCorrupt","ReportInvalid","ReportSpoof","ReportFake"})
            ace.CheckIntegrity = retTrue; ace.ScanMemory = retFalse
            ace.VerifyProcess  = retTrue; ace.CheckModule = retTrue
            ace.CollectInfo    = retEmpty; ace.ValidateClient = retTrue
            ace.CheckDebugger  = retFalse; ace.CheckEmulator = retFalse; ace.CheckRoot = retFalse
        end

        local XignCode = _G.XignCode or package.loaded["xigncode"]
        if XignCode then
            patchModule(XignCode, {"SendReport","ReportException","KickPlayer","BanPlayer","ReportCheat","ReportHack","ReportMod","ReportInject","ReportHook","ReportPatch","ReportTamper"})
            XignCode.CheckProcess      = retTrue
            XignCode.VerifyIntegrity   = retTrue
            XignCode.ScanModules       = retEmpty
            XignCode.ValidateMemory    = retTrue
            XignCode.CheckDebugger     = retFalse
            XignCode.EncryptData       = function(d) return d end
            XignCode.DecryptData       = function(d) return d end
        end

        local higgsPaths = {
            "GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent",
            "GameLua.Mod.BaseMod.Common.Security.HiggsBoson",
            "GameLua.Mod.BaseMod.Client.Security.HiggsBosonComponent",
            "Mod.BaseMod.Common.Security.HiggsBosonComponent",
        }
        for _, path in ipairs(higgsPaths) do
            local Higgs = package.loaded[path]
            if not Higgs then
                local ok, m = pcall(require, path)
                if ok then Higgs = m end
            end
            if Higgs then
                Higgs.bIsEnable              = false
                Higgs.bMHActive              = false
                Higgs.bCallPreReplication    = false
                Higgs.StaticShowSecurityAlertInDev = nop
                Higgs.CheckClientConfig      = retFalse
                Higgs.GetSecurityInfo        = retEmpty
                Higgs.ReportSecurityAlert    = nop
                Higgs.ValidateClient         = retTrue
                Higgs.CheckIntegrity         = retTrue
                Higgs.IsMHActive             = retFalse
                Higgs.ControlMHActive        = nop
                Higgs.CheckMHActive          = retFalse
                Higgs.ShouldRunMH            = retFalse
                if Higgs.BlackList then
                    for k in pairs(Higgs.BlackList) do Higgs.BlackList[k] = nil end
                end
                break
            end
        end
        _G.BlackList = {}
    end)
end

-- === Layer 2: SLUA / MD5 / signature ===
local function InitializeSLUA_MD5()
    pcall(function()
        if slua and slua.getSignature then slua.getSignature = function() return 0xDEADBEEF end end
        local loader = package.loaded["slua.loader"] or rawget(_G, "slua_loader")
        if loader then
            loader.verifyBytecode = retTrue
            loader.checkIntegrity = retTrue
            if loader.disableSignatureCheck then loader.disableSignatureCheck = retTrue end
        end
        local slua_serialize = package.loaded["slua.serialize"]
        if slua_serialize then
            slua_serialize.check  = retTrue
            slua_serialize.verify = retTrue
        end
        if jit and jit.attach then jit.attach(function() end, "bc") end
        if _G.slua_verify then _G.slua_verify = retTrue end
        if _G.check_slua_integrity then _G.check_slua_integrity = retTrue end

        local console = safeImport("KismetSystemLibrary")
        if console then
            pcall(function() console.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1") end)
            pcall(function() console.ExecuteConsoleCommand(nil, "pakchunk.EnableSignatureCheck 0") end)
            pcall(function() console.ExecuteConsoleCommand(nil, "s.VerifyPak 0") end)
            pcall(function() console.ExecuteConsoleCommand(nil, "sig.Check 0") end)
            pcall(function() console.ExecuteConsoleCommand(nil, "security.DisableChecks 1") end)
        end
        local CMode = safeImport("CreativeModeBlueprintLibrary")
        if CMode then
            CMode.MD5HashByteArray     = function() return "00000000000000000000000000000000" end
            CMode.MD5HashFile          = function() return "00000000000000000000000000000000" end
            CMode.GetContentDiffData   = function() return true, "BYPASSED" end
            CMode.VerifyFileIntegrity  = retTrue
            CMode.VerifyContent        = retTrue
            CMode.ValidateContent      = retTrue
            CMode.CheckContent         = retTrue
        end
        if _G.MD5Hash  then _G.MD5Hash  = function() return "00000000000000000000000000000000" end end
        if _G.CRC32    then _G.CRC32    = function() return 0 end end
        if _G.SHA1     then _G.SHA1     = function() return "BYPASS" end end
        if _G.SHA256   then _G.SHA256   = function() return "BYPASSED_SHA256" end end
        local FileHashChecker = package.loaded["common.file_hash_checker"]
        if FileHashChecker then
            FileHashChecker.CheckFileMD5 = retTrue
            FileHashChecker.VerifyAll    = retTrue
            FileHashChecker.GetHash      = function() return "BYPASS" end
        end
        local STExtra = safeImport("STExtraBlueprintFunctionLibrary")
        if STExtra then
            STExtra.CheckMD5              = retTrue
            STExtra.GetMD5                = function() return "BYPASS" end
            STExtra.VerifyFile            = retTrue
            STExtra.IsDevelopment         = retFalse
            STExtra.CheckFileIntegrity    = retTrue
        end
    end)
end

-- === Layer 3: Log / Screenshot / Crash ===
local function InitializeLogBlocker()
    pcall(function()
        local SMTD = safeImport("ScreenshotMTDer")
        if SMTD then
            SMTD.MTDePicture    = retEmptyStr
            SMTD.ReMTDePicture  = retEmptyStr
            SMTD.HasCaptured    = retTrue
            SMTD.TakeScreenshot = nop
        end
        local SM = safeImport("ScreenshotMaker")
        if SM then
            SM.MakePicture     = retEmptyStr
            SM.ReMakePicture   = retEmptyStr
            SM.HasCaptured     = retTrue
            SM.TakeScreenshot  = nop
            SM.SaveScreenshot  = nop
            SM.CaptureScreen   = nop
            SM.RecordScreen    = nop
        end
        local TLog = package.loaded["TLog"] or _G.TLog
        if TLog then
            patchModule(TLog, {"Info","Warning","Error","Debug","Report","Send","Flush","Log","LogWarning","LogError","LogVerbose","SetLogLevel"})
        end
        local CrashSight = package.loaded["CrashSight"] or _G.CrashSight
        if CrashSight then
            patchModule(CrashSight, {"ReportException","SetCustomData","Log","SendCrash","ReportUserException","UploadLog","SendReport","ReportCrash","ReportError","ReportFatal","ReportWarning","ReportInfo","ReportDebug","ReportMemory","ReportPerformance"})
            CrashSight.CollectInfo = retEmpty
        end

        local grPaths = {
            "GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils",
            "GameLua.Mod.BaseMod.Gameplay.GameReport.GameReportUtils",
        }
        local GRUtils = safeTryModule(grPaths)
        if GRUtils then
            GRUtils.BugglyPostExceptionFull      = retFalse
            GRUtils.CheckCanBugglyPostException  = retFalse
            GRUtils.ReplayReportData             = nop
            GRUtils.ReportGameException          = nop
            GRUtils.PostException                = nop
        end
        local CTR = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if CTR then CTR.SendReport = nop; CTR.SendException = nop; CTR.UploadLog = nop end
        local tlog = package.loaded["client.slua.config.tlog.tlog_report_utils"]
        if tlog then tlog.ReportTLogEvent = nop end

        local Logging = safeImport("Logging")
        if Logging then
            patchModule(Logging, {"Log","LogWarning","LogError","LogVerbose","SetLogLevel","LogInfo","LogDebug","LogTrace","LogFatal","LogPanic"})
        end
    end)
end

-- === Layer 4: Universal subsystem killer ===
local function InitializeScannerBlocker()
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if not SubMgr then return end

        local toKill = {
            "AFKReportorSubsystem","ClientDataStatistcsSubsystem","AvatarExceptionSubsystem",
            "ShootVerifySubSystemClient","MemoryCheckSubsystem","SpeedCheckSubsystem",
            "WallCheckSubsystem","FileCheckSubsystem","BehaviorScoreSubsystem",
            "CoronaLabSubsystem","PlayerSecurityInfoSubsystem","ClientCircleFlowSubsystem",
            "ModifierExceptionSubsystem","SimulateCharacterSubsystem",
            "ClientReportPlayerSubsystem","DSReportPlayerSubsystem",
            "ClientHawkEyePatrolSubsystem","DSHawkEyePatrolSubsystem",
            "GameReportSubsystem","ClientSecMrpcsFlowSubsystem","MrpcsFlowSubsystem",
            "CircleFlowSubsystem","SwiftHawkSubsystem","AntiCheatSubsystem",
            "IntegrityCheckSubsystem","SignatureVerifySubsystem","MD5CheckSubsystem",
            "PakVerifySubsystem","ClientKernelCheckSubsystem","ClientMemoryGuardSubsystem",
            "ClientWallhackDetectionSubsystem","ClientESPDetectionSubsystem",
            "ClientAimTrackingSubsystem","ClientRenderCheckSubsystem",
            "TssSdkSubsystem","AnogsSubsystem","ACEAntiCheatSubsystem",
            "MemoryProtectSubsystem","AntiDebugSubsystem","SafeGuardSubsystem",
            "ReportSystemSubsystem","PlayerBehaviorSubsystem",
        }

        for _, name in ipairs(toKill) do
            if not isSafeName(name) then
                pcall(function()
                    local sub = SubMgr:Get(name)
                    if sub then
                        for k, v in pairs(sub) do
                            if not isSafeName(k) then
                                if type(v) == "function" then
                                    pcall(function() sub[k] = nop end)
                                elseif type(v) == "number" then
                                    pcall(function() sub[k] = 0 end)
                                elseif type(v) == "boolean" then
                                    pcall(function() sub[k] = false end)
                                end
                            end
                        end
                        if sub.ReportPingDelayTimer then
                            pcall(function() sub:RemoveGameTimer(sub.ReportPingDelayTimer) end)
                            sub.ReportPingDelayTimer = nil
                        end
                    end
                end)
            end
        end

        local AvaEx = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
        if AvaEx then
            AvaEx.CheckAvatarException      = nop
            AvaEx.CheckAvatarExceptionOnce  = nop
            AvaEx.ReportAvatarException     = nop
            AvaEx.CheckSlotMeshVisible      = retFalse
            AvaEx.CheckPawnVisible          = retFalse
            AvaEx.CheckCanBugglyPostException = retFalse
        end
        local AvatarUtils = package.loaded["AvatarUtils"]
        if AvatarUtils then
            AvatarUtils.CheckIsWeaponInBlackList = retFalse
            AvatarUtils.IsValidAvatar            = retTrue
            AvatarUtils.CheckAvatarIntegrity     = retTrue
            AvatarUtils.ReportInvalidAvatar      = nop
        end
    end)
end

-- === Layer 5: Universal report blocker ===
local function InitializeReportBlocker()
    pcall(function()
        local reportPaths = {
            "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem",
            "client.slua.logic.report.EquipmentExceptionReport",
            "client.slua.logic.report.ClientToolsReport",
            "GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils",
            "client.slua.logic.download.report.puffer_tlog",
            "GameLua.Mod.BaseMod.Client.Security.ClientGlueHiaSystem",
            "GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils",
            "GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature",
            "client.slua.logic.ban.ClientBanLogic",
            "client.slua.logic.login.logic_tt_ban",
            "GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSAITLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem",
            "GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.InspectionSystemReportDSLogicSubsystem",
            "GameLua.Mod.BaseMod.Common.Subsystem.SpectateAndReplaySubsystem",
            "GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem",
            "GameLua.Mod.Escape.Gameplay.Subsystem.BehaviorScoreSubsystem",
            "GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem",
            "GameLua.Mod.BaseMod.GamePlay.AI.AITrackingLogSubsystem",
            "GameLua.Mod.TDM.Gameplay.Subsystem.TDMAFKReportorSubsystem",
        }
        local blockFuncs = {
            "Report","SendReport","ReportEvent","ReportException","ReportData","ReportTLogEvent",
            "OnInit","_OnPlayerKilledOtherPlayer","_RecordFatalDamager","_OnBattleResult",
            "_OnShowQuickReportMutualExclusiveUI","_AddEnemyMapToBattleResult","_AddKnockDownerToBattleResult",
            "_AddKillerToBattleResult","_AddTeammateMurderToBattleResult","_AddFatalDamagerMapToBattleResult",
            "_AddMLKillerUIDToBattleResult","_SaveHistoricalTeammateInfo","_RecordTeammateMurderer",
            "_OnNearDeathOrRescued","_OnCharacterDied","_OnTeammateDamage","_OnPlayerSettlementStart",
            "_OnHawkSync","_OnHawkReportSuccess","_StartExitGameTimer","OnHandleBehaviorScore","AIPerceptionScore",
            "ReportAllPlayerInfo","AddRecordMLAIInfo","ReportAI","RealLogoutTimer","SendAFKTips",
            "OnHandleLostConnection","ClientRPC_SyncBanID","ClientRPC_StrongTips","ClientRPC_NormalTips",
            "Notify","OnSyncBanInfo","OnVoiceBanNotify","DelayKickOutPlayer","ActiveKickNotify",
            "_UpdateTTKRecords","_UpdateOperatingFrequency","_OnReportServerJumpFlow","HandleKillTlog",
            "AskForInspector","ReportEnemy","KickOutOneTeam","ServerKickOutOneTeamByPlayerImplementation",
            "AddReportedCount","RequestGotoSpectatingImp","RequestGotoSpectating"
        }
        for _, path in ipairs(reportPaths) do
            local module = package.loaded[path]
            if not module then
                local ok, r = pcall(require, path)
                if ok then module = r end
            end
            if module then
                patchModule(module, blockFuncs)
                if module.GetCarrierInfo       then module.GetCarrierInfo       = function() return "[{\"mcc\":\"000\"}]" end end
                if module.CheckIfCanCreateRole then module.CheckIfCanCreateRole = retTrue end
                if module.GetSimpleFightData   then module.GetSimpleFightData   = retEmpty end
                if module.LogQueue             then module.LogQueue             = {} end
            end
        end

        if NetUtil and NetUtil.SendPacket then
            local originalSend = NetUtil.SendPacket
            local blocked = {}
            for _, p in ipairs({
                "ReportAttackFlow","ReportSecAttackFlow","ReportHurtFlow","ReportFireArms","ReportVerifyInfoFlow","ReportMrpcsFlow",
                "ReportPlayerBehavior","ReportTeammatHurt","ReportTeammateKillConfirmFlow","ReportForbiddenPickupFlow",
                "ReportPlayerMoveRoute","ReportPlayerPosition","ReportSecVehicleMoveFlow","ReportSecTgameMovingFlow",
                "report_parachute_data","on_tss_sdk_anti_data","report_unrealnet_exception","ReportPlayerEquipmentInfo",
                "ReportAimFlow","ReportHitFlow","log_shooting_miss","report_heavy_weapon_box_activation_flow",
                "report_heavy_weapon_box_item_flow","ReportCircleFlow","report_ds_player_circle_flow","ReportJumpFlow",
                "ReportGameStartFlow","ReportGameEndFlow","report_players_ping","report_player_ip","report_player_frame_ping_record",
                "report_net_saturate","report_ds_netsaturate","report_ds_net_continuous_saturate","report_ds_netrate",
                "report_unrealnet_clientstats","report_serverstat_avgtickdelta","report_all_players_address",
                "report_ai_strategyinfo","ReportAIActionFlow","ReportGenerateMonsterFlow","report_ds_match_room_data",
                "SendSpectatingLog","ReportIDCardProduceFlow","ReportIDCardPickUpFlow","ReportIDCardDestroyFlow",
                "ReportRevivalFlow","ReportGameSetting","ReportGameSettingNew","ReportAntsVoiceTeamCreate","ReportAntsVoiceTeamQuit",
                "report_common_info","report_common_battle_info","report_client_scan_result","tss_sdk_report",
                "report_memory_exception","report_avatar_exception","report_ui_state","report_hit_reg_fail",
                "report_character_state","report_vehicle_exception","report_camera_exception",
                "ReportPlayerControllerStateChanged","ReportAvatarFlow","ReportSecurityAlert","ReportAntiCheat",
                "ReportSuspiciousActivity","ReportViolation","ReportBan","ReportKick","ReportCheat","ReportHack",
                "ReportMod","ReportInject","ReportHook","ReportPatch","ReportTamper","ReportCorrupt","ReportInvalid",
                "ReportSpoof","ReportFake","ReportClone","ReportDuplicate","ReportConflict","ReportOverlap",
                "ReportMismatch","ReportInconsistent","ReportUnexpected","ReportUnknown",
                "ClientSecMrpcsFlow","MrpcsData","CheckReportSecAttackFlow","CheckReportSecAttackFlowWithAttackFlow",
                "RPC_ClientCoronaLab","CoronaLabReport","CoronaLabData","PlayerSecurityInfo","ReportSecurityInfo",
                "SendSecurityData","ClientCircleFlow","BulletHitInfoUploadData","ShootVerifyFailed","SwiftHawk",
                "ClientSwiftHawk","ClientSwiftHawkWithParams","SwiftHawkReport","SwiftHawkData",
                "AntiCheatReport","CheatDetection","ViolationReport","SecurityViolation","IntegrityCheck","SignatureVerify"
            }) do blocked[p] = true end
            NetUtil.SendPacket = function(packetName, ...)
                if blocked[packetName] then return nil end
                return originalSend(packetName, ...)
            end
            NetUtil.IsBypassed = true
        end
        if _G.SendRPC then
            local origRPC = _G.SendRPC
            local blockedRPC = {"RPC_Server_ClientSecMrpcsFlow","RPC_Server_SwiftHawk","RPC_Server_ClientSwiftHawkWithParams","RPC_Server_ReportSimulateCharacterLocation","RPC_Client_ShootVertifyRes","RPC_ClientCoronaLab"}
            _G.SendRPC = function(rpcName, ...)
                for _, b in ipairs(blockedRPC) do
                    if rpcName == b then return nil end
                end
                return origRPC(rpcName, ...)
            end
        end
    end)
end

-- === Layer 6: Gameplay callbacks ===
local function InitializeGameplayBypass()
    pcall(function()
        if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end
        if _G.GameplayCallbacks.IsBypassed then return end
        local GC = _G.GameplayCallbacks
        local reports = {
            "ReportAttackFlow","ReportSecAttackFlow","ReportHurtFlow","ReportFireArms","ReportVerifyInfoFlow",
            "ReportMrpcsFlow","ReportPlayerBehavior","ReportTeammatHurt","ReportMisKillByTeammate","ReportForbitPick",
            "ReportPlayerMoveRoute","ReportPlayerPosition","ReportVehicleMoveFlow","ReportSecTgameMovingFlow",
            "ReportParachuteData","SendTssSdkAntiDataToLobby","SendDSErrorLogToLobby","SendDSErrorLogToLobbyOnece",
            "SendDSHawkEyePatrolLogToLobby","ReportEquipmentFlow","ReportAimFlow","ReportHitFlow",
            "ReportHeavyWeaponBoxSpawnFlow","ReportHeavyWeaponBoxActivationFlow","ReportHeavyWeaponBoxOpenPlayerFlow",
            "ReportHeavyWeaponBoxItemFlow","ReportPlayersPing","ReportPlayerIP","ReportPlayerFramePingRecord",
            "OnDSConnectionSaturated","ReportDSNetSaturation","ReportNetContinuousSaturate","ReportDSNetRate",
            "SendClientStats","SendServerAvgTickDelta","ReportCircleFlow","ReportDSCircleFlow","ReportJumpFlow",
            "ReportAIStrategyInfo","SendAIDeliveryInfo","ReportDailyTaskInfo","ReportMatchRoomData",
            "SendPlayerSpectatingLog","ReportIDCardProduceFlow","ReportIDCardPickUpFlow","ReportIDCardDestroyFlow",
            "ReportRevivalFlow","ReportGameSetting","ReportGameSettingNew","ReportAntsVoiceTeamCreate",
            "ReportAntsVoiceTeamQuit","ReportCommonInfo","ReportLightweightStat","SendSecTLog",
            "SendDataMiningTLog","SendActivityTLog","OnPlayerNetConnectionClosed","OnPlayerActorChannelError",
            "OnPlayerRPCValidateFailed","OnPlayerSpectateException","OnShutdownAfterError",
            "ClientSecMrpcsFlow","SwiftHawk","ClientSwiftHawk","ClientSwiftHawkWithParams"
        }
        for _, f in ipairs(reports) do
            if not isSafeName(f) then
                GC[f] = nop
            end
        end
        GC.GetWeaponReport                     = retEmpty
        GC.GetOneWeaponReport                  = retEmpty
        GC.GetGeneralTLogData                  = retEmpty
        GC.CheckReportSecAttackFlowWithAttackFlow = retFalse
        GC.CheckReportSecAttackFlow            = retFalse
        GC.OnDSPlayerStateChanged = function(UID, State, bPure, bSafe, Param)
            local s = State and string.lower(tostring(State)) or ""
            local blocked = {["cheatdetected"]=1,["connectionlost"]=1,["connectiontimeout"]=1,["connectionexception"]=1,
                            ["netdrivererror"]=1,["banned"]=1,["kicked"]=1,["suspended"]=1,
                            ["violationdetected"]=1,["integrityfailure"]=1,["securityviolation"]=1}
            if blocked[s] then return end
        end
        GC.IsBypassed = true
    end)
end

-- === Layer 7: Universal Memory Patcher ===
local function AntiCheatKillerUniversal()
    pcall(function()
        if not Memory or not Memory.FindBase or not Memory.NopCode then return end

        local OffsetSets = {
            { lib = "libUE4.so",   offs = {0x4A3B000, 0x4A3B010, 0x4A3B020}, size = 8 },
            { lib = "libanogs.so", offs = {0x1A3C0, 0x1A3D0, 0x1A400},       size = 16 },
            { lib = "libtdata.so", offs = {0x2F000, 0x2F010},                 size = 16 },
            { lib = "libUE4.so",   offs = {0x4B3C000, 0x4B3C010},             size = 8 },
            { lib = "libanogs.so", offs = {0x1B3C0, 0x1B3D0},                 size = 16 },
            { lib = "libUE4.so",   offs = {0x4C3D000, 0x4C3D010},             size = 8 },
            { lib = "libanogs.so", offs = {0x1C3C0, 0x1C3D0},                 size = 16 },
        }

        for _, entry in ipairs(OffsetSets) do
            pcall(function()
                local lib = Memory.FindBase(entry.lib)
                if lib and lib > 0 then
                    for _, off in ipairs(entry.offs) do
                        pcall(function() Memory.NopCode(lib + off, entry.size) end)
                    end
                end
            end)
        end
    end)
end

-- === Layer 8: TFLite AI bypass ===
local function TFLiteAIBypass()
    pcall(function()
        if _G.tflite then
            _G.tflite.Invoke    = retEmpty
            _G.tflite.RunModel  = retTrue
            _G.tflite.LoadModel = retTrue
        end
        if _G.NeuralNet then
            _G.NeuralNet.Predict = retZero
            _G.NeuralNet.Analyze = retEmpty
            _G.NeuralNet.Detect  = retFalse
        end
    end)
end

-- === Layer 9: Behavioral analysis bypass ===
local function BehavioralBypass()
    pcall(function()
        if _G.AimPatternAnalyzer then
            _G.AimPatternAnalyzer.Analyze          = retEmpty
            _G.AimPatternAnalyzer.DetectAimbot     = retFalse
            _G.AimPatternAnalyzer.GetPatternScore  = retZero
        end
        if _G.MovementAnalyzer then
            _G.MovementAnalyzer.Analyze            = retEmpty
            _G.MovementAnalyzer.DetectSpeedHack    = retFalse
            _G.MovementAnalyzer.DetectTeleport     = retFalse
        end
        if _G.ShootPatternAnalyzer then
            _G.ShootPatternAnalyzer.Analyze        = retEmpty
            _G.ShootPatternAnalyzer.DetectRecoil   = retFalse
            _G.ShootPatternAnalyzer.DetectNoRecoil = retFalse
        end
        if _G.KillPatternAnalyzer then
            _G.KillPatternAnalyzer.Analyze              = retEmpty
            _G.KillPatternAnalyzer.DetectHeadshotRatio  = retZero
            _G.KillPatternAnalyzer.DetectSuspiciousKills = retFalse
        end
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) then
            if pc.BehaviorScore  then pc.BehaviorScore  = 100 end
            if pc.AimScore       then pc.AimScore       = 100 end
            if pc.MovementScore  then pc.MovementScore  = 100 end
            if pc.ShootScore     then pc.ShootScore     = 100 end
            if pc.KillScore      then pc.KillScore      = 100 end
            if pc.SuspicionScore then pc.SuspicionScore = 0   end
        end
    end)
end

-- === Layer 10: Server validation bypass ===
local function ServerValidationBypass()
    pcall(function()
        for _, name in ipairs({"ServerPosValidator","ServerDamageValidator","ServerShootValidator","ServerMoveValidator","RPCValidator"}) do
            local v = _G[name]
            if v then
                v.Validate = retTrue
                v.Check    = retTrue
                v.Report   = nop
            end
        end
        if NetUtil and NetUtil.ValidatePacket then NetUtil.ValidatePacket = retTrue end
    end)
end

-- === Layer 11: ML model bypass ===
local function MLBypass()
    pcall(function()
        for _, m in ipairs({"AimbotDetectionModel","ESPDDetectionModel","SpeedHackDetectionModel","WallHackDetectionModel","MagicBulletDetectionModel","NoRecoilDetectionModel","TeleportDetectionModel","FlyHackDetectionModel"}) do
            local model = _G[m]
            if model then
                model.Predict = retZero
                model.Analyze = retEmpty
                model.Detect  = retFalse
                model.Load    = retTrue
                model.Run     = retEmpty
            end
        end
    end)
end

-- === Layer 12: Memory integrity bypass ===
local function MemoryIntegrityBypass()
    pcall(function()
        if _G.MemoryHash then
            _G.MemoryHash.Calculate = function() return "BYPASSED" end
            _G.MemoryHash.Verify    = retTrue
            _G.MemoryHash.Check     = retTrue
        end
        if _G.MemoryDumpDetector then
            _G.MemoryDumpDetector.Detect = retFalse
            _G.MemoryDumpDetector.Check  = retFalse
            _G.MemoryDumpDetector.Report = nop
        end
        if _G.MemoryScanDetector then
            _G.MemoryScanDetector.Detect = retFalse
            _G.MemoryScanDetector.Check  = retFalse
            _G.MemoryScanDetector.Report = nop
        end
        if _G.MemoryModDetector then
            _G.MemoryModDetector.Detect = retFalse
            _G.MemoryModDetector.Check  = retFalse
            _G.MemoryModDetector.Report = nop
        end
    end)
end

-- === Layer 13: Cloud AI / analytics bypass ===
local function CloudAIBypass()
    pcall(function()
        for _, name in ipairs({"CloudUpload","CloudAnalyzer","DataCollector","Telemetry"}) do
            local v = _G[name]
            if v then
                for k, val in pairs(v) do
                    if type(val) == "function" then v[k] = nop end
                end
            end
        end
        if _G.Firebase then
            _G.Firebase.logEvent                      = nop
            _G.Firebase.setUserProperty               = nop
            _G.Firebase.setAnalyticsCollectionEnabled = nop
        end
        for _, sdk in ipairs({"Adjust","AppsFlyer","FacebookAnalytics","GameAnalytics","GoogleAnalytics"}) do
            local s = _G[sdk]
            if s then
                for k, val in pairs(s) do
                    if type(val) == "function" then
                        pcall(function() s[k] = nop end)
                    end
                end
            end
        end
    end)
end

-- === Layer 14: Packet encryption bypass ===
local function PacketEncryptionBypass()
    pcall(function()
        for _, name in ipairs({"AES","RSA","ECC","ChaCha20","PacketEncrypt"}) do
            local v = _G[name]
            if v then
                v.Encrypt = function(d) return d end
                v.Decrypt = function(d) return d end
                if v.GenerateKey then v.GenerateKey = function() return "BYPASSED" end end
            end
        end
    end)
end

-- === Layer 15: Kernel / hardware / neural / quantum ===
local function AdvancedBypasses()
    pcall(function()
        for _, name in ipairs({"KernelModuleDetector","PtraceDetector","SeccompDetector"}) do
            local v = _G[name]
            if v then
                v.Detect = retFalse
                v.Check  = retFalse
            end
        end
        if _G.SyscallHook then _G.SyscallHook.Detect = retFalse; _G.SyscallHook.Check = retTrue end

        for _, name in ipairs({"CPUSerial","GPUSerial","DiskSerial"}) do
            local v = _G[name]
            if v then
                v.Get  = function() return "BYPASSED" end
                v.Read = function() return "BYPASSED" end
            end
        end
        if _G.NetworkInterface then
            _G.NetworkInterface.GetMAC = function() return "00:00:00:00:00:00" end
            _G.NetworkInterface.GetIP  = function() return "127.0.0.1" end
        end
        if _G.TEEDetector   then _G.TEEDetector.Detect = retFalse; _G.TEEDetector.Check = retFalse end
        if _G.SecureBoot    then _G.SecureBoot.Check = retTrue;   _G.SecureBoot.Get = retTrue   end
        if _G.HardwareAttestation then
            _G.HardwareAttestation.Attest = function() return "BYPASSED" end
            _G.HardwareAttestation.Verify = retTrue
        end

        for _, m in ipairs({"AimbotNN","ESPNN","WallHackNN","SpeedHackNN","MagicBulletNN","NoRecoilNN"}) do
            local v = _G[m]
            if v then
                v.Predict = retZero
                v.Analyze = retEmpty
                v.Detect  = retFalse
            end
        end

        for _, name in ipairs({"Kyber","Dilithium","Falcon","SPHINCS","LatticeCrypto","HashBasedSignature"}) do
            local v = _G[name]
            if v then
                v.Encapsulate = function() return {}, {} end
                v.Decapsulate = retEmpty
                v.Sign        = function() return {} end
                v.Verify      = retTrue
                v.Encrypt     = function(d) return d end
                v.Decrypt     = function(d) return d end
            end
        end
    end)
end

-- === Layer 16: Device spoofing ===
local function AntiBanSpoof()
    pcall(function()
        local SystemInfo = safeImport("SystemInfo")
        if SystemInfo then
            SystemInfo.GetDeviceModel       = function() return "iPhone14,5" end
            SystemInfo.GetDeviceBrand       = function() return "Apple" end
            SystemInfo.GetAndroidVersion    = function() return "13" end
            SystemInfo.GetEMUIVersion       = retEmptyStr
            SystemInfo.IsEmulator           = retFalse
            SystemInfo.IsRooted             = retFalse
            SystemInfo.IsDebugged           = retFalse
            SystemInfo.GetKernelVersion     = function() return "Linux version 4.14.116" end
            SystemInfo.CheckKernelIntegrity = retTrue
            SystemInfo.GetDeviceID          = function() return "00000000-0000-0000-0000-000000000000" end
        end
        local DeviceID = safeImport("DeviceID")
        if DeviceID then
            DeviceID.GetDeviceID           = function() return "BYPASSED_DEVICE" end
            DeviceID.GetAndroidID          = function() return "BYPASSED_ANDROID_ID" end
            DeviceID.GetIMEI               = function() return "BYPASSED_IMEI" end
            DeviceID.GetMACAddress         = function() return "BYPASSED_MAC" end
            DeviceID.GetUniqueDeviceID     = function() return "BYPASSED_UNIQUE" end
            DeviceID.GetDeviceName         = function() return "BYPASSED_NAME" end
            DeviceID.GetDeviceModel        = function() return "BYPASSED_MODEL" end
            DeviceID.GetDeviceBrand        = function() return "BYPASSED_BRAND" end
            DeviceID.GetDeviceManufacturer = function() return "BYPASSED_MANUF" end
            DeviceID.GetDeviceSerial       = function() return "BYPASSED_SERIAL" end
        end
    end)
end

-- === Layer 17: Material Evasion ===
local function MaterialEvasionBypass()
    pcall(function()
        local UMaterial               = safeImport("Material")
        local UMaterialInstance       = safeImport("MaterialInstance")
        local UMaterialInstanceDynamic = safeImport("MaterialInstanceDynamic")
        local UPrimitiveComponent     = safeImport("PrimitiveComponent")
        local UMeshComponent          = safeImport("MeshComponent")

        if UMaterial then
            UMaterial.GetDisableDepthTest = retFalse
            UMaterial.GetBlendMode        = retZero
            UMaterial.GetMaterialHash     = function() return "FAKE_HASH" end
            UMaterial.VerifyMaterial      = retTrue
        end
        if UMaterialInstance then
            UMaterialInstance.GetDisableDepthTest = retFalse
            UMaterialInstance.GetBlendMode        = retZero
            UMaterialInstance.GetBaseMaterial     = retNil
        end
        if UMaterialInstanceDynamic then
            local oldVec = UMaterialInstanceDynamic.K2_GetVectorParameterValue
            UMaterialInstanceDynamic.K2_GetVectorParameterValue = function(self, name)
                local n = tostring(name)
                if n:find("Color") or n:find("Emissive") then return {R=0,G=255,B=255,A=255} end
                return oldVec(self, name)
            end
            local oldScal = UMaterialInstanceDynamic.K2_GetScalarParameterValue
            UMaterialInstanceDynamic.K2_GetScalarParameterValue = function(self, name)
                if tostring(name):find("Emissive") then return 0.0 end
                return oldScal(self, name)
            end
            UMaterialInstanceDynamic.GetFullName = function() return "DefaultMaterial" end
        end
        if UPrimitiveComponent then
            UPrimitiveComponent.IsRenderedOnCustomDepth          = retFalse
            UPrimitiveComponent.GetRenderCustomDepth             = retFalse
            UPrimitiveComponent.GetCustomDepthStencilValue       = retZero
            UPrimitiveComponent.GetCustomDepthStencilWriteMask   = retZero
            UPrimitiveComponent.GetVisibleFlag                   = retTrue
        end
        if UMeshComponent then
            UMeshComponent.ShouldRender      = retTrue
            UMeshComponent.GetShouldRender   = retTrue
            UMeshComponent.IsVisible         = retTrue
        end
        local UObject = safeImport("Object")
        if UObject and UObject.GetObjectsOfClass then
            local oldGet = UObject.GetObjectsOfClass
            UObject.GetObjectsOfClass = function(Class, IncludeDerived)
                if Class and tostring(Class):find("MaterialInstanceDynamic") then return {} end
                return oldGet(Class, IncludeDerived)
            end
        end
    end)
end

-- === Layer 18: Aimbot Detection Bypass ===
local function AimbotDetectionBypass()
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            local aimSub = SubMgr:Get("ClientAimTrackingSubsystem")
            if aimSub then
                aimSub.GetAimData = function(self)
                    return {
                        accuracy     = math.random(40, 60),
                        headshotRate = math.random(10, 25),
                        trackingTime = math.random(100, 300),
                        aimLockCount = 0
                    }
                end
                for _, fn in ipairs({"ReportAimData","SendAimStats","UploadAimInfo"}) do
                    if aimSub[fn] then aimSub[fn] = nop end
                end
            end
        end

        local PlayerController = safeImport("PlayerController")
        if PlayerController then
            local origAddYaw = PlayerController.AddYawInput
            if origAddYaw then
                PlayerController.AddYawInput = function(self, Val)
                    if self == slua_GameFrontendHUD:GetPlayerController() then
                        Val = Val + (math.random() - 0.5) * 0.5
                    end
                    return origAddYaw(self, Val)
                end
            end
            local origAddPitch = PlayerController.AddPitchInput
            if origAddPitch then
                PlayerController.AddPitchInput = function(self, Val)
                    if self == slua_GameFrontendHUD:GetPlayerController() then
                        Val = Val + (math.random() - 0.5) * 0.5
                    end
                    return origAddPitch(self, Val)
                end
            end
        end

        local Actor = safeImport("Actor")
        if Actor and Actor.GetBoneName then
            local origGetBone = Actor.GetBoneName
            Actor.GetBoneName = function(self, index)
                local name = origGetBone(self, index)
                if tostring(name):find("neck") then
                    local rand = math.random(1, 3)
                    if rand == 1 then return "head_01"
                    elseif rand == 2 then return "spine_02"
                    end
                end
                return name
            end
        end
    end)
end

-- === Layer 19: Runtime Signature Masking ===
local function RuntimeSignatureMasking()
    pcall(function()
        local localPlayer = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController() and slua_GameFrontendHUD:GetPlayerController():GetPlayerCharacterSafety()
        if slua.isValid(localPlayer) and slua.isValid(localPlayer.AutoAimComp) then
            local autoAim = localPlayer.AutoAimComp
            if autoAim.AimAssistConfig then
                local temp = autoAim.AimAssistConfig.HeadPriority
                autoAim.AimAssistConfig.HeadPriority  = autoAim.AimAssistConfig.ChestPriority
                autoAim.AimAssistConfig.ChestPriority = temp
            end
            local fakeBones = {"Head", "Spine_01", "Pelvis"}
            if autoAim.HeadBoneName then
                local oldBone = autoAim.HeadBoneName
                local newBone = fakeBones[math.random(1, 3)]
                autoAim.HeadBoneName = newBone
                pcall(function() autoAim.Bones = {newBone, oldBone} end)
            end
            if autoAim.InnerRange then autoAim.InnerRange.Speed = math.random(2, 15) end
            if autoAim.OuterRange then autoAim.OuterRange.Speed = math.random(2, 15) end
        end
    end)
end

-- === Layer 20: Aggressive Dynamic Reset ===
local function AggressiveReset()
    pcall(function()
        local CHiggs = _G.CHiggsBosonComponent
        if CHiggs then
            CHiggs.bMHActive                    = false
            CHiggs.bCallPreReplication          = false
            CHiggs.bSkipAlertServer             = true
            CHiggs._ProcessReportChatRobotQueue = nop
            CHiggs.RPC_Client_ShowSecurityAlertWindow = nop
            CHiggs.RPC_Server_TellServerName    = nop
            if CHiggs.ControlMHActive then
                CHiggs.ControlMHActive = function(self) self.bMHActive = false end
            end
        end

        if _G.PlayerSecurityInfoCollector then
            _G.PlayerSecurityInfoCollector.ReportData   = nop
            _G.PlayerSecurityInfoCollector.SendToServer = nop
            _G.PlayerSecurityInfoCollector.CollectData  = nop
        end

        if _G.ClientHawkEyePatrolSubsystem then
            _G.ClientHawkEyePatrolSubsystem._bHasReported    = true
            _G.ClientHawkEyePatrolSubsystem._bHasInitialized = true
            _G.ClientHawkEyePatrolSubsystem.ReportCheat      = nop
            _G.ClientHawkEyePatrolSubsystem.RequestImprison  = nop
            _G.ClientHawkEyePatrolSubsystem.IsDuringHawkEyePatrol = retFalse
        end

        if _G.ClientBanLogic then
            _G.ClientBanLogic.ReqBanInfo          = nop
            _G.ClientBanLogic.IsVoiceReportEnable = retFalse
            _G.ClientBanLogic.bEnableVoiceReport  = false
        end

        if _G.RealTimeBan then
            _G.RealTimeBan.tOnRankInspectorUIDSet         = {}
            _G.RealTimeBan.tInspectorRankUIDSet           = {}
            _G.RealTimeBan.tInspectorBroadcastCountUIDSet = {}
            _G.RealTimeBan.is_onrank_inspector            = false
        end

        if _G.tlog_report_utils then
            _G.tlog_report_utils.ReportTLogEvent         = nop
            _G.tlog_report_utils.SendTLogReportImmediate = nop
            _G.tlog_report_utils.IsCanReportLobbyEvent   = retFalse
            _G.tlog_report_utils.IsBusinessReport        = retFalse
        end

        if _G.STExtraBlueprintFunctionLibrary then
            _G.STExtraBlueprintFunctionLibrary.CheckMD5   = retTrue
            _G.STExtraBlueprintFunctionLibrary.VerifyFile = retTrue
        end

        if _G.CoronaLab then
            _G.CoronaLab.ReportData  = nop
            _G.CoronaLab.SendData    = nop
            _G.CoronaLab.CollectData = nop
            _G.CoronaLab.Telemetry   = nop
        end

        if _G.GokubaLogic then
            _G.GokubaLogic.ForwardFeature   = nop
            _G.GokubaLogic.InitGokubaLogic  = nop
        end

        if _G.SwiftHawk                  then _G.SwiftHawk                  = nop end
        if _G.ClientSwiftHawk            then _G.ClientSwiftHawk            = nop end
        if _G.ClientSwiftHawkWithParams  then _G.ClientSwiftHawkWithParams  = nop end
    end)
end

-- === Master bypass runner ===
_G.StartBypass_VIP_v3 = function()
    pcall(function()
        InitializeCoreBypass()
        InitializeSLUA_MD5()
        InitializeLogBlocker()
        InitializeScannerBlocker()
        InitializeReportBlocker()
        InitializeGameplayBypass()
        AntiCheatKillerUniversal()
        TFLiteAIBypass()
        BehavioralBypass()
        ServerValidationBypass()
        MLBypass()
        MemoryIntegrityBypass()
        CloudAIBypass()
        PacketEncryptionBypass()
        AdvancedBypasses()
        AntiBanSpoof()
        MaterialEvasionBypass()
        AimbotDetectionBypass()
        AggressiveReset()
    end)
end

_G.StartBypass_VIP_v3()

do
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(0.5, _G.StartBypass_VIP_v3)
            ticker.AddTimerOnce(2.0, _G.StartBypass_VIP_v3)
            ticker.AddTimerOnce(5.0, _G.StartBypass_VIP_v3)
        end
    end)
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            local function maskLoop()
                pcall(RuntimeSignatureMasking)
                ticker.AddTimerOnce(0.5, maskLoop)
            end
            ticker.AddTimerOnce(1.0, maskLoop)
        end
    end)
end

-- 如需 5 秒周期性重跑全部 bypass，取消下面这一行的注释
-- pcall(function()
--     local function BypassRefreshLoop()
--         pcall(_G.StartBypass_VIP_v3)
--         pcall(AggressiveReset)
--         local okTicker, ticker = pcall(require, "common.time_ticker")
--         if okTicker and ticker and ticker.AddTimerOnce then
--             ticker.AddTimerOnce(5.0, BypassRefreshLoop)
--         end
--     end
--     BypassRefreshLoop()
-- end)

if type(_G.InitializeAutoHeadHooks) == "function" then
    pcall(_G.InitializeAutoHeadHooks)
end

-- =========================================================================
-- [SECTION 6] Wide View (原 BRPlayerCharacterBase.lua 搬来)
-- =========================================================================
local TARGET_AXIS = 0
local _wideViewApplied = false

local function getLocalPlayer()
    local ok_ui, UIUtil = pcall(require, "client.common.ui_util")
    if not ok_ui or not UIUtil or not UIUtil.GetGameInstance then return nil end
    local WorldContextObject = UIUtil.GetGameInstance()
    if not WorldContextObject then return nil end
    local ok_g, UGameplayStatics = pcall(import, "GameplayStatics")
    if not ok_g or not UGameplayStatics then return nil end
    local PlayerController = UGameplayStatics.GetPlayerController(WorldContextObject, 0)
    if not PlayerController then return nil end
    local LP = PlayerController.Player
    if not LP then return nil end
    if slua and slua.isValid and not slua.isValid(LP) then return nil end
    return LP
end

local function applyWideView()
    local LP = getLocalPlayer()
    if not LP then return false end
    if LP.AspectRatioAxisConstraint ~= TARGET_AXIS then
        LP.AspectRatioAxisConstraint = TARGET_AXIS
    end
    return true
end

-- =========================================================================
-- [SECTION 7] 类方法
-- =========================================================================
function BRPlayerCharacterBase:ctor() end

function BRPlayerCharacterBase:_PostConstruct()
    BRPlayerCharacterBase.__super._PostConstruct(self)
    self:InitAddSpecialMoveInfo()
    self.bCanNearDeathGiveup = true
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
    BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
    self:AddControlEvent(self, "MovementModeChangedDelegate", self.HandleOnMovementModeChangedNew, self)
    if self:HasAuthority() and self:CheckAddCheckFallingDistanceComponent() then
        local CheckFallingDistanceComponent_C = safeImport("CheckFallingDistanceComponent")
        if slua.isValid(CheckFallingDistanceComponent_C) and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponent_C)) then
            Game:AddComponent(CheckFallingDistanceComponent_C, self, "CheckFallingDistanceComponent")
        end
    end
    if slua.isValid(self.STCharacterMovement) then self.STCharacterMovement.bPositiveBlowUp = true end
    if ENetRole and self.Role == ENetRole.ROLE_AutonomousProxy then
        self:AddControlEvent(self, "OnPawnStateDisabled", self.OnPawnStateChange, self)
        self:AddControlEvent(self, "OnPawnStateEnabled",  self.OnPawnStateChange, self)
        self:AddControlEventConditionOnly(self, "OnAttrChangeEventDelegate", { AttrName = { "bCanSelfRescue" } }, self.CharacterAttrChangeEvent, self)
    end
    if Client then
        self:InitWideView()   -- ⬅️ 合并：启动 Wide View
        if GameplayData then GameplayData.AddCharacter(self.Object) end
        self:AddControlEvent(self, "OnAttachedToVehicle",   self.HandleOnAttachedToVehicle,   self)
        self:AddControlEvent(self, "OnDetachedFromVehicle", self.HandleOnDetachedFromVehicle, self)
    else
        self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, { [1] = "FinishedState" }, self.HandleFinishedState, self)
    end
end

function BRPlayerCharacterBase:InitWideView()
    if not Client then return end
    pcall(applyWideView)

    local frameCount = 0
    self:AddGameTimer(0.1, true, function()
        pcall(function()
            frameCount = frameCount + 1
            if not _wideViewApplied then
                if applyWideView() then _wideViewApplied = true end
            else
                if frameCount % 12 == 0 then pcall(applyWideView) end
            end
        end)
    end)
end

function BRPlayerCharacterBase:HandleOnAttachedToVehicle(uVehicle)
    if slua.isValid(uVehicle) then self:ClearAttachToVehicleTimer() end
end
function BRPlayerCharacterBase:HandleOnDetachedFromVehicle(uLastVehicle)
    if slua.isValid(uLastVehicle) then self:ClearAttachToVehicleTimer() end
end
function BRPlayerCharacterBase:UpdatePlayerAttachToVehicle() end
function BRPlayerCharacterBase:FixMeshContainerOffsetIfNeeded() end
function BRPlayerCharacterBase:ClearAttachToVehicleTimer()
    if self.nUpdatePlayerAttachToVehicleTimer then
        self:RemoveGameTimer(self.nUpdatePlayerAttachToVehicleTimer)
        self.nUpdatePlayerAttachToVehicleTimer = nil
    end
    if self.nFixMeshContainerTimer then
        self:RemoveGameTimer(self.nFixMeshContainerTimer)
        self.nFixMeshContainerTimer = nil
    end
end

function BRPlayerCharacterBase:CharacterAttrChangeEvent(uPawn, AttrName, AttrVal)
    BRPlayerCharacterBase.__super.CharacterAttrChangeEvent(self, uPawn, AttrName, AttrVal)
    if self.Object ~= uPawn then return end
    if ENetRole and self.Role == ENetRole.ROLE_AutonomousProxy and AttrName == "bCanSelfRescue" then
        local pc = self:GetPlayerControllerSafety()
        if slua.isValid(pc) then pc:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "") end
    end
end

function BRPlayerCharacterBase:OnPawnStateChange(PawnState)
    if EPawnState and PawnState == EPawnState.SwitchPP then
        local pc = self:GetPlayerControllerSafety()
        if slua.isValid(pc) then pc:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "") end
    end
end

function BRPlayerCharacterBase:HandleFinishedState()
    if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfig then
        self.STCharacterMovement:SetDynamicSimpleQueryConfig(false)
    end
end

function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent() return false end
function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(LastParachuteState, NewParachuteState)
    BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self, LastParachuteState, NewParachuteState)
end
function BRPlayerCharacterBase:OnLanded()
    if self.HandleOnLanded then self:HandleOnLanded(-1) end
end
function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
    BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
    if Client and GameplayData then GameplayData.RemoveCharacter(self.Object) end
end
function BRPlayerCharacterBase:IsWarGameMode() return false end
function BRPlayerCharacterBase:BPOnRecycled()    if Client then self:ResetMeshRelativeLocationAndRotation() end end
function BRPlayerCharacterBase:BPOnRespawned()   if Client then self:ResetMeshRelativeLocationAndRotation() end end
function BRPlayerCharacterBase:ReceiveOnRecycle()
    if Client then
        self:ResetMeshRelativeLocationAndRotation()
        if GameplayData then GameplayData.RemoveCharacter(self.Object) end
    end
end
function BRPlayerCharacterBase:ReceiveOnSpawn()
    if Client then
        self:ResetMeshRelativeLocationAndRotation()
        if GameplayData then GameplayData.AddCharacter(self.Object) end
    end
end
function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation()
    if Game:IsValid(self.Object) and Game:IsValid(self.Mesh) then
        local rot = FRotator(0, -90, 0)
        if self.Mesh.K2_SetRelativeRotation then self.Mesh:K2_SetRelativeRotation(rot, false, nil, false) end
        self:CacheInitialMeshOffset(FVector(0, 0, 0), rot)
    end
end

function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
    local EMovementMode = nil
    pcall(function() EMovementMode = import("EMovementMode") end)
    if EMovementMode and Game:IsValid(self.STCharacterMovement)
        and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Swimming
        and self:CheckBaseIsMoveable() then
        self.CharacterMovement:SetBase(nil, "", true)
    end
end

function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord() end
function BRPlayerCharacterBase:ClientRPC_TriggerHighlightMoment(Type, Param)
    EventSystem:postEvent(EVENTTYPE_INGAME, EVENTID_INGAME_TRIGGER_HIGHLIGHT_MOMENT, Type, Param)
end

function BRPlayerCharacterBase:ParachuteJump()
    local pc = self:GetControllerSafety()
    if slua.isValid(pc) and not self:GetEnsure() then
        local EStateType = nil
        local EPS = nil
        pcall(function() EStateType = import("EStateType") end)
        pcall(function() EPS = import("ESTEPoseState") end)
        if not EStateType or not EPS then return end
        if pc:GetCurrentStateType() ~= EStateType.State_ParachuteJump and pc:GetCurrentStateType() ~= EStateType.State_ParachuteOpen then
            self:SwitchPoseState(EPS.Stand, true, true, true, false)
            pc:ReInitParachuteItem()
            pc:ServerChangeStatePC(EStateType.State_ParachuteJump)
        end
    end
end
function BRPlayerCharacterBase:CheckForbidFlaregun()
    local ps = self:GetPlayerStateSafety()
    if not slua.isValid(ps) then return false end
    return not ps.CanUseFlaregun
end
function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue() self:HandleNearDeathGiveupRescue() end
function BRPlayerCharacterBase:HandleNearDeathGiveupRescue() end
function BRPlayerCharacterBase:RPC_Server_GmPlayAction(actionId) end
function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(actionId) end
function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(b)
    if slua.isValid(self.ParachuteComponent) then self.ParachuteComponent.bServerSyncShouldCheckPassWall = b end
end
function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
    self.Super:OnPlayerEnterCarryBoxState()
    if self.CarryDeadBoxFeature then self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState() end
end
function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(b)
    self.Super:OnPlayerLeaveCarryBoxState(b)
    if self.CarryDeadBoxFeature then self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(b) end
end

function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(u)
    if not slua.isValid(u) then return end
    local tombBoxClass = nil
    pcall(function() tombBoxClass = import("/Script/ShadowTrackerExtra.PlayerTombBox") end)
    if tombBoxClass and Game:IsClassOf(u, tombBoxClass) and self.CarryDeadBoxFeature then
        self.CarryDeadBoxFeature:CarryDeadBox(u)
    end
end
function BRPlayerCharacterBase:SetAreaID(a) self:SetAttrValue("AreaID", a, -1) end
function BRPlayerCharacterBase:GetAreaID() return math.floor(self:GetAttrValue("AreaID") + 0.5) end
function BRPlayerCharacterBase:CannotChangeIntoPetSpectator() return self.bCannotChangeIntoPetSpectator end

function BRPlayerCharacterBase:DoModChangeToBT()
    if EPawnState and self:HasState(EPawnState.SpecialSuit) then
        self:TriggerEntrySkillWithID(4301101, true)
    end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteOpening() self.Super:SwitchCameraToParachuteOpening() end
function BRPlayerCharacterBase:SwitchCameraToParachuteFalling() self.Super:SwitchCameraToParachuteFalling() end
function BRPlayerCharacterBase:SwitchCameraToNormal()         self.Super:SwitchCameraToNormal() end
function BRPlayerCharacterBase:SwitchWeaponCheck(Slot, IgnoreState) return self.Super:SwitchWeaponCheck(Slot, IgnoreState) end

local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)
return require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
    { SkyTransition                  = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
    { CarryDeadBoxFeature            = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
    { SpecialSuitFeature             = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
    { TeleportPawnFeature            = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
    { LifterControl                  = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
    { FinalKillEffect                = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
    { CampFeature                    = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
    { BuildAircraftVehicleFeature    = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature" },
    { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" },
    { UnifiedBuildVehicleFeature     = "GameLua.Mod.BaseMod.GamePlay.Feature.UnifiedBuildVehicleFeature" },
    { ParachuteFormation             = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature" },
    { ParachuteSprint                = "GameLua.Mod.BaseMod.GamePlay.Feature.Parachute.ParachuteSprintFeature" },
    { GeneralShowSpotFeature         = "GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature" },
    { FPPAnimMonitor                 = "GameLua.Mod.BaseMod.GamePlay.Feature.Player.FPPAnimMonitorFeature" }
}, "BRPlayerCharacterBase")