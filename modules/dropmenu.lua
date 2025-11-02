--[[
    Modular Roblox Dropdown Menu (User's Drag Version)
    Version: 1.0.2
    Description: A modular dropdown menu component for Roblox with draggable title bar,
                 using the drag implementation style provided by the user.
]]

local ModularDropdown = {}
ModularDropdown.__index = ModularDropdown

-- 点击音效
local uiclicker = Instance.new("Sound")
uiclicker.SoundId = "rbxassetid://535716488"
uiclicker.Volume = 0.3
uiclicker.Parent = SoundService

-- Constants for UI styling
local UI_STYLES = {
    Menu = {
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderColor3 = Color3.fromRGB(0, 0, 0), -- Black border
        BorderSizePixel = 2,
        CornerRadius = UDim.new(0, 2),
        ShadowTransparency = 0.7,
        ShadowSize = 5
    },
    Title = {
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 16,
        Font = Enum.Font.SourceSansBold,
        Height = 30
    },
    Item = {
        BackgroundColor3 = Color3.fromRGB(65, 65, 65),
        HoverColor = Color3.fromRGB(50, 50, 50),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 16,
        Font = Enum.Font.SourceSans,
        Height = 28
    }
}

--[[
    Creates a new ModularDropdown instance.
    
    Parameters:
        title (string) - The title to display at the top of the menu
        position (Vector2) - The initial position of the menu on the screen
        parent (Instance) - The parent instance to attach the menu to (usually PlayerGui)
        
    Returns:
        ModularDropdown - A new ModularDropdown instance
]]
function ModularDropdown.new(title, position, parent)
    local self = setmetatable({}, ModularDropdown)
    
    -- Main menu container (mainFrame in user's code)
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "MenuContainer"
    self.mainFrame.Position = UDim2.new(0, position.X, 0, position.Y)
    self.mainFrame.BackgroundColor3 = UI_STYLES.Menu.BackgroundColor3
    self.mainFrame.BorderColor3 = UI_STYLES.Menu.BorderColor3
    self.mainFrame.BorderSizePixel = UI_STYLES.Menu.BorderSizePixel
    self.mainFrame.ClipsDescendants = true
    self.mainFrame.Parent = parent
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UI_STYLES.Menu.CornerRadius
    corner.Parent = self.mainFrame
    
    -- Add shadow effect
    local shadow = Instance.new("UIStroke")
    shadow.Name = "MenuShadow"
    shadow.Color = Color3.fromRGB(0, 0, 0)
    shadow.Transparency = UI_STYLES.Menu.ShadowTransparency
    shadow.Thickness = UI_STYLES.Menu.ShadowSize
    shadow.Parent = self.mainFrame
    
    -- Title bar (draggable)
    self.titleBar = Instance.new("TextButton")
    self.titleBar.Name = "TitleBar"
    self.titleBar.Text = title
    self.titleBar.BackgroundColor3 = UI_STYLES.Title.BackgroundColor3
    self.titleBar.TextColor3 = UI_STYLES.Title.TextColor3
    self.titleBar.TextSize = UI_STYLES.Title.TextSize
    self.titleBar.Font = UI_STYLES.Title.Font
    self.titleBar.Size = UDim2.new(1, 0, 0, UI_STYLES.Title.Height)
    self.titleBar.Position = UDim2.new(0, 0, 0, 0)
    self.titleBar.AutoButtonColor = false
    self.titleBar.Parent = self.mainFrame
    
    -- Content container for menu items
    self.contentContainer = Instance.new("Frame")
    self.contentContainer.Name = "ContentContainer"
    self.contentContainer.BackgroundTransparency = 1
    self.contentContainer.Size = UDim2.new(1, 0, 0, 0)
    self.contentContainer.Position = UDim2.new(0, 0, 0, UI_STYLES.Title.Height)
    self.contentContainer.Parent = self.mainFrame
    
    -- UIListLayout for automatic item layout
    self.listLayout = Instance.new("UIListLayout")
    self.listLayout.Name = "ItemLayout"
    self.listLayout.FillDirection = Enum.FillDirection.Vertical
    self.listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    self.listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    self.listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    self.listLayout.Parent = self.contentContainer
    
    -- Store menu items
    self.menuItems = {}
    self.itemCount = 0
    
    -- Initialize drag functionality using user's implementation
    self:InitializeDragBehavior()
    
    -- Update menu size initially
    self:UpdateMenuSize()
    
    return self
end

--[[
    Initializes the drag behavior for the title bar.
    IMPLEMENTATION: Using the exact style from the user's provided code
]]
function ModularDropdown:InitializeDragBehavior()
    local UserInputService = game:GetService("UserInputService")
    local isDragging = false
    local dragStartPos
    local windowStartPos
    
    -- Title bar InputBegan event (as per user's code)
    self.titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
            windowStartPos = self.mainFrame.Position
            
            -- Visual feedback: darken title bar when dragging
            self.titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end
    end)
    
    -- Title bar InputEnded event (as per user's code)
    self.titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
            
            -- Visual feedback: revert title bar color
            self.titleBar.BackgroundColor3 = UI_STYLES.Title.BackgroundColor3
        end
    end)
    
    -- UserInputService InputChanged event (as per user's code)
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartPos
            self.mainFrame.Position = UDim2.new(
                windowStartPos.X.Scale,
                windowStartPos.X.Offset + delta.X,
                windowStartPos.Y.Scale,
                windowStartPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Prevent title bar click from activating twice
    self.titleBar.MouseButton1Click:Connect(function()
        -- Empty function to consume the click event
    end)
end

--[[
    Adds a new item to the menu.
    
    Parameters:
        text (string) - The text to display for the item
        callback (function) - The function to execute when the item is clicked
        
    Returns:
        Instance - The created menu item button
]]
function ModularDropdown:AddMenuItem(text, callback, mode)
    self.itemCount = self.itemCount + 1
    
    -- Create item button
    local itemButton = Instance.new("TextButton")
    itemButton.Name = "MenuItem_" .. self.itemCount
    itemButton.Text = text
    itemButton.BackgroundColor3 = UI_STYLES.Item.BackgroundColor3
    itemButton.TextColor3 = UI_STYLES.Item.TextColor3
    itemButton.TextSize = UI_STYLES.Item.TextSize
    itemButton.Font = UI_STYLES.Item.Font
    itemButton.Size = UDim2.new(1, 0, 0, UI_STYLES.Item.Height)
    itemButton.LayoutOrder = self.itemCount
    itemButton.AutoButtonColor = false
    itemButton.Parent = self.contentContainer

    local enable = false

    -- Add hover effect
    itemButton.MouseEnter:Connect(function()
        itemButton.BackgroundColor3 = enable and Color3.new(0.3, 1, 0.5) or UI_STYLES.Item.HoverColor
    end)
    
    itemButton.MouseLeave:Connect(function()
        itemButton.BackgroundColor3 = enable and Color3.new(0.8, 1, 0.5) or UI_STYLES.Item.BackgroundColor3
        itemButton.TextColor3 = enable and Color3.new(0, 0, 0) or UI_STYLES.Item.TextColor3
    end)
    
    -- Add click event
    itemButton.MouseButton1Click:Connect(function()
        uiclicker:Play()
        if type(callback) == "function" and mode == 1 then
            callback()
        elseif type(callback) == "function" and mode == 2 then
            enable = not enable
            itemButton.BackgroundColor3 = enable and Color3.new(0.8, 1, 0.5) or UI_STYLES.Item.BackgroundColor3
            itemButton.TextColor3 = enable and Color3.new(0, 0, 0) or UI_STYLES.Item.TextColor3
            callback(enable)
        end
    end)
    
    -- Store the menu item
    table.insert(self.menuItems, {
        Button = itemButton,
        Text = text,
        Callback = callback
    })
    
    -- Update menu size
    self:UpdateMenuSize()
    
    return itemButton
end

--[[
    Updates the menu size based on the number of items.
]]
function ModularDropdown:UpdateMenuSize()
    -- Calculate total content height
    local contentHeight = self.itemCount * UI_STYLES.Item.Height
    
    -- Update content container size
    self.contentContainer.Size = UDim2.new(1, 0, 0, contentHeight)
    
    -- Calculate menu width based on longest text
    local maxTextWidth = 0
    for _, item in ipairs(self.menuItems) do
        local textWidth = item.Button.TextBounds.X
        if textWidth > maxTextWidth then
            maxTextWidth = textWidth
        end
    end
    
    -- Also consider title width
    local titleWidth = self.titleBar.TextBounds.X
    local menuWidth = math.max(maxTextWidth, titleWidth) + 40 -- Add padding
    
    -- Update menu container size
    self.mainFrame.Size = UDim2.new(
        0, menuWidth,
        0, UI_STYLES.Title.Height + contentHeight
    )
end

--[[
    Updates the text of a specific menu item.
    
    Parameters:
        index (number) - The index of the menu item
        text (string) - The new text for the item
]]
function ModularDropdown:SetItemText(index, text)
    if self.menuItems[index] then
        local item = self.menuItems[index]
        item.Text = text
        item.Button.Text = text
        
        -- Update menu size in case text is longer
        self:UpdateMenuSize()
    end
end

--[[
    Shows the menu.
]]
function ModularDropdown:Show()
    self.screenGui.Enabled = true
end

--[[
    Hides the menu.
]]
function ModularDropdown:Hide()
    self.screenGui.Enabled = false
end

--[[
    Destroys the menu and cleans up resources.
]]
function ModularDropdown:Destroy()
    -- Destroy the main UI components
    self.screenGui:Destroy()
    
    -- Clear references
    self.menuItems = nil
end

return ModularDropdown
