local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local API = {}

local BACKUP_FOLDER_NAME = "__AttachmentBackup"

local ATTACHMENTS = {
    "RootAttachment",
    "RootRigAttachment"
}


--------------------------------------------------
-- CHARACTER
--------------------------------------------------

local function getCharacter()
    return Player.Character or Player.CharacterAdded:Wait()
end


local function getHRP()
    return getCharacter():WaitForChild("HumanoidRootPart")
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
-- VERIFICA SE O BACKUP JÁ EXISTE
--------------------------------------------------

local function backupExists()
    local Folder = getBackupFolder()

    local Attachments = Folder:FindFirstChild("Attachments")

    if not Attachments then
        return false
    end

    local Root = Attachments:FindFirstChild("RootAttachment")
    local Rig = Attachments:FindFirstChild("RootRigAttachment")

    return Root ~= nil and Rig ~= nil
end


--------------------------------------------------
-- ENCONTRA REFERÊNCIAS
--------------------------------------------------

local function findAttachmentReferences(HRP)

    local Results = {}

    local RootAttachment =
        HRP:FindFirstChild("RootAttachment")

    local RootRigAttachment =
        HRP:FindFirstChild("RootRigAttachment")

    for _, Object in ipairs(
        HRP.Parent:GetDescendants()
    ) do

        if Object ~= HRP then

            for _, Property in ipairs({
                "Attachment0",
                "Attachment1",
                "Attachment",
                "Adornee"
            }) do

                local Success, Value =
                    pcall(function()
                        return Object[Property]
                    end)

                if Success then

                    if Value == RootAttachment
                        or Value == RootRigAttachment then

                        table.insert(Results, {
                            Object = Object,
                            Property = Property,
                            TargetName = Value.Name
                        })

                        break
                    end

                end

            end

        end

    end

    return Results
end


--------------------------------------------------
-- CRIA BACKUP
--------------------------------------------------

local function createBackup()

    --------------------------------------------------
    -- Se já existe, NÃO cria outro
    --------------------------------------------------

    if backupExists() then
        return getBackupFolder()
    end


    local HRP = getHRP()
    local Folder = getBackupFolder()


    --------------------------------------------------
    -- Pasta dos attachments
    --------------------------------------------------

    local AttachmentFolder = Instance.new("Folder")

    AttachmentFolder.Name = "Attachments"

    AttachmentFolder.Parent = Folder


    --------------------------------------------------
    -- Backup RootAttachment
    --------------------------------------------------

    local RootAttachment =
        HRP:FindFirstChild("RootAttachment")

    if RootAttachment then

        RootAttachment:Clone().Parent =
            AttachmentFolder

    end


    --------------------------------------------------
    -- Backup RootRigAttachment
    --------------------------------------------------

    local RootRigAttachment =
        HRP:FindFirstChild("RootRigAttachment")

    if RootRigAttachment then

        RootRigAttachment:Clone().Parent =
            AttachmentFolder

    end


    --------------------------------------------------
    -- Pasta de dependências
    --------------------------------------------------

    local DependencyFolder = Instance.new("Folder")

    DependencyFolder.Name = "Dependencies"

    DependencyFolder.Parent = Folder


    --------------------------------------------------
    -- Encontra objetos que usam os attachments
    --------------------------------------------------

    local References =
        findAttachmentReferences(HRP)


    for Index, Info in ipairs(References) do

        local Object = Info.Object

        if Object
            and Object.Parent
            and Object:IsDescendantOf(HRP.Parent)
        then

            local Clone = Object:Clone()

            Clone.Name =
                "__Dependency_" .. Index


            --------------------------------------------------
            -- Metadados
            --------------------------------------------------

            local OriginalName =
                Instance.new("StringValue")

            OriginalName.Name = "OriginalName"
            OriginalName.Value = Object.Name
            OriginalName.Parent = Clone


            local OriginalClass =
                Instance.new("StringValue")

            OriginalClass.Name = "OriginalClass"
            OriginalClass.Value = Object.ClassName
            OriginalClass.Parent = Clone


            local PropertyName =
                Instance.new("StringValue")

            PropertyName.Name = "AttachmentProperty"
            PropertyName.Value = Info.Property
            PropertyName.Parent = Clone


            local TargetName =
                Instance.new("StringValue")

            TargetName.Name = "TargetAttachment"
            TargetName.Value = Info.TargetName
            TargetName.Parent = Clone


            --------------------------------------------------
            -- Guarda o caminho do parent
            --------------------------------------------------

            local ParentName =
                Instance.new("StringValue")

            ParentName.Name = "OriginalParent"
            ParentName.Value = Object.Parent.Name
            ParentName.Parent = Clone


            Clone.Parent = DependencyFolder

        end

    end


    return Folder
end


--------------------------------------------------
-- DESYNC
--------------------------------------------------

