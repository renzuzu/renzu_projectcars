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



# Installation:
- IMPORT SQL FILE

- IMPORTANT DEPENDENCY
```
- ensure renzu_contextmenu
- ensure renzu_popui
```
- OPTIONAL DEPENDENCY ( Reccommended to enable this to fully see the full function of script )
```
- ensure vImageCreator - OPTIONAL for shop images
- ensure renzu_lockgame - OPTIONAL for interaction (recommended)
- ensure renzu_notify (OPTIONAL) needed to see whats happening or else change the notify system in client and server files
```
- Start Project Cars
- ensure renzu_projectcars

# Framework Dependency 
- ESX
- QBCORE
# ESX Optional dependency ( without this inventory you cant use the Unique Car Parts per Vehicle Feature)
- ox_inventory

# items installation
- QB CORE - https://pastebin.com/4jC4GvAN
- ESX normal Inventory - start renzu_projectcars ( auto import items if not error )
- restart whole server
- ESX OX inventory - start renzu_projectcars to let them import the items
- restart ox_inventory ( auto import to items.lua )
- restart your server

# todo minor list
- replace Install to Remove text UI when Chopping a vehicle.
- continues feat adds
- fix any bugs (if known)
- support custom notification
