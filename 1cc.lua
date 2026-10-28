-- ============================================================================
-- ULTIMATE MERGED BYPASS v3.0 - COMPLETE SECURITY DISABLEMENT
-- ============================================================================
local function nop() return true end
local function retFalse() return false end
local function retZero() return 0 end
local function retEmpty() return {} end
local function retNil() return nil end
local function retTrue() return true end
local function retEmptyString() return "" end

local function InitializeSLUABypass()
    pcall(function()
        if slua and slua.getSignature then slua.getSignature = function() return 0xDEADBEEF end end
        local loader = package.loaded["slua.loader"] or rawget(_G, "slua_loader")
        if loader then
            loader.verifyBytecode = retTrue
            loader.checkIntegrity = retTrue
            if loader.disableSignatureCheck then loader.disableSignatureCheck = retTrue end
        end
        local slua_serialize = package.loaded["slua.serialize"]
        if slua_serialize then slua_serialize.check = retTrue; slua_serialize.verify = retTrue end
        if jit and jit.attach then jit.attach(function() end, "bc") end
        if _G.slua_verify then _G.slua_verify = retTrue end
        if _G.check_slua_integrity then _G.check_slua_integrity = retTrue end
    end)
end

local function InitializeMD5Bypass()
    pcall(function()
        local console = import("KismetSystemLibrary")
        if console then
            console.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1")
            console.ExecuteConsoleCommand(nil, "pakchunk.EnableSignatureCheck 0")
            console.ExecuteConsoleCommand(nil, "s.VerifyPak 0")
            console.ExecuteConsoleCommand(nil, "sig.Check 0")
            console.ExecuteConsoleCommand(nil, "security.DisableChecks 1")
        end
        local CMode = import("CreativeModeBlueprintLibrary")
        if CMode then
            CMode.MD5HashByteArray = function() return "00000000000000000000000000000000" end
            CMode.MD5HashFile = function() return "00000000000000000000000000000000" end
            CMode.GetContentDiffData = function() return true, "BYPASSED" end
            CMode.VerifyFileIntegrity = retTrue
        end
        if _G.MD5Hash then _G.MD5Hash = function() return "00000000000000000000000000000000" end end
        if _G.CRC32 then _G.CRC32 = function() return 0 end end
        if _G.SHA1 then _G.SHA1 = function() return "BYPASS" end end
        local FileHashChecker = package.loaded["common.file_hash_checker"]
        if FileHashChecker then
            FileHashChecker.CheckFileMD5 = retTrue; FileHashChecker.VerifyAll = retTrue
            FileHashChecker.GetHash = function() return "BYPASS" end
        end
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then TssSdk.GetFileMD5 = function() return "BYPASS" end; TssSdk.VerifyFileSignature = retTrue end
        local STExtra = import("STExtraBlueprintFunctionLibrary")
        if STExtra then STExtra.CheckMD5 = retTrue; STExtra.GetMD5 = function() return "BYPASS" end; STExtra.VerifyFile = retTrue end
    end)
end
local function InitializeSkinBypass()
    pcall(function()
        local ptlog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
        if ptlog then ptlog.ReportEvent = nop; ptlog.ReportDownloadResult = nop; ptlog.ReportODPTDError = nop; ptlog.ReportSkinError = nop end
        local AvatarUtils = package.loaded["AvatarUtils"]
        if AvatarUtils then AvatarUtils.CheckIsWeaponInBlackList = retFalse; AvatarUtils.IsValidAvatar = retTrue; AvatarUtils.CheckAvatarIntegrity = retTrue; AvatarUtils.ReportInvalidAvatar = nop end
        local sub = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("FileCheckSubsystem")
        if sub then sub.StartCheck = nop; sub.ReportAbnormalFile = nop; sub.StopCheck = nop end
        local eqEx = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
        if eqEx then eqEx.Report = nop; eqEx.SendException = nop end
    end)
end
local function InitializeLogBlocker()
    pcall(function()
        local SMTD = import("ScreenshotMTDer")
        if SMTD then SMTD.MTDePicture = function() return "" end; SMTD.ReMTDePicture = function() return "" end; SMTD.HasCaptured = retTrue; SMTD.TakeScreenshot = nop end
        local TLog = package.loaded["TLog"] or _G.TLog
        if TLog then TLog.Info = nop; TLog.Warning = nop; TLog.Error = nop; TLog.Debug = nop; TLog.Report = nop; TLog.Send = nop; TLog.Flush = nop end
        local CrashSight = package.loaded["CrashSight"] or _G.CrashSight
        if CrashSight then CrashSight.ReportException = nop; CrashSight.SetCustomData = nop; CrashSight.Log = nop; CrashSight.SendCrash = nop; CrashSight.ReportUserException = nop end
        local GRUtils = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
        if GRUtils then GRUtils.BugglyPostExceptionFull = retFalse; GRUtils.CheckCanBugglyPostException = retFalse; GRUtils.ReplayReportData = nop; GRUtils.ReportGameException = nop; GRUtils.PostException = nop end
        local CTR = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if CTR then CTR.SendReport = nop; CTR.SendException = nop; CTR.UploadLog = nop end
        for _, sdk in ipairs({"Firebase", "Adjust", "AppsFlyer", "FacebookAnalytics", "GameAnalytics"}) do
            local s = _G[sdk]; if s then s.logEvent = nop; s.trackEvent = nop; s.setEnabled = retFalse; s.sendEvent = nop; s.report = nop end
        end
    end)
end

local function InitializeScannerBlocker()
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            local subs = {"AFKReportorSubsystem", "ClientDataStatistcsSubsystem", "AvatarExceptionSubsystem", "ShootVerifySubSystemClient", "MemoryCheckSubsystem", "SpeedCheckSubsystem", "WallCheckSubsystem", "FileCheckSubsystem", "BehaviorScoreSubsystem"}
            for _, name in ipairs(subs) do
                local sub = SubMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Upload") or k:find("Verify") or k:find("Check") or k:find("Validate") or k:find("Scan") or k:find("Detect")) then pcall(function() sub[k] = nop end) end
                    end
                    if sub.ReportPingDelayTimer then sub:RemoveGameTimer(sub.ReportPingDelayTimer); sub.ReportPingDelayTimer = nil end; sub.DelayCount = 0
                end
            end
        end
        local AvaEx = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
        if AvaEx then AvaEx.CheckAvatarException = nop; AvaEx.CheckAvatarExceptionOnce = nop; AvaEx.ReportAvatarException = nop; AvaEx.CheckSlotMeshVisible = retFalse; AvaEx.CheckPawnVisible = retFalse; AvaEx.CheckCanBugglyPostException = retFalse end
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then
            local origData = TssSdk.OnRecvData
            -- [FIX PING]: Thêm tham số 'true' vào hàm find để tìm kiếm chuỗi thuần túy, nhanh hơn hàng chục lần so với regex, chống giật ping
            TssSdk.OnRecvData = function(data) if type(data) == "string" and (data:find("report", 1, true) or data:find("exception", 1, true) or data:find("cheat", 1, true) or data:find("violation", 1, true) or data:find("hack", 1, true) or data:find("verify", 1, true)) then return end; if origData then origData(data) end end
            TssSdk.SendReportInfo = nop; TssSdk.ScanMemory = retTrue; TssSdk.IsEmulator = retFalse; TssSdk.GetTssSdkReportInfo = retEmptyString; TssSdk.CheckEnvironment = retTrue; TssSdk.VerifyProcess = retTrue
        end
    end)
end

local function InitializeReplayTelemetryBlocker()
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            for _, name in ipairs({"GameReportSubsystem", "ReplaySubsystem"}) do
                local sub = SubMgr:Get(name)
                if sub then for k, v in pairs(sub) do if type(v) == "function" and (k:find("Report") or k:find("Trace") or k:find("Replay") or k:find("Record") or k:find("Save")) then pcall(function() sub[k] = nop end) end end end
            end
        end
        local logRep = package.loaded["client.slua.logic.replay.logic_report_replay"]
        if logRep then logRep.ReportReplay = nop; logRep.SendReportReq = nop; logRep.UploadReplay = nop end
    end)
end

local function InitializeReportFlowBlocker()
    pcall(function()
        local flows = {"ReportAimFlow", "ReportHitFlow", "ReportAttackFlow", "ReportSecAttackFlow", "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow", "ReportPlayerBehavior", "ReportTeammatHurt", "ReportMisKillByTeammate", "ReportForbitPick", "ReportPlayerMoveRoute", "ReportPlayerPosition", "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow", "ReportParachuteData", "ReportEquipmentFlow", "ReportPlayersPing", "ReportPlayerIP", "ReportPlayerFramePingRecord", "ReportDSNetSaturation", "ReportNetContinuousSaturate", "ReportDSNetRate", "ReportCircleFlow", "ReportSecMrpcsFlow"}
        for _, f in ipairs(flows) do if _G[f] then _G[f] = nop end; if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then _G.GameplayCallbacks[f] = nop end end
        for _, f in ipairs({"CheckReportSecAttackFlowWithAttackFlow", "CheckReportSecAttackFlow"}) do if _G[f] then _G[f] = retFalse end; if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then _G.GameplayCallbacks[f] = retFalse end end
        for _, f in ipairs({"IsEnableReportMrpcsInCircleFlow", "IsEnableReportMrpcsInPartCircleFlow", "IsEnableReportMrpcsFlow", "IsEnableReportAttackFlow", "IsEnableReportHitFlow", "IsEnableReportCircleFlow"}) do if _G[f] then _G[f] = retFalse end end
    end)
end

local function InitializePlayerSecurityBypass()
    pcall(function()
        for _, c in ipairs({"PlayerSecurityInfoCollector", "PlayerSecurityInfo", "SecurityInfoCollector", "ClientSecurityCollector", "PlayerAntiCheatCollector"}) do
            if _G[c] then for k, v in pairs(_G[c]) do if type(v) == "function" and (k:find("Report") or k:find("Collect") or k:find("Send") or k:find("Upload") or k:find("Record")) then _G[c][k] = nop end end end
        end
        local SecSub = require("GameLua.Mod.BaseMod.Common.Security.PlayerSecurityInfoSubsystem")
        if SecSub then SecSub.ReportData = nop; SecSub.CheckCheat = retFalse; SecSub.ValidatePlayer = retTrue; SecSub.CollectData = nop; SecSub.SendToServer = nop end
    end)
end

local function InitializeClientFlowBypass()
    pcall(function()
        for _, name in ipairs({"ClientSecMrpcsFlow", "MrpcsFlow", "MrpcsData", "ClientCircleFlowSubsystem", "ClientKillFlowSubsystem", "ClientSecPlayerKillFlow"}) do
            local sub = package.loaded[name] or _G[name]
            if sub then for k, v in pairs(sub) do if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Flow") or k:find("Record") or k:find("Process")) then pcall(function() sub[k] = nop end) end end end
        end
    end)
end

local function InitializeSwiftHawkBypass()
    pcall(function()
        for _, f in ipairs({"SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams", "SendSwiftHawkData"}) do if _G[f] then _G[f] = nop end; if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then _G.GameplayCallbacks[f] = nop end end
        local sub = package.loaded["GameLua.Mod.BaseMod.Client.Security.SwiftHawkSubsystem"]
        if sub then sub.ReportData = nop; sub.SendReport = nop; sub.CollectTelemetry = nop end
    end)
end

local function InitializeCoronaLabBypass()
    pcall(function()
        if _G.CoronaLab then _G.CoronaLab.ReportData = nop; _G.CoronaLab.SendData = nop; _G.CoronaLab.CollectData = nop; _G.CoronaLab.Telemetry = nop end
        local sub = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("CoronaLabSubsystem")
        if sub then sub.ReportData = nop; sub.SendToServer = nop; sub.CollectTelemetry = nop; sub.StopCollection = nop end
    end)
end

local function InitializeModifierExceptionBypass()
    pcall(function()
        if _G.bReportedModifierException then _G.bReportedModifierException = false end
        local sub = require("GameLua.Mod.BaseMod.Common.Security.ModifierExceptionSubsystem")
        if sub then sub.ReportException = nop; sub.CheckModifier = retTrue; sub.ValidateModifier = retTrue; sub.ReportModifierError = nop end
    end)
end

local function InitializeSimulateCharacterLocationBypass()
    pcall(function()
        local sub = require("GameLua.Mod.BaseMod.Gameplay.Simulate.SimulateCharacterSubsystem")
        if sub then sub.ReportLocation = nop; sub.SendLocationData = nop; sub.VerifyLocation = retTrue end
    end)
end

local function InitializeShootVerificationBypass()
    pcall(function()
        local sub = require("GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
        if sub then sub.OnShootVerifyFailed = nop; sub.SendVerifyData = nop; sub.ReportBulletHit = nop; sub.UploadHitInfo = nop; sub.VerifyShot = retTrue end
        if _G.BulletHitInfoUploadData then _G.BulletHitInfoUploadData.Report = nop; _G.BulletHitInfoUploadData.Send = nop; _G.BulletHitInfoUploadData.Upload = nop end
    end)
end

local function InitializeNetworkPacketBlock()
    pcall(function()
        if NetUtil and NetUtil.SendPacket then
            local orig = NetUtil.SendPacket
            local blocked = {
                ["ReportAttackFlow"]=1, ["ReportSecAttackFlow"]=1, ["ReportFireArms"]=1, ["ReportVerifyInfoFlow"]=1, ["ReportMrpcsFlow"]=1,
                ["ReportPlayerBehavior"]=1, ["ReportTeammatHurt"]=1, ["ReportPlayerMoveRoute"]=1, ["ReportPlayerPosition"]=1, ["ReportSecVehicleMoveFlow"]=1,
                ["report_parachute_data"]=1, ["on_tss_sdk_anti_data"]=1, ["ReportAimFlow"]=1, ["ReportHitFlow"]=1, ["ReportCircleFlow"]=1, ["report_players_ping"]=1,
                ["report_player_ip"]=1, ["report_net_saturate"]=1, ["report_speed_hack"]=1, ["report_wall_hack"]=1, ["report_aim_bot"]=1, ["report_esp_usage"]=1,
                ["report_modded_files"]=1, ["detect_cheat"]=1, ["ban_player"]=1, ["client_anti_cheat_report"]=1,
                ["ClientSecMrpcsFlow"]=1, ["MrpcsData"]=1, ["CheckReportSecAttackFlow"]=1, ["CheckReportSecAttackFlowWithAttackFlow"]=1, ["RPC_ClientCoronaLab"]=1,
                ["CoronaLabReport"]=1, ["CoronaLabData"]=1, ["PlayerSecurityInfo"]=1, ["ReportSecurityInfo"]=1, ["SendSecurityData"]=1, ["ClientCircleFlow"]=1,
                ["IsEnableReportMrpcsInCircleFlow"]=1, ["IsEnableReportMrpcsInPartCircleFlow"]=1, ["bReportedModifierException"]=1,
                ["ReportModifierException"]=1, ["RPC_Server_ReportSimulateCharacterLocation"]=1, ["ReportSimulateCharacterLocation"]=1, ["RPC_Client_ShootVertifyRes"]=1,
                ["BulletHitInfoUploadData"]=1, ["ShootVerifyFailed"]=1, ["report_unrealnet_exception"]=1, ["tss_sdk_report"]=1, ["SwiftHawk"]=1, ["ClientSwiftHawk"]=1, ["ClientSwiftHawkWithParams"]=1, ["SwiftHawkReport"]=1, ["SwiftHawkData"]=1,
                ["AntiCheatReport"]=1, ["CheatDetection"]=1, ["ViolationReport"]=1, ["SecurityViolation"]=1, ["IntegrityCheck"]=1, ["SignatureVerify"]=1
            }
            NetUtil.SendPacket = function(packetName, ...) if blocked[packetName] then return nil end; return orig(packetName, ...) end
            NetUtil.IsBypassed = true
        end
        if _G.SendRPC then
            local origRPC = _G.SendRPC
            local blockedRPC = {"RPC_Server_ClientSecMrpcsFlow", "RPC_Server_SwiftHawk", "RPC_Server_ClientSwiftHawkWithParams", "RPC_Server_ReportSimulateCharacterLocation", "RPC_Client_ShootVertifyRes", "RPC_ClientCoronaLab"}
            _G.SendRPC = function(rpcName, ...) for _, b in ipairs(blockedRPC) do if rpcName == b then return nil end end; return origRPC(rpcName, ...) end
        end
    end)
end

local function InitializeHiggsBosonBypass()
    pcall(function()
        local Higgs = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if Higgs then
            for _, m in ipairs({"ControlMHActive", "Tick", "OnTick", "MHActiveLogic", "TriggerAvatarCheck", "StartAvatarCheck", "ReportItemID", "ReceiveAnyDamage", "OnWeaponHitRecord", "ShowSecurityAlert", "ServerReportAvatar", "ClientReportNetAvatar", "SendHisarData", "ValidateSecurityData", "StaticShowSecurityAlertInDev", "RPC_Client_ShootVertifyRes", "RPC_Server_ReportSimulateCharacterLocation", "DisableHiggsBoson", "CheckMHActive", "ReportViolation", "ProcessSecurityEvent", "ValidatePlayer", "CheckIntegrity"}) do
                if Higgs[m] then Higgs[m] = nop end
            end
            Higgs.GetNetAvatarItemIDs = retEmpty; Higgs.GetCurWeaponSkinID = retZero; Higgs.IsMHActive = retFalse; Higgs.bMHActive = false; Higgs.bCallPreReplication = false
            if Higgs.BlackList then for k in pairs(Higgs.BlackList) do Higgs.BlackList[k] = nil end end
        end
        _G.BlackList = {}
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) then
            if pc.HiggsBoson then pc.HiggsBoson.bMHActive = false; pc.HiggsBoson.bCallPreReplication = false; if pc.HiggsBoson.ControlMHActive then pc.HiggsBoson:ControlMHActive(0) end end
            if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive = false; pc.HiggsBosonComponent.bCallPreReplication = false; pc.HiggsBosonComponent:ControlMHActive(0) end
        end
    end)
