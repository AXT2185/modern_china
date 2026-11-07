-- Hu's Neighborhood variants inherit the original buildings' Gathering Storm
-- power, tourism and entertainment metadata.
DROP TABLE IF EXISTS temp.MC_HU_XP2_BUILDING_MAP;
CREATE TEMP TABLE MC_HU_XP2_BUILDING_MAP (
  SourceBuilding TEXT PRIMARY KEY,
  TargetBuilding TEXT NOT NULL
);

INSERT INTO MC_HU_XP2_BUILDING_MAP (SourceBuilding, TargetBuilding) VALUES
  ('BUILDING_ARENA',              'BUILDING_HU_NEIGHBORHOOD_ARENA'),
  ('BUILDING_ZOO',                'BUILDING_HU_NEIGHBORHOOD_ZOO'),
  ('BUILDING_STADIUM',            'BUILDING_HU_NEIGHBORHOOD_STADIUM'),
  ('BUILDING_AMPHITHEATER',       'BUILDING_HU_NEIGHBORHOOD_AMPHITHEATER'),
  ('BUILDING_MUSEUM_ART',         'BUILDING_HU_NEIGHBORHOOD_MUSEUM_ART'),
  ('BUILDING_MUSEUM_ARTIFACT',    'BUILDING_HU_NEIGHBORHOOD_MUSEUM_ARTIFACT'),
  ('BUILDING_BROADCAST_CENTER',   'BUILDING_HU_NEIGHBORHOOD_BROADCAST_CENTER');

DROP TABLE IF EXISTS temp.MC_HU_XP2_BUILDING_COPY;
CREATE TEMP TABLE MC_HU_XP2_BUILDING_COPY AS
  SELECT b.*
  FROM Buildings_XP2 b
  JOIN MC_HU_XP2_BUILDING_MAP m ON m.SourceBuilding = b.BuildingType;

UPDATE MC_HU_XP2_BUILDING_COPY
  SET BuildingType = (
        SELECT m.TargetBuilding
        FROM MC_HU_XP2_BUILDING_MAP m
        WHERE m.SourceBuilding = MC_HU_XP2_BUILDING_COPY.BuildingType
      );

INSERT OR REPLACE INTO Buildings_XP2
  SELECT * FROM MC_HU_XP2_BUILDING_COPY;
DROP TABLE temp.MC_HU_XP2_BUILDING_COPY;

INSERT OR REPLACE INTO Building_YieldChangesBonusWithPower
  (BuildingType, YieldType, YieldChange)
  SELECT m.TargetBuilding, b.YieldType, b.YieldChange
  FROM Building_YieldChangesBonusWithPower b
  JOIN MC_HU_XP2_BUILDING_MAP m ON m.SourceBuilding = b.BuildingType;

INSERT OR REPLACE INTO Building_TourismBombs_XP2
  (BuildingType, TourismBombValue)
  SELECT m.TargetBuilding, b.TourismBombValue
  FROM Building_TourismBombs_XP2 b
  JOIN MC_HU_XP2_BUILDING_MAP m ON m.SourceBuilding = b.BuildingType;

DROP TABLE temp.MC_HU_XP2_BUILDING_MAP;
