--[==[
    Diamond PK - Loadstring Singleton (Sync / Desync Corrected)
    Cole este código atualizado no seu repositório do GitHub.
]==]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer

getgenv().DiamondPK = getgenv().DiamondPK or {
    Active = false,
    Mode = "desync",
    RealChar = nil,
    FakeChar = nil,
    Connections = {},
    AnimTracks = {},
    OriginalCF = nil
}

local PK = getgenv().DiamondPK

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
    for _, track in pairs(PK.AnimTracks) do
        if track and track.IsPlaying then track:Stop(0.1) end
    end
end

local function Cleanup()
    for _, conn in pairs(PK.Connections) do conn:Disconnect() end
    PK.Connections = {}
    StopAll()

    if PK.FakeChar then
        local lastCF = PK.FakeChar:GetPrimaryPartCFrame()
        PK.FakeChar:Destroy()
        PK.FakeChar = nil

        if PK.RealChar and PK.RealChar:FindFirstChild("HumanoidRootPart") then
            PK.RealChar.HumanoidRootPart.Anchored = false
            PK.RealChar.HumanoidRootPart.CFrame = lastCF
            Player.Character = PK.RealChar
            Camera.CameraSubject = PK.RealChar.Humanoid
        end
    end
    PK.Active = false
end

local function ApplyMode(targetMode)
    PK.Mode = targetMode
    local realRoot = PK.RealChar and PK.RealChar:FindFirstChild("HumanoidRootPart")
    
    if not realRoot then return end

    if PK.Mode == "desync" then
        -- Desync: Corpo real vai pro alto e fica ancorado
        realRoot.CFrame = PK.OriginalCF + Vector3.new(0, 5000, 0)
        realRoot.Anchored = true
    elseif PK.Mode == "sync" then
        -- Sync: Corpo real vai debaixo da terra, desancorado para poder se mover junto
        realRoot.CFrame = PK.OriginalCF + Vector3.new(0, -5000, 0)
        realRoot.Anchored = false
    end
end

local function Start(mode)
    if not PK.Active then
        PK.RealChar = Player.Character
        if not PK.RealChar or not PK.RealChar:FindFirstChild("HumanoidRootPart") then return end

        PK.Active = true
        PK.OriginalCF = PK.RealChar.HumanoidRootPart.CFrame

        PK.RealChar.Archivable = true
        PK.FakeChar = PK.RealChar:Clone()
        PK.FakeChar.Name = "Core_FakeChar"
        PK.FakeChar.Parent = workspace

        local fakeHum = PK.FakeChar:FindFirstChild("Humanoid")
        local fakeRoot = PK.FakeChar:FindFirstChild("HumanoidRootPart")

        for _, v in pairs(PK.FakeChar:GetDescendants()) do
            if v:IsA("LocalScript") or v:IsA("Script") then v:Destroy() end
            if v:IsA("BasePart") then
                v.Anchored = false
                v.CanCollide = (v.Name == "HumanoidRootPart")
                if v.Name == "HumanoidRootPart" then v.Transparency = 1 end
            end
        end

        PK.AnimTracks.Idle  = LoadAnim(fakeHum, OfficialIDs.Idle)
        PK.AnimTracks.Walk  = LoadAnim(fakeHum, OfficialIDs.Walk)
        PK.AnimTracks.Run   = LoadAnim(fakeHum, OfficialIDs.Run)
        PK.AnimTracks.Jump  = LoadAnim(fakeHum, OfficialIDs.Jump)
        PK.AnimTracks.Fall  = LoadAnim(fakeHum, OfficialIDs.Fall)

        Camera.CameraSubject = fakeHum
        if PK.AnimTracks.Idle then PK.AnimTracks.Idle:Play() end

        -- Loop de renderização ajustado para sincronizar posições se estiver em modo sync
        table.insert(PK.Connections, RunService.RenderStepped:Connect(function()
            if not PK.Active or not fakeHum or not fakeRoot or not PK.RealChar then return end

            local realRoot = PK.RealChar:FindFirstChild("HumanoidRootPart")
            if realRoot then
                if PK.Mode == "sync" then
                    -- No sync, o corpo real debaixo da terra copia perfeitamente o movimento do clone
                    realRoot.CFrame = fakeRoot.CFrame
                end
            end
        end))
    end

    -- Aplica as regras de posição/âncora para o modo escolhido
    ApplyMode(mode)
end

return {
    setState = function(state, mode)
        if state == true then
            Start(mode or "desync")
        else
            Cleanup()
        end
    end,
    getChars = function()
        return { RealChar = PK.RealChar, FakeChar = PK.FakeChar }
    end
}