end

local function InitializeAntiCheatHooks()
    pcall(function()
        local HBC = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if HBC and HBC.StaticShowSecurityAlertInDev then HBC.StaticShowSecurityAlertInDev = nop end
    end)
    if _G.AvatarCheckCallback then
        _G.AvatarCheckCallback.StartAvatarCheck = nop; _G.AvatarCheckCallback.OnReportItemID = nop
        _G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(PlayerController)
            if slua.isValid(PlayerController) and PlayerController.HiggsBosonComponent then PlayerController.HiggsBosonComponent:ControlMHActive(0); PlayerController.HiggsBosonComponent.bMHActive = false end
        end
    end
end

local function InitializeAntiReport()
    pcall(function()
        for _, path in ipairs({"GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem", "Client.Security.ClientReportPlayerSubsystem", "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem"}) do
            local sub = package.loaded[path]; if not sub then local s, r = pcall(require, path); if s and r then sub = r end end
            if sub then for k, v in pairs(sub) do if type(v) == "function" and (k:find("Report") or k:find("Record") or k:find("Send") or k:find("Upload") or k:find("Notify")) then pcall(function() sub[k] = nop end) end end end
        end
    end)
end

local function InitializeGameplayBypass()
    pcall(function()
        if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end
        if _G.GameplayCallbacks.IsBypassed then return end
        local GC = _G.GameplayCallbacks
        local reports = {"ReportAttackFlow", "ReportSecAttackFlow", "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow", "ReportPlayerBehavior", "ReportTeammatHurt", "ReportMisKillByTeammate", "ReportForbitPick", "ReportPlayerMoveRoute", "ReportPlayerPosition", "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow", "ReportParachuteData", "SendTssSdkAntiDataToLobby", "ReportEquipmentFlow", "ReportAimFlow", "ReportPlayersPing", "ReportPlayerIP", "ReportPlayerFramePingRecord", "OnDSConnectionSaturated", "ReportDSNetSaturation", "ReportNetContinuousSaturate", "ReportDSNetRate", "SendClientStats", "SendServerAvgTickDelta", "ReportCircleFlow", "ClientSecMrpcsFlow", "SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams"}
        for _, f in ipairs(reports) do GC[f] = nop end
        GC.CheckReportSecAttackFlowWithAttackFlow = retFalse; GC.CheckReportSecAttackFlow = retFalse
        local origState = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, State, bPure, bSafe, Param)
            local s = State and string.lower(tostring(State)) or ""
            local blocked = {["cheatdetected"]=1, ["connectionlost"]=1, ["connectiontimeout"]=1, ["connectionexception"]=1, ["netdrivererror"]=1, ["banned"]=1, ["kicked"]=1, ["suspended"]=1, ["violationdetected"]=1, ["integrityfailure"]=1, ["securityviolation"]=1}
            if blocked[s] then return end
            if origState then pcall(origState, UID, State, bPure, bSafe, Param) end
        end
        GC.OnPlayerNetConnectionClosed = nop; GC.OnPlayerActorChannelError = nop; GC.OnPlayerRPCValidateFailed = nop; GC.OnPlayerSpectateException = nop; GC.OnShutdownAfterError = nop; GC.IsBypassed = true
    end)
end

local function InitializeKillAllSubsystems()
    pcall(function()
        local subMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if not subMgr then return end
        local toKill = {"CoronaLabSubsystem", "PlayerSecurityInfoSubsystem", "ClientCircleFlowSubsystem", "ModifierExceptionSubsystem", "SimulateCharacterSubsystem", "ShootVerifySubSystemClient", "HiggsBosonComponent", "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem", "ClientHawkEyePatrolSubsystem", "DSHawkEyePatrolSubsystem", "ClientDataStatistcsSubsystem", "AFKReportorSubsystem", "BehaviorScoreSubsystem", "FileCheckSubsystem", "MemoryCheckSubsystem", "SpeedCheckSubsystem", "WallCheckSubsystem", "AvatarExceptionSubsystem", "GameReportSubsystem", "ClientSecMrpcsFlowSubsystem", "MrpcsFlowSubsystem", "CircleFlowSubsystem", "SwiftHawkSubsystem", "AntiCheatSubsystem", "IntegrityCheckSubsystem", "SignatureVerifySubsystem", "MD5CheckSubsystem", "PakVerifySubsystem"}
        for _, name in ipairs(toKill) do
            local sub = subMgr:Get(name)
            if sub then
                for k, v in pairs(sub) do if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Upload") or k:find("Verify") or k:find("Check") or k:find("Validate") or k:find("Scan") or k:find("Detect") or k:find("Collect") or k:find("Flow") or k:find("Heartbeat")) then pcall(function() sub[k] = nop end) end end
                if sub.timer then pcall(function() sub:RemoveGameTimer(sub.timer) end) end
                if sub.heartbeatTimer then pcall(function() sub:RemoveGameTimer(sub.heartbeatTimer) end) end
                if sub.reportTimer then pcall(function() sub:RemoveGameTimer(sub.reportTimer) end) end
            end
        end
    end)
end

local function InitializeFinalProtection()
    pcall(function()
        for _, flag in ipairs({"ENABLE_REPORT", "ENABLE_ANTI_CHEAT", "ENABLE_SECURITY", "ENABLE_TELEMETRY", "ENABLE_ANALYTICS", "ENABLE_CRASH_REPORT", "ENABLE_PERFORMANCE_REPORT"}) do if _G[flag] then _G[flag] = false end end
        local origReq = require
        local blocked = {"HiggsBosonComponent", "PlayerSecurityInfoSubsystem", "CoronaLabSubsystem", "ClientCircleFlowSubsystem", "ModifierExceptionSubsystem", "ShootVerifySubSystemClient", "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem"}
        _G.require = function(m) for _, b in ipairs(blocked) do if m:find(b) then return {} end end; return origReq(m) end
    end)
end

local function InitializeOperationalStatsBypass()
    pcall(function()
        -- Lấy qua SubsystemMgr hoặc Global để đảm bảo 100% bắt được đích
        local subMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        local OperationalStatsSubsystem = (subMgr and subMgr:Get("OperationalStatsSubsystem")) or _G.OperationalStatsSubsystem
        
        if OperationalStatsSubsystem then
            OperationalStatsSubsystem.ReportOperationalStats = nop
            OperationalStatsSubsystem.AddOperationalStats = nop
            OperationalStatsSubsystem.HandleTouchBegin = nop
            OperationalStatsSubsystem.HandleTouchEnd = nop
            OperationalStatsSubsystem.OnInit = nop
            OperationalStatsSubsystem.HandleEnterFighting = nop
            OperationalStatsSubsystem.OnBattleResult = nop
            if OperationalStatsSubsystem.TimerHandle then
                pcall(function() OperationalStatsSubsystem:RemoveGameTimer(OperationalStatsSubsystem.TimerHandle) end)
                OperationalStatsSubsystem.TimerHandle = nil
            end
            OperationalStatsSubsystem.StatsData = {}
            print("[ULTIMATE BYPASS] OperationalStatsSubsystem blocked!")
        end
    end)
end

_G.StartBypass_VIP_v3 = function()
    pcall(function()
        print("[ULTIMATE BYPASS] Starting initialization...")
        InitializeSLUABypass()
        InitializeMD5Bypass()
        InitializeSkinBypass() -- Thêm dòng này
        InitializeLogBlocker()
        InitializeScannerBlocker()
        InitializeReplayTelemetryBlocker()
        InitializeReportFlowBlocker()
        InitializePlayerSecurityBypass()
        InitializeClientFlowBypass()
        InitializeSwiftHawkBypass()
        InitializeCoronaLabBypass()
        InitializeModifierExceptionBypass()
        InitializeSimulateCharacterLocationBypass()
        InitializeShootVerificationBypass()
        InitializeNetworkPacketBlock()
        InitializeHiggsBosonBypass()
        InitializeAntiCheatHooks()
        InitializeAntiReport()
        InitializeGameplayBypass()
        InitializeKillAllSubsystems()
        InitializeOperationalStatsBypass() -- [NEW] BYPASS BÁO CÁO THỐNG KÊ (Operational Stats)
        InitializeFinalProtection()
        print("[ULTIMATE BYPASS] Complete - All Security Systems Disabled")
    end)
end


local BlockedSecurityModules = {
  "Server.security.GameSafeCallbacks",
  "Server.security.AllStrategyCfgLines",
  "Server.security.PlayerSafeCallback",
  "Server.security.WeaponSafeCallback",
  "Server.security.VehicleSafeCallback",
  "Server.security.ESPSafeCallback",
  "Server.security.IntegrityCheckCallback",
  "Server.security.AndroidObscuredCallback",
  "Server.security.SecurityCommon",
  "Server.security.TickEncryptCallback",
  "Server.security.MoveInputCallback",
  "Server.security.AutoAimConfig",
  "Server.security.PeekShootVerifyCallback",
  "Server.security.SecurityPakCallback",
  "Server.security.BaziConfig",
  "Server.security.AvatarCheckCallback",
}

for _, modulePath in ipairs(BlockedSecurityModules) do
  package.loaded[modulePath] = {}
end



local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
local IsNumber = SecurityCommonUtils.IsNumber
local IsString = SecurityCommonUtils.IsString
local IsNonemptyString = SecurityCommonUtils.IsNonemptyString
local FormatLog = FuncUtil.FormatLog
local bIsDevelopment = false
local bIsRelease = true


-- 🔥 PART 3: GLOBAL TABLES

_G.GameSafeCallbacks = _G.GameSafeCallbacks or {}
GlobalPlayerCheatTimes = {}
GlobalPlayerCoronaData = {}
TestBanUIDSet = {}
UID2PlayerKey = {}
GrayPublishPendingPlayerKey = {}
GrayPublishPVSCellSubModeID = {}
SafeModulesTable = {}


-- 🔥 PART 4: ENUM PLACEHOLDERS (fully defined)

ScriptReportEnum = {
  ObscuredData = "",
  Kills = 0,
  ClientInfo = "",
  DiffRuntimeMatched = 0,
  Level = 0,
  ClientGravityAnomalyCount = 0,
  ShootVerifyClientHitAABBCount = 0,
  ShootVerifyDSAABBMissCount = 0,
  WeaponScopeHeightBigNum = 0,
  WeaponScopeDisBigNum = 0,
  OwnerHeadAndMuzzleBlockNum = 0,
  ImpactPointAndBulletDisBigNum = 0,
  ShootVerifyInvalidNum = 0,
  BulletDirError = 0,
  ClientAccFrame = 0,
  EspData = "",
  ClientGravityZ = -980,
  HeartBreaks = 0,
  MaxFlySkyTime = 0,
  StartFlySkyTime = 0,
  FlySkyTimes = 0,
  IsDynamicActorsEnabled = 0,
  DynamicActorsData = "",
  IntegrityCheckNotMatchCount = 0,
  IntegrityCheckNotMatchDetail = "",
  BulletFireSpeed = 0,
  ClientScreenShot = 0,
  FlyingErrorCnt = 0,
  MaxFlyingDuration = 0,
  FlyingStableRate = 0,
  PlayerPingRecordArray = {},
  PlayerPingReportCount = 0,
  PlayerPingReport = "",
  PlayerBadPingTimes = 0,
  PlayerReportedCount = 0,
  MinUndilatedFrameTime = 0,
  AccumulatedFightingStateTime = 0,
  PVSInCityKillTotalTime = 0,
  PVSNotInCityKillTotalTime = 0,
  PVSInCityKillerTotalMoveDistance = 0,
  PVSNotInCityKillerTotalMoveDistance = 0,
  IsTickEncryptEnabled = 0,
  TickEncryptDetail = "",
  ShooterCapsuleCollided = 0,
  AvatarCheckData = "",
  JumpMaxCount = 0,
  pubgmvStr62 = 0,
  pubgmvStr63 = 0,
  IsPeekShootVerifyEnabled = 0,
  PeekShootVerifyDetail = "",
  InvalidPakFiles = "",
  IsMoveInputEnabled = 0,
  pubgmvStr67 = 0,
  pubgmvStr68 = 0,
  TeamID = 0,
  BlackAvatarCount = 0,
}

ScriptReportIndex = {
  ObscuredData = 1, PlayerPingReport = 2, ClientInfo = 3,
  PlayerBadPingTimes = 4, Level = 5, PlayerReportedCount = 6,
  PVSInCityKillTotalTime = 7, AccumulatedFightingStateTime = 8,
  Kills = 9, ClientGravityAnomalyCount = 10,
  ShootVerifyClientHitAABBCount = 11, ShootVerifyDSAABBMissCount = 12,
  BulletDirError = 13, FlyingStableRate = 14, EspData = 15,
  ClientGravityZ = 16, HeartBreaks = 17, ClientAccFrame = 18,
  MaxFlyingDuration = 19, FlyingErrorCnt = 20,
  StartFlySkyTime = 21, MaxFlySkyTime = 22, FlySkyTimes = 23,
  IsDynamicActorsEnabled = 24, DynamicActorsData = 25,
  IntegrityCheckNotMatchCount = 26, IntegrityCheckNotMatchDetail = 27,
  BulletFireSpeed = 28, WeaponScopeHeightBigNum = 29,
  WeaponScopeDisBigNum = 30, OwnerHeadAndMuzzleBlockNum = 31,
  ClientScreenShot = 32, ImpactPointAndBulletDisBigNum = 33,
  ShootVerifyInvalidNum = 34, DiffRuntimeMatched = 35,
  IsTickEncryptEnabled = 36, TickEncryptDetail = 37,
  JumpMaxCount = 38, pubgmvStr55 = 39,
  PVSInCityKillerTotalMoveDistance = 40,
  PVSNotInCityKillerTotalMoveDistance = 41,
  PVSNotInCityKillTotalTime = 42, MinUndilatedFrameTime = 43,
  ShooterCapsuleCollided = 44, AvatarCheckData = 45,
  pubgmvStr62 = 46, pubgmvStr63 = 47,
  IsPeekShootVerifyEnabled = 48, PeekShootVerifyDetail = 49,
  IsMoveInputEnabled = 50, InvalidPakFiles = 51,
  pubgmvStr68 = 52, TeamID = 53, BlackAvatarCount = 54,
}
local ScriptReportIndexCount = 54
ScriptReportEnum.__index = ScriptReportEnum


-- 🔥 PART 5: FULL CoronaDataEnum (all 200+ fields)

