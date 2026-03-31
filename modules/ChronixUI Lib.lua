-- local library = {count = 0, queue = {}, callbacks = {}, rainbowtable = {}, toggled = true, binds = {}};
-- local defaults; do
--     local dragger = {}; do
--         local mouse        = game:GetService("Players").LocalPlayer:GetMouse();
--         local inputService = game:GetService('UserInputService');
--         local heartbeat    = game:GetService("RunService").Heartbeat;
--         -- // credits to Ririchi / Inori for this cute drag function :)
--         function dragger.new(frame)
--             local s, event = pcall(function()
--                 return frame.MouseEnter
--             end)
    
--             if s then
--                 frame.Active = true;
                
--                 event:connect(function()
--                     local input = frame.InputBegan:connect(function(key)
--                         if key.UserInputType == Enum.UserInputType.MouseButton1 then
--                             local objectPosition = Vector2.new(mouse.X - frame.AbsolutePosition.X, mouse.Y - frame.AbsolutePosition.Y);
--                             while heartbeat:wait() and inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
--                                 pcall(function()
--                                     frame:TweenPosition(UDim2.new(0, mouse.X - objectPosition.X + (frame.Size.X.Offset * frame.AnchorPoint.X), 0, mouse.Y - objectPosition.Y + (frame.Size.Y.Offset * frame.AnchorPoint.Y)), 'Out', 'Linear', 0.1, true);
--                                 end)
--                             end
--                         end
--                     end)
    
--                     local leave;
--                     leave = frame.MouseLeave:connect(function()
--                         input:disconnect();
--                         leave:disconnect();
--                     end)
--                 end)
--             end
--         end

--         game:GetService('UserInputService').InputBegan:connect(function(key, gpe)
--             if (not gpe) then
--                 if key.KeyCode == Enum.KeyCode.RightControl then
--                     library.toggled = not library.toggled;
--                     for i, data in next, library.queue do
--                         local pos = (library.toggled and data.p or UDim2.new(-1, 0, -0.5,0))
--                         data.w:TweenPosition(pos, (library.toggled and 'Out' or 'In'), 'Quad', 0.15, true)
--                         wait();
--                     end
--                 end
--             end
--         end)
--     end
    
--     local types = {}; do
--         types.__index = types;
--         function types.window(name, options)
--             library.count = library.count + 1
--             local newWindow = library:Create('Frame', {
--                 Name = name;
--                 Size = UDim2.new(0, 190, 0, 30);
--                 BackgroundColor3 = options.topcolor;
--                 BorderSizePixel = 0;
--                 Parent = library.container;
--                 Position = UDim2.new(0, (15 + (200 * library.count) - 200), 0, 0);
--                 ZIndex = 3;
--                 library:Create('TextLabel', {
--                     Text = name;
--                     Size = UDim2.new(1, -10, 1, 0);
--                     Position = UDim2.new(0, 5, 0, 0);
--                     BackgroundTransparency = 1;
--                     Font = Enum.Font.Code;
--                     TextSize = options.titlesize;
--                     Font = options.titlefont;
--                     TextColor3 = options.titletextcolor;
--                     TextStrokeTransparency = library.options.titlestroke;
--                     TextStrokeColor3 = library.options.titlestrokecolor;
--                     ZIndex = 3;
--                 });
--                 library:Create("TextButton", {
--                     Size = UDim2.new(0, 30, 0, 30);
--                     Position = UDim2.new(1, -35, 0, 0);
--                     BackgroundTransparency = 1;
--                     Text = "-";
--                     TextSize = options.titlesize;
--                     Font = options.titlefont;--Enum.Font.Code;
--                     Name = 'window_toggle';
--                     TextColor3 = options.titletextcolor;
--                     TextStrokeTransparency = library.options.titlestroke;
--                     TextStrokeColor3 = library.options.titlestrokecolor;
--                     ZIndex = 3;
--                 });
--                 library:Create("Frame", {
--                     Name = 'Underline';
--                     Size = UDim2.new(1, 0, 0, 2);
--                     Position = UDim2.new(0, 0, 1, -2);
--                     BackgroundColor3 = (options.underlinecolor ~= "rainbow" and options.underlinecolor or Color3.new());
--                     BorderSizePixel = 0;
--                     ZIndex = 3;
--                 });
--                 library:Create('Frame', {
--                     Name = 'container';
--                     Position = UDim2.new(0, 0, 1, 0);
--                     Size = UDim2.new(1, 0, 0, 0);
--                     BorderSizePixel = 0;
--                     BackgroundColor3 = options.bgcolor;
--                     ClipsDescendants = false;
--                     library:Create('UIListLayout', {
--                         Name = 'List';
--                         SortOrder = Enum.SortOrder.LayoutOrder;
--                     })
--                 });
--             })
            
--             if options.underlinecolor == "rainbow" then
--                 table.insert(library.rainbowtable, newWindow:FindFirstChild('Underline'))
--             end

--             local window = setmetatable({
--                 count = 0;
--                 object = newWindow;
--                 container = newWindow.container;
--                 toggled = true;
--                 flags   = {};

--             }, types)

--             table.insert(library.queue, {
--                 w = window.object;
--                 p = window.object.Position;
--             })

--             newWindow:FindFirstChild("window_toggle").MouseButton1Click:connect(function()
--                 window.toggled = not window.toggled;
--                 newWindow:FindFirstChild("window_toggle").Text = (window.toggled and "+" or "-")
--                 if (not window.toggled) then
--                     window.container.ClipsDescendants = true;
--                 end
--                 wait();
--                 local y = 0;
--                 for i, v in next, window.container:GetChildren() do
--                     if (not v:IsA('UIListLayout')) then
--                         y = y + v.AbsoluteSize.Y;
--                     end
--                 end 

--                 local targetSize = window.toggled and UDim2.new(1, 0, 0, y+5) or UDim2.new(1, 0, 0, 0);
--                 local targetDirection = window.toggled and "In" or "Out"

--                 window.container:TweenSize(targetSize, targetDirection, "Quad", 0.15, true)
--                 wait(.15)
--                 if window.toggled then
--                     window.container.ClipsDescendants = false;
--                 end
--             end)

--             return window;
--         end
        
--         function types:Resize()
--             local y = 0;
--             for i, v in next, self.container:GetChildren() do
--                 if (not v:IsA('UIListLayout')) then
--                     y = y + v.AbsoluteSize.Y;
--                 end
--             end 
--             self.container.Size = UDim2.new(1, 0, 0, y+5)
--         end
        
--         function types:GetOrder() 
--             local c = 0;
--             for i, v in next, self.container:GetChildren() do
--                 if (not v:IsA('UIListLayout')) then
--                     c = c + 1
--                 end
--             end
--             return c
--         end
        
--         function types:Label(text)
--             local v = game:GetService'TextService':GetTextSize(text, 18, Enum.Font.SourceSans, Vector2.new(math.huge, math.huge))
--             local object = library:Create('Frame', {
--                 Size = UDim2.new(1, 0, 0, v.Y + 5);
--                 BackgroundTransparency  = 1;
--                 library:Create('TextLabel', {
--                     Size = UDim2.new(1, 0, 1, 0);
--                     Position = UDim2.new(0, 10, 0, 0);
--                     LayoutOrder = self:GetOrder();

--                     Text = text;
--                     TextSize = 18;
--                     Font = Enum.Font.SourceSans;
--                     TextColor3 = Color3.fromRGB(255, 255, 255);
--                     BackgroundTransparency = 1;
--                     TextXAlignment = Enum.TextXAlignment.Left;
--                     TextWrapped = true;
--                 });
--                 Parent = self.container
--             })
--             self:Resize();
--         end

