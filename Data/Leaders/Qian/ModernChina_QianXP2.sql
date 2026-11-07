-- Qian: the Mechanics Class uses the powered-building model from GS.
INSERT INTO Buildings_XP2 (BuildingType, RequiredPower) VALUES
  ('BUILDING_QIAN_MECHANICS_CLASS', 3);

INSERT INTO Building_YieldChangesBonusWithPower
  (BuildingType, YieldType, YieldChange)
VALUES
  ('BUILDING_QIAN_MECHANICS_CLASS', 'YIELD_SCIENCE', 10);
