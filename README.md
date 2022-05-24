## Unbind Inventory Items for CABAL ONLINE

### What does it do?

Basically, the item will be removed from the character's inventory and a new item will be created and sent to him, with modified binding properties.

### Usage

Implement the tables that is in the Tables folder, or modify it by inserting **only the items that will be accepted by the system**. After that, restore all the scripts from the Functions folder and also from the Procedures folder.

You can handle exceptions according to the returns commented in the `cabal_tool_unbind_inventoryItem` procedure.

<p>&nbsp;</p>

To unbind a character's inventory item, run: 
```sql
EXEC [Server01].[dbo].[cabal_tool_unbind_InventoryItem] '@CharacterIdx', '@ItemData'
```

<p>&nbsp;</p>

Get `@ItemData` with the command:
```sql
EXEC [Server01].[dbo].[cabal_tool_GetInventoryInfo] '@CharacterIdx'
```

<p>&nbsp;</p>

### Conditions

- Character account must be offline.
- The item cannot be temporary.
- The item must be bound to the character.
- The item must be in the character's inventory.
- The item to be unbinded must be present in the tables mentioned above.
- If the item is bound to the character, after unbind, it will have the property "bind when equip".
- If the item is bound to the character, and has 1 slot extended, it will become bound to the account.

### Video Demo

{ ... }
