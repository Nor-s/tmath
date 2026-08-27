-- Question: which entities own each field, and what is the cardinality at both ends?
-- Replace entity_specs and relation_specs; keep field rows and endpoint notation intact.
local scene = tmath.scene {
    width = 960, height = 540, fps = 30, loop = false,
    theme = "adaptive_vscode",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 540},
}

local LAYER = {relation = 10, body = 20, divider = 22, text = 30}
local root = scene:group {id = "commerce-schema:root"}
local relationGeometry = root:group {id = "commerce-schema:relations"}
local relationLabels = root:group {id = "commerce-schema:relation-labels"}
local shells = root:group {id = "commerce-schema:entity-shells"}
local fieldRows = root:group {id = "commerce-schema:field-rows"}

local ENTITY_W = 250
local ENTITY_H = 140
local HEADER_H = 44
local ROW_H = 27

-- This is the copy/paste edit surface. Coordinates are entity centers in the 960x540 frame.
local entity_specs = {
    {
        id = "user", name = "User", center = {-270, 110},
        fields = {
            {key = "PK", name = "id", type = "uuid"},
            {name = "email", type = "text"},
            {name = "status", type = "enum"},
        },
    },
    {
        id = "order", name = "Order", center = {220, 110}, focal = true,
        fields = {
            {key = "PK", name = "id", type = "uuid"},
            {key = "FK", name = "user_id", type = "uuid"},
            {name = "total", type = "decimal"},
        },
    },
    {
        id = "product", name = "Product", center = {-270, -115},
        fields = {
            {key = "PK", name = "id", type = "uuid"},
            {name = "sku", type = "text"},
            {name = "price", type = "decimal"},
        },
    },
    {
        id = "item", name = "OrderItem", center = {220, -115},
        fields = {
            {key = "PK", name = "id", type = "uuid"},
            {key = "FK", name = "order_id", type = "uuid"},
            {key = "FK", name = "product_id", type = "uuid"},
        },
    },
}

for _, spec in ipairs(entity_specs) do
    local prefix = "commerce-schema:entity:" .. spec.id
    local left = spec.center[1] - ENTITY_W * 0.5
    local right = spec.center[1] + ENTITY_W * 0.5
    local top = spec.center[2] + ENTITY_H * 0.5
    local bottom = spec.center[2] - ENTITY_H * 0.5
    local headerY = top - HEADER_H

    shells:rectangle {
        center = spec.center, size = {ENTITY_W, ENTITY_H}, corner = 4, fill = "surface",
        stroke = spec.focal and "accent" or "border", width = spec.focal and 2 or 1.5,
        layer = LAYER.body, id = prefix .. ":body",
    }
    shells:line {
        from = {left, headerY}, to = {right, headerY}, color = "border", width = 1.5,
        layer = LAYER.divider, id = prefix .. ":header-divider",
    }
    shells:text {
        text = spec.name, point = {left + 16, top - 22}, align = {0, 0.5},
        role = "text", fill = spec.focal and "accent" or "foreground",
        layer = LAYER.text, id = prefix .. ":name",
    }
    shells:text {
        text = "ENTITY", point = {right - 16, top - 22}, align = {1, 0.5},
        role = "code", fill = "muted", layer = LAYER.text, id = prefix .. ":kind",
    }

    -- A dedicated type column and row rules make the body read as a schema, not a card.
    local typeDividerX = right - 82
    fieldRows:line {
        from = {typeDividerX, headerY}, to = {typeDividerX, bottom},
        color = "border", width = 1, opacity = 0.55,
        layer = LAYER.divider, id = prefix .. ":type-divider",
    }
    for index, field in ipairs(spec.fields) do
        local y = headerY - 19 - (index - 1) * ROW_H
        if field.key then
            fieldRows:text {
                text = field.key, point = {left + 14, y}, align = {0, 0.5},
                role = "code", fill = "muted", layer = LAYER.text,
                id = prefix .. ":field:" .. field.name .. ":key",
            }
        end
        fieldRows:text {
            text = field.name, point = {left + 48, y}, align = {0, 0.5},
            role = "code", fill = "foreground", layer = LAYER.text,
            id = prefix .. ":field:" .. field.name .. ":name",
        }
        fieldRows:text {
            text = field.type, point = {right - 14, y}, align = {1, 0.5},
            role = "code", fill = "muted", layer = LAYER.text,
            id = prefix .. ":field:" .. field.name .. ":type",
        }
        if index < #spec.fields then
            fieldRows:line {
                from = {left, y - 14}, to = {right, y - 14}, color = "border",
                width = 1, opacity = 0.35, layer = LAYER.divider,
                id = prefix .. ":field:" .. field.name .. ":divider",
            }
        end
    end
