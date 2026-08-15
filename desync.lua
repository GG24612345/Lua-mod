return (function()

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")

    local player = Players.LocalPlayer
    local camera = workspace.CurrentCamera

    -- =========================================================
    -- CHARACTER REAL
    -- =========================================================

    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    character.Archivable = true

    -- =========================================================
    -- VARIÁVEIS
    -- =========================================================

    local fake = nil
    local fh = nil

    local renderConnection = nil
    local jumpRequestConnection = nil
    local inputEndedConnection = nil

    local tracks = {}
    local currentTrack = nil

    local jumpHeld = false
    local running = false

    -- =========================================================
    -- CONTROLES
    -- =========================================================

    local Controls = require(
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

            character =
                player.Character
                or player.CharacterAdded:Wait()

            humanoid =
                character:WaitForChild("Humanoid")

        end

        character.Archivable = true

        fake = character:Clone()
        fake.Name = "FakeCharacter"
        fake.Parent = workspace

        fh = fake:WaitForChild("Humanoid")

        loadAnimations()

        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = fh
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

                -- REAL FICA PARADO
                if character.PrimaryPart then
                    character.PrimaryPart.Anchored = true
                end

                -- MOVIMENTO VAI PARA O FAKE
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

                -- =================================================
                -- CLIMBING
                -- =================================================

                if state ==
                    Enum.HumanoidStateType.Climbing then

                    if horizontalSpeed > 0.05 then

                        playTrack(
                            tracks.climb,
                            1
                        )

                    else

                        -- PAUSA A ANIMAÇÃO
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
                -- ANDANDO
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
                -- PARADO
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
    -- DESYNC
    -- =========================================================

    local function desync()

        if running then
            return
        end

        if not character
            or not character.Parent then

            character =
                player.Character
                or player.CharacterAdded:Wait()

            humanoid =
                character:WaitForChild("Humanoid")
        end

        character.Archivable = true

        -- Garante que o real está livre
        if character.PrimaryPart then
            character.PrimaryPart.Anchored = false
        end

        local root =
            character:FindFirstChild(
                "HumanoidRootPart"
            )

        if root then
            root.Anchored = false
        end

        -- Cria o Fake
        createFake()

        running = true

        -- Câmera no Fake
        camera.CameraType =
            Enum.CameraType.Custom

        camera.CameraSubject = fh

        -- Inicia movimento
        startLoop()
    end

    -- =========================================================
    -- SYNC
    -- =========================================================

    local function sync()

        if not character
            or not character.Parent then

            return
        end

        -- =====================================================
        -- SALVA A POSIÇÃO DO FAKE PRIMEIRO
        -- =====================================================

        local fakeCFrame = nil

        if fake and fake.Parent then
            fakeCFrame = fake:GetPivot()
        end

        -- =====================================================
        -- PARA O DESYNC
        -- =====================================================

        running = false

        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end

        -- =====================================================
        -- PARA ANIMAÇÕES DO FAKE
        -- =====================================================

        stopAll()

        -- =====================================================
        -- TELEPORTA O REAL PARA O FAKE
        -- =====================================================

        if fakeCFrame then

            character:PivotTo(
                fakeCFrame
            )

        end

        -- =====================================================
        -- DELETA O FAKE
        -- =====================================================

        if fake then
            fake:Destroy()
            fake = nil
        end

        fh = nil

        -- =====================================================
        -- DESANCORA O REAL
        -- =====================================================

        if character.PrimaryPart then
            character.PrimaryPart.Anchored = false
        end

        local root =
            character:FindFirstChild(
                "HumanoidRootPart"
            )

        if root then
            root.Anchored = false
        end

        -- =====================================================
        -- ATIVA HUMANOID REAL
        -- =====================================================

        if humanoid then

            humanoid.PlatformStand = false
            humanoid.AutoRotate = true

            humanoid:ChangeState(
                Enum.HumanoidStateType.Running
            )

        end

        -- =====================================================
        -- DEVOLVE CONTROLE AO REAL
        -- =====================================================

        pcall(function()
            Controls:Enable()
        end)

        -- =====================================================
        -- DEVOLVE CÂMERA AO REAL
        -- =====================================================

        camera.CameraType =
            Enum.CameraType.Custom

        camera.CameraSubject = humanoid
    end

    -- =========================================================
    -- API
    -- =========================================================

    local API = {}

    -- Character REAL
    function API.getRealChar()
        return character
    end

    -- Character FAKE
    function API.getFakeChar()
        return fake
    end

    -- Humanoid REAL
    function API.getRealHumanoid()
        return humanoid
    end

    -- Humanoid FAKE
    function API.getFakeHumanoid()
        return fh
    end

    -- Verifica se está em desync
    function API.isDesynced()
        return running
    end

    -- Desync
    function API.desync()
        desync()
    end

    -- Sync
    function API.sync()
        sync()
    end

    -- Para animações
    function API.stopAnimations()
        stopAll()
    end

    -- =========================================================
    -- DESTROY
    -- =========================================================

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
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true

            camera.CameraType =
                Enum.CameraType.Custom

            camera.CameraSubject = humanoid
        end

        pcall(function()
            Controls:Enable()
        end)
    end

    -- =========================================================
    -- INICIA EM DESYNC
    -- =========================================================

    desync()

    -- =========================================================
    -- RETORNA API
    -- =========================================================

    return API

end)()
