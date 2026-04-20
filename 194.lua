local UserInputService = game:GetService('UserInputService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local http_service = game:GetService('HttpService')
local Lighting = game:GetService('Lighting')
local RunService = game:GetService('RunService')
local coregui = game:GetService('CoreGui')
local TweenService = game:GetService('TweenService')
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer 
local Mouse = LocalPlayer:GetMouse()

-- // library init

local utility = {}
getgenv().library = {
    accent = Color3.fromRGB(136, 180, 57),
    directory = 'gamesense',
    folders = {
        '/configs',
    },
    flags = {},
    config_flags = {},
    connections = {},   
    notifications = {},
    playerlist_data = {
        players = {},
        player = {}, 
    },
    colorpicker_open = false; 
    gui;
}
local flags = library.flags
makefolder(library.directory)
makefolder(library.directory..'/configs')

library.__index = library

for _, path in next, library.folders do 
    makefolder(library.directory .. path)
end

local config_flags = library.config_flags

function utility:Tween(...) TweenService:Create(...):Play() end

function library:close_current_element(cfg) 
	local path = library.current_element_open

	if path then
		path.set_visible(false)
		path.open = false 
	end
end 

function library:resizify(frame) 
	local Frame = Instance.new('TextButton')
	Frame.Position = UDim2.new(1, -10, 1, -10)
	Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Frame.Size = UDim2.new(0, 10, 0, 10)
	Frame.BorderSizePixel = 0
	Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Frame.Parent = frame
	Frame.BackgroundTransparency = 1 
	Frame.Text = ''

	local resizing = false 
	local start_size 
	local start 
	local og_size = frame.Size  

	Frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = true
			start = input.Position
			start_size = frame.Size
		end
	end)

	Frame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = false
		end
	end)

	library:connection(UserInputService.InputChanged, function(input, game_event) 
		if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
			local viewport_x = Camera.ViewportSize.X
			local viewport_y = Camera.ViewportSize.Y

			local current_size = UDim2.new(
				start_size.X.Scale,
				math.clamp(
					start_size.X.Offset + (input.Position.X - start.X),
					og_size.X.Offset,
					viewport_x
				),
				start_size.Y.Scale,
				math.clamp(
					start_size.Y.Offset + (input.Position.Y - start.Y),
					og_size.Y.Offset,
					viewport_y
				)
			)
			frame.Size = current_size
		end
	end)
end

function library:mouse_in_frame(uiobject)
	local y_cond = uiobject.AbsolutePosition.Y <= Mouse.Y and Mouse.Y <= uiobject.AbsolutePosition.Y + uiobject.AbsoluteSize.Y
	local x_cond = uiobject.AbsolutePosition.X <= Mouse.X and Mouse.X <= uiobject.AbsolutePosition.X + uiobject.AbsoluteSize.X

	return (y_cond and x_cond)
end

library.lerp = function(start, finish, t)
	t = t or 1 / 8

	return start * (1 - t) + finish * t
end

function library:draggify(frame)
	local dragging = false 
	local start_size = frame.Position
	local start 

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			start = input.Position
			start_size = frame.Position
		end
	end)

	frame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	library:connection(UserInputService.InputChanged, function(input, game_event) 
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local viewport_x = Camera.ViewportSize.X
			local viewport_y = Camera.ViewportSize.Y

			local current_position = UDim2.new(
				0,
				math.clamp(
					start_size.X.Offset + (input.Position.X - start.X),
					0,
					viewport_x - frame.Size.X.Offset
				),
				0,
				math.clamp(
					start_size.Y.Offset + (input.Position.Y - start.Y),
					0,
					viewport_y - frame.Size.Y.Offset
				)
			)

			frame.Position = current_position
		end
	end)
end 

function library:convert(str)
	local values = {}

	for value in string.gmatch(str, '[^,]+') do
		table.insert(values, tonumber(value))
	end
	
	if #values == 4 then              
		return unpack(values)
	else 
		return
	end
end

function library:convert_enum(enum)
	local enum_parts = {}

	for part in string.gmatch(enum, '[%w_]+') do
		table.insert(enum_parts, part)
	end
	
	local enum_table = Enum
	for i = 2, #enum_parts do
		local enum_item = enum_table[enum_parts[i]]

		enum_table = enum_item
	end

	return enum_table
end

