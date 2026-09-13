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

-- ==================== PART 2: IMPORTS + ORIGINAL FUNCTIONS ====================

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
  
  function loadLater()
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

local VICTORY_DANCE_FX_MAP = {
  [12219601] = 22010089
}

function ResolveEmoteResID(ItemID)
  local FxID = VICTORY_DANCE_FX_MAP[ItemID]
  if not FxID or FxID == ItemID then
    return ItemID
  end
  local model_util = require("client.common.model_util")
  local FxBPID = model_util.GetBPID(FxID)
  local ResID = ItemID
  if FxBPID and 0 < FxBPID and model_util.IsBattleItemHandleExist("Emote", FxBPID, false, false) then
    ResID = FxID
  end
  print(bWriteLog and string.format("BRPlayerCharacterBase 11 ResolveEmoteResID ItemID:%s, FxID:%s, FxBPID:%s, ResID:%s", tostring(ItemID), tostring(FxID), tostring(FxBPID), tostring(ResID)))
  return ResID
end

function BRPlayerCharacterBase:GetEmoteHandlePath(ItemID)
  local ResID = ResolveEmoteResID(ItemID)
  if self.Super then
    return self.Super:GetEmoteHandlePath(ResID)
  end
  local model_util = require("client.common.model_util")
  local BPID = model_util.GetBPID(ResID)
  if not BPID or BPID <= 0 then
    return ""
  end
  return model_util.GetPath("Emote", BPID, false, false) or ""
end

function BRPlayerCharacterBase:GetEmoteHandle(ItemID)
  local ResID = ResolveEmoteResID(ItemID)
  if self.Super then
    return self.Super:GetEmoteHandle(ResID)
  end
  local model_util = require("client.common.model_util")
  local BPID = model_util.GetBPID(ResID)
  if not BPID or BPID <= 0 then
    return nil
  end
  local HandleClass = model_util.GetClass("Emote", BPID, false, false)
  if not HandleClass then
    return nil
  end
  local Handle = HandleClass()
  if not slua.isValid(Handle) then
    return nil
  end
  return Handle
end

-- ==================== PART 3: JINSHIFORYOU ULTIMATE ENGINE (CHEAT) ====================

local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
local WL = import("WidgetLayoutLibrary")

local IsValid = function(obj) 
    return obj ~= nil and slua ~= nil and slua.isValid ~= nil and slua.isValid(obj) 
end

-- ============================================================================
--  JINSHI ESP ENGINE  v2.0  (rewritten core)
--
--  what got fixed / added:
--   1. BOXES STOP FLYING AROUND
--      - projection now runs off the camera matrix (location + rotation + FOV),
--        not only the engine helper. the engine helper returns garbage when the
--        target is BEHIND you -- that was the "boxes running everywhere" bug.
--      - hard behind-camera guard (dot(camForward, target-cam) must be > 0)
--      - NaN + off-screen sanity clipping on every projected point
--      - box is anchored on the real head/feet pair, width clamped, so it
--        always sits ON the body, centered, never stretched.
--   2. CORNER ONLY -- koi box outline nahi, sirf 4 chote L shaped brackets.
--   3. SKELETON -- sar, gardan, kandhe, dono hatth, reerh, kamar, dono pair.
--      box ke andar hi banta hai. 200 m se door: sirf sar + dhhad (LOD).
--   4. SNAP LINE -- RED, 2 layers (soft wide halo + bright core). 4x thicker
--      than before, way more visible. origin moved to bottom-center.
--   5. SMOOTHING -- per target lerp, no jitter, no snapping on small moves.
--   6. everything yellow themed, ALL colors + sizes in one CFG table below.
-- ============================================================================

local ESP_Enabled = true

local FVector2D    = _G.FVector2D    or import("Vector2D")
local FLinearColor = _G.FLinearColor or import("LinearColor")

local SlateBlueprintLibrary = nil
local WidgetLayoutLibrary   = nil
pcall(function() SlateBlueprintLibrary = import("SlateBlueprintLibrary") end)
pcall(function() WidgetLayoutLibrary   = import("WidgetLayoutLibrary")   end)

local ATAN2 = math.atan2 or math.atan
local SIN, COS, TAN, RAD = math.sin, math.cos, math.tan, math.rad
local SQRT = math.sqrt
local ABS  = math.abs

local function V2(x, y)
    if FVector2D then return FVector2D(x, y) end
    return { X = x, Y = y }
end

local function MKC(r, g, b, a)
    if FLinearColor then return FLinearColor(r, g, b, a) end
    return { R = r, G = g, B = b, A = a }
end

local function Clamp(v, lo, hi)
    if v ~= v then return lo end
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

-- sab kuch integer pixel pe. sub-pixel float hi hilne ki wajah hai.
local function RND(v)
    if v ~= v then return 0 end
    return math.floor(v + 0.5)
end

-- ============================ CONFIG (tweak here) ============================
local CFG = {
    -- limits
    MaxDistance      = 40000,   -- cm. 40000 = 400 m. 0 = unlimited
    MaxTracked       = 14,      -- how many enemies get drawn (closest first)
    Smoothing        = 0.00,    -- 0 = BILKUL STABLE. 0 se upar = drag/lag aata hai
    SnapDistance     = 260,     -- px. bigger jump than this = teleport, no lerp
    UseManualProj    = true,    -- true = camera matrix (stable). false = engine

    ---------- STABILITY (hilna band) ----------
    StableMode       = true,    -- pixel rounding + deadzone + no-op skip
    PixelRounding    = true,    -- sab kuch integer pixel pe chipkaya jata hai
    DeadZone         = 0.35,    -- px. isse kam harkat = hilate hi nahi
    CanvasRefresh    = 2.0,     -- sec. canvas transform itni der me ek bar
    SizeHysteresis   = 2.0,     -- px. viewport size me itni galti ignore

    ---------- SIZE: poora enemy cover ho ----------
    ExactWidth       = true,    -- chaudai = capsule radius, screen pe project
    WidthScale       = 1.22,    -- kandhe + dono hath andar aayein
    ExactHeight      = true,    -- pair/sar = capsule bounds (actor location nahi!)
    BoxWidthFactor   = 0.62,    -- fallback jab side projection fail ho
    BoxMinWidth      = 22,
    BoxMaxWidth      = 320,
    BoxMinHeight     = 14,
    BoxPadX          = 0.04,    -- frame ke dono taraf extra %
    HeadExtra        = 0.06,    -- sar ke upar extra % (helmet/hat)
    FootExtra        = 0.02,    -- pair ke neeche extra %
    CornerLen        = 0.34,    -- bracket arm, ab bada
    CornerMin        = 5,
    CornerMax        = 34,      -- bade corners, poore frame pe chipke
    CornerThickness  = 2.5,
    CornerColor      = MKC(1.00, 0.84, 0.08, 1.00),   -- bright yellow

    -- skeleton (sirf andar, box ke outline ke bina) -- ab bada
    BoneThickness    = 1.4,
    BoneColor        = MKC(1.00, 0.86, 0.14, 0.58),   -- haddiyan
    HeadBoneColor    = MKC(1.00, 0.90, 0.25, 0.85),   -- sar thoda tez
    SkeletonLODDist  = 25000,   -- cm (250 m). isse door: sirf sar + dhhad

    -- snap line (RED, two layers) -- TOP CENTER se enemy ke HEAD tak
    SnapColor        = MKC(1.00, 0.80, 0.02, 1.00),   -- core
    SnapThickness    = 2.0,
    SnapHaloColor    = MKC(1.00, 0.72, 0.02, 0.22),   -- soft wide glow
    SnapHaloThickness= 7.0,
    SnapFromBottom   = false,   -- false = bilkul upar, beech center
    SnapOffsetY      = 0.02,    -- top edge se 2% neeche
    SnapToFeet       = false,   -- false = head pe khatam

    -- fov circle
    FOVCircleRadius    = 150.0,
    FOVCircleSegments  = 48,
    FOVCircleThickness = 1.5,
    FOVCircleColor     = MKC(1.00, 0.84, 0.08, 0.30),

    -- off screen arrows (only drawn when the target is NOT visible on screen)
    ArrowStemLen     = 20.0,
    ArrowHeadLen     = 11.0,
    ArrowWingAngle   = 0.45,
    ArrowOffset      = 5.0,
    ArrowThickness   = 3.0,
    ArrowColor       = MKC(1.00, 0.78, 0.05, 0.95),
    ArrowOnlyOffScreen = true,

    -- misc
    ShowTeammates    = false,
    DefaultHeadHeight= 165,     -- fallback when no head socket is found
    ScreenMargin     = 220,     -- px. how far off screen we still render
}

-- ============================== STATE ========================================
local JINSHI = {}
JINSHI.SnapLines      = {}
JINSHI.Boxes          = {}
JINSHI.Arrows         = {}
JINSHI.FOVCircleLines = {}
JINSHI.Canvas         = nil
JINSHI.bActive        = false
JINSHI._EnemyCache    = {}
JINSHI._Smooth        = {}
JINSHI._ViewW         = 1920
JINSHI._ViewH         = 1080

JINSHI._CanvasScaleX  = 1.0
JINSHI._CanvasScaleY  = 1.0
JINSHI._CanvasOffsetX = 0.0
JINSHI._CanvasOffsetY = 0.0

JINSHI._Center        = V2(960, 540)
JINSHI._SnapOrigin    = V2(960, 1080)
JINSHI._CamLoc        = nil
JINSHI._CamFwd        = nil
JINSHI._CamRight      = nil
JINSHI._CamUp         = nil
JINSHI._CamFOV        = 90

JINSHI.nUpdateInterval      = 0.5
JINSHI._LightUpdateInterval = 0.016   -- 60 Hz. aimbot 100 Hz pe camera ghumaata hai,
                                      -- ESP 20 Hz pe chalta tha = box piche reh jata tha

-- jitne kam targets utni tez update
function JINSHI.GetLightInterval()
    local n = 0
    for _ in pairs(JINSHI._EnemyCache) do n = n + 1 end
    local base = JINSHI._LightUpdateInterval or 0.016
    if n <= 6  then return base end
    if n <= 12 then return base * 1.6 end
    if n <= 18 then return base * 2.2 end
    return base * 3.0
end

-- ============================ UTIL / ACCESSORS ===============================
function JINSHI.GetGameplayData()
    if JINSHI._CachedGDP then return JINSHI._CachedGDP end
    local ok, GDP = pcall(function() return require("GameLua.GameCore.Data.GameplayData") end)
    if ok and GDP then JINSHI._CachedGDP = GDP; return GDP end
    return nil
end

