--v3

if getgenv().esp ~= nil then
    getgenv().esp:Unload();
end

local esp = {
    enabled        = false;
    teamcheck      = false;
    displayname    = false;
    limitdistance  = false;
    boldtext       = false;
    maxdistance    = 1000;
    arrowradius    = 500;
    arrowsize      = 20;
    textfont       = 2;
    textsize       = 13;
    snaplineOrigin = Vector2.new(0,0);
    custombox      = 'default';
    distancemode   = 'meter';
    targets        = {};
    players        = {};
    connections    = {};
    infov          = {};
    outline        = {true, Color3.new(0,0,0)};
    skeleton       = {false, Color3.new(1,1,1), 1};
    box            = {false, Color3.new(1,1,1), 1};
    boxfill        = {false, Color3.new(1,.25,.25), .5};
    tracer         = {false, Color3.new(1,1,1), 1};
    snapline       = {false, Color3.new(1,1,1), 0, 0, 'Head'};
    angle          = {false, Color3.new(1,1,1), 1};
    arrow          = {false, Color3.new(0,1,0), Color3.new(1,0,0), 1, 0.5};
    chams          = {false, Color3.new(1,1,1), Color3.new(1,1,1), 1, 1, true};
    textlayout     = {
        ['Name']     = {Position = 'top', Enabled = false, Color = Color3.new(1,1,1), Transparency = 0};
        ['Distance'] = {Position = 'bottom', Enabled = false, Default = 'NaN', Suffix = 'm', Color = Color3.new(1,1,1), Transparency = 0};
        ['Tool']     = {Position = 'bottom', Enabled = false, Default = 'None', Color = Color3.new(1,1,1), Transparency = 0};
        ['Health']   = {Position = 'left', Enabled = false, IgnoreTarget = true, Default = 'NaN', Color = Color3.new(1,1,1), Transparency = 0};
    };
    barlayout      = {
        ['Health']   = {Position = 'left', Enabled = false, Color1 = Color3.new(1,0,0), Color2 = Color3.new(0,1,0), Transparency = 0};
    };
}
local id = 'tabatha61271s'
local players = game:GetService('Players');
local localPlayer = players.LocalPlayer;
local atan2, min, max, clamp, sin, cos, rad, floor, abs = math.atan2, math.min, math.max, math.clamp, math.sin, math.cos, math.rad, math.floor, math.abs;
local newVector2, newCFrame, newColor3, fromrgb = Vector2.new, CFrame.new, Color3.new, Color3.fromRGB;

function NewDrawing(class, props)
    local d = Drawing.new(class);
    for i,v in next, props or {} do
        d[i] = v;
    end
    return d;
end

function RotateVector2(v2, r)
    local c = math.cos(r);
    local s = math.sin(r);
    return Vector2.new(c * v2.X - s * v2.Y, s * v2.X + c * v2.Y);
end

function FloorVector2(v2)
    return newVector2(floor(v2.X), floor(v2.Y));
end

function ConvertNumberRange(val,oldmin,oldmax,newmin,newmax)
    return (((val - oldmin) * (newmax - newmin)) / (oldmax - oldmin)) + newmin;
end

function SetAll(drawings, prop, val)
    for i,v in next, drawings do
        if (i == 'text' or i == 'bar' or i =='custombox') then
            for _,v2 in next, v do
                v2[1][prop] = val;
                v2[2][prop] = val;
            end
        elseif i ~= 'chams' and i ~= 'arrow' then
            v[prop] = val;
        end
    end
end

function esp:Unload()
    for i,v in next, self.connections do
        v:Disconnect();
    end
    for i,v in next, self.players do
        self:RemovePlayer(i);
    end
	game:GetService('RunService'):UnbindFromRenderStep(id)
    table.clear(esp);
    getgenv().esp = nil;
end

function isAlive(plr)
    if not plr then plr = localPlayer end
    return plr.Character and plr.Character:FindFirstChild('Humanoid') and plr.Character:FindFirstChild('Head') and plr.Character.Humanoid.Health > 0 and true or false
end

