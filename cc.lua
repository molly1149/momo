_G.WallhackExtracted = true

local isValid = slua.isValid

_G.CheatsEnabled = true

local function ApplyWallHack(localPlayer, enemy, pc)
    if not _G.CheatsEnabled then return end
    if not isValid(enemy) then return end

    local meshes = {}
    pcall(function()
        if isValid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
        local SkelClass = import("SkeletalMeshComponent")
        if SkelClass then
            local childs = enemy:GetComponentsByClass(SkelClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for c = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(c-1) or childs[c]
                    if isValid(comp) and comp ~= enemy.Mesh then table.insert(meshes, comp) end
                end
            end
        end
    end)

    pcall(function()
        for _, comp in ipairs(meshes) do
            if isValid(comp) then
                local ok, mat = pcall(function() return comp:GetMaterial(0) end)
                if ok and isValid(mat) then
                    local ok2, base = pcall(function() return mat:GetBaseMaterial() end)
                    if ok2 and isValid(base) then
                        base.bDisableDepthTest = true
                        base.BlendMode = 2 
                    end
                end
                comp.UseScopeDistanceCulling = false
                comp.PrimitiveShadingStrategy = 1
                comp.ShadingRate = 6
            end
        end

        local isVisible = false
        if isValid(pc) and isValid(enemy) and type(pc.LineOfSightTo) == "function" then
            pcall(function() isVisible = pc:LineOfSightTo(enemy) end)
        end
        local finalColor = isVisible and {R=0, G=255, B=0, A=1} or {R=255, G=0, B=0, A=1}
        local scale = {R=3, G=3, B=0, A=0}

        enemy._WH_MIDs = enemy._WH_MIDs or {}
        for _, comp in ipairs(meshes) do
            if isValid(comp) then
                local ck = tostring(comp)
                enemy._WH_MIDs[ck] = enemy._WH_MIDs[ck] or {}
                for i = 0, 10 do
                    local ok3, mi = pcall(function() return comp:GetMaterial(i) end)
                    if not ok3 or not isValid(mi) then break end
                    local mid = enemy._WH_MIDs[ck][i]
                    if not isValid(mid) then
                        local ok4, nm = pcall(function() return comp:CreateAndSetMaterialInstanceDynamic(i) end)
                        if ok4 and isValid(nm) then
                            enemy._WH_MIDs[ck][i] = nm
                            mid = nm
                        end
                    end
                    if isValid(mid) then
                        pcall(function()
                            mid:SetVectorParameterValue("颜色", finalColor)
                            mid:SetVectorParameterValue("Color", finalColor)
                            mid:SetVectorParameterValue("BaseColor", finalColor)
                            mid:SetVectorParameterValue("BodyColor", finalColor)
                            mid:SetVectorParameterValue("DiffuseColor", finalColor)
                            mid:SetVectorParameterValue("ParaScaleOffset", scale)
                        end)
                    end
                end
            end
        end
    end)
end


pcall(function()
    local function WallhackTick()
        if not _G.CheatsEnabled then return end
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not isValid(pc) then return end
        local localPlayer = pc:GetPlayerCharacterSafety()
        if not isValid(localPlayer) then return end

        local allPawns = Game:GetAllPlayerPawns() or {}
        for _, enemy in pairs(allPawns) do
            if isValid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
                ApplyWallHack(localPlayer, enemy, pc)
            end
        end
    end


    local function StartWallhackTimer()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if isValid(pc) and pc.AddGameTimer then
            if not _G._WH_TimerPC or _G._WH_TimerPC ~= pc then
                _G._WH_TimerPC = pc
                _G._WH_TimerHandle = pc:AddGameTimer(0.5, true, WallhackTick)
            end
        else

            local fb = slua_GameFrontendHUD or Game
            if fb and fb.AddGameTimer then
                fb:AddGameTimer(1.0, false, StartWallhackTimer)
            end
        end
    end

    StartWallhackTimer()
end)

