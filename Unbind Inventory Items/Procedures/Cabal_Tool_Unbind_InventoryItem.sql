USE [Server01]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Pedro-GL>
-- Create date: <2022-07-21>
-- =============================================
CREATE PROCEDURE [dbo].[cabal_tool_unbind_InventoryItem]
(
	@characterIdx INT,
	@itemData VARBINARY(18)
)
AS
BEGIN
	DECLARE @r_result SMALLINT;
	DECLARE @r_OK SMALLINT = 1;
	DECLARE @r_FAILED SMALLINT = 0;

	/* 

	- return codes
	
	character not found			 = -1;
	character is online			 = -2;
	usernum not found			 = -3;
	usernum is online			 = -4;
	invalid itemdata length		 = -5;
	itemKind out of range		 = -6;
	itemId out of range			 = -7;
	itemOption out of range		 = -8;
	item not allowed			 = -9;
	invdata not found			 = -10;
	invdata empty				 = -11;
	item not in invdata			 = -12;
	item is temporary			 = -13;
	item is already free		 = -14;
	item is binded to acc		 = -15;
	item is binded on equip		 = -16;

	*/

	-- search character
	DECLARE @login TINYINT;
	SELECT @characterIdx=CharacterIdx, @login=Login FROM [dbo].[cabal_character_table] WHERE CharacterIdx=@characterIdx;
	IF (@@ROWCOUNT <= 0) BEGIN SELECT -1 RETURN; END;
	IF (@login != 0) BEGIN SELECT -2 RETURN; END;

	-- check account
	DECLARE @userNum INT;
	SELECT @userNum=UserNum, @login=Login FROM [Account].[dbo].[cabal_auth_table] WHERE UserNum=@characterIdx/8;
	IF (@@ROWCOUNT <= 0) BEGIN SELECT -3 RETURN; END;
	IF (@login != 0) BEGIN SELECT -4 RETURN; END;

	-- check item data len
	IF (LEN(@itemData) != 18) BEGIN SELECT -5 RETURN; END;

	-- decode and check item duration
	DECLARE @itemDurationBin VARBINARY(5) = SUBSTRING(@itemData, 14, 18);
	DECLARE @itemDuration INT = [dbo].[BinToInt](@itemDurationBin);
	IF (@itemDuration != 0) BEGIN SELECT -13 RETURN; END;

	-- decode and check item data
	DECLARE @itemKind INT = [dbo].[BinToInt](SUBSTRING(@itemData, 1, 5));
	DECLARE @itemId INT = @itemKind & 0xFFF;
	DECLARE @itemOpt INT = CONVERT(INT, CONVERT(VARBINARY, [dbo].[BinToInt](SUBSTRING(@itemData, 9, 12)), 1));
	IF (@itemKind < 1 OR @itemKind > 2097152) BEGIN SELECT -6 RETURN; END;
	IF (@itemKind < 4096) BEGIN SELECT -14 RETURN; END;
	IF (@itemKind < 131072) BEGIN SELECT -15 RETURN; END;
	IF ((@itemKind & 0x180000) = 1572864) BEGIN SELECT -16 RETURN; END;
	IF (@itemId < 1 OR @itemId > 4095) BEGIN SELECT -7 RETURN; END;
	IF (@itemOpt < 0 OR @itemOpt > 2147483647) BEGIN SELECT -8 RETURN; END;

	-- check item id exists in cabal_unbin_items table
	DECLARE @ID INT;
	SELECT @ID=ID FROM [dbo].[cabal_unbin_items] WHERE ID=@itemId;
	IF (@@ROWCOUNT <= 0) BEGIN SELECT -9 RETURN; END;

	-- get inventory data
	DECLARE @inventoryData VARBINARY(8000);
	SELECT @inventoryData=[Data] FROM [dbo].[cabal_Inventory_table] WHERE CharacterIdx=@characterIdx;
	IF (@@ROWCOUNT <= 0) BEGIN SELECT -10 RETURN; END;
	IF (@inventoryData = 0x) BEGIN SELECT -11 RETURN; END;

	-- check if the item exists in the inventory
	DECLARE @count INT = 1;
	DECLARE @itemFound INT = 0;
	DECLARE @itemData2 VARBINARY(18);
	WHILE (@count < LEN(@inventoryData))
	BEGIN
		SET @itemData2 = SUBSTRING(@inventoryData, @count, 18);
		IF (@itemData = @itemData2) BEGIN SET @itemFound=1 BREAK END;
		SET @count += 18;
	END
	IF (@itemFound <= 0) BEGIN SELECT -12 RETURN; END;

	-- get item enhant code
	DECLARE @itemEnhantCode INT = [dbo].[GetItemEnchantValue](@itemData) * 8192;

	-- create new item id
	DECLARE @newItemKind INT = @itemId + @itemEnhantCode;
	
	-- check item properties
	DECLARE @isExt INT = [dbo].[checkIfItemIsExtended](@itemData);
	
	-- add new bind value to the new item id
	SET @newItemKind = CASE
		WHEN @isExt = 0 THEN @newItemKind + 1572864 /* 1572864 = bind when equip */
		WHEN @isExt = 1 THEN @newItemKind + 4096    /* 4096 = bind to account */
	END;

	-- remove old item from inventory data
	SET @inventoryData = CONVERT(VARBINARY(8000), REPLACE(@inventoryData, @itemData, 0x))

	-- lock account
	UPDATE [Account].[dbo].[cabal_auth_table] SET AuthType=2 WHERE UserNum=@userNum;

	BEGIN TRAN updt;
		UPDATE [dbo].[cabal_Inventory_table] SET [Data] = @inventoryData WHERE CharacterIdx = @characterIdx
		IF (@@ROWCOUNT <= 0)
		BEGIN
			-- failed to update inventory data
			ROLLBACK TRAN updt;
			SELECT @r_result = @r_FAILED;
			GOTO finish;
		END
		
		INSERT INTO [CabalCash].[dbo].[MyCashItem] (UserNum, TranNo, ServerIdx, ItemKindIdx, ItemOpt, DurationIdx)
		VALUES (@userNum, 0, 1, @newItemKind, @itemOpt, 0);
		IF (@@ROWCOUNT <= 0)
		BEGIN
			-- insert failed
			ROLLBACK TRAN updt;
			SELECT @r_result = @r_FAILED;
			GOTO finish;
		END

		COMMIT TRAN updt;

		SELECT @r_result = @r_OK;
		GOTO finish;

	finish:
		UPDATE [Account].[dbo].[cabal_auth_table] SET AuthType=1 WHERE UserNum=@userNum;
		SELECT @r_result as result;
		RETURN;
END
