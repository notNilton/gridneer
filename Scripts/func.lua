---@diagnostic disable: lowercase-global

local UEHelpers = require("UEHelpers")
modules = "lib.LEEF-math.modules."
local vec3 = require("lib.LEEF-math.modules.vec3")

function round2(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 4)
    return math.floor(num * mult + 0.5) / mult
end

---@param num number
---@param base number
---@return number
function roundToBase(num, base) return math.floor(num / base + 0.5) * base end

---@return vec3
function getPlanetCenter()
    local playerController = UEHelpers:GetPlayerController() ---@cast playerController APlayControllerInstance_C
    local loc = playerController.HomeBody.RootComponent.RelativeLocation
    return vec3.new(loc.X, loc.Y, loc.Z)
end

---@param actor AActor
---@param location vec3
---@param planetCenter vec3
function fixRotation(actor, location, planetCenter)
    local rot = vec3.findLookAtRotation(location, planetCenter)
    actor:K2_SetActorRotation(rot, true)
    ---@diagnostic disable-next-line: missing-fields
    actor:K2_AddActorLocalRotation({ Roll = 0, Pitch = 90, Yaw = 0 }, false, {}, false)
end

---@param start vec3
---@param target vec3
---@return FRotator
function vec3.findLookAtRotation(start, target)
    local d = target - start
    local yaw = math.atan(d.y, d.x)
    local pitch = math.atan(d.z, math.sqrt(d.x * d.x + d.y * d.y))
    return { Pitch = math.deg(pitch), Yaw = math.deg(yaw), Roll = 0 }
end

---vec3.angle_to with cosine clamped to [-1, 1] to prevent NaN.
function vec3.angle_to_safe(a, b)
    local v = math.max(-1, math.min(1, a:normalize():dot(b:normalize())))
    return math.acos(v)
end

---@param point vec3
---@param planeBase vec3
---@param planeNormal_unit vec3
---@return vec3
function vec3.projectPointOnToPlane(point, planeBase, planeNormal_unit)
    return point - vec3.scale(planeNormal_unit, vec3.dot(point - planeBase, planeNormal_unit))
end
