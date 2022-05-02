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
ALTER FUNCTION [dbo].[checkIfItemIsExtended] 
(
	@itemData varbinary(18)
)
RETURNS int
AS
BEGIN
	DECLARE @r_result INT;
	SET @r_result = CASE
		WHEN [dbo].[BinToInt](SUBSTRING(@itemData, 1, 5)) & 0x1000 != 0 THEN 1
		ELSE 0
	END
	RETURN @r_result;
END
