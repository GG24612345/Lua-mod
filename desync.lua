local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local API = {}

local BACKUP_FOLDER_NAME = "__AttachmentBackup"

local TARGETS = {
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
-- ENCONTRA OBJETOS QUE REFERENCIAM OS ATTACHMENTS
--------------------------------------------------

local function findReferences(HRP)

    local Character = HRP.Parent

    local RootAttachment =
        HRP:FindFirstChild("RootAttachment")

    local RootRigAttachment =
        HRP:FindFirstChild("RootRigAttachment")

    local References = {}

    if not RootAttachment and not RootRigAttachment then
        return References
    end

    for _, Object in ipairs(Character:GetDescendants()) do

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

                    local TargetName

                    if Value == RootAttachment then
                        TargetName = "RootAttachment"

                    elseif Value == RootRigAttachment then
                        TargetName = "RootRigAttachment"
                    end

                    if TargetName then

                        table.insert(References, {
                            Object = Object,
                            Property = Property,
                            TargetName = TargetName,
                            Parent = Object.Parent
                        })

                        break
                    end
                end
            end
        end
    end

    return References
end


--------------------------------------------------
-- BACKUP
--------------------------------------------------

function API.backup()

    local HRP = getHRP()
    local Folder = getBackupFolder()

    -- Apaga backup antigo
    Folder:ClearAllChildren()


    --------------------------------------------------
    -- ATTACHMENTS
    --------------------------------------------------

    local AttachmentFolder = Instance.new("Folder")

    AttachmentFolder.Name = "Attachments"

    AttachmentFolder.Parent = Folder


    for _, Name in ipairs(TARGETS) do

        local Attachment =
            HRP:FindFirstChild(Name)

        if Attachment
            and Attachment:IsA("Attachment") then

            Attachment:Clone().Parent =
                AttachmentFolder

        end
    end


    --------------------------------------------------
    -- DEPENDÊNCIAS
    --------------------------------------------------

    local DependencyFolder = Instance.new("Folder")

    DependencyFolder.Name = "Dependencies"

    DependencyFolder.Parent = Folder


    local References =
        findReferences(HRP)


    for Index, Info in ipairs(References) do

        local Object = Info.Object

        local Clone = Object:Clone()

        Clone.Name =
            "__Dependency_" .. Index


        -- Metadados
        Clone:SetAttribute(
            "OriginalName",
            Object.Name
        )

        Clone:SetAttribute(
            "OriginalClass",
            Object.ClassName
        )

        Clone:SetAttribute(
            "Property",
            Info.Property
        )

        Clone:SetAttribute(
            "TargetAttachment",
            Info.TargetName
        )


        -- Caminho relativo do parent
        local Parent = Info.Parent

        local Path = ""

        while Parent
            and Parent ~= getCharacter() do

            Path =
                Parent.Name ..
                (Path ~= "" and "." .. Path or "")

            Parent = Parent.Parent
        end

        Clone:SetAttribute(
            "ParentPath",
            Path
        )


        Clone.Parent =
            DependencyFolder

    end


    print("[API] Backup criado.")

end


--------------------------------------------------
-- DESYNC
--------------------------------------------------

function API.desync()

    local HRP = getHRP()

    local RootAttachment =
        HRP:FindFirstChild("RootAttachment")

    if RootAttachment then
        RootAttachment:Destroy()
    end


    local RootRigAttachment =
        HRP:FindFirstChild("RootRigAttachment")

    if RootRigAttachment then
        RootRigAttachment:Destroy()
    end


    print("[API] Desync executado.")

end


--------------------------------------------------
-- SYNC
--------------------------------------------------

function API.sync()

    local HRP = getHRP()
    local Folder = getBackupFolder()

    local AttachmentFolder =
        Folder:FindFirstChild("Attachments")

    if not AttachmentFolder then

        warn(
            "[API] Nenhum backup encontrado. Use API.backup() primeiro."
        )

        return
    end


    --------------------------------------------------
    -- ROOT ATTACHMENT
    --------------------------------------------------

    local SavedRoot =
        AttachmentFolder:FindFirstChild(
            "RootAttachment"
        )

    if SavedRoot then

        local Old =
            HRP:FindFirstChild(
                "RootAttachment"
            )

        if Old then
            Old:Destroy()
        end

        SavedRoot:Clone().Parent =
            HRP
    end


    --------------------------------------------------
    -- ROOT RIG ATTACHMENT
    --------------------------------------------------

    local SavedRig =
        AttachmentFolder:FindFirstChild(
            "RootRigAttachment"
        )

    if SavedRig then

        local Old =
            HRP:FindFirstChild(
                "RootRigAttachment"
            )

        if Old then
            Old:Destroy()
        end

        SavedRig:Clone().Parent =
            HRP
    end


    --------------------------------------------------
    -- NOVOS ATTACHMENTS
    --------------------------------------------------

    local NewRoot =
        HRP:FindFirstChild(
            "RootAttachment"
        )

    local NewRig =
        HRP:FindFirstChild(
            "RootRigAttachment"
        )


    --------------------------------------------------
    -- DEPENDÊNCIAS
    --------------------------------------------------

    local DependencyFolder =
        Folder:FindFirstChild(
            "Dependencies"
        )

    if DependencyFolder then

        for _, Backup in ipairs(
            DependencyFolder:GetChildren()
        ) do

            local Property =
                Backup:GetAttribute(
                    "Property"
                )

            local Target =
                Backup:GetAttribute(
                    "TargetAttachment"
                )

            if Property and Target then

                local Clone =
                    Backup:Clone()


                --------------------------------------------------
                -- Remove metadados
                --------------------------------------------------

                for _, Attribute in ipairs({
                    "OriginalName",
                    "OriginalClass",
                    "Property",
                    "TargetAttachment",
                    "ParentPath"
                }) do

                    Clone:SetAttribute(
                        Attribute,
                        nil
                    )

                end


                --------------------------------------------------
                -- Escolhe o novo Attachment
                --------------------------------------------------

                local Attachment

                if Target == "RootAttachment" then
                    Attachment = NewRoot

                elseif Target == "RootRigAttachment" then
                    Attachment = NewRig
                end


                --------------------------------------------------
                -- Reconecta
                --------------------------------------------------

                if Attachment then

                    pcall(function()

                        Clone[Property] =
                            Attachment

                    end)

                end


                --------------------------------------------------
                -- Parent
                --------------------------------------------------

                Clone.Parent =
                    getCharacter()

            end
        end
    end


    print("[API] Sync executado.")

end


--------------------------------------------------
-- IMPORTANTE:
-- NÃO EXECUTA API.backup() AQUI
--------------------------------------------------

return API
