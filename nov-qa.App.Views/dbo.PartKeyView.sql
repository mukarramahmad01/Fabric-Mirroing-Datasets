-- Update PartKeyView to use the index provided by PartKeyView (Instead of Part.LocationId) to do Location name joins (SELECT Location from PartKeyViews WHERE Id = 1)
CREATE OR ALTER VIEW [dbo].[PartKeyView]
--
AS
SELECT  dbo.PartKeys.Id, dbo.PartKeys.DataSetId, dbo.PartKeys.LocationId, dbo.PartKeys.PartNumber, dbo.PartKeys.Revision, dbo.Locations.Name AS Location
FROM    dbo.PartKeys INNER JOIN
        dbo.Parts ON dbo.PartKeys.Id = dbo.Parts.Id INNER JOIN
        dbo.Locations ON dbo.PartKeys.LocationId = dbo.Locations.Id
