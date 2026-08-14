--[==[
    Diamond PK - Headless / UI-Less Script for Github Loadstring
    Uso: loadstring(game:HttpGet("SEU_LINK_AQUI"))(true, "sync") -- ou ("false", "desync")
]==]

return function(enableState, modeType)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera
    local Player = Players.LocalPlayer

    -- Tratamento dos argumentos passados via loadstring
    local isModeOn = (enableState == true or enableState == "true")
    local isSync = (modeType == "sync" or modeType == true) -- "sync" ou "desync"

    -- Variáveis de controle globais locais do escopo
    local RealChar = Player.Character
    local FakeChar = nil
    local originalCF = nil
    local Connections = {}
    local AnimTracks = {}

    -- IDs de animação padrão do Roblox
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

    -- Limpeza caso já exista algo rodando
    if not isModeOn then
        return { RealChar = nil, FakeChar = nil, Status = "Off" }
    end

    if not RealChar or not RealChar:FindFirstChild("HumanoidRootPart") then
        return { RealChar = nil, FakeChar = nil, Status = "Error: No Character" }
    end

    originalCF = RealChar.HumanoidRootPart.CFrame
    RealChar.Archivable = true
    FakeChar = RealChar:Clone()
    FakeChar.Name = "Core_FakeChar"
    FakeChar.Parent = workspace

    -- Isola o corpo real no céu (segurança para evitar dano)
    RealChar.HumanoidRootPart.CFrame = originalCF + Vector3.new(0, 5000, 0)
    RealChar.HumanoidRootPart.Anchored = true

    local fakeHum = FakeChar:FindFirstChild("Humanoid")
    local fakeRoot = FakeChar:FindFirstChild("HumanoidRootPart")

    -- Limpa scripts do clone e ajusta colisões
    for _, v in pairs(FakeChar:GetDescendants()) do
        if v:IsA("LocalScript") or v:IsA("Script") then v:Destroy() end
        if v:IsA("BasePart") then
            v.Anchored = false
            v.CanCollide = (v.Name == "HumanoidRootPart")
            if v.Name == "HumanoidRootPart" then v.Transparency = 1 end
        end
    end

    -- Carrega animações no clone
    AnimTracks.Idle  = LoadAnim(fakeHum, OfficialIDs.Idle)
    AnimTracks.Walk  = LoadAnim(fakeHum, OfficialIDs.Walk)
    AnimTracks.Run   = LoadAnim(fakeHum, OfficialIDs.Run)
    AnimTracks.Jump  = LoadAnim(fakeHum, OfficialIDs.Jump)
    AnimTracks.Fall  = LoadAnim(fakeHum, OfficialIDs.Fall)

    Camera.CameraSubject = fakeHum
    if AnimTracks.Idle then AnimTracks.Idle:Play() end

    -- Lógica principal baseada no modo (Sync vs Desync)
    table.insert(Connections, RunService.RenderStepped:Connect(function()
        if not fakeHum or not fakeRoot or not RealChar then return end

        if isSync then
            -- MODO SYNC: O corpo real copia exatamente a posição e rotação do clone
            local realRoot = RealChar:FindFirstChild("HumanoidRootPart")
            if realRoot then
                realRoot.CFrame = fakeRoot.CFrame
            end
        else
            -- MODO DESYNC: O corpo real fica isolado/congelado, apenas o clone se move
            -- Opcional: manter o corpo real travado nas alturas
            local realRoot = RealChar:FindFirstChild("HumanoidRootPart")
            if realRoot then
                realRoot.CFrame = originalCF + Vector3.new(0, 5000, 0)
            end
        end
    end)))

    -- Retorna as referências exatas solicitadas
    return {
        RealChar = RealChar,
        FakeChar = FakeChar,
        Status = "Running",
        Mode = isSync and "Sync" or "Desync"
    }
end
