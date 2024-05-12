Components = {}

---@class ComponentsLayout
---@field Root ExtuiTable
---@field Rows table<number, ExtuiTableRow>
---@field Cells table<number, table<number, ExtuiTableCell>>
---@param root ExtuiTreeParent
---@param cols number
---@param rows number
---@param onCreated fun(layout: ComponentsLayout)
---@return ComponentsLayout
function Components.Layout(root, cols, rows, onCreated)
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

---@class ComponentsComputed
---@field Root ExtuiStyledRenderable
---@field Update fun(...)
---@field Field string
---@param root ExtuiStyledRenderable
---@param event string
---@param compute fun(computed: ComponentsComputed, ...: any): any
---@param field string|nil default "Label"
---@return ComponentsComputed
function Components.Computed(root, compute, event, field)
    field = field or "Label"

    local o = {
        Root = root,
        Field = field,
    }

    function o.Update(...)
        local value = { ... }

        if #value == 1 then
            value = value[1]
        end

        if compute then
            value = compute(root, ...)
        end

        if type(value) == "table" then
            xpcall(function()
                value = table.concat(value, "	")
            end, function() -- lazy fallback
                value = Ext.Json.Stringify(value)
            end)
        end

        if value ~= nil then
            root[field] = value
        end
    end

    if event then
        WindowEvent(event, o.Update)
    end

    return root
end

---@class ComponentsRadioList
---@field Selected number
---@field Value any
---@field Root ExtuiGroup
---@field RadioButtons table<number, ExtuiRadioButton>
---@field Reset fun()
---@field AddItem fun(label: string, value: number)
---@param root ExtuiTreeParent
---@return ComponentsRadioList
function Components.RadioList(root)
    local selection = {}
    selection.Selected = 1
    selection.Value = nil

    selection.Root = root:AddGroup(U.RandomId())

    selection.RadioButtons = {}

    function selection.Reset()
        for _, radio in pairs(selection.RadioButtons) do
            radio:Destroy()
        end

        selection.RadioButtons = {}
    end

    function selection.AddItem(label, value)
        local i = #selection.RadioButtons + 1

        local radio = selection.Root:AddRadioButton(value, i == selection.Selected)

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

---@class ComponentsConditional
---@field Root ExtuiGroup
---@field Update fun(bool: boolean)
---@field Created table<number, ExtuiStyledRenderable>
---@param root ExtuiTreeParent
---@param create fun(conditional: ComponentsConditional): table<number, ExtuiStyledRenderable>|ExtuiStyledRenderable
---@param event string|nil
---@return ComponentsConditional
function Components.Conditional(root, create, event)
    local o = {
        Created = {},
        Root = root,
    }

    function o.Update(bool)
        if bool then
            if #o.Created == 0 then
                local elements = create(o)
                if type(elements) ~= "table" then
                    elements = { elements }
                end

                for _, child in pairs(elements) do
                    table.insert(o.Created, child)
                end
            end
        else
            if o.Created then
                for i = #o.Created, 1, -1 do
                    o.Created[i]:Destroy()
                    table.remove(o.Created, i)
                end
            end
        end
    end

    if event then
        WindowEvent(event, o.Update)
    end

    return o
end

---@param root ExtuiTreeParent
---@param tbl table
---@param label string|nil
---@return ExtuiTree
function Components.Tree(root, tbl, label)
    local tree
    if label then
        tree = root:AddTree(U.RandomId())
        tree.Label = label
    else
        tree = root:AddGroup(U.RandomId())
    end

    local function addNode(node, data)
        for k, v in pairs(data) do
            if type(k) == "number" then
                k = "[" .. k .. "]"
            end
            if type(v) == "string" then
                v = '"' .. v .. '"'
            end

            if type(v) == "table" then
                local label = k .. " (" .. UT.Size(v) .. ")"
                addNode(node:AddTree(label), v)
            else
                node:AddText("   " .. k .. " = " .. tostring(v))
            end
        end
    end
    addNode(tree, tbl)

    return tree
end
