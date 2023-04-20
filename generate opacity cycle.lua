local OpacityDialog = {
    title = "Animate Opacity",
    dialog = nil,
    bounds = nil,
    layers = {},
    layersToAnimate = {},
    cycleDuration = 10,
    startFrame = 1
}

function OpacityDialog:GetAvailableLayers()

    local layers = {}

    for _, layer in ipairs(app.activeSprite.layers) do
        if not layer.isBackground then
            table.insert(layers, layer)
        end
    end

    return layers;
end

function OpacityDialog:_LayerSelected(layer)
    for _, targetLayer in ipairs(self.layersToAnimate) do
        if targetLayer == layer then return true end
    end

    return false
end

function OpacityDialog:Create()
    self.layersToAnimate = {}
    self.layers = self:GetAvailableLayers()
end

function OpacityDialog:Show()
    self.dialog = Dialog(self.title)

    self.dialog --
    :separator{text = "Select layer to animate: "} --

    -- Get all layers
    -- this loop needs fixing
    for _, layer in ipairs(self.layers) do
        local isSelected = self:_LayerSelected(layer)

        self.dialog:button{
            label = layer.name,
            text = isSelected and "-" or "+",
            onclick = function()
                if isSelected then
                    for i = 1, #self.layersToAnimate do
                        if self.layersToAnimate[i] == layer then
                            table.remove(self.layersToAnimate, i)
                            break
                        end
                    end
                else
                    table.insert(self.layersToAnimate, layer)
                end

                self:Refresh()
            end
        }
    end
    

    self.dialog:separator{
        text = "Selected " .. tostring(#self.layersToAnimate) .. " Layers to animate"
    }:slider{
        id = "cycleDuration",
        label = "Cycle Duration: ",
        value = self.cycleDuration,
        min = 10,
        max = 255,
        onrelease = function()
            self:Refresh()
        end,
        onchange = function ()
            self.cycleDuration = self.dialog.data["cycleDuration"]
        end
    }:slider {
        id = "startFrame",
        label = "Start at Frame:",
        value = self.startFrame,
        min = 1,
        max = #app.activeSprite.frames,
        onrelease = function()
            self:Refresh()
        end,
        onchange = function() 
            self.startFrame = self.dialog.data["startFrame"]
        end
    }:button{
        text = "generate",
        enabled = (#self.layersToAnimate > 0) and (self.cycleDuration > 0),
        onclick = function()
            local sprite = app.activeSprite
            local bgLayer = sprite.backgroundLayer
            local bgLayerImage = bgLayer.cels[1].image
            local bgLayerPos = bgLayer.cels[1].position
            for i, targetLayer in ipairs(self.layersToAnimate) do

                targetLayer.cels[1].opacity = 0

                for j=2, self.cycleDuration + 1, 1 do
                    local curFrame = sprite.frames[j]

                    -- if frame does not yet exist, create it
                    if curFrame == nil then
                        sprite:newEmptyFrame()
                        curFrame = sprite.frames[j]

                        -- nested because we only want to duplicate the background if we also created it in the script
                        -- we don't want to overwrite the user's background, if they have one
                        local bgLayer
                        if bgLayer then
                            sprite:newCel(bgLayer, curFrame, bgLayerImage, bgLayerPos)
                        end
                        
                    end

                    local lastCel = targetLayer.cels[j-1]
                    local curCel = sprite:newCel(targetLayer, sprite.frames[j], lastCel.image, lastCel.position)

                    curCel.opacity = self:CalculateOpacity(j);
                end
            end
            self.dialog:close()
        end
    } --
    :button{text = "Cancel"}

    -- Reset bounds
    if self.bounds ~= nil then
        local newBounds = self.dialog.bounds
        newBounds.x = self.bounds.x
        newBounds.y = self.bounds.y
        self.dialog.bounds = newBounds
    end

    self.dialog:show()
end

function OpacityDialog:Refresh()
    self.bounds = self.dialog.bounds
    self.dialog:close()
    self:Show()
end

function OpacityDialog:CycleOpacityLinear(sprite)

end

function OpacityDialog:CalculateOpacity(currentFrameIdx)
    local completion = 2 * (currentFrameIdx - 1) / self.cycleDuration;
    local maxOpacity = 255;

    if completion < 0.5 then -- first half of cycle, forward animation, regular opacity function
        return maxOpacity * completion;
    else -- second half of cycle, reverse animation, inverse opacity function
        return maxOpacity * (1 - completion);
    end
end

local opDialog = OpacityDialog;
opDialog:Create();
opDialog:Show();