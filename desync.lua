--[[
    Attachment Desync / Sync
    GitHub / loadstring ready

    Backup:
        RootAttachment
        RootRigAttachment
        Objetos que referenciam esses Attachments

    Uso:

        local API = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/GG24612345/Lua-mod/refs/heads/main/desync.lua"
        ))()

        API.desync()
        API.sync()
]]

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
-- ENCONTRA REFERÊNCIAS AOS ATTACHMENTS
--
-- Procura propriedades que realmente apontem
-- para RootAttachment / RootRigAttachment.
--------------------------------------------------

local function findAttachmentReferences(HRP)

    local Results = {}

    local Targets = {
        RootAttachment = HRP:FindFirstChild("RootAttachment"),
        RootRigAttachment = HRP:FindFirstChild("RootRigAttachment")
    }

    for _, Object in ipairs(HRP.Parent:GetDescendants()) do

        -- Não salva o próprio HRP
        if Object ~= HRP then

            for _, Property in ipairs({
                "Attachment0",
                "Attachment1",
                "Attachment",
                "Adornee"
            }) do

                local Success, Value = pcall(function()
                    return Object[Property]
                end)

                if Success then

                    if Value == Targets.RootAttachment
                        or Value == Targets.RootRigAttachment then

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

    local HRP = getHRP()
    local Folder = getBackupFolder()

    --------------------------------------------------
    -- Limpa backup anterior
    --------------------------------------------------

    for _, Child in ipairs(Folder:GetChildren()) do
        Child:Destroy()
    end


    --------------------------------------------------
    -- Pasta dos Attachments
    --------------------------------------------------

    local AttachmentFolder = Instance.new("Folder")

    AttachmentFolder.Name = "Attachments"

    AttachmentFolder.Parent = Folder


    --------------------------------------------------
    -- Salva os dois Attachments
    --------------------------------------------------

    local Saved = {}

    for _, Name in ipairs(ATTACHMENTS) do

        local Attachment = HRP:FindFirstChild(Name)

        if Attachment and Attachment:IsA("Attachment") then

            local Clone = Attachment:Clone()

            Clone.Name = Name

            Clone.Parent = AttachmentFolder

            Saved[Name] = true

        end

    end


    --------------------------------------------------
    -- Pasta dos objetos dependentes
    --------------------------------------------------

    local DependencyFolder = Instance.new("Folder")

    DependencyFolder.Name = "Dependencies"

    DependencyFolder.Parent = Folder


    --------------------------------------------------
    -- Encontra objetos que usam os Attachments
    --------------------------------------------------

    local References = findAttachmentReferences(HRP)

    for Index, Info in ipairs(References) do

        local Object = Info.Object

        if Object
            and Object.Parent
            and Object:IsDescendantOf(HRP.Parent)
        then

            local Clone = Object:Clone()

            Clone.Name = "__Dependency_" .. Index

            --------------------------------------------------
            -- Guarda metadados para reconectar depois
            --------------------------------------------------

            local OriginalName = Instance.new("StringValue")

            OriginalName.Name = "OriginalName"

            OriginalName.Value = Object.Name

            OriginalName.Parent = Clone


            local OriginalClass = Instance.new("StringValue")

            OriginalClass.Name = "OriginalClass"

            OriginalClass.Value = Object.ClassName

            OriginalClass.Parent = Clone


            local PropertyName = Instance.new("StringValue")

            PropertyName.Name = "AttachmentProperty"

            PropertyName.Value = Info.Property

            PropertyName.Parent = Clone


            local TargetName = Instance.new("StringValue")

            TargetName.Name = "TargetAttachment"

            TargetName.Value = Info.TargetName

            TargetName.Parent = Clone


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
    -- PRIMEIRO:
    -- cria o backup completo
    --------------------------------------------------

    createBackup()


    --------------------------------------------------
    -- DEPOIS REMOVE RootAttachment
    --------------------------------------------------

    local RootAttachment =
        HRP:FindFirstChild("RootAttachment")

    if RootAttachment then
        RootAttachment:Destroy()
    end


    --------------------------------------------------
    -- DEPOIS REMOVE RootRigAttachment
    --------------------------------------------------

    local RootRigAttachment =
        HRP:FindFirstChild("RootRigAttachment")

    if RootRigAttachment then
        RootRigAttachment:Destroy()
    end

