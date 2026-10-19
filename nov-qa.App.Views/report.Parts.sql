CREATE OR ALTER VIEW [report].[Parts]
AS
WITH LocalizedPartType AS (
    SELECT [Value], [Text] FROM dbo.EnumLanguageMappings
    WHERE EnumTypeName = 'PartType' AND Culture = 'en'
),
LocalizedBoMType AS (
    SELECT [Value], [Text] FROM dbo.EnumLanguageMappings
    WHERE EnumTypeName = 'BoMType' AND Culture = 'en'
),
LocalizedPriority AS (
    SELECT [Value], [Text] FROM dbo.EnumLanguageMappings
    WHERE EnumTypeName = 'Priority' AND Culture = 'en'
),
LocalizedAlertSeverity AS (
    SELECT [Value], [Text] FROM dbo.EnumLanguageMappings
    WHERE EnumTypeName = 'AlertSeverity' AND Culture = 'en'
),
LocalizedDailyUsageType AS (
    SELECT [Value], [Text] FROM dbo.EnumLanguageMappings
    WHERE EnumTypeName = 'DailyUsageType' AND Culture = 'en'
),
LocalizedCDAFCoverageType AS (
    SELECT [Value], [Text] FROM dbo.EnumLanguageMappings
    WHERE EnumTypeName = 'CycleDayAdjustmentFactorCoverageType' AND Culture = 'en'
),
LocalizedInventoryMethod AS (
    SELECT [Value], [Text] FROM dbo.EnumLanguageMappings
    WHERE EnumTypeName = 'InventoryMethod' AND Culture = 'en'
),
InstanceDate AS (
    SELECT DataSetId,
           CONVERT(DATE, (SYSDATETIMEOFFSET() AT TIME ZONE
               ISNULL(JSON_VALUE([Value], '$.TimeZoneName'), 'UTC'))) AS InstanceCurrentDate
    FROM dbo.KeyValueItems
    WHERE Id = 'Settings.Global.TimeZone'
),
ActiveAdjustmentFactors AS (
    SELECT pcdaf.PartId
        , STRING_AGG(CASE WHEN cdaf.ZoneType = 0 THEN cdaf.[Name] END, ',') AS YZAFNames
        , STRING_AGG(CASE WHEN cdaf.ZoneType = 1 THEN cdaf.[Name] END, ',') AS RZAFNames
        , STRING_AGG(CASE WHEN cdaf.ZoneType = 0 THEN lafct.[Text] END, ',') AS YZAFTypeDescriptions
        , STRING_AGG(CASE WHEN cdaf.ZoneType = 1 THEN lafct.[Text] END, ',') AS RZAFTypeDescriptions
    FROM dbo.PartCycleDayAdjustmentFactors AS pcdaf
    INNER JOIN dbo.CycleDayAdjustmentFactors AS cdaf
        ON pcdaf.CycleDayAdjustmentFactorId = cdaf.Id
    LEFT JOIN InstanceDate AS IDT
        ON cdaf.DataSetId = IDT.DataSetId
    LEFT JOIN LocalizedCDAFCoverageType AS lafct
        ON lafct.[Value] = CASE
                               WHEN cdaf.DaysCoverage <> 0 THEN 1
                               WHEN cdaf.UnitsCoverage IS NOT NULL THEN 2
                               ELSE 0
                           END
    WHERE (cdaf.EndDate IS NULL OR cdaf.EndDate >= IDT.InstanceCurrentDate)
    GROUP BY pcdaf.PartId
)
SELECT pk.DataSetId,
    pk.Id,
    pk.LocationId,
    pk.PartNumber,
    pk.Revision,
    loc.[Name] AS [Location],
    p.[Description],
    LocalizedInventoryMethod.[Text] AS InventoryMethod,
    pd.InventoryPlanning,
    p.BufferProfileId,
    p.PlanningCalendarId,
    p.PlannedAdjustmentFactorId,
    p.UnitOfMeasure,
    LocalizedPartType.[Text] AS PartType,
    LocalizedDailyUsageType.[Text] AS DailyUsageType,
    p.FixedLeadTime,
    p.GoodsReceiptTime,
    p.AutoApproveRecommendedOrders,
    p.DisableAutoProfile,
    p.AlertHorizon,
    p.DecoupledLeadTime,
    p.OrderCycle,
    p.OrderMaximumQty,
    p.OrderMinimumQty,
    p.OrderMultipleQty,
    p.ManualTopOfRed,
    p.ManualTopOfYellow,
    p.ManualTopOfGreen,
    p.OutSourceCost,
    p.RawMaterialsCost,
    NULLIF(p.PlannerCode, '') AS PlannerCode,
    p.MaterialType,
    p.Notes,
    p.Vendor,
    p.VendorIdentifier,
    p.IncludeInMAC,
    p.FixedReorderCycle,
    p.SourceErp,
    pd.TopOfGreen,
    pd.TopOfYellow,
    pd.TopOfRed,
    pd.TodaysPAF,
    pd.ReorderPoint,
    pd.RedZoneBase,
    pd.PercentageOfToR,
    pd.PercentageOfToRSpike,
    pd.OrderSpikeHorizon,
    pd.SupplyOrderQty,
    pd.OnHandQty,
    pd.DemandAllocationQty,
    pd.IssuedQty,
    pd.ForecastedDailyUsage,
    pd.EffectiveDailyUsage,
    pd.AverageDailyUsage,
    pd.RPlusLeadTime,
    LocalizedPriority.[Text] AS [Priority],
    pd.BufferAlertLevel,
    LocalizedReminderStatus.[Text] AS ReminderStatus,
    pd.IsOrderSpike,
    pd.LTMTotalOrders,
    LocalizedAlertSeverity.[Text] AS AlertSeverity,
    pd.DueDate,
    pd.ReorderQuantityTo,
    pd.InventoryQty,
    pd.NetFlowQty,
    pd.NetFlowPercentage,
    pd.TargetedInventory,
    pd.TodaysYZAF,
    LocalizedCDAFCoverageType_YZAFType.[Text] AS YZAFType,
    pd.YZAFValue,
    pd.YZAFName,
    pd.CDAFTargetedInventory,
    LocalizedCDAFCoverageType_TargetedInventoryType.[Text] AS CDAFTargetedInventoryType,
    pd.TodaysRZAF,
    pd.RZAFValue,
    LocalizedCDAFCoverageType_RZAFType.[Text] AS RZAFType,
    pd.RZAFName,
    pd.EffectiveLeadTime,
    pd.ReorderQuantityFrom,
    pd.ScheduleOrderDate,
    pd.RequestDate,
    pd.OrderReceiptDate,
    pd.SupplyOrderFollowUpBy,
    pd.SupplyOrderNote,
    pd.MaterialAvailabilityShortage,
    pd.MaterialAvailabilityShortageAsChild,
    pd.AvailableToBuild,
    pd.ConstrainingComponent,
    pd.CustomOrderDueDate,
    pd.DaysUntilYellow,
    pd.OrderIntervalDays,
    pd.AlertType,
    pd.AlertJSONBlob,
    sdd.TotalDeployed AS DeploymentQuantity,
    sdd.AfterDeploymentRequirement AS ShortfallQuantity,
    pd.StandardDeviationOfDemand,
    p.UserDefined1,  p.UserDefined2,  p.UserDefined3,  p.UserDefined4,
    p.UserDefined5,  p.UserDefined6,  p.UserDefined7,  p.UserDefined8,
    p.UserDefined9,  p.UserDefined10, p.UserDefined11, p.UserDefined12,
    p.UserDefined13, p.UserDefined14, p.UserDefined15, p.UserDefined16,
    p.ShelfLife,
    LocalizedBoMType.[Text] AS BoMType,
    p.SourceInformation1,
    p.SourceInformation2,
    p.SourceInformation3,
    pd.AlertDate,
    ISNULL(pd.NetFlowQty, 0) - pd.TopOfGreen       AS NetFlowQtyMinusTopOfGreen,          -- was computed column
    pd.OnHandQty - pd.DemandAllocationQty          AS OnHandQtyMinusDemandAllocationQty,  -- was computed column
    srcLoc.[Name] AS SourceLocation,
    p.ForecastedDailyUsageHorizonOverride,
    p.AverageDailyUsageHorizonOverride,
    p.DisableIntelligentAdjustments,
    pd.TodaysIAFUnits,
    p.LeadTimeOffset,
    p.IncludeInCombineByRequestDate,
    aaf.YZAFNames,
    aaf.YZAFTypeDescriptions,
    aaf.RZAFNames,
    aaf.RZAFTypeDescriptions
