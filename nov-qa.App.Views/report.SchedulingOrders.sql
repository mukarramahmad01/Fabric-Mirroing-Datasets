CREATE OR ALTER VIEW [report].[SchedulingOrders]
	--
AS
WITH LocalizedExpedite
AS (
	SELECT Value,
		[Text]
	FROM dbo.EnumLanguageMappings
	WHERE EnumTypeName = N'Expedite'
		AND Culture = ISNULL(CONVERT(VARCHAR(10), SESSION_CONTEXT(N'CurrentCulture')), 'en')
	),
cte_FilteredSchedulingOrders
AS (
	SELECT DISTINCT so.Id
	FROM [dbo].[SchedulingOrders] so
	INNER JOIN [dbo].[SchedulingOrderPackets] sop ON sop.ChildSchedulingOrderId = so.Id
		OR sop.ParentSchedulingOrderId = so.Id
	),
cte_PacketsRelantionshipsTemp
AS (
	SELECT so.[Id],
		so.OrderNumber,
		toplvlso.OrderNumber AS [TopLevelPacket],
		chidPacketsInfo.OrderNumber AS [PacketParent]
	FROM [dbo].[SchedulingOrders] so
	INNER JOIN cte_FilteredSchedulingOrders fso ON fso.Id = so.Id
	LEFT JOIN [dbo].[SchedulingOrderPackets] childPackets ON childPackets.ChildSchedulingOrderId = so.Id
	LEFT JOIN [dbo].[SchedulingOrders] chidPacketsInfo ON chidPacketsInfo.Id = childPackets.ParentSchedulingOrderId
	LEFT JOIN dbo.SchedulingOrders AS toplvlso ON toplvlso.Id = childPackets.TopLevelSchedulingOrderId
	),
cte_PacketsRelantionships
AS (
	SELECT DISTINCT packetsRelantionshipsTemp.Id,
		packetsRelantionshipsTemp.OrderNumber,
		CASE WHEN (
					packetsRelantionshipsTemp.TopLevelPacket IS NULL
					AND topLevelPacketInfo.Id IS NOT NULL
					) THEN packetsRelantionshipsTemp.OrderNumber ELSE packetsRelantionshipsTemp.TopLevelPacket END AS TopLevelPacket,
		packetsRelantionshipsTemp.PacketParent
	FROM cte_PacketsRelantionshipsTemp AS packetsRelantionshipsTemp
	LEFT JOIN cte_PacketsRelantionshipsTemp AS topLevelPacketInfo ON topLevelPacketInfo.TopLevelPacket = packetsRelantionshipsTemp.OrderNumber
	)
SELECT dbo.PartKeys.DataSetId,
	dbo.SchedulingOrders.Id,
	dbo.SchedulingOrders.SchedulingSetId,
	dbo.SchedulingOrders.OrderNumber,
	dbo.RoutingSets.Id AS RoutingSetId,
	RoutingSets.[Name] AS RoutingName,
	dbo.RoutingSets.[PartId],
	dbo.PartKeys.PartNumber,
	dbo.PartKeys.Revision,
	dbo.PartKeys.LocationId,
	dbo.Locations.[Name] AS [Location],
	dbo.SchedulingOrders.OrderQuantity,
	dbo.SchedulingOrders.PromiseDate,
	-- optional group info
	dbo.SchedulingGroups.Name AS ScheduleGroupName,
	dbo.SchedulingGroups.ResourceId AS ScheduleGroupResourceId,
	IIF(dbo.SchedulingOrders.SchedulingGroupId IS NULL, NULL, dbo.SchedulingOrders.ScheduleGroupOrder) AS ScheduleGroupOrder,
	dbo.SchedulingGroups.GroupItemCount AS ScheduleGroupTotal,
	dbo.SchedulingOrders.ScheduleGroupBatchCount,
	dbo.SchedulingOrders.BeginRequestDate,
	dbo.SchedulingOrders.EndRequestDate,
	ISNULL(dbo.SchedulingOrders.EffectivePriority, dbo.SchedulingOrders.[Priority]) AS Priority,
	dbo.SchedulingOrders.FrozenPriority,
	LocalizedExpedite.[Text] AS Expedite,
	dbo.SchedulingOrders.PlannedReleaseDate,
	dbo.SchedulingOrders.LockDate,
	dbo.SchedulingOrders.ReleaseDate,
	dbo.SchedulingOrders.OnHoldDate,
	dbo.SchedulingOrders.CloseDate,
	dbo.SchedulingOrders.ScheduleState,
	CAST(CASE WHEN dbo.SchedulingOrders.CurrentRopeItemId IS NULL THEN 0 ELSE 1 END AS BIT) AS InProgress,
	dbo.SchedulingOrders.InInventory,
	dbo.SchedulingOrders.SalesOrderNumber,
	dbo.SchedulingOrders.LineItem,
	dbo.SchedulingOrders.SalesOrderQuantity,
	dbo.SchedulingOrders.OrderDate,
	dbo.SchedulingOrders.Customer,
	dbo.SchedulingOrders.UnitPrice,
	dbo.SchedulingOrders.OnHandQtyPenetration,
	dbo.SchedulingOrders.AvailableOnHandQtyPenetration,
	dbo.SchedulingOrders.MaterialAvailabilityCheck,
	dbo.SchedulingOrders.ProductionNotes,
	dbo.SchedulingOrders.FinalBufferOverride,
	COALESCE(packetsInfo.TopLevelPacket, '') AS TopLevelPacket,
	COALESCE(packetsInfo.PacketParent, '') AS PacketParent
FROM dbo.Locations
INNER JOIN dbo.PartKeys ON dbo.Locations.Id = dbo.PartKeys.LocationId
INNER JOIN dbo.RoutingSets ON PartKeys.Id = RoutingSets.PartId
INNER JOIN dbo.SchedulingOrders ON dbo.RoutingSets.Id = dbo.SchedulingOrders.RoutingSetId
INNER JOIN LocalizedExpedite ON LocalizedExpedite.Value = dbo.SchedulingOrders.Expedite
LEFT JOIN dbo.SchedulingGroups ON dbo.SchedulingOrders.SchedulingGroupId = dbo.SchedulingGroups.Id
LEFT JOIN cte_PacketsRelantionships packetsInfo ON packetsInfo.Id = dbo.SchedulingOrders.Id;