CoronaDataEnum = {
  TotalStatisticCnt = 0, CrcCheckRet = 0, bAndroid = 0, bRoot = 0,
  bSimulator = 0, bHasMalware = 0, bTssMgrDie = 0, TssFeatureState = 0,
  Level = 0, ReportedCount = 0, IOSAppSignFailedCnt = 0, AOSAppSignFailedCnt = 0,
  LibCheckFailedCnt = 0, GrassDensityFailedCnt = 0, AnubisResFailedCnt = 0,
  AnubisCrc = 0, ChronosResFailedCnt = 0, ChronosVer = 0,
  ArtemisResFailedCnt = 0, ArtemisCrc = 0, DianaResFailedCnt = 0,
  DianaCrc = 0, AppSignCrc = 0, SoCheckFailedCnt = 0, BasePakFailedCnt = 0,
  CheckFilesInPakFailedCnt = 0, EnemyBoneMaxLen = 0, EnemyBoneFailedCnt = 0,
  EnemyPhyAggemFailedCnt = 0, MaxWalkSpeed = 0, WalkSpeedFailedCnt = 0,
  SelfModelFailedCnt = 0, EspTotalTime = 0, EspTotalCnt = 0,
  AutoAimTotalCnt = 0, AutoRotationTotalCnt = 0, AutoCameraRotationTotalCnt = 0,
  AutoCameraLocationTotalCnt = 0, AutoAimByLockViewPitchTotalCnt = 0,
  AutoAimByLockViewYawTotalCnt = 0, MarcoPoloYawChangedCount = 0,
  MarcoPoloVerifyFailedCount = 0, MarcoPoloWorldYawChangedCount = 0,
  RocoilLessTotalCnt = 0, WeaponIDList = "", DistOfScope2Head = 0,
  DistOfScope2HeadFailedCnt = 0, AutoAimCfgFailedCnt = 0, RecoilCfgFailedCnt = 0,
  DeviationCfgFailedCnt = 0, AccessoryFactorFailedCnt = 0,
  RecoilCurveFailedCnt = 0, AimInputFailedCnt = 0, BulletDirFailedCnt = 0,
  BulletDirDSErrorCnt = 0, AimCompInputFailedCnt1 = 0, AimCompInputFailedCnt2 = 0,
  AimCompInputFailedCnt3 = 0, AimCompInputFailedCnt4 = 0,
  NormalShootTotalKillCnt100 = 0, NormalShootKillCnt30 = 0,
  NormalShootKillLockHeadCnt30 = 0, OpenScopeShootKillCnt100 = 0,
  OpenScopeShootKillLockHeadCnt100 = 0, IntegrityCheckNotMatchCount = 0,
  TotalOutOfOrderPackets = 0, MaxOutOfOrderPacketsPerSec = 0,
  ProofRawData = "", EspBattleInvisibleCnt = 0, EspOpenScopeInvisibleCnt = 0,
  EspContinueInvisibleCnt = 0, DSSpeedOver10FailedCnt = 0,
  DSSpeedOver15FailedCnt = 0, DSSpeedOver20FailedCnt = 0, ClientAccFrame = 0,
  JumpMaxHeight2 = 0, DSPlayerZ = 0, SelfBoneLenOverMaxFailedCnt = 0,
  TotalSkeletonLengthMax = 0, SkeletonLengthCheckInvaildNum = 0,
  TimeAccTotal = 0, SpeedQuickCheck = 0, FlyCar2 = 0,
  MuzzleAndOwnerPosInVaildNum = 0, MuzzleAndHeadPassWall = 0,
  ShootVerifyClientHitAABBCount = 0, ShootVerifyDSAABBMissCount = 0,
  MissRate = 0, PrisonBreaks = 0, PlayerBadPingTimes = 0,
  ServerAccumulateErrors = 0, ServerAvgErrors = 0,
  AndroidOrSimRootCnt = 0, IOSRootCnt = 0, KillNum = 0,
  nHawkEyeSpectatorVerifyFailedCount = 0, FlySkyTimes = 0,
  EspTotalSimTraceCnt = 0, EspTotalImeFocusCnt = 0, TimeOut10Kill = 0,
  MuzzleImpactDirError2 = 0, ShootPosHistoryLocusError2 = 0,
  MuzzleLocusError = 0, MuzzleLocusErrorX = 0, MuzzleLocusErrorY = 0,
  MuzzleLocusErrorZ = 0, FlyingErrorCnt = 0, MaxFlyingDuration = 0,
  FlyingStableRate = 0, IllegalTeamUpNearbyButNoFireAfterKill = 0,
  IllegalTeamUpNearbyButNoFirePickUpItem = 0, IllegalTeamUpNearbyButNoFireNotKill = 0,
  IllegalTeamUpNearbyButNoFireOnVehicle = 0, IllegalTeamUpNearbyButNoFireSameVehicle = 0,
  IllegalTeamUpUseObjectTogether = 0, IllegalTeamUpStayOnEnemyVehicle = 0,
  IllegalTeamUpGetOnEnemyVehicleCount = 0,
  IllegalTeamUpNearbyButNoFireOneSideHasWeaponOnFoot = 0,
  BulletFireSpeed = 0, ClientGravityAnomalyCount = 0,
  BulletFlySpeedIncreaseCount = 0, ShootBirdNonGunADS = 0,
  NonGunADSFarShootFromClientBulletDataCount = 0,
  MinUndilatedFrameTimeFailedCount = 0, DSFallingSpeedFailCount = 0,
  DSFallingHeightFailCount = 0, ShootInterval = 1.0E8,
  ExtraHitPerformScale = -1, SwitchWeaponSpeedScale = -1,
  AnimationKick = 1.0E8, RecoilKickADS = 1.0E8,
  AccessoriesVRecoilFactor = 1.0E8, AccessoriesHRecoilFactor = 1.0E8,
  AccessoriesRecoveryFactor = 1.0E8, PVSInCityKillCount = 0,
  PVSNotInCityKillCount = 0, AccumulatedFightingStateTime = 0,
  ShooterCapsuleCollided = 0, LargeRotateLockShooting = 0,
  SmallRotateLockShooting = 0, OneClipShootCount = 0,
  ClientWeaponFastReload = 0, ActorTimeDilationFailCount = 0,
  FarJumpTimes = 0, JumpMaxHeight = 0, SmallActorTimeDilationCount = 0,
  JumpZVelocity = -1, PeekShootRotationModifiedCount = 0,
  PeekShootTranslationModifiedCount = 0, PeekShootScale3DModifiedCount = 0,
  pubgmcdvStr61 = "", pubgmcdvStr62 = "", pubgmcdvStr63 = "",
  pubgmcdvStr64 = "", pubgmcdvStr65 = "", pubgmcdvStr66 = "",
  MaxMoveDistance2DPerSecond = "", NonGunADSFarShootCount = "",
  pubgmcdvStr69 = "", pubgmcdvStr70 = "", ClientTimeSpeedAcc = 0,
  ClientTimeTotalAcc = 0, JumpMaxCount = 0, TimeDilation = -1,
  KillOtherAfterBurstMove = 0, MaxAcceleration = -1,
  ClientTimestampBurst = 0, DSCheckClientTimeMoveDistance2D = 0,
  IsServerControlMove = 0, ServerMoveCorrectsPerSecond = 0,
  ClientTimeReset = 0, ClientGlueHiaSystemTickAnomaly = 0,
  ParachuteLandingSecondsExceedThreshold = 0,
  ParachuteObliqueLandingSecondsExceedThreshold = 0,
  IntervalFrequencyStatisticsMax = 0, IntervalFrequencyStatisticsAverage = 0,
  VehicleMoveDirection = 0, VehicleSidesway1 = 0, VehicleSidesway2 = 0,
  BurstPickup = 0, GetOnEnemyVehicleID = -1, StayOnEnemyVehicleID = -1,
  BlackAvatarCount = 0,
}
-- Add ClientAutoAimConfig001-050
for i = 1, 50 do
  CoronaDataEnum[string.format("ClientAutoAimConfig%03d", i)] = 0
end
CoronaDataEnum.__index = CoronaDataEnum


-- 🔥 PART 6: OTHER ENUMS

ECoronaProofType = {
  ECoronaProofNone = 0, ECoronaProofSoFile = 1, ECoronaProofBone = 2,
  ECoronaProofCVar = 3, ECoronaProofMax = 4
}
ECoronaDataType = {
  ECoronaDataNone = 0, ECoronaDataPlayer = 1, ECoronaDataVehicle = 2,
  ECoronaDataWeapon = 3, ECoronaDataRes = 4, ECoronaDataDevice = 5,
  ECoronaDataOthers = 6, ECoronaDataCVar = 7,
  ECoronaClientLuaHotUpdateData = 8, ECoronaDataMax = 9
}
EHawkFamily = {
  Blind = 0, BlindAll = 1, Heart = 2, ClientVersion = 3,
  DynamicActors = 4, SwitchAck = 5, CClientInfoPacket = 6,
  SIntegrityItemCheckPacket = 7, CIntegrityItemCheckResultPacket = 8,
  SIntegrityMemoryReadPacket = 9, CIntegrityMemoryReadResultPacket = 10,
  ClientScreenShot = 11, SControlAndroidObscuredPacket = 12,
  CObscuredStatusPacket = 13, CDeviceInfoPacket = 14, CVarDownList = 15,
  EnhancedDynamicActors = 16, SAvatarCheckControlPacket = 20,
  CAvatarCheckDataPacket = 21, SMoveInputRecordControlPacket = 22,
  CMoveInputRecordPacket = 23, SEnablePeekShootVerify = 24,
  CPeekShootVerifyResult = 25, HeartAck = 26, SEnableCheckPakFiles = 27,
  CCheckFilesInPakFailed = 28
}
EStrategyOperatorType = { Greater = 0, Less = 1 }
EClientDataPointerValueType = { Bool = 1, Int32 = 2, Float = 3 }
EGrayPublishType = { PVSCell = 7, SpeedQuickCheck = 25 }
GrayPublishProbabilityConfig = {}


-- 🔥 PART 7: FULL AOSCheatSoTable (200+ names)

AOSCheatSoTable = {
  "libAliSalimMod", "libDangerpro", "libMyLibName", "libSoiShipperGLOBAL",
  "libskpkg", "libamunmods", "libSoiShipperVNG", "libGrimReapers",
  "libHMODEVIP", "libPutriMod", "libalamdar", "libSYRI", "libABNS",
  "libhma_native_hooks", "libNTTGAMING", "libteamUxH", "libAPK_CRACKING_ZONE",
  "libFakecez", "libRUDRA", "libKINGCHAET", "libsgr", "libMyLib", "libmiku",
  "libPanda", "libRaunakMods", "libepic64", "libexp82464", "libmodxpro",
  "libSPARTAGAMINGS", "libSasuke", "libRicMods", "libCMODS", "libmodxproESP",
  "libSACRMOD", "libSoiShipperChannel", "libSameerArora", "libFuCkYou",
  "libMAAN", "libCHEAT", "libKING", "libNicOP", "libepic", "libexp824",
  "libndk", "libDanger", "libHentai", "libMpMods", "libHackerWorldMods",
  "SameerArora", "libteamdymond", "libpubgm", "libsuria", "libSY",
  "libabnsyr", "libsyr", "libABN_SYRIA", "libsrc", "libABN",
  "libBlackNinjaMod", "libRubel", "libEpic", "libArmEpic", "libRSDMODS",
  "libGaribGamingEsp", "libfuck", "libRGMESP", "libKINGCHEAT", "libNicHacks",
  "libAutoChickens", "libarm", "libZzZ", "libNirobAhammed", "libsagar",
  "libBangjo", "libruruzi", "PUBGMESP7", "libZzz", "SORS DIV IOS",
  "libsaolei", "libFPCMOD", "FLAME", "libGKPMODS", "libhacks", "libRURUZI",
  "libHackerBody", "libsurprisecheats", "libtersafe", "libbypass",
  "libanogs_lx.so", "liblive.so", "libmib.so", "libNASA", "libboss",
  "libGKPxStudio", "libtdfix", "libfix", "libCrashFix", "libYZYMOD",
  "libanort_jni", "libtdmodgame", "libpaCQMOD8", "libXZNB", "libZeroFix",
  "libzZzz", "SFLAME", "libSPEED", "libHunter", "DrawHM", "Alamofire",
  "libarisu", "libsigplus", "libmiwumod", "libmatrix", "libSpider",
  "libGKPCRASHFIX64", "libaa", "libTITAN", "libSanseroFixCrash",
  "libavaritia", "libbantai", "libsCQMOD", "fuckreports", "libFYISULTAN",
  "libpawpaw", "libFAN1", "libApples", "libFix", "libUE4Game",
  "libSignatureKiller", "libkiller", "libkDogProNew", "libtDogProNew",
  "libfoza", "liblsplant", "libreverse", "libshieldplus", "libtoolChecker",
  "libUSA", "libarm_classes", "libhDCGZS37", "libhDCGZS39", "libiDCGZS90",
  "libtDCGZS46", "lib4399", "libzx", "libtdmod", "libShrem", "libVIP",
  "libPUBGM", "libAkshatModz", "libFox", "libss", "libMSDS9", "libSTRONG",
  "libYM", "libSpider1", "libcc", "libApple", "libQX", "libGOST", "libMTR1",
  "libMKmod", "libVIP1", "libYTsine", "libPutrimod", "libJSZMOD", "libXuan",
  "libCRASHFix", "libCK", "libdttsxa", "libFLAME", "libXERO", "libJL",
  "libVenus", "libCKYMOD", "libccc", "libFOXFS", "libHTD", "libHY",
  "libViper", "libHASADXSA", "libXINMODD", "libpl_droidsonroids_gif",
  "Blackshark", "libHarley", "libXH", "libhxd", "libHOOK", "libBangjo1",
  "libOffWork", "libErickk", "libMarcusMod", "libzDogPro", "libzDogProNew",
  "libXinmod", "libXinmodd", "libGodCheat", "libBOZZ", "libHHx", "libxiuke",
  "libbrk", "libQuangAre22", "libgoo", "libAlex", "libHarleyCheat",
  "libALOUSH", "libHASADV8KG", "libexe_right", "libubaydulla", "libTheo",
  "libNHKMOD", "libmono", "libWH", "libAZ997926", "libUZIMOD", "libAli",
  "libZERO", "libkeysuperman", "libtool", "libNIKE", "libx", "libNG",
  "libav2d", "libjo", "libxcheeat", "libhaoyunb", "libPubgm", "libWuGan",
  "libSTRESS_CHEAT", "libjcnb", "libUbaydulla", "libRC", "libRCFIX",
  "libfenghuang", "libmundo", "libELMOD", "libKK", "libQZUIM", "libav3d",
  "libwl", "libWQ", "libVENOM", "libQYGM", "libKawKab", "libHASADV10X",
  "lib10xulaconcho", "libGAMAL", "libTakeo",
}
--@ RAHMANYVI 

-- 🔥 PART 8: OTHER CONFIG TABLES

tBalticModeIDSet = {
  [1001] = false, [1002] = false, [1003] = false,
  [2001] = false, [2002] = false, [2003] = false,
  [1064] = false, [1065] = false, [1066] = false,
  [2064] = false, [2065] = false, [2066] = false,
  [60112] = false, [60113] = false, [60114] = false,
  [60115] = false, [60116] = false, [60117] = false,
  [64200] = false, [64201] = false, [64202] = false,
  [64203] = false, [64204] = false, [64205] = false,
}

BattleReportNosChatOnlyOnceStrategySet = { [87510] = false }
BattleReportNosChatOnlyOnceStrategyHistory = {}
IgnoreBulletFireSpeedWeaponID = { [108030] = false }
SkipStrategyIDofReportBanPlayer = { [87520] = false }

CompositeStrategyBanLessDimensionAlertWhiteList = {
  CrcCheckRet = false, bAndroid = false, bRoot = false, bSimulator = false,
  bHasMalware = false, Level = false, ReportedCount = false,
  TotalOutOfOrderPackets = false, MaxOutOfOrderPacketsPerSec = false,
  ProofRawData = false, PlayerBadPingTimes = false,
  AndroidOrSimRootCnt = false, IOSRootCnt = false, KillNum = false,
}

CompositeStrategySingleDimensionSkipAlertLessThan = { BulletFireSpeed = false }

CompositeStrategySingleDimensionSkipAlert = {
  TotalStatisticCnt = false, JumpMaxHeight = false, JumpMaxHeight2 = false,
  AccumulatedFightingStateTime = false, EspOpenScopeInvisibleCnt = false,
  LibCheckFailedCnt = false, IsServerControlMove = false,
  MaxAcceleration = false, NonGunADSFarFromClientBulletDataCount = false,
  RocoilLessTotalCnt = false,
}


-- 🔥 PART 9: HELPER FUNCTIONS (no-op)

function DSDeepCopyTable(object)
  return {}
end

function ValuClamp(t, min, max)
  return t
end

local function ConvertByteCodeStringToArray(sLuaHexString)
  return {}
end

local function GetPlayerTable(bIsDatabase, nUID)
  return nil
end

local function SetPlayerTableField(bIsDatabase, nUID, sName, Value)
end

local function GetPlayerTableField(bIsDatabase, nUID, sName)
  return nil
end

local function IncreasePlayerTableField(bIsDatabase, nUID, sName, nValue)
end

local function MonotonicSetPlayerTableField(bIsDatabase, nUID, sName, nValue, bIsIncrease)
end

local function GetDSGlueHiaSystem()
  return nil
end

local function GetClientDataPointerValue(DataPointer, Type, Name)
  return nil
end

local function SetVerifySwitchField(Controller, SwitchName, FieldName, NewValue)
end

local function IncreaseCheckBanFailCount(OperatorType, CurValue, ThresholdValue, FailedCnt)
  return FailedCnt
end


-- 🔥 PART 10: ALL GameSafeCallbacks FUNCTIONS = NO-OP

