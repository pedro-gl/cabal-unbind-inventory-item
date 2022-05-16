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
CREATE FUNCTION [dbo].[GetItemEnchantValue]
(
	@itemData varbinary(18)
)
RETURNS int
AS
BEGIN
	RETURN ([dbo].[BinToInt](SUBSTRING(@itemData, 1, 5)) & 0x1e000) / 8192; /* 0x28000 to work with +20 */
END
