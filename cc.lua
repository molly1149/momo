local Class = require("class")
local CharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CombineClass = require("combine_class")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")

_G.Mod_NoRecoil = _G.Mod_NoRecoil or false
_G.Mod_WideFOV = _G.Mod_WideFOV or true

pcall(function()
  if require("client.logic.setting.setting_config") and require("client.logic.setting.setting_config").TpViewValue then
    require("client.logic.setting.setting_config").TpViewValue.max = 140
    require("client.logic.setting.setting_config").FpViewValue.max = 140
  end
  if require("client.logic.NewSetting.SettingItemDefine.SettingItem_Game") and require("client.logic.NewSetting.SettingItemDefine.SettingItem_Game").TpViewValue then
    require("client.logic.NewSetting.SettingItemDefine.SettingItem_Game").TpViewValue.Max = 140
    require("client.logic.NewSetting.SettingItemDefine.SettingItem_Game").FpViewValue.Max = 140
  end
end)

function _G.TryShowWelcomeNoRecoil()
  if _G.WelcomeShown then return end
  pcall(function()
    local msgBox = package.loaded["client.slua.logic.common.logic_common_msg_box"] or require("client.slua.logic.common.logic_common_msg_box")
    local enableRecoil = function()
      _G.Mod_NoRecoil = true
      msgBox.Show(1, "pubg", "✓ open", nil, nil)
    end
    local disableRecoil = function()
      _G.Mod_NoRecoil = false
      msgBox.Show(1, "pubg", "✗ close", nil, nil)
    end
    msgBox.Show(2, "pubg设置", "是否开启pubg？\n\n[左边按钮]: 关闭\n[右边按钮]: 开启", enableRecoil,disableRecoil)
    _G.WelcomeShown = true
  end)
end

function _G.Enable165FPSLogic()
  pcall(function()
    local graphics = require("client.slua.logic.setting.logic_setting_graphics")
    local fpsComp = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
    local fpsFT = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
    local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
    if graphics then
      local orig = graphics.SetFPS
      function graphics:SetFPS(lvl)
        if orig then orig(self, lvl) end
        if lvl == 8 then
          self:ExecuteCMD("t.MaxFPS", "165")
          self:ExecuteCMD("r.FrameRateLimit", "165")
        end
      end
    end
    if fpsComp and fpsComp.__inner_impl then
      local impl = fpsComp.__inner_impl
      function impl.GetMaxFPSLevel() return 8, 8 end
      function impl:InitRealSupportFPS()
        local t = {}
        for i = 1, 8 do t[i] = {true, true} end
        if db then db:UpdateUIData(db.RealSupportFPS, t, false) end
        return t
      end
      function impl:UpdateSelectedFPSState(lvl)
        local fpsMap = {[2]=20, [3]=25, [4]=30, [5]=40, [6]=60, [7]=90, [8]=120}
        for i = 2, 8 do
          local nodeName = "NodeFps" .. (fpsMap[i] or 120)
          local node = self.UIRoot[nodeName]
          if slua.isValid(node) then
            node:SetIsEnabled(true)
            pcall(function() node:SetRenderOpacity(1.0) end)
            local sw = self.UIRoot["WidgetSwitcher_" .. i]
            if slua.isValid(sw) then
              sw:SetActiveWidgetIndex(i == lvl and 0 or 1)
            end
          end
        end
      end
    end
    if fpsFT and fpsFT.__inner_impl then
      local impl = fpsFT.__inner_impl
      local MIN_FPS, STEP = 90, 5
      local function clamp(v, lo, hi)
        if v < lo then return lo end
        if hi < v then return hi end
        return v
      end
      function impl:ShowOrHide()
        self:SelfHitTestInvisible()
        if self.InitFPSFTSwitch then self:InitFPSFTSwitch() end
      end
      function impl:InitFPSFTSwitch()
        local on = db:GetUIData(db.FPSFineTuneSwitch)
        if self.UIRoot.Setting_Switch then
          self.UIRoot.Setting_Switch:SetSwitcherEnable2(on, true)
        end
        if self.UIRoot.CanvasPanel_8 then
          self:SetWidgetVisible(self.UIRoot.CanvasPanel_8, on)
        end
        if self.UIRoot.WidgetSwitcher_0 then
          self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2)
        end
        if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
      end
      function impl:InitFPSFTValue165()
        local r = self.UIRoot
        local on = db:GetUIData(db.FPSFineTuneSwitch)
        local val = on and (db:GetUIData(db.FPSFineTuneNum) or 165) or 165
        if on then
          r.Slider_screen3:SetLocked(false)
          r.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1,1,1,1))
          r.Slider_screen3:SetSliderHandleColor(FLinearColor(1,1,1,1))
        else
          r.Slider_screen3:SetLocked(true)
          r.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1,0.625,0.6,1))
          r.Slider_screen3:SetSliderHandleColor(FLinearColor(1,0.625,0.6,1))
        end
        local norm = (val - MIN_FPS) / (165 - MIN_FPS)
        r.Veihclescreen3:SetText(tostring(val))
        r.Slider_screen3:SetValue(norm)
        r.ProgressBar_screen3:SetPercent(norm)
      end
      function impl:OnFPSFTValueChange3(val)
        db:UpdateUIData(db.FPSFineTuneNum, val)
        if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
        if self:GetParentUI() then self:GetParentUI():SetDirty(true) end
        local gi = db.GetGameInstance and db.GetGameInstance()
        if gi then
          gi:ExecuteCMD("t.MaxFPS", tostring(val))
          gi:ExecuteCMD("r.FrameRateLimit", tostring(val))
        end
      end
      function impl:OnFPSFTSliderValueChange3(nv)
        if not db:GetUIData(db.FPSFineTuneSwitch) then return end
        local raw = math.floor((MIN_FPS + nv * (165 - MIN_FPS)) / STEP + 0.5) * STEP
        self:OnFPSFTValueChange3(clamp(raw, MIN_FPS, 165))
      end
      function impl:OnFPSFTAdd3()
        local cur = db:GetUIData(db.FPSFineTuneNum) or 90
        self:OnFPSFTValueChange3(math.min(165, cur + STEP))
      end
      function impl:OnFPSFTMinus3()
        local cur = db:GetUIData(db.FPSFineTuneNum) or 90
        self:OnFPSFTValueChange3(math.max(MIN_FPS, cur - STEP))
      end
      impl.OnFPSFTAdd = impl.OnFPSFTAdd3
      impl.OnFPSFTMinus = impl.OnFPSFTMinus3
      impl.OnFPSFTSliderValueChange = impl.OnFPSFTSliderValueChange3
    end
  end)