local config_holder;
function library:update_config_list() 
	if not config_holder then 
		return 
	end
	
	local list = {}
	
	for idx, file in listfiles(library.directory .. '/configs') do
		local name = file:gsub(library.directory .. '/configs\\', ''):gsub('.cfg', ''):gsub(library.directory .. '\\configs\\', '')
		list[#list + 1] = name
	end
	

	config_holder.refresh_options(list)
	
	return list
end 
local function tableToString(tbl)
	local str = "{"

	for i,v in pairs(tbl) do
		str = str .. "\"" .. tostring(v) .. "\";"
	end

	str = str .. "}"
	return str
end
function library:get_config()

	local Config = {}
    
	for i, v in pairs(library.flags) do
		if type(v) == "table" and v.key then
			Config[i] = {active = v.active, mode = v.mode, key = tostring(v.key)}
		elseif type(v) == "table" and v["Transparency"] and v["Color"] then
			Config[i] = {Transparency = v["Transparency"], Color = v["Color"]:ToHex()}
		else
			Config[i] = v
		end
	end 

	return http_service:JSONEncode(Config)
end

function library:load_config(config_json) 
	local config = http_service:JSONDecode(config_json)
	
	for _, v in next, config do 
		local function_set = library.config_flags[_]
		
		if _ == 'config_name_list' then 
			continue
		end

		if function_set then 
			if type(v) == 'table' and v['Transparency'] and v['Color'] then
				function_set(Color3.fromHex(v['Color']), v['Transparency'])
			elseif type(v) == 'table' and v['active'] then 
				function_set(v)
			else
				function_set(v)
			end
		end 
	end 
end 

function library:connection(signal, callback)
	local connection = signal:Connect(callback)
	
	table.insert(library.connections, connection)

	return connection 
end

function library:apply_stroke(parent) 
	local STROKE = library:create('UIStroke', {
		Parent = parent,
		Color = Color3.fromRGB(0,0,0), 
		LineJoinMode = Enum.LineJoinMode.Miter
	})
end

function library:create(instance, options)
	local ins = Instance.new(instance) 
	
	for prop, value in next, options do 
		ins[prop] = value
	end
	
	if instance == 'TextLabel' or instance == 'TextButton' or instance == 'TextBox' then
		library:apply_stroke(ins)
	end
	
	return ins 
end

function library:unload_menu() 
	if library.gui then 
		library.gui:Destroy()
	end
	
	for index, connection in next, library.connections do 
		connection:Disconnect() 
		connection = nil 
	end     

	if library.gui then 
		library.gui:Destroy()
	end 
	
	library = nil 
end 
-- Library element functions
function library:window(properties)
    local cfg = {
		size = properties.size or properties.Size or UDim2.new(0, 660, 0, 560),
        accent = properties.accent or properties.Accent or library.accent,
		selected_tab
	}
    --
    library.accent = cfg.accent
    --
	library.gui = library:create('ScreenGui', {
		Parent = coregui,
		Name = 'S',
		DisplayOrder = 9999,
        Enabled = true,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = "Global"
	})
    -- Window
		local window_border = library:create('Frame', {
			Parent = library.gui;
			Position = UDim2.new(0.5, -cfg.size.X.Offset / 2, 0.5, -cfg.size.Y.Offset / 2);
			BorderColor3 = Color3.fromRGB(12, 12, 12);
			Size = cfg.size;
			BorderSizePixel = 1;
            BorderMode = "Inset";
			BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		});
		window_border.Position = UDim2.new(0, window_border.AbsolutePosition.Y, 0, window_border.AbsolutePosition.Y)
		cfg.main_outline = window_border
        --
		library:resizify(window_border)
		library:draggify(window_border)
        --
        local window_inborder = library:create("Frame", {
            Parent = window_border;
            BackgroundColor3 = Color3.fromRGB(40, 40, 40);
            BorderSizePixel = 0;
            Position = UDim2.new(0, 1, 0, 1);
            Size = UDim2.new(1, -2, 1, -2)
        });
        --
        local window_inframe = library:create("Frame", {
            Parent = window_inborder;
            BackgroundColor3 = Color3.fromRGB(12, 12, 12);
            BorderColor3 = Color3.fromRGB(60, 60, 60);
            BorderMode = "Inset";
            BorderSizePixel = 1;
            Position = UDim2.new(0, 3, 0, 3);
            Size = UDim2.new(1, -6, 1, -6)
        });
        --
        local window_inframe_tabs = library:create("Frame", {
            BackgroundColor3 = Color3.fromRGB(12, 12, 12);
            BorderSizePixel = 0;
            Parent = window_inframe,
            Position = UDim2.new(0, 0, 0, 4),
            Size = UDim2.new(0, 74, 1, -4)
        });
        --
        library["TabsHolder"] = window_inframe_tabs
        --
        local window_inframe_pages = library:create("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Parent = window_inframe,
            Position = UDim2.new(1, 0, 0, 4),
            Size = UDim2.new(1, -73, 1, -4)
        });
        --
        local window_inframe_gradient = library:create("Frame", {
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            BorderSizePixel = 0,
            Parent = window_inframe,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, 4)
        });
        --
        local window_tabs_list = library:create("UIListLayout", {
            Padding = UDim.new(0, 4),
            Parent = window_inframe_tabs,
            FillDirection = "Vertical",
            HorizontalAlignment = "Left",
            VerticalAlignment = "Top"
        });
		--
        local window_tabs_padding = library:create("UIPadding", {
            Parent = window_inframe_tabs,
            PaddingTop = UDim.new(0, 9)
        });
        --
        local pages_border = library:create("Frame", {
            BackgroundColor3 = Color3.fromRGB(45, 45, 45),
            BorderSizePixel = 0,
            Parent = window_inframe_pages,
            Position = UDim2.new(0, 1, 0, 0),
            Size = UDim2.new(1, -1, 1, 0)
        });
        --
        local gradient_image = library:create("ImageLabel", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = window_inframe_gradient,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            Image = "rbxassetid://8508019876",
            ImageColor3 = Color3.fromRGB(255, 255, 255)
        });
        --
        local pages_inframe = library:create("Frame", {
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            BorderSizePixel = 0,
            Parent = pages_border,
            Position = UDim2.new(0, 1, 0, 0),
            Size = UDim2.new(1, -1, 1, 0)
        });
        --
        local inborder_folder = library:create("Folder", {
            Parent = pages_inframe
        });
        --
        library["PagesHolder"] = inborder_folder
        --
        local inframe_pattern = library:create("ImageLabel", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = pages_inframe,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            Image = "rbxassetid://8547666218",
            ImageColor3 = Color3.fromRGB(12, 12, 12),
            ScaleType = "Tile",
            TileSize = UDim2.new(0, 8, 0, 8)
        });
        --
        UserInputService.InputBegan:Connect(function(key)
			if key.KeyCode == Enum.KeyCode.Insert or key.KeyCode == Enum.KeyCode.Delete then
				library.gui.Enabled = not library.gui.Enabled
				library.uiopen = library.gui.Enabled
			end
		end)
	--
	return setmetatable(cfg, library)
end
--
function library:tab(properties)
    local Page = {
		icon = properties.id or properties.icon or 'rbxassetid://8547236654', 
		count = 0
	}
    --
    local page_tab = library:create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = library["TabsHolder"],
        Size = UDim2.new(1, 0, 0, 72)
    });
    --
    local page_border = library:create("Frame", {
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Parent = page_tab,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        ZIndex = 2
    });
    --
    local page_image = library:create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = page_tab,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 50, 0, 50),
        ZIndex = 2,
        Image = Page.icon,
        ImageColor3 = Color3.fromRGB(100, 100, 100)
    });
    --
    local page_tab_action = library:create("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = page_tab,
        Size = UDim2.new(1, 0, 1, 0),
        Text = ""
    });
    --
    local tab_inborder = library:create("Frame", {
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BackgroundTransparency = 0,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Parent = page_border,
        Position = UDim2.new(0, 0, 0, 1),
        Size = UDim2.new(1, 1, 1, -2),
        ZIndex = 2
    });
    --
    local inborder = library:create("Frame", {
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderSizePixel = 0,
        Parent = tab_inborder,
        Position = UDim2.new(0, 0, 0, 1),
        Size = UDim2.new(1, 0, 1, -2),
        ZIndex = 2
    });
    --
    local border_in = library:create("Frame", {
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderSizePixel = 0,
        Parent = inborder,
        Position = UDim2.new(0, 0, 0, 1),
        Size = UDim2.new(1, 0, 1, -2),
        ZIndex = 2
    });
    --
    local inpattern = library:create("ImageLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = border_in,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        Image = "rbxassetid://8509210785",
        ImageColor3 = Color3.fromRGB(12, 12, 12),
        ScaleType = "Tile",
        TileSize = UDim2.new(0, 8, 0, 8),
        ZIndex = 2
    });
    --
    local pagepage = library:create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = library["PagesHolder"],
        Position = UDim2.new(0, 20, 0, 20),
        Size = UDim2.new(1, -40, 1, -40),
        Visible = false
    });
    --
    local pageOne = library:create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = pagepage,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0)
    });
    --
    local pageLeft = library:create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = pagepage,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0.5, -10, 1, 0)
    });
    --
    local pageRight = library:create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = pagepage,
        Position = UDim2.new(0.5, 10, 0, 0),
        Size = UDim2.new(0.5, -10, 1, 0)
    });
    --
    local pagemlist = library:create("UIListLayout", {
        Padding = UDim.new(0, 18),
        Parent = pageOne,
        FillDirection = "Vertical",
        HorizontalAlignment = "Left",
        VerticalAlignment = "Top"
    });
    --
    local pagellist = library:create("UIListLayout", {
        Padding = UDim.new(0, 18),
        Parent = pageLeft,
        FillDirection = "Vertical",
        HorizontalAlignment = "Left",
        VerticalAlignment = "Top"
    });
    --
    local pagerlist = library:create("UIListLayout", {
        Padding = UDim.new(0, 18),
        Parent = pageRight,
        FillDirection = "Vertical",
        HorizontalAlignment = "Left",
        VerticalAlignment = "Top"
    });
    --
    do
        Page["Page"] = pagepage;
        Page["One"] = pageOne;
        Page["Left"] = pageLeft;
        Page["Right"] = pageRight;
    end
    --
    function Page.open_tab() 
		local selected_tab = self.selected_tab
		
        if selected_tab then
            selected_tab[1].Visible = false
			selected_tab[2].Visible = false
			selected_tab[3].ImageColor3 = Color3.fromRGB(90, 90, 90)

            selected_tab = false
        end

		pagepage.Visible = true
        page_border.Visible = true
		page_image.ImageColor3 = Color3.fromRGB(255,255,255)

		self.selected_tab = {pagepage, page_border, page_image, page_tab_action}
	end
    --
    page_tab_action.MouseButton1Down:Connect(function()
		Page.open_tab()
	end)
    --
	if not self.selected_tab then 
		Page.open_tab(true) 
	end
    --
	return setmetatable(Page, library)