FROM dbo.PartDetails AS pd
INNER JOIN dbo.Parts      AS p   ON pd.Id = p.Id
INNER JOIN dbo.PartKeys   AS pk  ON pk.Id = p.Id
INNER JOIN dbo.Locations  AS loc ON loc.Id = pk.LocationId
LEFT JOIN dbo.StockDeploymentDestinations AS sdd ON pd.Id = sdd.Id
-- replaces dbo.PartKeyView (views are not mirrored)
LEFT JOIN dbo.Parts     AS SourceParts ON p.SourcePartId = SourceParts.Id
LEFT JOIN dbo.PartKeys  AS srcPk       ON SourceParts.Id = srcPk.Id
LEFT JOIN dbo.Locations AS srcLoc      ON srcPk.LocationId = srcLoc.Id
-- localizations
INNER JOIN LocalizedAlertSeverity  ON LocalizedAlertSeverity.[Value]  = pd.AlertSeverity
INNER JOIN LocalizedPartType       ON LocalizedPartType.[Value]       = p.PartType
INNER JOIN LocalizedBoMType        ON LocalizedBoMType.[Value]        = p.BoMType
INNER JOIN LocalizedPriority       ON LocalizedPriority.[Value]       = pd.[Priority]
INNER JOIN LocalizedDailyUsageType ON LocalizedDailyUsageType.[Value] = p.DailyUsageType
INNER JOIN LocalizedPriority AS LocalizedReminderStatus ON LocalizedReminderStatus.[Value] = pd.ReminderStatus
INNER JOIN LocalizedCDAFCoverageType AS LocalizedCDAFCoverageType_YZAFType              ON LocalizedCDAFCoverageType_YZAFType.[Value]              = pd.YZAFType
INNER JOIN LocalizedCDAFCoverageType AS LocalizedCDAFCoverageType_TargetedInventoryType ON LocalizedCDAFCoverageType_TargetedInventoryType.[Value] = pd.CDAFTargetedInventoryType
INNER JOIN LocalizedCDAFCoverageType AS LocalizedCDAFCoverageType_RZAFType              ON LocalizedCDAFCoverageType_RZAFType.[Value]              = pd.RZAFType
INNER JOIN LocalizedInventoryMethod ON LocalizedInventoryMethod.[Value] = p.InventoryMethod
LEFT JOIN ActiveAdjustmentFactors AS aaf ON pd.Id = aaf.PartId;
