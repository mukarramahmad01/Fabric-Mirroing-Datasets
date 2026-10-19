CREATE OR ALTER VIEW [report].[SchedulingResourceDailyLoading]
	--
AS
SELECT dbo.Resources.DataSetId,
	dbo.SchedulingOrders.SchedulingSetId,
	dbo.SchedulingRopeItemMaster.SchedulingOrderId,
	dbo.SchedulingRopeItemDetails.SchedulingRopeItemId,
	dbo.Resources.LocationId,
	dbo.SchedulingRopeItemMaster.ResourceId,
	dbo.Resources.Name AS [Resource],
	dbo.Locations.Name AS [Location],
	dbo.SchedulingRopeItemDetails.[Date],
	dbo.SchedulingRopeItemDetails.[CalendarDate],
	dbo.SchedulingRopeItemDetails.Offset,
	dbo.SchedulingRopeItemDetails.Duration,
	DATEADD(mi, dbo.SchedulingRopeItemDetails.Offset, CAST(dbo.SchedulingRopeItemDetails.Date AS DATETIME)) AS [Start],
	DATEADD(mi, dbo.SchedulingRopeItemDetails.Offset + dbo.SchedulingRopeItemDetails.Duration, CAST(dbo.SchedulingRopeItemDetails.Date AS DATETIME)) AS Finish
FROM dbo.SchedulingRopeItemDetails
INNER JOIN dbo.SchedulingRopeItemMaster ON dbo.SchedulingRopeItemDetails.SchedulingRopeItemId = dbo.SchedulingRopeItemMaster.Id
INNER JOIN dbo.Resources ON dbo.SchedulingRopeItemMaster.ResourceId = dbo.Resources.Id
INNER JOIN dbo.SchedulingOrders ON dbo.SchedulingRopeItemMaster.SchedulingOrderId = dbo.SchedulingOrders.Id
INNER JOIN dbo.Locations ON dbo.Locations.Id = dbo.Resources.LocationId
