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

---@class ComponentsSelection
---@field Selected table<number, number>
---@field Values table<number, any>
---@field Value any
---@field Root ExtuiGroup
---@field Selectables table<number, ExtuiRadioButton>
---@field Reset fun()
---@field AddItem fun(label: string, value: any)
---@param multiple boolean|nil
---@param root ExtuiTreeParent
---@return ComponentsSelection
function Components.Selection(root, multiple)
    local selection = {}
    selection.Selected = { 1 }
    selection.Values = {}
    selection.Value = nil

    ---@type ExtuiGroup
    selection.Root = root:AddGroup(U.RandomId())

    selection.Selectables = {}

    function selection.Reset()
        for _, select in pairs(selection.Selectables) do
            select:Destroy()
        end

        selection.Selectables = {}
    end

    function selection.AddItem(label, value)
        local i = #selection.Selectables + 1

        local selected = UT.Contains(selection.Selected, i)

        local select = multiple and selection.Root:AddCheckbox(label, selected)
            or selection.Root:AddRadioButton(label, selected)

        if selected then
            table.insert(selection.Values, value)
            selection.Value = value
        end

        select.OnChange = function()
            if not multiple then
                for _, r in pairs(selection.Selectables) do
                    r.Active = false
                end
                select.Active = true
                selection.Selected = { i }
                selection.Values = { value }
                selection.Value = value
            else
                if select.Checked then
                    table.insert(selection.Selected, i)
                    table.insert(selection.Values, value)
                    selection.Value = value
                else
                    UT.Remove(selection.Selected, i)
                    UT.Remove(selection.Values, value)
                end
            end
        end
        table.insert(selection.Selectables, select)
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
---@param destroy boolean|nil
---@return ComponentsConditional
function Components.Conditional(root, create, event, destroy)
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
            else
                for _, child in pairs(o.Created) do
                    child.Visible = true
                end
            end
        else
            for i = #o.Created, 1, -1 do
                o.Created[i].Visible = false

                if destroy then
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