end
--
function library:watermark(properties)
    local cfg = {
        name = properties.name or properties.Name or "gamesense"
    }
    --
    local sgui = library:create("ScreenGui", {
        Parent = coregui,
		Name = 'S',
		DisplayOrder = 9999,
        Enabled = true,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = "Global"
    })
    --
    local back = library:create("Frame", {
        Parent = sgui,
        BackgroundColor3 = Color3.fromRGB(12, 12, 12),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 25, 0, 25),
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 150, 0, 20)
    });
    --
    library:draggify(back)
    --
    local grad = library:create("UIGradient",{
        Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(0.30, 0.36), NumberSequenceKeypoint.new(0.50, 0.36), NumberSequenceKeypoint.new(0.70, 0.36), NumberSequenceKeypoint.new(1.00, 1.00)},
        Parent = back
    });
    --
    local text = library:create("TextLabel", {
        Parent = back,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = Enum.Font.SourceSansBold,
        RichText = true,
        Text = cfg.name,
        TextColor3 = Color3.fromRGB(240, 240, 240),
        TextSize = 14
    })
    --
    function cfg.toggle_watermark(bool)
		back.Visible = bool
	end

	function cfg.update_text(txt)
		text.Text = txt
	end

	cfg.update_text(cfg.name)

	return setmetatable(cfg, library)
end
--
local watermark = library:watermark("gamesense  999MS  1999FPS")
local fps = 0
local watermark_delay = tick()
RunService.RenderStepped:Connect(function()
	fps += 1
	if tick() - watermark_delay > 1 then 
		watermark_delay = tick()
        local ping = math.floor(game:GetService('Stats').PerformanceStats.Ping:GetValue())
        watermark.update_text(string.format('gay<font color=\"rgb(%s, %s, %s)\">sex</font>  %s<font size = \"9\">MS</font>  %s<font size = \"9\">FPS</font>', math.round(library.accent.R * 255), math.round(library.accent.G * 255), math.round(library.accent.B * 255), ping, fps))
		fps = 0
	end
end)
--
function library:section(properties)
    local Section = {
        name = properties.Name or properties.name or "Sector",
        side = properties.pos or properties.Pos or properties.side or properties.Side or "Left",
        size = properties.size or properties.Size or properties.Y or 0.5,
        --
        content = {},
        --
        Page = self
    }
    --
    local section_hol = library:create("Frame", {
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BackgroundTransparency = 0,
        BorderColor3 = Color3.fromRGB(12, 12, 12),
        BorderMode = "Inset",
        BorderSizePixel = 1,
        Parent = Section.Page[Section.side],
        Size = UDim2.new(1, 0, Section.size, 0) - UDim2.new(0,0,0, Section.size < .9 and 9 or 0),
        ZIndex = 2
    });
    --
    local holder_extra = library:create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = section_hol,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 2
    });
    local holder_frame = library:create("Frame", {
        BackgroundColor3 = Color3.fromRGB(23, 23, 23),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Parent = section_hol,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 2
    });
    --
    local holder_title_inline = library:create("Frame", {
        BackgroundColor3 = Color3.fromRGB(23, 23, 23),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Parent = section_hol,
        Position = UDim2.new(0, 9, 0, -1),
        Size = UDim2.new(0, 0, 0, 2),
        ZIndex = 5
    });
    --
    local holder_title = library:create("TextLabel", {
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = section_hol,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -26, 0, 15),
        ZIndex = 5,
        Font = Enum.Font.SourceSans,
        RichText = true,
        Text = "<b>"..Section.name.."</b>",
        TextColor3 = Color3.fromRGB(205, 205, 205),
        TextSize = 13,
        TextStrokeTransparency = 1,
        TextXAlignment = "Left"
    });
    --
    local holder_gradient = library:create("ImageLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = holder_extra,
        Position = UDim2.new(0, 1, 0, 1),
        Rotation = 180,
        Size = UDim2.new(1, -2, 0, 20),
        Visible = false,
        ZIndex = 4,
        Image = "rbxassetid://7783533907",
        ImageColor3 = Color3.fromRGB(23, 23, 23)
    });
    --
    local holder_gradient2 = library:create("ImageLabel", {
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Parent = holder_extra,
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, -2, 0, 20),
        Visible = false,
        ZIndex = 4,
        Image = "rbxassetid://7783533907",
        ImageColor3 = Color3.fromRGB(23, 23, 23)
    });
    --
    local extra_bar = library:create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = Color3.fromRGB(45, 45, 45),
        BackgroundTransparency = 0,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Parent = holder_extra,
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 6, 1, 0),
        Visible = false,
        ZIndex = 4
    });
    --
    local extra_line = library:create("Frame", {
        BackgroundColor3 = Color3.fromRGB(45, 45, 45),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Parent = holder_extra,
        Position = UDim2.new(0, 0, 0, -1),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 4
    });
    --
    local frame_holder = library:create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = section_hol,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, -1, 1, 0),
        ZIndex = 4,
        AutomaticCanvasSize = "Y",
        BottomImage = "rbxassetid://7783554086",
        CanvasSize = UDim2.new(0, 0, 0, 0),
        MidImage = "rbxassetid://7783554086",
        ScrollBarImageColor3 = Color3.fromRGB(65, 65, 65),
        ScrollBarImageTransparency = 0,
        ScrollBarThickness = 5,
        TopImage = "rbxassetid://7783554086",
        VerticalScrollBarInset = "None"
    });
    --
    local holder_list = library:create("UIListLayout", {
        Padding = UDim.new(0, 0),
        Parent = frame_holder,
        FillDirection = "Vertical",
        HorizontalAlignment = "Center",
        VerticalAlignment = "Top"
    });
    --
    local Frame_ContentHolder_Padding = library:create("UIPadding", {
        Parent = frame_holder,
        PaddingTop = UDim.new(0, 15),
        PaddingBottom = UDim.new(0, 15)
    });
    --
    do
        holder_title_inline.Size = UDim2.new(0, holder_title.TextBounds.X + 6, 0, 2)
    end
    --
    do
        Section["Holder"] = frame_holder
        Section["Extra"] = holder_extra
    end
    --
        function Section:CloseContent()
            if Section.content.open then
                Section.content:Close()
                --
                Section.content = {}
            end
        end
    --
        frame_holder:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
            holder_gradient.Visible = frame_holder.AbsoluteCanvasSize.Y > frame_holder.AbsoluteWindowSize.Y
            holder_gradient2.Visible = frame_holder.AbsoluteCanvasSize.Y > frame_holder.AbsoluteWindowSize.Y
            extra_bar.Visible = frame_holder.AbsoluteCanvasSize.Y > frame_holder.AbsoluteWindowSize.Y
        end)
        --
        frame_holder:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            if Section.content.Open then
                Section.content:Close()
                --
                Section.content = {}
            end
        end)
    --
    return setmetatable(Section, library)
