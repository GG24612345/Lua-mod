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

        API.backup()
        API.desync()

        -- depois:
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
-- ENCONTRA REFERÊNCIAS AOS ATTACHMENTS
--------------------------------------------------

local function findAttachmentReferences(HRP)

    local Results = {}

    local Character = HRP.Parent

    local RootAttachment =
        HRP:FindFirstChild("RootAttachment")

    local RootRigAttachment =
        HRP:FindFirstChild("RootRigAttachment")


    if not RootAttachment
        and not RootRigAttachment then

        return Results
    end


    for _, Object in ipairs(
        Character:GetDescendants()
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

                    local TargetName = nil

                    if Value == RootAttachment then
                        TargetName = "RootAttachment"

                    elseif Value == RootRigAttachment then
                        TargetName = "RootRigAttachment"
                    end


                    if TargetName then

                        table.insert(
                            Results,
                            {
                                Object = Object,
                                Property = Property,
                                TargetName = TargetName
                            }
                        )

                        break
                    end

                end

            end

        end

    end

    return Results
end


--------------------------------------------------
-- BACKUP
--------------------------------------------------

function API.backup()

    local HRP = getHRP()

    local Character = HRP.Parent

    local Folder = getBackupFolder()


    --------------------------------------------------
    -- LIMPA BACKUP ANTERIOR
    --------------------------------------------------

    for _, Child in ipairs(
        Folder:GetChildren()
    ) do

        Child:Destroy()

    end


    --------------------------------------------------
    -- PASTA DOS ATTACHMENTS
    --------------------------------------------------

    local AttachmentFolder =
        Instance.new("Folder")

    AttachmentFolder.Name = "Attachments"

    AttachmentFolder.Parent = Folder


    --------------------------------------------------
    -- BACKUP DOS DOIS ATTACHMENTS
    --------------------------------------------------

    for _, Name in ipairs(ATTACHMENTS) do

        local Attachment =
            HRP:FindFirstChild(Name)

        if Attachment
            and Attachment:IsA("Attachment") then

            local Clone =
                Attachment:Clone()

            Clone.Name = Name

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
    -- PROCURA QUEM USA OS ATTACHMENTS
    --------------------------------------------------

    local References =
        findAttachmentReferences(HRP)


    for Index, Info in ipairs(References) do

        local Object = Info.Object

        if Object
            and Object.Parent
            and Object:IsDescendantOf(Character)
        then

            local Clone =
                Object:Clone()


            Clone.Name =
                "__Dependency_" .. Index


            --------------------------------------------------
            -- NOME ORIGINAL
            --------------------------------------------------

            local OriginalName =
                Instance.new("StringValue")

            OriginalName.Name =
                "OriginalName"

            OriginalName.Value =
                Object.Name

            OriginalName.Parent =
                Clone


            --------------------------------------------------
            -- CLASSE ORIGINAL
            --------------------------------------------------

            local OriginalClass =
                Instance.new("StringValue")

            OriginalClass.Name =
                "OriginalClass"

            OriginalClass.Value =
                Object.ClassName

            OriginalClass.Parent =
                Clone


            --------------------------------------------------
            -- PROPRIEDADE QUE USA O ATTACHMENT
            --------------------------------------------------

            local PropertyName =
                Instance.new("StringValue")

            PropertyName.Name =
                "AttachmentProperty"

            PropertyName.Value =
                Info.Property

            PropertyName.Parent =
                Clone


            --------------------------------------------------
            -- QUAL ATTACHMENT ELE USAVA
            --------------------------------------------------

            local TargetName =
                Instance.new("StringValue")

            TargetName.Name =
                "TargetAttachment"

            TargetName.Value =
                Info.TargetName

            TargetName.Parent =
                Clone


            --------------------------------------------------
            -- CAMINHO DO PARENT
            --------------------------------------------------

            local ParentPath =
                Instance.new("StringValue")

            ParentPath.Name =
                "OriginalParent"

            ParentPath.Value =
                Object.Parent:GetFullName()

            ParentPath.Parent =
                Clone


            --------------------------------------------------
            -- COLOCA NO BACKUP
            --------------------------------------------------

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
--------------------------------------------------

function API.desync()

    local HRP = getHRP()


    --------------------------------------------------
    -- NÃO FAZ BACKUP AQUI
    --
    -- Usa somente o backup criado por API.backup()
    --------------------------------------------------


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


    print(
        "[Attachment API] Desync executado."
    )

end


--------------------------------------------------
-- RESTAURA ATTACHMENTS
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
-- ENCONTRA PARENT PELO CAMINHO
--------------------------------------------------

local function findOriginalParent(
    Character,
    FullName
)

    if not FullName then
        return Character
    end


    local CharacterName =
        Character:GetFullName()


    if FullName == CharacterName then
        return Character
    end


    local Relative =
        FullName:sub(
            #CharacterName + 2
        )


    local Current =
        Character


    for Part in Relative:gmatch("[^%.]+") do

        local Next =
            Current:FindFirstChild(Part)

        if not Next then
            return Character
        end

        Current = Next

    end


    return Current
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
    -- PEGA OS NOVOS ATTACHMENTS
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

        local OriginalClass =
            BackupObject:FindFirstChild(
                "OriginalClass"
            )

        local PropertyName =
            BackupObject:FindFirstChild(
                "AttachmentProperty"
            )

        local TargetName =
            BackupObject:FindFirstChild(
                "TargetAttachment"
            )

        local OriginalParent =
            BackupObject:FindFirstChild(
                "OriginalParent"
            )


        if OriginalName
            and OriginalClass
            and PropertyName
            and TargetName
        then

            --------------------------------------------------
            -- REMOVE CÓPIA ATUAL DA DEPENDÊNCIA
            --------------------------------------------------

            for _, Existing in ipairs(
                Character:GetDescendants()
            ) do

                if Existing ~= HRP
                    and Existing.Name ==
                        OriginalName.Value
                    and Existing.ClassName ==
                        OriginalClass.Value
                then

                    pcall(function()
                        Existing:Destroy()
                    end)

                end

            end


            --------------------------------------------------
            -- CLONA O OBJETO SALVO
            --------------------------------------------------

            local Clone =
                BackupObject:Clone()


            --------------------------------------------------
            -- REMOVE METADADOS
            --------------------------------------------------

            for _, Name in ipairs({
                "OriginalName",
                "OriginalClass",
                "AttachmentProperty",
                "TargetAttachment",
                "OriginalParent"
            }) do

                local Meta =
                    Clone:FindFirstChild(Name)

                if Meta then
                    Meta:Destroy()
                end

            end


            --------------------------------------------------
            -- PARENT ORIGINAL
            --------------------------------------------------

            local Parent =
                Character

            if OriginalParent then

                Parent =
                    findOriginalParent(
                        Character,
                        OriginalParent.Value
                    )

            end


            Clone.Parent =
                Parent


            --------------------------------------------------
            -- NOVO ATTACHMENT
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
            -- REFAZ A REFERÊNCIA
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
    -- RESTAURA OS ATTACHMENTS DO BACKUP
    --------------------------------------------------

    local Success =
        restoreAttachments()

    if not Success then
        return
    end


    --------------------------------------------------
    -- REFAZ AS REFERÊNCIAS
    -- PARA OS NOVOS ATTACHMENTS
    --------------------------------------------------

    restoreDependencies()


    print(
        "[Attachment API] Sync executado."
    )

end


--------------------------------------------------
-- NÃO FAZ BACKUP AUTOMÁTICO
--------------------------------------------------
--
-- O usuário precisa chamar:
--
-- API.backup()
--
--------------------------------------------------


return API
