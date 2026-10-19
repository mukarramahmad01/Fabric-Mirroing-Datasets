CREATE OR ALTER VIEW [dbo].[SchedulingRopeItems]
AS
WITH CTE_RoutingItems_Checklist
AS (
    SELECT DISTINCT ri.ResourceId,
        scl.[Name] AS [ChecklistName],
        rs.Id AS [RoutingSetId],
        so.Id AS [SOId],
        ri.OperationSequenceNumber
    FROM RoutingItems ri
    INNER JOIN Checklists scl
        ON ri.ChecklistId = scl.Id
    INNER JOIN [dbo].[RoutingSets] rs
        ON ri.RoutingSetId = rs.Id
    INNER JOIN [dbo].[SchedulingOrders] so
        ON rs.Id = so.RoutingSetId
    ),
CTE_RoutingItemsForOrder_Checklist
AS (
    SELECT DISTINCT ri.ResourceId,
        scl.[Name] AS [ChecklistName],
        rs.Id AS [RoutingSetId],
        so.Id AS [SOId],
        ri.OperationSequenceNumber
    FROM RoutingItemsForOrder ri
    INNER JOIN Checklists scl
        ON ri.ChecklistId = scl.Id
    INNER JOIN [dbo].[PartKeys] pk
        ON ri.PartId = pk.Id
    INNER JOIN [dbo].[SchedulingSets] ss
        ON pk.LocationId = ss.LocationId
    INNER JOIN [dbo].[SchedulingOrders] so
        ON ri.OrderNumber = so.OrderNumber
            AND ss.Id = so.SchedulingSetId
    INNER JOIN [dbo].[RoutingSets] rs
        ON so.RoutingSetId = rs.Id
    ),
CTE_CheckList
AS (
    SELECT DISTINCT COALESCE(t2.ResourceId, t1.ResourceId) AS ResourceId,
        COALESCE(t2.[ChecklistName], t1.[ChecklistName]) AS [ChecklistName],
        COALESCE(t2.[RoutingSetId], t1.[RoutingSetId]) AS [RoutingSetId],
        COALESCE(t2.[SOId], t1.[SOId]) AS [SOId],
        COALESCE(t2.OperationSequenceNumber, t1.OperationSequenceNumber) AS OperationSequenceNumber
    FROM CTE_RoutingItems_Checklist t1
    LEFT JOIN CTE_RoutingItemsForOrder_Checklist t2
        ON t1.SOId = t2.SOId
    WHERE t2.SOId IS NOT NULL
        OR t1.SOId IS NOT NULL
    )
SELECT dbo.Resources.DataSetId,
    dbo.SchedulingRopeItemMaster.Id,
    dbo.SchedulingSets.LocationId,
    dbo.SchedulingRopeItemMaster.SchedulingOrderId,
    dbo.SchedulingOrders.RoutingSetId,
    dbo.SchedulingRopeItemMaster.ResourceId,
    dbo.Resources.Name AS ResourceName,
    LEAD(dbo.Resources.Name) OVER (
        PARTITION BY dbo.SchedulingRopeItemMaster.SchedulingOrderId ORDER BY dbo.Resources.DataSetId,
            dbo.SchedulingRopeItemMaster.Id
        ) AS NextResource,
    dbo.Resources.Description AS ResourceDescription,
    dbo.Resources.ResourceType,
    dbo.SchedulingRopeItemMaster.Efficiency,
    dbo.SchedulingRopeItemMaster.CrewSize,
    dbo.SchedulingRopeItemMaster.IsPrimaryConstraint,
    dbo.SchedulingRopeItemMaster.Buffer,
    dbo.SchedulingRopeItemMaster.OperationSequenceNumber,
    dbo.SchedulingRopeItemMaster.OperationDescription,
    dbo.SchedulingRopeItemMaster.ScheduledReceiptAtBuffer,
    dbo.SchedulingRopeItemMaster.GreenZoneEnd,
    dbo.SchedulingRopeItemMaster.YellowZoneEnd,
    dbo.SchedulingRopeItemMaster.ScheduledStartOperation,
    dbo.SchedulingRopeItemMaster.Duration AS FullDuration,
    dbo.SchedulingRopeItemMaster.ScheduledEndOperation,
    dbo.SchedulingRopeItemMaster.FixedOffset,
    dbo.SchedulingRopeItemMaster.ParallelOperationResourceCount,
    --dbo.SchedulingRopeItemMaster.TIMESTAMP,
    CTE.[ChecklistName]
FROM dbo.SchedulingRopeItemMaster
INNER JOIN dbo.Resources
    ON dbo.Resources.Id = dbo.SchedulingRopeItemMaster.ResourceId
INNER JOIN dbo.SchedulingOrders
    ON dbo.SchedulingOrders.Id = dbo.SchedulingRopeItemMaster.SchedulingOrderId
INNER JOIN dbo.SchedulingSets
    ON dbo.SchedulingOrders.SchedulingSetId = dbo.SchedulingSets.Id
LEFT JOIN CTE_CheckList CTE
    ON CTE.ResourceId = dbo.Resources.Id
        AND CTE.RoutingSetId = dbo.SchedulingOrders.RoutingSetId
        AND CTE.SOId = dbo.SchedulingOrders.Id
        AND CTE.OperationSequenceNumber = dbo.SchedulingRopeItemMaster.OperationSequenceNumber
