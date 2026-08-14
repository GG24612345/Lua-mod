-- [[ 鑽石PK - API Core Sem UI (Sync/Desync Exato) ]] --

local function InitializeDesync()
    local Player = game.Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera

    local Controls = nil

    pcall(function()
        local PlayerModule = require(
            Player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
        )

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
        Idle = "rbxassetid://507766388",
        Walk = "rbxassetid://507777826",
        Run = "rbxassetid://507767714",
        Jump = "rbxassetid://507765000",
        Fall = "rbxassetid://507767968",
        Climb = "rbxassetid://507765644",
        Swim = "rbxassetid://507784064"
    }

    ----------------------------------------------------------------
    -- ANIMAÇÕES
    ----------------------------------------------------------------

    local function LoadAnim(hum, id)
        local animation = Instance.new("Animation")
        animation.AnimationId = id

        local track

        pcall(function()
            track = hum:LoadAnimation(animation)
        end)

        animation:Destroy()

        return track
    end

    local function StopAll()
        for _, track in pairs(AnimTracks) do
            if track then
                pcall(function()
                    if track.IsPlaying then
                        track:Stop(0.1)
                    end
                end)
            end
        end
    end

    local function ClearAnimations()
        StopAll()

        for key, track in pairs(AnimTracks) do
            if track then
                pcall(function()
                    track:Destroy()
                end)
            end

            AnimTracks[key] = nil
        end
    end

    ----------------------------------------------------------------
    -- CONNECTIONS
    ----------------------------------------------------------------

    local function DisconnectAll()
        for _, connection in pairs(Connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end

        table.clear(Connections)
    end

    ----------------------------------------------------------------
    -- RESTAURAR REAL CHARACTER
    ----------------------------------------------------------------

    local function RestoreRealCharacter(lastCF)
        if not RealChar then
            return
        end

        local realRoot = RealChar:FindFirstChild("HumanoidRootPart")
        local realHum = RealChar:FindFirstChildOfClass("Humanoid")

        if realRoot then
            -- Escolhe para onde o personagem real deve voltar
            if teleportOnClose and lastCF then
                realRoot.CFrame = lastCF
            elseif originalCF then
                realRoot.CFrame = originalCF
            end

            -- Limpa velocidade residual
            realRoot.AssemblyLinearVelocity = Vector3.zero
            realRoot.AssemblyAngularVelocity = Vector3.zero

            realRoot.Anchored = false
        end

        -- Restaura o Character real
        pcall(function()
            Player.Character = RealChar
        end)

        if realHum then
            pcall(function()
                Camera.CameraSubject = realHum
            end)
        end
    end

    ----------------------------------------------------------------
    -- DESLIGAR
    ----------------------------------------------------------------

    local function DisableMode()
        if not isModeOn then
            return
        end

        isModeOn = false

        DisconnectAll()
        ClearAnimations()

        local lastCF = nil

        ------------------------------------------------------------
        -- PEGAR POSIÇÃO DO FAKE ANTES DE DESTRUIR
        ------------------------------------------------------------

        if FakeChar then
            local fakeRoot = FakeChar:FindFirstChild("HumanoidRootPart")

            if fakeRoot then
                lastCF = fakeRoot.CFrame

                -- Remove velocity de voo
                local flyVelocity = fakeRoot:FindFirstChild("FlyVelocity")

                if flyVelocity then
                    flyVelocity:Destroy()
                end

                fakeRoot.AssemblyLinearVelocity = Vector3.zero
                fakeRoot.AssemblyAngularVelocity = Vector3.zero
            end

            --------------------------------------------------------
            -- DESTRÓI O FAKE
            --------------------------------------------------------

            pcall(function()
                FakeChar:Destroy()
            end)

            FakeChar = nil
        end

        ------------------------------------------------------------
        -- RESTAURA REAL
        ------------------------------------------------------------

        RestoreRealCharacter(lastCF)

        RealChar = nil
        originalCF = nil

        flyActive = false
    end

    ----------------------------------------------------------------
    -- LIGAR
    ----------------------------------------------------------------

    local function EnableMode()
        if isModeOn then
            return
        end

        local character = Player.Character

        if not character then
            return
        end

        local realRoot = character:FindFirstChild("HumanoidRootPart")
        local realHum = character:FindFirstChildOfClass("Humanoid")

        if not realRoot or not realHum then
            return
        end

        ------------------------------------------------------------
        -- SALVA CHARACTER REAL
        ------------------------------------------------------------

        RealChar = character

        originalCF = realRoot.CFrame

        ------------------------------------------------------------
        -- CLONA
        ------------------------------------------------------------

        RealChar.Archivable = true

        local clone

        local success = pcall(function()
            clone = RealChar:Clone()
        end)

        if not success or not clone then
            RealChar = nil
            originalCF = nil
            return
        end

        FakeChar = clone
        FakeChar.Name = "God_Clone"

        ------------------------------------------------------------
        -- PARENT
        ------------------------------------------------------------

        FakeChar.Parent = workspace

        local fakeHum = FakeChar:FindFirstChildOfClass("Humanoid")
        local fakeRoot = FakeChar:FindFirstChild("HumanoidRootPart")

        if not fakeHum or not fakeRoot then
            FakeChar:Destroy()
            FakeChar = nil

            RealChar = nil
            originalCF = nil

            return
        end

        ------------------------------------------------------------
        -- GARANTE PRIMARY PART
        ------------------------------------------------------------

        pcall(function()
            FakeChar.PrimaryPart = fakeRoot
        end)

        ------------------------------------------------------------
        -- PREPARA PARTES
        ------------------------------------------------------------

        for _, object in ipairs(FakeChar:GetDescendants()) do

            if object:IsA("LocalScript") or object:IsA("Script") then
                object:Destroy()

            elseif object:IsA("BasePart") then

                object.Anchored = false

                if object.Name == "HumanoidRootPart" then
                    object.Transparency = 1
                    object.CanCollide = true
                else
                    object.CanCollide = false
                end
            end
        end

        ------------------------------------------------------------
        -- REAL CHARACTER FICA PARADO
        ------------------------------------------------------------

        realRoot.Anchored = true

        ------------------------------------------------------------
        -- ATIVA MODO
        ------------------------------------------------------------

        isModeOn = true

        ------------------------------------------------------------
        -- ANIMAÇÕES
        ------------------------------------------------------------

        AnimTracks.Idle = LoadAnim(fakeHum, OfficialIDs.Idle)
        AnimTracks.Walk = LoadAnim(fakeHum, OfficialIDs.Walk)
        AnimTracks.Run = LoadAnim(fakeHum, OfficialIDs.Run)
        AnimTracks.Jump = LoadAnim(fakeHum, OfficialIDs.Jump)
        AnimTracks.Fall = LoadAnim(fakeHum, OfficialIDs.Fall)

        ------------------------------------------------------------
        -- CÂMERA
        ------------------------------------------------------------

        Camera.CameraSubject = fakeHum

        if AnimTracks.Idle then
            AnimTracks.Idle:Play()
        end

        ----------------------------------------------------------------
        -- STATE CHANGED
        ----------------------------------------------------------------

        table.insert(
            Connections,
            fakeHum.StateChanged:Connect(function(_, newState)

                if not isModeOn then
                    return
                end

                if flyActive then
                    return
                end

                if newState == Enum.HumanoidStateType.Jumping then

                    StopAll()

                    if AnimTracks.Jump then
                        AnimTracks.Jump:Play()
                    end

                elseif newState == Enum.HumanoidStateType.Freefall then

                    StopAll()

                    if AnimTracks.Fall then
                        AnimTracks.Fall:Play()
                    end

                elseif newState == Enum.HumanoidStateType.Landed then

                    StopAll()

                    if AnimTracks.Idle then
                        AnimTracks.Idle:Play()
                    end
                end
            end)
        )

        ----------------------------------------------------------------
        -- MOVIMENTO
        ----------------------------------------------------------------

        table.insert(
            Connections,
            RunService.RenderStepped:Connect(function()

                if not isModeOn then
                    return
                end

                if not FakeChar then
                    return
                end

                if not fakeHum or not fakeRoot then
                    return
                end

                --------------------------------------------------------
                -- NOCLIP
                --------------------------------------------------------

                if noclipActive then

                    for _, object in ipairs(FakeChar:GetDescendants()) do

                        if object:IsA("BasePart") then
                            object.CanCollide = false
                        end

                    end
                end

                --------------------------------------------------------
                -- SHIFT LOCK
                --------------------------------------------------------

                if shiftLockActive then

                    local look = Camera.CFrame.LookVector

                    local flatLook = Vector3.new(
                        look.X,
                        0,
                        look.Z
                    )

                    if flatLook.Magnitude > 0 then

                        local lookAt = fakeRoot.Position + flatLook

                        fakeRoot.CFrame = CFrame.lookAt(
                            fakeRoot.Position,
                            lookAt
                        )
                    end
                end

                --------------------------------------------------------
                -- VELOCIDADE
                --------------------------------------------------------

                local currentSpeed = 16

                fakeHum.WalkSpeed = currentSpeed

                --------------------------------------------------------
                -- INPUT
                --------------------------------------------------------

                local inputVector = Vector3.zero

                if Controls then

                    local success, result = pcall(function()
                        return Controls:GetMoveVector()
                    end)

                    if success and result then
                        inputVector = result
                    end

                else

                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                        inputVector += Vector3.new(0, 0, -1)
                    end

                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        inputVector += Vector3.new(0, 0, 1)
                    end

                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                        inputVector += Vector3.new(-1, 0, 0)
                    end

                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        inputVector += Vector3.new(1, 0, 0)
                    end
                end

                local camCF = Camera.CFrame

                ----------------------------------------------------------------
                -- FLY
                ----------------------------------------------------------------

                if flyActive then

                    fakeHum.PlatformStand = true

                    local move3D =
                        (camCF.RightVector * inputVector.X)
                        +
                        (camCF.LookVector * -inputVector.Z)

                    local bv = fakeRoot:FindFirstChild("FlyVelocity")

                    if not bv then

                        bv = Instance.new("BodyVelocity")

                        bv.Name = "FlyVelocity"

                        bv.MaxForce = Vector3.new(
                            100000,
                            100000,
                            100000
                        )

                        bv.P = 10000

                        bv.Parent = fakeRoot
                    end

                    if move3D.Magnitude > 0 then

                        bv.Velocity =
                            move3D.Unit * currentSpeed

                        if AnimTracks.Fall
                            and not AnimTracks.Fall.IsPlaying then

                            StopAll()
                            AnimTracks.Fall:Play(0.1)
                        end

                    else

                        bv.Velocity = Vector3.zero

                        if AnimTracks.Idle
                            and not AnimTracks.Idle.IsPlaying then

                            StopAll()
                            AnimTracks.Idle:Play(0.1)
                        end
                    end

                ----------------------------------------------------------------
                -- NORMAL
                ----------------------------------------------------------------

                else

                    fakeHum.PlatformStand = false

                    local bv = fakeRoot:FindFirstChild("FlyVelocity")

                    if bv then
                        bv:Destroy()
                    end

                    local finalDir =
                        (camCF.RightVector * inputVector.X)
                        +
                        (camCF.LookVector * -inputVector.Z)

                    finalDir = Vector3.new(
                        finalDir.X,
                        0,
                        finalDir.Z
                    )

                    local currentState = fakeHum:GetState()

                    local isGrounded =
                        currentState == Enum.HumanoidStateType.Running
                        or
                        currentState == Enum.HumanoidStateType.RunningNoPhysics

                    if finalDir.Magnitude > 0 then

                        fakeHum:Move(
                            finalDir.Unit,
                            false
                        )

                        if isGrounded then

                            if AnimTracks.Run
                                and not AnimTracks.Run.IsPlaying then

                                StopAll()
                                AnimTracks.Run:Play(0.1)
                            end
                        end

                    else

                        fakeHum:Move(
                            Vector3.zero,
                            false
                        )

                        if isGrounded then

                            if AnimTracks.Idle
                                and not AnimTracks.Idle.IsPlaying then

                                StopAll()
                                AnimTracks.Idle:Play(0.1)
                            end
                        end
                    end
                end
            end)
        )

        ----------------------------------------------------------------
        -- JUMP
        ----------------------------------------------------------------

        table.insert(
            Connections,
            UserInputService.JumpRequest:Connect(function()

                if not isModeOn then
                    return
                end

                if not fakeHum then
                    return
                end

                if flyActive then
                    return
                end

                local state = fakeHum:GetState()

                if state ~= Enum.HumanoidStateType.Freefall then

                    fakeHum.UseJumpPower = true
                    fakeHum.JumpPower = 50
                    fakeHum.Jump = true

                end
            end)
        )
    end

    ----------------------------------------------------------------
    -- TOGGLE
    ----------------------------------------------------------------

    local function ToggleMode()

        if isModeOn then
            DisableMode()
        else
            EnableMode()
        end
    end

    ----------------------------------------------------------------
    -- API
    ----------------------------------------------------------------

    return {

        Toggle = ToggleMode,

        SetState = function(value)

            value = value and true or false

            if value then
                EnableMode()
            else
                DisableMode()
            end
        end,

        IsActive = function()
            return isModeOn
        end,

        SetFly = function(value)
            flyActive = value and true or false
        end,

        SetLock = function(value)
            shiftLockActive = value and true or false
        end,

        SetNoclip = function(value)
            noclipActive = value and true or false
        end,

        SetTPOnClose = function(value)
            teleportOnClose = value and true or false
        end
    }
end

return InitializeDesync()
