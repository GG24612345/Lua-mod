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

local BACKUP_FOLDER_NAME = "__HRPBackup"
local BACKUP_HRP_NAME = "HRPBackup"


--------------------------------------------------
-- CHARACTER
--------------------------------------------------

local function getCharacter()
    return Player.Character or Player.CharacterAdded:Wait()
end


--------------------------------------------------
-- HRP
--------------------------------------------------

local function getHRP()
    local Character = getCharacter()

    return Character:WaitForChild("HumanoidRootPart")
end


--------------------------------------------------
-- BACKUP FOLDER
--------------------------------------------------

local function getBackupFolder()
    local Character = getCharacter()

    local Folder = Character:FindFirstChild(BACKUP_FOLDER_NAME)

    if not Folder then
        Folder = Instance.new("Folder")
        Folder.Name = BACKUP_FOLDER_NAME
        Folder.Parent = Character
    end

    return Folder
end


--------------------------------------------------
-- CREATE HRP BACKUP
--
-- SOMENTE O HRP É BACKUPADO
--------------------------------------------------

local function createHRPBackup()

    local HRP = getHRP()
    local Folder = getBackupFolder()

    --------------------------------------------------
    -- Remove backup antigo
    --------------------------------------------------

    local OldBackup = Folder:FindFirstChild(BACKUP_HRP_NAME)

    if OldBackup then
        OldBackup:Destroy()
    end


    --------------------------------------------------
    -- CLONA O HRP
    --------------------------------------------------

    local Backup = HRP:Clone()

    Backup.Name = BACKUP_HRP_NAME


    --------------------------------------------------
    -- Coloca na pasta
    --------------------------------------------------

    Backup.Parent = Folder

    return Backup
end


--------------------------------------------------
-- CRIA O BACKUP AO CARREGAR
--------------------------------------------------

createHRPBackup()


--------------------------------------------------
-- DESYNC
--------------------------------------------------

function API.desync()

    local HRP = getHRP()

    --------------------------------------------------
    -- ATUALIZA O BACKUP DO HRP
    --------------------------------------------------

    createHRPBackup()


    --------------------------------------------------
    -- REMOVE RootAttachment
    --------------------------------------------------

    local RootAttachment =
        HRP:FindFirstChild("RootAttachment")

    if RootAttachment then
        RootAttachment:Destroy()
    end


    --------------------------------------------------
    -- REMOVE RootRigAttachment
    --------------------------------------------------

    local RootRigAttachment =
        HRP:FindFirstChild("RootRigAttachment")

    if RootRigAttachment then
        RootRigAttachment:Destroy()
    end

end


--------------------------------------------------
-- SYNC
--------------------------------------------------

function API.sync()

    local Character = getCharacter()

    --------------------------------------------------
    -- PEGA O HRP ATUAL
    --------------------------------------------------

    local OldHRP =
        Character:FindFirstChild("HumanoidRootPart")

    if not OldHRP then
        return
    end


    --------------------------------------------------
    -- PEGA A POSIÇÃO DO HRP QUE SERÁ REMOVIDO
    --------------------------------------------------

    local OldCFrame = OldHRP.CFrame


    --------------------------------------------------
    -- PEGA A PASTA DE BACKUP
    --------------------------------------------------

    local Folder =
        getBackupFolder()


    --------------------------------------------------
    -- PEGA O HRP BACKUP
    --------------------------------------------------

    local Backup =
        Folder:FindFirstChild(BACKUP_HRP_NAME)

    if not Backup then
        return
    end


    --------------------------------------------------
    -- CLONA O HRP BACKUP
    --------------------------------------------------

    local NewHRP =
        Backup:Clone()


    --------------------------------------------------
    -- NOME CORRETO
    --------------------------------------------------

    NewHRP.Name =
        "HumanoidRootPart"


    --------------------------------------------------
    -- COLOCA EXATAMENTE NO LUGAR
    -- DO HRP ANTIGO
    --------------------------------------------------

    NewHRP.CFrame =
        OldCFrame


    --------------------------------------------------
    -- DELETA O HRP ANTIGO
    --------------------------------------------------

    OldHRP:Destroy()


    --------------------------------------------------
    -- COLOCA O HRP CLONADO NO CHARACTER
    --------------------------------------------------

    NewHRP.Parent =
        Character


    --------------------------------------------------
    -- GARANTE A POSIÇÃO NOVAMENTE
    --------------------------------------------------

    NewHRP.CFrame =
        OldCFrame


    --------------------------------------------------
    -- MUDA A CAMERA PARA O HRP CLONADO
    --------------------------------------------------

    Camera.CameraSubject =
        NewHRP

end


--------------------------------------------------
-- RETURN
--------------------------------------------------

return API
