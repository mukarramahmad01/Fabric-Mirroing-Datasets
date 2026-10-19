CREATE OR ALTER VIEW [report].[Resources]
	--
AS
WITH LocalizedResourceType
AS (
	SELECT Value,
		Text
	FROM dbo.EnumLanguageMappings
	WHERE EnumTypeName = 'ResourceType'
		AND Culture = ISNULL(CONVERT(VARCHAR(10), SESSION_CONTEXT(N'CurrentCulture')), 'en')
	)
SELECT r.DataSetId,
	r.Id,
	r.LocationId,
	r.Name,
	dbo.Locations.Name AS Location,
	r.Description,
	r.Count,
	LocalizedResourceType.[Text] AS ResourceType,
	r.CrewSize,
	r.BufferManager,
	r.ResourceManager,
	r.Category,
	r.Efficiency,
	r.Buffer,
	r.SetupTime,
	r.FixedOffset,
	r.Notes
FROM dbo.Locations
INNER JOIN dbo.Resources AS r ON dbo.Locations.Id = r.LocationId
-- the localizations
INNER JOIN LocalizedResourceType ON LocalizedResourceType.Value = r.ResourceType
