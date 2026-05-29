# Snap to Grid

Astroneer mod that automatically snaps every placed physical item to a spherical grid aligned to the planet. No configuration, no keybindings — install and it works.

## How it works

When any `PhysicalItem` is dropped in the world, the mod intercepts the placement and moves it to the nearest point on a global spherical grid.

The grid is derived entirely from the planet's geometry: no reference object needs to be set by the player. The grid pole is fixed to the planet's coordinate X axis, so the same grid tiles exist everywhere on the planet, for every player, every session.

### Spherical grid

The grid is not flat — it follows the planet's curvature. Two adjacent grid points are always `ARC_LENGTH` Unreal units apart, measured along the sphere surface (arc length, not chord length). The angular step between points shrinks slightly as you move away from the grid pole, which is the natural behavior of any spherical grid (same reason longitude lines converge at the poles).

Objects placed at different terrain heights are snapped to the correct angular position independently of their altitude, so they align horizontally even when the ground is uneven.

After snapping position, the mod also corrects the object's rotation to be tangent to the planet surface and aligned with the grid axis.

## Requirements

- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) installed in Astroneer

## Installation

### Manual

1. Install UE4SS in your Astroneer directory if you haven't already.
2. Inside `<Astroneer>\Astro\Binaries\Win64\Mods\`, create a folder named `gridneer`.
3. Copy the `Scripts/` folder from this repo into it.
4. Create an empty file named `enabled.txt` inside `gridneer/`.

```
Astro\Binaries\Win64\
└── Mods\
    └── gridneer\
        ├── Scripts\
        │   ├── main.lua
        │   ├── func.lua
        │   └── lib\
        └── enabled.txt
```

### Via AstroModLoader Classic

Download the `.pak` release from the [Nexus Mods page](https://www.nexusmods.com/profile/0R4X/mods?gameId=1955) and install it through AstroModLoader. UE4SS will be enabled automatically.

## Tuning (optional)

All defaults work out of the box. If you want to adjust the grid, open the UE4SS console in-game and use these commands — changes take effect immediately, no restart needed:

| Command | Description | Default |
|---|---|---|
| `arc <n>` | Grid spacing in Unreal units | `500` |
| `rot_angle <deg>` | Extra yaw rotation added after snapping | `0` |
| `info` | Show current player position and active parameters | — |

**Example:** `arc 250` halves the grid density.

## Project structure

```
Scripts/
├── main.lua          — Entry point: snap hook, grid algorithm, console commands
├── func.lua          — Shared math helpers and UE4SS utility functions
└── lib/
    └── LEEF-math/    — 3D vector math library (third-party)
```

## Algorithm

`snapToGrid` in `main.lua`:

1. Translate the actor's world position to planet-centered space.
2. Compute the actor's radius `r₀` from the planet center.
3. Set the grid pole at `pA₀ = (r₀, 0, 0)` — a fixed equatorial point on the X axis in planet-centered coordinates.
4. Derive an orthonormal basis `(u, v)` tangent to the sphere at `pA₀`.
5. Project the actor onto the sphere of radius `r₀`.
6. Measure the actor's arc distances along each axis, round each to the nearest multiple of `ARC_LENGTH`, and reconstruct the snapped position by rotating `pA₀` back by the rounded angles.
7. Apply rotation: orient the object tangent to the planet surface, aligned with the `u` grid axis.

## License

See [LICENSE](LICENSE).
