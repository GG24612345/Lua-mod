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

    local Controls

    local renderConnection
    local jumpRequestConnection
    local inputEndedConnection

    local tracks = {}
    local currentTrack = nil

    local jumpHeld = false
    local running = false
    local syncing = false

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

        local animation =
            folder:FindFirstChild(animationName)

        if not animation then
            animation =
                folder:FindFirstChildWhichIsA("Animation")
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
    -- ANIMAÇÃO
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

            if track then
                pcall(function()
                    track:Stop(0)
                end)
            end

        end

        currentTrack = nil
    end

    -- =========================================================
    -- CRIAR FAKE
    -- =========================================================

    local function createFake()

        if fake and fake.Parent then
            return false
        end

        if not character
            or not character.Parent then

            updateRealCharacter()
        end

        character.Archivable = true

        fake = character:Clone()
        fake.Name = "FakeCharacter"

        fake.Parent = workspace

        -- Garante PrimaryPart
        if not fake.PrimaryPart then

            local fakeRoot =
                fake:FindFirstChild("HumanoidRootPart")

            if fakeRoot then
                fake.PrimaryPart = fakeRoot
            end
        end

        fh = fake:WaitForChild("Humanoid")

        loadAnimations()

        return true
    end

    -- =========================================================
    -- LOOP
    -- =========================================================

    local function startLoop()

        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end

        renderConnection =
            RunService.RenderStepped:Connect(function()

                -- IMPORTANTE:
                -- durante sync absolutamente nada deve
                -- continuar mexendo no Fake.
                if not running or syncing then
                    return
                end

                if not character
                    or not character.Parent then
                    return
                end

                if not fake
                    or not fake.Parent
                    or not fh then
                    return
                end

                local moveVector =
                    Controls:GetMoveVector()

                -- =================================================
                -- REAL PARADO
                -- =================================================

                local realRoot =
                    character:FindFirstChild(
                        "HumanoidRootPart"
                    )

                if realRoot then
                    realRoot.Anchored = true
                end

                -- =================================================
                -- MOVIMENTO NO FAKE
                -- =================================================

                fh:Move(moveVector, true)

                fh.Jump = jumpHeld

                -- =================================================
                -- ESTADO
                -- =================================================

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

                -- =================================================
                -- CLIMB
                -- =================================================

                if state ==
                    Enum.HumanoidStateType.Climbing then

                    if horizontalSpeed > 0.05 then

                        playTrack(
                            tracks.climb,
                            1
                        )

                    else

                        playTrack(
                            tracks.climb,
                            0
                        )

                    end

                -- =================================================
                -- JUMP
                -- =================================================

                elseif state ==
                    Enum.HumanoidStateType.Jumping then

                    playTrack(
                        tracks.jump,
                        1
                    )

                -- =================================================
                -- FALL
                -- =================================================

                elseif state ==
                    Enum.HumanoidStateType.Freefall then

                    playTrack(
                        tracks.fall,
                        1
                    )

                -- =================================================
                -- WALK
                -- =================================================

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

                -- =================================================
                -- IDLE
                -- =================================================

                else

                    playTrack(
                        tracks.idle,
                        1
                    )

                end

            end)
    end

    -- =========================================================
    -- JUMP
    -- =========================================================

    jumpRequestConnection =
        UserInputService.JumpRequest:Connect(function()

            if running then
                jumpHeld = true
            end

        end)

    inputEndedConnection =
        UserInputService.InputEnded:Connect(function(input)

            if input.KeyCode == Enum.KeyCode.Space
                or input.KeyCode == Enum.KeyCode.ButtonA then

                jumpHeld = false

            end

        end)

    -- =========================================================
    -- BOTÃO MOBILE
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
    -- DESYNC
    -- =========================================================

    local function desync()

        if running then
            return
        end

        syncing = false

        if not character
            or not character.Parent then

            updateRealCharacter()
        end

        -- Real desbloqueado antes de começar
        local realRoot =
            character:FindFirstChild(
                "HumanoidRootPart"
            )

        if realRoot then
            realRoot.Anchored = false
        end

        -- Cria Fake
        createFake()

        if not fake or not fh then
            return
        end

        running = true

        -- Câmera no Fake
        camera.CameraType =
            Enum.CameraType.Custom

        camera.CameraSubject = fh

        -- Começa movimento
        startLoop()
    end

    -- =========================================================
    -- SYNC
    -- =========================================================

    local function sync()

        -- Impede duas chamadas simultâneas
        if syncing then
            return
        end

        syncing = true

        -- =====================================================
        -- PRIMEIRO: PARAR O LOOP
        -- =====================================================

        running = false

        if renderConnection then

            renderConnection:Disconnect()
            renderConnection = nil

        end

        -- =====================================================
        -- SEGUNDO: PEGAR O CFRAME DO FAKE
        -- ANTES DE DELETAR
        -- =====================================================

        local fakeCFrame

        if fake and fake.Parent then

            fakeCFrame = fake:GetPivot()

        end

        -- =====================================================
        -- TERCEIRO: PARAR ANIMAÇÕES
        -- =====================================================

        stopAll()

        -- =====================================================
        -- QUARTO: TELEPORTAR O REAL
        -- PARA EXATAMENTE ONDE O FAKE ESTÁ
        -- =====================================================

        if fakeCFrame
            and character
            and character.Parent then

            -- Desancora temporariamente
            local realRoot =
                character:FindFirstChild(
                    "HumanoidRootPart"
                )

            if realRoot then
                realRoot.Anchored = false
            end

            -- TP do personagem REAL
            character:PivotTo(fakeCFrame)

            -- Garante também o CFrame do RootPart
            if realRoot then
                realRoot.CFrame = fakeCFrame
            end

        end

        -- =====================================================
        -- QUINTO: DELETAR FAKE
        -- =====================================================

        if fake then

            pcall(function()
                fake:Destroy()
            end)

        end

        fake = nil
        fh = nil

        -- =====================================================
        -- SEXTO: REAL NOVAMENTE CONTROLÁVEL
        -- =====================================================

        if character
            and character.Parent then

            local realRoot =
                character:FindFirstChild(
                    "HumanoidRootPart"
                )

            if realRoot then
                realRoot.Anchored = false
            end

            if character.PrimaryPart then
                character.PrimaryPart.Anchored = false
            end

        end

        -- =====================================================
        -- SÉTIMO: HUMANOID REAL
        -- =====================================================

        if humanoid
            and humanoid.Parent then

            humanoid.PlatformStand = false
            humanoid.AutoRotate = true

            pcall(function()
                humanoid:ChangeState(
                    Enum.HumanoidStateType.GettingUp
                )
            end)

        end

        -- =====================================================
        -- OITAVO: CÂMERA NO REAL
        -- =====================================================

        camera.CameraType =
            Enum.CameraType.Custom

        if humanoid
            and humanoid.Parent then

            camera.CameraSubject = humanoid

        end

        -- =====================================================
        -- NONO: CONTROLES
        -- =====================================================

        pcall(function()
            Controls:Enable()
        end)

        syncing = false
    end

    -- =========================================================
    -- API
    -- =========================================================

    local API = {}

    function API.getRealChar()
        return character
    end

    function API.getFakeChar()
        return fake
    end

    function API.getRealHumanoid()
        return humanoid
    end

    function API.getFakeHumanoid()
        return fh
    end

    function API.isDesynced()
        return running
    end

    function API.desync()
        desync()
    end

    function API.sync()
        sync()
    end

    function API.getCamera()
        return camera
    end

    function API.getTracks()
        return tracks
    end

    function API.stopAnimations()
        stopAll()
    end

    function API.destroy()

        syncing = true
        running = false

        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end

        stopAll()

        if fake then
            fake:Destroy()
            fake = nil
        end

        fh = nil

        if character and character.Parent then

            local root =
                character:FindFirstChild(
                    "HumanoidRootPart"
                )

            if root then
                root.Anchored = false
            end

        end

        if humanoid then
            camera.CameraSubject = humanoid
        end

        syncing = false
    end

    -- =========================================================
    -- COMEÇA EM DESYNC
    -- =========================================================

    desync()

    return API

end)()
