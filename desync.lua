--[[
    HRP DESYNC / SYNC
    GitHub / loadstring ready

    Uso:

    local API = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/GG24612345/Lua-mod/refs/heads/main/desync.lua"
    ))()

    API.desync()
    API.sync()
]]

local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local API = {}

local BACKUP_NAME = "__HRP_BACKUP"


--------------------------------------------------
-- CHARACTER
--------------------------------------------------

local function getCharacter()
    return Player.Character or Player.CharacterAdded:Wait()
end


local function getHRP()
    local Character = getCharacter()

    return Character:WaitForChild("HumanoidRootPart")
end


--------------------------------------------------
-- BACKUP FOLDER
--------------------------------------------------

local function getBackupFolder()
    local Character = getCharacter()

    local Folder = Character:FindFirstChild(BACKUP_NAME)

    if not Folder then
        Folder = Instance.new("Folder")
        Folder.Name = BACKUP_NAME
        Folder.Parent = Character
    end

    return Folder
end


--------------------------------------------------
-- CREATE HRP BACKUP
--------------------------------------------------

local function createBackup()

    local Character = getCharacter()
    local HRP = Character:WaitForChild("HumanoidRootPart")

    local Folder = getBackupFolder()

    local OldBackup = Folder:FindFirstChild("HumanoidRootPart")

    if OldBackup then
        OldBackup:Destroy()
    end

    --------------------------------------------------
    -- Clona o HRP inteiro
    --------------------------------------------------

    local Backup = HRP:Clone()

    Backup.Name = "HumanoidRootPart"

    --------------------------------------------------
    -- Desliga scripts/eventuais efeitos
    --------------------------------------------------

    for _, Object in ipairs(Backup:GetDescendants()) do

        if Object:IsA("Script")
            or Object:IsA("LocalScript") then

            Object.Disabled = true

        end

    end

    Backup.Parent = Folder

    return Backup
end


--------------------------------------------------
-- BACKUP INICIAL
--------------------------------------------------

createBackup()


--------------------------------------------------
-- DESYNC
--------------------------------------------------

function API.desync()

    local Character = getCharacter()
    local HRP = Character:FindFirstChild("HumanoidRootPart")

    if not HRP then
        return
    end

    --------------------------------------------------
    -- Atualiza o backup antes do desync
    --------------------------------------------------

    local Folder = getBackupFolder()

    local OldBackup = Folder:FindFirstChild("HumanoidRootPart")

    if OldBackup then
        OldBackup:Destroy()
    end

    local Backup = HRP:Clone()

    Backup.Name = "HumanoidRootPart"

    for _, Object in ipairs(Backup:GetDescendants()) do

        if Object:IsA("Script")
            or Object:IsA("LocalScript") then

            Object.Disabled = true

        end

    end

    Backup.Parent = Folder

end


--------------------------------------------------
-- RECONNECT MOTOR6DS
--------------------------------------------------

local function reconnectJoints(
    Character,
    OldHRP,
    NewHRP
)

    for _, Object in ipairs(Character:GetDescendants()) do

        if Object:IsA("Motor6D") then

            --------------------------------------------------
            -- O antigo HRP era Part0
            --------------------------------------------------

            if Object.Part0 == OldHRP then
                Object.Part0 = NewHRP
            end


            --------------------------------------------------
            -- O antigo HRP era Part1
            --------------------------------------------------

            if Object.Part1 == OldHRP then
                Object.Part1 = NewHRP
            end

        end

    end

end


--------------------------------------------------
-- SYNC
--------------------------------------------------

function API.sync()

    local Character = getCharacter()

    local OldHRP = Character:FindFirstChild("HumanoidRootPart")

    if not OldHRP then
        return
    end


    --------------------------------------------------
    -- Pega backup
    --------------------------------------------------

    local Folder = getBackupFolder()

    local Backup = Folder:FindFirstChild("HumanoidRootPart")

    if not Backup then

        -- Se por algum motivo não existir,
        -- cria novamente.

        Backup = createBackup()

        if not Backup then
            return
        end

    end


    --------------------------------------------------
    -- Guarda posição atual
    --------------------------------------------------

    local CurrentCFrame = OldHRP.CFrame


    --------------------------------------------------
    -- Clona o HRP do backup
    --------------------------------------------------

    local NewHRP = Backup:Clone()

    NewHRP.Name = "HumanoidRootPart"


    --------------------------------------------------
    -- Coloca temporariamente na posição atual
    --------------------------------------------------

    NewHRP.CFrame = CurrentCFrame


    --------------------------------------------------
    -- O backup não deve continuar sendo
    -- confundido com o HRP real
    --------------------------------------------------

    NewHRP.Parent = Character


    --------------------------------------------------
    -- Recoloca os joints no novo HRP
    --------------------------------------------------

    reconnectJoints(
        Character,
        OldHRP,
        NewHRP
    )


    --------------------------------------------------
    -- Remove o HRP antigo
    --------------------------------------------------

    if OldHRP and OldHRP ~= NewHRP then
        OldHRP:Destroy()
    end


    --------------------------------------------------
    -- Garante que o novo HRP tenha o nome correto
    --------------------------------------------------

    NewHRP.Name = "HumanoidRootPart"


    --------------------------------------------------
    -- Câmera volta para o personagem
    --------------------------------------------------

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")

    if Humanoid then
        Camera.CameraSubject = Humanoid
    else
        Camera.CameraSubject = NewHRP
    end

end


--------------------------------------------------
-- RETURN
--------------------------------------------------

return API
