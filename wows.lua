-- Originally used for Opiumware before we upgraded to C side drawing
-- Fork of solara's drawing (https://github.com/quivings/Solara/blob/main/Storage/Drawing.lua)

do
	local CoreGui = game:GetService("CoreGui")
	local DrawingUI = Instance.new("ScreenGui")
	DrawingUI.Name = "Drawing"
	DrawingUI.IgnoreGuiInset = true
	DrawingUI.DisplayOrder = 0x7fffffff
	DrawingUI.Parent = CoreGui

	local DrawingIndex = 0
	local UIStrokes = {}

	local MergeTable = function(base, override)
		local result = table.clone(base)
		for k, v in override do
			result[k] = v
		end
		return result
	end

	local ConvertTransparency = function(transparency)
		return math.clamp(1 - transparency, 0, 1)
	end

	local RandomString = function(length)
		local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		local result = {}
		for i = 1, length do
			local index = math.random(1, #charset)
			table.insert(result, charset:sub(index, index))
		end
		return table.concat(result)
	end

	local BaseDrawingObj = setmetatable({
		Visible = true,
		ZIndex = 0,
		Transparency = 1,
		Color = Color3.new(),
		__OBJECT_EXISTS = true,
		Remove = function(self)
			if self.__OBJECT_EXISTS == false then
				return
			end
			self.__OBJECT_EXISTS = false
			self.Visible = false
		end,
		Destroy = function(self)
			if self.__OBJECT_EXISTS == false then
				return
			end
			self.__OBJECT_EXISTS = false
			self.Visible = false
		end,
	}, {
		__add = function(t1, t2) return MergeTable(t1, t2) end
	})

	local FontEnum = {
		[0] = Font.fromEnum(Enum.Font.Roboto),
		[1] = Font.fromEnum(Enum.Font.Legacy),
		[2] = Font.fromEnum(Enum.Font.SourceSans),
		[3] = Font.fromEnum(Enum.Font.RobotoMono),
	}

	getgenv().Drawing = {}

	getgenv().Drawing.Fonts = {
		UI = 0,
		System = 1,
		Plex = 2,
		Monospace = 3,
	}

	table.freeze(getgenv().Drawing.Fonts);

	getgenv().Drawing.clear = newcclosure(function()
		pcall(function()
			DrawingUI:ClearAllChildren()
			DrawingIndex = 0
			delfolder(".Drawing/CustomAssets")
		end)
	end)

	getgenv().cleardrawcache = getgenv().Drawing.clear

	getgenv().Drawing.new = newcclosure(function(Type)
		assert(typeof(Type) == "string", "invalid argument #1 to 'Drawing.new' (string expected, got " .. typeof(Type) .. ")")
		DrawingIndex += 1;

		local CreateFrame = function(Name)
			local Frame = Instance.new("Frame")
			Frame.Name = Name
			Frame.BorderSizePixel = 0
			Frame.AnchorPoint = Vector2.new(0.5, 0.5)
			Frame.BackgroundTransparency = 1
			Frame.ZIndex = 0
			Frame.Visible = true
			return Frame
		end

		if Type == "Line" then
			local Obj = MergeTable(BaseDrawingObj, {
				From = Vector2.zero,
				To = Vector2.zero,
				Thickness = 1,
			})

			local LineFrame = CreateFrame("Line")
			LineFrame.BackgroundColor3 = Obj.Color
			LineFrame.Visible = Obj.Visible
			LineFrame.ZIndex = Obj.ZIndex
			LineFrame.BackgroundTransparency = ConvertTransparency(Obj.Transparency)
			LineFrame.Size = UDim2.new()

			LineFrame.Parent = DrawingUI

			return setmetatable({}, {
				__newindex = function(_, Key, Value)
					if Obj.__OBJECT_EXISTS == false then return end
					if Obj[Key] == nil then return end

					if Key == "From" or Key == "To" then
						Obj[Key] = Value

						local Direction = Obj.To - Obj.From
						local Center = (Obj.To + Obj.From) / 2
						local Distance = Direction.Magnitude
						local Theta = math.deg(math.atan2(Direction.Y, Direction.X))

						LineFrame.Position = UDim2.fromOffset(Center.X, Center.Y)
						LineFrame.Rotation = Theta
						LineFrame.Size = UDim2.fromOffset(Distance, Obj.Thickness)
					elseif Key == "Thickness" then
						Obj.Thickness = Value
						local Distance = (Obj.To - Obj.From).Magnitude
						LineFrame.Size = UDim2.fromOffset(Distance, Value)
					elseif Key == "Visible" then
						Obj.Visible = Value
						LineFrame.Visible = Value
					elseif Key == "ZIndex" then
						Obj.ZIndex = Value
						LineFrame.ZIndex = Value
					elseif Key == "Transparency" then
						Obj.Transparency = Value
						LineFrame.BackgroundTransparency = ConvertTransparency(Value)
					elseif Key == "Color" then
						Obj.Color = Value
						LineFrame.BackgroundColor3 = Value
					end
				end,
				__index = function(_, Key)
					if Key == "Remove" or Key == "Destroy" then
						return function()
							LineFrame:Destroy()
							Obj:Remove()
						end
					end
					return Obj[Key]
				end,
				__tostring = function() return "Drawing" end,
			})
		elseif Type == "Text" then
			local Obj = MergeTable(BaseDrawingObj, {
				Text = "",
				Font = Drawing.Fonts.UI,
				Size = 14,
				Position = Vector2.zero,
				Center = false,
				Outline = false,
				OutlineColor = Color3.new(0, 0, 0),
			})

			local TextLabel = Instance.new("TextLabel")
			local UIStroke = Instance.new("UIStroke")

			TextLabel.Name = "Text"
			TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
			TextLabel.BorderSizePixel = 0
			TextLabel.BackgroundTransparency = 1
			TextLabel.Visible = Obj.Visible
			TextLabel.TextColor3 = Obj.Color
			TextLabel.TextTransparency = ConvertTransparency(Obj.Transparency)
			TextLabel.ZIndex = Obj.ZIndex
			TextLabel.FontFace = FontEnum[Obj.Font]
			TextLabel.TextSize = Obj.Size
			TextLabel.Text = Obj.Text

			UIStroke.Thickness = 1
			UIStroke.Enabled = Obj.Outline
			UIStroke.Color = Obj.OutlineColor
			UIStroke.Parent = TextLabel

			TextLabel.Parent = DrawingUI

			local updatePosition = function()
				local bounds = TextLabel.TextBounds
				local offsetX = Obj.Center and 0 or bounds.X / 2
				local offsetY = bounds.Y / 2
				local posX = (typeof(Obj.Position) == "Vector2") and Obj.Position.X or 0
				local posY = (typeof(Obj.Position) == "Vector2") and Obj.Position.Y or 0
				local newSize = UDim2.fromOffset(bounds.X, bounds.Y)
				local newPos = UDim2.fromOffset(posX + offsetX, posY + offsetY)

				if TextLabel.Size ~= newSize then
					TextLabel.Size = newSize
				end
				if TextLabel.Position ~= newPos then
					TextLabel.Position = newPos
				end
			end

			return setmetatable({}, {
				__newindex = function(_, Key, Value)
					if Obj.__OBJECT_EXISTS == false then return end
					if Obj[Key] == nil or Obj[Key] == Value then return end

					if Key == "Text" then
						Obj.Text = Value
						TextLabel.Text = Value
						updatePosition()
					elseif Key == "Font" then
						Obj.Font = math.clamp(Value, 0, 3)
						TextLabel.FontFace = FontEnum[Obj.Font]
						updatePosition()
					elseif Key == "Size" then
						Obj.Size = Value
						TextLabel.TextSize = Value
						updatePosition()
					elseif Key == "Position" or Key == "Center" then
						Obj[Key] = Value
						updatePosition()
					elseif Key == "Outline" then
						Obj.Outline = Value
						UIStroke.Enabled = Value
					elseif Key == "OutlineColor" then
						Obj.OutlineColor = Value
						UIStroke.Color = Value
					elseif Key == "Visible" then
						Obj.Visible = Value
						TextLabel.Visible = Value
					elseif Key == "ZIndex" then
						Obj.ZIndex = Value
						TextLabel.ZIndex = Value
					elseif Key == "Transparency" then
						Obj.Transparency = Value
						local transparency = ConvertTransparency(Value)
						TextLabel.TextTransparency = transparency
						UIStroke.Transparency = transparency
					elseif Key == "Color" then
						Obj.Color = Value
						TextLabel.TextColor3 = Value
					end
				end,
				__index = function(_, Key)
					if Key == "Remove" or Key == "Destroy" then
						return function()
							TextLabel:Destroy()
							Obj:Remove()
						end
					elseif Key == "TextBounds" then
						return TextLabel.TextBounds
					end
					return Obj[Key]
				end,
				__tostring = function() return "Drawing" end,
			})
		elseif Type == "Circle" then
			local Obj = MergeTable(BaseDrawingObj, {
				Radius = 75,
				Position = Vector2.zero,
				Thickness = 0.7,
				Filled = false,
			})

			local circleFrame = Instance.new("Frame")
			local uiCorner = Instance.new("UICorner")
			local uiStroke = Instance.new("UIStroke")

			circleFrame.Name = "Circle"
			circleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
			circleFrame.BorderSizePixel = 0

			circleFrame.BackgroundColor3 = Obj.Color
			circleFrame.BackgroundTransparency = (Obj.Filled and ConvertTransparency(Obj.Transparency)) or 1
			circleFrame.Position = UDim2.fromOffset(Obj.Position.X, Obj.Position.Y)
			circleFrame.ZIndex = Obj.ZIndex
			circleFrame.Visible = Obj.Visible

			uiCorner.CornerRadius = UDim.new(1, 0)
			uiCorner.Parent = circleFrame

			uiStroke.Thickness = Obj.Thickness
			uiStroke.Enabled = not Obj.Filled
			uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			uiStroke.Color = Obj.Color
			uiStroke.Transparency = ConvertTransparency(Obj.Transparency)
			uiStroke.Parent = circleFrame

			circleFrame.Size = UDim2.fromOffset(Obj.Radius * 2, Obj.Radius * 2)

			circleFrame.Parent = DrawingUI

			return setmetatable({}, {
				__newindex = function(_, Key, Value)
					if Obj.__OBJECT_EXISTS == false then return end
					if Obj[Key] == nil then return end

					if Key == "Radius" then
						Obj.Radius = Value
						circleFrame.Size = UDim2.fromOffset(Value * 2, Value * 2)
					elseif Key == "Position" then
						Obj.Position = Value
						circleFrame.Position = UDim2.fromOffset(Value.X, Value.Y)
					elseif Key == "Thickness" then
						Obj.Thickness = math.clamp(Value, 0.6, 1e4)
						uiStroke.Thickness = Obj.Thickness
					elseif Key == "Filled" then
						Obj.Filled = Value
						circleFrame.BackgroundTransparency = (Value and ConvertTransparency(Obj.Transparency)) or 1
						uiStroke.Enabled = not Value
					elseif Key == "Visible" then
						Obj.Visible = Value
						circleFrame.Visible = Value
					elseif Key == "Transparency" then
						Obj.Transparency = Value
						local transparency = ConvertTransparency(Value)
						circleFrame.BackgroundTransparency = (Obj.Filled and transparency) or 1
						uiStroke.Transparency = transparency
					elseif Key == "Color" then
						Obj.Color = Value
						circleFrame.BackgroundColor3 = Value
						uiStroke.Color = Value
					elseif Key == "ZIndex" then
						Obj.ZIndex = Value
						circleFrame.ZIndex = Value
					end
				end,
				__index = function(_, Key)
					if Key == "Remove" or Key == "Destroy" then
						return function()
							circleFrame:Destroy()
							Obj:Remove()
						end
					end
					return Obj[Key]
				end,
				__tostring = function() return "Drawing" end,
			})
		elseif Type == "Square" then
			local Obj = MergeTable(BaseDrawingObj, {
				Size = Vector2.new(100, 100),
				Position = Vector2.zero,
				Thickness = 0.7,
				Filled = false,
			})

			local squareFrame = Instance.new("Frame")
			local uiStroke = Instance.new("UIStroke")

			squareFrame.Name = "Square"
			squareFrame.BorderSizePixel = 0
			squareFrame.AnchorPoint = Vector2.new(0, 0)
			squareFrame.BackgroundTransparency = (Obj.Filled and ConvertTransparency(Obj.Transparency)) or 1
			squareFrame.ZIndex = Obj.ZIndex
			squareFrame.BackgroundColor3 = Obj.Color
			squareFrame.Visible = Obj.Visible

			uiStroke.Thickness = Obj.Thickness
			uiStroke.Enabled = not Obj.Filled
			uiStroke.LineJoinMode = Enum.LineJoinMode.Miter
			uiStroke.Color = Obj.Color
			uiStroke.Transparency = ConvertTransparency(Obj.Transparency)

			squareFrame.Size = UDim2.fromOffset(Obj.Size.X, Obj.Size.Y)
			squareFrame.Position = UDim2.fromOffset(Obj.Position.X, Obj.Position.Y)

			squareFrame.Parent = DrawingUI
			uiStroke.Parent = squareFrame

			return setmetatable({}, {
				__newindex = function(_, Key, Value)
					if Obj.__OBJECT_EXISTS == false then return end
					if Obj[Key] == nil then return end

					if Key == "Size" then
						Obj.Size = Value
						squareFrame.Size = UDim2.fromOffset(Value.X, Value.Y)
					elseif Key == "Position" then
						Obj.Position = Value
						squareFrame.Position = UDim2.fromOffset(Value.X, Value.Y)
					elseif Key == "Thickness" then
						Obj.Thickness = math.clamp(Value, 0.6, 1e4)
						uiStroke.Thickness = Obj.Thickness
					elseif Key == "Filled" then
						Obj.Filled = Value
						squareFrame.BackgroundTransparency = (Value and ConvertTransparency(Obj.Transparency)) or 1
						uiStroke.Enabled = not Value
					elseif Key == "Visible" then
						Obj.Visible = Value
						squareFrame.Visible = Value
					elseif Key == "Transparency" then
						Obj.Transparency = Value
						local transparency = ConvertTransparency(Value)
						squareFrame.BackgroundTransparency = (Obj.Filled and transparency) or 1
						uiStroke.Transparency = transparency
					elseif Key == "Color" then
						Obj.Color = Value
						uiStroke.Color = Value
						squareFrame.BackgroundColor3 = Value
					elseif Key == "ZIndex" then
						Obj.ZIndex = Value
						squareFrame.ZIndex = Value
					end
				end,
				__index = function(_, Key)
					if Key == "Remove" or Key == "Destroy" then
						return function()
							squareFrame:Destroy()
							Obj:Remove()
						end
					end
					return Obj[Key]
				end,
				__tostring = function() return "Drawing" end,
			})
		elseif Type == "Image" then
			local Obj = MergeTable(BaseDrawingObj, {
				Data = "",
				Size = Vector2.zero,
				Position = Vector2.zero,
			})

			local imageLabel = Instance.new("ImageLabel")
			imageLabel.Name = "Image"
			imageLabel.BorderSizePixel = 0
			imageLabel.ScaleType = Enum.ScaleType.Stretch
			imageLabel.BackgroundTransparency = 1
			imageLabel.Visible = Obj.Visible
			imageLabel.ZIndex = Obj.ZIndex
			imageLabel.ImageTransparency = ConvertTransparency(Obj.Transparency)
			imageLabel.Parent = DrawingUI

			return setmetatable({}, {
				__newindex = function(_, Key, Value)
					if Obj.__OBJECT_EXISTS == false then return end
					if Obj[Key] == nil then return end
					if Key == "Data" then
						local filename = ".Drawing/CustomAssets/" .. RandomString(5) .. ".png"
						writefile(filename, Value)
						imageLabel.Image = getcustomasset(filename)
						delfile(filename)
					elseif Key == "Size" then
						Obj.Size = Value
						imageLabel.Size = UDim2.fromOffset(Value.X, Value.Y)
					elseif Key == "Position" then
						Obj.Position = Value
						imageLabel.Position = UDim2.fromOffset(Value.X, Value.Y)
					elseif Key == "Visible" then
						Obj.Visible = Value
						imageLabel.Visible = Value
					elseif Key == "ZIndex" then
						Obj.ZIndex = Value
						imageLabel.ZIndex = Value
					elseif Key == "Transparency" then
						Obj.Transparency = Value
						imageLabel.ImageTransparency = ConvertTransparency(Value)
					elseif Key == "Color" then
						Obj.Color = Value
						imageLabel.ImageColor3 = Value
					end
				end,
				__index = function(_, Key)
					if Key == "Remove" or Key == "Destroy" then
						return function()
							imageLabel:Destroy()
							Obj:Remove()
						end
					end
					return Obj[Key]
				end,
				__tostring = function() return "Drawing" end,
			})
		elseif Type == "Quad" then
			local Obj = MergeTable(BaseDrawingObj, {
				Thickness = 1,
				PointA = Vector2.zero,
				PointB = Vector2.zero,
				PointC = Vector2.zero,
				PointD = Vector2.zero,
				Filled = false,
			})

			local PointA = Drawing.new("Line")
			local PointB = Drawing.new("Line")
			local PointC = Drawing.new("Line")
			local PointD = Drawing.new("Line")

			return setmetatable({}, {
				__newindex = function(_, Key, Value)
					if Obj.__OBJECT_EXISTS == false then return end
					if Key == "Thickness" then
						PointA.Thickness = Value
						PointB.Thickness = Value
						PointC.Thickness = Value
						PointD.Thickness = Value
						Obj.Thickness = Value
					elseif Key == "PointA" then
						PointA.From = Value
						PointB.To = Value
						Obj.PointA = Value
					elseif Key == "PointB" then
						PointB.From = Value
						PointC.To = Value
						Obj.PointB = Value
					elseif Key == "PointC" then
						PointC.From = Value
						PointD.To = Value
						Obj.PointC = Value
					elseif Key == "PointD" then
						PointD.From = Value
						PointA.To = Value
						Obj.PointD = Value
					elseif Key == "Visible" then
						PointA.Visible = Value
						PointB.Visible = Value
						PointC.Visible = Value
						PointD.Visible = Value
						Obj.Visible = Value
					elseif Key == "Filled" then
						Obj.Filled = Value -- no filled implementation yet
					elseif Key == "Color" then
						PointA.Color = Value
						PointB.Color = Value
						PointC.Color = Value
						PointD.Color = Value
						Obj.Color = Value
					elseif Key == "ZIndex" then
						PointA.ZIndex = Value
						PointB.ZIndex = Value
						PointC.ZIndex = Value
						PointD.ZIndex = Value
						Obj.ZIndex = Value
					end
				end,
				__index = function(_, Key)
					if Key == "Remove" or Key == "Destroy" then
						return function()
							if Obj.__OBJECT_EXISTS == false then return end
							PointA:Remove()
							PointB:Remove()
							PointC:Remove()
							PointD:Remove()
							Obj:Remove()
						end
					end
					return Obj[Key]
				end,
				__tostring = function() return "Drawing" end,
			})
		elseif Type == "Triangle" then
			local Obj = MergeTable(BaseDrawingObj, {
				Thickness = 1,
				PointA = Vector2.zero,
				PointB = Vector2.zero,
				PointC = Vector2.zero,
				Filled = false,
			})

			local LineAB = Drawing.new("Line")
			local LineBC = Drawing.new("Line")
			local LineCA = Drawing.new("Line")

			return setmetatable({}, {
				__newindex = function(_, Key, Value)
					if Obj.__OBJECT_EXISTS == false then return end
					if Key == "Thickness" then
						LineAB.Thickness = Value
						LineBC.Thickness = Value
						LineCA.Thickness = Value
						Obj.Thickness = Value
					elseif Key == "PointA" then
						LineAB.From = Value
						LineCA.To = Value
						Obj.PointA = Value
					elseif Key == "PointB" then
						LineAB.To = Value
						LineBC.From = Value
						Obj.PointB = Value
					elseif Key == "PointC" then
						LineBC.To = Value
						LineCA.From = Value
						Obj.PointC = Value
					elseif Key == "Visible" then
						LineAB.Visible = Value
						LineBC.Visible = Value
						LineCA.Visible = Value
						Obj.Visible = Value
					elseif Key == "Filled" then
						Obj.Filled = Value -- no filled implementation yet
					elseif Key == "Color" then
						LineAB.Color = Value
						LineBC.Color = Value
						LineCA.Color = Value
						Obj.Color = Value
					elseif Key == "ZIndex" then
						LineAB.ZIndex = Value
						LineBC.ZIndex = Value
						LineCA.ZIndex = Value
						Obj.ZIndex = Value
					end
				end,
				__index = function(_, Key)
					if Key == "Remove" or Key == "Destroy" then
						return function()
							if Obj.__OBJECT_EXISTS == false then return end
							LineAB:Remove()
							LineBC:Remove()
							LineCA:Remove()
							Obj:Remove()
						end
					end
					return Obj[Key]
				end,
				__tostring = function() return "Drawing" end,
			})
		else
			return warn('Unsupported drawing type: \'%s\'', Type)
		end
	end)

	getgenv().isrenderobj = newcclosure(function(Object)
		if typeof(Object) == "userdata" or typeof(Object) == "Instance" or not getmetatable(Object) then
			return false
		end
		if tostring(Object) ~= "Drawing" then
			return false
		end
		local ok, exists = pcall(function()
			return Object.__OBJECT_EXISTS
		end)
		if ok and exists == false then
			return false
		end
		return true
	end)
end