end

local relation_specs = {
    {id = "user-orders", orientation = "horizontal", from = {-145, 110}, to = {95, 110}, label = "places"},
    {id = "order-items", orientation = "vertical", from = {220, 40}, to = {220, -45}, label = "contains"},
    {id = "product-items", orientation = "horizontal", from = {-145, -115}, to = {95, -115}, label = "appears in"},
}

local relations = {}
for _, spec in ipairs(relation_specs) do
    local prefix = "commerce-schema:relation:" .. spec.id
    local geometry = relationGeometry:group {id = prefix .. ":geometry"}
    local labels = relationLabels:group {id = prefix .. ":labels"}
    geometry:line {
        from = spec.from, to = spec.to, color = "muted", width = 2,
        layer = LAYER.relation, id = prefix .. ":line",
    }

    if spec.orientation == "horizontal" then
        local y = spec.from[2]
        local oneX = spec.from[1] + 10
        local manyBase = spec.to[1] - 16
        geometry:line {
            from = {oneX, y - 7}, to = {oneX, y + 7}, color = "muted", width = 2,
            layer = LAYER.relation, id = prefix .. ":one-mark",
        }
        geometry:line {
            from = {manyBase, y}, to = {spec.to[1] - 4, y + 7}, color = "muted", width = 2,
            layer = LAYER.relation, id = prefix .. ":many-top",
        }
        geometry:line {
            from = {manyBase, y}, to = {spec.to[1] - 4, y}, color = "muted", width = 2,
            layer = LAYER.relation, id = prefix .. ":many-middle",
        }
        geometry:line {
            from = {manyBase, y}, to = {spec.to[1] - 4, y - 7}, color = "muted", width = 2,
            layer = LAYER.relation, id = prefix .. ":many-bottom",
        }
        labels:text {
            text = "1", point = {spec.from[1] + 25, y + 20}, role = "code",
            fill = "foreground", layer = LAYER.text, id = prefix .. ":from-cardinality",
        }
        labels:text {
            text = "N", point = {spec.to[1] - 28, y + 20}, role = "code",
            fill = "foreground", layer = LAYER.text, id = prefix .. ":to-cardinality",
        }
        labels:text {
            text = spec.label, point = {(spec.from[1] + spec.to[1]) * 0.5, y + 24},
            role = "code", fill = "muted", layer = LAYER.text, id = prefix .. ":label",
        }
    else
        local x = spec.from[1]
        local oneY = spec.from[2] - 10
        local manyBase = spec.to[2] + 16
        geometry:line {
            from = {x - 7, oneY}, to = {x + 7, oneY}, color = "muted", width = 2,
            layer = LAYER.relation, id = prefix .. ":one-mark",
        }
        geometry:line {
            from = {x, manyBase}, to = {x - 7, spec.to[2] + 4}, color = "muted", width = 2,
            layer = LAYER.relation, id = prefix .. ":many-left",
        }
        geometry:line {
            from = {x, manyBase}, to = {x, spec.to[2] + 4}, color = "muted", width = 2,
            layer = LAYER.relation, id = prefix .. ":many-middle",
        }
        geometry:line {
            from = {x, manyBase}, to = {x + 7, spec.to[2] + 4}, color = "muted", width = 2,
            layer = LAYER.relation, id = prefix .. ":many-right",
        }
        labels:text {
            text = "1", point = {x + 20, spec.from[2] - 23}, role = "code",
            fill = "foreground", layer = LAYER.text, id = prefix .. ":from-cardinality",
        }
        labels:text {
            text = "N", point = {x + 20, spec.to[2] + 25}, role = "code",
            fill = "foreground", layer = LAYER.text, id = prefix .. ":to-cardinality",
        }
        labels:text {
            text = spec.label, point = {x + 58, (spec.from[2] + spec.to[2]) * 0.5},
            align = {0, 0.5}, role = "code", fill = "muted", layer = LAYER.text,
            id = prefix .. ":label",
        }
    end
    relations[#relations + 1] = {geometry = geometry, labels = labels}
end

scene:fade_in(shells, {shift = {0, -6}, duration = 0.55, curve = "gentle"})
scene:fade_in(fieldRows, {shift = {0, -3}, duration = 0.55, curve = "gentle"})
for _, relation in ipairs(relations) do
    scene:create(relation.geometry, 0.52, "ease_out")
    scene:fade_in(relation.labels, {shift = {0, -4}, duration = 0.22, curve = "gentle"})
end
scene:wait(2.4)
return scene
