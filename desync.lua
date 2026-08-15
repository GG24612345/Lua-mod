return (function()

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")

    local player = Players.LocalPlayer
    local camera = workspace.CurrentCamera

    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    character.Archivable = true

    local fake = nil
    local fakeHumanoid = nil

    local renderConnection = nil

    local Controls = require(
        player.PlayerScripts:WaitForChild("PlayerModule")
    ):GetControls()

    local running = false

    local jumpHeld = false

    local tracks = {}
    local currentTrack = nil

    -- =========================================================
    -- ANIMAÇÕES
    -- =========================================================

    local function getAnimation(folderName, animationName)

        local animate = character:FindFirstChild("Animate")

        if not animate then
            return nil
        end

        local folder = animate:FindFirstChild(folderName)

        if not folder then
            return nil
        end

        return folder:FindFirstChild(animationName)
            or folder:FindFirstChildWhichIsA("Animation")
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

        if not fakeHumanoid then
            return
        end

        local animator =
            fakeHumanoid:FindFirstChildOfClass("Animator")

        if not animator then

            animator = Instance.new("Animator")
            animator.Parent = fakeHumanoid

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

    local function stopAnimations()

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
            return
        end

        character.Archivable = true

        fake = character:Clone()
        fake.Name = "FakeCharacter"
        fake.Parent = workspace

        local root =
            fake:FindFirstChild("HumanoidRootPart")

        if root then
            fake.PrimaryPart = root
        end

        fakeHumanoid =
            fake:WaitForChild("Humanoid")

        loadAnimations()

        camera.CameraType =
            Enum.CameraType.Custom

        camera.CameraSubject =
            fakeHumanoid
    end

    -- =========================================================
    -- LOOP DESYNC
    -- =========================================================

    local function startLoop()

        if renderConnection then
            renderConnection:Disconnect()
        end

        running = true

        renderConnection =
            RunService.RenderStepped:Connect(function()

                if not running then
                    return
                end

                if not fake
                    or not fake.Parent
                    or not fakeHumanoid then

                    return
                end

                -- REAL FICA PARADO
                local realRoot =
                    character:FindFirstChild(
                        "HumanoidRootPart"
                    )

                if realRoot then
                    realRoot.Anchored = true
                end

                -- MOVIMENTO DO FAKE
                local moveVector =
                    Controls:GetMoveVector()

                fakeHumanoid:Move(
                    moveVector,
                    true
                )

                fakeHumanoid.Jump =
                    jumpHeld

                -- ESTADO
                local state =
                    fakeHumanoid:GetState()

                local velocity =
                    fakeHumanoid.RootPart
                    and fakeHumanoid.RootPart.AssemblyLinearVelocity
                    or Vector3.zero

                local horizontalSpeed =
                    Vector3.new(
                        velocity.X,
                        0,
                        velocity.Z
                    ).Magnitude

                -- CLIMB
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

                -- JUMP
                elseif state ==
                    Enum.HumanoidStateType.Jumping then

                    playTrack(
                        tracks.jump,
                        1
                    )

                -- FALL
                elseif state ==
                    Enum.HumanoidStateType.Freefall then

                    playTrack(
                        tracks.fall,
                        1
                    )

                -- WALK
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

                -- IDLE
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

            character.Archivable = true
        end

        -- Garante que o Real está livre
        local realRoot =
            character:FindFirstChild(
                "HumanoidRootPart"
            )

        if realRoot then
            realRoot.Anchored = false
        end

        createFake()

        startLoop()

        camera.CameraType =
            Enum.CameraType.Custom

        camera.CameraSubject =
            fakeHumanoid
    end

    -- =========================================================
    -- SYNC
    -- =========================================================

    local function sync()

        if not fake or not fake.Parent then
            return
        end

        -- =====================================================
        -- 1. PARA O LOOP
        -- =====================================================

        running = false

        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end

        -- =====================================================
        -- 2. SALVA A POSIÇÃO DO FAKE
        -- =====================================================

        local fakeCFrame =
            fake:GetPivot()

        -- =====================================================
        -- 3. PEGA O ROOT REAL
        -- =====================================================

        local realRoot =
            character:FindFirstChild(
                "HumanoidRootPart"
            )

        -- =====================================================
        -- 4. DESANCORA O REAL
        -- =====================================================

        if realRoot then
            realRoot.Anchored = false
        end

        -- =====================================================
        -- 5. TP REAL -> FAKE
        -- =====================================================

        character:PivotTo(fakeCFrame)

        -- =====================================================
        -- 6. GARANTE O TP PELO ROOT
        -- =====================================================

        if realRoot then
            realRoot.CFrame = fakeCFrame
        end

        -- =====================================================
        -- 7. DELETA O FAKE
        -- =====================================================

        fake:Destroy()

        fake = nil
        fakeHumanoid = nil

        -- =====================================================
        -- 8. REAL DESANCORADO
        -- =====================================================

        if realRoot then
            realRoot.Anchored = false
        end

        if character.PrimaryPart then
            character.PrimaryPart.Anchored = false
        end

        -- =====================================================
        -- 9. HUMANOID REAL
        -- =====================================================

        humanoid.PlatformStand = false
        humanoid.AutoRotate = true

        -- =====================================================
        -- 10. CÂMERA REAL
        -- =====================================================

        camera.CameraType =
            Enum.CameraType.Custom

        camera.CameraSubject =
            humanoid

        -- =====================================================
        -- 11. ANIMAÇÕES
        -- =====================================================

        stopAnimations()

        -- =====================================================
        -- 12. CONTROLES
        -- =====================================================

        pcall(function()
            Controls:Enable()
        end)

    end

    -- =========================================================
    -- PULO
    -- =========================================================

    UserInputService.JumpRequest:Connect(function()

        if running then
            jumpHeld = true
        end

    end)

    UserInputService.InputEnded:Connect(function(input)

        if input.KeyCode == Enum.KeyCode.Space
            or input.KeyCode == Enum.KeyCode.ButtonA then

            jumpHeld = false

        end

    end)

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
        return fakeHumanoid
    end

    function API.isDesynced()
        return running
    end

    function API.sync()
        sync()
    end

    function API.desync()
        desync()
    end

    function API.stopAnimations()
        stopAnimations()
    end

    function API.destroy()

        running = false

        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end

        stopAnimations()

        if fake then
            fake:Destroy()
        end

        fake = nil
        fakeHumanoid = nil

        local root =
            character:FindFirstChild(
                "HumanoidRootPart"
            )

        if root then
            root.Anchored = false
        end

        camera.CameraType =
            Enum.CameraType.Custom

        camera.CameraSubject =
            humanoid

        pcall(function()
            Controls:Enable()
        end)

    end

    -- =========================================================
    -- INICIA EM DESYNC
    -- =========================================================

    desync()

    return API

end)()