function esp:AddPlayer(plr)
    local data = {
        box_fill = NewDrawing('Square', {Filled = true, Thickness = 1});
        angle = NewDrawing('Line', {Thickness = 1});
        box_outline = NewDrawing('Square', {Filled = false, Thickness = 3});
        box = NewDrawing('Square', {Filled = false, Thickness = 1});
        tracer = NewDrawing('Line', {Thickness = 1});
        snapline = NewDrawing('Line', {Thickness = 1});
        arrow = NewDrawing('Triangle', {Filled = true, Thickness = 1, ZIndex = 1});
        arrow_outline = NewDrawing('Triangle', {Filled = false, Thickness = 1, ZIndex = 2});
        chams = Instance.new('Highlight');
        --
        custombox = {};
        text = {};
        bar = {};
        --
        skeleton_spine       = NewDrawing('Line', {Thickness = 1});
        skeleton_leftleg     = NewDrawing('Line', {Thickness = 1});
        skeleton_rightleg    = NewDrawing('Line', {Thickness = 1});
        skeleton_leftknee    = NewDrawing('Line', {Thickness = 1});
        skeleton_rightknee   = NewDrawing('Line', {Thickness = 1});
        skeleton_leftfoot    = NewDrawing('Line', {Thickness = 1});
        skeleton_rightfoot   = NewDrawing('Line', {Thickness = 1});
        skeleton_leftarm     = NewDrawing('Line', {Thickness = 1});
        skeleton_rightarm    = NewDrawing('Line', {Thickness = 1});
        skeleton_leftelbow   = NewDrawing('Line', {Thickness = 1});
        skeleton_rightelbow  = NewDrawing('Line', {Thickness = 1});
        skeleton_lefthand    = NewDrawing('Line', {Thickness = 1});
        skeleton_righthand   = NewDrawing('Line', {Thickness = 1});
    };
    for i,v in next, self.textlayout do
        data.text[i] = {NewDrawing('Text', {ZIndex = 1}), NewDrawing('Text', {ZIndex = 1}), order = v.Order or 0}
    end
    for i,v in next, self.barlayout  do
        data.bar[i] = {NewDrawing('Square', {Filled = true}), NewDrawing('Square', {Filled = true}), order = v.Order or 0};
    end
    for i = 1,8 do
        data.custombox[i] = {NewDrawing('Line', {Thickness = 1, ZIndex = 2}), NewDrawing('Line', {Thickness = 3, ZIndex = 1})};
        data.custombox[i].set = function(prop, val)
            data.custombox[i][1][prop] = val
            data.custombox[i][2][prop] = val
        end
    end


    table.sort(self.textlayout, function(a,b)
        return a.order > b.order
    end)

    table.sort(self.barlayout, function(a,b)
        return a.order > b.order
    end)

    self.players[plr] = data;
end

function esp:RemovePlayer(plr)
    local data = self.players[plr];
    self.players[plr] = nil;
    if data then
        for i,v in next, data do
            if (i == 'text' or i == 'bar' or i =='custombox') then
                for i2,v2 in next, v do
                    v2[1]:Remove();
                    v2[2]:Remove();
                end
            elseif (i == 'chams') then
            else
                v:Remove();
            end
        end
    end
end

function esp.CFrameToViewport(cframe)
    local cam = workspace.CurrentCamera;
    return cam:WorldToViewportPoint(cframe * (cframe - cframe.p):ToObjectSpace(cam.CFrame - cam.CFrame.p).p);
end

function esp.GetDistance(p1, p2)
    local mag = (p1-p2).magnitude;
    if esp.distancemode == 'meter' then
        return (mag / 3);
    end
    return mag
