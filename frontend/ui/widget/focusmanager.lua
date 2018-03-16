local InputContainer = require("ui/widget/container/inputcontainer")
local Event = require("ui/event")
local UIManager = require("ui/uimanager")

--[[
Wrapper Widget that manages focus for a whole dialog

supports a 2D model of active elements

e.g.:
    layout = {
        { textinput, textinput,    item },
        { okbutton,  cancelbutton, item },
        { nil,       item,         nil  },
        { nil,       item,         nil  },
        { nil,       item,         nil  },
    }
Navigate the layout by trying to avoid not set or nil value.
Provide a simple wrap around in the vertical direction.
The first element of the first table must be valid to ensure
to not get stuck in an invalid position.

but notice that this does _not_ do the layout for you,
it rather defines an abstract layout.
]]
local FocusManager = InputContainer:new{
    selected = nil, -- defaults to x=1, y=1
    layout = nil, -- mandatory
    movement_allowed = { x = true, y = true }
}

function FocusManager:init()
    if not self.selected then
        self.selected = { x = 1, y = 1 }
    end
    self.key_events = {
        -- these will all generate the same event, just with different arguments
        FocusUp =    { {"Up"},    doc = "move focus up",    event = "FocusMove", args = {0, -1} },
        FocusDown =  { {"Down"},  doc = "move focus down",  event = "FocusMove", args = {0,  1} },
        FocusLeft =  { {"Left"},  doc = "move focus left",  event = "FocusMove", args = {-1, 0} },
        FocusRight = { {"Right"}, doc = "move focus right", event = "FocusMove", args = {1,  0} },
    }
end

function FocusManager:onFocusMove(args)
    local dx, dy = unpack(args)

    if (dx ~= 0 and not self.movement_allowed.x)
        or (dy ~= 0 and not self.movement_allowed.y) then
        return true
    end

    if not self.layout or not self.layout[self.selected.y] or not self.layout[self.selected.y][self.selected.x] then
        return true
    end
    local current_item = self.layout[self.selected.y][self.selected.x]
    while true do
        if not self.layout[self.selected.y + dy] then
            --vertical borders, try to wraparound
            if not self:wrapAround(dy) then
                break
            end
        elseif not self.layout[self.selected.y + dy][self.selected.x + dx] then
           --vertical border, no wraparound
            break
        else
            self.selected.y = self.selected.y + dy
            self.selected.x = self.selected.x + dx
        end

        if self.layout[self.selected.y][self.selected.x] ~= current_item
        or not self.layout[self.selected.y][self.selected.x].is_inactive then
            -- we found a different object to focus
            current_item:handleEvent(Event:new("Unfocus"))
            self.layout[self.selected.y][self.selected.x]:handleEvent(Event:new("Focus"))
            -- trigger a fast repaint, this seem to not count toward a fullscreen eink resfresh
            -- TODO: is this really needed?
            UIManager:setDirty(self.show_parent or self, "fast")
            break
        end
    end
    return true
end

function FocusManager:wrapAround(dy)
    --go to the last valid item directly above or below the current item
    --return false if none could be found
    local y = self.selected.y
    while self.layout[y - dy] and self.layout[y - dy][self.selected.x] do
        y = y - dy
    end
    if y ~= self.selected.y then
        self.selected.y = y
        return true
    else
        return false
    end
end

function FocusManager:getFocusItem()
    return self.layout[self.selected.y][self.selected.x]
end

return FocusManager