--         function types:Toggle(name, options, callback)
--             local default  = options.default or false;
--             local location = options.location or self.flags;
--             local flag     = options.flag or "";
--             local callback = callback or function() end;
            
--             location[flag] = default;

--             local check = library:Create('Frame', {
--                 BackgroundTransparency = 1;
--                 Size = UDim2.new(1, 0, 0, 25);
--                 LayoutOrder = self:GetOrder();
--                 library:Create('TextLabel', {
--                     Name = name;
--                     Text = "\r" .. name;
--                     BackgroundTransparency = 1;
--                     TextColor3 = library.options.textcolor;
--                     Position = UDim2.new(0, 5, 0, 0);
--                     Size     = UDim2.new(1, -5, 1, 0);
--                     TextXAlignment = Enum.TextXAlignment.Left;
--                     Font = library.options.font;
--                     TextSize = library.options.fontsize;
--                     TextStrokeTransparency = library.options.textstroke;
--                     TextStrokeColor3 = library.options.strokecolor;
--                     library:Create('TextButton', {
--                         Text = (location[flag] and utf8.char(10003) or "");
--                         Font = library.options.font;
--                         TextSize = library.options.fontsize;
--                         Name = 'Checkmark';
--                         Size = UDim2.new(0, 20, 0, 20);
--                         Position = UDim2.new(1, -25, 0, 4);
--                         TextColor3 = library.options.textcolor;
--                         BackgroundColor3 = library.options.bgcolor;
--                         BorderColor3 = library.options.bordercolor;
--                         TextStrokeTransparency = library.options.textstroke;
--                         TextStrokeColor3 = library.options.strokecolor;
--                     })
--                 });
--                 Parent = self.container;
--             });
                
--             local function click(t)
--                 location[flag] = not location[flag];
--                 callback(location[flag])
--                 check:FindFirstChild(name).Checkmark.Text = location[flag] and utf8.char(10003) or "";
--             end

--             check:FindFirstChild(name).Checkmark.MouseButton1Click:connect(click)
--             library.callbacks[flag] = click;

--             if location[flag] == true then
--                 callback(location[flag])
--             end

--             self:Resize();
--             return {
--                 Set = function(self, b)
--                     location[flag] = b;
--                     callback(location[flag])
--                     check:FindFirstChild(name).Checkmark.Text = location[flag] and utf8.char(10003) or "";
--                 end
--             }
--         end
        
--         function types:Button(name, callback)
--             callback = callback or function() end;
            
--             local check = library:Create('Frame', {
--                 BackgroundTransparency = 1;
--                 Size = UDim2.new(1, 0, 0, 25);
--                 LayoutOrder = self:GetOrder();
--                 library:Create('TextButton', {
--                     Name = name;
--                     Text = name;
--                     BackgroundColor3 = library.options.btncolor;
--                     BorderColor3 = library.options.bordercolor;
--                     TextStrokeTransparency = library.options.textstroke;
--                     TextStrokeColor3 = library.options.strokecolor;
--                     TextColor3 = library.options.textcolor;
--                     Position = UDim2.new(0, 5, 0, 5);
--                     Size     = UDim2.new(1, -10, 0, 20);
--                     Font = library.options.font;
--                     TextSize = library.options.fontsize;
--                 });
--                 Parent = self.container;
--             });
            
--             check:FindFirstChild(name).MouseButton1Click:connect(callback)
--             self:Resize();

--             return {
--                 Fire = function()
--                     callback();
--                 end
--             }
--         end
        
--         function types:Box(name, options, callback) --type, default, data, location, flag)
--             local type   = options.type or "";
--             local default = options.default or "";
--             local data = options.data
--             local location = options.location or self.flags;
--             local flag     = options.flag or "";
--             local callback = callback or function() end;
--             local min      = options.min or 0;
--             local max      = options.max or 9e9;

--             if type == 'number' and (not tonumber(default)) then
--                 location[flag] = default;
--             else
--                 location[flag] = "";
--                 default = "";
--             end

--             local check = library:Create('Frame', {
--                 BackgroundTransparency = 1;
--                 Size = UDim2.new(1, 0, 0, 25);
--                 LayoutOrder = self:GetOrder();
--                 library:Create('TextLabel', {
--                     Name = name;
--                     Text = "\r" .. name;
--                     BackgroundTransparency = 1;
--                     TextColor3 = library.options.textcolor;
--                     TextStrokeTransparency = library.options.textstroke;
--                     TextStrokeColor3 = library.options.strokecolor;
--                     Position = UDim2.new(0, 5, 0, 0);
--                     Size     = UDim2.new(1, -5, 1, 0);
--                     TextXAlignment = Enum.TextXAlignment.Left;
--                     Font = library.options.font;
--                     TextSize = library.options.fontsize;
--                     library:Create('TextBox', {
--                         TextStrokeTransparency = library.options.textstroke;
--                         TextStrokeColor3 = library.options.strokecolor;
--                         Text = tostring(default);
--                         Font = library.options.font;
--                         TextSize = library.options.fontsize;
--                         Name = 'Box';
--                         Size = UDim2.new(0, 60, 0, 20);
--                         Position = UDim2.new(1, -65, 0, 3);
--                         TextColor3 = library.options.textcolor;
--                         BackgroundColor3 = library.options.boxcolor;
--                         BorderColor3 = library.options.bordercolor;
--                         PlaceholderColor3 = library.options.placeholdercolor;
--                     })
--                 });
--                 Parent = self.container;
--             });
        
--             local box = check:FindFirstChild(name):FindFirstChild('Box');
--             box.FocusLost:connect(function(e)
--                 local old = location[flag];
--                 if type == "number" then
--                     local num = tonumber(box.Text)
--                     if (not num) then
--                         box.Text = tonumber(location[flag])
--                     else
--                         location[flag] = math.clamp(num, min, max)
--                         box.Text = tonumber(location[flag])
--                     end
--                 else
--                     location[flag] = tostring(box.Text)
--                 end

--                 callback(location[flag], old, e)
--             end)
            
--             if type == 'number' then
--                 box:GetPropertyChangedSignal('Text'):connect(function()
--                     box.Text = string.gsub(box.Text, "[%a+]", "");
--                 end)
--             end
            
--             self:Resize();
--             return box
--         end
        
--         function types:Bind(name, options, callback)
--             local location     = options.location or self.flags;
--             local keyboardOnly = options.kbonly or false
--             local flag         = options.flag or "";
--             local callback     = callback or function() end;
--             local default      = options.default;

--             local passed = true;
--             if keyboardOnly and (tostring(default):find('MouseButton')) then 
--                 passed = false 
--             end
--             if passed then 
--                location[flag] = default 
--             end
           
--             local banned = {
--                 Return = true;
--                 Space = true;
--                 Tab = true;
--                 Unknown = true;
--             }
            
--             local shortNames = {
--                 RightControl = 'RightCtrl';
--                 LeftControl = 'LeftCtrl';
--                 LeftShift = 'LShift';
--                 RightShift = 'RShift';
--                 MouseButton1 = "Mouse1";
--                 MouseButton2 = "Mouse2";
--             }
            
--             local allowed = {
--                 MouseButton1 = true;
--                 MouseButton2 = true;
--             }      