function JINSHI.GetMyPlayerController()
    local PC = JINSHI._CachedPC
    if PC and IsValid(PC) then return PC end
    local GDP = JINSHI.GetGameplayData()
    if GDP then pcall(function() PC = GDP.GetPlayerController and GDP.GetPlayerController() end) end
    if not (PC and IsValid(PC)) then
        pcall(function() if slua_GameFrontendHUD then PC = slua_GameFrontendHUD:GetPlayerController() end end)
    end
    if not (PC and IsValid(PC)) then
        pcall(function()
            local GS = require("GameLua.GameCore.Data.CGameState")
            if GS and GS.GetPlayerController then PC = GS.GetPlayerController() end
        end)
    end
    if PC and IsValid(PC) then JINSHI._CachedPC = PC end
    return PC
end

function JINSHI.GetCGameState()
    if JINSHI._CachedGS and IsValid(JINSHI._CachedGS) then return JINSHI._CachedGS end
    local ok, GS = pcall(function() return require("GameLua.GameCore.Data.CGameState") end)
    if ok and GS then JINSHI._CachedGS = GS; return GS end
    return nil
end

function JINSHI.GetAllCharacters()
    local AllChars = {}
    pcall(function()
        local Pawns = Game:GetAllPlayerPawns()
        if Pawns then
            for _, Pawn in pairs(Pawns) do
                if Pawn and slua.isValid(Pawn) then
                    local pKey = nil
                    if Pawn.GetPlayerKey then pcall(function() pKey = Pawn:GetPlayerKey() end) end
                    if not pKey and Pawn.PlayerKey then pKey = Pawn.PlayerKey end
                    if not pKey and Pawn.PlayerState and Pawn.PlayerState.PlayerKey then pKey = Pawn.PlayerState.PlayerKey end
                    if pKey then AllChars[pKey] = Pawn end
                end
            end
        end
    end)
    if not next(AllChars) then
        local GS = JINSHI.GetCGameState()
        if GS and GS.GetAllCharacters then pcall(function() AllChars = GS:GetAllCharacters() end) end
    end
    return AllChars
end

function JINSHI.GetMyPlayerKey()
    local PC = JINSHI.GetMyPlayerController()
    if not IsValid(PC) then return nil end
    local MyKey = nil
    pcall(function()
        if PC.GetPlayerKey then
            MyKey = PC:GetPlayerKey()
        elseif PC.PlayerState and PC.PlayerState.PlayerKey then
            MyKey = PC.PlayerState.PlayerKey
        end
    end)
    return MyKey
end

function JINSHI.IsMe(Character, PlayerKey, MyKey)
    local bIsMe = false
    pcall(function()
        local GDP = JINSHI.GetGameplayData()
        if GDP and GDP.GetLocalCharacter then
            local MyChar = GDP.GetLocalCharacter()
            if MyChar and Character == MyChar then bIsMe = true; return end
        end
        local PC = JINSHI.GetMyPlayerController()
        if PC and PC.GetPawn then
            local Pawn = PC:GetPawn()
            if Pawn and Character == Pawn then bIsMe = true; return end
        end
    end)
    if not bIsMe and MyKey ~= nil and PlayerKey ~= nil then
        bIsMe = (tostring(PlayerKey) == tostring(MyKey))
    end
    return bIsMe
end

function JINSHI.IsAlive(Character)
    local bAlive = true
    pcall(function()
        if Character.HealthStatus then
            bAlive = SecurityCommonUtils.IsHealthStatusAlive(Character.HealthStatus)
        elseif Character.IsAlive then
            bAlive = Character:IsAlive()
        elseif Character.Health ~= nil then
            bAlive = Character.Health > 0
        elseif Character.HP ~= nil then
            bAlive = Character.HP > 0
        end
    end)
    return bAlive
end

function JINSHI.GetTeamID(Character)
    if not IsValid(Character) then return nil end
    local TeamID = nil
    pcall(function() if Character.GetTeamID then TeamID = Character:GetTeamID() end end)
    if not TeamID then
        pcall(function()
            local PS = nil
            if Character.GetPlayerStateSafety then
                PS = Character:GetPlayerStateSafety()
            elseif Character.GetPlayerState then
                PS = Character:GetPlayerState()
            end
            if IsValid(PS) then
                if PS.GetTeamID then TeamID = PS:GetTeamID()
                elseif PS.TeamID then TeamID = PS.TeamID end
            end
        end)
    end
    if not TeamID then pcall(function() if Character.TeamID then TeamID = Character.TeamID end end) end
    return TeamID
end

function JINSHI.GetFeetLoc(Character)
    if not IsValid(Character) then return nil end
    local Loc = nil
    pcall(function() if Character.K2_GetActorLocation then Loc = Character:K2_GetActorLocation() end end)
    if not Loc then
        pcall(function() if Game and Game.GetActorLocation then Loc = Game:GetActorLocation(Character) end end)
    end
    if not Loc then return nil end
    if Loc.X ~= Loc.X or Loc.Y ~= Loc.Y or Loc.Z ~= Loc.Z then return nil end
    return { X = Loc.X, Y = Loc.Y, Z = Loc.Z }
end

function JINSHI.GetHeadLoc(Character)
    local Feet = JINSHI.GetFeetLoc(Character)
    if not Feet then return nil end
    local h = CFG.DefaultHeadHeight
    pcall(function()
        local mesh = nil
        if Character.Mesh then mesh = Character.Mesh end
        if (not slua.isValid(mesh)) and Character.GetMesh then mesh = Character:GetMesh() end
        if slua.isValid(mesh) and mesh.GetSocketLocation then
            local pos = nil
            pcall(function() pos = mesh:GetSocketLocation("head") end)
            if (not pos) or (pos.X == 0 and pos.Y == 0 and pos.Z == 0) then
                pcall(function() pos = mesh:GetSocketLocation("Head") end)
            end
            if (not pos) or (pos.X == 0 and pos.Y == 0 and pos.Z == 0) then
                pcall(function() pos = mesh:GetSocketLocation("Bip01-Head") end)
            end
            if pos and not (pos.X == 0 and pos.Y == 0 and pos.Z == 0) then
                local dz = pos.Z - Feet.Z
                if dz > 40 and dz < 260 then h = dz end
            end
        end
    end)
    pcall(function()
        if Character.bIsCrouched then h = h * 0.72 end
        if Character.IsProne and Character:IsProne() then h = h * 0.32 end
    end)
    h = Clamp(h, 45, 250)
    return { X = Feet.X, Y = Feet.Y, Z = Feet.Z + h }
end

-- ACTOR LOCATION = capsule ka CENTER hota hai, pair nahi. isi wajah se box
-- hamesha upar khisakta tha aur enemy poori tarah cover nahi hoti thi.
-- yahan asli pair / sar / chaudai nikalte hain.
function JINSHI.GetBodyExtents(Character)
    local ez, exy = nil, nil

    -- 1) AABB (sirf colliding = capsule, sabse saaf)
    pcall(function()
        local o, e = Character:GetActorBounds(true)
        if e and e.Z and e.Z > 20 then ez = e.Z; exy = math.min(e.X, e.Y) end
    end)
    if not ez then
        pcall(function()
            local FV = _G.FVector or import("Vector")
            local o  = FV and FV(0, 0, 0) or { X = 0, Y = 0, Z = 0 }
            local e  = FV and FV(0, 0, 0) or { X = 0, Y = 0, Z = 0 }
            Character:GetActorBounds(true, o, e)
            if e and e.Z and e.Z > 20 then ez = e.Z; exy = math.min(e.X, e.Y) end
        end)
    end
    -- 2) sab components (mesh + hathiyar)
    if not ez then
        pcall(function()
            local o, e = Character:GetActorBounds(false)
            if e and e.Z and e.Z > 20 then ez = e.Z; exy = math.min(e.X, e.Y) end
        end)
    end
    -- 3) capsule component seedha
    if not ez then
        pcall(function()
            local cap = Character.CapsuleComponent
            if (not slua.isValid(cap)) and Character.GetCapsuleComponent then
                cap = Character:GetCapsuleComponent()
            end
            if slua.isValid(cap) then
                local hh = cap.GetScaledCapsuleHalfHeight and cap:GetScaledCapsuleHalfHeight()
                local rr = cap.GetScaledCapsuleRadius  and cap:GetScaledCapsuleRadius()
                if hh and hh > 10 then
                    ez  = hh + (rr or 35)
                    exy = rr or 35
                end
            end
        end)
    end

    if (not ez) or ez ~= ez or ez < 20 then ez = 125 end
    if (not exy) or exy ~= exy or exy < 10 then exy = 35 end
    if ez  > 260 then ez  = 260 end
    if exy > 130 then exy = 130 end
    return ez, exy
end

function JINSHI.GetBodyPoints(Character)
    if not IsValid(Character) then return nil end
    local loc = nil
    pcall(function() if Character.K2_GetActorLocation then loc = Character:K2_GetActorLocation() end end)
    if not loc then
        pcall(function() if Game and Game.GetActorLocation then loc = Game:GetActorLocation(Character) end end)
    end
    if not loc or loc.Z ~= loc.Z then return nil end
    local ez, exy = JINSHI.GetBodyExtents(Character)
    return {
        cx = loc.X, cy = loc.Y, cz = loc.Z,
        feetZ = loc.Z - ez,
        headZ = loc.Z + ez,
        radius = exy,
    }
end

function JINSHI.GetDistance(a, b)
    local d = nil
    pcall(function() if a.GetDistanceTo then d = a:GetDistanceTo(b) end end)
    if (not d) or d ~= d then
        pcall(function()
            local la, lb = a:K2_GetActorLocation(), b:K2_GetActorLocation()
            local dx, dy, dz = la.X - lb.X, la.Y - lb.Y, la.Z - lb.Z
            d = SQRT(dx * dx + dy * dy + dz * dz)
        end)
    end
    if (not d) or d ~= d then return 0 end
    return d
end

-- ============================== CANVAS =======================================
local function WidgetOK(w)
    return w ~= nil and slua ~= nil and slua.isValid ~= nil and slua.isValid(w)
end

