-- [[ Desync Básico com TP ON (Formato Loadstring) ]] --

local function InitializeDesync()
    local Player = game.Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera

    -- Obter controlador do jogador (suporta joystick mobile)
    local Controls = nil
    pcall(function()
        local PlayerModule = require(Player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
        Controls = PlayerModule:GetControls()
    end)

    -- 1. Configuração da UI (Apenas botão Clone e TP)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Simple_Desync"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = Player:WaitForChild("PlayerGui")

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 70, 0, 70) 
    ToggleBtn.Position = UDim2.new(0, 20, 0.5, -35)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    ToggleBtn.Text = "CLONE\nOFF"
    ToggleBtn.TextColor3 = Color3.new(0, 0, 0)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 15
    ToggleBtn.Parent = ScreenGui
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0) 
    local btnStroke = Instance.new("UIStroke", ToggleBtn)
    btnStroke.Thickness = 3
    btnStroke.Color = Color3.new(0, 0, 0) 

    ---------------- Variáveis Principais ----------------

    local isModeOn = false
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

    local function ToggleMode()
        if isModeOn then
            isModeOn = false
            ToggleBtn.Text = "CLONE\nOFF"
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
            for _, conn in pairs(Connections) do conn:Disconnect() end
            Connections = {}
            StopAll()
            
            if FakeChar then
                local lastCF = FakeChar:GetPrimaryPartCFrame()
                FakeChar:Destroy()
                FakeChar = nil
                
                if RealChar and RealChar:FindFirstChild("HumanoidRootPart") then
                    RealChar.HumanoidRootPart.Anchored = false
                    -- TP ON fixo ao desligar
                    RealChar.HumanoidRootPart.CFrame = lastCF
                    Player.Character = RealChar
                    Camera.CameraSubject = RealChar.Humanoid
                end
            end
        else
            RealChar = Player.Character
            if not RealChar or not RealChar:FindFirstChild("HumanoidRootPart") then return end
            
            isModeOn = true
            ToggleBtn.Text = "CLONE\nON"
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
            
            RealChar.Archivable = true
            FakeChar = RealChar:Clone()
            FakeChar.Name = "God_Clone"
            FakeChar.Parent = workspace
            
            RealChar.HumanoidRootPart.Anchored = true
            
            local fakeHum = FakeChar:FindFirstChild("Humanoid")
            local fakeRoot = FakeChar:FindFirstChild("HumanoidRootPart")
            
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
                if not isModeOn or not fakeHum or not fakeRoot then return end
                
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
                if isModeOn and fakeHum and fakeHum:GetState() ~= Enum.HumanoidStateType.Freefall then
                    fakeHum.UseJumpPower = true
                    fakeHum.JumpPower = 50
                    fakeHum.Jump = true
                end
            end))
        end
    end

    ToggleBtn.MouseButton1Click:Connect(function()
        ToggleMode()
    end)

    -- Retorna um objeto/tabela contendo referências úteis
    return {
        Player = Player,
        GetRealChar = function() return RealChar end,
        GetRealHRP = function() return RealChar and RealChar:FindFirstChild("HumanoidRootPart") end,
        GetFakeChar = function() return FakeChar end,
        GetFakeHRP = function() return FakeChar and FakeChar:FindFirstChild("HumanoidRootPart") end,
        Toggle = ToggleMode,
        IsActive = function() return isModeOn end
    }
end

return InitializeDesync()