--             local nm = (default and (shortNames[default.Name] or default.Name) or "None");
--             local check = library:Create('Frame', {
--                 BackgroundTransparency = 1;
--                 Size = UDim2.new(1, 0, 0, 30);
--                 LayoutOrder = self:GetOrder();
--                 library:Create('TextLabel', {
--                     Name = name;
--                     Text = "\r" .. name;
--                     BackgroundTransparency = 1;
--                     TextColor3 = library.options.textcolor;
--                     Position = UDim2.new(0, 5, 0, 0);
--                     Size     = UDim2.new(1, -5, 1, 0);
--                     TextXAlignment = Enum.TextXAlignment.Left;
--                     Font = library.options.font;
--                     TextSize = library.options.fontsize;
--                     TextStrokeTransparency = library.options.textstroke;
--                     TextStrokeColor3 = library.options.strokecolor;
--                     BorderColor3     = library.options.bordercolor;
--                     BorderSizePixel  = 1;
--                     library:Create('TextButton', {
--                         Name = 'Keybind';
--                         Text = nm;
--                         TextStrokeTransparency = library.options.textstroke;
--                         TextStrokeColor3 = library.options.strokecolor;
--                         Font = library.options.font;
--                         TextSize = library.options.fontsize;
--                         Size = UDim2.new(0, 60, 0, 20);
--                         Position = UDim2.new(1, -65, 0, 5);
--                         TextColor3 = library.options.textcolor;
--                         BackgroundColor3 = library.options.bgcolor;
--                         BorderColor3     = library.options.bordercolor;
--                         BorderSizePixel  = 1;
--                     })
--                 });
--                 Parent = self.container;
--             });
             
--             local button = check:FindFirstChild(name).Keybind;
--             button.MouseButton1Click:connect(function()
--                 library.binding = true

--                 button.Text = "..."
--                 local a, b = game:GetService('UserInputService').InputBegan:wait();
--                 local name = tostring(a.KeyCode.Name);
--                 local typeName = tostring(a.UserInputType.Name);

--                 if (a.UserInputType ~= Enum.UserInputType.Keyboard and (allowed[a.UserInputType.Name]) and (not keyboardOnly)) or (a.KeyCode and (not banned[a.KeyCode.Name])) then
--                     local name = (a.UserInputType ~= Enum.UserInputType.Keyboard and a.UserInputType.Name or a.KeyCode.Name);
--                     location[flag] = (a);
--                     button.Text = shortNames[name] or name;
                    
--                 else
--                     if (location[flag]) then
--                         if (not pcall(function()
--                             return location[flag].UserInputType
--                         end)) then
--                             local name = tostring(location[flag])
--                             button.Text = shortNames[name] or name
--                         else
--                             local name = (location[flag].UserInputType ~= Enum.UserInputType.Keyboard and location[flag].UserInputType.Name or location[flag].KeyCode.Name);
--                             button.Text = shortNames[name] or name;
--                         end
--                     end
--                 end

--                 wait(0.1)  
--                 library.binding = false;
--             end)
            
--             if location[flag] then
--                 button.Text = shortNames[tostring(location[flag].Name)] or tostring(location[flag].Name)
--             end

--             library.binds[flag] = {
--                 location = location;
--                 callback = callback;
--             };

--             self:Resize();
--         end
    
--         function types:Section(name)
--             local order = self:GetOrder();
--             local determinedSize = UDim2.new(1, 0, 0, 25)
--             local determinedPos = UDim2.new(0, 0, 0, 4);
--             local secondarySize = UDim2.new(1, 0, 0, 20);
                        
--             if order == 0 then
--                 determinedSize = UDim2.new(1, 0, 0, 21)
--                 determinedPos = UDim2.new(0, 0, 0, -1);
--                 secondarySize = nil
--             end
            
--             local check = library:Create('Frame', {
--                 Name = 'Section';
--                 BackgroundTransparency = 1;
--                 Size = determinedSize;
--                 BackgroundColor3 = library.options.sectncolor;
--                 BorderSizePixel = 0;
--                 LayoutOrder = order;
--                 library:Create('TextLabel', {
--                     Name = 'section_lbl';
--                     Text = name;
--                     BackgroundTransparency = 0;
--                     BorderSizePixel = 0;
--                     BackgroundColor3 = library.options.sectncolor;
--                     TextColor3 = library.options.textcolor;
--                     Position = determinedPos;
--                     Size     = (secondarySize or UDim2.new(1, 0, 1, 0));
--                     Font = library.options.font;
--                     TextSize = library.options.fontsize;
--                     TextStrokeTransparency = library.options.textstroke;
--                     TextStrokeColor3 = library.options.strokecolor;
--                 });
--                 Parent = self.container;
--             });
        
--             self:Resize();
--         end

--         function types:Slider(name, options, callback)
--             local default = options.default or options.min;
--             local min     = options.min or 0;
--             local max      = options.max or 1;
--             local location = options.location or self.flags;
--             local precise  = options.precise  or false -- e.g 0, 1 vs 0, 0.1, 0.2, ...
--             local flag     = options.flag or "";
--             local callback = callback or function() end

--             location[flag] = default;

--             local check = library:Create('Frame', {
--                 BackgroundTransparency = 1;
--                 Size = UDim2.new(1, 0, 0, 25);
--                 LayoutOrder = self:GetOrder();
--                 library:Create('TextLabel', {
--                     Name = name;
--                     TextStrokeTransparency = library.options.textstroke;
--                     TextStrokeColor3 = library.options.strokecolor;
--                     Text = "\r" .. name;
--                     BackgroundTransparency = 1;
--                     TextColor3 = library.options.textcolor;
--                     Position = UDim2.new(0, 5, 0, 2);
--                     Size     = UDim2.new(1, -5, 1, 0);
--                     TextXAlignment = Enum.TextXAlignment.Left;
--                     Font = library.options.font;
--                     TextSize = library.options.fontsize;
--                     library:Create('Frame', {
--                         Name = 'Container';
--                         Size = UDim2.new(0, 60, 0, 20);
--                         Position = UDim2.new(1, -65, 0, 3);
--                         BackgroundTransparency = 1;
--                         --BorderColor3 = library.options.bordercolor;
--                         BorderSizePixel = 0;
--                         library:Create('TextLabel', {
--                             Name = 'ValueLabel';
--                             Text = default;
--                             BackgroundTransparency = 1;
--                             TextColor3 = library.options.textcolor;
--                             Position = UDim2.new(0, -10, 0, 0);
--                             Size     = UDim2.new(0, 1, 1, 0);
--                             TextXAlignment = Enum.TextXAlignment.Right;
--                             Font = library.options.font;
--                             TextSize = library.options.fontsize;
--                             TextStrokeTransparency = library.options.textstroke;
--                             TextStrokeColor3 = library.options.strokecolor;
--                         });
--                         library:Create('TextButton', {
--                             Name = 'Button';
--                             Size = UDim2.new(0, 5, 1, -2);
--                             Position = UDim2.new(0, 0, 0, 1);
--                             AutoButtonColor = false;
--                             Text = "";
--                             BackgroundColor3 = Color3.fromRGB(20, 20, 20);
--                             BorderSizePixel = 0;
--                             ZIndex = 2;
--                             TextStrokeTransparency = library.options.textstroke;
--                             TextStrokeColor3 = library.options.strokecolor;
--                         });
--                         library:Create('Frame', {
--                             Name = 'Line';
--                             BackgroundTransparency = 0;
--                             Position = UDim2.new(0, 0, 0.5, 0);
--                             Size     = UDim2.new(1, 0, 0, 1);
--                             BackgroundColor3 = Color3.fromRGB(255, 255, 255);
--                             BorderSizePixel = 0;
--                         });
--                     })
--                 });
--                 Parent = self.container;
--             });

--             local overlay = check:FindFirstChild(name);

--             local renderSteppedConnection;
--             local inputBeganConnection;
--             local inputEndedConnection;
--             local mouseLeaveConnection;
--             local mouseDownConnection;
--             local mouseUpConnection;

