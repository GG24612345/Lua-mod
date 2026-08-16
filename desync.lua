--[[
    Attachment Desync/Sync
    GitHub / loadstring ready

    Uso:
        local Desync = loadstring(game:HttpGet("SEU_RAW_GITHUB_AQUI"))()

        Desync.desync()
        Desync.sync()
]]

local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local API = {}

local BACKUP_FOLDER_NAME = "__AttachmentBackup"

local function getCharacter()
    return Player.Character or Player.CharacterAdded:Wait()
end

local function getHRP()
    local Character = getCharacter()
    return Character:WaitForChild("HumanoidRootPart")
end

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

-- Cria o backup dos attachments
local function createBackup()
    local HRP = getHRP()
    local Folder = getBackupFolder()

    -- Evita duplicatas
    for _, Name in ipairs({
        "RootAttachment",
        "RootRigAttachment"
    }) do
        if not Folder:FindFirstChild(Name) then
            local Attachment = HRP:FindFirstChild(Name)

            if Attachment and Attachment:IsA("Attachment") then
                local Clone = Attachment:Clone()
                Clone.Parent = Folder
            end
        end
    end
end

-- Deleta os attachments do HRP
function API.desync()
    local HRP = getHRP()

    -- Garante que o backup existe antes de deletar
    createBackup()

    local RootAttachment = HRP:FindFirstChild("RootAttachment")
    if RootAttachment and RootAttachment:IsA("Attachment") then
        RootAttachment:Destroy()
    end

    local RootRigAttachment = HRP:FindFirstChild("RootRigAttachment")
    if RootRigAttachment and RootRigAttachment:IsA("Attachment") then
        RootRigAttachment:Destroy()
    end
end

-- Restaura os attachments
function API.sync()
    local HRP = getHRP()
    local Folder = getBackupFolder()

    -- Remove versões existentes para evitar duplicação
    local ExistingRoot = HRP:FindFirstChild("RootAttachment")
    if ExistingRoot then
        ExistingRoot:Destroy()
    end

    local ExistingRig = HRP:FindFirstChild("RootRigAttachment")
    if ExistingRig then
        ExistingRig:Destroy()
    end

    -- Restaura RootAttachment
    local RootAttachment = Folder:FindFirstChild("RootAttachment")

    if RootAttachment and RootAttachment:IsA("Attachment") then
        local Clone = RootAttachment:Clone()
        Clone.Parent = HRP
    end

    -- Restaura RootRigAttachment
    local RootRigAttachment = Folder:FindFirstChild("RootRigAttachment")

    if RootRigAttachment and RootRigAttachment:IsA("Attachment") then
        local Clone = RootRigAttachment:Clone()
        Clone.Parent = HRP
    end
end

-- Cria o backup imediatamente
createBackup()

return API
