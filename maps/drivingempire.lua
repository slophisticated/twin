--[[
    2 Tab UI with AutoFarm Integration
    Tab 1: AutoFarm Controls
    Tab 2: Settings (kosong untuk sekarang)
]]

-- ======= AUTOFARM LOGIC MODULE =======
local AutoFarmLogic = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Variables
AutoFarmLogic.IsRunning = false
AutoFarmLogic.CurrentSpeed = 710
AutoFarmLogic.Player = Players.LocalPlayer

-- Points
local PointA = CFrame.new(-18158.0664, 34.5178947, -454.243683, 0.89404887, -0.000757645816, 0.447968811, 6.20140418e-06, 0.999998569, 0.00167891255, -0.447969437, -0.0014982518, 0.894047618)
local PointB = CFrame.new(-34492.1211, 34.3485794, -32842.832, -0.934907079, 0.00187035452, -0.354887635, 0.000956334639, 0.999995768, 0.0027509057, 0.35489127, 0.00223244983, -0.934904933)

-- Internal variables
local heartbeatConn = nil
local wasInFront = nil
local justTeleported = false
local currentTarget = PointB
local printTimer = 0

-- Private function: Teleport vehicle
local function teleportVehicle(targetCFrame, vehicle)
    pcall(function()
        local chassis = vehicle.PrimaryPart
        if not chassis then return end
        
        chassis.Anchored = true
        
        pcall(function() vehicle:PivotTo(targetCFrame) end)
        pcall(function() vehicle:SetPrimaryPartCFrame(targetCFrame) end)
        chassis.CFrame = targetCFrame
        
        chassis.Velocity = Vector3.zero
        chassis.RotVelocity = Vector3.zero
        if chassis.AssemblyLinearVelocity then
            chassis.AssemblyLinearVelocity = Vector3.zero
            chassis.AssemblyAngularVelocity = Vector3.zero
        end
        
        wait(0.15)
        chassis.Anchored = false
    end)
end

-- Set speed
function AutoFarmLogic:SetSpeed(speed)
    self.CurrentSpeed = math.clamp(speed, 100, 710)
    print("⚙️ Speed set to: " .. self.CurrentSpeed .. " studs/s")
end

-- Start autofarm
function AutoFarmLogic:Start(teleportPosition)
    if self.IsRunning then
        warn("⚠️ AutoFarm already running!")
        return
    end
    
    print("🚗 AutoFarm STARTING...")
    
    -- ========== TELEPORT TO POINT A FIRST ==========
    local char = self.Player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
            local vehicleSeat = hum.SeatPart
            local vehicleModel = vehicleSeat.Parent
            
            if vehicleModel and vehicleModel.PrimaryPart then
                local pp = vehicleModel.PrimaryPart
                
                print("📍 Teleporting to Point A...")
                
                -- Simpan velocity
                local oldVel = pp.AssemblyLinearVelocity or Vector3.zero
                local oldAng = pp.AssemblyAngularVelocity or Vector3.zero
                
                -- Teleport ke Point A
                pcall(function() vehicleModel:PivotTo(PointA) end)
                
                -- Restore velocity
                pp.AssemblyLinearVelocity = oldVel
                pp.AssemblyAngularVelocity = oldAng
                
                print("✅ Teleported to Point A!")
                
                -- Wait sebentar biar settle
                task.wait(0.3)
            else
                warn("⚠️ Vehicle PrimaryPart not found! Skipping teleport.")
            end
        else
            warn("⚠️ Not in vehicle! Skipping teleport.")
        end
    end
    
    -- ========== START AUTOFARM LOOP ==========
    self.IsRunning = true
    currentTarget = PointB
    wasInFront = nil
    justTeleported = false
    printTimer = 0
    
    print("🚗 AutoFarm STARTED!")
    print("   Speed: " .. self.CurrentSpeed .. " studs/s")
    print("   Target: Point B")
    
    -- Main loop
    heartbeatConn = RunService.Heartbeat:Connect(function(dt)
        if not self.IsRunning then
            return
        end
        
        pcall(function()
            printTimer = printTimer + dt
            
            local char = self.Player.Character
            if not char then return end
            
            local hum = char:FindFirstChild("Humanoid")
            if not hum then return end
            
            local seat = hum.SeatPart
            if not seat or not seat:IsA("VehicleSeat") then
                return
            end
            
            local vehicle = seat.Parent
            local chassis = vehicle.PrimaryPart
            if not chassis then return end
            
            local pos = chassis.Position
            local targetPos = currentTarget.Position
            local toTarget = targetPos - pos
            local distance = toTarget.Magnitude
            
            -- Force move car
            local flatDir = Vector3.new(toTarget.X, 0, toTarget.Z)
            if flatDir.Magnitude > 1 then
                flatDir = flatDir.Unit
                
                -- Set velocity
                if chassis.AssemblyLinearVelocity then
                    chassis.AssemblyLinearVelocity = flatDir * self.CurrentSpeed
                else
                    chassis.Velocity = flatDir * self.CurrentSpeed
                end
                
                -- Set rotation
                local targetCFrame = CFrame.lookAt(pos, pos + flatDir)
                chassis.CFrame = chassis.CFrame:Lerp(targetCFrame, 0.15)
            end
            
            -- Crossing detection
            local carForward = chassis.CFrame.LookVector
            local toTargetDir = toTarget.Unit
            local dot = carForward:Dot(toTargetDir)
            
            local isInFront = dot > 0
            
            -- Detect crossing
            if wasInFront == true and isInFront == false and not justTeleported then
                print("🔥 CROSSED TARGET! Teleporting...")
                
                justTeleported = true
                
                local teleportTarget = (currentTarget == PointB) and PointB or PointA
                local nextTarget = (currentTarget == PointB) and PointA or PointB
                
                teleportVehicle(teleportTarget, vehicle)
                
                currentTarget = nextTarget
                wasInFront = nil
                
                print("✅ Teleported! Next target: " .. (currentTarget == PointB and "Point B" or "Point A"))
                
                task.delay(3, function()
                    justTeleported = false
                end)
            end
            
            -- Update state
            if wasInFront == nil and not justTeleported then
                wasInFront = isInFront
            elseif not justTeleported then
                wasInFront = isInFront
            end
            
            -- Print stats every 5 seconds
            if printTimer >= 5 then
                printTimer = 0
                local targetName = (currentTarget == PointB) and "Point B" or "Point A"
                print("📊 To " .. targetName .. ": " .. math.floor(distance) .. " studs | Speed: " .. self.CurrentSpeed)
            end
        end)
    end)
