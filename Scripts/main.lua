local UEHelpers = require("UEHelpers")
require("func")

modules = "lib.LEEF-math.modules." ---@diagnostic disable-line: lowercase-global
Vec3 = require("lib.LEEF-math.modules.vec3") ---@diagnostic disable-line: lowercase-global
local vec3 = Vec3

-- Grid spacing in Unreal units. Adjust via console: `arc 250`
local ARC_LENGTH = 500

-- Extra rotation applied after snapping. Adjust via console: `rot_angle 45`
local ROTATION_ANGLE = 0

--[[
  Grid reference is derived purely from planet geometry: the X-axis equatorial
  point at the actor's radius. This makes the grid globally consistent across
  the entire planet with zero player setup.

  The reference uses a fixed world-space direction (X axis) in planet-centered
  coordinates. Since planets don't rotate in Astroneer, this produces the same
  grid tile layout every time, for every player, without any config.
]]
local function snapToGrid(p_actor_world, actor)
    local planetCenter = getPlanetCenter()

    local p = vec3.new(
        p_actor_world.x - planetCenter.x,
        p_actor_world.y - planetCenter.y,
        p_actor_world.z - planetCenter.z)
    local r_0 = vec3.len(p)

    -- Grid pole: equatorial X-axis point on the same sphere as the actor
    local pA_0 = vec3.new(r_0, 0, 0)

    -- Orientation vector: rotate the Z-direction at pA_0 by 90° around pA_0.
    -- With pA_0 on the X axis this gives a stable, non-degenerate basis.
    local p_vop = vec3.rotate(vec3.new(pA_0.x, pA_0.y, pA_0.z + 1), math.rad(90), pA_0)
    local vectorOnPlane = vec3.new(p_vop.x - pA_0.x, p_vop.y - pA_0.y, p_vop.z - pA_0.z)

    -- Project actor onto the reference sphere so height doesn't affect grid position
    local unit = vec3.normalize(p)
    local p_norm = vec3.new(unit.x * r_0, unit.y * r_0, unit.z * r_0)

    -- Orthonormal grid basis
    local u = vec3.cross(pA_0, vectorOnPlane)
    local u_unit = vec3.normalize(u)
    local v = vec3.cross(pA_0, u)
    local v_unit = vec3.normalize(v)

    local sign_0 = (u_unit.x*p_norm.x + u_unit.y*p_norm.y + u_unit.z*p_norm.z) < 0 and -1 or 1
    local sign_1 = (v_unit.x*p_norm.x + v_unit.y*p_norm.y + v_unit.z*p_norm.z) < 0 and  1 or -1

    -- Arc 1: forward/backward grid index
    local projection = vec3.projectPointOnToPlane(p_norm, vec3.zero, u_unit)
    local n_number = math.tointeger(
        round2(roundToBase(r_0 * vec3.angle_to_safe(p_norm, projection), ARC_LENGTH) / ARC_LENGTH * sign_0, 0))
    assert(n_number ~= nil)

    local theta_0 = ARC_LENGTH / r_0
    local pA_N = n_number == 0 and pA_0 or vec3.rotate(pA_0, n_number * theta_0, v)

    -- Arc 2: left/right grid index (arc length shrinks away from the equator of pA_0)
    local n_letter = math.tointeger(
        round2(roundToBase(vec3.len(projection) * vec3.angle_to_safe(pA_0, projection), ARC_LENGTH) / ARC_LENGTH * sign_1, 0))
    assert(n_letter ~= nil)

    local r_N = r_0 * math.cos(n_number * theta_0)
    local theta_N = ARC_LENGTH / r_N

    local snapped = vec3.rotate(pA_N, n_letter * theta_N, u)
    local newLoc = vec3.new(
        snapped.x + planetCenter.x,
        snapped.y + planetCenter.y,
        snapped.z + planetCenter.z)

    -- Align object to planet surface and grid axis
    if actor then
        fixRotation(actor, newLoc, planetCenter)
        local right = actor:GetActorRightVector()
        local cos_a = vec3.dot(u_unit, vec3.new(right.X, right.Y, right.Z))
        ---@diagnostic disable-next-line: missing-fields
        actor:K2_AddActorLocalRotation({ Roll = 0, Pitch = 0, Yaw = math.deg(math.acos(cos_a)) }, false, {}, false)
        if ROTATION_ANGLE ~= 0 then
            ---@diagnostic disable-next-line: missing-fields
            actor:K2_AddActorLocalRotation({ Roll = 0, Pitch = 0, Yaw = ROTATION_ANGLE }, false, {}, false)
        end
    end

    return newLoc
end

-- Always-on: snap every physical item the moment it is placed in the world
RegisterHook(
    "/Script/Astro.PhysicalItem:MulticastDroppedInWorld",
    function(self, Component, TerrainComponent, Point, Normal)
        local physicalItem = self:get() ---@diagnostic disable-line: undefined-field
        ---@cast physicalItem APhysicalItem
        local loc = physicalItem:K2_GetActorLocation()
        local newLoc = snapToGrid(vec3.new(loc.X, loc.Y, loc.Z), physicalItem)
        Point:set(newLoc)
    end
)

-- Optional runtime tuning via in-game console (no restart needed)
RegisterConsoleCommandHandler("arc", function(fullCommand, parameters, outputDevice)
    if #parameters < 1 then
        outputDevice:Log("arc <length> — grid spacing in Unreal units. Current: " .. ARC_LENGTH)
        return true
    end
    local v = tonumber(parameters[1])
    if not v or v == 0 then outputDevice:Log("Must be a non-zero number."); return true end
    ARC_LENGTH = v
    outputDevice:Log("ARC_LENGTH = " .. v)
    return true
end)

RegisterConsoleCommandHandler("rot_angle", function(fullCommand, parameters, outputDevice)
    if #parameters < 1 then
        outputDevice:Log("rot_angle <degrees> — extra yaw after snap. Current: " .. ROTATION_ANGLE)
        return true
    end
    local v = tonumber(parameters[1])
    if not v then outputDevice:Log("Must be a number."); return true end
    ROTATION_ANGLE = v
    outputDevice:Log("ROTATION_ANGLE = " .. v)
    return true
end)

RegisterConsoleCommandHandler("info", function(fullCommand, parameters, outputDevice)
    local player = UEHelpers:GetPlayer()
    local loc = player:K2_GetActorLocation()
    local pc = getPlanetCenter()
    outputDevice:Log(string.format(
        "Player: %.1f %.1f %.1f | Planet center: %.1f %.1f %.1f | ARC_LENGTH: %s | ROTATION_ANGLE: %s",
        loc.X, loc.Y, loc.Z, pc.x, pc.y, pc.z, ARC_LENGTH, ROTATION_ANGLE))
    return true
end)
