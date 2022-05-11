## unbind-inventory-items
### Unbind Inventory Items for CABAL ONLINE

It's a TSQL system for unbind items of the players. Basically, the item will be removed from the character's inventory and a new item will be created and sent to him, with modified binding properties. It is ready to be implemented on a website, admin panel or for manual execution in SQL itself.

### Usage

Implement the tables that is in the **Tables** folder, or modify it by inserting _only the items that will be accepted by the system_. After that, restore all the scripts from the **Functions** folder and also from the **Procedures** folder.

To unbind a character's inventory item, run: `EXEC [Server01].[dbo].[cabal_tool_unbind_InventoryItem] '@CharacterIdx', '@ItemData'`

To get the **@ItemData** with the command: `EXEC [Server01].[dbo].[cabal_tool_GetInventoryInfo] '@CharacterIdx'`

### Usage Rules

- Character account must be offline.
- The item cannot be temporary.
- The item must be bound to the character.
- The item must be in the character's inventory.
- The item to be unbinded must be present in the tables mentioned above.
- If the item is bound to the character, after unbind, it will have the property "bind when equip".
- If the item is bound to the character, and has 1 slot extended, it will become bound to the account.

### Pictures

Nop.
