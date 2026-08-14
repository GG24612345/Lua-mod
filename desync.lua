-- [[ 鑽石PK - API Core Corrigido (Sync/Desync Funcional) ]] --

local function InitializeDesync()
    local Player = game.Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera

    local Controls = nil
    pcall(function()
        local PlayerModule = require(Player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
        Controls = PlayerModule:GetControls()
    end)

    local isModeOn = false
    local teleportOnClose = true
    local flyActive = false
    local shiftLockActive = false
    local noclipActive = false
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
        Fall  = "rbxassetid://507767968",
        Climb = "rbxassetid://507765644",
        Swim  = "rbxassetid://507784064"
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

    local function SetState(state)
        local targetState = state and true or false
        if targetState == isModeOn then return end
        isModeOn = targetState

        if not isModeOn then
            -- [ DESLIGAR / VOLTAR AO SYNC ] --
            for _, conn in pairs(Connections) do conn:Disconnect() end
            Connections = {}
            StopAll()
            
            local lastCF = nil
            if FakeChar then
                local fakeRoot = FakeChar:FindFirstChild("HumanoidRootPart")
                if fakeRoot then
                    lastCF = fakeRoot.CFrame
                end
                FakeChar:Destroy()
                FakeChar = nil
            end
            
            if RealChar and RealChar:FindFirstChild("HumanoidRootPart") then
                RealChar.HumanoidRootPart.Anchored = false
                if teleportOnClose and lastCF then
                    RealChar.HumanoidRootPart.CFrame = lastCF
                elseif originalCF then
                    RealChar.HumanoidRootPart.CFrame = originalCF
                end
                Player.Character = RealChar
                local realHum = RealChar:FindFirstChild("Humanoid")
                if realHum then
                    Camera.CameraSubject = realHum
                end
            end
        else
            -- [ LIGAR / ATIVAR DESYNC ] --
            RealChar = Player.Character
            if not RealChar or not RealChar:FindFirstChild("HumanoidRootPart") or not RealChar:FindFirstChild("Humanoid") then 
                isModeOn = false
                return 
            end
            
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
                if flyActive then return end 
                
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
                if not isModeOn or not fakeHum or not fakeRoot or not fakeRoot.Parent then return end
                
                if noclipActive then
                    for _, v in pairs(FakeChar:GetDescendants()) do
                        if v:IsA("BasePart") then v.CanCollide = false end
                    end
                end
                
                if shiftLockActive then
                    local camLook = Camera.CFrame.LookVector
                    local lookAtPos = fakeRoot.Position + Vector3.new(camLook.X, 0, camLook.Z)
                    fakeRoot.CFrame = CFrame.lookAt(fakeRoot.Position, lookAtPos)
                end
                
                local currentSpeed = 16
                fakeHum.WalkSpeed = currentSpeed
                
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
                
                if flyActive then
                    fakeHum.PlatformStand = true 
                    local move3D = (camCF.RightVector * inputVector.X) + (camCF.LookVector * -inputVector.Z)
                    
                    local bv = fakeRoot:FindFirstChild("FlyVelocity")
                    if not bv then
                        bv = Instance.new("BodyVelocity")
                        bv.Name = "FlyVelocity"
                        bv.MaxForce = Vector3.new(100000, 100000, 100000)
                        bv.Parent = fakeRoot
                    end
                    
                    if move3D.Magnitude > 0 then
                        bv.Velocity = move3D.Unit * currentSpeed
                        if AnimTracks.Fall and not AnimTracks.Fall.IsPlaying then
                            StopAll()
                            AnimTracks.Fall:Play(0.1)
                        end
                    else
                        bv.Velocity = Vector3.new(0, 0, 0)
                        if AnimTracks.Idle and not AnimTracks.Idle.IsPlaying then
                            StopAll()
                            AnimTracks.Idle:Play(0.1)
                        end
                    end
                else
                    fakeHum.PlatformStand = false
                    local bv = fakeRoot:FindFirstChild("FlyVelocity")
                    if bv then bv:Destroy() end
                    
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
        Toggle = ToggleMode,
        SetState = SetState,
        IsActive = function() return isModeOn end,
        SetFly = function(v) flyActive = v end,
        SetLock = function(v) shiftLockActive = v end,
        SetNoclip = function(v) noclipActive = v end,
        SetTPOnClose = function(v) teleportOnClose = v end
    }
end

return InitializeDesync()
