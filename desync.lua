return (function()

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")

    local player = Players.LocalPlayer
    local camera = workspace.CurrentCamera

    local character
    local humanoid

    local fake
    local fh

    local renderConnection
    local jumpRequestConnection
    local inputEndedConnection

    local tracks = {}
    local currentTrack = nil

    local jumpHeld = false
    local running = false

    local Controls

    -- =========================================================
    -- CHARACTER REAL
    -- =========================================================

    local function updateRealCharacter()

        character = player.Character
            or player.CharacterAdded:Wait()

        humanoid = character:WaitForChild("Humanoid")

        character.Archivable = true
    end

    updateRealCharacter()

    -- =========================================================
    -- CONTROLES
    -- =========================================================

    Controls = require(
        player.PlayerScripts:WaitForChild("PlayerModule")
    ):GetControls()

    -- =========================================================
    -- ANIMAÇÕES
    -- =========================================================

    local function getAnimation(folderName, animationName)

        if not character then
            return nil
        end

        local animate = character:FindFirstChild("Animate")

        if not animate then
            return nil
        end

        local folder = animate:FindFirstChild(folderName)

        if not folder then
            return nil
        end

        local animation = folder:FindFirstChild(animationName)

        if not animation then
            animation = folder:FindFirstChildWhichIsA("Animation")
        end

        return animation
    end

    local function loadTrack(
        animator,
        folderName,
        animationName,
        priority,
        looped
    )

        local animation = getAnimation(
            folderName,
            animationName
        )

        if not animation then
            return nil
        end

        local track = animator:LoadAnimation(animation)

        track.Priority = priority
        track.Looped = looped

        return track
    end

    local function loadAnimations()

        tracks = {}
        currentTrack = nil

        if not fh then
            return
        end

        local animator =
            fh:FindFirstChildOfClass("Animator")

        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = fh
        end

        tracks.idle = loadTrack(
            animator,
            "idle",
            "Animation1",
            Enum.AnimationPriority.Idle,
            true
        )

        tracks.walk = loadTrack(
            animator,
            "run",
            "RunAnim",
            Enum.AnimationPriority.Movement,
            true
        )

        tracks.run = loadTrack(
            animator,
            "run",
            "RunAnim",
            Enum.AnimationPriority.Movement,
            true
        )

        tracks.jump = loadTrack(
            animator,
            "jump",
            "JumpAnim",
            Enum.AnimationPriority.Movement,
            false
        )

        tracks.fall = loadTrack(
            animator,
            "fall",
            "FallAnim",
            Enum.AnimationPriority.Movement,
            true
        )

        tracks.climb = loadTrack(
            animator,
            "climb",
            "ClimbAnim",
            Enum.AnimationPriority.Movement,
            true
        )
    end

    -- =========================================================
    -- CONTROLE DAS ANIMAÇÕES
    -- =========================================================

    local function playTrack(track, speed)

        if not track then
            return
        end

        if currentTrack ~= track then

            if currentTrack then
                currentTrack:Stop(0.15)
            end

            currentTrack = track

            track:Play(0.15)
        end

        track:AdjustSpeed(speed or 1)
    end

    local function stopAll()

        for _, track in pairs(tracks) do

            if track and track.IsPlaying then
                track:Stop(0.15)
            end

        end

        currentTrack = nil
    end

    -- =========================================================
    -- CRIAR FAKE
    -- =========================================================

    local function createFake()

        if fake and fake.Parent then
            return
        end

        if not character or not character.Parent then
            updateRealCharacter()
        end

        character.Archivable = true

        fake = character:Clone()
        fake.Name = "FakeCharacter"

        fake.Parent = workspace

        fh = fake:WaitForChild("Humanoid")

        loadAnimations()

        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = fh

        running = true
    end

    -- =========================================================
    -- PULO
    -- =========================================================

    jumpRequestConnection =
        UserInputService.JumpRequest:Connect(function()

            if not running then
                return
            end

            jumpHeld = true
        end)

    inputEndedConnection =
        UserInputService.InputEnded:Connect(function(input)

            if input.KeyCode == Enum.KeyCode.Space
                or input.KeyCode == Enum.KeyCode.ButtonA then

                jumpHeld = false
            end
        end)

    -- =========================================================
    -- BOTÃO MOBILE DE PULO
    -- =========================================================

    task.spawn(function()

        local playerGui =
            player:WaitForChild("PlayerGui")

        local touchGui =
            playerGui:WaitForChild(
                "TouchGui",
                10
            )

        if not touchGui then
            return
        end

        local jumpButton =
            touchGui:FindFirstChild(
                "JumpButton",
                true
            )

        if not jumpButton then
            return
        end

        jumpButton.InputBegan:Connect(function(input)

            if input.UserInputType ==
                Enum.UserInputType.Touch then

                jumpHeld = true
            end
        end)

        jumpButton.InputEnded:Connect(function(input)

            if input.UserInputType ==
                Enum.UserInputType.Touch then

                jumpHeld = false
            end
        end)
    end)

    -- =========================================================
    -- LOOP DO DESYNC
    -- =========================================================

    local function startLoop()

        if renderConnection then
            renderConnection:Disconnect()
        end

        renderConnection =
            RunService.RenderStepped:Connect(function()

                if not running then
                    return
                end

                if not fake
                    or not fake.Parent
                    or not fh then

                    return
                end

                if not character
                    or not character.Parent then

                    return
                end

                local moveVector =
                    Controls:GetMoveVector()

                -- =============================================
                -- REAL FICA PARADO
                -- =============================================

                if character.PrimaryPart then
                    character.PrimaryPart.Anchored = true
                end

                -- =============================================
                -- FAKE RECEBE O MOVIMENTO
                -- =============================================

                fh:Move(moveVector, true)

                fh.Jump = jumpHeld

                local state = fh:GetState()

                local velocity =
                    fh.RootPart
                    and fh.RootPart.AssemblyLinearVelocity
                    or Vector3.zero

                local horizontalSpeed =
                    Vector3.new(
                        velocity.X,
                        0,
                        velocity.Z
                    ).Magnitude

                -- =============================================
                -- CLIMBING
                -- =============================================

                if state ==
                    Enum.HumanoidStateType.Climbing then

                    if horizontalSpeed > 0.05 then

                        playTrack(
                            tracks.climb,
                            1
                        )

                    else

                        -- Mantém a animação parada
                        playTrack(
                            tracks.climb,
                            0
                        )

                    end

                -- =============================================
                -- JUMP
                -- =============================================

                elseif state ==
                    Enum.HumanoidStateType.Jumping then

                    playTrack(
                        tracks.jump,
                        1
                    )

                -- =============================================
                -- FALL
                -- =============================================

                elseif state ==
                    Enum.HumanoidStateType.Freefall then

                    playTrack(
                        tracks.fall,
                        1
                    )

                -- =============================================
                -- ANDANDO
                -- =============================================

                elseif horizontalSpeed > 0.05 then

                    if tracks.walk then

                        playTrack(
                            tracks.walk,
                            horizontalSpeed / 16
                        )

                    elseif tracks.run then

                        playTrack(
                            tracks.run,
                            horizontalSpeed / 16
                        )

                    end

                -- =============================================
                -- PARADO
                -- =============================================

                else

                    playTrack(
                        tracks.idle,
                        1
                    )

                end
            end)
    end

    -- =========================================================
    -- DESYNC
    -- =========================================================

    local function desync()

        if running then
            return
        end

        if not character
            or not character.Parent then

            updateRealCharacter()
        end

        -- Garante que o real pode ser ancorado
        if character.PrimaryPart then
            character.PrimaryPart.Anchored = false
        end

        local root =
            character:FindFirstChild("HumanoidRootPart")

        if root then
            root.Anchored = false
        end

        -- Cria o Fake
        createFake()

        -- Inicia o loop
        startLoop()

        -- Câmera no Fake
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = fh
    end

    -- =========================================================
    -- SYNC
    -- =========================================================

    local function sync()

        if not character
            or not character.Parent then

            return
        end

        -- =============================================
        -- PEGAR A POSIÇÃO DO FAKE PRIMEIRO
        -- =============================================

        local fakeCFrame = nil

        if fake and fake.Parent then
            fakeCFrame = fake:GetPivot()
        end

        -- =============================================
        -- PARAR DESYNC
        -- =============================================

        running = false

        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end

        -- =============================================
        -- PARAR ANIMAÇÕES DO FAKE
        -- =============================================

        stopAll()

        -- =============================================
        -- TP DO REAL PARA O FAKE
        -- =============================================

        if fakeCFrame then
            character:PivotTo(fakeCFrame)
        end

        -- =============================================
        -- DELETAR FAKE
        -- =============================================

        if fake then
            fake:Destroy()
            fake = nil
        end

        fh = nil

        -- =============================================
        -- DESANCORAR REAL
        -- =============================================

        if character.PrimaryPart then
            character.PrimaryPart.Anchored = false
        end

        local root =
            character:FindFirstChild("HumanoidRootPart")

        if root then
            root.Anchored = false
        end

        -- =============================================
        -- REATIVAR HUMANOID REAL
        -- =============================================

        if humanoid then

            humanoid.PlatformStand = false
            humanoid.AutoRotate = true

            humanoid:ChangeState(
                Enum.HumanoidStateType.Running
            )
        end

        -- =============================================
        -- CÂMERA → REAL
        -- =============================================

        camera.CameraType =
            Enum.CameraType.Custom

        camera.CameraSubject = humanoid

        -- =============================================
        -- CONTROLES → REAL
        -- =============================================

        pcall(function()
            Controls:Enable()
        end)
    end

    -- =========================================================
    -- API
    -- =========================================================

    local API = {}

    -- Character real
    function API.getRealChar()
        return character
    end

    -- Character fake
    function API.getFakeChar()
        return fake
    end

    -- Humanoid real
    function API.getRealHumanoid()
        return humanoid
    end

    -- Humanoid fake
    function API.getFakeHumanoid()
        return fh
    end

    -- Verificar se está em desync
    function API.isDesynced()
        return running
    end

    -- Ativar desync
    function API.desync()
        desync()
    end

    -- Fazer sync
    function API.sync()
        sync()
    end

    -- Parar animações
    function API.stopAnimations()
        stopAll()
    end

    -- Destruir sistema
    function API.destroy()

        running = false

        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end

        if jumpRequestConnection then
            jumpRequestConnection:Disconnect()
            jumpRequestConnection = nil
        end

        if inputEndedConnection then
            inputEndedConnection:Disconnect()
            inputEndedConnection = nil
        end

        stopAll()

        if fake then
            fake:Destroy()
            fake = nil
        end

        fh = nil

        if character and character.PrimaryPart then
            character.PrimaryPart.Anchored = false
        end

        if humanoid then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = humanoid
        end
    end

    -- =========================================================
    -- INICIAR AUTOMATICAMENTE EM DESYNC
    -- =========================================================

    createFake()
    startLoop()

    -- =========================================================
    -- RETORNAR API
    -- =========================================================

    return API

end)()