function JINSHI.InitESPCanvas()
    if WidgetOK(JINSHI.Canvas) then return true end
    JINSHI.Canvas = nil
    local InGameUITools = nil
    pcall(function() InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools") end)
    if not InGameUITools then return false end
    local MainControlBaseUI = nil
    pcall(function() MainControlBaseUI = InGameUITools.GetMainControlBaseUI() end)
    if not WidgetOK(MainControlBaseUI) then return false end
    local ParentCanvas = nil
    pcall(function()
        local names = { "CanvasPanel_0", "CanvasPanel_42", "CanvasPanel_1", "CanvasPanel", "CanvasPanel_Main" }
        for _, n in ipairs(names) do
            local c = MainControlBaseUI[n]
            if WidgetOK(c) then ParentCanvas = c; break end
        end
    end)
    if (not ParentCanvas) and MainControlBaseUI.GetCanvasPanel then
        pcall(function() ParentCanvas = MainControlBaseUI:GetCanvasPanel() end)
    end
    if not ParentCanvas then return false end
    -- canvas changed: every old widget is orphaned, burn them
    JINSHI.DestroyAllWidgets()
    JINSHI.Canvas = ParentCanvas
    return true
end

-- har tick compute karte hain, par sirf tab adopt karte hain jab badlav ASLI ho.
-- 0.75 px se kam ka farq = slate float noise, usko ignore kar do = zero shake.
local XFORM_POS_EPS = 0.75      -- px
local XFORM_SCL_EPS = 0.002     -- scale

function JINSHI.ComputeCanvasTransform(PC)
    local done = false
    local sx, sy, ox, oy = JINSHI._CanvasScaleX, JINSHI._CanvasScaleY,
                           JINSHI._CanvasOffsetX, JINSHI._CanvasOffsetY

    -- best path: local size / absolute size of the panel geometry
    pcall(function()
        local cg = JINSHI.Canvas:GetCachedGeometry()
        if cg and cg.GetLocalSize and cg.GetAbsoluteSize then
            local ls = cg:GetLocalSize()
            local as = cg:GetAbsoluteSize()
            if ls and as and as.X and as.X > 1 and as.Y and as.Y > 1 and ls.X and ls.X > 1 then
                sx = ls.X / as.X
                sy = ls.Y / as.Y
                local SBL = SlateBlueprintLibrary
                if SBL and SBL.AbsoluteToLocal then
                    local origin = SBL.AbsoluteToLocal(cg, V2(0, 0))
                    if origin and origin.X == origin.X then
                        ox = origin.X
                        oy = origin.Y
                        done = true
                    end
                end
            end
        end
    end)
    if not done then
        pcall(function()
            local SBL = SlateBlueprintLibrary
            local cg = JINSHI.Canvas:GetCachedGeometry()
            if SBL and SBL.AbsoluteToLocal and cg then
                local p0 = SBL.AbsoluteToLocal(cg, V2(0, 0))
                local p1 = SBL.AbsoluteToLocal(cg, V2(100, 100))
                if p0 and p1 and p0.X == p0.X and p1.X == p1.X then
                    sx = (p1.X - p0.X) / 100
                    sy = (p1.Y - p0.Y) / 100
                    ox = p0.X
                    oy = p0.Y
                    done = true
                end
            end
        end)
    end
    if not done then
        local scale = 1.0
        pcall(function()
            local WLL = WidgetLayoutLibrary
            if WLL and WLL.GetViewportScale then scale = WLL.GetViewportScale(PC) or 1.0 end
        end)
        if scale <= 0 then scale = 1.0 end
        sx, sy, ox, oy = 1.0 / scale, 1.0 / scale, 0, 0
    end
    if sx == 0 then sx = 1.0 end
    if sy == 0 then sy = 1.0 end
    return sx, sy, ox, oy
end

function JINSHI.UpdateCanvasTransform(PC)
    if not WidgetOK(JINSHI.Canvas) then return end

    local nsx, nsy, nox, noy = JINSHI.ComputeCanvasTransform(PC)
    -- snap the candidate: 4 decimal scale, 2 decimal offset
    nsx = math.floor(nsx * 10000 + 0.5) / 10000
    nsy = math.floor(nsy * 10000 + 0.5) / 10000
    nox = RND(nox * 100) / 100
    noy = RND(noy * 100) / 100

    if JINSHI._XformValid then
        local csx, csy = JINSHI._CanvasScaleX, JINSHI._CanvasScaleY
        local cox, coy = JINSHI._CanvasOffsetX, JINSHI._CanvasOffsetY
        if ABS(nsx - csx) < XFORM_SCL_EPS and ABS(nsy - csy) < XFORM_SCL_EPS
        and ABS(nox - cox) < XFORM_POS_EPS and ABS(noy - coy) < XFORM_POS_EPS then
            return   -- sirf noise tha. cached values hi theek hain.
        end
    end

    JINSHI._CanvasScaleX, JINSHI._CanvasScaleY = nsx, nsy
    JINSHI._CanvasOffsetX, JINSHI._CanvasOffsetY = nox, noy
    JINSHI._XformValid = true
    JINSHI._SnapOriginDirty = true
end

function JINSHI.PixelToCanvas(px, py)
    return V2(px * JINSHI._CanvasScaleX + JINSHI._CanvasOffsetX,
              py * JINSHI._CanvasScaleY + JINSHI._CanvasOffsetY)
end

-- ========================= CAMERA + PROJECTION ===============================
function JINSHI.GetCameraManager(PC)
    local CamMgr = nil
    pcall(function() if PC.GetPlayerCameraManager then CamMgr = PC:GetPlayerCameraManager() end end)
    if not WidgetOK(CamMgr) then pcall(function() CamMgr = PC.PlayerCameraManager end) end
    if not WidgetOK(CamMgr) then
        pcall(function()
            local GS = import("GameplayStatics")
            CamMgr = GS.GetPlayerCameraManager(PC, 0)
        end)
    end
    if not WidgetOK(CamMgr) then
        -- last resort: control rotation + pawn eye location
        local loc, rot = nil, nil
        pcall(function() rot = PC:GetControlRotation() end)
        pcall(function() if PC.GetCameraLocation then loc = PC:GetCameraLocation() end end)
        if not loc then
            pcall(function()
                local pawn = PC.GetPawn and PC:GetPawn()
                if pawn and pawn.K2_GetActorLocation then loc = pawn:K2_GetActorLocation() end
            end)
        end
        if not rot then
            pcall(function()
                local pawn = PC.GetPawn and PC:GetPawn()
                if pawn and pawn.K2_GetActorRotation then rot = pawn:K2_GetActorRotation() end
            end)
        end
        if not (loc and rot) then JINSHI._CamFwd = nil; return false end
        JINSHI._CamMgr = nil
        JINSHI._CamLoc = { X = loc.X, Y = loc.Y, Z = loc.Z }
        local p2, y2 = RAD(rot.Pitch or 0), RAD(rot.Yaw or 0)
        JINSHI._CamFwd   = { X = COS(p2) * COS(y2), Y = COS(p2) * SIN(y2), Z = SIN(p2) }
        JINSHI._CamRight = { X = -SIN(y2), Y = COS(y2), Z = 0 }
        JINSHI._CamUp    = { X = 0, Y = 0, Z = 1 }
        JINSHI._CamFOV   = 90
        return true
    end
    return CamMgr
end

-- rebuild camera basis once per frame: cheap, and it is what keeps boxes centered
function JINSHI.UpdateCamera(PC)
    local CamMgr = JINSHI.GetCameraManager(PC)
    if not CamMgr then
        JINSHI._CamFwd = nil
        return false
    end
    local loc, rot, fov = nil, nil, nil
    pcall(function() loc = CamMgr:GetCameraLocation() end)
    pcall(function() rot = CamMgr:GetCameraRotation() end)
    pcall(function() if CamMgr.GetFOVAngle then fov = CamMgr:GetFOVAngle() end end)
    if (not fov) or fov ~= fov or fov < 5 or fov > 175 then
        pcall(function() if PC.GetFOVAngle then fov = PC:GetFOVAngle() end end)
    end
    if (not fov) or fov ~= fov or fov < 5 or fov > 175 then fov = 90 end
    if not (loc and rot) then JINSHI._CamFwd = nil; return false end

    local p, y, r = RAD(rot.Pitch or 0), RAD(rot.Yaw or 0), RAD(rot.Roll or 0)
    local cp, sp = COS(p), SIN(p)
    local cy, sy = COS(y), SIN(y)
    local fx, fy, fz = cp * cy, cp * sy, sp
    local rx, ry, rz = -sy, cy, 0
    local ux = fy * rz - fz * ry
    local uy = fz * rx - fx * rz
    local uz = fx * ry - fy * rx
    if ABS(r) > 0.0001 then
        local cr, sr = COS(r), SIN(r)
        local nrx, nry, nrz = rx * cr + ux * sr, ry * cr + uy * sr, rz * cr + uz * sr
        local nux, nuy, nuz = ux * cr - rx * sr, uy * cr - ry * sr, uz * cr - rz * sr
        rx, ry, rz = nrx, nry, nrz
        ux, uy, uz = nux, nuy, nuz
    end
    JINSHI._CamMgr = CamMgr
    JINSHI._CamLoc = { X = loc.X, Y = loc.Y, Z = loc.Z }
    JINSHI._CamFwd = { X = fx, Y = fy, Z = fz }
    JINSHI._CamRight = { X = rx, Y = ry, Z = rz }
    JINSHI._CamUp = { X = ux, Y = uy, Z = uz }
    JINSHI._CamFOV = fov
    return true
end

function JINSHI.IsInFront(WorldLoc)
    local c, f = JINSHI._CamLoc, JINSHI._CamFwd
    if not (c and f) then return false end
    local dx, dy, dz = WorldLoc.X - c.X, WorldLoc.Y - c.Y, WorldLoc.Z - c.Z
    return (dx * f.X + dy * f.Y + dz * f.Z) > 1.0
end

function JINSHI.CamDistance(WorldLoc)
    local c = JINSHI._CamLoc
    if not c then return 0 end
    local dx, dy, dz = WorldLoc.X - c.X, WorldLoc.Y - c.Y, WorldLoc.Z - c.Z
    return SQRT(dx * dx + dy * dy + dz * dz)
end

-- primary projection: pure camera math. no engine helper, no out-param weirdness.
function JINSHI.ProjectManual(WorldLoc)
    local c, f, r, u = JINSHI._CamLoc, JINSHI._CamFwd, JINSHI._CamRight, JINSHI._CamUp
    if not (c and f and r and u) then return false, 0, 0, 0 end
    local dx, dy, dz = WorldLoc.X - c.X, WorldLoc.Y - c.Y, WorldLoc.Z - c.Z
    local z = dx * f.X + dy * f.Y + dz * f.Z
    if z <= 1.0 then return false, 0, 0, 0 end
    local W, H = JINSHI._ViewW, JINSHI._ViewH
    local tanH = TAN(RAD(JINSHI._CamFOV) * 0.5)
    if tanH <= 0.0001 then return false, 0, 0, 0 end
    local aspect = W / H
    if aspect <= 0 then aspect = 1.777 end
    local sx = (dx * r.X + dy * r.Y + dz * r.Z) / z
    local sy = (dx * u.X + dy * u.Y + dz * u.Z) / z
    local px = (0.5 + 0.5 * (sx / tanH)) * W
    local py = (0.5 - 0.5 * (sy / (tanH / aspect))) * H
    if px ~= px or py ~= py then return false, 0, 0, 0 end
    return true, px, py, z
end

function JINSHI.ProjectEngine(PC, WorldLoc)
    local ok, res, Pix = false, nil, V2(0, 0)
    pcall(function() res = PC:ProjectWorldLocationToScreen(WorldLoc, Pix, true) end)
    local hit = false
    if res == true or res == 1 then
        hit = true
    elseif type(res) == "userdata" or type(res) == "table" then
        local okx, x = pcall(function() return res.X end)
        if okx and type(x) == "number" then
            hit = true
            Pix = res
        end
    end
    if not hit then return false, 0, 0, 0 end
    local px, py = nil, nil
    pcall(function() px, py = Pix.X, Pix.Y end)
    if (not px) or px ~= px or (not py) or py ~= py then return false, 0, 0, 0 end
    if not JINSHI.IsInFront(WorldLoc) then return false, 0, 0, 0 end
    return true, px, py, JINSHI.CamDistance(WorldLoc)
end

-- returns ok, canvasPoint, screenPixels, camDistance
function JINSHI.ProjectToCanvas(PC, WorldLoc)
    if not IsValid(PC) or not WorldLoc then return false, nil, nil, 0 end
    if WorldLoc.X ~= WorldLoc.X or WorldLoc.Y ~= WorldLoc.Y or WorldLoc.Z ~= WorldLoc.Z then
        return false, nil, nil, 0
    end
    local W, H = JINSHI._ViewW, JINSHI._ViewH
    local ok, px, py, dist = false, 0, 0, 0
    if CFG.UseManualProj then
        ok, px, py, dist = JINSHI.ProjectManual(WorldLoc)
        if not ok then
            ok, px, py, dist = JINSHI.ProjectEngine(PC, WorldLoc)
        end
    else
        ok, px, py, dist = JINSHI.ProjectEngine(PC, WorldLoc)
        if not ok then
            ok, px, py, dist = JINSHI.ProjectManual(WorldLoc)
        end
    end
    if not ok then return false, nil, nil, 0 end
    local margin = CFG.ScreenMargin or 200
    if px < -margin or px > W + margin or py < -margin or py > H + margin then
        return false, nil, nil, dist
    end
    return true, JINSHI.PixelToCanvas(px, py), V2(px, py), dist
end

function JINSHI.GetScreenCenter(PC)
    local W, H = 0, 0
    pcall(function()
        if PC and PC.GetViewportSize then
            local vs = V2(0, 0)
            PC:GetViewportSize(vs)
            if vs and vs.X and vs.X > 200 and vs.Y and vs.Y > 200 then W, H = vs.X, vs.Y end
        end
    end)
    if W <= 200 then
        pcall(function()
            local WLL = WidgetLayoutLibrary
            if WLL and WLL.GetViewportSize then
                local vs = WLL.GetViewportSize(PC)
                if vs and vs.X and vs.X > 200 and vs.Y and vs.Y > 200 then W, H = vs.X, vs.Y end
            end
        end)
    end
    if W <= 200 then
        pcall(function()
            local GS = import("GameplayStatics")
            local vs = GS.GetViewportSize and GS.GetViewportSize(PC)
            if vs and vs.X and vs.X > 200 then W, H = vs.X, vs.Y end
        end)
    end
    if W <= 200 then
        W = JINSHI._ViewW or 1920
        H = JINSHI._ViewH or 1080
    end
    -- size hysteresis: 2 px se kam ka farq ignore, warna har frame aspect badalta
    local hyst = CFG.SizeHysteresis or 2
    if ABS(W - (JINSHI._ViewW or 0)) > hyst or ABS(H - (JINSHI._ViewH or 0)) > hyst then
        JINSHI._ViewW, JINSHI._ViewH = W, H
    end
    return JINSHI.PixelToCanvas(JINSHI._ViewW / 2, JINSHI._ViewH / 2), JINSHI._ViewW, JINSHI._ViewH
end

function JINSHI.UpdateSnapOrigin(W, H)
    if not JINSHI._SnapOriginDirty then
        if JINSHI._SnapOrigin and JINSHI._SnapW == W and JINSHI._SnapH == H then return end
    end
    local ox = W / 2
    local oy = 0
    if CFG.SnapFromBottom then
        oy = H * (1.0 - (CFG.SnapOffsetY or 0))
    else
        oy = H * (CFG.SnapOffsetY or 0)
    end
    JINSHI._SnapOrigin = JINSHI.PixelToCanvas(RND(ox), RND(oy))
    JINSHI._SnapW, JINSHI._SnapH = W, H
    JINSHI._SnapOriginDirty = false
end

-- ============================== WIDGETS ======================================
function JINSHI.CreateLineWidget(color, zOrder)
    if not WidgetOK(JINSHI.Canvas) then return nil end
    local Border = nil
    pcall(function() Border = CGame:NewObjectFromPath("/Script/UMG.Border", JINSHI.Canvas) end)
    if not WidgetOK(Border) then return nil end
    pcall(function() Border:SetBrushColor(color) end)
    pcall(function() Border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    pcall(function() Border:SetRenderTransformPivot(V2(0.0, 0.5)) end)
    local Slot = nil
    pcall(function()
        Slot = JINSHI.Canvas:AddChildToCanvas(Border)
        if Slot then
            Slot:SetAutoSize(false)
            Slot:SetZOrder(zOrder or 1)
        end
    end)
    if not Slot then
        pcall(function() Border:RemoveFromParent() end)
        return nil
    end
    return { Widget = Border, Slot = Slot, Visible = true }
end

function JINSHI.DrawLine(ld, x1, y1, x2, y2, thickness)
    if not (ld and WidgetOK(ld.Widget) and WidgetOK(ld.Slot)) then return end
    if x1 ~= x1 or y1 ~= y1 or x2 ~= x2 or y2 ~= y2 then return end

    if CFG.PixelRounding then
        x1, y1, x2, y2 = RND(x1), RND(y1), RND(x2), RND(y2)
    end

    -- deadzone: itni si harkat pe widget ko chhuate hi nahi. yahi se 0 stability aati hai
    if CFG.StableMode and ld.lx1 and ld.th == thickness then
        local dz = CFG.DeadZone or 0
        if ABS(ld.lx1 - x1) < dz and ABS(ld.ly1 - y1) < dz
        and ABS(ld.lx2 - x2) < dz and ABS(ld.ly2 - y2) < dz then
            return
        end
    end

    local dx, dy = x2 - x1, y2 - y1
    local len = SQRT(dx * dx + dy * dy)
    if len < 0.5 then JINSHI.HideLine(ld); return end
    local ang = ATAN2(dy, dx) * (180.0 / math.pi)
    if CFG.PixelRounding then
        len = RND(len)
        ang = math.floor(ang * 10 + 0.5) / 10
    end

    -- kuch badla hi nahi to slate ko invalidate karne ka koi fayda nahi
    if ld.lx1 == x1 and ld.ly1 == y1 and ld.lx2 == x2 and ld.ly2 == y2 and ld.th == thickness then
        if ld.Visible == false then
            pcall(function() ld.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
            ld.Visible = true
        end
        return
    end

    local ok = pcall(function()
        ld.Slot:SetPosition(V2(x1, RND(y1 - thickness * 0.5)))
        ld.Slot:SetSize(V2(len, thickness))
        ld.Widget:SetRenderAngle(ang)
        if ld.Visible == false then
            ld.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            ld.Visible = true
        end
    end)
    if ok then
        ld.lx1, ld.ly1, ld.lx2, ld.ly2, ld.th = x1, y1, x2, y2, thickness
    end
end

function JINSHI.HideLine(ld)
    if ld and WidgetOK(ld.Widget) and ld.Visible ~= false then
        pcall(function() ld.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
        ld.Visible = false
        ld.lx1, ld.ly1, ld.lx2, ld.ly2, ld.th = nil, nil, nil, nil, nil
    end
end

function JINSHI.DestroyLine(ld)
    if ld and WidgetOK(ld.Widget) then
        pcall(function()
            ld.Widget:RemoveFromParent()
            ld.Widget:ConditionalBeginDestroy()
        end)
    end
end

local function EnsureSeg(tbl, key, color, zOrder)
    if tbl[key] and WidgetOK(tbl[key].Widget) then return tbl[key] end
    tbl[key] = JINSHI.CreateLineWidget(color, zOrder)
    return tbl[key]
end

-- ============================== BOX (CORNERS) ================================
local function DrawBone(tbl, idx, x1, y1, x2, y2, thickness, color)
    tbl[idx] = EnsureSeg(tbl, idx, color or CFG.BoneColor, 2)
    JINSHI.DrawLine(tbl[idx], x1, y1, x2, y2, thickness or CFG.BoneThickness or 1.0)
end

function JINSHI.HideBox(box)
    if not box then return end
    if box.corners then for _, s in ipairs(box.corners) do JINSHI.HideLine(s) end end
    if box.bones   then for _, s in ipairs(box.bones)   do JINSHI.HideLine(s) end end
end

function JINSHI.DestroyBox(box)
    if not box then return end
    if box.corners then for _, s in ipairs(box.corners) do JINSHI.DestroyLine(s) end end
    if box.bones   then for _, s in ipairs(box.bones)   do JINSHI.DestroyLine(s) end end
end

-- sirf chote corners + andar ka skeleton. koi band hua box nahi.
function JINSHI.UpdateBox(KeyStr, rect, bVisible, dist)
    local box = JINSHI.Boxes[KeyStr]
    if not bVisible or not rect then
        if box then JINSHI.HideBox(box) end
        return
    end
    if not box then
        box = { corners = {}, bones = {} }
        JINSHI.Boxes[KeyStr] = box
    end
    local L, T, R, B = rect.L, rect.T, rect.R, rect.B
    local w, h = R - L, B - T
    if w < 2 or h < 2 then JINSHI.HideBox(box); return end

    ---------------- 1. chote corner brackets ----------------
    local arm = math.min(w, h) * (CFG.CornerLen or 0.34)
    arm = Clamp(arm, CFG.CornerMin or 5, CFG.CornerMax or 34)
    if arm > w then arm = w end
    if arm > h then arm = h end
    local th = CFG.CornerThickness or 2.0
    local c = box.corners
    for i = 1, 8 do c[i] = EnsureSeg(c, i, CFG.CornerColor, 3) end
    JINSHI.DrawLine(c[1], L, T, L + arm, T, th)      -- top left
    JINSHI.DrawLine(c[2], L, T, L, T + arm, th)
    JINSHI.DrawLine(c[3], R, T, R - arm, T, th)      -- top right
    JINSHI.DrawLine(c[4], R, T, R, T + arm, th)
    JINSHI.DrawLine(c[5], L, B, L + arm, B, th)      -- bottom left
    JINSHI.DrawLine(c[6], L, B, L, B - arm, th)
    JINSHI.DrawLine(c[7], R, B, R - arm, B, th)      -- bottom right
    JINSHI.DrawLine(c[8], R, B, R, B - arm, th)

    ---------------- 2. skeleton, andar hi ----------------
    local b  = box.bones
    local bt = CFG.BoneThickness or 1.0
    local cx = (L + R) * 0.5
    local full = (CFG.SkeletonLODDist or 0) <= 0 or (not dist) or (dist <= CFG.SkeletonLODDist)

    -- padding nikal ke asli sar / pair ki jagah
    local tot     = 1 + (CFG.HeadExtra or 0) + (CFG.FootExtra or 0)
    local headTop = h * ((CFG.HeadExtra or 0) / tot)
    local footPad = h * ((CFG.FootExtra or 0) / tot)
    local top = T + headTop          -- asli sar ka upar
    local bot = B - footPad          -- asli pair
    local bh  = bot - top            -- asli body ki screen height
    if bh < 6 then bh = 6 end

    -- insani nisbatein (sar ke upar se):
    -- sar 0.13 | kandhe 0.19 | kohni 0.44 | kalai 0.56 | kamar 0.53 | ghutna 0.74 | pair 1.00

    ---------- sar ----------
    local hs = bh * 0.065
    if hs > w * 0.30 then hs = w * 0.30 end
    if hs < 2 then hs = 2 end
    local hcy = top + hs
    DrawBone(b, 1, cx - hs, hcy - hs, cx + hs, hcy - hs, bt, CFG.HeadBoneColor)
    DrawBone(b, 2, cx - hs, hcy + hs, cx + hs, hcy + hs, bt, CFG.HeadBoneColor)
    DrawBone(b, 3, cx - hs, hcy - hs, cx - hs, hcy + hs, bt, CFG.HeadBoneColor)
    DrawBone(b, 4, cx + hs, hcy - hs, cx + hs, hcy + hs, bt, CFG.HeadBoneColor)

    ---------- gardan + kandhe ----------
    local shY = top + bh * 0.19
    if shY < top + hs * 2 then shY = top + hs * 2 end
    DrawBone(b, 5, cx, hcy + hs, cx, shY, bt)

    if full then
        local shW = w * 0.28
        local elX = w * 0.33
        local hdX = w * 0.30
        local plW = w * 0.18
        local knX = w * 0.16
        local elY = top + bh * 0.44
        local hdY = top + bh * 0.56
        local plY = top + bh * 0.53
        local knY = top + bh * 0.74
        DrawBone(b, 6,  cx - shW, shY, cx + shW, shY, bt)          -- kandhe
        DrawBone(b, 7,  cx - shW, shY, cx - elX, elY, bt)          -- bayen hath upar
        DrawBone(b, 8,  cx - elX, elY, cx - hdX, hdY, bt)          -- bayen hath neeche
        DrawBone(b, 9,  cx + shW, shY, cx + elX, elY, bt)          -- dayen hath upar
        DrawBone(b, 10, cx + elX, elY, cx + hdX, hdY, bt)          -- dayen hath neeche
        DrawBone(b, 11, cx, shY, cx, plY, bt)                      -- reerh ki haddi
        DrawBone(b, 12, cx - plW, plY, cx + plW, plY, bt)          -- kamar
        DrawBone(b, 13, cx - plW, plY, cx - knX, knY, bt)          -- bayi jangh
        DrawBone(b, 14, cx - knX, knY, cx - knX, bot, bt)          -- bayi pinri
        DrawBone(b, 15, cx + plW, plY, cx + knX, knY, bt)          -- dayi jangh
        DrawBone(b, 16, cx + knX, knY, cx + knX, bot, bt)          -- dayi pinri
    else
        -- door ka target: sirf dhhad, koi hath pair nahi (widgets bachte hain)
        DrawBone(b, 6, cx, shY, cx, bot, bt)
        for i2 = 7, 16 do JINSHI.HideLine(b[i2]) end
    end
end

function JINSHI.RemoveBox(KeyStr)
    JINSHI.DestroyBox(JINSHI.Boxes[KeyStr])
    JINSHI.Boxes[KeyStr] = nil
end

function JINSHI.ClearAllBoxes()
    for k, box in pairs(JINSHI.Boxes) do JINSHI.DestroyBox(box) end
    JINSHI.Boxes = {}
end

-- ============================== SNAP LINE ====================================
function JINSHI.UpdateSnapLine(KeyStr, targetCanvas, bVisible)
    local snap = JINSHI.SnapLines[KeyStr]
    if not bVisible or not targetCanvas then
        if snap then JINSHI.HideLine(snap.core); JINSHI.HideLine(snap.halo) end
        return
    end
    if not snap then
        snap = {}
        JINSHI.SnapLines[KeyStr] = snap
    end
    snap.halo = EnsureSeg(snap, "halo", CFG.SnapHaloColor, 1)
    snap.core = EnsureSeg(snap, "core", CFG.SnapColor, 2)
    local ox, oy = JINSHI._SnapOrigin.X, JINSHI._SnapOrigin.Y
    local tx, ty = targetCanvas.X, targetCanvas.Y
    JINSHI.DrawLine(snap.halo, ox, oy, tx, ty, CFG.SnapHaloThickness)
    JINSHI.DrawLine(snap.core, ox, oy, tx, ty, CFG.SnapThickness)
end

function JINSHI.RemoveSnapLine(KeyStr)
    local snap = JINSHI.SnapLines[KeyStr]
    if snap then JINSHI.DestroyLine(snap.core); JINSHI.DestroyLine(snap.halo) end
    JINSHI.SnapLines[KeyStr] = nil
end

function JINSHI.ClearAllSnapLines()
    for k, snap in pairs(JINSHI.SnapLines) do
        JINSHI.DestroyLine(snap.core)
        JINSHI.DestroyLine(snap.halo)
    end
    JINSHI.SnapLines = {}
end

-- ============================ OFF SCREEN ARROWS ==============================
function JINSHI.UpdateArrow(KeyStr, WorldLoc, PC, bVisible)
    local arr = JINSHI.Arrows[KeyStr]
    if not bVisible then
        if arr then JINSHI.HideLine(arr.stem); JINSHI.HideLine(arr.wL); JINSHI.HideLine(arr.wR) end
        return
    end
    if not arr then
        arr = {}
        JINSHI.Arrows[KeyStr] = arr
    end
    arr.stem = EnsureSeg(arr, "stem", CFG.ArrowColor, 4)
    arr.wL   = EnsureSeg(arr, "wL",   CFG.ArrowColor, 4)
    arr.wR   = EnsureSeg(arr, "wR",   CFG.ArrowColor, 4)

    -- direction straight from the camera basis: stable even when the target is
    -- behind us (screen projection is meaningless back there)
    local a = 0
    local c, f, r, u = JINSHI._CamLoc, JINSHI._CamFwd, JINSHI._CamRight, JINSHI._CamUp
    if c and f and r and u then
        local dx, dy, dz = WorldLoc.X - c.X, WorldLoc.Y - c.Y, WorldLoc.Z - c.Z
        local fz = dx * f.X + dy * f.Y + dz * f.Z
        local sx = dx * r.X + dy * r.Y + dz * r.Z
        local sy = dx * u.X + dy * u.Y + dz * u.Z
        if fz > 1 then
            if ABS(sx) > 0.001 or ABS(sy) > 0.001 then a = ATAN2(sy, sx) end
        else
            if ABS(sx) > 0.001 or ABS(fz) > 0.001 then a = ATAN2(-fz, sx) end
        end
    end
    local cx, cy = JINSHI._Center.X, JINSHI._Center.Y
    local radius  = CFG.FOVCircleRadius or 150.0
    local stemLen = CFG.ArrowStemLen or 20.0
    local headLen = CFG.ArrowHeadLen or 11.0
    local wingAng = CFG.ArrowWingAngle or 0.45
    local offset  = CFG.ArrowOffset or 5.0
    local thick   = CFG.ArrowThickness or 3.0
    local baseX = cx + COS(a) * radius
    local baseY = cy + SIN(a) * radius
    local tipX  = cx + COS(a) * (radius + offset + stemLen)
    local tipY  = cy + SIN(a) * (radius + offset + stemLen)
    local backL = a + math.pi - wingAng
    local backR = a + math.pi + wingAng
    JINSHI.DrawLine(arr.stem, baseX, baseY, tipX, tipY, thick)
    JINSHI.DrawLine(arr.wL, tipX, tipY, tipX + COS(backL) * headLen, tipY + SIN(backL) * headLen, thick)
    JINSHI.DrawLine(arr.wR, tipX, tipY, tipX + COS(backR) * headLen, tipY + SIN(backR) * headLen, thick)
end

function JINSHI.RemoveArrow(KeyStr)
    local arr = JINSHI.Arrows[KeyStr]
    if arr then JINSHI.DestroyLine(arr.stem); JINSHI.DestroyLine(arr.wL); JINSHI.DestroyLine(arr.wR) end
    JINSHI.Arrows[KeyStr] = nil
end

function JINSHI.ClearAllArrows()
    for k, arr in pairs(JINSHI.Arrows) do
        JINSHI.DestroyLine(arr.stem)
        JINSHI.DestroyLine(arr.wL)
        JINSHI.DestroyLine(arr.wR)
    end
    JINSHI.Arrows = {}
end

-- ============================== FOV CIRCLE ===================================
function JINSHI.UpdateCenterCircle(cx, cy)
    local lx, ly = JINSHI._CircleX, JINSHI._CircleY
    if lx and ly and ABS(lx - cx) < 0.5 and ABS(ly - cy) < 0.5 then return end
    JINSHI._CircleX, JINSHI._CircleY = cx, cy
    local radius   = CFG.FOVCircleRadius or 150.0
    local segments = CFG.FOVCircleSegments or 48
    local th       = CFG.FOVCircleThickness or 1.5
    for i = 1, segments do
        local a1 = ((i - 1) / segments) * (2 * math.pi)
        local a2 = (i / segments) * (2 * math.pi)
        if not JINSHI.FOVCircleLines[i] then
            JINSHI.FOVCircleLines[i] = JINSHI.CreateLineWidget(CFG.FOVCircleColor, 0)
        end
        JINSHI.DrawLine(JINSHI.FOVCircleLines[i],
            cx + COS(a1) * radius, cy + SIN(a1) * radius,
            cx + COS(a2) * radius, cy + SIN(a2) * radius, th)
    end
end

function JINSHI.RemoveCenterCircle()
    for _, ld in pairs(JINSHI.FOVCircleLines) do JINSHI.DestroyLine(ld) end
    JINSHI.FOVCircleLines = {}
    JINSHI._CircleX, JINSHI._CircleY = nil, nil
end

-- ============================== PER TARGET ===================================
function JINSHI.ReleaseTarget(KeyStr)
    JINSHI.RemoveSnapLine(KeyStr)
    JINSHI.RemoveBox(KeyStr)
    JINSHI.RemoveArrow(KeyStr)
    JINSHI._EnemyCache[KeyStr] = nil
    JINSHI._Smooth[KeyStr] = nil
end

function JINSHI.DestroyAllWidgets()
    JINSHI.ClearAllSnapLines()
    JINSHI.ClearAllBoxes()
    JINSHI.ClearAllArrows()
    JINSHI.RemoveCenterCircle()
    JINSHI._Smooth = {}
end

function JINSHI.HideTarget(KeyStr, HeadLoc, PC)
    JINSHI.HideBox(JINSHI.Boxes[KeyStr])
    JINSHI.UpdateSnapLine(KeyStr, nil, false)
    JINSHI.UpdateArrow(KeyStr, HeadLoc, PC, true)
end

function JINSHI.UpdateTarget(KeyStr, Character, PC)
    if not IsValid(Character) then JINSHI.ReleaseTarget(KeyStr); return end
    if not JINSHI.IsAlive(Character) then
        JINSHI.HideBox(JINSHI.Boxes[KeyStr])
        JINSHI.UpdateSnapLine(KeyStr, nil, false)
        JINSHI.UpdateArrow(KeyStr, nil, PC, false)
        return
    end

    local body = JINSHI.GetBodyPoints(Character)
    if not body then
        JINSHI.HideBox(JINSHI.Boxes[KeyStr])
        JINSHI.UpdateSnapLine(KeyStr, nil, false)
        JINSHI.UpdateArrow(KeyStr, nil, PC, false)
        return
    end

    local HeadLoc = { X = body.cx, Y = body.cy, Z = body.headZ }
    local FeetLoc = { X = body.cx, Y = body.cy, Z = body.feetZ }

    local bHeadOK, headCanvas, headPix, headDist = JINSHI.ProjectToCanvas(PC, HeadLoc)
    local bFeetOK, feetCanvas, feetPix = JINSHI.ProjectToCanvas(PC, FeetLoc)

    if not (bHeadOK and bFeetOK) then
        JINSHI.HideTarget(KeyStr, HeadLoc, PC)
        JINSHI._Smooth[KeyStr] = nil
        return
    end

    local H = feetCanvas.Y - headCanvas.Y
    if H < (CFG.BoxMinHeight or 14) then
        JINSHI.HideTarget(KeyStr, HeadLoc, PC)
        return
    end

    ------ chaudai: capsule radius ko screen pe project kar ke. EXACT FIT ------
    ------ (height * factor wala purana tareeka animation ke saath pulse karta tha) ------
    local W = nil
    if CFG.ExactWidth then
        local r = JINSHI._CamRight
        local rad = (body.radius or 35) * (CFG.WidthScale or 1.18)
        if r and rad then
            local okL, Lc = JINSHI.ProjectToCanvas(PC, { X = body.cx - r.X * rad, Y = body.cy - r.Y * rad, Z = body.cz })
            local okR, Rc = JINSHI.ProjectToCanvas(PC, { X = body.cx + r.X * rad, Y = body.cy + r.Y * rad, Z = body.cz })
            if okL and okR then
                local dxp, dyp = Rc.X - Lc.X, Rc.Y - Lc.Y
                W = SQRT(dxp * dxp + dyp * dyp)
            end
        end
    end
    if (not W) or W ~= W or W < 2 then
        W = H * (CFG.BoxWidthFactor or 0.62)
    end
    W = Clamp(W * (1 + (CFG.BoxPadX or 0)), CFG.BoxMinWidth or 22, CFG.BoxMaxWidth or 320)

    local padT = H * (CFG.HeadExtra or 0)
    local padB = H * (CFG.FootExtra or 0)
    local cx   = (headCanvas.X + feetCanvas.X) * 0.5
    local target = {
        L = cx - W * 0.5,
        R = cx + W * 0.5,
        T = headCanvas.Y - padT,
        B = feetCanvas.Y + padB,
    }

    ---- STABILITY: Smoothing 0 ka matlab koi lerp nahi, koi drag nahi, ZERO lag ----
    local sm = JINSHI._Smooth[KeyStr]
    if not sm then sm = {}; JINSHI._Smooth[KeyStr] = sm end
    if (CFG.Smoothing or 0) <= 0 then
        sm.L, sm.T, sm.R, sm.B = target.L, target.T, target.R, target.B
        sm.SX, sm.SY = headCanvas.X, headCanvas.Y
        sm.FX, sm.FY = feetCanvas.X, feetCanvas.Y
    else
        local t = 1.0 - Clamp(CFG.Smoothing, 0, 0.95)
        local jump = (sm.L and sm.T) and (ABS(target.L - sm.L) + ABS(target.T - sm.T)) or 1e9
        if jump > (CFG.SnapDistance or 260) then
            sm.L, sm.T, sm.R, sm.B = target.L, target.T, target.R, target.B
            sm.SX, sm.SY = headCanvas.X, headCanvas.Y
            sm.FX, sm.FY = feetCanvas.X, feetCanvas.Y
        else
            sm.L  = Lerp(sm.L,  target.L, t)
            sm.R  = Lerp(sm.R,  target.R, t)
            sm.T  = Lerp(sm.T,  target.T, t)
            sm.B  = Lerp(sm.B,  target.B, t)
            sm.SX = Lerp(sm.SX, headCanvas.X, t)
            sm.SY = Lerp(sm.SY, headCanvas.Y, t)
            sm.FX = Lerp(sm.FX, feetCanvas.X, t)
            sm.FY = Lerp(sm.FY, feetCanvas.Y, t)
        end
    end

    local m = CFG.ScreenMargin or 200
    local onScreen = headPix ~= nil and feetPix ~= nil
        and headPix.X > -m and headPix.X < JINSHI._ViewW + m
        and headPix.Y > -m and headPix.Y < JINSHI._ViewH + m

    JINSHI.UpdateBox(KeyStr, sm, true, headDist)
    -- snap line ka aakhri hissa: enemy ke HEAD pe hi lagta hai
    local snapEnd = CFG.SnapToFeet and V2(sm.FX, sm.FY) or V2(sm.SX, sm.SY)
    JINSHI.UpdateSnapLine(KeyStr, snapEnd, onScreen)
    if CFG.ArrowOnlyOffScreen then
        JINSHI.UpdateArrow(KeyStr, HeadLoc, PC, not onScreen)
    else
        JINSHI.UpdateArrow(KeyStr, HeadLoc, PC, true)
    end
end

-- ============================== MAIN LOOPS ===================================
function JINSHI.ScanAndUpdate()
    if not ESP_Enabled then return end
    if not JINSHI.InitESPCanvas() then return end
    local PC = JINSHI.GetMyPlayerController()
    if not IsValid(PC) then return end
    if not JINSHI.UpdateCamera(PC) then return end
    JINSHI.UpdateCanvasTransform(PC)
    local center, viewW, viewH = JINSHI.GetScreenCenter(PC)
    JINSHI._Center = center
    JINSHI.UpdateSnapOrigin(viewW, viewH)
    JINSHI.UpdateCenterCircle(center.X, center.Y)

    local AllChars = JINSHI.GetAllCharacters()
    if not AllChars then return end
    local MyKey = JINSHI.GetMyPlayerKey()
    local MyChar = nil
    pcall(function()
        local GDP = JINSHI.GetGameplayData()
        if GDP and GDP.GetLocalCharacter then
            MyChar = GDP.GetLocalCharacter()
        elseif PC and PC.GetPawn then
            MyChar = PC:GetPawn()
        end
    end)
    local MyTeamID = IsValid(MyChar) and JINSHI.GetTeamID(MyChar) or nil

    local cands = {}
    for PlayerKey, Character in pairs(AllChars) do
        if IsValid(Character) then
            local KeyStr = tostring(PlayerKey)
            local bIsMe = JINSHI.IsMe(Character, PlayerKey, MyKey)
            if not bIsMe and JINSHI.IsAlive(Character) then
                local TeamID = JINSHI.GetTeamID(Character)
                local bMate = (MyTeamID ~= nil and TeamID == MyTeamID)
                if (not bMate) or CFG.ShowTeammates then
                    local dist = IsValid(MyChar) and JINSHI.GetDistance(MyChar, Character) or JINSHI.CamDistance(JINSHI.GetFeetLoc(Character) or { X = 0, Y = 0, Z = 0 })
                    if (CFG.MaxDistance or 0) <= 0 or dist <= CFG.MaxDistance then
                        cands[#cands + 1] = { k = KeyStr, c = Character, d = dist }
                    end
                end
            end
        end
    end
    table.sort(cands, function(a, b) return a.d < b.d end)

    local Seen = {}
    local limit = math.min(#cands, CFG.MaxTracked or 16)
    for i = 1, limit do
        local c = cands[i]
        Seen[c.k] = true
        JINSHI._EnemyCache[c.k] = c.c
        JINSHI.UpdateTarget(c.k, c.c, PC)
    end

    local allKeys = {}
    for k in pairs(JINSHI.SnapLines) do allKeys[k] = true end
    for k in pairs(JINSHI.Arrows)    do allKeys[k] = true end
    for k in pairs(JINSHI.Boxes)     do allKeys[k] = true end
    for k in pairs(allKeys) do
        if not Seen[k] then JINSHI.ReleaseTarget(k) end
    end
end

function JINSHI.UpdateLight()
    if not ESP_Enabled then return end
    if not WidgetOK(JINSHI.Canvas) then
        if not JINSHI.InitESPCanvas() then return end
    end
    local PC = JINSHI.GetMyPlayerController()
    if not IsValid(PC) then return end
    if not JINSHI.UpdateCamera(PC) then return end
    JINSHI.UpdateCanvasTransform(PC)
    local center, viewW, viewH = JINSHI.GetScreenCenter(PC)
    JINSHI._Center = center
    JINSHI.UpdateSnapOrigin(viewW, viewH)
    for KeyStr, Character in pairs(JINSHI._EnemyCache) do
        if IsValid(Character) then
            JINSHI.UpdateTarget(KeyStr, Character, PC)
        else
            JINSHI.ReleaseTarget(KeyStr)
        end
    end
end

-- ============================== TIMERS =======================================
function JINSHI.AttachTimers()
    pcall(function()
        local pc = JINSHI.GetMyPlayerController()
        if not slua.isValid(pc) or not pc.AddGameTimer then
            local now = os.time()
            if JINSHI._AttachPending then
                if JINSHI._AttachPendingTime and (now - JINSHI._AttachPendingTime) < 2 then return end
            end
            JINSHI._AttachPending = true
            JINSHI._AttachPendingTime = now
            pcall(function()
                require("timer").SetGameTimer(1.0, false, function()
                    JINSHI._AttachPending = nil
                    JINSHI._AttachPendingTime = nil
                    JINSHI.AttachTimers()
                end)
            end)
            return
        end
        JINSHI._AttachPending = nil
        JINSHI._AttachPendingTime = nil
        local now = os.time()
        local lastPC = JINSHI._ActiveTimerPC
        if lastPC and slua.isValid(lastPC) and lastPC == pc then
            if JINSHI._ActiveTimerTick and (now - JINSHI._ActiveTimerTick) < 5 then return end
        end
        JINSHI._ActiveTimerPC = pc
        JINSHI._ActiveTimerTick = now
        pcall(function()
            pc:AddGameTimer(JINSHI.nUpdateInterval or 0.5, true, function()
                JINSHI._ActiveTimerTick = os.time()
                if JINSHI.bActive then pcall(JINSHI.ScanAndUpdate) end
            end)
        end)
        pcall(function()
            pc:AddGameTimer(0.016, true, function()
                JINSHI._ActiveTimerTick = os.time()
                if not JINSHI.bActive then return end
                local now = (os.clock and os.clock()) or os.time()
                if (now - (JINSHI._LastLight or 0)) < JINSHI.GetLightInterval() then return end
                JINSHI._LastLight = now
                pcall(JINSHI.UpdateLight)
            end)
        end)
        pcall(function() require("timer").SetGameTimer(5.0, false, JINSHI.AttachTimers) end)
    end)
end

function JINSHI.Start()
    if JINSHI.bActive then return end
    JINSHI.bActive = true
    pcall(JINSHI.ScanAndUpdate)
    JINSHI.AttachTimers()
end

function JINSHI.Stop()
    JINSHI.bActive = false
    JINSHI.DestroyAllWidgets()
    JINSHI._EnemyCache = {}
    JINSHI.Canvas = nil
end

function JINSHI.SetEnabled(v)
    ESP_Enabled = v and true or false
    if ESP_Enabled then JINSHI.Start() else JINSHI.Stop() end
    return ESP_Enabled
end

function JINSHI.Toggle()
    return JINSHI.SetEnabled(not ESP_Enabled)
end

function JINSHI.IsEnabled()
    return ESP_Enabled
end

_G.JINSHI = JINSHI
_G.PlayerMapMarker = JINSHI   -- back-compat name

-- ============================ JINSHI TOGGLE BUTTON ===========================
local BTN_BP  = "/Game/UMG/UI_BP/Common/BaseComponent/CommonBaseComponent_TextButton_UIBP.CommonBaseComponent_TextButton_UIBP_C"
local BTN_BP2 = "/Game/UMG/UI_BP/Common/BaseComponent/CommonBaseComponent_TextButton_UIBP.CommonBaseComponent_TextButton_UIBP"

local C_ON   = MKC(1.00, 0.80, 0.05, 1.00)   -- GREEN  = MEHREN ON
local C_OFF  = MKC(0.16, 0.16, 0.18, 0.85)   -- dark    = MEHREN OFF
local C_TXT_ON  = MKC(0.06, 0.05, 0.00, 1.00)
local C_TXT_OFF = MKC(1.00, 0.84, 0.08, 1.00)

local BTN_LABEL_ON  = "MEHREN ON"
local BTN_LABEL_OFF = "MEHREN OFF"
local BTN_POS  = { X = 12, Y = 96 }
local BTN_SIZE = { X = 132, Y = 36 }

local ToggleBtn = nil

local function LoadUI(p1, p2)
    local w = nil
    pcall(function() w = slua.loadUI(p1) end)
    if not IsValid(w) and p2 then pcall(function() w = slua.loadUI(p2) end) end
    return w
end

local function AddToHUD(w, z)
    if not IsValid(w) then return end
    pcall(function()
        if w.AddToViewport then
            w:AddToViewport(z or 10900)
        else
            require("game_frontend_hud").AddToContainer(UIContainers.Top, w, z or 10900)
        end
    end)
end

local function FindImg(w)
    for _, n in ipairs({ "Image_BtnBg", "Image_backGround", "Image_BG", "Image_1", "Image_0", "Image", "BgImage", "Background" }) do
        if w[n] and w[n].SetColorAndOpacity then return w[n] end
    end
    for _, c in pairs(w) do
        if type(c) == "userdata" and IsValid(c) and c.SetColorAndOpacity then return c end
    end
end

local function FindTxt(w)
    for _, n in ipairs({ "TextBlock", "Text", "RichText", "RichText_Content", "Label", "Text_0", "ContentText" }) do
        if w[n] and (w[n].SetText or w[n].SetTextString) then return w[n] end
    end
    for _, c in pairs(w) do
        if type(c) == "userdata" and IsValid(c) and (c.SetText or c.SetTextString) then return c end
    end
end

local function FindBtn(w)
    for _, n in ipairs({ "Button", "Btn", "Button_Temp", "MainButton", "Button_0", "Btn_0" }) do
        if w[n] and (w[n].OnClicked or w[n].OnClickBg or w[n].OnClick) then return w[n] end
    end
    for _, c in pairs(w) do
        if type(c) == "userdata" and IsValid(c) and (c.OnClicked or c.OnClickBg or c.OnClick) then return c end
    end
end

local function SetTxt(w, txt, sz, col)
    if not IsValid(w) then return end
    pcall(function()
        local t = FindTxt(w) or w
        if t.SetText then t:SetText(txt)
        elseif t.SetTextString then t:SetTextString(txt) end
        if sz then
            local ok, f = pcall(function() return t.Font end)
            if ok and f then f.Size = sz; t:SetFont(f) end
        end
        if col then
            pcall(function()
                if t.SetColorAndOpacity then t:SetColorAndOpacity(col) end
            end)
        end
    end)
end

local function SetClr(w, c)
    if not IsValid(w) then return end
    pcall(function()
        local i = FindImg(w)
        if i then i:SetColorAndOpacity(c) end
    end)
end

local function Bind(w, fn)
    pcall(function()
        local function tryBind(src)
            if not IsValid(src) then return false end
            if src.OnClicked  then src.OnClicked:Add(function() pcall(fn) end);  return true end
            if src.OnClickBg  then src.OnClickBg:Add(function() pcall(fn) end);  return true end
            if src.OnClick    then src.OnClick:Add(function() pcall(fn) end);    return true end
            return false
        end
        if not tryBind(FindBtn(w)) then tryBind(w) end
    end)
end

local function RefreshBtn()
    if not IsValid(ToggleBtn) then return end
    if ESP_Enabled then
        SetTxt(ToggleBtn, BTN_LABEL_ON, 14, C_TXT_ON)
        SetClr(ToggleBtn, C_ON)
    else
        SetTxt(ToggleBtn, BTN_LABEL_OFF, 14, C_TXT_OFF)
        SetClr(ToggleBtn, C_OFF)
    end
end

local function CreateToggleButton()
    if IsValid(ToggleBtn) then return end
    ToggleBtn = LoadUI(BTN_BP, BTN_BP2)
    if not IsValid(ToggleBtn) then return end
    AddToHUD(ToggleBtn, 10900)
    pcall(function()
        if ToggleBtn.SetPositionInViewport then
            ToggleBtn:SetPositionInViewport(V2(BTN_POS.X, BTN_POS.Y), false)
            ToggleBtn:SetDesiredSizeInViewport(V2(BTN_SIZE.X, BTN_SIZE.Y))
        end
    end)
    ToggleBtn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
    RefreshBtn()
    Bind(ToggleBtn, function()
        JINSHI.Toggle()
        RefreshBtn()
    end)
end

local _ActivePC = nil
local function StartAll()
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if IsValid(pc) and pc ~= _ActivePC then
            _ActivePC = pc
            CreateToggleButton()
            JINSHI.Start()
        end
    end)
end

pcall(function()
    StartAll()
    if slua_GameFrontendHUD then
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if IsValid(pc) then pc:AddGameTimer(1.0, true, StartAll) end
    end
end)

-- handy console hooks:  _G.JINSHI.Toggle()  /  _G.JINSHI.SetEnabled(false)
-- recolor at runtime:   _G.JINSHI.CFG.SnapColor = ...  (CFG is exposed below)
JINSHI.CFG = CFG
JINSHI.RefreshButton = RefreshBtn

local CONFIG = { 
    ENABLED = 1, 
    FIRE_ONLY = 1, 
    SCOPE_ALLOWED = 0, 
    AIM_AT_KNOCKED = 1, 
    AIM_AT_BOTS = 1, 
    MAX_DIST = 250, 
    FOV = 360, 
    SMOOTH = 85, 
    PREDICT = 1, 
    SMART_SMOOTH = 1, 
    HEAD_CORRECTION = {x=0, y=0, z=0}, 
    HIP_OFFSET = {x=0, y=0, z=0}, 
    ADS_OFFSET = {x=0, y=0, z=0}, 
    RECOIL_HIP = 0, 
    RECOIL_ADS = 0, 
} 

local function UltimateEngine() 
    pcall(function() 
        if not slua_GameFrontendHUD then return end 
        local player = GameplayData.GetPlayerCharacter() 
        if not IsValid(player) then return end 
        local wpn = player.GetCurrentWeapon and player:GetCurrentWeapon() 
        if IsValid(wpn) then 
            local shoot = wpn.ShootWeaponEntity or wpn.ShootWeaponEntity_GEN_VARIABLE 
            if IsValid(shoot) then shoot.GameDeviationFactor = 0 end 
        end 
    end) 
end 

local function IsBot(pawn) 
    if not IsValid(pawn) then return false end 
    if pawn.bIsAI == true or pawn.IsAI == true then return true end 
    if (pawn.TeamID or 0) > 100 then return true end 
    local ps = pawn.PlayerState 
    if IsValid(ps) and (ps.bIsABot or ps.bIsBot) then return true end 
    return false 
end 

local function IsKnocked(pawn) 
    if not IsValid(pawn) then return false end 
    if pawn.HealthStatus == 1 then return true end 
    if pawn.IsNearDeath and pawn:IsNearDeath() then return true end 
    return (pawn.Health or 1) <= 0 
end 

local function GetHeadPos(target) 
    if not IsValid(target) or not IsValid(target.Mesh) then return nil end 
    local mesh = target.Mesh 
    local pos = mesh:GetSocketLocation("head") 
    if pos and not (pos.X == 0 and pos.Y == 0 and pos.Z == 0) then 
        pos.Z = pos.Z + 3 
        return pos 
    end 
    for i = 0, mesh:GetNumBones() - 1 do 
        local name = mesh:GetBoneName(i) 
        if name and string.find(string.lower(name), "head") then 
            pos = mesh:GetBoneLocationByName(name, 0) 
            if pos and not (pos.X == 0 and pos.Y == 0 and pos.Z == 0) then 
                pos.Z = pos.Z + 3 
                return pos 
            end 
        end 
    end 
    pos = target:K2_GetActorLocation() 
    return pos and {X=pos.X, Y=pos.Y, Z=pos.Z+100} or nil 
end 

local function GetEnemies(radius) 
    local player = GameplayData.GetPlayerCharacter() 
    if not IsValid(player) then return {} end 
    local actors = GameplayData.GetAllPlayerCharacters and GameplayData.GetAllPlayerCharacters() or {} 
    local myTeam = player:GetTeamID() 
    local list = {} 
    for _, a in pairs(actors) do 
        if IsValid(a) and a ~= player and a:IsAlive() and a:GetTeamID() ~= myTeam then 
            if player:GetDistanceTo(a) <= radius then 
                table.insert(list, a) 
            end 
        end 
    end 
    return list 
end 

local cachedEnemies, lastCacheTime = {}, 0 
local velocityHistory = {} 

_G.SmartAimbot = function() 
    pcall(function() 
        if not slua_GameFrontendHUD or CONFIG.ENABLED ~= 1 then return end 
        local player = GameplayData.GetPlayerCharacter() 
        if not IsValid(player) then return end 
        local pc = player:GetPlayerControllerSafety() 
        if not IsValid(pc) then return end 
        local firing = player.bIsWeaponFiring 
        local ads = player.bIsGunADS 
        
        if CONFIG.SCOPE_ALLOWED == 0 and ads then return end 
        if CONFIG.FIRE_ONLY == 1 and not firing then return end 
        
        local now = os.clock() 
        if now - lastCacheTime > 0.1 then 
            cachedEnemies = GetEnemies(CONFIG.MAX_DIST * 100) 
            lastCacheTime = now 
        end 
        if #cachedEnemies == 0 then return end 
        
        local camMgr = import("GameplayStatics").GetPlayerCameraManager(pc, 0) 
        if not IsValid(camMgr) then return end 
        local camLoc = camMgr:GetCameraLocation() 
        local camFwd = camMgr:GetActorForwardVector() 
        if not camLoc or not camFwd then return end 

        local bestTarget, bestPos, bestScore = nil, nil, math.huge 

        for _, target in ipairs(cachedEnemies) do 
            if not IsValid(target) then goto continue end 
            if not CONFIG.AIM_AT_KNOCKED and IsKnocked(target) then goto continue end 
            if not CONFIG.AIM_AT_BOTS and IsBot(target) then goto continue end 

            local tpos = GetHeadPos(target) 
            if not tpos then goto continue end 

            tpos.X = tpos.X + CONFIG.HEAD_CORRECTION.x 
            tpos.Y = tpos.Y + CONFIG.HEAD_CORRECTION.y 
            tpos.Z = tpos.Z + CONFIG.HEAD_CORRECTION.z 

            if ads then 
                tpos.X = tpos.X + CONFIG.ADS_OFFSET.x 
                tpos.Y = tpos.Y + CONFIG.ADS_OFFSET.y 
                tpos.Z = tpos.Z + CONFIG.ADS_OFFSET.z 
            else 
                tpos.X = tpos.X + CONFIG.HIP_OFFSET.x 
                tpos.Y = tpos.Y + CONFIG.HIP_OFFSET.y 
                tpos.Z = tpos.Z + CONFIG.HIP_OFFSET.z 
            end 

            if CONFIG.PREDICT == 1 then 
                local prev = velocityHistory[target] 
                if prev then 
                    local dt = now - prev.time 
                    if dt > 0 and dt < 0.5 then 
                        local vx = (tpos.X - prev.x) / dt 
                        local vy = (tpos.Y - prev.y) / dt 
                        local vz = (tpos.Z - prev.z) / dt 
                        local ahead = 0.12 
                        tpos.X = tpos.X + vx * ahead 
                        tpos.Y = tpos.Y + vy * ahead 
                        tpos.Z = tpos.Z + vz * ahead 
                    end 
                end 
                velocityHistory[target] = {x=tpos.X, y=tpos.Y, z=tpos.Z, time=now} 
            end 

            local dx = tpos.X - camLoc.X 
            local dy = tpos.Y - camLoc.Y 
            local dz = tpos.Z - camLoc.Z 
            local mag = math.sqrt(dx*dx + dy*dy + dz*dz) 
            if mag < 1 then goto continue end 
            
            local dot = (camFwd.X*dx + camFwd.Y*dy + camFwd.Z*dz) / mag 
            dot = math.max(-1, math.min(1, dot)) 
            local angle = math.deg(math.acos(dot)) 

            if angle <= CONFIG.FOV / 2 then 
                local score = angle + (mag / 50000) 
                if score < bestScore then 
                    bestScore = score 
                    bestTarget = target 
                    bestPos = tpos 
                end 
            end 
            ::continue:: 
        end 

        if not bestPos then return end 

        local KMath = import("KismetMathLibrary") 
        local targetRot = KMath.FindLookAtRotation(camLoc, bestPos) 
        if not targetRot then return end 
        
        local curRot = pc:GetControlRotation() 
        if not curRot then return end 

        local dYaw = targetRot.Yaw - curRot.Yaw 
        local dPitch = targetRot.Pitch - curRot.Pitch 
        dYaw = (dYaw + 180) % 360 - 180 
        dPitch = (dPitch + 180) % 360 - 180 

        local speed = CONFIG.SMOOTH / 100 
        if CONFIG.SMART_SMOOTH == 1 then 
            local dist = math.sqrt(dYaw*dYaw + dPitch*dPitch) 
            speed = speed * (0.5 + 0.5 * math.min(dist, 30) / 30) 
        end 
        speed = math.max(0.1, math.min(1, speed)) 

        local newPitch = curRot.Pitch + dPitch * speed 
        local newYaw = curRot.Yaw + dYaw * speed 

        if firing then 
            if ads and CONFIG.RECOIL_ADS > 0 then 
                newPitch = newPitch - (CONFIG.RECOIL_ADS / 50) * 1.5 
            elseif not ads and CONFIG.RECOIL_HIP > 0 then 
                newPitch = newPitch - (CONFIG.RECOIL_HIP / 50) * 1.5 
            end 
        end 

        pc:SetControlRotation({Pitch=newPitch, Yaw=newYaw, Roll=0}, "Aimbot") 
    end) 
end 

local function later(sec, fn) 
    if _G.SetTimer then pcall(_G.SetTimer, sec, fn) return end 
    local tk = _G.Mytimer_ticker 
    if not tk then pcall(function() tk = require("common.time_ticker"); _G.Mytimer_ticker = tk end) end 
    if tk and tk.AddTimer then pcall(tk.AddTimer, sec, fn) return end 
    local GameThread = import("GameThread") 
    if GameThread and GameThread.Delay then pcall(GameThread.Delay, sec, fn) end 
end 

later(4, function() 
    pcall(function() 
        local pc = slua_GameFrontendHUD:GetPlayerController() 
        if IsValid(pc) then 
            pc:AddGameTimer(0.010, true, _G.SmartAimbot) 
            pc:AddGameTimer(0.010, true, UltimateEngine) 
        end 
    end) 
end) 

_G.InitUltimateAim = function() 
    if _G.UltimateAimInitialized then return end 
    _G.UltimateAimInitialized = true 
    
    local LocUtil = _G.LocUtil or require("client.common.LocUtil") 
    if LocUtil and not LocUtil._IsUltimateAimHooked then 
        local orig = LocUtil.GetLocalizeResStr 
        LocUtil.GetLocalizeResStr = function(k) 
            local n = tonumber(k) 
            if n and orig then return orig(n) end 
            return k 
        end 
        LocUtil._IsUltimateAimHooked = true 
    end 
    
    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine") 
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog") 
    if SettingPageDefine.UltimateAim then return end 
    
    local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap") 
    local UltimateAim = { 
        Key = "UltimateAim", 
        loc = "Jinshiforyou Aimbot 5.0", 
        UIKey = "Setting_Page_Privacy", 
        Category = {} 
    } 
    
    table.insert(UltimateAim.Category, { 
        Key = "Cat_Aimbot", 
        loc = "Aimbot", 
        Stack = { 
            { 
                Key = "AimbotEnabled", 
                UI = AliasMap.TitleSwitcher, 
                Text = "Enable Aimbot", 
                GetFunc = function() return CONFIG.ENABLED == 1 end, 
                SetFunc = function(_, v) CONFIG.ENABLED = v and 1 or 0; return true end 
            }, 
            { 
                Key = "FireOnly", 
                UI = AliasMap.TitleSwitcher, 
                Text = "Fire Only", 
                GetFunc = function() return CONFIG.FIRE_ONLY == 1 end, 
                SetFunc = function(_, v) CONFIG.FIRE_ONLY = v and 1 or 0; return true end 
            }, 
            { 
                Key = "AimAtBots", 
                UI = AliasMap.TitleSwitcher, 
                Text = "Aim At Bots", 
                GetFunc = function() return CONFIG.AIM_AT_BOTS == 1 end, 
                SetFunc = function(_, v) CONFIG.AIM_AT_BOTS = v and 1 or 0; return true end 
            }, 
            { 
                Key = "FOV", 
                UI = AliasMap.Slider, 
                Text = "FOV", 
                Min = 10, 
                Max = 360, 
                Step = 10, 
                GetFunc = function() return CONFIG.FOV end, 
                SetFunc = function(_, v) CONFIG.FOV = v; return true end 
            }, 
            { 
                Key = "Smooth", 
                UI = AliasMap.Slider, 
                Text = "Smooth", 
                Min = 1, 
                Max = 100, 
                Step = 1, 
                GetFunc = function() return CONFIG.SMOOTH end, 
                SetFunc = function(_, v) CONFIG.SMOOTH = v; return true end 
            }, 
        } 
    }) 
    
    SettingPageDefine.UltimateAim = UltimateAim 
    table.insert(SettingCatalog, SettingPageDefine.UltimateAim) 
    
    local UIManager = _G.UIManager 
    if UIManager and not UIManager._IsUltimateAimHooked then 
        local origShow = UIManager.ShowUI 
        UIManager.ShowUI = function(config, ...) 
            local args = {...} 
            local cnt = select("#", ...) 
            if config and config.keyName and string.find(string.lower(config.keyName), "setting") then 
                local cat = args[1] 
                if type(cat) == "table" then 
                    local found = false 
                    for _, p in ipairs(cat) do 
                        if type(p) == "table" and p.Key == "UltimateAim" then 
                            found = true 
                            break 
                        end 
                    end 
                    if not found then 
                        table.insert(cat, SettingPageDefine.UltimateAim) 
                    end 
                end 
            end 
            return origShow(config, table.unpack(args, 1, cnt)) 
        end 
        UIManager._IsUltimateAimHooked = true 
    end 
end 

later(3, function() 
    pcall(_G.InitUltimateAim) 
end)

-- ==================== PART 4: CLASS REGISTRATION (LAST) ====================

local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)
return require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
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
    BuildAircraftVehicleFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature"
  },
  {
    UnifiedBuildVehicleFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.UnifiedBuildVehicleFeature"
  },
  {
    CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature"
  },
  {
    ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature"
  },
  {
    ParachuteSprint = "GameLua.Mod.BaseMod.GamePlay.Feature.Parachute.ParachuteSprintFeature"
  },
  {
    GeneralShowSpotFeature = "GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature"
  },
  {
    FPPAnimMonitor = "GameLua.Mod.BaseMod.GamePlay.Feature.Player.FPPAnimMonitorFeature"
  }
}, "BRPlayerCharacterBase")