end
function getBoxInfo(character, position)
	local middle = character:FindFirstChild'HumanoidRootPart' and character['HumanoidRootPart'].CFrame or character['Torso'].CFrame
		local smallestX, biggestX = 9e9, -9e9
		local smallestY, biggestY = 9e9, -9e9
		local y      = (middle.p - character['Head'].Position).magnitude + character['Head'].Size.Y / 2
		local x1     = character:FindFirstChild('RightHand')  and (middle.p - character['RightHand'].Position).magnitude or 0
		local x2     = character:FindFirstChild('LeftHand')  and (middle.p - character['LeftHand'].Position).magnitude or 0
		local minY1  = character:FindFirstChild('RightFoot') and (middle.p - character['RightFoot'].Position).magnitude or 0
		local minY2  = character:FindFirstChild('LeftFoot')  and (middle.p - character['LeftFoot'].Position).magnitude or 0
		local minY = minY1 > minY2 and minY1 or minY2
		local minX = x1 < x2 and x1 or x2
		local espOffsets = getOffsets(minX + character['LeftHand'].Size.X / 2, y, minY + character['RightFoot'].Size.Y / 2, character:FindFirstChild'HumanoidRootPart' and character['HumanoidRootPart'].Size.Z or character['Torso'].Size.Z / 2)
		for i, v in next, espOffsets do
			local pos = esp.CFrameToViewport(middle * v)
			if smallestX > pos.X then
				smallestX = pos.X
			end;
			if biggestX < pos.X then
				biggestX = pos.X
			end;
			if smallestY > pos.Y then
				smallestY = pos.Y
			end;
			if biggestY < pos.Y then
				biggestY = pos.Y
			end;
		end
		local position = FloorVector2(newVector2(position.X, position.Y));
		local size = FloorVector2(newVector2(biggestX - smallestX, biggestY - smallestY));
		position = position - FloorVector2(size / 2);
		local bottom = position + newVector2(size.X / 2, size.Y);
		return position, size, bottom
end
function esp.GetPlayerData(player)
    local character = player.Character;
	local screenPos, onScreen = esp.CFrameToViewport(character.HumanoidRootPart.CFrame)
    local cframe, size = getBoxInfo(character, screenPos);
    local status = isAlive(player)
    return {
        angleorigin = character:FindFirstChild('Head') and character.Head.CFrame or nil,
        snaplineCFrame = character:FindFirstChild(esp.snapline[5]) and character:FindFirstChild(esp.snapline[5]).CFrame or nil,
        cframe = character:FindFirstChild('HumanoidRootPart') and character.HumanoidRootPart.CFrame,
        size = size,
        health = character.Humanoid.Health,
        maxhealth = character.Humanoid.MaxHealth,
        model = character;
        live = status;
        tool = '';
    }
end

function esp.GetPlayerOptionInfo(player, playerdata)
    return
    {
        ['Name'] = {text = esp.displayname and player.DisplayName or player.Name};
        ['Distance'] = {text = floor(esp.GetDistance(playerdata.cframe.p, workspace.CurrentCamera.CFrame.p))};
        ['Tool'] = {text = ''};
        ['Health'] = {text = floor(playerdata.health), color = esp.barlayout.Health.Color1:Lerp(esp.barlayout.Health.Color2, playerdata.health / playerdata.maxhealth)};
    },
    {
        ['Health'] = {value = playerdata.health, min = 0, max = playerdata.maxhealth, color = esp.barlayout.Health.Color1:Lerp(esp.barlayout.Health.Color2, playerdata.health / playerdata.maxhealth)};
    }
end

function esp.GetTeam(player)
    return player.Team
end

function esp.Check(player)
    if player == players.LocalPlayer then return false end
    local pass = true;
    local character = player.Character;

    if not (character and character.PrimaryPart ~= nil and character:FindFirstChild('Humanoid') and character:FindFirstChild('Head') and character:FindFirstChild('LeftUpperArm') and character.Humanoid.Health >= 0 and character.LeftUpperArm.Transparency == 0) then
        pass = false;
    elseif (esp.limitdistance and (character.PrimaryPart.CFrame.p - workspace.CurrentCamera.CFrame.p).magnitude > esp.maxdistance) then
        pass = false;
    elseif (esp.teamcheck and (esp.GetTeam(player) == esp.GetTeam(localPlayer))) then
        pass = false;
    end

    return pass;
end

