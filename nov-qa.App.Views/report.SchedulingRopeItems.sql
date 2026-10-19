CREATE OR ALTER VIEW [report].[SchedulingRopeItems]
AS
SELECT dbo.Resources.DataSetId,
	dbo.SchedulingSets.LocationId,
	dbo.Locations.Name AS Location,
	dbo.SchedulingRopeItemMaster.Id,
	dbo.SchedulingRopeItemMaster.SchedulingOrderId,
	dbo.SchedulingOrders.RoutingSetId,
	dbo.SchedulingRopeItemMaster.ResourceId,
	dbo.Resources.[Name] AS [Resource],
	dbo.SchedulingRopeItemMaster.IsPrimaryConstraint,
	dbo.SchedulingRopeItemMaster.[Buffer],
	dbo.SchedulingRopeItemMaster.OperationSequenceNumber,
	dbo.SchedulingRopeItemMaster.OperationDescription,
	dbo.SchedulingRopeItemMaster.ScheduledReceiptAtBuffer,
	dbo.SchedulingRopeItemMaster.ScheduledStartOperation,
	dbo.SchedulingRopeItemMaster.Duration AS FullDuration,
	dbo.SchedulingRopeItemMaster.ScheduledEndOperation,
	dbo.SchedulingRopeItemMaster.FixedOffset,
	dbo.SchedulingRopeItemMaster.GreenZoneEnd,
	dbo.SchedulingRopeItemMaster.YellowZoneEnd,
	dbo.SchedulingRopeItemMaster.Efficiency,
	dbo.SchedulingRopeItemMaster.CrewSize,
	RIR.ActualReceiptAtBuffer,
	RIR.ActualStartOperation,
	RIR.ActualEndOperation,
	FRIM.ActualReceiptAtBuffer AS FinalReceiptAtBuffer,
	FRIM.ActualStartOperation AS FinalStartOperation,
	RIR.ActualReceiptAtBuffer_LastBatch,
	RIR.ActualStartOperation_LastBatch,
	RIR.ActualEndOperation_LastBatch,
	RIR.QuantityReceived,
	RIR.QuantityStarted,
	RIR.QuantityCompleted
FROM dbo.SchedulingRopeItemMaster
INNER JOIN dbo.Resources ON dbo.Resources.Id = dbo.SchedulingRopeItemMaster.ResourceId
INNER JOIN dbo.SchedulingOrders ON dbo.SchedulingOrders.Id = dbo.SchedulingRopeItemMaster.SchedulingOrderId
INNER JOIN dbo.SchedulingSets ON dbo.SchedulingSets.Id = dbo.SchedulingOrders.SchedulingSetId
INNER JOIN dbo.Locations ON dbo.Locations.Id = dbo.SchedulingSets.LocationId
INNER JOIN dbo.SchedulingRopeItemMaster AS RIR ON dbo.SchedulingRopeItemMaster.Id = RIR.Id
INNER JOIN dbo.SchedulingRopeItemMaster AS FRIM ON dbo.SchedulingOrders.FinalRopeItemId = FRIM.Id
