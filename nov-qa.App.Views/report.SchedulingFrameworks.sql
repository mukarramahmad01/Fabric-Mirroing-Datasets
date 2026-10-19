CREATE OR ALTER VIEW [report].[SchedulingFrameworks]
	--
AS
SELECT dbo.SchedulingSets.DataSetId,
	dbo.SchedulingFrameworks.Id,
	dbo.SchedulingFrameworks.SchedulingSetId,
	dbo.SchedulingSets.LocationId,
	dbo.Locations.Name AS Location,
	dbo.SchedulingFrameworks.ResourceId,
	dbo.Resources.Name AS Resource,
	dbo.SchedulingFrameworks.[Date],
	dbo.SchedulingFrameworks.Year,
	dbo.SchedulingFrameworks.WeekNumber,
	dbo.SchedulingFrameworks.AvailableCapacity,
	dbo.SchedulingFrameworks.BeginningOfDay,
	dbo.SchedulingFrameworks.EndOfDay
FROM dbo.SchedulingFrameworks
INNER JOIN dbo.SchedulingSets ON dbo.SchedulingFrameworks.SchedulingSetId = dbo.SchedulingSets.Id
INNER JOIN dbo.Resources ON dbo.SchedulingFrameworks.ResourceId = dbo.Resources.Id
INNER JOIN dbo.Locations ON dbo.Locations.Id = dbo.SchedulingSets.LocationId
