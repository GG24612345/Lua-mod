return (function()

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")

    local player = Players.LocalPlayer
    local camera = workspace.CurrentCamera

    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local realRoot = character:WaitForChild("HumanoidRootPart")

    character.Archivable = true

    local Controls = require(
        player.PlayerScripts:WaitForChild("PlayerModule")
    ):GetControls()

    local fake = nil
    local fakeHumanoid = nil
    local fakeRoot = nil

    local renderConnection = nil

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

    local function playTrack(track, speed)

        if not track then
            return
        end

        if currentTrack ~= track then

            if currentTrack then
                pcall(function()
                    currentTrack:Stop(0.15)
                end)
            end

            currentTrack = track

            pcall(function()
                track:Play(0.15)
            end)

        end

        pcall(function()
            track:AdjustSpeed(speed or 1)
        end)
    end

    -- =========================================================
    -- CRIA FAKE
    -- =========================================================

    local function createFake()

        if fake then
            pcall(function()
                fake:Destroy()
            end)
        end

        character.Archivable = true

        fake = character:Clone()
        fake.Name = "FakeCharacter"
        fake.Parent = workspace

        fakeRoot =
            fake:FindFirstChild("HumanoidRootPart")

        fakeHumanoid =
            fake:FindFirstChildOfClass("Humanoid")

        if not fakeRoot or not fakeHumanoid then
            return false
        end

        fake.PrimaryPart = fakeRoot

        loadAnimations()

        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = fakeHumanoid

        return true
    end

    -- =========================================================
    -- LOOP DO DESYNC
    -- =========================================================

    local function startLoop()

        if renderConnection then

            renderConnection:Disconnect()
            renderConnection = nil

        end

        running = true

        renderConnection =
            RunService.RenderStepped:Connect(function()

                if not running then
                    return
                end

                if not fake
                    or not fake.Parent
                    or not fakeHumanoid
                    or not fakeRoot then

                    return
                end

                -- =============================================
                -- REAL PARADO
                -- =============================================

                realRoot.Anchored = true

                -- =============================================
                -- MOVIMENTO NO FAKE
                -- =============================================

                local moveVector =
                    Controls:GetMoveVector()

                fakeHumanoid:Move(
                    moveVector,
                    true
                )

                fakeHumanoid.Jump = jumpHeld

                -- =============================================
                -- VELOCIDADE
                -- =============================================

                local velocity =
                    fakeRoot.AssemblyLinearVelocity

                local horizontalSpeed =
                    Vector3.new(
                        velocity.X,
                        0,
                        velocity.Z
                    ).Magnitude

                -- =============================================
                -- ESTADO
                -- =============================================

                local state =
                    fakeHumanoid:GetState()

                -- =============================================
                -- CLIMB
                -- =============================================

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
    -- SYNC
    -- =========================================================

    local function sync()

        if not fake
            or not fake.Parent
            or not fakeRoot then

            return
        end

        -- =====================================================
        -- 1. PARA O DESYNC
        -- =====================================================

        running = false

        if renderConnection then

            renderConnection:Disconnect()
            renderConnection = nil

        end

        -- =====================================================
        -- 2. GUARDA A POSIÇÃO DO FAKE
        -- =====================================================

        local targetCFrame =
            fakeRoot.CFrame

        -- =====================================================
        -- 3. PARA ANIMAÇÕES
        -- =====================================================

        stopAnimations()

        -- =====================================================
        -- 4. DESANCORA O REAL
        -- =====================================================

        realRoot.Anchored = false

        -- =====================================================
        -- 5. TELEPORTA O REAL PARA O FAKE
        -- =====================================================

        character:PivotTo(targetCFrame)

        -- Garante a posição exata do RootPart
        realRoot.CFrame = targetCFrame

        -- Remove velocidade anterior
        realRoot.AssemblyLinearVelocity = Vector3.zero
        realRoot.AssemblyAngularVelocity = Vector3.zero

        -- =====================================================
        -- 6. DELETA O FAKE
        -- =====================================================

        fake:Destroy()

        fake = nil
        fakeHumanoid = nil
        fakeRoot = nil

        -- =====================================================
        -- 7. REAL LIVRE
        -- =====================================================

        realRoot.Anchored = false

        humanoid.PlatformStand = false
        humanoid.AutoRotate = true

        -- =====================================================
        -- 8. CÂMERA NO REAL
        -- =====================================================

        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoid

        -- =====================================================
        -- 9. CONTROLES NO REAL
        -- =====================================================

        pcall(function()
            Controls:Enable()
        end)

    end

    -- =========================================================
    -- DESYNC
    -- =========================================================

    local function desync()

        if running then
            return
        end

        -- Cria Fake
        if not createFake() then
            return
        end

        -- Garante que o Real está ancorado
        realRoot.Anchored = true

        -- Começa o loop
        startLoop()

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
        return fakeHumanoid
    end

    function API.getRealRoot()
        return realRoot
    end

    function API.getFakeRoot()
        return fakeRoot
    end

    function API.sync()
        sync()
    end

    function API.desync()
        desync()
    end

    function API.isDesynced()
        return running
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
        fakeRoot = nil

        realRoot.Anchored = false

        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoid

        pcall(function()
            Controls:Enable()
        end)

    end

    -- =========================================================
    -- INICIA DESYNC
    -- =========================================================

    desync()

    return API

end)()