--             check:FindFirstChild(name).Container.MouseEnter:connect(function()
--                 local function update()
--                     if renderSteppedConnection then renderSteppedConnection:disconnect() end 
                    

--                     renderSteppedConnection = game:GetService('RunService').RenderStepped:connect(function()
--                         local mouse = game:GetService("UserInputService"):GetMouseLocation()
--                         local percent = (mouse.X - overlay.Container.AbsolutePosition.X) / (overlay.Container.AbsoluteSize.X)
--                         percent = math.clamp(percent, 0, 1)
--                         percent = tonumber(string.format("%.2f", percent))

--                         overlay.Container.Button.Position = UDim2.new(math.clamp(percent, 0, 0.99), 0, 0, 1)
                        
--                         local num = min + (max - min) * percent
--                         local value = (precise and num or math.floor(num))

--                         overlay.Container.ValueLabel.Text = value;
--                         callback(tonumber(value))
--                         location[flag] = tonumber(value)
--                     end)
--                 end

--                 local function disconnect()
--                     if renderSteppedConnection then renderSteppedConnection:disconnect() end
--                     if inputBeganConnection then inputBeganConnection:disconnect() end
--                     if inputEndedConnection then inputEndedConnection:disconnect() end
--                     if mouseLeaveConnection then mouseLeaveConnection:disconnect() end
--                     if mouseUpConnection then mouseUpConnection:disconnect() end
--                 end

--                 inputBeganConnection = check:FindFirstChild(name).Container.InputBegan:connect(function(input)
--                     if input.UserInputType == Enum.UserInputType.MouseButton1 then
--                         update()
--                     end
--                 end)

--                 inputEndedConnection = check:FindFirstChild(name).Container.InputEnded:connect(function(input)
--                     if input.UserInputType == Enum.UserInputType.MouseButton1 then
--                         disconnect()
--                     end
--                 end)

--                 mouseDownConnection = check:FindFirstChild(name).Container.Button.MouseButton1Down:connect(update)
--                 mouseUpConnection   = game:GetService("UserInputService").InputEnded:connect(function(a, b)
--                     if a.UserInputType == Enum.UserInputType.MouseButton1 and (mouseDownConnection.Connected) then
--                         disconnect()
--                     end
--                 end)
--             end)    

--             if default ~= min then
--                 local percent = 1 - ((max - default) / (max - min))
--                 local number  = default 

--                 number = tonumber(string.format("%.2f", number))
--                 if (not precise) then
--                     number = math.floor(number)
--                 end

--                 overlay.Container.Button.Position  = UDim2.new(math.clamp(percent, 0, 0.99), 0,  0, 1) 
--                 overlay.Container.ValueLabel.Text  = number
--             end

--             self:Resize();
--             return {
--                 Set = function(self, value)
--                     local percent = 1 - ((max - value) / (max - min))
--                     local number  = value 

--                     number = tonumber(string.format("%.2f", number))
--                     if (not precise) then
--                         number = math.floor(number)
--                     end

--                     overlay.Container.Button.Position  = UDim2.new(math.clamp(percent, 0, 0.99), 0,  0, 1) 
--                     overlay.Container.ValueLabel.Text  = number
--                     location[flag] = number
--                     callback(number)
--                 end
--             }
--         end 

--         function types:SearchBox(text, options, callback)
--             local list = options.list or {};
--             local flag = options.flag or "";
--             local location = options.location or self.flags;
--             local callback = callback or function() end;

--             local busy = false;
--             local box = library:Create('Frame', {
--                 BackgroundTransparency = 1;
--                 Size = UDim2.new(1, 0, 0, 25);
--                 LayoutOrder = self:GetOrder();
--                 library:Create('TextBox', {
--                     Text = "";
--                     PlaceholderText = text;
--                     PlaceholderColor3 = Color3.fromRGB(60, 60, 60);
--                     Font = library.options.font;
--                     TextSize = library.options.fontsize;
--                     Name = 'Box';
--                     Size = UDim2.new(1, -10, 0, 20);
--                     Position = UDim2.new(0, 5, 0, 4);
--                     TextColor3 = library.options.textcolor;
--                     BackgroundColor3 = library.options.dropcolor;
--                     BorderColor3 = library.options.bordercolor;
--                     TextStrokeTransparency = library.options.textstroke;
--                     TextStrokeColor3 = library.options.strokecolor;
--                     library:Create('ScrollingFrame', {
--                         Position = UDim2.new(0, 0, 1, 1);
--                         Name = 'Container';
--                         BackgroundColor3 = library.options.btncolor;
--                         ScrollBarThickness = 0;
--                         BorderSizePixel = 0;
--                         BorderColor3 = library.options.bordercolor;
--                         Size = UDim2.new(1, 0, 0, 0);
--                         library:Create('UIListLayout', {
--                             Name = 'ListLayout';
--                             SortOrder = Enum.SortOrder.LayoutOrder;
--                         });
--                         ZIndex = 2;
--                     });
--                 });
--                 Parent = self.container;
--             })

--             local function rebuild(text)
--                 box:FindFirstChild('Box').Container.ScrollBarThickness = 0
--                 for i, child in next, box:FindFirstChild('Box').Container:GetChildren() do
--                     if (not child:IsA('UIListLayout')) then
--                         child:Destroy();
--                     end
--                 end

--                 if #text > 0 then
--                     for i, v in next, list do
--                         if string.sub(string.lower(v), 1, string.len(text)) == string.lower(text) then
--                             local button = library:Create('TextButton', {
--                                 Text = v;
--                                 Font = library.options.font;
--                                 TextSize = library.options.fontsize;
--                                 TextColor3 = library.options.textcolor;
--                                 BorderColor3 = library.options.bordercolor;
--                                 TextStrokeTransparency = library.options.textstroke;
--                                 TextStrokeColor3 = library.options.strokecolor;
--                                 Parent = box:FindFirstChild('Box').Container;
--                                 Size = UDim2.new(1, 0, 0, 20);
--                                 LayoutOrder = i;
--                                 BackgroundColor3 = library.options.btncolor;
--                                 ZIndex = 2;
--                             })

--                             button.MouseButton1Click:connect(function()
--                                 busy = true;
--                                 box:FindFirstChild('Box').Text = button.Text;
--                                 wait();
--                                 busy = false;

--                                 location[flag] = button.Text;
--                                 callback(location[flag])

--                                 box:FindFirstChild('Box').Container.ScrollBarThickness = 0
--                                 for i, child in next, box:FindFirstChild('Box').Container:GetChildren() do
--                                     if (not child:IsA('UIListLayout')) then
--                                         child:Destroy();
--                                     end
--                                 end
--                                 box:FindFirstChild('Box').Container:TweenSize(UDim2.new(1, 0, 0, 0), 'Out', 'Quad', 0.25, true)
--                             end)
--                         end
--                     end
--                 end

