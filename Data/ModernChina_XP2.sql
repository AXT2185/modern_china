-- =============================================================
-- 现代中国 : 风云变幻(Expansion2) 专属补丁
-- =============================================================

-- 红军沿用线列步兵的战略资源消耗
INSERT INTO Units_XP2 (UnitType, ResourceCost)
  SELECT 'UNIT_RED_ARMY', ResourceCost FROM Units_XP2 WHERE UnitType = 'UNIT_LINE_INFANTRY';

-- Qian Xuesen: the Mechanics Class uses the powered-building model from GS.
INSERT INTO Buildings_XP2 (BuildingType, RequiredPower) VALUES
  ('BUILDING_QIAN_MECHANICS_CLASS', 3);

INSERT INTO Building_YieldChangesBonusWithPower (BuildingType, YieldType, YieldChange) VALUES
  ('BUILDING_QIAN_MECHANICS_CLASS', 'YIELD_SCIENCE', 10);
