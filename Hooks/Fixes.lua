local F = table.remove(RequiredScript:split("/"))
local Hooks = Hooks
if F == "elementinteraction" then
    --Checks if the interaction unit is loaded to avoid crashes
    --Checks if interaction tweak id exists
    core:import("CoreMissionScriptElement")
    ElementInteraction = ElementInteraction or class(CoreMissionScriptElement.MissionScriptElement)
    local orig_init = ElementInteraction.init
    local unit_ids = Idstring("unit")
    local norm_ids = Idstring("units/dev_tools/mission_elements/point_interaction/interaction_dummy")
    local nosync_ids = Idstring("units/dev_tools/mission_elements/point_interaction/interaction_dummy_nosync")
    function ElementInteraction:init(mission_script, data, ...)
        if not PackageManager:has(unit_ids, norm_ids) or not PackageManager:has(unit_ids, nosync_ids) then
            return ElementInteraction.super.init(self, mission_script, data, ...)
        end
        if data and data.values and not tweak_data.interaction[data.values.tweak_data_id] then
            return ElementInteraction.super.init(self, mission_script, data, ...)
        end
        return orig_init(self, mission_script, data, ...)
    end

    function MissionScriptElement:init(mission_script, data)
        self._mission_script = mission_script
        self._id = data.id
        self._editor_name = data.editor_name
        self._values = data.values
    end
elseif F == "coresoundenvironmentmanager" then
    --From what I remember, this fixes a crash, these are useless in public.
    function CoreSoundEnvironmentManager:emitter_events(path)
        return {""}
    end
    function CoreSoundEnvironmentManager:ambience_events()
        return {""}
    end
elseif F == "coreelementinstance" then
    core:module("CoreElementInstance")
    core:import("CoreMissionScriptElement")
    function ElementInstancePoint:client_on_executed(...)
        self:on_executed(...)
    end
-- elseif F == "coreelementarea" then
--     core:module("CoreElementArea")
--     Hooks:PostHook(ElementArea, "init", "BeardLibAddSphereShape", function(self)
--         if self._values.shape_type == "sphere" then
--             self:_add_shape(CoreShapeManager.ShapeSphere:new({
--                 position = self._values.position,
--                 rotation = self._values.rotation,
--                 height = self._values.height,
--                 radius = self._values.radius
--             }))
--         end
--     end)
elseif F == "playerdamage" then
    Hooks:PostHook(PlayerDamage, "init", "BeardLibPlyDmgInit", function(self)
        local level_tweak = tweak_data.levels[Global.level_data.level_id]

        if level_tweak and level_tweak.player_invulnerable then
            self:set_mission_damage_blockers("damage_fall_disabled", true)
            self:set_mission_damage_blockers("invulnerable", true)
        end
    end)
elseif F == "dlcmanager" then
    --Fixes parts receiving global value doing a check here using global values and disregarding if the global value is not a DLC. https://github.com/simon-wh/PAYDAY-2-BeardLib/issues/237
    function GenericDLCManager:is_dlc_unlocked(dlc)
        if not tweak_data.dlc[dlc] then
            local global_value = tweak_data.lootdrop.global_values[dlc]
            if global_value and global_value.custom then
                return tweak_data.lootdrop.global_values[dlc].dlc == false
            end
        end
        return tweak_data.dlc[dlc] and tweak_data.dlc[dlc].free or self:has_dlc(dlc)
    end
elseif F == "coreworldinstancemanager" then
    --Fixes #252
    local prepare = CoreWorldInstanceManager.prepare_mission_data
    function CoreWorldInstanceManager:prepare_mission_data(instance, ...)
        local instance_data = prepare(self, instance, ...)
        for _, script_data in pairs(instance_data) do
            for _, element in ipairs(script_data.elements) do
                local vals = element.values
                if element.class == "ElementMoveUnit" then
                    if vals.start_pos then
                        vals.start_pos = instance.position + element.values.start_pos:rotate_with(instance.rotation)
                    end
                    if vals.end_pos then
                        vals.end_pos = instance.position + element.values.end_pos:rotate_with(instance.rotation)
                    end
                elseif element.class == "ElementRotateUnit" then
                    vals.end_rot = instance.rotation * vals.end_rot
                end
            end
        end
        return instance_data
    end
end