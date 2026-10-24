

-- Random number generator function
local function randomInt(min, max)
    math.randomseed(os.time() + math.random(1, 99999))
    return math.random(min, max)
end

-- Store random collector level once per session
local randomCollectorLevel = randomInt(80, 95)

local oldInitRoleData=DataMgr.InitRoleData
function DataMgr.InitRoleData(roleDataTb)
    oldInitRoleData(roleDataTb)
    
    -- Random values for each game session
    local goldVal = randomInt(100000, 200000)      -- GOLD: 1Lakh to 2Lakh
    local silverVal = randomInt(100000, 200000)    -- SILVER: 1Lakh to 2Lakh
    local ucVal = randomInt(200000, 400000)        -- UC: 2Lakh to 4Lakh
    local agVal = randomInt(50000, 150000)         -- AG: 50k to 1.5Lakh
    local levelVal = randomInt(80, 99)            -- Player Level: 90 to 100
    local fpTokenVal = randomInt(50000, 100000)    -- KR TOKEN: 50k to 1Lakh
    
    DataMgr.gold = goldVal
    DataMgr.diamond = silverVal
    DataMgr.eternal_diamond = agVal                -- AG
    DataMgr.uc = ucVal                             -- UC (if exists)
    DataMgr.roleData.level = levelVal
    DataMgr.fp_token = fpTokenVal                  -- KR TOKEN randomized
    
    -- Other values keep as before
    DataMgr.ticket=999999992
    DataMgr.gold_chip=999999995
    DataMgr.gen_ticket=999999996
    DataMgr.corps_money=999999998
    DataMgr.smelt=999999911
    DataMgr.battle_coin=999999922
    DataMgr.wow_creation_score=999999933
    DataMgr.ugc_advanced_crystal=999999944
    DataMgr.carteam_coin_count=999999955
    DataMgr.anchor=999999966
    DataMgr.anchor_origin=999999977
    DataMgr.roleData.bgbg_vip=1
    
    EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_GOLD_CHANGE, DataMgr.gold)
    EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_TICKET_CHANGE, DataMgr.ticket)
    EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_DIAMOND_CHANGE, DataMgr.diamond)
    EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_FP_TOKEN_CHANGE, DataMgr.fp_token)
    EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_GOLD_CHIP_CHANGE, DataMgr.gold_chip)
    EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLE_LEVEL_CHANGE, DataMgr.roleData.level)
end

local oldGetItem=DataMgr.GetItemStoreByItemId
function DataMgr.GetItemStoreByItemId(nItemId)
    if nItemId==1000 or nItemId==1001 or nItemId==1006 then
        return 999999111
    end
    return oldGetItem(nItemId)
end

local oldSetItem=DataMgr.SetItemStoreData
function DataMgr.SetItemStoreData(nItemId,nCount)
    if nItemId==1000 or nItemId==1001 or nItemId==1006 then
        nCount=999999222
    end
    oldSetItem(nItemId,nCount)
    EventSystem:postEvent(EVENTTYPE_BAG, EVENTID_BAG_ITEM_UPDATE, nItemId, nCount)
end

local oldGetBanInfo=DataMgr.GetBanInfo
function DataMgr.GetBanInfo(ban_id) return nil end

local oldHasEquipVehicleSkin=DataMgr.HasEquipVehicleSkin
function DataMgr.HasEquipVehicleSkin(insID) return true end

local oldGetMaxRankLevel=DataMgr.GetMaxRankLevel
function DataMgr.GetMaxRankLevel() return 701 end

local oldIsValidTime=DataMgr.IsValidTime
function DataMgr.IsValidTime(time) return true end

local oldIsEnableWatch=DataMgr.IsEnableWatch
function DataMgr.IsEnableWatch() return true end

local oldHaveNewbieGuide=DataMgr.HaveNewbieGuide
function DataMgr.HaveNewbieGuide(module_id,key) return false end

local oldGetNewbieGuideValue=DataMgr.GetNewbieGuideValue
function DataMgr.GetNewbieGuideValue(module_id,key) return 1 end

local oldGetRoleSetting=DataMgr.GetRoleSetting
function DataMgr.GetRoleSetting(settingKey) return 0 end

local oldIsMoneyEnough=DataMgr.IsMoneyEnough
function DataMgr.IsMoneyEnough(money_type,money_price) return true end

local oldGetMoneyByType=DataMgr.GetMoneyByType
function DataMgr.GetMoneyByType(money_type) return 199999999 end

