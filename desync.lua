return (function()

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")

    local player = Players.LocalPlayer
    local camera = workspace.CurrentCamera

    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    character.Archivable = true

    local fake
    local fh

    local Controls = require(
        player.PlayerScripts:WaitForChild("PlayerModule")
    ):GetControls()

    local running = false
    local renderConnection

    local tracks = {}
    local currentTrack

    local jumpHeld = false

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
                track:Stop(0)
            end

        end

        currentTrack = nil
    end

    -- =========================================================
    -- CRIAR FAKE
    -- =========================================================

    local function createFake()

        character.Archivable = true

        fake = character:Clone()
        fake.Name = "FakeCharacter"
        fake.Parent = workspace

        fh = fake:WaitForChild("Humanoid")

        loadAnimations()

        camera.CameraSubject = fh
    end

    -- =========================================================
    -- LOOP DO DESYNC
    -- =========================================================

    local function startDesync()

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
                    or not fh then

                    return
                end

                -- =============================================
                -- REAL ANCORADO
                -- =============================================

                if character.PrimaryPart then
                    character.PrimaryPart.Anchored = true
                end

                -- =============================================
                -- MOVIMENTO DO FAKE
                -- =============================================

                local moveVector =
                    Controls:GetMoveVector()

                fh:Move(moveVector, true)

                fh.Jump = jumpHeld

                -- =============================================
                -- ANIMAÇÃO
                -- =============================================

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

                if state ==
                    Enum.HumanoidStateType.Climbing then

                    if horizontalSpeed > 0.05 then
                        playTrack(tracks.climb, 1)
                    else
                        playTrack(tracks.climb, 0)
                    end

                elseif state ==
                    Enum.HumanoidStateType.Jumping then

                    playTrack(tracks.jump, 1)

                elseif state ==
                    Enum.HumanoidStateType.Freefall then

                    playTrack(tracks.fall, 1)

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

                else

                    playTrack(tracks.idle, 1)

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

        if not fake or not fake.Parent then
            return
        end

        -- PARA O LOOP PRIMEIRO
        running = false

        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end

        -- PEGA O ROOT DO FAKE
        local fakeRoot =
            fake:FindFirstChild("HumanoidRootPart")

        local realRoot =
            character:FindFirstChild("HumanoidRootPart")

        -- =====================================================
        -- TP REAL -> FAKE
        -- =====================================================

        if fakeRoot and realRoot then

            realRoot.Anchored = false

            realRoot.CFrame =
                fakeRoot.CFrame

        end

        -- =====================================================
        -- DELETA FAKE
        -- =====================================================

        fake:Destroy()

        fake = nil
        fh = nil

        -- =====================================================
        -- REAL LIVRE
        -- =====================================================

        if realRoot then
            realRoot.Anchored = false
        end

        -- =====================================================
        -- CAMERA REAL
        -- =====================================================

        camera.CameraSubject = humanoid

        stopAll()
    end

    -- =========================================================
    -- DESYNC
    -- =========================================================

    local function desync()

        if running then
            return
        end

        -- Se existir um Fake antigo, remove
        if fake then
            fake:Destroy()
            fake = nil
            fh = nil
        end

        -- Garante que o Real está livre
        local realRoot =
            character:FindFirstChild("HumanoidRootPart")

        if realRoot then
            realRoot.Anchored = false
        end

        createFake()

        startDesync()
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
        stopAll()
    end

    function API.destroy()

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

        local root =
            character:FindFirstChild("HumanoidRootPart")

        if root then
            root.Anchored = false
        end

        camera.CameraSubject = humanoid
    end

    -- =========================================================
    -- COMEÇA EM DESYNC
    -- =========================================================

    desync()

    return API

end)()