function API.desync()

    local HRP = getHRP()

    --------------------------------------------------
    -- Só cria backup se ainda não existir
    --------------------------------------------------

    createBackup()


    --------------------------------------------------
    -- Remove RootAttachment
    --------------------------------------------------

    local RootAttachment =
        HRP:FindFirstChild("RootAttachment")

    if RootAttachment then
        RootAttachment:Destroy()
    end


    --------------------------------------------------
    -- Remove RootRigAttachment
    --------------------------------------------------

    local RootRigAttachment =
        HRP:FindFirstChild("RootRigAttachment")

    if RootRigAttachment then
        RootRigAttachment:Destroy()
    end

end


--------------------------------------------------
-- RESTORE ATTACHMENTS
--------------------------------------------------

local function restoreAttachments()

    local HRP = getHRP()
    local Folder = getBackupFolder()

    local AttachmentFolder =
        Folder:FindFirstChild("Attachments")

    if not AttachmentFolder then
        return
    end


    --------------------------------------------------
    -- RootAttachment
    --------------------------------------------------

    local SavedRoot =
        AttachmentFolder:FindFirstChild("RootAttachment")

    if SavedRoot then

        local Current =
            HRP:FindFirstChild("RootAttachment")

        if Current then
            Current:Destroy()
        end

        SavedRoot:Clone().Parent = HRP

    end


    --------------------------------------------------
    -- RootRigAttachment
    --------------------------------------------------

    local SavedRig =
        AttachmentFolder:FindFirstChild("RootRigAttachment")

    if SavedRig then

        local Current =
            HRP:FindFirstChild("RootRigAttachment")

        if Current then
            Current:Destroy()
        end

        SavedRig:Clone().Parent = HRP

    end

end


--------------------------------------------------
-- RESTORE DEPENDENCIES
--------------------------------------------------

local function restoreDependencies()

    local Character = getCharacter()
    local HRP = getHRP()

    local Folder = getBackupFolder()

    local DependencyFolder =
        Folder:FindFirstChild("Dependencies")

    if not DependencyFolder then
        return
    end


    --------------------------------------------------
    -- Novos attachments
    --------------------------------------------------

    local RootAttachment =
        HRP:FindFirstChild("RootAttachment")

    local RootRigAttachment =
        HRP:FindFirstChild("RootRigAttachment")


    --------------------------------------------------
    -- Restaura dependências
    --------------------------------------------------

    for _, BackupObject in ipairs(
        DependencyFolder:GetChildren()
    ) do

        local OriginalName =
            BackupObject:FindFirstChild("OriginalName")

        local OriginalClass =
            BackupObject:FindFirstChild("OriginalClass")

        local PropertyName =
            BackupObject:FindFirstChild("AttachmentProperty")

        local TargetName =
            BackupObject:FindFirstChild("TargetAttachment")

        local OriginalParent =
            BackupObject:FindFirstChild("OriginalParent")


        if OriginalName
            and OriginalClass
            and PropertyName
            and TargetName
        then

            --------------------------------------------------
            -- Procura objeto antigo
            --------------------------------------------------

            for _, Existing in ipairs(
                Character:GetDescendants()
            ) do

                if Existing.Name == OriginalName.Value
                    and Existing.ClassName == OriginalClass.Value
                    and Existing ~= HRP
                then

                    pcall(function()
                        Existing:Destroy()
                    end)

                end

            end


            --------------------------------------------------
            -- Clona
            --------------------------------------------------

            local Clone =
                BackupObject:Clone()


            --------------------------------------------------
            -- Remove metadados
            --------------------------------------------------

            for _, Name in ipairs({
                "OriginalName",
                "OriginalClass",
                "AttachmentProperty",
                "TargetAttachment",
                "OriginalParent"
            }) do

                local Value =
                    Clone:FindFirstChild(Name)

                if Value then
                    Value:Destroy()
                end

            end


            --------------------------------------------------
            -- Encontra novo attachment
            --------------------------------------------------

            local NewAttachment

            if TargetName.Value ==
                "RootAttachment" then

                NewAttachment =
                    RootAttachment

            elseif TargetName.Value ==
                "RootRigAttachment" then

                NewAttachment =
                    RootRigAttachment

            end


            --------------------------------------------------
            -- Parent
            --------------------------------------------------

            local Parent

            if OriginalParent then

                Parent =
                    Character:FindFirstChild(
                        OriginalParent.Value,
                        true
                    )

            end

            Clone.Parent =
                Parent or Character


            --------------------------------------------------
            -- Reconecta
            --------------------------------------------------

            if NewAttachment then

                pcall(function()

                    Clone[
                        PropertyName.Value
                    ] = NewAttachment

                end)

            end

        end

    end

end


--------------------------------------------------
-- SYNC
--------------------------------------------------

function API.sync()

    --------------------------------------------------
    -- Primeiro os attachments
    --------------------------------------------------

    restoreAttachments()


    --------------------------------------------------
    -- Depois quem usa eles
    --------------------------------------------------

    restoreDependencies()

end


--------------------------------------------------
-- NÃO CRIA BACKUP AQUI
--
-- Isso é importante:
-- o loadstring pode ser executado várias vezes
-- sem criar outro backup.
--------------------------------------------------

return API
