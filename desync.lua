--[[
    DESYNC / SYNC
    Attachment + RootJoint restore
    GitHub / loadstring ready

    Uso:

    local Desync = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/GG24612345/Lua-mod/refs/heads/main/desync.lua"
    ))()

    Desync.desync()
    Desync.sync()
]]

local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local API = {}

local BACKUP_FOLDER_NAME = "__AttachmentBackup"


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

    local Folder = Character:FindFirstChild(BACKUP_FOLDER_NAME)

    if not Folder then
        Folder = Instance.new("Folder")
        Folder.Name = BACKUP_FOLDER_NAME
        Folder.Parent = Character
    end

    return Folder
end


--------------------------------------------------
-- BACKUP ATTACHMENT
--------------------------------------------------

local function backupAttachment(Name)
    local HRP = getHRP()
    local Folder = getBackupFolder()

    -- Já existe backup
    if Folder:FindFirstChild(Name) then
        return
    end

    local Attachment = HRP:FindFirstChild(Name)

    if Attachment and Attachment:IsA("Attachment") then
        local Clone = Attachment:Clone()

        Clone.Parent = Folder
    end
end


--------------------------------------------------
-- BACKUP ROOT JOINT
--------------------------------------------------

local function findRootJoint()
    local Character = getCharacter()
    local HRP = Character:FindFirstChild("HumanoidRootPart")

    if not HRP then
        return nil
    end

    -- R15 normalmente usa Root
    local Root = HRP:FindFirstChild("Root")

    if Root and Root:IsA("Motor6D") then
        return Root
    end

    -- Algumas estruturas usam RootJoint
    local RootJoint = HRP:FindFirstChild("RootJoint")

    if RootJoint and RootJoint:IsA("Motor6D") then
        return RootJoint
    end

    -- Procura em todo o Character
    for _, Object in ipairs(Character:GetDescendants()) do
        if Object:IsA("Motor6D") then
            if Object.Name == "Root" or Object.Name == "RootJoint" then
                return Object
            end
        end
    end

    return nil
end


local function backupRootJoint()
    local Folder = getBackupFolder()

    if Folder:FindFirstChild("__RootJointBackup") then
        return
    end

    local RootJoint = findRootJoint()

    if not RootJoint then
        return
    end

    local Clone = RootJoint:Clone()

    Clone.Name = "__RootJointBackup"

    Clone.Parent = Folder
end


--------------------------------------------------
-- CREATE BACKUP
--------------------------------------------------

local function createBackup()
    getHRP()
    getBackupFolder()

    backupAttachment("RootAttachment")
    backupAttachment("RootRigAttachment")

    backupRootJoint()
end


--------------------------------------------------
-- DESYNC
--------------------------------------------------

function API.desync()

    local HRP = getHRP()

    -- Faz backup antes de remover
    createBackup()

    --------------------------------------------------
    -- Remove RootAttachment
    --------------------------------------------------

    local RootAttachment = HRP:FindFirstChild("RootAttachment")

    if RootAttachment and RootAttachment:IsA("Attachment") then
        RootAttachment:Destroy()
    end


    --------------------------------------------------
    -- Remove RootRigAttachment
    --------------------------------------------------

    local RootRigAttachment = HRP:FindFirstChild("RootRigAttachment")

    if RootRigAttachment and RootRigAttachment:IsA("Attachment") then
        RootRigAttachment:Destroy()
    end

end


--------------------------------------------------
-- RESTORE ATTACHMENT
--------------------------------------------------

local function restoreAttachment(Name)

    local HRP = getHRP()
    local Folder = getBackupFolder()

    --------------------------------------------------
    -- Remove current
    --------------------------------------------------

    local Current = HRP:FindFirstChild(Name)

    if Current then
        Current:Destroy()
    end


    --------------------------------------------------
    -- Get backup
    --------------------------------------------------

    local Backup = Folder:FindFirstChild(Name)

    if not Backup then
        return
    end

    if not Backup:IsA("Attachment") then
        return
    end


    --------------------------------------------------
    -- Clone
    --------------------------------------------------

    local Clone = Backup:Clone()

    Clone.Parent = HRP
end


--------------------------------------------------
-- RESTORE ROOT JOINT
--------------------------------------------------

local function restoreRootJoint()

    local Character = getCharacter()
    local HRP = Character:FindFirstChild("HumanoidRootPart")

    if not HRP then
        return
    end

    local Folder = getBackupFolder()

    local RootJoint = findRootJoint()

    --------------------------------------------------
    -- Se o RootJoint já existe
    --------------------------------------------------

    if RootJoint then

        -- Reativa
        pcall(function()
            RootJoint.Enabled = true
        end)

        -- Remove transformação temporária
        pcall(function()
            RootJoint.Transform = CFrame.identity
        end)

        return
    end


    --------------------------------------------------
    -- RootJoint não existe
    -- restaura do backup
    --------------------------------------------------

    local Backup = Folder:FindFirstChild("__RootJointBackup")

    if not Backup then
        return
    end

    if not Backup:IsA("Motor6D") then
        return
    end


    local Clone = Backup:Clone()

    Clone.Name = Backup.Name:gsub("^__RootJointBackup$", "Root")


    --------------------------------------------------
    -- Descobre onde o joint original estava
    --------------------------------------------------

    local ParentPart = nil

    if Backup.Parent and Backup.Parent:IsA("BasePart") then
        ParentPart = Character:FindFirstChild(Backup.Parent.Name)
    end


    if ParentPart and ParentPart:IsA("BasePart") then
        Clone.Parent = ParentPart
    else
        Clone.Parent = HRP
    end


    --------------------------------------------------
    -- Corrige Part0 / Part1
    --------------------------------------------------

    local Part0Name = Backup.Part0 and Backup.Part0.Name
    local Part1Name = Backup.Part1 and Backup.Part1.Name

    if Part0Name then
        local Part0 = Character:FindFirstChild(Part0Name, true)

        if Part0 and Part0:IsA("BasePart") then
            Clone.Part0 = Part0
        end
    end

    if Part1Name then
        local Part1 = Character:FindFirstChild(Part1Name, true)

        if Part1 and Part1:IsA("BasePart") then
            Clone.Part1 = Part1
        end
    end


    pcall(function()
        Clone.Enabled = true
        Clone.Transform = CFrame.identity
    end)

end


--------------------------------------------------
-- SYNC
--------------------------------------------------

function API.sync()

    local HRP = getHRP()

    --------------------------------------------------
    -- Restaura os attachments
    --------------------------------------------------

    restoreAttachment("RootAttachment")

    restoreAttachment("RootRigAttachment")


    --------------------------------------------------
    -- Restaura a conexão do Root
    --------------------------------------------------

    restoreRootJoint()


    --------------------------------------------------
    -- Força o RootJoint existente a ficar ativo
    --------------------------------------------------

    local RootJoint = findRootJoint()

    if RootJoint then

        pcall(function()
            RootJoint.Enabled = true
        end)

        pcall(function()
            RootJoint.Transform = CFrame.identity
        end)

        --------------------------------------------------
        -- Garante que o Part0 seja o HRP
        --------------------------------------------------

        pcall(function()
            if RootJoint.Part0 == nil then
                RootJoint.Part0 = HRP
            end
        end)

    end

end


--------------------------------------------------
-- BACKUP INICIAL
--------------------------------------------------

createBackup()


--------------------------------------------------
-- RETURN
--------------------------------------------------

return API