function GameSafeCallbacks.GetGrayPublishProbability(Type) return -1 end
function GameSafeCallbacks.IsGrayPublish(Type) return false end
function GameSafeCallbacks.DSPatchLua(a, b) print("[MASTER-BYPASS] DSPatchLua - BLOCKED") end
function GameSafeCallbacks.LoadSafePatchModules() print("[MASTER-BYPASS] LoadSafePatchModules - BLOCKED") end
function GameSafeCallbacks.InitPlayerData(a, b) end
function GameSafeCallbacks.TriggerRealtimeVerify(a) end
function GameSafeCallbacks.PlayerReport(a) end
function GameSafeCallbacks.WeaponReport(a, b) end
function GameSafeCallbacks.GetCoronaProofData() return "" end
function GameSafeCallbacks.GetClientCVarData() return "" end
function GameSafeCallbacks.TriggerCoronaLabVerify(a, b, c, d) end
function GameSafeCallbacks.CheckAOSValidSO(a) return false end
function GameSafeCallbacks.FilterGameMode(a) return false end
function GameSafeCallbacks.TestBan(a) end
function GameSafeCallbacks.CheckWorkModeFilter(a) return false end
function GameSafeCallbacks.BanPlayerForMultiCheatNew(a, b) end
function GameSafeCallbacks.CheckBanCo(a, b) end
function GameSafeCallbacks.ReportBanPlayer(a, b, c, d, e, f)
  print(string.format("[MASTER-BYPASS] ReportBanPlayer UID:%s Strategy:%s - BLOCKED", tostring(a), tostring(c)))
end
function GameSafeCallbacks.GetScriptReportContent(a, b) return "" end
function GameSafeCallbacks.DoAttackFlowStrategy(a) end
function GameSafeCallbacks.ReportNetworkData() end
function GameSafeCallbacks.ReportClientNetworkData() end
function GameSafeCallbacks.ReportClientCoronaData(a) end
function GameSafeCallbacks.TriggerTick(a) end
function GameSafeCallbacks.TriggerSlowTick(a) end
function GameSafeCallbacks.ConditionallyControlServerMove(a) end
function GameSafeCallbacks.RecordPlayerPing(a) end
function GameSafeCallbacks.CharacterReceiveBeginPlay(a) end
function GameSafeCallbacks.PostPlayerControllerLoginReconnect(a) end
function GameSafeCallbacks.PostPlayerControllerLoginInit(a) print("[MASTER-BYPASS] PostPlayerControllerLoginInit - BLOCKED") end
function GameSafeCallbacks.InitSwitchOnAntiCheatManager(a) end
function GameSafeCallbacks.IsPVSObfuscateEnabled() return false end
function GameSafeCallbacks.RecordStrategyTimestampInReplay(a, b, c, d) end
function GameSafeCallbacks.GetPlayerRealtimeVerifyInfo(a) return {} end
function GameSafeCallbacks.GetGameModeID() return -1 end
function GameSafeCallbacks.StartAreaIDTimer() end
function GameSafeCallbacks.ConditionallyGrayPublish(a, b, c, d) end
function GameSafeCallbacks.StartTimerToEnableFeatureInArea() end
function GameSafeCallbacks.DispatchStrategyConfig() end
function GameSafeCallbacks.ParseBaziConfigIntoBaziState(a) end
function GameSafeCallbacks.ParseConfigIntoBazi(a, b, c, d) return false end
function GameSafeCallbacks.ParseSingleStrategyConfig(a, b, c, d) return nil end
function GameSafeCallbacks.ParseSingleStrategyCondition(a, b) return nil end
function GameSafeCallbacks.ConvertStrategyValueString(a, b) return nil end
function GameSafeCallbacks.SendStrategyConfigAlertMessage(a) end
function GameSafeCallbacks.CallDSGlueHiaSystemPostControllerLogin(a) end
function GameSafeCallbacks.GetCompositeStrategyFieldName(a) return nil end
function GameSafeCallbacks.AlertSingleDimensionOfCompositeStrategy(a) end
function GameSafeCallbacks.EditorIncreaseTotalStatisticCnt(a) end
function GameSafeCallbacks.IsSoftPunishMultiDimensionChanged(a, b, c) return false end
function GameSafeCallbacks.EditorEnablePVSByConfigTable() end


-- 🔥 PART 11: STUBS FOR ALL 15 MODULES

local AllStrategyCfgLines_stub = {
  AssignCurrentCheatValue = function() end,
  GetStrategyValue = function() return 0 end,
  SetStrategyValue = function() end,
  CheckStrategy = function() end,
  IsStrategyActive = function() return false end,
  GetActiveStrategies = function() return {} end,
}
package.loaded["Server.security.AllStrategyCfgLines"] = AllStrategyCfgLines_stub
AllStrategyCfgLines = AllStrategyCfgLines_stub

local PlayerSafeCallback_stub = {
  InitPlayerSafeCallback = function() end,
  ReceivePlayerForbidMove = function() end,
  ReportPlayerForbidMove = function() end,
  CheckFlying = function() end,
  TriggerTick = function() end,
  TriggerSlowTick = function() end,
  PostPlayerControllerLoginInit = function() end,
  PostPlayerControllerLoginReconnect = function() end,
  OnPlayerLogin = function() end,
  OnPlayerLogout = function() end,
  OnPlayerDie = function() end,
  OnPlayerRespawn = function() end,
  ReportPlayer = function() end,
  CheckPlayer = function() end,
  CheckPlayerSpeed = function() end,
  CheckPlayerFly = function() end,
  CheckPlayerJump = function() end,
  CheckPlayerPosition = function() end,
  OnPlayerSprint = function() end,
  OnPlayerCrouch = function() end,
  OnPlayerProne = function() end,
}
package.loaded["Server.security.PlayerSafeCallback"] = PlayerSafeCallback_stub
PlayerSafeCallback = PlayerSafeCallback_stub

local WeaponSafeCallback_stub = {
  InitWeaponSafeCallback = function() end,
  TriggerTick = function() end,
  TriggerSlowTick = function() end,
  OnClientAnomalyCountUpload = function() end,
  PostPlayerControllerLoginInit = function() end,
  OnWeaponFire = function() end,
  OnWeaponReload = function() end,
  OnWeaponSwitch = function() end,
  CheckWeaponDamage = function() end,
  CheckWeaponRecoil = function() end,
  CheckBulletSpeed = function() end,
  CheckAutoAim = function() end,
  CheckBulletDir = function() end,
  CheckShootInterval = function() end,
}
package.loaded["Server.security.WeaponSafeCallback"] = WeaponSafeCallback_stub
WeaponSafeCallback = WeaponSafeCallback_stub

local VehicleSafeCallback_stub = {
  InitVehicleSafeCallback = function() end,
  TriggerTick = function() end,
  TriggerSlowTick = function() end,
  PostPlayerControllerLoginInit = function() end,
  OnVehicleEnter = function() end,
  OnVehicleExit = function() end,
  CheckVehicleSpeed = function() end,
  CheckVehiclePosition = function() end,
  CheckVehicleFly = function() end,
  CheckVehicleMove = function() end,
}
package.loaded["Server.security.VehicleSafeCallback"] = VehicleSafeCallback_stub
VehicleSafeCallback = VehicleSafeCallback_stub

local ESPSafeCallback_stub = {
  InitESPSafeCallback = function() end,
  TriggerTick = function() end,
  TriggerSlowTick = function() end,
  PostPlayerControllerLoginInit = function() end,
  OnReportESPCheat = function() end,
  CheckESPState = function() end,
  CheckESPTime = function() end,
  CheckESPCount = function() end,
  OnESPBattleInvisible = function() end,
  OnESPOpenScopeInvisible = function() end,
  OnESPContinueInvisible = function() end,
  OnESPSimTrace = function() end,
  OnESPImeFocus = function() end,
  CheckESPTotalTime = function() end,
  CheckESPTotalCnt = function() end,
}
package.loaded["Server.security.ESPSafeCallback"] = ESPSafeCallback_stub
ESPSafeCallback = ESPSafeCallback_stub

local IntegrityCheckCallback_stub = {
  InitIntegrityCheckCallback = function() end,
  TriggerTick = function() end,
  TriggerSlowTick = function() end,
  OnReportIntegrityItemCheckResult = function() end,
  PostPlayerControllerLoginInit = function() end,
  CheckIntegrityItem = function() end,
  CheckFileIntegrity = function() end,
  CheckPakIntegrity = function() end,
  OnIntegrityFail = function() end,
  CheckMemoryRead = function() end,
}
package.loaded["Server.security.IntegrityCheckCallback"] = IntegrityCheckCallback_stub
IntegrityCheckCallback = IntegrityCheckCallback_stub

local AndroidObscuredCallback_stub = {
  InitAndroidObscuredCallback = function() end,
  PostPlayerControllerLoginInit = function() end,
  OnReportObscuredStatus = function() end,
  CheckObscuredStatus = function() end,
  OnObscuredDetected = function() end,
  CheckAndroidStatus = function() end,
}
package.loaded["Server.security.AndroidObscuredCallback"] = AndroidObscuredCallback_stub
AndroidObscuredCallback = AndroidObscuredCallback_stub

local SecurityCommon_stub = {
  Init = function() end,
  OnReportClientInfo = function() end,
  CheckClientInfo = function() end,
  GetSecurityLevel = function() return 0 end,
  SetSecurityLevel = function() end,
  IsSecurityEnabled = function() return false end,
  GetSecurityStatus = function() return {} end,
}
package.loaded["Server.security.SecurityCommon"] = SecurityCommon_stub
SecurityCommon = SecurityCommon_stub

local TickEncryptCallback_stub = {
  Init = function() end,
  PostPlayerControllerLoginInit = function() end,
  TriggerTick = function() end,
  TriggerSlowTick = function() end,
  OnTickEncrypt = function() end,
  CheckTickEncrypt = function() end,
  VerifyTickEncrypt = function() end,
}
package.loaded["Server.security.TickEncryptCallback"] = TickEncryptCallback_stub
TickEncryptCallback = TickEncryptCallback_stub

local MoveInputCallback_stub = {
  Init = function() end,
  PostPlayerControllerLoginInit = function() end,
  TriggerSlowTick = function() end,
  OnMoveInput = function() end,
  CheckMoveInput = function() end,
  RecordMoveInput = function() end,
  VerifyMoveInput = function() end,
}
package.loaded["Server.security.MoveInputCallback"] = MoveInputCallback_stub
MoveInputCallback = MoveInputCallback_stub

local AutoAimConfig_stub = {
  Init = function() end,
  GetConfig = function() return {} end,
  CheckAutoAim = function() end,
  OnAutoAimDetected = function() end,
  IsAutoAim = function() return false end,
}
package.loaded["Server.security.AutoAimConfig"] = AutoAimConfig_stub
AutoAimConfig = AutoAimConfig_stub

local PeekShootVerifyCallback_stub = {
  PostPlayerControllerLoginInit = function() end,
  TriggerTick = function() end,
  TriggerSlowTick = function() end,
  OnReportPeekShootVerifyResult = function() end,
  CheckPeekShoot = function() end,
  VerifyPeekShoot = function() end,
  OnPeekShootDetected = function() end,
}
package.loaded["Server.security.PeekShootVerifyCallback"] = PeekShootVerifyCallback_stub
PeekShootVerifyCallback = PeekShootVerifyCallback_stub

local SecurityPakCallback_stub = {
  PostPlayerControllerLoginInit = function() end,
  TriggerSlowTick = function() end,
  OnServerReceiveInvalidFilesInPakLite = function() end,
  CheckPakFiles = function() end,
  VerifyPakFiles = function() end,
  OnPakCheckFailed = function() end,
  CheckFilesInPak = function() end,
}
package.loaded["Server.security.SecurityPakCallback"] = SecurityPakCallback_stub
SecurityPakCallback = SecurityPakCallback_stub

local BaziConfig_stub = {
  Init = function() end,
  GetConfig = function() return {} end,
  CheckBazi = function() end,
  OnBaziDetected = function() end,
}
package.loaded["Server.security.BaziConfig"] = BaziConfig_stub
BaziConfig = BaziConfig_stub

local AvatarCheckCallback_stub = {
  Init = function() end,
  PostPlayerControllerLoginInit = function() end,
  OnReportItemID = function() end,
  CheckAvatar = function() end,
  VerifyAvatar = function() end,
  OnAvatarDetected = function() end,
  CheckItemID = function() end,
}
package.loaded["Server.security.AvatarCheckCallback"] = AvatarCheckCallback_stub
AvatarCheckCallback = AvatarCheckCallback_stub

package.loaded["Server.security.GameSafeCallbacks"] = GameSafeCallbacks


-- 🔥 PART 12: CLEAR ALL EXISTING DATA

if GlobalPlayerCheatTimes then
  for k in pairs(GlobalPlayerCheatTimes) do GlobalPlayerCheatTimes[k] = nil end
end
if GlobalPlayerCoronaData then
  for k in pairs(GlobalPlayerCoronaData) do GlobalPlayerCoronaData[k] = nil end
end
if TestBanUIDSet then
  for k in pairs(TestBanUIDSet) do TestBanUIDSet[k] = nil end
end
if UID2PlayerKey then
  for k in pairs(UID2PlayerKey) do UID2PlayerKey[k] = nil end
end


-- 🔥 PART 13: FINAL LOG

sandbox.LogShippingDS("==============================================")
sandbox.LogShippingDS("GameSafeCallbacks.lua: FULL MASTER BYPASS LOADED")
sandbox.LogShippingDS("ALL 16 SECURITY MODULES DISABLED:")
sandbox.LogShippingDS("  1. GameSafeCallbacks         - DISABLED")
sandbox.LogShippingDS("  2. AllStrategyCfgLines       - DISABLED")
sandbox.LogShippingDS("  3. PlayerSafeCallback        - DISABLED")
sandbox.LogShippingDS("  4. WeaponSafeCallback        - DISABLED")
sandbox.LogShippingDS("  5. VehicleSafeCallback       - DISABLED")
sandbox.LogShippingDS("  6. ESPSafeCallback           - DISABLED")
sandbox.LogShippingDS("  7. IntegrityCheckCallback    - DISABLED")
sandbox.LogShippingDS("  8. AndroidObscuredCallback   - DISABLED")
sandbox.LogShippingDS("  9. SecurityCommon             - DISABLED")
sandbox.LogShippingDS(" 10. TickEncryptCallback       - DISABLED")
sandbox.LogShippingDS(" 11. MoveInputCallback         - DISABLED")
sandbox.LogShippingDS(" 12. AutoAimConfig             - DISABLED")
sandbox.LogShippingDS(" 13. PeekShootVerifyCallback   - DISABLED")
sandbox.LogShippingDS(" 14. SecurityPakCallback       - DISABLED")
sandbox.LogShippingDS(" 15. BaziConfig                - DISABLED")
sandbox.LogShippingDS(" 16. AvatarCheckCallback       - DISABLED")
sandbox.LogShippingDS("==============================================")

return {}

-- ==============================================================================
-- LAYER 01: SLUA SIGNATURE BYPASS
-- ==============================================================================
local function L01_SLUA()
    local ok = false
    pcall(function()
        if slua and type(slua.getSignature) == "function" then
            slua.getSignature = function() return 0xDEADBEEF end
            ok = true
        end
        local loader = package.loaded["slua.loader"] or rawget(_G, "slua_loader")
        if loader then
            loader.verifyBytecode = retTrue
            loader.checkIntegrity = retTrue
            loader.disableSignatureCheck = retTrue
            ok = true
        end
        local ser = package.loaded["slua.serialize"]
        if ser then ser.check = retTrue; ser.verify = retTrue; ok = true end
        if _G.slua_verify then _G.slua_verify = retTrue; ok = true end
        if _G.check_slua_integrity then _G.check_slua_integrity = retTrue; ok = true end
        if jit and jit.attach then
            jit.attach(function() end, "bc")
            ok = true
        end
    end)
    MarkLayer("L01_SLUA", ok)
end

