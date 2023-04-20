-- AUTHOR: https://github.com/frxedlxver/
-- REPO: https://github.com/frxedlxver/aseprite-opacity-animation-tool

local OpacityDialog = {
    title = "Animate Opacity",
    dialog = nil,
    bounds = nil,
    layers = {};
    layersToAnimate = {};
    animationDuration = 5,
    startFrame = 1,
    initOpacity = 0,
    endOpacity = 255,
    mode = "linear"
}


-- calculations for linear mode (init -> final)
function OpacityDialog:CalculateOpacityLinear(currentFrameIdx)
    local completion = (currentFrameIdx - 1) / self.animationDuration;
    local maxDeltaOpacity = (self.finalOpacity - self.initOpacity);

    return (maxDeltaOpacity * completion) + self.initOpacity;
end


-- calculations for cycle mode (init -> final -> init)
function OpacityDialog:CalculateOpacityCycle(currentFrameIdx)
    local completion = (currentFrameIdx - 1) / self.animationDuration;
    local maxDeltaOpacity = (self.finalOpacity - self.initOpacity);

    if completion < 0.5 then -- first half of cycle, forward animation, regular opacity function
        return (2 * maxDeltaOpacity * completion) + self.initOpacity;
    else -- second half of cycle, reverse animation, inverse opacity function
        return (2 * maxDeltaOpacity * (1 - completion)) + self.initOpacity;
    end
end


-- function to initialize the dialog
function OpacityDialog:Create()
    self.layersToAnimate = {}
    self.layers = self:GetAvailableLayers();
end


-- get all non-bg layers in sprite
function OpacityDialog:GetAvailableLayers()

    local layers = {};

    for _, layer in ipairs(app.activeSprite.layers) do
        if not layer.isBackground then
            table.insert(layers, layer)
        end
    end

    return layers;
end


-- check if a layer is currently selected in dialog
function OpacityDialog:_LayerSelected(layer)
    for _, targetLayer in ipairs(self.layersToAnimate) do
        if targetLayer == layer then return true end
    end

    return false
end


-- refresh dialog elements
function OpacityDialog:Refresh()
    self.bounds = self.dialog.bounds
    self.dialog:close()
    self:Show()
end


-- function to inflate the dialog
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
                            table.remove(self.layersToAnimate, layer)
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
    }

    -- animation duration slider
    self.dialog:slider{
        id = "cycleDuration",
        label = "Animation Duration: ",
        value = self.animationDuration,
        min = 5,
        max = 100,
        onrelease = function()
            self:Refresh()
        end,
        onchange = function ()
            self.animationDuration = self.dialog.data["cycleDuration"]
        end
    }

    -- start frame slider
    self.dialog:slider {
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
    }

    -- initial opacity slider
    self.dialog:slider {
        id = "initOpacity",
        label = "From opacity:",
        value = self.initOpacity,
        min = 0,
        max = 255,
        onrelease = function()
            self:Refresh()
        end,
        onchange = function()
            self.initOpacity = self.dialog.data["initOpacity"]
        end
    }

    -- final opacity slider
    self.dialog:slider {
        id = "finalOpacity",
        label = "To opacity:",
        value = self.finalOpacity,
        min = 0,
        max = 255,
        onrelease = function()
            self:Refresh()
        end,
        onchange = function()
            self.finalOpacity = self.dialog.data["finalOpacity"];
        end
    }

    -- mode selection combobox
    self.dialog:combobox{
        id="mode",
        label="animation direction:",
        option=self.mode,
        options= {"linear", "cycle"},
        onchange=function ()
            self.mode = self.dialog.data["mode"]
            self:Refresh()
        end
    }

    -- generate animation button
    self.dialog:button{
        text = "generate",
        enabled = (#self.layersToAnimate > 0) and (self.animationDuration > 0),

        -- listener
        onclick = function()
            local sprite = app.activeSprite

            -- get bgLayer and data, in case we need to work with it
            local bgLayer = sprite.backgroundLayer
            local bgLayerImage, bgLayerPos
            if bgLayer then
                bgLayerImage = bgLayer.cels[1].image
                bgLayerPos = bgLayer.cels[1].position
            end


            -- iterate over selected layers
            for i, targetLayer in ipairs(self.layersToAnimate) do

                -- set first cell opacity outside of initial loop
                targetLayer.cels[self.startFrame].opacity = self.initOpacity;
                -- iterate over cels for targetLayer
                for j = (self.startFrame + 1), self.animationDuration, 1 do
                    local curFrame = sprite.frames[j]

                    -- if frame does not yet exist, create it
                    if curFrame == nil then
                        sprite:newEmptyFrame()
                        curFrame = sprite.frames[j]

                        -- duplicate the first background cel if frame created by script
                        -- nested so that bg is not overwritten if it already exists in the frame
                        if bgLayer then
                            sprite:newCel(bgLayer, curFrame, bgLayerImage, bgLayerPos)
                        end

                    end

                    local lastCel = targetLayer.cels[j-1]
                    local curCel = sprite:newCel(targetLayer, sprite.frames[j], lastCel.image, lastCel.position)

                    if(self.mode == "linear") then
                        curCel.opacity = self:CalculateOpacityLinear(j);
                    else
                        curCel.opacity = self:CalculateOpacityCycle(j);
                    end

                end
            end
            self.dialog:close()
        end
    }
    self.dialog:button{text = "Cancel"}

    if self.bounds ~= nil then
        local newBounds = self.dialog.bounds
        newBounds.x = self.bounds.x
        newBounds.y = self.bounds.y
        self.dialog.bounds = newBounds
    end

    self.dialog:show()
end



-- create and run the dialog
local opDialog = OpacityDialog;
opDialog:Create();
opDialog:Show();