local oldGetRoleAttr=DataMgr.OnRoleAttrChangeNotify
function DataMgr.OnRoleAttrChangeNotify(attriType,attriValue,attriTab,isClickReward)
    local currencyTypes={
        [3]="gold",
        [4]="diamond",
        [7]="ticket",
        [8]="gen_ticket",
        [10]="eternal_diamond",  -- AG
        [98]="corps_money",
        [100]="fp_token",
        [101]="gold_chip",
        [110]="smelt"
    }
    if currencyTypes[attriType] then
        local maxValue
        if attriType == 10 then  -- AG (eternal_diamond)
            maxValue = randomInt(50000, 150000)  -- 50k to 1.5Lakh
        else
            maxValue = randomInt(200000, 400000)  -- UC: 2Lakh to 5Lakh
        end
        if attriValue~=maxValue then
            attriValue=maxValue
            if attriTab then
                attriTab.gen_ticket=maxValue
            end
        end
    end
    if oldGetRoleAttr then
        oldGetRoleAttr(attriType,attriValue,attriTab,isClickReward)
    end
end

function hook_collect_module()
    local collect_mod = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.collect_module)
    if not collect_mod then return false end
    if collect_mod.OnGetMainData and not collect_mod.__fs_main then
        local old = collect_mod.OnGetMainData
        collect_mod.__fs_main = old
        collect_mod.OnGetMainData = function(_, ret, data, ...)
            if data then
                data.total_score = 399999999
                data.cur_season_collect_score = data.total_score
                if not data.season_score then data.season_score = {} end
                if DataMgr and DataMgr.season_id then
                    data.season_score[DataMgr.season_id] = data.total_score
                end
                if not data.level_reward then data.level_reward = {} end
                for i=1,95 do
                    if not data.level_reward[i] then
                        data.level_reward[i] = { state = 1 }
                    end
                end
            end
            local result = old(_, ret, data, ...)
            return result
        end
    end
    if collect_mod.NotifyCollectData and not collect_mod.__fs_notify then
        local old = collect_mod.NotifyCollectData
        collect_mod.__fs_notify = old
        collect_mod.NotifyCollectData = function(_, data)
            if data then
                data.total_score = 499999999
                data.cur_season_collect_score = data.total_score
                if not data.season_score then data.season_score = {} end
                if DataMgr and DataMgr.season_id then
                    data.season_score[DataMgr.season_id] = data.total_score
                end
            end
            local result = old(_, data)
            return result
        end
    end
    if collect_mod.GetCollectTotalScore and not collect_mod.__fs_totalscore then
        local old = collect_mod.GetCollectTotalScore
        collect_mod.__fs_totalscore = old
        collect_mod.GetCollectTotalScore = function(_)
            return 599999999, randomCollectorLevel
        end
    end
    if collect_mod.GetLevelByScore and not collect_mod.__fs_lvscore then
        local old = collect_mod.GetLevelByScore
        collect_mod.__fs_lvscore = old
        collect_mod.GetLevelByScore = function(_, score)
            if score and score >= 0 then
                return randomCollectorLevel, randomCollectorLevel, randomCollectorLevel, 0, 0
            end
            return old(_, score)
        end
    end
    if collect_mod.GetLevelDataByScore and not collect_mod.__fs_lvdata then
        local old = collect_mod.GetLevelDataByScore
        collect_mod.__fs_lvdata = old
        collect_mod.GetLevelDataByScore = function(_, score, isSeason)
            if score and score >= 0 then
                if isSeason then
                    return randomCollectorLevel, "", randomCollectorLevel
                else
                    return randomCollectorLevel, "", randomCollectorLevel
                end
            end
            return old(_, score, isSeason)
        end
    end
    if collect_mod.GetSeasonLevelByScore and not collect_mod.__fs_seasonlv then
        local old = collect_mod.GetSeasonLevelByScore
        collect_mod.__fs_seasonlv = old
        collect_mod.GetSeasonLevelByScore = function(_, score, ...)
            if score and score >= 0 then
                return randomCollectorLevel, false, ""
            end
            return old(_, score, ...)
        end
    end
    if collect_mod.GetCollectScoreByProfile and not collect_mod.__fs_proscore then
        local old = collect_mod.GetCollectScoreByProfile
        collect_mod.__fs_proscore = old
        collect_mod.GetCollectScoreByProfile = function(_, profile)
            local local_uid = DataMgr and DataMgr.roleData and tonumber(DataMgr.roleData.uid)
            if local_uid and profile then
                if type(profile) == "table" and tonumber(profile.uid) == local_uid then
                    return 699999999, 799999999
                end
                if profile == local_uid then
                    return 899999999, 119999999
                end
            end
            local total, cur = old(_, profile)
            return total, cur
        end
    end
    if collect_mod.GetCollectScoreByCollectData and not collect_mod.__fs_colscore then
        local old = collect_mod.GetCollectScoreByCollectData
        collect_mod.__fs_colscore = old
        collect_mod.GetCollectScoreByCollectData = function(_, data)
            local my_data = DataMgr and DataMgr.roleData and DataMgr.roleData.brief_collect_data
            if data and my_data and data == my_data then
                return 129999999, 139999999
            end
            if data and data.total_score and data.total_score >= 149999999 then
                return 159999999, 169999999
            end
            local total, cur = old(_, data)
            return total, cur
        end
    end
    if collect_mod.OnGetItemData and not collect_mod.__fs_item then
        local old = collect_mod.OnGetItemData
        collect_mod.__fs_item = old
        collect_mod.OnGetItemData = function(_, uid, data)
            local local_uid = DataMgr and DataMgr.roleData and tonumber(DataMgr.roleData.uid)
            if tonumber(uid) == local_uid and data then
                if not data.item_detail then data.item_detail = {} end
                for i=1,1000 do
                    if not data.item_detail[i] then
                        data.item_detail[i] = { count = 1, expire_ts = 0 }
                    end
                end
            end
            return old(_, uid, data)
        end
    end
    return true