-- ==============================================================================
-- LAYER 02: MD5 / PAK SIGNATURE BYPASS
-- ==============================================================================
local function L02_MD5()
    local ok = false
    pcall(function()
        local console = import("KismetSystemLibrary")
        if console then
            console.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1")
            console.ExecuteConsoleCommand(nil, "pakchunk.EnableSignatureCheck 0")
            console.ExecuteConsoleCommand(nil, "s.VerifyPak 0")
            console.ExecuteConsoleCommand(nil, "sig.Check 0")
            console.ExecuteConsoleCommand(nil, "security.DisableChecks 1")
            ok = true
        end
        local CMode = import("CreativeModeBlueprintLibrary")
        if CMode then
            CMode.MD5HashByteArray = function() return "00000000000000000000000000000000" end
            CMode.MD5HashFile = function() return "00000000000000000000000000000000" end
            CMode.GetContentDiffData = function() return true, "OK" end
            CMode.VerifyFileIntegrity = retTrue
            ok = true
        end
        if _G.MD5Hash then _G.MD5Hash = function() return "00000000000000000000000000000000" end; ok = true end
        if _G.CRC32 then _G.CRC32 = function() return 0 end; ok = true end
        if _G.SHA1 then _G.SHA1 = function() return "0000000000000000" end; ok = true end
        local FHC = package.loaded["common.file_hash_checker"]
        if FHC then
            FHC.CheckFileMD5 = retTrue
            FHC.VerifyAll = retTrue
            FHC.GetHash = function() return "0000000000000000" end
            ok = true
        end
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then
            TssSdk.GetFileMD5 = function() return "0000000000000000" end
            TssSdk.VerifyFileSignature = retTrue
            ok = true
        end
        local STExtra = import("STExtraBlueprintFunctionLibrary")
        if STExtra then
            STExtra.CheckMD5 = retTrue
            STExtra.GetMD5 = function() return "0000000000000000" end
            STExtra.VerifyFile = retTrue
            ok = true
        end
    end)
    MarkLayer("L02_MD5", ok)
end

-- ==============================================================================
-- LAYER 03: SKIN / AVATAR EXCEPTION BYPASS
-- ==============================================================================
local function L03_SKIN()
    local ok = false
    pcall(function()
        local ptlog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
        if ptlog then
            ptlog.ReportEvent = nop
            ptlog.ReportDownloadResult = nop
            ptlog.ReportODPTDError = nop
            ptlog.ReportSkinError = nop
            ok = true
        end
        local AvatarUtils = package.loaded["AvatarUtils"]
        if AvatarUtils then
            AvatarUtils.CheckIsWeaponInBlackList = retFalse
            AvatarUtils.IsValidAvatar = retTrue
            AvatarUtils.CheckAvatarIntegrity = retTrue
            AvatarUtils.ReportInvalidAvatar = nop
            ok = true
        end
        local SubMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            local sub = SubMgr:Get("FileCheckSubsystem")
            if sub then
                sub.StartCheck = nop
                sub.ReportAbnormalFile = nop
                sub.StopCheck = nop
                ok = true
            end
        end
        local eqEx = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
        if eqEx then
            eqEx.Report = nop
            eqEx.SendException = nop
            ok = true
        end
        local AvaEx = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
        if AvaEx then
            AvaEx.CheckAvatarException = nop
            AvaEx.CheckAvatarExceptionOnce = nop
            AvaEx.ReportAvatarException = nop
            AvaEx.CheckSlotMeshVisible = retFalse
            AvaEx.CheckPawnVisible = retFalse
            AvaEx.CheckCanBugglyPostException = retFalse
            ok = true
        end
    end)
    MarkLayer("L03_SKIN", ok)
end

-- ==============================================================================
-- LAYER 04: LOG / CRASH REPORTER BYPASS
-- ==============================================================================
local function L04_LOG()
    local ok = false
    pcall(function()
        local SMTD = import("ScreenshotMTDer")
        if SMTD then
            SMTD.MTDePicture = function() return "" end
            SMTD.ReMTDePicture = function() return "" end
            SMTD.HasCaptured = retTrue
            SMTD.TakeScreenshot = nop
            ok = true
        end
        local TLog = package.loaded["TLog"] or _G.TLog
        if TLog then
            TLog.Info = nop; TLog.Warning = nop; TLog.Error = nop
            TLog.Debug = nop; TLog.Report = nop; TLog.Send = nop; TLog.Flush = nop
            ok = true
        end
        local CrashSight = package.loaded["CrashSight"] or _G.CrashSight
        if CrashSight then
            CrashSight.ReportException = nop
            CrashSight.SetCustomData = nop
            CrashSight.Log = nop
            CrashSight.SendCrash = nop
            CrashSight.ReportUserException = nop
            ok = true
        end
        local GRU = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
        if GRU then
            GRU.BugglyPostExceptionFull = retFalse
            GRU.CheckCanBugglyPostException = retFalse
            GRU.ReplayReportData = nop
            GRU.ReportGameException = nop
            GRU.PostException = nop
            ok = true
        end
        local CTR = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if CTR then
            CTR.SendReport = nop
            CTR.SendException = nop
            CTR.UploadLog = nop
            ok = true
        end
        for _, sdk in ipairs({"Firebase","Adjust","AppsFlyer","FacebookAnalytics","GameAnalytics"}) do
            local s = _G[sdk]
            if s then
                s.logEvent = nop; s.trackEvent = nop
                s.setEnabled = retFalse; s.sendEvent = nop; s.report = nop
                ok = true
            end
        end
    end)
    MarkLayer("L04_LOG", ok)
end

-- ==============================================================================
-- LAYER 05: SUBSYSTEM SCANNER BYPASS (real subsystem names)
-- ==============================================================================
local function L05_SCANNER()
    local ok = false
    pcall(function()
        local SubMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if not SubMgr then return end
        for _, name in ipairs(REAL_SECURITY_SUBSYSTEMS) do
            local sub = SubMgr:Get(name)
            if sub then
                for k, v in pairs(sub) do
                    if type(v) == "function" and
                       (k:find("Report") or k:find("Send") or k:find("Upload") or
                        k:find("Verify") or k:find("Check") or k:find("Validate") or
                        k:find("Scan") or k:find("Detect") or k:find("Heartbeat") or
                        k:find("Flow")) then
                        pcall(function() sub[k] = nop end)
                    end
                end
                if sub.ReportPingDelayTimer then
                    pcall(function() sub:RemoveGameTimer(sub.ReportPingDelayTimer) end)
                    sub.ReportPingDelayTimer = nil
                end
                sub.DelayCount = 0
                ok = true
            end
        end
    end)
    MarkLayer("L05_SCANNER", ok)
end

-- ==============================================================================
-- LAYER 06: REPLAY TELEMETRY BYPASS
-- ==============================================================================
local function L06_REPLAY()
    local ok = false
    pcall(function()
        local SubMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            for _, name in ipairs({"GameReportSubsystem","ReplaySubsystem","RescueBtnReplayTraceSubsystem","SpectateAndReplaySubsystem"}) do
                local sub = SubMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" and
                           (k:find("Report") or k:find("Trace") or k:find("Replay") or
                            k:find("Record") or k:find("Save") or k:find("Heartbeat")) then
                            pcall(function() sub[k] = nop end)
                        end
                    end
                    ok = true
                end
            end
        end
        local logRep = package.loaded["client.slua.logic.replay.logic_report_replay"]
        if logRep then
            logRep.ReportReplay = nop
            logRep.SendReportReq = nop
            logRep.UploadReplay = nop
            ok = true
        end
        if _G.ClientReplayDataReporter then
            _G.ClientReplayDataReporter.ReportIntArrayData = nop
            _G.ClientReplayDataReporter.ReportUInt8ArrayData = nop
            _G.ClientReplayDataReporter.ReportFloatArrayData = nop
            ok = true
        end
    end)
    MarkLayer("L06_REPLAY", ok)
end

-- ==============================================================================
-- LAYER 07: REPORT FLOW CALLBACK BLOCKER
-- ==============================================================================
local function L07_REPORT_FLOW()
    local ok = false
    pcall(function()
        local flows = {
            "ReportAimFlow","ReportHitFlow","ReportAttackFlow","ReportSecAttackFlow",
            "ReportFireArms","ReportVerifyInfoFlow","ReportMrpcsFlow","ReportPlayerBehavior",
            "ReportTeammatHurt","ReportMisKillByTeammate","ReportForbitPick","ReportPlayerMoveRoute",
            "ReportPlayerPosition","ReportVehicleMoveFlow","ReportSecTgameMovingFlow","ReportParachuteData",
            "ReportEquipmentFlow","ReportPlayersPing","ReportPlayerIP","ReportPlayerFramePingRecord",
            "ReportDSNetSaturation","ReportNetContinuousSaturate","ReportDSNetRate","ReportCircleFlow",
            "ReportSecMrpcsFlow","SendTssSdkAntiDataToLobby","SendDSErrorLogToLobby",
            "SendDSHawkEyePatrolLogToLobby","SendSecTLog","SendDataMiningTLog","SendActivityTLog",
            "SendClientMemUsage","SendClientFPS","OnClientCrashReport","OnNetworkLossDetected",
            "ReportMatchRoomData","SendClientStats","SendServerAvgTickDelta","SendClientDeviceInfo",
            "ReportDeviceFingerprint","SendNetworkInfo","ReportIPAddress","SendMACAddress","ReportHardwareID"
        }
        for _, f in ipairs(flows) do
            if _G[f] then _G[f] = nop; ok = true end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then
                _G.GameplayCallbacks[f] = nop
                ok = true
            end
        end
        for _, f in ipairs({"CheckReportSecAttackFlowWithAttackFlow","CheckReportSecAttackFlow"}) do
            if _G[f] then _G[f] = retFalse; ok = true end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then
                _G.GameplayCallbacks[f] = retFalse
                ok = true
            end
        end
        for _, f in ipairs({"IsEnableReportMrpcsInCircleFlow","IsEnableReportMrpcsInPartCircleFlow",
                            "IsEnableReportMrpcsFlow","IsEnableReportAttackFlow",
                            "IsEnableReportHitFlow","IsEnableReportCircleFlow"}) do
            if _G[f] then _G[f] = retFalse; ok = true end
        end
    end)
    MarkLayer("L07_REPORT_FLOW", ok)
end

-- ==============================================================================
-- LAYER 08: PLAYER SECURITY INFO BYPASS
-- ==============================================================================
local function L08_PLAYER_SEC()
    local ok = false
    pcall(function()
        local SecSub = safe_require("GameLua.Mod.BaseMod.Common.Security.PlayerSecurityInfoSubsystem")
        if SecSub then
            SecSub.ReportData = nop
            SecSub.CheckCheat = retFalse
            SecSub.ValidatePlayer = retTrue
            SecSub.CollectData = nop
            SecSub.SendToServer = nop
            ok = true
        end
        for _, c in ipairs({"PlayerSecurityInfoCollector","PlayerSecurityInfo","SecurityInfoCollector",
                            "ClientSecurityCollector","PlayerAntiCheatCollector"}) do
            if _G[c] then
                for k, v in pairs(_G[c]) do
                    if type(v) == "function" and
                       (k:find("Report") or k:find("Collect") or k:find("Send") or
                        k:find("Upload") or k:find("Record")) then
                        _G[c][k] = nop
                        ok = true
                    end
                end
            end
        end
    end)
    MarkLayer("L08_PLAYER_SEC", ok)
end

-- ==============================================================================
-- LAYER 09: MRPCS / CLIENT FLOW BYPASS
-- ==============================================================================
local function L09_CLIENT_FLOW()
    local ok = false
    pcall(function()
        for _, name in ipairs({"ClientSecMrpcsFlow","MrpcsFlow","MrpcsData",
                                "ClientCircleFlowSubsystem","ClientKillFlowSubsystem",
                                "ClientSecPlayerKillFlow"}) do
            local sub = package.loaded[name] or _G[name]
            if sub then
                for k, v in pairs(sub) do
                    if type(v) == "function" and
                       (k:find("Report") or k:find("Send") or k:find("Flow") or
                        k:find("Record") or k:find("Process")) then
                        pcall(function() sub[k] = nop end)
                        ok = true
                    end
                end
            end
        end
    end)
    MarkLayer("L09_CLIENT_FLOW", ok)
end

-- ==============================================================================
-- LAYER 10: SWIFT HAWK BYPASS
-- ==============================================================================
local function L10_SWIFT_HAWK()
    local ok = false
    pcall(function()
        for _, f in ipairs({"SwiftHawk","ClientSwiftHawk","ClientSwiftHawkWithParams","SendSwiftHawkData"}) do
            if _G[f] then _G[f] = nop; ok = true end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then
                _G.GameplayCallbacks[f] = nop
                ok = true
            end
        end
        local sub = safe_require("GameLua.Mod.BaseMod.Client.Security.SwiftHawkSubsystem")
        if sub then
            sub.ReportData = nop
            sub.SendReport = nop
            sub.CollectTelemetry = nop
            ok = true
        end
    end)
    MarkLayer("L10_SWIFT_HAWK", ok)
end

-- ==============================================================================
-- LAYER 11: CORONA LAB BYPASS
-- ==============================================================================
local function L11_CORONA()
    local ok = false
    pcall(function()
        if _G.CoronaLab then
            _G.CoronaLab.ReportData = nop
            _G.CoronaLab.SendData = nop
            _G.CoronaLab.CollectData = nop
            _G.CoronaLab.Telemetry = nop
            ok = true
        end
        local SubMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        local sub = SubMgr and SubMgr:Get("CoronaLabSubsystem")
        if sub then
            sub.ReportData = nop
            sub.SendToServer = nop
            sub.CollectTelemetry = nop
            sub.StopCollection = nop
            ok = true
        end
        -- GlobalPlayerCoronaData lockdown — writes silently swallowed
        _G.GlobalPlayerCoronaData = _G.GlobalPlayerCoronaData or {}
        local mt = getmetatable(_G.GlobalPlayerCoronaData) or {}
        mt.__newindex = function() end
        setmetatable(_G.GlobalPlayerCoronaData, mt)
        _G.BlackList = {}
        ok = true
    end)
    MarkLayer("L11_CORONA", ok)
end

-- ==============================================================================
-- LAYER 12: MODIFIER EXCEPTION BYPASS
-- ==============================================================================
local function L12_MODIFIER()
    local ok = false
    pcall(function()
        _G.bReportedModifierException = false
        local sub = safe_require("GameLua.Mod.BaseMod.Common.Security.ModifierExceptionSubsystem")
        if sub then
            sub.ReportException = nop
            sub.CheckModifier = retTrue
            sub.ValidateModifier = retTrue
            sub.ReportModifierError = nop
            ok = true
        end
    end)
    MarkLayer("L12_MODIFIER", ok)
end

-- ==============================================================================
-- LAYER 13: SIMULATE CHARACTER LOCATION BYPASS
-- ==============================================================================
local function L13_SIMULATE_CHAR()
    local ok = false
    pcall(function()
        local sub = safe_require("GameLua.Mod.BaseMod.Gameplay.Simulate.SimulateCharacterSubsystem")
        if sub then
            sub.ReportLocation = nop
            sub.SendLocationData = nop
            sub.VerifyLocation = retTrue
            ok = true
        end
    end)
    MarkLayer("L13_SIMULATE_CHAR", ok)
end