--                 local c = box:FindFirstChild('Box').Container:GetChildren()
--                 local ry = (20 * (#c)) - 20

--                 local y = math.clamp((20 * (#c)) - 20, 0, 100)
--                 if ry > 100 then
--                     box:FindFirstChild('Box').Container.ScrollBarThickness = 5;
--                 end

--                 box:FindFirstChild('Box').Container:TweenSize(UDim2.new(1, 0, 0, y), 'Out', 'Quad', 0.25, true)
--                 box:FindFirstChild('Box').Container.CanvasSize = UDim2.new(1, 0, 0, (20 * (#c)) - 20)
--             end

--             box:FindFirstChild('Box'):GetPropertyChangedSignal('Text'):connect(function()
--                 if (not busy) then
--                     rebuild(box:FindFirstChild('Box').Text)
--                 end
--             end);

--             local function reload(new_list)
--                 list = new_list;
--                 rebuild("")
--             end
--             self:Resize();
--             return reload, box:FindFirstChild('Box');
--         end
        
--         function types:Dropdown(name, options, callback)
--             local location = options.location or self.flags;
--             local flag = options.flag or "";
--             local callback = callback or function() end;
--             local list = options.list or {};

--             location[flag] = list[1]
--             local check = library:Create('Frame', {
--                 BackgroundTransparency = 1;
--                 Size = UDim2.new(1, 0, 0, 25);
--                 BackgroundColor3 = Color3.fromRGB(25, 25, 25);
--                 BorderSizePixel = 0;
--                 LayoutOrder = self:GetOrder();
--                 library:Create('Frame', {
--                     Name = 'dropdown_lbl';
--                     BackgroundTransparency = 0;
--                     BackgroundColor3 = library.options.dropcolor;
--                     Position = UDim2.new(0, 5, 0, 4);
--                     BorderColor3 = library.options.bordercolor;
--                     Size     = UDim2.new(1, -10, 0, 20);
--                     library:Create('TextLabel', {
--                         Name = 'Selection';
--                         Size = UDim2.new(1, 0, 1, 0);
--                         Text = list[1];
--                         TextColor3 = library.options.textcolor;
--                         BackgroundTransparency = 1;
--                         Font = library.options.font;
--                         TextSize = library.options.fontsize;
--                         TextStrokeTransparency = library.options.textstroke;
--                         TextStrokeColor3 = library.options.strokecolor;
--                     });
--                     library:Create("TextButton", {
--                         Name = 'drop';
--                         BackgroundTransparency = 1;
--                         Size = UDim2.new(0, 20, 1, 0);
--                         Position = UDim2.new(1, -25, 0, 0);
--                         Text = 'v';
--                         TextColor3 = library.options.textcolor;
--                         Font = library.options.font;
--                         TextSize = library.options.fontsize;
--                         TextStrokeTransparency = library.options.textstroke;
--                         TextStrokeColor3 = library.options.strokecolor;
--                     })
--                 });
--                 Parent = self.container;
--             });
            
--             local button = check:FindFirstChild('dropdown_lbl').drop;
--             local input;
            
--             button.MouseButton1Click:connect(function()
--                 if (input and input.Connected) then
--                     return
--                 end 
                
--                 check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').TextColor3 = Color3.fromRGB(60, 60, 60);
--                 check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').Text = name;
--                 local c = 0;
--                 for i, v in next, list do
--                     c = c + 20;
--                 end

--                 local size = UDim2.new(1, 0, 0, c)

--                 local clampedSize;
--                 local scrollSize = 0;
--                 if size.Y.Offset > 100 then
--                     clampedSize = UDim2.new(1, 0, 0, 100)
--                     scrollSize = 5;
--                 end
                
--                 local goSize = (clampedSize ~= nil and clampedSize) or size;    
--                 local container = library:Create('ScrollingFrame', {
--                     TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
--                     BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
--                     Name = 'DropContainer';
--                     Parent = check:FindFirstChild('dropdown_lbl');
--                     Size = UDim2.new(1, 0, 0, 0);
--                     BackgroundColor3 = library.options.bgcolor;
--                     BorderColor3 = library.options.bordercolor;
--                     Position = UDim2.new(0, 0, 1, 0);
--                     ScrollBarThickness = scrollSize;
--                     CanvasSize = UDim2.new(0, 0, 0, size.Y.Offset);
--                     ZIndex = 5;
--                     ClipsDescendants = true;
--                     library:Create('UIListLayout', {
--                         Name = 'List';
--                         SortOrder = Enum.SortOrder.LayoutOrder
--                     })
--                 })

--                 for i, v in next, list do
--                     local btn = library:Create('TextButton', {
--                         Size = UDim2.new(1, 0, 0, 20);
--                         BackgroundColor3 = library.options.btncolor;
--                         BorderColor3 = library.options.bordercolor;
--                         Text = v;
--                         Font = library.options.font;
--                         TextSize = library.options.fontsize;
--                         LayoutOrder = i;
--                         Parent = container;
--                         ZIndex = 5;
--                         TextColor3 = library.options.textcolor;
--                         TextStrokeTransparency = library.options.textstroke;
--                         TextStrokeColor3 = library.options.strokecolor;
--                     })
                    
--                     btn.MouseButton1Click:connect(function()
--                         check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').TextColor3 = library.options.textcolor
--                         check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').Text = btn.Text;

--                         location[flag] = tostring(btn.Text);
--                         callback(location[flag])

--                         game:GetService('Debris'):AddItem(container, 0)
--                         input:disconnect();
--                     end)
--                 end
                
--                 container:TweenSize(goSize, 'Out', 'Quad', 0.15, true)
                
--                 local function isInGui(frame)
--                     local mloc = game:GetService('UserInputService'):GetMouseLocation();
--                     local mouse = Vector2.new(mloc.X, mloc.Y - 36);
                    
--                     local x1, x2 = frame.AbsolutePosition.X, frame.AbsolutePosition.X + frame.AbsoluteSize.X;
--                     local y1, y2 = frame.AbsolutePosition.Y, frame.AbsolutePosition.Y + frame.AbsoluteSize.Y;
                
--                     return (mouse.X >= x1 and mouse.X <= x2) and (mouse.Y >= y1 and mouse.Y <= y2)
--                 end
                
--                 input = game:GetService('UserInputService').InputBegan:connect(function(a)
--                     if a.UserInputType == Enum.UserInputType.MouseButton1 and (not isInGui(container)) then
--                         check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').TextColor3 = library.options.textcolor
--                         check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').Text       = location[flag];

--                         container:TweenSize(UDim2.new(1, 0, 0, 0), 'In', 'Quad', 0.15, true)
--                         wait(0.15)

--                         game:GetService('Debris'):AddItem(container, 0)
--                         input:disconnect();
--                     end
--                 end)
--             end)
            
--             self:Resize();
--             local function reload(self, array)
--                 options = array;
--                 location[flag] = array[1];
--                 pcall(function()
--                     input:disconnect()
--                 end)
--                 check:WaitForChild('dropdown_lbl').Selection.Text = location[flag]
--                 check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').TextColor3 = library.options.textcolor
--                 game:GetService('Debris'):AddItem(container, 0)
--             end

--             return {
--                 Refresh = reload;
--             }
--         end
--     end
    
--     function library:Create(class, data)
--         local obj = Instance.new(class);
--         for i, v in next, data do
--             if i ~= 'Parent' then
                
--                 if typeof(v) == "Instance" then
--                     v.Parent = obj;
--                 else
--                     obj[i] = v
--                 end
--             end
--         end
        
--         obj.Parent = data.Parent;
--         return obj
--     end
    
--     function library:CreateWindow(name, options)
--         if (not library.container) then
--             library.container = self:Create("ScreenGui", {
--                 self:Create('Frame', {
--                     Name = 'Container';
--                     Size = UDim2.new(1, -30, 1, 0);
--                     Position = UDim2.new(0, 20, 0, 20);
--                     BackgroundTransparency = 1;
--                     Active = false;
--                 });
--                 Parent = game:GetService("CoreGui");
--             }):FindFirstChild('Container');
--         end
        
--         if (not library.options) then
--             library.options = setmetatable(options or {}, {__index = defaults})
--         end
        
--         local window = types.window(name, library.options);
--         dragger.new(window.object);
--         return window
--     end
    
--     default = {
--         topcolor       = Color3.fromRGB(30, 30, 30);
--         titlecolor     = Color3.fromRGB(255, 255, 255);
        
--         underlinecolor = Color3.fromRGB(0, 255, 140);
--         bgcolor        = Color3.fromRGB(35, 35, 35);
--         boxcolor       = Color3.fromRGB(35, 35, 35);
--         btncolor       = Color3.fromRGB(25, 25, 25);
--         dropcolor      = Color3.fromRGB(25, 25, 25);
--         sectncolor     = Color3.fromRGB(25, 25, 25);
--         bordercolor    = Color3.fromRGB(60, 60, 60);

--         font           = Enum.Font.SourceSans;
--         titlefont      = Enum.Font.Code;

--         fontsize       = 17;
--         titlesize      = 18;

--         textstroke     = 1;
--         titlestroke    = 1;

--         strokecolor    = Color3.fromRGB(0, 0, 0);

--         textcolor      = Color3.fromRGB(255, 255, 255);
--         titletextcolor = Color3.fromRGB(255, 255, 255);

--         placeholdercolor = Color3.fromRGB(255, 255, 255);
--         titlestrokecolor = Color3.fromRGB(0, 0, 0);
--     }

--     library.options = setmetatable({}, {__index = default})

--     spawn(function()
--         while true do
--             for i=0, 1, 1 / 300 do              
--                 for _, obj in next, library.rainbowtable do
--                     obj.BackgroundColor3 = Color3.fromHSV(i, 1, 1);
--                 end
--                 wait()
--             end;
--         end
--     end)

--     local function isreallypressed(bind, inp)
--         local key = bind
--         if typeof(key) == "Instance" then
--             if key.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == key.KeyCode then
--                 return true;
--             elseif tostring(key.UserInputType):find('MouseButton') and inp.UserInputType == key.UserInputType then
--                 return true
--             end
--         end
--         if tostring(key):find'MouseButton1' then
--             return key == inp.UserInputType
--         else
--             return key == inp.KeyCode
--         end
--     end

--     game:GetService("UserInputService").InputBegan:connect(function(input)
--         if (not library.binding) then
--             for idx, binds in next, library.binds do
--                 local real_binding = binds.location[idx];
--                 if real_binding and isreallypressed(real_binding, input) then
--                     binds.callback()
--                 end
--             end
--         end
--     end)
-- end

-- return library

-- ChronixUI Lib
-- 一个现代化、支持手机/电脑的UI库
-- 适用于 ChronixHub V2

local ChronixUI = {}

-- 服务
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- 检测设备类型
local isMobile = UserInputService.TouchEnabled
local rowHeight = isMobile and 45 or 32  -- 手机端更高的点击区域

-- 默认主题（ChronixHub风格 - 墨蓝色系）
local defaultTheme = {
    -- 颜色
    MainBg = Color3.fromRGB(30, 30, 46),      -- 主背景色（墨蓝色）
    TitleBg = Color3.fromRGB(20, 20, 36),     -- 标题栏背景色（深墨蓝）
    ContentBg = Color3.fromRGB(40, 40, 56),   -- 内容区域背景色（中墨蓝）
    ButtonBg = Color3.fromRGB(50, 50, 70),    -- 按钮背景色（浅墨蓝）
    ButtonHoverBg = Color3.fromRGB(80, 80, 110), -- 按钮悬停背景色
    AccentColor = Color3.fromRGB(100, 100, 170), -- 强调色（浅墨蓝紫）
    TextColor = Color3.fromRGB(255, 255, 255),    -- 文字颜色（白色）
    ToggleOnBg = Color3.fromRGB(0, 200, 100),     -- 开关开启背景色（绿色）
    ToggleOffBg = Color3.fromRGB(80, 80, 100),    -- 开关关闭背景色（灰色）
    
    -- 字体
    Font = Enum.Font.Gotham,
    TitleFont = Enum.Font.GothamBold,
    TextSize = isMobile and 16 or 14,
    TitleSize = isMobile and 18 or 16,
    
    -- 窗口
    WindowWidth = isMobile and 350 or 300,
    WindowTitleHeight = isMobile and 45 or 35,
    
    -- 动画
    TweenTime = 0.2,
}

-- 存储所有窗口和控件
local windows = {}
local bindings = {}

-- ============ 工具函数 ============

local function playClickSound()
    -- 播放点击音效（可选）
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://535716488"
        sound.Volume = 0.3
        sound.Parent = game:GetService("SoundService")
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 1)
    end)
end

-- 创建圆角
local function applyCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 5)
    corner.Parent = instance
end

-- 创建阴影效果
local function applyShadow(instance)
    local shadow = Instance.new("UIStroke")
    shadow.Color = Color3.fromRGB(0, 0, 0)
    shadow.Transparency = 0.5
    shadow.Thickness = 2
    shadow.Parent = instance
end

-- ============ 拖拽功能（支持鼠标和触摸） ============

local function makeDraggable(frame, dragHandle)
    local dragHandleFrame = dragHandle or frame
    local dragData = {
        isDragging = false,
        dragStartPos = nil,
        frameStartPos = nil
    }
    
    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragData.isDragging = true
            dragData.dragStartPos = input.Position
            dragData.frameStartPos = frame.Position
        end
    end
    
    local function onInputChanged(input)
        if not dragData.isDragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and 
           input.UserInputType ~= Enum.UserInputType.Touch then return end
        
        local delta = input.Position - dragData.dragStartPos
        frame.Position = UDim2.new(
            dragData.frameStartPos.X.Scale,
            dragData.frameStartPos.X.Offset + delta.X,
            dragData.frameStartPos.Y.Scale,
            dragData.frameStartPos.Y.Offset + delta.Y
        )
    end
    
    local function onInputEnded(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragData.isDragging = false
        end
    end
    
    dragHandleFrame.InputBegan:Connect(onInputBegan)
    UserInputService.InputChanged:Connect(onInputChanged)
    UserInputService.InputEnded:Connect(onInputEnded)
end

-- ============ 主窗口类 ============

local Window = {}
Window.__index = Window

function ChronixUI:CreateWindow(title, options)
    options = options or {}
    local theme = {}
    for k, v in pairs(defaultTheme) do
        theme[k] = options[k] or v
    end
    
    -- 创建ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ChronixUI"
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui
    
    -- 主窗口Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, theme.WindowWidth, 0, 0)
    mainFrame.Position = UDim2.new(0.5, -theme.WindowWidth/2, 0.5, -200)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = theme.MainBg
    mainFrame.BackgroundTransparency = 0
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = gui
    applyCorner(mainFrame, 8)
    applyShadow(mainFrame)
    
    -- 标题栏
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, theme.WindowTitleHeight)
    titleBar.BackgroundColor3 = theme.TitleBg
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    applyCorner(titleBar, 8)
    
    -- 标题文字
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.Text = title
    titleLabel.TextColor3 = theme.TextColor
    titleLabel.TextSize = theme.TitleSize
    titleLabel.Font = theme.TitleFont
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = titleBar
    
    -- 关闭按钮
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, theme.WindowTitleHeight - 10, 0, theme.WindowTitleHeight - 10)
    closeBtn.Position = UDim2.new(1, -theme.WindowTitleHeight + 5, 0, 5)
    closeBtn.BackgroundColor3 = theme.ButtonBg
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = theme.TextColor
    closeBtn.TextSize = theme.TextSize
    closeBtn.Font = theme.Font
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar
    applyCorner(closeBtn, 5)
    
    closeBtn.MouseButton1Click:Connect(function()
        playClickSound()
        gui:Destroy()
    end)
    
    -- 内容容器（使用Canvas + UIListLayout自动布局）
    local contentContainer = Instance.new("ScrollingFrame")
    contentContainer.Size = UDim2.new(1, 0, 1, -theme.WindowTitleHeight)
    contentContainer.Position = UDim2.new(0, 0, 0, theme.WindowTitleHeight)
    contentContainer.BackgroundColor3 = theme.ContentBg
    contentContainer.BorderSizePixel = 0
    contentContainer.ScrollBarThickness = isMobile and 0 or 5
    contentContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentContainer.Parent = mainFrame
    
    local canvasLayout = Instance.new("UIListLayout")
    canvasLayout.Padding = UDim.new(0, 5)
    canvasLayout.SortOrder = Enum.SortOrder.LayoutOrder
    canvasLayout.Parent = contentContainer
    
    -- 更新Canvas大小
    local function updateCanvasSize()
        task.wait()
        contentContainer.CanvasSize = UDim2.new(0, 0, 0, canvasLayout.AbsoluteContentSize.Y + 10)
    end
    canvasLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
    
    -- 窗口数据
    local windowObj = {
        gui = gui,
        mainFrame = mainFrame,
        contentContainer = contentContainer,
        canvasLayout = canvasLayout,
        theme = theme,
        updateCanvas = updateCanvasSize,
        flags = {},
        sections = {}
    }
    
    makeDraggable(mainFrame, titleBar)
    
    setmetatable(windowObj, Window)
    table.insert(windows, windowObj)
    
    -- 初始调整窗口大小
    task.wait()
    updateCanvasSize()
    mainFrame.Size = UDim2.new(0, theme.WindowWidth, 0, math.min(canvasLayout.AbsoluteContentSize.Y + theme.WindowTitleHeight + 15, isMobile and 500 or 600))
    
    return windowObj
end

-- ============ 控件类 ============

-- 分区标题
function Window:Section(title)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -20, 0, 30)
    section.Position = UDim2.new(0, 10, 0, 0)
    section.BackgroundColor3 = self.theme.ButtonBg
    section.BorderSizePixel = 0
    section.LayoutOrder = self.canvasLayout.AbsoluteContentSize.Y
    section.Parent = self.contentContainer
    applyCorner(section, 5)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Text = title
    label.TextColor3 = self.theme.AccentColor
    label.TextSize = self.theme.TextSize
    label.Font = self.theme.TitleFont
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.BackgroundTransparency = 1
    label.Parent = section
    
    self.updateCanvas()
    return section
end

-- 按钮
function Window:Button(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, rowHeight)
    btn.Position = UDim2.new(0, 10, 0, 0)
    btn.Text = text
    btn.TextColor3 = self.theme.TextColor
    btn.TextSize = self.theme.TextSize
    btn.Font = self.theme.Font
    btn.BackgroundColor3 = self.theme.ButtonBg
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.LayoutOrder = self.canvasLayout.AbsoluteContentSize.Y
    btn.Parent = self.contentContainer
    applyCorner(btn, 5)
    
    -- 悬停效果
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = self.theme.ButtonHoverBg}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = self.theme.ButtonBg}):Play()
    end)
    
    btn.MouseButton1Click:Connect(function()
        playClickSound()
        if callback then callback() end
    end)
    
    self.updateCanvas()
    return btn