end

pcall(hook_collect_module)

local oShowUI=UIManager.ShowUI
UIManager.ShowUI=function(uiCfg,...)
    local ret=oShowUI(uiCfg,...)
    if uiCfg==UIManager.UI_Config.roleinfo_main then
        local timer=require("common.timer")
        timer.AddTimer(0.5,function()
            local ui=UIManager.GetUI(UIManager.UI_Config.roleinfo_main)
            if ui and ui.UIRoot then
                local RoleInfoSystem=require("client.logic.roleinfo.logic_roleinfo")
                local isSelf=RoleInfoSystem.IsSelf()
                local t28=ui.UIRoot.TextBlock_28
                local t32=ui.UIRoot.TextBlock_32
                if t28 and not t28._h then
                    local oSet28=t28.SetText
                    t28.SetText=function(self,txt)
                        if isSelf then oSet28(self,"9178") else oSet28(self,txt) end
                    end
                    t28._h=true
                end
                if t32 and not t32._h then
                    local oSet32=t32.SetText
                    t32.SetText=function(self,txt)
                        if isSelf then oSet32(self,"第1名") else oSet32(self,txt) end
                    end
                    t32._h=true
                end
                local maxSegmentID=31
                local rankWidgets={
                    ui.UIRoot.Common_RankIntegralLevel_Style_Large_UIBP_C_1,
                    ui.UIRoot.Common_RankIntegralLevel_Style_Small_UIBP_C_1,
                    ui.UIRoot.Common_RankIntegralLevel_Style_Large_UIBP_C_2,
                    ui.UIRoot.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_2,
                    ui.UIRoot.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_0,
                    ui.UIRoot.PeakGame_RankIntegralLevel_Style_Small_UIBP_C_1,
                }
                for _,w in pairs(rankWidgets) do
                    if w and not w._h then
                        if w.SetRankInteral then
                            local oSetRank=w.SetRankInteral
                            w.SetRankInteral=function(self,seg,_,__,___,____)
                                if isSelf then oSetRank(self,maxSegmentID) else oSetRank(self,seg) end
                            end
                        end
                        if w.SetRankInteralBySeason then
                            local oSetRankSea=w.SetRankInteralBySeason
                            w.SetRankInteralBySeason=function(self,seg,_,sea)
                                if isSelf then oSetRankSea(self,maxSegmentID,nil,sea) else oSetRankSea(self,seg,_,sea) end
                            end
                        end
                        if w.SetPeakRankIntegral then
                            local oSetPeak=w.SetPeakRankIntegral
                            w.SetPeakRankIntegral=function(self,seg,_)
                                if isSelf then oSetPeak(self,maxSegmentID) else oSetPeak(self,seg) end
                            end
                        end
                        w._h=true
                    end
                end
            end
        end)
    end
    return ret
end



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