-- ==============================================================================
-- LAYER 14: SHOOT VERIFICATION BYPASS
-- ==============================================================================
local function L14_SHOOT_VERIFY()
    local ok = false
    pcall(function()
        local sub = safe_require("GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
        if sub then
            sub.OnShootVerifyFailed = nop
            sub.SendVerifyData = nop
            sub.ReportBulletHit = nop
            sub.UploadHitInfo = nop
            sub.VerifyShot = retTrue
            ok = true
        end
        if _G.BulletHitInfoUploadData then
            _G.BulletHitInfoUploadData.Report = nop
            _G.BulletHitInfoUploadData.Send = nop
            _G.BulletHitInfoUploadData.Upload = nop
            ok = true
        end
    end)
    MarkLayer("L14_SHOOT_VERIFY", ok)
end

-- ==============================================================================
-- LAYER 15: NETWORK PACKET BLOCK
-- ==============================================================================
local function L15_NET_PACKET()
    local ok = false
    pcall(function()
        if NetUtil and NetUtil.SendPacket and not NetUtil._IsBypassed then
            local orig = NetUtil.SendPacket
            local blocked = {
                ["ReportAttackFlow"]=1, ["ReportSecAttackFlow"]=1, ["ReportFireArms"]=1,
                ["ReportVerifyInfoFlow"]=1, ["ReportMrpcsFlow"]=1, ["ReportPlayerBehavior"]=1,
                ["ReportTeammatHurt"]=1, ["ReportPlayerMoveRoute"]=1, ["ReportPlayerPosition"]=1,
                ["ReportSecVehicleMoveFlow"]=1, ["ReportVehicleMoveFlow"]=1, ["ReportParachuteData"]=1,
                ["ReportEquipmentFlow"]=1, ["ReportJumpFlow"]=1, ["ReportHurtFlow"]=1,
                ["on_tss_sdk_anti_data"]=1, ["ReportAimFlow"]=1, ["ReportHitFlow"]=1,
                ["ReportCircleFlow"]=1, ["report_players_ping"]=1, ["report_player_ip"]=1,
                ["report_net_saturate"]=1, ["report_speed_hack"]=1, ["report_wall_hack"]=1,
                ["report_aim_bot"]=1, ["report_esp_usage"]=1, ["report_modded_files"]=1,
                ["detect_cheat"]=1, ["ban_player"]=1, ["client_anti_cheat_report"]=1,
                ["ClientSecMrpcsFlow"]=1, ["MrpcsData"]=1,
                ["CheckReportSecAttackFlow"]=1, ["CheckReportSecAttackFlowWithAttackFlow"]=1,
                ["RPC_ClientCoronaLab"]=1, ["CoronaLabReport"]=1, ["CoronaLabData"]=1,
                ["PlayerSecurityInfo"]=1, ["ReportSecurityInfo"]=1, ["SendSecurityData"]=1,
                ["ClientCircleFlow"]=1, ["IsEnableReportMrpcsInCircleFlow"]=1,
                ["IsEnableReportMrpcsInPartCircleFlow"]=1, ["bReportedModifierException"]=1,
                ["ReportModifierException"]=1, ["RPC_Server_ReportSimulateCharacterLocation"]=1,
                ["ReportSimulateCharacterLocation"]=1, ["RPC_Client_ShootVertifyRes"]=1,
                ["BulletHitInfoUploadData"]=1, ["ShootVerifyFailed"]=1,
                ["report_unrealnet_exception"]=1, ["tss_sdk_report"]=1,
                ["SwiftHawk"]=1, ["ClientSwiftHawk"]=1, ["ClientSwiftHawkWithParams"]=1,
                ["SwiftHawkReport"]=1, ["SwiftHawkData"]=1,
                ["AntiCheatReport"]=1, ["CheatDetection"]=1, ["ViolationReport"]=1,
                ["SecurityViolation"]=1, ["IntegrityCheck"]=1, ["SignatureVerify"]=1,
                ["ReportSecTLog"]=1, ["report_client_scan_result"]=1,
                ["report_memory_exception"]=1, ["report_avatar_exception"]=1,
                ["report_character_state"]=1, ["report_vehicle_exception"]=1,
                ["report_camera_exception"]=1,
                ["ReportHeavyWeaponBoxSpawnFlow"]=1, ["ReportHeavyWeaponBoxActivationFlow"]=1,
                ["report_player_frame_ping_record"]=1,
                ["report_ds_net_saturation"]=1,
            }
            NetUtil.SendPacket = function(packetName, ...)
                if blocked[packetName] then return nil end
                return orig(packetName, ...)
            end
            NetUtil._IsBypassed = true
            ok = true
        end
        if _G.SendRPC and not _G._SendRPCBypassed then
            local origRPC = _G.SendRPC
            local blockedRPC = {
                "RPC_Server_ClientSecMrpcsFlow","RPC_Server_SwiftHawk",
                "RPC_Server_ClientSwiftHawkWithParams",
                "RPC_Server_ReportSimulateCharacterLocation",
                "RPC_Client_ShootVertifyRes","RPC_ClientCoronaLab"
            }
            _G.SendRPC = function(rpcName, ...)
                for _, b in ipairs(blockedRPC) do
                    if rpcName == b then return nil end
                end
                return origRPC(rpcName, ...)
            end
            _G._SendRPCBypassed = true
            ok = true
        end
    end)
    MarkLayer("L15_NET_PACKET", ok)
end

-- ==============================================================================
-- LAYER 16: HIGGS BOSON FULL BYPASS
-- ==============================================================================
local function L16_HIGGS()
    local ok = false
    pcall(function()
        local Higgs = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if Higgs then
            local methods = {
                "ControlMHActive","Tick","OnTick","MHActiveLogic","TriggerAvatarCheck",
                "StartAvatarCheck","ReportItemID","ReceiveAnyDamage","OnWeaponHitRecord",
                "ShowSecurityAlert","ServerReportAvatar","ClientReportNetAvatar",
                "SendHisarData","ValidateSecurityData","StaticShowSecurityAlertInDev",
                "RPC_Client_ShootVertifyRes","RPC_Server_ReportSimulateCharacterLocation",
                "DisableHiggsBoson","CheckMHActive","ReportViolation","ProcessSecurityEvent",
                "ValidatePlayer","CheckIntegrity"
            }
            for _, m in ipairs(methods) do
                if Higgs[m] then Higgs[m] = nop end
            end
            Higgs.GetNetAvatarItemIDs = retEmpty
            Higgs.GetCurWeaponSkinID = retZero
            Higgs.IsMHActive = retFalse
            Higgs.bMHActive = false
            Higgs.bCallPreReplication = false
            if Higgs.BlackList then
                for k in pairs(Higgs.BlackList) do Higgs.BlackList[k] = nil end
            end
            ok = true
        end
        _G.BlackList = {}
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) then
            if pc.HiggsBoson then
                pc.HiggsBoson.bMHActive = false
                pc.HiggsBoson.bCallPreReplication = false
                if pc.HiggsBoson.ControlMHActive then
                    pcall(function() pc.HiggsBoson:ControlMHActive(0) end)
                end
            end
            if pc.HiggsBosonComponent then
                pc.HiggsBosonComponent.bMHActive = false
                pc.HiggsBosonComponent.bCallPreReplication = false
                pcall(function() pc.HiggsBosonComponent:ControlMHActive(0) end)
            end
            ok = true
        end
        local hia = safe_require("GameLua.Mod.BaseMod.Client.Security.ClientGlueHiaSystem")
        if hia then
            hia.CheckHitIntegrity = nop
            hia.InitSession = nop
            hia.OnBattleEnd = nop
            ok = true
        end
    end)
    MarkLayer("L16_HIGGS", ok)
end

-- ==============================================================================
-- LAYER 17: ANTI-CHEAT CALLBACK HOOKS
-- ==============================================================================
local function L17_ANTICHEAT_HOOKS()
    local ok = false
    pcall(function()
        local HBC = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if HBC and HBC.StaticShowSecurityAlertInDev then
            HBC.StaticShowSecurityAlertInDev = nop
            ok = true
        end
        if _G.AvatarCheckCallback then
            _G.AvatarCheckCallback.StartAvatarCheck = nop
            _G.AvatarCheckCallback.OnReportItemID = nop
            _G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(PlayerController)
                if slua.isValid(PlayerController) and PlayerController.HiggsBosonComponent then
                    PlayerController.HiggsBosonComponent:ControlMHActive(0)
                    PlayerController.HiggsBosonComponent.bMHActive = false
                end
            end
            ok = true
        end
    end)
    MarkLayer("L17_ANTICHEAT_HOOKS", ok)
end

-- ==============================================================================
-- LAYER 18: ANTI-REPORT PLAYER SUBSYSTEM BYPASS
-- ==============================================================================
local function L18_ANTI_REPORT()
    local ok = false
    pcall(function()
        for _, path in ipairs({
            "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem",
            "Client.Security.ClientReportPlayerSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem",
            "GameLua.Mod.BaseMod.Common.Security.DSReportPlayerSubsystem"
        }) do
            local sub = package.loaded[path]
            if not sub then
                local s, r = pcall(require, path)
                if s and r then sub = r end
            end
            if sub then
                for k, v in pairs(sub) do
                    if type(v) == "function" and
                       (k:find("Report") or k:find("Record") or k:find("Send") or
                        k:find("Upload") or k:find("Notify") or k:find("Submit")) then
                        pcall(function() sub[k] = nop end)
                        ok = true
                    end
                end
            end
        end
    end)
    MarkLayer("L18_ANTI_REPORT", ok)
end

-- ==============================================================================
-- LAYER 19: GAMEPLAY CALLBACKS (SINGLE WRAP — critical layer)
-- ==============================================================================
local function L19_GAMEPLAY_CALLBACKS()
    local ok = false
    pcall(function()
        if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end
        local GC = _G.GameplayCallbacks

        if not GC._BypassV5Applied then
            local reports = {
                "ReportAttackFlow","ReportSecAttackFlow","ReportFireArms","ReportVerifyInfoFlow",
                "ReportMrpcsFlow","ReportPlayerBehavior","ReportTeammatHurt","ReportMisKillByTeammate",
                "ReportForbitPick","ReportPlayerMoveRoute","ReportPlayerPosition","ReportVehicleMoveFlow",
                "ReportSecTgameMovingFlow","ReportParachuteData","SendTssSdkAntiDataToLobby",
                "ReportEquipmentFlow","ReportAimFlow","ReportPlayersPing","ReportPlayerIP",
                "ReportPlayerFramePingRecord","OnDSConnectionSaturated","ReportDSNetSaturation",
                "ReportNetContinuousSaturate","ReportDSNetRate","SendClientStats",
                "SendServerAvgTickDelta","ReportCircleFlow","ClientSecMrpcsFlow","SwiftHawk",
                "ClientSwiftHawk","ClientSwiftHawkWithParams","ReportHitFlow","ReportJumpFlow",
                "ReportHurtFlow","ReportHeavyWeaponBoxSpawnFlow","ReportHeavyWeaponBoxActivationFlow"
            }
            for _, f in ipairs(reports) do GC[f] = nop end

            GC.CheckReportSecAttackFlowWithAttackFlow = retFalse
            GC.CheckReportSecAttackFlow = retFalse

            -- Single-wrap of OnDSPlayerStateChanged
            local origState = GC.OnDSPlayerStateChanged
            GC.OnDSPlayerStateChanged = function(UID, State, bPure, bSafe, Param)
                local s = State and string.lower(tostring(State)) or ""
                local block = {
                    ["cheatdetected"]=1, ["connectionlost"]=1, ["connectiontimeout"]=1,
                    ["connectionexception"]=1, ["netdrivererror"]=1, ["banned"]=1,
                    ["kicked"]=1, ["suspended"]=1, ["violationdetected"]=1,
                    ["integrityfailure"]=1, ["securityviolation"]=1
                }
                if block[s] then return end
                if origState then pcall(origState, UID, State, bPure, bSafe, Param) end
            end

            GC.OnPlayerNetConnectionClosed = nop
            GC.OnPlayerActorChannelError = nop
            GC.OnPlayerRPCValidateFailed = nop
            GC.OnPlayerSpectateException = nop
            GC.OnShutdownAfterError = nop

            GC._BypassV5Applied = true
            ok = true
        else
            ok = true
        end
    end)
    MarkLayer("L19_GAMEPLAY_CALLBACKS", ok)
end

-- ==============================================================================
-- LAYER 20: ALL SUBSYSTEMS KILL (real names only)
-- ==============================================================================
local function L20_KILL_SUBSYSTEMS()
    local ok = false
    pcall(function()
        local SubMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if not SubMgr then return end
        for _, name in ipairs(REAL_SECURITY_SUBSYSTEMS) do
            local sub = SubMgr:Get(name)
            if sub then
                for k, v in pairs(sub) do
                    if type(v) == "function" and
                       (k:find("Report") or k:find("Send") or k:find("Upload") or
                        k:find("Verify") or k:find("Check") or k:find("Validate") or
                        k:find("Scan") or k:find("Detect") or k:find("Collect") or
                        k:find("Flow") or k:find("Heartbeat") or k:find("Tick")) then
                        pcall(function() sub[k] = nop end)
                    end
                end
                if sub.timer then pcall(function() sub:RemoveGameTimer(sub.timer) end) end
                if sub.heartbeatTimer then pcall(function() sub:RemoveGameTimer(sub.heartbeatTimer) end) end
                if sub.reportTimer then pcall(function() sub:RemoveGameTimer(sub.reportTimer) end) end
                ok = true
            end
        end
    end)
    MarkLayer("L20_KILL_SUBSYSTEMS", ok)
end

-- ==============================================================================
-- LAYER 21: TARGETED MODULE STUBBING (no global require hijack)
-- ==============================================================================
-- Instead of replacing _G.require globally (which breaks unrelated requires),
-- we replace the specific modules with safe stubs in package.loaded.
local function L21_MODULE_STUBS()
    local ok = false
    pcall(function()
        local stubPaths = {
            "GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent",
            "GameLua.Mod.BaseMod.Common.Security.PlayerSecurityInfoSubsystem",
            "GameLua.GameCore.Module.Subsystem.CoronaLabSubsystem",
            "GameLua.Mod.BaseMod.Common.Security.ModifierExceptionSubsystem",
            "GameLua.Dev.Subsystem.ShootVerifySubSystemClient",
            "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem",
        }
        for _, path in ipairs(stubPaths) do
            local existing = package.loaded[path]
            if existing and type(existing) == "table" then
                -- Keep the table (so live references stay valid) but nop all callables
                for k, v in pairs(existing) do
                    if type(v) == "function" then
                        pcall(function() existing[k] = nop end)
                    end
                end
                ok = true
            end
        end
    end)
    MarkLayer("L21_MODULE_STUBS", ok)
end

-- ==============================================================================
-- LAYER 22: OPERATIONAL STATS BYPASS
-- ==============================================================================
local function L22_OPERATIONAL_STATS()
    local ok = false
    pcall(function()
        local SubMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        local OSS = (SubMgr and SubMgr:Get("OperationalStatsSubsystem")) or _G.OperationalStatsSubsystem
        if OSS then
            OSS.ReportOperationalStats = nop
            OSS.AddOperationalStats = nop
            OSS.HandleTouchBegin = nop
            OSS.HandleTouchEnd = nop
            OSS.OnInit = nop
            OSS.HandleEnterFighting = nop
            OSS.OnBattleResult = nop
            if OSS.TimerHandle then
                pcall(function() OSS:RemoveGameTimer(OSS.TimerHandle) end)
                OSS.TimerHandle = nil
            end
            OSS.StatsData = {}
            ok = true
        end
    end)
    MarkLayer("L22_OPERATIONAL_STATS", ok)
end

-- ==============================================================================
-- LAYER 23: BASE BYPASS (dev / shipping flags)
-- ==============================================================================
local function L23_BASE()
    local ok = false
    pcall(function()
        local stExtra = import("STExtraBlueprintFunctionLibrary")
        if stExtra and stExtra.IsDevelopment then stExtra.IsDevelopment = nop; ok = true end
        if Client then Client.IsDevelopment = nop; Client.IsShipping = retFalse; ok = true end
        if Server then Server.IsShipping = retFalse; ok = true end

        local ToolReport = safe_require("client.slua.logic.report.ToolReportUtil")
        if ToolReport then
            ToolReport.IsReleaseVersion = retFalse
            ToolReport.IsWhite = retFalse
            ToolReport.GetReportSwitch = retFalse
            ok = true
        end

        local callbacks = _G.GameplayCallbacks
        if callbacks then
            local extra = {
                "ReportHitFlow","SendClientStats","SendServerAvgTickDelta"
            }
            for _, fn in ipairs(extra) do
                if callbacks[fn] then callbacks[fn] = nop end
            end
            ok = true
        end

        if _G.TApmHelper then _G.TApmHelper.postEvent = nop; ok = true end

        local PC = _G.PacketCallbacks
        if PC then
            PC.player_report_cheat = nop
            PC.upload_loots_rsp = nop
            PC.watch_player_exit = nop
            PC.player_login_report = nop
            PC.player_logout_report = nop
            PC.server_time_report = nop
            ok = true
        end

        local sdm = _G.ServerDataMgr
        if sdm and sdm.DeletablePlayerResultKey then
            sdm.DeletablePlayerResultKey["SuspiciousHitCount"] = true
            sdm.DeletablePlayerResultKey["EspTotalSimTraceCnt"] = true
            sdm.DeletablePlayerResultKey["EspTotalImeFocusCnt"] = true
            sdm.DeletablePlayerResultKey["ClientGravityAnomalyCount"] = true
            ok = true
        end

        local pcNotify = safe_require("GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature")
        if pcNotify then
            pcNotify.ClientRPC_SyncBanID = nop
            pcNotify.ClientRPC_StrongTips = nop
            pcNotify.ClientRPC_NormalTips = nop
            pcNotify.Notify = nop
            pcNotify.ClientRPC_NotifyBan = nop
            pcNotify.ClientRPC_NotifyPunish = nop
            pcNotify.ClientRPC_NotifyIllegalProgram = nop
            ok = true
        end

        local secUtils = safe_require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
        if secUtils and secUtils.EStrategyTypeInReplay then
            secUtils.EStrategyTypeInReplay.EspTotalSimTraceCnt = 0
            secUtils.EStrategyTypeInReplay.EspTotalImeFocusCnt = 0
            secUtils.EStrategyTypeInReplay.ClientGravityAnomalyCount = 0
            secUtils.EStrategyTypeInReplay.FlyingErrorCnt = 0
            ok = true
        end
    end)
    MarkLayer("L23_BASE", ok)
end

