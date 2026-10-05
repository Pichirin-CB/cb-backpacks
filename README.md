# CB Backpacks

Wearable backpack system for FiveM using:

- `ox_inventory` containers.
- `illenium-appearance` for clothing application
- `rpemotes-reborn` for the backpack animation
- `ox_lib`

## Important

The backpack clothing values are **not guessed**. Set the real `drawable` and `texture` values from your clothing pack in `config.lua`.

The `slots` and `maxWeight` values in the included config are starter values and should be changed to the capacities you want for your server. The item `weight` is intentionally `0` because no physical backpack weights were supplied.

The script uses GTA V clothing component **5** by default, which is the bag/parachute component.

## Installation

1. Put `cb-backpacks` in your resources folder.
2. Start dependencies first:

```cfg
ensure ox_lib
ensure ox_inventory
ensure illenium-appearance
ensure rpemotes-reborn
ensure cb-backpacks
```

3. Copy the item definitions from:

`INSTALL_FILES/ox_items.lua`

into your `ox_inventory/data/items.lua`.

4. Put your backpack inventory images in:

`ox_inventory/web/images/`

5. Edit `config.lua` and set the real clothing drawable/texture values.

## How it works

The item itself is the backpack. Each backpack gets a persistent `metadata.container` ID. The container therefore travels with that exact item instead of being tied to the player's slot.

When the player uses the backpack:

1. The resource verifies the item server-side.
2. A container ID is generated if the backpack does not have one.
3. The backpack clothing component is applied through the illenium-appearance outfit event.
4. rpemotes-reborn plays the configured backpack animation.
5. ox_inventory opens the backpack's own container.

Removing the backpack restores the component that was being worn before the backpack was equipped.

## Security

The server never trusts the client-provided item name. It checks the actual item in the requested ox_inventory slot before creating or returning a container ID.

## Current limitations

- Clothing component values must be configured for your actual clothing pack.
- The first version targets freemode male/female characters because illenium-appearance's outfit event requires a model name.
- The backpack inventory remains persistent because the container ID is stored in item metadata.

## Recommended next phase

For Sector 13, this can be extended with:

- backpack durability
- backpack damage/destruction
- contamination/infection storage rules
- whitelist/blacklist by backpack type
- weight penalties while wearing a backpack
- backpack dropping on death
- visual backpack variants
- different equip animations per backpack