end

local function noRecoilJitter(base)
  return base + (math.random(-2, 2) * 0.01)
end

local PlayerModule = {}

function PlayerModule:ctor()
  self.LastWeapon = nil
end

function PlayerModule:postConstruct()
  CharacterBase._PostConstruct(self)
  self:StartAdvancedSystems()
end

function PlayerModule:receiveBeginPlay()
  CharacterBase.ReceiveBeginPlay(self)
  if Client then
    _G.Enable165FPSLogic()
    _G.TryShowWelcomeNoRecoil()
  end
end

function PlayerModule:receiveEndPlay(reason)
  CharacterBase.ReceiveEndPlay(self, reason)
end

function PlayerModule:startAdvancedSystems()
  if not Client then return end
  self:AddGameTimer(0.5, true, function()
    if not slua.isValid(self.Object) then return end
    local lp = GameplayData.GetPlayerCharacter()
    if not slua.isValid(lp) then return end

    if _G.Mod_WideFOV then
      local ss = SubsystemMgr:Get("SettingSubsystem")
      if ss then
        local tpFov = ss:GetUserSettings_Int("TpViewValue")
        if tpFov and tpFov > 0 then
          local tpCam = self.Object.ThirdPersonCameraComponent
          if slua.isValid(tpCam) and not self.Object.bIsWeaponAiming and tpCam.FieldOfView ~= tpFov then
            tpCam.FieldOfView = tpFov
          end
        end
      end
    end

    if _G.Mod_NoRecoil then
      self:ApplyWeaponMods()
    end
  end)
end

function PlayerModule:ApplyWeaponMods()
  if not Client then return end
  local weapon = self.Object.GetCurrentWeapon and self.Object:GetCurrentWeapon()
  if not slua.isValid(weapon) then return end
  if weapon == self.LastWeapon then return end
  self.LastWeapon = weapon

  local entity = weapon.ShootWeaponEntityComp
  if not slua.isValid(entity) then return end

  if _G.Mod_NoRecoil then
    entity.Scale3D = 10
    entity.RecoilKick = noRecoilJitter(0.1)
    entity.RecoilKickADS = noRecoilJitter(0.1)
    entity.AnimationKick = noRecoilJitter(0.1)
    entity.AccessoriesVRecoilFactor = 0.2
    entity.AccessoriesHRecoilFactor = 0.2
    entity.GameDeviationFactor  = noRecoilJitter(0.08)
    entity.GameDeviationAccuracy = 0.01
    entity.ExtraHitPerformScale = 10
    entity.SwitchFromBackpackToIdleTime = 0.1
    entity.SwitchFromIdleToBackpackTime = 0.1

    if entity.RecoilInfo then
      entity.RecoilInfo.VerticalRecoilMin = 0.8
      entity.RecoilInfo.VerticalRecoilMax = 1.5
      entity.RecoilInfo.RecoilSpeedVertical = 0.8
      entity.RecoilInfo.RecoilSpeedHorizontal = 0.8
      entity.RecoilInfo.VerticalRecoveryMax = 0.8
      entity.RecoilInfo.RecoilModifierStand = 0.15
      entity.RecoilInfo.RecoilModifierCrouch = 0.15
      entity.RecoilInfo.RecoilModifierProne = 0.15
    end
  end
end

local BRPlayerCharacterBase = Class(CharacterBase, nil, {
  ctor = PlayerModule.ctor,
  _PostConstruct = PlayerModule.postConstruct,
  ReceiveBeginPlay = PlayerModule.receiveBeginPlay,
  ReceiveEndPlay = PlayerModule.receiveEndPlay,
  StartAdvancedSystems = PlayerModule.startAdvancedSystems,
  ApplyWeaponMods = PlayerModule.ApplyWeaponMods,
})


pcall(function()
    local clientReport = package.loaded["GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem"]
    if not clientReport then
        clientReport = require("GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem")
    end
    if clientReport then
        local noop = function() end
        clientReport.OnInit = noop
        clientReport._OnPlayerKilledOtherPlayer = noop
        clientReport._RecordFatalDamager = noop
        clientReport._OnBattleResult = noop
    end
end)

pcall(function()
    local HiggsBosonComponent = import("HiggsBosonComponent")
    if HiggsBosonComponent then
        HiggsBosonComponent.ValidateSecurityData = function() return true end
    end
end)

return CombineClass.DeclareFeature(BRPlayerCharacterBase, {
  { SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
  { CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
  { SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
  { TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
  { LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
  { FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
  { CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
  { BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature" },
  { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" }
}, "BRPlayerCharacterBase")                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               