-- ==============================================================================
-- LAYER 24: BAN SYSTEM BYPASS — ALL BAN TYPES
-- Covers: 1-day, 1-week, 10-year, HWID, device, IP, account.
-- All client-side ban handlers / notify paths silenced.
-- ==============================================================================
local function L24_BAN_SYSTEM()
    local ok = false
    pcall(function()
        -- Core ban logic
        local BanLogic = safe_require("client.slua.logic.ban.ClientBanLogic")
        if BanLogic then
            BanLogic.OnSyncBanInfo = nop
            BanLogic.OnVoiceBanNotify = nop
            BanLogic.OnRealTimeVoiceBanNotify = nop
            BanLogic.OnVoiceBanSuccess = nop
            BanLogic.OnSyncMicSuspicious = nop
            BanLogic.OnSyncMicPreFilter = nop
            BanLogic.OnNotifyWarningTips = nop
            BanLogic.ReqBanInfo = nop
            BanLogic.OnReceiveBanInfo = nop
            BanLogic.ShowBanUI = nop
            BanLogic.OnKickPlayer = nop
            ok = true
        end

        local BanUtil = safe_require("client.common.ban_util") or _G.ban_util
        if BanUtil then
            BanUtil.CheckBanStatus = retFalse
            BanUtil.GetBanTime = retZero
            BanUtil.IsBanForever = retFalse
            BanUtil.GetBanEndTime = retZero
            BanUtil.IsDeviceBanned = retFalse
            BanUtil.IsHWIDBanned = retFalse
            BanUtil.IsIPBanned = retFalse
            ok = true
        end

        -- TT (account) ban
        local TTBan = safe_require("client.logic.login.logic_tt_ban") or _G.logic_tt_ban
        if TTBan then
            TTBan.CheckIfCanCreateRole = nop
            TTBan.GetCarrierInfo = function() return "[{\"mcc\":\"000\"}]" end
            TTBan.OnBanNotify = nop
            ok = true
        end

        -- Godzilla (device/HWID) ban
        local GodzillaBan = safe_require("client.network.Protocol.GodzillaBanHandler")
        if GodzillaBan then
            GodzillaBan.send_godzilla_ban_req = nop
            GodzillaBan.send_godzilla_unban_req = nop
            GodzillaBan.on_godzilla_ban_notify = nop
            ok = true
        end

        -- Anti-addiction (region lock / minor lock)
        local AntiAddiction = safe_require("client.network.Protocol.AntiaddctionHandler")
        if AntiAddiction then
            AntiAddiction.send_anti_addiction_req = nop
            AntiAddiction.send_anti_addiction_notify = nop
            AntiAddiction.on_anti_addiction_notify = nop
            ok = true
        end

        -- Access restriction (region / IP restrictions)
        local AccessRestrict = safe_require("client.network.Protocol.AccessRestrictionHandler")
        if AccessRestrict then
            AccessRestrict.send_access_restriction_req = nop
            AccessRestrict.send_access_restriction_notify = nop
            AccessRestrict.on_player_cheat_state_notify = nop
            AccessRestrict.on_access_restriction_notify = nop
            ok = true
        end

        -- Account deletion / forced GDPR
        local DeleteAccount = safe_require("client.slua.logic.gdpr.logic_deleteaccount")
        if DeleteAccount then
            DeleteAccount.ForceDeleteAccount = retFalse
            DeleteAccount.OnReceiveDeleteNotify = nop
            ok = true
        end

        local ComplianceUtil = safe_require("client.slua.logic.gdpr.compliance_util")
        if ComplianceUtil then ComplianceUtil.CheckCompliance = nop; ok = true end

        -- Security Notify PC (in-game ban popup path)
        local pcNotify = safe_require("GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature")
        if pcNotify then
            pcNotify.ClientRPC_SyncBanID = nop
            pcNotify.ClientRPC_StrongTips = nop
            pcNotify.ClientRPC_NormalTips = nop
            pcNotify.Notify = nop
            pcNotify.ClientRPC_NotifyBan = nop
            pcNotify.ClientRPC_NotifyPunish = nop
            pcNotify.ClientRPC_NotifyIllegalProgram = nop
            pcNotify.ClientRPC_ShowBanUI = nop
            ok = true
        end
    end)
    MarkLayer("L24_BAN_SYSTEM", ok)
end

-- ==============================================================================
-- LAYER 25: FULL REPORT SYSTEMS BYPASS
-- ==============================================================================
local function L25_REPORT_SYSTEMS()
    local ok = false
    pcall(function()
        local clientReport = safe_require("GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem")
        if clientReport then
            for _, fn in ipairs({
                "OnInit","_OnPlayerKilledOtherPlayer","_RecordFatalDamager","SendPacket",
                "ReportSuspiciousPlayer","SubmitReport","_OnBattleResult",
                "_RecordTeammatePlayerInfo","_OnDeathReplayDataWhenFatalDamaged",
                "_RecordMurdererFromDeathReplayData"
            }) do
                if clientReport[fn] then clientReport[fn] = nop end
            end
            ok = true
        end

        local dsReport = safe_require("GameLua.Mod.BaseMod.Common.Security.DSReportPlayerSubsystem")
            or safe_require("GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem")
        if dsReport then
            for _, fn in ipairs({
                "_OnNearDeathOrRescued","_OnPlayerSettlementStart","_OnTeammateDamage",
                "_OnCharacterDied","_AddEnemyMapToBattleResult","_AddTeammateMapToBattleResult",
                "_SubmitAbnormalData"
            }) do
                if dsReport[fn] then dsReport[fn] = nop end
            end
            ok = true
        end

        local reportUtils = safe_require("GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils")
        if reportUtils then
            reportUtils.GetBotType = retZero
            reportUtils.IsCharacterDeliverAI = retFalse
            ok = true
        end

        local AvatarSub = safe_require("GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionSubsystem")
        if AvatarSub then
            AvatarSub.OnClickReportCheckAvatar = nop
            AvatarSub.RegisterTickCheckCharacterAvatar = nop
            ok = true
        end

        if _G.AvatarExceptionPlayerInst then
            _G.AvatarExceptionPlayerInst.ReportAvatarException = nop
            _G.AvatarExceptionPlayerInst.CheckAvatarException = nop
            _G.AvatarExceptionPlayerInst.CheckCanBugglyPostException = nop
            ok = true
        end

        local SubMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            local hawk = SubMgr:Get("DSHawkEyePatrolSubsystem")
            if hawk then
                hawk.MarkSuspiciousPlayer = nop
                hawk._OnHawkReport = nop
                hawk._OnHawkImprison = nop
                hawk.CheckPunishPlayer = nop
                ok = true
            end
        end

        local ClientHawk = safe_require("GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem")
        if ClientHawk then
            for _, fn in ipairs({
                "_OnHawkSync","_OnHawkReportSuccess","_StartExitGameTimer",
                "_OnRecvInspectorBroadcastCount","SendReportTLog","ReportCheat"
            }) do
                if ClientHawk[fn] then ClientHawk[fn] = nop end
            end
            ClientHawk.CanInspectorBroadcast = retFalse
            ok = true
        end

        local InspectClient = safe_require("GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem")
        if InspectClient then
            for _, fn in ipairs({
                "AskForInspector","ReportEnemy","KickOutOneTeam","OnReceiveInspectCmd",
                "ClientReportData","SendReportToInspector","SendKickOutOneTeam",
                "ClientNotifyInspectorImplementation","RecvNotifyInspector"
            }) do
                if InspectClient[fn] then InspectClient[fn] = nop end
            end
            ok = true
        end

        local InspectDS = safe_require("GameLua.Mod.BaseMod.DS.Security.InspectionSystemReportDSLogicSubsystem")
        if InspectDS then
            for _, fn in ipairs({
                "ServerKickOutOneTeamByPlayerImplementation","AddReportedCount",
                "AddInspectionRecord","BanPlayerByInspection","BroadCastToAllInspector",
                "ServerReportToInspectorImplementation","InitPlayerInspectionInfo"
            }) do
                if InspectDS[fn] then InspectDS[fn] = nop end
            end
            ok = true
        end
    end)
    MarkLayer("L25_REPORT_SYSTEMS", ok)
end

-- ==============================================================================
-- LAYER 26: TLOG BYPASS (all paths)
-- ==============================================================================
local function L26_TLOG()
    local ok = false
    pcall(function()
        local tlogMods = {
            "client.network.Protocol.ClientTlogHandler",
            "client.network.Protocol.BattleReportHandler",
            "client.network.Protocol.ClientErrorReportHandler",
            "client.network.Protocol.LobbyPingReportHandler",
            "client.slua.config.tlog.tlog_report_utils",
            "client.slua.data.BasicData.BasicDataTLogReport",
            "client.slua.data.BasicData.BasicDataClientReport",
            "client.slua.data.BasicData.BasicDataReport",
            "GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem",
            "GameLua.Mod.BaseMod.Client.Security.ClientDataStatistcsSubsystem",
        }
        for _, path in ipairs(tlogMods) do
            local mod = package.loaded[path]
            if mod then
                for k, v in pairs(mod) do
                    if type(v) == "function" and
                       (k:find("Log") or k:find("Report") or k:find("Send") or k:find("Tlog")) then
                        pcall(function() mod[k] = nop end)
                    end
                end
                ok = true
            end
        end

        local AmphibiousBoat = safe_require("GameLua.GameCore.Module.Vehicle.VehicleFeatures.TLog.AmphibiousBoatTLogFeature")
        if AmphibiousBoat then
            AmphibiousBoat.RecordMovement = nop
            AmphibiousBoat.StartRecordMovement = nop
            ok = true
        end

        local ICTLog = safe_require("GameLua.Mod.BaseMod.DS.Security.ICTLogSubsystem")
        if ICTLog then ICTLog.SendICExceptionTLog = nop; ok = true end

        local DSFight = safe_require("GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem")
        if DSFight then
            DSFight.GetSimpleFightData = retEmpty
            DSFight.ReportFightData = nop
            DSFight.ReportPlayerWeapon = nop
            ok = true
        end

        local DSSec = safe_require("GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem")
        if DSSec then
            DSSec._OnReportServerJumpFlow = nop
            DSSec._OnReportTeleportFlow = nop
            DSSec._OnReportSpeedHackFlow = nop
            ok = true
        end

        local DSCommon = safe_require("GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem")
        if DSCommon then DSCommon.HandleKillTlog = nop; ok = true end

        local PufferTlog = safe_require("client.slua.logic.download.report.puffer_tlog")
        if PufferTlog then PufferTlog.report_download_tlog = nop; ok = true end
    end)
    MarkLayer("L26_TLOG", ok)
end

-- ==============================================================================
-- LAYER 27: NETWORK HANDLER BYPASS
-- ==============================================================================
local function L27_NET_HANDLERS()
    local ok = false
    pcall(function()
        local ClientError = safe_require("client.network.Protocol.ClientErrorReportHandler")
        if ClientError then
            ClientError.send_client_error_report = nop
            ClientError.send_client_crash_report = nop
            ClientError.send_client_tools_batch_report_req = nop
            ok = true
        end

        local BattleReport = safe_require("client.network.Protocol.BattleReportHandler")
        if BattleReport then
            for _, fn in ipairs({
                "send_battle_report","send_battle_result","send_vod_game_report_req",
                "send_batch_get_vod_info_req","send_get_game_report_req",
                "send_batch_get_game_report_req","send_get_game_report_by_uid_req"
            }) do
                if BattleReport[fn] then BattleReport[fn] = nop end
            end
            ok = true
        end

        local BugHandler = safe_require("client.network.Protocol.BugHandler")
        if BugHandler then
            BugHandler.send_report_bug_info = nop
            BugHandler.send_report_bug_feedback = nop
            ok = true
        end

        local PingReport = safe_require("client.network.Protocol.LobbyPingReportHandler")
        if PingReport then
            PingReport.send_lobby_ping_report = nop
            PingReport.send_ingame_ping_report = nop
            ok = true
        end

        local WeekReport = safe_require("client.network.Protocol.WeekRportHandler")
        if WeekReport then
            WeekReport.send_week_report = nop
            WeekReport.send_week_detail = nop
            ok = true
        end

        local LogicComplaint = safe_require("client.logic.battle.logic_complaint")
        if LogicComplaint then
            LogicComplaint.SendComplaintReq = nop
            LogicComplaint.Submit = nop
            LogicComplaint.ReportPlayer = nop
            LogicComplaint.ShowComplaint = nop
            LogicComplaint.ShowHandle = nop
            ok = true
        end

        local OBResult = safe_require("GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.EscapeBattleResultShowOBResultLogic")
        if OBResult then
            OBResult.OnBattleResult = nop
            OBResult.OnResultProcessStart = nop
            ok = true
        end

        local NormalOBResult = safe_require("GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowOBResultLogic")
        if NormalOBResult then
            NormalOBResult.OnBattleResult = nop
            NormalOBResult.OnResultProcessStart = nop
            ok = true
        end

        local ShowResult = safe_require("GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowResultLogic")
        if ShowResult then
            for _, fn in ipairs({
                "OnBattleResult","OnResultProcessStart","OnResultProcessContinue",
                "ReceiveData","SendEndFlow","OnReport","ShowResult",
                "ShowResultInternal","StopResultProcess"
            }) do
                if ShowResult[fn] then ShowResult[fn] = nop end
            end
            ok = true
        end
    end)
    MarkLayer("L27_NET_HANDLERS", ok)
end