function getOffsets(x,y,minY,z)
    return {CFrame.new(x,y,z),CFrame.new(-x,y,z),CFrame.new(x,y,-z),CFrame.new(-x,y,-z),CFrame.new(x,-minY,z),CFrame.new(-x,-minY,z),CFrame.new(x,-minY,-z),CFrame.new(-x,-minY,-z)}
end

function getpos(pos)
    return Vector2.new(pos.X, pos.Y)
end

function connectLine(bone, to, from)
	bone.To = to
	bone.From = from
	bone.Visible = esp.skeleton[1]
	bone.Color = esp.skeleton[2]
	bone.Transparency = esp.skeleton[3]
end

game:GetService('RunService'):BindToRenderStep(id,  9999,  function()
	local camera = workspace.CurrentCamera;
	for player, drawings in next, esp.players do
		local check, data = isAlive(player) and esp.Check(player) and esp.enabled == true, nil;
		local screenPos, onScreen;
		if check then
			data = esp.GetPlayerData(player);
			screenPos, onScreen = esp.CFrameToViewport(data.cframe);
		end
		if not (check and onScreen) then
			SetAll(drawings, 'Visible', false);
		end
		drawings.arrow.Visible = esp.arrow[1] and check;
		drawings.arrow_outline.Visible = drawings.arrow.Visible;
		if drawings.arrow.Visible then
			local proj = camera.CFrame:PointToObjectSpace(data.cframe.p);
			local ang  = atan2(proj.Z, proj.X);
			local dir  = newVector2(cos(ang), sin(ang));
			local a    = (dir * esp.arrowradius * .5) + camera.ViewportSize / 2;
			local b, c = a - RotateVector2(dir, rad(35)) * esp.arrowsize, a - RotateVector2(dir, -rad(35)) * esp.arrowsize
			drawings.arrow.PointA = a;
			drawings.arrow.PointB = b;
			drawings.arrow.PointC = c;
			drawings.arrow.Color  = not onScreen and esp.arrow[3] or esp.arrow[2];
			drawings.arrow.Transparency = not onScreen and 1 - esp.arrow[5] or 1 - esp.arrow[4];
			drawings.arrow_outline.PointA = a;
			drawings.arrow_outline.PointB = b;
			drawings.arrow_outline.PointC = c;
			drawings.arrow_outline.Color  = not onScreen and esp.arrow[3] or esp.arrow[2];
			drawings.arrow_outline.Transparency = not onScreen and 1 - esp.arrow[5] or 1 - esp.arrow[4];
		end
		drawings.chams.Enabled             = check and esp.chams[1];
		drawings.chams.Adornee             = check and esp.chams[1] and data.model or nil;
		drawings.chams.Parent              = check and data.live and esp.chams[1] and data.model or nil;
		if drawings.chams.Enabled then
			drawings.chams.FillColor           = esp.chams[2];
			drawings.chams.OutlineColor        = esp.chams[3];
			drawings.chams.FillTransparency    = esp.chams[4];
			drawings.chams.OutlineTransparency = esp.chams[5];
			drawings.chams.DepthMode           = esp.chams[6] and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded;
		end
		if not check or not onScreen then
			continue
		end
		local character = data.model
		local transparency = esp.limitdistance and (1 - clamp(ConvertNumberRange(floor((data.cframe.p - camera.CFrame.p).magnitude), esp.maxdistance - 150, esp.maxdistance, 0, 1), 0, 1)) or 1;
		local color = esp.targets[player];
		local textinfo, barinfo = esp.GetPlayerOptionInfo(player, data);
		local position, size, bottom = getBoxInfo(character, screenPos)
		local barsizepixel    = 3;
		local padding         = 1;
		local topOptionPos    = 1;
		local bottomOptionPos = 1;
		local leftTextPos     = 0;
		local rightTextPos    = 0;
		local leftBarPos      = 1;
		local rightBarPos     = 1;
		drawings.box.Visible = esp.box[1] and esp.custombox == 'default';
		drawings.box_fill.Visible = esp.box[1] and esp.boxfill[1];
		drawings.box_outline.Visible = drawings.box.Visible and esp.outline[1];
		if esp.box[1] then
			drawings.box.Size = size;
			drawings.box.Position = position;
			drawings.box.Color = color or esp.box[2];
			drawings.box.Transparency = min(esp.box[3], transparency);
			drawings.box_outline.Size = size;
			drawings.box_outline.Position = position;
			drawings.box_outline.Color = esp.outline[2];
			drawings.box_outline.Transparency = min(esp.box[3], transparency);
			drawings.box_fill.Size = size;
			drawings.box_fill.Position = position;
			drawings.box_fill.Color = color or esp.boxfill[2];
			drawings.box_fill.Transparency = min(esp.boxfill[3], transparency)
			if esp.custombox == 'corner' then -- this is actually so fucking stupid idk why im doing this LOL
                    -- top left
				drawings.custombox[1][1].From = position + newVector2(0, 0);
				drawings.custombox[1][1].To   = position + newVector2(size.X / 3, 0);
				drawings.custombox[1][2].From = position + newVector2(-1, 0);
				drawings.custombox[1][2].To   = position + newVector2(size.X / 3 + 1, 0);
                    
                    -- top right
				drawings.custombox[2][1].From = position + newVector2(size.X, 0);
				drawings.custombox[2][1].To   = position + newVector2(size.X - size.X / 3, 0);
				drawings.custombox[2][2].From = position + newVector2(size.X + 1, 0);
				drawings.custombox[2][2].To   = position + newVector2(size.X - size.X / 3 - 1, 0);
                    
                    -- bottom left
				drawings.custombox[3][1].From = position + newVector2(0, size.Y - 1);
				drawings.custombox[3][1].To   = position + newVector2(size.X / 3, size.Y - 1);
				drawings.custombox[3][2].From = position + newVector2(-1, size.Y - 1);
				drawings.custombox[3][2].To   = position + newVector2(size.X / 3 + 1, size.Y - 1);
                    
                    -- bottom right
				drawings.custombox[4][1].From = position + newVector2(size.X, size.Y - 1);
				drawings.custombox[4][1].To   = position + newVector2(size.X - size.X / 3, size.Y - 1);
				drawings.custombox[4][2].From = position + newVector2(size.X + 1, size.Y - 1);
				drawings.custombox[4][2].To   = position + newVector2(size.X - size.X / 3 - 1, size.Y - 1);
                    
                    -- left top
				drawings.custombox[5][1].From = position
				drawings.custombox[5][1].To   = position + newVector2(0, size.Y / 3);
				drawings.custombox[5][2].From = position
				drawings.custombox[5][2].To   = position + newVector2(0, size.Y / 3 + 1);
                    
                    -- right top
				drawings.custombox[6][1].From = position + newVector2(size.X, 0);
				drawings.custombox[6][1].To   = position + newVector2(size.X, size.Y / 3);
				drawings.custombox[6][2].From = position + newVector2(size.X, -1);
				drawings.custombox[6][2].To   = position + newVector2(size.X, size.Y / 3 + 1);
                    
                    -- left bottom
				drawings.custombox[7][1].From = position + newVector2(0, size.Y );
				drawings.custombox[7][1].To   = position + newVector2(0, size.Y - size.Y / 3);
				drawings.custombox[7][2].From = position + newVector2(0, size.Y );
				drawings.custombox[7][2].To   = position + newVector2(0, size.Y - size.Y / 3 - 1);
                    
                    -- right bottom
				drawings.custombox[8][1].From = position + newVector2(size.X, size.Y);
				drawings.custombox[8][1].To   = position + newVector2(size.X, size.Y - size.Y / 3);
				drawings.custombox[8][2].From = position + newVector2(size.X, size.Y + 1);
				drawings.custombox[8][2].To   = position + newVector2(size.X, size.Y - size.Y / 3 - 1);
				for i, v in next, drawings.custombox do
					v[1].Transparency = min(esp.box[3], transparency);
					v[2].Transparency = min(esp.box[3], transparency);
					v[1].Visible = true;
					v[2].Visible = esp.outline[1];
					v[1].Color = color or esp.box[2];
					v[2].Color = esp.outline[2];
				end
			elseif esp.custombox == 'trans' then
				for i = 1, 8 do
					local drawing = drawings.custombox[i]
					if i == 7 or i == 8 then
						drawing.set('From', position + newVector2(0, i == 8 and size.Y or 0))
						drawing.set('To', position + newVector2(size.X + 1, i == 8 and size.Y or 0))
						drawing[1].Color = fromrgb(90, 200, 250);
						drawing[2].Color = esp.outline[2];
						drawing[1].Transparency = min(esp.box[3], transparency);
						drawing[2].Transparency = min(esp.box[3], transparency);
					else
						local left = i == 1 or i == 2 or i == 3
						local pos = i % 3
						drawing.set('From', position + newVector2(left and 0 or size.X, size.Y / 3 + ((pos - 1) * size.Y / 3)));
						drawing.set('To', position + newVector2(left and 0 or size.X, size.Y / 3 + (pos * size.Y / 3)));
						drawing[1].Color = pos == 1 and fromrgb(255, 255, 255) or fromrgb(255, 135, 255);
						drawing[1].Transparency = min(esp.box[3], transparency);
						drawing[2].Transparency = min(esp.box[3], transparency);
					end
					drawing[1].Visible = true;
					drawing[2].Visible = esp.outline[1];
				end
				drawings.custombox[7][2].From = position + newVector2(-1, 0)
				drawings.custombox[7][2].To   = position + newVector2(size.X + 2, 0)
				drawings.custombox[8][2].From = position + newVector2(-1, size.Y)
				drawings.custombox[8][2].To   = position + newVector2(size.X + 2, size.Y)
			elseif drawings.custombox[1][1].Transparency ~= 0 then
				for i = 1, 8 do
					local drawing = drawings.custombox[i]
					drawing[1].Transparency = 0
					drawing[2].Transparency = 0
				end
			end
		elseif drawings.custombox[1][1].Visible then
			for i = 1, 8 do
				local drawing = drawings.custombox[i]
				drawing[1].Visible = false;
				drawing[2].Visible = false;
			end
		end
		for i, v in next, drawings do
			local split = string.split(i, '_')
			if split[1] == 'skeleton' then
				v.Visible = esp.skeleton[1]
			end
		end
		if esp.skeleton[1] then
			local TopTorso      = getpos(camera:WorldToViewportPoint(character.Head.Position - Vector3.new(0, 0.7, 0)))
			local BottomTorso   = getpos(camera:WorldToViewportPoint(character.LowerTorso.Position - Vector3.new(0, 0.2, 0)))
			local RightLeg      = getpos(camera:WorldToViewportPoint(character.RightUpperLeg.Position + Vector3.new(0, 0.2, 0)))
			local LeftLeg       = getpos(camera:WorldToViewportPoint(character.LeftUpperLeg.Position + Vector3.new(0, 0.2, 0)))
			local RightKnee     = getpos(camera:WorldToViewportPoint(character.RightLowerLeg.Position + Vector3.new(0, 0.2, 0)))
			local LeftKnee      = getpos(camera:WorldToViewportPoint(character.LeftLowerLeg.Position + Vector3.new(0, 0.2, 0)))
			local LeftFoot      = getpos(camera:WorldToViewportPoint(character.LeftFoot.Position))
			local RightFoot     = getpos(camera:WorldToViewportPoint(character.RightFoot.Position))
			local LeftArm       = getpos(camera:WorldToViewportPoint(character.LeftUpperArm.Position + Vector3.new(0, 0.2, 0)))
			local RightArm      = getpos(camera:WorldToViewportPoint(character.RightUpperArm.Position + Vector3.new(0, 0.2, 0)))
			local LeftElbow     = getpos(camera:WorldToViewportPoint(character.LeftLowerArm.Position + Vector3.new(0, 0.2, 0)))
			local RightElbow    = getpos(camera:WorldToViewportPoint(character.RightLowerArm.Position + Vector3.new(0, 0.2, 0)))
			local LeftHand      = getpos(camera:WorldToViewportPoint(character.LeftHand.Position))
			local RightHand     = getpos(camera:WorldToViewportPoint(character.RightHand.Position))

			connectLine(drawings.skeleton_spine, TopTorso, BottomTorso)
			connectLine(drawings.skeleton_rightarm, TopTorso, RightArm)
			connectLine(drawings.skeleton_rightelbow, RightArm, RightElbow)
			connectLine(drawings.skeleton_righthand, RightElbow, RightHand)
			connectLine(drawings.skeleton_rightleg, BottomTorso, RightLeg)
			connectLine(drawings.skeleton_rightknee, RightLeg, RightKnee)
			connectLine(drawings.skeleton_rightfoot, RightKnee, RightFoot)
			connectLine(drawings.skeleton_leftarm, TopTorso, LeftArm)
			connectLine(drawings.skeleton_leftelbow, LeftArm, LeftElbow)
			connectLine(drawings.skeleton_lefthand, LeftElbow, LeftHand)
			connectLine(drawings.skeleton_leftleg, BottomTorso, LeftLeg)
			connectLine(drawings.skeleton_leftknee, LeftLeg, LeftKnee)
			connectLine(drawings.skeleton_leftfoot, LeftKnee, LeftFoot)
		end
		drawings.tracer.Visible = esp.tracer[1];
		if esp.tracer[1] then
			drawings.tracer.From  = newVector2(camera.ViewportSize.X / 2, camera.ViewportSize.Y);
			drawings.tracer.To = bottom;
			drawings.tracer.Color = esp.tracer[2];
			drawings.tracer.Transparency = min(esp.tracer[3], transparency);
		end
		drawings.angle.Visible = esp.angle[1] and data.angleorigin ~= nil;
		if esp.angle[1] and data.angleorigin ~= nil then
			local from, fromVis = esp.CFrameToViewport(data.angleorigin)
			local to, toVis = esp.CFrameToViewport(data.angleorigin + (data.angleorigin.lookVector * 10));
			drawings.angle.Visible = fromVis and toVis;
			drawings.angle.From = newVector2(from.X, from.Y);
			drawings.angle.To = newVector2(to.X, to.Y);
			drawings.angle.Color = color or esp.angle[2];
			drawings.angle.Transparency = min(esp.angle[3], transparency);
		end
		drawings.snapline.Visible = esp.snapline[1] and esp.infov[player] == true and data.snaplineCFrame ~= nil;
		if drawings.snapline.Visible then
			local to, toVis = esp.CFrameToViewport(data.snaplineCFrame);
			drawings.snapline.Visible = toVis;
			drawings.snapline.From = esp.snaplineOrigin;
			drawings.snapline.To = newVector2(to.X, to.Y);
			drawings.snapline.Color = color or esp.snapline[2];
			drawings.snapline.Transparency = min(color == nil and esp.snapline[3] or esp.snapline[4], transparency);
		end
		for name, default in next, esp.barlayout do
			local drawing = drawings.bar[name];
			local barinfo = barinfo[name]
			if drawing ~= nil and barinfo ~= nil then
				local barpos = default.Position:lower();
				local vert = (barpos == 'left' or barpos == 'right')
				drawing[1].Visible = default.Enabled == true and esp.outline[1];
				drawing[2].Visible = default.Enabled == true
				if drawing[2].Visible then
					drawing[1].Color = esp.outline[2];
					drawing[2].Color = barinfo.Color or (default.Color1 ~= nil and default.Color2 ~= nil) and default.Color1:Lerp(default.Color2, (barinfo.value or default.Value or 0) / (barinfo.max or default.Max or 100)) or newColor3(1, 1, 1);
					drawing[1].Transparency = transparency;
					drawing[2].Transparency = transparency;
					drawing[1].Size = vert and newVector2(barsizepixel, size.Y + 2) or newVector2(size.X + 2, barsizepixel);
					drawing[1].Position = position + (
                            barpos == 'left' and newVector2(- padding - barsizepixel - leftBarPos, -1) or
                            barpos == 'right' and newVector2(size.X + padding + rightBarPos, -1) or
                            barpos == 'top' and newVector2(-1, - padding - barsizepixel - topOptionPos) or
                            newVector2(-1, size.Y + padding + bottomOptionPos)
                        )
					local barSize = ConvertNumberRange(barinfo.value or 0, barinfo.min or 0, barinfo.max or 100, 0, (vert and drawing[1].Size.Y or drawing[1].Size.X) - 2);
					drawing[2].Position = drawing[1].Position + newVector2(1, 1) + (vert and newVector2(0, drawing[1].Size.Y - 2 - barSize) or newVector2(0, 0));
					drawing[2].Size     = vert and newVector2(barsizepixel - 2, barSize) or newVector2(barSize, barsizepixel - 2)
					if barpos == 'left'       then
						leftBarPos = leftBarPos + padding + barsizepixel
					elseif barpos == 'right'  then
						rightBarPos = rightBarPos + padding + barsizepixel
					elseif barpos == 'top'    then
						topOptionPos = topOptionPos + padding + barsizepixel
					elseif barpos == 'bottom' then
						bottomOptionPos = bottomOptionPos + padding + barsizepixel
					end
				end
			end
		end
		for name, default in next, esp.textlayout do
			local drawing = drawings.text[name];
			local textinfo = textinfo[name];
			if drawing ~= nil and textinfo ~= nil then
				drawing[1].Visible = default.Enabled
				drawing[2].Visible = drawing[1].Visible and esp.boldtext;
				if drawing[1].Visible then
					drawing[1].Text         = tostring(textinfo.text ~= nil and textinfo.text or default.Default or name) .. (typeof(default.Suffix) == 'string' and default.Suffix or '');
					drawing[1].Color        = (not default.IgnoreTarget and color or nil) or textinfo.color or default.Color or newColor3(1, 1, 1);
					drawing[1].Transparency = transparency;
					drawing[1].Center       = (default.Position == 'top' or default.Position == 'bottom')
					drawing[1].Outline      = esp.outline[1];
					drawing[1].OutlineColor = esp.outline[2];
					drawing[1].Font         = esp.textfont;
					drawing[1].Size         = esp.textsize;
					local textBounds = drawing[1].TextBounds;
					drawing[1].Position = position + (
                            default.Position == 'top'    and newVector2(size.X / 2, - (textBounds.Y + padding + topOptionPos)) or
                            default.Position == 'bottom' and newVector2(size.X / 2, size.Y + padding + bottomOptionPos) or
                            default.Position == 'left'   and newVector2(-(textBounds.X + padding + leftBarPos + (esp.outline[1] and 2 or 0)), - (2 + padding) + leftTextPos + padding) or
                            newVector2(size.X + padding + rightBarPos + (esp.outline[1] and 2 or 0), - (2 + padding) + rightTextPos + padding)
                        )
					if drawing[2].Visible then
						drawing[2].Position     = drawing[1].Position + newVector2(1, 0);
						drawing[2].Transparency = drawing[1].Transparency
						drawing[2].Color        = drawing[1].Color;
						drawing[2].OutlineColor = drawing[1].OutlineColor;
						drawing[2].Size         = drawing[1].Size;
						drawing[2].Text         = drawing[1].Text;
						drawing[2].Font         = drawing[1].Font;
						drawing[2].Center       = drawing[1].Center;
						drawing[2].Outline      = false
					end
					if default.Position == 'top' then
						topOptionPos = topOptionPos + padding + textBounds.Y
					elseif default.Position == 'bottom' then
						bottomOptionPos = bottomOptionPos + padding + textBounds.Y
					elseif default.Position == 'left' then
						leftTextPos = leftTextPos + padding + textBounds.Y
					elseif default.Position == 'right' then
						rightBarPos = rightBarPos + padding + textBounds.Y
					end
				end
			end
		end
	end
end)

table.insert(esp.connections, players.PlayerAdded:Connect(function(plr)
	esp:AddPlayer(plr);
end))
table.insert(esp.connections, players.PlayerRemoving:Connect(function(plr)
	esp:RemovePlayer(plr);
end))
for i, v in next, players:GetPlayers() do
	esp:AddPlayer(v);
end

getgenv().esp = esp;
return esp;
