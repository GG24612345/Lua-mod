--[[
    Attachment Desync / Sync
    GitHub / loadstring ready

    API:

        API.backup()
        API.desync()
        API.sync()

    IMPORTANTE:

        backup() NÃO é automático.

        Você precisa chamar:

            API.backup()

        antes de usar:

            API.desync()
]]

local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local API = {}

local BACKUP_FOLDER_NAME = "__AttachmentBackup"

local TARGET_ATTACHMENTS = {
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
    local Character = getCharacter()

    return Character:WaitForChild("HumanoidRootPart")
end


--------------------------------------------------
-- BACKUP FOLDER
--------------------------------------------------

local function getBackupFolder()

    local Character = getCharacter()

    local Folder =
        Character:FindFirstChild(BACKUP_FOLDER_NAME)

    if not Folder then

        Folder = Instance.new("Folder")

        Folder.Name = BACKUP_FOLDER_NAME

        Folder.Parent = Character

    end

    return Folder
end


--------------------------------------------------
-- VERIFICA SE É UM DOS ATTACHMENTS
--------------------------------------------------

local function isTargetAttachment(Object)

    if not Object then
        return false
    end

    if not Object:IsA("Attachment") then
        return false
    end

    return Object.Name == "RootAttachment"
        or Object.Name == "RootRigAttachment"
end


--------------------------------------------------
-- ENCONTRA OBJETOS QUE REFERENCIAM
-- OS ATTACHMENTS DO HRP
--------------------------------------------------

local function findDependencies(HRP)

    local Character = HRP.Parent

    local RootAttachment =
        HRP:FindFirstChild("RootAttachment")

    local RootRigAttachment =
        HRP:FindFirstChild("RootRigAttachment")

    local Dependencies = {}

    for _, Object in ipairs(Character:GetDescendants()) do

        if Object ~= HRP
            and not Object:IsDescendantOf(
                Character:FindFirstChild("__AttachmentBackup")
                    or Instance.new("Folder")
            )
        then

            for _, PropertyName in ipairs({
                "Attachment0",
                "Attachment1",
                "Attachment",
                "Adornee"
            }) do

                local Success, Value =
                    pcall(function()
                        return Object[PropertyName]
                    end)

                if Success then

                    local TargetName = nil

                    if Value == RootAttachment then
                        TargetName = "RootAttachment"
                    elseif Value == RootRigAttachment then
                        TargetName = "RootRigAttachment"
                    end

                    if TargetName then

                        table.insert(
                            Dependencies,
                            {
                                Object = Object,
                                Property = PropertyName,
                                TargetName = TargetName
                            }
                        )

                        break
                    end
                end
            end
        end
    end

    return Dependencies
end


--------------------------------------------------
-- BACKUP
--
-- ESTA É A ÚNICA FUNÇÃO QUE FAZ BACKUP
--------------------------------------------------

function API.backup()

    local HRP = getHRP()

    local Folder = getBackupFolder()


    --------------------------------------------------
    -- LIMPA BACKUP ANTIGO
    --------------------------------------------------

    for _, Child in ipairs(Folder:GetChildren()) do
        Child:Destroy()
    end


    --------------------------------------------------
    -- PASTA DOS ATTACHMENTS
    --------------------------------------------------

    local AttachmentFolder =
        Instance.new("Folder")

    AttachmentFolder.Name =
        "Attachments"

    AttachmentFolder.Parent =
        Folder


    --------------------------------------------------
    -- BACKUP DOS DOIS ATTACHMENTS
    --------------------------------------------------

    for _, Name in ipairs(TARGET_ATTACHMENTS) do

        local Attachment =
            HRP:FindFirstChild(Name)

        if Attachment
            and Attachment:IsA("Attachment")
        then

            local Clone =
                Attachment:Clone()

            Clone.Name =
                Name

            Clone.Parent =
                AttachmentFolder

        end
    end


    --------------------------------------------------
    -- PASTA DAS DEPENDÊNCIAS
    --------------------------------------------------

    local DependencyFolder =
        Instance.new("Folder")

    DependencyFolder.Name =
        "Dependencies"

    DependencyFolder.Parent =
        Folder


    --------------------------------------------------
    -- ENCONTRA QUEM USA OS ATTACHMENTS
    --------------------------------------------------

    local Dependencies =
        findDependencies(HRP)


    --------------------------------------------------
    -- SALVA CADA DEPENDÊNCIA
    --------------------------------------------------

    for Index, Info in ipairs(Dependencies) do

        local Object = Info.Object

        if Object
            and Object.Parent
        then

            local Clone =
                Object:Clone()

            Clone.Name =
                "__Dependency_" .. Index


            --------------------------------------------------
            -- METADADOS
            --------------------------------------------------

            local OriginalName =
                Instance.new("StringValue")

            OriginalName.Name =
                "OriginalName"

            OriginalName.Value =
                Object.Name

            OriginalName.Parent =
                Clone


            local OriginalParent =
                Instance.new("StringValue")

            OriginalParent.Name =
                "OriginalParent"

            OriginalParent.Value =
                Object.Parent:GetFullName()

            OriginalParent.Parent =
                Clone


            local PropertyName =
                Instance.new("StringValue")

            PropertyName.Name =
                "AttachmentProperty"

            PropertyName.Value =
                Info.Property

            PropertyName.Parent =
                Clone


            local TargetName =
                Instance.new("StringValue")

            TargetName.Name =
                "TargetAttachment"

            TargetName.Value =
                Info.TargetName

            TargetName.Parent =
                Clone


            Clone.Parent =
                DependencyFolder
        end
    end

    print(
        "[Attachment API] Backup criado."
    )

end


--------------------------------------------------
-- DESYNC
--
-- NÃO FAZ BACKUP
--------------------------------------------------

function API.desync()

    local HRP = getHRP()


    --------------------------------------------------
    -- REMOVE RootAttachment
    --------------------------------------------------

    local RootAttachment =
        HRP:FindFirstChild("RootAttachment")

    if RootAttachment
        and RootAttachment:IsA("Attachment")
    then

        RootAttachment:Destroy()

    end


    --------------------------------------------------
    -- REMOVE RootRigAttachment
    --------------------------------------------------

    local RootRigAttachment =
        HRP:FindFirstChild("RootRigAttachment")

    if RootRigAttachment
        and RootRigAttachment:IsA("Attachment")
    then

        RootRigAttachment:Destroy()

    end


    print(
        "[Attachment API] Desync."
    )

end


--------------------------------------------------
-- RESTAURA OS ATTACHMENTS
--------------------------------------------------

local function restoreAttachments()

    local HRP = getHRP()

    local Folder =
        getBackupFolder()

    local AttachmentFolder =
        Folder:FindFirstChild("Attachments")

    if not AttachmentFolder then

        warn(
            "[Attachment API] Nenhum backup encontrado. Use API.backup() primeiro."
        )

        return false
    end


    --------------------------------------------------
    -- RootAttachment
    --------------------------------------------------

    local SavedRoot =
        AttachmentFolder:FindFirstChild(
            "RootAttachment"
        )

    if SavedRoot then

        local Current =
            HRP:FindFirstChild(
                "RootAttachment"
            )

        if Current then
            Current:Destroy()
        end


        local Clone =
            SavedRoot:Clone()

        Clone.Parent =
            HRP

    end


    --------------------------------------------------
    -- RootRigAttachment
    --------------------------------------------------

    local SavedRig =
        AttachmentFolder:FindFirstChild(
            "RootRigAttachment"
        )

    if SavedRig then

        local Current =
            HRP:FindFirstChild(
                "RootRigAttachment"
            )

        if Current then
            Current:Destroy()
        end


        local Clone =
            SavedRig:Clone()

        Clone.Parent =
            HRP

    end

    return true
end


--------------------------------------------------
-- RESTAURA DEPENDÊNCIAS
--------------------------------------------------

local function restoreDependencies()

    local Character =
        getCharacter()

    local HRP =
        getHRP()

    local Folder =
        getBackupFolder()

    local DependencyFolder =
        Folder:FindFirstChild(
            "Dependencies"
        )

    if not DependencyFolder then
        return
    end


    --------------------------------------------------
    -- NOVOS ATTACHMENTS
    --------------------------------------------------

    local RootAttachment =
        HRP:FindFirstChild(
            "RootAttachment"
        )

    local RootRigAttachment =
        HRP:FindFirstChild(
            "RootRigAttachment"
        )


    --------------------------------------------------
    -- RESTAURA CADA DEPENDÊNCIA
    --------------------------------------------------

    for _, BackupObject in ipairs(
        DependencyFolder:GetChildren()
    ) do

        local OriginalName =
            BackupObject:FindFirstChild(
                "OriginalName"
            )

        local OriginalParent =
            BackupObject:FindFirstChild(
                "OriginalParent"
            )

        local PropertyName =
            BackupObject:FindFirstChild(
                "AttachmentProperty"
            )

        local TargetName =
            BackupObject:FindFirstChild(
                "TargetAttachment"
            )

        if OriginalName
            and PropertyName
            and TargetName
        then

            --------------------------------------------------
            -- ENCONTRA O ATTACHMENT NOVO
            --------------------------------------------------

            local NewAttachment

            if TargetName.Value ==
                "RootAttachment"
            then

                NewAttachment =
                    RootAttachment

            elseif TargetName.Value ==
                "RootRigAttachment"
            then

                NewAttachment =
                    RootRigAttachment

            end


            --------------------------------------------------
            -- CLONA A DEPENDÊNCIA
            --------------------------------------------------

            local Clone =
                BackupObject:Clone()


            --------------------------------------------------
            -- REMOVE METADADOS
            --------------------------------------------------

            for _, MetaName in ipairs({
                "OriginalName",
                "OriginalParent",
                "AttachmentProperty",
                "TargetAttachment"
            }) do

                local Meta =
                    Clone:FindFirstChild(
                        MetaName
                    )

                if Meta then
                    Meta:Destroy()
                end

            end


            --------------------------------------------------
            -- TENTA ENCONTRAR O PARENT ORIGINAL
            --------------------------------------------------

            local ParentObject = nil

            if OriginalParent then

                for _, Object in ipairs(
                    Character:GetDescendants()
                ) do

                    if Object:GetFullName()
                        == OriginalParent.Value
                    then

                        ParentObject =
                            Object

                        break
                    end
                end
            end


            --------------------------------------------------
            -- PARENT
            --------------------------------------------------

            Clone.Parent =
                ParentObject
                or Character


            --------------------------------------------------
            -- REFAZ A REFERÊNCIA
            --
            -- IMPORTANTE:
            -- aponta para o Attachment NOVO
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
--
-- NÃO FAZ BACKUP
--------------------------------------------------

function API.sync()

    --------------------------------------------------
    -- Primeiro restaura os Attachments
    --------------------------------------------------

    local Success =
        restoreAttachments()

    if not Success then
        return
    end


    --------------------------------------------------
    -- Depois restaura quem usava eles
    --------------------------------------------------

    restoreDependencies()


    print(
        "[Attachment API] Sync."
    )

end


--------------------------------------------------
-- NÃO EXISTE BACKUP AUTOMÁTICO AQUI
--------------------------------------------------

return API