end


--------------------------------------------------
-- RESTAURA ATTACHMENTS
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

        local Clone =
            SavedRoot:Clone()

        Clone.Parent = HRP
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

        local Clone =
            SavedRig:Clone()

        Clone.Parent = HRP
    end

end


--------------------------------------------------
-- RESTAURA DEPENDÊNCIAS
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
    -- Novos Attachments
    --------------------------------------------------

    local RootAttachment =
        HRP:FindFirstChild("RootAttachment")

    local RootRigAttachment =
        HRP:FindFirstChild("RootRigAttachment")


    --------------------------------------------------
    -- Percorre os objetos salvos
    --------------------------------------------------

    for _, BackupObject in ipairs(
        DependencyFolder:GetChildren()
    ) do

        local OriginalName =
            BackupObject:FindFirstChild("OriginalName")

        local PropertyName =
            BackupObject:FindFirstChild("AttachmentProperty")

        local TargetName =
            BackupObject:FindFirstChild("TargetAttachment")

        if OriginalName
            and PropertyName
            and TargetName
        then

            --------------------------------------------------
            -- Remove objeto antigo com o mesmo nome/classe
            --------------------------------------------------

            for _, Existing in ipairs(
                Character:GetDescendants()
            ) do

                if Existing ~= HRP
                    and Existing.Name == OriginalName.Value
                    and Existing.ClassName == BackupObject.OriginalClass.Value
                then

                    pcall(function()
                        Existing:Destroy()
                    end)

                end

            end


            --------------------------------------------------
            -- Clona dependência
            --------------------------------------------------

            local Clone =
                BackupObject:Clone()


            --------------------------------------------------
            -- Remove metadados do backup
            --------------------------------------------------

            local Meta1 =
                Clone:FindFirstChild("OriginalName")

            if Meta1 then
                Meta1:Destroy()
            end

            local Meta2 =
                Clone:FindFirstChild("OriginalClass")

            if Meta2 then
                Meta2:Destroy()
            end

            local Meta3 =
                Clone:FindFirstChild("AttachmentProperty")

            if Meta3 then
                Meta3:Destroy()
            end

            local Meta4 =
                Clone:FindFirstChild("TargetAttachment")

            if Meta4 then
                Meta4:Destroy()
            end


            --------------------------------------------------
            -- Descobre o novo Attachment
            --------------------------------------------------

            local NewAttachment

            if TargetName.Value == "RootAttachment" then
                NewAttachment = RootAttachment
            elseif TargetName.Value == "RootRigAttachment" then
                NewAttachment = RootRigAttachment
            end


            --------------------------------------------------
            -- Coloca o objeto no mesmo parent lógico
            --------------------------------------------------

            local OriginalParentName =
                BackupObject:GetAttribute(
                    "OriginalParent"
                )

            if OriginalParentName then

                local Parent =
                    Character:FindFirstChild(
                        OriginalParentName,
                        true
                    )

                if Parent then
                    Clone.Parent = Parent
                else
                    Clone.Parent = Character
                end

            else
                Clone.Parent = Character
            end


            --------------------------------------------------
            -- Reconecta a propriedade
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
    -- Primeiro restaura os dois Attachments
    --------------------------------------------------

    restoreAttachments()


    --------------------------------------------------
    -- Depois reconecta tudo que usava eles
    --------------------------------------------------

    restoreDependencies()

end


--------------------------------------------------
-- BACKUP INICIAL
--------------------------------------------------

createBackup()


--------------------------------------------------
-- API
--------------------------------------------------

return API
