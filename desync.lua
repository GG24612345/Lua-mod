-- CharacterController.lua

return function()

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")

    local player = Players.LocalPlayer

    local character =
        player.Character or player.CharacterAdded:Wait()

    local humanoid =
        character:WaitForChild("Humanoid")

    local camera = workspace.CurrentCamera

    -- =========================================================
    -- PERSONAGENS
    -- =========================================================

    character.Archivable = true

    local fake = character:Clone()
    fake.Name = "FakeCharacter"
    fake.Parent = workspace

    local fh = fake:WaitForChild("Humanoid")

    local animator =
        fh:FindFirstChildOfClass("Animator")

    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = fh
    end

    camera.CameraSubject = fh

    -- =========================================================
    -- CONTROLES
    -- =========================================================

    local Controls = require(
        player.PlayerScripts:WaitForChild("PlayerModule")
    ):GetControls()

    -- =========================================================
    -- ANIMATE ORIGINAL
    -- =========================================================

    local originalAnimate =
        character:FindFirstChild("Animate")

    local tracks = {}

    local function getAnimation(
        folderName,
        animationName
    )

        if not originalAnimate then
            return nil
        end

        local folder =
            originalAnimate:FindFirstChild(folderName)

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
        folderName,
        animationName,
        priority,
        looped
    )

        local animation =
            getAnimation(
                folderName,
                animationName
            )

        if not animation then
            return nil
        end

        local track =
            animator:LoadAnimation(animation)

        track.Priority = priority
        track.Looped = looped

        return track
    end

    -- =========================================================
    -- TRACKS
    -- =========================================================

    tracks.idle = loadTrack(
        "idle",
        "Animation1",
        Enum.AnimationPriority.Idle,
        true
    )

    tracks.walk = loadTrack(
        "run",
        "RunAnim",
        Enum.AnimationPriority.Movement,
        true
    )

    tracks.run = loadTrack(
        "run",
        "RunAnim",
        Enum.AnimationPriority.Movement,
        true
    )

    tracks.jump = loadTrack(
        "jump",
        "JumpAnim",
        Enum.AnimationPriority.Movement,
        false
    )

    tracks.fall = loadTrack(
        "fall",
        "FallAnim",
        Enum.AnimationPriority.Movement,
        true
    )

    tracks.climb = loadTrack(
        "climb",
        "ClimbAnim",
        Enum.AnimationPriority.Movement,
        true
    )

    -- =========================================================
    -- CONTROLE DAS ANIMAÇÕES
    -- =========================================================

    local currentTrack = nil

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
                    track:Stop(0.15)
                end)
            end

        end

        currentTrack = nil
    end

    -- =========================================================
    -- ESTADO CUSTOMIZADO
    -- =========================================================

    local forcedState = nil

    local stateMap = {

        Idle =
            Enum.HumanoidStateType.Running,

        Running =
            Enum.HumanoidStateType.Running,

        Walking =
            Enum.HumanoidStateType.Running,

        Jumping =
            Enum.HumanoidStateType.Jumping,

        Freefall =
            Enum.HumanoidStateType.Freefall,

        Falling =
            Enum.HumanoidStateType.Freefall,

        Climbing =
            Enum.HumanoidStateType.Climbing,

        Swimming =
            Enum.HumanoidStateType.Swimming,

        Seated =
            Enum.HumanoidStateType.Seated,

        Dead =
            Enum.HumanoidStateType.Dead
    }

    local function setState(state)

        if state == nil then
            forcedState = nil
            return
        end

        if typeof(state) == "string" then
            state = stateMap[state]
        end

        if typeof(state) ~= "EnumItem" then
            error("setState: estado inválido")
        end

        forcedState = state
    end

    -- =========================================================
    -- PULO
    -- =========================================================

    local jumpHeld = false

    local jumpRequestConnection =
        UserInputService.JumpRequest:Connect(
            function()

                jumpHeld = true

            end
        )

    local inputEndedConnection =
        UserInputService.InputEnded:Connect(
            function(input)

                if input.KeyCode ==
                    Enum.KeyCode.Space
                    or
                    input.KeyCode ==
                    Enum.KeyCode.ButtonA then

                    jumpHeld = false

                end

            end
        )

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

        jumpButton.InputBegan:Connect(
            function(input)

                if input.UserInputType ==
                    Enum.UserInputType.Touch then

                    jumpHeld = true

                end

            end
        )

        jumpButton.InputEnded:Connect(
            function(input)

                if input.UserInputType ==
                    Enum.UserInputType.Touch then

                    jumpHeld = false

                end

            end
        )

    end)

    -- =========================================================
    -- LOOP
    -- =========================================================

    local renderConnection = nil

    local running = true

    local function startLoop()

        if renderConnection then
            renderConnection:Disconnect()
        end

        running = true

        renderConnection =
            RunService.RenderStepped:Connect(
                function()

                    if not running then
                        return
                    end

                    if not character.Parent then
                        return
                    end

                    if not fake
                        or not fake.Parent then
                        return
                    end

                    local moveVector =
                        Controls:GetMoveVector()

                    -- REAL FICA PARADO
                    if character.PrimaryPart then
                        character.PrimaryPart.Anchored = true
                    end

                    -- FAKE RECEBE O MOVIMENTO
                    fh:Move(
                        moveVector,
                        true
                    )

                    fh.Jump = jumpHeld

                    local state

                    if forcedState then
                        state = forcedState
                    else
                        state = fh:GetState()
                    end

                    local velocity =
                        fh.RootPart
                        and
                        fh.RootPart.AssemblyLinearVelocity
                        or
                        Vector3.zero

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

                end
            )
    end

    -- =========================================================
    -- SYNC
    -- =========================================================

    local function sync()

        if not fake or not fake.Parent then
            return
        end

        -- PARA O LOOP
        running = false

        if renderConnection then

            renderConnection:Disconnect()
            renderConnection = nil

        end

        -- PEGA A POSIÇÃO DO FAKE
        local fakeCFrame =
            fake:GetPivot()

        -- DESANCLA O REAL
        if character.PrimaryPart then
            character.PrimaryPart.Anchored = false
        end

        -- TP REAL -> FAKE
        character:PivotTo(fakeCFrame)

        -- DELETA FAKE
        fake:Destroy()

        fake = nil

        -- CÂMERA -> REAL
        camera.CameraSubject = humanoid

        -- CONTROLES -> REAL
        pcall(function()
            Controls:Enable()
        end)

        stopAll()
    end

    -- =========================================================
    -- DESYNC
    -- =========================================================

    local function desync()

        if running then
            return
        end

        -- Cria novo Fake
        character.Archivable = true

        fake = character:Clone()

        fake.Name = "FakeCharacter"

        fake.Parent = workspace

        fh =
            fake:WaitForChild("Humanoid")

        animator =
            fh:FindFirstChildOfClass("Animator")

        if not animator then

            animator =
                Instance.new("Animator")

            animator.Parent = fh

        end

        -- Recarrega animações
        tracks = {}

        tracks.idle = loadTrack(
            "idle",
            "Animation1",
            Enum.AnimationPriority.Idle,
            true
        )

        tracks.walk = loadTrack(
            "run",
            "RunAnim",
            Enum.AnimationPriority.Movement,
            true
        )

        tracks.run = loadTrack(
            "run",
            "RunAnim",
            Enum.AnimationPriority.Movement,
            true
        )

        tracks.jump = loadTrack(
            "jump",
            "JumpAnim",
            Enum.AnimationPriority.Movement,
            false
        )

        tracks.fall = loadTrack(
            "fall",
            "FallAnim",
            Enum.AnimationPriority.Movement,
            true
        )

        tracks.climb = loadTrack(
            "climb",
            "ClimbAnim",
            Enum.AnimationPriority.Movement,
            true
        )

        camera.CameraSubject = fh

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
        return fh
    end

    function API.getCamera()
        return camera
    end

    function API.setState(state)
        setState(state)
    end

    function API.getState()

        if forcedState then
            return forcedState
        end

        if fh then
            return fh:GetState()
        end

        return nil
    end

    function API.getTracks()
        return tracks
    end

    function API.stopAnimations()
        stopAll()
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

        if character.PrimaryPart then
            character.PrimaryPart.Anchored = false
        end

        camera.CameraSubject = humanoid
    end

    return API

end