end

-- Stop autofarm
function AutoFarmLogic:StopAutoDrive()
    if not self.IsRunning then
        warn("⚠️ AutoFarm not running!")
        return
    end
    
    self.IsRunning = false
    
    if heartbeatConn then
        heartbeatConn:Disconnect()
        heartbeatConn = nil
    end
    
    wasInFront = nil
    justTeleported = false
    
    print("🛑 AutoFarm STOPPED!")
end

-- Cleanup on character removing
AutoFarmLogic.Player.CharacterRemoving:Connect(function()
    if AutoFarmLogic.IsRunning then
        AutoFarmLogic:StopAutoDrive()
    end
end)

print("✅ AutoFarm Logic loaded!")

-- ======= WINDUI SETUP =======
-- Load WindUI Library
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Create Window
local Window = WindUI:CreateWindow({
    Title = "AutoFarm Hub",
    Icon = "rbxassetid://10723415903",
    Author = "Your Name",
    Folder = "AutoFarmConfig",
    Size = UDim2.fromOffset(400, 360),
    KeySystem = false,
    Transparent = false,
    Theme = "Dark",
    SideBarWidth = 170,
})

local Tab1 = Window:Tab({
    Title = "AutoFarm Panels",
    Icon = "car",
})

-- Create Tab 2 - AutoFarm
local Tab2 = Window:Tab({
    Title = "AutoFarm",
    Icon = "zap",
})

-- Create Tab 3 - Settings
local Tab3 = Window:Tab({
    Title = "Settings", 
    Icon = "settings",
})

local Tab1Section = Tab1:Section({
    Title = "AutoFarm Panels"
})

-- ====================
-- TAB 2: AUTOFARM
-- ====================

local Tab2Section = Tab2:Section({
    Title = "AutoFarm Controls"
})

-- Speed variable
local currentSpeed = 710

-- Start/Stop Toggle
Tab2Section:Toggle({
    Title = "Start AutoFarm",
    Default = false,
    Callback = function(toggled)
        if toggled then
            if not AutoFarmLogic.IsRunning then
                AutoFarmLogic:SetSpeed(currentSpeed)
                AutoFarmLogic:Start(Vector3.new(0, 10, 0))
                WindUI:Notification({
                    Title = "AutoFarm Started",
                    Description = "Auto-drive is running...",
                    Duration = 2
                })
            end
        else
            if AutoFarmLogic.IsRunning then
                AutoFarmLogic:StopAutoDrive()
                WindUI:Notification({
                    Title = "AutoFarm Stopped",
                    Description = "Auto-drive stopped.",
                    Duration = 2
                })
            end
        end
    end
})

for _,v in pairs(getconnections(game.Players.LocalPlayer.Idled)) do
    v:Disable()
end

print("AutoFarm UI loaded successfully!")