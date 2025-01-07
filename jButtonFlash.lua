-- locals and speed
local AddonName, Addon = ...

local _G = _G

local GetActionButtonForID = GetActionButtonForID

local TEXTURE_OFFSET = 3

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

  if (action) then
    action(self, ...)
  end
end

function Addon:PLAYER_LOGIN()
  self:SetupButtonFlash()
  self:HookActionEvents()
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
  alpha:SetFromAlpha(0)
  alpha:SetToAlpha(1)
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

function Addon:ActionButtonDown(id)
  local button = GetActionButtonForID(id)
  if (button) then
    self:AnimateButton(button)
  end
end

function Addon:MultiActionButtonDown(bar, id)
  local button = _G[bar..'Button'..id]
  if (button) then
    self:AnimateButton(button)
  end
end

function Addon:AnimateButton(button)
  if (not button:IsVisible()) then return end

  self.frame:SetPoint('TOPLEFT', button, 'TOPLEFT', -TEXTURE_OFFSET, TEXTURE_OFFSET)
  self.frame:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', TEXTURE_OFFSET, -TEXTURE_OFFSET)

  self.animationGroup:Stop()
  self.animationGroup:Play()
end

-- call
Addon:Load()