end
-- Elements
    function library:button(options)
        local cfg = {
            name = options.name or options.Name or "New button",
            callback = options.callback or function() end,
            Section = self
        }
        --
        local Content_Holder = library:create("Frame", {
            Parent = cfg.Section.Holder,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 24 + 5),
            ZIndex = 3
        })
        --
        local FrameButton = library:create("Frame", {
            Parent = Content_Holder,
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = Color3.fromRGB(16, 16, 16),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(1, -98, 0, 24),
            ZIndex = 3
        })
        --
        local InnerFrame = library:create("Frame", {
            Parent = FrameButton,
            BackgroundColor3 = Color3.fromRGB(43, 43, 43),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            ZIndex = 3
        })
        --
        local TextButton = library:create("TextButton", {
            Parent = InnerFrame,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            AutoButtonColor = false,
            Font = Enum.Font.SourceSans,
            Text = "",
            TextColor3 = Color3.fromRGB(0, 0, 0),
            TextSize = 0,
            ZIndex = 3
        })
        --
        local UIGradient = library:create("UIGradient", {
            Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(29, 29, 29)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(35, 35, 35))},
            Rotation = -90,
            Parent = TextButton
        })
        --
        local TextLabel = library:create("TextLabel", {
            Parent = TextButton,
            BackgroundTransparency = 1,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.SourceSans,
            Text = cfg.name,
            TextColor3 = Color3.fromRGB(150, 150, 150),
            TextSize = 13,
            TextStrokeTransparency = 0.8,
            ZIndex = 3
        })
        TextButton.MouseButton1Click:Connect(function(Input)
            cfg.callback()
        end)
        --
        TextButton.MouseEnter:Connect(function(Input)
            UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(44, 44, 44)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(48, 48, 48))}
            TextLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end)
        --
        TextButton.MouseLeave:Connect(function(Input)
            UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(29, 29, 29)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(35, 35, 35))}
            TextLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        end)
        return setmetatable(cfg, library)
    end
    --
    function library:toggle(options)
        local cfg = {
            name = options.name or options.Name or "New toggle",
            state = options.state or options.State or false,
            flag = options.flag or options.Flag or "194",
            risky = options.risky or false,
            callback = options.callback or function() end,
            --
            Section = self
        }
        local Content_Holder = library:create("Frame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = cfg.Section.Holder,
            Size = UDim2.new(1, 0, 0, 8 + 10),
            ZIndex = 3
        })
        --
        local Content_Holder_Outline = library:create("Frame", {
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            BackgroundTransparency = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Parent = Content_Holder,
            Position = UDim2.new(0, 20, 0, 5),
            Size = UDim2.new(0, 8, 0, 8),
            ZIndex = 3
        })
        --
        local Content_Holder_Title = library:create("TextLabel", {
            AnchorPoint = Vector2.new(0, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Parent = Content_Holder,
            Position = UDim2.new(0, 41, 0, 0),
            Size = UDim2.new(1, -41, 1, 0),
            ZIndex = 3,
            Font = Enum.Font.SourceSans,
            RichText = true,
            Text = cfg.name,
            TextColor3 = Color3.fromRGB(205, 205, 205),
            TextSize = 13,
            TextStrokeTransparency = 1,
            TextXAlignment = "Left",
        })
        local Content_Holder_Button = library:create("TextButton", {
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Parent = Content_Holder,
            Size = UDim2.new(1, 0, 1, 0),
            Text = ""
        })
        --
        local Holder_Outline_Frame = library:create("Frame", {
            BackgroundColor3 = Color3.fromRGB(77, 77, 77),
            BackgroundTransparency = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Parent = Content_Holder_Outline,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            ZIndex = 3
        })
        --
        local Outline_Frame_Gradient = library:create("UIGradient", {
            Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(140, 140, 140)),
            Enabled = true,
            Rotation = 90,
            Parent = Holder_Outline_Frame
        })
        --
            RunService.RenderStepped:Connect(function()
                Holder_Outline_Frame.BackgroundColor3 = cfg.state and library.accent or Color3.fromRGB(77, 77, 77)
                Content_Holder_Title.TextColor3 = cfg.state and Color3.new(255,255,255) or Color3.fromRGB(205, 205, 205)
            end)
            function cfg.set(bool)
                cfg.state = bool
                flags[cfg.flag] = cfg.state
                --
                Holder_Outline_Frame.BackgroundColor3 = cfg.state and library.accent or Color3.fromRGB(77, 77, 77)
                Content_Holder_Title.TextColor3 = cfg.state and Color3.new(255,255,255) or Color3.fromRGB(205, 205, 205)
                --
                cfg.callback(cfg.get())
            end
            --
            function cfg.get()
                return cfg.state
            end
        --
            Content_Holder_Button.MouseButton1Click:Connect(function()
                cfg.set(not cfg.get())
            end)
            --
            Content_Holder_Button.MouseEnter:Connect(function()
                Outline_Frame_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 180, 180))
            end)
            --
            Content_Holder_Button.MouseLeave:Connect(function()
                Outline_Frame_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(140, 140, 140))
            end)
        --
        cfg.set(cfg.state)
        config_flags[cfg.flag] = cfg.set
        --
        return setmetatable(cfg, library)
    end
    --
    function library:slider(options)
        local cfg = {
            name = options.name or options.Name or nil,
            suffix = options.suffix or options.Suffix or "",
            flag = options.flag or options.Flag or "slider",
            callback = options.callback or options.Callback or function() end,
            --
            min = options.min or options.Min or 0,
            max = options.max or options.Max or 100,
            interval = options.interval or options.Interval or options.Decimal or options.decimal or 1,
            default = (options.default or options.Default) ~= nil or (options.min or options.Min),
            value = options.default or options.Default or 10,
            --
            mtext = options.maxtext or options.Maxtext or nil,
            --
            ignore = options.ignore or false, 
			dragging = false,
            --
            Section = self
        }
        local Content_Holder = library:create("Frame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = cfg.Section.Holder,
            Size = UDim2.new(1, 0, 0, (cfg.name and 24 or 13) + 5),
            ZIndex = 3
        })
        -- //
        local Content_Holder_Outline = library:create("Frame", {
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            BackgroundTransparency = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Parent = Content_Holder,
            Position = UDim2.new(0, 40, 0, cfg.name and 18 or 5),
            Size = UDim2.new(1, -99, 0, 7),
            ZIndex = 3
        })
        if cfg.name then
            local Content_Holder_Title = library:create("TextLabel", {
                AnchorPoint = Vector2.new(0, 0),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 1,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BorderSizePixel = 0,
                Parent = Content_Holder,
                Position = UDim2.new(0, 41, 0, 4),
                Size = UDim2.new(1, -41, 0, 10),
                ZIndex = 3,
                Font = Enum.Font.SourceSans,
                Text = cfg.name,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 13,
                TextStrokeTransparency = 1,
                TextXAlignment = "Left"
            })
        end
        --
        local Content_Holder_Button = library:create("TextButton", {
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Parent = Content_Holder,
            Size = UDim2.new(1, 0, 1, 0),
            Text = ""
        })
        --
        local Holder_Outline_Frame = library:create("Frame", {
            BackgroundColor3 = Color3.fromRGB(71, 71, 71),
            BackgroundTransparency = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Parent = Content_Holder_Outline,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            ZIndex = 3
        })
        --
        local Outline_Frame_Slider = library:create("Frame", {
            BackgroundColor3 = library.accent,
            BackgroundTransparency = 0,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Parent = Holder_Outline_Frame,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 0, 1, 0),
            ZIndex = 3
        })
        --
        local Outline_Frame_Gradient = library:create("UIGradient", {
            Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(175, 175, 175)),
            Enabled = true,
            Rotation = 270,
            Parent = Holder_Outline_Frame
        })
        --
        local Frame_Slider_Gradient = library:create("UIGradient", {
            Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(175, 175, 175)),
            Enabled = true,
            Rotation = 90,
            Parent = Outline_Frame_Slider
        })
        --
        local Frame_Slider_Title = library:create("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Parent = Outline_Frame_Slider,
            Position = UDim2.new(1, 0, 0.5, 1),
            Size = UDim2.new(0, 2, 1, 0),
            ZIndex = 3,
            Font = Enum.Font.SourceSans,
            RichText = true,
            Text = "",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 13,
            TextStrokeTransparency = 0.5,
            TextXAlignment = "Center"
        })
        --
        local Frame_Slider_Title2 = library:create("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Parent = Outline_Frame_Slider,
            Position = UDim2.new(1, 0, 0.5, 1),
            Size = UDim2.new(0, 2, 1, 0),
            ZIndex = 3,
            Font = Enum.Font.SourceSans,
            RichText = true,
            Text = "",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 13,
            TextStrokeTransparency = 0.5,
            TextTransparency = 0,
            TextXAlignment = "Center"
        })
        --
            RunService.RenderStepped:Connect(function()
                Outline_Frame_Slider.BackgroundColor3 = library.accent
            end)
        --
        function cfg.set(state)
            cfg.value = math.clamp(math.round(state * cfg.interval) / cfg.interval, cfg.min, cfg.max)
            flags[cfg.flag] = cfg.value
            --
            if cfg.mtext ~= nil then
                if cfg.value == cfg.max then
                    Frame_Slider_Title.Text = "<b>" .. cfg.mtext .. "</b>"
                else
                    Frame_Slider_Title.Text = "<b>" .. cfg.value .. cfg.suffix .. "</b>"
                end
            else
                Frame_Slider_Title.Text = "<b>" .. cfg.value .. cfg.suffix .. "</b>"
            end
            Outline_Frame_Slider.Size = UDim2.new((1 - ((cfg.max - cfg.value) / (cfg.max - cfg.min))), 0, 1, 0)
            --
            cfg.callback(cfg.get())
        end
        --
        function cfg.refresh()
            local Mouse = UserInputService:GetMouseLocation()
            --
            cfg.set(math.clamp(math.floor((cfg.min + (cfg.max - cfg.min) * math.clamp(Mouse.X - Outline_Frame_Slider.AbsolutePosition.X, 0, Holder_Outline_Frame.AbsoluteSize.X) / Holder_Outline_Frame.AbsoluteSize.X) * cfg.interval) / cfg.interval, cfg.min, cfg.max))
        end
        --
        function cfg.get()
            return cfg.value
        end
        --
            Content_Holder_Button.MouseButton1Down:Connect(function(Input)
                cfg.refresh()
                --
                cfg.dragging = true
                --
                Outline_Frame_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(215, 215, 215))
                Frame_Slider_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(215, 215, 215))
            end)
            --
            Content_Holder_Button.MouseEnter:Connect(function(Input)
                Outline_Frame_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(215, 215, 215))
                Frame_Slider_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(215, 215, 215))
            end)
            --
            Content_Holder_Button.MouseLeave:Connect(function(Input)
                Outline_Frame_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), cfg.dragging and Color3.fromRGB(215, 215, 215) or Color3.fromRGB(175, 175, 175))
                Frame_Slider_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), cfg.dragging and Color3.fromRGB(215, 215, 215) or Color3.fromRGB(175, 175, 175))
            end)
            --
            UserInputService.InputChanged:Connect(function(Input)
                if cfg.dragging then
                    cfg.refresh()
                end
            end)
            --
            UserInputService.InputEnded:Connect(function(Input)
                if cfg.dragging and Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    cfg.dragging = false
                    --
                    Outline_Frame_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(175, 175, 175))
                    Frame_Slider_Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(175, 175, 175))
                end
            end)
        --
        cfg.set(cfg.value)
        config_flags[cfg.flag] = cfg.set
        --
        return setmetatable(cfg, library)
    end
    --
    function library:textbox(options)
        local cfg = {
            text = options.text or options.Text or "...",
            default = options.default or options.Default,
            placeholder = options.placeholder or options.Placeholder or "text",
            --
            flag = options.flag or "textbox",
            callback = options.callback or options.Callback or function() end,
            --
            Section = self
        }
        --
        local Content_Holder = library:create("Frame", {
            Parent = cfg.Section.Holder,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 29),
            ZIndex = 3
        });
        --
        local MainFrame = library:create("Frame", {
            Parent = Content_Holder,
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = Color3.fromRGB(3, 3, 3),
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(1, -98, 0, 24),
            ZIndex = 3
        });
        --
        local MainFrame_InnerBorder = library:create("Frame", {
            Parent = MainFrame,
            BackgroundColor3 = Color3.fromRGB(49, 50, 50),
            BorderColor3 = Color3.fromRGB(49, 50, 50),
            BorderSizePixel = 1,
            BorderMode = "Inset",
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            ZIndex = 3
        });
        --
        local BoxHolder = library:create("Frame",{
            Parent = MainFrame_InnerBorder,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 3
        });
        --
        local Gradient = library:create("UIGradient", {
            Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 35)), ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 26))},
            Rotation = 90,
            Parent = BoxHolder
        });
        --
        local TextBox = library:create("TextBox", {
            Parent = BoxHolder,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(1, -5, 1, 0),
            Font = Enum.Font.SourceSans,
            PlaceholderColor3 = Color3.fromRGB(85, 85, 85),
            Text = cfg.text,
            PlaceholderText = cfg.placeholder,
            TextColor3 = Color3.fromRGB(205, 205, 205),
            TextSize = 13,
            TextStrokeTransparency = 0.2,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 3
        });
        --
        function cfg.set(string)
            flags[cfg.flag] = string
            --
            TextBox.Text = string
            --
            cfg.callback(string)
        end
        --
        config_flags[cfg.flag] = cfg.set
        --
        if cfg.default then
            cfg.set(cfg.default)
        end
        --
        TextBox:GetPropertyChangedSignal('Text'):Connect(function()
            cfg.set(TextBox.Text)
        end)
        --
        return setmetatable(cfg, library)
    end
    --
    function library:dropdown(options)
        local cfg = {
            name = options.name or nil,
            state = options.state or options.State or options.Default or options.default or 1,
            items = options.items or options.Items or options.List or options.list or {"a","b","c"},
            callback = options.callback or options.Callback or function() end,
            flag = options.flag or options.Flag or "dropdown",
            --
            content = {
                open = false
            },
            --
            Section = self
        }
        --
        local Content_Holder = library:create("Frame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = cfg.Section.Holder,  
            Size = UDim2.new(1, 0, 0, (cfg.name and 34 or 23) + 5),
            ZIndex = 3
        });
        --
        local Content_Holder_Outline = library:create("Frame", {
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Parent = Content_Holder,
            Position = UDim2.new(0, 40, 0, cfg.name and 17 or 4),
            Size = UDim2.new(1, -98, 0, 20),
            ZIndex = 3
        });
        --
        if cfg.name then
            local Content_Holder_Title = library:create("TextLabel", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Parent = Content_Holder,
                Position = UDim2.new(0, 41, 0, 4),
                Size = UDim2.new(1, -41, 0, 10),
                ZIndex = 3,
                Font = Enum.Font.SourceSans,
                RichText = true,
                Text = cfg.name,
                TextColor3 = Color3.fromRGB(205, 205, 205),
                TextSize = 13,
                TextXAlignment = "Left"
            });
        end
        --
        local Content_Holder_Button = library:create("TextButton", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = Content_Holder,
            Size = UDim2.new(1, 0, 1, 0),
            Text = ""
        })
        --
        local Holder_Outline_Frame = library:create("Frame", {
            BackgroundColor3 = Color3.fromRGB(36, 36, 36),
            BorderSizePixel = 0,
            Parent = Content_Holder_Outline,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            ZIndex = 3
        })
        --
        local Outline_Frame_Gradient = library:create("UIGradient", {
            Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(220, 220, 220)),
            Enabled = true,
            Rotation = 270,
            Parent = Holder_Outline_Frame
        })
        --
        local Outline_Frame_Title = library:create("TextLabel", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = Holder_Outline_Frame,
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 3,
            Font = Enum.Font.SourceSans,
            RichText = true,
            Text = "",
            TextColor3 = Color3.fromRGB(155, 155, 155),
            TextSize = 13,
            TextStrokeTransparency = 1,
            TextXAlignment = "Left"
        })
        --
        local Outline_Frame_Arrow = library:create("ImageLabel", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = Holder_Outline_Frame,
            Position = UDim2.new(1, -11, 0.5, -4),
            Size = UDim2.new(0, 7, 0, 6),
            Image = "rbxassetid://8532000591",
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ZIndex = 3
        })
        --
            function cfg.set(state)
                cfg.state = state
                flags[cfg.flag] = cfg.state
                --
                Outline_Frame_Title.Text = cfg.items[cfg.get()]
                --
                cfg.callback(cfg.get())
                --
                if cfg.content.open then
                    cfg.content:Refresh(cfg.get())
                end
            end
            --
            function cfg.get()
                return cfg.state
            end
            --
            function cfg.open()
				cfg.Section:CloseContent()
                --
                local Open = {}
                local Connections = {}
                --
                local InputCheck
                --
                local Content_Open_Holder = library:create("Frame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Parent = cfg.Section.Extra,
                    Position = UDim2.new(0, Content_Holder_Outline.AbsolutePosition.X - cfg.Section.Extra.AbsolutePosition.X, 0, Content_Holder_Outline.AbsolutePosition.Y - cfg.Section.Extra.AbsolutePosition.Y + 21),
                    Size = UDim2.new(1, -98, 0, (18 * #cfg.items) + 2),
                    ZIndex = 6
                })
                --
                local Open_Holder_Outline = library:create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                    BorderSizePixel = 0,
                    Parent = Content_Open_Holder,
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(1, 0, 1, 0),
                    ZIndex = 6
                })
                --
                local Open_Holder_Outline_Frame = library:create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                    BorderSizePixel = 0,
                    Parent = Open_Holder_Outline,
                    Position = UDim2.new(0, 1, 0, 1),
                    Size = UDim2.new(1, -2, 1, -2),
                    ZIndex = 6
                })
                --
                for Index, Option in pairs(cfg.items) do
                    local Outline_Frame_Option = library:create("Frame", {
                        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                        BorderSizePixel = 0,
                        Parent = Open_Holder_Outline_Frame,
                        Position = UDim2.new(0, 0, 0, 18 * (Index - 1)),
                        Size = UDim2.new(1, 0, 1 / #cfg.items, 0),
                        ZIndex = 6
                    })
                    --
                    local Frame_Option_Title = library:create("TextLabel", {
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Parent = Outline_Frame_Option,
                        Position = UDim2.new(0, 8, 0, 0),
                        Size = UDim2.new(1, 0, 1, 0),
                        ZIndex = 6,
                        Font = Enum.Font.SourceSans,
                        Text = tostring(Option),
                        TextColor3 = Index == cfg.state and library.accent or Color3.fromRGB(205, 205, 205),
                        TextSize = 13,
                        TextXAlignment = "Left"
                    })
                    --
                    local Frame_Option_Button = library:create("TextButton", {
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Parent = Outline_Frame_Option,
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "",
                        ZIndex = 6
                    })
                    --
                        Frame_Option_Button.MouseButton1Click:Connect(function(Input)
                            cfg.set(Index)
                        end)
                        --
                        Frame_Option_Button.MouseEnter:Connect(function(Input)
                            Outline_Frame_Option.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                        end)
                        --
                        Frame_Option_Button.MouseLeave:Connect(function(Input)
                            Outline_Frame_Option.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                        end)
                    --
                    Open[#Open + 1] = {Index, Frame_Option_Title, Outline_Frame_Option, Frame_Option_Button}
                end
                --
                function cfg.content:Close()
                    cfg.content.open = false
                    --
                    Holder_Outline_Frame.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
                    --
                    InputCheck:Disconnect()
                    --
                    for Index, Value in pairs(Open) do
                        Value[2]:Remove()
                        Value[3]:Remove()
                        Value[4]:Remove()
                    end
                    --
                    Content_Open_Holder:Remove()
                    Open_Holder_Outline:Remove()
                    Open_Holder_Outline_Frame:Remove()
                    --
                    function cfg.content:Refresh() end
                    --
                    InputCheck = nil
                    Connections = nil
                    Open = nil
                end
                --
                function cfg.content:Refresh(state)
                    for Index, Value in pairs(Open) do
                        Value[2].TextColor3 = Value[1] == cfg.state and library.accent or Color3.fromRGB(205, 205, 205)
                    end
                end
                --
                cfg.content.open = true
                cfg.Section.Content = cfg.content
                --
                Holder_Outline_Frame.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
                do
                    task.wait()
                    --
                    InputCheck = UserInputService.InputBegan:Connect(function(Input)
                        if cfg.content.open and Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            local Mouse = UserInputService:GetMouseLocation()
                            --
                            if not (Mouse.X < (Content_Open_Holder.AbsolutePosition.X + Content_Open_Holder.AbsoluteSize.X) and Mouse.Y < (Content_Open_Holder.AbsolutePosition.Y + Content_Open_Holder.AbsoluteSize.Y + 60)) then
                                cfg.content:Close()
                            end
                        end
                    end)
                end
            end
            do -- // Connections
                Content_Holder_Button.MouseButton1Down:Connect(function(Input)
                    if cfg.content.open then
                        cfg.content:Close()
                    else
                        cfg.open()
                    end
                end)
                --
                Content_Holder_Button.MouseEnter:Connect(function(Input)
                    Holder_Outline_Frame.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
                end)
                --
                Content_Holder_Button.MouseLeave:Connect(function(Input)
                    Holder_Outline_Frame.BackgroundColor3 = cfg.content.open and Color3.fromRGB(46, 46, 46) or Color3.fromRGB(36, 36, 36)
                end)
            end
            --
            cfg.set(cfg.state)
        --
        return setmetatable(cfg, library)
    end
    --
    function library:keybind(options)
        local cfg = {
            name = options.name or options.Name or "New keybind",
            state = options.state or options.State or nil,
            mode = options.mode or options.Mode or "Hold",
            callback = options.callback or options.Callback or function() end,
            flag = options.flag or options.Flag or "keybind",
            --
            active = false,
            holding = false,
            --
            Section = self
        }
        --
        local Keys = {
            KeyCodes = {"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", "Z", "X", "C", "V", "B", "N", "M", "One", "Two", "Three", "Four", "Five", "Six", "Seveen", "Eight", "Nine", "0", "Insert", "Tab", "Home", "End", "LeftAlt", "LeftControl", "LeftShift", "RightAlt", "RightControl", "RightShift", "CapsLock"},
            Inputs = {"MouseButton1", "MouseButton2", "MouseButton3"},
            Shortened = {["MouseButton1"] = "M1", ["MouseButton2"] = "M2", ["MouseButton3"] = "M3", ["Insert"] = "INS", ["LeftAlt"] = "LA", ["LeftControl"] = "LC", ["LeftShift"] = "LS", ["RightAlt"] = "RA", ["RightControl"] = "RC", ["RightShift"] = "RS", ["CapsLock"] = "CL"}
        }
        local Content_Holder = library:create("Frame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = cfg.Section.Holder,
            Size = UDim2.new(1, 0, 0, 8 + 10),
            ZIndex = 3
        })
        -- //
        local Content_Holder_Title = library:create("TextLabel", {
            AnchorPoint = Vector2.new(0, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Parent = Content_Holder,
            Position = UDim2.new(0, 41, 0, 0),
            Size = UDim2.new(1, -41, 1, 0),
            ZIndex = 3,
            Font = Enum.Font.SourceSans,
            RichText = true,
            Text = cfg.name,
            TextColor3 = Color3.fromRGB(205, 205, 205),
            TextSize = 13,
            TextStrokeTransparency = 1,
            TextXAlignment = "Left"
        })
        --
        local Content_Holder_Button = library:create("TextButton", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = Content_Holder,
            Size = UDim2.new(1, 0, 1, 0),
            Text = ""
        })
        --
        local Content_Holder_Value = library:create("TextLabel", {
            AnchorPoint = Vector2.new(0, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Parent = Content_Holder,
            Position = UDim2.new(0, 41, 0, 0),
            Size = UDim2.new(1, -61, 1, 0),
            ZIndex = 3,
            Font = Enum.Font.SourceSans,
            RichText = true,
            Text =  "",
            TextColor3 = Color3.fromRGB(114, 114, 114),
            TextStrokeColor3 = Color3.fromRGB(15, 15, 15),
            TextSize = 13,
            TextStrokeTransparency = 0,
            TextXAlignment = "Right"
        })
        --
            function cfg.set(state)
                cfg.state = state or {}
                cfg.active = false
                flags[cfg.flag] = cfg.active
                --
                Content_Holder_Value.Text = "[" .. (#cfg.get() > 0 and cfg.shorten(cfg.get()[2]) or "-") .. "]"
                --
                cfg.callback(cfg.get())
            end
            --
            function cfg.get()
                return cfg.state
            end
            --
            function cfg.shorten(Str)
                for Index, Value in pairs(Keys.Shortened) do
                    Str = string.gsub(Str, Index, Value)
                end
                --
                return Str
            end
            --
            function cfg.change(Key)
                if Key.EnumType then
                    if Key.EnumType == Enum.KeyCode or Key.EnumType == Enum.UserInputType then
                        if table.find(Keys.KeyCodes, Key.Name) or table.find(Keys.Inputs, Key.Name) then
                            cfg.set({Key.EnumType == Enum.KeyCode and "KeyCode" or "UserInputType", Key.Name})
                            return true
                        end
                    end
                end
            end
        --
            Content_Holder_Button.MouseButton1Click:Connect(function(Input)
                cfg.holding = true
                --
                Content_Holder_Value.TextColor3 = Color3.fromRGB(255, 0, 0)
            end)
            --
            Content_Holder_Button.MouseButton2Click:Connect(function(Input)
                cfg.set()
            end)
            --
            Content_Holder_Button.MouseEnter:Connect(function(Input)
                Content_Holder_Value.TextColor3 = Color3.fromRGB(164, 164, 164)
            end)
            --
            Content_Holder_Button.MouseLeave:Connect(function(Input)
                Content_Holder_Value.TextColor3 = cfg.holding and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(114, 114, 114)
            end)
            UserInputService.InputBegan:Connect(function(Input)
                if cfg.holding then
                    local Success = cfg.change(Input.KeyCode.Name ~= "Unknown" and Input.KeyCode or Input.UserInputType)
                    --
                    if Success then
                        cfg.holding = false
                        --
                        Content_Holder_Value.TextColor3 = Color3.fromRGB(114, 114, 114)
                    end
                end
                --
                if cfg.get()[1] and cfg.get()[2] then
                    if Input.KeyCode == Enum[cfg.get()[1]][cfg.get()[2]] or Input.UserInputType == Enum[cfg.get()[1]][cfg.get()[2]] then
                        if cfg.mode == "Hold" then
                            cfg.active = true
                            flags[cfg.flag] = cfg.active
                        elseif cfg.mode == "Toggle" then
                            cfg.active = not cfg.active
                            flags[cfg.flag] = cfg.active
                        end
                    end
                end
            end)
            --
            UserInputService.InputEnded:Connect(function(Input)
                if cfg.get()[1] and cfg.get()[2] then
                    if Input.KeyCode == Enum[cfg.get()[1]][cfg.get()[2]] or Input.UserInputType == Enum[cfg.get()[1]][cfg.get()[2]] then
                        if cfg.mode == "Hold" then
                            cfg.active = false
                            flags[cfg.flag] = cfg.active
                        end
                    end
                end
            end)
            cfg.set(cfg.state)
        --
        return setmetatable(cfg, library)
    end
    --
    function library:color(options)
        local cfg = {
            name = options.name or options.Name or "New colorpicker",
            flag = options.flag or options.Flag or "colorpicker",
            --
            color = options.color or options.Color or Color3.new(1,1,1),
            alpha = options.alpha and 1 - options.alpha or options.Alpha and 1 - options.Alpha or 0,
            --
            content = { open = false },
            Section = self,
            --
            callback = options.callback or options.Callback or function() end
        }
        --
        local Content_Holder = library:create("Frame", {
            Parent = cfg.Section.Holder,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 20),
            ZIndex = 3
        });
        --
        local Content_Holder_Outline = library:create("Frame", {
            AnchorPoint = Vector2.new(0, .5),
            Parent = Content_Holder,
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            BorderSizePixel = 0,
            Position = UDim2.new(1, -38, .5, 0),
            Size = UDim2.new(0, 17, 0, 9),
            ZIndex = 3
        });
        --
        local Holder_Outline_Frame = library:create("Frame", {
            Parent = Content_Holder_Outline,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            ZIndex = 3
        });
        --
        local Outline_Frame_Gradient = library:create("UIGradient", {
            Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(140, 140, 140))},
            Rotation = 90,
            Parent = Holder_Outline_Frame
        });
        --
        local Content_Holder_Title = library:create("TextLabel", {
            Parent = Content_Holder,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 41, 0, 0),
            Size = UDim2.new(1, -41, 1, 0),
            Font = Enum.Font.SourceSans,
            Text = cfg.name,
            TextColor3 = Color3.fromRGB(205, 205, 205),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 3
        });
        --
        local Content_Holder_Button = library:create("TextButton", {
            Parent = Content_Holder,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.SourceSans,
            Text = "",
            TextSize = 0,
            ZIndex = 3
        });
        -- Frame Picker
            local colorpicker = library:create("Frame", {
                Parent = library.gui,
                Visible = false,
                BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                BorderColor3 = Color3.fromRGB(12, 12, 12),
                Position = UDim2.new(0.688817918, 0, 0.247512445, 0),
                Size = UDim2.new(0, 150, 0, 150),
                ZIndex = 9
            });
            --
            local a = library:create("Frame", {
                Parent = colorpicker,
                BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 9
            });
            --
            local e = library:create("Frame", {
                Parent = a,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                ZIndex = -1
            });
            --
            local _ = library:create("UIPadding", {
                Parent = e,
                PaddingBottom = UDim.new(0, -13),
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 6),
                PaddingTop = UDim.new(0, 7)
            });
            --
            local hue_button = library:create("TextButton", {
                Parent = e,
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                BorderColor3 = Color3.fromRGB(12, 12, 12),
                BorderSizePixel = 1,
                Position = UDim2.new(1, -1, 0, 0),
                Size = UDim2.new(0, 14, 1.13157892, -60),
                AutoButtonColor = false,
                Font = Enum.Font.SourceSans,
                Text = "",
                TextSize = 0,
                ZIndex = 9
            });
            --
            local hue_drag = library:create("Frame", {
                Parent = hue_button,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                ZIndex = 9
            });
            --
            library:create("UIGradient", {
                Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))},
                Rotation = -90,
                Parent = hue_drag,
            });
            --
            local hue_picker = library:create("Frame", {
                Parent = hue_drag,
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BorderColor3 = Color3.fromRGB(60, 60, 60),
                Position = UDim2.new(0, -1, 0, -1),
                Size = UDim2.new(1, 2, 0, 3),
                ZIndex = 9
            });
            --
            local alpha_button = library:create("TextButton", {
                Parent = e,
                AnchorPoint = Vector2.new(0, 1),
                BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                BorderColor3 = Color3.fromRGB(12, 12, 12),
                BorderSizePixel = 1,
                Position = UDim2.new(0, 0, 1, -20),
                Size = UDim2.new(1, -1, 0, 14),
                AutoButtonColor = false,
                Font = Enum.Font.SourceSans,
                Text = "",
                TextSize = 0,
                ZIndex = 9
            });
            --
            local alpha_color = library:create("Frame", {
                Parent = alpha_button,
                BackgroundColor3 = Color3.fromRGB(255, 0, 0),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                ZIndex = 9
            });
            --
            local alphaind = library:create("ImageLabel", {
                Parent = alpha_color,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0),
                Image = "rbxassetid://18274452449",
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.new(0, 4, 0, 4),
                ZIndex = 9
            });
            --
            library:create("UIGradient", {
                Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(1.00, 1.00)},
                Parent = alphaind
            });
            --
            local alpha_picker = library:create("Frame", {
                Parent = alpha_color,
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BorderColor3 = Color3.fromRGB(60, 60, 60),
                BorderSizePixel = 1,
                Position = UDim2.new(0, -1, 0, -1),
                Size = UDim2.new(0, 3, 1, 2),
                ZIndex = 9
            });
            --
            local saturation_value_button = library:create("TextButton", {
                Parent = e,
                BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                BorderColor3 = Color3.fromRGB(12, 12, 12),
                BorderSizePixel = 1,
                Position = UDim2.new(0.0225563906, 0, 0.00657894742, 0),
                Size = UDim2.new(0.977443635, -20, 1.11842108, -60),
                AutoButtonColor = false,
                Font = Enum.Font.SourceSans,
                Text = "",
                TextSize = 0,
                ZIndex = 9
            });
            --
            local colorpicker_color = library:create("Frame", {
                Parent = saturation_value_button,
                BackgroundColor3 = Color3.fromRGB(255, 0, 0),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                ZIndex = 9
            });
            --
            local val = library:create("TextButton", {
                Parent = colorpicker_color,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0),
                AutoButtonColor = false,
                Font = Enum.Font.SourceSans,
                Text = "",
                TextSize = 0,
                ZIndex = 9
            });
            --
            library:create("UIGradient", {
                Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(1.00, 1.00)},
                Parent = val
            });
            --
            local saturation_value_picker = library:create("Frame", {
                Parent = colorpicker_color,
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BorderSizePixel = 0,
                Size = UDim2.new(0, 3, 0, 3),
                ZIndex = 9
            });
            --
            local inline = library:create("Frame", {
                Parent = saturation_value_picker,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                ZIndex = 9
            });
            --
            local saturation_button = library:create("TextButton", {
                Parent = colorpicker_color,
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 2,
                AutoButtonColor = false,
                Font = Enum.Font.SourceSans,
                Text = "",
                TextSize = 0,
                ZIndex = 9
            });
            --
            library:create("UIGradient", {
                Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))},
                Rotation = 270,
                Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(1.00, 1.00)},
                Parent = saturation_button
            });
            --
        --
            
        -- functions
            local dragging_sat = false 
			local dragging_hue = false 
			local dragging_alpha = false 
            --
			local h, s, v = cfg.color:ToHSV() 
			local a = cfg.alpha 
            flags[cfg.flag] = {}
            --
            function cfg.set_visible(bool) 
				colorpicker.Visible = bool
				colorpicker.Position = UDim2.fromOffset(Holder_Outline_Frame.AbsolutePosition.X - 1, Holder_Outline_Frame.AbsolutePosition.Y + Holder_Outline_Frame.AbsoluteSize.Y + 65)
			end
            --
            function cfg.set(color, alpha)
				if color then
					h, s, v = color:ToHSV()
				end
				--
				if alpha then 
					a = alpha
				end 
				--
				local Color = Color3.fromHSV(h, s, v)
                --
				hue_picker.Position = UDim2.new(0, -1, 1 - h, -1)
				alpha_picker.Position = UDim2.new(1 - a, -1, 0, -1)
				saturation_value_picker.Position = UDim2.new(s, -1, 1 - v, -1)
                --
				alpha_color.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				Holder_Outline_Frame.BackgroundColor3 = Color
				colorpicker_color.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				--
				flags[cfg.flag] = {
					Color = Color;
					Transparency = a
				}
				--
				local color = Holder_Outline_Frame.BackgroundColor3
				--
				cfg.callback(Color, a)
			end
            --
            function cfg.update_color() 
				local Mouse = UserInputService:GetMouseLocation() 
				local offset = Vector2.new(Mouse.X, Mouse.Y - game:GetService('GuiService'):GetGuiInset().Y) 
                --
				if dragging_sat then	
					s = math.clamp((offset - saturation_value_button.AbsolutePosition).X / saturation_value_button.AbsoluteSize.X, 0, 1)
					v = 1 - math.clamp((offset - saturation_value_button.AbsolutePosition).Y / saturation_value_button.AbsoluteSize.Y, 0, 1)
				elseif dragging_hue then
					h = 1 - math.clamp((offset - hue_button.AbsolutePosition).Y / hue_button.AbsoluteSize.Y, 0, 1)
				elseif dragging_alpha then
					a = 1 - math.clamp((offset - alpha_button.AbsolutePosition).X / alpha_button.AbsoluteSize.X, 0, 1)
				end
                --
				cfg.set(nil, nil)
			end
            --
			cfg.set(cfg.color, cfg.alpha)
            --
			config_flags[cfg.flag] = cfg.set
        --

        -- Connections
            Content_Holder_Button.MouseButton1Click:Connect(function()
				cfg.open = not cfg.open 
				cfg.set_visible(cfg.open)            
			end)

			UserInputService.InputChanged:Connect(function(input)
				if (dragging_sat or dragging_hue or dragging_alpha) and input.UserInputType == Enum.UserInputType.MouseMovement then
					cfg.update_color()
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging_sat = false
					dragging_hue = false
					dragging_alpha = false  

					if not (library:mouse_in_frame(Content_Holder_Button) or library:mouse_in_frame(colorpicker)) then 
						cfg.open = false
						cfg.set_visible(false)
					end
				end
			end)
            --
			alpha_button.MouseButton1Down:Connect(function()
				dragging_alpha = true 
			end)
            --
			hue_button.MouseButton1Down:Connect(function()
				dragging_hue = true 
			end)
			--
			saturation_button.MouseButton1Down:Connect(function()
				dragging_sat = true  
			end)
            --
        return setmetatable(cfg, library)
    end
    --
--
return library