end

-- 开关（Toggle）
function Window:Toggle(labelText, default, callback)
    local toggled = default or false
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, rowHeight)
    container.Position = UDim2.new(0, 10, 0, 0)
    container.BackgroundTransparency = 1
    container.LayoutOrder = self.canvasLayout.AbsoluteContentSize.Y
    container.Parent = self.contentContainer
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.Text = labelText
    label.TextColor3 = self.theme.TextColor
    label.TextSize = self.theme.TextSize
    label.Font = self.theme.Font
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = container
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 50, 0, rowHeight - 8)
    toggleBtn.Position = UDim2.new(1, -55, 0, 4)
    toggleBtn.Text = toggled and "ON" or "OFF"
    toggleBtn.TextColor3 = self.theme.TextColor
    toggleBtn.TextSize = self.theme.TextSize - 2
    toggleBtn.Font = self.theme.Font
    toggleBtn.BackgroundColor3 = toggled and self.theme.ToggleOnBg or self.theme.ToggleOffBg
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = container
    applyCorner(toggleBtn, 15)
    
    local function updateToggle()
        toggled = not toggled
        toggleBtn.Text = toggled and "ON" or "OFF"
        toggleBtn.BackgroundColor3 = toggled and self.theme.ToggleOnBg or self.theme.ToggleOffBg
        if callback then callback(toggled) end
    end
    
    toggleBtn.MouseButton1Click:Connect(function()
        playClickSound()
        updateToggle()
    end)
    
    self.updateCanvas()
    
    return {
        set = function(val)
            toggled = val
            toggleBtn.Text = toggled and "ON" or "OFF"
            toggleBtn.BackgroundColor3 = toggled and self.theme.ToggleOnBg or self.theme.ToggleOffBg
        end,
        get = function() return toggled end
    }
