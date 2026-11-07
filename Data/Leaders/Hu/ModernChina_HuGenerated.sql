-- =============================================================
-- Hu: unique Neighborhood and Entertainment/Theater building variants
--   Source rows are cloned, then only the Type, district and trait are changed.
-- =============================================================

DROP TABLE IF EXISTS temp.MC_HU_NEIGHBORHOOD_TEMPLATE;
CREATE TEMP TABLE MC_HU_NEIGHBORHOOD_TEMPLATE AS
  SELECT * FROM Districts WHERE DistrictType = 'DISTRICT_NEIGHBORHOOD';

UPDATE MC_HU_NEIGHBORHOOD_TEMPLATE
  SET DistrictType = 'DISTRICT_HU_NEIGHBORHOOD',
      Name = 'LOC_DISTRICT_NEIGHBORHOOD_NAME',
      Description = 'LOC_DISTRICT_HU_NEIGHBORHOOD_DESCRIPTION',
      PrereqCivic = 'CIVIC_RECORDED_HISTORY',
      TraitType = 'TRAIT_LEADER_HU_SCIENTIFIC_OUTLOOK';

INSERT OR REPLACE INTO Districts
  SELECT * FROM MC_HU_NEIGHBORHOOD_TEMPLATE;
DROP TABLE temp.MC_HU_NEIGHBORHOOD_TEMPLATE;

INSERT OR REPLACE INTO DistrictReplaces
  (CivUniqueDistrictType, ReplacesDistrictType)
VALUES
  ('DISTRICT_HU_NEIGHBORHOOD', 'DISTRICT_NEIGHBORHOOD');

-- A Hu Neighborhood also receives Theater Square's existing adjacency rules.
INSERT OR REPLACE INTO District_Adjacencies (DistrictType, YieldChangeId)
  SELECT 'DISTRICT_HU_NEIGHBORHOOD', YieldChangeId
  FROM District_Adjacencies
  WHERE DistrictType = 'DISTRICT_THEATER';

DROP TABLE IF EXISTS temp.MC_HU_BUILDING_MAP;
CREATE TEMP TABLE MC_HU_BUILDING_MAP (
  SourceBuilding TEXT PRIMARY KEY,
  TargetBuilding TEXT NOT NULL
);

INSERT INTO MC_HU_BUILDING_MAP (SourceBuilding, TargetBuilding) VALUES
  ('BUILDING_ARENA',              'BUILDING_HU_NEIGHBORHOOD_ARENA'),
  ('BUILDING_ZOO',                'BUILDING_HU_NEIGHBORHOOD_ZOO'),
  ('BUILDING_STADIUM',            'BUILDING_HU_NEIGHBORHOOD_STADIUM'),
  ('BUILDING_AMPHITHEATER',       'BUILDING_HU_NEIGHBORHOOD_AMPHITHEATER'),
  ('BUILDING_MUSEUM_ART',         'BUILDING_HU_NEIGHBORHOOD_MUSEUM_ART'),
  ('BUILDING_MUSEUM_ARTIFACT',    'BUILDING_HU_NEIGHBORHOOD_MUSEUM_ARTIFACT'),
  ('BUILDING_BROADCAST_CENTER',   'BUILDING_HU_NEIGHBORHOOD_BROADCAST_CENTER');

DROP TABLE IF EXISTS temp.MC_HU_BUILDING_COPY;
CREATE TEMP TABLE MC_HU_BUILDING_COPY AS
  SELECT b.*
  FROM Buildings b
  JOIN MC_HU_BUILDING_MAP m ON m.SourceBuilding = b.BuildingType;

UPDATE MC_HU_BUILDING_COPY
  SET BuildingType = (
        SELECT m.TargetBuilding
        FROM MC_HU_BUILDING_MAP m
        WHERE m.SourceBuilding = MC_HU_BUILDING_COPY.BuildingType
      ),
      PrereqDistrict = 'DISTRICT_HU_NEIGHBORHOOD',
      TraitType = 'TRAIT_LEADER_HU_SCIENTIFIC_OUTLOOK';

INSERT OR REPLACE INTO Buildings
  SELECT * FROM MC_HU_BUILDING_COPY;
DROP TABLE temp.MC_HU_BUILDING_COPY;

INSERT OR REPLACE INTO BuildingPrereqs (Building, PrereqBuilding)
  SELECT m.TargetBuilding, COALESCE(pm.TargetBuilding, bp.PrereqBuilding)
  FROM BuildingPrereqs bp
  JOIN MC_HU_BUILDING_MAP m ON m.SourceBuilding = bp.Building
  LEFT JOIN MC_HU_BUILDING_MAP pm ON pm.SourceBuilding = bp.PrereqBuilding;

INSERT OR REPLACE INTO BuildingModifiers (BuildingType, ModifierId)
  SELECT m.TargetBuilding, bm.ModifierId
  FROM BuildingModifiers bm
  JOIN MC_HU_BUILDING_MAP m ON m.SourceBuilding = bm.BuildingType;

INSERT OR REPLACE INTO Building_YieldChanges
  (BuildingType, YieldType, YieldChange)
  SELECT m.TargetBuilding, y.YieldType, y.YieldChange
  FROM Building_YieldChanges y
  JOIN MC_HU_BUILDING_MAP m ON m.SourceBuilding = y.BuildingType;

INSERT OR REPLACE INTO Building_GreatPersonPoints
  (BuildingType, GreatPersonClassType, PointsPerTurn)
  SELECT m.TargetBuilding, g.GreatPersonClassType, g.PointsPerTurn
  FROM Building_GreatPersonPoints g
  JOIN MC_HU_BUILDING_MAP m ON m.SourceBuilding = g.BuildingType;

INSERT OR REPLACE INTO Building_GreatWorks
  (BuildingType, GreatWorkSlotType, NumSlots, ThemingUniquePerson,
   ThemingSameObjectType, ThemingUniqueCivs, ThemingSameEras,
   ThemingYieldMultiplier, ThemingTourismMultiplier,
   NonUniquePersonYield, NonUniquePersonTourism, ThemingBonusDescription)
  SELECT m.TargetBuilding, w.GreatWorkSlotType, w.NumSlots,
         w.ThemingUniquePerson, w.ThemingSameObjectType, w.ThemingUniqueCivs,
         w.ThemingSameEras, w.ThemingYieldMultiplier,
         w.ThemingTourismMultiplier, w.NonUniquePersonYield,
         w.NonUniquePersonTourism, w.ThemingBonusDescription
  FROM Building_GreatWorks w
  JOIN MC_HU_BUILDING_MAP m ON m.SourceBuilding = w.BuildingType;

INSERT OR REPLACE INTO Building_CitizenYieldChanges
  (BuildingType, YieldType, YieldChange)
  SELECT m.TargetBuilding, y.YieldType, y.YieldChange
  FROM Building_CitizenYieldChanges y
  JOIN MC_HU_BUILDING_MAP m ON m.SourceBuilding = y.BuildingType;

DROP TABLE temp.MC_HU_BUILDING_MAP;
