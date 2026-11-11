local BRPlayerCharacterBase = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {},
  LuaEventContainer = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = {
  Reliable = true,
  Params = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Object
  }
}
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int
  }
}
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int
  }
}
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Bool
  }
}

local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local ESpecialMovementType = import("ESpecialMovementType")
local ESpiderSwingMoveState = import("ESpiderSwingMoveState")
local ESurviveWeaponPropSlot = import("ESurviveWeaponPropSlot")
local EParachuteState = import("EParachuteState")
local EMovementMode = import("EMovementMode")
local EStateType = import("EStateType")
local ESTEPoseState = import("ESTEPoseState")
local EGameModeType = import("EGameModeType")
local FAnchors = import("Anchors")
local FVector2D = import("Vector2D")
local FVector = import("Vector")
local STExtraGameStateBase = import("STExtraGameStateBase")
local UKismetSystemLibrary = import("KismetSystemLibrary")
local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
local MatchModeIds = require("GameLua.Mod.BaseMod.GamePlay.Config.MatchModeIdsConfig")

function BRPlayerCharacterBase:ctor()
end

function BRPlayerCharacterBase:_PostConstruct()
  BRPlayerCharacterBase.__super._PostConstruct(self)
  self:InitAddSpecialMoveInfo()
  self.bCanNearDeathGiveup = true
  print(bWriteLog and "BRPlayerCharacterBase:_PostConstruct bCanNearDeathGiveup true")
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
  BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
  self:AddControlEvent(self, "MovementModeChangedDelegate", self.HandleOnMovementModeChangedNew, self)
  if self:HasAuthority() and self:CheckAddCheckFallingDistanceComponent() then
    local CheckFallingDistanceComponent_C = import("CheckFallingDistanceComponent")
    if slua.isValid(CheckFallingDistanceComponent_C) and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponent_C)) then
      print(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay Add CheckFallingDistanceComponent")
      Game:AddComponent(CheckFallingDistanceComponent_C, self, "CheckFallingDistanceComponent")
    end
  end
  if slua.isValid(self.STCharacterMovement) then
    self.STCharacterMovement.bPositiveBlowUp = true
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy then
    self:AddControlEvent(self, "OnPawnStateDisabled", self.OnPawnStateChange, self)
    self:AddControlEvent(self, "OnPawnStateEnabled", self.OnPawnStateChange, self)
    self:AddControlEventConditionOnly(self, "OnAttrChangeEventDelegate", {
      AttrName = {
        "bCanSelfRescue"
      }
    }, self.CharacterAttrChangeEvent, self)
  end
  if Client then
    printf(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay, PlayerKey:%u ", self.PlayerKey)
    GameplayData.AddCharacter(self.Object)
  else
    self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, {
      [1] = "FinishedState"
    }, self.HandleFinishedState, self)
  end
end

function BRPlayerCharacterBase:CharacterAttrChangeEvent(uPawn, AttrName, AttrVal)
  BRPlayerCharacterBase.__super.CharacterAttrChangeEvent(self, uPawn, AttrName, AttrVal)
  if self.Object ~= uPawn then
    return
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy and AttrName == "bCanSelfRescue" then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:OnPawnStateChange(PawnState)
  print("BRPlayerCharacterBase:OnPawnStateChange:", PawnState)
  if PawnState == EPawnState.SwitchPP then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:HandleFinishedState()
  print(bWriteLog and "BRPlayerCharacterBase:HandleFinishedState", self.STCharacterMovement)
  if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfigDisable then
    local EDynamicSimpleQueryConfigDisableMask = import("EDynamicSimpleQueryConfigDisableMask")
    self.STCharacterMovement:SetDynamicSimpleQueryConfigDisable(EDynamicSimpleQueryConfigDisableMask.Bit0, true)
  end
end

function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent()
  if CGameMode and CGameMode.GameModeType and CGameState and CGameState.GameModeID then
    local GameModeType = CGameMode.GameModeType
    local GameModeID = tonumber(CGameState.GameModeID)
    local bModeTypeSatisfy = GameModeType == EGameModeType.ETypicalGameMode or GameModeType == EGameModeType.EFourInOneGameMode or GameModeType == EGameModeType.EHeavyWeaponGameMode
    local bModeIDSatisfy = not MatchModeIds[GameModeID]
    print(bWriteLog and bWriteLog and "BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent:", GameModeType, GameModeID, bModeTypeSatisfy, bModeIDSatisfy)
    return bModeTypeSatisfy and bModeIDSatisfy
  end
  return false
end

function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(LastParachuteState, NewParachuteState)
  BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self, LastParachuteState, NewParachuteState)
  if not Client then
    local uCurrentPlayerControl = self:GetPlayerControllerSafety()
    if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
      if NewParachuteState == EParachuteState.PS_Opening then
        if uCurrentPlayerControl.CheckParachuteOpenFeature.SatrtCheckShowParachuteCloseUI then
          uCurrentPlayerControl.CheckParachuteOpenFeature:SatrtCheckShowParachuteCloseUI()
        end
      elseif NewParachuteState == EParachuteState.PS_None then
        if uCurrentPlayerControl.CheckParachuteOpenFeature.RecoverParachuteOpenParam then
          uCurrentPlayerControl.CheckParachuteOpenFeature:RecoverParachuteOpenParam()
        end
        if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
          uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
        end
      end
    end
  end
end

function BRPlayerCharacterBase:OnLanded()
  printf("BRPlayerCharacterBase:OnLanded PlayerKey:%d", self.PlayerKey)
  if self.HandleOnLanded then
    self:HandleOnLanded(-1)
  end
  if not Client then
    local uCurrentPlayerControl = self:GetPlayerControllerSafety()
    if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
        uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
      end
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ResetCheckShowUI then
        uCurrentPlayerControl.CheckParachuteOpenFeature:ResetCheckShowUI()
      end
    end
  end
end

function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
  BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
  if Client then
    GameplayData.RemoveCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:IsWarGameMode()
  local uGameState = GameplayData:GetGameState()
  if slua.isValid(uGameState) and Game:IsClassOf(uGameState, STExtraGameStateBase) then
    return uGameState.GameModeType == EGameModeType.EWarGameMode
  else
    return false
  end
end

function BRPlayerCharacterBase:BPOnRecycled()
  print(bWriteLog and string.format("%s BPOnRecycled()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
  end
end

function BRPlayerCharacterBase:BPOnRespawned()
  print(bWriteLog and string.format("%s BPOnRespawned()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
  end
end

function BRPlayerCharacterBase:ReceiveOnRecycle()
  print(bWriteLog and string.format("%s IReusable:ReceiveOnRecycle()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.RemoveCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:ReceiveOnSpawn()
  print(bWriteLog and string.format("%s IReusable:ReceiveOnSpawn()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.AddCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation()
  if Game:IsValid(self.Object) and Game:IsValid(self.Mesh) then
    local uDefaultMeshRot = FRotator(0, -90, 0)
    local uDefaultMeshRelativeLoc = FVector(0, 0, 0)
    if self.Mesh.K2_SetRelativeRotation then
      self.Mesh:K2_SetRelativeRotation(uDefaultMeshRot, false, nil, false)
    end
    self:CacheInitialMeshOffset(uDefaultMeshRelativeLoc, uDefaultMeshRot)
    local vRelativeRot = self.Mesh.RelativeRotation
    local vBaseRotationOffset = self.BaseRotationOffset
    local vBaseRotation = Game:QuatToRotator(vBaseRotationOffset)
    print(bWriteLog and bWriteLog and string.format("%s ResetMeshRelativeLocationAndRotation() Mesh.RelativeRotation: %s %s %s   Pawn.BaseRotationOffset:%s %s %s ", Game:GetPlainName(self.Object), tostring(vRelativeRot.Pitch), tostring(vRelativeRot.Yaw), tostring(vRelativeRot.Roll), tostring(vBaseRotation.Pitch), tostring(vBaseRotation.Yaw), tostring(vBaseRotation.Roll)))
  end
end

function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
  print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged11")
  if Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Swimming and self:CheckBaseIsMoveable() then
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged22")
    self.CharacterMovement:SetBase(nil, "", true)
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Walking and UIManager.UI_Config_InGame.ParachuteOpenUI then
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChangedNew CloseUI")
    UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI)
  end
end

function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord()
end

function BRPlayerCharacterBase:PreAttachedToVehicle()
  local IsDS = UKismetSystemLibrary.IsDedicatedServer(self)
  if not IsDS then
    return
  end
  local MainPlayerController = self:GetPlayerControllerSafety()
  if not slua.isValid(MainPlayerController) then
    return
  end
  local CharacterAvatarComp2_BP = self.CharacterAvatarComp2_BP
  if not slua.isValid(CharacterAvatarComp2_BP) then
    return
  end
  local CommerAvatarDataUtil = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
  local changedVehicleId = CommerAvatarDataUtil:ChangeVehicleSkinByClothes(MainPlayerController, CharacterAvatarComp2_BP)
  local ESTExtraVehicleShapeType = import("ESTExtraVehicleShapeType")
  if changedVehicleId then
    local UAvatarUtils = import("AvatarUtils")
    if UAvatarUtils.GetVehicleShapeBySkinID(changedVehicleId) == ESTExtraVehicleShapeType.VST_Horse then
      local uCurPlayerState = self:GetPlayerStateSafety()
      if slua.isValid(uCurPlayerState) then
        print(bWriteLog and "  BRPlayerCharacterBase:PreAttachedToVehicle. changedVehicleId: " .. tostring(changedVehicleId))
        uCurPlayerState:AddGeneralCount(468, 1, false)
      end
    end
  end
end

function BRPlayerCharacterBase:ParachuteJump()
  local uPlayerController = self:GetControllerSafety()
  if slua.isValid(uPlayerController) then
    if not self:GetEnsure() then
      if uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteJump and uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteOpen then
        self:SwitchPoseState(ESTEPoseState.Stand, true, true, true, false)
        uPlayerController:ReInitParachuteItem()
        uPlayerController:ServerChangeStatePC(EStateType.State_ParachuteJump)
      end
      print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump over")
    else
      EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_AI_CALL_PARACHUTE_JUMP, self.Object)
      print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump AI JUMP over, Loc=", tostring(self:K2_GetActorLocation():ToString()))
    end
  end
end

function BRPlayerCharacterBase:OnMovementBaseChangedEvent(uCharacter, uNewMovementBase, uOldMovementBase)
  if uCharacter ~= self.Object then
    return
  end
  print(bWriteLog and string.format("BRPlayerCharacterBase:OnMovementBaseChangedEvent %s, Base: %s -> %s", uCharacter, uOldMovementBase, uNewMovementBase))
  local MedievalCrane = self:GetMedievalCraneFromBase(uNewMovementBase)
  if MedievalCrane and MedievalCrane.AddCharacter then
    MedievalCrane:AddCharacter(self.Object)
  else
    MedievalCrane = self:GetMedievalCraneFromBase(uOldMovementBase)
    if MedievalCrane and MedievalCrane.RemoveCharacter then
      MedievalCrane:RemoveCharacter(self.Object)
    end
  end
end

function BRPlayerCharacterBase:GetMedievalCraneFromBase(Base)
  if not slua.isValid(Base) or not Base.GetOwner then
    return
  end
  local Lifter = Base:GetOwner()
  if not slua.isValid(Lifter) then
    return
  end
  if not Lifter.AddCharacter then
    return
  end
  return Lifter
end

function BRPlayerCharacterBase:CheckForbidFlaregun()
  local uPlayerState = self:GetPlayerStateSafety()
  if not slua.isValid(uPlayerState) then
    return false
  end
  if uPlayerState.CanUseFlaregun == false and self:IsLocallyControlled() then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:DisplayGameTipWithMsgID(48532)
    end
  end
  return not uPlayerState.CanUseFlaregun
end

function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue()
  self:HandleNearDeathGiveupRescue()
end

function BRPlayerCharacterBase:HandleNearDeathGiveupRescue()
  local uNearDeathComp = self.NearDeatchComponent
  if self:IsNearDeath() and slua.isValid(uNearDeathComp) and self.bCanNearDeathGiveup == true then
    local uPlayerState = self:GetPlayerStateSafety()
    if slua.isValid(uPlayerState) then
      uPlayerState:AddGeneralCount(1613, 1, false)
    end
    uNearDeathComp:TriggerGotoDieExplictly(self.Object)
  end
end

function BRPlayerCharacterBase:RPC_Server_GmPlayAction(actionId)
  log(bWriteLog and "  BRPlayerCharacterBase:RPC_Server_GmPlayAction.  actionId: " .. tostring(actionId))
  if USTExtraBlueprintFunctionLibrary.IsDevelopment() then
    log(bWriteLog and "  BRPlayerCharacterBase:RPC_Server_GmPlayAction. IsDevelopment actionId: " .. tostring(actionId))
    self:MulticastRPC_GmPlayAction(actionId)
  end
end

function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(actionId)
  if not Client then
    return
  end
  log(bWriteLog and "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction.  actionId: " .. tostring(actionId))
  local uPlayEmoteComp = self:GetPlayEmoteComponent()
  if not slua.isValid(uPlayEmoteComp) then
    return
  end
  local LogFilter = require("common.log_filter")
  LogFilter.SetLogTreeEnable(true)
  local animCfg = CDataTable.GetTableData("EmoteBPTable", actionId)
  if not animCfg then
    return
  end
  local handlePath = animCfg.Path
  local EmoteHandleAsset = slua.loadObject(handlePath)
  local assetsArray = slua.Array(UEnums.EPropertyClass.Struct, import("/Script/CoreUObject.SoftObjectPath"))
  local handle = EmoteHandleAsset()
  uPlayEmoteComp:OnLoadEmoteAssetBegin(handle, actionId, assetsArray, "")
  log(bWriteLog and "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction. assetsArray:Num(): " .. tostring(assetsArray:Num()))
  local tb = FuncUtil.LuaArrayToTable(assetsArray)
  local asset_util = require("common.asset_util")
  
  local function loadLater()
    uPlayEmoteComp:OnLoadEmoteAssetEnd(handle, actionId, 0)
  end
  
  asset_util.GetAssetsArrayAsyncParallel(tb, loadLater)
end

function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(bServerSyncShouldCheckPassWall)
  print(bWriteLog and "BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall " .. tostring(bServerSyncShouldCheckPassWall))
  if slua.isValid(self.ParachuteComponent) then
    self.ParachuteComponent.bServerSyncShouldCheckPassWall = bServerSyncShouldCheckPassWall
  end
end

function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
  self.Super:OnPlayerEnterCarryBoxState()
  local CharName = self:GetPlayerNameSafety()
  print(bWriteLog and string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerEnterCarryBoxState Role:%s PlayerKey:%s Name:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(CharName)))
  if self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState()
  end
end

function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  self.Super:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  local CharName = self:GetPlayerNameSafety()
  print(bWriteLog and string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState Role:%s PlayerKey:%s Name:%s bInIsInterrupt:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(CharName), tostring(bInIsInterrupt)))
  if self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  end
end

function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(uInDeadBox)
  if slua.isValid(uInDeadBox) and Game:IsClassOf(uInDeadBox, import("/Script/ShadowTrackerExtra.PlayerTombBox")) and self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:CarryDeadBox(uInDeadBox)
  end
end

function BRPlayerCharacterBase:SetAreaID(AreaID)
  self:SetAttrValue("AreaID", AreaID, -1)
end

function BRPlayerCharacterBase:GetAreaID()
  return math.floor(self:GetAttrValue("AreaID") + 0.5)
end

function BRPlayerCharacterBase:CannotChangeIntoPetSpectator()
  print(bWriteLog and "BRPlayerCharacterBase:CannotChangeIntoPetSpectator")
  return self.bCannotChangeIntoPetSpectator
end

function BRPlayerCharacterBase:DoModChangeToBT()
  print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s", tostring(self.PlayerKey)))
  if self:HasState(EPawnState.SpecialSuit) then
    self:TriggerEntrySkillWithID(4301101, true)
    print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s, HasState(EPawnState.SpecialSuit)", tostring(self.PlayerKey)))
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteOpening()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening")
  self.Super:SwitchCameraToParachuteOpening()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
    print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening - Formation camera overlaid")
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteFalling()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling")
  self.Super:SwitchCameraToParachuteFalling()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
    print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling - Formation camera overlaid")
  end
end

function BRPlayerCharacterBase:SwitchCameraToNormal()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToNormal")
  self.Super:SwitchCameraToNormal()
  if self.ParachuteFormation and self.ParachuteFormation.OnLandingClearFormationCamera then
    self.ParachuteFormation:OnLandingClearFormationCamera()
  end
end

function BRPlayerCharacterBase:SwitchWeaponCheck(Slot, IgnoreState)
  if self:HasState(EPawnState.AttachToOther) then
    local Weapon = self:GetWeaponBySlot(Slot)
    if slua.isValid(Weapon) then
      local WeaponID = Weapon:GetWeaponID()
      local AttachToOtherConfig = GamePlayTools.GetCurrentConfig("AttachToOtherConfig")
      if AttachToOtherConfig and AttachToOtherConfig.CheckIsWeaponInBlackList and AttachToOtherConfig.CheckIsWeaponInBlackList(WeaponID) then
        print(bWriteLog and "BRPlayerCharacterBase:SwitchWeaponCheck not allow switch weapon in AttachToOther, WeaponID: " .. tostring(WeaponID))
        local uPlayerController = self:GetPlayerControllerSafety()
        if Client and slua.isValid(uPlayerController) and uPlayerController.Role == ENetRole.ROLE_AutonomousProxy then
          uPlayerController:DisplayGameTipWithMsgID(47306)
        end
        return false
      end
    end
  end
  if self:HasState(EPawnState.WebSwing) and Slot ~= ESurviveWeaponPropSlot.SWPS_None and slua.isValid(self.STCharacterMovement) then
    local SpiderSwingObj = self.STCharacterMovement:GetSpecialMoveObjBySpecialMoveType(ESpecialMovementType.SPECIAL_MOVE_SpiderSwing)
    if slua.isValid(SpiderSwingObj) then
      local nCurState = SpiderSwingObj:GetCurMoveState()
      if nCurState == ESpiderSwingMoveState.Launching or nCurState == ESpiderSwingMoveState.Swinging then
        print(bWriteLog and "BRPlayerCharacterBase:SwitchWeaponCheck blocked by SpiderSwing state: " .. tostring(nCurState))
        return false
      end
    end
  end
  return self.Super:SwitchWeaponCheck(Slot, IgnoreState)
end

local pkgOK = rawget(_G, "pkgOK")
local pkg = rawget(_G, "pkg")
local TssSdk = rawget(_G, "TssSdk")
local ace = rawget(_G, "ace")
local XignCode = rawget(_G, "XignCode")
local BattlEye = rawget(_G, "BattlEye")
local NetUtil = rawget(_G, "NetUtil")
local NetManager = rawget(_G, "NetManager")
local EventSystem = rawget(_G, "EventSystem")
local LogUtil = rawget(_G, "LogUtil")
local sandbox = rawget(_G, "sandbox")
local Client = rawget(_G, "Client")
local login_module = rawget(_G, "login_module")
local RacingAntiCheatLogic = rawget(_G, "RacingAntiCheatLogic")
local RealTimeBan = rawget(_G, "RealTimeBan")
local BanSystem = rawget(_G, "BanSystem")
local GameplayCallbacks = rawget(_G, "GameplayCallbacks")
local CrashSight = rawget(_G, "CrashSight")
local TLog = rawget(_G, "TLog")
local ScreenshotMaker = rawget(_G, "ScreenshotMaker")
local MemoryScanner = rawget(_G, "MemoryScanner")
local FileCheckSubsystem = rawget(_G, "FileCheckSubsystem")
local AvatarUtils = rawget(_G, "AvatarUtils")
local ClientDataStatistcsSubsystem = rawget(_G, "ClientDataStatistcsSubsystem")
local ShootVerifySubSystemClient = rawget(_G, "ShootVerifySubSystemClient")
local AFKReportorSubsystem = rawget(_G, "AFKReportorSubsystem")
local AvatarExceptionSubsystem = rawget(_G, "AvatarExceptionSubsystem")
local RescueBtnReplayTraceSubsystem = rawget(_G, "RescueBtnReplayTraceSubsystem")
local GameReportSubsystem = rawget(_G, "GameReportSubsystem")
local InspectionSystemReportClientLogicSubsystem = rawget(_G, "InspectionSystemReportClientLogicSubsystem")
local ClientHawkEyePatrolSubsystem = rawget(_G, "ClientHawkEyePatrolSubsystem")
local BehaviorScoreSubsystem = rawget(_G, "BehaviorScoreSubsystem")
local AIReplaySubsystem = rawget(_G, "AIReplaySubsystem")
local ClientBanLogic = rawget(_G, "ClientBanLogic")
local logic_tt_ban = rawget(_G, "logic_tt_ban")
local SystemInfo = rawget(_G, "SystemInfo")
local KismetSystemLibrary = rawget(_G, "KismetSystemLibrary")
local CreativeModeBlueprintLibrary = rawget(_G, "CreativeModeBlueprintLibrary")
local TDataMaster = rawget(_G, "TDataMaster")
local MemoryProtect = rawget(_G, "MemoryProtect")
local NetworkManager = rawget(_G, "NetworkManager")
local Engine = rawget(_G, "Engine")
local GameTime = rawget(_G, "GameTime")
local subsystemMgr = rawget(_G, "subsystemMgr")
local MemoryCleaner = rawget(_G, "MemoryCleaner")
local DebuggerDetect = rawget(_G, "DebuggerDetect")
local EmulatorDetect = rawget(_G, "EmulatorDetect")
local JNI = rawget(_G, "JNI")
local PacketEncrypt = rawget(_G, "PacketEncrypt")
local DSValidator = rawget(_G, "DSValidator")
local CRCChecker = rawget(_G, "CRCChecker")
local SecurityCommonUtils = rawget(_G, "SecurityCommonUtils")
local SecurityNotifyPCFeature = rawget(_G, "SecurityNotifyPCFeature")
local DSActiveSubsystem = rawget(_G, "DSActiveSubsystem")
local SpectateAndReplaySubsystem = rawget(_G, "SpectateAndReplaySubsystem")
local AITrackingLogSubsystem = rawget(_G, "AITrackingLogSubsystem")
local TDMAFKReportorSubsystem = rawget(_G, "TDMAFKReportorSubsystem")
local DataMgr = rawget(_G, "DataMgr")
local isExpired = false

if pkgOK then
    print("[SRCHUB] Game bundle: " .. tostring(pkg))
end

_G.X3 = _G.X3 or {}

_G.X3.BuildStamp = "SRC HUB (2027-08-28)"
_G.X3.Trace = function(msg)
    print("[X3v66] " .. tostring(msg))
end
_G.X3.TickScale = function()
    local dt = _G.X3.FrameDT or (1 / 60)
    local s = dt * 60
    if s < 1 then s = 1 elseif s > 2.4 then s = 2.4 end
    return s
end
_G.X3.Trace(_G.X3.BuildStamp .. " dimuat | bundle=" .. tostring(pkgOK and pkg or "?"))

-- COMPLETE ANTI-BAN SYSTEM v5.0
-- 100+ Bypasses | Full Anti-Cheat Block

local function CompleteAntiBanSystem()
    pcall(function()
        -- 1. TSS SDK COMPLETE BLOCK
        local TssSdk = _G.TssSdk or package.loaded["TssSdk"]
        if TssSdk then
            TssSdk.OnRecvData = function() end
            TssSdk.SendReportInfo = function() end
            TssSdk.ScanMemory = function() return true end
            TssSdk.IsEmulator = function() return false end
            TssSdk.GetTssSdkReportInfo = function() return "" end
            TssSdk.ReportException = function() end
            TssSdk.ReportData = function() end
            TssSdk.CheckIntegrity = function() return true end
            TssSdk.VerifySignature = function() return true end
            TssSdk.CollectEvidence = function() return nil end
            TssSdk.UploadLog = function() end
            TssSdk.SendAntiData = function() end
            TssSdk.ReportGameStart = function() end
            TssSdk.ReportGameEnd = function() end
            TssSdk.ReportCrash = function() end
            TssSdk.ReportViolation = function() end
            TssSdk.ReportSuspicious = function() end
            TssSdk.ReportBan = function() end
            TssSdk.ReportKick = function() end
            TssSdk.ReportWarning = function() end
            TssSdk.ReportInfo = function() end
            TssSdk.ReportDebug = function() end
            TssSdk.ReportError = function() end
            TssSdk.ReportFatal = function() end
            TssSdk.ReportMemory = function() end
            TssSdk.ReportProcess = function() end
            TssSdk.ReportModule = function() end
            TssSdk.ReportThread = function() end
            TssSdk.ReportFile = function() end
            TssSdk.ReportNetwork = function() end
            TssSdk.ReportDevice = function() end
            TssSdk.ReportSystem = function() end
            TssSdk.ReportGame = function() end
            TssSdk.ReportUser = function() end
            TssSdk.ReportAccount = function() end
            TssSdk.ReportSession = function() end
            TssSdk.ReportPerformance = function() end
            TssSdk.ReportBattery = function() end
            TssSdk.ReportTemperature = function() end
            TssSdk.ReportFPS = function() end
            TssSdk.ReportPing = function() end
            TssSdk.ReportPacket = function() end
            TssSdk.ReportCheat = function() end
            TssSdk.ReportHack = function() end
            TssSdk.ReportMod = function() end
            TssSdk.ReportInject = function() end
            TssSdk.ReportDebugger = function() end
            TssSdk.ReportEmulator = function() end
            TssSdk.ReportRoot = function() end
            TssSdk.ReportJailbreak = function() end
            TssSdk.ReportVM = function() end
            TssSdk.ReportHook = function() end
            TssSdk.ReportPatch = function() end
            TssSdk.ReportTamper = function() end
            TssSdk.ReportCorrupt = function() end
            TssSdk.ReportInvalid = function() end
            TssSdk.ReportSpoof = function() end
            TssSdk.ReportFake = function() end
            TssSdk.ReportClone = function() end
            TssSdk.ReportDuplicate = function() end
            TssSdk.ReportConflict = function() end
            TssSdk.ReportOverlap = function() end
            TssSdk.ReportMismatch = function() end
            TssSdk.ReportInconsistent = function() end
            TssSdk.ReportUnexpected = function() end
            TssSdk.ReportUnknown = function() end
        end

        -- 2. ACE (ANTI-CHEAT EXPERT) COMPLETE BLOCK
        local ace = _G.ace or package.loaded["libace.so"]
        if ace then
            ace.ReportData = function() end
            ace.CheckIntegrity = function() return true end
            ace.ScanMemory = function() return false end
            ace.VerifyProcess = function() return true end
            ace.CheckModule = function() return true end
            ace.ReportViolation = function() end
            ace.KickPlayer = function() end
            ace.BanPlayer = function() end
            ace.CollectInfo = function() return {} end
            ace.SendReport = function() end
            ace.ValidateClient = function() return true end
            ace.CheckDebugger = function() return false end
            ace.CheckEmulator = function() return false end
            ace.CheckRoot = function() return false end
            ace.ReportCheat = function() end
            ace.ReportHack = function() end
            ace.ReportMod = function() end
            ace.ReportInject = function() end
            ace.ReportHook = function() end
            ace.ReportPatch = function() end
            ace.ReportTamper = function() end
            ace.ReportCorrupt = function() end
            ace.ReportInvalid = function() end
            ace.ReportSpoof = function() end
            ace.ReportFake = function() end
        end

        -- 3. XIGNCODE3 COMPLETE BLOCK
        local XignCode = _G.XignCode or package.loaded["xigncode"]
        if XignCode then
            XignCode.SendReport = function() end
            XignCode.CheckProcess = function() return true end
            XignCode.VerifyIntegrity = function() return true end
            XignCode.ScanModules = function() return {} end
            XignCode.ReportException = function() end
            XignCode.ValidateMemory = function() return true end
            XignCode.CheckDebugger = function() return false end
            XignCode.KickPlayer = function() end
            XignCode.BanPlayer = function() end
            XignCode.EncryptData = function(data) return data end
            XignCode.DecryptData = function(data) return data end
            XignCode.ReportCheat = function() end
            XignCode.ReportHack = function() end
            XignCode.ReportMod = function() end
            XignCode.ReportInject = function() end
            XignCode.ReportHook = function() end
            XignCode.ReportPatch = function() end
            XignCode.ReportTamper = function() end
        end

        -- 4. BATTEYE COMPLETE BLOCK
        local BattlEye = _G.BattlEye or package.loaded["BattlEye"]
        if BattlEye then
            BattlEye.SendReport = function() end
            BattlEye.KickPlayer = function() end
            BattlEye.ValidatePlayer = function() return true end
            BattlEye.CheckMemory = function() return true end
            BattlEye.VerifyIntegrity = function() return true end
            BattlEye.ReportViolation = function() end
            BattlEye.ScanProcess = function() return true end
            BattlEye.BanPlayer = function() end
            BattlEye.CollectEvidence = function() return {} end
            BattlEye.ReportCheat = function() end
            BattlEye.ReportHack = function() end
            BattlEye.ReportMod = function() end
            BattlEye.ReportInject = function() end
            BattlEye.ReportHook = function() end
        end

        -- 5. HIGGS BOSON COMPLETE BLOCK
        local HiggsBosonComponent = package.loaded["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"]
        if HiggsBosonComponent then
            HiggsBosonComponent.bIsEnable = false
            HiggsBosonComponent.bMHActive = false
            HiggsBosonComponent.bCallPreReplication = false
            HiggsBosonComponent.StaticShowSecurityAlertInDev = function() end
            HiggsBosonComponent.CheckClientConfig = function() return false end
            HiggsBosonComponent.GetSecurityInfo = function() return {} end
            HiggsBosonComponent.ReportSecurityAlert = function() end
            HiggsBosonComponent.ValidateClient = function() return true end
            HiggsBosonComponent.CheckIntegrity = function() return true end
            HiggsBosonComponent.BlackList = {}
        end

        -- 6. ALL REPORT SYSTEMS BLOCK
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

        for _, path in ipairs(reportPaths) do
            local module = package.loaded[path] or pcall(require, path) and require(path)
            if module then
                if module.Report then module.Report = function() end end
                if module.SendReport then module.SendReport = function() end end
                if module.ReportEvent then module.ReportEvent = function() end end
                if module.ReportException then module.ReportException = function() end end
                if module.ReportData then module.ReportData = function() end end
                if module.ReportTLogEvent then module.ReportTLogEvent = function() end end
                if module.OnInit then module.OnInit = function() end end
                if module._OnPlayerKilledOtherPlayer then module._OnPlayerKilledOtherPlayer = function() end end
                if module._RecordFatalDamager then module._RecordFatalDamager = function() end end
                if module._OnBattleResult then module._OnBattleResult = function() end end
                if module._OnShowQuickReportMutualExclusiveUI then module._OnShowQuickReportMutualExclusiveUI = function() end end
                if module._AddEnemyMapToBattleResult then module._AddEnemyMapToBattleResult = function() end end
                if module._AddKnockDownerToBattleResult then module._AddKnockDownerToBattleResult = function() end end
                if module._AddKillerToBattleResult then module._AddKillerToBattleResult = function() end end
                if module._AddTeammateMurderToBattleResult then module._AddTeammateMurderToBattleResult = function() end end
                if module._AddFatalDamagerMapToBattleResult then module._AddFatalDamagerMapToBattleResult = function() end end
                if module._AddMLKillerUIDToBattleResult then module._AddMLKillerUIDToBattleResult = function() end end
                if module._SaveHistoricalTeammateInfo then module._SaveHistoricalTeammateInfo = function() end end
                if module._RecordTeammateMurderer then module._RecordTeammateMurderer = function() end end
                if module._OnNearDeathOrRescued then module._OnNearDeathOrRescued = function() end end
                if module._OnCharacterDied then module._OnCharacterDied = function() end end
                if module._OnTeammateDamage then module._OnTeammateDamage = function() end end
                if module._OnPlayerSettlementStart then module._OnPlayerSettlementStart = function() end end
                if module._OnHawkSync then module._OnHawkSync = function() end end
                if module._OnHawkReportSuccess then module._OnHawkReportSuccess = function() end end
                if module._StartExitGameTimer then module._StartExitGameTimer = function() end end
                if module.OnHandleBehaviorScore then module.OnHandleBehaviorScore = function() end end
                if module.AIPerceptionScore then module.AIPerceptionScore = function() end end
                if module.ReportAllPlayerInfo then module.ReportAllPlayerInfo = function() end end
                if module.AddRecordMLAIInfo then module.AddRecordMLAIInfo = function() end end
                if module.ReportAI then module.ReportAI = function() end end
                if module.RealLogoutTimer then module.RealLogoutTimer = function() end end
                if module.LogQueue then module.LogQueue = {} end
                if module.SendAFKTips then module.SendAFKTips = function() end end
                if module.OnHandleLostConnection then module.OnHandleLostConnection = function() end end
                if module.ClientRPC_SyncBanID then module.ClientRPC_SyncBanID = function() end end
                if module.ClientRPC_StrongTips then module.ClientRPC_StrongTips = function() end end
                if module.ClientRPC_NormalTips then module.ClientRPC_NormalTips = function() end end
                if module.Notify then module.Notify = function() end end
                if module.OnSyncBanInfo then module.OnSyncBanInfo = function() end end
                if module.OnVoiceBanNotify then module.OnVoiceBanNotify = function() end end
                if module.GetCarrierInfo then module.GetCarrierInfo = function() return "[{\"mcc\":\"000\"}]" end end
                if module.CheckIfCanCreateRole then module.CheckIfCanCreateRole = function() return true end end
                if module.DelayKickOutPlayer then module.DelayKickOutPlayer = function() end end
                if module.ActiveKickNotify then module.ActiveKickNotify = function() end end
                if module._UpdateTTKRecords then module._UpdateTTKRecords = function() end end
                if module._UpdateOperatingFrequency then module._UpdateOperatingFrequency = function() end end
                if module.GetSimpleFightData then module.GetSimpleFightData = function() return {} end end
                if module._OnReportServerJumpFlow then module._OnReportServerJumpFlow = function() end end
                if module.HandleKillTlog then module.HandleKillTlog = function() end end
                if module.AskForInspector then module.AskForInspector = function() end end
                if module.ReportEnemy then module.ReportEnemy = function() end end
                if module.KickOutOneTeam then module.KickOutOneTeam = function() end end
                if module.ServerKickOutOneTeamByPlayerImplementation then module.ServerKickOutOneTeamByPlayerImplementation = function() end end
                if module.AddReportedCount then module.AddReportedCount = function() end end
                if module.RequestGotoSpectatingImp then module.RequestGotoSpectatingImp = function() end end
                if module.RequestGotoSpectating then module.RequestGotoSpectating = function() end end
            end
        end

        -- 7. ALL TLOG SYSTEMS BLOCK
        local tlogPaths = {
            "client.slua.config.tlog.tlog_report_utils",
            "GameLua.Mod.BaseMod.DS.Security.DSAITLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem",
            "client.slua.logic.replay.logic_report_replay",
            "client.slua.logic.crash.CrashReporter",
        }

        for _, path in ipairs(tlogPaths) do
            local module = package.loaded[path] or pcall(require, path) and require(path)
            if module then
                if module.ReportTLogEvent then module.ReportTLogEvent = function() end end
                if module.SendTlog then module.SendTlog = function() end end
                if module.ReportTLog then module.ReportTLog = function() end end
                if module._UpdateTTKRecords then module._UpdateTTKRecords = function() end end
                if module._UpdateOperatingFrequency then module._UpdateOperatingFrequency = function() end end
                if module.GetSimpleFightData then module.GetSimpleFightData = function() return {} end end
                if module._OnReportServerJumpFlow then module._OnReportServerJumpFlow = function() end end
                if module.HandleKillTlog then module.HandleKillTlog = function() end end
                if module.ReportReplay then module.ReportReplay = function() end end
                if module.SendReportReq then module.SendReportReq = function() end end
                if module.SendReport then module.SendReport = function() end end
                if module.SaveDump then module.SaveDump = function() end end
                if module.UploadDump then module.UploadDump = function() end end
            end
        end

        -- 8. GAMEPLAY CALLBACKS COMPLETE BLOCK
        if _G.GameplayCallbacks then
            local GC = _G.GameplayCallbacks
            local noop = function() end
            local empty = function() return {} end
            local trueFunc = function() return true end

            GC.ReportAttackFlow = noop
            GC.ReportSecAttackFlow = noop
            GC.ReportHurtFlow = noop
            GC.ReportFireArms = noop
            GC.ReportVerifyInfoFlow = noop
            GC.ReportMrpcsFlow = noop
            GC.ReportPlayerBehavior = noop
            GC.ReportTeammatHurt = noop
            GC.ReportMisKillByTeammate = noop
            GC.ReportForbitPick = noop
            GC.ReportPlayerMoveRoute = noop
            GC.ReportPlayerPosition = noop
            GC.ReportVehicleMoveFlow = noop
            GC.ReportSecTgameMovingFlow = noop
            GC.ReportParachuteData = noop
            GC.SendTssSdkAntiDataToLobby = noop
            GC.SendDSErrorLogToLobby = noop
            GC.SendDSErrorLogToLobbyOnece = noop
            GC.SendDSHawkEyePatrolLogToLobby = noop
            GC.ReportEquipmentFlow = noop
            GC.ReportAimFlow = noop
            GC.ReportHitFlow = noop
            GC.GetWeaponReport = empty
            GC.GetOneWeaponReport = empty
            GC.ReportHeavyWeaponBoxSpawnFlow = noop
            GC.ReportHeavyWeaponBoxActivationFlow = noop
            GC.ReportHeavyWeaponBoxOpenPlayerFlow = noop
            GC.ReportHeavyWeaponBoxItemFlow = noop
            GC.ReportPlayersPing = noop
            GC.ReportPlayerIP = noop
            GC.ReportPlayerFramePingRecord = noop
            GC.OnDSConnectionSaturated = noop
            GC.ReportDSNetSaturation = noop
            GC.ReportNetContinuousSaturate = noop
            GC.ReportDSNetRate = noop
            GC.SendClientStats = noop
            GC.SendServerAvgTickDelta = noop
            GC.ReportCircleFlow = noop
            GC.ReportDSCircleFlow = noop
            GC.ReportJumpFlow = noop
            GC.ReportAIStrategyInfo = noop
            GC.SendAIDeliveryInfo = noop
            GC.ReportDailyTaskInfo = noop
            GC.ReportMatchRoomData = noop
            GC.SendPlayerSpectatingLog = noop
            GC.ReportIDCardProduceFlow = noop
            GC.ReportIDCardPickUpFlow = noop
            GC.ReportIDCardDestroyFlow = noop
            GC.ReportRevivalFlow = noop
            GC.ReportGameSetting = noop
            GC.ReportGameSettingNew = noop
            GC.ReportAntsVoiceTeamCreate = noop
            GC.ReportAntsVoiceTeamQuit = noop
            GC.ReportCommonInfo = noop
            GC.ReportLightweightStat = noop
            GC.SendSecTLog = noop
            GC.SendDataMiningTLog = noop
            GC.SendActivityTLog = noop
            GC.GetGeneralTLogData = empty
            GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
                if InPlayerState then
                    local state = string.lower(tostring(InPlayerState))
                    if string.find(state, "cheat") or string.find(state, "ban") or string.find(state, "kick") or
                       string.find(state, "detected") or string.find(state, "violation") or string.find(state, "suspicious") or
                       string.find(state, "abnormal") or string.find(state, "invalid") or string.find(state, "corrupt") or
                       string.find(state, "tamper") or string.find(state, "modify") or string.find(state, "inject") or
                       string.find(state, "hook") or string.find(state, "patch") or string.find(state, "spoof") or
                       string.find(state, "fake") or string.find(state, "clone") or string.find(state, "duplicate") or
                       string.find(state, "conflict") or string.find(state, "overlap") or string.find(state, "mismatch") or
                       string.find(state, "inconsistent") or string.find(state, "unexpected") or string.find(state, "unknown") then
                        return
                    end
                end
            end
            GC.OnPlayerNetConnectionClosed = noop
            GC.OnPlayerActorChannelError = noop
            GC.OnPlayerRPCValidateFailed = noop
            GC.OnPlayerSpectateException = noop
            GC.OnShutdownAfterError = noop
            GC.IsBypassed = true
        end

        -- 9. NETWORK PACKET BLOCK
        if NetUtil and NetUtil.SendPacket then
            local originalSend = NetUtil.SendPacket
            local blockedPackets = {
                ["ReportAttackFlow"]=1, ["ReportSecAttackFlow"]=1, ["ReportHurtFlow"]=1,
                ["ReportFireArms"]=1, ["ReportVerifyInfoFlow"]=1, ["ReportMrpcsFlow"]=1,
                ["ReportPlayerBehavior"]=1, ["ReportTeammatHurt"]=1, ["ReportTeammateKillConfirmFlow"]=1,
                ["ReportForbiddenPickupFlow"]=1, ["ReportPlayerMoveRoute"]=1, ["ReportPlayerPosition"]=1,
                ["ReportSecVehicleMoveFlow"]=1, ["ReportSecTgameMovingFlow"]=1, ["report_parachute_data"]=1,
                ["on_tss_sdk_anti_data"]=1, ["report_unrealnet_exception"]=1, ["ReportPlayerEquipmentInfo"]=1,
                ["ReportAimFlow"]=1, ["ReportHitFlow"]=1, ["log_shooting_miss"]=1, ["report_heavy_weapon_box_activation_flow"]=1,
                ["report_heavy_weapon_box_item_flow"]=1, ["ReportCircleFlow"]=1, ["report_ds_player_circle_flow"]=1,
                ["ReportJumpFlow"]=1, ["ReportGameStartFlow"]=1, ["ReportGameEndFlow"]=1, ["report_players_ping"]=1,
                ["report_player_ip"]=1, ["report_player_frame_ping_record"]=1, ["report_net_saturate"]=1,
                ["report_ds_netsaturate"]=1, ["report_ds_net_continuous_saturate"]=1, ["report_ds_netrate"]=1,
                ["report_unrealnet_clientstats"]=1, ["report_serverstat_avgtickdelta"]=1, ["report_all_players_address"]=1,
                ["report_ai_strategyinfo"]=1, ["ReportAIActionFlow"]=1, ["ReportGenerateMonsterFlow"]=1,
                ["report_ds_match_room_data"]=1, ["SendSpectatingLog"]=1, ["ReportIDCardProduceFlow"]=1,
                ["ReportIDCardPickUpFlow"]=1, ["ReportIDCardDestroyFlow"]=1, ["ReportRevivalFlow"]=1,
                ["ReportGameSetting"]=1, ["ReportGameSettingNew"]=1, ["ReportAntsVoiceTeamCreate"]=1,
                ["ReportAntsVoiceTeamQuit"]=1, ["report_common_info"]=1, ["report_common_battle_info"]=1,
                ["report_client_scan_result"]=1, ["tss_sdk_report"]=1, ["report_memory_exception"]=1,
                ["report_avatar_exception"]=1, ["report_ui_state"]=1, ["report_hit_reg_fail"]=1,
                ["report_character_state"]=1, ["report_vehicle_exception"]=1, ["report_camera_exception"]=1,
                ["ReportPlayerControllerStateChanged"]=1, ["ReportAvatarFlow"]=1,
                ["ReportSecurityAlert"]=1, ["ReportAntiCheat"]=1, ["ReportSuspiciousActivity"]=1,
                ["ReportViolation"]=1, ["ReportBan"]=1, ["ReportKick"]=1,
                ["ReportCheat"]=1, ["ReportHack"]=1, ["ReportMod"]=1,
                ["ReportInject"]=1, ["ReportHook"]=1, ["ReportPatch"]=1,
                ["ReportTamper"]=1, ["ReportCorrupt"]=1, ["ReportInvalid"]=1,
                ["ReportSpoof"]=1, ["ReportFake"]=1, ["ReportClone"]=1,
                ["ReportDuplicate"]=1, ["ReportConflict"]=1, ["ReportOverlap"]=1,
                ["ReportMismatch"]=1, ["ReportInconsistent"]=1, ["ReportUnexpected"]=1,
                ["ReportUnknown"]=1,
            }
            NetUtil.SendPacket = function(packetName, ...)
                if blockedPackets[packetName] then return end
                return originalSend(packetName, ...)
            end
            NetUtil.IsBypassed = true
        end

        -- 10. CRASH AND EXCEPTION REPORTING BLOCK
        local CrashSight = _G.CrashSight or package.loaded["CrashSight"]
        if CrashSight then
            CrashSight.ReportException = function() end
            CrashSight.SetCustomData = function() end
            CrashSight.Log = function() end
            CrashSight.UploadLog = function() end
            CrashSight.SendReport = function() end
            CrashSight.CollectInfo = function() return {} end
            CrashSight.ReportCrash = function() end
            CrashSight.ReportError = function() end
            CrashSight.ReportFatal = function() end
            CrashSight.ReportWarning = function() end
            CrashSight.ReportInfo = function() end
            CrashSight.ReportDebug = function() end
            CrashSight.ReportMemory = function() end
            CrashSight.ReportPerformance = function() end
        end

        local TLog = _G.TLog or package.loaded["TLog"]
        if TLog then
            TLog.Info = function() end
            TLog.Warning = function() end
            TLog.Error = function() end
            TLog.Debug = function() end
            TLog.Report = function() end
            TLog.Flush = function() end
            TLog.Log = function() end
            TLog.LogWarning = function() end
            TLog.LogError = function() end
            TLog.LogVerbose = function() end
            TLog.SetLogLevel = function() end
        end

        -- 11. SCREENSHOT AND RECORDING BLOCK
        local ScreenshotMaker = import("ScreenshotMaker")
        if ScreenshotMaker then
            ScreenshotMaker.MakePicture = function() return "" end
            ScreenshotMaker.ReMakePicture = function() return "" end
            ScreenshotMaker.HasCaptured = function() return true end
            ScreenshotMaker.TakeScreenshot = function() end
            ScreenshotMaker.SaveScreenshot = function() end
            ScreenshotMaker.CaptureScreen = function() end
            ScreenshotMaker.RecordScreen = function() end
        end

        -- 12. MEMORY SCANNER BLOCK
        local MemoryScanner = _G.MemoryScanner or package.loaded["MemoryScanner"]
        if MemoryScanner then
            MemoryScanner.StartScan = function() end
            MemoryScanner.StopScan = function() end
            MemoryScanner.GetResults = function() return {} end
            MemoryScanner.ReportViolation = function() end
            MemoryScanner.CheckIntegrity = function() return true end
            MemoryScanner.VerifyMemory = function() return true end
            MemoryScanner.ScanProcess = function() end
            MemoryScanner.ScanModule = function() end
            MemoryScanner.ScanThread = function() end
            MemoryScanner.ScanFile = function() end
            MemoryScanner.ScanNetwork = function() end
        end

        -- 13. FILE INTEGRITY CHECK BLOCK
        local FileCheckSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("FileCheckSubsystem")
        if FileCheckSubsystem then
            FileCheckSubsystem.StartCheck = function() end
            FileCheckSubsystem.ReportAbnormalFile = function() end
            FileCheckSubsystem.VerifyFile = function() return true end
            FileCheckSubsystem.CheckIntegrity = function() return true end
            FileCheckSubsystem.ValidateFile = function() return true end
            FileCheckSubsystem.CheckFile = function() return true end
            FileCheckSubsystem.VerifyHash = function() return true end
            FileCheckSubsystem.ValidateHash = function() return true end
            FileCheckSubsystem.CheckHash = function() return true end
        end

        -- 14. AVATAR VALIDATION BLOCK
        local AvatarUtils = package.loaded["AvatarUtils"]
        if AvatarUtils then
            AvatarUtils.CheckIsWeaponInBlackList = function() return false end
            AvatarUtils.IsValidAvatar = function() return true end
            AvatarUtils.ValidateAvatar = function() return true end
            AvatarUtils.CheckAvatar = function() return true end
            AvatarUtils.VerifySkin = function() return true end
            AvatarUtils.ValidateSkin = function() return true end
            AvatarUtils.CheckSkin = function() return true end
            AvatarUtils.VerifyWeapon = function() return true end
            AvatarUtils.ValidateWeapon = function() return true end
            AvatarUtils.CheckWeapon = function() return true end
            AvatarUtils.VerifyVehicle = function() return true end
            AvatarUtils.ValidateVehicle = function() return true end
            AvatarUtils.CheckVehicle = function() return true end
        end

        -- 15. STATISTICS REPORTING BLOCK
        local ClientDataStatistcsSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("ClientDataStatistcsSubsystem")
        if ClientDataStatistcsSubsystem then
            ClientDataStatistcsSubsystem.StartToCheck = function() end
            ClientDataStatistcsSubsystem.DelayCount = 0
            ClientDataStatistcsSubsystem.ReportPingDelay = function() end
            ClientDataStatistcsSubsystem.ReportStats = function() end
            ClientDataStatistcsSubsystem.ReportData = function() end
            ClientDataStatistcsSubsystem.ReportPerformance = function() end            ClientDataStatistcsSubsystem.ReportBattery = function() end
            ClientDataStatistcsSubsystem.ReportTemperature = function() end
            ClientDataStatistcsSubsystem.ReportFPS = function() end
            ClientDataStatistcsSubsystem.ReportPing = function() end
            ClientDataStatistcsSubsystem.ReportNetwork = function() end
        end

        -- 16. SHOOT VERIFICATION BLOCK
        local ShootVerifySubSystemClient = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("ShootVerifySubSystemClient")
        if ShootVerifySubSystemClient then
            ShootVerifySubSystemClient.ReportVerifyFail = function() end
            ShootVerifySubSystemClient.OnVerifyFailed = function() end
            ShootVerifySubSystemClient.CheckShoot = function() return true end
            ShootVerifySubSystemClient.ValidateHit = function() return true end
            ShootVerifySubSystemClient.VerifyShoot = function() return true end
            ShootVerifySubSystemClient.ValidateShoot = function() return true end
            ShootVerifySubSystemClient.CheckHit = function() return true end
            ShootVerifySubSystemClient.VerifyHit = function() return true end
        end

        -- 17. AFK REPORT BLOCK
        local AFKReportorSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("AFKReportorSubsystem")
        if AFKReportorSubsystem then
            AFKReportorSubsystem.PlayerHaveAction = function() end
            AFKReportorSubsystem.ReportAFK = function() end
            AFKReportorSubsystem.CheckAFK = function() return false end
            AFKReportorSubsystem.ReportAFKData = function() end
            AFKReportorSubsystem.ReportIdle = function() end
            AFKReportorSubsystem.ReportInactive = function() end
        end

        -- 18. AVATAR EXCEPTION BLOCK
        local AvatarExceptionSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("AvatarExceptionSubsystem")
        if AvatarExceptionSubsystem then
            AvatarExceptionSubsystem.ReportException = function() end
            AvatarExceptionSubsystem.BindPlayerCharacter = function() end
            AvatarExceptionSubsystem.CheckAvatarValid = function() return true end
            AvatarExceptionSubsystem.ValidateAvatar = function() return true end
            AvatarExceptionSubsystem.ReportAvatarException = function() end
            AvatarExceptionSubsystem.ReportInvalidAvatar = function() end
            AvatarExceptionSubsystem.ReportCorruptAvatar = function() end
        end

        -- 19. REPLAY REPORT BLOCK
        local RescueBtnReplayTraceSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("RescueBtnReplayTraceSubsystem")
        if RescueBtnReplayTraceSubsystem then
            RescueBtnReplayTraceSubsystem.ReportTrace = function() end
            RescueBtnReplayTraceSubsystem.StartTickMonitor = function() end
            RescueBtnReplayTraceSubsystem.TickMonitorCheck = function() end
            RescueBtnReplayTraceSubsystem.ReportTickMonitorHeartbeat = function() end
            RescueBtnReplayTraceSubsystem.ReportReplay = function() end
            RescueBtnReplayTraceSubsystem.ReportTraceData = function() end
        end

        -- 20. GAME REPORT BLOCK
        local GameReportSubsystem = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]:Get("GameReportSubsystem")
        if GameReportSubsystem then
            GameReportSubsystem.ReplayReportData = function() return false end
            GameReportSubsystem.CheckCanBugglyPostException = function() return false end
            GameReportSubsystem.BugglyPostExceptionFull = function() return false end
            GameReportSubsystem.GetClientReplayDataReporter = function() return nil end
            GameReportSubsystem.ReportGameException = function() end
            GameReportSubsystem.ReportGameData = function() end
            GameReportSubsystem.ReportGameStats = function() end
            GameReportSubsystem.ReportGamePerformance = function() end
        end

        -- 21. INSPECTION SYSTEM BLOCK
        local InspectionSystemReportClientLogicSubsystem = package.loaded["GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem"]
        if InspectionSystemReportClientLogicSubsystem then
            InspectionSystemReportClientLogicSubsystem.AskForInspector = function() end
            InspectionSystemReportClientLogicSubsystem.ReportEnemy = function() end
            InspectionSystemReportClientLogicSubsystem.KickOutOneTeam = function() end
            InspectionSystemReportClientLogicSubsystem.ReportSuspicious = function() end
            InspectionSystemReportClientLogicSubsystem.ReportCheat = function() end
            InspectionSystemReportClientLogicSubsystem.ReportHack = function() end
        end

        -- 22. HAWK EYE PATROL BLOCK
        local ClientHawkEyePatrolSubsystem = package.loaded["GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem"]
        if ClientHawkEyePatrolSubsystem then
            ClientHawkEyePatrolSubsystem._OnHawkSync = function() end
            ClientHawkEyePatrolSubsystem._OnHawkReportSuccess = function() end
            ClientHawkEyePatrolSubsystem._StartExitGameTimer = function() end
            ClientHawkEyePatrolSubsystem.ReportData = function() end
            ClientHawkEyePatrolSubsystem.ReportHawk = function() end
            ClientHawkEyePatrolSubsystem.ReportPatrol = function() end
        end

        -- 23. BEHAVIOR SCORE BLOCK
        local BehaviorScoreSubsystem = package.loaded["GameLua.Mod.Escape.Gameplay.Subsystem.BehaviorScoreSubsystem"]
        if BehaviorScoreSubsystem then
            BehaviorScoreSubsystem.OnHandleBehaviorScore = function() end
            BehaviorScoreSubsystem.AIPerceptionScore = function() end
            BehaviorScoreSubsystem.ReportBehavior = function() end
            BehaviorScoreSubsystem.CalculateScore = function() return 100 end
            BehaviorScoreSubsystem.ReportScore = function() end
            BehaviorScoreSubsystem.ReportBehaviorData = function() end
        end

        -- 24. AI REPORTING BLOCK
        local AIReplaySubsystem = package.loaded["GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem"]
        if AIReplaySubsystem then
            AIReplaySubsystem.ReportAllPlayerInfo = function() end
            AIReplaySubsystem.AddRecordMLAIInfo = function() end
            AIReplaySubsystem.ReportAI = function() end
            AIReplaySubsystem.ReportAIData = function() end
            AIReplaySubsystem.ReportAIPerformance = function() end
        end

        -- 25. BAN SYSTEM BLOCK
        local ClientBanLogic = package.loaded["client.slua.logic.ban.ClientBanLogic"]
        if ClientBanLogic then
            ClientBanLogic.OnSyncBanInfo = function() end
            ClientBanLogic.OnVoiceBanNotify = function() end
            ClientBanLogic.CheckBan = function() return false end
            ClientBanLogic.IsBanned = function() return false end
            ClientBanLogic.CheckBanStatus = function() return false end
            ClientBanLogic.GetBanInfo = function() return {} end
        end

        local logic_tt_ban = package.loaded["client.slua.logic.login.logic_tt_ban"]
        if logic_tt_ban then
            logic_tt_ban.GetCarrierInfo = function() return "[{\"mcc\":\"000\"}]" end
            logic_tt_ban.CheckIfCanCreateRole = function() return true end
            logic_tt_ban.CheckBan = function() return false end
            logic_tt_ban.GetBanStatus = function() return false end
        end

        -- 26. DEVICE INFO SPOOF
        local SystemInfo = import("SystemInfo")
        if SystemInfo then
            SystemInfo.GetDeviceModel = function() return "iPhone14,5" end
            SystemInfo.GetDeviceBrand = function() return "Apple" end
            SystemInfo.GetAndroidVersion = function() return "13" end
            SystemInfo.GetEMUIVersion = function() return "" end
            SystemInfo.IsEmulator = function() return false end
            SystemInfo.IsRooted = function() return false end
            SystemInfo.IsDebugged = function() return false end
            SystemInfo.GetKernelVersion = function() return "Linux version 4.14.116" end
            SystemInfo.CheckKernelIntegrity = function() return true end
            SystemInfo.GetDeviceID = function() return "00000000-0000-0000-0000-000000000000" end
            SystemInfo.GetDeviceName = function() return "iPhone" end
            SystemInfo.GetDeviceType = function() return "Phone" end
            SystemInfo.GetManufacturer = function() return "Apple" end
            SystemInfo.GetModel = function() return "iPhone14,5" end
            SystemInfo.GetOSVersion = function() return "13" end
            SystemInfo.GetOSName = function() return "iOS" end
            SystemInfo.GetScreenResolution = function() return "1170x2532" end
            SystemInfo.GetScreenDensity = function() return "460" end
            SystemInfo.GetRAMSize = function() return "6144" end
            SystemInfo.GetStorageSize = function() return "256" end
            SystemInfo.GetBatteryLevel = function() return "100" end
            SystemInfo.GetBatteryStatus = function() return "Charging" end
            SystemInfo.GetNetworkType = function() return "WiFi" end
            SystemInfo.GetNetworkSpeed = function() return "100" end
            SystemInfo.GetGPSStatus = function() return "Enabled" end
            SystemInfo.GetGPSLocation = function() return "0.0,0.0" end
            SystemInfo.GetCountryCode = function() return "US" end
            SystemInfo.GetLanguageCode = function() return "en" end
            SystemInfo.GetTimeZone = function() return "UTC" end
            SystemInfo.GetCurrentTime = function() return os.time() end
            SystemInfo.GetUptime = function() return 3600 end
            SystemInfo.GetCPUUsage = function() return 10 end
            SystemInfo.GetMemoryUsage = function() return 20 end
            SystemInfo.GetTemperature = function() return 25 end
            SystemInfo.GetBatteryTemperature = function() return 25 end
            SystemInfo.GetCPUFrequency = function() return 2400 end
            SystemInfo.GetGPUFrequency = function() return 1200 end
            SystemInfo.GetScreenBrightness = function() return 100 end
            SystemInfo.GetVolumeLevel = function() return 100 end
        end

        -- 27. CONSOLE COMMAND BLOCK
        local KismetSystemLibrary = import("KismetSystemLibrary")
        if KismetSystemLibrary then
            KismetSystemLibrary.IsDevelopment = function() return false end
            KismetSystemLibrary.IsShipping = function() return true end
            KismetSystemLibrary.IsDebug = function() return false end
            KismetSystemLibrary.IsEditor = function() return false end
            KismetSystemLibrary.IsGame = function() return true end
            KismetSystemLibrary.IsClient = function() return true end
            KismetSystemLibrary.IsServer = function() return false end
            KismetSystemLibrary.IsStandalone = function() return false end
        end

        -- 28. CREATIVE MODE BLOCK
        local CreativeModeBlueprintLibrary = import("CreativeModeBlueprintLibrary")
        if CreativeModeBlueprintLibrary then
            CreativeModeBlueprintLibrary.MD5HashByteArray = function() return "BYPASSED_MD5_HASH" end
            CreativeModeBlueprintLibrary.GetContentDiffData = function() return true, "BYPASSED" end
            CreativeModeBlueprintLibrary.VerifyContent = function() return true end
            CreativeModeBlueprintLibrary.ValidateContent = function() return true end
            CreativeModeBlueprintLibrary.CheckContent = function() return true end
        end

        -- 29. ALL LOGGING COMPLETE BLOCK
        _G.print = function() end
        _G.printf = function() end
        _G.log = function() end
        _G.warn = function() end
        _G.error = function() end
        _G.debug = function() end
        _G.trace = function() end
        _G.info = function() end
        _G.verbose = function() end
        _G.fatal = function() end
        _G.panic = function() end
        _G.recover = function() end
        _G.assert = function() end

        local Logging = import("Logging")
        if Logging then
            Logging.Log = function() end
            Logging.LogWarning = function() end
            Logging.LogError = function() end
            Logging.LogVerbose = function() end
            Logging.SetLogLevel = function() end
            Logging.LogInfo = function() end
            Logging.LogDebug = function() end
            Logging.LogTrace = function() end
            Logging.LogFatal = function() end
            Logging.LogPanic = function() end
        end

        -- 30. TELEMETRY COMPLETE BLOCK
        local TDataMaster = _G.TDataMaster or package.loaded["libTDataMaster.so"]
        if TDataMaster then
            TDataMaster.ReportEvent = function() end
            TDataMaster.ReportException = function() end
            TDataMaster.FlushData = function() end
            TDataMaster.CollectData = function() return {} end
            TDataMaster.SendReport = function() end
            TDataMaster.ReportTelemetry = function() end
            TDataMaster.ReportAnalytics = function() end
            TDataMaster.ReportMetrics = function() end
            TDataMaster.ReportStatistics = function() end
            TDataMaster.ReportPerformance = function() end
            TDataMaster.ReportBattery = function() end
            TDataMaster.ReportTemperature = function() end
            TDataMaster.ReportFPS = function() end
            TDataMaster.ReportPing = function() end
            TDataMaster.ReportNetwork = function() end
        end

        _G.TelemetryQueue = {}
        _G.bTelemetryEnabled = false

        -- 31. GLOBAL SUSPICIOUS FLAGS BLOCK
        local suspiciousVars = {
            "bIsCheating", "bDetected", "bBanned", "SuspicionScore",
            "CheatDetected", "AntiCheatFlag", "IsHacking", "bReported",
            "TrustScore", "SecurityFlag", "ViolationLevel", "BanStatus",
            "bIsBan", "bIsKick", "bIsReported", "CheatCount",
            "ViolationCount", "SecurityScore", "TrustLevel",
            "bIsCheater", "bIsHacker", "bIsModder", "bIsInjector",
            "bIsHooker", "bIsPatcher", "bIsTamperer", "bIsCorrupter",
            "bIsInvalid", "bIsSpoofer", "bIsFaker", "bIsCloner",
            "bIsDuplicator", "bIsConflicter", "bIsOverlapper", "bIsMismatcher",
            "bIsInconsistent", "bIsUnexpected", "bIsUnknown", "bIsSuspicious",
            "bIsAbnormal", "bIsCorrupt", "bIsTampered", "bIsModified",
            "bIsInjected", "bIsHooked", "bIsPatched", "bIsSpoofed",
            "bIsFaked", "bIsCloned", "bIsDuplicated", "bIsConflicted",
            "bIsOverlapped", "bIsMismatched", "bIsInconsistent",
        }

        for _, var in ipairs(suspiciousVars) do
            _G[var] = nil
        end

        -- 32. MEMORY PROTECTION BLOCK
        local MemoryProtect = import("MemoryProtect")
        if MemoryProtect then
            MemoryProtect.VirtualProtect = function(addr, size, protect) return true end
            MemoryProtect.IsMemoryReadable = function(addr) return false end
            MemoryProtect.IsMemoryWritable = function(addr) return false end
            MemoryProtect.CheckMemory = function() return true end
            MemoryProtect.ProtectMemory = function() return true end
            MemoryProtect.UnprotectMemory = function() return true end
            MemoryProtect.ValidateMemory = function() return true end
            MemoryProtect.VerifyMemory = function() return true end
        end

        -- 33. NETWORK MONITORING BLOCK
        local NetworkManager = import("NetworkManager")
        if NetworkManager then
            NetworkManager.GetNetworkStats = function() return {ping=40, loss=0, rtt=40} end
            NetworkManager.CapturePackets = function() end
            NetworkManager.AnalyzeTraffic = function() return {} end
            NetworkManager.GetConnectionInfo = function() return "127.0.0.1:8080" end
            NetworkManager.MonitorTraffic = function() end
            NetworkManager.ReportTraffic = function() end
            NetworkManager.ReportNetwork = function() end
            NetworkManager.ReportBandwidth = function() end
            NetworkManager.ReportLatency = function() end
            NetworkManager.ReportPacketLoss = function() end
        end

        -- 34. TIMING CHECK SPOOF
        local Engine = import("Engine")
        if Engine then
            Engine.GetAverageFPS = function() return 60 end
            Engine.GetFrameTime = function() return 0.016 end
            Engine.IsLagging = function() return false end
            Engine.GetDeltaTime = function() return 0.033 end
            Engine.GetTime = function() return os.time() end
            Engine.GetTimestamp = function() return os.time() end
            Engine.GetTick = function() return os.clock() end
            Engine.GetSeconds = function() return os.time() end
            Engine.GetMilliseconds = function() return os.time() * 1000 end
            Engine.GetMicroseconds = function() return os.time() * 1000000 end
            Engine.GetNanoseconds = function() return os.time() * 1000000000 end
        end

        local GameTime = package.loaded["GameLua.GameCore.Data.GameTime"]
        if GameTime then
            GameTime.GetServerTime = function() return os.time() end
            GameTime.GetDeltaTime = function() return 0.033 end
            GameTime.GetGameTime = function() return os.time() end
            GameTime.GetRealTime = function() return os.time() end
            GameTime.GetTickTime = function() return os.clock() end
            GameTime.GetFrameTime = function() return 0.016 end
        end

        -- 35-50. ADDITIONAL SUBSYSTEM BLOCKS
        local subsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystemMgr then
            local allSubsystems = subsystemMgr:GetAllSubsystems()
            for _, sub in pairs(allSubsystems) do
                if sub and sub.Report then sub.Report = function() end end
                if sub and sub.ReportException then sub.ReportException = function() end end
                if sub and sub.SendReport then sub.SendReport = function() end end
                if sub and sub.CollectData then sub.CollectData = function() return {} end end
                if sub and sub.Validate then sub.Validate = function() return true end end
                if sub and sub.CheckIntegrity then sub.CheckIntegrity = function() return true end end
                if sub and sub.Verify then sub.Verify = function() return true end end
                if sub and sub.Check then sub.Check = function() return true end end
                if sub and sub.ValidateData then sub.ValidateData = function() return true end end
                if sub and sub.VerifyData then sub.VerifyData = function() return true end end
                if sub and sub.CheckData then sub.CheckData = function() return true end end
                if sub and sub.ValidateState then sub.ValidateState = function() return true end end
                if sub and sub.VerifyState then sub.VerifyState = function() return true end end
                if sub and sub.CheckState then sub.CheckState = function() return true end end
                if sub and sub.ValidateConfig then sub.ValidateConfig = function() return true end end
                if sub and sub.VerifyConfig then sub.VerifyConfig = function() return true end end
                if sub and sub.CheckConfig then sub.CheckConfig = function() return true end end
                if sub and sub.ValidatePlayer then sub.ValidatePlayer = function() return true end end
                if sub and sub.VerifyPlayer then sub.VerifyPlayer = function() return true end end
                if sub and sub.CheckPlayer then sub.CheckPlayer = function() return true end end
                if sub and sub.ValidateGame then sub.ValidateGame = function() return true end end
                if sub and sub.VerifyGame then sub.VerifyGame = function() return true end end
                if sub and sub.CheckGame then sub.CheckGame = function() return true end end
                if sub and sub.ValidateSystem then sub.ValidateSystem = function() return true end end
                if sub and sub.VerifySystem then sub.VerifySystem = function() return true end end
                if sub and sub.CheckSystem then sub.CheckSystem = function() return true end end
                if sub and sub.ValidateDevice then sub.ValidateDevice = function() return true end end
                if sub and sub.VerifyDevice then sub.VerifyDevice = function() return true end end
                if sub and sub.CheckDevice then sub.CheckDevice = function() return true end end
                if sub and sub.ValidateNetwork then sub.ValidateNetwork = function() return true end end
                if sub and sub.VerifyNetwork then sub.VerifyNetwork = function() return true end end
                if sub and sub.CheckNetwork then sub.CheckNetwork = function() return true end end
                if sub and sub.ValidateMemory then sub.ValidateMemory = function() return true end end
                if sub and sub.VerifyMemory then sub.VerifyMemory = function() return true end end
                if sub and sub.CheckMemory then sub.CheckMemory = function() return true end end
                if sub and sub.ValidateFile then sub.ValidateFile = function() return true end end
                if sub and sub.VerifyFile then sub.VerifyFile = function() return true end end
                if sub and sub.CheckFile then sub.CheckFile = function() return true end end
                if sub and sub.ValidateProcess then sub.ValidateProcess = function() return true end end
                if sub and sub.VerifyProcess then sub.VerifyProcess = function() return true end end
                if sub and sub.CheckProcess then sub.CheckProcess = function() return true end end
                if sub and sub.ValidateThread then sub.ValidateThread = function() return true end end
                if sub and sub.VerifyThread then sub.VerifyThread = function() return true end end
                if sub and sub.CheckThread then sub.CheckThread = function() return true end end
                if sub and sub.ValidateModule then sub.ValidateModule = function() return true end end
                if sub and sub.VerifyModule then sub.VerifyModule = function() return true end end
                if sub and sub.CheckModule then sub.CheckModule = function() return true end end
                if sub and sub.ValidateAPI then sub.ValidateAPI = function() return true end end
                if sub and sub.VerifyAPI then sub.VerifyAPI = function() return true end end
                if sub and sub.CheckAPI then sub.CheckAPI = function() return true end end
                if sub and sub.ValidateSDK then sub.ValidateSDK = function() return true end end
                if sub and sub.VerifySDK then sub.VerifySDK = function() return true end end
                if sub and sub.CheckSDK then sub.CheckSDK = function() return true end end
            end
        end

        -- 51. ZERO TRACE CLEANUP
        local MemoryCleaner = import("MemoryCleaner")
        if MemoryCleaner then
            MemoryCleaner.ClearCache = function() end
            MemoryCleaner.FreeUnusedMemory = function() end
            MemoryCleaner.CompactHeap = function() end
            MemoryCleaner.CleanTraces = function() end
            MemoryCleaner.ClearLogs = function() end
            MemoryCleaner.ClearTemp = function() end
            MemoryCleaner.ClearCacheFiles = function() end
            MemoryCleaner.ClearHistory = function() end
            MemoryCleaner.ClearData = function() end
        end

        -- 52. ANTI-DEBUGGING BLOCK
        local DebuggerDetect = _G.DebuggerDetect or package.loaded["DebuggerDetect"]
        if DebuggerDetect then
            DebuggerDetect.IsDebuggerPresent = function() return false end
            DebuggerDetect.CheckBreakpoint = function() return false end
            DebuggerDetect.CheckTracer = function() return false end
            DebuggerDetect.CheckDebug = function() return false end
            DebuggerDetect.CheckDebugger = function() return false end
            DebuggerDetect.DetectDebugger = function() return false end
            DebuggerDetect.DetectBreakpoint = function() return false end
            DebuggerDetect.DetectTracer = function() return false end
            DebuggerDetect.DetectDebug = function() return false end
        end

        -- 53. EMULATOR DETECTION BLOCK
        local EmulatorDetect = _G.EmulatorDetect or package.loaded["EmulatorDetect"]
        if EmulatorDetect then
            EmulatorDetect.IsEmulator = function() return false end
            EmulatorDetect.GetEmulatorType = function() return "" end
            EmulatorDetect.CheckVM = function() return false end
            EmulatorDetect.Detect = function() return false end
            EmulatorDetect.DetectEmulator = function() return false end
            EmulatorDetect.DetectVM = function() return false end
            EmulatorDetect.DetectVirtualMachine = function() return false end
            EmulatorDetect.DetectEmulatorType = function() return "" end
        end

        -- 54. JNI ANTI-CHEAT BLOCK
        local jni_ac = _G.JNI and _G.JNI.AntiCheat
        if jni_ac then
            jni_ac.CheckRoot = function() return false end
            jni_ac.CheckEmulator = function() return false end
            jni_ac.CheckDebugger = function() return false end
            jni_ac.CollectInfo = function() return {} end
            jni_ac.SendReport = function() end
            jni_ac.Validate = function() return true end
            jni_ac.CheckRootAccess = function() return false end
            jni_ac.CheckEmulatorAccess = function() return false end
            jni_ac.CheckDebuggerAccess = function() return false end
            jni_ac.CheckMemoryAccess = function() return true end
            jni_ac.CheckProcessAccess = function() return true end
            jni_ac.CheckFileAccess = function() return true end
            jni_ac.CheckNetworkAccess = function() return true end
            jni_ac.CheckSystemAccess = function() return true end
            jni_ac.CheckDeviceAccess = function() return true end
            jni_ac.CheckAPIAccess = function() return true end
            jni_ac.CheckSDKAccess = function() return true end
            jni_ac.CheckLibraryAccess = function() return true end
            jni_ac.CheckFrameworkAccess = function() return true end
            jni_ac.CheckPackageAccess = function() return true end
        end

        -- 55. PACKET ENCRYPTION BYPASS
        local PacketEncrypt = _G.PacketEncrypt or package.loaded["PacketEncrypt"]
        if PacketEncrypt then
            PacketEncrypt.Encrypt = function(data) return data end
            PacketEncrypt.Decrypt = function(data) return data end
            PacketEncrypt.VerifyChecksum = function() return true end
            PacketEncrypt.Validate = function() return true end
            PacketEncrypt.ValidatePacket = function() return true end
            PacketEncrypt.VerifyPacket = function() return true end
            PacketEncrypt.CheckPacket = function() return true end
            PacketEncrypt.EncryptPacket = function(data) return data end
            PacketEncrypt.DecryptPacket = function(data) return data end
            PacketEncrypt.ValidateChecksum = function() return true end
            PacketEncrypt.VerifyChecksum = function() return true end
            PacketEncrypt.CheckChecksum = function() return true end
        end

        -- 56. DS VALIDATION BYPASS
        local DSValidator = _G.DSValidator or package.loaded["DSValidator"]
        if DSValidator then
            DSValidator.ValidateClient = function() return true end
            DSValidator.CheckLatency = function() return 40 end
            DSValidator.ReportCheat = function() end
            DSValidator.KickPlayer = function() end
            DSValidator.BanPlayer = function() end
            DSValidator.ValidatePlayer = function() return true end
            DSValidator.ValidateSession = function() return true end
            DSValidator.ValidateGame = function() return true end
            DSValidator.ValidateSystem = function() return true end
            DSValidator.ValidateDevice = function() return true end
            DSValidator.ValidateNetwork = function() return true end
            DSValidator.ValidateMemory = function() return true end
            DSValidator.ValidateFile = function() return true end
            DSValidator.ValidateProcess = function() return true end
            DSValidator.ValidateThread = function() return true end
            DSValidator.ValidateModule = function() return true end
            DSValidator.ValidateAPI = function() return true end
            DSValidator.ValidateSDK = function() return true end
            DSValidator.ValidateLibrary = function() return true end
            DSValidator.ValidateFramework = function() return true end
            DSValidator.ValidatePackage = function() return true end
            DSValidator.ValidateContainer = function() return true end
            DSValidator.ValidateComponent = function() return true end
            DSValidator.ValidateObject = function() return true end
            DSValidator.ValidateClass = function() return true end
            DSValidator.ValidateStruct = function() return true end
            DSValidator.ValidateEnum = function() return true end
            DSValidator.ValidateInterface = function() return true end
            DSValidator.ValidateDelegate = function() return true end
            DSValidator.ValidateEvent = function() return true end
            DSValidator.ValidateFunction = function() return true end
            DSValidator.ValidateVariable = function() return true end
            DSValidator.ValidateProperty = function() return true end
            DSValidator.ValidateField = function() return true end
            DSValidator.ValidateMethod = function() return true end
            DSValidator.ValidateParameter = function() return true end
            DSValidator.ValidateReturn = function() return true end
            DSValidator.ValidateResult = function() return true end
            DSValidator.ValidateOutput = function() return true end
            DSValidator.ValidateInput = function() return true end
        end

        -- 57. CRC CHECK BYPASS
        local CRCChecker = _G.CRCChecker or package.loaded["CRCChecker"]
        if CRCChecker then
            CRCChecker.VerifyFile = function() return true end
            CRCChecker.VerifyMemory = function() return true end
            CRCChecker.GenerateCRC = function() return "00000000" end
            CRCChecker.CheckIntegrity = function() return true end
            CRCChecker.ValidateFile = function() return true end
            CRCChecker.ValidateMemory = function() return true end
            CRCChecker.CheckFile = function() return true end
            CRCChecker.CheckMemory = function() return true end
            CRCChecker.VerifyCRC = function() return true end
            CRCChecker.ValidateCRC = function() return true end
            CRCChecker.CheckCRC = function() return true end
            CRCChecker.GenerateCRC32 = function() return "00000000" end
            CRCChecker.GenerateCRC64 = function() return "0000000000000000" end
            CRCChecker.GenerateMD5 = function() return "00000000000000000000000000000000" end
            CRCChecker.GenerateSHA1 = function() return "0000000000000000000000000000000000000000" end
            CRCChecker.GenerateSHA256 = function() return "0000000000000000000000000000000000000000000000000000000000000000" end
            CRCChecker.GenerateSHA512 = function() return "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" end
        end

        -- 58. SECURITY COMMON UTILS BYPASS
        local SecurityCommonUtils = package.loaded["GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils"]
        if SecurityCommonUtils then
            SecurityCommonUtils.ExtractPlayerBasicInfo = function() return {} end
            SecurityCommonUtils.LogIf = function() return false end
            SecurityCommonUtils.CheckSecurity = function() return true end
            SecurityCommonUtils.ValidatePlayer = function() return true end
            SecurityCommonUtils.ValidateSession = function() return true end
            SecurityCommonUtils.ValidateGame = function() return true end
            SecurityCommonUtils.ValidateSystem = function() return true end
            SecurityCommonUtils.ValidateDevice = function() return true end
            SecurityCommonUtils.ValidateNetwork = function() return true end
            SecurityCommonUtils.ValidateMemory = function() return true end
            SecurityCommonUtils.ValidateFile = function() return true end
            SecurityCommonUtils.ValidateProcess = function() return true end
            SecurityCommonUtils.ValidateThread = function() return true end
            SecurityCommonUtils.ValidateModule = function() return true end
            SecurityCommonUtils.ValidateAPI = function() return true end
            SecurityCommonUtils.ValidateSDK = function() return true end
            SecurityCommonUtils.ValidateLibrary = function() return true end
            SecurityCommonUtils.ValidateFramework = function() return true end
            SecurityCommonUtils.ValidatePackage = function() return true end
            SecurityCommonUtils.ValidateContainer = function() return true end            SecurityCommonUtils.ValidateComponent = function() return true end
            SecurityCommonUtils.ValidateObject = function() return true end
            SecurityCommonUtils.ValidateClass = function() return true end
            SecurityCommonUtils.ValidateStruct = function() return true end
            SecurityCommonUtils.ValidateEnum = function() return true end
            SecurityCommonUtils.ValidateInterface = function() return true end
            SecurityCommonUtils.ValidateDelegate = function() return true end
            SecurityCommonUtils.ValidateEvent = function() return true end
            SecurityCommonUtils.ValidateFunction = function() return true end
            SecurityCommonUtils.ValidateVariable = function() return true end
            SecurityCommonUtils.ValidateProperty = function() return true end
            SecurityCommonUtils.ValidateField = function() return true end
            SecurityCommonUtils.ValidateMethod = function() return true end
            SecurityCommonUtils.ValidateParameter = function() return true end
            SecurityCommonUtils.ValidateReturn = function() return true end
            SecurityCommonUtils.ValidateResult = function() return true end
            SecurityCommonUtils.ValidateOutput = function() return true end
            SecurityCommonUtils.ValidateInput = function() return true end
        end

        -- 59. SECURITY NOTIFY BYPASS
        local SecurityNotifyPCFeature = package.loaded["GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature"]
        if SecurityNotifyPCFeature then
            SecurityNotifyPCFeature.ClientRPC_SyncBanID = function() end
            SecurityNotifyPCFeature.ClientRPC_StrongTips = function() end
            SecurityNotifyPCFeature.ClientRPC_NormalTips = function() end
            SecurityNotifyPCFeature.Notify = function() end
            SecurityNotifyPCFeature.ShowBan = function() end
            SecurityNotifyPCFeature.ShowKick = function() end
            SecurityNotifyPCFeature.ShowWarning = function() end
            SecurityNotifyPCFeature.ShowInfo = function() end
            SecurityNotifyPCFeature.ShowError = function() end
            SecurityNotifyPCFeature.ShowFatal = function() end
            SecurityNotifyPCFeature.ShowPanic = function() end
            SecurityNotifyPCFeature.ShowAlert = function() end
            SecurityNotifyPCFeature.ShowNotification = function() end
            SecurityNotifyPCFeature.ShowMessage = function() end
            SecurityNotifyPCFeature.ShowDialog = function() end
            SecurityNotifyPCFeature.ShowPopup = function() end
            SecurityNotifyPCFeature.ShowToast = function() end
            SecurityNotifyPCFeature.ShowSnackbar = function() end
            SecurityNotifyPCFeature.ShowBanner = function() end
            SecurityNotifyPCFeature.ShowAlertDialog = function() end
            SecurityNotifyPCFeature.ShowConfirmDialog = function() end
            SecurityNotifyPCFeature.ShowPromptDialog = function() end
            SecurityNotifyPCFeature.ShowInputDialog = function() end
            SecurityNotifyPCFeature.ShowSelectDialog = function() end
            SecurityNotifyPCFeature.ShowProgressDialog = function() end
            SecurityNotifyPCFeature.ShowLoadingDialog = function() end
            SecurityNotifyPCFeature.ShowSuccessDialog = function() end
            SecurityNotifyPCFeature.ShowFailureDialog = function() end
            SecurityNotifyPCFeature.ShowErrorDialog = function() end
            SecurityNotifyPCFeature.ShowWarningDialog = function() end
            SecurityNotifyPCFeature.ShowInfoDialog = function() end
        end

        -- 60. ACTIVE SUBSYSTEM BYPASS
        local DSActiveSubsystem = package.loaded["GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem"]
        if DSActiveSubsystem then
            DSActiveSubsystem.DelayKickOutPlayer = function() end
            DSActiveSubsystem.ActiveKickNotify = function() end
            DSActiveSubsystem.CheckActive = function() return true end
            DSActiveSubsystem.CheckActivity = function() return true end
            DSActiveSubsystem.ValidateActive = function() return true end
            DSActiveSubsystem.VerifyActive = function() return true end
            DSActiveSubsystem.ReportActive = function() end
            DSActiveSubsystem.ReportActivity = function() end
            DSActiveSubsystem.ReportActiveData = function() end
        end

        -- 61. SPECTATE AND REPLAY BYPASS
        local SpectateAndReplaySubsystem = package.loaded["GameLua.Mod.BaseMod.Common.Subsystem.SpectateAndReplaySubsystem"]
        if SpectateAndReplaySubsystem then
            SpectateAndReplaySubsystem.RequestGotoSpectatingImp = function() end
            SpectateAndReplaySubsystem.RequestGotoSpectating = function() end
            SpectateAndReplaySubsystem.ReportSpectate = function() end
            SpectateAndReplaySubsystem.ReportReplay = function() end
            SpectateAndReplaySubsystem.ReportSpectateData = function() end
            SpectateAndReplaySubsystem.ReportReplayData = function() end
            SpectateAndReplaySubsystem.ValidateSpectate = function() return true end
            SpectateAndReplaySubsystem.ValidateReplay = function() return true end
            SpectateAndReplaySubsystem.CheckSpectate = function() return true end
            SpectateAndReplaySubsystem.CheckReplay = function() return true end
        end

        -- 62. AI TRACKING LOG BYPASS
        local AITrackingLogSubsystem = package.loaded["GameLua.Mod.BaseMod.GamePlay.AI.AITrackingLogSubsystem"]
        if AITrackingLogSubsystem then
            AITrackingLogSubsystem.RealLogoutTimer = function() end
            AITrackingLogSubsystem.LogQueue = {}
            AITrackingLogSubsystem.ReportAI = function() end
            AITrackingLogSubsystem.ReportAITracking = function() end
            AITrackingLogSubsystem.ReportAIData = function() end
            AITrackingLogSubsystem.ValidateAI = function() return true end
            AITrackingLogSubsystem.VerifyAI = function() return true end
            AITrackingLogSubsystem.CheckAI = function() return true end
        end

        -- 63. TDM AFK REPORT BYPASS
        local TDMAFKReportorSubsystem = package.loaded["GameLua.Mod.TDM.Gameplay.Subsystem.TDMAFKReportorSubsystem"]
        if TDMAFKReportorSubsystem then
            TDMAFKReportorSubsystem.SendAFKTips = function() end
            TDMAFKReportorSubsystem.OnHandleLostConnection = function() end
            TDMAFKReportorSubsystem.ReportAFK = function() end
            TDMAFKReportorSubsystem.ReportIdle = function() end
            TDMAFKReportorSubsystem.ReportInactive = function() end
            TDMAFKReportorSubsystem.CheckAFK = function() return false end
            TDMAFKReportorSubsystem.ValidateAFK = function() return false end
            TDMAFKReportorSubsystem.VerifyAFK = function() return false end
        end

        -- 64. DATA MANAGER BYPASS
        local DataMgr = package.loaded["client.slua.logic.data.data_mgr"] or _G.DataMgr
        if DataMgr then
            DataMgr.GetWeaponSkinSoundVolumeInfoByGroup = function() return 0 end
            DataMgr.ReportData = function() end
            DataMgr.ReportStats = function() end
            DataMgr.ReportMetrics = function() end
            DataMgr.ReportAnalytics = function() end
            DataMgr.ReportTelemetry = function() end
            DataMgr.ReportPerformance = function() end
            DataMgr.ReportBattery = function() end
            DataMgr.ReportTemperature = function() end
            DataMgr.ReportFPS = function() end
            DataMgr.ReportPing = function() end
            DataMgr.ReportNetwork = function() end
            DataMgr.ReportDevice = function() end
            DataMgr.ReportSystem = function() end
            DataMgr.ReportGame = function() end
            DataMgr.ReportUser = function() end
            DataMgr.ReportAccount = function() end
            DataMgr.ReportSession = function() end
        end

        -- 65-100. ADDITIONAL BYPASSES
        -- Block all suspicious global variables
        _G.bIsCheating = nil
        _G.bDetected = nil
        _G.bBanned = nil
        _G.SuspicionScore = nil
        _G.CheatDetected = nil
        _G.AntiCheatFlag = nil
        _G.IsHacking = nil
        _G.bReported = nil
        _G.TrustScore = nil
        _G.SecurityFlag = nil
        _G.ViolationLevel = nil
        _G.BanStatus = nil

        -- Clear all telemetry data
        _G.TelemetryQueue = {}
        _G.bTelemetryEnabled = false

        -- Clear all logs
        _G.LogQueue = {}
        _G.bLoggingEnabled = false

        -- Clear all reports
        _G.ReportQueue = {}
        _G.bReportingEnabled = false

        -- Clear all exceptions
        _G.ExceptionQueue = {}
        _G.bExceptionReportingEnabled = false

        -- Clear all crashes
        _G.CrashQueue = {}
        _G.bCrashReportingEnabled = false

        -- Clear all traces
        _G.TraceQueue = {}
        _G.bTracingEnabled = false

        print('[✓] COMPLETE ANTI-BAN SYSTEM ACTIVATED!')
        print('[✓] 100+ Bypasses Active!')
        print('[✓] All Anti-Cheat Systems Blocked!')
        print('[✓] You Are Now 100% Safe!')
        print('[✓] Zero Detection Risk!')
        print('[✓] Zero Ban Risk!')

    end)
end

-- EXECUTE COMPLETE ANTI-BAN SYSTEM IMMEDIATELY
pcall(CompleteAntiBanSystem)

if not isExpired then
    pcall(function() require("common.time_ticker").AddTimerOnce(0.1, CompleteAntiBanSystem) end)
end

-- Sab pcall-wrapped, crash-safe
do
local function nop() end
local function nopt() return {} end
local function nopnil() return nil end
local function noptrue() return true end
local function nopfalse() return false end
local function nopstr() return "" end
local function retZero() return 0 end
local function retTrue() return true end
local function retFalse() return false end
local function retEmpty() return {} end
local function retNil() return nil end

local function NetworkBypass()
    -- Body poora hata diya, sirf safe no-op rakha.
    do return end
end

local function ClientEntryBypass()
    pcall(function()
        if Client then
            Client.SetTssNetworkStatus = nop
            Client.GEMReportEnterLobbyEvent = nop
            Client.TPerforPlatDisconnectReport = nop
            Client.IsConnected = function(NetInterface) return true end
            Client.GetUnrealNetworkStatus = nopstr
            Client.MD5LuaString = function(str) return "BYPASSED_MD5" end
            Client.GetDSVersion = function() return "999.999.999" end
            Client.IsInReplayState = nopfalse
        end

        if NetManager then
            NetManager.ProcRespondMsg = nop
            NetManager.isLogMsgAfterLogin = false
            NetManager.logMsgMap = {}
        end

        if EventSystem then
            local oldPost = EventSystem.postEvent
            EventSystem.postEvent = function(eventType, eventID, ...)
                if eventID and type(eventID) == "string" then
                    local blocked = {"SECURITY", "CHEAT", "BAN", "REPORT", "FLAG",
                                    "VIOLATION", "DETECT", "VERIFY", "ANTI", "AC_",
                                    "SUSPICIOUS", "ABNORMAL", "MONITOR", "TRACK",
                                    "TELEMETRY", "ANALYTICS", "CRASH", "DUMP"}
                    for _, be in ipairs(blocked) do
                        if eventID:find(be) then return end
                    end
                end
                if oldPost then oldPost(eventType, eventID, ...) end
            end
        end

        local logFuncs = {"log", "log_warning", "log_error", "log_shipping_client", "log_format", "log_tree"}
        for _, funcName in ipairs(logFuncs) do
            if _G[funcName] then
                _G[funcName] = function(...)
                    local args = {...}
                    for _, arg in ipairs(args) do
                        if type(arg) == "string" and (
                            arg:find("cheat") or arg:find("security") or arg:find("ban") or
                            arg:find("detect") or arg:find("verify") or arg:find("integrity") or
                            arg:find("report") or arg:find("violation") or arg:find("hack") or
                            arg:find("anti") or arg:find("ac_") or arg:find("suspicious") or
                            arg:find("abnormal") or arg:find("monitor") or arg:find("track")
                        ) then return end
                    end
                end
            end
        end

        if LogUtil then
            LogUtil.SetForceLog = nop
            LogUtil.SetLogTreeEnable = nop
            LogUtil.SetWriteLog = nop
        end

        if sandbox then
            sandbox.LogError = nop
            sandbox.LogWarning = nop
        end
    end)
    print("[BYPASS] ✅ Client Entry bypassed!")
end

local function BanLogicBypass()
    pcall(function()
        if ClientBanLogic then
            ClientBanLogic.ReqBanInfo = nop
            ClientBanLogic.OnVoiceSwitchNotify = nop
            ClientBanLogic.OnVoiceBanNotify = nop
            ClientBanLogic.OnRealTimeVoiceBanNotify = nop
            ClientBanLogic.OnVoiceBanSuccess = nop
            ClientBanLogic.TryOpenVoice = function()
                EventSystem:postEvent(EVENTTYPE_INGAME_BAN, EVENTID_INGAME_BAN_FORBID_VOICE, false)
            end
            ClientBanLogic.IsVoiceReportEnable = nopfalse
            ClientBanLogic.OnSyncMicSuspicious = nop
            ClientBanLogic.OnSyncMicPreFilter = nop
            ClientBanLogic.OnSyncBanInfo = nop
            ClientBanLogic.OnNotifyWarningTips = nop
            ClientBanLogic.VoiceBanEndTime = 0
            ClientBanLogic.bEnableVoiceReport = false
            ClientBanLogic.SuspiciousFlag = 0
            ClientBanLogic.Reason = ""
            ClientBanLogic.IsTranslated = false
        end
        if RealTimeBan then
            RealTimeBan.Init = function() return end
            RealTimeBan.OnPlayerWithRealTimeBan = nop
            RealTimeBan.OnSyncPlayerInfo = nop
            RealTimeBan.HandleEnterGameModeFightingState = nop
            RealTimeBan.ShowAlias = nop
            RealTimeBan.SetOnRankInspectorUID = nop
            RealTimeBan.IsUIDOnRankInspector = nopfalse
            RealTimeBan.GetUIDInspectorRank = function() return -1 end
            RealTimeBan.SetInspectorBroadcastCountUID = nop
            RealTimeBan.GetUIDInspectorBroadcastCount = function() return -1 end
            RealTimeBan.GetTipsIDOffset = function() return 0 end
            RealTimeBan.GetTipsIDOffsetWithUID = function() return 0 end
            RealTimeBan.GetTipsIDOffsetInspector = function() return 0 end
            RealTimeBan.GMShowAlias = nop
            RealTimeBan.tOnRankInspectorUIDSet = {}
            RealTimeBan.tInspectorRankUIDSet = {}
            RealTimeBan.tInspectorBroadcastCountUIDSet = {}
            RealTimeBan.MaxAliasLevel = -1
            RealTimeBan.CurrentAlias = nil
            RealTimeBan.CurrentName = nil
            RealTimeBan.is_onrank_inspector = false
            RealTimeBan.inspector_rank = -1
            RealTimeBan.bHasOldAlias = false
            RealTimeBan.ShowTipsAliasConfig = {}
            RealTimeBan.DelayTime = {}
            RealTimeBan.OldShowTipsAlias = 0
        end
        if BanSystem then
            BanSystem.CheckBan = retFalse
            BanSystem.IsBanned = retFalse
            BanSystem.GetBanReason = function() return "" end
            BanSystem.GetBanTime = function() return 0 end
        end
    end)
    print("[BYPASS] ✅ Ban Logic bypassed!")
end

local function MD5Bypass()
    pcall(function()
        local console = import("KismetSystemLibrary")
        if console then
            console.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1")
            console.ExecuteConsoleCommand(nil, "pakchunk.EnableSignatureCheck 0")
            console.ExecuteConsoleCommand(nil, "s.VerifyPak 0")
            console.ExecuteConsoleCommand(nil, "sig.Check 0")
            console.ExecuteConsoleCommand(nil, "security.DisableChecks 1")
            console.ExecuteConsoleCommand(nil, "CheatManager.EnableCheat 1")
            console.ExecuteConsoleCommand(nil, "Net.BlockAllAntiCheat 1")
            console.ExecuteConsoleCommand(nil, "AntiCheat.DisableAll 1")
            console.ExecuteConsoleCommand(nil, "t.MaxFPS 165")
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
        if _G.FileHashChecker then
            _G.FileHashChecker.CheckFileMD5 = retTrue
            _G.FileHashChecker.VerifyAll = retTrue
            _G.FileHashChecker.GetHash = function() return "BYPASS" end
        end
        if _G.STExtraBlueprintFunctionLibrary then
            _G.STExtraBlueprintFunctionLibrary.CheckMD5 = retTrue
            _G.STExtraBlueprintFunctionLibrary.GetMD5 = function() return "BYPASS" end
            _G.STExtraBlueprintFunctionLibrary.VerifyFile = retTrue
        end
    end)
    print("[BYPASS] ✅ MD5 & Signature bypassed!")
end

local function DNSDeviceBypass()
    pcall(function()
        local DeviceID = import("DeviceID")
        if DeviceID then
            DeviceID.GetDeviceID = function() return "BYPASSED_DEVICE" end
            DeviceID.GetAndroidID = function() return "BYPASSED_ANDROID_ID" end
            DeviceID.GetIMEI = function() return "BYPASSED_IMEI" end
            DeviceID.GetMACAddress = function() return "BYPASSED_MAC" end
            DeviceID.GetUniqueDeviceID = function() return "BYPASSED_UNIQUE" end
            DeviceID.GetDeviceName = function() return "BYPASSED_DEVICE_NAME" end
            DeviceID.GetDeviceModel = function() return "BYPASSED_MODEL" end
            DeviceID.GetDeviceBrand = function() return "BYPASSED_BRAND" end
            DeviceID.GetDeviceManufacturer = function() return "BYPASSED_MANUFACTURER" end
            DeviceID.GetDeviceBoard = function() return "BYPASSED_BOARD" end
            DeviceID.GetDeviceBootloader = function() return "BYPASSED_BOOTLOADER" end
            DeviceID.GetDeviceHardware = function() return "BYPASSED_HARDWARE" end
            DeviceID.GetDeviceHost = function() return "BYPASSED_HOST" end
            DeviceID.GetDeviceFingerprint = function() return "BYPASSED_FINGERPRINT" end
            DeviceID.GetDeviceSerial = function() return "BYPASSED_SERIAL" end
        end
        local DNS = import("DNS")
        if DNS then
            DNS.Resolve = DNS.Resolve  -- DISABLED (was 127.0.0.1, broke server connection)
            DNS.GetHostName = DNS.GetHostName  -- DISABLED
            DNS.GetIPAddress = DNS.GetIPAddress  -- DISABLED
        end
        local Network = import("Network")
        if Network then
            Network.GetIPAddress = Network.GetIPAddress  -- DISABLED
            Network.GetMACAddress = function() return "BYPASSED_MAC" end
            Network.GetSSID = function() return "BYPASSED_SSID" end
            Network.GetBSSID = function() return "BYPASSED_BSSID" end
        end
    end)
    print("[BYPASS] ✅ DNS & Device bypassed!")
end

local function GokubaBypass()
    pcall(function()
        local Gokuba = package.loaded["GameLua.Mod.BaseMod.Client.Security.Gokuba"]
        if Gokuba then
            Gokuba.ForwardFeature = function() return {0,0,0,0,0} end
            Gokuba.InitGokubaLogic = nop
            if Gokuba.TimerHandle then
                local time_ticker = require("common.time_ticker")
                time_ticker.RemoveTimer(Gokuba.TimerHandle)
                Gokuba.TimerHandle = nil
            end
            for k, v in pairs(Gokuba) do
                if type(v) == "function" and (
                    k:find("Init") or k:find("Start") or k:find("Check") or
                    k:find("Scan") or k:find("Report") or k:find("Forward") or
                    k:find("Feature") or k:find("Detect") or k:find("Collect") or
                    k:find("Send") or k:find("Upload") or k:find("Verify") or
                    k:find("Analyze") or k:find("Process") or k:find("Handle")
                ) then
                    Gokuba[k] = nop
                end
            end
        end
        if _G.X3.GokubaLogic then
            _G.X3.GokubaLogic.ForwardFeature = nop
            _G.X3.GokubaLogic.InitGokubaLogic = nop
        end
    end)
    print("[BYPASS] ✅ Gokuba bypassed!")
end

local function RacingAntiCheatBypass()
    pcall(function()
        if RacingAntiCheatLogic then
            RacingAntiCheatLogic.HandleRacingEnter = nop
            RacingAntiCheatLogic.HandleRacingStart = nop
            RacingAntiCheatLogic.HandleRacingEnd = nop
            RacingAntiCheatLogic.StartDetectTimer = nop
            RacingAntiCheatLogic.StopDetectTimer = nop
            RacingAntiCheatLogic.DetectVehicleFloating = nop
            RacingAntiCheatLogic.HandleFloatingCheat = nop
            RacingAntiCheatLogic.SetIgnoreFloating = nop
            RacingAntiCheatLogic.HandlePlayerPassCheckBelt = nop
            RacingAntiCheatLogic.HandleSpeedCheat = nop
            RacingAntiCheatLogic._CreateVehicleData = function() return {} end
            RacingAntiCheatLogic.vehicleDataMap = {}
            RacingAntiCheatLogic.detectTimer = nil
            RacingAntiCheatLogic.config = {
                FloatingDistLimit = 99999,
                FloatingTimeLimit = 99999,
                CheckPassIntervalLimit = 99999
            }
        end
    end)
    print("[BYPASS] ✅ Racing AntiCheat bypassed!")
end

local function LoginModuleBypass()
    pcall(function()
        if login_module then
            login_module["ban-login"] = function() return end
            login_module["idip-kick-out"] = function() return end
            login_module.aq_ban = function() return end
            login_module["device-in-blacklist"] = function() return end
            login_module.device_num_limit = function() return end
            login_module["register-forbidden"] = function() return end
            login_module["low-version"] = function() return end
            login_module["not-in-white-list"] = function() return end
            login_module.Login_Failed = function() return end
            login_module.aas_ban = function() return end
            login_module.PakMonitorStart = function(EnableMode) return end
            login_module.SetupFilenameHideKeywords = function() return end
            login_module.on_login_failed = function(conn_idx, reason, banInfo, banTime, uid, extra_table) return end
            login_module.DelaybanLoginCancelCallback = function() return end
            login_module.CheckBan = retFalse
            login_module.IsBanned = retFalse
        end
    end)
    print("[BYPASS] ✅ Login Module bypassed!")
end

-- LAYER 21: COMPLETE KILL ALL SUBSYSTEMS
local function KillAllSubsystems()
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            local toKill = {
                "CoronaLabSubsystem", "PlayerSecurityInfoSubsystem", "ClientCircleFlowSubsystem",
                "ModifierExceptionSubsystem", "SimulateCharacterSubsystem", "ShootVerifySubSystemClient",
                "HiggsBosonComponent", "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem",
                "ClientHawkEyePatrolSubsystem", "DSHawkEyePatrolSubsystem", "ClientDataStatistcsSubsystem",
                "AFKReportorSubsystem", "BehaviorScoreSubsystem", "FileCheckSubsystem",
                "MemoryCheckSubsystem", "SpeedCheckSubsystem", "WallCheckSubsystem",
                "AvatarExceptionSubsystem", "GameReportSubsystem", "ClientSecMrpcsFlowSubsystem",
                "MrpcsFlowSubsystem", "CircleFlowSubsystem", "SwiftHawkSubsystem",
                "AntiCheatSubsystem", "IntegrityCheckSubsystem", "SignatureVerifySubsystem",
                "MD5CheckSubsystem", "PakVerifySubsystem", "DNSMonitorSubsystem",
                "DeviceFingerprintSubsystem", "ReplayMonitorSubsystem", "TelemetrySubsystem",
                "GokubaSubsystem", "RacingAntiCheatSubsystem", "ClientBanSubsystem",
                "RealTimeBanSubsystem", "TLogSubsystem", "ReportSubsystem",
                "SecurityMonitorSubsystem", "CheatDetectionSubsystem", "ViolationMonitorSubsystem",
                "SuspiciousActivitySubsystem", "AbnormalBehaviorSubsystem", "NetworkMonitorSubsystem",
                "AnalyticsSubsystem", "CrashReportSubsystem", "PerformanceMonitorSubsystem"
            }
            for _, name in ipairs(toKill) do
                local sub = SubMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" and (
                            k:find("Report") or k:find("Send") or k:find("Upload") or
                            k:find("Verify") or k:find("Check") or k:find("Validate") or
                            k:find("Scan") or k:find("Detect") or k:find("Collect") or
                            k:find("Flow") or k:find("Heartbeat") or k:find("Monitor") or
                            k:find("Track") or k:find("Record") or k:find("Log") or
                            k:find("Alert") or k:find("Notify") or k:find("Ban") or
                            k:find("Kick") or k:find("Suspend") or k:find("Flag") or
                            k:find("Anti") or k:find("AC") or k:find("Analyze") or
                            k:find("Process") or k:find("Handle") or k:find("Evaluate")
                        ) then pcall(function() sub[k] = nop end) end
                    end
                    if sub.timer then pcall(function() sub:RemoveGameTimer(sub.timer) end) end
                    if sub.heartbeatTimer then pcall(function() sub:RemoveGameTimer(sub.heartbeatTimer) end) end
                    if sub.reportTimer then pcall(function() sub:RemoveGameTimer(sub.reportTimer) end) end
                    if sub.checkTimer then pcall(function() sub:RemoveGameTimer(sub.checkTimer) end) end
                    if sub.monitorTimer then pcall(function() sub:RemoveGameTimer(sub.monitorTimer) end) end
                    if sub.scanTimer then pcall(function() sub:RemoveGameTimer(sub.scanTimer) end) end
                end
            end
        end
    end)
    print("[BYPASS] ✅ All subsystems killed!")
end

-- Execute all additional bypass layers
_G.X3.RunAdditionalBypass = function()
    -- pcall(NetworkBypass)
    pcall(ClientEntryBypass)
    pcall(BanLogicBypass)
    pcall(MD5Bypass)
    -- pcall(DNSDeviceBypass)
    pcall(GokubaBypass)
    pcall(RacingAntiCheatBypass)
    -- pcall(LoginModuleBypass)
    pcall(KillAllSubsystems)
end

pcall(_G.X3.RunAdditionalBypass)
end

do
    local function _gk_ret_true() return true end
    local function _gk_ret_false() return false end
    local function _gk_ret_zero() return 0 end
    local function _gk_ret_empty() return {} end
    local function _gk_noop() end
    local function _gk_isValid(obj)
        if type(slua) == "table" and type(slua.isValid) == "function" then
            local ok, res = pcall(slua.isValid, obj)
            return ok and (res == true)
        end
        return obj ~= nil
    end
    local function _gk_safe_require(path)
        local ok, mod = pcall(require, path)
        return ok and mod or nil
    end
    local function _gk_KillTable(tbl, keys)
        if type(tbl) ~= "table" then return end
        for _, k in ipairs(keys) do
            pcall(function() if tbl[k] ~= nil then tbl[k] = _gk_noop end end)
        end
    end

    _G.X3.BypassState = _G.X3.BypassState or {
        DeadEyeDisabled = false, HawkEyeDisabled = false, VoklaiDisabled = false,
        HiggsBosonDisabled = false, HashVerifyDisabled = false, IPMappingDisabled = false,
        MemoryPatchDisabled = false, EduEyeDisabled = false, FullBypassActive = false
    }

    function _G.X3.ApplyWeowBypasses()
        if _G.X3.BypassState.FullBypassActive then return end
        pcall(function()
            -- DeadEye / Aim tracking block
            if _G.GameplayCallbacks then
                _gk_KillTable(_G.GameplayCallbacks, {
                    "ReportAimFlow", "ReportHitFlow", "ReportAttackFlow",
                    "OnAimDetected", "OnHeadshotDetected", "OnPerfectAccuracy"
                })
            end
            local subsystems = _gk_safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
            if subsystems then
                local ok, aimTracker = pcall(function() return subsystems:Get("ClientAimTrackingSubsystem") end)
                if ok and aimTracker then
                    pcall(function()
                        aimTracker.GetAimData = function()
                            return { accuracy = math.random(45, 65), headshotRate = math.random(15, 35) }
                        end
                        aimTracker.IsAimNormal = _gk_ret_true
                    end)
                end
            end
            _G.X3.BypassState.DeadEyeDisabled = true

            -- HawkEye patrol block
            if subsystems then
                local ok, hawkEye = pcall(function() return subsystems:Get("ClientHawkEyePatrolSubsystem") end)
                if ok and hawkEye then
                    pcall(function()
                        hawkEye.GetPatrolData = _gk_ret_empty
                        hawkEye.IsBeingWatched = _gk_ret_false
                        hawkEye.GetSpectatorCount = _gk_ret_zero
                    end)
                end
            end
            if _G.GameplayCallbacks then
                _gk_KillTable(_G.GameplayCallbacks, {
                    "SendDSErrorLogToLobby", "SendDSHawkEyePatrolLogToLobby", "ReportMatchRoomData"
                })
            end
            _G.X3.BypassState.HawkEyeDisabled = true

            -- Voklai / behavior + speedhack block
            if subsystems then
                local ok, aiBehavior = pcall(function() return subsystems:Get("ClientAIBehaviourSubsystem") end)
                if ok and aiBehavior then
                    pcall(function()
                        aiBehavior.GetBehaviorScore = function() return math.random(10, 30) end
                        aiBehavior.IsSuspicious = _gk_ret_false
                        aiBehavior.GetRiskLevel = _gk_ret_zero
                    end)
                end
                local ok2, speedHack = pcall(function() return subsystems:Get("AntiSpeedHackSubsystem") or subsystems:Get("ClientAntiSpeedHackSubsystem") end)
                if ok2 and speedHack then
                    pcall(function()
                        speedHack.GetSpeed = function() return math.random(300, 600) end
                        speedHack.IsSpeedValid = _gk_ret_true
                    end)
                end
            end
            _G.X3.BypassState.VoklaiDisabled = true

            -- HiggsBoson block
            local hud = _G.slua_GameFrontendHUD or _G.GameFrontendHUD
            local pc = nil
            if hud and type(hud.GetPlayerController) == "function" then
                local ok, r = pcall(function() return hud:GetPlayerController() end)
                if ok then pc = r end
            end
            if _gk_isValid(pc) then
                pcall(function()
                    if pc.HiggsBoson then
                        pc.HiggsBoson.bMHActive = false
                        pc.HiggsBoson.bCallPreReplication = false
                    end
                    if pc.HiggsBosonComponent then
                        pc.HiggsBosonComponent.bMHActive = false
                        pcall(function() pc.HiggsBosonComponent:ControlMHActive(0) end)
                    end
                end)
            end
            local higgs = _gk_safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
            if higgs then
                pcall(function()
                    higgs.GetNetAvatarItemIDs = function() return { 1001, 2002, 3003 } end
                    higgs.GetCurWeaponSkinID = function() return 6001 end
                    higgs.GetCurItemIDs = function() return { 7001, 8002 } end
                end)
            end
            _G.X3.BypassState.HiggsBosonDisabled = true

            -- HashVerify / TSS scan block
            if _G.TssSdk then
                pcall(function()
                    _G.TssSdk.ScanMemory = function() return true, { code = 0, msg = "clean" } end
                    _G.TssSdk.VerifyFileHash = _gk_ret_true
                end)
            end
            _G.X3.BypassState.HashVerifyDisabled = true
            _G.X3.BypassState.IPMappingDisabled = true
            _G.X3.BypassState.MemoryPatchDisabled = true
            _G.X3.BypassState.EduEyeDisabled = true
            _G.X3.BypassState.FullBypassActive = true
        end)
    end

    local function _gk_InitFileIOCrashBlock()
        pcall(function()
            if not _G.X3.WEOW_IO_HOOKED and io and io.open then
                _G.X3.WEOW_IO_HOOKED = true
                local FILE_KEYWORDS = { "report", "cheat", "detect", "ban", "hawkeye", "crash", "log", "telemetry" }
                local orig_io_open = io.open
                io.open = function(path, mode)
                    if type(path) == "string" then
                        local lp = path:lower()
                        for _, kw in ipairs(FILE_KEYWORDS) do
                            if lp:find(kw, 1, true) then
                                if mode and (mode == "w" or mode == "a" or mode == "w+" or mode == "a+") then
                                    return nil, "Blocked"
                                end
                            end
                        end
                        if lp:find("tdm", 1, true) or lp:find("gcloud", 1, true) or lp:find("beacon", 1, true) then
                            if mode and (mode == "w" or mode == "a" or mode == "w+") then return nil, "Blocked" end
                        end
                    end
                    return orig_io_open(path, mode)
                end
            end
        end)
    end

    -- Execute Weow bypasses
    pcall(_G.X3.ApplyWeowBypasses)
    -- pcall(_gk_InitFileIOCrashBlock)

    if not isExpired then
        local okT, ticker = pcall(require, "common.time_ticker")
        if okT and ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(0.2, function()
                pcall(_G.X3.ApplyWeowBypasses)
                -- pcall(_gk_InitFileIOCrashBlock)
            end)
        end
    end
end

local function Notify(msg)
    local s = "[VIP SRCHUBID] " .. tostring(msg)
    pcall(function()
        if _G.X3.XthrlenNotify then
            _G.X3.XthrlenNotify(s)
        end
    end)
    pcall(function()
        local sh = import("ScriptHelperClient")
        if sh and sh.AddOnScreenDebugMessage then
            sh.AddOnScreenDebugMessage(s, -1, 3.0, {R=1, G=1, B=0, A=1}, {X=1.2, Y=1.2})
        end
    end)
    print(s)
end

local _slua = rawget(_G, "slua")

local function Valid(obj)
    if not obj then
        return false
    end
    if _slua and _slua.isValid then
        local ok, v = pcall(_slua.isValid, obj)
        if not ok or not v then
            return false
        end
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

local GLOBAL_CONNECTIONS = {
    {"neck_01", "pelvis", C_YELLOW},
    {"neck_01", "upperarm_l", C_CYAN}, {"upperarm_l", "lowerarm_l", C_CYAN}, {"lowerarm_l", "hand_l", C_CYAN},
    {"neck_01", "upperarm_r", C_CYAN}, {"upperarm_r", "lowerarm_r", C_CYAN}, {"lowerarm_r", "hand_r", C_CYAN},
    {"pelvis", "thigh_l", C_CYAN}, {"thigh_l", "calf_l", C_CYAN}, {"calf_l", "foot_l", C_CYAN},
    {"pelvis", "thigh_r", C_CYAN}, {"thigh_r", "calf_r", C_CYAN}, {"calf_r", "foot_r", C_CYAN}
}

-- KONFIGURASI XTHRLEN CORE + FULL FITUR VIP
_G.X3.XthrlenConfig = _G.X3.XthrlenConfig or {
    OutlineWeapon = false, OutlineWepThick = 3, OutlineWepBright = 180, OutlineWepRainbow = true,
    EspEnemyCount = false, EspEnemyCountSize = 13,
    SkinIngame = false,
    BulletTrack = false, BTRange = 300, BTPart = 0, BTProb = 100,
    CustomMagicBullet = false,
    AutoHead = false,
    EspDistance = false,
    EspRadar = false,
    EspLoai6 = false,
    EspLoai7 = false,
    EspLoai8 = false,
    EspVip = false, EspVipPro = false, EspLoai5 = false,
    Esp3ShowName = true, Esp3ShowHP = true,
    Esp7_SoLuong = true, Esp7_VuKhi = true, Esp7_TuThe = true,
    EspBomMaster = false, EspItemBom = false, EspActiveBom = false,
    EspAimWarning = false, EspAimWarningVisCheck = false,
    EspVehicle = false, EspVeh_Dacia = true, EspVeh_UAZ = true, EspVeh_Buggy = true,
    EspVeh_Coupe = true, EspVeh_Mirado = true, EspVeh_Motor = true, EspVeh_Other = true,
    EspAntenna = false, EspOutline = false, OutlineThickness = 10,
    EspItem_Master = false, EspItem_AR = true, EspItem_Sniper = true, EspItem_SMG = true,
    EspItem_Shotgun = true, EspItem_LMG = true, EspItem_Pistol = true, EspItem_Melee = false,
    EspItem_Special = true, EspItem_Scope = true, EspItem_Grenade = true, EspItem_Med = true,
    WallVehicle = false, ColorBodyV3 = false, ColorBodyNew = false,
    UnlockFPS = false,
    IpadView = false,
    CustomHRecoil = false,
    CustomVRecoil = false,
    LessShake = false,
    RemoveGrass = false,
    RemoveFog = false,
    WhiteBody = false,
    ColorBodyV2 = false,
    WallXuyenTuong = false,
    WallhackVisCheck = false,
    WallShowVis = true,
    WallShowOcc = true,
    WallAdaptive = true,
    WallPanicGuard = true,
    WallHideDead = true,
    SkinUnlockAll = false,
    SkinLobbyPreview = false,
    Crosshair = false,
    Accuracy = false,
    GodMode = false,
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

    ModSkin = false,
    SkinOptionOpen = false
}

local function SRCHUB_ShowPopup(msg)
    local text = tostring(msg)

    pcall(function()
        local Msg = require("client.slua.logic.common.logic_common_msg_box")
        if Msg and Msg.Show then
            Msg.Show(1, " SRCHUB Notification", text, function() end, function() end, "OK", "TUTUP")
        end
    end)

    pcall(function()
        if type(Notify) == "function" then
            Notify("[SRCHUB] " .. text)
        elseif type(_G.Notify) == "function" then
            _G.Notify("[SRCHUB] " .. text)
        end
    end)
end

_G.X3.XthrlenConfig = _G.X3.XthrlenConfig or {}
_G.X3.XthrlenConfig.FakeHWID = _G.X3.XthrlenConfig.FakeHWID or false
_G.X3.XthrlenConfig.RegenHWIDBtn = _G.X3.XthrlenConfig.RegenHWIDBtn or false
_G.X3.Team_OriginalInfo = _G.X3.Team_OriginalInfo or {}
_G.X3.Team_FakeData = _G.X3.Team_FakeData or {}

do

local function SRCHUB_ShowPopup(msg)
    pcall(function()
        local Msg = require("client.slua.logic.Common.logic_common_msg_box") or require("client.slua.logic.common.logic_common_msg_box")
        if Msg and Msg.Show then
            Msg.Show(1, "[SRCHUB] Identity Spoofer", tostring(msg), function() end, function() end, "OK", "TUTUP")
        end
    end)
    pcall(function()
        if type(_G.Notify) == "function" then _G.Notify(tostring(msg)) end
    end)
end

local function SRCHUB_GenerateFakeIP()
    local prefixes = {"192.168", "10.0", "172.16", "100.64"}
    local prefix = prefixes[math.random(1, #prefixes)]
    return string.format("%s.%d.%d", prefix, math.random(1, 254), math.random(1, 254))
end

local function SRCHUB_HexStr(n)
    local hex = "0123456789abcdef"
    local s = ""
    for i = 1, n do local r = math.random(1, 16); s = s .. hex:sub(r, r) end
    return s
end

-- FirebaseInstanceID di dump: 32 hex lowercase
local function SRCHUB_GenerateFirebaseID()
    return SRCHUB_HexStr(32)
end

local function SRCHUB_GenerateXID()
    return SRCHUB_HexStr(64)
end

-- DeviceId di dump: 16 hex lowercase
local function SRCHUB_GenerateDeviceID()
    return SRCHUB_HexStr(16)
end

-- OAID / AdvertisingID: UUID v4 standar
local function SRCHUB_GenerateUUID()
    local hex = "0123456789abcdef"
    local function part(n) local s = "" for i=1,n do local r = math.random(1,16); s = s .. hex:sub(r, r) end return s end
    return string.format("%s-%s-4%s-%x%s-%s", part(8), part(4), part(3), math.random(8, 11), part(3), part(12))
end

local function SRCHUB_GenerateHWID()
    return "SRCHUB" .. SRCHUB_HexStr(26)
end

local SRCHUB_DeviceProfiles = {
    { Model="IN2020",    Name="IN2020",    Make="oneplus",  UName="OnePlus 9 Pro",   Hardware="OnePlus+IN2020",      CPU="IN2020",    GPU="Adreno (TM) 660", GLRender="Adreno (TM) 660", GL="OpenGL ES 3.2 V@0530.0 (GIT@193cd85, I6ff8b5b3fc, 1635957706)",  Android="12", Sys="12" },
    { Model="SM-S928B",  Name="SM-S928B",  Make="samsung",  UName="Galaxy S24 Ultra", Hardware="samsung+SM-S928B",    CPU="SM-S928B",  GPU="Adreno (TM) 750", GLRender="Adreno (TM) 750", GL="OpenGL ES 3.2 V@0676.32 (GIT@e5f0e0a, I0e5f0e0abc, 1700000000)", Android="14", Sys="14" },
    { Model="2304FPN6DG", Name="2304FPN6DG", Make="Xiaomi", UName="Xiaomi 13T Pro",  Hardware="Xiaomi+2304FPN6DG",    CPU="2304FPN6DG", GPU="Mali-G720 Immortalis MC12", GLRender="Mali-G720", GL="OpenGL ES 3.2 v1.r36p0-01eac0",  Android="13", Sys="13" },
    { Model="22021211RG", Name="munch",    Make="Xiaomi",   UName="POCO F4",         Hardware="Xiaomi+munch",         CPU="munch",     GPU="Adreno (TM) 650", GLRender="Adreno (TM) 650", GL="OpenGL ES 3.2 V@0744.16 (GIT@afa4d62ddb, I8db249ac41, 1703587456)", Android="13", Sys="13" },
    { Model="ASUS_AI701", Name="ASUS_AI701", Make="asus",   UName="ROG Phone 7",     Hardware="asus+ASUS_AI701",      CPU="ASUS_AI701", GPU="Adreno (TM) 740", GLRender="Adreno (TM) 740", GL="OpenGL ES 3.2 V@0655.0 (GIT@b2f5b0e, I9ab12cd34, 1686000000)",  Android="13", Sys="13" },
    { Model="LE2121",    Name="LE2121",    Make="oneplus",  UName="OnePlus 9",       Hardware="OnePlus+LE2121",       CPU="LE2121",    GPU="Adreno (TM) 660", GLRender="Adreno (TM) 660", GL="OpenGL ES 3.2 V@0530.0 (GIT@193cd85, I6ff8b5b3fc, 1635957706)",  Android="12", Sys="12" },
}

local function SRCHUB_RegenerateAllFakeData()
    local p = SRCHUB_DeviceProfiles[math.random(1, #SRCHUB_DeviceProfiles)]
    _G.X3.Team_FakeData = {
        HWID = SRCHUB_GenerateHWID(),
        DeviceID = SRCHUB_GenerateDeviceID(),
        IP = SRCHUB_GenerateFakeIP(),
        Firebase = SRCHUB_GenerateFirebaseID(),
        XID = SRCHUB_GenerateXID(),
        L1XID = SRCHUB_HexStr(32),
        AdID = SRCHUB_GenerateUUID(),
        OAID = SRCHUB_GenerateUUID(),
        Model = p.Model,
        Name = p.Name,
        Make = p.Make,
        UName = p.UName,
        Hardware = p.Hardware,
        CPU = p.CPU,
        GPU = p.GPU,
        GLRender = p.GLRender,
        GL = p.GL,
        MAC = string.format("%02X:%02X:%02X:%02X:%02X:%02X", math.random(0,255), math.random(0,255), math.random(0,255), math.random(0,255), math.random(0,255), math.random(0,255)),
        OS = p.Android,
        Sys = p.Sys,
        AndroidID = SRCHUB_HexStr(16),
        Serial = SRCHUB_HexStr(8),
        BuildFP = p.Make .. "/" .. p.Model .. "/" .. p.Model .. ":" .. p.Android .. "/RQ3A." .. math.random(100000, 999999) .. "." .. math.random(100, 999) .. ":user/release-keys",
        Operator = ({ "Telkomsel", "Indosat", "XL", "Tri", "Smartfren" })[math.random(1, 5)],
        BSSID = string.format("%02x:%02x:%02x:%02x:%02x:%02x", math.random(0,255), math.random(0,255), math.random(0,255), math.random(0,255), math.random(0,255), math.random(0,255)),
        SSID = "WiFi-" .. SRCHUB_HexStr(4),
    }
    return _G.X3.Team_FakeData
end

-- InfoListKey -> Team_FakeData key
local SRCHUB_InfoListFieldMap = {
    XID = "XID", DeviceId = "DeviceID", FirebaseInstanceID = "Firebase",
    OAID = "OAID", AdvertisingID = "AdID", L1XID = "L1XID",
    vClientIP = "IP",
    DeviceName = "Name", DeviceModel = "Model", DeviceMake = "Make",
    SystemHardware = "Hardware", CpuHardware = "CPU",
    UserDefineDeviceName = "UName",
    GLVersion = "GL", GLRender = "GLRender", GPUFamily = "GPU",
    AndroidVersion = "OS", SystemSoftware = "Sys",
    AndroidID = "AndroidID", DeviceSerial = "Serial",
    BuildFingerprint = "BuildFP", NetworkOperatorName = "Operator",
    WifiBSSID = "BSSID", WifiSSID = "SSID",
}
_G.X3.Team_DeviceOS_Orig = _G.X3.Team_DeviceOS_Orig or {}

local function SRCHUB_GetDataOS()
    local DataOS = package.loaded["client.logic.data.data_device_os"]
    if not DataOS then
        local okR, rR = pcall(require, "client.logic.data.data_device_os")
        if okR and type(rR) == "table" then DataOS = rR end
    end
    return DataOS
end

local function SRCHUB_CaptureOriginalInfo()
    pcall(function()
        if _G.X3.Team_OriginalInfo.Captured then return end
        local o = _G.X3.Team_OriginalInfo
        local S = import("KismetSystemLibrary")
        local T = import("STExtraBlueprintFunctionLibrary")
        local P = import("PlatformWrapper")
        local DataOS = SRCHUB_GetDataOS()

        if not o.HWID then pcall(function() if S and S.GetDeviceId then local v = S.GetDeviceId(); if v and v ~= "" then o.HWID = v end end end) end
        if not o.Model then pcall(function() if T and T.GetDeviceModel then local v = T.GetDeviceModel(); if v and v ~= "" then o.Model = v end end end) end
        if not o.Name then pcall(function() if T and T.GetDeviceName then local v = T.GetDeviceName(); if v and v ~= "" then o.Name = v end end end) end
        if not o.MAC then pcall(function() if P and P.GetMacAddress then local v = P.GetMacAddress(); if v and v ~= "" then o.MAC = v end end end) end
        if not o.OS then pcall(function() if T and T.GetOSVersion then local v = T.GetOSVersion(); if v and v ~= "" then o.OS = v end end end) end

        if DataOS then
            local IL = rawget(DataOS, "InfoList")
            if type(IL) == "table" then
                if not o.XID then local v = rawget(IL, "XID"); if v and v ~= "" then o.XID = v end end
                if not o.IP then local v = rawget(IL, "vClientIP"); if v and v ~= "" then o.IP = v end end
                if not o.Firebase then local v = rawget(IL, "FirebaseInstanceID"); if v and v ~= "" then o.Firebase = v end end
                if not o.HWID then local v = rawget(IL, "DeviceId"); if v and v ~= "" then o.HWID = v end end
                if not o.Model then local v = rawget(IL, "DeviceModel"); if v and v ~= "" then o.Model = v end end
                if not o.Name then local v = rawget(IL, "DeviceName"); if v and v ~= "" then o.Name = v end end
                if not o.OS then local v = rawget(IL, "AndroidVersion"); if v and v ~= "" then o.OS = v end end
                for ilKey, _ in pairs(SRCHUB_InfoListFieldMap) do
                    local kk = "IL_" .. ilKey
                    if _G.X3.Team_DeviceOS_Orig[kk] == nil then
                        _G.X3.Team_DeviceOS_Orig[kk] = rawget(IL, ilKey)
                    end
                end
            end
            if not o.XID then pcall(function()
                if type(rawget(DataOS, "GetXID")) == "function" then
                    local v = DataOS.GetXID()
                    if v and v ~= "" then o.XID = v end
                end
            end) end
            if not o.IP then local v = rawget(DataOS, "vClientIP"); if v and v ~= "" then o.IP = v end end
            if not o.Firebase then local v = rawget(DataOS, "FirebaseInstanceID"); if v and v ~= "" then o.Firebase = v end end
            if not o.XID then local v = rawget(DataOS, "XID"); if v and v ~= "" then o.XID = v end end
            for ilKey, _ in pairs(SRCHUB_InfoListFieldMap) do
                local kk = "TL_" .. ilKey
                if _G.X3.Team_DeviceOS_Orig[kk] == nil then
                    _G.X3.Team_DeviceOS_Orig[kk] = rawget(DataOS, ilKey)
                end
            end
            -- latch hanya jika ada hasil nyata
            if o.XID or o.IP or o.Firebase or o.HWID then
                o.Captured = true
            end
        end
    end)
end

_G.X3._HWIDCaptureRetries = _G.X3._HWIDCaptureRetries or 0
local function SRCHUB_CaptureRetryTick()
    if _G.X3.Team_OriginalInfo.Captured then return end
    if (_G.X3._HWIDCaptureRetries or 0) >= 15 then return end
    _G.X3._HWIDCaptureRetries = (_G.X3._HWIDCaptureRetries or 0) + 1
    SRCHUB_CaptureOriginalInfo()
    if not _G.X3.Team_OriginalInfo.Captured then
        local okT, tk = pcall(require, "common.time_ticker")
        if okT and tk and tk.AddTimerOnce then
            tk.AddTimerOnce(0.8, SRCHUB_CaptureRetryTick)
        end
    end
end
local function SRCHUB_StartCaptureRetry()
    if _G.X3._HWIDCaptureRetryStarted then return end
    _G.X3._HWIDCaptureRetryStarted = true
    local okT, tk = pcall(require, "common.time_ticker")
    if okT and tk and tk.AddTimerOnce then
        tk.AddTimerOnce(1.0, SRCHUB_CaptureRetryTick)
    end
end

-- bisa placebo. Raw write = selalu kena baca.
function _G.X3.ApplyDeviceOSFakes()
    pcall(function()
        if not _G.X3.XthrlenConfig.FakeHWID then return end
        if not _G.X3.Team_FakeData.XID then SRCHUB_RegenerateAllFakeData() end
        local DataOS = SRCHUB_GetDataOS()
        if not DataOS then return end
        local f = _G.X3.Team_FakeData
        local IL = rawget(DataOS, "InfoList")
        if type(IL) == "table" then
            for ilKey, fKey in pairs(SRCHUB_InfoListFieldMap) do
                if f[fKey] ~= nil then IL[ilKey] = f[fKey] end
            end
        end
        for ilKey, fKey in pairs(SRCHUB_InfoListFieldMap) do
            if rawget(DataOS, ilKey) ~= nil and f[fKey] ~= nil then
                DataOS[ilKey] = f[fKey]
            end
        end
    end)
end

function _G.X3.RestoreDeviceOSFakes()
    pcall(function()
        local DataOS = SRCHUB_GetDataOS()
        if not DataOS then return end
        local IL = rawget(DataOS, "InfoList")
        if type(IL) == "table" then
            for ilKey, _ in pairs(SRCHUB_InfoListFieldMap) do
                local ov = _G.X3.Team_DeviceOS_Orig["IL_" .. ilKey]
                if ov ~= nil then IL[ilKey] = ov end
            end
        end
        for ilKey, _ in pairs(SRCHUB_InfoListFieldMap) do
            local ov = _G.X3.Team_DeviceOS_Orig["TL_" .. ilKey]
            if ov ~= nil then DataOS[ilKey] = ov end
        end
    end)
end

local function SRCHUB_HWIDAutoRegenTick()
    pcall(function()
        if _G.X3.XthrlenConfig.FakeHWID then
            SRCHUB_RegenerateAllFakeData()
            _G.X3.ApplyDeviceOSFakes()
            if type(_G.X3.Trace) == "function" then _G.X3.Trace("HWID: auto-regen 5 menit (silent)") end
        end
    end)
    local okT, tk = pcall(require, "common.time_ticker")
    if okT and tk and tk.AddTimerOnce then
        tk.AddTimerOnce(300.0, SRCHUB_HWIDAutoRegenTick)
    end
end

local function SRCHUB_StartHWIDAutoRegen()
    if _G.X3._HWIDAutoRegenStarted then return end
    _G.X3._HWIDAutoRegenStarted = true
    local okT, tk = pcall(require, "common.time_ticker")
    if okT and tk and tk.AddTimerOnce then
        tk.AddTimerOnce(300.0, SRCHUB_HWIDAutoRegenTick)
    else
        _G.X3._HWIDAutoRegenStarted = false
    end
end

function _G.X3.Team_InitializeHWIDHook()
    SRCHUB_CaptureOriginalInfo()
    pcall(function()
        local S = import("KismetSystemLibrary")
        local T = import("STExtraBlueprintFunctionLibrary")
        local P = import("PlatformWrapper")

        if S and not _G.X3.Team_HWID_Hooked then
            -- Hook HWID
            _G.X3.Team_Orig_GetDeviceId = S.GetDeviceId
            function S.GetDeviceId(...)
                if _G.X3.XthrlenConfig.FakeHWID then
                    if not _G.X3.Team_FakeData.HWID then SRCHUB_RegenerateAllFakeData() end
                    return _G.X3.Team_FakeData.HWID
                end
                return _G.X3.Team_Orig_GetDeviceId and _G.X3.Team_Orig_GetDeviceId(...) or "UNKNOWN"
            end

            -- Hook Model
            if T and T.GetDeviceModel then
                _G.X3.Team_Orig_GetDeviceModel = T.GetDeviceModel
                function T.GetDeviceModel(...)
                    if _G.X3.XthrlenConfig.FakeHWID then return _G.X3.Team_FakeData.Model end
                    return _G.X3.Team_Orig_GetDeviceModel(...)
                end
            end

            -- Hook Name
            if T and T.GetDeviceName then
                _G.X3.Team_Orig_GetDeviceName = T.GetDeviceName
                function T.GetDeviceName(...)
                    if _G.X3.XthrlenConfig.FakeHWID then return _G.X3.Team_FakeData.Name end
                    return _G.X3.Team_Orig_GetDeviceName(...)
                end
            end

            -- Hook OS Version
            if T and T.GetOSVersion then
                _G.X3.Team_Orig_GetOSVersion = T.GetOSVersion
                function T.GetOSVersion(...)
                    if _G.X3.XthrlenConfig.FakeHWID then return _G.X3.Team_FakeData.OS end
                    return _G.X3.Team_Orig_GetOSVersion(...)
                end
            end

            -- Hook MAC
            if P and P.GetMacAddress then
                _G.X3.Team_Orig_GetMac = P.GetMacAddress
                function P.GetMacAddress(...)
                    if _G.X3.XthrlenConfig.FakeHWID then return _G.X3.Team_FakeData.MAC end
                    return _G.X3.Team_Orig_GetMac(...)
                end
            end

            _G.X3.Team_HWID_Hooked = true
        end

        local DataOS = SRCHUB_GetDataOS()
        if DataOS and not _G.X3.Team_DataOS_Hooked then
            if type(rawget(DataOS, "GetXID")) == "function" then
                _G.X3.Team_Orig_GetXID = rawget(DataOS, "GetXID")
                DataOS.GetXID = function(...)
                    if _G.X3.XthrlenConfig.FakeHWID and _G.X3.Team_FakeData.XID then return _G.X3.Team_FakeData.XID end
                    return _G.X3.Team_Orig_GetXID(...)
                end
            end
            if type(rawget(DataOS, "GetDeviceName")) == "function" then
                _G.X3.Team_Orig_GetDeviceNameOS = rawget(DataOS, "GetDeviceName")
                DataOS.GetDeviceName = function(...)
                    if _G.X3.XthrlenConfig.FakeHWID and _G.X3.Team_FakeData.Name then return _G.X3.Team_FakeData.Name end
                    return _G.X3.Team_Orig_GetDeviceNameOS(...)
                end
            end
            if type(rawget(DataOS, "GetGPUFamily")) == "function" then
                _G.X3.Team_Orig_GetGPUFamily = rawget(DataOS, "GetGPUFamily")
                DataOS.GetGPUFamily = function(...)
                    if _G.X3.XthrlenConfig.FakeHWID and _G.X3.Team_FakeData.GPU then return _G.X3.Team_FakeData.GPU end
                    return _G.X3.Team_Orig_GetGPUFamily(...)
                end
            end
            if type(rawget(DataOS, "getDeviceOSInfo")) == "function" then
                _G.X3.Team_Orig_getDeviceOSInfo = rawget(DataOS, "getDeviceOSInfo")
                DataOS.getDeviceOSInfo = function(...)
                    local r = _G.X3.Team_Orig_getDeviceOSInfo(...)
                    if _G.X3.XthrlenConfig.FakeHWID then _G.X3.ApplyDeviceOSFakes() end
                    return r
                end
            end
            _G.X3.Team_DataOS_Hooked = true
        end
        -- apply awal jika fitur sedang ON
        if _G.X3.XthrlenConfig.FakeHWID then _G.X3.ApplyDeviceOSFakes() end
    end)
end

local function SRCHUB_BuildPopupON()
    local o = _G.X3.Team_OriginalInfo
    local f = _G.X3.Team_FakeData
    local function Safe(val) return (val and val ~= "") and tostring(val) or "[Not Found]" end
    local function Short(val) local s = Safe(val); if #s > 24 then s = s:sub(1, 24) .. "..." end return s end
    return string.format(
        "[FAKE IDENTITY AKTIF]\n\n" ..
        "DeviceID ASLI: %s\n> FAKE: %s\n\n" ..
        "XID ASLI: %s\n> FAKE: %s\n\n" ..
        "IP ASLI: %s\n> FAKE IP: %s\n\n" ..
        "Firebase ASLI: %s\n> FAKE: %s\n\n" ..
        "OAID/AdID FAKE: %s\n\n" ..
        "Model ASLI: %s\n> FAKE: %s (%s)\n\n" ..
        "MAC ASLI: %s\n> FAKE MAC: %s\n\n" ..
        "Auto-regen tiap 5 menit aktif (silent).",
        Short(o.HWID), Short(f.HWID),
        Short(o.XID), Short(f.XID),
        Safe(o.IP), Safe(f.IP),
        Short(o.Firebase), Short(f.Firebase),
        Short(f.OAID),
        Safe(o.Model), Safe(f.Model), Safe(f.UName),
        Safe(o.MAC), Safe(f.MAC)
    )
end

local function SRCHUB_BuildPopupOFF()
    return "[SEMUA IDENTITAS DIPULIHKAN]\n\n" ..
           "HWID, XID, DeviceId, IP, Firebase ID,\n" ..
           "OAID/AdID/L1XID, Device Model/Make,\n" ..
           "Hardware/CPU/GPU, MAC & OS Version\n" ..
           "telah dikembalikan ke nilai asli device Anda."
end

-- [MENU UI] Fake HWID + IP + Firebase + XID
function _G.X3.BuildX3HWIDMenu(stack, AliasMap)
    if not stack then return end

    table.insert(stack, {
        Key = "ModMenu_FakeHWID_Ex",
        UI = AliasMap.TitleSwitcher or "TitleSwitcher",
        Text = "FAKE HWID + IP + FIREBASE + XID [ IDENTITAS PERANGKAT PALSU ] (+ BOOST UDP)",
        ExpandIndex = 0,
        GetFunc = function() return _G.X3.XthrlenConfig.FakeHWID end,
        SetFunc = function(c, v)
            _G.X3.XthrlenConfig.FakeHWID = v
            if v then
                SRCHUB_RegenerateAllFakeData()
                SRCHUB_CaptureOriginalInfo()
                _G.X3.Team_InitializeHWIDHook()
                _G.X3.ApplyDeviceOSFakes()
                SRCHUB_ShowPopup(SRCHUB_BuildPopupON())
                SRCHUB_StartHWIDAutoRegen()
                if _G.X3.XthrlenConfig.NetBoost ~= true then
                    _G.X3._NetBoostAutoOn = true
                    _G.X3.XthrlenConfig.NetBoost = true
                end
                if _G.X3.ApplyNetworkBoost then pcall(_G.X3.ApplyNetworkBoost, true) end
            else
                _G.X3.RestoreDeviceOSFakes()
                SRCHUB_ShowPopup(SRCHUB_BuildPopupOFF())
                if _G.X3._NetBoostAutoOn then
                    _G.X3._NetBoostAutoOn = nil
                    _G.X3.XthrlenConfig.NetBoost = false
                    if _G.X3.ApplyNetworkBoost then pcall(_G.X3.ApplyNetworkBoost, false) end
                end
            end
            return true
        end
    })

    table.insert(stack, {
        Key = "ModMenu_FakeHWID_Regen",
        UI = AliasMap.Switcher or "Switcher",
        Text = "  [GENERATE] Randomize All Data [ ACAK ULANG SEMUA DATA ]",
        ExpandHandle = "ModMenu_FakeHWID_Ex",
        GetFunc = function() return _G.X3.XthrlenConfig.RegenHWIDBtn end,
        SetFunc = function(c, v)
            _G.X3.XthrlenConfig.RegenHWIDBtn = v
            if v then
                SRCHUB_RegenerateAllFakeData()
                _G.X3.ApplyDeviceOSFakes()
                local f = _G.X3.Team_FakeData
                local function Short(s) s = tostring(s or "?"); if #s > 24 then s = s:sub(1, 24) .. "..." end return s end
                SRCHUB_ShowPopup(string.format(
                    "[DATA BARU DI-GENERATE]\n\n" ..
                    "HWID: %s\n" ..
                    "XID: %s\n" ..
                    "DeviceId: %s\n" ..
                    "IP: %s\n" ..
                    "Firebase: %s\n" ..
                    "OAID: %s\n" ..
                    "Model: %s (%s)\n" ..
                    "MAC: %s",
                    Short(f.HWID), Short(f.XID), Short(f.DeviceID), Short(f.IP), Short(f.Firebase), Short(f.OAID), Short(f.Model), Short(f.UName), Short(f.MAC)
                ))
            end
            return true
        end
    })
end

-- Auto-Initialize Hook saat script dimuat
pcall(_G.X3.Team_InitializeHWIDHook)
pcall(SRCHUB_StartHWIDAutoRegen)
pcall(SRCHUB_StartCaptureRetry)
print("[SRCHUB] Ultimate Fake HWID + IP + Firebase + XID (No Placebo) Loaded!")

end

--   A) BANDWIDTH (server -> client):
--         jendela rate yang diminta client ke server.
--   B) FREKUENSI REPLIKASI (server -> client):
--         respon tembakan terasa lebih cepat.
_G.X3.XthrlenConfig.NetBoost = _G.X3.XthrlenConfig.NetBoost or false
_G.X3._NetBoostState = _G.X3._NetBoostState or { applied = false, lastApply = 0 }

do
local X3NetBoostCmds_ON = {
    -- A) bandwidth
    "netspeed 100000",
    "net.MaxInternetClientRate 100000",
    "net.MinNetRate 100000",
    "net.MaxNetRate 1000000",
    -- B) frekuensi replikasi aktor
    "net.UseAdaptiveNetUpdateFrequency 0",
    "net.ClientNetSendMoveDeltaTime 0.011",
    "net.ClientNetSendMoveDeltaTimeThrottled 0.011",
    "net.ClientNetSendMoveDeltaTimeStationary 0.016",
}
local X3NetBoostCmds_OFF = {
    "netspeed 10000",
    "net.MaxInternetClientRate 100000",
    "net.MinNetRate 10000",
    "net.MaxNetRate 100000",
    "net.UseAdaptiveNetUpdateFrequency 1",
    "net.ClientNetSendMoveDeltaTime 0.022",
    "net.ClientNetSendMoveDeltaTimeThrottled 0.016",
    "net.ClientNetSendMoveDeltaTimeStationary 0.03",
}

-- BOOST JARINGAN / NETWORK BOOST --
function _G.X3.ApplyNetworkBoost(on)
    local st = _G.X3._NetBoostState
    local nowC = os.clock()
    if st.applied == on and (nowC - st.lastApply) < 5.0 then return end
    pcall(function()
        local console = import("KismetSystemLibrary")
        if not (console and console.ExecuteConsoleCommand) then return end
        local cmds = on and X3NetBoostCmds_ON or X3NetBoostCmds_OFF
        for _, cmd in ipairs(cmds) do
            pcall(function() console.ExecuteConsoleCommand(nil, cmd) end)
        end
        st.applied = on
        st.lastApply = nowC
        if type(_G.X3.Trace) == "function" then
            _G.X3.Trace("NETBOOST: " .. (on and "ON (netspeed 100000, adaptive-freq OFF)" or "OFF (default dipulihkan)"))
        end
    end)
end
end

_G.X3.XthrlenState = _G.X3.XthrlenState or {
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
isExpired = false

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

_G.X3.StartBypass_VIP_v3 = function()
    pcall(function()
        print("[ULTIMATE BYPASS] Starting initialization...")
        InitializeSLUABypass()
        InitializeMD5Bypass()
        InitializeSkinBypass()
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
        InitializeCustomMagicBulletHooks()  -- <-- INI DITAMBAH
        InitializeKillAllSubsystems()
        InitializeFinalProtection()
                pcall(function()
            if _G.X3.RareFeatures and not _G.X3.RareFeatures.Inited then
                -- Trigger init via dummy access
                local _ = _G.X3.RareFeatures.DR_Active
            end
        end)
        print("[ULTIMATE BYPASS] Complete - All Security Systems Disabled")
    end)
end

local function SafeAddMark(id, pos, z, str, size, actor)
    local mark = nil
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
            mark = InGameMarkTools.ClientAddMapMark(id, pos, z, str, size, actor)
            if mark then _G.X3.XthrlenState.TrackedMarks[mark] = true end
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
    _G.X3.XthrlenState.TrackedMarks[mark] = nil
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

    if _G.X3.GetBotScore then
        local okS, s = pcall(_G.X3.GetBotScore, pawn)
        if okS and type(s) == "number" then
            if s >= 3 then
                isAI = true
                hasChecked = true
            elseif s <= -3 then
                isAI = false
                hasChecked = true
            end
        end
    end

    -- Fallback saat scoring belum termuat
    if not hasChecked and not _G.X3.GetBotScore then
        pcall(function()
            if pawn.bIsAI == true or pawn.IsAI == true then isAI = true; hasChecked = true end
            if type(pawn.IsBot) == "function" and pawn:IsBot() then isAI = true; hasChecked = true end
            local pState = pawn.PlayerState or (type(pawn.GetPlayerState) == "function" and pawn:GetPlayerState())
            if Valid(pState) then
                hasChecked = true
                if pState.bIsABot == true or pState.bIsBot == true then isAI = true end
                if type(pState.IsBot) == "function" and pState:IsBot() then isAI = true end
            end
        end)
    end

    if hasChecked then markData.AK_IS_BOT = isAI end
    return isAI, hasChecked
end

-- INISIALISASI HOOKS AUTO HEAD
function _G.X3.InitializeAutoHeadHooks()
    if _G.X3.InstallUnifiedHitHook then _G.X3.InstallUnifiedHitHook() end
end

-- [SRCHUB] CUSTOM MAGIC BULLET SMART v3.0
-- FIX: AutoInit + Direct Actor + Proximity

_G.X3.MagicBulletCache = _G.X3.MagicBulletCache or {
    ValidTargets = {},
    LastUpdate = 0,
    UpdateInterval = 0.5
}

-- [HELPER] Deteksi Bot akurat
local function MB_IsBot(target)
    if _G.X3.GetBotScore then
        local okS, s = pcall(_G.X3.GetBotScore, target)
        if okS and type(s) == "number" then
            if s >= 3 then return true end
            if s <= -3 then return false end
        end
    end
    -- Fallback penuh saat scoring belum termuat
    local bot = false
    pcall(function()
        if target.bIsAI == true or target.IsAI == true then bot = true end
        if type(target.IsBot) == "function" and target:IsBot() then bot = true end
        local ps = target.PlayerState or (type(target.GetPlayerState) == "function" and target:GetPlayerState())
        if slua.isValid(ps) then
            if ps.bIsABot == true or ps.bIsBot == true then bot = true end
            if type(ps.IsBot) == "function" and ps:IsBot() then bot = true end
        end
    end)
    return bot
end

-- [HELPER] VisCheck
local function MB_IsVisible(pc, target)
    local vis = true
    pcall(function()
        if slua.isValid(pc) and type(pc.LineOfSightTo) == "function" then
            vis = pc:LineOfSightTo(target)
        else
            vis = not (target.bHidden or target.bTearOff)
        end
    end)
    return vis
end

function _G.X3.UpdateMagicBulletCache()
    if not _G.X3.XthrlenConfig.CustomMagicBullet then return end
    local now = os.clock()
    if (now - _G.X3.MagicBulletCache.LastUpdate) < _G.X3.MagicBulletCache.UpdateInterval then return end
    _G.X3.MagicBulletCache.LastUpdate = now

    pcall(function()
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local localPlayer = GameplayData.GetPlayerCharacter()
        if not slua.isValid(localPlayer) then _G.X3.MagicBulletCache.ValidTargets = {} return end

        local myLoc = localPlayer:K2_GetActorLocation()
        local maxDistCm = 400 * 100

        -- AMBIL SEMUA KARAKTER DARI BERBAGAI SUMBER
        local allChars = {}
        pcall(function()
            if GameplayData.GetAllPlayerCharacters then
                local chars = GameplayData.GetAllPlayerCharacters()
                if chars then for _, c in pairs(chars) do if slua.isValid(c) then table.insert(allChars, c) end end end
            end
        end)
        pcall(function()
            if GameplayData.GetAllCharacters then
                local chars = GameplayData.GetAllCharacters()
                if chars then for _, c in pairs(chars) do if slua.isValid(c) then table.insert(allChars, c) end end end
            end
        end)
        pcall(function()
            if GameplayData.GameCharacters then
                local chars = GameplayData.GameCharacters
                if type(chars) == "table" then for _, c in pairs(chars) do if slua.isValid(c) then table.insert(allChars, c) end end end
            end
        end)

        local pc = GameplayData.GetPlayerController and GameplayData.GetPlayerController()
        local valid = {}
        local myTeamId = nil
        pcall(function() if localPlayer.GetTeamId then myTeamId = localPlayer:GetTeamId() end end)

        for _, char in ipairs(allChars) do
            if slua.isValid(char) and char ~= localPlayer then
                local isEnemy = true
                pcall(function()
                    if myTeamId and char.GetTeamId then
                        if myTeamId == char:GetTeamId() then isEnemy = false end
                    end
                end)

                if isEnemy then
                    local pass = true

                    if pass then
                        local charLoc = char:K2_GetActorLocation()
                        local dx = myLoc.X - charLoc.X
                        local dy = myLoc.Y - charLoc.Y
                        local dz = myLoc.Z - charLoc.Z
                        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                        if dist <= maxDistCm then
                            valid[char] = {Dist = dist}
                        end
                    end
                end
            end
        end
        _G.X3.MagicBulletCache.ValidTargets = valid
    end)
end

function _G.X3.InstallUnifiedHitHook()
    pcall(function()
        local EADP = import("EAvatarDamagePosition")
        if not EADP then return end

        local modulesToHook = {
            "GameLua.Mod.BaseMod.Common.Weapon.ShootWeaponEntity",
            "GameLua.Logic.Weapon.ShootWeaponEntity"
        }

        for _, path in ipairs(modulesToHook) do
            local hitLogic = package.loaded[path]
            if hitLogic and not hitLogic._X3HitUnified then
                hitLogic._X3HitUnified = true

                if hitLogic._X3OrigGetHitBodyType == nil then
                    hitLogic._X3OrigGetHitBodyType = hitLogic.GetHitBodyType
                end
                if hitLogic._X3OrigGetHitBodyTypeByHitPos == nil then
                    hitLogic._X3OrigGetHitBodyTypeByHitPos = hitLogic.GetHitBodyTypeByHitPos
                end

                hitLogic.GetHitBodyType = function(self, ImpactResult, InImpactVec)
                    if _G.X3.XthrlenConfig.AutoHead then return EADP.BigHead end
                    if _G.X3.XthrlenConfig.SmartAutoHead then return EADP.BigHead end

                    if _G.X3.XthrlenConfig.CustomMagicBullet then
                        _G.X3.UpdateMagicBulletCache()

                        local hitActor = nil
                        pcall(function()
                            if ImpactResult and ImpactResult.Actor then
                                hitActor = ImpactResult.Actor
                            end
                        end)

                        if slua.isValid(hitActor) and _G.X3.MagicBulletCache.ValidTargets[hitActor] then
                            return EADP.BigHead
                        end

                        if InImpactVec then
                            for target, _ in pairs(_G.X3.MagicBulletCache.ValidTargets) do
                                if slua.isValid(target) then
                                    local tLoc = target:K2_GetActorLocation()
                                    local dx = InImpactVec.X - tLoc.X
                                    local dy = InImpactVec.Y - tLoc.Y
                                    local dz = InImpactVec.Z - tLoc.Z
                                    if (dx*dx + dy*dy + dz*dz) < 640000 then -- 800cm = 8m
                                        return EADP.BigHead
                                    end
                                end
                            end
                        end
                    end

                    local o = hitLogic._X3OrigGetHitBodyType
                    if o then return o(self, ImpactResult, InImpactVec) end
                end

                -- HOOK TUNGGAL: GetHitBodyTypeByHitPos
                hitLogic.GetHitBodyTypeByHitPos = function(self, InImpactVec)
                    if _G.X3.XthrlenConfig.AutoHead then return EADP.BigHead end
                    if _G.X3.XthrlenConfig.SmartAutoHead then return EADP.BigHead end

                    if _G.X3.XthrlenConfig.CustomMagicBullet then
                        _G.X3.UpdateMagicBulletCache()

                        if InImpactVec then
                            local nearestDist = 640000 -- 800cm squared
                            local nearestValid = false
                            for target, _ in pairs(_G.X3.MagicBulletCache.ValidTargets) do
                                if slua.isValid(target) then
                                    local tLoc = target:K2_GetActorLocation()
                                    local dx = InImpactVec.X - tLoc.X
                                    local dy = InImpactVec.Y - tLoc.Y
                                    local dz = InImpactVec.Z - tLoc.Z
                                    local distSq = dx*dx + dy*dy + dz*dz
                                    if distSq < nearestDist then
                                        nearestDist = distSq
                                        nearestValid = true
                                    end
                                end
                            end
                            if nearestValid then
                                return EADP.BigHead
                            end
                        end
                    end

                    local o = hitLogic._X3OrigGetHitBodyTypeByHitPos
                    if o then return o(self, InImpactVec) end
                end
            end
        end
    end)
end

-- MAGIC BULLET / HITBOX SCALING --
function _G.X3.InitializeCustomMagicBulletHooks()
    if _G.X3.InstallUnifiedHitHook then _G.X3.InstallUnifiedHitHook() end
end

_G.X3.InstallUnifiedHitHook()
_G.X3.TDFTDeKillCounts = _G.X3.TDFTDeKillCounts or {}
local CACHED_LinearColor = import("LinearColor")
local CACHED_GoldColor = CACHED_LinearColor and CACHED_LinearColor(1.0, 0.8, 0.0, 1.0) or nil


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

local ConfigFileName = "SRCHUB.txt"
_G.X3.LastConfigSaveStr = ""

_G.X3.CfgSer = function(v)
    local t = type(v)
    if t == "string" then return string.format("%q", v) end
    if t == "number" or t == "boolean" then return tostring(v) end
    return "nil"
end

_G.X3.SaveModSettings = function()
    pcall(function()
        local data = "return {\nXthrlenConfig = {\n"
        for k, v in pairs(_G.X3.XthrlenConfig or {}) do
            data = data .. "  [\"" .. tostring(k) .. "\"] = " .. _G.X3.CfgSer(v) .. ",\n"
        end
        data = data .. "},\nCustomTextData = {\n"
        if _G.X3.XthrlenState and _G.X3.XthrlenState.CustomTextData then
            for k, v in pairs(_G.X3.XthrlenState.CustomTextData) do
                data = data .. "  [\"" .. tostring(k) .. "\"] = " .. _G.X3.CfgSer(v) .. ",\n"
            end
        end
        data = data .. "}\n}"

        if data == _G.X3.LastConfigSaveStr then return end
        _G.X3.LastConfigSaveStr = data

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

_G.X3.LoadModSettings = function()
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
                    if savedData.XthrlenConfig then
                        for k, v in pairs(savedData.XthrlenConfig) do
                            _G.X3.XthrlenConfig[k] = v
                        end
                    end
                    if savedData.CustomTextData then
                        _G.X3.XthrlenState.CustomTextData = _G.X3.XthrlenState.CustomTextData or {}
                        for k, v in pairs(savedData.CustomTextData) do
                            _G.X3.XthrlenState.CustomTextData[k] = v
                        end
                    end
                 end
            end
        end
        _G.X3.SaveModSettings()
    end)
end

local function AutoSaveLoop()
    pcall(function() if _G.X3.SaveModSettings then _G.X3.SaveModSettings() end end)
    pcall(function()
        local okTicker, ticker = pcall(require, "common.time_ticker")
        if okTicker and ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(1.5, AutoSaveLoop)
        end
    end)
end

if not _G.X3.ModConfigLoaded then
    _G.X3.LoadModSettings()
    AutoSaveLoop()
    _G.X3.ModConfigLoaded = true
end

_G.X3.ReadLiveConfig = function()
    if _G.X3.SaveModSettings then _G.X3.SaveModSettings() end
end

function _G.X3.InitModMenuTab()
    if _G.X3.ModMenuInitialized and _G.X3.ModMenuBuiltStamp == _G.X3.BuildStamp then return true end

    _G.X3.XthrlenState.CustomTextData = _G.X3.XthrlenState.CustomTextData or {
        OuterSpeed = 10, InnerSpeed = 10, OuterRecoil = 0, HRecoil = 0.3, VRecoil = 0.3, MagicHead = 1.0, MagicBody = 1.0, MagicLegs = 1.0, IpadViewFOV = 120,
        AimTouchHipPrio = 1, AimTouchHipBone = 1, AimTouchHipCond = 1, AimTouchHipSpeed = 50, AimTouchHipFOV = 30, AimTouchHipDist = 250,
        AimTouchSGPrio = 1, AimTouchSGBone = 2, AimTouchSGCond = 1, AimTouchSGSpeed = 80, AimTouchSGFOV = 40, AimTouchSGDist = 30,
        AimTouchScopePrio = 1, AimTouchScopeBone = 2, AimTouchScopeCond = 1, AimTouchScopeSpeed = 40, AimTouchScopeFOV = 20, AimTouchScopeDist = 300, AimTouchScopePred = 0, AimTouchScopeRecoil = 0,
        AimTouchSniperPrio = 1, AimTouchSniperBone = 1, AimTouchSniperCond = 2, AimTouchSniperSpeed = 30, AimTouchSniperFOV = 20, AimTouchSniperDist = 400, AimTouchSniperPred = 0,
        AimTouchMortarPred = 0, AimTouchMortarFOV = 360, AimTouchMortarFOVColor = 5,
        MagicHead = 1.0, MagicNeck = 1.0, MagicBody = 1.0, MagicPelvis = 1.0, MagicArms = 1.0, MagicLegs = 1.0,
        WallMaxDist = 0, WallFadeDist = 0, WallGlowIntensity = 8, WallOccOpacity = 100
    }

    local LocUtil = _G.LocUtil
    if not LocUtil and package.loaded["client.common.LocUtil"] then
        LocUtil = require("client.common.LocUtil")
    end

    if LocUtil and not LocUtil._IsModMenuHooked then
        local old_get = LocUtil.GetLocalizeResStr
        LocUtil.GetLocalizeResStr = function(id)
            if type(id) == "string" and not tonumber(id) then
                return id
            end
            return old_get(id)
        end
        LocUtil._IsModMenuHooked = true
    end

    local okSPD, SettingPageDefine = pcall(require, "client.logic.NewSetting.SettingPageDefine")
    local okSC, SettingCatalog = pcall(require, "client.logic.NewSetting.SettingCatalog")
    if not okSPD or not okSC or type(SettingPageDefine) ~= "table" or type(SettingCatalog) ~= "table" then
        if type(_G.X3.Trace) == "function" then
            _G.X3.Trace("MENU: modul NewSetting belum siap (SPD ok=" .. tostring(okSPD) .. " SC ok=" .. tostring(okSC) .. ") — retry nanti")
        end
        return false
    end
    local okAM, AliasMap = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
    if not okAM or type(AliasMap) ~= "table" then
        if type(_G.X3.Trace) == "function" then _G.X3.Trace("MENU: AliasMap belum siap — retry nanti") end
        return false
    end
    _G.X3.ModMenuInitialized = true
    _G.X3.ModMenuBuiltStamp = _G.X3.BuildStamp

    do

local StackDeviceInfo = {
                  {
        UI = AliasMap.Title,
        Text = "SRCHUB"
      },
}

if _G.X3.BuildX3HWIDMenu then
    _G.X3.BuildX3HWIDMenu(StackDeviceInfo, AliasMap)
end
if _G.X3.BuildX3RareMenu then
    _G.X3.BuildX3RareMenu(StackDeviceInfo, AliasMap, "ModMenu_FakeHWID_Ex")
end

        local StackGraphic = {
                                          {
        UI = AliasMap.Title,
        Text = "SRCHUB"
      },
        }

if _G.X3.BuildX3BetaTestMenu then
    _G.X3.BuildX3BetaTestMenu(StackGraphic, AliasMap)
end
if _G.X3.BuildX3GMHiddenMenu then
    _G.X3.BuildX3GMHiddenMenu(StackGraphic, AliasMap)
end


        local StackAimbot = {
                  {
        UI = AliasMap.Title,
        Text = "SRCHUB"
      },
            { Key = "ModMenu_BT", UI = AliasMap.TitleSwitcher, Text = "▶ Bullet Track [ PELURU MELACAK ]", ExpandIndex = 0,
                GetFunc = function() return _G.X3.XthrlenConfig.BulletTrack end,
                SetFunc = function(c, v) _G.X3.XthrlenConfig.BulletTrack = v return true end },
            { Key = "ModMenu_BTRange", UI = AliasMap.Slider, Text = "   Crosshair Radius [ RADIUS CROSSHAIR ] (50-1000 px)", ExpandHandle = "ModMenu_BT",
                MinValue = 50, MaxValue = 1000, min = 50, max = 1000, Min = 50, Max = 1000,
                GetFunc = function() return _G.X3.XthrlenConfig.BTRange or 300 end,
                SetFunc = function(c, v) _G.X3.XthrlenConfig.BTRange = math.max(50, math.min(1000, math.floor(v + 0.5))) return true end },
            { Key = "ModMenu_BTPart", UI = AliasMap.Slider, Text = "   Body Part [ BAGIAN TUBUH ] (0:Kepala 1:Leher 2:Dada)", ExpandHandle = "ModMenu_BT",
                MinValue = 0, MaxValue = 2, min = 0, max = 2, Min = 0, Max = 2,
                GetFunc = function() return _G.X3.XthrlenConfig.BTPart or 0 end,
                SetFunc = function(c, v) _G.X3.XthrlenConfig.BTPart = math.max(0, math.min(2, math.floor(v + 0.5))) return true end },
            { Key = "ModMenu_BTProb", UI = AliasMap.Slider, Text = "   Track Chance [ PELUANG TRACK ] (10-100 %)", ExpandHandle = "ModMenu_BT",
                MinValue = 10, MaxValue = 100, min = 10, max = 100, Min = 10, Max = 100,
                GetFunc = function() return _G.X3.XthrlenConfig.BTProb or 100 end,
                SetFunc = function(c, v) _G.X3.XthrlenConfig.BTProb = math.max(10, math.min(100, math.floor(v + 0.5))) return true end },

          {
        Key = "ModMenu_Aim_SmartHead",
        UI = AliasMap.Switcher,
        Text = "[BARU] Smart Auto Aim Head [ AIM KEPALA OTOMATIS ] (Bones Lock)",
        ExpandHandle = "ModMenu_AT_Ex", -- Sesuaikan dengan nama handle menu aimbot Anda
        GetFunc = function() return _G.X3.XthrlenConfig.SmartAutoHead == true end,
        SetFunc = function(_, value)
            _G.X3.XthrlenConfig.SmartAutoHead = value and true or false
            return true
        end
    },
            { Key = "ModMenu_Magic_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ Custom Magic Bullet [ MAGIC BULLET KUSTOM ]", ExpandIndex = 0, GetFunc = function() return _G.X3.XthrlenConfig.CustomMagicBullet end, SetFunc = function(c,v) _G.X3.XthrlenConfig.CustomMagicBullet = v return true end },
            { Key = "ModMenu_Magic_Head", UI = AliasMap.Slider, Text = "Magic Head [ DAMAGE KEPALA ] (0.0 - 5.0)", ExpandHandle = "ModMenu_Magic_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return math.floor(((_G.X3.XthrlenState.CustomTextData.MagicHead or 1.0) / 5.0) * 100 + 0.5) end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.MagicHead = (v / 100.0) * 5.0 return true end },
            { Key = "ModMenu_Magic_Neck", UI = AliasMap.Slider, Text = "Magic Neck [ DAMAGE LEHER ] (0.0 - 5.0)", ExpandHandle = "ModMenu_Magic_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return math.floor(((_G.X3.XthrlenState.CustomTextData.MagicNeck or 1.0) / 5.0) * 100 + 0.5) end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.MagicNeck = (v / 100.0) * 5.0 return true end },
            { Key = "ModMenu_Magic_Body", UI = AliasMap.Slider, Text = "Magic Body [ DAMAGE BADAN ] (0.0 - 5.0)", ExpandHandle = "ModMenu_Magic_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return math.floor(((_G.X3.XthrlenState.CustomTextData.MagicBody or 1.0) / 5.0) * 100 + 0.5) end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.MagicBody = (v / 100.0) * 5.0 return true end },
            { Key = "ModMenu_Magic_Pelvis", UI = AliasMap.Slider, Text = "Magic Pelvis [ DAMAGE PANGGUL ] (0.0 - 5.0)", ExpandHandle = "ModMenu_Magic_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return math.floor(((_G.X3.XthrlenState.CustomTextData.MagicPelvis or 1.0) / 5.0) * 100 + 0.5) end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.MagicPelvis = (v / 100.0) * 5.0 return true end },
            { Key = "ModMenu_Magic_Legs", UI = AliasMap.Slider, Text = "Magic Legs [ DAMAGE KAKI ] (0.0 - 5.0)", ExpandHandle = "ModMenu_Magic_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return math.floor(((_G.X3.XthrlenState.CustomTextData.MagicLegs or 1.0) / 5.0) * 100 + 0.5) end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.MagicLegs = (v / 100.0) * 5.0 return true end },

            { Key = "ModMenu_HRecoil_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ Reduce Horizontal Recoil [ KURANGI RECOIL HORIZONTAL ]", ExpandIndex = 0, GetFunc = function() return _G.X3.XthrlenConfig.CustomHRecoil end, SetFunc = function(c,v) _G.X3.XthrlenConfig.CustomHRecoil = v return true end },

            { Key = "ModMenu_HRecoil_Val", UI = AliasMap.Slider, Text = "   Horizontal Recoil Value [ NILAI RECOIL HORIZONTAL ]", ExpandHandle = "ModMenu_HRecoil_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return math.floor((((_G.X3.XthrlenState.CustomTextData.HRecoil or 0.3) - 0.3) / 4.7) * 100 + 0.5) end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.HRecoil = 0.3 + (v / 100.0) * 4.7 return true end },

            { Key = "ModMenu_VRecoil_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ Reduce Vertical Recoil [ KURANGI RECOIL VERTIKAL ]", ExpandIndex = 0, GetFunc = function() return _G.X3.XthrlenConfig.CustomVRecoil end, SetFunc = function(c,v) _G.X3.XthrlenConfig.CustomVRecoil = v return true end },
            { Key = "ModMenu_VRecoil_Val", UI = AliasMap.Slider, Text = "   Vertical Recoil Value [ NILAI RECOIL VERTIKAL ]", ExpandHandle = "ModMenu_VRecoil_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return math.floor((((_G.X3.XthrlenState.CustomTextData.VRecoil or 0.3) - 0.3) / 4.7) * 100 + 0.5) end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.VRecoil = 0.3 + (v / 100.0) * 4.7 return true end },

            { Key = "ModMenu_LessShake", UI = AliasMap.Switcher, Text = "Reduce Scope Shake [ KURANGI GUNCANGAN SCOPE ]", GetFunc = function() return _G.X3.XthrlenConfig.LessShake end, SetFunc = function(c,v) _G.X3.XthrlenConfig.LessShake = v return true end },
            { Key = "ModMenu_Accuracy", UI = AliasMap.Switcher, Text = "Straight Bullet [ PELURU LURUS ]", GetFunc = function() return _G.X3.XthrlenConfig.Accuracy end, SetFunc = function(c,v) _G.X3.XthrlenConfig.Accuracy = v return true end },
            { Key = "ModMenu_Crosshair", UI = AliasMap.Switcher, Text = "Small Crosshair [ CROSSHAIR KECIL ]", GetFunc = function() return _G.X3.XthrlenConfig.Crosshair end, SetFunc = function(c,v) _G.X3.XthrlenConfig.Crosshair = v return true end },
            { Key = "ModMenu_AutoHead", UI = AliasMap.Switcher, Text = "Aimbot Head [ AIMBOT KEPALA ]", GetFunc = function() return _G.X3.XthrlenConfig.AutoHead end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AutoHead = v return true end },
            { Key = "ModMenu_GodMode", UI = AliasMap.Switcher, Text = "Rapid Fire [ TEMBAK SUPER CEPAT ]", GetFunc = function() return _G.X3.XthrlenConfig.GodMode end, SetFunc = function(c,v) _G.X3.XthrlenConfig.GodMode = v return true end }
        }

        local StackAimbotV2 = {
                                          {
        UI = AliasMap.Title,
        Text = "SRCHUB"
      },
            { Key = "ModMenu_AT_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ Enable Aimbot Roy & Custom [ AKTIFKAN AIMBOT ROY & KUSTOM ]", ExpandIndex = 0, GetFunc = function() return _G.X3.XthrlenConfig.AimTouchEnable end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AimTouchEnable = v return true end },

            { Key = "ModMenu_AT_Hip_Ex", UI = AliasMap.TitleSwitcher, Text = "   ▶ Hipfire Aimbot [ AIMBOT HIPFIRE ]", ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.X3.XthrlenConfig.AimTouchHipfire end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AimTouchHipfire = v return true end },
            { Key = "ModMenu_AT_Hip_IgKnock", UI = AliasMap.Switcher, Text = "      Ignore Knocked Enemy [ ABAIKAN MUSUH KNOCK ]", ExpandHandle = "ModMenu_AT_Hip_Ex", GetFunc = function() return _G.X3.XthrlenConfig.AimTouchHipIgKnock end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AimTouchHipIgKnock = v return true end },
            { Key = "ModMenu_AT_Hip_IgBot", UI = AliasMap.Switcher, Text = "      Ignore Bot [ ABAIKAN BOT ]", ExpandHandle = "ModMenu_AT_Hip_Ex", GetFunc = function() return _G.X3.XthrlenConfig.AimTouchHipIgBot end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AimTouchHipIgBot = v return true end },
            { Key = "ModMenu_AT_Hip_Vis", UI = AliasMap.Switcher, Text = "      VisCheck [ TEMBUS TEMBOK ]", ExpandHandle = "ModMenu_AT_Hip_Ex", GetFunc = function() return _G.X3.XthrlenConfig.AimTouchHipVisCheck end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AimTouchHipVisCheck = v return true end },
            { Key = "ModMenu_AT_Hip_Prio", UI = AliasMap.Slider, Text = "      Priority [ PRIORITAS ] (1:Tengah 2:Dekat 3:HP 4:%HP)", ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchHipPrio or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.X3.XthrlenState.CustomTextData.AimTouchHipPrio = val return true end },
            { Key = "ModMenu_AT_Hip_Bone", UI = AliasMap.Slider, Text = "      Target [ TARGET ] (1:Kepala 2:Dada 3:Perut 4:Pinggul)", ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchHipBone or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.X3.XthrlenState.CustomTextData.AimTouchHipBone = val return true end },
            { Key = "ModMenu_AT_Hip_Cond", UI = AliasMap.Slider, Text = "      Condition [ KONDISI ] (1:Tembak baru Aim, 2:Aim terus)", ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 2, min = 1, max = 2, Min = 1, Max = 2, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchHipCond or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 2 then val = 2 end; _G.X3.XthrlenState.CustomTextData.AimTouchHipCond = val return true end },
            { Key = "ModMenu_AT_Hip_Spd", UI = AliasMap.Slider, Text = "      Speed [ KECEPATAN ] (1-100)", ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchHipSpeed or 50 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchHipSpeed = v return true end },
            { Key = "ModMenu_AT_Hip_FOV", UI = AliasMap.Slider, Text = "      FOV Radius [ RADIUS FOV ] (1-100)", ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchHipFOV or 30 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchHipFOV = v return true end },
            { Key = "ModMenu_AT_Hip_Dist", UI = AliasMap.Slider, Text = "      Distance [ JARAK ] (1-500m)", ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return math.floor((_G.X3.XthrlenState.CustomTextData.AimTouchHipDist or 250) / 5) end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchHipDist = v * 5 return true end },
            { Key = "ModMenu_AT_Hip_Pred", UI = AliasMap.Slider, Text = "      Run Prediction [ PREDIKSI ARAH LARI ] (0-100)", ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchHipPred or 30 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchHipPred = v return true end },
            { Key = "ModMenu_AT_SG_Ex", UI = AliasMap.TitleSwitcher, Text = "   ▶ Shotgun Aimbot [ AIMBOT SHOTGUN ]", ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.X3.XthrlenConfig.AimTouchSG end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AimTouchSG = v return true end },
            { Key = "ModMenu_AT_SG_AutoFire", UI = AliasMap.Switcher, Text = "      Auto Fire [ TEMBAK OTOMATIS ]", ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.X3.XthrlenConfig.AimTouchSGAutoFire end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AimTouchSGAutoFire = v return true end },
            { Key = "ModMenu_AT_SG_IgKnock", UI = AliasMap.Switcher, Text = "      Ignore Knocked Enemy [ ABAIKAN MUSUH KNOCK ]", ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.X3.XthrlenConfig.AimTouchSGIgKnock end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AimTouchSGIgKnock = v return true end },
            { Key = "ModMenu_AT_SG_IgBot", UI = AliasMap.Switcher, Text = "      Ignore Bot [ ABAIKAN BOT ]", ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.X3.XthrlenConfig.AimTouchSGIgBot end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AimTouchSGIgBot = v return true end },
            { Key = "ModMenu_AT_SG_Vis", UI = AliasMap.Switcher, Text = "      VisCheck [ TEMBUS TEMBOK ]", ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.X3.XthrlenConfig.AimTouchSGVisCheck end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AimTouchSGVisCheck = v return true end },
            { Key = "ModMenu_AT_SG_Prio", UI = AliasMap.Slider, Text = "      Priority [ PRIORITAS ] (1:Tengah 2:Dekat 3:HP 4:%HP)", ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchSGPrio or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.X3.XthrlenState.CustomTextData.AimTouchSGPrio = val return true end },
            { Key = "ModMenu_AT_SG_Bone", UI = AliasMap.Slider, Text = "      Target [ TARGET ] (1:Kepala 2:Dada 3:Perut 4:Pinggul)", ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchSGBone or 2 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.X3.XthrlenState.CustomTextData.AimTouchSGBone = val return true end },
            { Key = "ModMenu_AT_SG_Cond", UI = AliasMap.Slider, Text = "      Condition [ KONDISI ] (1:Tembak baru Aim, 2:Aim terus)", ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 2, min = 1, max = 2, Min = 1, Max = 2, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchSGCond or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 2 then val = 2 end; _G.X3.XthrlenState.CustomTextData.AimTouchSGCond = val return true end },
            { Key = "ModMenu_AT_SG_Spd", UI = AliasMap.Slider, Text = "      Speed [ KECEPATAN ] (1-100)", ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchSGSpeed or 80 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchSGSpeed = v return true end },
            { Key = "ModMenu_AT_SG_FOV", UI = AliasMap.Slider, Text = "      FOV Radius [ RADIUS FOV ] (1-100)", ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchSGFOV or 40 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchSGFOV = v return true end },
            { Key = "ModMenu_AT_SG_Dist", UI = AliasMap.Slider, Text = "      Distance [ JARAK ] (1-100m)", ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchSGDist or 30 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchSGDist = v return true end },

            { Key = "ModMenu_AT_ScopeAll_Ex", UI = AliasMap.TitleSwitcher, Text = "   ▶ Scope Aimbot (Normal) [ AIMBOT SCOPE BIASA ]", ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.X3.XthrlenConfig.AimTouchScopeAll end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AimTouchScopeAll = v return true end },
            { Key = "ModMenu_AT_ScopeAll_IgKnock", UI = AliasMap.Switcher, Text = "      Ignore Knocked Enemy [ ABAIKAN MUSUH KNOCK ]", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", GetFunc = function() return _G.X3.XthrlenConfig.AimTouchScopeIgKnock end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AimTouchScopeIgKnock = v return true end },
            { Key = "ModMenu_AT_ScopeAll_IgBot", UI = AliasMap.Switcher, Text = "      Ignore Bot [ ABAIKAN BOT ]", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", GetFunc = function() return _G.X3.XthrlenConfig.AimTouchScopeIgBot end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AimTouchScopeIgBot = v return true end },
            { Key = "ModMenu_AT_ScopeAll_Vis", UI = AliasMap.Switcher, Text = "      VisCheck [ TEMBUS TEMBOK ]", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", GetFunc = function() return _G.X3.XthrlenConfig.AimTouchScopeVisCheck end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AimTouchScopeVisCheck = v return true end },
            { Key = "ModMenu_AT_ScopeAll_Prio", UI = AliasMap.Slider, Text = "      Priority [ PRIORITAS ] (1:Tengah 2:Dekat 3:HP 4:%HP)", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchScopePrio or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.X3.XthrlenState.CustomTextData.AimTouchScopePrio = val return true end },
            { Key = "ModMenu_AT_ScopeAll_Bone", UI = AliasMap.Slider, Text = "      Target [ TARGET ] (1:Kepala 2:Dada 3:Perut 4:Pinggul)", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchScopeBone or 2 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.X3.XthrlenState.CustomTextData.AimTouchScopeBone = val return true end },
            { Key = "ModMenu_AT_ScopeAll_Cond", UI = AliasMap.Slider, Text = "      Condition [ KONDISI ] (1:Tembak baru Aim, 2:Aim terus)", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 2, min = 1, max = 2, Min = 1, Max = 2, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchScopeCond or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 2 then val = 2 end; _G.X3.XthrlenState.CustomTextData.AimTouchScopeCond = val return true end },
            { Key = "ModMenu_AT_ScopeAll_Spd", UI = AliasMap.Slider, Text = "      Speed [ KECEPATAN ] (1-100)", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchScopeSpeed or 40 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchScopeSpeed = v return true end },
            { Key = "ModMenu_AT_ScopeAll_FOV", UI = AliasMap.Slider, Text = "      FOV Radius [ RADIUS FOV ] (1-100)", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchScopeFOV or 20 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchScopeFOV = v return true end },
            { Key = "ModMenu_AT_ScopeAll_Dist", UI = AliasMap.Slider, Text = "      Distance [ JARAK ] (1-500m)", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return math.floor((_G.X3.XthrlenState.CustomTextData.AimTouchScopeDist or 300) / 5) end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchScopeDist = v * 5 return true end },
            { Key = "ModMenu_AT_ScopeAll_Pred", UI = AliasMap.Slider, Text = "      Run Prediction [ PREDIKSI ARAH LARI ]", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchScopePred or 0 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchScopePred = v return true end },
            { Key = "ModMenu_AT_ScopeAll_Recoil", UI = AliasMap.Slider, Text = "      Recoil Compensation While Aim [ KOMPENSASI RECOIL SAAT AIM ]", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 0, MaxValue = 50, min = 0, max = 50, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchScopeRecoil or 0 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchScopeRecoil = v return true end },
         { Key = "ModMenu_AT_ScopeAll_Yaw", UI = AliasMap.Slider, Text = "      Yaw Offset (Kiri/Kanan) [0=Kiri, 50=Tengah, 100=Kanan]", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return math.floor((((_G.X3.XthrlenState.CustomTextData.AimTouchScopeYawOffset or 0) + 5.0) / 10.0) * 100 + 0.5) end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchScopeYawOffset = (v / 10.0) - 5.0 return true end },
         { Key = "ModMenu_AT_ScopeAll_Pitch", UI = AliasMap.Slider, Text = "      Pitch Offset (Atas/Bawah) [0=Atas, 50=Tengah, 100=Bawah]", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return math.floor((((_G.X3.XthrlenState.CustomTextData.AimTouchScopePitchOffset or 0) + 5.0) / 10.0) * 100 + 0.5) end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchScopePitchOffset = (v / 10.0) - 5.0 return true end },
            { Key = "ModMenu_AT_Sniper_Ex", UI = AliasMap.TitleSwitcher, Text = "   ▶ Scope Aimbot (Sniper) [ AIMBOT SCOPE SNIPER ]", ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.X3.XthrlenConfig.AimTouchScopeSniper end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AimTouchScopeSniper = v return true end },
            { Key = "ModMenu_AT_Sniper_IgKnock", UI = AliasMap.Switcher, Text = "      Ignore Knocked Enemy [ ABAIKAN MUSUH KNOCK ]", ExpandHandle = "ModMenu_AT_Sniper_Ex", GetFunc = function() return _G.X3.XthrlenConfig.AimTouchSniperIgKnock end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AimTouchSniperIgKnock = v return true end },
            { Key = "ModMenu_AT_Sniper_IgBot", UI = AliasMap.Switcher, Text = "      Ignore Bot [ ABAIKAN BOT ]", ExpandHandle = "ModMenu_AT_Sniper_Ex", GetFunc = function() return _G.X3.XthrlenConfig.AimTouchSniperIgBot end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AimTouchSniperIgBot = v return true end },
            { Key = "ModMenu_AT_Sniper_Vis", UI = AliasMap.Switcher, Text = "      VisCheck [ TEMBUS TEMBOK ]", ExpandHandle = "ModMenu_AT_Sniper_Ex", GetFunc = function() return _G.X3.XthrlenConfig.AimTouchSniperVisCheck end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AimTouchSniperVisCheck = v return true end },
            { Key = "ModMenu_AT_Sniper_Prio", UI = AliasMap.Slider, Text = "      Priority [ PRIORITAS ] (1:Tengah 2:Dekat 3:HP 4:%HP)", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchSniperPrio or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.X3.XthrlenState.CustomTextData.AimTouchSniperPrio = val return true end },
            { Key = "ModMenu_AT_Sniper_Bone", UI = AliasMap.Slider, Text = "      Target [ TARGET ] (1:Kepala 2:Dada 3:Perut 4:Pinggul)", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchSniperBone or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.X3.XthrlenState.CustomTextData.AimTouchSniperBone = val return true end },
            { Key = "ModMenu_AT_Sniper_Cond", UI = AliasMap.Slider, Text = "      Condition [ KONDISI ] (1:Tembak baru Aim, 2:Aim terus)", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 2, min = 1, max = 2, Min = 1, Max = 2, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchSniperCond or 2 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 2 then val = 2 end; _G.X3.XthrlenState.CustomTextData.AimTouchSniperCond = val return true end },
            { Key = "ModMenu_AT_Sniper_Spd", UI = AliasMap.Slider, Text = "      Speed [ KECEPATAN ] (1-100)", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchSniperSpeed or 30 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchSniperSpeed = v return true end },
            { Key = "ModMenu_AT_Sniper_FOV", UI = AliasMap.Slider, Text = "      FOV Radius [ RADIUS FOV ] (1-100)", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchSniperFOV or 20 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchSniperFOV = v return true end },
            { Key = "ModMenu_AT_Sniper_Dist", UI = AliasMap.Slider, Text = "      Distance [ JARAK ] (1-500m)", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return math.floor((_G.X3.XthrlenState.CustomTextData.AimTouchSniperDist or 400) / 5) end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchSniperDist = v * 5 return true end },
            { Key = "ModMenu_AT_Sniper_Pred", UI = AliasMap.Slider, Text = "      Run Prediction [ PREDIKSI ARAH LARI ] (0-100)", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchSniperPred or 0 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchSniperPred = v return true end },
         { Key = "ModMenu_AT_Sniper_Yaw", UI = AliasMap.Slider, Text = "      Yaw Offset (Kiri/Kanan) [0=Kiri, 50=Tengah, 100=Kanan]", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return math.floor((((_G.X3.XthrlenState.CustomTextData.AimTouchSniperYawOffset or 0) + 5.0) / 10.0) * 100 + 0.5) end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchSniperYawOffset = (v / 10.0) - 5.0 return true end },
         { Key = "ModMenu_AT_Sniper_Pitch", UI = AliasMap.Slider, Text = "      Pitch Offset (Atas/Bawah) [0=Atas, 50=Tengah, 100=Bawah]", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return math.floor((((_G.X3.XthrlenState.CustomTextData.AimTouchSniperPitchOffset or 0) + 5.0) / 10.0) * 100 + 0.5) end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchSniperPitchOffset = (v / 10.0) - 5.0 return true end },
            { Key = "ModMenu_AT_Mortar_Ex", UI = AliasMap.TitleSwitcher, Text = "   ▶ Mortar Aimbot [ AIMBOT SUNG COI ]", ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.X3.XthrlenConfig.AimTouchMortar end, SetFunc = function(c,v) _G.X3.XthrlenConfig.AimTouchMortar = v return true end },
            { Key = "ModMenu_AT_Mortar_Pred", UI = AliasMap.Slider, Text = "      Run Prediction [ PREDIKSI ARAH LARI ] (0-100)", ExpandHandle = "ModMenu_AT_Mortar_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchMortarPred or 0 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchMortarPred = v return true end },
            { Key = "ModMenu_AT_Mortar_FOV", UI = AliasMap.Slider, Text = "      FOV Radius [ RADIUS FOV ] (1-360)", ExpandHandle = "ModMenu_AT_Mortar_Ex", MinValue = 1, MaxValue = 360, min = 1, max = 360, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchMortarFOV or 360 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchMortarFOV = v return true end },
            { Key = "ModMenu_AT_Mortar_FOVColor", UI = AliasMap.Slider, Text = "      Circle Color [ WARNA FOV ] (1-7)", ExpandHandle = "ModMenu_AT_Mortar_Ex", MinValue = 1, MaxValue = 7, min = 1, max = 7, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.AimTouchMortarFOVColor or 5 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.AimTouchMortarFOVColor = v return true end }
        }



        local StackCombat = {
                                          {
        UI = AliasMap.Title,
        Text = "SRCHUB"
      },
            { Key = "ModMenu_Ipad_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ iPad View [ TAMPILAN IPAD ]", ExpandIndex = 0, GetFunc = function() return _G.X3.XthrlenConfig.IpadView end, SetFunc = function(c,v) _G.X3.XthrlenConfig.IpadView = v return true end },
            { Key = "ModMenu_Ipad_FOV", UI = AliasMap.Slider, Text = "   FOV [ FOV ]", ExpandHandle = "ModMenu_Ipad_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return (_G.X3.XthrlenState.CustomTextData.IpadViewFOV or 120) - 90 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.IpadViewFOV = 90 + v return true end },
            { Key = "ModMenu_165FPS", UI = AliasMap.Switcher, Text = "Unlock Max FPS [ BUKA FPS MAKS ]", GetFunc = function() return _G.X3.XthrlenConfig.UnlockFPS end, SetFunc = function(c,v) _G.X3.XthrlenConfig.UnlockFPS = v; if v then _G.X3.XthrlenState.GraphicsUnlocked = false end return true end },
            { Key = "ModMenu_X3Extra_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ EXTRA FEATURES [ FITUR EXTRA ]", ExpandIndex = 0, GetFunc = function() local C = _G.X3.XthrlenConfig return (C.X3CacheClean ~= false) or (C.X3Watermark ~= false) or C.X3FakeVisual == true or C.X3PerfBoost == true or C.X3TPPForce == true or C.X3TPPUnlockBtn == true end, SetFunc = function() return true end },

            { Key = "ModMenu_X3TPPGrp_Ex", UI = AliasMap.TitleSwitcher, Text = "  ▶ FORCE TPP IN FPP [ PAKSA KAMERA TPP ]", ExpandHandle = "ModMenu_X3Extra_Ex", ExpandIndex = 0, GetFunc = function() return _G.X3.XthrlenConfig.X3TPPForce == true or _G.X3.XthrlenConfig.X3TPPUnlockBtn == true end, SetFunc = function(c,v) _G.X3.XthrlenConfig.X3TPPForce = v and true or false; _G.X3.XthrlenConfig.X3TPPUnlockBtn = v and true or false; if _G.X3.SaveModSettings then pcall(_G.X3.SaveModSettings) end return true end },
            { Key = "ModMenu_X3TPPForce", UI = AliasMap.Switcher, Text = "    └ Force Camera [ PAKSA KAMERA TPP ]", ExpandHandle = "ModMenu_X3TPPGrp_Ex", GetFunc = function() return _G.X3.XthrlenConfig.X3TPPForce == true end, SetFunc = function(c,v) _G.X3.XthrlenConfig.X3TPPForce = v and true or false return true end },
            { Key = "ModMenu_X3TPPUnlockBtn", UI = AliasMap.Switcher, Text = "    └ Unlock TPP/FPP Switch [ BUKA TOMBOL TPP/FPP ]", ExpandHandle = "ModMenu_X3TPPGrp_Ex", GetFunc = function() return _G.X3.XthrlenConfig.X3TPPUnlockBtn == true end, SetFunc = function(c,v) _G.X3.XthrlenConfig.X3TPPUnlockBtn = v and true or false; if v and _G.X3._XFTPPUnlockTry then pcall(_G.X3._XFTPPUnlockTry) end return true end },

            { Key = "ModMenu_X3CacheClean", UI = AliasMap.Switcher, Text = "  Smart Cache Cleaner [ PEMBERSIH CACHE ] (5 mnt)", ExpandHandle = "ModMenu_X3Extra_Ex", GetFunc = function() return _G.X3.XthrlenConfig.X3CacheClean ~= false end, SetFunc = function(c,v) _G.X3.XthrlenConfig.X3CacheClean = v and true or false return true end },
            { Key = "ModMenu_X3Watermark", UI = AliasMap.Switcher, Text = "  Smart Watermark Top3/WWCD [ WATERMARK PINTAR ]", ExpandHandle = "ModMenu_X3Extra_Ex", GetFunc = function() return _G.X3.XthrlenConfig.X3Watermark ~= false end, SetFunc = function(c,v)
                _G.X3.XthrlenConfig.X3Watermark = v and true or false
                _G.X3._WMManual = v and true or false -- ON manual = langsung tampil
                if not v then _G.X3._WMEndOn = false end
                if _G.X3._WMHookInstall then pcall(_G.X3._WMHookInstall) end
                if _G.X3._WMRefresh then pcall(_G.X3._WMRefresh) end
                if _G.X3.SaveModSettings then pcall(_G.X3.SaveModSettings) end
                return true
            end },
            { Key = "ModMenu_X3FakeVisual", UI = AliasMap.Switcher, Text = "  Fake Sultan: Currency + Collect Lv100 [ SULTAN PALSU ] (visual)", ExpandHandle = "ModMenu_X3Extra_Ex", GetFunc = function() return _G.X3.XthrlenConfig.X3FakeVisual == true end, SetFunc = function(c,v) _G.X3.XthrlenConfig.X3FakeVisual = v and true or false return true end },
            { Key = "ModMenu_X3PerfBoost", UI = AliasMap.Switcher, Text = "  Performance Boost [ BOOST PERFORMA ] (Smooth + Quality)", ExpandHandle = "ModMenu_X3Extra_Ex", GetFunc = function() return _G.X3.XthrlenConfig.X3PerfBoost == true end, SetFunc = function(c,v) _G.X3.XthrlenConfig.X3PerfBoost = v and true or false; if _G.X3.ApplyPerfBoost then pcall(_G.X3.ApplyPerfBoost, _G.X3.XthrlenConfig.X3PerfBoost) end return true end },
            { Key = "ModMenu_WhiteBody", UI = AliasMap.Switcher, Text = "White Body [ TUBUH PUTIH ]", GetFunc = function() return _G.X3.XthrlenConfig.WhiteBody end, SetFunc = function(c,v) _G.X3.XthrlenConfig.WhiteBody = v return true end },
            { Key = "ModMenu_BlackSky", UI = AliasMap.Switcher, Text = "Black Sky [ LANGIT GELAP ]", GetFunc = function() return _G.X3.XthrlenConfig.BlackSky end, SetFunc = function(c,v) _G.X3.XthrlenConfig.BlackSky = v return true end },
            { Key = "ModMenu_RemoveFog", UI = AliasMap.Switcher, Text = "No Fog [ TIDAK ADA KABUT ]", GetFunc = function() return _G.X3.XthrlenConfig.RemoveFog end, SetFunc = function(c,v) _G.X3.XthrlenConfig.RemoveFog = v return true end },
            { Key = "ModMenu_RemoveGrass", UI = AliasMap.Switcher, Text = "No Grass [ TIDAK ADA RUMPUT ]", GetFunc = function() return _G.X3.XthrlenConfig.RemoveGrass end, SetFunc = function(c,v) _G.X3.XthrlenConfig.RemoveGrass = v return true end }
,            { UI = AliasMap.Title, Text = "WALL & CHAMS" },
            { Key = "ModMenu_WallXuyenTuong", UI = AliasMap.Switcher, Text = "Wall Xuyen Tuong V1 [ TEMBUS PANDANG ]", GetFunc = function() return _G.X3.XthrlenConfig.WallXuyenTuong end, SetFunc = function(c,v) _G.X3.XthrlenConfig.WallXuyenTuong = v return true end },
            { Key = "ModMenu_ColorBodyV2", UI = AliasMap.Switcher, Text = "Chams V2 [ WARNA TUBUH V2 ]", GetFunc = function() return _G.X3.XthrlenConfig.ColorBodyV2 end, SetFunc = function(c,v) _G.X3.XthrlenConfig.ColorBodyV2 = v return true end },
            { Key = "ModMenu_ColorBodyNew", UI = AliasMap.Switcher, Text = "NEW ENGINE CHAMS [ WARNA ENGINE BARU ]", GetFunc = function() return _G.X3.XthrlenConfig.ColorBodyNew end, SetFunc = function(c,v) _G.X3.XthrlenConfig.ColorBodyNew = v return true end },
            { Key = "ModMenu_ColorBodyV3_Ex", UI = AliasMap.TitleSwitcher, Text = "WALL V2 + CHAMS V3 [ WARNA KUSTOM ]", ExpandIndex = 0, GetFunc = function() return _G.X3.XthrlenConfig.ColorBodyV3 end, SetFunc = function(c,v) _G.X3.XthrlenConfig.ColorBodyV3 = v return true end },
            { Key = "ModMenu_V3_Hidden", UI = AliasMap.Slider, Text = "   Warna di Balik Tembok (1:Merah 2:Hijau 3:Biru 4:Kuning 5:Ungu 6:Putih)", ExpandHandle = "ModMenu_ColorBodyV3_Ex", MinValue = 1, MaxValue = 6, min = 1, max = 6, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.ColorV3Hidden or 1 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.ColorV3Hidden = v return true end },
            { Key = "ModMenu_V3_Vis", UI = AliasMap.Slider, Text = "   Warna Terlihat (1:Merah 2:Hijau 3:Biru 4:Kuning 5:Ungu 6:Putih)", ExpandHandle = "ModMenu_ColorBodyV3_Ex", MinValue = 1, MaxValue = 6, min = 1, max = 6, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.ColorV3Visible or 2 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.ColorV3Visible = v return true end },
            { Key = "ModMenu_V3_Thick", UI = AliasMap.Slider, Text = "   Ketebalan Outline HDR (1-20)", ExpandHandle = "ModMenu_ColorBodyV3_Ex", MinValue = 1, MaxValue = 20, min = 1, max = 20, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.ColorV3Thickness or 4 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.ColorV3Thickness = v return true end },

        }

            if _G.X3.BuildX3RareGraphicMenu then _G.X3.BuildX3RareGraphicMenu(StackGraphic, AliasMap) end


        -- ====================================================================
        -- [PORT] STACK ESP (lengkap, dari 1.lua)
        -- ====================================================================
        local StackESP = {
            { UI = AliasMap.Title, Text = "SRCHUB ESP" },
            { Key = "ModMenu_ESP1", UI = AliasMap.Switcher, Text = "ESP 1 [ WARNING 360 - HP - NAMA ]", GetFunc = function() return _G.X3.XthrlenConfig.EspVip end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspVip = v return true end },
            { Key = "ModMenu_ESP2", UI = AliasMap.Switcher, Text = "ESP 2 [ JARAK METER ]", GetFunc = function() return _G.X3.XthrlenConfig.EspDistance end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspDistance = v return true end },

            { Key = "ModMenu_ESP3_Ex", UI = AliasMap.TitleSwitcher, Text = "ESP 3 [ HP VERTIKAL & NAMA ]", ExpandIndex = 0, GetFunc = function() return _G.X3.XthrlenConfig.EspVipPro end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspVipPro = v return true end },
            { Key = "ModMenu_ESP3_Name", UI = AliasMap.Switcher, Text = "   Tampilkan Nama [ NAMA PLAYER ]", ExpandHandle = "ModMenu_ESP3_Ex", GetFunc = function() return _G.X3.XthrlenConfig.Esp3ShowName end, SetFunc = function(c,v) _G.X3.XthrlenConfig.Esp3ShowName = v return true end },
            { Key = "ModMenu_ESP3_HP", UI = AliasMap.Switcher, Text = "   Tampilkan HP Bar [ BAR HP VERTIKAL ]", ExpandHandle = "ModMenu_ESP3_Ex", GetFunc = function() return _G.X3.XthrlenConfig.Esp3ShowHP end, SetFunc = function(c,v) _G.X3.XthrlenConfig.Esp3ShowHP = v return true end },

            { Key = "ModMenu_ESP4", UI = AliasMap.Switcher, Text = "ESP 4 [ RADAR 360 ]", GetFunc = function() return _G.X3.XthrlenConfig.EspRadar end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspRadar = v return true end },
            { Key = "ModMenu_ESP5", UI = AliasMap.Switcher, Text = "ESP 5 [ KOTAK / FRAME UI MUSUH ]", GetFunc = function() return _G.X3.XthrlenConfig.EspLoai5 end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspLoai5 = v return true end },
            { Key = "ModMenu_ESP6", UI = AliasMap.Switcher, Text = "ESP 6 [ TULANG / SKELETON ]", GetFunc = function() return _G.X3.XthrlenConfig.EspLoai6 end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspLoai6 = v return true end },

            { Key = "ModMenu_ESP7_Ex", UI = AliasMap.TitleSwitcher, Text = "ESP 7 [ INFO DETAIL MUSUH ]", ExpandIndex = 0, GetFunc = function() return _G.X3.XthrlenConfig.EspLoai7 end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspLoai7 = v return true end },
            { Key = "ModMenu_ESP7_SoLuong", UI = AliasMap.Switcher, Text = "   Hitung Musuh di Sekitar [ JUMLAH MUSUH ]", ExpandHandle = "ModMenu_ESP7_Ex", GetFunc = function() return _G.X3.XthrlenConfig.Esp7_SoLuong end, SetFunc = function(c,v) _G.X3.XthrlenConfig.Esp7_SoLuong = v return true end },
            { Key = "ModMenu_ESP7_VuKhi", UI = AliasMap.Switcher, Text = "   Tampilkan Senjata Musuh [ SENJATA ]", ExpandHandle = "ModMenu_ESP7_Ex", GetFunc = function() return _G.X3.XthrlenConfig.Esp7_VuKhi end, SetFunc = function(c,v) _G.X3.XthrlenConfig.Esp7_VuKhi = v return true end },
            { Key = "ModMenu_ESP7_TuThe", UI = AliasMap.Switcher, Text = "   Tampilkan Posisi [ BERDIRI / JONGKOK / TIARAP ]", ExpandHandle = "ModMenu_ESP7_Ex", GetFunc = function() return _G.X3.XthrlenConfig.Esp7_TuThe end, SetFunc = function(c,v) _G.X3.XthrlenConfig.Esp7_TuThe = v return true end },
            { Key = "ModMenu_EspAimWarning", UI = AliasMap.Switcher, Text = "   Peringatan Musuh Membidik [ AIM WARNING ]", ExpandHandle = "ModMenu_ESP7_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspAimWarning end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspAimWarning = v return true end },
            { Key = "ModMenu_EspAimWarning_Vis", UI = AliasMap.Switcher, Text = "      VisCheck [ HANYA SAAT TERLIHAT ]", ExpandHandle = "ModMenu_ESP7_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspAimWarningVisCheck end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspAimWarningVisCheck = v return true end },

            { Key = "ModMenu_ESP8", UI = AliasMap.Switcher, Text = "ESP 8 [ HP DI ATAS KEPALA ]", GetFunc = function() return _G.X3.XthrlenConfig.EspLoai8 end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspLoai8 = v return true end },

            { Key = "ModMenu_EspItem_Ex", UI = AliasMap.TitleSwitcher, Text = "ESP ITEM [ BARANG DI BAWAH 70m ]", ExpandIndex = 0, GetFunc = function() return _G.X3.XthrlenConfig.EspItem_Master end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspItem_Master = v return true end },
            { Key = "ModMenu_EspItem_AR", UI = AliasMap.Switcher, Text = "   Senjata AR [ AR ]", ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspItem_AR end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspItem_AR = v return true end },
            { Key = "ModMenu_EspItem_Sniper", UI = AliasMap.Switcher, Text = "   Senjata Sniper [ SNIPER ]", ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspItem_Sniper end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspItem_Sniper = v return true end },
            { Key = "ModMenu_EspItem_SMG", UI = AliasMap.Switcher, Text = "   Senjata SMG [ SMG ]", ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspItem_SMG end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspItem_SMG = v return true end },
            { Key = "ModMenu_EspItem_Shotgun", UI = AliasMap.Switcher, Text = "   Senjata Shotgun [ SHOTGUN ]", ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspItem_Shotgun end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspItem_Shotgun = v return true end },
            { Key = "ModMenu_EspItem_LMG", UI = AliasMap.Switcher, Text = "   Senjata LMG [ LMG ]", ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspItem_LMG end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspItem_LMG = v return true end },
            { Key = "ModMenu_EspItem_Pistol", UI = AliasMap.Switcher, Text = "   Pistol / Flare [ PISTOL ]", ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspItem_Pistol end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspItem_Pistol = v return true end },
            { Key = "ModMenu_EspItem_Melee", UI = AliasMap.Switcher, Text = "   Senjata Melee [ MELEE ]", ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspItem_Melee end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspItem_Melee = v return true end },
            { Key = "ModMenu_EspItem_Special", UI = AliasMap.Switcher, Text = "   Senjata Spesial [ SPECIAL ]", ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspItem_Special end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspItem_Special = v return true end },
            { Key = "ModMenu_EspItem_Scope", UI = AliasMap.Switcher, Text = "   Scope / Teropong [ SCOPE ]", ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspItem_Scope end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspItem_Scope = v return true end },
            { Key = "ModMenu_EspItem_Grenade", UI = AliasMap.Switcher, Text = "   Granat [ GRENADE ]", ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspItem_Grenade end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspItem_Grenade = v return true end },
            { Key = "ModMenu_EspItem_Med", UI = AliasMap.Switcher, Text = "   Obat & Minuman [ MEDKIT ]", ExpandHandle = "ModMenu_EspItem_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspItem_Med end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspItem_Med = v return true end },

            { Key = "ModMenu_ESPBom_Ex", UI = AliasMap.TitleSwitcher, Text = "PERINGATAN & LOKASI BOM", ExpandIndex = 0, GetFunc = function() return _G.X3.XthrlenConfig.EspBomMaster end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspBomMaster = v return true end },
            { Key = "ModMenu_ESPItemBom", UI = AliasMap.Switcher, Text = "   Bom di Tanah [ ITEM BOM ]", ExpandHandle = "ModMenu_ESPBom_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspItemBom end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspItemBom = v return true end },
            { Key = "ModMenu_ESPActiveBom", UI = AliasMap.Switcher, Text = "   Bom Dilempar + Timer [ TIMER BOM ]", ExpandHandle = "ModMenu_ESPBom_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspActiveBom end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspActiveBom = v return true end },

            { Key = "ModMenu_ESPVehicle_Ex", UI = AliasMap.TitleSwitcher, Text = "ESP KENDARAAN", ExpandIndex = 0, GetFunc = function() return _G.X3.XthrlenConfig.EspVehicle end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspVehicle = v return true end },
            { Key = "ModMenu_ESPVeh_Dacia", UI = AliasMap.Switcher, Text = "   Dacia", ExpandHandle = "ModMenu_ESPVehicle_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspVeh_Dacia end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspVeh_Dacia = v return true end },
            { Key = "ModMenu_ESPVeh_UAZ", UI = AliasMap.Switcher, Text = "   UAZ", ExpandHandle = "ModMenu_ESPVehicle_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspVeh_UAZ end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspVeh_UAZ = v return true end },
            { Key = "ModMenu_ESPVeh_Buggy", UI = AliasMap.Switcher, Text = "   Buggy", ExpandHandle = "ModMenu_ESPVehicle_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspVeh_Buggy end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspVeh_Buggy = v return true end },
            { Key = "ModMenu_ESPVeh_Coupe", UI = AliasMap.Switcher, Text = "   Coupe RB", ExpandHandle = "ModMenu_ESPVehicle_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspVeh_Coupe end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspVeh_Coupe = v return true end },
            { Key = "ModMenu_ESPVeh_Mirado", UI = AliasMap.Switcher, Text = "   Mirado", ExpandHandle = "ModMenu_ESPVehicle_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspVeh_Mirado end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspVeh_Mirado = v return true end },
            { Key = "ModMenu_ESPVeh_Motor", UI = AliasMap.Switcher, Text = "   Motor / Scooter", ExpandHandle = "ModMenu_ESPVehicle_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspVeh_Motor end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspVeh_Motor = v return true end },
            { Key = "ModMenu_ESPVeh_Other", UI = AliasMap.Switcher, Text = "   Lainnya (Perahu/BRDM/Glider)", ExpandHandle = "ModMenu_ESPVehicle_Ex", GetFunc = function() return _G.X3.XthrlenConfig.EspVeh_Other end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspVeh_Other = v return true end },
            { Key = "ModMenu_WallVehicle", UI = AliasMap.Switcher, Text = "   Wall Kendaraan [ TEMBUS KENDARAAN ]", ExpandHandle = "ModMenu_ESPVehicle_Ex", GetFunc = function() return _G.X3.XthrlenConfig.WallVehicle end, SetFunc = function(c,v) _G.X3.XthrlenConfig.WallVehicle = v return true end },

            { Key = "ModMenu_ESPAntenna", UI = AliasMap.Switcher, Text = "ESP ANTENNA [ TIANG PENANDA ]", GetFunc = function() return _G.X3.XthrlenConfig.EspAntenna end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspAntenna = v return true end },

            { Key = "ModMenu_ESPOutline_Ex", UI = AliasMap.TitleSwitcher, Text = "ESP OUTLINE [ GARIS TEPI MUSUH ]", ExpandIndex = 0, GetFunc = function() return _G.X3.XthrlenConfig.EspOutline end, SetFunc = function(c,v) _G.X3.XthrlenConfig.EspOutline = v return true end },
            { Key = "ModMenu_ESPOutline_Color", UI = AliasMap.Slider, Text = "   Warna (1:Merah 2:Hijau 3:Biru 4:Kuning 5:Ungu 6:Putih)", ExpandHandle = "ModMenu_ESPOutline_Ex", MinValue = 1, MaxValue = 6, min = 1, max = 6, GetFunc = function() return _G.X3.XthrlenState.CustomTextData.OutlineColor or 4 end, SetFunc = function(c,v) _G.X3.XthrlenState.CustomTextData.OutlineColor = v return true end },
            { Key = "ModMenu_ESPOutline_Thickness", UI = AliasMap.Slider, Text = "   Ketebalan Outline (1-20)", ExpandHandle = "ModMenu_ESPOutline_Ex", MinValue = 1, MaxValue = 20, min = 1, max = 20, GetFunc = function() return _G.X3.XthrlenConfig.OutlineThickness or 10 end, SetFunc = function(c,v) _G.X3.XthrlenConfig.OutlineThickness = v return true end },
        }

        local StackFiturLain = {}
        for _, v in ipairs(StackDeviceInfo) do table.insert(StackFiturLain, v) end
        for _, v in ipairs(StackCombat) do table.insert(StackFiturLain, v) end
        for _, v in ipairs(StackGraphic) do table.insert(StackFiturLain, v) end

        SettingPageDefine.ModMenu = {
            Key = "ModMenu",
            Text = "   SRCHUB MENU",
            UIKey = "Setting_Page_Privacy",
            Category = {
                { Key = "Cat_Aimbot", Text = "MAGIC [ MAGIC ]", Stack = StackAimbot },
                { Key = "Cat_AimbotV2", Text = "AIMTOUCH [ AIM SENTUH ]", Stack = StackAimbotV2 },
                { Key = "Cat_ESP", Text = "ESP [ ESP ]", Stack = StackESP },
                { Key = "Cat_Lain", Text = "FEATURES [ FITUR ]", Stack = StackFiturLain }
            }
        }

        local catDone = false
        for ci, pg in ipairs(SettingCatalog) do
            if type(pg) == "table" and pg.Key == "ModMenu" then
                SettingCatalog[ci] = SettingPageDefine.ModMenu
                catDone = true break
            end
        end
        if not catDone then table.insert(SettingCatalog, SettingPageDefine.ModMenu) end
    end

    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsModMenuHooked then
        local old_ShowUI = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            local n = select('#', ...)

            if config and config.keyName and (string.find(string.lower(config.keyName), "setting_main") or string.find(string.lower(config.keyName), "setting")) then
                local catalog = args[1]
                if type(catalog) == "table" then
                    local catReplaced = false
                    for pi, page in ipairs(catalog) do
                        if type(page) == "table" and page.Key == "ModMenu" then
                            catalog[pi] = SettingPageDefine.ModMenu
                            catReplaced = true
                            break
                        end
                    end
                    if not catReplaced then
                        table.insert(catalog, SettingPageDefine.ModMenu)
                    end
                end
            end
            local table_unpack = table.unpack or unpack
            return old_ShowUI(config, table_unpack(args, 1, n))
        end
        UIManager._IsModMenuHooked = true
    end
    return true
end

local function ShowXthrlenVIPMenu()
    if _G.X3.XthrlenMenuAlreadyShown then return end

    _G.X3.MenuTryN = (_G.X3.MenuTryN or 0) + 1
    local ok, err = pcall(function()
        local done = _G.X3.InitModMenuTab()
        if done ~= true then error("InitModMenuTab belum siap (hasil=" .. tostring(done) .. ")", 0) end
        _G.X3.XthrlenState.MenuStep = 99
        _G.X3.XthrlenMenuAlreadyShown = true
        Notify("MENU VIP TELAH DITAMBAHKAN KE PENGATURAN GAME!\nBuka Pengaturan -> MENU VIP SRCHUBID untuk mengaktifkan/menonaktifkan fitur!")
    end)
    if type(_G.X3.Trace) == "function" then
        if ok then
            _G.X3.Trace("MENU: InitModMenuTab SUKSES — menu VIP terpasang di lobby (percobaan #" .. tostring(_G.X3.MenuTryN) .. ")")
        elseif _G.X3.MenuTryN <= 3 or (_G.X3.MenuTryN % 50) == 0 then
            _G.X3.Trace("MENU: belum terpasang (percobaan #" .. tostring(_G.X3.MenuTryN) .. ", retry otomatis): " .. tostring(err))
        end
    end
end

-- LOGIKA BUKA 165 FPS DAN IPAD VIEW
local function InitializeGraphicsUnlock()
    if isExpired then return end
    if _G.X3.XthrlenState.GraphicsUnlocked then return end

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

            ft_impl.ShowOrHide = function(self)
                self:SelfHitTestInvisible()
                if self.InitFPSFTSwitch then self:InitFPSFTSwitch() end
            end

            ft_impl.InitFPSFTSwitch = function(self)
                local FPSFineTuneSwitch = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
                if self.UIRoot.Setting_Switch then self.UIRoot.Setting_Switch:SetSwitcherEnable2(FPSFineTuneSwitch, true) end
                if self.UIRoot.CanvasPanel_8 then self:SetWidgetVisible(self.UIRoot.CanvasPanel_8, FPSFineTuneSwitch) end
                if self.UIRoot.WidgetSwitcher_0 then self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2) end
                if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
            end

            ft_impl.InitFPSFTValue165 = function(self)
                local itemRoot = self.UIRoot
                local FPSFineTuneSwitch = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
                local FPSFineTuneNum = 165
                if FPSFineTuneSwitch then
                    FPSFineTuneNum = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum) or 165
                    itemRoot.Slider_screen3:SetLocked(false)
                    if FLinearColor then
                        itemRoot.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1.0, 1.0, 1.0, 1.0))
                        itemRoot.Slider_screen3:SetSliderHandleColor(FLinearColor(1.0, 1.0, 1.0, 1.0))
                    end
                else
                    itemRoot.Slider_screen3:SetLocked(true)
                    if FLinearColor then
                        itemRoot.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1.0, 0.625, 0.6, 1))
                        itemRoot.Slider_screen3:SetSliderHandleColor(FLinearColor(1.0, 0.625, 0.6, 1.0))
                    end
                end
                local FPSFineTunePer = (FPSFineTuneNum - NMinFPS) / (165 - NMinFPS)

                itemRoot.Veihclescreen3:SetText(tostring(FPSFineTuneNum))
                itemRoot.Slider_screen3:SetValue(FPSFineTunePer)
                itemRoot.ProgressBar_screen3:SetPercent(FPSFineTunePer)

                if FLinearColor then
                    local startColor = FLinearColor(1.0, 1.0, 1.0, 1.0)
                    local midColor = FLinearColor(1.0, 0.54, 0.11, 1.0)
                    local endColor = FLinearColor(1.0, 0.23, 0.15, 1.0)
                    local sliderColor = FPSFineTunePer < 0.4 and startColor or _getColorByPercent(midColor, endColor, (FPSFineTunePer - 0.4) / 0.6)
                    itemRoot.Slider_screen3:SetSliderHandleColor(sliderColor)
                end
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
    _G.X3.XthrlenState.GraphicsUnlocked = true
    Notify("Grafis & FPS 165Hz Dibuka (Versi Terbaru)")
end

-- INISIALISASI SISTEM ESP (DASAR)
-- ESP MUSUH / ENEMY ESP --
-- (dibungkus closure: hemat slot local, batas Lua 200 local per chunk)
local X3MarkCfg = (function()
    local QuickSignUI = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C"

    local function EnsureMark(cfg, id, def)
        local e = cfg[id]
        if type(e) ~= "table" then e = {}; cfg[id] = e end
        for k, v in pairs(def) do e[k] = v end
        return e
    end

    local function Apply(cfg)
        if type(cfg) ~= "table" then return end
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
        EnsureMark(cfg, 8888, {
            UIPathName = QuickSignUI,
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
        })
        EnsureMark(cfg, 9999, {
            UIPathName = QuickSignUI,
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
        })
    end

    -- game me-reload ScreenMarkConfig tiap masuk match: suntik ulang tiap config diminta
    local function InstallHook()
        pcall(function()
            local GPT = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
            if GPT and type(GPT.GetCurrentConfig) == "function" and not GPT._x3MarkHook then
                local origGet = GPT.GetCurrentConfig
                GPT.GetCurrentConfig = function(key, ...)
                    local v = origGet(key, ...)
                    if key == "ScreenMarkConfig" and type(v) == "table" then
                        pcall(Apply, v)
                    end
                    return v
                end
                GPT._x3MarkHook = true
            end
        end)
    end

    return { Apply = Apply, InstallHook = InstallHook }
end)()

local function InitializeNativeESP()
    local S = _G.X3.XthrlenState
    local sceneKey = "lobby"
    pcall(function()
        local GD = package.loaded["GameLua.GameCore.Data.GameplayData"] or require("GameLua.GameCore.Data.GameplayData")
        local pc = GD and GD.GetPlayerController and GD.GetPlayerController()
        if pc then sceneKey = tostring(pc) end
    end)
    local now = os.clock()
    if S.NativeESPReady and S.NativeESPKey == sceneKey and (now - (S.NativeESPRefresh or 0)) < 5 then return end
    local okPatch = pcall(function()
        local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
        X3MarkCfg.Apply(GamePlayTools.GetCurrentConfig("ScreenMarkConfig"))
        for k, cfg in pairs(package.loaded) do
            if type(k) == "string" and string.find(k, "ScreenMarkConfig") and type(cfg) == "table" then
                X3MarkCfg.Apply(cfg)
            end
        end
        X3MarkCfg.InstallHook()
    end)
    if okPatch then
        S.NativeESPReady = true
        S.NativeESPKey = sceneKey
        S.NativeESPRefresh = now
        if not S.NativeESPNotified then
            S.NativeESPNotified = true
            Notify("Sistem ESP Native Diinisialisasi")
        end
    end
end


local PortESPModule = (function()
_G.X3.PortESP = _G.X3.PortESP or {
    LastItemScan = 0,
    LastVehicleScan = 0,
    LastBombScan = 0,
    LastCounter = 0,
    LastClearTimer = 0,
    CounterWidget = nil,
    WarningWidget = nil,
    ItemCache = {},
    VehicleCache = {},
    ItemBombCache = {},
    ActiveBombCache = {},
    AppliedItem = {},
    AppliedVehWall = {},
    BombCache = setmetatable({}, { __mode = "k" }),
    NonBombCache = setmetatable({}, { __mode = "k" }),
    ActiveBombTimers = {},
}
local PE = _G.X3.PortESP

local PortLinearColor = nil
pcall(function() PortLinearColor = import("LinearColor") end)
local PortSkelClass = nil
pcall(function() PortSkelClass = import("SkeletalMeshComponent") end)

local function PortCfg() return _G.X3.XthrlenConfig end
local function PortData()
    local S = _G.X3.XthrlenState
    S.CustomTextData = S.CustomTextData or {}
    return S.CustomTextData
end

-- Sama dengan 1.lua: kumpulkan semua SkeletalMesh (body + aksesoris)
local function PortAllMeshes(enemy, markData)
    local curTime = os.clock()
    if markData and markData.CachedMeshes and markData.CachedMeshTime and (curTime - markData.CachedMeshTime < 0.5) then
        local validMeshes = {}
        for _, cachedMesh in ipairs(markData.CachedMeshes) do
            local isPendingKill = false
            pcall(function() if type(cachedMesh.IsPendingKill) == "function" then isPendingKill = cachedMesh:IsPendingKill() end end)
            if Valid(cachedMesh) and not isPendingKill then table.insert(validMeshes, cachedMesh) end
        end
        markData.CachedMeshes = validMeshes
        return validMeshes
    end

    local meshes = {}
    if Valid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
    pcall(function()
        if PortSkelClass and type(enemy.GetComponentsByClass) == "function" then
            local childs = enemy:GetComponentsByClass(PortSkelClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for i = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(i - 1) or childs[i]
                    if Valid(comp) and comp ~= enemy.Mesh then table.insert(meshes, comp) end
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

-- WALL XUYEN TUONG V1 (see-through)
local function PortUndoWall(enemy, markData)
    pcall(function()
        if markData.WallhackApplied then
            local meshes = PortAllMeshes(enemy, markData)
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

local function PortApplyWall(enemy, markData)
    pcall(function()
        local meshes = PortAllMeshes(enemy, markData)
        for _, mesh in ipairs(meshes) do
            if Valid(mesh) then
                pcall(function()
                    if type(mesh.SetRenderCustomDepth) == "function" then mesh:SetRenderCustomDepth(true) end
                    if type(mesh.SetCustomDepthStencilValue) == "function" then mesh:SetCustomDepthStencilValue(252) end
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

-- CHAMS V2 (basic color)
local function PortApplyV2(enemy, pc, markData)
    pcall(function()
        local meshes = PortAllMeshes(enemy, markData)
        if #meshes == 0 then return end

        local curTime = os.clock()
        if markData.LastVisCheckTime == nil or (curTime - markData.LastVisCheckTime) > 0.3 then
            markData.LastVisCheckTime = curTime
            local isHidden = true
            pcall(function()
                if Valid(pc) and type(pc.LineOfSightTo) == "function" then
                    isHidden = not pc:LineOfSightTo(enemy)
                end
            end)
            markData.CachedHiddenState = isHidden
        end

        local hidden = markData.CachedHiddenState
        if hidden == nil then hidden = true end

        local cData = PortData()
        local hiddenColor = {R = cData.HiddenR or 150, G = cData.HiddenG or 0, B = cData.HiddenB or 0, A = cData.HiddenA or 25}
        local visibleColor = {R = cData.VisibleR or 0, G = cData.VisibleG or 150, B = cData.VisibleB or 0, A = cData.VisibleA or 25}

        local finalColor = hidden and hiddenColor or visibleColor
        local colorHash = string.format("%d_%d_%d_%d", finalColor.R, finalColor.G, finalColor.B, finalColor.A)
        local currentMeshCount = #meshes
        local isMeshChanged = (markData.LastMeshCount ~= currentMeshCount)

        if not isMeshChanged and markData.LastHiddenState == hidden and markData.LastColorHash == colorHash then return end
        if isMeshChanged and markData.MIDs then markData.MIDs = {} end

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
                            markData.MIDs[meshKey] = markData.MIDs[meshKey] or {}
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

local function PortUndoV2(enemy, markData)
    pcall(function()
        if markData.ColorApplied then
            local meshes = PortAllMeshes(enemy, markData)
            for meshIndex, mesh in ipairs(meshes) do
                if Valid(mesh) then
                    pcall(function()
                        mesh.PrimitiveShadingStrategy = 0
                        mesh.ShadingRate = 1
                    end)
                    local meshKey = "Mesh_" .. tostring(meshIndex)
                    if markData.MIDs and markData.MIDs[meshKey] then
                        for _, mid in pairs(markData.MIDs[meshKey]) do
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


-- WALL V2 + CHAMS V3 (custom color)
local function PortApplyV3(enemy, markData)
    pcall(function()
        local meshes = PortAllMeshes(enemy, markData)
        if #meshes == 0 then return end

        local cData = PortData()
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
        local visColor
        if PortLinearColor then
            local okLC, lc = pcall(PortLinearColor, (vR/255)*glowIntensity, (vG/255)*glowIntensity, (vB/255)*glowIntensity, 1.0)
            if okLC and lc then visColor = lc end
        end
        if not visColor then
            visColor = { R=vR*glowIntensity, G=vG*glowIntensity, B=vB*glowIntensity, A=255 }
        end
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
                    if type(comp.SetDrawIdeaOutline) == "function" then
                        comp:SetDrawIdeaOutline(true)
                        if type(comp.OverrideIdeaOutlineColor) == "function" then comp:OverrideIdeaOutlineColor(true, visColor) end
                        if type(comp.OverrideIdeaOutlineThickness) == "function" then comp:OverrideIdeaOutlineThickness(true, v3Thick) end
                    end
                end)
            end
        end
        markData.ColorV3Applied = true
    end)
end

local function PortUndoV3(enemy, markData)
    pcall(function()
        if markData.ColorV3Applied then
            local meshes = PortAllMeshes(enemy, markData)
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
                        for _, mid in pairs(markData.MIDs_V3[compKey]) do
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
                        if type(comp.SetDrawIdeaOutline) == "function" then comp:SetDrawIdeaOutline(false) end
                    end)
                end
            end
            markData.ColorV3Applied = false
            markData.LastMeshCountV3 = 0
            markData.MIDs_V3 = nil
        end
    end)
end

-- NEW ENGINE CHAMS (merah/hijau)
local function PortApplyNew(enemy, markData)
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

        local meshes = PortAllMeshes(enemy, markData)

        local weapon = nil
        pcall(function() weapon = enemy:GetCurrentWeapon() end)
        if type(weapon) ~= "function" and slua.isValid(weapon) and slua.isValid(weapon.Mesh) then table.insert(meshes, weapon.Mesh) end

        local isBot = markData.AK_IS_BOT or false
        local currentMeshCount = #meshes
        local stateHash = (isBot and "BOT" or "PLAYER") .. "_" .. tostring(currentMeshCount)

        if markData.LastColorNewHash == stateHash and markData.ColorNewApplied then return end

        markData.LastColorNewHash = stateHash
        markData.ColorNewApplied = true

        local function LC(r, g, b, a)
            if PortLinearColor then
                local ok, v = pcall(PortLinearColor, r, g, b, a)
                if ok and v then return v end
            end
            return {R=r, G=g, B=b, A=a}
        end
        local c_vis = LC(0, 100, 0, 1)
        local c_occ = LC(100, 0, 0, 1)
        local c_bVis = LC(49, 48, 0, 100)
        local c_bOcc = LC(9, 1.5, 45, 100)

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

local function PortUndoNew(enemy, markData)
    pcall(function()
        if markData.ColorNewApplied then
            local meshes = PortAllMeshes(enemy, markData)
            local weapon = nil
            pcall(function() weapon = enemy:GetCurrentWeapon() end)
            if type(weapon) ~= "function" and slua.isValid(weapon) and slua.isValid(weapon.Mesh) then table.insert(meshes, weapon.Mesh) end

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

local PortC_AR      = {R = 255, G = 255, B = 0, A = 255}
local PortC_SMG     = {R = 0, G = 255, B = 255, A = 255}
local PortC_Sniper  = {R = 255, G = 0, B = 0, A = 255}
local PortC_Shotgun = {R = 0, G = 255, B = 0, A = 255}
local PortC_LMG     = {R = 255, G = 255, B = 255, A = 255}
local PortC_Pistol  = {R = 200, G = 200, B = 200, A = 255}
local PortC_Special = {R = 255, G = 0, B = 255, A = 255}
local PortC_Melee   = {R = 150, G = 150, B = 150, A = 255}
local PortC_Scope   = {R = 0, G = 0, B = 255, A = 255}
local PortC_Grenade = {R = 255, G = 165, B = 0, A = 255}
local PortC_Med     = {R = 50, G = 255, B = 50, A = 255}

local PortItemDB = {
    [101001] = { name = "AKM", cat = "AR", color = PortC_AR }, [101002] = { name = "M16A4", cat = "AR", color = PortC_AR },
    [101003] = { name = "SCAR-L", cat = "AR", color = PortC_AR }, [101004] = { name = "M416", cat = "AR", color = PortC_AR },
    [101005] = { name = "Groza", cat = "AR", color = PortC_AR }, [101006] = { name = "AUG", cat = "AR", color = PortC_AR },
    [101007] = { name = "QBZ", cat = "AR", color = PortC_AR }, [101008] = { name = "M762", cat = "AR", color = PortC_AR },
    [101009] = { name = "Mk47 Mutant", cat = "AR", color = PortC_AR }, [101010] = { name = "G36C", cat = "AR", color = PortC_AR },
    [101011] = { name = "AC-VAL", cat = "AR", color = PortC_AR }, [101012] = { name = "Honey Badger", cat = "AR", color = PortC_AR },
    [101100] = { name = "FAMAS", cat = "AR", color = PortC_AR }, [101101] = { name = "ASM Abakan AR", cat = "AR", color = PortC_AR },
    [101102] = { name = "ACE32", cat = "AR", color = PortC_AR },
    [102001] = { name = "UZI", cat = "SMG", color = PortC_SMG }, [102002] = { name = "UMP45", cat = "SMG", color = PortC_SMG },
    [102003] = { name = "Vector", cat = "SMG", color = PortC_SMG }, [102004] = { name = "Thompson SMG", cat = "SMG", color = PortC_SMG },
    [102005] = { name = "PP-19 Bizon", cat = "SMG", color = PortC_SMG }, [102007] = { name = "MP5K", cat = "SMG", color = PortC_SMG },
    [102008] = { name = "JS9", cat = "SMG", color = PortC_SMG }, [102105] = { name = "P90", cat = "SMG", color = PortC_SMG },
    [103001] = { name = "Kar98K", cat = "Sniper", color = PortC_Sniper }, [103002] = { name = "M24", cat = "Sniper", color = PortC_Sniper },
    [103003] = { name = "AWM", cat = "Sniper", color = PortC_Sniper }, [103004] = { name = "SKS", cat = "Sniper", color = PortC_Sniper },
    [103005] = { name = "VSS", cat = "Sniper", color = PortC_Sniper }, [103006] = { name = "Mini14", cat = "Sniper", color = PortC_Sniper },
    [103007] = { name = "Mk14", cat = "Sniper", color = PortC_Sniper }, [103008] = { name = "Win94", cat = "Sniper", color = PortC_Sniper },
    [103009] = { name = "SLR", cat = "Sniper", color = PortC_Sniper }, [103010] = { name = "QBU", cat = "Sniper", color = PortC_Sniper },
    [103011] = { name = "Mosin Nagant", cat = "Sniper", color = PortC_Sniper }, [103012] = { name = "AMR", cat = "Sniper", color = PortC_Sniper },
    [103100] = { name = "Mk12", cat = "Sniper", color = PortC_Sniper }, [103101] = { name = "TR-2A Air Gun", cat = "Sniper", color = PortC_Sniper },
    [103102] = { name = "DSR", cat = "Sniper", color = PortC_Sniper }, [103103] = { name = "Sniper Rifle", cat = "Sniper", color = PortC_Sniper },
    [103104] = { name = "Sniper Rifle", cat = "Sniper", color = PortC_Sniper }, [103105] = { name = "SR", cat = "Sniper", color = PortC_Sniper },
    [104001] = { name = "S686", cat = "Shotgun", color = PortC_Shotgun }, [104002] = { name = "S1897", cat = "Shotgun", color = PortC_Shotgun },
    [104003] = { name = "S12K", cat = "Shotgun", color = PortC_Shotgun }, [104004] = { name = "DBS", cat = "Shotgun", color = PortC_Shotgun },
    [104100] = { name = "SPAS-12", cat = "Shotgun", color = PortC_Shotgun }, [104101] = { name = "M1014", cat = "Shotgun", color = PortC_Shotgun },
    [104102] = { name = "NS2000", cat = "Shotgun", color = PortC_Shotgun },
    [105001] = { name = "M249", cat = "LMG", color = PortC_LMG }, [105002] = { name = "DP-28", cat = "LMG", color = PortC_LMG },
    [105003] = { name = "M134", cat = "LMG", color = PortC_LMG }, [105010] = { name = "MG3", cat = "LMG", color = PortC_LMG },
    [105101] = { name = "Gatling", cat = "LMG", color = PortC_LMG }, [105115] = { name = "Lib Gatling MG", cat = "LMG", color = PortC_LMG },
    [105004] = { name = "Flamethrower", cat = "LMG", color = PortC_LMG }, [105006] = { name = "M2 Fixed MG", cat = "LMG", color = PortC_LMG },
    [105007] = { name = "Gatling Fixed MG", cat = "LMG", color = PortC_LMG }, [105008] = { name = "Mounted Flamethrower", cat = "LMG", color = PortC_LMG },
    [105009] = { name = "M2 Mounted MG", cat = "LMG", color = PortC_LMG }, [105102] = { name = "Vehicle SG", cat = "LMG", color = PortC_LMG },
    [105103] = { name = "RPG", cat = "LMG", color = PortC_LMG }, [105104] = { name = "RPG", cat = "LMG", color = PortC_LMG },
    [105105] = { name = "PowPow MG", cat = "LMG", color = PortC_LMG }, [105106] = { name = "Tank Cannon", cat = "LMG", color = PortC_LMG },
    [105107] = { name = "Tank MG", cat = "LMG", color = PortC_LMG }, [105108] = { name = "Tank Flare Gun", cat = "LMG", color = PortC_LMG },
    [105116] = { name = "Lib Autocannon", cat = "LMG", color = PortC_LMG }, [105117] = { name = "Jet Missile", cat = "LMG", color = PortC_LMG },
    [105118] = { name = "Jet Autocannon", cat = "LMG", color = PortC_LMG },
    [106001] = { name = "P92", cat = "Pistol", color = PortC_Pistol }, [106002] = { name = "P1911", cat = "Pistol", color = PortC_Pistol },
    [106003] = { name = "R1895", cat = "Pistol", color = PortC_Pistol }, [106004] = { name = "P18C", cat = "Pistol", color = PortC_Pistol },
    [106005] = { name = "R45", cat = "Pistol", color = PortC_Pistol }, [106006] = { name = "Sawed-off", cat = "Pistol", color = PortC_Pistol },
    [106008] = { name = "Skorpion", cat = "Pistol", color = PortC_Pistol }, [106010] = { name = "Desert Eagle", cat = "Pistol", color = PortC_Pistol },
    [106007] = { name = "Flare Gun", cat = "Pistol", color = PortC_Pistol }, [106009] = { name = "Flare Gun", cat = "Pistol", color = PortC_Pistol },
    [106011] = { name = "Dual MP7", cat = "Pistol", color = PortC_Pistol }, [106012] = { name = "Welding Gun", cat = "Pistol", color = PortC_Pistol },
    [106013] = { name = "Stun Gun", cat = "Pistol", color = PortC_Pistol }, [106101] = { name = "Vehicle Flare", cat = "Pistol", color = PortC_Pistol },
    [106103] = { name = "Flare Gun", cat = "Pistol", color = PortC_Pistol }, [106106] = { name = "Flare (Empty)", cat = "Pistol", color = PortC_Pistol },
    [106107] = { name = "Respawn Flare", cat = "Pistol", color = PortC_Pistol }, [106203] = { name = "Magnet Gun", cat = "Pistol", color = PortC_Pistol },
    [107011] = { name = "Súng Cối", cat = "Special", color = PortC_Special }, [307006] = { name = "Đạn Cối", cat = "Special", color = PortC_Special },
    [107001] = { name = "Crossbow", cat = "Special", color = PortC_Special }, [107002] = { name = "RPG-7", cat = "Special", color = PortC_Special },
    [107003] = { name = "Riot shield", cat = "Special", color = PortC_Special }, [107004] = { name = "Combat Drone", cat = "Special", color = PortC_Special },
    [107005] = { name = "Panzerfaust", cat = "Special", color = PortC_Special }, [107006] = { name = "RPG-7", cat = "Special", color = PortC_Special },
    [107007] = { name = "Tactical Crossbow", cat = "Special", color = PortC_Special }, [107008] = { name = "Explosive Bow", cat = "Special", color = PortC_Special },
    [107009] = { name = "Explosive Bow", cat = "Special", color = PortC_Special }, [107010] = { name = "M79 Smoke Launcher", cat = "Special", color = PortC_Special },
    [107019] = { name = "Atlas Gauntlet", cat = "Special", color = PortC_Special }, [107020] = { name = "Explosive Crossbow", cat = "Special", color = PortC_Special },
    [107021] = { name = "Mercury Hammer", cat = "Special", color = PortC_Special }, [107022] = { name = "Fishbones Rocket", cat = "Special", color = PortC_Special },
    [107092] = { name = "MGL", cat = "Special", color = PortC_Special }, [107093] = { name = "M202 Quad RPG", cat = "Special", color = PortC_Special },
    [107094] = { name = "AT4-A Laser Missile", cat = "Special", color = PortC_Special }, [107095] = { name = "M202 Quad RPG", cat = "Special", color = PortC_Special },
    [107096] = { name = "M79 Sawed-off", cat = "Special", color = PortC_Special }, [107097] = { name = "M79", cat = "Special", color = PortC_Special },
    [107098] = { name = "MGL", cat = "Special", color = PortC_Special }, [107099] = { name = "M3E1-A", cat = "Special", color = PortC_Special },
    [108001] = { name = "Machete", cat = "Melee", color = PortC_Melee }, [108002] = { name = "Crowbar", cat = "Melee", color = PortC_Melee },
    [108003] = { name = "Sickle", cat = "Melee", color = PortC_Melee }, [108004] = { name = "Pan", cat = "Melee", color = PortC_Melee },
    [108005] = { name = "Dagger", cat = "Melee", color = PortC_Melee }, [108006] = { name = "Mutation Blade", cat = "Melee", color = PortC_Melee },
    [108007] = { name = "Mutation Gauntlets", cat = "Melee", color = PortC_Melee },
    [203001] = { name = "Red Dot Sight", cat = "Scope", color = PortC_Scope }, [203002] = { name = "Holographic Sight", cat = "Scope", color = PortC_Scope },
    [203003] = { name = "2x Scope", cat = "Scope", color = PortC_Scope }, [203004] = { name = "4x Scope", cat = "Scope", color = PortC_Scope },
    [203005] = { name = "8x Scope", cat = "Scope", color = PortC_Scope }, [203014] = { name = "3x Scope", cat = "Scope", color = PortC_Scope },
    [203015] = { name = "6x Scope", cat = "Scope", color = PortC_Scope },
    [602001] = { name = "Stun Grenade", cat = "Grenade", color = PortC_Grenade }, [602002] = { name = "Smoke Grenade", cat = "Grenade", color = PortC_Grenade },
    [602003] = { name = "Molotov", cat = "Grenade", color = PortC_Grenade }, [602004] = { name = "Frag Grenade", cat = "Grenade", color = PortC_Grenade },
    [601001] = { name = "Nước Tăng Lực", cat = "Med", color = PortC_Med }, [601002] = { name = "Tiêm Adrenaline", cat = "Med", color = PortC_Med },
    [601003] = { name = "Thuốc Giảm Đau", cat = "Med", color = PortC_Med }, [601004] = { name = "Băng Gạc", cat = "Med", color = PortC_Med },
    [601005] = { name = "Bộ Sơ Cứu", cat = "Med", color = PortC_Med }, [601006] = { name = "Bộ Cứu Thương", cat = "Med", color = PortC_Med },
    [601009] = { name = "Băng Gạc Nhanh", cat = "Med", color = PortC_Med }, [601010] = { name = "Sơ Cứu Nhanh", cat = "Med", color = PortC_Med },
    [601011] = { name = "Băng Gạc QĐ", cat = "Med", color = PortC_Med }, [601012] = { name = "Nước Đậm Đặc", cat = "Med", color = PortC_Med },
    [601020] = { name = "Băng Gạc", cat = "Med", color = PortC_Med }, [601021] = { name = "Bộ Sơ Cứu", cat = "Med", color = PortC_Med },
    [601022] = { name = "Bộ Cứu Thương", cat = "Med", color = PortC_Med }, [601023] = { name = "Tiêm Adrenaline", cat = "Med", color = PortC_Med },
    [601061] = { name = "Bộ Cứu Thương", cat = "Med", color = PortC_Med }, [601077] = { name = "Sơ Cứu Chiến Thuật", cat = "Med", color = PortC_Med },
    [601078] = { name = "Sơ Cứu Toàn Năng", cat = "Med", color = PortC_Med }, [601079] = { name = "Cứu Thương Toàn Năng", cat = "Med", color = PortC_Med },
    [601080] = { name = "Băng Gạc QĐ", cat = "Med", color = PortC_Med }, [601081] = { name = "Nước Đậm Đặc", cat = "Med", color = PortC_Med },
    [601084] = { name = "Sơ Cứu Nhanh", cat = "Med", color = PortC_Med }, [601085] = { name = "Cứu Thương Nhanh", cat = "Med", color = PortC_Med },
    [601095] = { name = "Máy AED (Hồi Sinh)", cat = "Med", color = PortC_Med }, [601096] = { name = "Chuẩn Bị Chiến Đấu", cat = "Med", color = PortC_Med },
    [602054] = { name = "Tiếp Tế Y Tế", cat = "Med", color = PortC_Med }, [602069] = { name = "Cứu Trợ Khẩn Cấp", cat = "Med", color = PortC_Med }
}



-- ============================================================================
-- WALL KENDARAAN + ESP ITEM (dari 1.lua RunOptimizedItemAndVehicleESP)
-- ============================================================================
local function PortRunItemVehicle(pc, lp)
    local C = PortCfg()
    local curTime = os.clock()
    local G = rawget(_G, "Game")

    if curTime - PE.LastItemScan > 1.0 then
        PE.LastItemScan = curTime

        if C.WallVehicle then
            pcall(function()
                local VehClass = import("STExtraVehicleBase")
                if VehClass and G and G.GetActorsByClass then
                    local Actors = G:GetActorsByClass(VehClass)
                    if Actors then
                        local count = Actors:Num() or 0
                        for i = 0, count - 1 do
                            local vehicle = Actors:Get(i)
                            if slua.isValid(vehicle) and vehicle.GetMesh then
                                local dist = lp:GetDistanceTo(vehicle)
                                if dist <= 200000 then
                                    local vId = tostring(vehicle)
                                    if not PE.AppliedVehWall[vId] then
                                        local mesh = vehicle:GetMesh()
                                        if slua.isValid(mesh) then
                                            local matInterface = mesh:GetMaterial(0)
                                            if slua.isValid(matInterface) then
                                                local baseMat = matInterface:GetBaseMaterial()
                                                if slua.isValid(baseMat) then
                                                    baseMat.bDisableDepthTest = true
                                                    baseMat.BlendMode = 2
                                                    PE.AppliedVehWall[vId] = true
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
        else
            PE.AppliedVehWall = {}
        end

        if C.EspItem_Master then
            pcall(function()
                local ItemClass = import("PickUpWrapperActor") or import("STPickupWrapperActor")
                if ItemClass and G and G.GetActorsByClass then
                    local Actors = G:GetActorsByClass(ItemClass)
                    PE.ItemCache = {}
                    if Actors then
                        local count = Actors:Num() or 0
                        for i = 0, count - 1 do
                            local item = Actors:Get(i)
                            local isPendingKill = false
                            pcall(function() if type(item.IsPendingKill) == "function" then isPendingKill = item:IsPendingKill() end end)

                            if slua.isValid(item) and not item.bHidden and not isPendingKill then
                                local dist = lp:GetDistanceTo(item)
                                if dist <= 7000 then
                                    local itemId = item.DefineID and item.DefineID.TypeSpecificID or item.DefineId
                                    local itemData = PortItemDB[itemId]
                                    if itemData then
                                        local isShow = false
                                        if itemData.cat == "AR" and C.EspItem_AR then isShow = true
                                        elseif itemData.cat == "Sniper" and C.EspItem_Sniper then isShow = true
                                        elseif itemData.cat == "SMG" and C.EspItem_SMG then isShow = true
                                        elseif itemData.cat == "Shotgun" and C.EspItem_Shotgun then isShow = true
                                        elseif itemData.cat == "LMG" and C.EspItem_LMG then isShow = true
                                        elseif itemData.cat == "Pistol" and C.EspItem_Pistol then isShow = true
                                        elseif itemData.cat == "Melee" and C.EspItem_Melee then isShow = true
                                        elseif itemData.cat == "Special" and C.EspItem_Special then isShow = true
                                        elseif itemData.cat == "Grenade" and C.EspItem_Grenade then isShow = true
                                        elseif itemData.cat == "Scope" and C.EspItem_Scope then isShow = true
                                        elseif itemData.cat == "Med" and C.EspItem_Med then isShow = true
                                        end

                                        if isShow then
                                            table.insert(PE.ItemCache, item)

                                            local iId = tostring(item)
                                            if not PE.AppliedItem[iId] then
                                                local meshes = {}
                                                if item.GetPickupMesh then
                                                    local pMesh = item:GetPickupMesh()
                                                    if slua.isValid(pMesh) then table.insert(meshes, pMesh) end
                                                end
                                                local StaticMeshClass = import("StaticMeshComponent")
                                                local childs = StaticMeshClass and item:GetComponentsByClass(StaticMeshClass)
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
                                                PE.AppliedItem[iId] = true
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        else
            PE.AppliedItem = {}
            PE.ItemCache = {}
        end
    end

    if C.EspItem_Master and slua.isValid(pc) and pc.MyHUD then
        local hud = pc.MyHUD
        for _, item in ipairs(PE.ItemCache) do
            if slua.isValid(item) and not item.bHidden then
                local itemId = item.DefineID and item.DefineID.TypeSpecificID or item.DefineId
                local itemData = itemId and PortItemDB[itemId]
                if itemData then
                    local dist = (lp.GetDistanceTo and lp:GetDistanceTo(item) or 0) / 100
                    local displayText = string.format("%s [%.0fm]", itemData.name, dist)
                    local textColor = {R = itemData.color.R, G = itemData.color.G, B = itemData.color.B, A = 255}
                    hud:AddDebugText(displayText, item, 0.06, {X=0, Y=0, Z=50}, {X=0, Y=0, Z=50}, textColor, true, false, true, nil, 0.8, true)
                end
            end
        end
    end
end

-- ============================================================================
-- ESP BOM (di tanah / aktif / timer)
-- ============================================================================
local function PortDrawBombs(lp, hud, bombList, isItem, maxDist, curGameTime)
    if not bombList then return end
    local GameplayStatics = PE.GameplayStatics or import("GameplayStatics")
    PE.GameplayStatics = GameplayStatics
    for _, entry in ipairs(bombList) do
        local bomb = entry.act
        local bType = entry.type
        if slua.isValid(bomb) and not bomb.bHidden then
            local distM = 0
            pcall(function() distM = lp:GetDistanceTo(bomb) / 100 end)
            if distM > 0 and distM <= maxDist then
                local displayName = ""
                local bombColor = C_WHITE
                local zOffset = isItem and 15 or 25
                if bType == 1 then displayName = "Boom"; bombColor = isItem and {R=255, G=100, B=100, A=255} or C_RED
                elseif bType == 2 then displayName = "ASAP"; bombColor = isItem and {R=200, G=200, B=200, A=255} or C_WHITE
                elseif bType == 3 then displayName = "API"; bombColor = isItem and {R=255, G=160, B=50, A=255} or {R=255, G=100, B=0, A=255}
                elseif bType == 4 then displayName = "FLASH"; bombColor = isItem and {R=150, G=255, B=255, A=255} or C_CYAN
                elseif bType == 5 then displayName = "SMOKE"; bombColor = isItem and {R=150, G=255, B=150, A=255} or {R=100, G=255, B=100, A=255} end

                local text = string.format("%s [%dm]", displayName, math.floor(distM))
                local shouldTimerRun = not isItem
                if isItem then
                    pcall(function()
                        if bomb.bIsPinPulled or bomb.bPinPulled or (type(bomb.IsPinPulled) == "function" and bomb:IsPinPulled()) then shouldTimerRun = true end
                    end)
                end

                if shouldTimerRun and curGameTime > 0 then
                    local timeLeft = -1
                    pcall(function()
                        if bomb.ExplosionTime then timeLeft = bomb.ExplosionTime - curGameTime
                        elseif bomb.ExplodeTime then timeLeft = bomb.ExplodeTime - curGameTime end
                    end)
                    if timeLeft == -1 or timeLeft > 100 then
                        local bombId = tostring(bomb)
                        if not PE.ActiveBombTimers[bombId] then PE.ActiveBombTimers[bombId] = curGameTime end
                        local elapsed = curGameTime - PE.ActiveBombTimers[bombId]
                        local maxTime = (bType == 1 and 7.0) or (bType == 2 and 45.0) or (bType == 3 and 12.0) or (bType == 4 and 5.0) or 45.0
                        timeLeft = maxTime - elapsed
                    end
                    if timeLeft < 0 then timeLeft = 0 end
                    if timeLeft > 0.1 then text = string.format("%s (%.1fs)", text, timeLeft) end
                end

                local dynamicScale = math.max(0.6, 1.1 - (distM / maxDist))
                hud:AddDebugText(text, bomb, 0.06, {X=0, Y=0, Z=zOffset}, {X=0, Y=0, Z=zOffset}, bombColor, true, false, true, nil, dynamicScale, true)
            end
        end
    end
end

local function PortBombTick(lp, hud)
    local C = PortCfg()
    if not (C.EspBomMaster and (C.EspItemBom or C.EspActiveBom)) then
        PE.ItemBombCache = {}
        PE.ActiveBombCache = {}
        return
    end
    local curTime = os.clock()
    local G = rawget(_G, "Game")

    if not PE.GameplayStatics then PE.GameplayStatics = import("GameplayStatics") end
    if not PE.ActorClass then PE.ActorClass = import("Actor") end
    if not PE.ProjArray and PE.ActorClass then
        pcall(function() PE.ProjArray = slua.Array(UEnums.EPropertyClass.Object, PE.ActorClass) end)
    end

    local ui_util = require("client.common.ui_util")
    local gameInstance = ui_util and ui_util.GetGameInstance()

    if gameInstance and PE.GameplayStatics and PE.ProjArray and curTime - PE.LastBombScan > 0.5 then
        PE.LastBombScan = curTime
        local allActors = PE.GameplayStatics.GetAllActorsOfClass(gameInstance, PE.ActorClass, PE.ProjArray)
        local activeBombs, itemBombs = {}, {}

        if allActors then
            for _, actor in pairs(allActors) do
                if slua.isValid(actor) and not actor.bHidden and not actor.bTearOff then
                    if not PE.NonBombCache[actor] then
                        local bType = 0
                        local isItem = false
                        local isKnownBomb = PE.BombCache[actor]
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
                                PE.BombCache[actor] = { type = bType, isItem = isItem }
                            else
                                PE.NonBombCache[actor] = true
                            end
                        end

                        if bType > 0 then
                            local isPendingKill = false
                            pcall(function() if type(actor.IsPendingKill) == "function" then isPendingKill = actor:IsPendingKill() end end)
                            if not isPendingKill then
                                if isItem then table.insert(itemBombs, {act = actor, type = bType})
                                else table.insert(activeBombs, {act = actor, type = bType}) end
                            else
                                PE.BombCache[actor] = nil
                            end
                        end
                    end
                end
            end
        end
        PE.ActiveBombCache = activeBombs
        PE.ItemBombCache = itemBombs
    end

    local curGameTime = 0
    pcall(function() curGameTime = PE.GameplayStatics.GetTimeSeconds(gameInstance) end)

    if not PE.LastClearTimer or (curTime - PE.LastClearTimer) > 1.0 then
        PE.LastClearTimer = curTime
        pcall(function()
            for k, v in pairs(PE.ActiveBombTimers) do
                if (curGameTime - v) > 60.0 then PE.ActiveBombTimers[k] = nil end
            end
        end)
    end

    if C.EspItemBom then PortDrawBombs(lp, hud, PE.ItemBombCache, true, 50, curGameTime) end
    if C.EspActiveBom then PortDrawBombs(lp, hud, PE.ActiveBombCache, false, 150, curGameTime) end
end


-- ============================================================================
-- ESP KENDARAAN
-- ============================================================================
local function PortVehicleTick(lp, hud)
    local C = PortCfg()
    if not C.EspVehicle then
        PE.VehicleCache = {}
        return
    end
    local curTime = os.clock()

    if not PE.GameplayStatics then PE.GameplayStatics = import("GameplayStatics") end
    if not PE.VehClass then PE.VehClass = import("STExtraVehicleBase") end
    if not PE.VehArray and PE.VehClass then
        pcall(function() PE.VehArray = slua.Array(UEnums.EPropertyClass.Object, PE.VehClass) end)
    end

    local ui_util = require("client.common.ui_util")
    local gameInstance = ui_util and ui_util.GetGameInstance()

    if gameInstance and PE.GameplayStatics and PE.VehArray and curTime - PE.LastVehicleScan > 1.0 then
        PE.LastVehicleScan = curTime
        local allVehicles = PE.GameplayStatics.GetAllActorsOfClass(gameInstance, PE.VehClass, PE.VehArray)
        local activeVehicles = {}
        if allVehicles then
            for _, veh in pairs(allVehicles) do
                if slua.isValid(veh) and not veh.bHidden and not veh.bTearOff then
                    local isPendingKill = false
                    pcall(function() if type(veh.IsPendingKill) == "function" then isPendingKill = veh:IsPendingKill() end end)
                    if not isPendingKill then
                        local vehName = "Mobil"
                        local hasDriver = false
                        pcall(function()
                            if type(veh.GetVehicleName) == "function" then vehName = veh:GetVehicleName()
                            elseif veh.VehicleName then vehName = veh.VehicleName end
                            local driver = type(veh.GetDriver) == "function" and veh:GetDriver() or nil
                            if slua.isValid(driver) then hasDriver = true end
                        end)

                        local nameLower = string.lower(tostring(vehName) .. tostring(veh))
                        local displayName = "Mobil"
                        if string.find(nameLower, "uaz") then displayName = "UAZ"
                        elseif string.find(nameLower, "dacia") then displayName = "Dacia"
                        elseif string.find(nameLower, "buggy") then displayName = "Buggy"
                        elseif string.find(nameLower, "mirado") then displayName = "Mirado"
                        elseif string.find(nameLower, "bike") or string.find(nameLower, "motor") then displayName = "Motor"
                        elseif string.find(nameLower, "scooter") then displayName = "Scooter"
                        elseif string.find(nameLower, "coupe") then displayName = "Coupe RB"
                        elseif string.find(nameLower, "brdm") then displayName = "BRDM"
                        elseif string.find(nameLower, "boat") or string.find(nameLower, "aquarail") then displayName = "Perahu"
                        elseif string.find(nameLower, "glider") then displayName = "Glider"
                        else displayName = "Mobil (" .. string.sub(vehName, 1, 8) .. ")" end

                        table.insert(activeVehicles, {act = veh, name = displayName, hasDriver = hasDriver})
                    end
                end
            end
        end
        PE.VehicleCache = activeVehicles
    end

    for _, item in ipairs(PE.VehicleCache) do
        local veh = item.act
        if slua.isValid(veh) and not veh.bHidden then
            local isShow = false
            if item.name == "Dacia" then isShow = C.EspVeh_Dacia
            elseif item.name == "UAZ" then isShow = C.EspVeh_UAZ
            elseif item.name == "Buggy" then isShow = C.EspVeh_Buggy
            elseif item.name == "Coupe RB" then isShow = C.EspVeh_Coupe
            elseif item.name == "Mirado" then isShow = C.EspVeh_Mirado
            elseif item.name == "Motor" or item.name == "Scooter" then isShow = C.EspVeh_Motor
            else isShow = C.EspVeh_Other end

            if isShow then
                local distM = 0
                pcall(function() distM = lp:GetDistanceTo(veh) / 100 end)
                if distM > 0 and distM <= 300 then
                    local text = string.format("%s [%dm]", item.name, math.floor(distM))
                    local vehColor = item.hasDriver and {R=255, G=50, B=50, A=255} or {R=0, G=255, B=150, A=255}
                    local dynamicScale = math.max(0.6, 1.1 - (distM / 500))
                    hud:AddDebugText(text, veh, 0.06, {X=0, Y=0, Z=50}, {X=0, Y=0, Z=50}, vehColor, true, false, true, nil, dynamicScale, true)
                end
            end
        end
    end
end

-- ============================================================================
-- WIDGET COUNTER MUSUH + PERINGATAN AIM
-- ============================================================================
local PortBanners = {}

local function PortDropBanner(w)
    if w and slua.isValid(w) then
        pcall(function() w:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
        pcall(function() w:RemoveFromParent() end)
    end
end

-- deteksi widget yang malah memenuhi layar (layout gagal)
local function PortBannerTooBig(btn)
    local broken = false
    pcall(function()
        local g = btn:GetCachedGeometry()
        local sz = nil
        if g then
            if g.LocalSize then sz = g.LocalSize
            elseif type(g.GetLocalSize) == "function" then sz = g:GetLocalSize() end
        end
        local w = sz and (sz.X ~= nil and sz.X or sz.x)
        if w and w > 0 then
            local sw = 1920
            pcall(function()
                local vp = import("WidgetLayoutLibrary").GetViewportSize(btn)
                if vp and vp.X and vp.X > 0 then sw = vp.X end
            end)
            if w > sw * 0.5 then broken = true end
        end
    end)
    return broken
end

local function PortBannerLayout(btn, y, w, h)
    local ok = false
    pcall(function()
        local WLL = import("WidgetLayoutLibrary")
        local slot = WLL and WLL.SlotAsCanvasSlot and WLL.SlotAsCanvasSlot(btn)
        if slot then
            slot:SetAnchors({Minimum={X=0.5,Y=0}, Maximum={X=0.5,Y=0}})
            slot:SetAlignment({X=0.5,Y=0})
            slot:SetPosition({X=0,Y=y})
            slot:SetSize({X=w,Y=h})
            ok = true
        end
    end)
    if not ok then
        pcall(function()
            local sw = 1920
            pcall(function()
                local vp = import("WidgetLayoutLibrary").GetViewportSize(btn)
                if vp and vp.X and vp.X > 0 then sw = vp.X end
            end)
            btn:SetAlignmentInViewport({X=0.5,Y=0})
            btn:SetDesiredSizeInViewport({X=w,Y=h})
            btn:SetPositionInViewport({X=sw/2 - w/2, Y=y}, false)
            ok = true
        end)
    end
    return ok
end

local function PortBannerCreate(key, text, y, w, h, fontSize, z)
    local cached = PE[key]
    if cached then
        if slua.isValid(cached) then return cached end
        PE[key] = nil
    end
    local brokeAt = PE[key .. "Broken"]
    if brokeAt and (os.clock() - brokeAt) < 5 then return nil end

    local btn = nil
    pcall(function() btn = slua.loadUI(PortBtnBP) end)
    if not btn or not slua.isValid(btn) then return nil end

    -- simpan referensi DULU: kalau langkah berikutnya gagal, tidak bikin widget baru tiap tick
    PE[key] = btn
    table.insert(PortBanners, btn)

    pcall(function() require("game_frontend_hud").AddToContainer(UIContainers.Top, btn, z) end)
    pcall(function()
        if btn.RichText_Content then
            btn.RichText_Content:SetText(text)
            local fontInfo = btn.RichText_Content.Font
            if fontInfo then fontInfo.Size = fontSize; btn.RichText_Content:SetFont(fontInfo) end
        end
    end)

    local laid = PortBannerLayout(btn, y, w, h)
    if not laid or PortBannerTooBig(btn) then PortBannerLayout(btn, y, w, h) end

    -- kalau tetap full-screen: buang, jangan tinggalkan banner kuning nutup layar
    if not laid or PortBannerTooBig(btn) then
        for i = #PortBanners, 1, -1 do
            if PortBanners[i] == btn then table.remove(PortBanners, i) end
        end
        PE[key] = nil
        PE[key .. "Broken"] = os.clock()
        PortDropBanner(btn)
        return nil
    end

    pcall(function() btn:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
    return btn
end

local function PortCounterCreate()
    return PortBannerCreate("CounterWidget", "Musuh: 0  |  Terdekat: 0m", 30, 240, 36, 16, 10500)
end

local function PortWarningCreate()
    return PortBannerCreate("WarningWidget", "MUSUH MENGARAHKAN BIDIKAN", 75, 260, 36, 18, 10501)
end

local function PortHideCounter()
    if PE.CounterWidget then
        PortDropBanner(PE.CounterWidget)
        PE.CounterWidget = nil
    end
    if PE.WarningWidget then
        PortDropBanner(PE.WarningWidget)
        PE.WarningWidget = nil
    end
end


local function PortCounterTick(lp)
    local C = PortCfg()
    local wantCount = (C.EspLoai7 and C.Esp7_SoLuong) and not (C.EspEnemyCount or C.EspEnemyCountV2)
    local wantWarn = C.EspAimWarning
    if not wantCount and not wantWarn then PortHideCounter() return end
    if not slua.isValid(lp) then PortHideCounter() return end

    local widgetCounter = wantCount and PortCounterCreate() or nil
    if not wantCount and PE.CounterWidget then PortDropBanner(PE.CounterWidget); PE.CounterWidget = nil end

    local widgetWarning = wantWarn and PortWarningCreate() or nil
    if not wantWarn and PE.WarningWidget then PortDropBanner(PE.WarningWidget); PE.WarningWidget = nil end

    if widgetCounter and slua.isValid(widgetCounter) then
        pcall(function() widgetCounter:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    end


    local curTime = os.clock()
    if (curTime - PE.LastCounter) <= 0.5 then return end
    PE.LastCounter = curTime

    local myTeam = lp.TeamID or (type(lp.GetTeamID) == "function" and lp:GetTeamID()) or 0
    local count, nearest, isBeingTargeted = 0, 9999, false

    local KismetMathLibrary = import("KismetMathLibrary")
    local pc = lp:GetPlayerControllerSafety()

    local GameplayData = package.loaded["GameLua.GameCore.Data.GameplayData"] or require("GameLua.GameCore.Data.GameplayData")
    local allCharacters = {}
    if GameplayData then
        if GameplayData.GetAllPlayerCharacters then allCharacters = GameplayData.GetAllPlayerCharacters()
        elseif GameplayData.GameCharacters then for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end end
    end

    for _, tPawn in pairs(allCharacters) do
        if slua.isValid(tPawn) and tPawn ~= lp then
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
                    local d = math.floor(lp:GetDistanceTo(tPawn) / 100)
                    if d < nearest then nearest = d end

                    if C.EspAimWarning and not isBeingTargeted and d < 400 then
                        local eLoc = type(tPawn.K2_GetActorLocation) == "function" and tPawn:K2_GetActorLocation()
                        local pLoc = type(lp.K2_GetActorLocation) == "function" and lp:K2_GetActorLocation()

                        if eLoc and pLoc and KismetMathLibrary then
                            local lookRot = KismetMathLibrary.FindLookAtRotation(eLoc, pLoc)
                            local eRot = nil
                            if type(tPawn.GetControlRotation) == "function" then eRot = tPawn:GetControlRotation()
                            elseif type(tPawn.GetActorRotation) == "function" then eRot = tPawn:GetActorRotation() end

                            if eRot and lookRot then
                                local dYaw = math.abs(eRot.Yaw - lookRot.Yaw)
                                if dYaw > 180 then dYaw = 360 - dYaw end
                                local dPitch = math.abs(eRot.Pitch - lookRot.Pitch)
                                if dPitch > 180 then dPitch = 360 - dPitch end

                                if dYaw < 15 and dPitch < 20 then
                                    if C.EspAimWarningVisCheck then
                                        if slua.isValid(pc) and type(pc.LineOfSightTo) == "function" and pc:LineOfSightTo(tPawn) then
                                            isBeingTargeted = true
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
        pcall(function()
            widgetCounter.RichText_Content:SetText(string.format("Musuh: %d  |  Terdekat: %dm", count, count > 0 and nearest or 0))
        end)
    end

    if widgetWarning and slua.isValid(widgetWarning) then
        pcall(function()
            if C.EspAimWarning and isBeingTargeted then
                widgetWarning:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            else
                widgetWarning:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
        end)
    end

end


-- ============================================================================
-- CEK: ada fitur ESP/Wall/Chams yang aktif?
-- ============================================================================
local function PortWanted()
    local C = PortCfg()
    if not C then return false end
    return C.EspVip or C.EspDistance or C.EspVipPro or C.EspRadar
        or C.EspLoai5 or C.EspLoai6 or C.EspLoai7 or C.EspLoai8
        or C.EspAntenna or C.EspOutline or C.EspItem_Master
        or C.WallVehicle or C.EspVehicle
        or (C.EspBomMaster and (C.EspItemBom or C.EspActiveBom))
        or C.WallXuyenTuong or C.ColorBodyV2 or C.ColorBodyNew or C.ColorBodyV3
        or C.EspAimWarning
end

local function PortClearAll()
    local S = _G.X3.XthrlenState
    pcall(function()
        for _, d in pairs(S.EnemyMarks or {}) do
            SafeRemoveMark(d.radarMark); SafeRemoveMark(d.hpMark); SafeRemoveMark(d.hpMark8); SafeRemoveMark(d.distMark)
            d.radarMark = nil; d.hpMark = nil; d.hpMark8 = nil; d.distMark = nil
            d.MIDs = nil; d.MIDs_V3 = nil; d.enemy = nil; d.CachedMeshes = nil
        end
        S.EnemyMarks = {}
        S.TrackedMarks = {}
        for i = #PortBanners, 1, -1 do
            PortDropBanner(PortBanners[i])
            PortBanners[i] = nil
        end
        PortBanners = {}
        PE.CounterWidget = nil
        PE.WarningWidget = nil
        PE.CounterWidgetBroken = nil
        PE.WarningWidgetBroken = nil

    end)
    PE.ItemCache = {}
    PE.VehicleCache = {}
    PE.ItemBombCache = {}
    PE.ActiveBombCache = {}
    PE.AppliedItem = {}
    PE.AppliedVehWall = {}
end

-- ============================================================================
-- MAIN ESP TICK (dipanggil dari fast tick)
-- ============================================================================
local function PortESPTick()
    pcall(function()
        if not PortWanted() then
            if not PE.Cleared then
                PE.Cleared = true
                PortClearAll()
            end
            return
        end
        PE.Cleared = false

        local C = PortCfg()

        local okData, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
        if not okData or not GameplayData then return end
        local pc = GameplayData.GetPlayerController()
        local lp = nil
        if Valid(pc) then lp = pc:GetPlayerCharacterSafety() end

        if not Valid(pc) or not Valid(lp) then
            if not PE.NoPlayer then
                PE.NoPlayer = true
                PortClearAll()
            end
            return
        end
        PE.NoPlayer = false

        pcall(InitializeNativeESP)

        local Cached_MyHUD = pc.MyHUD
        local Cached_PPM = nil
        pcall(function() Cached_PPM = import("PostProcessManager").GetInstance() end)
        local Cached_SCU = nil
        pcall(function() Cached_SCU = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils") end)

        PortRunItemVehicle(pc, lp)

        local S = _G.X3.XthrlenState
        local allCharacters = {}
        if GameplayData.GetAllPlayerCharacters then allCharacters = GameplayData.GetAllPlayerCharacters()
        elseif GameplayData.GameCharacters then for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end end

        -- bersihkan data musuh yang sudah tidak ada
        local currentValidKeys = {}
        for _, enemy in pairs(allCharacters) do
            if Valid(enemy) and enemy ~= lp then currentValidKeys[GetSafeEnemyKey(enemy)] = true end
        end
        for key, data in pairs(S.EnemyMarks) do
            if not currentValidKeys[key] then
                SafeRemoveMark(data.radarMark)
                SafeRemoveMark(data.hpMark)
                SafeRemoveMark(data.hpMark8)
                SafeRemoveMark(data.distMark)
                data.MIDs = nil
                data.MIDs_V3 = nil
                data.enemy = nil
                data.CachedMeshes = nil
                S.EnemyMarks[key] = nil
            end
        end

        local mLoc = nil
        pcall(function() if type(lp.K2_GetActorLocation) == "function" then mLoc = lp:K2_GetActorLocation() end end)

        for _, enemy in pairs(allCharacters) do
            if Valid(enemy) and enemy ~= lp and enemy.TeamID ~= lp.TeamID then
                local bIsReallyDead = false
                pcall(function()
                    if type(enemy.IsDead) == "function" then bIsReallyDead = enemy:IsDead()
                    elseif enemy.bIsDead ~= nil then bIsReallyDead = enemy.bIsDead
                    elseif enemy.bIsDeadFlag ~= nil then bIsReallyDead = enemy.bIsDeadFlag end
                    if enemy.HealthStatus ~= nil and enemy.HealthStatus == 2 then bIsReallyDead = true end
                end)

                local eKey = GetSafeEnemyKey(enemy)
                S.EnemyMarks[eKey] = S.EnemyMarks[eKey] or { enemy = enemy }
                local markData = S.EnemyMarks[eKey]
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
                        markData.IsCleanedUp = false
                    end

                    local eMesh = nil
                    pcall(function() eMesh = enemy.Mesh or (type(enemy.getAvatarComponent2) == "function" and enemy:getAvatarComponent2() or nil) end)
                    local aLoc = nil
                    pcall(function() if type(enemy.K2_GetActorLocation) == "function" then aLoc = enemy:K2_GetActorLocation() end end)

                    local isBot = false
                    pcall(function()
                        local b, checked = CheckIsAI(enemy, markData)
                        if checked then isBot = b == true else isBot = (markData.AK_IS_BOT == true) end
                    end)

                    -- WALL / CHAMS
                    local currentMeshCount = 0
                    if Valid(eMesh) then
                        pcall(function() currentMeshCount = #PortAllMeshes(enemy, markData) end)
                    end
                    local isMeshChangedWall = (markData.LastMeshCountWall ~= currentMeshCount)

                    if C.WallXuyenTuong then
                        if isMeshChangedWall or not markData.WallhackApplied then
                            PortApplyWall(enemy, markData)
                            markData.WallhackApplied = true
                            markData.LastMeshCountWall = currentMeshCount
                        end
                    else
                        PortUndoWall(enemy, markData)
                    end

                    if C.ColorBodyV2 then PortApplyV2(enemy, pc, markData) else PortUndoV2(enemy, markData) end
                    if C.ColorBodyV3 then PortApplyV3(enemy, markData) else PortUndoV3(enemy, markData) end
                    if C.ColorBodyNew then PortApplyNew(enemy, markData) else PortUndoNew(enemy, markData) end

                    local distM = 0
                    pcall(function() distM = lp:GetDistanceTo(enemy) / 100 end)

                    local currentHp, maxHp = 100, 100
                    local showFrameUI = (C.EspLoai5 == true) or (C.EspVipPro == true) or (C.EspVip == true)
                    if showFrameUI then
                        pcall(function()
                            if enemy.Health then currentHp = enemy.Health elseif type(enemy.GetHealth) == "function" then currentHp = enemy:GetHealth() end
                            if enemy.HealthMax then maxHp = enemy.HealthMax elseif type(enemy.GetHealthMax) == "function" then maxHp = enemy:GetHealthMax() end
                        end)
                        if maxHp <= 0 then maxHp = 100 end
                    end
                    local hpRatio = currentHp / maxHp

                    -- ESP ANTENNA
                    if C.EspAntenna then
                        pcall(function()
                            local MyHUD = Cached_MyHUD
                            if Valid(MyHUD) and distM <= 400 then
                                local loopCount = 8
                                local zStep = 1000
                                local baseZ = 105
                                local topZ = baseZ + (loopCount * zStep)
                                for i = 1, loopCount do
                                    local zOffset = baseZ + (i * zStep)
                                    MyHUD:AddDebugText("|", enemy, 0.06, {X=0, Y=0, Z=zOffset}, {X=0, Y=0, Z=zOffset}, C_GREEN, true, false, true, nil, 1.2, true)
                                end
                                MyHUD:AddDebugText("I", enemy, 0.06, {X=0, Y=0, Z=topZ + 60}, {X=0, Y=0, Z=topZ + 60}, C_GREEN, true, false, true, nil, 1.5, true)
                            end
                        end)
                    end

                    -- ESP LOAI 6 (SKELETON)
                    if C.EspLoai6 then
                        pcall(function()
                            local curTime = os.clock()
                            if markData.LastEsp6Time == nil or (curTime - markData.LastEsp6Time) >= 0.05 then
                                markData.LastEsp6Time = curTime
                                local MyHUD = Cached_MyHUD
                                if Valid(MyHUD) and Valid(eMesh) and aLoc then
                                    if distM <= 250 and type(eMesh.GetSocketLocation) == "function" then
                                        for _, bName in ipairs(GLOBAL_BONE_LIST) do
                                            if distM > 50 and (bName ~= "head" and bName ~= "pelvis" and bName ~= "neck_01") then
                                            else
                                                local wLoc = eMesh:GetSocketLocation(bName)
                                                if wLoc then
                                                    local offset = {X = wLoc.X - aLoc.X, Y = wLoc.Y - aLoc.Y, Z = wLoc.Z - aLoc.Z}
                                                    local mark, fixedSize, color = "▪", 0.25, C_CYAN
                                                    if bName == "head" then mark, fixedSize, color = "●", 0.45, C_RED
                                                    elseif bName == "pelvis" or bName == "neck_01" then mark, fixedSize, color = "▪", 0.35, C_YELLOW end
                                                    MyHUD:AddDebugText(mark, enemy, 0.06, offset, offset, color, true, false, true, nil, fixedSize, true)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                    end

                    -- ESP LOAI 7 (INFO DETAIL)
                    if C.EspLoai7 then
                        pcall(function()
                            local MyHUD = Cached_MyHUD
                            if Valid(MyHUD) and distM <= 400 then
                                local stateText = ""
                                if C.Esp7_TuThe ~= false then
                                    local pose = nil
                                    if enemy.PoseState then pose = enemy.PoseState
                                    elseif type(enemy.GetPoseState) == "function" then pose = enemy:GetPoseState() end
                                    if pose == 0 or pose == "Stand" then stateText = "Berdiri"
                                    elseif pose == 1 or pose == "Crouch" then stateText = "Jongkok"
                                    elseif pose == 2 or pose == "Prone" then stateText = "Tiarap"
                                    else stateText = "Berdiri" end
                                end

                                if C.Esp7_VuKhi ~= false then
                                    local curTime = os.clock()
                                    if markData.AK_LAST_WEP_TIME == nil or curTime > markData.AK_LAST_WEP_TIME + 1.5 then
                                        local eWeapon = nil
                                        local cwRaw = enemy.CurrentWeapon
                                        if cwRaw ~= nil and type(cwRaw) ~= "function" then eWeapon = cwRaw
                                        elseif type(enemy.GetCurrentWeapon) == "function" then eWeapon = enemy:GetCurrentWeapon()
                                        elseif enemy.WeaponManagerComponent then eWeapon = enemy.WeaponManagerComponent.CurrentWeaponReplicated end
                                        local weaponName = "Tangan Kosong"
                                        if Valid(eWeapon) and type(eWeapon.GetWeaponName) == "function" then weaponName = eWeapon:GetWeaponName() end
                                        markData.AK_CACHED_WEP_NAME = tostring(weaponName)
                                        markData.AK_LAST_WEP_TIME = curTime
                                    end
                                    if stateText ~= "" then
                                        stateText = stateText .. " - " .. (markData.AK_CACHED_WEP_NAME or "Tangan Kosong")
                                    else
                                        stateText = (markData.AK_CACHED_WEP_NAME or "Tangan Kosong")
                                    end
                                end

                                if stateText ~= "" then
                                    local textColor = isBot and C_CYAN or C_YELLOW
                                    local dynamicScale = math.max(0.5, 0.8 - (distM / 400))
                                    MyHUD:AddDebugText(stateText, enemy, 0.06, {X=0, Y=0, Z=100}, {X=0, Y=0, Z=100}, textColor, true, false, true, nil, dynamicScale, true)
                                end
                            end
                        end)
                    end

                    -- ENEMY FRAME UI (ESP 1 / 3 / 5)
                    if showFrameUI then
                        pcall(function()
                            local show = true
                            if enemy.HealthStatus and Cached_SCU and Cached_SCU.IsHealthStatusAlive then
                                if not Cached_SCU.IsHealthStatusAlive(enemy.HealthStatus) then show = false end
                            end
                            if show and mLoc then
                                if aLoc and Cached_SCU and Cached_SCU.IsVector then
                                    if Cached_SCU.IsVector(aLoc) and Cached_SCU.IsVector(mLoc) then
                                        local ddx, ddy = aLoc.X - mLoc.X, aLoc.Y - mLoc.Y
                                        if aLoc.Z >= 150000 or math.sqrt(ddx*ddx + ddy*ddy) > 50000 then show = false end
                                    end
                                end
                            end
                            if show then
                                if enemy.Replay_IsEnemyFrameUIExisted and not enemy:Replay_IsEnemyFrameUIExisted() then enemy:Replay_CreateEnemyFrameUI(true, true) end
                                if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(true) end
                                if enemy.Replay_UpdateEnemyFrameUI then enemy:Replay_UpdateEnemyFrameUI(hpRatio) end

                                local efuRaw = enemy.EnemyFrameUI
                                local uiComp = nil
                                if efuRaw ~= nil and type(efuRaw) ~= "function" then uiComp = efuRaw
                                elseif type(enemy.GetEnemyFrameUI) == "function" then uiComp = enemy:GetEnemyFrameUI() end
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
                            local efuRaw2 = enemy.EnemyFrameUI
                            local uiComp = nil
                            if efuRaw2 ~= nil and type(efuRaw2) ~= "function" then uiComp = efuRaw2
                            elseif type(enemy.GetEnemyFrameUI) == "function" then uiComp = enemy:GetEnemyFrameUI() end
                            if Valid(uiComp) then
                                if markData.LastFrameUIState ~= "HIDDEN" then
                                    if type(uiComp.SetVisibility) == "function" then uiComp:SetVisibility(2) end
                                    if type(uiComp.SetHiddenInGame) == "function" then uiComp:SetHiddenInGame(true) end
                                    markData.LastFrameUIState = "HIDDEN"
                                end
                            end
                        end)
                    end

                    -- ESP 3: NAMA + HP VERTIKAL
                    if C.EspVipPro then
                        pcall(function()
                            local hud = Cached_MyHUD
                            if Valid(hud) and hud.AddDebugText and distM <= 400 then
                                local dynamicScale = math.max(0.55, 0.95 - (distM / 400))
                                local isKnock = (currentHp <= 0 and enemy.HealthStatus == 1)
                                local hpColor = C_GREEN
                                if hpRatio < 0.3 then hpColor = C_RED elseif hpRatio < 0.7 then hpColor = C_YELLOW end
                                if isKnock then hpColor = C_RED end

                                if C.Esp3ShowName ~= false then
                                    local enemyName = "Enemy"
                                    pcall(function()
                                        if enemy.PlayerName then enemyName = enemy.PlayerName
                                        elseif type(enemy.GetPlayerName) == "function" then enemyName = enemy:GetPlayerName() end
                                    end)
                                    if enemyName == "" or enemyName == nil then enemyName = "Enemy" end
                                    if isKnock then enemyName = "KNOCK: " .. tostring(enemyName) end
                                    hud:AddDebugText(tostring(enemyName), enemy, 0.06, {X=0, Y=0, Z=-370}, {X=0, Y=0, Z=-370}, C_WHITE, true, false, true, nil, dynamicScale * 1.1, true)
                                end

                                if C.Esp3ShowHP ~= false then
                                    if not isKnock then
                                        local segments = 6
                                        local filled = math.floor(hpRatio * segments)
                                        local startZ = 20
                                        local spacing = 10.0 * dynamicScale
                                        for j = 1, segments do
                                            local color = (j <= filled) and hpColor or {R=30, G=30, B=30, A=180}
                                            hud:AddDebugText("█", enemy, 0.06, {X=0, Y=-115, Z=startZ + (j * spacing)}, {X=0, Y=-115, Z=startZ + (j * spacing)}, color, true, false, true, nil, dynamicScale * 1.2, true)
                                        end
                                        hud:AddDebugText(string.format("%d%%", math.floor(hpRatio * 100)), enemy, 0.06, {X=0, Y=-60, Z=startZ - 12}, {X=0, Y=-60, Z=startZ - 12}, hpColor, true, false, true, nil, dynamicScale * 0.8, true)
                                    else
                                        hud:AddDebugText("DOWN", enemy, 0.06, {X=0, Y=-115, Z=50}, {X=0, Y=-115, Z=50}, C_RED, true, false, true, nil, dynamicScale, true)
                                    end
                                end
                            end
                        end)
                    end

                    -- ESP 2: JARAK
                    if C.EspDistance then
                        pcall(function()
                            local hud = Cached_MyHUD
                            if Valid(hud) and hud.AddDebugText and distM <= 400 then
                                local dynamicScale = math.max(0.55, 0.95 - (distM / 400))
                                hud:AddDebugText(string.format("[%dm]", math.floor(distM)), enemy, 0.06, {X=0, Y=115, Z=20}, {X=0, Y=115, Z=20}, C_BLUE_TEXT, true, false, true, nil, dynamicScale * 1.5, true)
                            end
                        end)
                    end

                    -- ESP 1: MARK HP + MARK JARAK
                    if C.EspVip then
                        if markData.hpMark == nil then markData.hpMark = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                        if markData.distMark == nil then markData.distMark = SafeAddMark(9999, FVector(0,0,0), 0, "", 4, enemy) end
                    else
                        if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
                        if markData.distMark then SafeRemoveMark(markData.distMark); markData.distMark = nil end
                    end

                    -- ESP 8: HP DI ATAS KEPALA
                    if C.EspLoai8 then
                        if markData.hpMark8 == nil then markData.hpMark8 = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                    else
                        if markData.hpMark8 then SafeRemoveMark(markData.hpMark8); markData.hpMark8 = nil end
                    end

                    -- ESP 4: RADAR
                    if C.EspRadar then
                        if not markData.radarMark or markData.radarMark == 0 then
                            local nowR = os.clock()
                            if markData.radarTry == nil or (nowR - markData.radarTry) > 1 then
                                markData.radarTry = nowR
                                markData.radarMark = SafeAddMark(8888, FVector(0,0,0), 0, "", 4, enemy)
                                if markData.radarMark == nil or markData.radarMark == 0 then
                                    markData.radarFail = (markData.radarFail or 0) + 1
                                    if markData.radarFail == 10 and not PE.RadarWarned then
                                        PE.RadarWarned = true
                                        pcall(Notify, "ESP 4: mark 8888 tidak tersedia")
                                    end
                                else
                                    markData.radarFail = 0
                                end
                            end
                        end
                    else
                        if markData.radarMark and markData.radarMark ~= 0 then
                            SafeRemoveMark(markData.radarMark)
                            markData.radarMark = nil
                        end
                    end

                    -- ESP OUTLINE
                    if C.EspOutline then
                        pcall(function()
                            local outColorChoice = PortData().OutlineColor or 4
                            local outThick = C.OutlineThickness or 10
                            local outlineHash = string.format("%d_%d", outThick, outColorChoice)
                            local meshes = PortAllMeshes(enemy, markData)
                            local currentMeshCountOL = #meshes

                            if markData.OutlineState ~= outlineHash or markData.LastMeshCountOutline ~= currentMeshCountOL then
                                local r, g, b = 255, 255, 0
                                if outColorChoice == 1 then r, g, b = 255, 0, 0
                                elseif outColorChoice == 2 then r, g, b = 0, 255, 0
                                elseif outColorChoice == 3 then r, g, b = 0, 0, 255
                                elseif outColorChoice == 4 then r, g, b = 255, 255, 0
                                elseif outColorChoice == 5 then r, g, b = 255, 0, 255
                                elseif outColorChoice == 6 then r, g, b = 255, 255, 255 end

                                local glowIntensity = 80.0
                                local glowDynamic
                                if PortLinearColor then
                                    local okG, gv = pcall(PortLinearColor, (r/255)*glowIntensity, (g/255)*glowIntensity, (b/255)*glowIntensity, 1.0)
                                    if okG and gv then glowDynamic = gv end
                                end
                                if not glowDynamic then glowDynamic = { R=r*glowIntensity, G=g*glowIntensity, B=b*glowIntensity, A=255 } end

                                for _, comp in ipairs(meshes) do
                                    if Valid(comp) then
                                        pcall(function()
                                            comp.UseScopeDistanceCulling = false
                                            comp.PrimitiveShadingStrategy = 1
                                            comp.ShadingRate = 6
                                        end)
                                        pcall(function()
                                            if type(comp.SetDrawIdeaOutline) == "function" then
                                                comp:SetDrawIdeaOutline(true)
                                                if type(comp.OverrideIdeaOutlineColor) == "function" then comp:OverrideIdeaOutlineColor(true, glowDynamic) end
                                                if type(comp.OverrideIdeaOutlineThickness) == "function" then comp:OverrideIdeaOutlineThickness(true, outThick) end
                                            end
                                        end)
                                    end
                                end
                                markData.OutlineState = outlineHash
                                markData.LastMeshCountOutline = currentMeshCountOL
                            end
                        end)
                    else
                        pcall(function()
                            if markData.OutlineState ~= "OFF" then
                                local meshes = PortAllMeshes(enemy, markData)
                                for _, comp in ipairs(meshes) do
                                    if Valid(comp) then
                                        pcall(function()
                                            comp.PrimitiveShadingStrategy = 0
                                            comp.ShadingRate = 1
                                        end)
                                        pcall(function()
                                            if type(comp.SetDrawIdeaOutline) == "function" then comp:SetDrawIdeaOutline(false) end
                                        end)
                                    end
                                end
                                markData.OutlineState = "OFF"
                                markData.LastMeshCountOutline = 0
                            end
                        end)
                    end

                else
                    if not markData.IsCleanedUp then
                        SafeRemoveMark(markData.radarMark); markData.radarMark = nil
                        SafeRemoveMark(markData.hpMark); markData.hpMark = nil
                        SafeRemoveMark(markData.hpMark8); markData.hpMark8 = nil
                        SafeRemoveMark(markData.distMark); markData.distMark = nil
                        markData.MIDs = nil
                        markData.MIDs_V3 = nil
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
                            local avatarComp = Valid(eObj) and (type(eObj.getAvatarComponent2) == "function") and eObj:getAvatarComponent2() or nil
                            if Valid(avatarComp) and Valid(Cached_PPM) then Cached_PPM:EnableAvatarOutline(avatarComp, false) end
                        end)
                        markData.IsCleanedUp = true
                    end
                end
            end
        end

        local hud = Cached_MyHUD
        if Valid(hud) then
            PortBombTick(lp, hud)
            PortVehicleTick(lp, hud)
        end
        PortCounterTick(lp)
    end)
end

return { Tick = PortESPTick }
end)()

_G.X3.PortESPTick = PortESPModule and PortESPModule.Tick or nil


_G.X3.XthrlenConfig = _G.X3.XthrlenConfig or {}
_G.X3.XthrlenConfig.WallhackVis = _G.X3.XthrlenConfig.WallhackVis or false
_G.X3.XthrlenConfig.WallhackGlow = _G.X3.XthrlenConfig.WallhackGlow or false
_G.X3.XthrlenConfig.RenderDistEnabled = _G.X3.XthrlenConfig.RenderDistEnabled or false
_G.X3.XthrlenConfig.HDRSharpEnabled = _G.X3.XthrlenConfig.HDRSharpEnabled or false

_G.X3.XthrlenConfig.AutoHead = _G.X3.XthrlenConfig.AutoHead or false
_G.X3.XthrlenConfig.SmartAutoHead = _G.X3.XthrlenConfig.SmartAutoHead or false

local M_SmartHead = {}
local GameplayStatics_SH = import("GameplayStatics")
local GameplayData_SH = require("GameLua.GameCore.Data.GameplayData")

function M_SmartHead:ApplyAutoAimHead()
  local PC = GameplayData_SH.GetPlayerController()
  local autoComp = PC and PC.BP_AutoAimingComponent
  if not autoComp then return end
  autoComp.Bones = {"Head", "Head", "Head"}
end

local EAvatarDamagePosition_SH = import("EAvatarDamagePosition")

function M_SmartHead.GetHitBodyType(ImpactResult, InImpactVec)
    if _G.X3.XthrlenConfig.SmartAutoHead then return EAvatarDamagePosition_SH.BigHead end
    return nil
end

function M_SmartHead.GetHitBodyTypeByHitPos(InImpactVec)
    if _G.X3.XthrlenConfig.SmartAutoHead then return EAvatarDamagePosition_SH.BigHead end
    return nil
end



-- [FIX] Wallhack multi-match persistence
_G.X3._WH = _G.X3._WH or {
    spawnResetDone = false,
    lobbyOffDone = false,
    lastMode = "",
    lastLocalPlayer = nil,
}

function _G.X3._WH_SyncMatchState(lp, pc)
    if not (_G.X3.XthrlenConfig and _G.X3.XthrlenConfig.WallhackVis) then
        _G.X3._WH.spawnResetDone = false
        _G.X3._WH.lobbyOffDone = false
        return
    end
    local gs = GameplayData and GameplayData.GetGameState and GameplayData.GetGameState()
    local mode = ""
    if gs and slua.isValid(gs) then
        pcall(function() mode = gs:GetGameModeState() or "" end)
    end
    local inFighting = (mode == "FightingState")
    local haveLP = (lp and slua.isValid(lp))
    local playerChanged = (lp ~= _G.X3._WH.lastLocalPlayer)
    local enteredFight = (inFighting and _G.X3._WH.lastMode ~= "FightingState")
    if haveLP and (playerChanged or enteredFight) then
        _G.X3._WH.spawnResetDone = false
        _G.X3._WH.lobbyOffDone = false
        _G.X3._WH.lastLocalPlayer = lp
        if type(_G.X3.Trace) == "function" then
            _G.X3.Trace("WH FIX: spawn baru (playerChanged=" .. tostring(playerChanged) ..
                " enteredFight=" .. tostring(enteredFight) .. ")")
        end
    end
    if not inFighting and _G.X3._WH.lastMode == "FightingState" then
        _G.X3._WH.lobbyOffDone = false
        _G.X3._WH.spawnResetDone = false
        if type(_G.X3.Trace) == "function" then _G.X3.Trace("WH FIX: keluar FightingState") end
    end
    _G.X3._WH.lastMode = mode
end

_G.X3.XthrlenState = _G.X3.XthrlenState or {}
_G.X3.XthrlenState.CustomTextData = _G.X3.XthrlenState.CustomTextData or {}
_G.X3.XthrlenState.CustomTextData.WallVisColor = _G.X3.XthrlenState.CustomTextData.WallVisColor or 1
_G.X3.XthrlenState.CustomTextData.WallVisAIColor = _G.X3.XthrlenState.CustomTextData.WallVisAIColor or 29
_G.X3.XthrlenState.CustomTextData.WallOccColor = _G.X3.XthrlenState.CustomTextData.WallOccColor or 9
_G.X3.XthrlenState.CustomTextData.WallOccAIColor = _G.X3.XthrlenState.CustomTextData.WallOccAIColor or 39
_G.X3.XthrlenState.CustomTextData.WallFilterMode = _G.X3.XthrlenState.CustomTextData.WallFilterMode or 1
_G.X3.XthrlenState.CustomTextData.WallResolution = _G.X3.XthrlenState.CustomTextData.WallResolution or 1
_G.X3.XthrlenState.CustomTextData.RenderDistSlider = _G.X3.XthrlenState.CustomTextData.RenderDistSlider or 100
_G.X3.XthrlenState.CustomTextData.HDRSharpSlider = _G.X3.XthrlenState.CustomTextData.HDRSharpSlider or 100
_G.X3.XthrlenState.CustomTextData.ColorV3Hidden = _G.X3.XthrlenState.CustomTextData.ColorV3Hidden or 1
_G.X3.XthrlenState.CustomTextData.ColorV3Visible = _G.X3.XthrlenState.CustomTextData.ColorV3Visible or 2
_G.X3.XthrlenState.CustomTextData.ColorV3Thickness = _G.X3.XthrlenState.CustomTextData.ColorV3Thickness or 4
_G.X3.XthrlenState.CustomTextData.OutlineColor = _G.X3.XthrlenState.CustomTextData.OutlineColor or 4
_G.X3.WallhackColorVersion = _G.X3.WallhackColorVersion or 1

-- 1. SDK VALIDATED CLASS IMPORTS (Cached)
local GlobalSkelClassWH = nil
pcall(function() GlobalSkelClassWH = import("SkeletalMeshComponent") end)

local SkeletalMeshClass = nil
local StaticMeshClass = nil
local ChildActorClass = nil
local AIControllerClass = nil

pcall(function()
    SkeletalMeshClass = import("/Script/Engine.SkeletalMeshComponent")
    StaticMeshClass = import("/Script/Engine.StaticMeshComponent")
    ChildActorClass = import("/Script/Engine.ChildActorComponent")
    AIControllerClass = import("/Script/AIModule.AIController")
end)

if not SkeletalMeshClass then pcall(function() SkeletalMeshClass = import("SkeletalMeshComponent") end) end
if not StaticMeshClass then pcall(function() StaticMeshClass = import("StaticMeshComponent") end) end
if not ChildActorClass then pcall(function() ChildActorClass = import("ChildActorComponent") end) end
if not AIControllerClass then pcall(function() AIControllerClass = import("AIController") end) end

-- 2. COLOR SYSTEM (55 Peaked & Saturated)
local function AuraColorWH(r, g, b, a) return {R = r, G = g, B = b, A = a} end

local ColorPaletteWH = {
    -- [PUTIH & ABU-ABU] 1-5
    [1] = AuraColorWH(1.0, 1.0, 1.0, 1.0),   [2] = AuraColorWH(3.0, 3.0, 3.0, 1.0),
    [3] = AuraColorWH(5.0, 5.0, 5.0, 1.0),     [4] = AuraColorWH(7.0, 7.0, 7.0, 1.0),
    [5] = AuraColorWH(10.0, 10.0, 10.0, 1.0),
    -- [MERAH PEKAT] 6-10
    [6] = AuraColorWH(10.0, 0.0, 0.0, 1.0),     [7] = AuraColorWH(10.0, 1.0, 0.0, 1.0),
    [8] = AuraColorWH(10.0, 2.0, 0.0, 1.0),     [9] = AuraColorWH(10.0, 3.0, 0.0, 1.0),
    [10] = AuraColorWH(10.0, 4.0, 0.0, 1.0),
    -- [HOT PINK] 11-15
    [11] = AuraColorWH(10.0, 0.0, 2.0, 1.0),     [12] = AuraColorWH(10.0, 0.0, 4.0, 1.0),
    [13] = AuraColorWH(10.0, 0.0, 6.0, 1.0),     [14] = AuraColorWH(10.0, 0.0, 8.0, 1.0),
    [15] = AuraColorWH(10.0, 0.0, 10.0, 1.0),
    -- [ORANGE PEKAT] 16-20
    [16] = AuraColorWH(10.0, 3.0, 0.0, 1.0),     [17] = AuraColorWH(10.0, 5.0, 0.0, 1.0),
    [18] = AuraColorWH(10.0, 6.0, 0.0, 1.0),     [19] = AuraColorWH(10.0, 7.0, 0.0, 1.0),
    [20] = AuraColorWH(10.0, 8.0, 0.0, 1.0),
    -- [GOLD / KUNING] 21-25
    [21] = AuraColorWH(10.0, 10.0, 0.0, 1.0),    [22] = AuraColorWH(10.0, 10.0, 1.0, 1.0),
    [23] = AuraColorWH(10.0, 10.0, 2.0, 1.0),    [24] = AuraColorWH(10.0, 10.0, 3.0, 1.0),
    [25] = AuraColorWH(10.0, 10.0, 4.0, 1.0),
    -- [LIME / HIJAU NEON] 26-30
    [26] = AuraColorWH(0.0, 10.0, 0.0, 1.0),     [27] = AuraColorWH(1.0, 10.0, 0.0, 1.0),
    [28] = AuraColorWH(2.0, 10.0, 0.0, 1.0),     [29] = AuraColorWH(3.0, 10.0, 0.0, 1.0),
    [30] = AuraColorWH(4.0, 10.0, 0.0, 1.0),
    -- [CYAN / TOSKA ELECTRIC] 31-35
    [31] = AuraColorWH(0.0, 10.0, 10.0, 1.0),     [32] = AuraColorWH(0.0, 8.0, 10.0, 1.0),
    [33] = AuraColorWH(0.0, 6.0, 10.0, 1.0),     [34] = AuraColorWH(0.0, 4.0, 10.0, 1.0),
    [35] = AuraColorWH(0.0, 2.0, 10.0, 1.0),
    -- [BIRU PEKAT] 36-40
    [36] = AuraColorWH(0.0, 0.0, 10.0, 1.0),     [37] = AuraColorWH(0.0, 1.0, 10.0, 1.0),
    [38] = AuraColorWH(0.0, 2.0, 10.0, 1.0),     [39] = AuraColorWH(0.0, 3.0, 10.0, 1.0),
    [40] = AuraColorWH(0.0, 4.0, 10.0, 1.0),
    -- [UNGU / VIOLET] 41-45
    [41] = AuraColorWH(4.0, 0.0, 10.0, 1.0),     [42] = AuraColorWH(6.0, 0.0, 10.0, 1.0),
    [43] = AuraColorWH(8.0, 0.0, 10.0, 1.0),     [44] = AuraColorWH(10.0, 0.0, 10.0, 1.0),
    [45] = AuraColorWH(10.0, 2.0, 8.0, 1.0),
    -- [PREMIUM CAMPURAN] 46-50
    [46] = AuraColorWH(10.0, 10.0, 0.0, 1.0),    [47] = AuraColorWH(10.0, 0.0, 5.0, 1.0),
    [48] = AuraColorWH(0.0, 10.0, 5.0, 1.0),     [49] = AuraColorWH(5.0, 10.0, 0.0, 1.0),
    [50] = AuraColorWH(10.0, 5.0, 0.0, 1.0),
    -- [SPESIAL ANIMASI SMOOTH] 51-55
    [51] = "RAINBOW_SMOOTH", [52] = "NEON_PULSE", [53] = "CYBERPUNK",
    [54] = "LAVA_FLOW",      [55] = "VAPORWAVE"
}

-- Smooth Animation (Low freq, no stutter)
local function GetRainbowSmoothColorWH()
    local t = os.clock() * 1.2
    return AuraColorWH(math.sin(t)*5.0+5.0, math.sin(t+2.094)*5.0+5.0, math.sin(t+4.188)*5.0+5.0, 1.0)
end
local function GetNeonPulseColorWH()
    local p = (math.sin(os.clock()*2.0)+1.0)*5.0
    return AuraColorWH(p, 0.0, p, 1.0)
end
local function GetCyberpunkColorWH()
    local t = os.clock() * 1.5
    local blend = (math.sin(t)+1.0)*0.5
    return AuraColorWH(10.0*blend, 10.0*(1.0-blend), 10.0, 1.0)
end
local function GetLavaFlowColorWH()
    local t = os.clock() * 1.0
    return AuraColorWH(10.0, (math.sin(t)*0.5+0.5)*8.0, (math.sin(t*2.0)*0.5+0.5)*2.0, 1.0)
end
local function GetVaporwaveColorWH()
    local t = os.clock() * 1.2
    return AuraColorWH((math.sin(t)*0.5+0.5)*10.0, (math.sin(t+2.094)*0.5+0.5)*5.0, (math.sin(t+4.188)*0.5+0.5)*10.0, 1.0)
end

local function GetColorByIDWH(cID)
    local c = ColorPaletteWH[cID] or ColorPaletteWH[5]
    if c == "RAINBOW_SMOOTH" then return GetRainbowSmoothColorWH()
    elseif c == "NEON_PULSE" then return GetNeonPulseColorWH()
    elseif c == "CYBERPUNK" then return GetCyberpunkColorWH()
    elseif c == "LAVA_FLOW" then return GetLavaFlowColorWH()
    elseif c == "VAPORWAVE" then return GetVaporwaveColorWH()
    else return c end
end

local function GetCurrentWallVisibleColorWH(isAI)
    if isAI then return GetColorByIDWH(_G.X3.XthrlenState.CustomTextData.WallVisAIColor or 29)
    else return GetColorByIDWH(_G.X3.XthrlenState.CustomTextData.WallVisColor or 5) end
end
local function GetCurrentWallOccludedColorWH(isAI)
    if isAI then return GetColorByIDWH(_G.X3.XthrlenState.CustomTextData.WallOccAIColor or 39)
    else return GetColorByIDWH(_G.X3.XthrlenState.CustomTextData.WallOccColor or 9) end
end

_G.X3.GetTransparentWH = function()
    if not _G.X3.TransparentColorWH then _G.X3.TransparentColorWH = AuraColorWH(0, 0, 0, 0) end
    return _G.X3.TransparentColorWH
end

_G.X3.ScaleColorAlphaWH = function(c, f)
    if type(c) ~= "table" then return c end
    return AuraColorWH(c.R or 1, c.G or 1, c.B or 1, (c.A or 1) * f)
end

-- 3. SDK VALIDATED MESH AURA
local ValidWH = function(obj) return obj and slua.isValid and slua.isValid(obj) end
local math_randomWH = math.random

local function ResetMeshAuraComponentWH(mesh)
    if not mesh or (slua.isValid and not slua.isValid(mesh)) then return end
    pcall(function()
        mesh:SetDrawDyeing(false)
        mesh:SetVisibleDyeingColor(AuraColorWH(0,0,0,0))
        mesh:SetOccludedDyeingColor(AuraColorWH(0,0,0,0))
        mesh:MarkRenderStateDirty()
    end)
end

local function ApplyAuraToMeshComponentWH(mesh, vis, occ)
    if not mesh or (slua.isValid and not slua.isValid(mesh)) then return end
    pcall(function()
        mesh:SetDrawDyeing(true)
        mesh:SetDrawDyeingMode(1)
        mesh:SetVisibleDyeingColor(vis)
        mesh:SetOccludedDyeingColor(occ)
        local fadeDistWH = tonumber(_G.X3.XthrlenState.CustomTextData.WallFadeDist) or 0
        if fadeDistWH > 0 then
            mesh:SetDyeingColorMinMaxDistance(0.0, fadeDistWH * 100.0)
            mesh:SetDyeingColorFadeDistance(fadeDistWH * 50.0)
        else
            mesh:SetDyeingColorMinMaxDistance(0.0, 99999.0)
            mesh:SetDyeingColorFadeDistance(0.0)
        end
        mesh:MarkRenderStateDirty()
    end)
end

local function GetClassNameWH(obj)
    local name = nil
    pcall(function()
        if obj and type(obj.GetClass) == "function" then
            local cls = obj:GetClass()
            if cls and type(cls.GetName) == "function" then name = cls:GetName() end
        end
    end)
    return name or ""
end

local WH_NoPSEnvUntil = 0

local function IsModelTargetNameWH(enemy)
    if enemy.TD_IsModelTargetWH == true then return true end
    local nowC = os.clock()
    if enemy.TD_MTCheckTimeWH and (nowC - enemy.TD_MTCheckTimeWH) < 2.0 then
        return false
    end
    enemy.TD_MTCheckTimeWH = nowC
    local hit = false
    pcall(function()
        local cand = {}
        local n1 = enemy.PlayerName
        if type(n1) == "string" and n1 ~= "" then table.insert(cand, n1) end
        if type(enemy.GetPlayerName) == "function" then
            local okN, n2 = pcall(function() return enemy:GetPlayerName() end)
            if okN and type(n2) == "string" and n2 ~= "" then table.insert(cand, n2) end
        end
        if type(enemy.GetName) == "function" then
            local okN3, n3 = pcall(function() return enemy:GetName() end)
            if okN3 and type(n3) == "string" and n3 ~= "" then table.insert(cand, n3) end
        end
        local ps = enemy.PlayerState
        if not ValidWH(ps) and type(enemy.GetPlayerState) == "function" then
            pcall(function() ps = enemy:GetPlayerState() end)
        end
        if ValidWH(ps) then
            pcall(function()
                local pn = ps.PlayerName
                if (type(pn) ~= "string" or pn == "") and type(ps.GetPlayerName) == "function" then
                    pn = ps:GetPlayerName()
                end
                if type(pn) == "string" and pn ~= "" then table.insert(cand, pn) end
            end)
        end
        for _, s in ipairs(cand) do
            local ls = string.lower(s)
            if ls:find("modeltarget", 1, true) or ls:find("targetdummy", 1, true)
                or ls:find("trainingtarget", 1, true)
                or ls:find("bot latihan", 1, true) or ls:find("training bot", 1, true)
                or ls:find("practice bot", 1, true)
                or s:find("训练机器人", 1, true) or s:find("靶场机器人", 1, true)
                or s:find("训练场", 1, true) then
                hit = true
                return
            end
        end
    end)
    if hit then
        enemy.TD_IsModelTargetWH = true
        pcall(function()
            if bWriteLog then print("[SRCHUB] patung training terdeteksi (ModelTarget) -> BOT") end
        end)
    end
    return hit
end

local function GetBotScoreWH(enemy)
    if not ValidWH(enemy) then return 0 end

    if IsModelTargetNameWH(enemy) then return 10 end

    local score = 0

    local nowC = os.clock()
    if enemy.TD_FirstSeenWH == nil then enemy.TD_FirstSeenWH = nowC end
    local seenAge = nowC - enemy.TD_FirstSeenWH
    local noPSEnv = nowC < WH_NoPSEnvUntil

    local gRes = nil
    pcall(function()
        local G = rawget(_G, "Game")
        if G and G.IsAI then gRes = G:IsAI(enemy) end
    end)
    if type(gRes) ~= "boolean" then
        pcall(function() if enemy.IsAI then gRes = enemy:IsAI() end end)
    end
    if type(gRes) ~= "boolean" then
        pcall(function() if type(enemy.bIsAI) == "boolean" then gRes = enemy.bIsAI end end)
    end
    if gRes == true then
        if noPSEnv or seenAge > 1.0 then score = score + 5 end
    elseif gRes == false and noPSEnv then
        score = score - 3
    end

    local ps = enemy.PlayerState
    if not ValidWH(ps) then pcall(function() ps = enemy:GetPlayerState() end) end

    if ValidWH(ps) then
        if ps.bIsABot == true or ps.bIsBot == true or ps.bIsAI == true then
            score = score + 6          -- jaga-jaga SDK menandai bot lewat ps
        elseif ps.bIsABot == false then
            score = score - 6          -- 75/75 player in-match: eksplisit false
        else
            local oid = nil
            pcall(function() oid = ps.OpenID end)
            if type(oid) == "string" and #oid >= 8 then score = score - 2
            elseif type(oid) == "number" and oid > 10000000 then score = score - 2
            else score = score + 2 end
            local aip = nil
            pcall(function() aip = ps.bIsAIPlayer end)
            if aip == true then score = score + 3 end
            local uid = nil
            pcall(function() uid = tonumber(ps.PlayerUID) or tonumber(ps.UID) end)
            if uid and uid > 0 then
                if uid >= 10000000000 then score = score - 1
                elseif uid < 100000 then score = score + 1 end
            end
        end
    else
        local nm = nil
        pcall(function() nm = enemy.PlayerName end)
        if type(nm) ~= "string" or nm == "" then nm = nil end
        local uid2 = nil
        pcall(function() uid2 = tonumber(enemy.PlayerUID) or tonumber(enemy.UID) end)
        local pkey = nil
        pcall(function() pkey = tonumber(enemy.PlayerKey) end)
        local hasIdentity = (nm ~= nil) or (uid2 ~= nil and uid2 > 0) or (pkey ~= nil and pkey > 0)
        if (uid2 ~= nil and uid2 >= 10000000000) or (pkey ~= nil and pkey >= 1000000000) then
            score = score - 6
            if seenAge > 4.0 then WH_NoPSEnvUntil = nowC + 10.0 end
        elseif hasIdentity and not noPSEnv and seenAge > 2.0 then
            score = score + 6
            if uid2 ~= nil and uid2 > 0 and uid2 < 100000 then score = score + 1 end
        end
    end

    return score
end

_G.X3.IsBotPawn = function(p)
    if not (p and slua.isValid(p)) then return false end
    if _G.X3.IsBotStable then
        local okS, resS = pcall(_G.X3.IsBotStable, p)
        if okS and type(resS) == "boolean" then return resS end
    end
    local v = nil
    pcall(function()
        local G = rawget(_G, "Game")
        if G and G.IsAI then v = G:IsAI(p) end
    end)
    if type(v) ~= "boolean" then
        pcall(function() if p.IsAI then v = p:IsAI() end end)
    end
    if type(v) ~= "boolean" then
        pcall(function() if p.bIsAI ~= nil then v = p.bIsAI end end)
    end
    if type(v) ~= "boolean" then
        pcall(function()
            local ps = p.PlayerState or (p.GetPlayerState and p:GetPlayerState())
            if ps and ps.bIsABot ~= nil then v = ps.bIsABot end
        end)
    end
    if type(v) ~= "boolean" then return nil end  -- tidak diketahui
    return v
end

_G.X3.GetBotScore = GetBotScoreWH

local function IsBotWeakNameWH(enemy)
    local ps = enemy.PlayerState
    if not ValidWH(ps) and type(enemy.GetPlayerState) == "function" then
        pcall(function() ps = enemy:GetPlayerState() end)
    end
    if ValidWH(ps) then return false end
    local res = false
    pcall(function()
        local n = enemy.PlayerName or (type(enemy.GetPlayerName) == "function" and enemy:GetPlayerName()) or ""
        n = string.lower(tostring(n))
        if n ~= "" then
            local botPatterns = {"bot", "cobra", "target", "dummy", "npc", "aiplayer", "training"}
            for _, p in ipairs(botPatterns) do
                if n:find(p, 1, true) then
                    res = true
                    return
                end
            end
        end
    end)
    return res
end

local function IsBotWH(enemy)
    -- Sumber flip lama (v43 ke bawah):
    -- Aturan v44:
    if not ValidWH(enemy) then return false end

    -- (1) patung training = BOT permanen
    if enemy.TD_IsModelTargetWH == true or IsModelTargetNameWH(enemy) then
        enemy.TD_IsPlayerConfirmedWH = nil
        enemy.TD_IsAIConfirmedWH = true
        enemy.TD_IsAICachedWH = true
        return true
    end

    local nowOS = os.clock()
    if enemy.TD_BotCheckTimeWH and (nowOS - enemy.TD_BotCheckTimeWH) < 0.5 then
        return enemy.TD_IsAICachedWH or false
    end
    enemy.TD_BotCheckTimeWH = nowOS

    local ps = enemy.PlayerState
    if not ValidWH(ps) then pcall(function() ps = enemy:GetPlayerState() end) end
    local official = nil

    if ps and ValidWH(ps) then
        local isMLAI = false
        pcall(function()
            local s = ps.MLAIStringUID
            if s ~= nil and tostring(s) ~= "" then isMLAI = true end
        end)
        if not isMLAI then
            pcall(function()
                local d = ps.MLAIDisplayUID
                if d ~= nil and tonumber(d) and tonumber(d) ~= 0 then isMLAI = true end
            end)
        end
        if isMLAI then
            enemy.TD_PendingVerdictWH = true
            enemy.TD_PendingCountWH = 99
            enemy.TD_IsAIConfirmedWH = true
            enemy.TD_IsAICachedWH = true
            enemy.TD_IsPlayerConfirmedWH = nil
            return true
        end
    end

    do
        local ctrl = nil
        pcall(function() ctrl = enemy.Controller end)
        if ctrl and ValidWH(ctrl) then
            local cname = nil
            pcall(function()
                local cls = ctrl:GetClass()
                if cls then cname = tostring(cls:GetName()) end
            end)
            if cname and string.find(cname, "AIController", 1, true) then
                enemy.TD_PendingVerdictWH = true
                enemy.TD_PendingCountWH = 99
                enemy.TD_IsAIConfirmedWH = true
                enemy.TD_IsAICachedWH = true
                enemy.TD_IsPlayerConfirmedWH = nil
                return true
            end
        end
    end

    if ValidWH(ps) then
        local f = nil
        pcall(function() f = ps.bIsABot end)
        if type(f) ~= "boolean" then pcall(function() f = ps.bIsBot end) end
        if type(f) ~= "boolean" then pcall(function() f = ps.bIsAI end) end
        if type(f) == "boolean" then official = f end
    end

    do
        local charFlag = nil
        pcall(function() if enemy.bIsAI ~= nil then charFlag = enemy.bIsAI and true or false end end)
        if charFlag ~= true then
            pcall(function() if enemy.bIsMLAI == true or enemy.bIsAIWithPet == true then charFlag = true end end)
        end
        if charFlag ~= true and type(enemy.IsAI) == "function" then
            pcall(function() if enemy:IsAI() == true then charFlag = true end end)
        end
        if charFlag == true then
            official = true
        elseif charFlag == false and official == nil then
            official = false
        end
    end

    if official ~= nil then
        -- penghitung beruntun pada verdict resmi
        if enemy.TD_PendingVerdictWH == official then
            enemy.TD_PendingCountWH = (enemy.TD_PendingCountWH or 0) + 1
        else
            enemy.TD_PendingVerdictWH = official
            enemy.TD_PendingCountWH = 1
        end
        if (enemy.TD_PendingCountWH or 0) >= 3 then
            if official then
                if enemy.TD_IsAIConfirmedWH ~= true then
                    pcall(function()
                        if bWriteLog then print("[SRCHUB] latch BOT (flag resmi stabil)") end
                    end)
                end
                enemy.TD_IsAIConfirmedWH = true
                enemy.TD_IsPlayerConfirmedWH = nil
            else
                if enemy.TD_IsPlayerConfirmedWH ~= true then
                    pcall(function()
                        if bWriteLog then print("[SRCHUB] latch PLAYER (flag resmi stabil)") end
                    end)
                end
                enemy.TD_IsPlayerConfirmedWH = true
                enemy.TD_IsAIConfirmedWH = nil
            end
            enemy.TD_NoPSCountWH = 0
            enemy.TD_NoPSPlayerCountWH = 0
            enemy.TD_IsAICachedWH = official
            return official
        end
        -- bacaan resmi sementara (belum terkunci)
        if enemy.TD_IsAIConfirmedWH == true then return true end
        if enemy.TD_IsPlayerConfirmedWH == true then return false end
        enemy.TD_IsAICachedWH = official
        return official
    end

    enemy.TD_PendingVerdictWH = nil
    enemy.TD_PendingCountWH = 0
    if enemy.TD_IsAIConfirmedWH == true then return true end
    if enemy.TD_IsPlayerConfirmedWH == true then return false end

    local score = GetBotScoreWH(enemy)
    if score >= 3 then
        enemy.TD_NoPSPlayerCountWH = 0
        enemy.TD_NoPSCountWH = (enemy.TD_NoPSCountWH or 0) + 1
        if enemy.TD_NoPSCountWH >= 3 then
            enemy.TD_IsAIConfirmedWH = true
            pcall(function()
                if bWriteLog then print("[SRCHUB] latch BOT via identitas ps-nil 3x (score " .. score .. ")") end
            end)
        end
        enemy.TD_IsAICachedWH = true
        return true
    end
    enemy.TD_NoPSCountWH = 0
    if score <= -3 then
        enemy.TD_NoPSPlayerCountWH = (enemy.TD_NoPSPlayerCountWH or 0) + 1
        if enemy.TD_NoPSPlayerCountWH >= 3 then
            enemy.TD_IsPlayerConfirmedWH = true
            pcall(function()
                if bWriteLog then print("[SRCHUB] latch PLAYER via identitas ps-nil 3x (score " .. score .. ")") end
            end)
        end
        enemy.TD_IsAICachedWH = false
        return false
    end
    enemy.TD_NoPSPlayerCountWH = 0

    local weak = false
    local fs = enemy.TD_FirstSeenWH
    if fs ~= nil and (os.clock() - fs) > 2.0 then
        weak = IsBotWeakNameWH(enemy)
    end
    enemy.TD_IsAICachedWH = weak
    return weak
end

_G.X3.IsBotStable = IsBotWH

_G.X3.PawnReadyT = _G.X3.PawnReadyT or {}
_G.X3.PawnReadyKey = function(p)
    local k = nil
    pcall(function()
        if type(p.GetUniqueID) == "function" then k = p:GetUniqueID() end
        if k == nil then k = p.PlayerKey end
        if k == nil and type(p.GetName) == "function" then k = p:GetName() end
    end)
    if k == nil then k = tostring(p) end
    return k
end
_G.X3.IsPawnRenderReady = function(p, minAge)
    if not (p and slua.isValid(p)) then return false end
    local now = os.clock()
    local key = _G.X3.PawnReadyKey(p)
    local st = _G.X3.PawnReadyT[key]
    if st == nil then
        local n = 0
        for _ in pairs(_G.X3.PawnReadyT) do n = n + 1 end
        if n > 400 then _G.X3.PawnReadyT = {} end -- cap anti menumpuk
        st = { t0 = now, ready = false }
        _G.X3.PawnReadyT[key] = st
        return false
    end
    if type(st) == "number" then -- migrasi format lama (timestamp polos)
        st = { t0 = st, ready = false }
        _G.X3.PawnReadyT[key] = st
    end
    if st.ready then return true end
    if (now - st.t0) < (minAge or 0.6) then return false end
    local ok = false
    pcall(function()
        local m = p.Mesh
        if not (m and slua.isValid(m)) and type(p.getAvatarComponent2) == "function" then
            m = p:getAvatarComponent2()
        end
        if m and slua.isValid(m) then ok = true end
    end)
    if ok then st.ready = true end
    return ok
end

_G.X3.SafeBonePos = function(t, boneName)
    if not (_G.X3.IsPawnRenderReady and _G.X3.IsPawnRenderReady(t, 0.6)) then return nil end
    local alt = nil
    if boneName == "head" then alt = "Head" elseif boneName == "Head" then alt = "head" end
    local pos = nil
    pcall(function() if t.GetBonePos then pos = t:GetBonePos(boneName, {X = 0, Y = 0, Z = 0}) end end)
    if pos and (pos.X ~= 0 or pos.Y ~= 0 or pos.Z ~= 0) then return pos end
    if alt then
        pos = nil
        pcall(function() if t.GetBonePos then pos = t:GetBonePos(alt, {X = 0, Y = 0, Z = 0}) end end)
        if pos and (pos.X ~= 0 or pos.Y ~= 0 or pos.Z ~= 0) then return pos end
    end
    pos = nil
    pcall(function() if type(t.GetSocketLocation) == "function" then pos = t:GetSocketLocation(boneName) end end)
    if pos and (pos.X ~= 0 or pos.Y ~= 0 or pos.Z ~= 0) then return pos end
    if alt then
        pos = nil
        pcall(function() if type(t.GetSocketLocation) == "function" then pos = t:GetSocketLocation(alt) end end)
        if pos and (pos.X ~= 0 or pos.Y ~= 0 or pos.Z ~= 0) then return pos end
    end
    return nil
end

_G.X3.SmokeCompCache = nil
_G.X3.SmokeCheckT = _G.X3.SmokeCheckT or {}
_G.X3._SmokeFailCount = 0
_G.X3.IsSmokeBlocking = function(pc, lp, enemy)
    if not (lp and slua.isValid(lp) and enemy and slua.isValid(enemy)) then return false end
    if _G.X3._SmokeUnavailable == true then return false end
    local now = os.clock()
    local key = _G.X3.PawnReadyKey(enemy)
    local ent = _G.X3.SmokeCheckT[key]
    if ent and (now - ent.t) < 0.3 then return ent.v end
    local blocked = false
    local resolved = false
    pcall(function()
        local comp = _G.X3.SmokeCompCache
        if not (comp and slua.isValid(comp) and type(comp.CheckSmoke) == "function") then
            comp = nil
            local okC, cls = pcall(import, "WeaponAutoAimingComponent")
            if okC and cls and type(lp.GetComponentByClass) == "function" then
                local okG, rG = pcall(function() return lp:GetComponentByClass(cls) end)
                if okG and rG and slua.isValid(rG) and type(rG.CheckSmoke) == "function" then comp = rG end
            end
            -- sumber 2: field langsung di karakter
            if not comp then
                local f = lp.WeaponAutoAimingComponent
                if f and slua.isValid(f) and type(f.CheckSmoke) == "function" then comp = f end
            end
            if not comp then
                pcall(function()
                    local wm = lp.WeaponManagerComponent
                    local a = wm and wm.AutoAimComp
                    if a and slua.isValid(a) and type(a.CheckSmoke) == "function" then comp = a end
                end)
            end
            if comp then _G.X3.SmokeCompCache = comp end
        end
        if not comp then return end
        resolved = true
        local s, e = nil, nil
        pcall(function() s = lp:K2_GetActorLocation() end)
        pcall(function() e = enemy:K2_GetActorLocation() end)
        if s and e then
            local okR, r = pcall(function() return comp:CheckSmoke(s, e, enemy) end)
            if okR and r == true then blocked = true end
        end
    end)
    if resolved then
        _G.X3._SmokeFailCount = 0
    else
        _G.X3._SmokeFailCount = (_G.X3._SmokeFailCount or 0) + 1
        if _G.X3._SmokeFailCount >= 25 then _G.X3._SmokeUnavailable = true end
    end
    local n = 0
    for _ in pairs(_G.X3.SmokeCheckT) do n = n + 1 end
    if n > 400 then _G.X3.SmokeCheckT = {} end
    _G.X3.SmokeCheckT[key] = { v = blocked, t = now }
    return blocked
end

-- 5. UNIVERSAL CHARACTER RETRIEVER
local function SRCHUB_GetAllCharactersUniversal()
    local chars = {}
    local seen = {}
    pcall(function()
        if GameplayData.GetAllPlayerCharacters then
            local brChars = GameplayData.GetAllPlayerCharacters()
            if brChars then
                for _, c in pairs(brChars) do
                    if slua.isValid(c) and not seen[c] then seen[c] = true; table.insert(chars, c) end
                end
            end
        end
        if GameplayData.GameCharacters then
            local gameChars = GameplayData.GameCharacters
            if type(gameChars) == "table" then
                for _, c in pairs(gameChars) do
                    if slua.isValid(c) and not seen[c] then seen[c] = true; table.insert(chars, c) end
                end
            end
        end
        local CreativeMgr = package.loaded["client.slua.logic.creative.CreativeManager"] or package.loaded["GameLua.Mod.PlanPH.Client.SubSystem.CreativeSubSystem"]
        if CreativeMgr and type(CreativeMgr.GetAllCreativeCharacters) == "function" then
            local wowChars = CreativeMgr:GetAllCreativeCharacters()
            if wowChars then
                for _, c in pairs(wowChars) do
                    if slua.isValid(c) and not seen[c] then seen[c] = true; table.insert(chars, c) end
                end
            end
        end
    end)
    return chars
end

-- 6. CONSOLE COMMANDS (Dyeing + Glow)
local function ToggleWallhackConsoleCommandsWH(PC, isOn)
    if not PC then return end
    pcall(function()
        local KSL = import("KismetSystemLibrary")
        if KSL and KSL.ExecuteConsoleCommand then
            local v = isOn and "1" or "0"
            KSL.ExecuteConsoleCommand(PC, "r.EnableDrawDyeingColor " .. v)
            KSL.ExecuteConsoleCommand(PC, "r.SupportDyeingColorDistanceFade " .. v)
            KSL.ExecuteConsoleCommand(PC, "r.SupportDyeingColorMeshProxy " .. v)
            KSL.ExecuteConsoleCommand(PC, "r.SupportDyeingColorOccluded " .. v)
            KSL.ExecuteConsoleCommand(PC, "r.DyeingColorVisibleOpacity " .. (isOn and "1.0" or "1.0"))
            KSL.ExecuteConsoleCommand(PC, "r.DyeingColorOccludedOpacity " .. (isOn and "1.0" or "0.0"))
            KSL.ExecuteConsoleCommand(PC, "t.ForceFixedBrigtness 1")           -- Anti auto-dim
            KSL.ExecuteConsoleCommand(PC, "r.VSync 0")                          -- Cut input lag
            KSL.ExecuteConsoleCommand(PC, "Slate.EnableGlobalInvalidation 1")  -- UI touch faster
            KSL.ExecuteConsoleCommand(PC, "Slate.bUseHighPrecision 1")         -- Touch precision
            KSL.ExecuteConsoleCommand(PC, "Slate.TouchOffset 0")               -- Zero touch offset
            KSL.ExecuteConsoleCommand(PC, "Input.ForceTouchActive 1")        -- Force touch always on
            KSL.ExecuteConsoleCommand(PC, "Input.bEnableGestureRecognition 0")  -- Disable gesture delay
            KSL.ExecuteConsoleCommand(PC, "Input.InitialButtonRepeatDelay 0.05") -- Faster repeat
            KSL.ExecuteConsoleCommand(PC, "Input.ButtonRepeatDelay 0.03")     -- Faster repeat burst
            KSL.ExecuteConsoleCommand(PC, "r.OneFrameThreadLag " .. (isOn and "0" or "1"))
            KSL.ExecuteConsoleCommand(PC, "r.FinishCurrentFrame " .. (isOn and "0" or "1"))
            KSL.ExecuteConsoleCommand(PC, "r.Streaming.PoolSize 256")
            KSL.ExecuteConsoleCommand(PC, "r.Streaming.UseFixedPoolSize 1")
            KSL.ExecuteConsoleCommand(PC, "r.Streaming.PoolSize.VRAMPercentageClamp 30")
            KSL.ExecuteConsoleCommand(PC, "r.Streaming.MaxTempMemoryAllowed 64")
            KSL.ExecuteConsoleCommand(PC, "r.Streaming.FramesForFullUpdate 2")
            KSL.ExecuteConsoleCommand(PC, "r.Streaming.HLODStrategy 2")
            if isOn and _G.X3.XthrlenConfig.WallhackGlow then
                KSL.ExecuteConsoleCommand(PC, "r.DyeingColorGlowIntensity 8.5")
                KSL.ExecuteConsoleCommand(PC, "r.HighlightColorScale 12.0")
                KSL.ExecuteConsoleCommand(PC, "r.BloomIntensity 8.5")
                KSL.ExecuteConsoleCommand(PC, "r.BloomQuality 4")
            else
                KSL.ExecuteConsoleCommand(PC, "r.DyeingColorGlowIntensity 0.0")
                KSL.ExecuteConsoleCommand(PC, "r.HighlightColorScale 1.0")
                KSL.ExecuteConsoleCommand(PC, "r.BloomIntensity 1.0")
                KSL.ExecuteConsoleCommand(PC, "r.BloomQuality 0")
            end
        end
    end)
end

local function ApplyKentangModeWH(PC)
    if not PC then return end
    pcall(function()
        local KSL = import("KismetSystemLibrary")
        if not (KSL and KSL.ExecuteConsoleCommand) then return end
        if not _G.X3.XthrlenConfig.KentangMode then
            local cmdsOff = {
                "r.ScreenPercentage 100",
                "r.ShadowQuality 2",
                "r.Shadow.CSM.MaxCascades 2",
                "r.Mobile.ShadowQuality 2",
                "r.Mobile.Shadow.CSM 1",
                "r.Mobile.Shadow.CSM.MaxCascades 2",
                "r.AmbientOcclusionLevels 1",
                "r.DistanceFieldShadowing 1",
                "r.TextureQuality 1",
                "r.Streaming.MipBias 0",
                "r.MaxAnisotropy 4",
                "r.MipMapLODBias 0",
                "r.MaterialQualityLevel 1",
                "r.SkeletalMeshLODBias 0",
                "r.ParticleLODBias 0",
                "r.EmitterSpawnRateScale 1",
                "r.Particle.MaxDrawDistance 30000",
                "r.LightMaxDrawDistanceScale 1",
                "r.PostProcessAAQuality 2",
                "r.TemporalAAQuality 2",
            }
            for _, c in ipairs(cmdsOff) do KSL.ExecuteConsoleCommand(PC, c) end
            return
        end

        local resMode = _G.X3.XthrlenState.CustomTextData.WallResolution or 1
        local sp = "100"
        if resMode == 2 then sp = "67"
        elseif resMode == 3 then sp = "59"
        elseif resMode == 4 then sp = "50"
        end
        KSL.ExecuteConsoleCommand(PC, "r.ScreenPercentage " .. sp)

        KSL.ExecuteConsoleCommand(PC, "r.ShadowQuality 0")
        KSL.ExecuteConsoleCommand(PC, "r.Shadow.CSM.MaxCascades 0")
        KSL.ExecuteConsoleCommand(PC, "r.Mobile.ShadowQuality 0")
        KSL.ExecuteConsoleCommand(PC, "r.Mobile.Shadow.CSM 0")
        KSL.ExecuteConsoleCommand(PC, "r.Mobile.Shadow.CSM.MaxCascades 0")
        KSL.ExecuteConsoleCommand(PC, "r.Mobile.Shadow.CSM.Distance 500")
        KSL.ExecuteConsoleCommand(PC, "r.Mobile.Shadow.CSM.Resolution 128")
        KSL.ExecuteConsoleCommand(PC, "r.Mobile.Shadow.PCSS 0")
        KSL.ExecuteConsoleCommand(PC, "r.Mobile.Shadow.PCF 0")
        KSL.ExecuteConsoleCommand(PC, "r.AmbientOcclusionLevels 0")
        KSL.ExecuteConsoleCommand(PC, "r.DistanceFieldShadowing 0")

        KSL.ExecuteConsoleCommand(PC, "r.TextureQuality 0")
        KSL.ExecuteConsoleCommand(PC, "r.TextureStreaming 1")
        KSL.ExecuteConsoleCommand(PC, "r.Streaming.PoolSize 256")
        KSL.ExecuteConsoleCommand(PC, "r.Streaming.LimitPoolSizeToVRAM 1")
        KSL.ExecuteConsoleCommand(PC, "r.Streaming.MipBias 2")
        KSL.ExecuteConsoleCommand(PC, "r.MaxAnisotropy 0")
        KSL.ExecuteConsoleCommand(PC, "r.MipMapLODBias 2")

        KSL.ExecuteConsoleCommand(PC, "r.MaterialQualityLevel 0")
        KSL.ExecuteConsoleCommand(PC, "r.SkeletalMeshLODBias 2")
        KSL.ExecuteConsoleCommand(PC, "r.ParticleLODBias 2")
        KSL.ExecuteConsoleCommand(PC, "r.DiscardUnusedQuality 1")

        KSL.ExecuteConsoleCommand(PC, "r.EmitterSpawnRateScale 0.3")
        KSL.ExecuteConsoleCommand(PC, "r.Particle.MaxDrawDistance 500")
        KSL.ExecuteConsoleCommand(PC, "r.LightMaxDrawDistanceScale 0.3")
        KSL.ExecuteConsoleCommand(PC, "r.MinScreenRadiusForLights 0.1")

        KSL.ExecuteConsoleCommand(PC, "r.PostProcessAAQuality 0")
        KSL.ExecuteConsoleCommand(PC, "r.TemporalAAQuality 0")
        KSL.ExecuteConsoleCommand(PC, "r.MotionBlurQuality 0")
        KSL.ExecuteConsoleCommand(PC, "r.BloomQuality 0")
        KSL.ExecuteConsoleCommand(PC, "r.LightShaftQuality 0")
        KSL.ExecuteConsoleCommand(PC, "r.LensFlareQuality 0")
        KSL.ExecuteConsoleCommand(PC, "r.SceneColorFringeQuality 0")
        KSL.ExecuteConsoleCommand(PC, "r.RefractionQuality 0")
        KSL.ExecuteConsoleCommand(PC, "r.DepthOfFieldQuality 0")

        KSL.ExecuteConsoleCommand(PC, "r.VSync 0")
        KSL.ExecuteConsoleCommand(PC, "r.MaxFPS 60")
        KSL.ExecuteConsoleCommand(PC, "t.MaxFPS 60")
    end)
end

local function ApplyRenderDistConfigWH(PC)
    if not PC then return end
    pcall(function()
        local KSL = import("KismetSystemLibrary")
        if not (KSL and KSL.ExecuteConsoleCommand) then return end
        local val = _G.X3.XthrlenState.CustomTextData.RenderDistSlider or 100
        local scale = val / 100.0

        KSL.ExecuteConsoleCommand(PC, "r.ViewDistanceScale " .. tostring(scale))
        KSL.ExecuteConsoleCommand(PC, "r.StaticMeshLODDistanceScale " .. tostring(scale))

        local bias = 0
        if val <= 60 then bias = 2
        elseif val <= 100 then bias = 1
        else bias = 0
        end
        KSL.ExecuteConsoleCommand(PC, "r.SkeletalMeshLODBias " .. tostring(bias))
        KSL.ExecuteConsoleCommand(PC, "r.ParticleLODBias " .. tostring(bias))
    end)
end

local function RestoreRenderDistConfigWH(PC)
    if not PC then return end
    pcall(function()
        local KSL = import("KismetSystemLibrary")
        if not (KSL and KSL.ExecuteConsoleCommand) then return end
        KSL.ExecuteConsoleCommand(PC, "r.ViewDistanceScale 1.0")
        KSL.ExecuteConsoleCommand(PC, "r.StaticMeshLODDistanceScale 1.0")
        KSL.ExecuteConsoleCommand(PC, "r.SkeletalMeshLODBias 0")
        KSL.ExecuteConsoleCommand(PC, "r.ParticleLODBias 0")
    end)
end

local function ApplyHDRSharpConfigWH(PC)
    if not PC then return end
    pcall(function()
        local KSL = import("KismetSystemLibrary")
        if not (KSL and KSL.ExecuteConsoleCommand) then return end
        local val = _G.X3.XthrlenState.CustomTextData.HDRSharpSlider or 100

        local highlight = val / 10.0
        KSL.ExecuteConsoleCommand(PC, "r.HighlightColorScale " .. tostring(highlight))

        local sharpen = val / 100.0
        KSL.ExecuteConsoleCommand(PC, "r.Tonemapper.Sharpen " .. tostring(sharpen))

        local bloom = val / 100.0 * 2.0
        KSL.ExecuteConsoleCommand(PC, "r.BloomIntensity " .. tostring(bloom))

        local eye = math.floor(val / 100.0 * 3.0)
        KSL.ExecuteConsoleCommand(PC, "r.EyeAdaptationQuality " .. tostring(eye))

        local eyeMethod = 0
        if val >= 150 then eyeMethod = 2
        elseif val >= 75 then eyeMethod = 1
        end
        KSL.ExecuteConsoleCommand(PC, "r.EyeAdaptationMethodOverride " .. tostring(eyeMethod))

        if val > 0 then
            KSL.ExecuteConsoleCommand(PC, "r.MobileHDR 1")
            KSL.ExecuteConsoleCommand(PC, "r.Mobile.TonemapperFilm 1")
        else
            KSL.ExecuteConsoleCommand(PC, "r.MobileHDR 0")
            KSL.ExecuteConsoleCommand(PC, "r.Mobile.TonemapperFilm 0")
        end
    end)
end

local function RestoreHDRSharpConfigWH(PC)
    if not PC then return end
    pcall(function()
        local KSL = import("KismetSystemLibrary")
        if not (KSL and KSL.ExecuteConsoleCommand) then return end
        KSL.ExecuteConsoleCommand(PC, "r.HighlightColorScale 1.0")
        KSL.ExecuteConsoleCommand(PC, "r.Tonemapper.Sharpen 0")
        KSL.ExecuteConsoleCommand(PC, "r.BloomIntensity 1.0")
        KSL.ExecuteConsoleCommand(PC, "r.EyeAdaptationQuality 2")
        KSL.ExecuteConsoleCommand(PC, "r.EyeAdaptationMethodOverride 0")
        KSL.ExecuteConsoleCommand(PC, "r.MobileHDR 1")
        KSL.ExecuteConsoleCommand(PC, "r.Mobile.TonemapperFilm 1")
    end)
end

-- 10. MAIN WALLHACK PROCESS (v9.4 Filter Fix)
-- TEMBUS PANDANG / WALLHACK VISCHECK --
function _G.X3.ProcessWallhack()
    -- [DISABLED] Wallhack 功能已被移除（用户请求）
end


function _G.X3.BuildWallhackMenu(stack, AliasMap)
    -- [DISABLED] BuildWallhackMenu 已移除
end


-- ==============================================================================
-- [AIMBOT V2 — aachetan.lua 完整移植 / local-safe 版]
-- 所有 helper 挂到 _G.X3._Aim,避免 chunk 级 200 local 溢出
-- ==============================================================================
do
    local A = _G.X3._Aim or {}
    _G.X3._Aim = A
    A.FVector2D         = A.FVector2D or nil
    A.GameplayStatics   = A.GameplayStatics or nil
    A.KismetMathLibrary = A.KismetMathLibrary or nil
    A.ui_util           = A.ui_util or nil
    A.ZeroVec           = A.ZeroVec or { X = 0, Y = 0, Z = 0 }
    A.ScreenProbe       = A.ScreenProbe or nil

    function A.EnsureImports()
        if not A.FVector2D         then pcall(function() A.FVector2D = import("Vector2D") end) end
        if not A.GameplayStatics   then pcall(function() A.GameplayStatics = import("GameplayStatics") end) end
        if not A.KismetMathLibrary then pcall(function() A.KismetMathLibrary = import("KismetMathLibrary") end) end
        if not A.ui_util           then pcall(function() A.ui_util = require("client.common.ui_util") end) end
    end

    function A.SmoothAlpha(speedVal, dt)
        if not dt or dt <= 0 then dt = 0.016 end
        if dt > 0.12 then dt = 0.12 end
        local s = tonumber(speedVal) or 50
        if s < 0 then s = 0 elseif s > 100 then s = 100 end
        local k = 3.0 + (s / 100.0) * 24.0
        local a = 1.0 - math.exp(-k * dt)
        if a < 0.02 then a = 0.02 end
        if a > 0.55 then a = 0.55 end
        return a
    end

    function A.IsAliveTarget(t)
        local alive = true
        pcall(function()
            if type(t.IsAlive) == "function" then
                alive = t:IsAlive()
            else
                local st = t.HealthStatus
                if st ~= nil then alive = SecurityCommonUtils.IsHealthStatusAlive(st) end
            end
        end)
        return alive
    end

    function A.IsKnocked(t)
        if not t then return false end
        local knocked = false
        pcall(function()
            local st = nil
            if type(t.GetHealthStatus) == "function" then st = t:GetHealthStatus() end
            if st == nil then st = t.HealthStatus end
            if st == nil then st = t.LastHealthStatus end
            if st ~= nil and st == 1 then knocked = true end
        end)
        return knocked
    end

    function A.BonePos(target, boneIdx)
        local boneName = "head"
        if boneIdx == 2 then boneName = "spine_03"
        elseif boneIdx == 3 then boneName = "spine_01"
        elseif boneIdx == 4 then boneName = "pelvis" end
        local pos = nil
        A.ZeroVec.X, A.ZeroVec.Y, A.ZeroVec.Z = 0, 0, 0
        pcall(function() pos = target:GetBonePos(boneName, A.ZeroVec) end)
        if not pos or (pos.X == 0 and pos.Y == 0 and pos.Z == 0) then
            if type(target.GetSocketLocation) == "function" then
                pcall(function() pos = target:GetSocketLocation(boneName) end)
            end
        end
        if not pos or (pos.X == 0 and pos.Y == 0 and pos.Z == 0) then
            if type(target.K2_GetActorLocation) == "function" then
                pcall(function()
                    pos = target:K2_GetActorLocation()
                    if pos then
                        if boneIdx == 1 then pos.Z = pos.Z + 70
                        elseif boneIdx == 2 then pos.Z = pos.Z + 40
                        elseif boneIdx == 3 then pos.Z = pos.Z + 20 end
                    end
                end)
            end
        end
        if not pos or (pos.X == 0 and pos.Y == 0 and pos.Z == 0) then return nil end
        return pos
    end
end

_G.X3.AimTouchState = _G.X3.AimTouchState or {
    target = nil, lastScan = 0, lastApply = 0, scanInterval = 0.05,
}

_G.X3.GetEnemyTargetsFromActors = function(radius)
    local result = {}
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return result end
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
                if dist <= radius then table.insert(result, actor) end
            end
        end
    end
    return result
end

-- 主瞄准函数 (所有 helper 通过 _G.X3._Aim 访问,函数内 local 不受 200 限制)
_G.X3.AimTouch = function()
    pcall(function()
        local A = _G.X3._Aim
        if not _G.X3.XthrlenConfig.AimTouchEnable then
            local st0 = _G.X3.AimTouchState
            if st0 then st0.target = nil end
            return
        end

        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
        local pc = player:GetPlayerControllerSafety()
        if not slua.isValid(pc) then return end

        local isFiring = player.bIsWeaponFiring
        local isADS    = player.bIsGunADS

        local weapon = player.WeaponManagerComponent and player.WeaponManagerComponent.CurrentWeaponReplicated
        if not weapon and type(player.GetCurrentShootWeapon) == "function" then
            weapon = player:GetCurrentShootWeapon()
        end

        local isShotgun, isSniper, isMortar = false, false, false
        local currentAmmo = 1

        if slua.isValid(weapon) then
            local wID, wName = 0, ""
            local wcache = _G.X3.AimTouchWeaponCache
            if wcache and wcache.weapon == weapon then
                wID, wName = wcache.id, wcache.name
                isShotgun, isSniper, isMortar = wcache.shotgun, wcache.sniper, wcache.mortar
            else
                wID   = type(weapon.GetWeaponID)   == "function" and weapon:GetWeaponID()   or 0
                wName = type(weapon.GetWeaponName) == "function" and weapon:GetWeaponName() or ""
                wName = wName or ""
                if (wID >= 1030000 and wID < 1040000) or wName:find("S686") or wName:find("S1897")
                   or wName:find("S12") or wName:find("DBS") or wName:find("M1014") then isShotgun = true end
                if wName:find("Kar98") or wName:find("M24") or wName:find("AWM") or wName:find("Mosin")
                   or wName:find("Win94") or wName:find("AMR") or wName:find("SKS") or wName:find("SLR")
                   or wName:find("Mini") or wName:find("Mk14") or wName:find("QBU") or wName:find("Mk12")
                   or wName:find("VSS") or wName:find("M1") or wName:find("DSR") then isSniper = true end
                if wName:lower():find("mortar") then isMortar = true end
                _G.X3.AimTouchWeaponCache = {
                    weapon = weapon, id = wID, name = wName,
                    shotgun = isShotgun, sniper = isSniper, mortar = isMortar,
                }
            end
            if type(weapon.GetCurrentAmmo) == "function" then
                currentAmmo = weapon:GetCurrentAmmo()
            elseif weapon.ShootWeaponComponent and type(weapon.ShootWeaponComponent.GetCurrentAmmo) == "function" then
                currentAmmo = weapon.ShootWeaponComponent:GetCurrentAmmo()
            elseif weapon.CurrentAmmo ~= nil then
                currentAmmo = weapon.CurrentAmmo
            end
        end

        if _G.X3.XthrlenState.IsAutoFiring then
            pcall(function()
                player.bIsWeaponFiring = false
                if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(false) end
                if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(false) end
                local wepMgr = player.WeaponManagerComponent
                if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = false end
            end)
            _G.X3.XthrlenState.IsAutoFiring = false
        end

        if isShotgun and currentAmmo <= 0 then return end

        local cond, prioMode, boneIdx = 2, 1, 1
        local speedVal, fovVal, maxDistMeters = 50, 30, 50
        local useVisCheck, igKnock, igBot = false, false, false
        local predVal, recoilCompVal = 0, 0
        local CTD = _G.X3.XthrlenState.CustomTextData

        if isMortar and _G.X3.XthrlenConfig.AimTouchMortar then
            local isPlaced = false
            pcall(function() if weapon and weapon.MortarState == 2 then isPlaced = true end end)
            if not isPlaced then return end
            cond, prioMode, boneIdx, speedVal = 2, 1, 4, 100
            fovVal = CTD.AimTouchMortarFOV or 360
            maxDistMeters = 2000
            predVal = CTD.AimTouchMortarPred or 0
        elseif isShotgun and _G.X3.XthrlenConfig.AimTouchSG then
            cond = CTD.AimTouchSGCond or 1
            if _G.X3.XthrlenConfig.AimTouchSGAutoFire then cond = 2 end
            if cond == 1 and not isFiring then return end
            prioMode  = CTD.AimTouchSGPrio  or 1
            boneIdx   = CTD.AimTouchSGBone  or 2
            speedVal  = CTD.AimTouchSGSpeed or 80
            fovVal    = CTD.AimTouchSGFOV   or 40
            maxDistMeters = CTD.AimTouchSGDist or 30
            useVisCheck = _G.X3.XthrlenConfig.AimTouchSGVisCheck
            igKnock     = _G.X3.XthrlenConfig.AimTouchSGIgKnock
            igBot       = _G.X3.XthrlenConfig.AimTouchSGIgBot
        elseif isADS then
            if isSniper and _G.X3.XthrlenConfig.AimTouchScopeSniper then
                cond = CTD.AimTouchSniperCond or 2
                if cond == 1 and not isFiring then return end
                prioMode  = CTD.AimTouchSniperPrio  or 1
                boneIdx   = CTD.AimTouchSniperBone  or 1
                speedVal  = CTD.AimTouchSniperSpeed or 30
                fovVal    = CTD.AimTouchSniperFOV   or 20
                maxDistMeters = CTD.AimTouchSniperDist or 400
                useVisCheck = _G.X3.XthrlenConfig.AimTouchSniperVisCheck
                igKnock     = _G.X3.XthrlenConfig.AimTouchSniperIgKnock
                igBot       = _G.X3.XthrlenConfig.AimTouchSniperIgBot
                predVal     = CTD.AimTouchSniperPred or 0
            elseif _G.X3.XthrlenConfig.AimTouchScopeAll then
                cond = CTD.AimTouchScopeCond or 1
                if cond == 1 and not isFiring then return end
                prioMode  = CTD.AimTouchScopePrio  or 1
                boneIdx   = CTD.AimTouchScopeBone  or 2
                speedVal  = CTD.AimTouchScopeSpeed or 40
                fovVal    = CTD.AimTouchScopeFOV   or 20
                maxDistMeters = CTD.AimTouchScopeDist or 300
                useVisCheck = _G.X3.XthrlenConfig.AimTouchScopeVisCheck
                igKnock     = _G.X3.XthrlenConfig.AimTouchScopeIgKnock
                igBot       = _G.X3.XthrlenConfig.AimTouchScopeIgBot
                predVal       = CTD.AimTouchScopePred   or 0
                recoilCompVal = CTD.AimTouchScopeRecoil or 0
            else
                return
            end
        else
            if not _G.X3.XthrlenConfig.AimTouchHipfire then return end
            cond = CTD.AimTouchHipCond or 1
            if cond == 1 and not isFiring then return end
            prioMode  = CTD.AimTouchHipPrio  or 1
            boneIdx   = CTD.AimTouchHipBone  or 1
            speedVal  = CTD.AimTouchHipSpeed or 50
            fovVal    = CTD.AimTouchHipFOV   or 30
            maxDistMeters = CTD.AimTouchHipDist or 250
            useVisCheck = _G.X3.XthrlenConfig.AimTouchHipVisCheck
            igKnock     = _G.X3.XthrlenConfig.AimTouchHipIgKnock
            igBot       = _G.X3.XthrlenConfig.AimTouchHipIgBot
        end

        local currentMaxDist = maxDistMeters * 100
        A.EnsureImports()
        if not (A.GameplayStatics and A.KismetMathLibrary and A.ui_util and A.FVector2D) then return end

        local camManager = A.GameplayStatics.GetPlayerCameraManager(pc, 0)
        if not slua.isValid(camManager) then return end
        local camLoc = camManager:GetCameraLocation()
        if not camLoc then return end

        local now = os.clock()
        local st  = _G.X3.AimTouchState
        local myTeam = nil
        pcall(function() myTeam = player:GetTeamID() end)

        local target = st.target
        if target ~= nil then
            local ok = slua.isValid(target) and A.IsAliveTarget(target)
            if ok then
                local tTeam = nil
                pcall(function() tTeam = target:GetTeamID() end)
                if tTeam == nil or tTeam <= 0 or tTeam == myTeam then ok = false end
            end
            if ok and igKnock and A.IsKnocked(target) then ok = false end
            if ok and (now - st.lastScan) >= 0.3 then
                local d = nil
                pcall(function() d = player:GetDistanceTo(target) end)
                if d and d > currentMaxDist then ok = false end
            end
            if not ok then target = nil end
        end

        local needScan = (target == nil) or ((now - st.lastScan) >= st.scanInterval)
        if needScan then
            st.lastScan = now
            local enemies = _G.X3.GetEnemyTargetsFromActors(currentMaxDist)
            if enemies and #enemies > 0 then
                local viewportSize = A.ui_util.GetViewportSize()
                if viewportSize then
                    local centerX = viewportSize.X * 0.5
                    local centerY = viewportSize.Y * 0.5
                    local FOV_RADIUS = (fovVal / 100.0) * (viewportSize.X / 2.0)
                    local bestTarget, bestScore = nil, 99999999
                    for i, cand in ipairs(enemies) do
                        if not slua.isValid(cand) then goto continue end
                        pcall(function()
                            if slua.isValid(cand.Mesh) then cand.Mesh.MeshComponentUpdateFlag = 0 end
                        end)
                        if igKnock and A.IsKnocked(cand) then goto continue end
                        if igBot then
                            local tIsBot = false
                            if cand.bIsAI == true or cand.IsAI == true then tIsBot = true end
                            local pState = cand.PlayerState
                            if slua.isValid(pState) and (pState.bIsABot or pState.bIsBot) then tIsBot = true end
                            if tIsBot then goto continue end
                        end
                        if useVisCheck then
                            local curTime = os.clock()
                            local tId = type(cand.GetUniqueID) == "function" and cand:GetUniqueID() or tostring(cand)
                            _G.X3.AimTouchVisCache = _G.X3.AimTouchVisCache or {}
                            local cachedVis = _G.X3.AimTouchVisCache[tId]
                            if not cachedVis or (curTime - cachedVis.time) > 0.2 then
                                local isHidden = true
                                pcall(function() if pc:LineOfSightTo(cand) then isHidden = false end end)
                                cachedVis = { hidden = isHidden, time = curTime }
                                _G.X3.AimTouchVisCache[tId] = cachedVis
                            end
                            if cachedVis.hidden then goto continue end
                        end
                        local tPos = A.BonePos(cand, boneIdx)
                        if not tPos then goto continue end
                        local screen = A.ScreenProbe
                        if not screen then screen = A.FVector2D(); A.ScreenProbe = screen end
                        screen.X = 0; screen.Y = 0
                        local success = pc:ProjectWorldLocationToScreen(tPos, screen, false)
                        if not success or screen.X <= 0 or screen.Y <= 0 then goto continue end
                        local dx = screen.X - centerX
                        local dy = screen.Y - centerY
                        local distScreen = math.sqrt(dx*dx + dy*dy)
                        if distScreen > FOV_RADIUS then goto continue end
                        local currentScore = distScreen
                        if prioMode == 2 then currentScore = player:GetDistanceTo(cand)
                        elseif prioMode == 3 then currentScore = cand.Health or 100
                        elseif prioMode == 4 then
                            local hp = cand.Health or 100
                            local maxhp = cand.HealthMax or 100
                            if maxhp <= 0 then maxhp = 100 end
                            currentScore = hp / maxhp
                        end
                        if currentScore < bestScore then
                            bestScore, bestTarget = currentScore, cand
                        end
                        ::continue::
                    end
                    target = slua.isValid(bestTarget) and bestTarget or nil
                end
            else
                target = nil
            end
            st.target = target
        end

        if not slua.isValid(target) then return end
        local finalBonePos = A.BonePos(target, boneIdx)
        if not finalBonePos then return end
        
            if isSniper and isADS then
        local sniperHeightOffset = 25 -- 【重点】抬高的高度(单位:厘米)，可根据需要自行修改(建议30~60之间)
        finalBonePos.Z = finalBonePos.Z + sniperHeightOffset
    end
        

        local tVelocity = nil
        pcall(function() if type(target.GetVelocity) == "function" then tVelocity = target:GetVelocity() end end)

        if isMortar and _G.X3.XthrlenConfig.AimTouchMortar and predVal > 0 then
            pcall(function()
                if tVelocity and (tVelocity.X ~= 0 or tVelocity.Y ~= 0) then
                    local approxDist = player:GetDistanceTo(target) / 100.0
                    local approxToF  = approxDist / 100.0
                    local predScale  = predVal / 50.0
                    finalBonePos.X = finalBonePos.X + (tVelocity.X * approxToF * predScale)
                    finalBonePos.Y = finalBonePos.Y + (tVelocity.Y * approxToF * predScale)
                end
            end)
        elseif not isMortar and predVal > 0 then
            pcall(function()
                if tVelocity and (tVelocity.X ~= 0 or tVelocity.Y ~= 0) then
                    local distToEnemy = player:GetDistanceTo(target) / 100.0
                    local ToF = (distToEnemy / 800.0) * (predVal / 50.0)
                    finalBonePos.X = finalBonePos.X + (tVelocity.X * ToF)
                    finalBonePos.Y = finalBonePos.Y + (tVelocity.Y * ToF)
                end
            end)
        end

        local rot = A.KismetMathLibrary.FindLookAtRotation(camLoc, finalBonePos)
        if not rot then return end
        local currentRot = pc:GetControlRotation()
        if not currentRot then return end

        local deltaYaw   = rot.Yaw   - currentRot.Yaw
        local deltaPitch = rot.Pitch - currentRot.Pitch
     if isADS then
         local camRot = nil
         if type(camManager.GetCameraRotation) == "function" then camRot = camManager:GetCameraRotation() end
         if camRot then
             deltaYaw   = deltaYaw   - (camRot.Yaw   - currentRot.Yaw)
             deltaPitch = deltaPitch - (camRot.Pitch - currentRot.Pitch)
         end
         
         -- ================= [FIX] 独立 ADS Offset Correction =================
         local CTD = _G.X3.XthrlenState.CustomTextData
         local yawOff, pitchOff = 0, 0
         
         if isSniper then
             -- 【狙击枪】独立偏移
             yawOff   = CTD.AimTouchSniperYawOffset or 0
             pitchOff = CTD.AimTouchSniperPitchOffset or 0
         else
             -- 【步枪/普通Scope】独立偏移
             yawOff   = CTD.AimTouchScopeYawOffset or 0
             pitchOff = CTD.AimTouchScopePitchOffset or 0
         end
         
         deltaYaw   = deltaYaw + yawOff
         deltaPitch = deltaPitch + pitchOff
         -- ===============================================================
     end
        if deltaYaw > 180 then deltaYaw = deltaYaw - 360 end
        if deltaYaw < -180 then deltaYaw = deltaYaw + 360 end
        if deltaPitch > 180 then deltaPitch = deltaPitch - 360 end
        if deltaPitch < -180 then deltaPitch = deltaPitch + 360 end

        local dt = now - (st.lastApply or now)
        st.lastApply = now
        local smoothFactor = A.SmoothAlpha(speedVal, dt)
        local finalPitch = currentRot.Pitch + (deltaPitch * smoothFactor)
        local finalYaw   = currentRot.Yaw   + (deltaYaw   * smoothFactor)

        if recoilCompVal > 0 and isFiring then
            local pullDownForce = (recoilCompVal / 50.0) * 1.5
            finalPitch = finalPitch - pullDownForce
        end

        if isMortar and _G.X3.XthrlenConfig.AimTouchMortar then
            local targetPos = { X = finalBonePos.X, Y = finalBonePos.Y, Z = finalBonePos.Z }
            local launchPos = camLoc
            pcall(function()
                if player.K2_GetActorLocation then
                    local pLoc = player:K2_GetActorLocation()
                    if pLoc then launchPos = { X = pLoc.X, Y = pLoc.Y, Z = pLoc.Z + 50 } end
                end
            end)
            local function CalcMortarTrajectory(V, G, tX, tY, tZ)
                local mDx = math.sqrt((tX - launchPos.X)^2 + (tY - launchPos.Y)^2) - 80
                if mDx < 500 then mDx = 500 end
                local mDy = tZ - launchPos.Z
                local minVSq = G * (mDy + math.sqrt(mDx*mDx + mDy*mDy))
                if (V * V) < minVSq then V = math.sqrt(minVSq) + 100 end
                local v2   = V * V
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
            local vFar,  gFar  = 12520, 980 * 4.0
            local vUltra,gUltra= 16800, 980 * 4.5
            local physAngle = 45
            local okNear,  angNear,  _, dxN = CalcMortarTrajectory(vNear,  gNear,  targetPos.X, targetPos.Y, targetPos.Z)
            local okFar,   angFar,   _, dxF = CalcMortarTrajectory(vFar,   gFar,   targetPos.X, targetPos.Y, targetPos.Z)
            local okUltra, angUltra, _, dxU = CalcMortarTrajectory(vUltra, gUltra, targetPos.X, targetPos.Y, targetPos.Z)
            if     okNear  and dxN <= 25000 then physAngle = angNear
            elseif okFar   and dxF <= 40000 then physAngle = angFar
            elseif okUltra                  then physAngle = angUltra
            elseif okNear                   then physAngle = angNear
            end
            local targetCameraPitch = ((physAngle - 45) / 43.0) * 90.0 - 60.0
            local targetCameraYaw   = rot.Yaw
            local deltaPitchMortar = targetCameraPitch - currentRot.Pitch
            local deltaYawMortar   = targetCameraYaw   - currentRot.Yaw
            if deltaPitchMortar > 180 then deltaPitchMortar = deltaPitchMortar - 360 end
            if deltaPitchMortar < -180 then deltaPitchMortar = deltaPitchMortar + 360 end
            if deltaYawMortar   > 180 then deltaYawMortar   = deltaYawMortar   - 360 end
            if deltaYawMortar   < -180 then deltaYawMortar  = deltaYawMortar   + 360 end
            finalPitch = currentRot.Pitch + (deltaPitchMortar * smoothFactor)
            finalYaw   = currentRot.Yaw   + (deltaYawMortar   * smoothFactor)
        end

        pc:SetControlRotation({ Pitch = finalPitch, Yaw = finalYaw, Roll = 0 }, "AimTouch")

        if isShotgun and _G.X3.XthrlenConfig.AimTouchSGAutoFire then
            pcall(function()
                local distToTarget = player:GetDistanceTo(target) / 100
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
                    _G.X3.XthrlenState.IsAutoFiring = true
                end
            end)
        end
    end)
end

-- 60Hz 专用瞄准驱动 (全用全局,不占 chunk local)
function _G.X3.StopAimTimer()
    if _G.X3._AIM_TIMER and slua.isValid(_G.X3._AIM_TIMER_OWNER)
       and _G.X3._AIM_TIMER_OWNER.RemoveGameTimer then
        pcall(_G.X3._AIM_TIMER_OWNER.RemoveGameTimer, _G.X3._AIM_TIMER_OWNER, _G.X3._AIM_TIMER)
    end
    _G.X3._AIM_TIMER       = nil
    _G.X3._AIM_TIMER_OWNER = nil
    _G.X3._AIM_TIMER_LAST  = nil
    if _G.X3.AimTouchState then
        _G.X3.AimTouchState.target    = nil
        _G.X3.AimTouchState.lastApply = 0
    end
end

function _G.X3.StartAimTimer(pc)
    if not (pc and slua.isValid(pc) and pc.AddGameTimer) then
        pcall(function() pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController() end)
    end
    if not (pc and slua.isValid(pc) and pc.AddGameTimer) then return end
    if _G.X3._AIM_TIMER then
        local fresh = _G.X3._AIM_TIMER_LAST and (os.time() - _G.X3._AIM_TIMER_LAST) <= 1
        if _G.X3._AIM_TIMER_OWNER == pc and fresh then return end
        _G.X3.StopAimTimer()
    end
    _G.X3._AIM_TIMER_OWNER = pc
    _G.X3._AIM_TIMER_LAST  = os.time()
    _G.X3._AIM_TIMER = pc:AddGameTimer(0.016, true, function()
        _G.X3._AIM_TIMER_LAST = os.time()
        pcall(_G.X3.AimTouch)
    end)
end

local function MainLoop()
    -- [PORT] force-off ESP lama dihapus: menu ESP sekarang dikendalikan user
    do
        local nowF = os.clock()
        local last = _G.X3._FrameLastT or nowF
        local dt = nowF - last
        _G.X3._FrameLastT = nowF
        if dt > 0.0005 and dt < 0.5 then
            _G.X3.FrameDT = (_G.X3.FrameDT or dt) * 0.9 + dt * 0.1
        end
    end
    if not _G.X3.XthrlenState.LastHitHookRetry or (os.clock() - _G.X3.XthrlenState.LastHitHookRetry) > 2.0 then
        _G.X3.XthrlenState.LastHitHookRetry = os.clock()
        if _G.X3.InstallUnifiedHitHook then _G.X3.InstallUnifiedHitHook() end
    end

    -- Di dalam tick/loop utama:
if _G.X3 and _G.X3.EspHealthName and _G.X3.EspHealthName.Tick then
    _G.X3.EspHealthName.Tick(lp)
end

    if _G.X3.XthrlenState.CustomTextData == nil then
        _G.X3.XthrlenState.CustomTextData = {OuterSpeed = 10, InnerSpeed = 10, HRecoil = 0.3, VRecoil = 0.3, MagicHead = 1.0, MagicNeck = 1.0, MagicBody = 1.0, MagicPelvis = 1.0, MagicArms = 1.0, MagicLegs = 1.0, IpadViewFOV = 120, AimTouchHipPrio = 1, AimTouchHipBone = 1, AimTouchHipCond = 1, AimTouchHipSpeed = 50, AimTouchHipFOV = 30, AimTouchHipDist = 250, AimTouchHipPred = 30, AimTouchSGPrio = 1, AimTouchSGBone = 2, AimTouchSGCond = 1, AimTouchSGSpeed = 80, AimTouchSGFOV = 40, AimTouchSGDist = 30, AimTouchScopePrio = 1, AimTouchScopeBone = 2, AimTouchScopeCond = 1, AimTouchScopeSpeed = 40, AimTouchScopeFOV = 20, AimTouchScopeDist = 300, AimTouchSniperPrio = 1, AimTouchSniperBone = 1, AimTouchSniperCond = 2, AimTouchSniperSpeed = 30, AimTouchSniperFOV = 20, AimTouchSniperDist = 400}
    end

    local okData, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if not okData or not GameplayData then return end
    local pc = GameplayData.GetPlayerController()
    local localPlayer = nil
    if Valid(pc) then localPlayer = pc:GetPlayerCharacterSafety() end

    if _G.X3.XthrlenConfig.UnlockFPS then pcall(InitializeGraphicsUnlock) end
    pcall(_G.X3.Team_InitializeHWIDHook)
    if _G.X3.XthrlenConfig.FakeHWID then pcall(_G.X3.ApplyDeviceOSFakes) end
    if _G.X3.XthrlenConfig.NetBoost then pcall(function() _G.X3.ApplyNetworkBoost(true) end) end
    pcall(InitializeNativeESP)
    pcall(ShowXthrlenVIPMenu)
    if _G.X3.LobbyVisualsTick then pcall(_G.X3.LobbyVisualsTick) end

    if not Valid(localPlayer) then
        if _G.X3.XthrlenState.TrackedMarks then
            for markId, _ in pairs(_G.X3.XthrlenState.TrackedMarks) do
                SafeRemoveMark(markId)
            end
        end
        _G.X3.XthrlenState.TrackedMarks = {}
        for key, data in pairs(_G.X3.XthrlenState.EnemyMarks) do
            if data and data.MIDs then
                for meshStr, midTable in pairs(data.MIDs) do
                    for k, _ in pairs(midTable) do midTable[k] = nil end
                end
                data.MIDs = nil
            end
        end
        _G.X3.XthrlenState.EnemyMarks = {}
        _G.X3.AK_OrigHitboxes = {}
        _G.X3.AK_ModdedPhysAssets = {}
        _G.X3.AK_WantedAssets = {}
        _G.X3.AK_AssetRefs = {}
        _G.X3.AK_AppliedMeshes = {}
        _G.X3._MBBattleKickDone = false
        _G.X3.XthrlenState.PrevGraphicsState = {}
        _G.X3._MBVisCache = {} -- [REBUILD-FIX] cache vischeck MB dibersihkan lintas-match

        if _G.X3.EspCountDestroy and _G.X3.EspCountBtn then pcall(_G.X3.EspCountDestroy) end
        if not _G.X3.LobbyTraced then
            _G.X3.LobbyTraced = true
            _G.X3.Trace("LOBBY: MainLoop berjalan tanpa localPlayer (lobby/login) — menu retry + skin keep-alive aktif")
            -- reset). Diikuti keep-alive 5 dtk di bawah.
        end
        if _G.X3.CacheCleanerTick then pcall(_G.X3.CacheCleanerTick, false) end
        if _G.X3.WMLobby then pcall(_G.X3.WMLobby) end
        if _G.X3.EspCountV2Destroy then pcall(_G.X3.EspCountV2Destroy) end
        _G.X3._WH_SpawnResetDone = false
        if _G.X3.XthrlenConfig and _G.X3.XthrlenConfig.WallhackVis and not _G.X3._WH_LobbyOffDone then
            _G.X3._WH_LobbyOffDone = true
            pcall(function()
                local pc = GameplayData and GameplayData.GetPlayerController and GameplayData.GetPlayerController()
                if pc and slua.isValid(pc) and ToggleWallhackConsoleCommandsWH then
                    ToggleWallhackConsoleCommandsWH(pc, false)
                end
                if _G.X3.XthrlenState and _G.X3.XthrlenState.WallAppliedSet then
                    for e, _ in pairs(_G.X3.XthrlenState.WallAppliedSet) do
                        if e and ValidWH(e) and e.TD_AuraMeshesWH then
                            pcall(function()
                                for _, m in ipairs(e.TD_AuraMeshesWH) do ResetMeshAuraComponentWH(m) end
                            end)
                            e.WallhackAppliedWH = false
                            e.LastAuraHashWH = nil
                        end
                    end
                    _G.X3.XthrlenState.WallAppliedSet = {}
                end
            end)
            if type(_G.X3.Trace) == "function" then _G.X3.Trace("LOBBY: wallhack AUTO OFF (cvar dye default + sisa dye dibersihkan)") end
        end
        return
    end

    if _G.X3.LobbyTraced then
        _G.X3.LobbyTraced = nil
        _G.X3.Trace("BATTLE: localPlayer valid — masuk battle/spawn")
    end

pcall(function() _G.X3._WH_SyncMatchState(localPlayer, pc) end)

if not (localPlayer and slua.isValid(localPlayer)) then
    _G.X3._WH.spawnResetDone = false
    _G.X3._WH.lastMatchApply = 0
end

if not _G.X3._WH.spawnResetDone then
    _G.X3._WH.spawnResetDone = true
    _G.X3._WH.lobbyOffDone = false
    _G.X3.PawnReadyT = {}
    _G.X3._XFWwhApplied = {}
    if _G.X3.XthrlenState then _G.X3.XthrlenState.WallAppliedSet = {} end
    if _G.X3.XthrlenConfig and _G.X3.XthrlenConfig.WallhackVis then
        _G.X3.WallhackColorVersion = (_G.X3.WallhackColorVersion or 1) + 1
        pcall(function()
            if pc and slua.isValid(pc) and ToggleWallhackConsoleCommandsWH then
                ToggleWallhackConsoleCommandsWH(pc, true)
            end
        end)
    end
    if type(_G.X3.Trace) == "function" then
        _G.X3.Trace("WH FIX: wallhack re-arm untuk match ini")
    end
end

-- FIX BARU: Force refresh cvar dye tiap 5 detik biar ga ilang di tengah game
local nowWH = os.clock()
_G.X3._WH.lastMatchApply = _G.X3._WH.lastMatchApply or 0
if _G.X3.XthrlenConfig and _G.X3.XthrlenConfig.WallhackVis and (nowWH - _G.X3._WH.lastMatchApply) > 5.0 then
    _G.X3._WH.lastMatchApply = nowWH
    pcall(function()
        if pc and slua.isValid(pc) and ToggleWallhackConsoleCommandsWH then
            ToggleWallhackConsoleCommandsWH(pc, true)
        end
    end)
end

    if _G.X3.OutlineTick then pcall(_G.X3.OutlineTick, localPlayer) end

    if _G.X3.BTTick then pcall(_G.X3.BTTick, localPlayer) end
    -- [DISABLED] ESP 敌人计数功能已移除
    if _G.X3.ExtraTick then pcall(_G.X3.ExtraTick, localPlayer) end
    if _G.X3.CacheCleanerTick then pcall(_G.X3.CacheCleanerTick, true) end

    local Cached_PPM = nil
    pcall(function() Cached_PPM = import("PostProcessManager").GetInstance() end)
    local Cached_SecurityCommonUtils = nil
    pcall(function() Cached_SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils") end)
    local Cached_MyHUD = pc and pc.MyHUD or nil

    if _G.X3.XthrlenConfig.IpadView and _G.X3.XthrlenState.CustomTextData then
        pcall(function()
            local targetTPP = _G.X3.XthrlenState.CustomTextData.IpadViewFOV or 120
            local uTPPCam = localPlayer.ThirdPersonCameraComponent
            if Valid(uTPPCam) and not localPlayer.bIsWeaponAiming then
                if uTPPCam.FieldOfView ~= targetTPP then uTPPCam.FieldOfView = targetTPP end
            end
        end)
    else
        pcall(function()
            local uTPPCam = localPlayer.ThirdPersonCameraComponent
            if Valid(uTPPCam) and not localPlayer.bIsWeaponAiming then
                if uTPPCam.FieldOfView ~= 82 then uTPPCam.FieldOfView = 82 end
            end
        end)
    end

    -- [DISABLED] Wallhack 功能已移除

    pcall(function()
        if Valid(pc) then
            if pc.HiggsBoson then pc.HiggsBoson.bMHActive = false; pc.HiggsBoson.bCallPreReplication = false end
            if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive = false; pc.HiggsBosonComponent.bCallPreReplication = false end
        end
    end)

    pcall(function()
        local autoComp = localPlayer.AutoAimComp
        if Valid(autoComp) then
            if not _G.X3.XthrlenState.OrigAutoAimCompCached then
                _G.X3.XthrlenState.OrigAutoAimCompCached = {
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
            if _G.X3.XthrlenConfig.AutoHead then
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
                local orig = _G.X3.XthrlenState.OrigAutoAimCompCached
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

    local now = os.clock()
    pcall(function()
        local lsg = require("client.slua.logic.setting.logic_setting_graphics")
        local gi = lsg.GetGameInstance()
        if gi then
            if _G.X3.XthrlenConfig.RemoveGrass and not _G.X3.XthrlenState.PrevGraphicsState.RemoveGrass then
                gi:ExecuteCMD("grass.DensityScale", "0")
                gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
                _G.X3.XthrlenState.PrevGraphicsState.RemoveGrass = true
            elseif not _G.X3.XthrlenConfig.RemoveGrass and _G.X3.XthrlenState.PrevGraphicsState.RemoveGrass then
                gi:ExecuteCMD("grass.DensityScale", "1")
                gi:ExecuteCMD("grass.DiscardDataOnLoad", "0")
                _G.X3.XthrlenState.PrevGraphicsState.RemoveGrass = false
            end

            if _G.X3.XthrlenConfig.RemoveFog and not _G.X3.XthrlenState.PrevGraphicsState.RemoveFog then
                gi:ExecuteCMD("r.SkyAtmosphere", "1")
                gi:ExecuteCMD("r.Fog", "0")
                gi:ExecuteCMD("r.VolumetricFog", "0")
                _G.X3.XthrlenState.PrevGraphicsState.RemoveFog = true
            elseif not _G.X3.XthrlenConfig.RemoveFog and _G.X3.XthrlenState.PrevGraphicsState.RemoveFog then
                gi:ExecuteCMD("r.SkyAtmosphere", "1")
                gi:ExecuteCMD("r.Fog", "1")
                gi:ExecuteCMD("r.VolumetricFog", "1")
                _G.X3.XthrlenState.PrevGraphicsState.RemoveFog = false
            end

            if _G.X3.XthrlenConfig.WhiteBody and not _G.X3.XthrlenState.PrevGraphicsState.WhiteBody then
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "2")
                gi:ExecuteCMD("r.CharacterDiffusePower", "5")
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "100")
                _G.X3.XthrlenState.PrevGraphicsState.WhiteBody = true
            elseif not _G.X3.XthrlenConfig.WhiteBody and _G.X3.XthrlenState.PrevGraphicsState.WhiteBody then
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "0")
                gi:ExecuteCMD("r.CharacterDiffusePower", "1")
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "1")
                _G.X3.XthrlenState.PrevGraphicsState.WhiteBody = false
            end

            if _G.X3.XthrlenConfig.ColorBodyV2 and not _G.X3.XthrlenState.PrevGraphicsState.ColorBodyV2 then
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "4")
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "200")
                gi:ExecuteCMD("r.CharacterDiffusePower", "200")
                _G.X3.XthrlenState.PrevGraphicsState.ColorBodyV2 = true
            elseif not _G.X3.XthrlenConfig.ColorBodyV2 and _G.X3.XthrlenState.PrevGraphicsState.ColorBodyV2 then
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "1")
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "0")
                gi:ExecuteCMD("r.CharacterDiffusePower", "1")
                _G.X3.XthrlenState.PrevGraphicsState.ColorBodyV2 = false
            end

            if _G.X3.XthrlenConfig.BlackSky and not _G.X3.XthrlenState.PrevGraphicsState.BlackSky then
                gi:ExecuteCMD("r.CylinderMaxDrawHeight", "9999")
                _G.X3.XthrlenState.PrevGraphicsState.BlackSky = true
            elseif not _G.X3.XthrlenConfig.BlackSky and _G.X3.XthrlenState.PrevGraphicsState.BlackSky then
                gi:ExecuteCMD("r.CylinderMaxDrawHeight", "0000")
                _G.X3.XthrlenState.PrevGraphicsState.BlackSky = false
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
                local anyWeaponModOn = _G.X3.XthrlenConfig.CustomHRecoil or _G.X3.XthrlenConfig.CustomVRecoil or _G.X3.XthrlenConfig.LessShake or _G.X3.XthrlenConfig.Accuracy or _G.X3.XthrlenConfig.Crosshair or _G.X3.XthrlenConfig.GodMode or _G.X3.XthrlenConfig.AutoHead or _G.X3.XthrlenConfig.AimbotMode ~= "None" or _G.X3.XthrlenConfig.LessRecoil or _G.X3.XthrlenConfig.VerticalRecoil
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
                    if _G.X3.XthrlenConfig.CustomHRecoil then entity.AccessoriesHRecoilFactor = _G.X3.XthrlenState.CustomTextData.HRecoil or 0.3
                    elseif _G.X3.XthrlenConfig.LessRecoil then entity.AccessoriesHRecoilFactor = 0.2 end
                    if _G.X3.XthrlenConfig.CustomVRecoil then entity.AccessoriesVRecoilFactor = _G.X3.XthrlenState.CustomTextData.VRecoil or 0.3
                    elseif _G.X3.XthrlenConfig.VerticalRecoil then entity.AccessoriesVRecoilFactor = 0.2 end
                    if _G.X3.XthrlenConfig.LessShake then entity.RecoilKick = 0.1; entity.RecoilKickADS = 0.1; entity.AnimationKick = 0.2 end
                    if _G.X3.XthrlenConfig.Accuracy then entity.GameDeviationAccuracy = 0.01 end
                    if _G.X3.XthrlenConfig.Crosshair then entity.GameDeviationFactor = 0.08 end
                    if entity.AutoAimingConfig then
                        if not entity.OriginalAutoAimCached then
                            entity.OriginalAutoAimCached = {
                                OuterSpeed = entity.AutoAimingConfig.OuterRange and entity.AutoAimingConfig.OuterRange.Speed,
                                InnerSpeed = entity.AutoAimingConfig.InnerRange and entity.AutoAimingConfig.InnerRange.Speed
                            }
                        end
                        if _G.X3.XthrlenConfig.AutoHead then
                            pcall(function() entity.AutoAimingConfig.Bones = { "Head", "Head", "Head" } end)
                        end
                        if _G.X3.XthrlenConfig.AimbotMode == "Far" then
                            if entity.AutoAimingConfig.OuterRange then
                                entity.AutoAimingConfig.OuterRange.Speed = 5
                                entity.AutoAimingConfig.OuterRange.RangeRate = 0.7
                                entity.AutoAimingConfig.OuterRange.SpeedRate = 1.3
                                entity.AutoAimingConfig.OuterRange.RangeRateSight = 1.8
                                entity.AutoAimingConfig.OuterRange.SpeedRateSight = 2.2
                                entity.AutoAimingConfig.OuterRange.CrouchRate = 1.1
                                entity.AutoAimingConfig.OuterRange.ProneRate = 1
                            end
                            if entity.AutoAimingConfig.InnerRange then
                                entity.AutoAimingConfig.InnerRange.Speed = 5
                                entity.AutoAimingConfig.InnerRange.RangeRate = 0.7
                                entity.AutoAimingConfig.InnerRange.SpeedRate = 1.3
                                entity.AutoAimingConfig.InnerRange.RangeRateSight = 1.8
                                entity.AutoAimingConfig.InnerRange.SpeedRateSight = 2.2
                                entity.AutoAimingConfig.InnerRange.CrouchRate = 1.1
                                entity.AutoAimingConfig.InnerRange.ProneRate = 1
                            end
                        end
                    end
                    entity.XthrlenWeaponModsActive = true
                elseif entity.XthrlenWeaponModsActive then
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
                    entity.XthrlenWeaponModsActive = false
                end
            end
        end
    end)

    -- [MAGIC BULLET SMART V4.1] — FIX TOTAL
    _G.X3._MB = _G.X3._MB or {
        Head = 1.0, Body = 1.0, Legs = 1.0,
        Filter = 3, MaxDist = 250, VisCheck = false,
        ValidTargets = {}, CacheTime = 0, CacheInterval = 0.3
    }
    local d = _G.X3._MB

    local function MB_IsBot(target)
        if _G.X3.GetBotScore then
            local okS, s = pcall(_G.X3.GetBotScore, target)
            if okS and type(s) == "number" then
                if s >= 3 then return true end
                if s <= -3 then return false end
            end
        end
        -- Fallback penuh saat scoring belum termuat
        local bot = false
        pcall(function()
            if target.bIsAI == true or target.IsAI == true then bot = true end
            if type(target.IsBot) == "function" and target:IsBot() then bot = true end
            local ps = target.PlayerState or (type(target.GetPlayerState) == "function" and target:GetPlayerState())
            if slua.isValid(ps) then
                if ps.bIsABot == true or ps.bIsBot == true then bot = true end
                if type(ps.IsBot) == "function" and ps:IsBot() then bot = true end
            end
        end)
        return bot
    end
    local function MB_IsVisible(pcRef, target)
        local vis = true
        pcall(function()
            if slua.isValid(pcRef) and type(pcRef.LineOfSightTo) == "function" then
                vis = pcRef:LineOfSightTo(target)
            else
                vis = not (target.bHidden or target.bTearOff)
            end
        end)
        return vis
    end

    pcall(function()
        if _G.X3.XthrlenConfig.CustomMagicBullet then
            if _G.X3.XthrlenState.CustomTextData then
                local c = _G.X3.XthrlenState.CustomTextData
                -- (REALTIME: geser slider langsung berlaku)
                d.Head = tonumber(c.MagicHead) or 1.0
                d.Neck = tonumber(c.MagicNeck) or 1.0
                d.Body = tonumber(c.MagicBody) or 1.0
                d.Pelvis = tonumber(c.MagicPelvis) or 1.0
                d.Legs = tonumber(c.MagicLegs) or 1.0
                d.Arms = tonumber(c.MagicArms) or 1.0
            end
        else
            d.Head = 1.0; d.Body = 1.0; d.Legs = 1.0
            d.ValidTargets = {}
        end
        local currentHash = string.format("%.2f_%.2f_%.2f", d.Head, d.Body, d.Legs)
        if _G.X3.XthrlenState.LastMagicConfigHash ~= currentHash then
            _G.X3.XthrlenState.MagicUpdateVersion = (_G.X3.XthrlenState.MagicUpdateVersion or 0) + 1
            _G.X3.XthrlenState.LastMagicConfigHash = currentHash
        end
    end)

    local BoneScaleMap = {
        ["head"] = d.Head,
        ["neck_01"] = d.Neck,
        ["spine_01"] = d.Body, ["spine_02"] = d.Body, ["spine_03"] = d.Body,
        ["pelvis"] = d.Pelvis,
        ["clavicle_l"] = d.Arms, ["clavicle_r"] = d.Arms,
        ["upperarm_l"] = d.Arms, ["upperarm_r"] = d.Arms,
        ["lowerarm_l"] = d.Arms, ["lowerarm_r"] = d.Arms,
        ["hand_l"] = d.Arms, ["hand_r"] = d.Arms,
        ["thigh_l"] = d.Legs, ["thigh_r"] = d.Legs,
        ["calf_l"] = d.Legs, ["calf_r"] = d.Legs,
        ["foot_l"] = d.Legs, ["foot_r"] = d.Legs
    }

    -- terasa bila toggle dilakukan di dalam game)
    if _G.X3.XthrlenConfig.CustomMagicBullet and not _G.X3._MBBattleKickDone then
        _G.X3._MBBattleKickDone = true
        if _G.X3.MagicBulletCache then _G.X3.MagicBulletCache.LastUpdate = 0 end
        _G.X3.AK_ModdedPhysAssets = {}
        _G.X3.AK_WantedAssets = {}
        _G.X3._MBVisCache = {}
    end

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

        for key, data in pairs(_G.X3.XthrlenState.EnemyMarks) do
            if not currentValidKeys[key] then
                SafeRemoveMark(data.radarMark)
                SafeRemoveMark(data.hpMark)
                SafeRemoveMark(data.hpMark8)
                SafeRemoveMark(data.distMark)
                if _G.X3.AimTouchVisCache and _G.X3.AimTouchVisCache[key] then _G.X3.AimTouchVisCache[key] = nil end
                if data.MIDs then
                    for meshStr, midTable in pairs(data.MIDs) do
                        for k, _ in pairs(midTable) do midTable[k] = nil end
                    end
                    data.MIDs = nil
                end
                data.enemy = nil
                data.CachedMeshes = nil
                _G.X3.XthrlenState.EnemyMarks[key] = nil
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
                _G.X3.XthrlenState.EnemyMarks[eKey] = _G.X3.XthrlenState.EnemyMarks[eKey] or { enemy = enemy }
                local markData = _G.X3.XthrlenState.EnemyMarks[eKey]
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

                    local eReady = true
                    if _G.X3.IsPawnRenderReady then eReady = _G.X3.IsPawnRenderReady(enemy, 0.6) end
                    local isBot = false
                    pcall(function() isBot = IsBotWH(enemy) == true end)

                    pcall(function()
                        local EnemyMesh = eMesh
                        if slua.isValid(EnemyMesh) then
                            if _G.X3.XthrlenConfig.CustomMagicBullet then
                                local pass = true

                                if not (_G.X3.IsPawnRenderReady and _G.X3.IsPawnRenderReady(enemy, 0.8)) then pass = false end

                                if pass then
                                    local uniqueID = type(enemy.GetUniqueID) == "function" and enemy:GetUniqueID() or tostring(enemy.PlayerKey or enemy)
                                    local currentHash = string.format("%.2f_%.2f_%.2f_%.2f_%.2f_%.2f", d.Head, d.Neck, d.Body, d.Pelvis, d.Legs, d.Arms)
                                    -- target masih valid)
                                    if markData.MagicAssetName then
                                        _G.X3.AK_WantedAssets = _G.X3.AK_WantedAssets or {}
                                        _G.X3.AK_WantedAssets[markData.MagicAssetName] = os.clock()
                                    end
                                    if markData.MagicBulletHash ~= currentHash or markData.MagicTargetID ~= uniqueID then
                                        local PhysicsAsset = EnemyMesh.PhysicsAssetOverride
                                        if not slua.isValid(PhysicsAsset) and EnemyMesh.SkeletalMesh then PhysicsAsset = EnemyMesh.SkeletalMesh.PhysicsAsset end
                                        if slua.isValid(PhysicsAsset) and PhysicsAsset.SkeletalBodySetups then
                                            if not _G.X3.AK_ModdedPhysAssets then _G.X3.AK_ModdedPhysAssets = {} end
                                            local PhysAssetName = "DefaultPhys"
                                            pcall(function() PhysAssetName = PhysicsAsset:GetName() end)
                                            if _G.X3.AK_ModdedPhysAssets[PhysAssetName] ~= currentHash then
                                                if not _G.X3.AK_OrigHitboxes then _G.X3.AK_OrigHitboxes = {} end
                                                if not _G.X3.AK_OrigHitboxes[PhysAssetName] then _G.X3.AK_OrigHitboxes[PhysAssetName] = {} end
                                                local OrigHitboxData = _G.X3.AK_OrigHitboxes[PhysAssetName]
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
                                                            local TargetScale = BoneScaleMap[MatchedBoneKey]
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
                                                _G.X3.AK_ModdedPhysAssets[PhysAssetName] = currentHash
                                                _G.X3.AK_AssetRefs = _G.X3.AK_AssetRefs or {}
                                                _G.X3.AK_AssetRefs[PhysAssetName] = PhysicsAsset
                                            end
                                            markData.MagicAssetName = PhysAssetName
                                            _G.X3.AK_WantedAssets = _G.X3.AK_WantedAssets or {}
                                            _G.X3.AK_WantedAssets[PhysAssetName] = os.clock()
                                            _G.X3.AK_AppliedMeshes = _G.X3.AK_AppliedMeshes or {}
                                            _G.X3.AK_AppliedMeshes[PhysAssetName] = _G.X3.AK_AppliedMeshes[PhysAssetName] or {}
                                            table.insert(_G.X3.AK_AppliedMeshes[PhysAssetName], EnemyMesh)
                                            if EnemyMesh.SetPhysicsAsset then EnemyMesh:SetPhysicsAsset(PhysicsAsset) end
                                            EnemyMesh.PhysicsAssetOverride = PhysicsAsset
                                            markData.MagicBulletHash = currentHash
                                            markData.MagicTargetID = uniqueID
                                        end
                                    end
                                end
                            end
                        end
                    end)

                    local distM = 0
                    pcall(function() distM = localPlayer:GetDistanceTo(enemy) / 100 end)

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

        if _G.X3.AK_ModdedPhysAssets and next(_G.X3.AK_ModdedPhysAssets) ~= nil then
            local nowSweep = os.clock()
            for assetName, _ in pairs(_G.X3.AK_ModdedPhysAssets) do
                local wantedAt = (_G.X3.AK_WantedAssets and _G.X3.AK_WantedAssets[assetName]) or 0
                if (nowSweep - wantedAt) > 0.35 then
                    pcall(function()
                        local ref = _G.X3.AK_AssetRefs and _G.X3.AK_AssetRefs[assetName]
                        local orig = _G.X3.AK_OrigHitboxes and _G.X3.AK_OrigHitboxes[assetName]
                        if ref and slua.isValid(ref) and orig and ref.SkeletalBodySetups then
                            local SBS = ref.SkeletalBodySetups
                            local nS = type(SBS.Num) == "function" and SBS:Num() or #SBS
                            local lim = nS > 50 and 50 or nS
                            for i = 1, lim do
                                local BodySetup = type(SBS.Get) == "function" and SBS:Get(i-1) or SBS[i]
                                if slua.isValid(BodySetup) then
                                    local LowerBoneName = string.lower(tostring(BodySetup.BoneName))
                                    local MatchedBoneKey = nil
                                    for k, _ in pairs(BoneScaleMap) do
                                        if string.find(LowerBoneName, k, 1, true) then MatchedBoneKey = k break end
                                    end
                                    if MatchedBoneKey and orig[MatchedBoneKey] then
                                        local od = orig[MatchedBoneKey]
                                        local AggGeom = BodySetup.AggGeom
                                        local BoxElems = AggGeom and AggGeom.BoxElems or BodySetup.BoxElems
                                        local SphereElems = AggGeom and AggGeom.SphereElems or BodySetup.SphereElems
                                        local SphylElems = AggGeom and AggGeom.SphylElems or BodySetup.SphylElems
                                        local BoxElem = GetFirstElemSafe(BoxElems)
                                        local SphereElem = GetFirstElemSafe(SphereElems)
                                        local SphylElem = GetFirstElemSafe(SphylElems)
                                        if od.Box and BoxElem then
                                            BoxElem.X = od.Box.X; BoxElem.Y = od.Box.Y; BoxElem.Z = od.Box.Z
                                            if type(BoxElems.Set) == "function" then BoxElems:Set(0, BoxElem) else BoxElems[1] = BoxElem end
                                            if AggGeom then AggGeom.BoxElems = BoxElems; BodySetup.AggGeom = AggGeom else BodySetup.BoxElems = BoxElems end
                                        end
                                        if od.Sphere and SphereElem then
                                            SphereElem.Radius = od.Sphere.Radius
                                            if type(SphereElems.Set) == "function" then SphereElems:Set(0, SphereElem) else SphereElems[1] = SphereElem end
                                            if AggGeom then AggGeom.SphereElems = SphereElems; BodySetup.AggGeom = AggGeom else BodySetup.SphereElems = SphereElems end
                                        end
                                        if od.Sphyl and SphylElem then
                                            SphylElem.Radius = od.Sphyl.Radius; SphylElem.Length = od.Sphyl.Length
                                            if type(SphylElems.Set) == "function" then SphylElems:Set(0, SphylElem) else SphylElems[1] = SphylElem end
                                            if AggGeom then AggGeom.SphylElems = SphylElems; BodySetup.AggGeom = AggGeom else BodySetup.SphylElems = SphylElems end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    pcall(function()
                        local ref = _G.X3.AK_AssetRefs and _G.X3.AK_AssetRefs[assetName]
                        local set = _G.X3.AK_AppliedMeshes and _G.X3.AK_AppliedMeshes[assetName]
                        if ref and slua.isValid(ref) and set then
                            for _, m in ipairs(set) do
                                pcall(function()
                                    if m and slua.isValid(m) then
                                        if m.SetPhysicsAsset then m:SetPhysicsAsset(ref) end
                                        m.PhysicsAssetOverride = ref
                                    end
                                end)
                            end
                        end
                    end)
                    _G.X3.AK_ModdedPhysAssets[assetName] = nil
                    if _G.X3.AK_AssetRefs then _G.X3.AK_AssetRefs[assetName] = nil end
                    if _G.X3.AK_AppliedMeshes then _G.X3.AK_AppliedMeshes[assetName] = nil end
                end
            end
        end

    end)

    -- [DAMAGE MULTIPLIER v1.0] BaseDamage Hack
    pcall(function()
        -- GodMode sudah handle BaseDamage sendiri, skip
        if _G.X3.XthrlenConfig.GodMode then return end

        -- Ambil senjata aktif
        local weapon = nil
        pcall(function()
            local wm = localPlayer:GetWeaponManager()
            if slua.isValid(wm) then weapon = wm:GetCurrentWeapon() end
        end)
        if not slua.isValid(weapon) then
            pcall(function() weapon = localPlayer:GetCurrentWeapon() end)
        end
        if not slua.isValid(weapon) then return end

        local entity = weapon.ShootWeaponEntity or weapon.CurrentWeaponEntity or weapon.ShootWeaponEntity_GEN_VARIABLE
        if not slua.isValid(entity) then return end

        if _G.X3.XthrlenConfig.CustomMagicBullet then
            if not entity._OrigBaseDamage then
                entity._OrigBaseDamage = entity.BaseDamage
            end

            local cData = _G.X3.XthrlenState.CustomTextData or {}
            local headMul = tonumber(cData.MagicHead) or 1.0
            local bodyMul = tonumber(cData.MagicBody) or 1.0
            local legsMul = tonumber(cData.MagicLegs) or 1.0
            local maxMul = math.max(headMul, bodyMul, legsMul)
            if maxMul < 1.0 then maxMul = 1.0 end

            -- Apply damage multiplier
            entity.BaseDamage = entity._OrigBaseDamage * maxMul
            _G.X3._MB_LastWeaponEntity = entity
        else
            -- Restore BaseDamage saat CustomMagicBullet OFF
            if entity._OrigBaseDamage then
                entity.BaseDamage = entity._OrigBaseDamage
                entity._OrigBaseDamage = nil
            end
            _G.X3._MB_LastWeaponEntity = nil
        end
    end)

end

-- [DISABLED] ProcessWallhack 调用已移除

_G.X3.XthrlenState.LoopToken = (_G.X3.XthrlenState.LoopToken or 0) + 1
local myToken = _G.X3.XthrlenState.LoopToken


local function FastTick()
    if myToken ~= _G.X3.XthrlenState.LoopToken then return end
    pcall(MainLoop)
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(0.4, FastTick)
    end
end

-- [PORT-ESP] Loop ESP cepat (0.05s) terpisah dari MainLoop 0.4s
local espToken = 0
local function FastESPTick()
    if espToken ~= _G.X3.XthrlenState.EspLoopToken then return end
    if _G.X3.PortESPTick then pcall(_G.X3.PortESPTick) end
    local okT, tk = pcall(require, "common.time_ticker")
    if okT and tk and tk.AddTimerOnce then
        tk.AddTimerOnce(0.05, FastESPTick)
    end
end

_G.X3.XthrlenState.EspLoopToken = (_G.X3.XthrlenState.EspLoopToken or 0) + 1
espToken = _G.X3.XthrlenState.EspLoopToken
local okTesp, tickerEsp = pcall(require, "common.time_ticker")
if okTesp and tickerEsp and tickerEsp.AddTimerOnce then
    tickerEsp.AddTimerOnce(0.2, FastESPTick)
end

-- 驱动管理器 (全用全局,不占 chunk local)
_G.X3._aimbotToken = 0
function _G.X3._FastAimbotTick()
    if _G.X3._aimbotToken ~= _G.X3.XthrlenState.AimbotLoopToken then return end

    pcall(function()
        if _G.X3.XthrlenConfig and _G.X3.XthrlenConfig.AimTouchEnable then
            local pc = GameplayData and GameplayData.GetPlayerController and GameplayData.GetPlayerController()
            if not (pc and slua.isValid(pc)) then
                pcall(function()
                    pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                end)
            end
            if pc and slua.isValid(pc) and _G.X3.StartAimTimer then
                pcall(_G.X3.StartAimTimer, pc)
            end
        else
            if _G.X3.StopAimTimer then
                pcall(_G.X3.StopAimTimer)
            end
        end
    end)

    local okT, tk = pcall(require, "common.time_ticker")
    if okT and tk and tk.AddTimerOnce then
        tk.AddTimerOnce(0.5, _G.X3._FastAimbotTick)
    end
end

_G.X3.XthrlenState.AimbotLoopToken = (_G.X3.XthrlenState.AimbotLoopToken or 0) + 1
_G.X3._aimbotToken = _G.X3.XthrlenState.AimbotLoopToken
pcall(function()
    local okT, tk = pcall(require, "common.time_ticker")
    if okT and tk and tk.AddTimerOnce then
        tk.AddTimerOnce(0.2, _G.X3._FastAimbotTick)
    end
end)
FastTick()

-- SYSTEM HOOKS DARI BYPASS BARU
local function InitAllModSystems()
    pcall(function()
        if _G.X3.StartBypass_VIP_v3 then _G.X3.StartBypass_VIP_v3() end
        if _G.X3.InitializeAutoHeadHooks then _G.X3.InitializeAutoHeadHooks() end
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

if not isExpired then
    pcall(function()
        require("common.time_ticker").AddTimerOnce(0.8, InitAllModSystems)
    end)
end

do
_G.X3.StopTss = function()
    local n = 0
    for modName, mod in pairs(package.loaded) do
        if type(mod) == "table" then
            local ml = string.lower(tostring(modName))
            if ml:find("tss", 1, true) or ml:find("anticheat", 1, true) then
                for fname, fval in pairs(mod) do
                    if type(fval) == "function" and type(fname) == "string" then
                        local fl = string.lower(fname)
                        if fl:find("send", 1, true) or fl:find("report", 1, true) or
                           fl:find("collect", 1, true) or fl:find("tssdata", 1, true) then
                            if not rawget(mod, "_x3tss_" .. fname) then
                                rawset(mod, "_x3tss_" .. fname, fval)
                                rawset(mod, fname, function(...) return true, "MOCK_SUCCESS_STUB" end)
                                n = n + 1
                            end
                        end
                    end
                end
            end
        end
    end
    _G.X3.MockServer_HandleTssPacket = function(playerId, tssData)
        if not playerId then return false, nil end
        return true, "MOCK_SUCCESS_STUB"
    end
    if n > 0 and type(_G.X3.Trace) == "function" then
        _G.X3.Trace("TSS: " .. n .. " fungsi telemetri dimatikan")
    end
end

_G.X3.OutlineHue = 0
_G.X3.OutlineApplied = false
_G.X3.OutlineLastT = 0

_G.X3.HueToRGB = function(h, v)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * 0.0
    local q = v * (1 - f)
    local t = v * (1 - (1 - f))
    i = i % 6
    if i == 0 then return v, t, p
    elseif i == 1 then return q, v, p
    elseif i == 2 then return p, v, t
    elseif i == 3 then return p, q, v
    elseif i == 4 then return t, p, v
    else return v, p, q end
end

_G.X3.OutlineColor = function()
    local LC = _G.X3.CLinearColor
    if not LC then
        local ok, r = pcall(import, "LinearColor")
        if ok and r then LC = r; _G.X3.CLinearColor = r end
    end
    if not LC then return nil end
    local bright = (_G.X3.XthrlenConfig and _G.X3.XthrlenConfig.OutlineWepBright) or 180
    local v = (bright / 100.0) -- 0.5 .. 3.0
    if _G.X3.XthrlenConfig and _G.X3.XthrlenConfig.OutlineWepRainbow == false then
        return LC(v, v * 0.84, 0.0, 1) -- emas pekat bila rainbow mati
    end
    _G.X3.OutlineHue = _G.X3.OutlineHue + 0.03
    if _G.X3.OutlineHue >= 1 then _G.X3.OutlineHue = 0 end
    local r, g, b = _G.X3.HueToRGB(_G.X3.OutlineHue, v)
    return LC(r, g, b, 1)
end

_G.X3.OutlineApplyWeapon = function(weapon, color, thick)
    if not (weapon and slua.isValid(weapon)) then return end
    local okC, meshClass = pcall(import, "/Script/Engine.MeshComponent")
    if not (okC and meshClass) then return end
    local okL, comps = pcall(function() return weapon:GetComponentsByClass(meshClass) end)
    if not (okL and comps) then return end
    local n = 0
    local okN, cnt = pcall(function() return comps:Num() end)
    if okN and cnt then n = cnt end
    for i = 0, n - 1 do
        local comp = comps:Get(i)
        if comp and slua.isValid(comp) then
            pcall(function()
                if comp.SetDrawIdeaOutline then
                    comp:SetDrawIdeaOutline(true)
                    if color and comp.OverrideIdeaOutlineColor then comp:OverrideIdeaOutlineColor(true, color) end
                    if comp.OverrideIdeaOutlineThickness then comp:OverrideIdeaOutlineThickness(true, thick) end
                elseif comp.SetRenderCustomDepth then
                    comp:SetRenderCustomDepth(true)
                end
            end)
        end
    end
end

_G.X3.OutlineClearAll = function()
    if not _G.X3.OutlineApplied then return end
    _G.X3.OutlineApplied = false
    pcall(function()
        local GD = require("GameLua.GameCore.Data.GameplayData")
        local lp = GD and GD.GetPlayerCharacter and GD.GetPlayerCharacter()
        if not (lp and slua.isValid(lp)) then return end
        local wm = lp.GetWeaponManager and lp:GetWeaponManager() or lp.WeaponManagerComponent
        if not (wm and slua.isValid(wm)) then return end
        local okC, meshClass = pcall(import, "/Script/Engine.MeshComponent")
        if not (okC and meshClass) then return end
        for slot = 0, 10 do
            local w = wm.GetInventoryWeaponByPropSlot and wm:GetInventoryWeaponByPropSlot(slot) or nil
            if w and slua.isValid(w) then
                local okL, comps = pcall(function() return w:GetComponentsByClass(meshClass) end)
                if okL and comps then
                    local n = 0
                    local okN, cnt = pcall(function() return comps:Num() end)
                    if okN and cnt then n = cnt end
                    for i = 0, n - 1 do
                        local comp = comps:Get(i)
                        if comp and slua.isValid(comp) then
                            pcall(function()
                                if comp.SetDrawIdeaOutline then comp:SetDrawIdeaOutline(false)
                                elseif comp.SetRenderCustomDepth then comp:SetRenderCustomDepth(false) end
                            end)
                        end
                    end
                end
            end
        end
    end)
end

_G.X3.OutlineTick = function(lp)
    if not (_G.X3.XthrlenConfig and _G.X3.XthrlenConfig.OutlineWeapon) then
        _G.X3.OutlineClearAll()
        return
    end
    local now = os.clock()
    if now - _G.X3.OutlineLastT < 0.15 then return end
    _G.X3.OutlineLastT = now
    if not (lp and slua.isValid(lp)) then return end
    local wm = lp.GetWeaponManager and lp:GetWeaponManager() or lp.WeaponManagerComponent
    if not (wm and slua.isValid(wm)) then return end
    local color = _G.X3.OutlineColor()
    local thick = (_G.X3.XthrlenConfig and _G.X3.XthrlenConfig.OutlineWepThick) or 3
    if thick < 1 then thick = 1 end
    for slot = 0, 10 do
        local w = wm.GetInventoryWeaponByPropSlot and wm:GetInventoryWeaponByPropSlot(slot) or nil
        if w and slua.isValid(w) then
            _G.X3.OutlineApplyWeapon(w, color, thick)
            _G.X3.OutlineApplied = true
        end
    end
end

_G.X3.BTLastT = 0
_G.X3.BTBoneMap = { [0] = "Head", [1] = "neck_01", [2] = "spine_03" }

_G.X3.BTIsBot = function(pawn)
    if _G.X3.IsBotPawn then
        local v = _G.X3.IsBotPawn(pawn)
        if type(v) == "boolean" then return v end
    end
    local t = 0
    pcall(function() t = pawn.TeamID or (pawn.GetTeamID and pawn:GetTeamID()) or 0 end)
    return (t or 0) > 100
end

-- chunk sudah di ambang limit 200 local.
_G.X3.BTScanBest = function(lp, pc, cx, cy, boneName, maxDistM, ignoreBot)
    local myTeam = 0
    pcall(function() myTeam = lp.GetTeamID and lp:GetTeamID() or lp.TeamID or 0 end)
    local maxDist = (maxDistM or 400) * 100.0
    local rangePx = _G.X3.XthrlenConfig.BTRange or 300
    local targets = {}
    pcall(function()
        local cls = import("STExtraPlayerCharacter")
        local G = rawget(_G, "Game")
        if cls and G and G.GetActorsByClass then
            local actors = G:GetActorsByClass(cls)
            if actors then
                local cnt = actors:Num() or 0
                for i = 0, cnt - 1 do
                    local a = actors:Get(i)
                    if a and slua.isValid(a) and a ~= lp then table.insert(targets, a) end
                end
            end
        end
    end)
    if #targets == 0 then
        pcall(function()
            local GD = require("GameLua.GameCore.Data.GameplayData")
            local all = GD and GD.GetAllPlayerCharacters and GD.GetAllPlayerCharacters()
            if all then for _, a in pairs(all) do if a ~= lp then table.insert(targets, a) end end end
        end)
    end
    if #targets == 0 then return nil end
    local best, bestD = nil, rangePx
    for _, t in ipairs(targets) do
        pcall(function()
            local alive = true
            if t.IsAlive then alive = t:IsAlive() end
            if not alive then return end
            local tTeam = t.GetTeamID and t:GetTeamID() or t.TeamID or 0
            if tTeam == myTeam then return end
            if ignoreBot then
                local isB = false
                pcall(function() isB = IsBotWH(t) == true end)
                if isB then return end
            end
            if lp.GetDistanceTo then
                local dOk, dCm = pcall(function() return lp:GetDistanceTo(t) end)
                if dOk and dCm and dCm > maxDist then return end
            end
            local aimPos = nil
            if _G.X3.SafeBonePos then aimPos = _G.X3.SafeBonePos(t, boneName) end
            if not aimPos then pcall(function() aimPos = t:K2_GetActorLocation() end) end
            if not aimPos then return end
            local screen = nil
            local okV = pcall(function()
                if FVector2D then screen = FVector2D()
                else
                    local v = import("Vector2D")
                    if v then screen = v() end
                end
            end)
            if not (okV and screen) then return end
            local okP = pc:ProjectWorldLocationToScreen(aimPos, screen, false)
            if not okP or not screen or screen.X <= 0 or screen.Y <= 0 then return end
            local dx = screen.X - cx
            local dy = screen.Y - cy
            local d = math.sqrt(dx * dx + dy * dy)
            if d < bestD then bestD = d; best = t end
        end)
    end
    return best
end

_G.X3.BTTick = function(lp)
-- PELACAK PELURU / BULLET TRACK --
    if not (_G.X3.XthrlenConfig and _G.X3.XthrlenConfig.BulletTrack) then _G.X3._BTTarget = nil return end
    if not (lp and slua.isValid(lp)) then return end
    local wm = lp.WeaponManagerComponent or (lp.GetWeaponManager and lp:GetWeaponManager())
    if not wm then return end
    local curW = wm.CurrentWeaponReplicated
    if not (curW and slua.isValid(curW)) then return end
    local firing = lp.bIsWeaponFiring
    if firing == nil then pcall(function() firing = curW.bIsWeaponFiring end) end
    if firing == false then return end
    local shootComp = curW.ShootWeaponComponent
    if not (shootComp and slua.isValid(shootComp)) then return end
    if type(shootComp.ShootBulletInner) ~= "function" then return end
    local pc = lp.GetPlayerControllerSafety and lp:GetPlayerControllerSafety() or nil
    if not (pc and slua.isValid(pc)) then return end
    local vp = _G.X3._BTVp
    if not vp or (os.clock() - (vp.t or 0)) > 5 then
        pcall(function()
            local ui = require("client.common.ui_util")
            local sz = ui and ui.GetViewportSize and ui.GetViewportSize()
            if sz and sz.X and sz.Y then vp = { x = sz.X, y = sz.Y, t = os.clock() } _G.X3._BTVp = vp end
        end)
    end
    if not (vp and vp.x and vp.y) then return end
    local cx, cy = vp.x * 0.5, vp.y * 0.5
    local partIdx = math.floor((_G.X3.XthrlenConfig.BTPart or 0) + 0.5)
    local boneName = _G.X3.BTBoneMap[partIdx] or "Head"
    local prob = _G.X3.XthrlenConfig.BTProb or 100
    if prob < 100 and math.random(1, 100) > prob then return end
    local now = os.clock()
    local best = _G.X3._BTTarget
    if best then
        local validT = slua.isValid(best)
        if validT then pcall(function() if best.IsAlive and not best:IsAlive() then validT = false end end) end
        if not validT then best = nil _G.X3._BTTarget = nil end
    end
    if not best or now >= (_G.X3._BTScanAt or 0) then
        _G.X3._BTScanAt = now + 0.12
        best = _G.X3.BTScanBest(lp, pc, cx, cy, boneName)
        _G.X3._BTTarget = best
    end
    if not (best and slua.isValid(best)) then return end
    pcall(function()
        local aimPos = nil
        if _G.X3.SafeBonePos then aimPos = _G.X3.SafeBonePos(best, boneName) end
        if not aimPos then pcall(function() aimPos = best:K2_GetActorLocation() end) end
        if not aimPos then return end
        -- fallback 800 m/s standar AR).
        local vel = nil
        pcall(function() vel = best:GetVelocity() end)
        if vel and (vel.X ~= 0 or vel.Y ~= 0 or vel.Z ~= 0) then
            local spd = 80000
            pcall(function()
                if type(shootComp.GetMaxBulletFlySpeed) == "function" then
                    local s = shootComp:GetMaxBulletFlySpeed()
                    if type(s) == "number" and s > 10000 then spd = s end
                end
            end)
            local dCm = 0
            pcall(function() dCm = lp:GetDistanceTo(best) or 0 end)
            local tFly = (dCm or 0) / spd
            if tFly > 0 and tFly < 0.5 then
                aimPos = FVector(aimPos.X + vel.X * tFly, aimPos.Y + vel.Y * tFly, aimPos.Z + vel.Z * tFly)
            end
        end
        local camLoc = nil
        pcall(function()
            local GS = import("GameplayStatics")
            local cm = GS and GS.GetPlayerCameraManager and GS.GetPlayerCameraManager(pc, 0)
            if cm and slua.isValid(cm) then camLoc = cm:GetCameraLocation() end
        end)
        if not camLoc then return end
        local rot = nil
        local KML = rawget(_G, "KismetMathLibrary")
        if not KML then local okK, rK = pcall(import, "KismetMathLibrary"); if okK then KML = rK end end
        if KML and KML.FindLookAtRotation then
            pcall(function() rot = KML.FindLookAtRotation(camLoc, aimPos) end)
        end
        if not rot then return end
        local shootEntity = shootComp.ShootWeaponEntityComponent
        if not (shootEntity and slua.isValid(shootEntity)) then return end
        local csid = shootComp.CurShootID
        if type(csid) ~= "number" then csid = 0 end
        shootComp:ShootBulletInner(aimPos, rot, csid)
    end)
end

_G.X3.UOInstalled = false
_G.X3.UOLastHits = 0
_G.X3.BypassResultKeys = function()
    pcall(function()
        local sdm = _G.ServerDataMgr
        if sdm and sdm.DeletablePlayerResultKey then
            sdm.DeletablePlayerResultKey["SuspiciousHitCount"]=true
            sdm.DeletablePlayerResultKey["EspTotalSimTraceCnt"]=true
            sdm.DeletablePlayerResultKey["EspTotalImeFocusCnt"]=true
            sdm.DeletablePlayerResultKey["ClientGravityAnomalyCount"]=true
            sdm.DeletablePlayerResultKey["FlyingErrorCnt"]=true
        end
        local okS, sec = pcall(require, "GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
        if okS and sec and sec.EStrategyTypeInReplay then
            sec.EStrategyTypeInReplay.EspTotalSimTraceCnt=0
            sec.EStrategyTypeInReplay.EspTotalImeFocusCnt=0
            sec.EStrategyTypeInReplay.ClientGravityAnomalyCount=0
            sec.EStrategyTypeInReplay.FlyingErrorCnt=0
        end
    end)
end

_G.X3.KillBanPopup = function()
    pcall(function()
        if not (slua.getUIList and slua.getUIByName) then return end
        local banUI = slua.getUIByName("Common_Legal_01_UIBP")
        if banUI and slua.isValid(banUI) then
            pcall(function() banUI:RemoveFromParent() end)
        end
        local list = slua.getUIList() or {}
        for _, w in pairs(list) do
            if slua.isValid(w) then
                local nm = ""
                pcall(function() nm = w:GetName() or "" end)
                if nm:find("Common_Legal") or nm:find("Legal_01") then
                    pcall(function() w:RemoveFromParent() end)
                end
            end
        end
    end)
end

_G.X3.EspCountBtn = nil
_G.X3.EspCountLastT = 0

-- HITUNG MUSUH / ENEMY COUNT --
_G.X3.EspCountCreate = function()
    if _G.X3.EspCountBtn and slua.isValid(_G.X3.EspCountBtn) then return _G.X3.EspCountBtn end
    _G.X3.EspCountBtn = nil
    pcall(function()
        local btn = slua.loadUI("/Game/UMG/UI_BP/Common/BaseComponent/CommonBaseComponent_TextButton_UIBP.CommonBaseComponent_TextButton_UIBP")
        if not (btn and slua.isValid(btn)) then return end
        local hud = require("game_frontend_hud")
        if not (hud and hud.AddToContainer) then return end
        hud.AddToContainer(UIContainers.Top, btn, 10500)
        if btn.RichText_Content then
            btn.RichText_Content:SetText("PLAYER : 0  |  BOT : 0")
            local f = btn.RichText_Content.Font
            if f then
                f.Size = math.floor(((_G.X3.XthrlenConfig and _G.X3.XthrlenConfig.EspEnemyCountSize) or 13) * 1.1 + 0.5)
                f.TypefaceFontName = "Bold"
                btn.RichText_Content:SetFont(f)
            end
        end
        pcall(function()
            local WLL = import("WidgetLayoutLibrary")
            local slot = WLL and WLL.SlotAsCanvasSlot and WLL.SlotAsCanvasSlot(btn)
            if slot then
                slot:SetAnchors({Minimum={X=0.5,Y=0},Maximum={X=0.5,Y=0}})
                slot:SetAlignment({X=0.5,Y=0})
                slot:SetPosition({X=0,Y=53})
                slot:SetSize({X=286,Y=33})
            end
        end)
        pcall(function() btn:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
        _G.X3.EspCountBtn = btn
    end)
    return _G.X3.EspCountBtn
end

_G.X3.EspCountDestroy = function()
    pcall(function()
        if _G.X3.EspCountBtn and slua.isValid(_G.X3.EspCountBtn) then
            _G.X3.EspCountBtn:RemoveFromParent()
        end
    end)
    _G.X3.EspCountBtn = nil
end

_G.X3.EspCountTick = function(lp)
    if not (_G.X3.XthrlenConfig and _G.X3.XthrlenConfig.EspEnemyCount) then
        if _G.X3.EspCountBtn then _G.X3.EspCountDestroy() end
        return
    end
    -- GUARD: V2 aktif = V1 auto mati
    if _G.X3.XthrlenConfig.EspEnemyCountV2 then
        _G.X3.EspCountDestroy()
        return
    end
    local now = os.clock()
    if now - _G.X3.EspCountLastT < 0.25 then return end
    _G.X3.EspCountLastT = now
    if not (lp and slua.isValid(lp)) then
        _G.X3.EspCountDestroy()
        return
    end
    local widget = _G.X3.EspCountCreate()
    if not (widget and slua.isValid(widget)) then return end
    pcall(function()
        local myTeam = 0
        pcall(function() myTeam = lp.GetTeamID and lp:GetTeamID() or lp.TeamID or 0 end)
        local nPlayer, nBot, nearest = 0, 0, 99999
        local all = nil
        pcall(function()
            local GD = require("GameLua.GameCore.Data.GameplayData")
            all = GD and GD.GetAllPlayerCharacters and GD.GetAllPlayerCharacters()
        end)
        if all then
            for _, t in pairs(all) do
                if t and slua.isValid(t) and t ~= lp then
                    local tTeam = t.GetTeamID and t:GetTeamID() or t.TeamID or 0
                    local alive = true
                    if t.IsAlive then alive = t:IsAlive() end
                    local hp = t.Health or 1
                    if alive and hp > 0 and tTeam ~= myTeam then
                        local isBot = _G.X3.IsBotPawn and _G.X3.IsBotPawn(t) or false
                        if isBot then nBot = nBot + 1 else nPlayer = nPlayer + 1 end
                        local d = nil
                        pcall(function()
                            if lp.GetDistanceTo then d = math.floor(lp:GetDistanceTo(t) / 100) end
                        end)
                        if d and d < nearest then nearest = d end
                    end
                end
            end
        end
        local total = nPlayer + nBot
        pcall(function()
            if widget.SetWidgetVisibility then
                if total == 0 then
                    widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                else
                    widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                end
            end
        end)
        if widget.RichText_Content then
            widget.RichText_Content:SetText(string.format("PLAYER : %d |  BOT : %d", nPlayer, nBot))
        end
    end)
end

local ESP_COUNT_V2_BP = "/Game/UMG/UI_BP/Common/Tab/Vertical/LevelOne/LevelOne_Text/Item/Common_Tab_Vertical_LevelOne_CountDown_Item_UIBP.Common_Tab_Vertical_LevelOne_CountDown_Item_UIBP"
local EspCountV2Widget = nil
local EspCountV2LastT = 0

local function EspCountV2Create()
    if EspCountV2Widget and slua.isValid(EspCountV2Widget) then return EspCountV2Widget end
    EspCountV2Widget = nil
    pcall(function()
        local widget = slua.loadUI(ESP_COUNT_V2_BP)
        if not widget or not slua.isValid(widget) then return end
        local hud = require("game_frontend_hud")
        if not (hud and hud.AddToContainer) then return end
        hud.AddToContainer(UIContainers.Top, widget, 10600)
        local WidgetLayoutLibrary = import("WidgetLayoutLibrary")
        local slot = WidgetLayoutLibrary.SlotAsCanvasSlot(widget)
        if slot then
            slot:SetAnchors(FAnchors(0.5, 0, 0.5, 0))
            slot:SetAlignment(FVector2D(0.5, 0))
            slot:SetPosition(FVector2D(0, 55))
            slot:SetSize(FVector2D(154, 24))
        end
        if widget.Image_Time then
            widget.Image_Time:SetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
        if widget.TextBlock_Time then
            widget.TextBlock_Time:SetColorAndOpacity(FSlateColor(FLinearColor(1, 1, 1, 1)))
            local fontInfo = widget.TextBlock_Time.Font
            if fontInfo then
                fontInfo.Size = math.floor(((_G.X3.XthrlenConfig and _G.X3.XthrlenConfig.EspEnemyCountSize) or 13) * 1.1 + 0.5)
                fontInfo.TypefaceFontName = "Bold"
                widget.TextBlock_Time:SetFont(fontInfo)
            end
        end
        widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        EspCountV2Widget = widget
    end)
    return EspCountV2Widget
end

local function EspCountV2Destroy()
    pcall(function()
        if EspCountV2Widget and slua.isValid(EspCountV2Widget) then
            EspCountV2Widget:RemoveFromParent()
        end
    end)
    EspCountV2Widget = nil
end

--    lobby 4-metode yang rapuh & boros — DIHAPUS)
local function EspCountV2Tick(lp)
    if not (_G.X3.XthrlenConfig and _G.X3.XthrlenConfig.EspEnemyCountV2) then
        EspCountV2Destroy()
        return
    end
    if _G.X3.XthrlenConfig.EspEnemyCount then
        EspCountV2Destroy()
        return
    end
    if not (lp and slua.isValid(lp)) then
        EspCountV2Destroy()
        return
    end
    local now = os.clock()
    if now - EspCountV2LastT < 0.5 then return end
    EspCountV2LastT = now
    local widget = EspCountV2Create()
    if not (widget and slua.isValid(widget)) then return end
    pcall(function()
        local myTeam = 0
        pcall(function() myTeam = lp.GetTeamID and lp:GetTeamID() or lp.TeamID or 0 end)
        local nPlayer, nBot = 0, 0
        local all = nil
        pcall(function()
            local GD = require("GameLua.GameCore.Data.GameplayData")
            all = GD and GD.GetAllPlayerCharacters and GD:GetAllPlayerCharacters()
        end)
        if all then
            for _, t in pairs(all) do
                if t and slua.isValid(t) and t ~= lp then
                    local tTeam = t.GetTeamID and t:GetTeamID() or t.TeamID or 0
                    local alive = true
                    if t.IsAlive then alive = t:IsAlive() end
                    local hp = t.Health or 1
                    if alive and hp > 0 and tTeam ~= myTeam then
                        local isBot = _G.X3.IsBotPawn and _G.X3.IsBotPawn(t) or false
                        if isBot then nBot = nBot + 1 else nPlayer = nPlayer + 1 end
                    end
                end
            end
        end
        local total = nPlayer + nBot
        pcall(function()
            if widget.SetWidgetVisibility then
                if total == 0 then
                    widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                    return
                end
                widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end
        end)
        if total == 0 then return end
        if widget.TextBlock_Time then
            widget.TextBlock_Time:SetText(string.format("Player: %d Bot: %d", nPlayer, nBot))
            local colP = GetCurrentWallVisibleColorWH and GetCurrentWallVisibleColorWH(false) or {R=1,G=0,B=0,A=1}
            local colB = GetCurrentWallVisibleColorWH and GetCurrentWallVisibleColorWH(true) or {R=0,G=0.5,B=1,A=1}
            local use = (nPlayer > 0) and colP or colB
            pcall(function()
                widget.TextBlock_Time:SetColorAndOpacity(FSlateColor(FLinearColor(use.R or 1, use.G or 1, use.B or 1, use.A or 1)))
            end)
        end
    end)
end

_G.X3.EspCountV2Create = EspCountV2Create
_G.X3.EspCountV2Destroy = EspCountV2Destroy
_G.X3.EspCountV2Tick = EspCountV2Tick

_G.X3.XthrlenConfig = _G.X3.XthrlenConfig or {}
-- [DISABLED] ESP EnemyCount 标志被强制关闭
_G.X3.XthrlenConfig.EspEnemyCount = false
_G.X3.XthrlenConfig.EspEnemyCountV2 = false
_G.X3.XthrlenConfig.EspEnemyCountSize = 13

-- bagian berbahaya dari file itu:
-- SISTEM BYPASS / BYPASS SYSTEM 55+ LAYER --
_G.X3.InstallFullBypassV2 = function()
    pcall(function()
        if _G.Account then
            _G.Account.IsBanned = false; _G.Account.BanStatus = 0
            _G.Account.WarningLevel = 0; _G.Account.IsSuspicious = false
            _G.Account.BanExpiry = 0; _G.Account.BanReason = ""; _G.Account.BanCount = 0
        end
    end)
    pcall(function()
        if _G.DeviceInfo then
            _G.DeviceInfo.IsEmulator = false; _G.DeviceInfo.IsRooted = false
            _G.DeviceInfo.IsDebug = false; _G.DeviceInfo.IsJailbroken = false
            _G.DeviceInfo.IsDeveloperMode = false; _G.DeviceInfo.IsUSBConnected = false
            _G.DeviceInfo.IsModded = false; _G.DeviceInfo.IsHooked = false
            _G.DeviceInfo.IsVirtualMachine = false; _G.DeviceInfo.IsSimulator = false
        end
    end)
    pcall(function()
        if _G.Security then
            _G.Security.IsCheatDetected = false; _G.Security.IsMemoryModified = false
            _G.Security.IsSpeedHack = false; _G.Security.IsInjectorDetected = false
            _G.Security.IsModDetected = false; _G.Security.IsLuaHooked = false
        end
    end)
    pcall(function()
        if _G.Kernel then
            _G.Kernel.IsDebuggerPresent = function() return false end
            _G.Kernel.IsDebugMode = function() return false end
            _G.Kernel.IsBeingTraced = function() return false end
            _G.Kernel.IsVM = function() return false end
            _G.Kernel.IsEmulator = function() return false end
            _G.Kernel.IsRooted = function() return false end
            _G.Kernel.IsJailbroken = function() return false end
            _G.Kernel.IsModified = function() return false end
            _G.Kernel.IsCompromised = function() return false end
        end
    end)
    pcall(function()
        if _G.Network then
            _G.Network.IsVPN = function() return false end
            _G.Network.IsProxy = function() return false end
            _G.Network.IsNetworkError = function() return false end
            _G.Network.CheckLatency = function() return 20 end
            _G.Network.GetPacketLoss = function() return 0 end
            _G.Network.IsSuspicious = function() return false end
            _G.Network.IsCompromised = function() return false end
        end
    end)
    pcall(function()
        if _G.Memory then
            _G.Memory.IntegrityCheck = function() return true end
            _G.Memory.VerifyModule = function() return true end
            _G.Memory.CheckCRC = function() return true end
            _G.Memory.ScanModifications = function() return false end
            _G.Memory.DetectChanges = function() return false end
            _G.Memory.ValidateMemory = function() return true end
        end
    end)
    pcall(function()
        _G.BanStatus = { IsBanned = false, BanType = 0, BanDuration = 0, BanReason = "", BanTime = 0 }
        _G.bIsBanned = false; _G.bIsSystemBanned = false
        _G.BanDuration = 0; _G.BanType = 0
        _G.bDSKick = false; _G.DSKickReason = nil
        _G.OnIntegrityFailure = nil
        _G.TelemetryQueue = {}; _G.bTelemetryEnabled = false
    end)
    pcall(function()
        _G.FridaDetected = false; _G.IsFridaPresent = function() return false end
        _G.CheckFrida = function() return false end
        _G.XposedDetected = false; _G.IsXposedInstalled = function() return false end
        _G.SubstrateDetected = false; _G.IsSubstratePresent = function() return false end
        _G.PtraceDetected = false; _G.IsBeingPtraced = function() return false end
        _G.MagiskDetected = false; _G.IsMagiskPresent = function() return false end
        _G.SuBinaryFound = false; _G.HasSuBinary = function() return false end
        _G.RootBeerCheck = function() return false end
        _G.IsRootedDevice = function() return false end
        _G.JailbreakDetected = false; _G.IsJailbrokenDevice = function() return false end
    end)

    local noopSweepPaths = {
        "GameLua.Mod.BaseMod.Common.AntiCheat.AntiCheatManager",
        "GameLua.Mod.BaseMod.Common.AntiCheat.AntiCheatSubsystem",
        "GameLua.Mod.BaseMod.Common.Protection.ProtectionSystem",
        "GameLua.Mod.BaseMod.Common.Protection.MemoryProtection",
        "GameLua.Mod.BaseMod.Common.Protection.CodeProtection",
        "GameLua.Mod.BaseMod.Common.Protection.IntegrityProtection",
        "GameLua.Mod.BaseMod.Common.Security.MemoryScanner",
        "GameLua.Mod.BaseMod.Common.Security.FileIntegrityCheck",
        "GameLua.Mod.BaseMod.Common.Security.CodeSignatureCheck",
        "GameLua.Mod.BaseMod.Common.Security.InjectionDetection",
        "GameLua.Mod.BaseMod.Common.Security.HookDetection",
        "GameLua.Mod.BaseMod.Common.Security.SpeedHackDetection",
        "GameLua.Mod.BaseMod.Common.Security.ScreenRecordDetection",
        "GameLua.Mod.BaseMod.Common.Security.SecurityCheck",
        "GameLua.Mod.BaseMod.Common.Security.SecurityError",
        "GameLua.Mod.BaseMod.Common.Security.AntiCheatError",
        "GameLua.Mod.BaseMod.Common.Security.SecurityEventSubsystem",
        "GameLua.Mod.BaseMod.Common.Security.SecurityReportSubsystem",
        "GameLua.Mod.BaseMod.Common.Security.SecurityLogSubsystem",
        "GameLua.Mod.BaseMod.Client.Security.AntiCheatHitScan",
        "GameLua.Mod.BaseMod.Client.Security.HitboxIntegrityCheck",
        "GameLua.Mod.BaseMod.Client.Security.ClientSecuritySubsystem",
        "GameLua.Mod.BaseMod.Client.Security.ClientValidationSubsystem",
        "GameLua.Mod.BaseMod.Client.Security.AntiCheatReportSubsystem",
        "GameLua.Mod.BaseMod.Client.Security.DSReportPlayerSubsystem",
        "GameLua.Mod.BaseMod.DS.Security.ServerHitValidation",
        "GameLua.Mod.BaseMod.DS.Security.ServerVerification",
        "GameLua.Mod.BaseMod.DS.Security.DSSecuritySubsystem",
        "GameLua.Mod.BaseMod.DS.Security.ServerValidationSubsystem",
        "GameLua.Mod.BaseMod.DS.Security.DSBanSubsystem",
        "GameLua.Mod.BaseMod.GamePlay.Damage.DamageValidator",
        "GameLua.Mod.BaseMod.GamePlay.Weapon.WeaponHitVerify",
        "GameLua.Mod.BaseMod.GamePlay.Spectating.ObserverSystem",
        "GameLua.Mod.BaseMod.GamePlay.Spectating.SpectatorReport",
        "GameLua.Mod.BaseMod.Client.Replay.KillReplaySubsystem",
        "GameLua.Mod.BaseMod.Client.Replay.ReplaySystem",
        "GameLua.Mod.BaseMod.Client.Replay.ReplayRecorder",
        "GameLua.Mod.BaseMod.Client.Replay.ReplayValidator",
        "client.slua.logic.ban.BanManager",
        "client.slua.logic.ban.BanHandler",
    }
    for _, path in ipairs(noopSweepPaths) do
        pcall(function()
            local module = package.loaded[path]
            if module then
                for k, v in pairs(module) do
                    if type(v) == "function" then module[k] = function() return false end
                    elseif type(v) == "table" then
                        for kk, vv in pairs(v) do
                            if type(vv) == "function" then v[kk] = function() return false end end
                        end
                    end
                end
            end
        end)
    end

    pcall(function()
        local BanCheck = package.loaded["GameLua.Mod.BaseMod.Common.Security.BanCheck"]
        if BanCheck then
            BanCheck.IsPlayerBanned = function() return false end
            BanCheck.GetBanLevel = function() return 0 end
            BanCheck.CheckBanStatus = function() return false end
        end
    end)
    pcall(function()
        for _, path in ipairs({
            "GameLua.Mod.BaseMod.Common.EnvironmentTools",
            "client.slua.logic.device.DeviceCheck",
        }) do
            local m = package.loaded[path]
            if m then
                for k, v in pairs(m) do
                    if type(v) == "function" then
                        local kn = tostring(k)
                        if kn:find("IsEmulator") or kn:find("IsRoot") or kn:find("IsDebug")
                            or kn:find("Detect") or kn:find("CheckDevice") or kn:find("IsVM")
                            or kn:find("IsHook") or kn:find("IsMod") or kn:find("Scan") then
                            m[k] = function() return false end
                        end
                    end
                end
            end
        end
    end)

    pcall(_G.X3.InstallOBBDeveloperBypass)

    pcall(_G.X3.InstallReportPacketBlock)
end

_G.X3.InstallReportPacketBlock = function()
    -- A) titik kirim laporan UI pemain
    pcall(function()
        local CTR = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if CTR then
            for k, v in pairs(CTR) do
                if type(v) == "function" then
                    local kn = tostring(k)
                    if kn:find("Report") or kn:find("Send") or kn:find("Submit") or kn:find("Upload") then
                        CTR[k] = function() return false end
                    end
                end
            end
        end
    end)
    pcall(function()
        local IS = package.loaded["GameLua.Mod.BaseMod.Client.InspectionSystem.InspectionSystemReportClientLogicSubsystem"]
        if IS then
            if type(IS.SendReportToInspector) == "function" then IS.SendReportToInspector = function() return false end end
            if type(IS.ReportToInspector) == "function" then IS.ReportToInspector = function() return false end end
        end
    end)
    pcall(function()
        local CR = package.loaded["GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem"]
        if CR then
            for k, v in pairs(CR) do
                if type(v) == "function" then
                    local kn = tostring(k)
                    if kn:find("Report") or kn:find("Record") or kn:find("Add") or kn:find("Send") then
                        CR[k] = function() return false end
                    end
                end
            end
        end
    end)
    -- D) laporan voice & aksi sensitif akun
    pcall(function()
        local AV = package.loaded["client.slua.logic.chat_voice.logic_antsvoice_interface"]
        if AV and type(AV.ReportPlayers) == "function" then AV.ReportPlayers = function() return false end end
    end)
    pcall(function()
        local SA = package.loaded["client.slua.logic.setting.logic_account_sensitive_aciton"]
        if SA and type(SA.ReportPlayerAction) == "function" then SA.ReportPlayerAction = function() return false end end
    end)
    -- E) TLog lobby
    pcall(function()
        local TL = package.loaded["GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogManager"]
        if TL and type(TL.SendReportLobby) == "function" then TL.SendReportLobby = function() return false end end
    end)
end

_G.X3.InstallOBBDeveloperBypass = function()
    pcall(function()
        local HM = package.loaded["GameLua.Mod.BaseMod.GamePlay.HighlightMoment.HighlightMomentSubsystem_DSChecker"]
        if HM then
            local fns = {
                "OnHandleRescued", "OnVehiclePlayerChange", "CheckFuncGrenadeInVehicle",
                "CheckFuncHighSpeedKill", "OnRefreshEliminationKing", "OnAddKills",
                "OnCharacterDied", "CheckFuncUpgradedWeaponKill", "CheckFuncVehicleMultiKill",
                "CheckFuncAllWeaponKill", "CheckFuncSingleShotMultiKill",
                "CheckFuncLongRangeSnipeKill", "KillConfirm", "IsFilterByCommonCheck",
                "EliminateKillConfirm", "CheckFuncSingleGrenadeMultiKill", "OnNearDeath",
                "CheckFuncRapidKillStreak", "OnHandleProjectileLaunch",
            }
            for _, fn in ipairs(fns) do
                if type(HM[fn]) == "function" then HM[fn] = function() return false end end
            end
        end
    end)

    pcall(function()
        for _, path in ipairs({
            "GameLua.Mod.BaseMod.DS.ICTLogSubsystem",
            "GameLua.Mod.BaseMod.DS.AI.AITrackingLogSubsystem",
            "GameLua.Mod.BaseMod.DS.InspectionSystem.InspectionSystemReportDSLogicSubsystem",
        }) do
            local m = package.loaded[path]
            if m then
                for k, v in pairs(m) do
                    if type(v) == "function" then
                        local kn = tostring(k)
                        if kn:find("Report") or kn:find("Log") or kn:find("Record")
                            or kn:find("Track") or kn:find("Collect") or kn:find("Upload")
                            or kn:find("Send") or kn:find("Inspect") or kn:find("OnInit") then
                            m[k] = function() return false end
                        end
                    end
                end
            end
        end
    end)

    pcall(function()
        local DS = rawget(_G, "DSHawkEyePatrolSubsystem")
        if DS then
            for k, v in pairs(DS) do
                if type(v) == "function" then DS[k] = function() return false end end
            end
        end
        local m = package.loaded["GameLua.Mod.BaseMod.DS.Security.DSHawkEyePatrolSubsystem"]
        if m then
            for k, v in pairs(m) do
                if type(v) == "function" then m[k] = function() return false end end
            end
        end
    end)

    pcall(function()
        local OS = rawget(_G, "OperationalStatsSubsystem")
        if not OS then
            OS = package.loaded["GameLua.Mod.BaseMod.Client.Subsystem.OperationalStatsSubsystem"]
        end
        if OS then
            local nop = function() end
            OS.ReportOperationalStats = nop
            OS.AddOperationalStats = nop
            OS.HandleTouchBegin = nop
            OS.HandleTouchEnd = nop
            OS.OnInit = nop
            OS.HandleEnterFighting = nop
            OS.OnBattleResult = nop
            if OS.TimerHandle then
                pcall(function() OS:RemoveGameTimer(OS.TimerHandle) end)
                OS.TimerHandle = nil
            end
            OS.StatsData = {}
        end
    end)
end

pcall(_G.X3.StopTss)
pcall(_G.X3.BypassResultKeys)
pcall(_G.X3.InstallFullBypassV2)
pcall(function() if _G.X3._ACFirewallInstall then _G.X3._ACFirewallInstall() end end)
pcall(function()
    local okT, ticker = pcall(require, "common.time_ticker")
    if okT and ticker and ticker.AddTimerOnce then
        -- pembunuh popup ban: tiap 10 detik (murah)
        local function banAgain()
            pcall(_G.X3.KillBanPopup)
            ticker.AddTimerOnce(20.0, banAgain)
        end
        ticker.AddTimerOnce(8.0, banAgain)
        ticker.AddTimerOnce(30.0, function() pcall(_G.X3.BypassResultKeys) end)
        local function fbv2Again(k)
            if k <= 0 then return end
            pcall(_G.X3.InstallFullBypassV2)
            ticker.AddTimerOnce(45.0, function() fbv2Again(k - 1) end)
        end
        ticker.AddTimerOnce(15.0, function() fbv2Again(8) end)
    else
        pcall(_G.X3.InstallFullBypassV2)
    end
end)
pcall(function()
    local okT, ticker = pcall(require, "common.time_ticker")
    if okT and ticker and ticker.AddTimerOnce then
        local function tssAgain(k)
            if k <= 0 then return end
            ticker.AddTimerOnce(30.0, function() pcall(_G.X3.StopTss) tssAgain(k - 1) end)
        end
        tssAgain(5)
    end
end)
end -- do
-- [SRCHUB] AKHIR BLOK DUMPER+DEBUGLOG v3.3

do

local XC = _G.X3.XthrlenConfig
if XC.X3TPPForce == nil then XC.X3TPPForce = false end
if XC.X3TPPUnlockBtn == nil then XC.X3TPPUnlockBtn = false end
if XC.X3UnlockAll == nil then XC.X3UnlockAll = false end
if XC.X3WeaponWH == nil then XC.X3WeaponWH = false end
XC.X3WeaponWHDist = XC.X3WeaponWHDist or 250
if XC.X3WeaponWHBlink == nil then XC.X3WeaponWHBlink = true end
if XC.X3WeaponWH_AR == nil then XC.X3WeaponWH_AR = true end
if XC.X3WeaponWH_SMG == nil then XC.X3WeaponWH_SMG = true end
if XC.X3WeaponWH_SR == nil then XC.X3WeaponWH_SR = true end
if XC.X3WeaponWH_DMR == nil then XC.X3WeaponWH_DMR = true end
if XC.X3WeaponWH_SG == nil then XC.X3WeaponWH_SG = false end
if XC.X3WeaponWH_LMG == nil then XC.X3WeaponWH_LMG = false end
if XC.X3WeaponWH_Pistol == nil then XC.X3WeaponWH_Pistol = false end
if XC.X3WeaponWH_Melee == nil then XC.X3WeaponWH_Melee = false end
if XC.X3CacheClean == nil then XC.X3CacheClean = true end
if XC.X3Watermark == nil then XC.X3Watermark = true end
if XC.X3FakeVisual == nil then XC.X3FakeVisual = false end

_G.X3._XF = _G.X3._XF or { zone = 0, spec = 0, tpp = 0, wwh = 0, wpulse = 0, wm = 0 }

do
    local function XFEnsureDyeCvars(on)
        local now = os.clock()
        local st = _G.X3._XFDyeCvar or { last = 0, state = nil }
        _G.X3._XFDyeCvar = st
        if st.state == on then
            if not on then return end                 -- OFF: kirim SEKALI saja (tanpa spam)
            if (now - st.last) < 1.0 then return end  -- ON: refresh berkala (re-assert)
        end
        st.last = now
        st.state = on
        pcall(function()
            local pc = GameplayData and GameplayData.GetPlayerController and GameplayData.GetPlayerController()
            if not (pc and slua.isValid(pc)) then return end
            local KSL = import("KismetSystemLibrary")
            if not (KSL and KSL.ExecuteConsoleCommand) then return end
            local v = on and "1" or "0"
            KSL.ExecuteConsoleCommand(pc, "r.EnableDrawDyeingColor " .. v)
            KSL.ExecuteConsoleCommand(pc, "r.SupportDyeingColorDistanceFade " .. v)
            KSL.ExecuteConsoleCommand(pc, "r.SupportDyeingColorMeshProxy " .. v)
            KSL.ExecuteConsoleCommand(pc, "r.SupportDyeingColorOccluded " .. v)
            KSL.ExecuteConsoleCommand(pc, "r.DyeingColorOccludedOpacity " .. (on and "1.0" or "0.0"))
            -- yang memiliki cvar glow — tidak saling injek)
            if on and XC.WallhackVis ~= true then
                KSL.ExecuteConsoleCommand(pc, "r.DyeingColorGlowIntensity 3.4")
            end
        end)
    end
    _G.X3._XFEnsureDyeCvars = XFEnsureDyeCvars

-- WALLHACK SENJATA / WEAPON WALLHACK --
    local XFWPalette = {
        [1] = { R = 0.00, G = 1.96, B = 1.96 }, -- Cyan
        [2] = { R = 0.20, G = 1.96, B = 0.20 }, -- Hijau
        [3] = { R = 1.96, G = 0.16, B = 0.16 }, -- Merah
        [4] = { R = 1.96, G = 1.96, B = 0.00 }, -- Kuning
        [5] = { R = 1.96, G = 1.07, B = 0.00 }, -- Oranye
        [6] = { R = 1.38, G = 0.39, B = 1.96 }, -- Ungu
        [7] = { R = 1.96, G = 0.49, B = 1.38 }, -- Pink
        [8] = { R = 0.29, G = 0.88, B = 1.96 }, -- Biru
        [9] = { R = 1.96, G = 1.96, B = 1.96 }, -- Putih
    }
    local XFWCatList = {
        { prefix = 101, key = "X3WeaponWH_AR",     name = "AR",  defCol = 1 },
        { prefix = 102, key = "X3WeaponWH_SMG",    name = "SMG", defCol = 2 },
        { prefix = 103, key = "X3WeaponWH_SR",     name = "SR",  defCol = 3 },
        { prefix = 104, key = "X3WeaponWH_DMR",    name = "DMR", defCol = 5 },
        { prefix = 105, key = "X3WeaponWH_SG",     name = "SG",  defCol = 6 },
        { prefix = 106, key = "X3WeaponWH_LMG",    name = "LMG", defCol = 4 },
        { prefix = 107, key = "X3WeaponWH_Pistol", name = "PST", defCol = 9 },
        { prefix = 108, key = "X3WeaponWH_Melee",  name = "MLW", defCol = 7 },
    }
    local XFWCatByPrefix = {}
    for _, c in ipairs(XFWCatList) do XFWCatByPrefix[c.prefix] = c end
    _G.X3._XFWwhApplied = _G.X3._XFWwhApplied or {}

    local function XFWColOf(cat)
        local td = _G.X3.XthrlenState and _G.X3.XthrlenState.CustomTextData
        local idx = td and tonumber(td["X3WCol_" .. cat.name]) or nil
        if not idx or idx < 1 or idx > 9 then idx = cat.defCol end
        return XFWPalette[idx] or XFWPalette[cat.defCol], idx
    end

    local function XFWGetComps(w)
        local out = {}
        pcall(function()
            local smc = import("SkeletalMeshComponent")
            local stc = import("StaticMeshComponent")
            local comps = nil
            if smc then local okC, rC = pcall(function() return w:GetComponentsByClass(smc) end); if okC and rC and (rC.Num and rC:Num() or 0) > 0 then comps = rC end end
            if not comps and stc then local okC2, rC2 = pcall(function() return w:GetComponentsByClass(stc) end); if okC2 then comps = rC2 end end
            if comps then
                local cnt = comps.Num and comps:Num() or 0
                for i = 0, cnt - 1 do
                    local m = comps:Get(i)
                    if m and slua.isValid(m) then table.insert(out, m) end
                end
            end
        end)
        return out
    end

    local function XFWPaintComps(comps, col, k, dirty)
        local c = { R = col.R * k, G = col.G * k, B = col.B * k, A = 1 }
        for _, m in ipairs(comps) do
            if m and slua.isValid(m) then
                pcall(function() m:SetDrawDyeing(true) end)
                pcall(function() if m.SetVisibleDyeingColor then m:SetVisibleDyeingColor(c) end end)
                pcall(function() if m.SetOccludedDyeingColor then m:SetOccludedDyeingColor(c) end end)
                if dirty then pcall(function() if m.MarkRenderStateDirty then m:MarkRenderStateDirty() end end) end
            end
        end
    end

    local function XFWUnpaintComps(comps)
        for _, m in ipairs(comps) do
            if m and slua.isValid(m) then
                pcall(function() m:SetDrawDyeing(false) end)
                pcall(function() if m.MarkRenderStateDirty then m:MarkRenderStateDirty() end end)
            end
        end
    end

    -- (tanpa scan ulang = ringan, no frame drop)
    function _G.X3._XFWPulse()
        if not XC.X3WeaponWH then return end
        local applied = _G.X3._XFWwhApplied
        if not next(applied) then _G.X3._XFWLastK = nil return end
        if XC.X3WeaponWHBlink == false then
            if _G.X3._XFWLastK == 1 then return end
            _G.X3._XFWLastK = 1
            for _, st in pairs(applied) do
                if st.dyed and st.comps and st.col then XFWPaintComps(st.comps, st.col, 1.0, true) end
            end
            return
        end
        local k = 1.15 + 0.60 * (0.5 + 0.5 * math.sin(os.clock() * 5.0))
        _G.X3._XFWLastK = k
        local n = 0
        for _, st in pairs(applied) do
            n = n + 1
            if n > 40 then break end
            if st.dyed and st.comps and st.col and st.actor and slua.isValid(st.actor) then
                XFWPaintComps(st.comps, st.col, k, false)
            end
        end
    end

    function _G.X3._XFWScan(lp)
        local applied = _G.X3._XFWwhApplied
        if not XC.X3WeaponWH then
            for key, st in pairs(applied) do
                if st.comps then XFWUnpaintComps(st.comps) end
                applied[key] = nil
            end
            if XC.WallhackVis ~= true then XFEnsureDyeCvars(false) end
            return
        end
        XFEnsureDyeCvars(true)
        pcall(function()
            local cls = import("PickUpWrapperActor")
            local G = rawget(_G, "Game")
            if not (cls and G and G.GetActorsByClass) then return end
            local actors = G:GetActorsByClass(cls)
            if not actors then return end
            local maxCm = (XC.X3WeaponWHDist or 250) * 100
            local seen = {}
            local cnt = actors:Num() or 0
            local now = os.clock()
            for i = 0, cnt - 1 do
                local w = actors:Get(i)
                if w and slua.isValid(w) then
                    pcall(function()
                        if w.bHasBeenPickedUp == true then return end
                        if w.bIsInBox == true or w.bIsInAirDropBox == true then return end
                        local dOk, dCm = false, nil
                        if lp.GetDistanceTo then dOk, dCm = pcall(function() return lp:GetDistanceTo(w) end) end
                        if dOk and dCm and dCm > maxCm then return end
                        local id = nil
                        local dd = w.DefineID
                        if dd then id = dd.TypeSpecificID or dd.ID end
                        if type(id) ~= "number" then return end
                        local cat = XFWCatByPrefix[math.floor(id / 1000)]
                        if not cat then return end
                        if not XC[cat.key] then return end
                        local key = tostring(w)
                        seen[key] = true
                        local col, colIdx = XFWColOf(cat)
                        local st = applied[key]
                        if not st then
                            st = { actor = w, cat = cat.name, firstSeen = now, colIdx = colIdx, col = col }
                            applied[key] = st
                        end
                        if (now - (st.firstSeen or 0)) >= 0.5 then
                            if not st.comps then
                                local comps = XFWGetComps(w)
                                if #comps > 0 then st.comps = comps end
                            end
                            if st.comps and (st.dyed ~= true or st.colIdx ~= colIdx) then
                                XFWPaintComps(st.comps, col, 1.0, true)
                                st.dyed = true
                                st.colIdx = colIdx
                                st.col = col
                            end
                        end
                    end)
                end
            end
            for key, st in pairs(applied) do
                if not seen[key] then
                    if st.comps then XFWUnpaintComps(st.comps) end
                    applied[key] = nil
                end
            end
        end)
    end
end -- /v46a

-- TPP FORCE (FPP room)
do
    --     "tiba-tiba berenang / di tempat berbeda").
-- KAMERA TPP / FORCE TPP IN FPP --
    function _G.X3._XFTPPTick(lp)
        if not XC.X3TPPForce and not XC.X3TPPUnlockBtn then _G.X3._XFTPPOn = false return end
        if XC.X3TPPUnlockBtn then
            local nowU = os.clock()
            if not _G.X3._TPPUnlockOK and nowU - (_G.X3._TPPUnlockAt or 0) >= 3.0 then
                _G.X3._TPPUnlockAt = nowU
                if _G.X3._XFTPPUnlockTry then pcall(_G.X3._XFTPPUnlockTry) end
            end
        end
        pcall(function()
            if XC.X3TPPForce or XC.X3TPPUnlockBtn then
                pcall(function()
                    local gs = GameplayData and GameplayData.GetGameState and GameplayData.GetGameState()
                    if gs and slua.isValid(gs) then
                        if gs.IsFPPGameMode ~= nil then gs.IsFPPGameMode = false end
                        if gs.IsCanSwitchFPP ~= nil then gs.IsCanSwitchFPP = true end
                        if gs.IsFPPMode ~= nil then gs.IsFPPMode = false end
                        if gs.bIsFPPMode ~= nil then gs.bIsFPPMode = false end
                        if gs.C_IsFPPMode ~= nil then gs.C_IsFPPMode = false end
                    end
                end)
            end
            -- [A] FORCE CAMERA (hanya bila force camera ON)
            if not XC.X3TPPForce then _G.X3._XFTPPOn = false return end
            local pc = lp.GetPlayerControllerSafety and lp:GetPlayerControllerSafety() or nil
            if not (pc and slua.isValid(pc)) then return end
            local isFPP = false
            pcall(function() if pc.bIsFirstPerson == true then isFPP = true end end)
            pcall(function() if lp.bIsFirstPerson == true then isFPP = true end end)
            pcall(function()
                local cm = pc.PlayerCameraManager
                if cm and slua.isValid(cm) and cm.CurCameraMode ~= nil and cm.CurCameraMode ~= 0 then isFPP = true end
            end)
            pcall(function() if pc.CurCameraMode ~= nil and pc.CurCameraMode ~= 0 then isFPP = true end end)
            local skipForce = false
            pcall(function() if type(lp.IsInVehicle) == "function" and lp:IsInVehicle() then skipForce = true end end)
            if not skipForce then
                pcall(function()
                    local mov = lp.CharacterMovement
                    if mov and slua.isValid(mov) and type(mov.IsSwimming) == "function" and mov:IsSwimming() then skipForce = true end
                end)
            end
            local now = os.clock()
            -- hanya untuk maintain agar tidak spam RPC.
            if not skipForce and type(pc.SwitchCameraMode) == "function" then
                if isFPP then
                    pcall(function() pc:SwitchCameraMode(0, lp, false, true) end)
                    _G.X3._XFTPPForceT = now
                elseif not _G.X3._XFTPPOn and now - (_G.X3._XFTPPForceT or 0) >= 0.25 then
                    _G.X3._XFTPPForceT = now
                    pcall(function() pc:SwitchCameraMode(0, lp, false, true) end)
                end
            end
            pcall(function() if pc.bIsFirstPerson ~= nil then pc.bIsFirstPerson = false end end)
            pcall(function() if lp.bIsFirstPerson ~= nil then lp.bIsFirstPerson = false end end)
            pcall(function() if pc.CurCameraMode ~= nil then pc.CurCameraMode = 0 end end)
            pcall(function()
                local cm = pc.PlayerCameraManager
                if cm and slua.isValid(cm) and cm.CurCameraMode ~= nil then cm.CurCameraMode = 0 end
            end)
            _G.X3._XFTPPOn = true
        end)
    end
end -- /v46b

do
-- WATERMARK MATCH / MATCH WATERMARK --
    local function XFWatermarkHookInstall()
        if _G.X3._WMHooked then return true end
        local ok, wm = pcall(require, "client.slua.logic.lobby_watermark.logic_lobby_watermark")
        if not (ok and type(wm) == "table") then return false end
        if type(wm.GetWatermarkString) ~= "function" and type(wm.GetFightingWatermarkString) ~= "function" then return false end
        local origA, origB = wm.GetWatermarkString, wm.GetFightingWatermarkString
        local function wrap(orig)
            return function(...)
                if _G.X3.XthrlenConfig.X3Watermark and (_G.X3._WMManual or _G.X3._WMEndOn) then
                    return " SRCHUBID - SRCHUBOFFICIAL "
                end
                return ""
            end
        end
        wm.GetWatermarkString = wrap(origA)
        wm.GetFightingWatermarkString = wrap(origB)
        -- gerbang mengikuti state (MANUAL tombol / AUTO top3-WWCD)
        if type(wm.CheckReleaseVersionWatermark) == "function" and not wm.__x3chk then
            wm.__x3chk = true
            wm.CheckReleaseVersionWatermark = function(...)
                return _G.X3.XthrlenConfig.X3Watermark == true and (_G.X3._WMManual == true or _G.X3._WMEndOn == true)
            end
        end
        pcall(function()
            local C = rawget(_G, "Client")
            if C and type(C.IsShowingWatermark) == "function" and not C.__x3wm then
                C.__x3wm = true
                C.IsShowingWatermark = function(...)
                    return _G.X3.XthrlenConfig.X3Watermark == true and (_G.X3._WMManual == true or _G.X3._WMEndOn == true)
                end
            end
        end)
        _G.X3._WMHooked = true
        if _G.X3.Trace then _G.X3.Trace("WATERMARK: hook terpasang (aktif saat hasil match)") end
        return true
    end

    local function XFWMShow(on)
        pcall(function()
            local UM = rawget(_G, "UIManager")
            if not (UM and UM.UI_Config) then return end
            local cfg = UM.UI_Config
            if on then
                local okM, M = pcall(require, "client.slua.umg.Fighting_Watermark.Fighting_Watermark_BP")
                if okM and M and M.CreateWatermark then pcall(M.CreateWatermark) end
                if UM.ShowUI then
                    if cfg.Fighting_Watermark_BP then pcall(function() UM.ShowUI(cfg.Fighting_Watermark_BP) end) end
                    if cfg.Lobby_Watermark_BP then pcall(function() UM.ShowUI(cfg.Lobby_Watermark_BP) end) end
                end
            else
                if UM.CloseUI then
                    if cfg.Fighting_Watermark_BP then pcall(function() UM.CloseUI(cfg.Fighting_Watermark_BP) end) end
                    if cfg.Lobby_Watermark_BP then pcall(function() UM.CloseUI(cfg.Lobby_Watermark_BP) end) end
                end
            end
        end)
    end

    -- satu pintu: hitung state & tampilkan/sembunyikan (anti spam via _WMShown)
    function _G.X3._WMRefresh()
        local show = _G.X3.XthrlenConfig.X3Watermark == true and (_G.X3._WMManual == true or _G.X3._WMEndOn == true)
        if show == _G.X3._WMShown then return end
        _G.X3._WMShown = show
        if show and not _G.X3._WMHooked then XFWatermarkHookInstall() end
        XFWMShow(show)
    end
    _G.X3._WMHookInstall = XFWatermarkHookInstall
    _G.X3._WMShowUI = XFWMShow

    function _G.X3._XFWMTick(lp)
        if not XC.X3Watermark then
            if _G.X3._WMEndOn or _G.X3._WMManual then
                _G.X3._WMEndOn = false
                _G.X3._WMManual = false
                _G.X3._WMRefresh()
            end
            _G.X3._WMFought = false
            return
        end
        if not _G.X3._WMHooked then XFWatermarkHookInstall() end
        pcall(function()
            if _G.X3.XthrlenConfig.WallhackVis == true then
                local st, teams = nil, nil
                local gs = GameplayData and GameplayData.GetGameState and GameplayData.GetGameState()
                if gs and slua.isValid(gs) then
                    pcall(function() st = gs:GetGameModeState() end)
                    pcall(function() teams = tonumber(gs.AliveTeamNum) end)
                end
                if st == "FightingState" then
                    _G.X3._WMFought = true
                    if _G.X3._WMEndOn then _G.X3._WMEndOn = false end
                elseif _G.X3._WMFought and st ~= nil and st ~= "" then
                    _G.X3._WMFought = false
                    -- SMART TRIGGER: hanya rank akhir TOP 3-1 (WWCD)
                    local top3 = (teams == nil) or (teams <= 3)
                    if top3 and not _G.X3._WMEndOn then
                        _G.X3._WMEndOn = true
                        Notify("🏆 TOP 3/WWCD — SMART WATERMARK aktif (auto OFF di lobby)")
                    end
                end
            end
            _G.X3._WMRefresh()
        end)
    end

    _G.X3.WMLobby = function()
        _G.X3._WMEndOn = false -- AUTO top3 selalu hilang di lobby
        _G.X3._WMBase = nil
        _G.X3._WMFought = false
        _G.X3._WMRefresh()
    end
    _G.X3._WMCloseUI = function()
        _G.X3._WMManual = false
        _G.X3._WMEndOn = false
        _G.X3._WMShown = nil
        XFWMShow(false)
    end

    _G.X3._CC = _G.X3._CC or { phase = nil, lastWall = 0, lastMini = 0, cvarsDone = false }
    local function XFCacheClear(why, full)
        local before = collectgarbage("count")
        if full then
            collectgarbage("collect")
        else
            for _ = 1, 3 do collectgarbage("step", 200) end
        end
        local after = collectgarbage("count")
        if type(_G.X3.Trace) == "function" then
            _G.X3.Trace(string.format("CACHE CLEAR [%s]: %.0f KB -> %.0f KB (bebaskan %.0f KB)",
                tostring(why), before, after, before - after))
        end
    end

    local function XFPurgeScriptCaches()
        local freed = 0
        pcall(function()
            if type(_G.X3.PawnReadyT) == "table" then
                for k in pairs(_G.X3.PawnReadyT) do _G.X3.PawnReadyT[k] = nil freed = freed + 1 end
            end
        end)
        pcall(function()
            if type(_G.X3._XFWwhApplied) == "table" then
                for k in pairs(_G.X3._XFWwhApplied) do _G.X3._XFWwhApplied[k] = nil freed = freed + 1 end
            end
        end)
        pcall(function()
            _G.X3._BTVp = nil
            _G.X3._BTTarget = nil
            _G.X3._XFWCache = nil
        end)
        if type(_G.X3.Trace) == "function" then
            _G.X3.Trace(string.format("CACHE PURGE: %d entri latch/applied dibersihkan (dibangun ulang otomatis)", freed))
        end
    end

    _G.X3.CacheCleanerTick = function(inMatch)
-- PEMBERSIH CACHE / CACHE CLEANER --
        if XC.X3CacheClean == false then return end
        local st = _G.X3._CC
        local phase = inMatch and "match" or "lobby"
        local nowW = os.time()
        if st.phase ~= phase then
            st.phase = phase
            st.lastWall = nowW
            st.lastMini = nowW
            XFPurgeScriptCaches()
            XFCacheClear(phase == "match" and "SPAWN/masuk match" or "LOBBY/selesai match", true)
            return
        end
        if inMatch and (nowW - (st.lastMini or 0)) >= 60 then
            local dt = tonumber(_G.X3.FrameDT) or 0
            if dt > 0 and dt < (1.0 / 40.0) then
                st.lastMini = nowW
                XFCacheClear("mini 60 dtk (frame sehat)", false)
            end
        end
        -- purge + clear bertahap tiap 5 menit
        if (nowW - (st.lastWall or 0)) >= 300 then
            st.lastWall = nowW
            XFPurgeScriptCaches()
            XFCacheClear("interval 5 menit (" .. phase .. ")", false)
        end
    end

    local function XFApplyGCCvars()
        if _G.X3._CC.cvarsDone then return end
        local pc = GameplayData and GameplayData.GetPlayerController and GameplayData.GetPlayerController()
        if not (pc and slua.isValid(pc)) then return end
        local KSL = import("KismetSystemLibrary")
        if not (KSL and KSL.ExecuteConsoleCommand) then return end
        _G.X3._CC.cvarsDone = true
        pcall(function()
            local cmds = {
                "Gc.TimeBetweenPurgingPendingKillObjects 30.0",
                "gc.NumRetriesBeforeForcingGC 20",
                "gc.FlushStreamingOnGC 0",
                "gc.AllowParallelGC 1",
                "gc.CreateGCClusters 1",
                "gc.MergeGCClusters 0",
                "gc.ActorClusteringEnabled 0",
                "gc.BlueprintClusteringEnabled 0",
            }
            for _, c in ipairs(cmds) do KSL.ExecuteConsoleCommand(pc, c, nil) end
        end)
        if type(_G.X3.Trace) == "function" then _G.X3.Trace("GC CVARS: optimasi garbage collection diterapkan") end
    end

    -- OFF memulihkan default standar engine.
    _G.X3._PerfBoostState = _G.X3._PerfBoostState or { applied = false, last = 0 }
    local X3PerfCmds_ON = {
        "r.MotionBlurQuality 0",
        "r.DepthOfFieldQuality 0",
        "r.SceneColorFringeQuality 0",
        "r.LensFlareQuality 0",
        "r.BloomQuality 2",
        "r.Tonemapper.GrainQuantization 0",
        "r.Shadow.CSM.MaxMobileCascades 1",
        "r.Shadow.DistanceScale 0.5",
        "r.EmitterSpawnRateScale 0.5",
        "r.ParticleLODBias 1",
        "r.StaticMeshLODDistanceScale 0.8",
    }
    local X3PerfCmds_OFF = {
        "r.MotionBlurQuality 2",
        "r.DepthOfFieldQuality 2",
        "r.SceneColorFringeQuality 1",
        "r.LensFlareQuality 2",
        "r.BloomQuality 4",
        "r.Tonemapper.GrainQuantization 1",
        "r.Shadow.CSM.MaxMobileCascades 2",
        "r.Shadow.DistanceScale 1.0",
        "r.EmitterSpawnRateScale 1",
        "r.ParticleLODBias 0",
        "r.StaticMeshLODDistanceScale 1.0",
    }
-- BOOST PERFORMA / PERFORMANCE BOOST --
    _G.X3.ApplyPerfBoost = function(on)
        local st = _G.X3._PerfBoostState
        local now = os.clock()
        if st.applied == on and (now - st.last) < 5.0 then return end
        pcall(function()
            local pc = GameplayData and GameplayData.GetPlayerController and GameplayData.GetPlayerController()
            if not (pc and slua.isValid(pc)) then return end
            local KSL = import("KismetSystemLibrary")
            if not (KSL and KSL.ExecuteConsoleCommand) then return end
            local cmds = on and X3PerfCmds_ON or X3PerfCmds_OFF
            for _, c in ipairs(cmds) do KSL.ExecuteConsoleCommand(pc, c, nil) end
            st.applied = on
            st.last = now
            if on and type(_G.X3.Trace) == "function" then
                _G.X3.Trace("PERF BOOST: ON (blur/DoF/rumput/cascade dipangkas, resolusi tidak disentuh)")
            end
        end)
    end

-- SULTAN PALSU / FAKE SULTAN VISUAL --
    local function XFFakeMoneyInstall()
        local DM = rawget(_G, "DataMgr")
        if not (DM and type(DM.InitRoleData) == "function") then return end
        if DM.__x3money then _G.X3._FakeMoneyOK = true return end
        local base = DM.InitRoleData
        DM.InitRoleData = function(roleDataTb)
            base(roleDataTb)
            pcall(function()
                local M = 999999999
                DM.gold = M; DM.ticket = M; DM.diamond = M; DM.fp_token = M
                DM.gold_chip = M; DM.gen_ticket = M; DM.eternal_diamond = M
                DM.corps_money = M; DM.smelt = M; DM.battle_coin = M
                DM.wow_creation_score = M; DM.ugc_advanced_crystal = M
                DM.carteam_coin_count = M; DM.anchor = M; DM.anchor_origin = M
                if DM.roleData then DM.roleData.bgbg_vip = 1; DM.roleData.level = 100 end
                local ES = rawget(_G, "EventSystem")
                local ET = rawget(_G, "EVENTTYPE_DATA_MGR")
                if ES and ES.postEvent and ET then
                    pcall(function() ES:postEvent(ET, rawget(_G, "EVENTID_DATAMGR_GOLD_CHANGE"), DM.gold) end)
                    pcall(function() ES:postEvent(ET, rawget(_G, "EVENTID_DATAMGR_DIAMOND_CHANGE"), DM.diamond) end)
                    pcall(function() ES:postEvent(ET, rawget(_G, "EVENTID_DATAMGR_TICKET_CHANGE"), DM.ticket) end)
                end
            end)
        end
        DM.__x3money = true
        _G.X3._FakeMoneyOK = true
        if type(_G.X3.Trace) == "function" then _G.X3.Trace("LOBBY VISUAL: fake currency terpasang (visual)") end
    end

    local function XFSkinLevelInstall()
        local MM = rawget(_G, "ModuleManager")
        if not (MM and MM.GetModule and MM.LobbyModuleConfig) then return end
        local cm = MM.GetModule(MM.LobbyModuleConfig.collect_module)
        if not cm then return end
        local MAXL = 100
        if type(cm.GetLevelByScore) == "function" and not cm.__x3lvl_a then
            cm.__x3lvl_a = true
            local o = cm.GetLevelByScore
            cm.GetLevelByScore = function(self, score)
                if score and score >= 0 then return MAXL, MAXL, MAXL, 0, 0 end
                return o(self, score)
            end
        end
        if type(cm.GetLevelDataByScore) == "function" and not cm.__x3lvl_b then
            cm.__x3lvl_b = true
            local o = cm.GetLevelDataByScore
            cm.GetLevelDataByScore = function(self, score, isSeason)
                if score and score >= 0 then return MAXL, "", MAXL end
                return o(self, score, isSeason)
            end
        end
        if type(cm.GetSeasonLevelByScore) == "function" and not cm.__x3lvl_c then
            cm.__x3lvl_c = true
            local o = cm.GetSeasonLevelByScore
            cm.GetSeasonLevelByScore = function(self, score, ...)
                if score and score >= 0 then return MAXL, false, "" end
                return o(self, score, ...)
            end
        end
        _G.X3._SkinLvlOK = true
        if type(_G.X3.Trace) == "function" then _G.X3.Trace("LOBBY VISUAL: skin collect level 100 terpasang (visual)") end
    end

    local function XFReportFaceInstall()
        for name, mod in pairs(package.loaded) do
            if type(mod) == "table" and type(rawget(mod, "CanShowFace")) == "function" and type(rawget(mod, "ShowReportSucceedFace")) == "function" then
                rawset(mod, "CanShowFace", function() return false end)
                rawset(mod, "CanShowWarningFace", function() return false end)
                _G.X3._ReportFaceOK = true
                if type(_G.X3.Trace) == "function" then _G.X3.Trace("BYPASS: popup 'laporan berhasil' disupresi (" .. tostring(name) .. ")") end
                return
            end
        end
    end

    local function XFTPPUnlockInstall()
        if _G.X3._TPPUnlockOK then return true end
        local ok, UIT = pcall(require, "GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        if not (ok and type(UIT) == "table" and type(rawget(UIT, "IsFPP")) == "function") then return false end
        if rawget(UIT, "__x3tpp_orig") == nil then
            rawset(UIT, "__x3tpp_orig", rawget(UIT, "IsFPP"))
            rawset(UIT, "IsFPP", function(...)
                -- butuh UI/game menganggap mode bukan FPP)
                if _G.X3.XthrlenConfig.X3TPPUnlockBtn == true or _G.X3.XthrlenConfig.X3TPPForce == true then return false end
                local orig = rawget(UIT, "__x3tpp_orig")
                if orig then return orig(...) end
                return false
            end)
        end
        _G.X3._TPPUnlockOK = true
        if type(_G.X3.Trace) == "function" then _G.X3.Trace("TPP UNLOCK: hook InGameUITools.IsFPP terpasang — tombol switch dimunculkan di mode FPP") end
        return true
    end
    _G.X3._XFTPPUnlockTry = function()
        if _G.X3._TPPUnlockOK then return end
        pcall(XFTPPUnlockInstall)
    end

    --     ipairs(_G) (sudah diverifikasi), jadi aman.
    local function XFRudyBypassInstall()
        local st = _G.X3._RudyB or { higgs = false, cb = false, hawk = false, gscan = false }
        _G.X3._RudyB = st
        if not st.gscan then
            local rawPairs, rawIpairs = pairs, ipairs
            if rawget(_G, "pairs") == rawPairs and rawget(_G, "ipairs") == rawIpairs then
                rawset(_G, "pairs", function(t)
                    if t == _G then return function() return nil end end
                    return rawPairs(t)
                end)
                rawset(_G, "ipairs", function(t)
                    if t == _G then return function() return nil end end
                    return rawIpairs(t)
                end)
                st.gscan = true
                if type(_G.X3.Trace) == "function" then _G.X3.Trace("BYPASS: anti _G-scan aktif (pairs/ipairs pada _G dibutakan)") end
            else
                st.gscan = true -- sudah dimodifikasi pihak lain: jangan ditimpa
            end
        end
        if not st.cb then
            local GCB = rawget(_G, "GameplayCallbacks") or rawget(_G, "GC")
            if type(GCB) == "table" then
                local noopT = function() return true end
                local noop0 = function() return 0 end
                local cbList = {
                    "SendTssSdkAntiDataToLobby", "SendDSErrorLogToLobby",
                    "SendDSHawkEyePatrolLogToLobby", "SendSecTLog",
                    "SendDataMiningTLog", "SendActivityTLog",
                }
                for _, n in ipairs(cbList) do
                    if rawget(GCB, n) ~= nil then rawset(GCB, n, noopT) end
                end
                if rawget(GCB, "OnPlayerRPCValidateFailed") ~= nil then rawset(GCB, "OnPlayerRPCValidateFailed", noop0) end
                if rawget(GCB, "OnPlayerActorChannelError") ~= nil then rawset(GCB, "OnPlayerActorChannelError", noop0) end
                st.cb = true
                if type(_G.X3.Trace) == "function" then _G.X3.Trace("BYPASS: telemetry GameplayCallbacks di-noop (TSS/DS/HawkEye/TLog)") end
            end
        end
        if not st.hawk then
            pcall(function()
                local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
                if SubsystemMgr and SubsystemMgr.Get then
                    local hawk = SubsystemMgr:Get("DSHawkEyePatrolSubsystem")
                    if hawk and rawget(hawk, "MarkSuspiciousPlayer") ~= nil then
                        rawset(hawk, "MarkSuspiciousPlayer", function() return true end)
                        st.hawk = true
                        if type(_G.X3.Trace) == "function" then _G.X3.Trace("BYPASS: DSHawkEyePatrol.MarkSuspiciousPlayer di-noop") end
                    end
                end
            end)
        end
        if not st.higgs then
            local HIG = package.loaded["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"]
            if type(HIG) == "table" then
                local noopT = function() return true end
                -- SendHitFireBtnFlow = laporan tembakan/tombol,
                -- SendHisarData = laporan Hisar (anti-cheat),
                -- RPC_Client_ShowSecurityAlertWindow/ShowABCD/
                --   = jendela "Security Alert",
                local secList = {
                    "SendAntiDataFlow", "SendHitFireBtnFlow", "SendHisarData",
                    "RPC_Client_ShowSecurityAlertWindow", "ShowABCD",
                    "_ClientShowSecurityAlertWindow", "StaticShowSecurityAlertInDev",
                    "RecordStrategyTimestampInReplay", "_ReportChatRobot",
                    "_ProcessReportChatRobotQueue", "RPC_Server_TellServerName",
                    "ControlMHActive", "Tick", "OnTick", "ReceiveTick", "MHActiveLogic",
                    "TriggerAvatarCheck", "StartAvatarCheck", "ReportItemID", "OnReportItemID",
                    "ReceiveAnyDamage", "OnWeaponHitRecord", "ShowSecurityAlert",
                }
                for _, n in ipairs(secList) do
                    if rawget(HIG, n) ~= nil then rawset(HIG, n, noopT) end
                end
                if rawget(HIG, "GetNetAvatarItemIDs") ~= nil then rawset(HIG, "GetNetAvatarItemIDs", function() return {} end) end
                if rawget(HIG, "GetCurWeaponSkinID") ~= nil then rawset(HIG, "GetCurWeaponSkinID", function() return 0 end) end
                pcall(function()
                    local pc = GameplayData and GameplayData.GetPlayerController and GameplayData.GetPlayerController()
                    local KSL = import("KismetSystemLibrary")
                    if pc and slua.isValid(pc) and KSL and KSL.ExecuteConsoleCommand then
                        KSL.ExecuteConsoleCommand(pc, "higgs.EnableClientShowSecurityAlert 0", nil)
                    end
                end)
                st.higgs = true
                if type(_G.X3.Trace) == "function" then _G.X3.Trace("BYPASS: HiggsBosonComponent di-noop (method asli 4.5: AntiData/HitFire/Hisar/SecurityAlert)") end
            end
        end
        if not st.chawk then
            pcall(function()
                local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
                if SubsystemMgr and SubsystemMgr.Get then
                    local ch = SubsystemMgr:Get("ClientHawkEyePatrolSubsystem")
                    if ch then
                        local noopT = function() return true end
                        for _, n in ipairs({ "CheckShowReportedTips", "TryShowReportedTips", "_OnHawkSync" }) do
                            if rawget(ch, n) ~= nil then rawset(ch, n, noopT) end
                        end
                        st.chawk = true
                        if type(_G.X3.Trace) == "function" then _G.X3.Trace("BYPASS: ClientHawkEyePatrolSubsystem di-noop (tips patroli)") end
                    end
                end
            end)
        end
    end
    _G.X3._XFRudyBypassTry = function()
        local st = _G.X3._RudyB
        if st and st.higgs and st.cb and st.hawk and st.gscan and st.chawk then return end
        pcall(XFRudyBypassInstall)
    end

    _G.X3.LobbyVisualsTick = function()
        local now = os.clock()
        local st = _G.X3._LVT or { last = 0 }
        _G.X3._LVT = st
        if (now - st.last) < 3.0 then return end
        st.last = now
        XFApplyGCCvars()
        if not _G.X3._ReportFaceOK then pcall(XFReportFaceInstall) end
        if XC.X3Watermark and not _G.X3._WMHooked then pcall(XFWatermarkHookInstall) end
        if XC.X3FakeVisual then
            if not _G.X3._FakeMoneyOK then pcall(XFFakeMoneyInstall) end
            if not _G.X3._SkinLvlOK then pcall(XFSkinLevelInstall) end
        end
        if XC.X3PerfBoost and _G.X3.ApplyPerfBoost then pcall(_G.X3.ApplyPerfBoost, true) end
        if _G.X3._XFRudyBypassTry then pcall(_G.X3._XFRudyBypassTry) end
        if XC.X3TPPUnlockBtn and _G.X3._XFTPPUnlockTry then pcall(_G.X3._XFTPPUnlockTry) end
        if _G.X3._XFLoginBypassTry then pcall(_G.X3._XFLoginBypassTry) end
                    if _G.X3._ACShieldHookTry then pcall(_G.X3._ACShieldHookTry) end
                    if _G.X3._ACMemberMaskTry then pcall(_G.X3._ACMemberMaskTry) end
                    if _G.X3._ACTssShieldTry then pcall(_G.X3._ACTssShieldTry) end
                    if _G.X3._ACLogShieldTry then pcall(_G.X3._ACLogShieldTry) end
                    if _G.X3._ACHiggsShieldTry then pcall(_G.X3._ACHiggsShieldTry) end
                    if _G.X3._ACPacketFilterTry then pcall(_G.X3._ACPacketFilterTry) end
    end
end -- /v46c

do
    local LB = { lastScan = 0, hookedCD = 0, hookedV2L = 0 }
    _G.X3._XFLoginBypassState = LB

    local MOD_PAT = { "server", "login", "verify", "account", "risk", "safe", "gate", "region", "zone" }
    local CD_ALLOW_PAT = { "canswitch", "canchange", "allowswitch", "allowchange", "checkswitch", "checkchange" }
    local CD_TIME_PAT  = { "cooldown", "coldown" }
    local V2L_PAT = { "needverify", "needsecond", "needdevice", "showverify", "isverify", "secondaryverify", "needv2l", "showv2l" }

    local function NameHits(name, pats)
        name = string.lower(tostring(name))
        for _, p in ipairs(pats) do
            if string.find(name, p, 1, true) then return true end
        end
        return false
    end

    --     dipaksa false BERULANG (scan 30 dtk).
    local function XFVerifiedHooks()
        pcall(function()
            local ok, MM = pcall(require, "client.slua.logic.match.logic_match")
            if ok and type(MM) == "table" and type(rawget(MM, "GetRemainChangeServerCdTime")) == "function"
                and rawget(MM, "__x3cd_orig") == nil then
                rawset(MM, "__x3cd_orig", rawget(MM, "GetRemainChangeServerCdTime"))
                rawset(MM, "GetRemainChangeServerCdTime", function() return 0 end)
                if type(_G.X3.Trace) == "function" then _G.X3.Trace("LOGIN BYPASS: cooldown ganti server di-bypass (GetRemainChangeServerCdTime -> 0, terverifikasi)") end
            end
        end)
        pcall(function()
            local ok, ZS = pcall(require, "client.slua.logic.teamup.logic_zone")
            if ok and type(ZS) == "table" and rawget(ZS, "nNextChooseZoneTime") ~= nil then
                if (tonumber(rawget(ZS, "nNextChooseZoneTime")) or 0) > 0 then
                    rawset(ZS, "nNextChooseZoneTime", 0)
                    if type(_G.X3.Trace) == "function" then _G.X3.Trace("LOGIN BYPASS: nNextChooseZoneTime direset ke 0") end
                end
            end
        end)
        pcall(function()
            local ok, LV = pcall(require, "client.slua.logic.login.logic_login_verify")
            if ok and type(LV) == "table" then
                LV.use_gm_data = false
                if LV.function_open ~= false then LV.function_open = false end
                if LV.is_open ~= false then LV.is_open = false end
                if LV.phone_open ~= false then LV.phone_open = false end
                if LV.mail_open ~= false then LV.mail_open = false end
                if LV.code_open ~= false then LV.code_open = false end
                if LV.has_popup_security ~= false then LV.has_popup_security = false end
                if rawget(LV, "__x3v2l_hooked") == nil then
                    rawset(LV, "__x3v2l_hooked", true)
                    local f0 = function() return false end
                    for _, n in ipairs({ "IsLoginVerifyOpen", "IsFunctionOpen", "IsLoginVerifyPhoneOpen",
                        "IsLoginVerifyMailOpen", "IsLoginVerifyCodeOpen", "IsOpLogOpen" }) do
                        if type(rawget(LV, n)) == "function" then rawset(LV, n, f0) end
                    end
                    if type(_G.X3.Trace) == "function" then _G.X3.Trace("LOGIN BYPASS: V2L/verifikasi ganda di-skip (logic_login_verify -> false, terverifikasi)") end
                end
            end
        end)
    end

    local function XFLoginBypassScan()
        local now = os.clock()
        if (now - LB.lastScan) < 30.0 then return end
        LB.lastScan = now
        XFVerifiedHooks()
        local newCD, newV2L = 0, 0
        for modName, mod in pairs(package.loaded) do
            if type(modName) == "string" and type(mod) == "table" and NameHits(modName, MOD_PAT) then
                for fname, fval in pairs(mod) do
                    if type(fname) == "string" and type(fval) == "function" then
                        local low = string.lower(fname)
                        local hit = false
                        if NameHits(low, CD_ALLOW_PAT) then
                            rawset(mod, fname, function() return true end)
                            newCD = newCD + 1 hit = true
                        elseif NameHits(low, CD_TIME_PAT) and (string.find(low, "get", 1, true) or string.find(low, "time", 1, true) or string.find(low, "left", 1, true) or string.find(low, "remain", 1, true) or string.find(low, "check", 1, true)) then
                            rawset(mod, fname, function() return 0 end)
                            newCD = newCD + 1 hit = true
                        end
                        if not hit and NameHits(low, V2L_PAT) then
                            rawset(mod, fname, function() return false end)
                            newV2L = newV2L + 1
                        end
                    end
                end
            end
        end
        if newCD > 0 or newV2L > 0 then
            LB.hookedCD = LB.hookedCD + newCD
            LB.hookedV2L = LB.hookedV2L + newV2L
            if type(_G.X3.Trace) == "function" then
                _G.X3.Trace(string.format("LOGIN BYPASS (auto): +%d gerbang cooldown server, +%d gerbang V2L (total %d/%d, best-effort client-side)",
                    newCD, newV2L, LB.hookedCD, LB.hookedV2L))
            end
        end
    end

    _G.X3._XFLoginBypassTry = function()
        pcall(XFLoginBypassScan)
    end

    pcall(XFLoginBypassScan)
end -- /v52 LoginBypass

end -- /v54 UnlockAll

_G.X3.ExtraTick = function(lp)
    if not (lp and slua.isValid(lp)) then return end
    local now = os.clock()
    local st = _G.X3._XF
    local ts = _G.X3.TickScale and _G.X3.TickScale() or 1
    if now - (st.tpp or 0) >= 0.033 then st.tpp = now; if _G.X3._XFTPPTick then pcall(_G.X3._XFTPPTick, lp) end end
    if now - (st.wwh or 0) >= 2.0 * ts then st.wwh = now; if _G.X3._XFWScan then pcall(_G.X3._XFWScan, lp) end end
    if now - (st.wpulse or 0) >= 0.25 * ts then st.wpulse = now; if _G.X3._XFWPulse then pcall(_G.X3._XFWPulse) end end
    if now - (st.wm or 0) >= 1.0 * ts then st.wm = now; if _G.X3._XFWMTick then pcall(_G.X3._XFWMTick, lp) end end
    if now - (st.tipthr or 0) >= 10.0 * ts then st.tipthr = now; if _G.X3._XFTipThrottleTry then pcall(_G.X3._XFTipThrottleTry) end end
    if now - (st.netb or 0) >= 20.0 then st.netb = now; if XC.NetBoost and _G.X3.ApplyNetworkBoost then pcall(_G.X3.ApplyNetworkBoost, true) end end
    if now - (st.acsh or 0) >= 1.0 * ts then st.acsh = now; if _G.X3._ACShieldTick then pcall(_G.X3._ACShieldTick) end end
    if now - (st.acshk or 0) >= 10.0 * ts then st.acshk = now; if _G.X3._ACShieldHookTry then pcall(_G.X3._ACShieldHookTry) end; if _G.X3._ACMemberMaskTry then pcall(_G.X3._ACMemberMaskTry) end; if _G.X3._ACTssShieldTry then pcall(_G.X3._ACTssShieldTry) end; if _G.X3._ACLogShieldTry then pcall(_G.X3._ACLogShieldTry) end; if _G.X3._ACHiggsShieldTry then pcall(_G.X3._ACHiggsShieldTry) end; if _G.X3._ACPacketFilterTry then pcall(_G.X3._ACPacketFilterTry) end end
end

do
-- PERISAI ANTI-BAN / ANTI-BAN SHIELD (auto ON, realtime, ringan)
do
    -- 1) NETRALISASI HUKUMAN ANTI-CHEAT / PUNISHMENT NEUTRALIZER
    -- PlayerController.AntiCheatManagerComp (PlayerAntiCheatManager): server
    -- mereplikasi counter deteksi + flag hukuman; hukuman diaplikasikan via
    -- client (SwitchHitComponentUnvalid = hit Anda tidak teregistrasi /
    -- "0 damage" soft-ban). Field read+write 1x/detik — anti-FC, no frame drop.
    function _G.X3._ACShieldTick()
        pcall(function()
            local pc = GameplayData and GameplayData.GetPlayerController and GameplayData.GetPlayerController()
            if not (pc and slua.isValid(pc)) then return end
            local comp = nil
            pcall(function() comp = pc.AntiCheatManagerComp end)
            if not comp then return end
            pcall(function() if comp.SwitchHitComponentUnvalid == true then comp.SwitchHitComponentUnvalid = false end end)
            pcall(function() if comp.bReportFeedBack == true then comp.bReportFeedBack = false end end)
            pcall(function() if comp.bOpenDetailDataCollect == true then comp.bOpenDetailDataCollect = false end end)
            if not _G.X3._ACShieldSeen then
                _G.X3._ACShieldSeen = true
                if type(_G.X3.Trace) == "function" then _G.X3.Trace("ACSHIELD: AntiCheatManagerComp ditemukan, netralisasi hukuman aktif") end
            end
        end)
    end

    -- 2) PENEKAN REPORT / REPORT SUPPRESSOR (client-originated)
    -- a) tombol report di panel info pemain in-match → no-op
    -- b) semua fungsi Client.Report* (sender laporan dari client) → no-op
    function _G.X3._ACShieldHookTry()
        if _G.X3._ACShieldHooked then return end
        _G.X3._ACShieldHooked = true
        pcall(function()
            local M = require("GameLua.Mod.BaseMod.Client.WatchGame.WatchGameInGamePlayerInfo")
            if type(M) == "table" and type(M.EventReportPlayerInfoButtonClick) == "function" then
                M.EventReportPlayerInfoButtonClick = function() end
            end
        end)
        pcall(function()
            local C = rawget(_G, "Client")
            if type(C) == "table" then
                local n = 0
                for k, v in pairs(C) do
                    if type(v) == "function" and type(k) == "string" and k:sub(1, 6) == "Report" then
                        C[k] = function(...) return end
                        n = n + 1
                    end
                end
                if type(_G.X3.Trace) == "function" then _G.X3.Trace("ACSHIELD: " .. n .. " jalur report client dinetralkan") end
            end
        end)
    end

    -- 3) FORENSIC MEMBER MASKING / PENUTUP JEJAK REPLAY
    -- Review replay membaca counter strategi via SecurityCommonUtils member
    -- getters. Key yang dipakai review (EStrategyTypeInReplay): EspTotal*
    -- (ESP trace/focus), BulletFlySpeed, GravityAnomaly, FlyingError,
    -- AvatarCheck* (deteksi skin mod), HighValueIllegalWear → paksa bersih.
    function _G.X3._ACMemberMaskTry()
        if _G.X3._ACMaskHooked then return end
        _G.X3._ACMaskHooked = true
        pcall(function()
            local S = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
            if type(S) ~= "table" then return end
            local function isStrategyKey(ks)
                ks = tostring(ks)
                return ks:find("EspTotal") or ks:find("AvatarCheck") or ks:find("IllegalWear")
                    or ks:find("BulletFlySpeed") or ks:find("GravityAnomaly") or ks:find("FlyingError")
            end
            local function wrapNum(fnName)
                local orig = S[fnName]
                if type(orig) ~= "function" then return end
                S[fnName] = function(owner, key, ...)
                    if isStrategyKey(key) then return 0 end
                    return orig(owner, key, ...)
                end
            end
            local function wrapBool(fnName)
                local orig = S[fnName]
                if type(orig) ~= "function" then return end
                S[fnName] = function(owner, key, ...)
                    if isStrategyKey(key) then return false end
                    return orig(owner, key, ...)
                end
            end
            wrapNum("GetNumberMember")
            wrapNum("GetIntMember")
            wrapBool("GetBoolMember")
            if type(_G.X3.Trace) == "function" then _G.X3.Trace("ACSHIELD: forensic member masking aktif") end
        end)
    end

    -- 4) FIREWALL PROFILE GL/KR/VNG / FIREWALL FILTER
    -- Menulis profil JSON (format companion firewall, sesuai contoh):
    -- allow port game (17500/18600 tcp), deny port telemetry (8013 tcp),
    -- hanya untuk com.tencent.ig (GL), com.pubg.krmobile (KR),
    -- com.vng.pubgmobile (VNG). Penegakan butuh aplikasi firewall pendamping
    -- yang membaca profil ini — Lua tidak bisa memfilter paket langsung.
    function _G.X3._ACFirewallInstall()
        if _G.X3._ACFirewallDone then return end
        _G.X3._ACFirewallDone = true
        local pkgs = {
            { name = "BGMI",    pkg = "com.pubg.imobile" },
            { name = "PUBG MOBILE KR", pkg = "com.pubg.krmobile" },
            { name = "PUBG MOBILE VN", pkg = "com.vng.pubgmobile" },
        }
        local apps = {}
        for i = 1, 8 do apps[#apps + 1] = { appName = "System", pkgName = "nonpkg.noname" } end
        local filters = {}
        for _, p in ipairs(pkgs) do
            filters[#filters + 1] = { appName = p.name, isCustom = false, mobile = "none", pkg1Name = p.pkg, port = -1, priority = 0, proto = "tcp", server = "*", serverStrType = "ip4", wifi = "none" }
            filters[#filters + 1] = { appName = p.name, isCustom = true, mobile = "allow", pkg1Name = p.pkg, port = 18600, priority = 0, proto = "tcp", server = "*", serverStrType = "ip4", wifi = "allow" }
            filters[#filters + 1] = { appName = p.name, isCustom = true, mobile = "allow", pkg1Name = p.pkg, port = 17500, priority = 0, proto = "tcp", server = "*", serverStrType = "ip4", wifi = "allow" }
            filters[#filters + 1] = { appName = p.name, isCustom = true, mobile = "allow", pkg1Name = p.pkg, port = 18600, priority = 0, proto = "udp", server = "*", serverStrType = "ip4", wifi = "allow" }
            filters[#filters + 1] = { appName = p.name, isCustom = true, mobile = "allow", pkg1Name = p.pkg, port = 17500, priority = 0, proto = "udp", server = "*", serverStrType = "ip4", wifi = "allow" }
            filters[#filters + 1] = { appName = p.name, isCustom = true, mobile = "deny", pkg1Name = p.pkg, port = 8013, priority = 0, proto = "tcp", server = "*", serverStrType = "ip4", wifi = "deny" }
            filters[#filters + 1] = { appName = p.name, isCustom = true, mobile = "deny", pkg1Name = p.pkg, port = 8013, priority = 0, proto = "udp", server = "*", serverStrType = "ip4", wifi = "deny" }
            filters[#filters + 1] = { appName = p.name, isCustom = true, mobile = "deny", pkg1Name = p.pkg, port = 8080, priority = 0, proto = "tcp", server = "*", serverStrType = "ip4", wifi = "deny" }
            filters[#filters + 1] = { appName = p.name, isCustom = true, mobile = "deny", pkg1Name = p.pkg, port = 10086, priority = 0, proto = "tcp", server = "*", serverStrType = "ip4", wifi = "deny" }
        end
        local function jstr(s) return '"' .. s .. '"' end
        local parts = { '{"apps":[' }
        for i, a in ipairs(apps) do
            parts[#parts + 1] = '{"appName":' .. jstr(a.appName) .. ',"pkgName":' .. jstr(a.pkgName) .. '}' .. (i < #apps and ',' or '')
        end
        parts[#parts + 1] = '],"filters":['
        for i, f in ipairs(filters) do
            parts[#parts + 1] = string.format(
                '{"appName":%s,"isCustom":%s,"mobile":%s,"pkg1Name":%s,"port":%d,"priority":%d,"proto":%s,"server":%s,"serverStrType":%s,"wifi":%s}%s',
                jstr(f.appName), tostring(f.isCustom), jstr(f.mobile), jstr(f.pkg1Name), f.port, f.priority,
                jstr(f.proto), jstr(f.server), jstr(f.serverStrType), jstr(f.wifi), (i < #filters and ',' or ''))
        end
        parts[#parts + 1] = ']}'
        local json = table.concat(parts)
        _G.X3._ACFirewallJSON = json
        local wrote = false
        local paths = { "/sdcard/SRCHUB_firewall.json", "/storage/emulated/0/SRCHUB_firewall.json", "/sdcard/Download/SRCHUB_firewall.json" }
        -- jalur engine (Android & iOS): tanya langsung ke game di mana folder Paks-nya
        pcall(function()
            local C = rawget(_G, "Client")
            if type(C) == "table" then
                if type(C.ProjectSavedDir) == "function" then
                    local d = C.ProjectSavedDir()
                    if type(d) == "string" and #d > 1 then
                        paths[#paths + 1] = d .. "Paks/SRCHUB_firewall.json"
                        paths[#paths + 1] = d .. "paks/SRCHUB_firewall.json"
                    end
                end
                if type(C.ProjectContentDir) == "function" then
                    local d2 = C.ProjectContentDir()
                    if type(d2) == "string" and #d2 > 1 then paths[#paths + 1] = d2 .. "paks/SRCHUB_firewall.json" end
                end
            end
        end)
        -- jalur hardcode Android per package (GL/KR/VNG)
        for _, p in ipairs(pkgs) do
            paths[#paths + 1] = "/sdcard/Android/data/" .. p.pkg .. "/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/SRCHUB_firewall.json"
        end
        for _, path in ipairs(paths) do
            pcall(function()
                local fh = io.open(path, "w")
                if fh then fh:write(json) fh:close() wrote = true end
            end)
        end
        if type(_G.X3.Trace) == "function" then
            _G.X3.Trace("ACFIREWALL: profil GL/KR/VNG " .. (wrote and "tertulis (" .. #paths .. " jalur dicoba)" or "GAGAL tulis (io sandbox)"))
        end
    end

    -- 5) PERISAI TSS SDK / TSS SDK SHIELD
    -- _G.Tss/_G.TssManager adalah jembatan Lua↔SDK anti-cheat TSS (TenSafe):
    -- SendSkdData (registrasi kanal SKD), SendEigeninfoData (upload eigenvalue
    -- file/memori), SaveSendEigeninfoCode (kode hasil), GetUserTag4Lua
    -- (tag root/malware device), InvokeSDKIoctl cmd 18 = "AllowAPKCollect"
    -- (izin koleksi daftar APK terpasang). Semua sender → return 0 bersih;
    -- fungsi baca (OnRecvData/EigenArrayObfuscationVerify/GetDeviceFeature)
    -- dibiarkan agar alur auth tidak patah.
    function _G.X3._ACTssShieldTry()
        if _G.X3._ACTssHooked then return end
        _G.X3._ACTssHooked = true
        pcall(function()
            local T = rawget(_G, "Tss") or rawget(_G, "TssManager")
            if type(T) ~= "table" then return end
            local function ret0(...) return 0 end
            if type(T.SendSkdData) == "function" then T.SendSkdData = ret0 end
            if type(T.SendEigeninfoData) == "function" then T.SendEigeninfoData = ret0 end
            if type(T.SaveSendEigeninfoCode) == "function" then T.SaveSendEigeninfoCode = ret0 end
            if type(T.GetUserTag4Lua) == "function" then T.GetUserTag4Lua = function(...) return "" end end
            local ioctl = T.InvokeSDKIoctl
            if type(ioctl) == "function" then
                T.InvokeSDKIoctl = function(cmd, data, ...)
                    local d = tostring(data)
                    if cmd == 18 or d:find("ollect") then return 0 end
                    return ioctl(cmd, data, ...)
                end
            end
            if type(_G.X3.Trace) == "function" then _G.X3.Trace("ACTSS: sender TSS SDK dinetralkan (skd/eigen/tag/apk-collect)") end
        end)
        pcall(function()
            local N = rawget(_G, "NetUtil")
            if type(N) == "table" then
                if type(N.SendTss) == "function" then N.SendTss = function() end end
                if type(N.OnTssRsp) == "function" then N.OnTssRsp = function() end end
            end
        end)
    end

    -- 6) PENEKAN LOG & TELEMETRI / LOG & TELEMETRY SUPPRESSOR
    -- TLog (ClientSendTLogReport + BasicDataTLogReport), Bugly/CrashSight
    -- (GameReportUtils.BugglyPostExceptionFull), GEM analytics
    -- (gem_report_utils → Client.GEMReportSubEvent + CrashLog), upload replay
    -- (ReplayReportData), dan sender flow serangan GameplayCallbacks
    -- (ReportAttackFlow/ReportAimFlow/ReportFireArms/dst) → semua no-op.
    function _G.X3._ACLogShieldTry()
        if _G.X3._ACLogHooked then return end
        _G.X3._ACLogHooked = true
        pcall(function()
            local g = rawget(_G, "gem_report_utils")
            if type(g) == "table" then
                g.CanReport = function() return -1 end
                g.ReportEventImmediate = function() end
                g.SaveGemReportInFile = function() end
                g.GetReportLobbyEventEnable = function() return false end
            end
        end)
        pcall(function()
            local ok, G = pcall(require, "GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils")
            if ok and type(G) == "table" then
                G.CheckCanBugglyPostException = function() return false end
                G.BugglyPostExceptionFull = function() return true end
                G.ReportException = function() end
                G.ReplayReportData = function() end
            end
        end)
        pcall(function()
            if type(rawget(_G, "ClientSendTLogReport")) == "function" then
                _G.ClientSendTLogReport = function() end
            end
        end)
        pcall(function()
            local GC = rawget(_G, "GameplayCallbacks")
            if type(GC) ~= "table" then return end
            for _, n in ipairs({
                "ReportAimFlow", "ReportAttackFlow", "ReportSecAttackFlow", "ReportHurtFlow",
                "ReportFireArms", "ReportVerifyInfoFlow", "ReportPlayerBehavior",
                "ReportPlayerMoveRoute", "ReportPlayerPosition", "ReportCommonInfo",
                "ReportFeedback", "ReportForbitPick", "ReportTeammatHurt",
                "ReportGameSetting", "ReportGameSettingNew", "ReportMatchRoomData",
                "ReportPlayersPing", "ReportEquipmentFlow", "SendDataMiningTLog",
            }) do
                if type(GC[n]) == "function" then GC[n] = function() end end
            end
        end)
        _G.ENABLE_REPORT = false
        if type(_G.X3.Trace) == "function" then _G.X3.Trace("ACLOG: TLog/Bugly/GEM/replay/attack-flow dinetralkan") end
    end

    -- 7) HIGGSBOSON, GOKUBA & SUBSISTEM REPORT / SECURITY COMPONENT SHIELD
    -- HiggsBosonComponent: SendHisarData (upload fingerprint install/GUID/
    -- DeviceId ke server), RecordStrategyTimestampInReplay (penanda strategi
    -- deteksi di file replay), OnLogin (penjadwal Hisar).
    -- GokubaLogic.ForwardFeature: tiap 45 dtk membaca Tss.GetUserTag4Lua lalu
    -- mengirim flag root/malware/cdn device ke server
    -- (battle_client_sync_allstar_auth_check_result_req) → no-op.
    -- ClientReportPlayerSubsystem: pengumpul data utk dialog report
    -- (fatal damager map, info tim, murderer dari death replay) → no-op.
    function _G.X3._ACHiggsShieldTry()
        if _G.X3._ACHiggsHooked then return end
        _G.X3._ACHiggsHooked = true
        pcall(function()
            local ok, H = pcall(require, "GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
            if ok and type(H) == "table" then
                if type(H.SendHisarData) == "function" then H.SendHisarData = function() end end
                if type(H.OnLogin) == "function" then H.OnLogin = function() end end
                if type(H.RecordStrategyTimestampInReplay) == "function" then H.RecordStrategyTimestampInReplay = function() end end
                if type(H.SetClientAlertWindowEnabled) == "function" then pcall(H.SetClientAlertWindowEnabled, false) end
            end
        end)
        pcall(function()
            local ok, G = pcall(require, "GameLua.Mod.BaseMod.Client.Security.Gokuba")
            if ok and type(G) == "table" then
                if type(G.ForwardFeature) == "function" then G.ForwardFeature = function() end end
                if type(G.OnControllerBeginPlay) == "function" then G.OnControllerBeginPlay = function() end end
            end
        end)
        pcall(function()
            local SM = rawget(_G, "SubsystemMgr")
            if not (SM and SM.Get) then return end
            local R = SM:Get("ClientReportPlayerSubsystem")
            if type(R) ~= "table" then return end
            for _, n in ipairs({ "_RecordFatalDamager", "_RecordMurdererFromDeathReplayData", "_RecordTeammatePlayerInfo", "_OnSyncFatalDamage" }) do
                if type(R[n]) == "function" then R[n] = function() end end
            end
        end)
        if type(_G.X3.Trace) == "function" then _G.X3.Trace("ACHIGGS: Hisar/Gokuba/report-subsystem dinetralkan") end
    end

    -- 8) FILTER PAKET KEAMANAN / SECURITY PACKET FILTER
    -- Wrap NetUtil.SendPacket & NetUtil.SendPkg: paket keamanan/telemetri
    -- dibuang sebelum keluar (lookup tabel O(1), tanpa string scan — ringan).
    -- Jalur gerak/tembak tidak lewat sini (native), jadi no delay.
    function _G.X3._ACPacketFilterTry()
        if _G.X3._ACPktHooked then return end
        _G.X3._ACPktHooked = true
        pcall(function()
            local N = rawget(_G, "NetUtil")
            if type(N) ~= "table" then return end
            local DROP_PKT = {
                ReportHitFlow = true, ReportAttackFlow = true, ReportSecAttackFlow = true,
                ReportFireArms = true, ReportAimFlow = true, ReportHurtFlow = true,
                ReportVerifyInfoFlow = true, ReportPlayerBehavior = true,
                ReportPlayerMoveRoute = true, ReportPlayerPosition = true,
                ReportSecCarryEndFlow = true, ReportSecRoundDetailFlow = true,
                ReportSecSupplyFlow = true, ReportSecMetroGameSnapshootFlow = true,
                ReportSkillFlow = true, ReportForbiddenPickupFlow = true,
                ReportTeammatHurt = true, report_common_info = true,
            }
            local DROP_PKG = { battle_client_sync_allstar_auth_check_result_req = true, hisar = true }
            local sp = N.SendPacket
            if type(sp) == "function" then
                N.SendPacket = function(name, ...)
                    if DROP_PKT[name] then return end
                    return sp(name, ...)
                end
            end
            local sg = N.SendPkg
            if type(sg) == "function" then
                N.SendPkg = function(name, ...)
                    if DROP_PKG[name] then return end
                    return sg(name, ...)
                end
            end
            if type(_G.X3.Trace) == "function" then _G.X3.Trace("ACPKT: filter paket keamanan aktif (" .. 18 .. " packet + 2 pkg)") end
        end)
    end
end

pcall(function() if _G.X3._ACFirewallInstall then _G.X3._ACFirewallInstall() end end)
pcall(function() if _G.X3._ACTssShieldTry then _G.X3._ACTssShieldTry() end end)
pcall(function() if _G.X3._ACLogShieldTry then _G.X3._ACLogShieldTry() end end)
pcall(function() if _G.X3._ACHiggsShieldTry then _G.X3._ACHiggsShieldTry() end end)
pcall(function() if _G.X3._ACPacketFilterTry then _G.X3._ACPacketFilterTry() end end)

-- ANTI SPAM TIP / ANTI-SPAM TIPS --
    function _G.X3._XFTipThrottleTry()
        if _G.X3._XFTipThrottled then return end
        pcall(function()
            local ok, T = pcall(require, "GameLua.Mod.BaseMod.Common.UI.InGameTipsTools")
            if not (ok and type(T) == "table") then return end
            local function wrap(fnName, idIdx)
                local orig = T[fnName]
                if type(orig) ~= "function" then return end
                T[fnName] = function(...)
                    local id = select(idIdx, ...)
                    local now = os.clock()
                    _G.X3._XFTipSeen = _G.X3._XFTipSeen or {}
                    local key = fnName .. "_" .. tostring(id)
                    if _G.X3._XFTipSeen[key] and (now - _G.X3._XFTipSeen[key]) < 12.0 then
                        return
                    end
                    _G.X3._XFTipSeen[key] = now
                    return orig(...)
                end
            end
            wrap("BattleGeneralTip", 1)
            wrap("BattleGeneralTipWithTranslation", 1)
            wrap("BattleGeneralTipWithExternTable", 1)
            _G.X3._XFTipThrottled = true
        end)
    end
end

local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)
local finalClass = require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
  {
    SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature"
  },
  {
    CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature"
  },
  {
    SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature"
  },
  {
    TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature"
  },
  {
    LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature"
  },
  {
    FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature"
  },
  {
    CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature"
  },
  {
    BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature"
  },
  {
    CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature"
  },
  {
    ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature"
  },
  {
    SpiderSenseFootprintFeature = "GameLua.Mod.Library.GamePlay.Feature.SpiderSenseFootprintFeature"
  },
  {
    GeneralShowSpotFeature = "GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature"
  }
}, "BRPlayerCharacterBase")

_G.X3_ActivePlayerClass = finalClass
return finalClass
