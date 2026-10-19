CREATE OR ALTER VIEW [report].[BillOfMaterials]
	--
AS
SELECT ppk.DataSetId,
	bom.ParentPartId,
	ppk.LocationId AS ParentLocationId,
	bom.ChildPartId,
	cpk.LocationId AS ChildLocationId,
	ppk.PartNumber AS ParentPartNumber,
	ppk.Revision AS ParentRevision,
	pl.Name AS ParentLocation,
	cpk.PartNumber AS ChildPartNumber,
	cpk.Revision AS ChildRevision,
	cl.Name AS ChildLocation,
	bom.Quantity,
	bom.ValidFrom,
	bom.ValidTo,
	bom.ChangeNumber
FROM dbo.BillOfMaterials bom
INNER JOIN dbo.PartKeys AS ppk ON ppk.Id = bom.ParentPartId
INNER JOIN dbo.Locations AS pl ON pl.Id = ppk.LocationId
INNER JOIN dbo.PartKeys AS cpk ON bom.ChildPartId = cpk.Id
INNER JOIN dbo.Locations AS cl ON cpk.LocationId = cl.Id
