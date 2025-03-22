local AddonName, Addon = ...
local _G = _G

--------------------------------------------------------------------------------
-- client compatibility
--------------------------------------------------------------------------------
local display_version, build_number, build_date, ui_version = GetBuildInfo()

-- AnimationGroup subfeatures not supported earlier than 3.1.0 client.
if not ui_version or ui_version < 30100 then return end

local is_wotlk, is_cata, is_wod, is_legion_or_later
if ui_version >= 30100 and ui_version <= 30300 then
  is_wotlk = true
elseif ui_version >= 40000 and ui_version <= 40300 then
  is_cata = true
elseif ui_version >= 50001 and ui_version <= 50400 then
  is_mop = true
elseif ui_version >= 60000 and ui_version <= 60200 then
  is_wod = true
else
  is_legion_or_later = true
end

local GetActionButtonForID
if is_wotlk or is_cata then
  local VEHICLE_MAX_ACTIONBUTTONS = _G.VEHICLE_MAX_ACTIONBUTTONS --6
  
  GetActionButtonForID = function(id)
    if VehicleMenuBar:IsShown() and id <= VEHICLE_MAX_ACTIONBUTTONS then
      return _G["VehicleMenuBarActionButton"..id]
    elseif BonusActionBarFrame:IsShown() then
      return _G["BonusActionButton"..id]
    else
      return _G["ActionButton"..id]
    end
  end
else
  local NUM_OVERRIDE_BUTTONS = _G.NUM_OVERRIDE_BUTTONS --6
  local isInPetBattle = _G.C_PetBattles.IsInBattle
  local function isPetBattle()
    if isInPetBattle() and PetBattleFrame then 
      return true
    end
    
    return false
  end
  
  if is_mop or is_wod then
    GetActionButtonForID = function(id)
      if isPetBattle() then return end
      
      if OverrideActionBar and OverrideActionBar:IsShown() then
        if id > NUM_OVERRIDE_BUTTONS then return end
        return _G["OverrideActionBarButton"..id]
      else
        return _G["ActionButton"..id]
      end
    end
  -- Legion or later.
  else
    local original = _G.GetActionButtonForID
    GetActionButtonForID = function(id)
      if isPetBattle() then return end
      return original(id)
    end
  end
end

local setAlphaDelta
if is_wotlk or is_cata or is_mop then
  setAlphaDelta = function(alpha)
    alpha:SetChange(1)
  end
else
  setAlphaDelta = function(alpha)
    alpha:SetFromAlpha(0)
    alpha:SetToAlpha(1)
  end
end

--------------------------------------------------------------------------------

local BARTENDER4_NAME = "Bartender4"
local BARTENDER4_BUTTONS_MAX = 120
local BARTENDER4_BUTTONS_PET_MAX = 10

-- main
function Addon:Load()
  do
    local eventHandler = CreateFrame('Frame', nil)

    -- set OnEvent handler
    eventHandler:SetScript('OnEvent', function(handler, ...)
        self:OnEvent(...)
      end)

    eventHandler:RegisterEvent('PLAYER_LOGIN')
  end
end

-- frame events
function Addon:OnEvent(event, ...)
  local action = self[event]

  if action then
    action(self, ...)
  end
end

function Addon:PLAYER_LOGIN()
  -- Blizzard buttons
  self:SetupButtonFlash()
  self:HookActionEvents()
  
  -- Addon "Bartender4" buttons
  local bt4 = IsAddOnLoaded(BARTENDER4_NAME)
  if bt4 then
    self:HookBartender4Buttons()
  end
end

function Addon:SetupButtonFlash()
  local frame = CreateFrame('Frame', nil)
  frame:SetFrameStrata('TOOLTIP')

  local texture = frame:CreateTexture()
  texture:SetTexture([[Interface\Cooldown\star4]])
  texture:SetAlpha(0)
  texture:SetAllPoints(frame)
  texture:SetBlendMode('ADD')
  texture:SetDrawLayer('OVERLAY', 7)

  local animationGroup = texture:CreateAnimationGroup()

  local alpha = animationGroup:CreateAnimation('Alpha')
  setAlphaDelta(alpha)
  alpha:SetDuration(0)
  alpha:SetOrder(1)

  local scale1 = animationGroup:CreateAnimation('Scale')
  scale1:SetScale(1.5, 1.5)
  scale1:SetDuration(0)
  scale1:SetOrder(1)

  local scale2 = animationGroup:CreateAnimation('Scale')
  scale2:SetScale(0, 0)
  scale2:SetDuration(.3)
  scale2:SetOrder(2)

  local rotation2 = animationGroup:CreateAnimation('Rotation')
  rotation2:SetDegrees(90)
  rotation2:SetDuration(.3)
  rotation2:SetOrder(2)

  self.frame = frame
  self.animationGroup = animationGroup
end

-- hooks
-- - Blizzard buttons
do
  local function Button_ActionButtonDown(id)
    Addon:ActionButtonDown(id)
  end

  local function Button_MultiActionButtonDown(bar, id)
    Addon:MultiActionButtonDown(bar, id)
  end

  function Addon:HookActionEvents()
    hooksecurefunc('ActionButtonDown', Button_ActionButtonDown)
    hooksecurefunc('MultiActionButtonDown', Button_MultiActionButtonDown)
  end
end

-- - Bartender4 support
do
  local function Button_OnMouseDown(self, _)
      Addon:AnimateButton(self)
  end

  -- Note. using RegisterForClicks and OnClick can result in extra effects
  -- such as sounds for each part of the click. So, use OnMouseDown instead
  function Addon:HookBartender4Buttons()
    -- Player action buttons
    for i = 1, BARTENDER4_BUTTONS_MAX do
      local button = _G["BT4Button" .. i]
      if button then
        button:HookScript("OnMouseDown", Button_OnMouseDown)
      end
    end
    
    -- Pet action buttons
    for i = 1, BARTENDER4_BUTTONS_PET_MAX do
      local button = _G["BT4PetButton" .. i]
      if button then
        button:HookScript("OnMouseDown", Button_OnMouseDown)
      end
    end
  end
end

function Addon:ActionButtonDown(id)
  if not id then return end
  
  local button = GetActionButtonForID(id)
  if button then
    self:AnimateButton(button)
  end
end

function Addon:MultiActionButtonDown(bar, id)
  if not bar or not id then return end
  
  local button = _G[bar.."Button"..id]
  if button then
    self:AnimateButton(button)
  end
end

do
  local TEXTURE_OFFSET = 3
  
  function Addon:AnimateButton(button)
    if not button:IsVisible() then return end

    self.frame:SetPoint('TOPLEFT', button, 'TOPLEFT', -TEXTURE_OFFSET, 
      TEXTURE_OFFSET)
    self.frame:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', TEXTURE_OFFSET, 
      -TEXTURE_OFFSET)

    self.animationGroup:Stop()
    self.animationGroup:Play()
  end
end

-- begin
Addon:Load()