end

-- 滑块（Slider）
function Window:Slider(labelText, min, max, defaultVal, callback)
    local value = defaultVal or min
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, rowHeight + 10)
    container.Position = UDim2.new(0, 10, 0, 0)
    container.BackgroundTransparency = 1
    container.LayoutOrder = self.canvasLayout.AbsoluteContentSize.Y
    container.Parent = self.contentContainer
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 0, 20)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.Text = labelText
    label.TextColor3 = self.theme.TextColor
    label.TextSize = self.theme.TextSize
    label.Font = self.theme.Font
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = container
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 50, 0, 20)
    valueLabel.Position = UDim2.new(1, -55, 0, 0)
    valueLabel.Text = tostring(value)
    valueLabel.TextColor3 = self.theme.AccentColor
    valueLabel.TextSize = self.theme.TextSize
    valueLabel.Font = self.theme.Font
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.BackgroundTransparency = 1
    valueLabel.Parent = container
    
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -10, 0, 4)
    track.Position = UDim2.new(0, 5, 0, 28)
    track.BackgroundColor3 = self.theme.ToggleOffBg
    track.BorderSizePixel = 0
    track.Parent = container
    applyCorner(track, 2)
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = self.theme.AccentColor
    fill.BorderSizePixel = 0
    fill.Parent = track
    applyCorner(fill, 2)
    
    local thumb = Instance.new("TextButton")
    thumb.Size = UDim2.new(0, 18, 0, 18)
    thumb.Position = UDim2.new((value - min) / (max - min), -9, 0, -7)
    thumb.BackgroundColor3 = self.theme.TextColor
    thumb.Text = ""
    thumb.BorderSizePixel = 0
    thumb.Parent = container
    applyCorner(thumb, 9)
    
    local isDragging = false
    
    local function updateSlider(inputPos)
        local trackPos = track.AbsolutePosition.X
        local trackWidth = track.AbsoluteSize.X
        local percent = math.clamp((inputPos.X - trackPos) / trackWidth, 0, 1)
        local newValue = min + (max - min) * percent
        value = math.floor(newValue)
        
        fill.Size = UDim2.new(percent, 0, 1, 0)
        thumb.Position = UDim2.new(percent, -9, 0, -7)
        valueLabel.Text = tostring(value)
        
        if callback then callback(value) end
    end
    
    thumb.MouseButton1Down:Connect(function(input)
        isDragging = true
        updateSlider(input)
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
    
    self.updateCanvas()
    
    return {
        set = function(val)
            value = math.clamp(val, min, max)
            local percent = (value - min) / (max - min)
            fill.Size = UDim2.new(percent, 0, 1, 0)
            thumb.Position = UDim2.new(percent, -9, 0, -7)
            valueLabel.Text = tostring(value)
            if callback then callback(value) end
        end,
        get = function() return value end
    }
end

-- 文本框输入
function Window:InputBox(labelText, placeholder, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, rowHeight)
    container.Position = UDim2.new(0, 10, 0, 0)
    container.BackgroundTransparency = 1
    container.LayoutOrder = self.canvasLayout.AbsoluteContentSize.Y
    container.Parent = self.contentContainer
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.Text = labelText
    label.TextColor3 = self.theme.TextColor
    label.TextSize = self.theme.TextSize
    label.Font = self.theme.Font
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = container
    
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0.6, -15, 1, -10)
    input.Position = UDim2.new(0.4, 5, 0, 5)
    input.PlaceholderText = placeholder or ""
    input.Text = ""
    input.TextColor3 = self.theme.TextColor
    input.TextSize = self.theme.TextSize
    input.Font = self.theme.Font
    input.BackgroundColor3 = self.theme.ButtonBg
    input.BorderSizePixel = 0
    input.Parent = container
    applyCorner(input, 5)
    
    input.FocusLost:Connect(function(enterPressed)
        if callback and enterPressed then
            callback(input.Text)
        end
    end)
    
    self.updateCanvas()
    return input
