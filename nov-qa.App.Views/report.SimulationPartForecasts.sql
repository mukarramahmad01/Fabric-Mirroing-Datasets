CREATE OR ALTER VIEW [report].[SimulationPartForecasts]
	--
AS
SELECT dbo.PartKeys.DataSetId,
	dbo.SimulationPartForecasts.Id,
	dbo.SimulationPartForecasts.SimulationId,
	dbo.PartKeys.LocationId,
	dbo.PartKeys.PartNumber,
	dbo.PartKeys.Revision,
	dbo.Locations.Name AS [Location],
	dbo.SimulationPartForecasts.[Date],
	dbo.SimulationPartForecasts.TopOfGreen,
	dbo.SimulationPartForecasts.TopOfYellow,
	dbo.SimulationPartForecasts.TopOfRed,
	dbo.SimulationPartForecasts.ReorderPoint,
	dbo.SimulationPartForecasts.RedZoneBase,
	dbo.SimulationPartForecasts.ProjectedDailyDemand,
	dbo.SimulationPartForecasts.ProjectedNewSupply,
	dbo.SimulationPartForecasts.ProjectedSupplyDueToday,
	dbo.SimulationPartForecasts.ProjectedOpenSupply,
	dbo.SimulationPartForecasts.ProjectedQualifiedDemand,
	dbo.SimulationPartForecasts.NetFlow,
	dbo.SimulationPartForecasts.ProjectedInventory,
	dbo.SimulationPartForecasts.ProjectedEDU,
	dbo.Scenarios.Name AS ScenarioName
FROM dbo.SimulationPartForecasts
INNER JOIN dbo.PartKeys ON dbo.SimulationPartForecasts.Id = dbo.PartKeys.Id
INNER JOIN dbo.Locations ON dbo.PartKeys.LocationId = dbo.Locations.Id
INNER JOIN dbo.Simulations ON dbo.SimulationPartForecasts.SimulationId = dbo.Simulations.Id
INNER JOIN dbo.Scenarios ON dbo.Simulations.ScenarioId = dbo.Scenarios.Id
