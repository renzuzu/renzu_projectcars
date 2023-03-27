# RENZU_PROJECTCARS
FIvem - Project Cars - Enable your player to build their dream car from Shell. Included Advanced Chopshop and Car Builder Job.

# Feat
- Vehicle Junk Shop `( Players can buy shells here )`
- Auto Parts Shop `( Players can buy parts here)`
- Built in Chop Shop `( Player can dismantle the vehicle for rewards )`
- Car Builder Job - a Unique job player can work at Automotive Center if its allowed  `(job)`
- Built in Garage System `( enable your player to hide from others while building the vehicle )`
- Admin Commands to delete project cars
- Support Item Unique per Vehicle Model `(meta inventory required)`
- Let your player build the vehicle from nothing.
- Build Zone `(allowed only designated place for building a vehicle)`
- Job Shop only `(disable Junk shop and auto parts shop for non registered job in config)`
- Both ESX and QBCORE is Supported.
- Support Oxmysql, Ghmattisql, Mysql Async


# Script Dependency
- Interaction UI https://github.com/renzuzu/renzu_popui
- Menu https://github.com/renzuzu/renzu_contextmenu
- Notification https://github.com/renzuzu/renzu_notify

# Installation:
- IMPORT SQL FILE

- IMPORTANT DEPENDENCY
```
- ensure ox_lib
```
- OPTIONAL DEPENDENCY ( Reccommended to enable this to fully see the full function of script )
```
- ensure vImageCreator - OPTIONAL for shop images
```
- Start Project Cars
- ensure renzu_projectcars

# Optional and Recommended Dependency
- Images for Shop usage - https://github.com/renzuzu/vImageCreator

# Framework Dependency 
- ESX LEGACY REPO https://github.com/esx-framework/esx-legacy ( normal inventory )
- QBCORE https://github.com/qbcore-framework/qb-core ( qb-inventory (repo) is the one tested to work with meta datas )
# ESX Recommended Inventory 
`( without this inventory you cant use the Unique Car Parts per Vehicle Feature)`
- ox_inventory https://github.com/overextended/ox_inventory

# items installation
- QB CORE - https://pastebin.com/4jC4GvAN
- ESX normal Inventory - start renzu_projectcars ( auto import items if not error )
- restart whole server
- ESX OX inventory - start renzu_projectcars to let them import the items
- restart ox_inventory ( auto import to items.lua )
- restart your server


# Props used in resoucre (good for anti cheat WhiteListing)

```lua
'prop_engine_hoist',
'prop_car_engine_01',
'imp_prop_impexp_gearbox_01',
'imp_prop_impexp_brake_caliper_01a',
'imp_prop_impexp_exhaust_01',
'imp_prop_impexp_gearbox_01',
'prop_wheel_01',
'imp_prop_impexp_trunk_01a',
'imp_prop_impexp_bonnet_02a',
'prop_car_door_01',
'prop_car_seat',
```

# Support only here
- You must be informative, with Screenshot of F8 and Server Console.
- Explain the problem
- Explain what you need
https://github.com/renzuzu/renzu_projectcars/issues

# FAQ
- Items not working? ` make sure to install the item correctly to your inventory` `(its should be automatic)` `full restart of server might be required`
- Whitelist Vehicle how? - Any Vehicle Listed in Config.Vehicles are Whitelisted and what not included cannot be chop and built (purchase from shops)
- How to use Inventory Image? - `Copy the contents of INVENTORY_IMAGE Folder` and drag it to your inventory image folder.
- Chop Shop Delete Vehicle? - `by default its true Config.DeleteVehicleSql`
- How to Allow only a Zone Coordinates for spawning a project - `Config.EnableZoneOnly`
- How to Delete Project car its messed up in PD,HP? - `Config.DeleteCommand` `default: /destroyprojectcar`
- What is vehicle_shell and vehicle_blueprints? - `when Meta Inventory is true, System are automatically using vehicle_shell, any new purchase from junk shop will use it` `while vehicle_blueprints is for normal Non Meta Inventory like. ex. Chezza inv, ESX INV HUD`
- i Want only some job can access the shop? - Enable this `Config.jobonly` and set a proper job here `Config.carbuilderjob` `default: mechanic`
- I Want some animation when installing a parts - `Config.Interaction` and `Config.EnableInteraction`
- My Vehicle is not Starting after Finish the progress? - `Config.KeySystemEvent` sounds like you use KeySystem, setup a proper event.
- My Vehicle is missing garage after Finishing up the progress - if your garage uses a Unique Garage id - setup it here `Config.Default_garage`
- How to Add more Brands in Builder Job? its only dink and maibatsu now! - 
```
in Config.BuilderJobs

add more here:
brands = {
      ['dinka'] = true,
      ['maibatsu'] = true,
      ['honda'] = true,
      ['bmw'] = true,
},
```
- How Car Builder Job Works? - 
1. By Now its default Permission for all Job registered in Car builder table Config.
2. In Car Builder Menu - you can request a job order list
3. When Job order is refreshed , you can see the Vehicle list Requested by Dealership (imaginary)
4. Build the Vehicle from Order List eg. Blista
5. After Building Blista Store it on garage.
6. now you can Release the Blista From Job Order to receive a money payout
` This is WIP Part and can be improved later on `

# Thank you