end

-- 下拉菜单
function Window:Dropdown(labelText, options, callback)
    local selected = options[1]
    local isOpen = false
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, rowHeight)
    container.Position = UDim2.new(0, 10, 0, 0)
    container.BackgroundTransparency = 1
    container.LayoutOrder = self.canvasLayout.AbsoluteContentSize.Y
    container.Parent = self.contentContainer
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.Text = labelText
    label.TextColor3 = self.theme.TextColor
    label.TextSize = self.theme.TextSize
    label.Font = self.theme.Font
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = container
    
    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Size = UDim2.new(0.6, -15, 1, -10)
    dropdownBtn.Position = UDim2.new(0.4, 5, 0, 5)
    dropdownBtn.Text = selected
    dropdownBtn.TextColor3 = self.theme.TextColor
    dropdownBtn.TextSize = self.theme.TextSize
    dropdownBtn.Font = self.theme.Font
    dropdownBtn.BackgroundColor3 = self.theme.ButtonBg
    dropdownBtn.BorderSizePixel = 0
    dropdownBtn.Parent = container
    applyCorner(dropdownBtn, 5)
    
    local dropdownList = Instance.new("ScrollingFrame")
    dropdownList.Size = UDim2.new(0.6, -15, 0, 0)
    dropdownList.Position = UDim2.new(0.4, 5, 0, rowHeight)
    dropdownList.BackgroundColor3 = self.theme.MainBg
    dropdownList.BorderSizePixel = 0
    dropdownList.ScrollBarThickness = isMobile and 0 or 3
    dropdownList.Visible = false
    dropdownList.Parent = container
    applyCorner(dropdownList, 5)
    applyShadow(dropdownList)
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = dropdownList
    
    local function rebuildList()
        for _, child in ipairs(dropdownList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        local totalHeight = 0
        for i, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, 0, 0, rowHeight - 5)
            optBtn.Text = opt
            optBtn.TextColor3 = self.theme.TextColor
            optBtn.TextSize = self.theme.TextSize - 2
            optBtn.Font = self.theme.Font
            optBtn.BackgroundColor3 = self.theme.ButtonBg
            optBtn.BorderSizePixel = 0
            optBtn.Parent = dropdownList
            applyCorner(optBtn, 3)
            
            optBtn.MouseButton1Click:Connect(function()
                playClickSound()
                selected = opt
                dropdownBtn.Text = selected
                dropdownList.Visible = false
                isOpen = false
                if callback then callback(selected) end
            end)
            
            totalHeight = totalHeight + rowHeight - 5 + 2
        end
        
        local maxHeight = math.min(totalHeight, isMobile and 200 or 150)
        dropdownList.Size = UDim2.new(0.6, -15, 0, maxHeight)
        dropdownList.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    end
    
    dropdownBtn.MouseButton1Click:Connect(function()
        playClickSound()
        isOpen = not isOpen
        if isOpen then
            rebuildList()
        end
        dropdownList.Visible = isOpen
    end)
    
    -- 点击其他地方关闭下拉菜单
    UserInputService.InputBegan:Connect(function(input)
        if isOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            local absPos = dropdownList.AbsolutePosition
            local absSize = dropdownList.AbsoluteSize
            if mousePos.X < absPos.X or mousePos.X > absPos.X + absSize.X or
               mousePos.Y < absPos.Y or mousePos.Y > absPos.Y + absSize.Y then
                dropdownList.Visible = false
                isOpen = false
            end
        end
    end)
    
    self.updateCanvas()
    
    return {
        set = function(val)
            selected = val
            dropdownBtn.Text = selected
        end,
        get = function() return selected end
    }
end

-- 标签
function Window:Label(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 25)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Text = text
    label.TextColor3 = self.theme.TextColor
    label.TextSize = self.theme.TextSize - 2
    label.Font = self.theme.Font
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.BackgroundTransparency = 1
    label.LayoutOrder = self.canvasLayout.AbsoluteContentSize.Y
    label.Parent = self.contentContainer
    
    self.updateCanvas()
    return label
end

-- 通知队列管理
local activeNotifications = {}

function ChronixUI:Notify(title, message, duration)
    duration = duration or 3
    
    -- 计算新通知的Y位置（基于已有通知数量）
    local yOffset = 0.1  -- 起始位置（屏幕高度的10%）
    local spacing = 0.12 -- 每个通知之间的间距（屏幕高度的12%）
    
    -- 根据已有通知计算位置
    for i, notif in ipairs(activeNotifications) do
        yOffset = yOffset + spacing
    end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "ChronixNotification"
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, isMobile and 300 or 250, 0, isMobile and 80 or 70)
    frame.Position = UDim2.new(1, 20, yOffset, 0)
    frame.BackgroundColor3 = defaultTheme.MainBg
    frame.BorderSizePixel = 0
    frame.Parent = gui
    applyCorner(frame, 8)
    applyShadow(frame)
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 25)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.Text = title
    titleLabel.TextColor3 = defaultTheme.AccentColor
    titleLabel.TextSize = defaultTheme.TextSize
    titleLabel.Font = defaultTheme.TitleFont
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = frame
    
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -20, 0, 35)
    msgLabel.Position = UDim2.new(0, 10, 0, 30)
    msgLabel.Text = message
    msgLabel.TextColor3 = defaultTheme.TextColor
    msgLabel.TextSize = defaultTheme.TextSize - 2
    msgLabel.Font = defaultTheme.Font
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    msgLabel.BackgroundTransparency = 1
    msgLabel.Parent = frame
    
    -- 记录当前通知到队列
    local notificationData = {gui = gui, frame = frame, yOffset = yOffset}
    table.insert(activeNotifications, notificationData)
    
    -- 滑入动画
    local inTween = TweenService:Create(frame, TweenInfo.new(0.3), {
        Position = UDim2.new(1, -frame.AbsoluteSize.X - 20, yOffset, 0)
    })
    inTween:Play()
    
    -- 延迟后滑出并清理
    task.wait(duration)
    
    local outTween = TweenService:Create(frame, TweenInfo.new(0.3), {
        Position = UDim2.new(1, 20, yOffset, 0)
    })
    outTween:Play()
    outTween.Completed:Connect(function()
        gui:Destroy()
        -- 从队列中移除自己
        for i, data in ipairs(activeNotifications) do
            if data == notificationData then
                table.remove(activeNotifications, i)
                break
            end
        end
        -- 更新剩余通知的位置（向上移动）
        for i, data in ipairs(activeNotifications) do
            local newY = 0.1 + (i - 1) * 0.12
            TweenService:Create(data.frame, TweenInfo.new(0.3), {
                Position = UDim2.new(1, -data.frame.AbsoluteSize.X - 20, newY, 0)
            }):Play()
        end
    end)
end

-- 卸载所有窗口
function ChronixUI:Unload()
    for _, window in ipairs(windows) do
        if window.gui then
            window.gui:Destroy()
        end
    end
    windows = {}
    bindings = {}
end

return ChronixUI