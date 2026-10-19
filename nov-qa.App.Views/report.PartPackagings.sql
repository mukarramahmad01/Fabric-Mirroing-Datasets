CREATE OR ALTER VIEW [report].[PartPackagings]
	--
AS
WITH LocalizedPartPackagingDimension
AS (
	SELECT Value,
		[Text]
	FROM dbo.EnumLanguageMappings
	WHERE EnumTypeName = 'PartPackagingDimension'
		AND Culture = ISNULL(CONVERT(VARCHAR(10), SESSION_CONTEXT(N'CurrentCulture')), 'en')
	)
SELECT dbo.PartKeys.DataSetId,
	dbo.PartPackagings.Id,
	dbo.PartPackagings.PartId,
	dbo.PartKeys.PartNumber,
	dbo.PartKeys.Revision,
	dbo.PartKeys.LocationId,
	dbo.Locations.Name AS Location,
	dbo.PartPackagings.Quantity,
	dbo.PartPackagings.Unit,
	LocalizedPartPackagingDimension.[Text] AS Dimension
FROM dbo.PartPackagings
INNER JOIN dbo.PartKeys ON dbo.PartPackagings.PartId = dbo.PartKeys.Id
INNER JOIN dbo.Locations ON dbo.PartKeys.LocationId = dbo.Locations.Id
-- the localizations
INNER JOIN LocalizedPartPackagingDimension ON LocalizedPartPackagingDimension.Value = dbo.PartPackagings.Dimension
