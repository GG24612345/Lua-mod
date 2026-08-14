-- [[ Desync Definitivo - Toggle e SetState Corrigidos ]] --

local function InitializeDesync()
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera
    local Player = Players.LocalPlayer

    local Controls = nil
    pcall(function()
        local PlayerModule = require(Player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
        Controls = PlayerModule:GetControls()
    end)

    local isModeOn = false
    local teleportOnClose = true
    local originalCF = nil 

    local RealChar = nil
    local FakeChar = nil
    local Connections = {} 
    local AnimTracks = {} 

    local OfficialIDs = {
        Idle  = "rbxassetid://507766388",
        Walk  = "rbxassetid://507777826",
        Run   = "rbxassetid://507767714",
        Jump  = "rbxassetid://507765000",
        Fall  = "rbxassetid://507767968"
    }

    local function LoadAnim(hum, id)
        local a = Instance.new("Animation")
        a.AnimationId = id
        return hum:LoadAnimation(a)
    end

    local function StopAll()
        for _, track in pairs(AnimTracks) do
            if track and track.IsPlaying then track:Stop(0.1) end
        end
    end

    local function CleanupOldClones()
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name == "God_Clone" then
                obj:Destroy()
            end
        end
    end

    local function SetState(state)
        local targetState = state and true or false
        if targetState == isModeOn then return end
        isModeOn = targetState

        if not isModeOn then
            -- [ DESLIGAR / VOLTAR AO SYNC ] --
            for _, conn in pairs(Connections) do 
                if conn then conn:Disconnect() end 
            end
            Connections = {}
            StopAll()
            
            local lastCF = nil
            if FakeChar then
                pcall(function()
                    lastCF = FakeChar:GetPrimaryPartCFrame()
                end)
                FakeChar:Destroy()
                FakeChar = nil
            end
            
            RealChar = Player.Character
            if RealChar and RealChar:FindFirstChild("HumanoidRootPart") then
                local hrp = RealChar.HumanoidRootPart
                local hum = RealChar:FindFirstChild("Humanoid")
                
                hrp.Anchored = false
                if teleportOnClose and lastCF then
                    hrp.CFrame = lastCF
                elseif originalCF then
                    hrp.CFrame = originalCF
                end
                
                if hum then
                    Camera.CameraSubject = hum
                end
            end
            
            CleanupOldClones()
        else
            -- [ LIGAR / ATIVAR DESYNC ] --
            RealChar = Player.Character
            if not RealChar or not RealChar:FindFirstChild("HumanoidRootPart") or not RealChar:FindFirstChild("Humanoid") then 
                isModeOn = false
                return 
            end
            
            CleanupOldClones()
            
            originalCF = RealChar.HumanoidRootPart.CFrame
            RealChar.Archivable = true
            FakeChar = RealChar:Clone()
            FakeChar.Name = "God_Clone"
            FakeChar.Parent = workspace
            
            RealChar.HumanoidRootPart.Anchored = true
            
            local fakeHum = FakeChar:FindFirstChild("Humanoid")
            local fakeRoot = FakeChar:FindFirstChild("HumanoidRootPart")
            
            if not fakeHum or not fakeRoot then
                isModeOn = false
                if FakeChar then FakeChar:Destroy() end
                RealChar.HumanoidRootPart.Anchored = false
                return
            end
            
            for _, v in pairs(FakeChar:GetDescendants()) do
                if v:IsA("LocalScript") or v:IsA("Script") then v:Destroy() end
                if v:IsA("BasePart") then
                    v.Anchored = false
                    v.CanCollide = (v.Name == "HumanoidRootPart")
                    if v.Name == "HumanoidRootPart" then v.Transparency = 1 end
                end
            end

            AnimTracks.Idle  = LoadAnim(fakeHum, OfficialIDs.Idle)
            AnimTracks.Walk  = LoadAnim(fakeHum, OfficialIDs.Walk)
            AnimTracks.Run   = LoadAnim(fakeHum, OfficialIDs.Run)
            AnimTracks.Jump  = LoadAnim(fakeHum, OfficialIDs.Jump)
            AnimTracks.Fall  = LoadAnim(fakeHum, OfficialIDs.Fall)

            Camera.CameraSubject = fakeHum
            if AnimTracks.Idle then AnimTracks.Idle:Play() end

            table.insert(Connections, fakeHum.StateChanged:Connect(function(oldState, newState)
                if not isModeOn then return end
                if newState == Enum.HumanoidStateType.Jumping then
                    StopAll()
                    if AnimTracks.Jump then AnimTracks.Jump:Play() end
                elseif newState == Enum.HumanoidStateType.Freefall then
                    StopAll()
                    if AnimTracks.Fall then AnimTracks.Fall:Play() end
                elseif newState == Enum.HumanoidStateType.Landed then
                    StopAll()
                    if AnimTracks.Idle then AnimTracks.Idle:Play() end
                end
            end))

            table.insert(Connections, RunService.RenderStepped:Connect(function()
                if not isModeOn or not fakeHum or not fakeRoot or not fakeHum.Parent then return end
                
                fakeHum.WalkSpeed = 16
                
                local inputVector = Vector3.new(0, 0, 0)
                if Controls then
                    inputVector = Controls:GetMoveVector()
                else
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then inputVector = inputVector + Vector3.new(0, 0, -1) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then inputVector = inputVector + Vector3.new(0, 0, 1) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then inputVector = inputVector + Vector3.new(-1, 0, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then inputVector = inputVector + Vector3.new(1, 0, 0) end
                end
                
                local camCF = Camera.CFrame
                local finalDir = (camCF.RightVector * inputVector.X) + (camCF.LookVector * -inputVector.Z)
                finalDir = Vector3.new(finalDir.X, 0, finalDir.Z)
                
                local currentState = fakeHum:GetState()
                local isGrounded = (currentState == Enum.HumanoidStateType.Running or currentState == Enum.HumanoidStateType.RunningNoPhysics)
                
                if finalDir.Magnitude > 0 then
                    fakeHum:Move(finalDir.Unit, false)
                    if isGrounded then
                        if AnimTracks.Run and not AnimTracks.Run.IsPlaying then
                            StopAll()
                            AnimTracks.Run:Play(0.1)
                        end
                    end
                else
                    fakeHum:Move(Vector3.new(0, 0, 0), false)
                    if isGrounded then
                        if AnimTracks.Idle and not AnimTracks.Idle.IsPlaying then
                            StopAll()
                            AnimTracks.Idle:Play(0.1)
                        end
                    end
                end
            end))

            table.insert(Connections, UserInputService.JumpRequest:Connect(function()
                if isModeOn and fakeHum and fakeHum.Parent and fakeHum:GetState() ~= Enum.HumanoidStateType.Freefall then
                    fakeHum.UseJumpPower = true
                    fakeHum.JumpPower = 50
                    fakeHum.Jump = true
                end
            end))
        end
    end

    local function ToggleMode()
        SetState(not isModeOn)
    end

    return {
        Player = Player,
        Toggle = ToggleMode,
        SetState = SetState,
        IsActive = function() return isModeOn end,
        SetTeleportOnClose = function(val) teleportOnClose = val end
    }
end

return InitializeDesync()
