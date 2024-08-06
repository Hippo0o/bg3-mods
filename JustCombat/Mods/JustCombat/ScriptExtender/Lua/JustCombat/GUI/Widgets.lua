---@class GUILayout
---@field Root ExtuiTable
---@field Rows table<number, ExtuiTableRow>
---@field Cells table<number, table<number, ExtuiTableCell>>
---@param root ImguiHandle
---@param cols number
---@param rows number
---@param onCreated fun(layout: GUILayout)
---@return GUILayout
function GUI.Layout(root, cols, rows, onCreated)
    rows = rows or 1

    local t = root:AddTable(U.RandomId(), cols)

    local cells = {}
    local lrows = {}
    for i = 1, rows do
        local row = t:AddRow()
        table.insert(lrows, row)

        cells[i] = {}
        for j = 1, cols do
            cells[i][j] = row:AddCell()
        end
    end

    local o = {
        Root = t,
        Rows = lrows,
        Cells = cells,
    }

    if onCreated then
        onCreated(o)
    end

    return o
end

---@param root ImguiHandle
---@param text string
---@param onClick fun(button: ExtuiButton)|nil
function GUI.Button(root, text, onClick)
    local id = U.RandomId()

    local button = root:AddButton(id)
    button.Label = text

    if onClick then
        button.OnClick = function()
            onClick(button)
        end
    end

    return button
end

---@class GUIEventTextbox
---@field Root ExtuiGroup
---@field TextList table<number, ExtuiText>
---@field Reset fun()
---@param root ImguiHandle
---@param event string
---@param onTriggered fun(textBox: GUIEventTextbox, ...: any): table|string the text to displaybox
---@return GUIEventTextbox
function GUI.EventTextbox(root, event, onTriggered)
    local box = {}

    local id = U.RandomId()

    box.Root = root:AddGroup(id)
    box.TextList = {}

    Event.On(event, function(...)
        local text = { ... }

        if onTriggered then
            text = onTriggered(box, ...)
        end

        if type(text) == "table" then
            xpcall(function()
                text = table.concat(text, "	")
            end, function() -- lazy fallback
                text = Ext.Json.Stringify(text)
            end)
        end

        local id = U.RandomId()
        local t = box.Root:AddText(id)
        t.Label = text
        table.insert(box.TextList, t)
    end)

    function box.Reset()
        for _, text in pairs(box.TextList) do
            text:Destroy()
        end

        box.TextList = {}
    end

    return box
end

---@class GUISelection
---@field Selected number
---@field Value any
---@field Root ExtuiGroup
---@field RadioButtons table<number, ExtuiRadioButton>
---@field Reset fun()
---@field AddItem fun(label: string, value: number)
---@param root ImguiHandle
---@return GUISelection
function GUI.Selection(root)
    local selection = {}
    selection.Selected = 1
    selection.Value = nil

    local id = U.RandomId()

    selection.Root = root:AddGroup(id)

    selection.RadioButtons = {}

    function selection.Reset()
        for _, radio in pairs(selection.RadioButtons) do
            radio:Destroy()
        end

        selection.RadioButtons = {}
    end

    function selection.AddItem(label, value)
        local id = U.RandomId()

        local i = #selection.RadioButtons + 1

        local radio = selection.Root:AddRadioButton(id, i == selection.Selected)
        radio.Label = label

        if i == selection.Selected then
            selection.Value = value
        end

        radio.OnChange = function()
            for _, r in pairs(selection.RadioButtons) do
                r.Active = false
            end

            radio.Active = true
            selection.Selected = i
            selection.Value = value
        end

        table.insert(selection.RadioButtons, radio)
    end

    return selection
end
