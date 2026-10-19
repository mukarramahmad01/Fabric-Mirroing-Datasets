CREATE OR ALTER VIEW [report].[HistoricalDemand]
	--
AS
WITH LocalizedPartType
AS (
	SELECT Value,
		[Text]
	FROM dbo.EnumLanguageMappings
	WHERE EnumTypeName = 'PartType'
		AND Culture = ISNULL(CONVERT(VARCHAR(10), SESSION_CONTEXT(N'CurrentCulture')), 'en')
	)
SELECT dbo.DemandHistories.PrimaryKeyId AS Id,
	dbo.PartKeys.DataSetId,
	dbo.DemandHistories.Id AS PartId,
	dbo.PartKeys.PartNumber,
	dbo.PartKeys.Revision,
	dbo.PartKeys.LocationId,
	dbo.Locations.Name AS Location,
	LocalizedPartType.[Text] AS PartType,
	dbo.DemandHistories.OrderDate,
	dbo.DemandHistories.Quantity
FROM dbo.PartKeys
INNER JOIN dbo.DemandHistories ON dbo.PartKeys.Id = dbo.DemandHistories.Id
INNER JOIN dbo.Locations ON dbo.PartKeys.LocationId = dbo.Locations.Id
INNER JOIN dbo.Parts ON dbo.PartKeys.Id = dbo.Parts.Id
-- the localizations
INNER JOIN LocalizedPartType ON LocalizedPartType.Value = dbo.Parts.PartType
