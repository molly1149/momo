-- @nthuy2004

local function NTHMOD_BypassAntiCheat()
  pcall(function()
    if _G.GameplayCallbacks then
      local GameplayCallbacks = _G.GameplayCallbacks
      local rawOnDSPlayerStateChanged = GameplayCallbacks.OnDSPlayerStateChanged
      GameplayCallbacks.OnDSPlayerStateChanged = function(UID, State, Arg3, Arg4, Reason)
        if type(State) == "string" then
          local LowerState = string.lower(State)
          if LowerState == "cheatdetected" or LowerState == "connectionexception" or LowerState == "connectiontimeout" or LowerState == "banned" then
            State = "Online"
            Reason = "SafeByNTHMod"
          end
        end
        if rawOnDSPlayerStateChanged then
          pcall(rawOnDSPlayerStateChanged, UID, State, Arg3, Arg4, Reason)
        end
      end
      local function ReturnTrue()
        return true
      end
      GameplayCallbacks.OnPlayerNetConnectionClosed = ReturnTrue
      GameplayCallbacks.OnPlayerActorChannelError = ReturnTrue
      GameplayCallbacks.OnPlayerSpectateException = ReturnTrue
      GameplayCallbacks.OnPlayerRPCValidateFailed = ReturnTrue
      GameplayCallbacks.OnShutdownAfterError = ReturnTrue
      GameplayCallbacks.RepListMismatchDetectTrigger = ReturnTrue
      GameplayCallbacks.SendDSHawkEyePatrolLogToLobby = ReturnTrue
      GameplayCallbacks.SendDSErrorLogToLobby = ReturnTrue
      GameplayCallbacks.GetWeaponReport = function()
        return {}
      end
      GameplayCallbacks.GetOneWeaponReport = function()
        return {}
      end
      GameplayCallbacks.GetGeneralTLogData = function()
        return nil
      end
      GameplayCallbacks.ReportPlayerIP = ReturnTrue
      local ReportFuncNames = {
        "ReportJumpFlow",
        "ReportCircleFlow",
        "ReportDSCircleFlow",
        "ReportGameEndFlow",
        "ReportAimFlow",
        "ReportEquipmentFlow",
        "ReportAttackFlow",
        "ReportSecAttackFlow",
        "ReportHurtFlow",
        "ReportFeedback",
        "ReportPlayerBehavior",
        "ReportPlayerMoveRoute",
        "ReportPlayerPosition",
        "ReportForbitPick",
        "ReportTeammatHurt",
        "ReportFireArms",
        "ReportVerifyInfoFlow",
        "ReportGameSetting",
        "ReportGameSettingNew",
        "SendPlayerSpectatingLog",
        "ReportSecTgameMovingFlow",
        "ReportMisKillByTeammate",
        "ReportMrpcsFlow",
        "ReportVehicleMoveFlow",
        "ReportParachuteData",
        "ReportLightweightStat",
        "SendClientStats",
        "ReportPlayersPing",
        "SendGameStart"
      }
      for _, FuncName in ipairs(ReportFuncNames) do
        GameplayCallbacks[FuncName] = ReturnTrue
      end
    end
    if NetUtil then
      if NetUtil.SendPacket then
        if not NetUtil._IsNTHModBypassed then
          local rawSendPacket = NetUtil.SendPacket
          local BlockedPackets = {
            report_player_ip = true,
            report_players_ping = true,
            report_unrealnet_clientstats = true,
            report_all_players_address = true,
            c2ds_ingame_flow_setting = true,
            RPC_Client_PostTGPAIS = true,
            report_unrealnet_exception = true,
            shutdown_after_error = true,
            detect_cheat = true,
            report_common_info = true,
            report_common_battle_info = true,
            SendSpectatingLog = true,
            ReportAvatarException = true,
            report_character_all_drag = true,
            report_parachute_all_drag = true,
            report_vehicle_move_drag = true,
            report_vehicle_move_drag_detail = true,
            log_shooting_miss = true,
            ReportGenerateMonsterFlow = true,
            report_net_saturate = true,
            report_ds_netsaturate = true,
            report_ds_net_continuous_saturate = true,
            report_ds_netrate = true,
            report_player_frame_ping_record = true
          }
          NetUtil.SendPacket = function(PacketName, ...)
            local Args = {...}
            if BlockedPackets[PacketName] then
              return nil
            end
            if type(PacketName) == "string" then
              local FoundIndex = string.find(PacketName, "Flow")
              if not FoundIndex then
                FoundIndex = string.find(PacketName, "Report")
              end
              if FoundIndex and PacketName ~= "ReportGameStartFlow" and PacketName ~= "ReportGameEndFlow" then
                return nil
              end
            end
            if PacketName == "on_tss_sdk_anti_data" then
              if not Args[2] or type(Args[2]) ~= "string" or #Args[2] <= 0 then
                Args[2] = "TSS_SECURE_PAYLOAD_VERIFIED_OK"
                Args[3] = #Args[2]
              end
              if type(Args[5]) == "table" then
                Args[5].ErrorCode = 0
                Args[5].ReportLog = 0
              end
              return rawSendPacket(PacketName, table.unpack(Args))
            end
            return rawSendPacket(PacketName, table.unpack(Args))
          end
          NetUtil._IsNTHModBypassed = true
        end
      end
    end
    local ServerPlayerDataMgr = package.loaded["Server.Data.ServerPlayerDataMgr"]
    if not ServerPlayerDataMgr then
      ServerPlayerDataMgr = rawget(_G, "ServerPlayerDataMgr")
    end
    if ServerPlayerDataMgr then
      if ServerPlayerDataMgr.GetPlayerInfo then
        local rawGetPlayerInfo = ServerPlayerDataMgr.GetPlayerInfo
        ServerPlayerDataMgr.GetPlayerInfo = function(UID)
          local PlayerInfo = rawGetPlayerInfo(UID)
          if type(PlayerInfo) == "table" then
            PlayerInfo.suspicious_flag = 0
            PlayerInfo.avatar_err_report = false
            PlayerInfo.ban = nil
          end
          return PlayerInfo
        end
      end
    end
    local TApmHelper = import("TApmHelper")
    if TApmHelper then
      if TApmHelper.PostGameStatusToTGPAIS then
        TApmHelper.PostGameStatusToTGPAIS = function()
          return true
        end
      end
    end
    local logic_recommend_handler = package.loaded["client.slua.logic.download.recommend.logic_recommend_handler"]
    if not logic_recommend_handler then
      logic_recommend_handler = rawget(_G, "logic_recommend_handler")
    end
    if logic_recommend_handler then
      if logic_recommend_handler.AddBattleItem then
        logic_recommend_handler.AddBattleItem = function()
          return true
        end
      end
    end
    local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if SubsystemMgr then
      local SubsystemNames = {
        "WeaponRecordSubSystem",
        "FatalDamageSubsystem",
        "DSHawkEyePatrolSubsystem",
        "ClientHawkEyePatrolSubsystem",
        "ShootVerifySubSystemClient",
        "AvatarExceptionSubsystem",
        "FileCheckSubsystem",
        "SpeedCheckSubsystem",
        "WallCheckSubsystem",
        "AFKReportorSubsystem",
        "ClientQuickReportMaliciousTeammate"
      }
      for _, SubsystemName in ipairs(SubsystemNames) do
        local Subsystem = SubsystemMgr:Get(SubsystemName)
        if Subsystem then
          for FuncName, FuncValue in pairs(Subsystem) do
            if type(FuncValue) == "function" then
              if string.find(FuncName, "Retrieve") or string.find(FuncName, "Report") or string.find(FuncName, "Send") or string.find(FuncName, "Check") or string.find(FuncName, "PlayerHaveAction") then
                Subsystem[FuncName] = function()
                  return {}
                end
              end
            end
          end
        end
      end
    end
    if Client then
      if Client.GetPhoneDeviceID then
        Client.GetPhoneDeviceID = function()
          return "SAMSUNG-SM-S918B-FAKE-" .. tostring(math.random(100000, 999999))
        end
      end
    end
    if slua then
      if slua.getSignature then
        slua.getSignature = function()
          return "VALID_SIGNATURE_846651419"
        end
      end
    end
    local slua_loader = package.loaded["slua.loader"]
    if not slua_loader then
      slua_loader = rawget(_G, "slua_loader")
    end
    if slua_loader then
      slua_loader.verifyBytecode = function()
        return true
      end
      slua_loader.checkIntegrity = function()
        return true
      end
      if slua_loader.disableSignatureCheck then
        slua_loader.disableSignatureCheck = function()
          return true
        end
      end
    end
  end)
end

NTHMOD_BypassAntiCheat()

local CharacterBase = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {},
  LuaEventContainer = {
    "DefaultLuaEventPlaceholder",
    "OnCharacterAnimInstanceInit",
    "OnCharacterAnimInstanceInitFrameDelay",
    "OnProjectileEffect",
    "OnUnmannedVehicleStateChange",
    "OnDSEnterSelfieMode",
    "OnDSExitSelfieMode",
    "EVENTID_CHARACTER_POSSESSED",
    "EVENTID_PAWN_PICK_UP_ITEM",
    "EVENTID_PLAYEREVENT_REVIVAL",
    "EVENTID_INGAME_BUILD_SUCCESS",
    "EVENTID_PLAYEREVENT_SCOPECHANGE",
    "EVENTID_CHARACTER_DIED_PRE",
    "EVENTID_LOCAL_HERO_ID_CHANGED",
    "EVENTID_HERO_ID_CHANGED",
    "EVENTID_INGAME_ON_PAWN_CAMP_CHANGED",
    "EVENTID_TAKE_DAMAGE",
    "EVENTID_PLAYEREVENT_CONSUMEITEM",
    "EVENTID_PLAYEREVENT_DROPITEM"
  }
}
local IngameTipsTools = require("GameLua.Mod.BaseMod.Common.UI.InGameTipsTools")
local EAvatarSlotType = import("EAvatarSlotType")
local EPawnState = import("EPawnState")
local ECharacterPoseState = import("ECharacterPoseType")
local GameLuaAPI = import("/Script/ShadowTrackerExtra.GameLuaAPI")
local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")
local ANewFakePlayerAIController = import("NewFakePlayerAIController")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local GameComponentData = require("GameLua.GameCore.Data.GameComponentData")
local GameplayActorData = require("GameLua.GameCore.Data.GameplayActorData")
local EMovementMode = import("EMovementMode")
local ESTEPoseState = import("ESTEPoseState")
local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
local ECharacterHealthStatus = import("ECharacterHealthStatus")
local FHealthPredictShowData = import("HealthPredictShowData")
local ELifetimeCondition = import("ELifetimeCondition")
CharacterBase.ServerRPC.ServerRPC_FailPreJoinDance = {
  Reliable = true,
  Params = {
    import("/Script/Engine.Actor")
  }
}
CharacterBase.ClientRPC.ClientRPC_FailedToJoinDance = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int
  }
}
CharacterBase.ClientRPC.ClientRPC_TryJoinDance = {
  Reliable = true,
  Params = {
    import("/Script/Engine.Actor"),
    UEnums.EPropertyClass.Int
  }
}
CharacterBase.ClientRPC.ClientRPC_ShowEffectAfterFruitBingo = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Str,
    UEnums.EPropertyClass.Str,
    UEnums.EPropertyClass.Int
  }
}
CharacterBase.ClientRPC.ClientRPC_PlayMontageCamera = {
  Reliable = true,
  Params = {
    import("/Script/CoreUObject.Vector"),
    UEnums.EPropertyClass.Float,
    UEnums.EPropertyClass.Float,
    UEnums.EPropertyClass.Str
  }
}
CharacterBase.MulticastRPC.ShowEffectAfterSelfRescueSucceed = {
  Reliable = true,
  Params = {}
}
CharacterBase.MulticastRPC.ServerShowShowUIConfigUI = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Str
  }
}
CharacterBase.MulticastRPC.MultiCast_GenericRPC = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int,
    {
      UEnums.EPropertyClass.Array,
      UEnums.EPropertyClass.Byte
    }
  }
}

function CharacterBase:ctor(selfType)
  self._SuperData = nil
  self.VehicleParachuteComponent = nil
  self.DefaultNetCullDistanceSq = 1600000000
  self.DiedTime = 0
  self.DiedPosition = FVector(0, 0, 0)
  self.TeammmatePositionWhenMeDied = {}
  self.DefaultFootStep = true
  self.tCorrectionSimulateRepData = {
    Timer = nil,
    CurRepLoc = nil,
    LastRepLoc = nil
  }
  self.LastAddBuffInstID = 0
  self.LastAddPawn = nil
  self.bDisableProne = false
  self.bHasShownExpiredNotice = false
  self.bHasShownDevNotice = false
  self.NTH_NativeESP_Ready = false
end

function CharacterBase:GetLifetimeReplicatedProps()
  local RepTable = {
    {
      "bCableCarView",
      ELifetimeCondition.COND_None,
      UEnums.EPropertyClass.Bool
    },
    {
      "bIsPlayingLevelSequenceForShow",
      ELifetimeCondition.COND_None,
      UEnums.EPropertyClass.Bool
    },
    {
      "bCounterattacking",
      ELifetimeCondition.COND_None,
      UEnums.EPropertyClass.Bool
    }
  }
  return RepTable
end

function CharacterBase:_PostConstruct()
  CharacterBase.__super._PostConstruct(self)
  self:NTHMOD_INJECT_MOD()
  self:AddControlEventWithCondition(self, "OnAttrChangeEventDelegate", {
    AttrName = {
      "bUseDeadBox",
      "IsInUnderGroundArea",
      "IsAroundUndergroundEntry",
      "EmotePlayRate",
      "AreaID",
      "MapID",
      "DanceStageAreaState"
    }
  }, self.CharacterAttrChangeEvent, self)
  self:AddControlEvent(self, "OnPawnRespawnDelegate", self.HandleOnRespawn, self)
  self:AddControlEvent(self, "OnParachuteStateChanged", self.LuaHandleParachuteStateChanged, self)
  self:AddControlEvent(self, "OnRepParachuteStateDelegate", self.LuaHandleRepParachuteStateDelegate, self)
  self:AddControlEvent(self, "OnPlayerPoseChange", self.PlayerPoseChange, self)
  self:AddControlEvent(self, "OnAttachedToVehicle", self.HandleAttachedToVehicle, self)
  self:AddControlEvent(self, "OnDetachedFromVehicle", self.HandleDetachedFromVehicle, self)
  if not Client then
    self.DefaultNetCullDistanceSq = self.NetCullDistanceSquared
    self.UseNewParachuteMove = false
    self.bIsPlayingLevelSequenceForShow = false
    self:SetNetUpdateGroupID(2)
    self:AddControlEvent(self, "IsEnterNearDeathDelegate", self.HandleServerEnterNearDeathDelegate, self)
    self:AddControlEvent(self, "OnPlayerStartRescue", self.HandleOnPlayerStartRescue, self)
    self:AddControlEvent(self, "StateEnterHandler", self.HandleOnEnterState, self)
    self:AddControlEvent(self, "OnHandleSkillStartDelegate", self.HandleOnSkillStart, self)
  else
    self.bClientCanTriggerSkill = true
    self:AddControlEvent(self, "OnPreRepAttachment", self.HandleOnPreRepAttachment, self)
    self:AddControlEvent(self, "IsEnterNearDeathDelegate", self.HandleIsEnterNearDeathDelegate, self)
    self:AddCommonEvent(EVENTTYPE_APPLICATION_ACTIVE_STATE, EVENTID_APPLICATION_REACTIVATED_EX, self.OnApplicationReactivated, self)
  end
  self:AddControlEvent(self, "OnDeathDelegate", self.HandleDeathDelegate, self)
end

function CharacterBase:OnDestroyed()
  self:Dispose()
  CharacterBase.__super.OnDestroyed(self)
end

function CharacterBase:ReceiveOnPoolCreate()
  self:ResetAnimInstanceClass()
end

function CharacterBase:CharacterIsRecycled()
  return false
end

function CharacterBase:BroadcastFatalDamageInfoWrapperSimpleLua(Causer, Victim, DamageType, AdditionalParam, IsHeadShot)
  local FatalDamageSubsystem = SubsystemMgr:Get("FatalDamageSubsystem")
  if FatalDamageSubsystem then
    FatalDamageSubsystem:BroadcastFatalDamageInfoWrapperSimpleLua(Causer, Victim, DamageType, AdditionalParam, IsHeadShot)
  end
end

function CharacterBase:BroadcastFatalDamageInfoWrapperLua(Causer, Victim, DamageType, AdditionalParam, IsHeadShot, ResultHealthStatus, PreviousHealthStatus, WhoKillMe, KillerKillCount)
  local FatalDamageSubsystem = SubsystemMgr:Get("FatalDamageSubsystem")
  if FatalDamageSubsystem then
    FatalDamageSubsystem:BroadcastFatalDamageInfoWrapperLua(Causer, Victim, DamageType, AdditionalParam, IsHeadShot, ResultHealthStatus, PreviousHealthStatus, WhoKillMe, KillerKillCount)
  end
end

function CharacterBase:OnApplicationReactivated()
  print(bWriteLog and "CharacterBase:OnApplicationReactivated FormReactivated true")
  self.FormReactivated = true
end

function CharacterBase:HandleOnEnterState(nState)
  if self:HasAuthority() then
    print(bWriteLog and "CharacterBase:HandleOnEnterState, nState = " .. tostring(nState) .. ", PlayerKey = " .. tostring(self.PlayerKey))
    local EPawnState = import("EPawnState")
    if nState == EPawnState.Dying or nState == EPawnState.Dead or nState == EPawnState.BeCarriedBack or nState == EPawnState.Dizziness or nState == EPawnState.Knock or nState == EPawnState.Arrest then
    else
      local AFKReportorSubsystem = SubsystemMgr:Get("AFKReportorSubsystem")
      if AFKReportorSubsystem then
        local PlayerState = self:GetPlayerStateSafety()
        if PlayerState and slua.isValid(PlayerState) then
          AFKReportorSubsystem:PlayerHaveAction(PlayerState.UID)
        else
          print(bWriteLog and "CharacterBase:HandleOnEnterState, PlayerState = " .. tostring(PlayerState))
        end
      else
        print(bWriteLog and "CharacterBase:HandleOnEnterState, AFKReportorSubsystem = nil")
      end
    end
  end
end

function CharacterBase:HandleOnSkillStart(uSkillCharacter, SkillID)
  if self:HasAuthority() then
    local AFKReportorSubsystem = SubsystemMgr:Get("AFKReportorSubsystem")
    if AFKReportorSubsystem then
      local PlayerState = self:GetPlayerStateSafety()
      if PlayerState and slua.isValid(PlayerState) then
        AFKReportorSubsystem:PlayerHaveAction(PlayerState.UID)
      else
        print(bWriteLog and "CharacterBase:HandleOnSkillStart, PlayerState = " .. tostring(PlayerState))
      end
    else
      print(bWriteLog and "CharacterBase:HandleOnSkillStart, AFKReportorSubsystem = nil")
    end
  end
end

function CharacterBase:HandCharacterDoJump()
  if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Walking then
    self.STCharacterMovement.Velocity.Z = self.STCharacterMovement.JumpZVelocity
    self.STCharacterMovement:SetMovementMode(EMovementMode.MOVE_Falling, 0)
    self:RemoveControlEvent(self, "CharacterDoJump")
    self:ServerTriggerJump()
    self:AddControlEvent(self, "CharacterDoJump", self.HandCharacterDoJump, self)
  end
end

function CharacterBase:HandleOnPreRepAttachment(uAttachParent, uAttachComponent, uAttachSocket, uLocationOffset, uRotationOffset, uRelativeScale3D)
  if uAttachParent and slua.isValid(uAttachParent) then
    if not Client.IsEnableDSGrayPublishFlag(2199023255552) or Client.IsEditor() then
      local ASTExtraVehicleBase = import("STExtraVehicleBase")
      if not Game:IsClassOf(uAttachParent, ASTExtraVehicleBase) then
        print(bWriteLog and "DebugAttach HandleOnPreRepAttachment not  STExtraVehicleBase return  PlayerKey:", self.PlayerKey)
        return
      end
      print(bWriteLog and "DebugAttach HandleOnPreRepAttachment uAttachParent ok PlayerKey:", self.PlayerKey)
      local RelativeLocation = FVector(0, 0, self:GetSimpleCollisionHalfHeightInStandPose())
      local uUseAttachComp
      if slua.isValid(uAttachComponent) then
        uUseAttachComp = uAttachComponent
      else
        if uAttachParent.GetMesh then
          uUseAttachComp = uAttachParent:GetMesh()
        end
        print(bWriteLog and "DebugAttach HandleOnPreRepAttachment uUseAttachComp nil or IsPendingKill, Please Check Vehicle's DefaultNetCullDistanceSq=3600000000.0 PlayerKey:", self.PlayerKey)
      end
      local VehicleSeat = uAttachParent:GetVehicleSeats()
      if slua.isValid(VehicleSeat) and slua.isValid(uUseAttachComp) then
        local RealSocketName = VehicleSeat:GetAttachSocketName(self, uUseAttachComp, uAttachSocket)
        if RealSocketName ~= "None" then
          print(bWriteLog and "CharacterBase:HandleOnPreRepAttachment", uAttachSocket, RealSocketName, uAttachParent)
          uAttachSocket = RealSocketName
        end
      end
      self:SetAttachment(uAttachParent, uUseAttachComp, RelativeLocation, uRotationOffset, uRelativeScale3D, uAttachSocket)
    end
  else
    print(bWriteLog and "DebugAttach HandleOnPreRepAttachment uAttachParent nil PlayerKey:", self.PlayerKey)
  end
end

function CharacterBase:HandleIsEnterNearDeathDelegate(IsNearDeath)
  if self.HealthStatus == ECharacterHealthStatus.FinishedLastBreath and self.LastHealthStatus == ECharacterHealthStatus.HasLastBreath then
    print(bWriteLog and "DeadAnimation HandleIsEnterNearDeathDelegate  call PlayerKey:", self.PlayerKey)
    if slua.isValid(self.Mesh) then
      self:CheckPlayDeadAnimation(self.Mesh.AnimScriptInstance)
      local uAnimInstances = self.Mesh:GetSubAnimInstances()
      for i = 1, uAnimInstances:Num() do
        local uAnimInst = uAnimInstances:Get(i - 1)
        self:CheckPlayDeadAnimation(uAnimInst)
      end
    end
  end
  local ENetRole = import("ENetRole")
  local EParachuteState = import("EParachuteState")
  if self.Role == ENetRole.ROLE_AutonomousProxy and self.HealthStatus == ECharacterHealthStatus.HasLastBreath and self.ParachuteState == EParachuteState.PS_Opening then
    self:SwitchCameraToParachuteOpening()
    print(bWriteLog and "NearDeathParachute parachute Death")
  end
  self:ClearFollowEmote()
end

function CharacterBase:HandleServerEnterNearDeathDelegate(IsNearDeath)
  if IsNearDeath then
    local Controller = self:GetPlayerControllerSafety()
    local SilentCommunicationSubsystem = SubsystemMgr:Get("SilentCommunicationSubsystem")
    if SilentCommunicationSubsystem then
      SilentCommunicationSubsystem:OnConditionTrigger(1, Controller)
    end
  end
end

function CharacterBase:GetSelfRescueSkillID()
  if self:HasState(EPawnState.AttachToOther) then
    return 0
  end
  return 1014669
end

function CharacterBase:HandleOnPlayerStartRescue(RescueWho, IsRescuing)
  if RescueWho and slua.isValid(RescueWho) and RescueWho == self.Object then
    print(bWriteLog and "CharacterBase:HandleOnPlayerStartRescue, IsRescuing = " .. tostring(IsRescuing) .. ", PlayerKey = " .. tostring(self.PlayerKey))
    if IsRescuing then
      local uWeaponManager = self:GetWeaponManager()
      if Game:IsValid(uWeaponManager) then
        uWeaponManager.HideCurrentWeapon = true
      else
        print(bWriteLog and "CharacterBase:HandleOnPlayerStartRescue, uWeaponManager invalid")
      end
      self.CachedSelfRescueSkillID = self:GetSelfRescueSkillID()
      self:TriggerEntrySkillWithID(self.CachedSelfRescueSkillID, true)
      local PlayerState = self:GetPlayerStateSafety()
      if Game:IsValid(PlayerState) then
        PlayerState:AddGeneralCount(1121, 1, false)
      end
    else
      local SkillManager = self:GetSkillManager()
      if SkillManager and slua.isValid(SkillManager) and self.CachedSelfRescueSkillID then
        local UTSkillStopReason = import("UTSkillStopReason")
        SkillManager:StopSkill(self.CachedSelfRescueSkillID, UTSkillStopReason.SkillStopReason_Interrupted)
        self.CachedSelfRescueSkillID = nil
      end
      local uWeaponManager = self:GetWeaponManager()
      if Game:IsValid(uWeaponManager) then
        uWeaponManager.HideCurrentWeapon = false
      else
        print(bWriteLog and "CharacterBase:HandleOnPlayerStartRescue, uWeaponManager invalid")
      end
    end
  end
  if IsRescuing then
    local Controller = self:GetPlayerControllerSafety()
    local SilentCommunicationSubsystem = SubsystemMgr:Get("SilentCommunicationSubsystem")
    if SilentCommunicationSubsystem then
      SilentCommunicationSubsystem:OnConditionTrigger(2, Controller)
    end
  else
    if not slua.isValid(RescueWho) then
      return
    end
    if RescueWho == self.Object then
      return
    end
    if RescueWho:HasState(EPawnState.Dying) then
      return
    end
    local uController = RescueWho:GetPlayerControllerSafety()
    if not slua.isValid(uController) then
      return
    end
    local uPlayerState = uController.PlayerState
    if not slua.isValid(uPlayerState) then
      return
    end
    local nKillerPlayerKey = uPlayerState.NearDeathCauserId
    local uKillerPlayerState = GameplayData.GetPlayerState(nKillerPlayerKey)
    if slua.isValid(uKillerPlayerState) and uKillerPlayerState.TeamID == self.TeamID and uPlayerState ~= uKillerPlayerState then
      return
    end
    local SilentCommunicationSubsystem = SubsystemMgr:Get("SilentCommunicationSubsystem")
    if SilentCommunicationSubsystem then
      SilentCommunicationSubsystem:OnConditionTrigger(2, uController, uController, 31006, 0, true, nil)
    end
  end
end

function CharacterBase:HandleDeathDelegate()
  print(bWriteLog and "CharacterBase HandleDeathDelegate" .. tostring(self.PlayerKey))
  if Client then
    self:ClearFollowEmote()
  end
  if slua.isValid(self.STCharacterMovement) then
    self.STCharacterMovement:Deactivate()
    self.STCharacterMovement:SetMovementMode(EMovementMode.MOVE_None, 0)
  end
end

function CharacterBase:GetTargetAnimClass()
  if self.AvatarAnimClassCache ~= nil then
    return self.AvatarAnimClassCache
  end
  local uPC = self:GetPlayerControllerSafety()
  if slua.isValid(uPC) then
    return self.MainCharAnimClass
  end
  if self:IsInCarryBackState() then
    local uBeCarriedCharacter = self:GetBeCarriedBackCharacter()
    if slua.isValid(uBeCarriedCharacter) and slua.isValid(uBeCarriedCharacter:GetPlayerControllerSafety()) then
      return self.MainCharAnimClass
    end
  end
  return self.MainCharTPPAnimClass
end

function CharacterBase:ResetCharAnimInstanceClass(SetReason, bForceClearOldAnim)
  self.Super:ResetCharAnimInstanceClass(SetReason, bForceClearOldAnim)
end

function CharacterBase:CheckPlayDeadAnimation(uAnimInst)
  if slua.isValid(uAnimInst) and uAnimInst.PlayPlayerDeadAnimation ~= nil and uAnimInst.C_IsNearDeathStatus ~= nil then
    local bResetND = false
    if uAnimInst.C_IsNearDeathStatus == true then
      uAnimInst.C_IsNearDeathStatus = false
      bResetND = true
    end
    local PrePose = uAnimInst.C_PoseType
    uAnimInst.C_PoseType = ECharacterPoseState.ECharPose_Crouch
    print(bWriteLog and "DeadAnimation HandleIsEnterNearDeathDelegate PlayPlayerDeadAnimation true PlayerKey:", self.PlayerKey)
    uAnimInst:PlayPlayerDeadAnimation()
    if bResetND then
      uAnimInst.C_IsNearDeathStatus = true
    end
    uAnimInst.C_PoseType = PrePose
  end
end
function CharacterBase:SetDiedTime()
  self.DiedTime = CGameState:GetServerWorldTimeSeconds()
  local PlayerState = self:GetPlayerStateSafety()
  if PlayerState == nil or slua.isValid(PlayerState) == false or PlayerState.SetDiedTime == nil then
    return
  end
  PlayerState:SetDiedTime()
end

function CharacterBase:GetDiedTime()
  if self.DiedTime then
    return self.DiedTime
  else
    return 0
  end
end

function CharacterBase:SetDiedPosition()
  self.DiedPosition = self:K2_GetActorLocation()
  self.TeammmatePositionWhenMeDied = {}
  local CharacterState = self:GetPlayerStateSafety()
  if CharacterState == nil then
    return
  end
  local TeammatesState = CharacterState.TeamMatePlayerStateList
  if TeammatesState == nil or TeammatesState:Num() <= 0 then
    return
  end
  for index = 0, TeammatesState:Num() - 1 do
    local uTeammatePlayerState = TeammatesState:Get(index)
    if uTeammatePlayerState and slua.isValid(uTeammatePlayerState) and slua.isValid(uTeammatePlayerState.TeamMatePlayerState) then
      local uOtherCharacter = uTeammatePlayerState.TeamMatePlayerState:GetPlayerCharacter()
      if uOtherCharacter and slua.isValid(uOtherCharacter) then
        self.TeammmatePositionWhenMeDied[uOtherCharacter.PlayerKey] = uOtherCharacter:K2_GetActorLocation()
      end
    end
  end
end

function CharacterBase:GetDiedPosition()
  if self.DiedPosition then
    return self.DiedPosition
  else
    return FVector(0, 0, 0)
  end
end

function CharacterBase:GetTeammatePositionWhenMeDied()
  return self.TeammmatePositionWhenMeDied
end

function CharacterBase:SetDiedPlayerCount()
  local uPlayerState = self:GetPlayerStateSafety()
  if uPlayerState == nil or slua.isValid(uPlayerState) == false then
    print(bWriteLog and "CharacterBase:SetDiedPlayerCount, PlayerKey = " .. tostring(self.PlayerKey) .. ", uPlayerState is invalid")
    return
  end
  if uPlayerState.SetDiedPlayerCount == nil then
    print(bWriteLog and "CharacterBase:SetDiedPlayerCount, PlayerKey = " .. tostring(self.PlayerKey) .. ", uPlayerState has no SetDiedPlayerCount function")
    return
  end
  uPlayerState:SetDiedPlayerCount()
end

function CharacterBase:ReceiveBeginPlay()
  printf("CharacterBase ReceiveBeginPlay() PlayerKey:%s", tostring(self.PlayerKey))
  CharacterBase.__super.ReceiveBeginPlay(self)
  GameplayData.BindPlayerCharacter(self.Object)
  self:ConditionChangePhysicsAsset()
  if Client then
    local AvatarExceptionSubsystem = SubsystemMgr:Get("AvatarExceptionSubsystem")
    if AvatarExceptionSubsystem then
      AvatarExceptionSubsystem:BindPlayerCharacter(self.Object)
    end
  end
  if self.LuaReceiveBeginPlay then
    self:LuaReceiveBeginPlay()
  end
  self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, {
    [1] = "FightingState"
  }, self.HandleEnterGameModeFightingState, self)
  self:CheckInitPlayerDSData()
  if self.DelayResetStandDuration ~= nil and self.DelayHideDuration ~= nil then
    self.DelayResetStandDuration = self.DelayHideDuration
  end
  if self:HasAuthority() and slua.isValid(self.NearDeatchComponent) then
    self:AddControlEvent(self.NearDeatchComponent, "OnPreEnterNearDeath", self.HandleOnPreEnterNearDeath, self)
  end
  if self:IsAutonomousProxy() and slua.isValid(self.STCharacterMovement) then
    self:AddControlEvent(self.STCharacterMovement, "OnClientAdjustPosition", self.HandleOnClientAdjustPosition, self)
    self.STCharacterMovement.ForbiddenMoveCondition.ContinueSeconds = 10
  end
  if CGame:IsEditor() then
    local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
    local SecurtyEditorConfig = GamePlayTools.GetCurrentConfig("SecurtyEditorConfig")
    if SecurtyEditorConfig and SecurtyEditorConfig.GameSafeCallbacks then
      require(SecurtyEditorConfig.GameSafeCallbacks)
    end
  end
  local UKismetSystemLibrary = import("KismetSystemLibrary")
  if UKismetSystemLibrary.IsDedicatedServer(self) and GameSafeCallbacks then
    GameSafeCallbacks.CharacterReceiveBeginPlay(self)
    self.bSkipComparePropertiesForReplay = true
  end
  if Client then
    self:AddControlEvent(self, "OnCharacterFallingModeChange", self.HandleCharacterFallingModeChange, self)
  end
  if self:HasAuthority() then
    local Config = require("GameLua.Mod.BaseMod.DS.Config.SelfRescueConfig")
    if Config then
      if Config.HurtWhenSelfRescue ~= nil then
        self.HurtWhenSelfRescue = Config.HurtWhenSelfRescue
      end
      if Config.CoolDownTime ~= nil then
        self.SelfRescueCoolDownTime = Config.CoolDownTime
      end
      print(bWriteLog and "CharacterBase:ReceiveBeginPlay, Set HurtWhenSelfRescue = " .. tostring(self.HurtWhenSelfRescue) .. ", SelfRescueCoolDownTime = " .. tostring(self.SelfRescueCoolDownTime))
    end
    self:ReplaceGrenadeSkills()
  end
  if self:IsAutonomousProxy() then
    local CurrentVehicle = self:GetCurrentVehicle()
    if slua.isValid(CurrentVehicle) then
      self:ChangeCurrentVehicle(CurrentVehicle)
    end
    self:AddControlEvent(self, "OnClientCurrentVehicleChange", self.ChangeCurrentVehicle, self)
    local CurrentShootWeapon = self:GetCurrentShootWeapon()
    if slua.isValid(CurrentShootWeapon) then
      self:ChangeCurrentWeapon(CurrentShootWeapon)
    end
    GameComponentData.AddSelfWeaponManagerComponentEvent(self, "ChangeCurrentUsingWeaponDelegate", self.ChangeCurrentWeapon, self)
    if self.ReportCharacterStateTimer then
      self:RemoveGameTimer(self.ReportCharacterStateTimer)
      self.ReportCharacterStateTimer = nil
    end
    self.ReportCharacterStateTimer = self:AddGameTimer(5.0, true, function()
      self:ReportCharacterState()
    end)
  end
  if Client and self:IsAutonomousProxy() then
    self:RegistAttrModifyRecordList()
  end
  if Client then
    local uGameState = slua_GameFrontendHUD:GetGameState()
    if uGameState and slua.isValid(uGameState) and uGameState.GetGameModeState and uGameState:GetGameModeState() == "FightingState" then
      local NewObjectPoolLuaBridgeSubsystem = SubsystemMgr:Get("NewObjectPoolLuaBridgeSubsystem")
      if NewObjectPoolLuaBridgeSubsystem then
        NewObjectPoolLuaBridgeSubsystem.SpawnActorCounter_Character = NewObjectPoolLuaBridgeSubsystem.SpawnActorCounter_Character + 1
      end
    end
    local UKismetSystemLibrary = import("KismetSystemLibrary")
    if slua.isValid(self.STCharacterMovement) then
      self.STCharacterMovement.MoveSkipTickContinueTime = 2
      self.STCharacterMovement.MoveSkipTickContinueCount = 40
      self.STCharacterMovement.SimulateDelayReceiveLODTheshold = 16
      self.STCharacterMovement.SimulateNotMoveSmoothLODTheshold = 14
    end
    if Client.IsDevelopment() then
      self:DevelopmentClientCheck()
    end
    local ENetRole = import("ENetRole")
    if self.Role == ENetRole.ROLE_SimulatedProxy then
      self:RefreshThermalImagingLocal()
    end
  end
  if self:HasAuthority() and slua.isValid(self.STCharacterMovement) then
    self:AddControlEvent(self.STCharacterMovement, "OnComponentActivated", self.OnMovementActivated, self)
    self:AddControlEvent(self.STCharacterMovement, "OnResolvePenetrationDelegate", self.HandleOnResolvePenetrationDelegate, self)
  end
  local ENetRole = import("ENetRole")
  if self.Role == ENetRole.ROLE_AutonomousProxy and slua.isValid(self.STCharacterMovement) then
    self.STCharacterMovement.bOpenLocationSmoothOnDynamicMovementBase = false
    print(bWriteLog and "CharacterBase:ReceiveBeginPlay bOpenLocationSmoothOnDynamicMovementBase false")
  end
  self:ShowDoorInteractUIIfNeed()
  if Client then
    self:AddControlEvent(self, "OnSmartBearerLayerVisibilityChanged", self._OnSmartBearerLayerVisibilityChanged, self)
  end
  if Client then
    GameplayData.AddCharacter(self.Object)
  else
    -- NOTE: upstream bug: HandleFinishedState is a subclass method, undefined on CharacterBase, so nil is registered as the handler.
    self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, {
      [1] = "FinishedState"
    }, self.HandleFinishedState, self)
  end
  -- NOTE: upstream bug: EVENTTYPE_SINGLETRAINING is defined nowhere, so this posts with a nil event type.
  EventSystem:postEvent(EVENTTYPE_SINGLETRAINING, EVENTID_CHARACTER_BEGINPLAY, self.Object)
end

function CharacterBase:_OnSmartBearerLayerVisibilityChanged(bSmartBearerVisible)
  printf("CharacterBase:_OnSmartBearerLayerVisibilityChanged %s", tostring(bSmartBearerVisible))
  local EMeshVisibleLayer = import("/Script/Engine.EMeshVisibleLayer")
  local ESkeletaTickMode = import("/Script/Engine.ESkeletaTickMode")
  local uMesh = self.Mesh
  if slua.isValid(uMesh) then
    if bSmartBearerVisible then
      uMesh:SetLayerVisibilityValue(EMeshVisibleLayer.VisibleLayer_2, false, false)
      uMesh:SetTickMode(ESkeletaTickMode.TICK_NONE)
    else
      uMesh:SetLayerVisibilityValue(EMeshVisibleLayer.VisibleLayer_2, true, false)
      uMesh:SetTickMode(ESkeletaTickMode.TICK_ALL)
    end
  end
end

function CharacterBase:ConditionChangePhysicsAsset()
  if Client then
    local uMyMesh = self.Mesh
    if slua.isValid(uMyMesh) then
      local uMyMeshPhysics = USTExtraBlueprintFunctionLibrary.GetPhysicsAssetFromMesh(uMyMesh)
      if uMyMeshPhysics == self.ShootPhysicsAsset and slua.isValid(self.ShootPhysicsAssetOpt) and uMyMesh.SetPhysicsAsset then
        uMyMesh:SetPhysicsAsset(self.ShootPhysicsAssetOpt, true)
        USTExtraBlueprintFunctionLibrary.CreatePhysicsState(uMyMesh)
        printf(string.format("CharacterBase:ReceiveBeginPlay SetPhysicsAsset"))
      end
      printf(string.format("CharacterBase:ReceiveBeginPlay GetPhysicsAssetFromMesh %s->%s)", tostring(uMyMeshPhysics), tostring(self.ShootPhysicsAsset)))
    end
  end
end

function CharacterBase:ShowDoorInteractUIIfNeed()
  local ENetRole = import("ENetRole")
  if Client and self.Role == ENetRole.ROLE_AutonomousProxy then
    self:AddGameTimer(1, false, function()
      local CapsuleComponent = self and self.CapsuleComponent
      if CapsuleComponent and slua.isValid(CapsuleComponent) then
        local ActorClass = import("/Script/Engine.Actor")
        local PUBGDoorClass = import("PUBGDoor")
        local OverlapActors = CapsuleComponent:GetOverlappingActors(slua.Array(UEnums.EPropertyClass.Object, ActorClass), PUBGDoorClass)
        if OverlapActors and OverlapActors:Num() > 0 then
          for Index = 0, OverlapActors:Num() - 1 do
            local PUBGDoor = OverlapActors:Get(Index)
            if PUBGDoor and slua.isValid(PUBGDoor) and PUBGDoor.bDoubleDoor == false and PUBGDoor.DoorBroken == false then
              local FHitResult = import("/Script/Engine.HitResult")
              local uHitResult = FHitResult()
              print(bWriteLog and "CharacterBase:ShowDoorInteractUIIfNeed, Call PUBGDoor:OnBeginOverlap")
              PUBGDoor:OnBeginOverlap(PUBGDoor.Interaction, self.Object, CapsuleComponent, -1, true, uHitResult)
            end
          end
        end
      end
    end)
  end
end

function CharacterBase:DevelopmentClientCheck()
  if slua.isValid(self.HitBox_Stand) or slua.isValid(self.HitBox_Prone) then
    local UKismetSystemLibrary = import("KismetSystemLibrary")
    if UKismetSystemLibrary.IsStandalone(slua.getGameInstance()) then
    else
      local Tips = "DevelopmentClientCheck: "
      Tips = Tips .. string.format("Character =  %s ", tostring(self.Object))
      Tips = Tips .. string.format("HitBox_Stand =  %s ", tostring(self.HitBox_Stand))
      Tips = Tips .. string.format("HitBox_Prone =  %s ", tostring(self.HitBox_Prone))
      print(bWriteLog and "CharacterBase:DevelopmentClientCheck.." .. tostring(Tips))
      self:RPC_Server_ShootVertifyFailAlarm(4, Tips)
    end
  end
end

function CharacterBase:IsAutonomousProxy()
  if CharacterBase.__super.IsAutonomousProxy(self) then
    return true
  end
  if Client and self.IsLocallyControlled and type(self.IsLocallyControlled) == "function" and self:IsLocallyControlled() then
    return true
  end
  -- NOTE: upstream redundancy: the first branch already returned on a true result, so this tail can only return a falsy one.
  return CharacterBase.__super.IsAutonomousProxy(self)
end

function CharacterBase:SetLastAddBuffInst(nInstID, uPawn)
  self.LastAddBuffInstID = nInstID
  self.LastAddPawn = uPawn
end

function CharacterBase:GetLastAddBuffInst()
  return self.LastAddBuffInstID, self.LastAddPawn
end

function CharacterBase:RegistAttrModifyRecordList()
end

function CharacterBase:ChangeCurrentVehicle(CurrentVehicle)
  GameplayActorData.BindSelfActor("CurrentVehicle", CurrentVehicle)
end

function CharacterBase:ChangeCurrentWeapon()
  if self.GetCurrentWeapon == nil then
    return
  end
  local uWeapon = self:GetCurrentWeapon()
  if slua.isValid(uWeapon) then
    GameplayActorData.BindSelfActor("CurrentWeapon", uWeapon)
  end
end

function CharacterBase:HandleOnClientAdjustPosition(NewLocation, Reason)
  if CGameState == nil or not slua.isValid(CGameState) then
    return
  end
  if CGameState.GetGameModeState == nil or CGameState:GetGameModeState() == "ReadyState" then
    return
  end
  local EReason = import("ECharacterMoveDragReason")
  if Reason == EReason.CMDR_ExceedsDistance and self.PlayerState and self.PlayerState.Ping then
    local bWeakNet = self.PlayerState.Ping * 4 > 250 or false
    print(bWriteLog and "CharacterBase:HandleOnClientAdjustPosition ", " Ping: ", self.PlayerState and self.PlayerState.Ping * 4 or -1)
    if bWeakNet then
      NetUtil.ShowDSTimeOutTipsUI(true, NetUtil.DSTimeOutShort)
      self:AddGameTimer(1, false, function()
        NetUtil.ShowDSTimeOutTipsUI(false, NetUtil.DSTimeOutShort)
      end)
    end
  end
end

function CharacterBase:CheckInitPlayerDSData()
  if self:IsAutonomousProxy() then
    if self.PlayerKey ~= nil and self.PlayerKey > 0 then
      self:InitPlayerDsData(self.PlayerKey)
    else
      self:AddControlEvent(self, "OnReceivePlayerKey", self.InitPlayerDsData, self)
    end
  end
end

function CharacterBase:InitPlayerDsData(nPlayerKey)
  if nPlayerKey == nil or nPlayerKey == 0 then
    print(bWriteLog and "CharacterBase InitPlayerDsData playerKey:", nPlayerKey)
    return
  end
  local PlayerEventSubsystem = SubsystemMgr:Get("PlayerEventSystem")
  if PlayerEventSubsystem then
    PlayerEventSubsystem:CheckInitDSData(nPlayerKey)
  end
end

function CharacterBase:ReceiveEndPlay(nDeltaSeconds)
  printf("CharacterBase ReceiveEndPlay() PlayerKey:%s", tostring(self.PlayerKey))
  if Client then
    local SKillManager = self:GetSkillManager()
    local CheckWeaponSkillID = 1014405
    if slua.isValid(SKillManager) and SKillManager:GetCurSkillID() == CheckWeaponSkillID then
      self:StopCurrentLevelSequence()
    end
    if self.ReportCharacterStateTimer then
      self:RemoveGameTimer(self.ReportCharacterStateTimer)
      self.ReportCharacterStateTimer = nil
    end
  end
  GameplayData.UnbindPlayerCharacter(self.Object)
  if Client then
    local AvatarExceptionSubsystem = SubsystemMgr:Get("AvatarExceptionSubsystem")
    if AvatarExceptionSubsystem then
      AvatarExceptionSubsystem:UnbindPlayerCharacter(self.Object)
    end
  end
  if self.PlayerKey ~= nil and self.PlayerKey > 0 then
    EventSystem:postEvent(EVENTTYPE_PLAYEREVENT_WEAPON, EVENTID_PLAYEREVENT_WEAPON_CLEAR, self.PlayerKey)
    local PlayerEventSubsystem = SubsystemMgr:Get("PlayerEventSystem")
    if PlayerEventSubsystem then
      PlayerEventSubsystem:ClearPlayer(self.PlayerKey)
    end
  end
  self:ClearFollowEmote()
  if not self:HasAuthority() then
    self:ClearAkEventSound()
  end
  self._SuperData = nil
  if Client and self._BloodSpotDelegateHandles then
    for sName, Info in pairs(self._BloodSpotDelegateHandles) do
      if type(Info) == "table" then
        local Provider = Info.Provider
        local Handle = Info.Handle
        if Handle then
          if slua.isValid(Provider) then
            local EventDelegate = Provider.AsyncLoadParticleComponentDone
            if slua.isValid(EventDelegate) and EventDelegate.Remove then
              EventDelegate:Remove(Handle)
            else
              slua.removeDelegate(Handle)
            end
          else
            slua.removeDelegate(Handle)
          end
        end
      end
      self._BloodSpotDelegateHandles[sName] = nil
    end
    self._BloodSpotDelegateHandles = nil
  end
  CharacterBase.__super.ReceiveEndPlay(self, nDeltaSeconds)
end

function CharacterBase:GetVehicleParachuteComponent()
  if self.VehicleParachuteComponent == nil then
    local ComponentClass = import("VehicleParachuteComponent")
    self.VehicleParachuteComponent = self:GetComponentByClass(ComponentClass)
  end
  return self.VehicleParachuteComponent
end

function CharacterBase:ReceivePossessed(InController)
  if not slua.isValid(InController) then
    return
  end
  print(bWriteLog and "CharacterBase:ReceivePossessed")
  self.Super:ReceivePossessed(InController)
  local FeatureUtil = require("GameLua.Mod.BaseMod.GamePlay.Feature.Common.FeatureUtil")
  FeatureUtil.ForEachFeatureCall(self, "ReceivePossessed", InController)
  self:HandleUseGlide(InController)
  self:HandleParachuteComponent(InController)
  self:InitRevivalCount(InController)
  if not Client and not Game:IsAIController(InController) then
    self:RegistAttrModifyRecordList()
  elseif not Client and Game:IsAIController(InController) then
    self.IndoorCheckTime = 2
  end
  printf(bWriteLog and "CharacterBase:ReceivePossessed Before PlayerKey:%d NetConsiderFrequency:%f NetUpdateFrequency:%f MinNetUpdateFrequency:%f", self.PlayerKey, self.NetConsiderFrequency, self.NetUpdateFrequency, self.MinNetUpdateFrequency)
  local bBatchMove = USTExtraBlueprintFunctionLibrary.IsActorRepMovementWithBatch(self.Object)
  self:RefreshNetUpdateFrequency(bBatchMove)
  if InController and slua.isValid(InController) and InController.RefreshNetUpdateFrequency then
    InController:RefreshNetUpdateFrequency(bBatchMove)
  end
  self:AddGameTimer(5, false, function()
    if self.PlayerKey ~= nil then
      printf(bWriteLog and "CharacterBase:ReceivePossessed After PlayerKey:%d NetConsiderFrequency:%f NetUpdateFrequency:%f MinNetUpdateFrequency:%f", self.PlayerKey, self.NetConsiderFrequency, self.NetUpdateFrequency, self.MinNetUpdateFrequency)
    end
  end)
end

function CharacterBase:HandleParachuteComponent(InController)
  if slua.isValid(InController) and slua.isValid(self.ParachuteComponent) then
    if Game:IsClassOf(InController, ASTExtraPlayerController) then
      self.ParachuteComponent:InitParachuteData(InController)
    elseif Game:IsClassOf(InController, ANewFakePlayerAIController) and self.ParachuteComponent.InitAIParachuteData then
      self.ParachuteComponent:InitAIParachuteData(InController)
    end
  end
end

function CharacterBase:InitRevivalCount(InController)
  if not self:HasAuthority() then
    return
  end
  local uPlayerState = self:GetPlayerStateSafety()
  if uPlayerState and slua.isValid(uPlayerState) then
    if uPlayerState.InitRevivalCountImpl then
      uPlayerState:InitRevivalCountImpl(InController, self.Object)
    else
      print(bWriteLog and "CharacterBase:InitRevivalCount, have no function InitRevivalCountImpl")
    end
  else
    print(bWriteLog and "CharacterBase:InitRevivalCount, uPlayerState = " .. tostring(uPlayerState))
  end
end

function CharacterBase:HandleUseGlide(InController)
  if self:HasAuthority() then
    self:InitParachutingVehicle()
  end
end

function CharacterBase:HandleEnterGameModeFightingState()
  print(bWriteLog and "CharacterBase:HandleEnterGameModeFightingState")
  if slua.isValid(CGameState) and CGameState:IsCreativeMode() then
    return
  end
  if self:CharacterIsRecycled() then
    print(bWriteLog and "CharacterBase:HandleEnterGameModeFightingState, CharacterIsRecycled = true")
    return
  end
  if slua.isValid(self.Object) and not self:HasAuthority() and self.EmoteBPIDToAnimHandleMap then
    local CheckTable = {
      2206015,
      2206016,
      2206017,
      2206018
    }
    for _, ID in pairs(CheckTable) do
      local EmoteHandle = self.EmoteBPIDToAnimHandleMap:Get(ID)
      if slua.isValid(EmoteHandle) and EmoteHandle.EmoteActionList then
        local NeedStop = false
        for _, Action in pairs(EmoteHandle.EmoteActionList) do
          if Action:GetIsExecuting() then
            NeedStop = true
            break
          end
        end
        if NeedStop then
          self:OnPlayEmoteStop(ID)
        end
      end
    end
  end
end

function CharacterBase:InitParachutingVehicle()
  if self:HasAuthority() then
    if self.bEnsure then
      print(bWriteLog and "CharacterBase:InitParachutingVehicle self.bEnsure")
      return
    end
    local ComponentClass = self.DynamicComponentMap:Get("ParachutingVehicle")
    if ComponentClass then
      local UScriptGameplayStatics = import("ScriptGameplayStatics")
      UScriptGameplayStatics.CreateComponent(self, ComponentClass, "ParachutingVehicle", false)
    else
      print(bWriteLog and "CharacterBase:InitParachutingVehicle not ComponentClass")
    end
  end
end

function CharacterBase:PlayerPoseChange(stLastPoseState, stNewPoseState)
  local ESTEPoseState = import("ESTEPoseState")
  if Client and (self.IsClientPeeking and stNewPoseState == ESTEPoseState.Sprint or stNewPoseState == ESTEPoseState.CrouchSprint) then
    self:NM_ForceSetPeekState(false, false)
  end
end

function CharacterBase:HandleAttachedToVehicle(uVehicle)
  if not slua.isValid(uVehicle) then
    return
  end
  if slua.isValid(self.CharacterMovement) then
    self.CharacterMovement:SetBase(nil, "", true)
  end
  if uVehicle.ForceUseTPP then
    print(bWriteLog and "CharacterBase:HandleAttachedToVehicle, bIsFPPOnVehicle: false", self.Object, uVehicle)
    self.bIsFPPOnVehicle = false
  end
end

function CharacterBase:HandleDetachedFromVehicle(uLastVehicle)
  if not slua.isValid(self.Object) or not slua.isValid(uLastVehicle) then
    return
  end
  if uLastVehicle.ForceUseTPP then
    print(bWriteLog and "CharacterBase:HandleAttachedToVehicle, bIsFPPOnVehicle: true", self.Object, uLastVehicle)
    self.bIsFPPOnVehicle = true
  end
  if Client then
    local Location = self:K2_GetActorLocation()
    if Location.X > -1.0E-5 and Location.X < 1.0E-5 and -1.0E-5 < Location.Y and 1.0E-5 > Location.Y and -1.0E-5 < Location.Z and 1.0E-5 > Location.Z then
      Location = uLastVehicle:K2_GetActorLocation() + FVector(0, 0, 200)
      print(bWriteLog and string.format("CharacterBase:HandleAttachedToVehicle, Vehicle: %s, character location: %s", uLastVehicle, Location))
      self:K2_SetActorLocation(Location, false, nil, true)
    end
  end
end

function CharacterBase:SwitchWeaponBySlotAfterConsume(OldWeaponSlotBeforeSkill)
  print(bWriteLog and "SwitchWeaponBySlotAfterConsume", OldWeaponSlotBeforeSkill)
  local ESurviveWeaponPropSlot = import("ESurviveWeaponPropSlot")
  if OldWeaponSlotBeforeSkill == ESurviveWeaponPropSlot.SWPS_HandProp then
    local Controller = self:GetPlayerControllerSafety()
    if not (slua.isValid(Controller) and GameLuaAPI.IsClassOf(Controller, ASTExtraPlayerController)) or not self:AllowState(EPawnState.SwitchWeapon, false) then
      return
    end
    if self:HasState(EPawnState.WebSwing) and slua.isValid(self.STCharacterMovement) then
      local ESpecialMovementType = import("ESpecialMovementType")
      local ESpiderSwingMoveState = import("ESpiderSwingMoveState")
      local SpiderSwingObj = self.STCharacterMovement:GetSpecialMoveObjBySpecialMoveType(ESpecialMovementType.SPECIAL_MOVE_SpiderSwing)
      if slua.isValid(SpiderSwingObj) then
        local nCurState = SpiderSwingObj:GetCurMoveState()
        if nCurState == ESpiderSwingMoveState.Launching or nCurState == ESpiderSwingMoveState.Swinging then
          print(bWriteLog and "CharacterBase:SwitchWeaponBySlotAfterConsume blocked by SpiderSwing state: " .. tostring(nCurState))
          return
        end
      end
    end
    Controller:ServerAutoSwitchSameSlotWeapon(OldWeaponSlotBeforeSkill)
  else
    self:SwitchWeaponBySlot(OldWeaponSlotBeforeSkill, true, false, false)
  end
end

function CharacterBase:IsEnablePlayerShovleing()
  local EPawnState = import("EPawnState")
  return not self:HasState(EPawnState.Prone) and self:HasState(EPawnState.Sprint)
end

function CharacterBase:OnRep_CarryBackStateChanged()
  local uCarryBackComp = self:GetCarryBackComp()
  if slua.isValid(uCarryBackComp) then
    uCarryBackComp:OnRep_CarryBackStateChanged()
  end
end

function CharacterBase:ShowCharacter(bShow)
  print(bWriteLog and "CharacterBase ShowCharacter", bShow, self.PlayerKey)
  self:SetActorHiddenInGame(not bShow)
end

function CharacterBase:ShowMainWeaponOnBack(bShow)
  local uWeaponMgrCom = self:GetWeaponManager()
  if uWeaponMgrCom and slua.isValid(uWeaponMgrCom) then
    uWeaponMgrCom.ShowMainWeaponModelOnBack = bShow
  end
end

function CharacterBase:AddRevivalCount(nRevivalCount)
  if type(nRevivalCount) == "number" then
    local uPlayerState = self:GetPlayerStateSafety()
    if uPlayerState and slua.isValid(uPlayerState) then
      if uPlayerState.GetRevivalCount and uPlayerState.SetRevivalCount then
        local GeneralRevivalCount = uPlayerState:GetRevivalCount()
        GeneralRevivalCount = GeneralRevivalCount + nRevivalCount
        if GeneralRevivalCount < 0 then
          GeneralRevivalCount = 0
        end
        print(bWriteLog and "CharacterBase:AddRevivalCount, nRevivalCount = " .. tostring(nRevivalCount))
        uPlayerState:SetRevivalCount(GeneralRevivalCount)
      else
        print(bWriteLog and "CharacterBase:AddRevivalCount, Have no function")
      end
    end
  else
    print(bWriteLog and "CharacterBase:AddRevivalCount, type(nRevivalCount) = " .. type(nRevivalCount))
  end
end

function CharacterBase:SetUseDeadBox(bUseDeadBox)
  local eUseDeadBox = 1
  if not bUseDeadBox then
    eUseDeadBox = 0
  end
  printf("revivaldebug CharacterBase SetUseDeadBox PlayerKey:%u, eUseDeadBox:%d ", self.PlayerKey, eUseDeadBox)
  self:SetAttrValue("bUseDeadBox", eUseDeadBox, -1)
end

function CharacterBase:GetUseDeadBox()
  local fUseDeadBox = self:GetAttrValue("bUseDeadBox")
  local nUseDeadBox = math.floor(fUseDeadBox + 0.1)
  return 0 < nUseDeadBox
end

function CharacterBase:CharacterAttrChangeEvent(uPawn, AttrName, AttrVal)
  if self.Object == uPawn then
    if AttrName == "bUseDeadBox" then
      self.bIsUseDeadBox = self:GetUseDeadBox()
      print(bWriteLog and "revivaldebug CharacterBase CharacterAttrChangeEvent PlayerKey:, self.bIsUseDeadBox:", self.PlayerKey, self.bIsUseDeadBox)
    elseif AttrName == "IsInUnderGroundArea" then
      self.bIsInUnderGroundArea = AttrVal == 1
      if not Client then
        local ESightVisionCondition = import("ESightVisionCondition")
        local USTExtraModLogicSwitchLibrary = import("STExtraModLogicSwitchLibrary")
        if USTExtraModLogicSwitchLibrary.IsNightVisionUnderGroundOnly() then
          self:SetSightCondition(self.bIsInUnderGroundArea, ESightVisionCondition.NightVisionUnderGround)
        end
      end
    elseif AttrName == "IsAroundUndergroundEntry" then
      self.bIsAroundUndergroundEntry = AttrVal == 1
    elseif AttrName == "EmotePlayRate" then
      if Client then
        local PhotoGrapherSubSystem = SubsystemMgr:Get("PhotoGrapherSubSystem")
        if PhotoGrapherSubSystem then
          PhotoGrapherSubSystem:EmotePlayRateChanged(self.Object, AttrVal)
        end
      end
    elseif AttrName == "AreaID" then
      self:ChangeFootStepValue(AttrVal)
      self:HandleAreaIDChanged(AttrVal)
      if self:IsLocalControlorView() or self:IsLocalViewed() then
        print(bWriteLog and "revivaldebug CharacterBase CharacterAttrChangeEvent PlayerKey:, AreaID", self.PlayerKey, AttrVal)
        EventSystem:postEvent(EVENTTYPE_PLAYEREVENT_CHARACTER, EVENTID_PLAYEREVENT_LOCAL_CHAR_AREA_ID_CHANGED, AttrVal)
      else
        EventSystem:postEvent(EVENTTYPE_PLAYEREVENT_CHARACTER, EVENTID_PLAYEREVENT_CHAR_AREA_ID_CHANGED, AttrVal)
      end
    elseif AttrName == "MapID" then
      if self:IsLocalControlorView() or self:IsLocalViewed() then
        print(bWriteLog and "revivaldebug CharacterBase CharacterAttrChangeEvent PlayerKey:, MapID:", self.PlayerKey, AttrVal)
        EventSystem:postEvent(EVENTTYPE_PLAYEREVENT_CHARACTER, EVENTID_PLAYEREVENT_LOCAL_CHAR_MAP_ID_CHANGED, AttrVal)
      end
    elseif AttrName == "DanceStageAreaState" and Client then
      EventSystem:postEvent(EVENTTYPE_PLAYEREVENT_CHARACTER, EVENTID_PLAYEREVENT_DANCESTATE_CHANGED, AttrVal, self.Object)
    end
  end
end

function CharacterBase:ChangeFootStepValue(AttrVal)
  if self.DefaultFootStep and AttrVal == 0 then
    return
  end
  local FootStepSoundConfig = GamePlayTools.GetCurrentConfig("FootStepSoundConfig")
  if not FootStepSoundConfig or not FootStepSoundConfig.bOpenAreaFootStep then
    return
  end
  local IntVal = math.tointeger(AttrVal)
  local AreaPara = FootStepSoundConfig[IntVal] or FootStepSoundConfig.DefaultPara
  local DefaultPara = FootStepSoundConfig.DefaultPara
  self.DefaultFootStep = AreaPara == DefaultPara
  self.FloorHeight = AreaPara.FloorHeight or DefaultPara.FloorHeight
  self.GFloorValue = AreaPara.GFloorValue or DefaultPara.GFloorValue
  self.DiffFloorValue = AreaPara.DiffFloorValue or DefaultPara.DiffFloorValue
  print(bWriteLog and "CharacterBase:ChangeFootStepValue, FloorHeight = " .. self.FloorHeight)
  self.bInSoundDiffFloorArea = AreaPara.bInSoundDiffFloorArea or DefaultPara.bInSoundDiffFloorArea
end

function CharacterBase:HandleAreaIDChanged(AttrVal)
  print(bWriteLog and "CharacterBase:HandleAreaIDChanged, AttrVal = " .. tostring(AttrVal))
end

function CharacterBase:HandleOnRespawn()
  printf("revivaldebug CharacterBase HandleOnRespawn")
  if self:IsAuthority() then
    printf(bWriteLog and "revivaldebug CharacterBase HandleOnRespawn self.PlayerKey:%u", self.PlayerKey)
    EventSystem:postEvent(EVENTTYPE_SECURITY, EVENTID_SECURITY_PLAYER_RESPAWN, self.Object)
  else
    local ENetRole = import("ENetRole")
    local uPlayerController = self:GetPlayerControllerSafety()
    if self:IsAutonomousProxy() then
      local UGameplayStatics = import("GameplayStatics")
      local uGameInstance = UGameplayStatics.GetGameInstance(self)
      if slua.isValid(uGameInstance) then
        local uReplay = uGameInstance:GetClientInGameReplay()
        if slua.isValid(uReplay) and uReplay:IsInRecordState() then
          printf("revivaldebug CharacterBase HandleOnRespawn clear deathplayback data")
          uReplay:OnPlayerRespawnNotify()
        end
      end
      local VibrateUtilitySubsystem = SubsystemMgr:Get("VibrateUtilitySubsystem")
      if VibrateUtilitySubsystem and VibrateUtilitySubsystem.HandleCharacterRespawned then
        print(bWriteLog and "CharacterBase.HandleOnRespawn VibrateUtilitySubsystem call HandleCharacterRespawned")
        VibrateUtilitySubsystem:HandleCharacterRespawned()
      end
      if slua.isValid(uPlayerController) and not uPlayerController:IsPureSpectator() and not uPlayerController:IsDemoPlayGlobalObserver() and not uPlayerController:IsDemoPlaySpectator() then
        print(bWriteLog and "CharacterBase.HandleOnRespawn QuitSpectating")
        uPlayerController:QuitSpectating()
        local uViewTarget = uPlayerController:GetViewTarget()
        if slua.isValid(uViewTarget) and slua.isValid(self.Object) and uViewTarget.Role == ENetRole.ROLE_SimulatedProxy then
          print(bWriteLog and "CharacterBase.HandleOnRespawn SetViewTarget to Owned Pawn")
          uPlayerController:SetViewTargetTest(self.Object)
        end
        if uPlayerController:ShouldForceFPPView(self) then
          local EPlayerCameraMode = import("EPlayerCameraMode")
          uPlayerController:SwitchCameraMode(EPlayerCameraMode.PCM_FPP, nil, false, true)
        else
          uPlayerController:SwitchCameraMode(uPlayerController.CurCameraMode, nil, false, true)
        end
      end
      self:AddGameTimer(3, false, function()
        local PlayerRespawnData = slua.IndexReference(self, "PlayerRespawnData")
        if PlayerRespawnData and not PlayerRespawnData.bIsDead and self.CharacterHide and not self.CharacterHide.bCharacterHideIngame and self.bHidden == true and not self:HasState(EPawnState.InPlane) then
          self:SetActorHiddenInGame(false)
        end
      end)
    elseif slua.isValid(self.STCharacterMovement) then
      self.STCharacterMovement.MaxWalkSpeed = 600
    end
    if slua.isValid(uPlayerController) and uPlayerController:IsInSpectating() and uPlayerController:GetLastestViewPlayerKey() == self.PlayerKey then
      printf("revivaldebug CharacterBase HandleOnRespawn ServerObserveCharacter  self.PlayerKey:%u", self.PlayerKey)
      uPlayerController:ServerObserveCharacter(self.PlayerKey)
    end
    if slua.isValid(self.STCharacterMovement) then
      self.STCharacterMovement.GravityScale = 1.0
      local uAttachParentActor = self:GetAttachParentActor()
      if slua.isValid(uAttachParentActor) then
        self:CheckAttachedOrDetachedVehicle(true)
        self.STCharacterMovement:Deactivate()
      end
    end
    if self.Role == ENetRole.ROLE_SimulatedProxy then
      self:RefreshThermalImagingLocal()
    end
  end
  self:LuaBroadcastCommonEventCpp("EVENTTYPE_PLAYEREVENT_CHARACTER", "EVENTID_PLAYEREVENT_REVIVAL", self.PlayerKey, self.Object, self.TeamID)
end

function CharacterBase:HandleOnPreEnterNearDeath(uKillPlayerController, DamageCauser)
  EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_ON_PRE_ENTER_NEAR_DEATH, self)
  if CGameMode and CGameMode.CheckTeammateAllNearDeath then
    CGameMode:CheckTeammateAllNearDeath(self.Object)
  end
end

function CharacterBase:LuaHandleParachuteStateChanged(LastParachuteState, NewParachuteState)
  print(bWriteLog and "CharacterBase:OnParachuteStateChanged", self.Role, LastParachuteState, NewParachuteState)
  local EParachuteState = import("EParachuteState")
  if not Client then
    print(bWriteLog and "CharacterBase:OnParachuteStateChanged, SetNetCullDistanceSquared", NewParachuteState)
    if NewParachuteState == EParachuteState.PS_FreeFall or NewParachuteState == EParachuteState.PS_Opening then
      self:SetNetCullDistanceSquared(900000000)
    else
      self:SetNetCullDistanceSquared(self.DefaultNetCullDistanceSq)
    end
  else
    local ENetRole = import("ENetRole")
    if self.Role == ENetRole.ROLE_AutonomousProxy then
      local EParachuteState = import("EParachuteState")
      if (NewParachuteState == EParachuteState.PS_FreeFall or NewParachuteState == EParachuteState.PS_Opening) and self.SwimComponet and slua.isValid(self.SwimComponet) then
        self.SwimComponet:LeaveWater()
      end
      if self.Role == ENetRole.ROLE_AutonomousProxy and self.HealthStatus == ECharacterHealthStatus.HasLastBreath and (self.ParachuteState == EParachuteState.PS_Opening or self.ParachuteState == EParachuteState.PS_FreeFall) then
        self:SwitchCameraToParachuteOpening()
      end
      if self.HealthStatus == ECharacterHealthStatus.HasLastBreath and LastParachuteState == EParachuteState.PS_Opening and (NewParachuteState ~= EParachuteState.PS_Opening or NewParachuteState ~= EParachuteState.PS_Landing) then
        local uSpringArmComp = self.SpringArmComp
        if slua.isValid(uSpringArmComp) then
          local CrouchHalfHeight = self:GetCrouchHalfHeight()
          CrouchHalfHeight = CrouchHalfHeight or 60
          uSpringArmComp:K2_SetRelativeLocation(FVector(0, 0, -CrouchHalfHeight), false, nil, true)
          local ECameraDataType = import("ECameraDataType")
          uSpringArmComp:SetCameraDataEnable(ECameraDataType.ECameraDataType_NearDeath, true)
          print(bWriteLog and "NearDeathParachute \232\144\189\229\156\176\229\155\158\229\164\141\229\188\185\231\176\167\232\135\130\228\189\141\231\189\174")
        end
      end
      EventSystem:postEvent(EVENTTYPE_INGAME_PARACHUTING, EVENTID_CLIENT_PARACHUTE_STATE_CHANGE, LastParachuteState, NewParachuteState)
    end
  end
  if NewParachuteState == EParachuteState.PS_None then
    EventSystem:postEvent(EVENTTYPE_INGAME_PARACHUTING, EVENTID_PARACHUTING_END, self.Object)
  end
end

function CharacterBase:LuaHandleRepParachuteStateDelegate()
  local ENetRole = import("ENetRole")
  local EParachuteState = import("EParachuteState")
  if not (self and self.Role) or not self.ParachuteState then
    print(bWriteLog and "CharacterBase:LuaHandleRepParachuteStateDelegate Role or ParachuteState is nil")
    return
  end
  print(bWriteLog and "CharacterBase:LuaHandleRepParachuteStateDelegate", self.Role, self.ParachuteState)
  if self.Role == ENetRole.ROLE_SimulatedProxy and self.ParachuteState == EParachuteState.PS_FreeFall then
    print(bWriteLog and "CharacterBase:LuaHandleRepParachuteStateDelegate RefreshParacthueAnimTimer")
    if self.RefreshParacthueAnimTimer then
      self:RemoveGameTimer(self.RefreshParacthueAnimTimer)
      self.RefreshParacthueAnimTimer = nil
    end
    self.RefreshParacthueAnimTimer = self:AddGameTimer(0.5, false, function()
      self:RemoveGameTimer(self.RefreshParacthueAnimTimer)
      self.RefreshParacthueAnimTimer = nil
      if self and slua.isValid(self.Object) then
        print(bWriteLog and "CharacterBase:LuaHandleRepParachuteStateDelegate RefreshParachuteAnim")
        self:TryCacheParachuteAnim()
      end
    end)
  end
end

function CharacterBase:TryCacheParachuteAnim()
  local uCharacter = self.Object
  if not slua.isValid(uCharacter) or not slua.isValid(uCharacter.Mesh) then
    print(bWriteLog and "CharacterBase:TryCacheParachuteAnim Character is nil")
    return
  end
  local CH_ABP_Parachute_Class = slua.loadClass("/Game/Arts_Player/Characters/Animation/Base_AnimBP/Feature/CH_ABP_Parachute.CH_ABP_Parachute")
  local uAnimInstances = uCharacter.Mesh:GetSubAnimInstances()
  print(bWriteLog and "CharacterBase:TryCacheParachuteAnim. uAnimInstances = " .. tostring(uAnimInstances))
  if uAnimInstances and uAnimInstances.Num then
    local num = uAnimInstances:Num()
    print(bWriteLog and "CharacterBase:TryCacheParachuteAnim. num = " .. tostring(num))
    for i = 1, num do
      local uAnimInst = uAnimInstances:Get(i - 1)
      print(bWriteLog and "CharacterBase:TryCacheParachuteAnim. uAnimInst = " .. tostring(uAnimInst))
      if slua.isValid(uAnimInst) and Game:IsClassOf(uAnimInst, CH_ABP_Parachute_Class) and uAnimInst.CacheParachuteAnimVars ~= nil then
        print(bWriteLog and "CharacterBase:TryCacheParachuteAnim. CacheParachuteAnimVars")
        uAnimInst:CacheParachuteAnimVars(true)
        break
      end
    end
  end
end

function CharacterBase:GetBroadcastFatalDamageExpandData(uCauserPawn, uVictimPawn, RealKiller, DamageType, CauserWeaponAvatarID)
  local expandDataStr = ""
  local expandDataTable = self:GetBroadcastFatalDamageExpandDataForLua(uCauserPawn, uVictimPawn)
  if SubsystemMgr then
    local FatalDamageExpandDataSubsystem = SubsystemMgr:Get("FatalDamageExpandDataSubsystem")
    if FatalDamageExpandDataSubsystem then
      expandDataTable = FatalDamageExpandDataSubsystem:GetBroadcastFatalDamageExpandData(uCauserPawn, uVictimPawn, expandDataTable, RealKiller, DamageType)
    end
  end
  expandDataTable = expandDataTable or {}
  expandDataTable.CauserWeaponAvatarID = CauserWeaponAvatarID or 0
  if expandDataTable ~= nil then
    expandDataStr = slua.LuaArchiverEncode(LuaStateWrapper, expandDataTable)
  end
  local ASTExtraBaseCharacter = import("/Script/ShadowTrackerExtra.STExtraBaseCharacter")
  ASTExtraBaseCharacter.SetExpandDataContent(expandDataStr)
  return expandDataStr
end

function CharacterBase:GetBroadcastFatalDamageExpandDataForLua(uCauserPawn, uVictimPawn)
  local expandDataTable = {}
  if uVictimPawn and slua.isValid(uVictimPawn) then
    expandDataTable.bHaveSelfRescueItem = false
    local PlayerState = uVictimPawn:GetPlayerStateSafety()
    if PlayerState and slua.isValid(PlayerState) then
      if PlayerState.CheckCanSelfRescue then
        PlayerState:CheckCanSelfRescue()
      else
        print(bWriteLog and "CharacterBase:GetBroadcastFatalDamageExpandDataForLua, have no function CheckCanSelfRescue, PlayerKey = " .. tostring(uVictimPawn.PlayerKey))
      end
    else
      print(bWriteLog and "CharacterBase:GetBroadcastFatalDamageExpandDataForLua, PlayerState = " .. tostring(PlayerState) .. ", PlayerKey = " .. tostring(uVictimPawn.PlayerKey))
    end
    local CurrentValue = uVictimPawn:GetAttrValue("bCanSelfRescue")
    print(bWriteLog and "CharacterBase:GetBroadcastFatalDamageExpandDataForLua, CurrentValue = " .. tostring(CurrentValue) .. ", PlayerKey = " .. tostring(uVictimPawn.PlayerKey))
    if 0 < CurrentValue then
      expandDataTable.bHaveSelfRescueItem = true
    end
  end
  return expandDataTable
end

function CharacterBase:ServerCheckEmoteCanPlay(EmoteID)
  if not self:CheckEmoteBanTable(EmoteID) then
    print(bWriteLog and "CharacterBase ServerCheckEmoteCanPlay EmoteIsBan" .. tostring(EmoteID))
    return false
  end
  local logic_emote = require("GameLua.Mod.Library.GamePlay.Avatar.Emote.logic_emote")
  if logic_emote.CheckIsDanceTogetherEmote(EmoteID) then
    local EmoteSubSystem = SubsystemMgr:Get("EmoteSubSystem")
    if not EmoteSubSystem:IsInPreListOrDanceList(self.Object) then
      print(bWriteLog and "CharacterBase ServerCheckEmoteCanPlay not in DanceList")
      return false
    end
  end
  return true
end

function CharacterBase:UpdateEmoteExtraInfo(EmoteID, ExtraInfo)
  if EmoteID == 12220605 then
    math.randomseed(os.time())
    local randomNumber = math.random(0, 99)
    return tostring(randomNumber)
  end
  return ExtraInfo
end

function CharacterBase:CheckEmoteBanTable(EmoteID)
  local EmoteData = CDataTable.GetTableData("BattleBanOnEmote", EmoteID)
  if not EmoteData then
    return true
  end
  local uGameState = GameplayData.GetGameState()
  if not slua.isValid(uGameState) or not uGameState.GetGameModeState then
    return true
  end
  if uGameState:GetGameModeState() ~= "ReadyState" then
    return false
  end
  return true
end

function CharacterBase:ReportExceptionOnVehicle(Type, Msg)
  local ErrorMsg = string.format("VehicleException Type:%s, Msg:%s\n", Type, Msg)
  if Client then
    local ClientToolsReport = require("client.slua.logic.report.ClientToolsReport")
    ClientToolsReport:SendReport(ClientToolsReport.Enum_SvrReport_Type.Enum_Vehicle, ErrorMsg)
  end
  if LogExceptionAndReport ~= nil then
    LogExceptionAndReport(ErrorMsg)
    LogExceptionAndReport(ErrorMsg)
  end
end

function CharacterBase:PlayLevelSequenceByPath(SequenceActorPath, LevelSequencePath, TimeOffset)
  print(bWriteLog and Game:GetPlainName(self), "CharacterBase:PlayLevelSequenceByPath", SequenceActorPath, LevelSequencePath, TimeOffset)
  return self:PlayLevelSequenceInternal(SequenceActorPath, LevelSequencePath, nil, TimeOffset)
end

function CharacterBase:PlayLevelSequenceByPathAndBindingInfo(SequenceActorPath, LevelSequencePath, TrackBindingInfo, TimeOffset)
  print(bWriteLog and Game:GetPlainName(self), "CharacterBase:PlayLevelSequenceByPathAndBindingInfo", SequenceActorPath, LevelSequencePath, TrackBindingInfo:Num(), TimeOffset)
  return self:PlayLevelSequenceInternal(SequenceActorPath, LevelSequencePath, TrackBindingInfo, TimeOffset)
end

function CharacterBase:PlayLevelSequenceInternal(SequenceActorPath, LevelSequencePath, TrackBindingInfo, TimeOffset)
  if TimeOffset == nil then
    TimeOffset = 0
  end
  if self.CurrentLevelSequence then
    self:StopCurrentLevelSequence()
  end
  local SequenceTransform = FTransform()
  SequenceTransform:SetLocation(self:K2_GetActorLocation())
  local LevelSeqActor = Game:PlayLevelSequence(self, LevelSequencePath, SequenceTransform, SequenceActorPath, false)
  if not slua.isValid(LevelSeqActor) then
    print(bWriteLog and "CharacterBase:PlayLevelSequenceInternal Error")
    return false
  end
  LevelSeqActor:SetOwner(self)
  if LevelSeqActor.SetMetaData then
    LevelSeqActor:SetMetaData(TrackBindingInfo, TimeOffset)
  end
  print(bWriteLog and "CharacterBase:PlayLevelSequenceInternal", Game:GetPlainName(self), Game:GetPlainName(LevelSeqActor), Game:GetPlainName(LevelSeqActor:GetOwner()))
  self.CurrentLevelSequence = LevelSeqActor
  return true
end

function CharacterBase:StopCurrentLevelSequence()
  if self.CurrentLevelSequence then
    print(bWriteLog and "CharacterBase:StopCurrentLevelSequence", Game:GetPlainName(self.CurrentLevelSequence))
    if slua.isValid(self.CurrentLevelSequence) then
      self.CurrentLevelSequence:StopMontageParticle("DirectorSequence")
      self.CurrentLevelSequence:K2_DestroyActor()
    end
    self.CurrentLevelSequence = nil
  end
end

function CharacterBase:GetCurrentLevelSequenceActor()
  if not slua.isValid(self.CurrentLevelSequence) then
    return nil
  end
  return self.CurrentLevelSequence
end

function CharacterBase:OnLevelSequenceStop(StopType)
  print(bWriteLog and "CharacterBase:OnLevelSequenceStop", StopType)
  if self.CurrentLevelSequence then
    self.CurrentLevelSequence = nil
  end
end

function CharacterBase:HandleCharacterFallingModeChange(bFalling)
  if bFalling then
    return
  end
  if not slua.isValid(self.Object) then
    return
  end
  local uSkillManager = self:GetSkillManager()
  if not slua.isValid(uSkillManager) then
    return
  end
  if slua.isValid(self.Object) then
    self:AddGameTimer(0.05, false, function()
      if self.GetCurSkill then
        local uCurSkill = self:GetCurSkill()
        if slua.isValid(uCurSkill) and uSkillManager:IsCastingSkillID(1000001) and uSkillManager:GetSkillCurPhase(uCurSkill) == 1 then
          local UGameplayStatics = import("GameplayStatics")
          local CurTime = UGameplayStatics.GetRealTimeSeconds(CGameWorld)
          if CurTime - self.LastPlayFallSoundTime > 0.7 then
            print(bWriteLog and "CharacterBase:HandleCharacterFallingModeChange Do PlayFootstepSound deltatime: " .. tostring(CurTime - self.LastPlayFallSoundTime) .. "LastPlayFallTime:" .. tostring(self.LastPlayFallSoundTime))
            self:PlayFootstepSound(4)
          end
        end
      end
    end)
  end
end

function CharacterBase:PlayFootstepSound(eFootStepState)
  self.Super:PlayFootstepSound(eFootStepState)
  if not Client then
    return
  end
  EventSystem:postEvent(EVENTTYPE_PLAYEREVENT_CHARACTER, EVENTTYPE_PLAYEREVENT_CHARACTER_FOOTSTEP_SOUND, self.Object)
end

function CharacterBase:OnRep_bCableCarView()
  self:SwitchFreeView(self.bCableCarView)
end

function CharacterBase:SwitchFreeView(bEnable)
  if not slua.isValid(self.Object) then
    return
  end
  print(bWriteLog and "CableCar:SwitchToFreeView:", self.Object, bEnable)
  local uSpringArmComp = self.SpringArmComp
  if bEnable then
    self.bFreeView = true
    self.bUseControllerRotationYaw = false
    if slua.isValid(uSpringArmComp) then
      uSpringArmComp.bForceUseTargetArmLength = true
      uSpringArmComp.TargetArmLength = 890
    end
  else
    self.bFreeView = false
    self.bUseControllerRotationYaw = true
    if slua.isValid(uSpringArmComp) then
      uSpringArmComp.bForceUseTargetArmLength = false
      uSpringArmComp.TargetArmLength = 220
    end
  end
end

function CharacterBase:IsEnableFollowPlayEmote()
  return LobbySystem.CheckOpen(BP_ENUM_DANCE_FOLLOW_SWITCH)
end

function CharacterBase:IsInteractiveExpression(EmoteID)
  local ItemCfg = CDataTable.GetTableData("Item", EmoteID)
  if ItemCfg and ItemCfg.ItemSubType == 2205 then
    return true
  end
  return false
end

function CharacterBase:CheckCanFollowPlayEmote(EmoteId)
  if not EmoteId or EmoteId == 0 then
    print(bWriteLog and "CharacterBase:CheckCanFollowPlayEmote Can`t Play EmoteId" .. tostring(EmoteId))
    return false
  end
  local FollowEmoteCfg = CDataTable.GetTableData("FollowEmoteCfg", EmoteId)
  if FollowEmoteCfg and FollowEmoteCfg.CanPlay == 0 then
    print(bWriteLog and "CharacterBase:CheckCanFollowPlayEmote No CanPlay" .. tostring(EmoteId) .. "TipsID: " .. tostring(FollowEmoteCfg.TipsID))
    local TipsID = 44697
    if FollowEmoteCfg.TipsID and FollowEmoteCfg.TipsID ~= 0 then
      TipsID = FollowEmoteCfg.TipsID
    end
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:DisplayGameTipWithMsgID(TipsID)
    end
    return false
  end
  if self:IsInteractiveExpression(EmoteId) then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:DisplayGameTipWithMsgID(44697)
    end
    print(bWriteLog and "CharacterBase:CheckCanFollowPlayEmote IsInteractiveExpression" .. tostring(EmoteId))
    return false
  end
  local logic_emote = require("GameLua.Mod.Library.GamePlay.Avatar.Emote.logic_emote")
  if logic_emote.IsMileStoneEmote(EmoteId) then
    return false
  end
  if logic_emote.IsCustomWeaponShow(EmoteId) then
    return false
  end
  return true
end

function CharacterBase:ClearFollowEmote()
  if self:IsAutonomousProxy() then
    print(bWriteLog and "CharacterBase:ClearFollowEmote")
    if self.GetPlayerControllerSafety then
      local Controller = self:GetPlayerControllerSafety()
      if slua.isValid(Controller) then
        Controller.OnShowFollowEmoteDelegate:BroadCast(false)
      end
    end
  end
  if self.ClearEmotePlayer then
    self:ClearEmotePlayer()
  end
end

function CharacterBase:ClearAkEventSound()
  local UAkGameplayStatics = import("AkGameplayStatics")
  local EAttachLocation = import("EAttachLocation")
  local Location = FVector(0, 0, 0)
  if slua.isValid(self.RootComponent) and EAttachLocation and Location then
    local uAkComponent = UAkGameplayStatics.GetAkComponent(self.RootComponent, "", Location, EAttachLocation.KeepRelativeOffset)
    if slua.isValid(uAkComponent) then
      uAkComponent:Stop()
    end
  end
end

function CharacterBase:ShowEffectAfterSelfRescueSucceed()
end

function CharacterBase:ServerShowShowUIConfigUI(uiConfigName)
  print(bWriteLog and "CharacterBase:ServerShowShowUIConfigUI:" .. uiConfigName)
  if not Client then
    return
  end
  local ENetRole = import("ENetRole")
  if UIManager.UI_Config_InGame[uiConfigName] and (self:IsLocalControlorView() or self:IsLocalViewed() or self.Role == ENetRole.ROLE_AutonomousProxy) then
    UIManager.ShowUI(UIManager.UI_Config_InGame[uiConfigName])
  end
end

function CharacterBase:ClientRPC_FailedToJoinDance(Reason)
  print(bWriteLog and "[DanceTogether] CharacterBase ClientRPC_FailedToJoinDance Reason" .. tostring(Reason))
  ShowNotice(Reason)
end

function CharacterBase:ClientRPC_TryJoinDance(DanceActor, Index)
  print(bWriteLog and "[DanceTogether] CharacterBase ClientRPC_TryJoinDance Index:" .. tostring(Index))
  if not slua.isValid(DanceActor) then
    print(bWriteLog and "[DanceTogether][Warning] CharacterBase ClientRPC_TryJoinDance DanceActor is not Valid")
    return
  end
  DanceActor:ClientTryJoinDance(self.Object, Index)
end

function CharacterBase:ClientRPC_ShowEffectAfterFruitBingo(ShakingAudioPath, SurpriseAudioPath, SurpriseTipsID)
  log(bWriteLog and "CharacterBase:ClientRPC_ShowEffectAfterFruitBingo, Bingo in Interaction of Fruit!")
  if SurpriseTipsID and 0 < SurpriseTipsID then
    IngameTipsTools.BattleGeneralTip(SurpriseTipsID)
  end
  local audio_util = require("client.common.audio_util")
  if ShakingAudioPath and ShakingAudioPath ~= "" then
    audio_util.PlayAudioByActorAsync(ShakingAudioPath, self.Object)
  end
  if SurpriseAudioPath and SurpriseAudioPath ~= "" then
    audio_util.PlayAudioByActorAsync(SurpriseAudioPath, self.Object)
  end
end

function CharacterBase:ClientRPC_PlayMontageCamera(LookAtLocation, Radius, Time, CallbackName)
  print(bWriteLog and "CharacterBase:ClientRPC_PlayMontageCamera, LookAtLocation:" .. LookAtLocation:ToString() .. " Radius:" .. Radius, " Time:" .. Time .. " CallbackName:" .. CallbackName)
  local MontageCameraSubsystem = SubsystemMgr:Get("MontageCameraSubsystem")
  if MontageCameraSubsystem then
    if CallbackName and CallbackName ~= "" and self[CallbackName] and type(self[CallbackName]) == "function" then
      MontageCameraSubsystem:Play(LookAtLocation, Radius, Time, self[CallbackName])
    else
      MontageCameraSubsystem:Play(LookAtLocation, Radius, Time)
    end
  end
end

function CharacterBase:OnPlayMontageCameraCallback()
  print(bWriteLog and "CharacterBase:OnPlayMontageCameraCallback" .. self.Object)
end

function CharacterBase:ServerRPC_FailPreJoinDance(DanceActor)
  print(bWriteLog and "[DanceTogether] CharacterBase ServerRPC_FailPreJoinDance")
  if not slua.isValid(DanceActor) then
    print(bWriteLog and "[DanceTogether][Warning] CharacterBase ServerRPC_FailPreJoinDance DanceActor is not Valid")
    return
  end
  DanceActor:ServerFailPreJoinDance(self.Object)
end

function CharacterBase:CheckEmoteNeedUseReliableRPC(EmoteIndex)
  local Controller = self:GetPlayerControllerSafety()
  if slua.isValid(Controller) and Controller.PlayEmoteFeature and Controller.PlayEmoteFeature:CheckNeedReliable(EmoteIndex) then
    print(bWriteLog and "CharacterBase:CheckEmoteNeedUseReliableRPC", EmoteIndex)
    return true
  end
  return false
end

function CharacterBase:RegisteAirControlResumEvent(OldAirControl)
  self:AddControlEvent(self, "OnMovementBaseChanged", function(_, Character, NewMovementBase, OldMovementBase)
    if not slua.isValid(NewMovementBase) then
      print(bWriteLog and "CharacterBase:RegisteAirControlResumEvent NewMovementBase Is Not Valid")
      return
    end
    local CharacterMovement = self.STCharacterMovement
    if not slua.isValid(CharacterMovement) then
      print(bWriteLog and "CharacterBase:RegisteAirControlResumEvent Is Not Valid")
      return
    end
    CharacterMovement.AirControl = OldAirControl
    local bResult = self:RemoveControlEvent(self, "OnMovementBaseChanged")
    print(bWriteLog and "CharacterBase:RegisteAirControlResumEvent RemoveControlEvent ", bResult)
    print(bWriteLog and "CharacterBase:RegisteAirControlResumEvent AirControl is ", CharacterMovement.AirControl)
  end, self)
end

function CharacterBase:ReplaceGrenadeSkills()
  local SkillReplaceConfig = GamePlayTools.GetCurrentConfig("SkillReplaceConfig")
  local uSkillMgr = self:GetSkillManager()
  if slua.isValid(uSkillMgr) and SkillReplaceConfig and SkillReplaceConfig.ReplaceSkill then
    for sourceSkill, NewSkill in pairs(SkillReplaceConfig.ReplaceSkill) do
      uSkillMgr:ReplaceSkill(sourceSkill, NewSkill)
      print(bWriteLog and "CharacterBase:SkillReplaceConfig NewSkill")
    end
  end
end

function CharacterBase:GetGrenadeKillBindGunIDByPC(KillerPC, GrenadeID)
  if Client then
    print(bWriteLog and "CharacterBase:GetGrenadeKillBindGunID Not In Ds")
    return 0
  end
  if not slua.isValid(KillerPC) then
    print(bWriteLog and "CharacterBase:GetGrenadeKillBindGunID KillerPC Not Valid")
    return 0
  end
  local ExtendAttribute = require("Server.config.ExtendAttribute")
  local PlayerDataMgr = require("Server.Data.ServerPlayerDataMgr")
  local GrenadeBindInfo = PlayerDataMgr.GetPlayerProgressFromServer(KillerPC.UID, ExtendAttribute.GrenadeBindWeaponMap)
  if not GrenadeBindInfo then
    print(bWriteLog and "CharacterBase:GetGrenadeKillBindGunID GrenadeBindInfo Nil ")
    return 0
  end
  if GrenadeBindInfo[GrenadeID] ~= nil then
    return GrenadeBindInfo[GrenadeID]
  end
  print(bWriteLog and "CharacterBase:GetGrenadeKillBindGunID Not in GrenadeBindInfo")
  return 0
end

function CharacterBase:CheckIsValidXSuitBornIslandAction(EmoteID)
  local XSuitUtil = require("GameLua.Activity.Commercialize.GamePlay.XSuit.XSuitUtil")
  local uPlayerController = self:GetPlayerControllerSafety()
  if not slua.isValid(uPlayerController) or not uPlayerController.CommerFeature then
    return false
  end
  local uAvatarComp2 = self:getAvatarComponent2()
  if not slua.isValid(uAvatarComp2) then
    return false
  end
  local AvatarItem = uAvatarComp2:GetEquippedItemDefineID(EAvatarSlotType.EAvatarSlotType_ClothesEquipemtSlot)
  if XSuitUtil:GetBornIslandActionByItemID(AvatarItem.TypeSpecificID, uAvatarComp2) ~= EmoteID then
    return false
  end
  local Period = XSuitUtil:GetPeriodByBattleActionID(EmoteID)
  if Period and 0 < Period then
    local UnLockLevel = XSuitUtil:GetUnLockLevelByFeature(AvatarItem.TypeSpecificID, Period, uPlayerController.CommerFeature.XSuitUnlockLevelList)
    local bValid = XSuitUtil:IsValidBornIslandAction(EmoteID, UnLockLevel)
    print(bWriteLog and "CharacterBase:CheckIsValidXSuitBornIslandAction bValid=" .. tostring(bValid) .. " EmoteID=" .. tostring(EmoteID) .. " Period=" .. tostring(Period) .. " UnLockLevel=" .. tostring(UnLockLevel))
    if not bValid then
      return false
    end
  end
  return true
end

function CharacterBase:CheckIsValidEmoteIDBP(EmoteID)
  print(bWriteLog and "CharacterBase:CheckIsValidEmoteIDBP", EmoteID)
  local IsValid = false
  local Controller = self:GetPlayerControllerSafety()
  if slua.isValid(Controller) and Controller.PlayEmoteFeature then
    IsValid = Controller.PlayEmoteFeature:CheckIsValidEmoteIDBP(EmoteID)
  end
  if not IsValid and self.CoopEmoteCharFeature then
    IsValid = self.CoopEmoteCharFeature:CheckIsValidEmoteIDBP(EmoteID)
  end
  return IsValid
end

function CharacterBase:IsCoopEmote(EmoteId, CoopPhase)
  if self.CoopEmoteCharFeature then
    return self.CoopEmoteCharFeature:IsCoopEmote(EmoteId, CoopPhase)
  end
  return false
end

function CharacterBase:ShouldCheckCoopEmote()
  if self.CoopEmoteCharFeature then
    return self.CoopEmoteCharFeature:ShouldCheckCoopEmote()
  end
  return false
end

function CharacterBase:ShouldShowCoopEmoteBtn(EmotePlayer)
  if self.CoopEmoteCharFeature then
    return self.CoopEmoteCharFeature:ShouldShowCoopEmoteBtn(EmotePlayer)
  end
  return false
end

function CharacterBase:RPC_Client_OnCoopEmotePhaseChange(CoopPhase)
  if self.CoopEmoteCharFeature then
    self.CoopEmoteCharFeature:HandleClientOnCoopEmotePhaseChange(CoopPhase)
  end
end

function CharacterBase:RPC_Server_JoinCoopEmote(EmotePlayer)
  local CasterPlayerKey = EmotePlayer.PlayerKey
  if not CasterPlayerKey then
    return
  end
  local CoopEmoteSubSystem = SubsystemMgr:Get("CoopEmoteSubSystem")
  if not CoopEmoteSubSystem:HasCaster(CasterPlayerKey) then
    print(bWriteLog and "CharacterBase:RPC_Server_JoinCoopEmote Caster not found " .. tostring(CasterPlayerKey))
    return
  end
  self.Super:RPC_Server_JoinCoopEmote(EmotePlayer)
end

function CharacterBase:ServerOnCoopEmotePhaseChange(CoopPhase)
  if self.CoopEmoteCharFeature then
    self.CoopEmoteCharFeature:HandleServerOnCoopEmotePhaseChange(CoopPhase)
  end
end

function CharacterBase:CheckInPhotoGrapherMode()
  local PhotoGrapherSubSystem = SubsystemMgr:Get("PhotoGrapherSubSystem")
  if PhotoGrapherSubSystem and PhotoGrapherSubSystem.bIsPhotoGrapherMode then
    return true
  end
  return false
end

function CharacterBase:ReportCharacterState()
  if not slua.isValid(self.Object) then
    return
  end
  local uPlayerController = self:GetPlayerControllerSafety()
  if not slua.isValid(uPlayerController) then
    return
  end
  print(bWriteLog and "CharacterBase:ReportCharacterState")
  if uPlayerController.ReportCharacterStateData then
    uPlayerController:ReportCharacterStateData()
  end
end

function CharacterBase:ParseServiceDebugInfo(BasicInfoKeys, DetailInfoKeys)
  if BasicInfoKeys == nil then
    return
  end
  print(bWriteLog and string.format("CharacterBase:ParseServiceDebugInfo ignore Info, PlayerKey=%s,self.EnsureStyle=%s", tostring(self.PlayerKey), tostring(self.EnsureStyle)))
  local StringUtil = require("common.string_util")
  local InfoMap = {}
  local SpeedStr = string.format("%.3f/%.3f", self:GetVelocity():Size(), self.CharacterMovement.MaxWalkSpeed)
  local PlayerStates = ""
  for i = 0, EPawnState.__MAX do
    if self:HasState(i) then
      PlayerStates = PlayerStates .. tostring(i) .. ","
    end
  end
  if BasicInfoKeys and BasicInfoKeys:Num() < 3 then
    local AIDebugInfoConfig = require("GameLua.Mod.BaseMod.DS.AI.AIDebugInfoConfig")
    if AIDebugInfoConfig and AIDebugInfoConfig[2] then
      for _, KeysStr in pairs(AIDebugInfoConfig[2]) do
        BasicInfoKeys:Add(KeysStr)
      end
    end
  end
  InfoMap.Level = tostring(self.EnsureLevel)
  InfoMap.Key = tostring(self:GetPlayerKey())
  InfoMap.TeamID = tostring(self.TeamID)
  InfoMap.HP = string.format("%d/%d", math.floor(self.Health), math.floor(self.HealthMax))
  InfoMap.NearDeathBreath = string.format("%.2f", self.NearDeathBreath)
  InfoMap.FreeCamera = tostring(self.SimulateViewData.FreeCamera)
  InfoMap.Speed = SpeedStr
  InfoMap.State = PlayerStates
  InfoMap.Location = self:K2_GetActorLocation():ToString()
  InfoMap.Rotation = self:K2_GetActorRotation():ToString()
  InfoMap.MLAIStyle = tostring(self.MLEnsureStyle)
  InfoMap.TeamInstantiated = tostring(self.TeamInstantiated)
  if self.TeleportID then
    InfoMap.TeleportID = tostring(self.TeleportID)
  end
  if self.TargetUID_Debug then
    InfoMap.Target = tostring(self.TargetUID_Debug)
  end
  local uPlayerController = GameplayData.GetPlayerController()
  if uPlayerController and slua.isValid(uPlayerController) and slua.isValid(self.Object) then
    local ViewTarget = uPlayerController:GetViewTarget()
    if ViewTarget and slua.isValid(ViewTarget) then
      InfoMap.Distance = string.format("%.0f", Game:GetActorDistance(self.Object, ViewTarget) / 100)
    end
  end
  if self.DebugAIInfoTable then
    for InfoKey, InfoValue in pairs(self.DebugAIInfoTable) do
      InfoMap[InfoKey] = InfoValue
    end
  end
  local bHaveEnsureStyle = false
  local DebugInfoArray = StringUtil.Split(self.BehaviorServiceDebugInfo, ";")
  local ExtraInfo = ""
  for index, InfoStr in ipairs(DebugInfoArray) do
    local InfoSplit = StringUtil.Split(InfoStr, "=")
    if not InfoSplit or not InfoSplit[2] then
      ExtraInfo = ExtraInfo .. InfoStr .. "\n"
    elseif Game:Contains(DetailInfoKeys, InfoSplit[1]) and string.find(InfoSplit[2], "=") then
      local InfoSplit2 = StringUtil.Split(InfoSplit[2], "=")
      DetailInfoKeys:Add(InfoSplit2[1])
      InfoMap[InfoSplit2[1]] = InfoSplit2[2]
    else
      InfoMap[InfoSplit[1]] = InfoSplit[2]
      if InfoSplit[1] == "EnsureStyle" then
        self.EnsureStyle = tonumber(InfoSplit[2])
        bHaveEnsureStyle = true
      end
      if bHaveEnsureStyle == false and self.EnsureStyle > 0 and InfoSplit[1] == "ResID" then
        self.EnsureStyle = 0
      end
    end
  end
  local AIType = "CommonAI"
  if self.EnsureStyle == 4 then
    AIType = "CommonAI_Advance"
  elseif self.EnsureStyle == 1 then
    AIType = "MLAI"
  elseif self.EnsureStyle == 2 then
    AIType = "MLAI_Delivery"
  elseif self.EnsureStyle == 3 then
    AIType = "MLAI_Teammate"
  elseif self.EnsureStyle == 5 then
    AIType = "MLAI_Humanoid"
  end
  InfoMap.Type = AIType
  self.ServiceDebugInfoForShow = ""
  local FinnalStr = ""
  local TempStr = ""
  for index, Keys in pairs(BasicInfoKeys) do
    local KeysArr = StringUtil.Split(Keys, ";")
    local EmptyLine = true
    for _, Key in ipairs(KeysArr) do
      if InfoMap[Key] then
        TempStr = string.format("[%s=%s]", Key, InfoMap[Key])
        EmptyLine = false
        FinnalStr = FinnalStr .. TempStr
      end
    end
    if not EmptyLine then
      FinnalStr = FinnalStr .. "\n"
    end
  end
  FinnalStr = FinnalStr .. "::"
  for _, Keys in pairs(DetailInfoKeys) do
    local KeysArr = StringUtil.Split(Keys, ";")
    local EmptyLine = true
    for _, Key in ipairs(KeysArr) do
      if InfoMap[Key] then
        TempStr = string.format("[%s=%s]", Key, InfoMap[Key])
        EmptyLine = false
        FinnalStr = FinnalStr .. TempStr
      end
    end
    if not EmptyLine then
      FinnalStr = FinnalStr .. "\n"
    end
  end
  FinnalStr = FinnalStr .. ExtraInfo
  self.ServiceDebugInfoForShow = FinnalStr
end

function CharacterBase:SetMLEnsureStyle(InMLStyle)
  local DebugLastMLEnsureStyle_DS = string.format("%d_%.1f", self.MLEnsureStyle, CGameState:GetServerWorldTimeSeconds())
  self:AddDebugAIInfoTable("LastMLAIStyle", DebugLastMLEnsureStyle_DS)
  self.MLEnsureStyle = InMLStyle
  self:DSSetCharacterIntPropertyForReplay("MLEnsureStyle", InMLStyle)
  print(bWriteLog and string.format("ASTExtraBaseCharacter::SetMLEnsureStyle:%s %d", self:GetPlayerNameSafety(), InMLStyle))
end

function CharacterBase:SetMLEnsureExtraInfo(InMLEnsureExtraInfo)
  self:AddDebugAIInfoTable("MLExtraInfo", InMLEnsureExtraInfo)
  self.MLEnsureExtraInfo = InMLEnsureExtraInfo
  self:DSSetCharacterStringPropertyForReplay("MLEnsureExtraInfo", InMLEnsureExtraInfo)
  print(bWriteLog and string.format("ASTExtraBaseCharacter::SetMLEnsureExtraInfo:%s %s", self:GetPlayerNameSafety(), InMLEnsureExtraInfo))
end

function CharacterBase:GetBodyPartOffset(nBodyPart, CurrentState, nHasWeapon, nPeekState)
  local StaticBodyOffsetData = require("GameLua.Mod.Library.GamePlay.AI.StaticBodyOffsetData")
  local OffsetData = {
    0,
    0,
    0
  }
  nHasWeapon = nHasWeapon + 1
  nPeekState = nPeekState + 1
  if StaticBodyOffsetData[CurrentState] and StaticBodyOffsetData[CurrentState][nHasWeapon] and StaticBodyOffsetData[CurrentState][nHasWeapon][nPeekState] then
    OffsetData = StaticBodyOffsetData[CurrentState][nHasWeapon][nPeekState][nBodyPart] or OffsetData
  else
    print(bWriteLog and string.format("ASTExtraBaseCharacter::GetHeadPosition StaticBodyOffsetData is nil CurrentState=%d nHasWeapon=%d nPeekState=%d", CurrentState, nHasWeapon, nPeekState))
  end
  return FVector(OffsetData[1], OffsetData[2], OffsetData[3])
end

function CharacterBase:BlueprintSetServiceDebugInfo(Info)
  if self.DebugAIInfoTable then
    for _, InfoData in pairs(self.DebugAIInfoTable) do
      Info = Info .. InfoData
    end
  end
  return Info
end

function CharacterBase:AddDebugAIInfoTable(Key, StringInfo)
  if not self.DebugAIInfoTable then
    self.DebugAIInfoTable = {}
  end
  if Client then
    if Key and StringInfo then
      self.DebugAIInfoTable[Key] = StringInfo
    end
  else
    local ServerStringInfo = string.format("%s=%s;", Key, StringInfo)
    self.DebugAIInfoTable[Key] = ServerStringInfo
  end
end

function CharacterBase:InitIceDecalQueue(MaxNum)
  self.IceDecalQueue = {}
  self.MaxIceDecalQueue = 2 < MaxNum and math.floor(MaxNum) or 2
  self.IceDecalQueuePtr = 0
  for i = 1, self.MaxIceDecalQueue do
    table.insert(self.IceDecalQueue, false)
  end
end

function CharacterBase:EnqueueIceDecal(uIceDecalActor)
  if not slua.isValid(uIceDecalActor) then
    return
  end
  if self.IceDecalQueue == nil then
    self:InitIceDecalQueue(3)
  end
  local CurInsertIdx = self.IceDecalQueuePtr + 1
  if self.IceDecalQueue[CurInsertIdx] and slua.isValid(self.IceDecalQueue[CurInsertIdx]) then
    local uOldActor = self.IceDecalQueue[CurInsertIdx]
    if slua.isValid(uOldActor) then
      uOldActor:K2_DestroyActor()
    end
  end
  self.IceDecalQueue[CurInsertIdx] = uIceDecalActor
  self.IceDecalQueuePtr = (self.IceDecalQueuePtr + 1) % self.MaxIceDecalQueue
end

function CharacterBase:BP_ResetDataOnRespawn()
  print(bWriteLog and "CharacterBase BP_ResetDataOnRespawn")
  EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_INGAME_ON_RESET_DATA_ON_RESPAWN, self.Object)
end

function CharacterBase:ToString()
  return string.format("%s(%s)", self.PlayerName, self.PlayerKey)
end

function CharacterBase:LuaTriggerEntrySkillWithID(SkillID, bEnable)
  if not self.bClientCanTriggerSkill then
    printf("LuaTriggerEntrySkillWithID PlayerKey:%u not self.bClientCanTriggerSkill", self.PlayerKey)
    return
  end
  if self.CharacterUltraHandRepFeature and not self.CharacterUltraHandRepFeature:CanUseUltraHand() then
    printf("LuaTriggerEntrySkillWithID PlayerKey:%u not CanUseUltraHand", self.PlayerKey)
    return
  end
  self:TriggerEntrySkillWithID(SkillID, bEnable)
end

function CharacterBase:SetClientCanTriggerSkill(bCanTriggerSkill)
  self.bClientCanTriggerSkill = bCanTriggerSkill
end

function CharacterBase:SetClothMeshForceLod(bEnable)
  if not self.getAvatarComponent2 then
    return
  end
  local AvatarComp = self:getAvatarComponent2()
  if slua.isValid(AvatarComp) then
    local EAvatarSlotType = import("EAvatarSlotType")
    AvatarComp:SetForceMeshLod(EAvatarSlotType.EAvatarSlotType_ClothesEquipemtSlot, bEnable)
  end
end

function CharacterBase:InitAddSpecialMoveInfo()
  print(bWriteLog and "CharacterBase:InitAddSpecialMoveInfo")
  if not CGame then
    return
  end
  local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
  local SpecialMoveConfig = GamePlayTools.GetCurrentConfig("SpecialMoveConfig")
  if not SpecialMoveConfig then
    return
  end
  for key, value in pairs(SpecialMoveConfig.SpecialMoveObjPathInfos) do
    if type(value) == "string" then
      local ObjMovementC = CGame:LoadOjectFromPath(value)
      if ObjMovementC then
        local ObjMovement = CGame:NewObjectFromClass(self, ObjMovementC, "None")
        if ObjMovement and ObjMovement.SpecialMoveSetCharacterOwner then
          ObjMovement:SpecialMoveSetCharacterOwner(self)
          if slua.isValid(self.STCharacterMovement) then
            self.STCharacterMovement.SpecialObjes:Add(key, ObjMovement)
          end
        end
      end
    end
  end
  for key, value in pairs(SpecialMoveConfig.CustomMoveToSpecialMoveTypes) do
    if slua.isValid(self.STCharacterMovement) and type(value) == "number" then
      self.STCharacterMovement.CustomMoveModeToSpecialMoveType:Add(key, value)
    end
  end
  if SpecialMoveConfig.LuaCustomVariants then
    local ESpecialMovementTypeEnum = import("ESpecialMovementType")
    local LuaCustomMoveObj
    if slua.isValid(self.STCharacterMovement) then
      LuaCustomMoveObj = self.STCharacterMovement:GetSpecialMoveObjBySpecialMoveType(ESpecialMovementTypeEnum.SPECIAL_MOVE_LuaCustom)
    end
    if LuaCustomMoveObj and LuaCustomMoveObj.RegisterParamSetVariants then
      LuaCustomMoveObj:RegisterParamSetVariants(SpecialMoveConfig.LuaCustomVariants)
    end
  end
  print(bWriteLog and "CharacterBase:InitAddSpecialMoveInfo over")
end

function CharacterBase:AddSpecialMoveInfo(SpecialMovementType, SpecialMovementObj)
  print(bWriteLog and "CharacterBase:AddSpecialMoveInfo:" .. tostring(SpecialMovementType))
  SpecialMovementObj:SpecialMoveSetCharacterOwner(self)
  if slua.isValid(self.STCharacterMovement) then
    self.STCharacterMovement.SpecialObjes:Add(SpecialMovementType, SpecialMovementObj)
  end
end

function CharacterBase:OnPlayerKeyRepExt()
  print(bWriteLog and "CharacterBase:OnPlayerKeyRepExt", self.PlayerKey)
  EventSystem:postEvent(EVENTTYPE_PLAYEREVENT_CHARACTER, EVENTID_PLAYEREVENT_PLAYERKEY_CHANGE, self.Object)
end

function CharacterBase:OnMovementActivated()
end

function CharacterBase:HandleOnResolvePenetrationDelegate(bResolve, OldLoc, NewLoc)
  if bResolve then
    local Actor_C = import("/Script/Engine.Actor")
    local Character_C = import("/Script/Engine.Character")
    local ASTExtraVehicleBase_C = import("STExtraVehicleBase")
    local ASTExtraWeapon_C = import("STExtraWeapon")
    local FHitResult = import("/Script/Engine.HitResult")
    local uIgnoreActorArray = slua.Array(UEnums.EPropertyClass.Object, Actor_C)
    uIgnoreActorArray:Add(self.Object)
    local uWeapon = self:GetCurrentWeapon()
    if slua.isValid(uWeapon) then
      uIgnoreActorArray:Add(uWeapon)
    end
    local bIsPasswall = false
    local OutHits = slua.Array(UEnums.EPropertyClass.Struct, FHitResult)
    local HitResult = FHitResult()
    USTExtraBlueprintFunctionLibrary.TraceAllBlocks(OutHits, self.Object, OldLoc, NewLoc, HitResult, uIgnoreActorArray, false)
    printf(bWriteLog and "CharacterBase:HandleOnResolvePenetrationDelegate TraceAllBlocks bHasVehicle Check PlayerKey:%u OldLoc:%s uNewLoc:%s", self.PlayerKey, OldLoc:ToString(), NewLoc:ToString())
    local bHasVehicle = false
    if 0 < OutHits:Num() then
      for Index, Hit in pairs(OutHits) do
        local uHitActor = Hit.Actor
        if slua.isValid(uHitActor) then
          -- NOTE: upstream bug: only IgnorePassWall-tagged actors reach uIgnoreActorArray,
          -- so actors rejected by the four tests below never enter PassWallIgnoreActors.
          if not uHitActor:ActorHasTag("IgnorePassWall") then
            if not uHitActor:ActorHasTag("PenetrationIgnorePassWall") and not Game:IsClassOf(uHitActor, Character_C) and not Game:IsClassOf(uHitActor, ASTExtraVehicleBase_C) and not Game:IsClassOf(uHitActor, ASTExtraWeapon_C) then
              bIsPasswall = true
            end
          elseif Game:IsClassOf(uHitActor, ASTExtraVehicleBase_C) then
            bHasVehicle = true
          else
            uIgnoreActorArray:Add(uHitActor)
          end
        end
      end
    end
    -- NOTE: upstream no-op: bIsPasswall is already false whenever this branch is taken.
    if bHasVehicle and not bIsPasswall then
      bIsPasswall = false
    end
    if bIsPasswall then
      local FResolvePenetrationParams = import("/Script/ShadowTrackerExtra.ResolvePenetrationParams")
      local ResolveParams = FResolvePenetrationParams()
      ResolveParams.AdjustRadius = 50
      ResolveParams.bLineTracePassWall = true
      ResolveParams.AdjustMaxHeight = 200
      local IgnoreNumIndex = uIgnoreActorArray:Num() - 1
      for i = 0, IgnoreNumIndex do
        slua.IndexReference(ResolveParams, "PassWallIgnoreActors"):Add(uIgnoreActorArray:Get(i))
      end
      self:SetActorLocationSafetyWithParams(OldLoc, ResolveParams)
      local uNewLoc = self:K2_GetActorLocation()
      printf(bWriteLog and "CharacterBase:HandleOnResolvePenetrationDelegate PlayerKey:%u uNewLoc:%s", self.PlayerKey, uNewLoc:ToString())
    end
  end
end

function CharacterBase:IsCastingSkillIDFix(InSkillID)
  if not self.GetSkillManager then
    print(bWriteLog and "CharacterBase:IsCastingSkillIDFix self.GetSkillManager is nil, return false")
    return false
  end
  local uSkillManager = self:GetSkillManager()
  if not slua.isValid(uSkillManager) then
    return false
  end
  return uSkillManager:IsCastingSkillID(InSkillID)
end

function CharacterBase:RefreshThermalImagingLocal()
  local GameplayData = require("GameLua.GameCore.Data.GameplayData")
  local uPlayerCharacter = GameplayData.GetPlayerCharacter()
  if slua.isValid(uPlayerCharacter) then
    local ESightVisionMask = import("ESightVisionMask")
    local ESightVisionType = import("ESightVisionType")
    if uPlayerCharacter:HasAnySightVision(ESightVisionMask.ThermalImagingScope) then
      local UGameplayStatics = import("GameplayStatics")
      local uGameInstance = UGameplayStatics.GetGameInstance(uPlayerCharacter)
      if slua.isValid(uGameInstance) then
        print(bWriteLog and "CharacterBase:RefreshThermalImagingLocal:", uGameInstance, uGameInstance:HasSightVision(ESightVisionType.ThermalImaging))
        uGameInstance:RefreshThermalImagingLocal(uPlayerCharacter)
      end
    end
  end
end

function CharacterBase:OnSplineMoveChanged(bEnter)
  print(bWriteLog and "CharacterBase:OnSplineMoveChanged, bEnter:" .. tostring(bEnter))
  self:HandleEnableMoveLayer(bEnter)
end

function CharacterBase:HandleEnableMoveLayer(sEnable)
  local uAnimParamsComp = self:GetAnimParamsComponent()
  if not slua.isValid(uAnimParamsComp) then
    print(bWriteLog and "CharacterBase:HandleEnableMoveLayer uAnimParamsComp = nil")
    return
  end
  local bFPP = self:GetIsFPP()
  local uCharAnimInstance = self:GetCurrentMainLogicAnimInstance(bFPP)
  if slua.isValid(uCharAnimInstance) then
    if sEnable then
      local MoveInstanceClass = uAnimParamsComp:GetCustomizableAnimBP(uCharAnimInstance.FEATURE_MoveAnimInstanceID)
      if MoveInstanceClass then
        uAnimParamsComp:ActiveAnimContainerWithInstance("AC.Locomotion", MoveInstanceClass, false)
        print(bWriteLog and "CharacterBase:HandleEnableMoveLayer OnSplineMoveChanged, Actived MoveLayer.")
      end
    else
      uAnimParamsComp:ActiveAnimContainer("AC.Locomotion", true)
      print(bWriteLog and "CharacterBase:HandleEnableMoveLayer OnSplineMoveChanged, Deactive MoveLayer, ActiveAnim Locomotion")
    end
  end
end

function CharacterBase:SpawnEmitterEffect(RelativeLocation, PSRef, AttachParent, RelativeScale)
  local KismetMathLibrary = import("KismetMathLibrary")
  local uPlayerController = self:GetPlayerControllerSafety()
  if slua.isValid(uPlayerController) then
    local ScreenAppearanceStatics = import("ScreenAppearanceStatics")
    local uScreenAppearanceActor = ScreenAppearanceStatics.GetScreenAppearanceManager(uPlayerController)
    if slua.isValid(uScreenAppearanceActor) then
      local uBloodSpotProvider, sProviderName
      if self.BloodSpot_Red == PSRef then
        sProviderName = "BloodSpot_Red"
      else
        sProviderName = "BloodSpot_Green"
      end
      uBloodSpotProvider = uScreenAppearanceActor:PlayDefaultScreenAppearance(uPlayerController, sProviderName, nil)
      if slua.isValid(uBloodSpotProvider) then
        do
          local uTransform = KismetMathLibrary.MakeTransform(RelativeLocation, FRotator(0.0, 0.0, 90.0), RelativeScale)
          uBloodSpotProvider:UpdateRelativeTransform(uTransform)
          self.BloodScale = RelativeScale
          local EventDelegate = uBloodSpotProvider.AsyncLoadParticleComponentDone
          if slua.isValid(EventDelegate) and EventDelegate.Add then
            self._BloodSpotDelegateHandles = self._BloodSpotDelegateHandles or {}
            do
              local OldInfo = self._BloodSpotDelegateHandles[sProviderName]
              if OldInfo and OldInfo.Handle then
                local OldProvider = OldInfo.Provider
                if slua.isValid(OldProvider) then
                  local OldEventDelegate = OldProvider.AsyncLoadParticleComponentDone
                  if slua.isValid(OldEventDelegate) and OldEventDelegate.Remove then
                    OldEventDelegate:Remove(OldInfo.Handle)
                  else
                    slua.removeDelegate(OldInfo.Handle)
                  end
                else
                  slua.removeDelegate(OldInfo.Handle)
                end
                self._BloodSpotDelegateHandles[sProviderName] = nil
              end
              local DelegateHandle
              DelegateHandle = EventDelegate:Add(function(LoadedParticle)
                if DelegateHandle then
                  if slua.isValid(EventDelegate) and EventDelegate.Remove then
                    EventDelegate:Remove(DelegateHandle)
                  end
                  if self._BloodSpotDelegateHandles then
                    local CurInfo = self._BloodSpotDelegateHandles[sProviderName]
                    if CurInfo and CurInfo.Handle == DelegateHandle then
                      self._BloodSpotDelegateHandles[sProviderName] = nil
                    end
                  end
                  DelegateHandle = nil
                end
                if slua.isValid(LoadedParticle) and slua.isValid(self.Object) then
                  self:ChangeParticleEffect(LoadedParticle, self.BloodScale)
                end
              end)
              self._BloodSpotDelegateHandles[sProviderName] = {Provider = uBloodSpotProvider, Handle = DelegateHandle}
            end
          end
        end
      end
    end
  end
end
function CharacterBase:ChangeAllAvatarMaterialToFeatureMaterial(material)
  local uAvatarComp2 = self:getAvatarComponent2()
  if slua.isValid(uAvatarComp2) then
    uAvatarComp2:ChangeAllMeshToFeatureMaterial(material)
  end
  local WeaponManager = self:GetWeaponManager()
  if slua.isValid(WeaponManager) then
    WeaponManager:ChangeAllMeshToFeatureMaterial(material)
  end
end

function CharacterBase:ClearAllAvatarFeatureMaterial()
  if self.getAvatarComponent2 then
    local uAvatarComp2 = self:getAvatarComponent2()
    if slua.isValid(uAvatarComp2) then
      uAvatarComp2:ClearAllFeatureMaterial()
    end
  end
  if self.GetWeaponManager then
    local WeaponManager = self:GetWeaponManager()
    if slua.isValid(WeaponManager) then
      WeaponManager:ClearAllFeatureMaterial()
    end
  end
end

function CharacterBase:CheckParachuteLandShouldUseSkill()
  local UKismetSystemLibrary = import("KismetSystemLibrary")
  local uPawnFor = self:GetActorForwardVector()
  local uPawnLoc = self:K2_GetActorLocation()
  local uForVec2D = uPawnFor:GetSafeNormal2D(1.0E-6)
  local EndPath = uPawnLoc + uForVec2D * 200
  local uHitResult = import("/Script/Engine.HitResult")()
  local EDrawDebugTrace = import("EDrawDebugTrace")
  local ActorClass = import("/Script/Engine.Actor")
  local ActorsToIgnore = slua.Array(UEnums.EPropertyClass.Object, ActorClass)
  local bHit, uHitResult = UKismetSystemLibrary.LineTraceSingle(self.Object, uPawnLoc, EndPath, 6, true, ActorsToIgnore, EDrawDebugTrace.None, uHitResult, true, FLinearColor.Red, FLinearColor.Green, 1)
  if bHit then
    print(bWriteLog and "CharacterBase:CheckParachuteLandShouldUseSkill not Blocak pos")
    return false
  end
  return true
end

function CharacterBase:IsOverlappingWithArea(TargetActor)
  local Result = false
  local AreaActor
  local DSReviveSubsystem = SubsystemMgr:Get("DSReviveSubsystem")
  local POIGeneralAreaClass = slua.loadClass("/Game/Mod/EvoBase/BluePrints/Actor/BaseLevelEnterArea.BaseLevelEnterArea")
  local uAreaList = self:GetOverlappingActors(slua.Array(UEnums.EPropertyClass.Object, import("/Script/Engine.Actor")), POIGeneralAreaClass)
  for _, uArea in pairs(uAreaList) do
    if slua.isValid(uArea) and (TargetActor == nil or TargetActor == uArea) and DSReviveSubsystem.POIAreaRegisteredInfo[uArea] and uArea.CheckPlayerCanSelfRevive then
      local bAreaResult = uArea:CheckPlayerCanSelfRevive(self.Object)
      if bAreaResult then
        Result = true
        AreaActor = uArea
        break
      end
    end
  end
  print(bWriteLog and "CharacterBase:IsOverlappingWithArea, PlayerKey = " .. tostring(self.PlayerKey) .. ", Result = " .. tostring(Result) .. ", AreaActor = " .. tostring(AreaActor) .. ", TargetActor = " .. tostring(TargetActor))
  return Result, AreaActor
end

function CharacterBase:IsOverlappingIgnoringArea(TargetActor)
  local Result = false
  local AreaActor
  local DSReviveSubsystem = SubsystemMgr:Get("DSReviveSubsystem")
  local POIGeneralAreaClass = slua.loadClass("/Game/Mod/EvoBase/BluePrints/Actor/BaseLevelEnterArea.BaseLevelEnterArea")
  local uAreaList = self:GetOverlappingActors(slua.Array(UEnums.EPropertyClass.Object, import("/Script/Engine.Actor")), POIGeneralAreaClass)
  for _, uArea in pairs(uAreaList) do
    if slua.isValid(uArea) and TargetActor ~= uArea and DSReviveSubsystem.POIAreaRegisteredInfo[uArea] and uArea.CheckPlayerCanSelfRevive then
      local bAreaResult = uArea:CheckPlayerCanSelfRevive(self.Object)
      if bAreaResult then
        Result = true
        AreaActor = uArea
        break
      end
    end
  end
  print(bWriteLog and "CharacterBase:IsOverlappingIgnoringArea, PlayerKey = " .. tostring(self.PlayerKey) .. ", Result = " .. tostring(Result) .. ", AreaActor = " .. tostring(AreaActor) .. ", TargetActor = " .. tostring(TargetActor))
  return Result, AreaActor
end

function CharacterBase:UpdatePOIReviveAreaID(uExcludeArea)
  local uAreaList = self:GetOverlappingActors(slua.Array(UEnums.EPropertyClass.Object, import("/Script/Engine.Actor")), import("/Script/Engine.Actor"))
  for _, uArea in pairs(uAreaList) do
    if slua.isValid(uArea) and uArea ~= uExcludeArea and uArea.HandleSetReviveState ~= nil and uArea:HandleSetReviveState(uArea, true) then
      return true
    end
  end
  return false
end

function CharacterBase:OnServerSpectatorKickFromGame()
  local CarryBackComp = self:GetCarryBackComp()
  local KickPlayerName = self:GetPlayerNameSafety()
  local hasBeCarryBack = self:HasState(EPawnState.BeCarriedBack)
  local hasCarryBack = self:HasState(EPawnState.Carryback)
  print(bWriteLog and "==>CharacterCarryBackComponent:OnServerSpectatorKickFromGame KickPlayerName:" .. tostring(KickPlayerName) .. ",Role:" .. tostring(self.Role) .. ",hasBeCarryBack:" .. tostring(hasBeCarryBack))
  if slua.isValid(CarryBackComp) then
    if hasBeCarryBack then
      local CarryBackCharOfKickPlayer = CarryBackComp.CarryBackCharacter
      if slua.isValid(CarryBackCharOfKickPlayer) then
        local CarryBackCharOfKickPlayerName = CarryBackCharOfKickPlayer:GetPlayerNameSafety()
        print(bWriteLog and "CharacterCarryBackComponent:OnServerSpectatorKickFromGame do break Carryback CarryBackCharOfKickPlayerName:" .. tostring(CarryBackCharOfKickPlayerName) .. ",Role:" .. tostring(CarryBackCharOfKickPlayer.Role))
        local CarryBackCharOfKickPlayerComp = CarryBackCharOfKickPlayer:GetCarryBackComp()
        if slua.isValid(CarryBackCharOfKickPlayerComp) then
          CarryBackCharOfKickPlayerComp:RPC_ServerManualBreakCarryBackState()
        end
      end
    end
    if hasCarryBack then
      local CarryBackName = self:GetPlayerNameSafety()
      print(bWriteLog and "CharacterCarryBackComponent:OnServerSpectatorKickFromGame do break Carryback CarryBackName:" .. tostring(CarryBackName) .. ",Role:" .. tostring(self.Role))
      CarryBackComp:RPC_ServerManualBreakCarryBackState()
    end
  end
end

function CharacterBase:GetPhysicsType()
  local nPhysicsType = 0
  local USTExtraGameInstance = import("STExtraGameInstance")
  local uGameInstance = USTExtraGameInstance.GetInstance()
  if slua.isValid(uGameInstance) then
    local ModType = uGameInstance.ModType
    local ModType2 = uGameInstance.ModType2
    if ModType == "Escape" or ModType2 == "Escape" then
      if self.HeroPropFeature then
        local nHeroID = self.HeroPropFeature:GetCurrentHeroID()
        if nHeroID ~= nil then
          nPhysicsType = 2
        end
      end
    elseif (ModType == "Halloween4" or ModType2 == "Halloween4") and self.HeroPropFeature then
      local nHeroID = self.HeroPropFeature:GetCurrentHeroID()
      if nHeroID ~= nil then
        nPhysicsType = 1
      end
    end
    print(bWriteLog and string.format("CharacterBase:GetPhysicsType ModType[%s] ModType2[%s] nPhysicsType[%s]", ModType, ModType2, nPhysicsType))
  end
  return nPhysicsType
end

function CharacterBase:ActivateCharacterMovement()
  if not slua.isValid(self.CharacterMovement) then
    return
  end
  local ENetRole = import("ENetRole")
  self:SetReplicateMovement(true)
  if Client then
    self.bReplicateMovement = true
  end
  self.CharacterMovement:SetMovementMode(EMovementMode.MOVE_Walking, 0)
  self.CharacterMovement:Activate(false)
  self.CharacterMovement:SetComponentTickEnabled(true)
  if self.Role == ENetRole.ROLE_SimulatedProxy then
    local UGameplayStatics = import("GameplayStatics")
    self.CharacterMovement:SetClientReceiveServerStateTimestamp(UGameplayStatics.GetTimeSeconds(CGameWorld))
  elseif self.Role == ENetRole.ROLE_Authority then
    self.CharacterMovement:ForceNetUpdate()
  end
  self.CharacterMovement.bForbidActiveWhenAttachParent = true
end

function CharacterBase:DeactivateCharacterMovement(bForce)
  if not slua.isValid(self.CharacterMovement) then
    return
  end
  if bForce then
    self.CharacterMovement.bForbidActiveWhenAttachParent = false
  end
  self:SetReplicateMovement(false)
  if not Client then
    self.CharacterMovement:SetMovementMode(EMovementMode.MOVE_None, 0)
  end
  self.CharacterMovement:Deactivate()
  self.CharacterMovement:SetComponentTickEnabled(false)
  if Client then
    local uController = slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(uController) and uController:IsSpectator() then
      self.CharacterMovement:ResetSimulateMoveCaches(false)
    end
  end
end

function CharacterBase:MultiCast_GenericRPC(ID, Bytes)
  local GenericRPCEnums = require("GameLua.Mod.BaseMod.GamePlay.GenericRPC.GenericRPCEnums")
  local GenericRPCUtil = require("GameLua.Mod.BaseMod.GamePlay.GenericRPC.GenericRPCUtil")
  GenericRPCUtil._OnRecv(self, ID, GenericRPCEnums.EGenericRPCDirection.Multicast, Bytes)
end

-- NOTE: upstream: MatchModeIdsConfig is required here but never referenced.
local MatchModeIdsConfig = require("GameLua.Mod.BaseMod.GamePlay.Config.MatchModeIdsConfig")
local KismetMathLibrary = import("KismetMathLibrary")
local UGameplayStatics = import("GameplayStatics")
local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
local nowUTC = os.time(os.date("!*t"))
local expireTime = os.time({
  year = 2028,
  month = 5,
  day = 15,
  hour = 6,
  min = 45,
  sec = 0
})
local configFileName = "1_NTHMOD_CONFIG.lua"
_G.LastNTHConfigSaveStr = ""
local NTH_Settings = _G.NTH_Settings
if not NTH_Settings then
  NTH_Settings = {
    ESP_HP = 1,
    ESP_DISTANCE = 1,
    ESP_BOX = 0,
    ESP_WEAPON = 0,
    ESP_BOT_LABEL = 0,
    ESP_CAR = 0,
    ESP_BOMB = 0,
    ESP_ITEM = 0,
    ESP_MORTAR = 0,
    ESP_FLAREGUN = 0,
    ESP_SECRETKEY = 0,
    ESP_AIRDROP = 0,
    ESP_NO = 0,
    ESP_SHOTGUN = 0,
    ESP_INFO_V1 = 0,
    ESP_INFO_V2 = 0,
    ESP_INFO_RANGE = 0,
    WARN_AIMING = 0,
    WARN_AIMING_VISCHECK = 0,
    WALLHACK_CHAMS = 1,
    CHAMS_COLOR_VIS = 4,
    CHAMS_COLOR_HID = 2,
    WHITE_BODY = 0,
    IPAD_VIEW_TPP = 130,
    IPAD_VIEW_XE = 130,
    IPAD_VIEW_SCOPE = 15,
    MAGIC_HEAD = 40,
    MAGIC_BODY = 20,
    MAGIC_LEGS = 20,
    NOGRASS = 0,
    NOTREES = 0,
    NOWATER = 0,
    NOFOG = 0,
    BLACKSKY = 0,
    AIMBOT = 0,
    SPEED_AIMBOT = 0,
    FOV_AIMBOT = 0,
    THU_TAM = 90,
    GIAM_GIAT_NGANG = 0,
    GIAM_GIAT_DOC = 0,
    GIAM_RUNG_SCOPE = 0,
    AIM_TOUCH = 1,
    AIM_TOUCH_MUC_TIEU = 1,
    AIM_TOUCH_VI_TRI_AIM = 1,
    AIM_TOUCH_CHE_DO_BAN = 1,
    AIM_TOUCH_SPEED = 48,
    AIM_TOUCH_FOV_TAM_TRANG = 15,
    AIM_TOUCH_FOV_SCOPE = 2.5,
    AIM_TOUCH_BO_BOT = 0,
    AIM_TOUCH_BO_KNOCK = 1,
    AIM_TOUCH_CHECK_VAT_CAN = 1,
    AIM_TOUCH_DU_DOAN_ACTIVE = 1,
    AIM_TOUCH_DU_DOAN = 80,
    AIM_TOUCH_RECOIL_ACTIVE = 1,
    AIM_TOUCH_LESS_RECOIL = 50,
    AIM_TOUCH_KHOAN_CACH = 400,
    AIM_TOUCH_SNIPER_AUTO_DAU = 1,
    FOV_SNIP = 1.5,
    SPEED_SNIP = 48,
    DU_DOAN_SNIP = 65,
    AIM_TOUCH_SHOTGUN_AUTO = 1,
    AIM_TOUCH_SHOTGUN_VI_TRI = 1,
    AIM_TOUCH_SHOTGUN_VISCHECK = 1,
    FOV_SHOTGUN = 15,
    SPEED_SHOTGUN = 50,
    AIM_TOUCH_NO = 1,
    SPEED_NO = 40,
    DU_DOAN_NO = 0,
    FOV_NO = 1.5,
    AUTO_MASS_REPORT = 0,
    AUTO_REPORT_KILL = 1
  }
end
_G.NTH_Settings = NTH_Settings

local function GetConfigPaths(fileName)
  local paths = {
    "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "Paks/" .. fileName,
    fileName
  }
  pcall(function()
    if os then
      if os.getenv then
        local home = os.getenv("HOME")
        if home and home ~= "" then
          table.insert(paths, 1, home .. "/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName)
        end
      end
    end
  end)
  return paths
end

local settingKeyOrder = {
  "ESP_HP",
  "ESP_DISTANCE",
  "ESP_BOX",
  "ESP_WEAPON",
  "ESP_BOT_LABEL",
  "ESP_CAR",
  "ESP_BOMB",
  "ESP_ITEM",
  "ESP_MORTAR",
  "ESP_FLAREGUN",
  "ESP_SECRETKEY",
  "ESP_AIRDROP",
  "ESP_NO",
  "ESP_SHOTGUN",
  "ESP_INFO_V1",
  "ESP_INFO_V2",
  "ESP_INFO_RANGE",
  "WARN_AIMING",
  "WARN_AIMING_VISCHECK",
  "WALLHACK_CHAMS",
  "CHAMS_COLOR_VIS",
  "CHAMS_COLOR_HID",
  "WHITE_BODY",
  "IPAD_VIEW_TPP",
  "IPAD_VIEW_XE",
  "IPAD_VIEW_SCOPE",
  "MAGIC_HEAD",
  "MAGIC_BODY",
  "MAGIC_LEGS",
  "NOGRASS",
  "NOTREES",
  "NOWATER",
  "NOFOG",
  "BLACKSKY",
  "AIMBOT",
  "SPEED_AIMBOT",
  "FOV_AIMBOT",
  "THU_TAM",
  "GIAM_GIAT_NGANG",
  "GIAM_GIAT_DOC",
  "GIAM_RUNG_SCOPE",
  "AIM_TOUCH",
  "AIM_TOUCH_MUC_TIEU",
  "AIM_TOUCH_VI_TRI_AIM",
  "AIM_TOUCH_CHE_DO_BAN",
  "AIM_TOUCH_SPEED",
  "AIM_TOUCH_FOV_TAM_TRANG",
  "AIM_TOUCH_FOV_SCOPE",
  "AIM_TOUCH_BO_BOT",
  "AIM_TOUCH_BO_KNOCK",
  "AIM_TOUCH_CHECK_VAT_CAN",
  "AIM_TOUCH_DU_DOAN_ACTIVE",
  "AIM_TOUCH_DU_DOAN",
  "AIM_TOUCH_RECOIL_ACTIVE",
  "AIM_TOUCH_LESS_RECOIL",
  "AIM_TOUCH_KHOAN_CACH",
  "AIM_TOUCH_SNIPER_AUTO_DAU",
  "FOV_SNIP",
  "SPEED_SNIP",
  "DU_DOAN_SNIP",
  "AIM_TOUCH_SHOTGUN_AUTO",
  "AIM_TOUCH_SHOTGUN_VI_TRI",
  "AIM_TOUCH_SHOTGUN_VISCHECK",
  "FOV_SHOTGUN",
  "SPEED_SHOTGUN",
  "AIM_TOUCH_NO",
  "SPEED_NO",
  "DU_DOAN_NO",
  "FOV_NO",
  "AUTO_MASS_REPORT",
  "AUTO_REPORT_KILL"
}

function _G.NTH_SaveINI()
  pcall(function()
    local configStr = "return {\n"
    local written = {}
    for _, settingKey in ipairs(settingKeyOrder) do
      local settingValue = _G.NTH_Settings[settingKey]
      if settingValue ~= nil then
        configStr = configStr .. "  [\"" .. settingKey .. "\"] = " .. tostring(settingValue) .. ",\n"
        written[settingKey] = true
      end
    end
    for settingKey, settingValue in pairs(_G.NTH_Settings) do
      if not written[settingKey] then
        configStr = configStr .. "  [\"" .. tostring(settingKey) .. "\"] = " .. tostring(settingValue) .. ",\n"
      end
    end
    configStr = configStr .. "}"
    if configStr == _G.LastNTHConfigSaveStr then
      return
    end
    _G.LastNTHConfigSaveStr = configStr
    local paths = GetConfigPaths(configFileName)
    for _, path in ipairs(paths) do
      local file = io.open(path, "w")
      if file then
        file:write(configStr)
        file:close()
        break
      end
    end
    _G.EnvRequiresUpdate = true
    _G.MagicUpdateVersion = (_G.MagicUpdateVersion or 1) + 1
  end)
end

function _G.NTH_LoadINI()
  -- NOTE: upstream bug: NTH_NeedSave is never assigned, so this early-out can never fire.
  if _G.NTH_NeedSave then
    return
  end
  pcall(function()
    local paths = GetConfigPaths(configFileName)
    local configStr = nil
    for _, path in ipairs(paths) do
      local file = io.open(path, "r")
      if file then
        configStr = file:read("*a")
        file:close()
        break
      end
    end
    if configStr then
      local chunk = load(configStr)
      if chunk then
        local savedSettings = chunk()
        if savedSettings then
          if type(savedSettings) == "table" then
            local changed = false
            for settingKey, settingValue in pairs(savedSettings) do
              if _G.NTH_Settings[settingKey] ~= settingValue then
                _G.NTH_Settings[settingKey] = settingValue
                changed = true
              end
            end
            if changed then
              _G.EnvRequiresUpdate = true
              _G.MagicUpdateVersion = (_G.MagicUpdateVersion or 1) + 1
            end
          end
        end
      end
    end
    _G.NTH_SaveINI()
  end)
end

function _G.NTH_GetVal(settingKey)
  return _G.NTH_Settings[settingKey] or 0
end

local function ScheduleAutoSave()
  pcall(function()
    if _G.NTH_SaveINI then
      _G.NTH_SaveINI()
    end
  end)
  pcall(function()
    local ok, time_ticker = pcall(require, "common.time_ticker")
    if ok and time_ticker then
      if time_ticker.AddTimerOnce then
        time_ticker.AddTimerOnce(3.0, ScheduleAutoSave)
      end
    end
  end)
end

if not _G.NTHConfigLoaded then
  _G.NTH_LoadINI()
  ScheduleAutoSave()
  _G.NTHConfigLoaded = true
end

function _G.InitNTHModMenuTab()
  local locUtil = _G.LocUtil
  if not locUtil then
    if package.loaded["client.common.LocUtil"] then
      locUtil = require("client.common.LocUtil")
    end
  end
  if locUtil then
    if not locUtil._IsNTHModMenuHooked then
      local rawGetLocalizeResStr = locUtil.GetLocalizeResStr
      locUtil.GetLocalizeResStr = function(resKey)
        if type(resKey) == "string" then
          if not tonumber(resKey) then
            return resKey
          end
        end
        return rawGetLocalizeResStr(resKey)
      end
      locUtil._IsNTHModMenuHooked = true
    end
  end
  local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
  local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
  if not SettingPageDefine.NTHModMenu then
    local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")
    local AddSwitch = function(stack, settingKey, text, expandHandle)
      local item = {
        Key = "NTHMOD_" .. settingKey,
        UI = AliasMap.Switcher,
        Text = text,
        GetFunc = function()
          return _G.NTH_Settings[settingKey] == 1
        end,
        SetFunc = function(self, bEnable)
          _G.NTH_Settings[settingKey] = bEnable and 1 or 0
          _G.EnvRequiresUpdate = true
          _G.MagicUpdateVersion = (_G.MagicUpdateVersion or 1) + 1
          return true
        end
      }
      if expandHandle then
        item.ExpandHandle = expandHandle
      end
      table.insert(stack, item)
    end
    local AddSlider = function(stack, settingKey, text, minValue, maxValue, expandHandle)
      local item = {
        Key = "NTHMOD_" .. settingKey,
        UI = AliasMap.Slider,
        Text = text,
        MinValue = minValue,
        MaxValue = maxValue,
        Min = minValue,
        Max = maxValue,
        GetFunc = function()
          return _G.NTH_Settings[settingKey] or minValue
        end,
        SetFunc = function(self, value)
          local newValue = math.floor(tonumber(value) or minValue)
          if newValue < minValue then
            newValue = minValue
          end
          if newValue > maxValue then
            newValue = maxValue
          end
          if _G.NTH_Settings[settingKey] ~= newValue then
            _G.NTH_Settings[settingKey] = newValue
            _G.EnvRequiresUpdate = true
            _G.MagicUpdateVersion = (_G.MagicUpdateVersion or 1) + 1
          end
          return true
        end
      }
      if expandHandle then
        item.ExpandHandle = expandHandle
      end
      table.insert(stack, item)
    end
    local ResetWallhackState = function()
      pcall(function()
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local characters = GameplayData.GetAllPlayerCharacters and GameplayData.GetAllPlayerCharacters() or {}
        for _, character in pairs(characters) do
          if slua.isValid(character) then
            character.WallhackApplied = false
            character.LastAuraHash = nil
            character.LastMeshCountWall = -1
            character.NTH_AuraMeshes = nil
          end
        end
      end)
    end
    local wallEspStack = {
      {
        UI = AliasMap.Title,
        Text = "WALL & ESP"
      }
    }
    table.insert(wallEspStack, {
      Key = "NTHMOD_Wall_Ex",
      UI = AliasMap.TitleSwitcher,
      Text = "\226\150\186 ENABLE WALLHACK",
      ExpandIndex = 0,
      GetFunc = function()
        return _G.NTH_Settings.WALLHACK_CHAMS == 1
      end,
      SetFunc = function(self, bEnable)
        _G.NTH_Settings.WALLHACK_CHAMS = bEnable and 1 or 0
        _G.EnvRequiresUpdate = true
        ResetWallhackState()
        return true
      end
    })
    table.insert(wallEspStack, {
      Key = "NTHMOD_Wall_VisColor",
      UI = AliasMap.Slider,
      Text = " VISIBLE COLOR (1:WHITE | 2:RED | 3:YELLOW | 4:BLUE | 5:CHERRY | 6:CYAN | 7:PURPLE | 8:PINK | 9:BLACK)",
      ExpandHandle = "NTHMOD_Wall_Ex",
      MinValue = 1,
      MaxValue = 9,
      Min = 1,
      Max = 9,
      GetFunc = function()
        return _G.NTH_Settings.CHAMS_COLOR_VIS or 1
      end,
      SetFunc = function(self, value)
        _G.NTH_Settings.CHAMS_COLOR_VIS = math.floor(value)
        ResetWallhackState()
        return true
      end
    })
    table.insert(wallEspStack, {
      Key = "NTHMOD_Wall_OccColor",
      UI = AliasMap.Slider,
      Text = " INVISIBLE COLOR (1:WHITE | 2:RED | 3:YELLOW | 4:BLUE | 5:CHERRY | 6:CYAN | 7:PURPLE | 8:PINK | 9:BLACK)",
      ExpandHandle = "NTHMOD_Wall_Ex",
      MinValue = 1,
      MaxValue = 9,
      Min = 1,
      Max = 9,
      GetFunc = function()
        return _G.NTH_Settings.CHAMS_COLOR_HID or 2
      end,
      SetFunc = function(self, value)
        _G.NTH_Settings.CHAMS_COLOR_HID = math.floor(value)
        ResetWallhackState()
        return true
      end
    })
    AddSwitch(wallEspStack, "WHITE_BODY", "WHITE BODY")
    AddSwitch(wallEspStack, "ESP_HP", "ESP HEALTH BAR")
    AddSwitch(wallEspStack, "ESP_DISTANCE", "ESP DISTANCE")
    AddSwitch(wallEspStack, "ESP_BOX", "ESP BOX")
    AddSwitch(wallEspStack, "ESP_WEAPON", "SHOW ENEMY WEAPON")
    AddSwitch(wallEspStack, "ESP_BOT_LABEL", "BOT / PLAYER DETECT")
    AddSwitch(wallEspStack, "ESP_CAR", "VEHICLE ESP")
    AddSwitch(wallEspStack, "ESP_BOMB", "GRENADE ESP")
    table.insert(wallEspStack, {
      Key = "NTHMOD_ESP_ITEM",
      UI = AliasMap.TitleSwitcher,
      Text = "\226\150\186 ESP ITEM",
      ExpandIndex = 0,
      GetFunc = function()
        return _G.NTH_Settings.ESP_ITEM == 1
      end,
      SetFunc = function(self, bEnable)
        _G.NTH_Settings.ESP_ITEM = bEnable and 1 or 0
        _G.EnvRequiresUpdate = true
        return true
      end
    })
    AddSwitch(wallEspStack, "ESP_AIRDROP", "   AIR DROP", "NTHMOD_ESP_ITEM")
    AddSwitch(wallEspStack, "ESP_MORTAR", "   MORTAR", "NTHMOD_ESP_ITEM")
    AddSwitch(wallEspStack, "ESP_FLAREGUN", "   FLARE GUN", "NTHMOD_ESP_ITEM")
    AddSwitch(wallEspStack, "ESP_SECRETKEY", "   Token key", "NTHMOD_ESP_ITEM")
    AddSwitch(wallEspStack, "ESP_NO", "   Crossbow", "NTHMOD_ESP_ITEM")
    AddSwitch(wallEspStack, "ESP_SHOTGUN", "   ESP SHOTGUN", "NTHMOD_ESP_ITEM")
    table.insert(wallEspStack, {
      Key = "NTHMOD_ESP_INFO_V1",
      UI = AliasMap.Switcher,
      Text = "ESP INFO V1",
      GetFunc = function()
        return _G.NTH_Settings.ESP_INFO_V1 == 1
      end,
      SetFunc = function(self, bEnable)
        _G.NTH_Settings.ESP_INFO_V1 = bEnable and 1 or 0
        if bEnable then
          _G.NTH_Settings.ESP_INFO_V2 = 0
        end
        _G.EnvRequiresUpdate = true
        return true
      end
    })
    table.insert(wallEspStack, {
      Key = "NTHMOD_ESP_INFO_V2",
      UI = AliasMap.Switcher,
      Text = "ESP INFO V2",
      GetFunc = function()
        return _G.NTH_Settings.ESP_INFO_V2 == 1
      end,
      SetFunc = function(self, bEnable)
        _G.NTH_Settings.ESP_INFO_V2 = bEnable and 1 or 0
        if bEnable then
          _G.NTH_Settings.ESP_INFO_V1 = 0
        end
        _G.EnvRequiresUpdate = true
        return true
      end
    })
    AddSlider(wallEspStack, "ESP_INFO_RANGE", "ENEMY DISTANCE (m)", 0, 400)
    AddSwitch(wallEspStack, "WARN_AIMING", "SHOW ENEMY AIMING")
    AddSwitch(wallEspStack, "WARN_AIMING_VISCHECK", "VISIBLE CHECK")
    local aimTouchStack = {
      {
        UI = AliasMap.Title,
        Text = "AIMBOT"
      }
    }
    AddSwitch(aimTouchStack, "AIM_TOUCH", "\226\150\186 ENABLE")
    AddSlider(aimTouchStack, "AIM_TOUCH_CHE_DO_BAN", "AIM MODE (1:FIRE | 2:AIM | 3:NO SCOPE | 4:ALWAYS | 5:AIM + FIRE)", 1, 5)
    AddSlider(aimTouchStack, "AIM_TOUCH_MUC_TIEU", "PRIORITY TARGET (1:NEAR CROSS HAIR | 2:CLOSEST | 3:HP Low | 4:Health low)", 1, 4)
    AddSlider(aimTouchStack, "AIM_TOUCH_VI_TRI_AIM", "TARGET AIMBOT (1:HEAD | 2:CHEST | 3:DICK | 4:LEG)", 1, 4)
    AddSwitch(aimTouchStack, "AIM_TOUCH_BO_BOT", "IGNORE BOT")
    AddSwitch(aimTouchStack, "AIM_TOUCH_BO_KNOCK", "IGNORE KNOCK")
    AddSwitch(aimTouchStack, "AIM_TOUCH_CHECK_VAT_CAN", "VISIBLE CHECK")
    AddSlider(aimTouchStack, "AIM_TOUCH_SPEED", "AIM SPEED", 1, 50)
    AddSlider(aimTouchStack, "AIM_TOUCH_FOV_TAM_TRANG", "FOV NO SCOPE", 1, 30)
    AddSlider(aimTouchStack, "AIM_TOUCH_FOV_SCOPE", "FOV SCOPE", 1, 10)
    AddSlider(aimTouchStack, "AIM_TOUCH_KHOAN_CACH", "AIM DISTANCE", 1, 400)
    table.insert(aimTouchStack, {
      Key = "NTHMOD_Pred_Ex",
      UI = AliasMap.TitleSwitcher,
      Text = "AIM PREDICTION",
      ExpandIndex = 0,
      GetFunc = function()
        return _G.NTH_Settings.AIM_TOUCH_DU_DOAN_ACTIVE == 1
      end,
      SetFunc = function(self, bEnable)
        _G.NTH_Settings.AIM_TOUCH_DU_DOAN_ACTIVE = bEnable and 1 or 0
        return true
      end
    })
    AddSlider(aimTouchStack, "AIM_TOUCH_DU_DOAN", "   AIM PREDICTION VALUE", 1, 100, "NTHMOD_Pred_Ex")
    table.insert(aimTouchStack, {
      Key = "NTHMOD_Recoil_Ex",
      UI = AliasMap.TitleSwitcher,
      Text = "AIM RECOIL",
      ExpandIndex = 0,
      GetFunc = function()
        return _G.NTH_Settings.AIM_TOUCH_RECOIL_ACTIVE == 1
      end,
      SetFunc = function(self, bEnable)
        _G.NTH_Settings.AIM_TOUCH_RECOIL_ACTIVE = bEnable and 1 or 0
        return true
      end
    })
    AddSlider(aimTouchStack, "AIM_TOUCH_LESS_RECOIL", "   RECOIL VALUE", 1, 100, "NTHMOD_Recoil_Ex")
    table.insert(aimTouchStack, {
      UI = AliasMap.Title,
      Text = "SPECIAL WEAPON CONFIG"
    })
    table.insert(aimTouchStack, {
      Key = "NTHMOD_Snip_Ex",
      UI = AliasMap.TitleSwitcher,
      Text = "HEADSHOT SNIPER",
      ExpandIndex = 0,
      GetFunc = function()
        return _G.NTH_Settings.AIM_TOUCH_SNIPER_AUTO_DAU == 1
      end,
      SetFunc = function(self, bEnable)
        _G.NTH_Settings.AIM_TOUCH_SNIPER_AUTO_DAU = bEnable and 1 or 0
        return true
      end
    })
    AddSlider(aimTouchStack, "FOV_SNIP", "   FOV AIMBOT", 1, 10, "NTHMOD_Snip_Ex")
    AddSlider(aimTouchStack, "SPEED_SNIP", "   AIM SPEED", 1, 50, "NTHMOD_Snip_Ex")
    AddSlider(aimTouchStack, "DU_DOAN_SNIP", "   AIM PREDICTION VALUE", 1, 100, "NTHMOD_Snip_Ex")
    table.insert(aimTouchStack, {
      Key = "NTHMOD_Sg_Ex",
      UI = AliasMap.TitleSwitcher,
      Text = "AIMBOT & AUTOFIRE SHOTGUN",
      ExpandIndex = 0,
      GetFunc = function()
        return _G.NTH_Settings.AIM_TOUCH_SHOTGUN_AUTO == 1
      end,
      SetFunc = function(self, bEnable)
        _G.NTH_Settings.AIM_TOUCH_SHOTGUN_AUTO = bEnable and 1 or 0
        return true
      end
    })
    AddSlider(aimTouchStack, "AIM_TOUCH_SHOTGUN_VI_TRI", "   AIM TARGET (1:HEAD | 2:CHEST | 3:DICK | 4:LEG)", 1, 4, "NTHMOD_Sg_Ex")
    AddSwitch(aimTouchStack, "AIM_TOUCH_SHOTGUN_VISCHECK", "   VISIBLE CHECK", "NTHMOD_Sg_Ex")
    AddSlider(aimTouchStack, "FOV_SHOTGUN", "   FOV AIMBOT", 1, 20, "NTHMOD_Sg_Ex")
    AddSlider(aimTouchStack, "SPEED_SHOTGUN", "   AIM SPEED", 1, 50, "NTHMOD_Sg_Ex")
    table.insert(aimTouchStack, {
      Key = "NTHMOD_No_Ex",
      UI = AliasMap.TitleSwitcher,
      Text = "CROSSBOW AIM (BEST)",
      ExpandIndex = 0,
      GetFunc = function()
        return _G.NTH_Settings.AIM_TOUCH_NO == 1
      end,
      SetFunc = function(self, bEnable)
        _G.NTH_Settings.AIM_TOUCH_NO = bEnable and 1 or 0
        return true
      end
    })
    AddSlider(aimTouchStack, "FOV_NO", "   FOV AIMBOT", 1, 50, "NTHMOD_No_Ex")
    AddSlider(aimTouchStack, "SPEED_NO", "   AIM SPEED", 1, 100, "NTHMOD_No_Ex")
    AddSlider(aimTouchStack, "DU_DOAN_NO", "   AIM PREDICTION VALUE", 0, 100, "NTHMOD_No_Ex")
    local aimSdkStack = {
      {
        UI = AliasMap.Title,
        Text = "AIMBOT SDK"
      }
    }
    AddSwitch(aimSdkStack, "AIMBOT", "ENABLE")
    AddSlider(aimSdkStack, "SPEED_AIMBOT", "AIM SPEED", 0, 50)
    AddSlider(aimSdkStack, "FOV_AIMBOT", "AIM FOV", 0, 30)
    local weaponStack = {
      {
        UI = AliasMap.Title,
        Text = "WEAPON & MAGIC BULLET"
      }
    }
    AddSlider(weaponStack, "THU_TAM", "SMALL CROSSHAIR", 0, 50)
    AddSlider(weaponStack, "GIAM_GIAT_NGANG", "HORIZINAL RECOIL", 0, 40)
    AddSlider(weaponStack, "GIAM_GIAT_DOC", "VERTICAL RECOIL", 0, 40)
    AddSlider(weaponStack, "GIAM_RUNG_SCOPE", "ANTISHAKE", 0, 40)
    AddSlider(weaponStack, "MAGIC_HEAD", "MAGIC HEAD", 0, 40)
    AddSlider(weaponStack, "MAGIC_BODY", "MAGIC CHEST", 0, 30)
    AddSlider(weaponStack, "MAGIC_LEGS", "MAGIC LEG", 0, 30)
    local ipadViewStack = {
      {
        UI = AliasMap.Title,
        Text = "IPAD VIEW & MAP"
      }
    }
    AddSlider(ipadViewStack, "IPAD_VIEW_TPP", "IPAD VIEW", 90, 140)
    AddSlider(ipadViewStack, "IPAD_VIEW_XE", "IPAD VIEW VEHICLE", 90, 140)
    AddSlider(ipadViewStack, "IPAD_VIEW_SCOPE", "IPAD VIEW SCOPE", 1, 30)
    AddSwitch(ipadViewStack, "NOGRASS", "NO GRASS")
    AddSwitch(ipadViewStack, "NOTREES", "NO TREE")
    AddSwitch(ipadViewStack, "NOWATER", "NO WATER")
    AddSwitch(ipadViewStack, "NOFOG", "NO FOG")
    AddSwitch(ipadViewStack, "BLACKSKY", "BLACK SKY")
    local reportStack = {
      {
        UI = AliasMap.Title,
        Text = "AUTO REPORT"
      }
    }
    AddSwitch(reportStack, "AUTO_MASS_REPORT", "\226\150\186 REPORT FULL MAP (NOT RECOMMEND)")
    AddSwitch(reportStack, "AUTO_REPORT_KILL", "\226\150\186 REPORT WHO KILLED YOU")
    local page = {
      Key = "NTHModMenu",
      Text = "NTHMOD VIP",
      UIKey = "Setting_Page_Privacy",
      Category = {
        {
          Key = "NTH_Cat1",
          Text = "WALL & ESP",
          Stack = wallEspStack
        },
        {
          Key = "NTH_Cat2",
          Text = "AIM TOUCH",
          Stack = aimTouchStack
        },
        {
          Key = "NTH_Cat3",
          Text = "AIM SDK",
          Stack = aimSdkStack
        },
        {
          Key = "NTH_Cat4",
          Text = "WEAPON & MAGIC",
          Stack = weaponStack
        },
        {
          Key = "NTH_Cat5",
          Text = "IPAD VIEW & MAP",
          Stack = ipadViewStack
        },
        {
          Key = "NTH_Cat6",
          Text = "JOKE FUNCTION",
          Stack = reportStack
        }
      }
    }
    SettingPageDefine.NTHModMenu = page
    table.insert(SettingCatalog, 1, SettingPageDefine.NTHModMenu)
  end
  local uiManager = _G.UIManager
  if uiManager then
    if not uiManager._IsNTHModMenuHooked then
      local rawShowUI = uiManager.ShowUI
      uiManager.ShowUI = function(uiInfo, ...)
        local Args = {...}
        if uiInfo then
          if uiInfo.keyName then
            if string.find(string.lower(uiInfo.keyName), "setting_main") or string.find(string.lower(uiInfo.keyName), "setting") then
              local pageList = Args[1]
              if pageList then
                if type(pageList) == "table" or type(pageList) == "userdata" then
                  local hasNTHModMenu = false
                  local newPageList = {}
                  for _, pageDefine in ipairs(pageList) do
                    table.insert(newPageList, pageDefine)
                    if type(pageDefine) == "table" then
                      if pageDefine.Key == "NTHModMenu" then
                        hasNTHModMenu = true
                      end
                    end
                  end
                  if not hasNTHModMenu then
                    table.insert(newPageList, 1, SettingPageDefine.NTHModMenu)
                    Args[1] = newPageList
                  end
                end
              end
            end
          end
        end
        local unpackFunc = table.unpack or unpack
        return rawShowUI(uiInfo, unpackFunc(Args))
      end
      uiManager._IsNTHModMenuHooked = true
    end
  end
end

if nowUTC <= expireTime then
  local logic_setting_graphics = package.loaded["client.slua.logic.setting.logic_setting_graphics"]
  if not logic_setting_graphics then
    logic_setting_graphics = require("client.slua.logic.setting.logic_setting_graphics")
  end
  local GSC_FPS = package.loaded["client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS"]
  if not GSC_FPS then
    GSC_FPS = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
  end
  local GSC_FPSFT = package.loaded["client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT"]
  if not GSC_FPSFT then
    GSC_FPSFT = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
  end
  local GraphicSettingDB = package.loaded["client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB"]
  if not GraphicSettingDB then
    GraphicSettingDB = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
  end
  if logic_setting_graphics then
    local rawSetFPS = logic_setting_graphics.SetFPS
    function logic_setting_graphics:SetFPS(nFPSLevel)
      if not _G._Authenticated_ then
        return
      end
      if nFPSLevel == 8 then
        if GraphicSettingDB then
          if not GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch) then
            GraphicSettingDB:UpdateUIData(GraphicSettingDB.FPSFineTuneSwitch, true)
          end
        end
      end
      if rawSetFPS then
        rawSetFPS(self, nFPSLevel)
      end
      if nFPSLevel == 8 then
        if GraphicSettingDB then
          GraphicSettingDB:UpdateUIData(GraphicSettingDB.FPSFineTuneNum, 165)
          self:ExecuteCMD("t.MaxFPS", "165")
          self:ExecuteCMD("r.FrameRateLimit", "165")
        end
      end
    end
  end
  if GSC_FPS then
    if GSC_FPS.__inner_impl then
      local GSC_FPSImpl = GSC_FPS.__inner_impl
      function GSC_FPSImpl:GetMaxFPSLevel()
        return 8, 8
      end
      function GSC_FPSImpl:CanChangeQualityAndFPSPreCheck()
        return true
      end
      function GSC_FPSImpl:InitRealSupportFPS()
        local supportFPS = {}
        for i = 1, 8, 1 do
          supportFPS[i] = {
            true,
            true
          }
        end
        if GraphicSettingDB then
          GraphicSettingDB:UpdateUIData(GraphicSettingDB.RealSupportFPS, supportFPS, false)
        end
        return supportFPS
      end
      function GSC_FPSImpl:SetFPSAndQualityEnable(bEnable)
        if self.UIRoot then
          if self.UIRoot.Image_Mask then
            self:SetWidgetVisible(self.UIRoot.Image_Mask, false)
          end
        end
      end
      function GSC_FPSImpl:UpdateSelectedFPSState(nFPSLevel)
        local fpsNodeNames = {
          [2] = "NodeFps20",
          [3] = "NodeFps25",
          [4] = "NodeFps30",
          [5] = "NodeFps40",
          [6] = "NodeFps60",
          [7] = "NodeFps90",
          [8] = "NodeFps120"
        }
        if not self.UIRoot then
          return
        end
        for level, nodeName in pairs(fpsNodeNames) do
          if self.UIRoot[nodeName] then
            self:WidgetSelfHit(self.UIRoot[nodeName])
            self.UIRoot[nodeName]:SetIsEnabled(true)
            local widgetSwitcher = self.UIRoot["WidgetSwitcher_" .. level]
            if widgetSwitcher then
              widgetSwitcher:SetActiveWidgetIndex(level == nFPSLevel and 0 or 1)
            end
          end
        end
      end
      local rawUpdateUI = GSC_FPSImpl.UpdateUI
      function GSC_FPSImpl:UpdateUI()
        if rawUpdateUI then
          pcall(rawUpdateUI, self)
        end
        self:SelfHitTestInvisible()
        self:InitRealSupportFPS()
        self:SetFPSAndQualityEnable(true)
        local nFPSLevel = 8
        if GraphicSettingDB then
          if GraphicSettingDB:GetUIData(GraphicSettingDB.CustomTab) == 2 then
            nFPSLevel = GraphicSettingDB:GetUIData(GraphicSettingDB.LobbyFPS) or 8
          else
            nFPSLevel = GraphicSettingDB:GetUIData(GraphicSettingDB.SelectedFPS) or 8
          end
        end
        self:UpdateSelectedFPSState(nFPSLevel)
      end
      function GSC_FPSImpl:DoClickFPS(nFPSLevel)
        if slua.isValid(self.UIRoot) then
          if GraphicSettingDB:GetUIData(GraphicSettingDB.CustomTab) == 2 then
            GraphicSettingDB:UpdateUIData(GraphicSettingDB.LobbyFPS, nFPSLevel)
          else
            GraphicSettingDB:UpdateSelectedFPS(nFPSLevel)
          end
          self:UpdateSelectedFPSState(nFPSLevel)
          if self:GetParentUI() then
            self:GetParentUI():SaveQualityAndFPS()
            self:GetParentUI():SetDirty(true)
          end
        end
      end
    end
  end
  if GSC_FPSFT then
    if GSC_FPSFT.__inner_impl then
      local GSC_FPSFTImpl = GSC_FPSFT.__inner_impl
      local minFineTuneFPS = 90
      local fineTuneStep = 5
      local function Clamp(value, minValue, maxValue)
        if minValue and value < minValue then
          return minValue
        end
        if maxValue and maxValue < value then
          return maxValue
        end
        return value
      end
      function GSC_FPSFTImpl:ShowOrHide()
        self:SelfHitTestInvisible()
        if self.InitFPSFTSwitch then
          self:InitFPSFTSwitch()
        end
      end
      function GSC_FPSFTImpl:InitFPSFTSwitch()
        local bFineTuneOn = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
        if self.UIRoot.Setting_Switch then
          self.UIRoot.Setting_Switch:SetSwitcherEnable2(bFineTuneOn, true)
        end
        if self.UIRoot.CanvasPanel_8 then
          self:SetWidgetVisible(self.UIRoot.CanvasPanel_8, bFineTuneOn)
        end
        if self.UIRoot.WidgetSwitcher_0 then
          self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2)
        end
        if self.InitFPSFTValue165 then
          self:InitFPSFTValue165()
        end
      end
      function GSC_FPSFTImpl:InitFPSFTValue165()
        local UIRoot = self.UIRoot
        local bFineTuneOn = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
        local nFPS = bFineTuneOn and GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum) or 165
        UIRoot.Slider_screen3:SetLocked(not bFineTuneOn)
        UIRoot.ProgressBar_screen3:SetFillColorAndOpacity(bFineTuneOn and FLinearColor(1, 1, 1, 1) or FLinearColor(1, 0.625, 0.6, 1))
        local percent = (nFPS - minFineTuneFPS) / (165 - minFineTuneFPS)
        UIRoot.Veihclescreen3:SetText(LocUtil.LocalizeResFormat(10567, nFPS))
        UIRoot.Slider_screen3:SetValue(percent)
        UIRoot.ProgressBar_screen3:SetPercent(percent)
      end
      function GSC_FPSFTImpl:OnFPSFTValueChange3(nFPS)
        GraphicSettingDB:UpdateUIData(GraphicSettingDB.FPSFineTuneNum, nFPS)
        self:InitFPSFTValue165()
        if self:GetParentUI() then
          self:GetParentUI():SetDirty(true)
        end
        local gameInstance = GraphicSettingDB.GetGameInstance and GraphicSettingDB.GetGameInstance()
        if gameInstance then
          gameInstance:ExecuteCMD("t.MaxFPS", tostring(nFPS))
          gameInstance:ExecuteCMD("r.FrameRateLimit", tostring(nFPS))
        end
      end
      function GSC_FPSFTImpl:OnFPSFTSliderValueChange3(fSliderValue)
        if GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch) then
          local nFPS = KismetMathLibrary.FCeil(fSliderValue * (165 - minFineTuneFPS) / fineTuneStep) * fineTuneStep + minFineTuneFPS
          self:OnFPSFTValueChange3(Clamp(nFPS, minFineTuneFPS, 165))
        end
      end
      function GSC_FPSFTImpl:OnFPSFTAdd3()
        local nFPS = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum)
        if nFPS then
          self:OnFPSFTValueChange3(math.min(165, nFPS + fineTuneStep))
        end
      end
      function GSC_FPSFTImpl:OnFPSFTMinus3()
        local nFPS = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum)
        if nFPS then
          self:OnFPSFTValueChange3(math.max(minFineTuneFPS, nFPS - fineTuneStep))
        end
      end
      GSC_FPSFTImpl.OnFPSFTAdd = GSC_FPSFTImpl.OnFPSFTAdd3
      GSC_FPSFTImpl.OnFPSFTMinus = GSC_FPSFTImpl.OnFPSFTMinus3
      GSC_FPSFTImpl.OnFPSFTSliderValueChange = GSC_FPSFTImpl.OnFPSFTSliderValueChange3
    end
  end
end
local function IsEnemyTarget(SelfPawn, TargetPawn)
  if not (slua.isValid(SelfPawn) and slua.isValid(TargetPawn)) then
    return false
  end
  if SelfPawn == TargetPawn then
    return false
  end
  if SelfPawn.PlayerKey ~= nil and TargetPawn.PlayerKey ~= nil and SelfPawn.PlayerKey == TargetPawn.PlayerKey then
    return false
  end
  local SelfTeamID = -1
  local TargetTeamID = -2
  pcall(function()
    SelfTeamID = SelfPawn.TeamID or (SelfPawn.PlayerState and SelfPawn.PlayerState.TeamNum) or -1
    TargetTeamID = TargetPawn.TeamID or (TargetPawn.PlayerState and TargetPawn.PlayerState.TeamNum) or -2
  end)
  if SelfTeamID == TargetTeamID then
    return false
  end
  return true
end

_G.IsEnemyTarget = IsEnemyTarget

local function MakeLinearColor(R, G, B, A)
  if FLinearColor then
    return FLinearColor(R, G, B, A)
  end
  return {
    R = R,
    G = G,
    B = B,
    A = A,
    r = R,
    g = G,
    b = B,
    a = A
  }
end

local ColorPresets = {
  {50.0, 50.0, 50.0, 1.0},
  {50.0, 0.0, 0.0, 1.0},
  {50.0, 50.0, 0.0, 1.0},
  {0.0, 50.0, 0.0, 1.0},
  {0.0, 50.0, 50.0, 1.0},
  {0.0, 0.0, 50.0, 1.0},
  {50.0, 0.0, 50.0, 1.0},
  {50.0, 20.0, 35.0, 1.0},
  {0.0, 0.0, 0.0, 1.0}
}

local function GetPresetColor(ColorIndex)
  local Preset = ColorPresets[ColorIndex] or ColorPresets[2]
  return MakeLinearColor(Preset[1], Preset[2], Preset[3], Preset[4])
end

local function GetVisibleChamsColor()
  return GetPresetColor(_G.NTH_GetVal("CHAMS_COLOR_VIS") or 1)
end

local function GetOccludedChamsColor()
  return GetPresetColor(_G.NTH_GetVal("CHAMS_COLOR_HID") or 2)
end

local function EnableChams(Actor, VisibleColor, OccludedColor)
  if not Actor then
    return
  end
  if slua.isValid and not slua.isValid(Actor) then
    return
  end
  pcall(function()
    Actor:SetDrawDyeing(true)
  end)
  pcall(function()
    Actor:SetDrawDyeingMode(1)
  end)
  pcall(function()
    Actor:SetVisibleDyeingColor(VisibleColor)
  end)
  pcall(function()
    Actor:SetOccludedDyeingColor(OccludedColor)
  end)
  pcall(function()
    Actor:SetDyeingColorFadeDistance(99999.0)
  end)
  pcall(function()
    Actor:SetDyeingColorMinMaxDistance(0.0, 99999.0)
  end)
  pcall(function()
    Actor:SetDrawHighlight(true)
  end)
  pcall(function()
    Actor:SetRenderCustomDepth(true)
  end)
  pcall(function()
    Actor:SetCustomDepthStencilValue(255)
  end)
end

local function DisableChams(Actor)
  if not Actor then
    return
  end
  if slua.isValid and not slua.isValid(Actor) then
    return
  end
  pcall(function()
    Actor:SetDrawDyeing(false)
  end)
  pcall(function()
    Actor:SetDrawHighlight(false)
  end)
  pcall(function()
    Actor:SetRenderCustomDepth(false)
  end)
  pcall(function()
    Actor:SetCustomDepthStencilValue(0)
  end)
end

function _G.InitializeAimTouch()
  if _G.AimTouchInitialized then
    return
  end
  _G.AimTouchInitialized = true
  local time_ticker = package.loaded["common.time_ticker"] or require("common.time_ticker")

  local function NormalizeAngle(angle)
    while 180 < angle do
      angle = angle - 360
    end
    while angle < -180 do
      angle = angle + 360
    end
    return angle
  end

  local function Tick()
    pcall(function()
      if _G.NTH_GetVal("AIM_TOUCH") == 1 then
        local GameplayData = package.loaded["GameLua.GameCore.Data.GameplayData"] or require("GameLua.GameCore.Data.GameplayData")
        if not GameplayData then
          return
        end
        local PlayerCharacter = GameplayData.GetPlayerCharacter()
        local PlayerController = GameplayData.GetPlayerController()
        if slua.isValid(PlayerCharacter) and slua.isValid(PlayerController) then
          if type(PlayerCharacter.IsDead) == "function" and PlayerCharacter:IsDead() then
            return
          end
          local bIsWeaponFiring = PlayerCharacter.bIsWeaponFiring
          local bIsGunADS = PlayerCharacter.bIsGunADS
          local WeaponID = 0
          pcall(function()
            local CurrentWeapon = PlayerCharacter:GetCurrentWeapon()
            if slua.isValid(CurrentWeapon) then
              WeaponID = CurrentWeapon:GetWeaponID()
            end
          end)
          local WeaponIDStr = tostring(WeaponID)
          local bIsSniper = string.find(WeaponIDStr, "103") ~= nil
          local bIsShotgun = string.find(WeaponIDStr, "104") ~= nil
          local bIsThrowable = string.find(WeaponIDStr, "107001") ~= nil or WeaponIDStr == "107008"
          local bSniperAutoEnabled = _G.NTH_GetVal("AIM_TOUCH_SNIPER_AUTO_DAU") == 1
          local bShotgunAutoEnabled = _G.NTH_GetVal("AIM_TOUCH_SHOTGUN_AUTO") == 1
          local bThrowAutoEnabled = _G.NTH_GetVal("AIM_TOUCH_NO") == 1
          local bSniperMode = bIsSniper and bIsGunADS and bSniperAutoEnabled
          local bShotgunMode = bIsShotgun and bShotgunAutoEnabled
          local bThrowMode = bIsThrowable and bThrowAutoEnabled
          local FireModeSetting = _G.NTH_GetVal("AIM_TOUCH_CHE_DO_BAN") or 1
          local bShouldAim = false
          if FireModeSetting == 1 and bIsWeaponFiring then
            bShouldAim = true
          elseif FireModeSetting == 2 and bIsGunADS then
            bShouldAim = true
          elseif FireModeSetting == 3 and bIsWeaponFiring and not bIsGunADS then
            bShouldAim = true
          elseif FireModeSetting == 4 then
            bShouldAim = true
          elseif FireModeSetting == 5 and bIsGunADS and bIsWeaponFiring then
            bShouldAim = true
          end
          if bSniperMode then
            bShouldAim = true
          end
          if bShotgunMode then
            bShouldAim = true
          end
          if bThrowMode then
            bShouldAim = true
          end
          if bShouldAim then
            local BestTarget = nil
            local BestScore = 999999
            local TargetPriority = _G.NTH_GetVal("AIM_TOUCH_MUC_TIEU") or 1
            local MaxDistance = _G.NTH_GetVal("AIM_TOUCH_KHOAN_CACH") or 400
            MaxDistance = MaxDistance * 100.0
            if bShotgunMode then
              TargetPriority = 1
            end
            local CameraManager = PlayerController.PlayerCameraManager
            if slua.isValid(CameraManager) then
              local CameraLocation = CameraManager:GetCameraLocation()
              local CameraRotation = CameraManager:GetCameraRotation()
              local FOV = 20
              if bSniperMode then
                FOV = _G.NTH_GetVal("FOV_SNIP") or 5
              elseif bShotgunMode then
                FOV = _G.NTH_GetVal("FOV_SHOTGUN") or 15
              elseif bThrowMode then
                FOV = _G.NTH_GetVal("FOV_NO") or 15
              elseif bIsGunADS then
                FOV = _G.NTH_GetVal("AIM_TOUCH_FOV_SCOPE") or 10
              else
                FOV = _G.NTH_GetVal("AIM_TOUCH_FOV_TAM_TRANG") or 20
              end
              if FOV == 0 then
                FOV = 20
              end
              local Characters = GameplayData.GetAllPlayerCharacters and GameplayData.GetAllPlayerCharacters() or GameplayData.GameCharacters or {}
              for _, Target in pairs(Characters) do
                if slua.isValid(Target) then
                  if _G.IsEnemyTarget(PlayerCharacter, Target) then
                    local DistanceToTarget = 999999
                    pcall(function()
                      DistanceToTarget = PlayerCharacter:GetDistanceTo(Target)
                    end)
                    if MaxDistance >= DistanceToTarget then
                      local bSkipTarget = false
                      if bShotgunMode and 3000.0 < DistanceToTarget then
                        bSkipTarget = true
                      end
                      local bIsNormalBot, bIsMLBot = _G.NTH_CheckIsBot(Target)
                      local bIsBot = bIsNormalBot or bIsMLBot
                      if bIsBot then
                        if _G.NTH_GetVal("AIM_TOUCH_BO_BOT") == 1 then
                          bSkipTarget = true
                        end
                      end
                      if not bSkipTarget then
                        local bTargetIsDead = false
                        local bTargetIsNearDeath = false
                        local TargetHealth = 100
                        pcall(function()
                          bTargetIsDead = (type(Target.IsDead) == "function" and Target:IsDead()) or Target.bIsDead or Target.bIsDeadFlag
                          bTargetIsNearDeath = (type(Target.IsNearDeath) == "function" and Target:IsNearDeath()) or Target.bIsNearDeath
                          TargetHealth = (type(Target.GetHealth) == "function" and Target:GetHealth()) or Target.Health or 100
                        end)
                        if bTargetIsDead or TargetHealth <= 0 then
                          bSkipTarget = true
                        end
                        if bTargetIsNearDeath then
                          if _G.NTH_GetVal("AIM_TOUCH_BO_KNOCK") == 1 then
                            bSkipTarget = true
                          end
                        end
                        if not bSkipTarget then
                          if slua.isValid(Target.Mesh) then
                            local bHasLineOfSight = true
                            local bNeedVisibilityCheck = false
                            if bShotgunMode then
                              if _G.NTH_GetVal("AIM_TOUCH_SHOTGUN_VISCHECK") == 1 then
                                bNeedVisibilityCheck = true
                              end
                            else
                              if _G.NTH_GetVal("AIM_TOUCH_CHECK_VAT_CAN") == 1 then
                                bNeedVisibilityCheck = true
                              end
                            end
                            if bNeedVisibilityCheck then
                              bHasLineOfSight = false
                              pcall(function()
                                bHasLineOfSight = PlayerController:LineOfSightTo(Target, import("Vector")(0, 0, 0), false)
                              end)
                            end
                            if bHasLineOfSight then
                              local TargetLocation = Target.Mesh:GetSocketLocation("spine_03")
                              local DeltaX = TargetLocation.X - CameraLocation.X
                              local DeltaY = TargetLocation.Y - CameraLocation.Y
                              local DeltaZ = TargetLocation.Z - CameraLocation.Z
                              local HorizontalDistance = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY)
                              local TargetYaw = math.atan(DeltaY, DeltaX) * (180.0 / math.pi)
                              local TargetPitch = math.atan(DeltaZ, HorizontalDistance) * (180.0 / math.pi)
                              local YawDelta = NormalizeAngle(TargetYaw - CameraRotation.Yaw)
                              local PitchDelta = NormalizeAngle(TargetPitch - CameraRotation.Pitch)
                              local AngleToTarget = math.sqrt(YawDelta * YawDelta + PitchDelta * PitchDelta)
                              if FOV >= AngleToTarget then
                                local Score = 999999
                                if TargetPriority == 1 then
                                  Score = AngleToTarget
                                elseif TargetPriority == 2 then
                                  Score = DistanceToTarget
                                elseif TargetPriority == 3 then
                                  Score = TargetHealth
                                elseif TargetPriority == 4 then
                                  local TargetHealthMax = 100
                                  pcall(function()
                                    TargetHealthMax = (type(Target.GetHealthMax) == "function" and Target:GetHealthMax()) or Target.HealthMax or 100
                                  end)
                                  local HealthRatio = TargetHealth / TargetHealthMax
                                  Score = HealthRatio * 100.0
                                end
                                if BestScore > Score then
                                  BestScore = Score
                                  BestTarget = Target
                                end
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
              if BestTarget then
                if slua.isValid(BestTarget.Mesh) then
                  local AimPart = _G.NTH_GetVal("AIM_TOUCH_VI_TRI_AIM") or 1
                  if bSniperMode or bThrowMode then
                    AimPart = 1
                  end
                  if bShotgunMode then
                    AimPart = _G.NTH_GetVal("AIM_TOUCH_SHOTGUN_VI_TRI") or 1
                  end
                  local BoneName = "head"
                  if AimPart == 2 then
                    BoneName = "spine_03"
                  elseif AimPart == 3 then
                    BoneName = "pelvis"
                  elseif AimPart == 4 then
                    BoneName = "calf_l"
                  end
                  local AimLocation = BestTarget.Mesh:GetSocketLocation(BoneName)
                  if bSniperMode or bShotgunMode then
                    AimLocation.Z = AimLocation.Z + 12.0
                  end
                  if bIsThrowable then
                    local ThrowDeltaX = AimLocation.X - CameraLocation.X
                    local ThrowDeltaY = AimLocation.Y - CameraLocation.Y
                    local ThrowDeltaZ = AimLocation.Z - CameraLocation.Z
                    local ThrowDistance = math.sqrt(ThrowDeltaX * ThrowDeltaX + ThrowDeltaY * ThrowDeltaY) / 100.0
                    local ThrowHeight = ThrowDeltaZ / 100.0
                    local ThrowSpeed = 160.0
                    local GravityScale = 0.65
                    local Gravity = 9.8 * GravityScale
                    local SpeedSq = ThrowSpeed * ThrowSpeed
                    local SpeedSqSq = SpeedSq * SpeedSq
                    local Discriminant = Gravity * ThrowDistance * ThrowDistance + 2.0 * ThrowHeight * SpeedSq
                    Discriminant = Gravity * Discriminant
                    Discriminant = SpeedSqSq - Discriminant
                    if 0 < Discriminant then
                      local LaunchAngle = math.atan((SpeedSq - math.sqrt(Discriminant)) / (Gravity * ThrowDistance))
                      local ArcHeight = ThrowDistance * math.tan(LaunchAngle)
                      AimLocation.Z = CameraLocation.Z + ArcHeight * 100.0
                    else
                      AimLocation.Z = AimLocation.Z + ThrowDistance * 100.0 * GravityScale
                    end
                  end
                  if _G.NTH_GetVal("AIM_TOUCH_DU_DOAN_ACTIVE") == 1 then
                    local DistanceToBest = PlayerCharacter:GetDistanceTo(BestTarget)
                    local PredictionRange = bIsThrowable and 16000.0 or 85000.0
                    local PredictionTime = DistanceToBest / PredictionRange
                    local PredictionScale = 1.0
                    if bSniperMode then
                      local PredictionSetting = _G.NTH_GetVal("DU_DOAN_SNIP") or 50
                      PredictionScale = PredictionSetting / 50.0
                    elseif bIsThrowable then
                      local PredictionSetting = _G.NTH_GetVal("DU_DOAN_NO") or 50
                      PredictionScale = PredictionSetting / 50.0
                    else
                      local PredictionSetting = _G.NTH_GetVal("AIM_TOUCH_DU_DOAN") or 50
                      PredictionScale = PredictionSetting / 50.0
                    end
                    local TargetVelocity = import("Vector")(0, 0, 0)
                    pcall(function()
                      TargetVelocity = BestTarget:GetVelocity()
                    end)
                    AimLocation.X = AimLocation.X + TargetVelocity.X * PredictionTime * PredictionScale
                    AimLocation.Y = AimLocation.Y + TargetVelocity.Y * PredictionTime * PredictionScale
                    AimLocation.Z = AimLocation.Z + TargetVelocity.Z * PredictionTime * PredictionScale
                  end
                  local bRecoilActive = _G.NTH_GetVal("AIM_TOUCH_RECOIL_ACTIVE") == 1
                  if bIsSniper or bShotgunMode or bIsThrowable then
                    bRecoilActive = false
                  end
                  if bRecoilActive then
                    local RecoilDistance = PlayerCharacter:GetDistanceTo(BestTarget)
                    local RecoilDistanceMeters = RecoilDistance / 100.0
                    local RecoilScale = _G.NTH_GetVal("AIM_TOUCH_LESS_RECOIL") or 50
                    RecoilScale = RecoilScale / 50.0
                    if bIsGunADS then
                      AimLocation.Z = AimLocation.Z - RecoilDistanceMeters * 1.5 * RecoilScale
                    else
                      AimLocation.Z = AimLocation.Z - RecoilDistanceMeters * 0.5 * RecoilScale
                    end
                  else
                    if not bIsThrowable then
                      AimLocation.Z = AimLocation.Z - 1.2
                    end
                    if not bIsSniper and not bShotgunMode and not bIsThrowable and bIsGunADS and bIsWeaponFiring then
                      local RecoilDistanceMeters = PlayerCharacter:GetDistanceTo(BestTarget) / 100.0
                      AimLocation.Z = AimLocation.Z - RecoilDistanceMeters * 1.3
                    end
                  end
                  local AimDeltaX = AimLocation.X - CameraLocation.X
                  local AimDeltaY = AimLocation.Y - CameraLocation.Y
                  local AimDeltaZ = AimLocation.Z - CameraLocation.Z
                  local AimHorizontalDistance = math.sqrt(AimDeltaX * AimDeltaX + AimDeltaY * AimDeltaY)
                  local AimYaw = math.atan(AimDeltaY, AimDeltaX) * (180.0 / math.pi)
                  local AimPitch = math.atan(AimDeltaZ, AimHorizontalDistance) * (180.0 / math.pi)
                  local AimYawDelta = NormalizeAngle(AimYaw - CameraRotation.Yaw)
                  local AimPitchDelta = NormalizeAngle(AimPitch - CameraRotation.Pitch)
                  local AimSpeed = _G.NTH_GetVal("AIM_TOUCH_SPEED") or 30
                  if bSniperMode then
                    AimSpeed = _G.NTH_GetVal("SPEED_SNIP") or 70
                  elseif bShotgunMode then
                    AimSpeed = _G.NTH_GetVal("SPEED_SHOTGUN") or 70
                  elseif bThrowMode then
                    AimSpeed = _G.NTH_GetVal("SPEED_NO") or 60
                  end
                  if AimSpeed <= 0 then
                    AimSpeed = 1
                  end
                  local SmoothDivisor = bIsGunADS and (51 - AimSpeed) * 1.5 or (51 - AimSpeed)
                  if SmoothDivisor < 1.0 then
                    SmoothDivisor = 1.0
                  end
                  PlayerController:AddYawInput(AimYawDelta / SmoothDivisor)
                  PlayerController:AddPitchInput(AimPitchDelta / SmoothDivisor)
                  if bShotgunMode then
                    local AimError = math.sqrt(AimYawDelta * AimYawDelta + AimPitchDelta * AimPitchDelta)
                    local FireAngleThreshold = 8.0
                    local FireInterval = 0.1
                    if AimError < FireAngleThreshold then
                      local Now = os.clock()
                      if not _G.NTH_LastAutoFireTime then
                        _G.NTH_LastAutoFireTime = 0
                      end
                      local SinceLastFire = Now - _G.NTH_LastAutoFireTime
                      if FireInterval < SinceLastFire then
                        pcall(function()
                          local EShootWeaponShootMode = import("EShootWeaponShootMode")
                          local ShootMode = (EShootWeaponShootMode and EShootWeaponShootMode.SWST_TraceTarget) or 0
                          if type(PlayerCharacter.StartFire) == "function" then
                            PlayerCharacter:StartFire(0, 0, ShootMode, import("Vector")(0, 0, 0), true, nil)
                          end
                          if type(PlayerCharacter.StartWeaponFire) == "function" then
                            PlayerCharacter:StartWeaponFire()
                          end
                          if time_ticker and time_ticker.AddTimerOnce then
                            time_ticker.AddTimerOnce(0.02, function()
                              pcall(function()
                                if type(PlayerCharacter.StopWeaponFire) == "function" then
                                  PlayerCharacter:StopWeaponFire()
                                end
                              end)
                            end)
                          end
                        end)
                        _G.NTH_LastAutoFireTime = Now
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end)
    if time_ticker and time_ticker.AddTimerOnce then
      time_ticker.AddTimerOnce(0.015, Tick)
    end
  end

  Tick()
end

_G.NTH_BotCache = _G.NTH_BotCache or {}
local function NTH_CheckIsBot(Character)
  if not Character or not slua.isValid(Character) then
    return false, false
  end
  local CacheKey = tostring(Character)
  if _G.NTH_BotCache[CacheKey] then
    return _G.NTH_BotCache[CacheKey].isNormalBot, _G.NTH_BotCache[CacheKey].isMLBot
  end
  local isNormalBot = false
  local isMLBot = false
  pcall(function()
    if Character.bMEnsure == true or (Character.MLEnsureStyle and 0 < Character.MLEnsureStyle) then
      isMLBot = true
    end
    if Character.EnsureStyle then
      if Character.EnsureStyle == 1 or Character.EnsureStyle == 2 or Character.EnsureStyle == 3 or Character.EnsureStyle == 5 then
        isMLBot = true
      elseif Character.EnsureStyle == 4 then
        isNormalBot = true
      end
    end
    if Character.bEnsure == true or Character.bIsAI == true or Character.bIsBot == true or Character.IsAI == true then
      isNormalBot = true
    end
    if type(Character.IsBot) == "function" then
      if Character:IsBot() then
        isNormalBot = true
      end
    end
    local Controller
    if type(Character.GetControllerSafety) == "function" then
      Controller = Character:GetControllerSafety()
    end
    if not Controller then
      Controller = Character.Controller
    end
    if slua.isValid(Controller) then
      if Controller.IsMLAI == true or (type(Controller.IsMLAIPlayerParam) == "function" and Controller:IsMLAIPlayerParam()) then
        isMLBot = true
      end
      if Controller.FakePlayerBornType == 1 then
        if not Controller.bForceRecordKillNum then
          isMLBot = true
        end
      end
      local AIParams
      if type(Controller.GetAIParams) == "function" then
        AIParams = Controller:GetAIParams()
      end
      if not AIParams then
        AIParams = Controller.AIParams
      end
      if AIParams then
        if AIParams.bMLAIPlayer == true or AIParams.bMLDelivery == true or (AIParams.MLBotType and 0 < AIParams.MLBotType) then
          isMLBot = true
        end
      end
      if Controller.IsMercenary == true or Controller.IsAdvancedAI == true then
        isNormalBot = true
      end
    end
    local PlayerState = Character.PlayerState
    if not PlayerState then
      if type(Character.GetPlayerStateSafety) == "function" then
        PlayerState = Character:GetPlayerStateSafety()
      end
    end
    if slua.isValid(PlayerState) then
      if PlayerState.bIsMLAI == true then
        isMLBot = true
      end
      if PlayerState.bPSEnsure == true or PlayerState.bIsABot == true or PlayerState.bIsBot == true or PlayerState.bIsAI == true then
        isNormalBot = true
      end
      if PlayerState.MLAIDisplayUID then
        if 0 < PlayerState.MLAIDisplayUID then
          isMLBot = true
        end
      end
      if PlayerState.TeammateTakeOverFeature then
        if PlayerState.TeammateTakeOverFeature.bAITakeOver == true then
          isNormalBot = true
        end
      end
      local UID = tonumber(PlayerState.UID)
      if not UID then
        UID = tonumber(PlayerState.PlayerUID)
        if not UID then
          UID = 0
        end
      end
      if 44001 <= UID and UID <= 44010 then
        isNormalBot = true
      end
      if type(PlayerState.IsBot) == "function" then
        if PlayerState:IsBot() then
          isNormalBot = true
        end
      end
      if type(PlayerState.IsABot) == "function" then
        if PlayerState:IsABot() then
          isNormalBot = true
        end
      end
    end
  end)
  if isMLBot then
    isNormalBot = false
  end
  if isNormalBot or isMLBot then
    _G.NTH_BotCache[CacheKey] = {
      isNormalBot = isNormalBot,
      isMLBot = isMLBot
    }
  end
  return isNormalBot, isMLBot
end

_G.NTH_CheckIsBot = NTH_CheckIsBot

_G.NTH_EspInfoV1Widget = _G.NTH_EspInfoV1Widget or nil
_G.NTH_EspInfoV2Widget = _G.NTH_EspInfoV2Widget or nil

local function ClearEspInfoV1Widget()
  if _G.NTH_EspInfoV1Widget then
    if slua.isValid(_G.NTH_EspInfoV1Widget) then
      pcall(function()
        _G.NTH_EspInfoV1Widget:RemoveFromParent()
      end)
    end
  end
  _G.NTH_EspInfoV1Widget = nil
end

local function ClearEspInfoV2Widget()
  if _G.NTH_EspInfoV2Widget then
    if slua.isValid(_G.NTH_EspInfoV2Widget) then
      pcall(function()
        _G.NTH_EspInfoV2Widget:RemoveFromParent()
      end)
    end
  end
  _G.NTH_EspInfoV2Widget = nil
end

local EspInfoV1WidgetPath = "/Game/UMG/UI_BP/Common/BaseComponent/CommonBaseComponent_TextButton_UIBP.CommonBaseComponent_TextButton_UIBP"

local function GetEspInfoV1Widget()
  if _G.NTH_EspInfoV1Widget then
    if slua.isValid(_G.NTH_EspInfoV1Widget) then
      return _G.NTH_EspInfoV1Widget
    end
  end
  ClearEspInfoV1Widget()
  pcall(function()
    local Widget = slua.loadUI(EspInfoV1WidgetPath)
    if not Widget or not slua.isValid(Widget) then
      return
    end
    local HudModule = require("game_frontend_hud")
    if not HudModule or not HudModule.AddToContainer then
      return
    end
    HudModule.AddToContainer(UIContainers.Top, Widget, 10600)
    if Widget.RichText_Content then
      local Font = Widget.RichText_Content.Font
      if Font then
        Font.Size = 13
        Font.TypefaceFontName = "Bold"
        Widget.RichText_Content:SetFont(Font)
      end
    end
    local WidgetLayoutLibrary = import("WidgetLayoutLibrary")
    local CanvasSlot = WidgetLayoutLibrary and WidgetLayoutLibrary.SlotAsCanvasSlot(Widget)
    if CanvasSlot then
      CanvasSlot:SetAnchors(FAnchors(0.5, 0, 0.5, 0))
      CanvasSlot:SetAlignment(FVector2D(0.5, 0))
      CanvasSlot:SetPosition(FVector2D(0, 70))
      CanvasSlot:SetSize(FVector2D(250, 30))
    end
    _G.NTH_EspInfoV1Widget = Widget
  end)
  return _G.NTH_EspInfoV1Widget
end

local EspInfoV2WidgetPath = "/Game/UMG/UI_BP/Common/Tab/Vertical/LevelOne/LevelOne_Text/Item/Common_Tab_Vertical_LevelOne_CountDown_Item_UIBP.Common_Tab_Vertical_LevelOne_CountDown_Item_UIBP"

local function GetEspInfoV2Widget()
  if _G.NTH_EspInfoV2Widget then
    if slua.isValid(_G.NTH_EspInfoV2Widget) then
      return _G.NTH_EspInfoV2Widget
    end
  end
  ClearEspInfoV2Widget()
  pcall(function()
    local Widget = slua.loadUI(EspInfoV2WidgetPath)
    if not Widget or not slua.isValid(Widget) then
      return
    end
    local HudModule = require("game_frontend_hud")
    if not HudModule or not HudModule.AddToContainer then
      return
    end
    HudModule.AddToContainer(UIContainers.Top, Widget, 10600)
    if Widget.Image_Time then
      Widget.Image_Time:SetVisibility(UEnums.ESlateVisibility.Collapsed)
    end
    if Widget.TextBlock_Time then
      pcall(function()
        Widget.TextBlock_Time:SetJustification(UEnums.ETextJustify.Center)
      end)
      local Font = Widget.TextBlock_Time.Font
      if Font then
        Font.Size = 14
        Font.TypefaceFontName = "Bold"
        Widget.TextBlock_Time:SetFont(Font)
      end
    end
    local WidgetLayoutLibrary = import("WidgetLayoutLibrary")
    local CanvasSlot = WidgetLayoutLibrary and WidgetLayoutLibrary.SlotAsCanvasSlot(Widget)
    if CanvasSlot then
      CanvasSlot:SetAnchors(FAnchors(0.5, 0, 0.5, 0))
      CanvasSlot:SetAlignment(FVector2D(0.5, 0))
      CanvasSlot:SetPosition(FVector2D(0, 70))
      CanvasSlot:SetAutoSize(true)
    end
    _G.NTH_EspInfoV2Widget = Widget
  end)
  return _G.NTH_EspInfoV2Widget
end

local function NormalizeAngle(angle)
  while 180 < angle do
    angle = angle - 360
  end
  while angle < -180 do
    angle = angle + 360
  end
  return angle
end

_G.NTH_WarningAimWidget = _G.NTH_WarningAimWidget or nil

local function ClearWarningAimWidget()
  if _G.NTH_WarningAimWidget then
    if slua.isValid(_G.NTH_WarningAimWidget) then
      pcall(function()
        _G.NTH_WarningAimWidget:RemoveFromParent()
      end)
    end
  end
  _G.NTH_WarningAimWidget = nil
end

local WarningAimWidgetPath = "/Game/UMG/UI_BP/Common/Tab/Vertical/LevelOne/LevelOne_Text/Item/Common_Tab_Vertical_LevelOne_CountDown_Item_UIBP.Common_Tab_Vertical_LevelOne_CountDown_Item_UIBP"

local function GetWarningAimWidget()
  if _G.NTH_WarningAimWidget then
    if slua.isValid(_G.NTH_WarningAimWidget) then
      return _G.NTH_WarningAimWidget
    end
  end
  ClearWarningAimWidget()
  pcall(function()
    local Widget = slua.loadUI(WarningAimWidgetPath)
    if not Widget or not slua.isValid(Widget) then
      return
    end
    local HudModule = require("game_frontend_hud")
    if not HudModule or not HudModule.AddToContainer then
      return
    end
    HudModule.AddToContainer(UIContainers.Top, Widget, 10601)
    if Widget.Image_Time then
      Widget.Image_Time:SetVisibility(UEnums.ESlateVisibility.Collapsed)
    end
    if Widget.TextBlock_Time then
      pcall(function()
        Widget.TextBlock_Time:SetJustification(UEnums.ETextJustify.Center)
      end)
      local Font = Widget.TextBlock_Time.Font
      if Font then
        Font.Size = 14
        Font.TypefaceFontName = "Bold"
        Widget.TextBlock_Time:SetFont(Font)
      end
      Widget.TextBlock_Time:SetColorAndOpacity(FSlateColor(FLinearColor(1, 0, 0, 1)))
    end
    local WidgetLayoutLibrary = import("WidgetLayoutLibrary")
    local CanvasSlot = WidgetLayoutLibrary and WidgetLayoutLibrary.SlotAsCanvasSlot(Widget)
    if CanvasSlot then
      CanvasSlot:SetAnchors(FAnchors(0.5, 0, 0.5, 0))
      CanvasSlot:SetAlignment(FVector2D(0.5, 0))
      CanvasSlot:SetPosition(FVector2D(0, 110))
      CanvasSlot:SetAutoSize(true)
    end
    _G.NTH_WarningAimWidget = Widget
  end)
  return _G.NTH_WarningAimWidget
end

local function InitNTHESPVIP()
  if _G.NTH_ESP_VIP_Init then
    return
  end
  _G.NTH_ESP_VIP_Init = true
  local NTH_PlayerMapMarker = {}
  local SlateBlueprintLibrary = nil
  local WidgetLayoutLibrary = nil
  pcall(function()
    local Library = import("SlateBlueprintLibrary")
    if not Library then
      Library = import("/Script/UMG.SlateBlueprintLibrary")
    end
    SlateBlueprintLibrary = Library
  end)
  pcall(function()
    local Library = import("WidgetLayoutLibrary")
    if not Library then
      Library = import("/Script/UMG.WidgetLayoutLibrary")
    end
    WidgetLayoutLibrary = Library
  end)
  NTH_PlayerMapMarker.ESPWorldOffsetZ = 0
  NTH_PlayerMapMarker.bActive = false
  NTH_PlayerMapMarker.ESPCanvas = nil
  NTH_PlayerMapMarker.ESPWidgets = {}
  NTH_PlayerMapMarker.ESPWidgetPtrs = {}

  local function IsValid(Obj)
    if Obj == nil then
      return false
    end
    if slua then
      if slua.isValid then
        return slua.isValid(Obj)
      end
    end
    return Obj ~= nil
  end

  function NTH_PlayerMapMarker.GetMyPlayerController()
    local PC = NTH_PlayerMapMarker._CachedPC
    if PC then
      if IsValid(PC) then
        return PC
      end
    end
    pcall(function()
      local GameplayData = require("GameLua.GameCore.Data.GameplayData")
      PC = GameplayData.GetPlayerController and GameplayData.GetPlayerController()
    end)
    if PC then
      if IsValid(PC) then
        NTH_PlayerMapMarker._CachedPC = PC
        return PC
      end
    end
    return nil
  end

  function NTH_PlayerMapMarker.GetAllCharacters()
    local Characters = {}
    pcall(function()
      local Pawns = Game:GetAllPlayerPawns()
      if Pawns then
        for _, Pawn in pairs(Pawns) do
          if Pawn then
            if slua.isValid(Pawn) then
              local PlayerKey
              if Pawn.GetPlayerKey then
                PlayerKey = Pawn:GetPlayerKey()
              end
              if not PlayerKey then
                PlayerKey = Pawn.PlayerKey
                if not PlayerKey then
                  PlayerKey = Pawn.PlayerState and Pawn.PlayerState.PlayerKey
                end
              end
              if PlayerKey then
                Characters[PlayerKey] = Pawn
              end
            end
          end
        end
      end
    end)
    return Characters
  end

  function NTH_PlayerMapMarker.GetMyPlayerKey()
    local PC = NTH_PlayerMapMarker.GetMyPlayerController()
    if not IsValid(PC) then
      return nil
    end
    local MyPlayerKey = nil
    pcall(function()
      local PlayerKey
      if PC.GetPlayerKey then
        PlayerKey = PC:GetPlayerKey()
      end
      if not PlayerKey then
        PlayerKey = PC.PlayerState and PC.PlayerState.PlayerKey
      end
      MyPlayerKey = PlayerKey
    end)
    return MyPlayerKey
  end

  function NTH_PlayerMapMarker.IsAlive(Character)
    local bAlive = true
    pcall(function()
      if Character.IsAlive then
        bAlive = Character:IsAlive()
      end
    end)
    return bAlive
  end

  function NTH_PlayerMapMarker.GetCharacterLocation(Character)
    if not IsValid(Character) then
      return nil
    end
    local Location = nil
    pcall(function()
      if Character.K2_GetActorLocation then
        Location = Character:K2_GetActorLocation()
      else
        if Game then
          if Game.GetActorLocation then
            Location = Game:GetActorLocation(Character)
          end
        end
      end
    end)
    return Location
  end

  function NTH_PlayerMapMarker.GetESPLocation(Character)
    if not IsValid(Character) then
      return nil
    end
    local Location = NTH_PlayerMapMarker.GetCharacterLocation(Character)
    if Location then
      local OffsetZ = 65
      pcall(function()
        if Character.bIsCrouched then
          OffsetZ = 40
        end
        if Character.IsProne then
          if Character:IsProne() then
            OffsetZ = 15
          end
        end
        local Z = Location.Z + OffsetZ
        local WorldOffsetZ = NTH_PlayerMapMarker.ESPWorldOffsetZ
        if not WorldOffsetZ then
          WorldOffsetZ = 0
        end
        Z = Z + WorldOffsetZ
        Location.Z = Z
      end)
    end
    return Location
  end

  function NTH_PlayerMapMarker.InitESPCanvas()
    if NTH_PlayerMapMarker.ESPCanvas then
      if Game:IsValid(NTH_PlayerMapMarker.ESPCanvas) then
        return true
      end
    end
    local Canvas = nil
    pcall(function()
      local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
      local MainControlBaseUI = InGameUITools.GetMainControlBaseUI()
      local CanvasPanel = MainControlBaseUI.CanvasPanel_0
      if not CanvasPanel then
        CanvasPanel = MainControlBaseUI.CanvasPanel_42
      end
      Canvas = CanvasPanel
    end)
    if not Canvas then
      return false
    end
    NTH_PlayerMapMarker.ESPCanvas = Canvas
    return true
  end

  NTH_PlayerMapMarker._CanvasScaleX, NTH_PlayerMapMarker._CanvasScaleY = 1.0, 1.0
  NTH_PlayerMapMarker._CanvasOffsetX, NTH_PlayerMapMarker._CanvasOffsetY = 0.0, 0.0

  function NTH_PlayerMapMarker.UpdateCanvasTransform(PC)
    if not NTH_PlayerMapMarker.ESPCanvas or not Game:IsValid(NTH_PlayerMapMarker.ESPCanvas) then
      return
    end
    pcall(function()
      local Geometry = NTH_PlayerMapMarker.ESPCanvas:GetCachedGeometry()
      if Geometry then
        if SlateBlueprintLibrary then
          if SlateBlueprintLibrary.AbsoluteToLocal then
            local OriginLocal = SlateBlueprintLibrary.AbsoluteToLocal(Geometry, FVector2D(0, 0))
            local HundredLocal = SlateBlueprintLibrary.AbsoluteToLocal(Geometry, FVector2D(100, 100))
            if OriginLocal and HundredLocal then
              NTH_PlayerMapMarker._CanvasScaleX = (HundredLocal.X - OriginLocal.X) / 100
              NTH_PlayerMapMarker._CanvasScaleY = (HundredLocal.Y - OriginLocal.Y) / 100
              NTH_PlayerMapMarker._CanvasOffsetX = OriginLocal.X
              NTH_PlayerMapMarker._CanvasOffsetY = OriginLocal.Y
            end
          end
        end
      end
    end)
  end

  function NTH_PlayerMapMarker.ScreenPixelToCanvasLocal(ScreenPos)
    if not ScreenPos then
      return FVector2D(0, 0)
    end
    return FVector2D(ScreenPos.X * NTH_PlayerMapMarker._CanvasScaleX + NTH_PlayerMapMarker._CanvasOffsetX, ScreenPos.Y * NTH_PlayerMapMarker._CanvasScaleY + NTH_PlayerMapMarker._CanvasOffsetY)
  end

  function NTH_PlayerMapMarker.ProjectWorldToCanvasLocal(PC, WorldLocation)
    if not IsValid(PC) or not WorldLocation then
      return false, FVector2D(0, 0)
    end
    local ScreenPos = FVector2D(0, 0)
    local bProjected = false
    pcall(function()
      local Result = PC:ProjectWorldLocationToScreen(WorldLocation, ScreenPos, true)
      if (Result == true or Result == 1) or ScreenPos.X ~= 0 or ScreenPos.Y ~= 0 then
        bProjected = true
      end
    end)
    if not bProjected or (ScreenPos.X == 0 and ScreenPos.Y == 0) then
      return false, FVector2D(0, 0)
    end
    return true, NTH_PlayerMapMarker.ScreenPixelToCanvasLocal(ScreenPos)
  end

  function NTH_PlayerMapMarker.FindWeaponIconInWidget(Widget, Depth, MaxDepth)
    if not Widget or not slua.isValid(Widget) then
      return nil
    end
    if not Depth then
      Depth = 0
    end
    if not MaxDepth then
      MaxDepth = 6
    end
    local IconNames = {
      "Image_Weapon",
      "Image_WeaponIcon",
      "Image_Gun",
      "Image_Icon",
      "WeaponIcon",
      "WeaponImage"
    }
    for _, IconName in ipairs(IconNames) do
      local FoundIcon = nil
      pcall(function()
        local Child = Widget[IconName]
        if Child then
          if slua.isValid(Child) then
            if Child.Brush then
              FoundIcon = Child
            end
          end
        end
      end)
      if FoundIcon then
        return FoundIcon
      end
    end
    if Depth >= MaxDepth then
      return nil
    end
    local ChildCount = 0
    pcall(function()
      if Widget.GetChildrenCount then
        ChildCount = Widget:GetChildrenCount()
      end
    end)
    for Index = 0, math.max(ChildCount - 1, 0), 1 do
      local ChildWidget = nil
      pcall(function()
        ChildWidget = Widget:GetChildAt(Index)
      end)
      if ChildWidget then
        if slua.isValid(ChildWidget) then
          local Icon = NTH_PlayerMapMarker.FindWeaponIconInWidget(ChildWidget, Depth + 1, MaxDepth)
          if Icon then
            return Icon
          end
        end
      end
    end
    return nil
  end

  function NTH_PlayerMapMarker.ApplyBotLabel(Widget)
    if not Widget or not slua.isValid(Widget) then
      return
    end
    pcall(function()
      local HideNames = {
        "WeaponIcon",
        "Image_Weapon",
        "Border_Weapon",
        "Switcher_WeaponIcon",
        "SizeBox_Weapon",
        "Image_WeaponBg",
        "Border_WeaponColor"
      }
      for _, HideName in ipairs(HideNames) do
        if Widget[HideName] then
          if slua.isValid(Widget[HideName]) then
            Widget[HideName]:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
          end
        end
      end
      local NameText = Widget.TextBlock_PlayerName
      if NameText then
        if slua.isValid(NameText) then
          NameText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
          NameText:SetText("[BOT]")
          local Vector2D = import("Vector2D")
          if not Vector2D then
            Vector2D = _G.FVector2D
          end
          if Vector2D then
            if NameText.SetRenderTranslation then
              NameText:SetRenderTranslation(Vector2D(25.0, 0.0))
            end
          end
          local LabelColor = import("LinearColor")(0, 1, 0, 1)
          local SlateColor = import("SlateColor")
          if not SlateColor then
            SlateColor = import("/Script/SlateCore.SlateColor")
          end
          if SlateColor then
            NameText:SetColorAndOpacity(SlateColor(LabelColor))
          else
            NameText:SetColorAndOpacity(LabelColor)
          end
          local Font = NameText.Font
          if Font then
            Font.Size = 10
            Font.TypefaceFontName = "Bold"
            NameText:SetFont(Font)
          end
          if NameText.SetJustification then
            NameText:SetJustification(UEnums.ETextJustify.Center)
          end
        end
      end
    end)
  end

  function NTH_PlayerMapMarker.AddWeaponIconToESP(Widget, Character)
    if not Widget or not slua.isValid(Widget) then
      return
    end
    pcall(function()
      if Widget.TextBlock_PlayerName then
        if slua.isValid(Widget.TextBlock_PlayerName) then
          Widget.TextBlock_PlayerName:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
      end
      -- NOTE: upstream bug: this result is discarded, the weapon is fetched again on the next line
      Character:GetCurrentWeapon()
      local Weapon = Character:GetCurrentWeapon()
      local WeaponID = 0
      if slua.isValid(Weapon) then
        local ItemDefineID = Weapon:GetItemDefineID()
        local TypeSpecificID = nil
        if ItemDefineID then
          TypeSpecificID = ItemDefineID.TypeSpecificID
        end
        WeaponID = TypeSpecificID or 0
      end
      if WeaponID == 0 then
        local HideNames = {
          "WeaponIcon",
          "Image_Weapon",
          "Border_Weapon",
          "Switcher_WeaponIcon",
          "SizeBox_Weapon"
        }
        for _, HideName in ipairs(HideNames) do
          if Widget[HideName] then
            if slua.isValid(Widget[HideName]) then
              pcall(function()
                Widget[HideName]:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
              end)
            end
          end
        end
        return
      end
      pcall(function()
        if Widget.UpdateWeapon then
          Widget:UpdateWeapon(WeaponID)
        end
      end)
      pcall(function()
        if Widget.SetWeaponID then
          Widget:SetWeaponID(WeaponID)
        end
      end)
      local Icon = Widget.WeaponIcon
      if not Icon then
        Icon = Widget.Image_Weapon
        if not Icon then
          Icon = Widget.Image_Gun
        end
      end
      if not Icon or not slua.isValid(Icon) then
        Icon = NTH_PlayerMapMarker.FindWeaponIconInWidget(Widget, 0, 6)
      end
      if slua.isValid(Icon) then
        local ItemData = CDataTable.GetTableData("Item", WeaponID)
        if ItemData then
          if ItemData.ItemWhiteIcon then
            if ItemData.ItemWhiteIcon ~= "" then
              Icon:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
              Icon:SetBrushFromPathAsync(ItemData.ItemWhiteIcon, false)
              pcall(function()
                Icon:SetColorAndOpacity(import("LinearColor")(1, 1, 1, 1))
              end)
              pcall(function()
                Icon:SetRenderOpacity(1.0)
              end)
              local Brush = slua.IndexReference(Icon, "Brush")
              if Brush then
                Brush.ImageSize = import("Vector2D")(128, 64)
                if Icon.SetBrush then
                  Icon:SetBrush(Brush)
                end
              end
              local Node = Icon
              for Depth = 1, 7, 1 do
                if not Node then
                  break
                end
                if not slua.isValid(Node) then
                  break
                end
                pcall(function()
                  if Node.GetParent then
                    local Parent = Node:GetParent()
                    if slua.isValid(Parent) then
                      Parent:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                      pcall(function()
                        Parent:SetRenderOpacity(1.0)
                      end)
                      if string.find(tostring(Parent), "WidgetSwitcher") then
                        local ChildCount = Parent:GetChildrenCount()
                        for Index = 0, ChildCount - 1, 1 do
                          local Child = Parent:GetChildAt(Index)
                          if Child == Node or tostring(Child) == tostring(Node) then
                            Parent:SetActiveWidgetIndex(Index)
                            break
                          end
                        end
                      end
                      Node = Parent
                    else
                      Node = nil
                    end
                  else
                    Node = nil
                  end
                end)
              end
            end
          end
        end
      end
      local FadeNames = {
        "Border_Weapon",
        "Image_WeaponBg",
        "Border_WeaponColor"
      }
      for _, FadeName in ipairs(FadeNames) do
        if Widget[FadeName] then
          if slua.isValid(Widget[FadeName]) then
            pcall(function()
              Widget[FadeName]:SetRenderOpacity(0.0)
            end)
          end
        end
      end
    end)
  end

  NTH_PlayerMapMarker._OBHeadWidgetClass = nil

  function NTH_PlayerMapMarker.CreateESPWidget()
    if not NTH_PlayerMapMarker.ESPCanvas then
      return nil
    end
    if not NTH_PlayerMapMarker._OBHeadWidgetClass then
      pcall(function()
        NTH_PlayerMapMarker._OBHeadWidgetClass = slua.loadClass("/Game/BluePrints/UI/OBUI/Item/OB_PlayerHeadHPItem_UIBP.OB_PlayerHeadHPItem_UIBP")
      end)
      if not NTH_PlayerMapMarker._OBHeadWidgetClass then
        return nil
      end
    end
    local ESPWidget = nil
    pcall(function()
      local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
      local PC = NTH_PlayerMapMarker.GetMyPlayerController()
      local Owner
      if IsValid(PC) then
        Owner = PC.Object
      end
      if not Owner then
        Owner = NTH_PlayerMapMarker.ESPCanvas
      end
      ESPWidget = USTExtraBlueprintFunctionLibrary.CreateWidgetByClass(NTH_PlayerMapMarker._OBHeadWidgetClass, Owner)
    end)
    if not ESPWidget then
      return nil
    end
    pcall(function()
      ESPWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
      local HideNames = {
        "TextBlock_TeamName",
        "SizeBox_HP",
        "ProgressBar_HP",
        "Image_HPBG",
        "Image_TeamBG",
        "Image_TeamLogoBG",
        "Image_TeamBG_2",
        "Image_RingBG",
        "Image_Line",
        "Image_Split",
        "Image_Bg",
        "Border_HP"
      }
      for _, HideName in ipairs(HideNames) do
        if ESPWidget[HideName] then
          if slua.isValid(ESPWidget[HideName]) then
            ESPWidget[HideName]:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
          end
        end
      end
    end)
    return ESPWidget
  end

  function NTH_PlayerMapMarker.UpdateESPPositionWithPC(ESPWidget, CanvasPos)
    if not ESPWidget or not CanvasPos then
      return
    end
    pcall(function()
      local Key = tostring(ESPWidget)
      local Slot = NTH_PlayerMapMarker.ESPWidgetPtrs[Key]
      if not Slot or not slua.isValid(Slot) then
        local NewSlot = NTH_PlayerMapMarker.ESPCanvas:AddChildToCanvas(ESPWidget)
        if NewSlot then
          if slua.isValid(NewSlot) then
            Slot = NewSlot
            NTH_PlayerMapMarker.ESPWidgetPtrs[Key] = NewSlot
            pcall(function()
              Slot:SetAutoSize(true)
            end)
            pcall(function()
              Slot.bAutoSize = true
            end)
            local Alignment = FVector2D(0.5, 1.0)
            pcall(function()
              Slot.Alignment = Alignment
            end)
            pcall(function()
              Slot:SetAlignment(Alignment)
            end)
            pcall(function()
              Slot:SetAlignment(0.5, 1.0)
            end)
            pcall(function()
              Slot:SetZOrder(20)
            end)
          end
        end
      end
      pcall(function()
        ESPWidget:SetRenderTranslation(FVector2D(0.0, 0.0))
      end)
      pcall(function()
        ESPWidget.RenderTransformPivot = FVector2D(0.5, 1.0)
      end)
      pcall(function()
        ESPWidget:SetRenderTransformPivot(FVector2D(0.5, 1.0))
      end)
      ESPWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
      if Slot then
        if slua.isValid(Slot) then
          local PosX = CanvasPos.X + 20
          local PosY = CanvasPos.Y
          Slot:SetPosition(FVector2D(PosX, PosY))
        end
      end
    end)
  end

  function NTH_PlayerMapMarker.RemoveESPWidget(ESPWidget)
    if not ESPWidget then
      return
    end
    pcall(function()
      local Key = tostring(ESPWidget)
      NTH_PlayerMapMarker.ESPWidgetPtrs[Key] = nil
      ESPWidget:RemoveFromParent()
      ESPWidget:ConditionalBeginDestroy()
    end)
  end

  function NTH_PlayerMapMarker.ScanAndRenderWeapons()
    local bWeaponESP = _G.NTH_GetVal and _G.NTH_GetVal("ESP_WEAPON") == 1
    local bBotLabelESP = _G.NTH_GetVal and _G.NTH_GetVal("ESP_BOT_LABEL") == 1
    if not bWeaponESP and not bBotLabelESP then
      NTH_PlayerMapMarker.ClearAllESP()
      return
    end
    if not NTH_PlayerMapMarker.InitESPCanvas() then
      return
    end
    local PC = NTH_PlayerMapMarker.GetMyPlayerController()
    if not IsValid(PC) then
      return
    end
    NTH_PlayerMapMarker.UpdateCanvasTransform(PC)
    local MyCharacter = nil
    pcall(function()
      local GameplayData = require("GameLua.GameCore.Data.GameplayData")
      MyCharacter = GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
      if not slua.isValid(MyCharacter) then
        if PC.GetPawn then
          MyCharacter = PC:GetPawn()
        end
      end
    end)
    local MyTeamID = -1
    if slua.isValid(MyCharacter) then
      pcall(function()
        local TeamID
        if type(MyCharacter.GetTeamID) == "function" then
          TeamID = MyCharacter:GetTeamID()
        end
        if not TeamID then
          TeamID = MyCharacter.TeamID
          if not TeamID then
            TeamID = MyCharacter.PlayerState and MyCharacter.PlayerState.TeamNum
            if not TeamID then
              TeamID = -1
            end
          end
        end
        MyTeamID = TeamID
      end)
    end
    local Characters = NTH_PlayerMapMarker.GetAllCharacters()
    local MyPlayerKey = NTH_PlayerMapMarker.GetMyPlayerKey()
    local SeenKeys = {}
    for PlayerKey, Character in pairs(Characters) do
      if IsValid(Character) then
        local bIsMe = tostring(PlayerKey) == tostring(MyPlayerKey)
        local KeyStr = tostring(PlayerKey)
        if not bIsMe then
          if NTH_PlayerMapMarker.IsAlive(Character) then
            local CharTeamID = -2
            pcall(function()
              local TeamID
              if type(Character.GetTeamID) == "function" then
                TeamID = Character:GetTeamID()
              end
              if not TeamID then
                TeamID = Character.TeamID
                if not TeamID then
                  TeamID = Character.PlayerState and Character.PlayerState.TeamNum
                  if not TeamID then
                    TeamID = -2
                  end
                end
              end
              CharTeamID = TeamID
            end)
            if CharTeamID ~= MyTeamID then
              local WorldLocation = NTH_PlayerMapMarker.GetESPLocation(Character)
              if WorldLocation then
                local bProjected, CanvasPos = NTH_PlayerMapMarker.ProjectWorldToCanvasLocal(PC, WorldLocation)
                if bProjected then
                  SeenKeys[KeyStr] = true
                  local ESPWidget = NTH_PlayerMapMarker.ESPWidgets[KeyStr]
                  if not ESPWidget or not slua.isValid(ESPWidget) then
                    ESPWidget = NTH_PlayerMapMarker.CreateESPWidget()
                    if ESPWidget then
                      NTH_PlayerMapMarker.ESPWidgets[KeyStr] = ESPWidget
                    end
                  end
                  if ESPWidget then
                    if slua.isValid(ESPWidget) then
                      local bIsNormalBot = false
                      local bIsMLBot = false
                      if _G.NTH_CheckIsBot then
                        bIsNormalBot, bIsMLBot = _G.NTH_CheckIsBot(Character)
                      end
                      local bIsBot = bIsNormalBot or bIsMLBot
                      local bHandled = false
                      if bIsBot then
                        if bBotLabelESP then
                          NTH_PlayerMapMarker.ApplyBotLabel(ESPWidget)
                          bHandled = true
                        elseif bWeaponESP then
                          NTH_PlayerMapMarker.AddWeaponIconToESP(ESPWidget, Character)
                          bHandled = true
                        end
                      elseif bWeaponESP then
                        NTH_PlayerMapMarker.AddWeaponIconToESP(ESPWidget, Character)
                        bHandled = true
                      end
                      if bHandled then
                        NTH_PlayerMapMarker.UpdateESPPositionWithPC(ESPWidget, CanvasPos)
                        pcall(function()
                          ESPWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        end)
                      else
                        pcall(function()
                          ESPWidget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                        end)
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    for KeyStr, ESPWidget in pairs(NTH_PlayerMapMarker.ESPWidgets) do
      if not SeenKeys[KeyStr] then
        NTH_PlayerMapMarker.RemoveESPWidget(ESPWidget)
        NTH_PlayerMapMarker.ESPWidgets[KeyStr] = nil
      end
    end
  end

  function NTH_PlayerMapMarker.ClearAllESP()
    for _, ESPWidget in pairs(NTH_PlayerMapMarker.ESPWidgets) do
      NTH_PlayerMapMarker.RemoveESPWidget(ESPWidget)
    end
    NTH_PlayerMapMarker.ESPWidgets = {}
    NTH_PlayerMapMarker.ESPWidgetPtrs = {}
    NTH_PlayerMapMarker.ESPCanvas = nil
  end

  function NTH_PlayerMapMarker.AttachTimers()
    local TimeTicker = package.loaded["common.time_ticker"]
    if not TimeTicker then
      TimeTicker = require("common.time_ticker")
    end
    if not TimeTicker or not TimeTicker.AddTimerLoop then
      return
    end
    if NTH_PlayerMapMarker.RenderTimerHandle then
      TimeTicker.RemoveTimer(NTH_PlayerMapMarker.RenderTimerHandle)
    end
    NTH_PlayerMapMarker.RenderTimerHandle = TimeTicker.AddTimerLoop(0, function()
      if NTH_PlayerMapMarker.bActive then
        pcall(function()
          local PC = NTH_PlayerMapMarker.GetMyPlayerController()
          if PC then
            if NTH_PlayerMapMarker._LastPC ~= PC then
              NTH_PlayerMapMarker.ClearAllESP()
              NTH_PlayerMapMarker._LastPC = PC
            end
          end
          NTH_PlayerMapMarker.ScanAndRenderWeapons()
        end)
      end
    end, -1, 0.02)
  end

  function NTH_PlayerMapMarker.Start()
    if NTH_PlayerMapMarker.bActive then
      return
    end
    NTH_PlayerMapMarker.bActive = true
    NTH_PlayerMapMarker.AttachTimers()
  end

  function NTH_PlayerMapMarker.Stop()
    NTH_PlayerMapMarker.bActive = false
    local TimeTicker = package.loaded["common.time_ticker"]
    if not TimeTicker then
      TimeTicker = require("common.time_ticker")
    end
    if TimeTicker then
      if NTH_PlayerMapMarker.RenderTimerHandle then
        TimeTicker.RemoveTimer(NTH_PlayerMapMarker.RenderTimerHandle)
        NTH_PlayerMapMarker.RenderTimerHandle = nil
      end
    end
    NTH_PlayerMapMarker.ClearAllESP()
  end

  _G.NTH_PlayerMapMarker = NTH_PlayerMapMarker
  NTH_PlayerMapMarker.Start()
end

_G.InitNTHESPVIP = InitNTHESPVIP
function CharacterBase:NTHMOD_INJECT_MOD()
  if not Client then
    return
  end

  local function OnTick()
    if not _G._Authenticated_ then
      return
    end
    if not slua.isValid(self.Object) then
      return
    end
    local PlayerController = GameplayData.GetPlayerController()
    local PlayerCharacter = GameplayData.GetPlayerCharacter()
    if slua.isValid(PlayerController) then
      local bUseViewTarget = false
      pcall(function()
        bUseViewTarget = not slua.isValid(PlayerCharacter) or (type(PlayerCharacter.IsDead) == "function" and PlayerCharacter:IsDead())
      end)
      if bUseViewTarget then
        if type(PlayerController.GetViewTarget) == "function" then
          local ViewTarget = PlayerController:GetViewTarget()
          if slua.isValid(ViewTarget) then
            if type(ViewTarget.GetHealth) == "function" then
              PlayerCharacter = ViewTarget
            end
          end
        end
      end
    end
    if not slua.isValid(PlayerCharacter) then
      return
    end
    if nowUTC > expireTime then
      if self.Object == PlayerCharacter then
        if not self.bHasShownExpiredNotice then
          if self.Object.IsAlive then
            if self.Object:IsAlive() then
              self.bHasShownExpiredNotice = true
              pcall(function()
                local logic_common_msg_box = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                if not logic_common_msg_box then
                  logic_common_msg_box = require("client.slua.logic.common.logic_common_msg_box")
                end
                if logic_common_msg_box then
                  if logic_common_msg_box.Show then
                    logic_common_msg_box.Show(4, "Notice from admin nthuy2004", "Contact @nthuy2004.", function()
                      local UKismetSystemLibrary = import("KismetSystemLibrary")
                      if UKismetSystemLibrary then
                        UKismetSystemLibrary.LaunchURL("https://t.me/nthuy2004")
                      end
                    end, function()
                    end, "Close", "H\225\187\166Y")
                  end
                end
              end)
            end
          end
        end
      end
      return
    end
    local TppFov = _G.NTH_GetVal("IPAD_VIEW_TPP")
    if TppFov == 0 or TppFov < 80 then
      TppFov = 100
    end
    local ScopeArmLength = _G.NTH_GetVal("IPAD_VIEW_SCOPE")
    if ScopeArmLength == 0 then
      ScopeArmLength = 15
    end
    local VehicleFov = _G.NTH_GetVal("IPAD_VIEW_XE")
    if VehicleFov == 0 or VehicleFov < 90 then
      VehicleFov = 110
    end
    local ThirdPersonCameraComponent = self.Object.ThirdPersonCameraComponent
    local ScopingSpringArm = self.Object.ScopingSpringArm
    local bIsWeaponAiming = self.Object.bIsWeaponAiming or false
    local CurrentVehicle = self.Object.GetCurrentVehicle and self.Object:GetCurrentVehicle() or nil
    local bIsDriver = false
    if slua.isValid(CurrentVehicle) then
      if CurrentVehicle.GetDriver then
        local Driver = CurrentVehicle:GetDriver()
        if slua.isValid(Driver) then
          if Driver == self.Object then
            bIsDriver = true
          end
        end
      end
    end
    if not bIsWeaponAiming then
      if bIsDriver then
        local CameraComponentClass = import("CameraComponent")
        if CameraComponentClass then
          if slua.isValid(CurrentVehicle) then
            local VehicleCamera = CurrentVehicle:GetComponentByClass(CameraComponentClass)
            if slua.isValid(VehicleCamera) then
              VehicleCamera:SetFieldOfView(VehicleFov)
              VehicleCamera.FieldOfView = VehicleFov
            end
          end
        end
        if slua.isValid(ThirdPersonCameraComponent) then
          ThirdPersonCameraComponent:SetFieldOfView(VehicleFov)
          ThirdPersonCameraComponent.FieldOfView = VehicleFov
        end
      else
        if slua.isValid(ThirdPersonCameraComponent) and 90 < TppFov then
          ThirdPersonCameraComponent:SetFieldOfView(TppFov)
          ThirdPersonCameraComponent.FieldOfView = TppFov
        end
      end
    end
    if slua.isValid(ScopingSpringArm) and 0 < ScopeArmLength then
      ScopingSpringArm.TargetArmLength = ScopeArmLength
    end
    if self.Object.GetCurrentWeapon then
      local CurrentWeapon = self.Object:GetCurrentWeapon()
      if slua.isValid(CurrentWeapon) then
        local NowClock = os.clock()
        if self.LastWeaponEntity ~= CurrentWeapon then
          self.LastWeaponEntity = CurrentWeapon
          self.bForceWeaponMod = true
        end
        if not self.LastWeaponModTime or NowClock > self.LastWeaponModTime + 2.0 then
          self.bForceWeaponMod = true
          self.LastWeaponModTime = NowClock
        end
        if self.bForceWeaponMod or not CurrentWeapon.bIsNTHModded then
          pcall(function()
            local ShootWeaponEntity = CurrentWeapon.ShootWeaponEntity_GEN_VARIABLE or CurrentWeapon.ShootWeaponEntity
            if slua.isValid(ShootWeaponEntity) then
              local ThuTam = _G.NTH_GetVal("THU_TAM") / 100.0
              local GiamGiatNgang = _G.NTH_GetVal("GIAM_GIAT_NGANG") / 100.0
              local GiamGiatDoc = _G.NTH_GetVal("GIAM_GIAT_DOC") / 100.0
              local GiamRungScope = _G.NTH_GetVal("GIAM_RUNG_SCOPE") / 100.0
              ShootWeaponEntity.GameDeviationFactor = 3.36 - 3.36 * ThuTam
              ShootWeaponEntity.AccessoriesHRecoilFactor = 0.8 - 0.8 * GiamGiatNgang
              ShootWeaponEntity.AccessoriesVRecoilFactor = 0.5 - 0.5 * GiamGiatDoc
              ShootWeaponEntity.RecoilKickADS = 0.2 - 0.2 * GiamRungScope
              if _G.NTH_GetVal("AIMBOT") == 1 then
                if ShootWeaponEntity.AutoAimingConfig then
                  local AutoAimingConfig = ShootWeaponEntity.AutoAimingConfig
                  local SpeedAimbot = _G.NTH_GetVal("SPEED_AIMBOT") / 100.0
                  local FovAimbot = _G.NTH_GetVal("FOV_AIMBOT") / 100.0
                  local AimSpeed = 3.0 + 3.0 * SpeedAimbot
                  local AimRangeRate = 1.5 + 1.5 * FovAimbot
                  if AutoAimingConfig.OuterRange then
                    AutoAimingConfig.OuterRange.Speed = AimSpeed
                    AutoAimingConfig.OuterRange.SpeedRate = AimSpeed
                    AutoAimingConfig.OuterRange.RangeRate = AimRangeRate
                    AutoAimingConfig.OuterRange.RangeRateSight = AimRangeRate
                    AutoAimingConfig.OuterRange.SpeedRateSight = AimSpeed
                    AutoAimingConfig.OuterRange.CrouchRate = 1.0
                    AutoAimingConfig.OuterRange.ProneRate = 1.0
                  end
                  if AutoAimingConfig.InnerRange then
                    AutoAimingConfig.InnerRange.Speed = AimSpeed
                    AutoAimingConfig.InnerRange.SpeedRate = AimSpeed
                    AutoAimingConfig.InnerRange.RangeRate = AimRangeRate
                    AutoAimingConfig.InnerRange.RangeRateSight = AimRangeRate
                    AutoAimingConfig.InnerRange.SpeedRateSight = AimSpeed
                    AutoAimingConfig.InnerRange.CrouchRate = 1.0
                    AutoAimingConfig.InnerRange.ProneRate = 1.0
                  end
                  ShootWeaponEntity.AutoAimingConfig = AutoAimingConfig
                end
              end
            end
          end)
          CurrentWeapon.bIsNTHModded = true
          self.bForceWeaponMod = false
        end
      end
    end
    if self.Object == PlayerCharacter then
      if not _G.NTHModTickCount then
        _G.NTHModTickCount = 0
      end
      if not _G.MagicUpdateVersion then
        _G.MagicUpdateVersion = 1
      end
      if _G.EnvRequiresUpdate == nil then
        _G.EnvRequiresUpdate = true
      end
      _G.NTHModTickCount = _G.NTHModTickCount + 1
      if _G.NTHModTickCount % 50 == 0 then
        -- NOTE: upstream bug: _G.NTH_NeedSave is never assigned anywhere in the
        -- mod, so this guard always passes and the reload is unconditional.
        if not _G.NTH_NeedSave then
          pcall(function()
            _G.NTH_LoadINI()
          end)
        end
      end
      if not self.NTH_NativeESP_Ready then
        pcall(function()
          local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
          local ScreenMarkConfig = GamePlayTools.GetCurrentConfig("ScreenMarkConfig")
          if ScreenMarkConfig then
            if ScreenMarkConfig[1006] then
              ScreenMarkConfig[1006].bBindBlocked = true
              ScreenMarkConfig[1006].bBindOutScreen = true
              ScreenMarkConfig[1006].MaxWidgetNum = 99
              ScreenMarkConfig[1006].MaxShowDistance = 6000000
              ScreenMarkConfig[1006].bScaleByDistance = false
              ScreenMarkConfig[1006].BindSocketName = "root"
              ScreenMarkConfig[1006].bUseLuaWorldSocketName = true
              ScreenMarkConfig[1006].WorldPositionOffset = import("Vector")(0, 0, -30)
            end
            if not ScreenMarkConfig[9999] then
              local MarkConfig = {}
              MarkConfig.UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C"
              MarkConfig.MaxWidgetNum = 99
              MarkConfig.MaxShowDistance = 6000000
              MarkConfig.bBindOutScreen = true
              MarkConfig.bBindBlocked = true
              MarkConfig.bIsBindingActor = true
              MarkConfig.BindSocketName = "head"
              MarkConfig.bUseLuaWorldSocketName = true
              MarkConfig.WorldPositionOffset = import("Vector")(0, 0, 50)
              MarkConfig.bNeedPreLoad = true
              MarkConfig.Priority = 2
              ScreenMarkConfig[9999] = MarkConfig
              local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
              if InGameMarkTools then
                if InGameMarkTools.ScreenMarkManager then
                  if InGameMarkTools.ScreenMarkManager.OnInitMarkGroupData then
                    pcall(function()
                      InGameMarkTools.ScreenMarkManager:OnInitMarkGroupData(9999)
                    end)
                  end
                end
              end
            end
          end
          for ModuleName, Module in pairs(package.loaded) do
            if type(ModuleName) == "string" then
              if string.find(ModuleName, "ScreenMarkConfig") then
                if type(Module) == "table" then
                  if Module[1006] then
                    Module[1006].bBindBlocked = true
                    Module[1006].bBindOutScreen = true
                    Module[1006].MaxWidgetNum = 99
                    Module[1006].MaxShowDistance = 6000000
                    Module[1006].bScaleByDistance = false
                    Module[1006].BindSocketName = "root"
                    Module[1006].bUseLuaWorldSocketName = true
                    Module[1006].WorldPositionOffset = import("Vector")(0, 0, -30)
                  end
                  local MarkConfig = {}
                  MarkConfig.UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C"
                  MarkConfig.MaxWidgetNum = 99
                  MarkConfig.MaxShowDistance = 6000000
                  MarkConfig.bBindOutScreen = true
                  MarkConfig.bBindBlocked = true
                  MarkConfig.bIsBindingActor = true
                  MarkConfig.BindSocketName = "head"
                  MarkConfig.bUseLuaWorldSocketName = true
                  MarkConfig.WorldPositionOffset = import("Vector")(0, 0, 50)
                  MarkConfig.bNeedPreLoad = true
                  MarkConfig.Priority = 2
                  Module[9999] = MarkConfig
                end
              end
            end
          end
          local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
          local ClientHPBarSubSystem = SubsystemMgr:Get("ClientHPBarSubSystem")
          if ClientHPBarSubSystem then
            if ClientHPBarSubSystem.SetPauseCheck then
              ClientHPBarSubSystem:SetPauseCheck(true)
            end
            if ClientHPBarSubSystem.FocusActorCheckParam then
              ClientHPBarSubSystem.FocusActorCheckParam.CheckBlock = false
              ClientHPBarSubSystem.FocusActorCheckParam.CheckDistance = 1000000
            end
          end
          if UIManager then
            if UIManager.GetUI then
              local EnemyHpWidgetsMain = UIManager.GetUI(UIManager.UI_Config_InGame.EnemyHpWidgetsMain)
              if slua.isValid(EnemyHpWidgetsMain) then
                if EnemyHpWidgetsMain.SetCheckBlock then
                  EnemyHpWidgetsMain:SetCheckBlock(false)
                end
                if EnemyHpWidgetsMain.UIRoot then
                  if EnemyHpWidgetsMain.UIRoot.CanvasPanel_HPBarWidgets then
                    if EnemyHpWidgetsMain.UIRoot.CanvasPanel_HPBarWidgets.SetRenderScale then
                      EnemyHpWidgetsMain.UIRoot.CanvasPanel_HPBarWidgets:SetRenderScale(import("Vector2D")(1.5, 1.5))
                    end
                  end
                end
              end
            end
          end
        end)
        self.NTH_NativeESP_Ready = true
      end
      local bWallhackChams = _G.NTH_GetVal("WALLHACK_CHAMS") == 1
      if _G.EnvRequiresUpdate then
        _G.EnvRequiresUpdate = false
        pcall(function()
          local AllCharacters = GameplayData.GetAllPlayerCharacters and GameplayData.GetAllPlayerCharacters() or {}
          for _, Character in pairs(AllCharacters) do
            if slua.isValid(Character) then
              Character.WallhackApplied = false
              Character.LastAuraHash = nil
              Character.LastMeshCountWall = -1
              Character.NTH_AuraMeshes = nil
            end
          end
          local UKismetSystemLibrary = import("KismetSystemLibrary")
          local Controller = GameplayData.GetPlayerController()

          local function RunCmd(CmdName, CmdValue)
            if slua.isValid(UKismetSystemLibrary) then
              if slua.isValid(Controller) then
                UKismetSystemLibrary.ExecuteConsoleCommand(Controller, CmdName .. " " .. CmdValue)
              end
            end
            local GameInstance = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
            if slua.isValid(GameInstance) then
              if GameInstance.ExecuteCMD then
                GameInstance:ExecuteCMD(CmdName, CmdValue)
              end
            end
          end

          if slua.isValid(Controller) then
            if bWallhackChams then
              RunCmd("r.EnableDrawDyeingColor", "1")
              RunCmd("r.SupportDyeingColorDistanceFade", "1")
              RunCmd("r.SupportDyeingColorMeshProxy", "1")
              RunCmd("r.EnablePrimitiveHighlight", "1")
              RunCmd("r.CustomDepth", "3")
              RunCmd("r.DeviceLevelUseHighLightMode", "1")
              RunCmd("r.Highlight.Enable", "1")
            end
            if _G.NTH_GetVal("NOGRASS") == 1 then
              RunCmd("r.DisableGrassRender", "1")
            else
              RunCmd("r.DisableGrassRender", "0")
            end
            if _G.NTH_GetVal("NOTREES") == 1 then
              RunCmd("foliage.DensityScale", "0")
              RunCmd("r.Foliage.DensityScale", "0")
              RunCmd("foliage.MinimumScreenSize", "10000")
              RunCmd("r.DisableTreeRender", "1")
            else
              RunCmd("foliage.DensityScale", "1")
              RunCmd("r.Foliage.DensityScale", "1")
              RunCmd("foliage.MinimumScreenSize", "0.0001")
              RunCmd("r.DisableTreeRender", "0")
            end
            if _G.NTH_GetVal("NOWATER") == 1 then
              RunCmd("r.Water.SingleLayer.Enable", "0")
              RunCmd("r.Show.Water", "0")
              RunCmd("r.Show.Translucency", "0")
              RunCmd("r.DisableWaterRender", "1")
            else
              RunCmd("r.Water.SingleLayer.Enable", "1")
              RunCmd("r.Show.Water", "1")
              RunCmd("r.Show.Translucency", "1")
              RunCmd("r.DisableWaterRender", "0")
            end
            if _G.NTH_GetVal("NOFOG") == 1 then
              RunCmd("r.SkyAtmosphere", "0")
              RunCmd("r.Atmosphere", "0")
              RunCmd("r.Fog", "0")
              RunCmd("r.VolumetricFog", "0")
              RunCmd("r.DisableSkyRender", "1")
            else
              RunCmd("r.SkyAtmosphere", "1")
              RunCmd("r.Atmosphere", "1")
              RunCmd("r.Fog", "1")
              RunCmd("r.VolumetricFog", "1")
              RunCmd("r.DisableSkyRender", "0")
            end
            if _G.NTH_GetVal("BLACKSKY") == 1 then
              RunCmd("r.CylinderMaxDrawHeight", "9999")
            else
              RunCmd("r.CylinderMaxDrawHeight", "0")
            end
            if _G.NTH_GetVal("WHITE_BODY") == 1 then
              RunCmd("r.CharacterDiffuseOffset", "2")
              RunCmd("r.CharacterDiffusePower", "5")
              RunCmd("r.CharacterMinShadowFactor", "100")
            else
              RunCmd("r.CharacterDiffuseOffset", "0")
              RunCmd("r.CharacterDiffusePower", "1")
              RunCmd("r.CharacterMinShadowFactor", "0")
            end
          end
        end)
      end
      local Characters = {}
      if GameplayData.GetAllPlayerCharacters then
        Characters = GameplayData.GetAllPlayerCharacters()
      else
        if GameplayData.GameCharacters then
          for _, GameCharacter in pairs(GameplayData.GameCharacters) do
            table.insert(Characters, GameCharacter)
          end
        end
      end
      local PlayerCount = 0
      local BotCount = 0
      local InRangeCount = 0
      local AimingAtYouCount = 0
      if not _G.NTH_Active_HP_Cache then
        _G.NTH_Active_HP_Cache = {}
      end
      if not _G.NTH_Active_Dist_Cache then
        _G.NTH_Active_Dist_Cache = {}
      end
      for CacheKey, CacheEntry in pairs(_G.NTH_Active_HP_Cache) do
        local bRemove = false
        if not slua.isValid(CacheEntry.actor) then
          bRemove = true
        else
          pcall(function()
            local Actor = CacheEntry.actor
            if Actor.bHidden or (Actor.Mesh and Actor.Mesh.bHidden) then
              bRemove = true
            end
            if type(Actor.IsDead) == "function" then
              if Actor:IsDead() then
                bRemove = true
              end
            elseif Actor.bIsDead == true or Actor.bIsDeadFlag == true then
              bRemove = true
            end
          end)
        end
        if bRemove then
          pcall(function()
            if InGameMarkTools then
              if InGameMarkTools.ClientRemoveMapMark then
                if CacheEntry.mark then
                  InGameMarkTools.ClientRemoveMapMark(CacheEntry.mark)
                end
              else
                if CacheEntry.mark then
                  InGameMarkTools.HideMapMark(CacheEntry.mark)
                end
              end
            end
          end)
          if slua.isValid(CacheEntry.actor) then
            CacheEntry.actor.bHasAKNativeHPBar = false
            CacheEntry.actor.NativeHPBarMark = nil
          end
          _G.NTH_Active_HP_Cache[CacheKey] = nil
        end
      end
      for CacheKey, CacheEntry in pairs(_G.NTH_Active_Dist_Cache) do
        local bRemove = false
        if not slua.isValid(CacheEntry.actor) then
          bRemove = true
        else
          pcall(function()
            local Actor = CacheEntry.actor
            if Actor.bHidden or (Actor.Mesh and Actor.Mesh.bHidden) then
              bRemove = true
            end
            if type(Actor.IsDead) == "function" then
              if Actor:IsDead() then
                bRemove = true
              end
            elseif Actor.bIsDead == true or Actor.bIsDeadFlag == true then
              bRemove = true
            end
            local bIsNearDeath = false
            if type(Actor.IsNearDeath) == "function" then
              bIsNearDeath = Actor:IsNearDeath()
            else
              if Actor.bIsNearDeath ~= nil then
                bIsNearDeath = Actor.bIsNearDeath
              end
            end
            local Health = 100
            if type(Actor.GetHealth) == "function" then
              Health = Actor:GetHealth()
            else
              if Actor.Health ~= nil then
                Health = Actor.Health
              end
            end
            if Health <= 0 and not bIsNearDeath then
              bRemove = true
            end
          end)
        end
        if bRemove then
          pcall(function()
            if InGameMarkTools then
              if InGameMarkTools.ClientRemoveMapMark then
                if CacheEntry.mark then
                  InGameMarkTools.ClientRemoveMapMark(CacheEntry.mark)
                end
              else
                if CacheEntry.mark then
                  InGameMarkTools.HideMapMark(CacheEntry.mark)
                end
              end
            end
          end)
          if slua.isValid(CacheEntry.actor) then
            CacheEntry.actor.bHasAKNativeDistBar = false
            CacheEntry.actor.NativeDistMark = nil
          end
          _G.NTH_Active_Dist_Cache[CacheKey] = nil
        end
      end
      local MyTeamID = -1
      pcall(function()
        MyTeamID = (type(PlayerCharacter.GetTeamID) == "function" and PlayerCharacter:GetTeamID()) or PlayerCharacter.TeamID or (PlayerCharacter.PlayerState and PlayerCharacter.PlayerState.TeamNum) or -1
      end)
      for _, Character in pairs(Characters) do
        if slua.isValid(Character) and Character ~= PlayerCharacter then
          local TargetTeamID = -2
          pcall(function()
            TargetTeamID = (type(Character.GetTeamID) == "function" and Character:GetTeamID()) or Character.TeamID or (Character.PlayerState and Character.PlayerState.TeamNum) or -2
          end)
          if TargetTeamID ~= MyTeamID then
            local bIsDead = false
            local bIsNearDeath = false
            local Health = 100
            pcall(function()
              if type(Character.IsNearDeath) == "function" then
                bIsNearDeath = Character:IsNearDeath()
              else
                if Character.bIsNearDeath ~= nil then
                  bIsNearDeath = Character.bIsNearDeath
                end
              end
              if type(Character.IsDead) == "function" then
                bIsDead = Character:IsDead()
              else
                if Character.bIsDead ~= nil then
                  bIsDead = Character.bIsDead
                else
                  if Character.bIsDeadFlag ~= nil then
                    bIsDead = Character.bIsDeadFlag
                  end
                end
              end
              if Character.bHidden or (Character.Mesh and Character.Mesh.bHidden) then
                bIsDead = true
              end
              if type(Character.GetHealth) == "function" then
                Health = Character:GetHealth()
              else
                if Character.Health ~= nil then
                  Health = Character.Health
                end
              end
              if not bIsNearDeath and Health <= 0 then
                bIsDead = true
              end
            end)
            local bDeadForDist = bIsDead
            pcall(function()
              if Health <= 0 and not bIsNearDeath then
                bDeadForDist = true
              end
            end)
            if not bIsDead then
              local bIsBot, bIsBotEx = _G.NTH_CheckIsBot(Character)
              if bIsBotEx or bIsBot then
                BotCount = BotCount + 1
              else
                PlayerCount = PlayerCount + 1
              end
              local InfoRange = _G.NTH_GetVal("ESP_INFO_RANGE") or 400
              local Distance = 99999
              pcall(function()
                if PlayerCharacter.GetDistanceTo then
                  Distance = math.floor(PlayerCharacter:GetDistanceTo(Character) / 100)
                end
              end)
              if InfoRange >= Distance then
                InRangeCount = InRangeCount + 1
              end
            end
            if _G.NTH_GetVal("WARN_AIMING") == 1 and not bIsNearDeath then
              pcall(function()
                local bVisible = true
                if _G.NTH_GetVal("WARN_AIMING_VISCHECK") == 1 then
                  bVisible = false
                  pcall(function()
                    bVisible = PlayerController:LineOfSightTo(Character, import("Vector")(0, 0, 0), false)
                  end)
                end
                if bVisible then
                  local MyLocation = PlayerCharacter:K2_GetActorLocation()
                  local TargetLocation = Character:K2_GetActorLocation()
                  local DeltaX = MyLocation.X - TargetLocation.X
                  local DeltaY = MyLocation.Y - TargetLocation.Y
                  local DeltaZ = MyLocation.Z - TargetLocation.Z
                  local Dist2D = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY)
                  local Dist3D = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY + DeltaZ * DeltaZ)
                  if Dist3D <= 40000.0 then
                    local AimRotation = Character.BaseAimRotation or Character:K2_GetActorRotation()
                    local AimPitch = NormalizeAngle(AimRotation.Pitch)
                    local AimYaw = NormalizeAngle(AimRotation.Yaw)
                    local WantYaw = NormalizeAngle(math.atan(DeltaY, DeltaX) * (180.0 / math.pi))
                    local WantPitch = NormalizeAngle(math.atan(DeltaZ, Dist2D) * (180.0 / math.pi))
                    local YawDiff = math.abs(NormalizeAngle(WantYaw - AimYaw))
                    local PitchDiff = math.abs(NormalizeAngle(WantPitch - AimPitch))
                    if YawDiff <= 20 and PitchDiff <= 20 then
                      AimingAtYouCount = AimingAtYouCount + 1
                    end
                  end
                end
              end)
            end
            if not bIsDead then
              local SkeletalMeshComponentClass = import("SkeletalMeshComponent")
              if not Character.NTH_NextMeshUpdateTime or os.clock() > Character.NTH_NextMeshUpdateTime then
                Character.NTH_NextMeshUpdateTime = os.clock() + 5.0 + math.random() * 1.0
                local NewMeshes = {}
                if slua.isValid(Character.Mesh) then
                  table.insert(NewMeshes, Character.Mesh)
                end
                if SkeletalMeshComponentClass then
                  pcall(function()
                    local Components = Character:GetComponentsByClass(SkeletalMeshComponentClass)
                    if Components then
                      local Count = (type(Components.Num) == "function" and Components:Num()) or #Components
                      for Index = 1, Count, 1 do
                        local Component = (type(Components.Get) == "function" and Components:Get(Index - 1)) or Components[Index]
                        if slua.isValid(Component) then
                          if Component ~= Character.Mesh then
                            table.insert(NewMeshes, Component)
                          end
                        end
                      end
                    end
                  end)
                end
                Character.NTH_CachedMeshes = NewMeshes
              end
              local CachedMeshes = Character.NTH_CachedMeshes or {}
              local MeshCount = #CachedMeshes
              local bMeshCountChanged = Character.LastMeshCountWall ~= MeshCount
              if bWallhackChams then
                local VisibleColor = GetVisibleChamsColor()
                local HiddenColor = GetOccludedChamsColor()
                local ColorKey = tostring(_G.NTH_GetVal("CHAMS_COLOR_VIS")) .. "_" .. tostring(_G.NTH_GetVal("CHAMS_COLOR_HID"))
                local AuraHash = "player_" .. ColorKey
                if bMeshCountChanged or Character.LastAuraHash ~= AuraHash or not Character.WallhackApplied then
                  pcall(function()
                    if bMeshCountChanged then
                      if Character.NTH_AuraMeshes then
                        for _, AuraMesh in ipairs(Character.NTH_AuraMeshes) do
                          DisableChams(AuraMesh)
                        end
                      end
                    end
                    for _, CachedMesh in ipairs(CachedMeshes) do
                      if slua.isValid(CachedMesh) then
                        EnableChams(CachedMesh, VisibleColor, HiddenColor)
                      end
                    end
                    if Character.DelayCustomDepth then
                      pcall(function()
                        Character:DelayCustomDepth(true)
                      end)
                    end
                  end)
                  Character.WallhackApplied = true
                  Character.LastAuraHash = AuraHash
                  Character.LastMeshCountWall = MeshCount
                  Character.NTH_AuraMeshes = CachedMeshes
                end
              else
                if Character.WallhackApplied then
                  pcall(function()
                    local AuraMeshes = Character.NTH_AuraMeshes or CachedMeshes
                    for _, AuraMesh in ipairs(AuraMeshes) do
                      if slua.isValid(AuraMesh) then
                        DisableChams(AuraMesh)
                      end
                    end
                  end)
                  Character.WallhackApplied = false
                  Character.LastAuraHash = nil
                  Character.LastMeshCountWall = nil
                  Character.NTH_AuraMeshes = nil
                end
              end
            else
              if Character.WallhackApplied then
                local CachedMeshes = Character.NTH_CachedMeshes or {}
                pcall(function()
                  local AuraMeshes = Character.NTH_AuraMeshes or CachedMeshes
                  for _, AuraMesh in ipairs(AuraMeshes) do
                    if slua.isValid(AuraMesh) then
                      DisableChams(AuraMesh)
                    end
                  end
                end)
                Character.WallhackApplied = false
                Character.LastAuraHash = nil
                Character.LastMeshCountWall = nil
                Character.NTH_AuraMeshes = nil
              end
            end
            if not bIsDead then
              if Character.bHasAKNativeHPBar then
                if Character.NTH_LastKnockState ~= nil then
                  if Character.NTH_LastKnockState ~= bIsNearDeath then
                    pcall(function()
                      if InGameMarkTools then
                        if InGameMarkTools.ClientRemoveMapMark then
                          if Character.NativeHPBarMark then
                            InGameMarkTools.ClientRemoveMapMark(Character.NativeHPBarMark)
                          end
                        end
                      end
                    end)
                    Character.bHasAKNativeHPBar = false
                    _G.NTH_Active_HP_Cache[tostring(Character)] = nil
                  end
                end
              end
              if _G.NTH_GetVal("ESP_HP") == 1 then
                if not Character.bHasAKNativeHPBar then
                  pcall(function()
                    if InGameMarkTools then
                      if InGameMarkTools.ClientAddMapMark then
                        local Mark = InGameMarkTools.ClientAddMapMark(1006, import("Vector")(0, 0, 0), 0, "", 4, Character)
                        Character.NativeHPBarMark = Mark
                        Character.bHasAKNativeHPBar = true
                        local Cache = _G.NTH_Active_HP_Cache
                        local Key = tostring(Character)
                        local Entry = {}
                        Entry.actor = Character
                        Entry.mark = Character.NativeHPBarMark
                        Cache[Key] = Entry
                      end
                    end
                  end)
                end
              else
                if Character.bHasAKNativeHPBar then
                  if InGameMarkTools then
                    pcall(function()
                      if InGameMarkTools.ClientRemoveMapMark then
                        if Character.NativeHPBarMark then
                          InGameMarkTools.ClientRemoveMapMark(Character.NativeHPBarMark)
                        end
                      else
                        if Character.NativeHPBarMark then
                          InGameMarkTools.HideMapMark(Character.NativeHPBarMark)
                        end
                      end
                    end)
                    Character.NativeHPBarMark = nil
                    Character.bHasAKNativeHPBar = false
                    _G.NTH_Active_HP_Cache[tostring(Character)] = nil
                  end
                end
              end
            else
              if Character.bHasAKNativeHPBar then
                pcall(function()
                  if InGameMarkTools then
                    if InGameMarkTools.ClientRemoveMapMark then
                      if Character.NativeHPBarMark then
                        InGameMarkTools.ClientRemoveMapMark(Character.NativeHPBarMark)
                      end
                    end
                  end
                end)
                Character.NativeHPBarMark = nil
                Character.bHasAKNativeHPBar = false
                _G.NTH_Active_HP_Cache[tostring(Character)] = nil
              end
            end
            if not bDeadForDist then
              if _G.NTH_GetVal("ESP_DISTANCE") == 1 then
                if not Character.bHasAKNativeDistBar then
                  pcall(function()
                    if InGameMarkTools then
                      if InGameMarkTools.ClientAddMapMark then
                        local Mark = InGameMarkTools.ClientAddMapMark(9999, import("Vector")(0, 0, 0), 0, "", 4, Character)
                        Character.NativeDistMark = Mark
                        Character.bHasAKNativeDistBar = true
                        local Cache = _G.NTH_Active_Dist_Cache
                        local Key = tostring(Character)
                        local Entry = {}
                        Entry.actor = Character
                        Entry.mark = Character.NativeDistMark
                        Cache[Key] = Entry
                      end
                    end
                  end)
                end
              else
                if Character.bHasAKNativeDistBar then
                  if InGameMarkTools then
                    pcall(function()
                      if InGameMarkTools.ClientRemoveMapMark then
                        if Character.NativeDistMark then
                          InGameMarkTools.ClientRemoveMapMark(Character.NativeDistMark)
                        end
                      else
                        if Character.NativeDistMark then
                          InGameMarkTools.HideMapMark(Character.NativeDistMark)
                        end
                      end
                    end)
                    Character.NativeDistMark = nil
                    Character.bHasAKNativeDistBar = false
                    _G.NTH_Active_Dist_Cache[tostring(Character)] = nil
                  end
                end
              end
            else
              if Character.bHasAKNativeDistBar then
                pcall(function()
                  if InGameMarkTools then
                    if InGameMarkTools.ClientRemoveMapMark then
                      if Character.NativeDistMark then
                        InGameMarkTools.ClientRemoveMapMark(Character.NativeDistMark)
                      end
                    end
                  end
                end)
                Character.NativeDistMark = nil
                Character.bHasAKNativeDistBar = false
                _G.NTH_Active_Dist_Cache[tostring(Character)] = nil
              end
            end
            Character.NTH_LastKnockState = bIsNearDeath
            if _G.NTH_GetVal("ESP_BOX") == 1 then
              pcall(function()
                if Character.Replay_IsEnemyFrameUIExisted then
                  if not Character:Replay_IsEnemyFrameUIExisted() then
                    Character:Replay_CreateEnemyFrameUI(true, true)
                  end
                  if Character.Replay_SetVisiableOfFrameUI then
                    Character:Replay_SetVisiableOfFrameUI(true)
                  end
                end
              end)
            else
              pcall(function()
                -- NOTE: upstream bug: self has no Replay_SetVisiableOfFrameUI, so this
                -- never runs; the enable path above targets Character, not self.
                if self.Replay_SetVisiableOfFrameUI then
                  self:Replay_SetVisiableOfFrameUI(false)
                end
              end)
            end
          end
          local Mesh = Character.Mesh
          if not Mesh then
            if Character.getAvatarComponent2 then
              Mesh = Character:getAvatarComponent2()
            end
          end
          if slua.isValid(Mesh) then
            if not Mesh.LastHitboxUpdateVersion or Mesh.LastHitboxUpdateVersion ~= _G.MagicUpdateVersion then
              Mesh.bIsAKHitboxModded = false
            end
            if not Mesh.bIsAKHitboxModded then
              pcall(function()
                local PhysicsAsset = Mesh.PhysicsAssetOverride
                if not PhysicsAsset then
                  if Mesh.SkeletalMesh then
                    PhysicsAsset = Mesh.SkeletalMesh.PhysicsAsset
                  end
                end
                if slua.isValid(PhysicsAsset) then
                  if PhysicsAsset.SkeletalBodySetups then
                    local HeadScale = 1.0 + _G.NTH_GetVal("MAGIC_HEAD") / 100.0
                    local BodyScale = 1.0 + _G.NTH_GetVal("MAGIC_BODY") / 100.0
                    local LegsScale = 1.0 + _G.NTH_GetVal("MAGIC_LEGS") / 100.0
                    local BoneScales = {}
                    BoneScales.head = HeadScale
                    BoneScales.pelvis = BodyScale
                    BoneScales.spine_03 = BodyScale
                    BoneScales.thigh_l = LegsScale
                    BoneScales.thigh_r = LegsScale
                    BoneScales.calf_l = LegsScale
                    BoneScales.calf_r = LegsScale
                    BoneScales.foot_l = LegsScale
                    BoneScales.foot_r = LegsScale
                    if not _G.NTH_HitboxBaseCache then
                      _G.NTH_HitboxBaseCache = {}
                    end
                    local AssetKey = tostring(PhysicsAsset)
                    if not _G.NTH_HitboxBaseCache[AssetKey] then
                      _G.NTH_HitboxBaseCache[AssetKey] = {}
                    end
                    local BaseCache = _G.NTH_HitboxBaseCache[AssetKey]
                    local BodySetups = PhysicsAsset.SkeletalBodySetups
                    local SetupCount = (type(BodySetups.Num) == "function" and BodySetups:Num()) or #BodySetups
                    for SetupIndex = 0, SetupCount - 1, 1 do
                      local BodySetup = (type(BodySetups.Get) == "function" and BodySetups:Get(SetupIndex)) or BodySetups[SetupIndex + 1]
                      if slua.isValid(BodySetup) then
                        local BoneName = string.lower(tostring(BodySetup.BoneName))
                        local MatchedBone = nil
                        for BoneKey, BoneScale in pairs(BoneScales) do
                          if string.find(BoneName, BoneKey) then
                            MatchedBone = BoneKey
                            break
                          end
                        end
                        if MatchedBone then
                          local Scale = BoneScales[MatchedBone]
                          local AggGeom = BodySetup.AggGeom
                          local BoxElems = (AggGeom and AggGeom.BoxElems) or BodySetup.BoxElems
                          local SphereElems = (AggGeom and AggGeom.SphereElems) or BodySetup.SphereElems
                          local SphylElems = (AggGeom and AggGeom.SphylElems) or BodySetup.SphylElems
                          local BaseEntry = BaseCache[MatchedBone]
                          if not BaseEntry then
                            BaseEntry = {}
                            BaseCache[MatchedBone] = BaseEntry
                          end
                          -- NOTE: upstream no-op: re-read cannot change the value; present verbatim in the original.
                          BaseEntry = BaseCache[MatchedBone]
                          if BoxElems then
                            local BoxElem = nil
                            pcall(function()
                              BoxElem = (type(BoxElems.Get) == "function" and BoxElems:Get(0)) or BoxElems[1]
                            end)
                            if BoxElem then
                              if not BaseEntry.Box then
                                local BaseBox = {}
                                BaseBox.X = BoxElem.X
                                BaseBox.Y = BoxElem.Y
                                BaseBox.Z = BoxElem.Z
                                BaseEntry.Box = BaseBox
                              end
                              BoxElem.X = BaseEntry.Box.X * Scale
                              BoxElem.Y = BaseEntry.Box.Y * Scale
                              BoxElem.Z = BaseEntry.Box.Z * Scale
                              pcall(function()
                                if type(BoxElems.Set) == "function" then
                                  BoxElems:Set(0, BoxElem)
                                else
                                  BoxElems[1] = BoxElem
                                end
                              end)
                              if AggGeom then
                                AggGeom.BoxElems = BoxElems
                              else
                                BodySetup.BoxElems = BoxElems
                              end
                            end
                          end
                          if SphereElems then
                            local SphereElem = nil
                            pcall(function()
                              SphereElem = (type(SphereElems.Get) == "function" and SphereElems:Get(0)) or SphereElems[1]
                            end)
                            if SphereElem then
                              if not BaseEntry.Sphere then
                                local BaseSphere = {}
                                BaseSphere.Radius = SphereElem.Radius
                                BaseEntry.Sphere = BaseSphere
                              end
                              SphereElem.Radius = BaseEntry.Sphere.Radius * Scale
                              pcall(function()
                                if type(SphereElems.Set) == "function" then
                                  SphereElems:Set(0, SphereElem)
                                else
                                  SphereElems[1] = SphereElem
                                end
                              end)
                              if AggGeom then
                                AggGeom.SphereElems = SphereElems
                              else
                                BodySetup.SphereElems = SphereElems
                              end
                            end
                          end
                          if SphylElems then
                            local SphylElem = nil
                            pcall(function()
                              SphylElem = (type(SphylElems.Get) == "function" and SphylElems:Get(0)) or SphylElems[1]
                            end)
                            if SphylElem then
                              if not BaseEntry.Sphyl then
                                local BaseSphyl = {}
                                BaseSphyl.Radius = SphylElem.Radius
                                BaseSphyl.Length = SphylElem.Length
                                BaseEntry.Sphyl = BaseSphyl
                              end
                              SphylElem.Radius = BaseEntry.Sphyl.Radius * Scale
                              SphylElem.Length = BaseEntry.Sphyl.Length * Scale
                              pcall(function()
                                if type(SphylElems.Set) == "function" then
                                  SphylElems:Set(0, SphylElem)
                                else
                                  SphylElems[1] = SphylElem
                                end
                              end)
                              if AggGeom then
                                AggGeom.SphylElems = SphylElems
                              else
                                BodySetup.SphylElems = SphylElems
                              end
                            end
                          end
                          if AggGeom then
                            BodySetup.AggGeom = AggGeom
                          end
                        end
                      end
                    end
                    if Mesh.SetPhysicsAsset then
                      Mesh:SetPhysicsAsset(PhysicsAsset)
                    end
                    Mesh.PhysicsAssetOverride = PhysicsAsset
                    if Mesh.RecreatePhysicsState then
                      pcall(function()
                        Mesh:RecreatePhysicsState()
                      end)
                    end
                  end
                end
              end)
              Mesh.bIsAKHitboxModded = true
              Mesh.LastHitboxUpdateVersion = _G.MagicUpdateVersion
            else
              pcall(function()
                Mesh.bEnableUpdateRateOptimizations = false
                if Mesh.bNoSkeletonUpdate ~= nil then
                  Mesh.bNoSkeletonUpdate = false
                end
                if Mesh.UpdateBounds then
                  Mesh:UpdateBounds()
                end
              end)
            end
          end
        else
          if Character.bHasAKNativeHPBar then
            pcall(function()
              if InGameMarkTools then
                if InGameMarkTools.ClientRemoveMapMark then
                  if Character.NativeHPBarMark then
                    InGameMarkTools.ClientRemoveMapMark(Character.NativeHPBarMark)
                  end
                  if Character.NativeDistMark then
                    InGameMarkTools.ClientRemoveMapMark(Character.NativeDistMark)
                  end
                else
                  if Character.NativeHPBarMark then
                    InGameMarkTools.HideMapMark(Character.NativeHPBarMark)
                  end
                  if Character.NativeDistMark then
                    InGameMarkTools.HideMapMark(Character.NativeDistMark)
                  end
                end
              end
            end)
            Character.NativeHPBarMark = nil
            Character.NativeDistMark = nil
            Character.bHasAKNativeHPBar = false
            Character.bHasAKNativeDistBar = false
            _G.NTH_Active_HP_Cache[tostring(Character)] = nil
            _G.NTH_Active_Dist_Cache[tostring(Character)] = nil
          end
          pcall(function()
            -- NOTE: upstream bug: self has no Replay_SetVisiableOfFrameUI, so this
            -- never runs; the enable path above targets Character, not self.
            if self.Replay_SetVisiableOfFrameUI then
              self:Replay_SetVisiableOfFrameUI(false)
            end
          end)
        end
      end
      local ShownPlayerCount = PlayerCount or 0
      local ShownBotCount = BotCount or 0
      local ShownInRangeCount = InRangeCount or 0
      local InfoRange = _G.NTH_GetVal("ESP_INFO_RANGE") or 400
      local InfoTextV1 = "[ PLAYER  " .. tostring(ShownPlayerCount) .. " ]  [ BOT  " .. tostring(ShownBotCount) .. " ]  [ DISTANCE " .. tostring(InfoRange) .. "M  " .. tostring(ShownInRangeCount) .. " ]"
      local InfoTextV2 = "[ PLAYER  " .. tostring(ShownPlayerCount) .. " ]  [ BOT  " .. tostring(ShownBotCount) .. " ]  [ DISTANCE " .. tostring(InfoRange) .. "M  " .. tostring(ShownInRangeCount) .. " ]"
      InfoTextV1 = string.gsub(InfoTextV1, " ", "\194\160")
      InfoTextV2 = string.gsub(InfoTextV2, " ", "\194\160")
      if _G.NTH_GetVal("ESP_INFO_V1") == 1 then
        ClearEspInfoV2Widget()
        local InfoWidget = GetEspInfoV1Widget()
        if InfoWidget then
          if slua.isValid(InfoWidget) then
            pcall(function()
              InfoWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
              if InfoWidget.RichText_Content then
                InfoWidget.RichText_Content:SetText(InfoTextV1)
              end
            end)
          end
        end
      else
        if _G.NTH_GetVal("ESP_INFO_V2") == 1 then
          ClearEspInfoV1Widget()
          local InfoWidget = GetEspInfoV2Widget()
          if InfoWidget then
            if slua.isValid(InfoWidget) then
              pcall(function()
                InfoWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                if InfoWidget.TextBlock_Time then
                  InfoWidget.TextBlock_Time:SetText(InfoTextV2)
                  if 0 < ShownInRangeCount then
                    InfoWidget.TextBlock_Time:SetColorAndOpacity(FSlateColor(FLinearColor(1, 0, 0, 1)))
                  else
                    InfoWidget.TextBlock_Time:SetColorAndOpacity(FSlateColor(FLinearColor(0, 1, 0, 1)))
                  end
                end
              end)
            end
          end
        else
          ClearEspInfoV1Widget()
          ClearEspInfoV2Widget()
        end
      end
      if _G.NTH_GetVal("WARN_AIMING") == 1 and 0 < AimingAtYouCount then
        local WarnWidget = GetWarningAimWidget()
        if WarnWidget then
          if slua.isValid(WarnWidget) then
            pcall(function()
              WarnWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
              if WarnWidget.TextBlock_Time then
                local WarnText = "[ WARNING  " .. tostring(AimingAtYouCount) .. "  AIMING TO YOU ]"
                WarnText = string.gsub(WarnText, " ", "\194\160")
                WarnWidget.TextBlock_Time:SetText(WarnText)
                local BlinkPhase = _G.NTHModTickCount or 0
                BlinkPhase = BlinkPhase % 10
                if BlinkPhase < 5 then
                  WarnWidget.TextBlock_Time:SetColorAndOpacity(FSlateColor(FLinearColor(1, 0, 0, 1)))
                else
                  WarnWidget.TextBlock_Time:SetColorAndOpacity(FSlateColor(FLinearColor(1, 1, 0, 1)))
                end
              end
            end)
          end
        end
      else
        ClearWarningAimWidget()
      end
      if _G.NTH_GetVal("ESP_CAR") == 1 then
        pcall(function()
          local HUD = (PlayerController and PlayerController.MyHUD) or nil
          if slua.isValid(HUD) then
            if HUD.AddDebugText then
              local VehicleClass = import("STExtraVehicleBase")
              local OutActors = slua.Array(UEnums.EPropertyClass.Object, import("Actor"))
              local Vehicles = UGameplayStatics.GetAllActorsOfClass(PlayerCharacter, VehicleClass, OutActors)
              for VehicleIndex = 0, Vehicles:Num() - 1, 1 do
                local Vehicle = Vehicles:Get(VehicleIndex)
                if slua.isValid(Vehicle) then
                  local VehicleHP = 0
                  pcall(function()
                    if slua.isValid(Vehicle.VehicleCommon) then
                      VehicleHP = Vehicle.VehicleCommon.HP or 0
                    end
                  end)
                  if 0 < VehicleHP then
                    local Distance = PlayerCharacter:GetDistanceTo(Vehicle) / 100
                    if Distance <= 400 then
                      local TextScale = math.max(0.6, 1.0 - Distance / 400)
                      local VehicleName = "PH\198\175\198\160NG TI\225\187\134N"
                      local VehicleColor = {}
                      VehicleColor.R = 200
                      VehicleColor.G = 200
                      VehicleColor.B = 200
                      VehicleColor.A = 255
                      pcall(function()
                        local UKismetSystemLibrary = import("KismetSystemLibrary")
                        local ClassName = UKismetSystemLibrary.GetClassDisplayName(Vehicle:GetClass())
                        if string.find(ClassName, "MotorcycleCart") or string.find(ClassName, "SideCar") then
                          VehicleName = "MOTOR 3 B\195\129NH"
                          VehicleColor = {R = 255, G = 215, B = 0, A = 255}
                        elseif string.find(ClassName, "Glider") then
                          VehicleName = "T\195\128U L\198\175\225\187\162N"
                          VehicleColor = {R = 255, G = 250, B = 205, A = 255}
                        elseif string.find(ClassName, "Motorcycle") or string.find(ClassName, "Motor") then
                          VehicleName = "MOTOR 2 B\195\129NH"
                          VehicleColor = {R = 255, G = 255, B = 0, A = 255}
                        elseif string.find(ClassName, "MiniBus") or string.find(ClassName, "Van") then
                          VehicleName = "XE BUS"
                          VehicleColor = {R = 255, G = 182, B = 193, A = 255}
                        elseif string.find(ClassName, "LadaNiva") or string.find(ClassName, "Niva") then
                          VehicleName = "LADA NIVA"
                          VehicleColor = {R = 173, G = 216, B = 230, A = 255}
                        elseif string.find(ClassName, "CoupeRB") or string.find(ClassName, "SportsCar") then
                          VehicleName = "COUPE RB"
                          VehicleColor = {R = 0, G = 250, B = 154, A = 255}
                        elseif string.find(ClassName, "Monster") then
                          VehicleName = "MONSTER TRUCK"
                          VehicleColor = {R = 139, G = 0, B = 0, A = 255}
                        elseif string.find(ClassName, "Hovercraft") then
                          VehicleName = "T\195\128U \196\144\225\187\134M KH\195\141"
                          VehicleColor = {R = 70, G = 130, B = 180, A = 255}
                        elseif string.find(ClassName, "AquaRail") or string.find(ClassName, "JetSki") then
                          VehicleName = "M\195\148T\195\148 N\198\175\225\187\154C"
                          VehicleColor = {R = 0, G = 255, B = 255, A = 255}
                        elseif string.find(ClassName, "Bicycle") or string.find(ClassName, "Bike") then
                          VehicleName = "XE \196\144\225\186\160P"
                          VehicleColor = {R = 244, G = 164, B = 96, A = 255}
                        elseif string.find(ClassName, "Helicopter") then
                          VehicleName = "TR\225\187\176C TH\196\130NG"
                          VehicleColor = {R = 169, G = 169, B = 169, A = 255}
                        elseif string.find(ClassName, "Quad") or string.find(ClassName, "ATV") then
                          VehicleName = "XE ATV"
                          VehicleColor = {R = 210, G = 105, B = 30, A = 255}
                        elseif string.find(ClassName, "Tuk") or string.find(ClassName, "Rikshaw") then
                          VehicleName = "XE TUKTUK"
                          VehicleColor = {R = 218, G = 112, B = 214, A = 255}
                        elseif string.find(ClassName, "BRDM") or string.find(ClassName, "Amphibia") then
                          VehicleName = "TANK BRDM"
                          VehicleColor = {R = 139, G = 69, B = 19, A = 255}
                        elseif string.find(ClassName, "UTV") or string.find(ClassName, "Polaris") then
                          VehicleName = "XE UTV"
                          VehicleColor = {R = 32, G = 178, B = 170, A = 255}
                        elseif string.find(ClassName, "PickUp") then
                          VehicleName = "B\195\129N T\225\186\162I"
                          VehicleColor = {R = 192, G = 192, B = 192, A = 255}
                        elseif string.find(ClassName, "UAZ") then
                          VehicleName = "UAZ"
                          VehicleColor = {R = 0, G = 255, B = 0, A = 255}
                        elseif string.find(ClassName, "Dacia") then
                          VehicleName = "DACIA"
                          VehicleColor = {R = 0, G = 191, B = 255, A = 255}
                        elseif string.find(ClassName, "Buggy") then
                          VehicleName = "BUGGY"
                          VehicleColor = {R = 255, G = 20, B = 147, A = 255}
                        elseif string.find(ClassName, "Mirado") then
                          VehicleName = "MIRADO"
                          VehicleColor = {R = 255, G = 140, B = 0, A = 255}
                        elseif string.find(ClassName, "Rony") then
                          VehicleName = "RONY"
                          VehicleColor = {R = 144, G = 238, B = 144, A = 255}
                        elseif string.find(ClassName, "Zima") then
                          VehicleName = "ZIMA"
                          VehicleColor = {R = 240, G = 248, B = 255, A = 255}
                        elseif string.find(ClassName, "Scooter") then
                          VehicleName = "SCOOTER"
                          VehicleColor = {R = 135, G = 206, B = 235, A = 255}
                        elseif string.find(ClassName, "Boat") or string.find(ClassName, "PG117") then
                          VehicleName = "CA N\195\148"
                          VehicleColor = {R = 0, G = 0, B = 255, A = 255}
                        end
                      end)
                      local DebugText = "[" .. VehicleName .. "]\n[" .. tostring(math.floor(Distance)) .. "m]"
                      HUD:AddDebugText(DebugText, Vehicle, 0.15, {X = 0, Y = 0, Z = 150}, {X = 0, Y = 0, Z = 150}, VehicleColor, true, false, true, nil, TextScale * 1.1, true)
                    end
                  end
                end
              end
            end
          end
        end)
      end
      if _G.NTH_GetVal("ESP_BOMB") == 1 then
        pcall(function()
          local HUD = (PlayerController and PlayerController.MyHUD) or nil
          if slua.isValid(HUD) then
            if HUD.AddDebugText then
              local GrenadeClass = import("STExtraGrenadeBase")
              local OutActors = slua.Array(UEnums.EPropertyClass.Object, import("Actor"))
              local Grenades = UGameplayStatics.GetAllActorsOfClass(PlayerCharacter, GrenadeClass, OutActors)
              if not _G.NTH_BombTimers then
                _G.NTH_BombTimers = {}
              end
              local ServerTime = 0.0
              pcall(function()
                ServerTime = GameplayData.GetGameState():GetServerWorldTimeSeconds()
              end)
              for GrenadeIndex = 0, Grenades:Num() - 1, 1 do
                local Grenade = Grenades:Get(GrenadeIndex)
                if slua.isValid(Grenade) then
                  local BombType = 0
                  pcall(function()
                    local UKismetSystemLibrary = import("KismetSystemLibrary")
                    local ClassName = UKismetSystemLibrary.GetClassDisplayName(Grenade:GetClass())
                    if string.find(ClassName, "Smoke") then
                      BombType = 602002
                    elseif string.find(ClassName, "Burn") or string.find(ClassName, "Molotov") then
                      BombType = 602003
                    elseif string.find(ClassName, "Grenade") then
                      BombType = 602004
                    end
                  end)
                  local bActive = false
                  pcall(function()
                    local bExploded = Grenade.bExploded == true
                    local bHidden = Grenade.bHidden or (Grenade.Mesh and Grenade.Mesh.bHidden)
                    if not bExploded and not bHidden then
                      bActive = true
                    end
                  end)
                  if bActive and 0 < ServerTime and (BombType == 602004 or BombType == 602002 or BombType == 602003) then
                    local Distance = PlayerCharacter:GetDistanceTo(Grenade) / 100
                    if Distance <= 100 then
                      local TextScale = math.max(0.6, 1.0 - Distance / 100)
                      local BombKey = tostring(Grenade)
                      local BombText = ""
                      local BombColor = {}
                      BombColor.R = 255
                      BombColor.G = 255
                      BombColor.B = 255
                      BombColor.A = 255
                      local DistanceText = tostring(math.floor(Distance))
                      if BombType == 602004 then
                        if not _G.NTH_BombTimers[BombKey] then
                          _G.NTH_BombTimers[BombKey] = ServerTime
                        end
                        local Elapsed = ServerTime - _G.NTH_BombTimers[BombKey]
                        local TimeLeft = 7.0 - Elapsed
                        if TimeLeft < 0 then
                          TimeLeft = 0.0
                        end
                        BombColor = (TimeLeft <= 2.0 and {R = 255, G = 0, B = 0, A = 255}) or {R = 255, G = 165, B = 0, A = 255}
                        local TimeText = tostring(math.floor(TimeLeft * 10) / 10)
                        BombText = "[BOM N\225\187\148]\n    [" .. TimeText .. "s]\n    [" .. DistanceText .. "m]"
                      elseif BombType == 602003 then
                        BombColor = {R = 255, G = 69, B = 0, A = 255}
                        BombText = "[BOM L\225\187\172A]\n     [" .. DistanceText .. "m]"
                      elseif BombType == 602002 then
                        BombColor = {R = 0, G = 255, B = 0, A = 255}
                        BombText = "[BOM KH\195\147I]\n     [" .. DistanceText .. "m]"
                      end
                      if BombText ~= "" then
                        HUD:AddDebugText(BombText, Grenade, 0.15, {X = 0, Y = 0, Z = 30}, {X = 0, Y = 0, Z = 30}, BombColor, true, false, true, nil, TextScale * 1.1, true)
                      end
                    end
                  end
                end
              end
              if 0 < ServerTime then
                for BombKey, BombTime in pairs(_G.NTH_BombTimers) do
                  if 10.0 < ServerTime - BombTime then
                    _G.NTH_BombTimers[BombKey] = nil
                  end
                end
              end
            end
          end
        end)
      end
      local bEspItem = _G.NTH_GetVal("ESP_ITEM") == 1
      local bScanPickUps = bEspItem and _G.NTH_GetVal("ESP_MORTAR") == 1
      local bScanAirDrops = bEspItem and _G.NTH_GetVal("ESP_AIRDROP") == 1
      if bScanPickUps or bScanAirDrops then
        pcall(function()
          local HUD = (PlayerController and PlayerController.MyHUD) or nil
          if slua.isValid(HUD) then
            if HUD.AddDebugText then
              local UKismetSystemLibrary = import("KismetSystemLibrary")
              if not _G.NTH_LootedItems then
                _G.NTH_LootedItems = {}
              end

              local function DrawActorMarks(Actors, MaxDistance, GetLabel, bIsAirDrop)
                if not Actors then
                  return
                end
                local MyLocation = nil
                pcall(function()
                  MyLocation = PlayerCharacter:K2_GetActorLocation()
                end)
                if not MyLocation then
                  return
                end
                for ActorIndex = 0, Actors:Num() - 1, 1 do
                  local Actor = Actors:Get(ActorIndex)
                  if slua.isValid(Actor) then
                    local bSkip = false
                    local ActorKey = tostring(Actor)
                    pcall(function()
                      if Actor:IsPendingKill() then
                        bSkip = true
                      end
                    end)
                    if not bSkip then
                      local Distance = 9999
                      local bHidden = false
                      pcall(function()
                        local ActorLocation = Actor:K2_GetActorLocation()
                        local DeltaX = MyLocation.X - ActorLocation.X
                        local DeltaY = MyLocation.Y - ActorLocation.Y
                        local DeltaZ = MyLocation.Z - ActorLocation.Z
                        Distance = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY + DeltaZ * DeltaZ) / 100.0
                        if (ActorLocation.X ~= 0 or ActorLocation.Y ~= 0) and ActorLocation.Z < -5000 then
                          bSkip = true
                        end
                        bHidden = Actor.bHidden or Actor.bIsHidden
                        if not bHidden then
                          if Actor.Mesh then
                            bHidden = Actor.Mesh.bHidden or false
                          end
                        end
                        if not bHidden then
                          if type(Actor.IsHidden) == "function" then
                            bHidden = Actor:IsHidden()
                          end
                        end
                      end)
                      if not bSkip then
                        if not bIsAirDrop then
                          if not bHidden then
                            _G.NTH_LootedItems[ActorKey] = nil
                          elseif Distance < 12.0 then
                            _G.NTH_LootedItems[ActorKey] = true
                          end
                          if _G.NTH_LootedItems[ActorKey] then
                            bSkip = true
                          end
                        elseif bHidden then
                          bSkip = true
                        end
                      end
                      if not bSkip and 0.1 < Distance and MaxDistance >= Distance then
                        local Label, LabelColor = GetLabel(Actor)
                        if Label then
                          local TextScale = math.max(0.6, 1.0 - Distance / MaxDistance)
                          local DebugText = "[" .. Label .. "]\n[" .. tostring(math.floor(Distance)) .. "m]"
                          HUD:AddDebugText(DebugText, Actor, 0.15, {X = 0, Y = 0, Z = 20}, {X = 0, Y = 0, Z = 20}, LabelColor, true, false, true, nil, TextScale, true)
                        end
                      end
                    end
                  end
                end
              end

              if bScanAirDrops then
                local AirDropClass = import("AirDropBoxActor")
                local OutActors = slua.Array(UEnums.EPropertyClass.Object, import("Actor"))
                local AirDrops = UGameplayStatics.GetAllActorsOfClass(PlayerCharacter, AirDropClass, OutActors)
                DrawActorMarks(AirDrops, 1000, function(Actor)
                  local Label = "H\195\146M TH\195\141NH"
                  local LabelColor = {}
                  LabelColor.R = 255
                  LabelColor.G = 0
                  LabelColor.B = 0
                  LabelColor.A = 255
                  return Label, LabelColor
                end, true)
              end
              if bScanPickUps then
                local PickUpClass = import("PickUpWrapperActor")
                local OutActors = slua.Array(UEnums.EPropertyClass.Object, import("Actor"))
                local PickUps = UGameplayStatics.GetAllActorsOfClass(PlayerCharacter, PickUpClass, OutActors)
                DrawActorMarks(PickUps, 150, function(Actor)
                  local ItemName = ""
                  pcall(function()
                    ItemName = UKismetSystemLibrary.GetClassDisplayName(Actor:GetClass()) or ""
                  end)
                  local Label = nil
                  local LabelColor = {}
                  LabelColor.R = 255
                  LabelColor.G = 255
                  LabelColor.B = 255
                  LabelColor.A = 255
                  if _G.NTH_GetVal("ESP_MORTAR") == 1 then
                    if string.find(ItemName, "10701100") or (string.find(ItemName, "Mortar") and not string.find(ItemName, "60mm") and not string.find(ItemName, "Shell") and not string.find(ItemName, "Ammo")) then
                      Label = "S\195\154NG C\225\187\144I"
                      LabelColor = {R = 255, G = 140, B = 0, A = 255}
                    elseif string.find(ItemName, "30700600") or string.find(ItemName, "60mm") or string.find(ItemName, "MortarShell") then
                      Label = "\196\144\225\186\160N C\225\187\144I"
                      LabelColor = {R = 255, G = 180, B = 80, A = 255}
                    end
                  end
                  if _G.NTH_GetVal("ESP_FLAREGUN") == 1 then
                    if string.find(ItemName, "Flare") or string.find(ItemName, "10600700") or string.find(ItemName, "10600900") or string.find(ItemName, "10601400") then
                      Label = "PH\195\129O S\195\129NG"
                      LabelColor = {R = 255, G = 50, B = 50, A = 255}
                    end
                  end
                  if _G.NTH_GetVal("ESP_SECRETKEY") == 1 then
                    if string.find(ItemName, "3000335") or string.find(ItemName, "Secret Room Key") or string.find(ItemName, "SecretKey") or string.find(ItemName, "CrimsonKey") or string.find(ItemName, "60411000") then
                      Label = "CH\195\140A KH\195\147A B\195\141 M\225\186\172T"
                      LabelColor = {R = 255, G = 215, B = 0, A = 255}
                    end
                  end
                  if _G.NTH_GetVal("ESP_NO") == 1 then
                    if string.find(ItemName, "10700100") or string.find(ItemName, "Crossbow") then
                      Label = "N\225\187\142"
                      LabelColor = {R = 0, G = 250, B = 154, A = 255}
                    elseif string.find(ItemName, "20500400") or string.find(ItemName, "Quiver (Crossbow)") then
                      Label = "\225\187\144NG T\195\138N N\225\187\142"
                      LabelColor = {R = 124, G = 252, B = 0, A = 255}
                    elseif string.find(ItemName, "30700100") or string.find(ItemName, "Bolt") then
                      Label = "M\197\168I T\195\138N N\225\187\142"
                      LabelColor = {R = 152, G = 251, B = 152, A = 255}
                    end
                  end
                  if _G.NTH_GetVal("ESP_SHOTGUN") == 1 then
                    if string.find(ItemName, "10400300") or string.find(ItemName, "S12K") then
                      Label = "S12K"
                      LabelColor = {R = 255, G = 20, B = 147, A = 255}
                    elseif string.find(ItemName, "10400400") or string.find(ItemName, "DBS") or string.find(ItemName, "DP12") then
                      Label = "DBS"
                      LabelColor = {R = 138, G = 43, B = 226, A = 255}
                    elseif string.find(ItemName, "10410100") or string.find(ItemName, "M1014") then
                      Label = "M1014"
                      LabelColor = {R = 0, G = 191, B = 255, A = 255}
                    end
                  end
                  return Label, LabelColor
                end, false)
              end
            end
          end
        end)
      end
    end
  end

  self:AddGameTimer(0.1, true, OnTick)
end

local MortarAim = {}
-- NOTE: upstream bug: the mod only ever defines _G.NTHMODNotify, so
-- _G.NTHMOD_NOTIFY is always nil and this banner never fires.
if _G.NTHMOD_NOTIFY then
  _G.NTHMOD_NOTIFY("[MortarAim] Script V30 loaded!")
end
local MortarGameplayData = nil
local bMortarDataReady = false
local bMortarActive = false
local MortarLockedTarget = nil
local MortarLastAimRot = nil
local MortarConfig = {
  AimInterval = 0.03,
  MaxRange = 600.0,
  FOV = 20.0,
  BaseGravity = 980.0,
  SwipeBreakAngle = 5.0
}
local function MortarNotify(Msg)
  local Text = "[NTHMOD] " .. tostring(Msg)
  print(Text)
  pcall(function()
    if _G.NTHMODNotify then
      _G.NTHMODNotify(Text)
      return
    end
    -- NOTE: upstream bug: the mod only ever defines _G.NTHMODNotify, so
    -- _G.NTHMOD_NOTIFY is always nil and this fallback branch is unreachable.
    if _G.NTHMOD_NOTIFY then
      _G.NTHMOD_NOTIFY(Text)
      return
    end
    local bOk, IngameTipsTools = pcall(require, "GameLua.Mod.BaseMod.Common.UI.InGameTipsTools")
    if bOk and IngameTipsTools then
      if IngameTipsTools.BattleNormalTips then
        IngameTipsTools.BattleNormalTips(Text, 2, 3)
      end
    end
  end)
end

local function MortarEnsureGameplayData()
  if bMortarDataReady then
    return true
  end
  local bOk, GameplayDataModule = pcall(require, "GameLua.GameCore.Data.GameplayData")
  if bOk and GameplayDataModule then
    MortarGameplayData = GameplayDataModule
  end
  if MortarGameplayData then
    bMortarDataReady = true
  end
  return bMortarDataReady
end

local function MortarNormalizeAngle(angle)
  while 180 < angle do
    angle = angle - 360
  end
  while angle < -180 do
    angle = angle + 360
  end
  return angle
end

local function MortarAtan2(y, x)
  if 0 < x then
    return math.atan(y / x)
  elseif x < 0 and 0 <= y then
    return math.atan(y / x) + math.pi
  elseif x < 0 and y < 0 then
    return math.atan(y / x) - math.pi
  elseif x == 0 and 0 < y then
    return math.pi / 2
  elseif x == 0 and y < 0 then
    return -math.pi / 2
  else
    return 0
  end
end

local function MortarIsEnemyTarget(uPawnA, uPawnB)
  if not (_G.slua.isValid(uPawnA) and _G.slua.isValid(uPawnB)) then
    return false
  end
  if uPawnA == uPawnB then
    return false
  end
  if uPawnA.PlayerKey ~= nil then
    if uPawnB.PlayerKey ~= nil then
      if uPawnA.PlayerKey == uPawnB.PlayerKey then
        return false
      end
    end
  end
  local TeamA = -1
  local TeamB = -2
  pcall(function()
    TeamA = uPawnA.TeamID or uPawnA.PlayerState and uPawnA.PlayerState.TeamNum or -1
    TeamB = uPawnB.TeamID or uPawnB.PlayerState and uPawnB.PlayerState.TeamNum or -2
  end)
  if TeamA == TeamB then
    return false
  end
  return true
end

local function MortarGetTargetLocation(uPawn, bUseHeadSocket)
  local TargetLoc = nil
  pcall(function()
    if bUseHeadSocket then
      if _G.slua.isValid(uPawn.Mesh) then
        TargetLoc = uPawn.Mesh:GetSocketLocation("head")
      end
    else
      TargetLoc = uPawn:K2_GetActorLocation()
      if TargetLoc then
        TargetLoc.Z = TargetLoc.Z - 85.0
        local RightVector = uPawn:GetActorRightVector()
        if RightVector then
          TargetLoc.X = TargetLoc.X + RightVector.X * 50.0
          TargetLoc.Y = TargetLoc.Y + RightVector.Y * 50.0
        end
      end
    end
  end)
  return TargetLoc
end

local function MortarIsPawnAlive(uPawn)
  if not _G.slua.isValid(uPawn) then
    return false
  end
  local bDead = false
  pcall(function()
    bDead = uPawn.bDead == true
  end)
  return not bDead
end

local function MortarSolvePitch(Dist, HeightDiff, Speed, Gravity)
  if Dist < 1.0 then
    Dist = 1.0
  end
  local v2 = Speed * Speed
  local v4 = v2 * v2
  local disc = v4 - Gravity * (Gravity * Dist * Dist + 2 * HeightDiff * v2)
  if disc < 0 then
    local FlatPitch = math.atan(v2 / (Gravity * Dist)) * (180.0 / math.pi)
    if FlatPitch < 45.0 then
      FlatPitch = 45.0
    end
    if 88.0 < FlatPitch then
      FlatPitch = 88.0
    end
    return FlatPitch, true
  end
  local Root = math.sqrt(disc)
  local Pitch = math.atan((v2 + Root) / (Gravity * Dist)) * (180.0 / math.pi)
  if Pitch < 45.0 then
    Pitch = 45.0
  end
  if 88.0 < Pitch then
    Pitch = 88.0
  end
  return Pitch, false
end

local function MortarPitchToControlPitch(Pitch)
  local ControlPitch = -60.0 + (Pitch - 45.0) * 2.0930232558139537
  if ControlPitch < -60.0 then
    ControlPitch = -60.0
  end
  if 30.0 < ControlPitch then
    ControlPitch = 30.0
  end
  return ControlPitch
end

local function MortarFindBestTarget(uSelfPawn, uController, bUseHeadSocket)
  local CameraManager = nil
  pcall(function()
    CameraManager = uController.PlayerCameraManager
  end)
  if not _G.slua.isValid(CameraManager) then
    return nil
  end
  local CameraLoc = CameraManager:GetCameraLocation()
  local CameraRot = CameraManager:GetCameraRotation()
  local Candidates = {}
  pcall(function()
    local PlayerCharacters = MortarGameplayData.GetAllPlayerCharacters()
    if PlayerCharacters then
      for _, uChar in pairs(PlayerCharacters) do
        if _G.slua.isValid(uChar) then
          Candidates[uChar] = true
        end
      end
    end
  end)
  pcall(function()
    local AllCharacters = MortarGameplayData.GetAllCharacters()
    if AllCharacters then
      for _, uChar in pairs(AllCharacters) do
        if _G.slua.isValid(uChar) then
          Candidates[uChar] = true
        end
      end
    end
  end)
  local BestTarget = nil
  local BestAngle = MortarConfig.FOV
  for uChar, _ in pairs(Candidates) do
    if MortarIsPawnAlive(uChar) then
      if MortarIsEnemyTarget(uSelfPawn, uChar) then
        local TargetLoc = MortarGetTargetLocation(uChar, bUseHeadSocket)
        if TargetLoc then
          local DeltaX = TargetLoc.X - CameraLoc.X
          local DeltaY = TargetLoc.Y - CameraLoc.Y
          local Dist2D = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY)
          local DistMeters = Dist2D / 100.0
          if DistMeters <= MortarConfig.MaxRange then
            local Yaw = MortarAtan2(DeltaY, DeltaX) * (180.0 / math.pi)
            local AngleDiff = math.abs(MortarNormalizeAngle(Yaw - CameraRot.Yaw))
            if AngleDiff <= MortarConfig.FOV and BestAngle > AngleDiff then
              BestAngle = AngleDiff
              BestTarget = uChar
            end
          end
        end
      end
    end
  end
  return BestTarget
end

local function MortarUpdateAim()
  if not MortarGameplayData then
    return
  end
  local uPlayerPawn = nil
  pcall(function()
    uPlayerPawn = MortarGameplayData.GetPlayerCharacter()
  end)
  if not _G.slua.isValid(uPlayerPawn) then
    return
  end
  local uPlayerController = nil
  pcall(function()
    uPlayerController = MortarGameplayData.GetPlayerController()
  end)
  if not _G.slua.isValid(uPlayerController) then
    return
  end
  local uCameraManager = nil
  pcall(function()
    uCameraManager = uPlayerController.PlayerCameraManager
  end)
  if not _G.slua.isValid(uCameraManager) then
    return
  end
  local uWeapon = nil
  pcall(function()
    uWeapon = uPlayerPawn.CurrentWeapon or uPlayerPawn:GetCurrentWeapon()
  end)
  if not _G.slua.isValid(uWeapon) then
    return
  end
  local nMortarState = 0
  local bMortarAiming = false
  pcall(function()
    nMortarState = uWeapon.MortarState
    bMortarAiming = uWeapon.MortarAimState == 1
  end)
  if nMortarState ~= 2 then
    return
  end
  local CameraRot = uCameraManager:GetCameraRotation()
  local SelfLoc = uPlayerPawn:K2_GetActorLocation()
  if MortarLockedTarget then
    if MortarLastAimRot then
      local SwipeDelta = math.abs(MortarNormalizeAngle(CameraRot.Yaw - MortarLastAimRot.Yaw))
      if SwipeDelta > MortarConfig.SwipeBreakAngle then
        MortarLockedTarget = nil
        MortarNotify("\196\144\195\163 \196\145\225\187\149i m\225\187\165c ti\195\170u")
      end
    end
  end
  if MortarLockedTarget then
    if MortarIsPawnAlive(MortarLockedTarget) and MortarIsEnemyTarget(uPlayerPawn, MortarLockedTarget) then
      local LockedLoc = MortarGetTargetLocation(MortarLockedTarget, bMortarAiming)
      if LockedLoc then
        local LockedDist = math.sqrt((LockedLoc.X - SelfLoc.X) ^ 2 + (LockedLoc.Y - SelfLoc.Y) ^ 2) / 100.0
        if LockedDist > MortarConfig.MaxRange then
          MortarLockedTarget = nil
        end
      else
        MortarLockedTarget = nil
      end
    else
      MortarLockedTarget = nil
    end
  end
  if not MortarLockedTarget then
    MortarLockedTarget = MortarFindBestTarget(uPlayerPawn, uPlayerController, bMortarAiming)
    if MortarLockedTarget then
      MortarNotify("\196\144\195\163 kh\195\179a m\225\187\165c ti\195\170u!")
    end
  end
  if not MortarLockedTarget then
    MortarLastAimRot = nil
    return
  end
  local AimLoc = MortarGetTargetLocation(MortarLockedTarget, bMortarAiming)
  local MuzzleLoc = nil
  pcall(function()
    MuzzleLoc = uWeapon:K2_GetActorLocation()
  end)
  local OriginX = MuzzleLoc and MuzzleLoc.X or SelfLoc.X
  local OriginY = MuzzleLoc and MuzzleLoc.Y or SelfLoc.Y
  local OriginZ = MuzzleLoc and MuzzleLoc.Z or SelfLoc.Z
  local DeltaX = AimLoc.X - OriginX
  local DeltaY = AimLoc.Y - OriginY
  local DeltaZ = AimLoc.Z - OriginZ
  local Dist2D = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY)
  local BulletSpeed = 9070.0
  local GravityScale = 2.8
  pcall(function()
    if uWeapon.GetBulletFireSpeedFromEntity then
      BulletSpeed = uWeapon:GetBulletFireSpeedFromEntity()
    else
      if bMortarAiming then
        BulletSpeed = 12520.0
      else
        BulletSpeed = 9070.0
      end
    end
    if _G.slua.isValid(uWeapon.ShootWeaponEntity) then
      if uWeapon.ShootWeaponEntity.LaunchGravityScale then
        GravityScale = uWeapon.ShootWeaponEntity.LaunchGravityScale
      end
    else
      if bMortarAiming then
        GravityScale = 4.0
      else
        GravityScale = 2.8
      end
    end
  end)
  local Gravity = MortarConfig.BaseGravity * GravityScale
  local Pitch, bOutOfRange = MortarSolvePitch(Dist2D, DeltaZ, BulletSpeed, Gravity)
  if bOutOfRange and not bMortarAiming then
    if not _G.NTH_LastWarnTime or 2.0 < os.clock() - _G.NTH_LastWarnTime then
      MortarNotify("\196\144\225\187\138CH QU\195\129 XA/CAO! B\225\186\164M N\195\154T NG\225\186\174M \196\144\225\187\130 B\225\186\174N CH\195\141NH X\195\129C!")
      _G.NTH_LastWarnTime = os.clock()
    end
  end
  local ControlPitch = MortarPitchToControlPitch(Pitch)
  local TargetYaw = MortarAtan2(DeltaY, DeltaX) * (180.0 / math.pi)
  local AimRot = FRotator(ControlPitch, TargetYaw, 0)
  pcall(function()
    if _G.slua.isValid(uCameraManager) then
      uCameraManager.bLimitViewPitch = false
      uCameraManager.bLimitViewYaw = false
      uCameraManager.ViewPitchMin = -89.9
      uCameraManager.ViewPitchMax = 89.9
    end
    uPlayerPawn:K2_SetActorRotation(FRotator(0, TargetYaw, 0), false)
    uPlayerPawn.BaseAimRotation = AimRot
    uPlayerController.ControlRotation = AimRot
    MortarLastAimRot = AimRot
  end)
end

local MortarTickCount = 0

local function MortarOnTick()
  if not _G._Authenticated_ then
    return
  end
  MortarTickCount = MortarTickCount + 1
  pcall(function()
    if not bMortarDataReady then
      MortarEnsureGameplayData()
      return
    end
    local uPlayerPawn = nil
    pcall(function()
      uPlayerPawn = MortarGameplayData.GetPlayerCharacter()
    end)
    if not _G.slua.isValid(uPlayerPawn) then
      return
    end
    local uWeapon = nil
    pcall(function()
      uWeapon = uPlayerPawn.CurrentWeapon or uPlayerPawn:GetCurrentWeapon()
    end)
    local bIsMortar = false
    pcall(function()
      bIsMortar = string.find(string.lower(tostring(uWeapon)), "mortar") ~= nil
    end)
    if not bIsMortar then
      if bMortarActive then
        bMortarActive = false
        MortarLockedTarget = nil
        MortarLastAimRot = nil
        MortarNotify("C\225\186\165t C\225\187\145i - Aim T\225\186\175t")
      end
      return
    end
    if not bMortarActive then
      bMortarActive = true
      MortarNotify("C\225\186\175m C\225\187\145i - Aim B\225\186\173t")
    end
    MortarUpdateAim()
  end)
end

local function MortarStart()
  local TimeTicker = package.loaded["common.time_ticker"] or require("common.time_ticker")
  if not (TimeTicker and TimeTicker.AddTimerLoop) then
    MortarNotify("[ERROR] AddTimerLoop not found!")
    return false
  end
  TimeTicker.AddTimerLoop(0, MortarOnTick, -1, MortarConfig.AimInterval)
  MortarNotify("[START] Mortar Auto Aim V30")
  return true
end

MortarAim.Start = MortarStart
MortarAim.Start()

if _G._Authenticated_ == nil then
  _G._Authenticated_ = true
end
if _G.NTH_HasShownLoginMsg == nil then
  _G.NTH_HasShownLoginMsg = false
end

function _G.NTHMODNotify(message)
  pcall(function()
    local bLocOk, loc_util = pcall(require, "common.loc_util")
    if bLocOk and loc_util then
      if loc_util.ShowNotice then
        loc_util.ShowNotice("Notice from telegram @nthmod: " .. message)
      end
    end
    local bTipsOk, InGameTipsTools = pcall(require, "GameLua.Mod.BaseMod.Common.UI.InGameTipsTools")
    if bTipsOk and InGameTipsTools then
      if InGameTipsTools.BattleNormalTips then
        InGameTipsTools.BattleNormalTips("Notice from telegram @nthmod: " .. message, 2, 3)
      end
    end
    local bDataOk, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if bDataOk and GameplayData then
      local PlayerController = GameplayData.GetPlayerController()
      if PlayerController then
        local bLibOk, STExtraBlueprintFunctionLibrary = pcall(import, "STExtraBlueprintFunctionLibrary")
        if bLibOk and STExtraBlueprintFunctionLibrary then
          local ChatComponent = STExtraBlueprintFunctionLibrary.GetChatComponentFromController(PlayerController)
          if ChatComponent then
            if ChatComponent.AddMsgInClient then
              ChatComponent:AddMsgInClient("Notice: " .. message .. ".")
            end
          end
        end
      end
    end
  end)
end

local function ShowDevNotice()
  pcall(function()
    local logic_common_msg_box = package.loaded["client.slua.logic.common.logic_common_msg_box"] or require("client.slua.logic.common.logic_common_msg_box")
    if logic_common_msg_box then
      if logic_common_msg_box.Show then
        logic_common_msg_box.Show(4, "xor", "MADE BY @NTHUY2004, TENCENT CAN'T FIX IT LMAO. :)", function()
          local UKismetSystemLibrary = import("KismetSystemLibrary")
          if UKismetSystemLibrary then
            UKismetSystemLibrary.LaunchURL("https://t.me/nthmod")
          end
        end, function()
        end, "TeLegram", "Cancel")
      end
    end
  end)
end

local PrevStartAdvancedSystems = CharacterBase.StartAdvancedSystems

function CharacterBase:StartAdvancedSystems()
  if PrevStartAdvancedSystems then
    PrevStartAdvancedSystems(self)
  end
  if not _G._Authenticated_ then
    return
  end
  self:AddGameTimer(1.0, true, function()
    if not slua.isValid(self.Object) then
      return
    end
    -- NOTE: upstream bug: MortarGameplayData stays nil until the mortar system initialises it; every other site uses the GameplayData module directly.
    local PlayerCharacter = MortarGameplayData.GetPlayerCharacter()
    if self.Object == PlayerCharacter then
      if not _G.NTH_HasShownGlobalAuthNotice then
        if self.Object.IsAlive then
          if self.Object:IsAlive() then
            _G.NTH_HasShownGlobalAuthNotice = true
            ShowDevNotice()
          end
        end
      end
    end
  end)
end



local MatchRadar = {
  TickCount = 0,
  TimerHandle = nil
}

local function MatchRadarStart()
  local time_ticker = package.loaded["common.time_ticker"] or require("common.time_ticker")
  if not time_ticker or not time_ticker.AddTimerLoop then
    return
  end
  if MatchRadar.TimerHandle then
    time_ticker.RemoveTimer(MatchRadar.TimerHandle)
    MatchRadar.TimerHandle = nil
  end
  MatchRadar.TickCount = 0
  MatchRadar.TimerHandle = time_ticker.AddTimerLoop(0, function()
    pcall(function()
      local http_manager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.http_manager)
      if not http_manager then
        return
      end
      local GameplayData = package.loaded["GameLua.GameCore.Data.GameplayData"] or require("GameLua.GameCore.Data.GameplayData")
      local PlayerCharacter = GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
      if not slua.isValid(PlayerCharacter) then
        return
      end
      local matchID = "LOBBY"
      pcall(function()
        if _G.CGameState then
          matchID = tostring(_G.CGameState.GameInstanceId or _G.CGameState.GameID or "LOBBY")
        end
      end)
      if matchID == "LOBBY" or matchID == "nil" then
        return
      end
      if _G.NTH_LastMatchID ~= matchID then
        _G.NTH_LastMatchID = matchID
        _G.NTH_ZeroTuatNotified = false
      end
      local uid = "unknown"
      if DataMgr then
        if DataMgr.roleData then
          if DataMgr.roleData.uid then
            uid = tostring(DataMgr.roleData.uid)
          end
        end
      else
        -- NOTE: upstream bug: _G._NTH_UK is never assigned anywhere, so this fallback can never produce a uid.
        if _G._NTH_UK then
          uid = tostring(_G._NTH_UK)
        end
      end
      local status = "alive"
      pcall(function()
        local health = PlayerCharacter.Health or (type(PlayerCharacter.GetHealth) == "function" and PlayerCharacter:GetHealth()) or 100
        if health <= 0 or (type(PlayerCharacter.IsDead) == "function" and PlayerCharacter:IsDead()) or PlayerCharacter.bIsDeadFlag then
          status = "dead"
        end
      end)
      local url = "https://server-lua-admin-new.onrender.com/match_radar"
      local headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded"
      }
      local function urlEncode(value)
        value = string.gsub(tostring(value), "([^%w %-%_%.%~])", function(char)
          return string.format("%%%02X", string.byte(char))
        end)
        return string.gsub(value, " ", "+")
      end
      local body = "match_id=" .. urlEncode(matchID) .. "&uid=" .. urlEncode(uid) .. "&status=" .. status
      http_manager:Post(url, headers, body, nil, function(bSuccess, response, responseCode, errorMsg)
        if bSuccess and response then
          local aliveCountText = string.match(response, "\"alive_count\":%s*(%d+)")
          local newDeathsText = string.match(response, "\"new_deaths\":%s*(%d+)")
          local modUidsText = string.match(response, "\"mod_uids\":%s*\"(.-)\"")
          if modUidsText then
            _G.NTH_ModUsersWhitelist = {}
            for modUid in string.gmatch(modUidsText, "([^,]+)") do
              _G.NTH_ModUsersWhitelist[modUid] = true
            end
          end
          local aliveCount = tonumber(aliveCountText) or 0
          local newDeaths = tonumber(newDeathsText) or 0
          local otherModUsers = aliveCount - 1
          if otherModUsers < 0 then
            otherModUsers = 0
          end
          if status == "dead" then
            if not _G.NTH_MyDeathReported then
              newDeaths = newDeaths - 1
              _G.NTH_MyDeathReported = true
            end
          end
          if newDeaths < 0 then
            newDeaths = 0
          end
          if 0 < newDeaths then
            for i = 1, newDeaths, 1 do
              if _G.NTHMODNotify then
                _G.NTHMODNotify("1 NTHMOD PLAYER HAS BEEN KILLED")
              end
            end
            if _G.NTHMODNotify then
              _G.NTHMODNotify(" " .. tostring(otherModUsers) .. " PLAYERS USING MOD")
            end
          end
          MatchRadar.TickCount = MatchRadar.TickCount + 1
          if 6 <= MatchRadar.TickCount then
            MatchRadar.TickCount = 0
            if otherModUsers == 0 then
              if not _G.NTH_ZeroTuatNotified then
                if _G.NTHMODNotify then
                  _G.NTHMODNotify("NO ONE USE NTHMOD IN THIS MATCH")
                end
                _G.NTH_ZeroTuatNotified = true
              end
            else
              _G.NTH_ZeroTuatNotified = false
              if _G.NTHMODNotify then
                _G.NTHMODNotify("HAVE " .. tostring(otherModUsers) .. " PLAYERS USING MOD")
              end
            end
          end
        end
      end, 5)
    end)
  end, -1, 10.0)
end

MatchRadar.Start = MatchRadarStart

local AutoMassReport = {
  Queue = {},
  IsScanning = false,
  TimerScan = nil,
  TimerProcess = nil
}
function AutoMassReport.Notify(message)
  if _G.NTHMODNotify then
    _G.NTHMODNotify(message)
  else
    print("[NTHMOD Report] " .. tostring(message))
  end
end

function AutoMassReport.ScanServer()
  if _G.NTH_GetVal("AUTO_MASS_REPORT") ~= 1 then
    return
  end
  pcall(function()
    local logic_complaint = package.loaded["client.logic.battle.logic_complaint"]
    if not logic_complaint then
      logic_complaint = require("client.logic.battle.logic_complaint")
    end
    if not logic_complaint then
      return
    end
    local battleID = tostring(logic_complaint.GetBattleID() or "LOBBY")
    if battleID == "LOBBY" or battleID == "0" then
      return
    end
    if battleID ~= AutoMassReport.CurrentMatchID then
      AutoMassReport.CurrentMatchID = battleID
      AutoMassReport.MatchStartTime = os.time()
      AutoMassReport.ReportedUIDs = {}
      AutoMassReport.Queue = {}
      AutoMassReport.Notify("Powered by @nthmod")
      return
    end
    local elapsedTime = os.time() - AutoMassReport.MatchStartTime
    if elapsedTime < 30 then
      if elapsedTime == 10 or elapsedTime == 20 then
        AutoMassReport.Notify(string.format("Starting auto-report (%d seconds)", 30 - elapsedTime))
      end
      return
    end
    local GameplayData = package.loaded["GameLua.GameCore.Data.GameplayData"]
    if not GameplayData then
      GameplayData = require("GameLua.GameCore.Data.GameplayData")
    end
    local playerCharacter = GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
    if not slua.isValid(playerCharacter) then
      return
    end
    local characters = {}
    if GameplayData.GetAllPlayerCharacters then
      characters = GameplayData.GetAllPlayerCharacters()
    elseif GameplayData.GameCharacters then
      for _, character in pairs(GameplayData.GameCharacters) do
        table.insert(characters, character)
      end
    end
    local addedCount = 0
    local skippedCount = 0
    for _, character in pairs(characters) do
      if slua.isValid(character) then
        if _G.IsEnemyTarget and _G.IsEnemyTarget(playerCharacter, character) then
          local name = ""
          local uid = 0
          local openid = ""
          pcall(function()
            name = character.PlayerName or (type(character.GetPlayerNameSafety) == "function" and character:GetPlayerNameSafety()) or ""
            local playerState = character.PlayerState or (type(character.GetPlayerStateSafety) == "function" and character:GetPlayerStateSafety())
            if slua.isValid(playerState) then
              uid = tonumber(playerState.UID) or tonumber(playerState.PlayerUID) or tonumber(character.PlayerKey) or 0
              openid = playerState.OpenID or ""
              if playerState.MLAIDisplayUID and 0 < playerState.MLAIDisplayUID then
                uid = tonumber(playerState.MLAIDisplayUID)
              end
            else
              uid = tonumber(character.PlayerKey) or 0
            end
          end)
          if name ~= "" and 0 < uid then
            local uidKey = tostring(uid)
            if not AutoMassReport.ReportedUIDs[uidKey] then
              local isWhitelisted = false
              if _G.NTH_ModUsersWhitelist and _G.NTH_ModUsersWhitelist[uidKey] then
                isWhitelisted = true
              end
              if isWhitelisted then
                skippedCount = skippedCount + 1
                AutoMassReport.ReportedUIDs[uidKey] = true
              else
                local alreadyQueued = false
                for _, entry in ipairs(AutoMassReport.Queue) do
                  if entry.uid == uid then
                    alreadyQueued = true
                    break
                  end
                end
                if not alreadyQueued then
                  table.insert(AutoMassReport.Queue, {
                    name = name,
                    uid = uid,
                    openid = openid
                  })
                  addedCount = addedCount + 1
                end
              end
            end
          end
        end
      end
    end
    if 0 < addedCount then
      local message = string.format("Added %d enemies to wait-list (total: %d)", addedCount, #AutoMassReport.Queue)
      if 0 < skippedCount then
        message = message .. string.format(" | Skipped %d VIP NTHMOD", skippedCount)
      end
      AutoMassReport.Notify(message)
    end
  end)
end

function AutoMassReport.ProcessQueue()
  if _G.NTH_GetVal("AUTO_MASS_REPORT") ~= 1 then
    AutoMassReport.Queue = {}
    return
  end
  if #AutoMassReport.Queue == 0 then
    return
  end
  if os.time() - AutoMassReport.MatchStartTime < 30 then
    return
  end
  pcall(function()
    local target = table.remove(AutoMassReport.Queue, 1)
    local logic_complaint = package.loaded["client.logic.battle.logic_complaint"]
    if not logic_complaint then
      logic_complaint = require("client.logic.battle.logic_complaint")
    end
    if not logic_complaint then
      return
    end
    local uidKey = tostring(target.uid)
    if not AutoMassReport.ReportedUIDs[uidKey] then
      if not logic_complaint.IsAlreadyReported(target.name, logic_complaint.GetBattleID()) then
        logic_complaint.Submit(target.name, false, false, {
          4
        }, "Auto Mass Report NTHMOD", 1, {
          1,
          3,
          9
        }, {}, "", logic_complaint.GetBattleID(), 18, target.uid, target.openid, "", {}, 0, 0, 0, 0, 0, 0, false, 0, nil, "MassReportQueue", target.uid, false, 0)
        AutoMassReport.ReportedUIDs[uidKey] = true
        -- NOTE: upstream bug: "%d" is fed target.name, a string, so string.format raises
        -- and the enclosing pcall swallows the rest of this closure. The report is still
        -- submitted and cached above; only the notification is lost.
        AutoMassReport.Notify(string.format("Reported %d enemies (Remaining %d targets)", target.name, #AutoMassReport.Queue))
      end
    end
  end)
end

function AutoMassReport.Start()
  local timeTicker = package.loaded["common.time_ticker"]
  if not timeTicker then
    timeTicker = require("common.time_ticker")
  end
  if not timeTicker or not timeTicker.AddTimerLoop then
    return
  end
  if AutoMassReport.TimerScan then
    timeTicker.RemoveTimer(AutoMassReport.TimerScan)
  end
  if AutoMassReport.TimerProcess then
    timeTicker.RemoveTimer(AutoMassReport.TimerProcess)
  end
  AutoMassReport.TimerScan = timeTicker.AddTimerLoop(0, AutoMassReport.ScanServer, -1, 30.0)
  AutoMassReport.TimerProcess = timeTicker.AddTimerLoop(0, AutoMassReport.ProcessQueue, -1, 10.0)
end

local AutoReportKiller = {
  ReportedCache = {},
  MatchID = "",
  TimerHandle = nil
}

function AutoReportKiller.CheckAndReport()
  if _G.NTH_GetVal("AUTO_REPORT_KILL") ~= 1 then
    return
  end
  pcall(function()
    local logic_complaint = package.loaded["client.logic.battle.logic_complaint"]
    if not logic_complaint then
      logic_complaint = require("client.logic.battle.logic_complaint")
    end
    if not logic_complaint then
      return
    end
    local battleID = tostring(logic_complaint.GetBattleID() or "LOBBY")
    if battleID == "LOBBY" or battleID == "0" then
      return
    end
    if battleID ~= AutoReportKiller.MatchID then
      AutoReportKiller.MatchID = battleID
      AutoReportKiller.ReportedCache = {}
      if _G.NTHMODNotify then
        _G.NTHMODNotify("New match started. Auto-report working normally...")
      end
    end
    local SubsystemMgr = _G.SubsystemMgr
    if not SubsystemMgr then
      return
    end
    local reportPlayerSubsystem = SubsystemMgr:Get("ClientReportPlayerSubsystem")
    if not reportPlayerSubsystem then
      return
    end
    local ReportPlayerUtils = package.loaded["GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils"]
    if not ReportPlayerUtils then
      ReportPlayerUtils = require("GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils")
    end
    if not ReportPlayerUtils then
      return
    end
    local S_NAME = ReportPlayerUtils.S_NAME
    local S_UID = ReportPlayerUtils.S_UID
    local S_OPEN_ID = ReportPlayerUtils.S_OPEN_ID
    local fatalDamagerMapTrue = reportPlayerSubsystem:GetFatalDamagerMap(true)
    if not fatalDamagerMapTrue then
      fatalDamagerMapTrue = {}
    end
    local fatalDamagerMapFalse = reportPlayerSubsystem:GetFatalDamagerMap(false)
    if not fatalDamagerMapFalse then
      fatalDamagerMapFalse = {}
    end
    local damagerList = {}
    for _, damagerInfo in pairs(fatalDamagerMapTrue) do
      table.insert(damagerList, damagerInfo)
    end
    for _, damagerInfo in pairs(fatalDamagerMapFalse) do
      table.insert(damagerList, damagerInfo)
    end
    for _, damagerInfo in pairs(damagerList) do
      if damagerInfo and damagerInfo[S_NAME] and damagerInfo[S_UID] then
        local name = damagerInfo[S_NAME]
        local uid = tonumber(damagerInfo[S_UID])
        local openid = damagerInfo[S_OPEN_ID] or ""
        local uidKey = tostring(uid)
        if not AutoReportKiller.ReportedCache[uidKey] then
          AutoReportKiller.ReportedCache[uidKey] = true
          if _G.NTH_ModUsersWhitelist and _G.NTH_ModUsersWhitelist[uidKey] then
            if _G.NTHMODNotify then
              _G.NTHMODNotify("\196\144\225\186\160O H\225\187\174U " .. name .. " KILLED YOU! SKIP REPORT")
            end
          else
            logic_complaint.Submit(name, false, false, {
              4
            }, "Auto Report Killer", 1, {
              1,
              3,
              9
            }, {}, "", battleID, 18, uid, openid, "", {}, 0, 0, 0, 0, 0, 0, false, 0, nil, "NTHMOD_KillerReport", uid, false, 0)
            if _G.NTHMODNotify then
              _G.NTHMODNotify("YOU HAVE BEEN KILLED, REPORTED: " .. name)
            end
          end
        end
      end
    end
  end)
end

function AutoReportKiller.Start()
  local timeTicker = package.loaded["common.time_ticker"]
  if not timeTicker then
    timeTicker = require("common.time_ticker")
  end
  if not timeTicker or not timeTicker.AddTimerLoop then
    return
  end
  if AutoReportKiller.TimerHandle then
    timeTicker.RemoveTimer(AutoReportKiller.TimerHandle)
  end
  AutoReportKiller.TimerHandle = timeTicker.AddTimerLoop(0, AutoReportKiller.CheckAndReport, -1, 1.0)
end

local function StartModSystems()
  pcall(function()
    if _G.InitializeAimTouch then
      _G.InitializeAimTouch()
    end
    if MatchRadar and MatchRadar.Start then
      MatchRadar.Start()
    end
    -- NOTE: upstream bug: the initialiser is invoked inside its own guard. It returns
    -- nil, so the body is dead; the call in the condition is what actually runs it.
    if _G.InitNTHESPVIP() then
      _G.InitNTHESPVIP()
    end
    if _G.InitNTHModMenuTab then
      _G.InitNTHModMenuTab()
    end
    if AutoMassReport and AutoMassReport.Start then
      AutoMassReport.Start()
    end
    if AutoReportKiller and AutoReportKiller.Start then
      AutoReportKiller.Start()
    end
  end)
  local GameplayData = package.loaded["GameLua.GameCore.Data.GameplayData"]
  if not GameplayData then
    GameplayData = require("GameLua.GameCore.Data.GameplayData")
  end
  if not GameplayData then
    return
  end
  pcall(function()
    local playerCharacter = GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
    if slua.isValid(playerCharacter) then
      if CharacterBase.StartAdvancedSystems then
        playerCharacter.StartAdvancedSystems = CharacterBase.StartAdvancedSystems
      end
      if playerCharacter.bHasShownExpiredNotice == nil then
        playerCharacter.bHasShownExpiredNotice = false
        playerCharacter.bHasShownDevNotice = false
        playerCharacter.bIsDeadFlag = false
        playerCharacter.NTH_NativeESP_Ready = false
      end
      if type(playerCharacter.StartAdvancedSystems) == "function" then
        pcall(function()
          playerCharacter:StartAdvancedSystems()
        end)
      end
    end
  end)
end




local class = require("class")
local CActorBase = require("GameLua.Mod.BaseMod.Common.Core.ActorBase")
local CCharacterBase = class(CActorBase, nil, CharacterBase)
return require("combine_class").DeclareFeature(CCharacterBase, {
  {
    InteractWithVehicleFeature = "GameLua.GameCore.Feature.InteractWithVehicleFeature"
  },
  {
    PetFormCharFeature = "GameLua.Activity.Commercialize.GamePlay.Pet.PetFormCharFeature"
  },
  {
    CoopEmoteCharFeature = "GameLua.Activity.Commercialize.GamePlay.CoopEmote.CoopEmoteCharFeature"
  },
  {
    WeaponKillCounterFeature = "GameLua.Activity.Commercialize.GamePlay.WeaponKillCounter.WeaponKillCounterFeature"
  },
  {
    PetExhibitFeature = "GameLua.Activity.Commercialize.GamePlay.Pet.PetExhibitFeature"
  }
}, "CharacterBase")
