USE [Server01]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[cabal_tool_GetInventoryInfo] (@CharacterIdx int)

AS
BEGIN

DECLARE @inv_data varbinary(8000),
		@item_data varbinary(18),
		@item_data2 varbinary(12),
		@item_name varchar(100),
		@item_id int,
		@item_enhant int,
		@item_props int,
		@option int,
		@slot_num int,
		@slot_num_bin varbinary(1),
		@count int = 1,
		@charName varchar(50)

DECLARE @output TABLE 
(
	itemData varbinary(18),
	itemName varchar(100),
	itemId int,
	itemProps int,
	itemOpt int,
	slotNum int
)

-- get character name
SELECT CharacterIdx 'CharIdx', Name 'Inventário do personagem', Alz 'Alzes' FROM cabal_character_table where CharacterIdx = @CharacterIdx

-- get inventory data
SELECT @inv_data = [Data] FROM cabal_Inventory_table WHERE CharacterIdx=@CharacterIdx

WHILE (@count < LEN(@inv_data))
	BEGIN

		-- set item_data (with slotnum and duration info)
		SET @item_data = SUBSTRING(@inv_data, @count, 18)

			-- remove slotnum and duration info from item_data
			SET @item_data2 = SUBSTRING(@item_data, 1, 12)

			-- get itemIdx from 
			SET @item_id = dbo.BinToInt(SUBSTRING(@item_data2, 1, 2)) & 0xFFF

			-- get itemIdx + item properties
			SET @item_props = dbo.BinToInt(SUBSTRING(@item_data2, 1, 5))

			-- get item enhant value
			SET @item_enhant = [dbo].[GetItemEnchantValue](@item_data)

			-- get item option
			SET @option = CONVERT(INT, CONVERT(VARBINARY, dbo.BinToInt(SUBSTRING(@item_data2, 9, 12)), 1))

			-- get slot num
			SET @slot_num_bin = SUBSTRING(@item_data, 13, 13);
			SET @slot_num = dbo.BinToInt(@slot_num_bin);

			-- get item name
			SELECT @item_name = Name FROM Cabal_ItemList WHERE ID = @item_id
			IF(@item_enhant != 0) BEGIN SET @item_name = CONCAT(@item_name + ' +', @item_enhant) END

				-- insert data into output table
				INSERT INTO @output (itemData, itemName, itemId, itemProps, itemOpt, slotNum)
				VALUES (@item_data, @item_name, @item_id, @item_props, @option, @slot_num)

		SET @count = @count + 18

	END

SELECT -- output
	itemData 'itemData',
	itemName 'Nome do item', 
	itemId 'ItemIdx', 
	itemProps 'ItemIdx (completo)', 
	itemOpt 'ItemOption', 
	slotNum 'SlotNum' 
FROM @output ORDER BY SlotNum

END
