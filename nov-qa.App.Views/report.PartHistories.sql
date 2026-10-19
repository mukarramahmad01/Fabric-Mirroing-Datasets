CREATE OR ALTER VIEW [report].[PartHistories]
	--
AS
WITH LocalizedPartType
AS (
	SELECT Value,
		[Text]
	FROM dbo.EnumLanguageMappings
	WHERE EnumTypeName = 'PartType'
		AND Culture = ISNULL(CONVERT(VARCHAR(10), SESSION_CONTEXT(N'CurrentCulture')), 'en')
	),
LocalizedPriority
AS (
	SELECT Value,
		[Text]
	FROM dbo.EnumLanguageMappings
	WHERE EnumTypeName = 'Priority'
		AND Culture = ISNULL(CONVERT(VARCHAR(10), SESSION_CONTEXT(N'CurrentCulture')), 'en')
	),
LocalizedAlertSeverity
AS (
	SELECT Value,
		[Text]
	FROM dbo.EnumLanguageMappings
	WHERE EnumTypeName = 'AlertSeverity'
		AND Culture = ISNULL(CONVERT(VARCHAR(10), SESSION_CONTEXT(N'CurrentCulture')), 'en')
	UNION
		SELECT null AS [Value], null AS [Text]
	)
SELECT dbo.Locations.DataSetId,
	PartHistories.Id,
	PartHistories.Id AS PartId,
	dbo.Locations.Id AS LocationId,
	PartHistories.[Date],
	PartHistories.PartNumber,
	PartHistories.Revision,
	PartHistories.[Location],
	LocalizedPartType.[Text] AS PartType,
	PartHistories.[Profile],
	PartHistories.TopOfGreen,
	PartHistories.TopOfYellow,
	PartHistories.TopOfRed,
	PartHistories.InventoryAlert,
	PartHistories.InventoryQty,
	PartHistories.TotalSupply,
	PartHistories.TotalDemand,
	NULLIF(PartHistories.PlannerCode, '') AS PlannerCode,
	PartHistories.MaterialType,
	PartHistories.RPlusLeadTime,
	PartHistories.Vendor,
	PartHistories.VendorId AS VendorIdentifier,
	PartHistories.RawMaterialsCost,
	PartHistories.OutSourceCost,
	LocalizedPriority.[Text] AS [Priority],
	PartHistories.OnHandQty,
	PartHistories.TargetedInventory,
	PartHistories.AlertType,
	PartHistories.EffectiveDailyUsage,
	PartHistories.MaterialAvailabilityShortage,
	PartHistories.AverageDailyUsage,
	PartHistories.ForecastedDailyUsage,
	PartHistories.RZAFValue,
	PartHistories.YZAFValue,
	PartHistories.FixedReorderCycle,
	PartHistories.StandardDeviationOfDemand,
	PartHistories.SourceInformation1,
	PartHistories.SourceInformation2,
	PartHistories.SourceInformation3,
	LocalizedAlertSeverity.[Text] AS AlertSeverity,
	PartHistories.AlertDate,
	PartHistories.SpikeDemand,
	PartHistories.PastDueDemand,
	PartHistories.DisableAutoProfile,
	PartHistories.Decoupled,
	PartHistories.AutoApprove
FROM dbo.PartHistories
INNER JOIN dbo.Locations ON dbo.Locations.[Name] = PartHistories.[Location]
	AND dbo.Locations.DataSetId = PartHistories.DataSetId
-- the localizations
INNER JOIN LocalizedAlertSeverity ON LocalizedAlertSeverity.Value = PartHistories.AlertSeverity
INNER JOIN LocalizedPartType ON LocalizedPartType.Value = PartHistories.PartType
INNER JOIN LocalizedPriority ON LocalizedPriority.Value = PartHistories.[Priority]