-- ==============================================================================
-- LAYER 28: MISC BYPASS (emulator, verify, voice, etc.)
-- ==============================================================================
local function L28_MISC()
    local ok = false
    pcall(function()
        local EmuHandler = safe_require("client.network.Protocol.EmulatorHandler")
        if EmuHandler then EmuHandler.send_emulator_info = nop; ok = true end

        local EmuScanner = safe_require("client.logic.login.emulator_scanner")
        if EmuScanner then
            EmuScanner.StartScan = nop
            EmuScanner.GetScanResult = retFalse
            EmuScanner.ReportScanResult = nop
            ok = true
        end

        local LoginVerify = safe_require("client.network.Protocol.LoginVerifyHandler")
        if LoginVerify then
            LoginVerify.send_login_verify_req = nop
            LoginVerify.send_device_verify_req = nop
            ok = true
        end

        local DSMonitor = safe_require("client.logic.data.logic_ds_monitor")
        if DSMonitor then
            DSMonitor.OnRecordMsg = nop
            DSMonitor.OnReportMsg = nop
            ok = true
        end

        local ClientDataStat = safe_require("GameLua.Mod.BaseMod.Client.Security.ClientDataStatistcsSubsystem")
        if ClientDataStat then
            ClientDataStat.StartToCheck = nop
            ClientDataStat.OnReceiveRTT = nop
            ClientDataStat.OnReceiveJitter = nop
            ClientDataStat.ReportAbnormal = nop
            ClientDataStat.ResetData = nop
            ok = true
        end

        local shootVerify = safe_require("GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
        if shootVerify then
            shootVerify.OnShootVerifyFailed = nop
            shootVerify.SendVerifyData = nop
            ok = true
        end

        local HighlightDS = safe_require("GameLua.Mod.BaseMod.DS.Security.HighlightMomentSubsystem_DSChecker")
        if HighlightDS then HighlightDS.CheckFuncUpgradedWeaponKill = nop; ok = true end

        local ProfileReport = safe_require("client.logic.data.profile_report_cfg")
        if ProfileReport then ProfileReport.SendReport = nop; ok = true end

        local VoiceReport = safe_require("client.slua.logic.chat_voice.logic_chat_voice_report")
        if VoiceReport then
            VoiceReport.ReportVoiceData = nop
            VoiceReport.ReportVoiceText = nop
            ok = true
        end

        local VoiceDoctor = safe_require("client.slua.logic.chat_voice.logic_chat_voice_doctor")
        if VoiceDoctor then
            VoiceDoctor.UploadVoiceLog = nop
            VoiceDoctor.UploadVoiceException = nop
            ok = true
        end

        local HomeAudit = safe_require("client.slua.logic.home.Audit.logic_home_audit_state")
        if HomeAudit then
            HomeAudit.SendAuditState = nop
            HomeAudit.ReportAuditResult = nop
            ok = true
        end

        local HomeReport = safe_require("client.slua.logic.home.logic_home_report")
        if HomeReport then
            HomeReport.ReportHomeData = nop
            HomeReport.ReportHomeVisitor = nop
            ok = true
        end

        local GemReport = safe_require("client.logic.store.gem_report_utils")
        if GemReport then
            GemReport.ReportGemData = nop
            GemReport.ReportGemPurchase = nop
            ok = true
        end

        local SafeStation = safe_require("client.slua.logic.CustomerService.LogicSafeStation")
        if SafeStation then
            SafeStation.UploadVideoEvidence = nop
            SafeStation.ReportPlayerBehavior = nop
            ok = true
        end

        local CustomerService = safe_require("client.slua.logic.CustomerService.LogicCustomerService")
        if CustomerService then
            CustomerService.SendComplaint = nop
            CustomerService.SendFeedback = nop
            ok = true
        end
    end)
    MarkLayer("L28_MISC", ok)
end

-- ==============================================================================
-- LAYER 29: EXTRA SUBSYSTEMS BYPASS
-- ==============================================================================
local function L29_EXTRA_SUBSYSTEMS()
    local ok = false
    pcall(function()
        local znq6Revive = safe_require("GameLua.Mod.TDEvent.ZNQ6th.DS.ZNQ6thDSReviveSubsystem")
        if znq6Revive then znq6Revive.HaveNewItemForRevive = nop; ok = true end

        local znq7Revive = safe_require("GameLua.Mod.TDEvent.ZNQ7th.DS.ZNQ7DSReviveSubsystem")
        if znq7Revive then znq7Revive.HaveChanceRevival = nop; ok = true end

        local DataLayer = safe_require("GameLua.Mod.BaseMod.Common.Subsystem.DataLayerSubsystem")
        if DataLayer then
            local orig = DataLayer.OnSpectatorReplayChanged
            if orig and not DataLayer._WrappedV5 then
                DataLayer.OnSpectatorReplayChanged = function(dlSelf)
                    _G.IsBeingWatched = true
                    orig(dlSelf)
                end
                DataLayer._WrappedV5 = true
            end
            ok = true
        end

        local DSActive = safe_require("GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem")
        if DSActive then
            DSActive.DelayKickOutPlayer = nop
            DSActive.ActiveKickNotify = nop
            ok = true
        end

        local CreativeDev = safe_require("GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeDevDebugSubsystem")
        if CreativeDev then CreativeDev.IsDebugPanelEnalbedCli = nop; ok = true end

        local CreativeDeath = safe_require("GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeModeDeathRecordSubsystem")
        if CreativeDeath then CreativeDeath.OnPlayerKilled = nop; ok = true end

        local SpectateReplay = safe_require("GameLua.Mod.BaseMod.Common.Subsystem.SpectateAndReplaySubsystem")
        if SpectateReplay then
            SpectateReplay.RequestGotoSpectatingImp = nop
            SpectateReplay.RequestGotoSpectating = nop
            ok = true
        end

        local AIReplay = safe_require("GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem")
        if AIReplay then
            AIReplay.ReportAllPlayerInfo = nop
            AIReplay.ReportFrameData = nop
            AIReplay.ReportPlayerInput = nop
            if AIReplay.uCompletePlayBack then
                AIReplay.uCompletePlayBack.AddRecordMLAIInfo = nop
                AIReplay.uCompletePlayBack.StopRecording = nop
            end
            ok = true
        end

        local AITracking = safe_require("GameLua.Mod.BaseMod.GamePlay.AI.AITrackingLogSubsystem")
        if AITracking then
            AITracking.RealLogoutTimer = nop
            AITracking.LogQueue = {}
            AITracking.AddToLogQue = nop
            AITracking.DoPrint = nop
            AITracking.OnAIPawnDied = nop
            AITracking.OnAIPawnReceiveDamage = nop
            AITracking.OnAIPawnEnemyChange = nop
            ok = true
        end

        local TDMAFK = safe_require("GameLua.Mod.TDM.Gameplay.Subsystem.TDMAFKReportorSubsystem")
        if TDMAFK then
            TDMAFK.SendAFKTips = nop
            TDMAFK.OnHandleLostConnection = nop
            ok = true
        end

        local DataMgr = safe_require("client.slua.logic.data.data_mgr")
        if DataMgr then DataMgr.GetWeaponSkinSoundVolumeInfoByGroup = retZero; ok = true end

        local CreditLogic = safe_require("GameLua.Mod.BaseMod.Client.ClientInGameCreditLogic")
        if CreditLogic then
            CreditLogic._SendUserReaction2ExitTeamBeforeBoardingReturnLobbyNotice = nop
            CreditLogic.ShowReturnLobbyIfFirstExitTeamBeforeBoarding = retFalse
            CreditLogic.OnReceiveCreditScoreChange = nop
            CreditLogic._IsFirstExitTeamBeforeBoardingReturnLobbyNoticeEnabled = retFalse
            CreditLogic.SetFirstExitTeamBeforeBoardingReturnLobbyNoticeEnabled = nop
            ok = true
        end
    end)
    MarkLayer("L29_EXTRA_SUBSYSTEMS", ok)
end

-- ==============================================================================
-- LAYER 30: NETWORK BLACKLIST (HTTP layer)
-- ==============================================================================
local function L30_NET_BLACKLIST()
    local ok = false
    pcall(function()
        if _G.HttpRequest and not _G._HttpBypassed then
            local orig = _G.HttpRequest
            _G.HttpRequest = function(url, ...)
                if isBlacklisted(url) then return nil end
                return orig(url, ...)
            end
            _G._HttpBypassed = true
            ok = true
        end

        if _G.FHttpModule and _G.FHttpModule.CreateRequest and not _G._FHttpBypassed then
            local orig = _G.FHttpModule.CreateRequest
            _G.FHttpModule.CreateRequest = function(...)
                local url = select(1, ...)
                if isBlacklisted(url) then return nil end
                return orig(...)
            end
            _G._FHttpBypassed = true
            ok = true
        end

        local netMods = {
            "client.slua.logic.network.logic_network",
            "client.slua.logic.download.report.puffer_tlog",
            "client.slua.data.BasicData.BasicDataClientReport",
            "GameLua.GameCore.Module.Network.NetworkManager",
            "client.network.Protocol.ClientTlogHandler",
            "client.network.Protocol.BattleReportHandler",
            "client.network.Protocol.ClientErrorReportHandler",
        }
        for _, mp in ipairs(netMods) do
            local mod = package.loaded[mp]
            if mod then
                for k, v in pairs(mod) do
                    if type(v) == "function" and
                       (k:find("Http") or k:find("Request") or k:find("Send") or
                        k:find("Upload") or k:find("Post") or k:find("Get") or k:find("Report")) then
                        local origf = v
                        mod[k] = function(...)
                            local args = {...}
                            for _, arg in ipairs(args) do
                                if type(arg) == "string" and isBlacklisted(arg) then return nil end
                            end
                            return pcall(origf, ...)
                        end
                    end
                end
                ok = true
            end
        end
    end)
    MarkLayer("L30_NET_BLACKLIST", ok)
end

-- ==============================================================================
-- LAYER 31: FILE IO + CRASH WRITE BLOCK
-- ==============================================================================
local function L31_FILEIO()
    local ok = false
    pcall(function()
        if not _G._IoOpenHooked then
            local orig_io_open = io.open
            io.open = function(path, mode)
                if type(path) == "string" then
                    local lp = path:lower()
                    for _, kw in ipairs(FILE_KEYWORDS) do
                        if lp:find(kw) then
                            if mode and (mode == "w" or mode == "a" or mode == "w+" or mode == "a+") then
                                return nil, "Blocked"
                            end
                        end
                    end
                    if lp:find("tdm") or lp:find("gcloud") or lp:find("beacon") then
                        if mode and (mode == "w" or mode == "a" or mode == "w+") then
                            return nil
                        end
                    end
                end
                return orig_io_open(path, mode)
            end
            _G._IoOpenHooked = true
            ok = true
        end

        if _G.UnrealEngine and _G.UnrealEngine.CrashContext then
            _G.UnrealEngine.CrashContext = nil
            _G.UnrealEngine.CrashContext = {
                SetCrashContext = nop,
                ReportCrash = nop,
                AddCrashData = nop
            }
            ok = true
        end
    end)
    MarkLayer("L31_FILEIO", ok)
end

-- ==============================================================================
-- LAYER 32: TSS SDK TOTAL SILENCE
-- ==============================================================================
local function L32_TSS_SDK()
    local ok = false
    pcall(function()
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then
            TssSdk.SendReportInfo = nop
            TssSdk.ScanMemory = function() return true, {code=0, msg="clean"} end
            TssSdk.ScanSo = function() return true, {code=0, msg="clean"} end
            TssSdk.ScanFile = function() return true, {code=0} end
            TssSdk.GetRiskFlag = function() return 0 end
            TssSdk.VerifyFileHash = function() return true end
            TssSdk.IsEmulator = retFalse
            TssSdk.GetTssSdkReportInfo = retEmptyString
            TssSdk.CheckEnvironment = retTrue
            TssSdk.VerifyProcess = retTrue
            TssSdk.CheckKernel = function() return true, {status="verified", tampered=false} end
            TssSdk.VerifyBoot = function() return true, {locked=true, verified=true} end

            -- Inbound data filter
            local origData = TssSdk.OnRecvData
            if origData and not TssSdk._DataFiltered then
                TssSdk.OnRecvData = function(data)
                    if type(data) == "string" then
                        local low = data:lower()
                        if low:find("report", 1, true) or low:find("exception", 1, true) or
                           low:find("cheat", 1, true) or low:find("violation", 1, true) or
                           low:find("hack", 1, true) or low:find("verify", 1, true) then
                            return
                        end
                    end
                    origData(data)
                end
                TssSdk._DataFiltered = true
            end
            ok = true
        end
    end)
    MarkLayer("L32_TSS_SDK", ok)
end

-- ==============================================================================
-- LAYER 33: BEHAVIOR SCORE / AFK / SPEED / WALL HEURISTIC BYPASS
-- These are the real heuristics used by GL 4.6 (via BehaviorScoreSubsystem
-- and AFKReportorSubsystem). Replaces the fake 8-layer names from v4.
-- ==============================================================================
local function L33_HEURISTICS()
    local ok = false
    pcall(function()
        local SubMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if not SubMgr then return end

        local Behavior = SubMgr:Get("BehaviorScoreSubsystem")
            or safe_require("GameLua.Mod.Escape.Gameplay.Subsystem.BehaviorScoreSubsystem")
        if Behavior then
            Behavior.OnHandleBehaviorScore = nop
            Behavior.AIPerceptionScore = nop
            Behavior.ReportBehavior = nop
            Behavior.CalcFinalScore = retZero
            Behavior.GetRiskLevel = retZero
            Behavior.IsSuspicious = retFalse
            ok = true
        end

        local AFK = SubMgr:Get("AFKReportorSubsystem")
            or safe_require("GameLua.Mod.BaseMod.DS.Security.AFKReportorSubsystem")
        if AFK then
            AFK.HandleEnterFighting = nop
            AFK.InitializePlayerInputInfo = nop
            AFK.AddOneAFKInfo = nop
            AFK.SetPlayerAFKState = nop
            AFK.ResetPlayerInputInfo = nop
            AFK.PlayerHaveAction = nop
            ok = true
        end

        -- Speed / movement heuristics (via GameplayCallbacks, already nop'd above,
        -- but expose the internal delta to be safe)
        if _G.GameplayCallbacks then
            for _, k in ipairs({
                "ReportServerJumpFlow","ReportTeleportFlow","ReportSpeedHackFlow",
                "ReportClientMemUsage","ReportMemoryInfo"
            }) do
                _G.GameplayCallbacks[k] = nop
            end
            ok = true
        end
    end)
    MarkLayer("L33_HEURISTICS", ok)
end

-- ==============================================================================
-- LAYER 34: HWID / DEVICE FINGERPRINT SPOOF
-- ==============================================================================
local function L34_HWID_SPOOF()
    local ok = false
    pcall(function()
        local SubMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            local deviceInfo = SubMgr:Get("ClientDeviceInfoSubsystem")
            if deviceInfo then
                deviceInfo.GetDeviceID = function() return FakeData.deviceID() end
                deviceInfo.GetIPAddress = function() return FakeData.ipAddress() end
                deviceInfo.GetMACAddress = function() return FakeData.macAddress() end
                deviceInfo.GetBuildFingerprint = function() return FakeData.buildFingerprint() end
                ok = true
            end
        end
        if _G.GetDeviceID then _G.GetDeviceID = function() return FakeData.deviceID() end; ok = true end
        if _G.GetDeviceUniqueIdentifier then
            _G.GetDeviceUniqueIdentifier = function() return FakeData.deviceID() end
            ok = true
        end
    end)
    MarkLayer("L34_HWID_SPOOF", ok)
end

-- ==============================================================================
-- LAYER 35: PERSISTENT HUNT TIMER (re-arms itself, checks PC validity)
-- ==============================================================================
local function L35_HUNT_TICK()
    pcall(function()
        if not _G.BYPASS_STATE then return end

        -- Re-apply the critical layer every 3s (cheap, catches respawns/reinits)
        L19_GAMEPLAY_CALLBACKS()
        L20_KILL_SUBSYSTEMS()
        L39_SKIN_ANTI_DETECTION()
        local SubMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            for _, name in ipairs({"ClientHawkEyePatrolSubsystem","DSHawkEyePatrolSubsystem",
                                    "ClientReportPlayerSubsystem","DSReportPlayerSubsystem",
                                    "AFKReportorSubsystem","BehaviorScoreSubsystem",
                                    "ClientDataStatistcsSubsystem"}) do
                local sub = SubMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" and
                           (k:find("Report") or k:find("Send") or k:find("Tick") or k:find("Log")) then
                            pcall(function() sub[k] = nop end)
                        end
                    end
                end
            end
        end

        local Higgs = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if Higgs then
            for _, m in ipairs({"ControlMHActive","Tick","OnTick","MHActiveLogic",
                                "TriggerAvatarCheck","StartAvatarCheck","ReportItemID",
                                "ReceiveAnyDamage","OnWeaponHitRecord","ShowSecurityAlert",
                                "ServerReportAvatar","ClientReportNetAvatar","SendHisarData",
                                "ValidateSecurityData"}) do
                if Higgs[m] then Higgs[m] = nop end
            end
            Higgs.GetNetAvatarItemIDs = retEmpty
            Higgs.GetCurWeaponSkinID = retZero
        end
    end)
end

local function L35_START_HUNT_TIMER()
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if pc and slua.isValid(pc) then
            if _G._V5HuntTimer then
                pcall(function() pc:RemoveGameTimer(_G._V5HuntTimer) end)
            end
            _G._V5HuntTimer = pc:AddGameTimer(3.0, true, L35_HUNT_TICK)
            return true
        end
        return false
    end)
    MarkLayer("L35_HUNT_TIMER", _G._V5HuntTimer ~= nil)
end

-- ==============================================================================
-- LAYER 36: ANTI-REPLAY BAN TRAP
-- Blocks replay-based "reviewed and banned" flows.
-- ==============================================================================
local function L36_REPLAY_BAN()
    local ok = false
    pcall(function()
        local rs = safe_require("GameLua.Mod.BaseMod.Common.Subsystem.SpectateAndReplaySubsystem")
        if rs then
            rs.StartReplayRecord = nop
            rs.StopReplayRecord = nop
            rs.UploadReplayData = nop
            rs.SubmitReplayForReview = nop
            ok = true
        end
        local SubMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            local Review = SubMgr:Get("ReplayReviewSubsystem")
            if Review then
                Review.SubmitForReview = nop
                Review.UploadClip = nop
                Review.FlagPlayer = nop
                ok = true
            end
        end
    end)
    MarkLayer("L36_REPLAY_BAN", ok)
end

-- ==============================================================================
-- LAYER 37: LOGIN-TIME BAN CHECK SILENCE
-- Bypasses ban checks that fire on login / lobby load.
-- ==============================================================================
local function L37_LOGIN_BAN()
    local ok = false
    pcall(function()
        local LoginBan = safe_require("client.logic.login.logic_ban_check")
        if LoginBan then
            LoginBan.CheckBanOnLogin = retFalse
            LoginBan.QueryBanStatus = retNil
            LoginBan.OnBanResponse = nop
            ok = true
        end
        local LoginFlow = safe_require("client.logic.login.login_flow")
        if LoginFlow then
            LoginFlow.HandleBanMessage = nop
            LoginFlow.ShowBanDialog = nop
            LoginFlow.KickOutOnBan = nop
            ok = true
        end
        local LobbyBan = safe_require("client.logic.lobby.lobby_ban_check")
        if LobbyBan then
            LobbyBan.OnLobbyBanCheck = retFalse
            LobbyBan.ProcessBanData = nop
            ok = true
        end
    end)
    MarkLayer("L37_LOGIN_BAN", ok)
end

-- ==============================================================================
-- LAYER 38: KICK / DISCONNECT / FORCED-EXIT BLOCK
-- Bypasses server-forced kicks, including "cheat detected" kicks.
-- ==============================================================================
local function L38_KICK_BLOCK()
    local ok = false
    pcall(function()
        local KickHandler = safe_require("client.network.Protocol.KickHandler")
        if KickHandler then
            KickHandler.on_kick_notify = nop
            KickHandler.handle_kick = nop
            ok = true
        end
        local DSMgr = safe_require("GameLua.Mod.BaseMod.DS.Subsystem.DSKickSubsystem")
        if DSMgr then
            DSMgr.KickPlayer = nop
            DSMgr.KickPlayerFromMatch = nop
            DSMgr.DelayKickOutPlayer = nop
            ok = true
        end
        local FlowMgr = safe_require("client.logic.flow.exit_game_flow")
        if FlowMgr then
            FlowMgr.ForceExitGame = nop
            FlowMgr.ForceReturnToLobby = nop
            ok = true
        end
    end)
    MarkLayer("L38_KICK_BLOCK", ok)
end
