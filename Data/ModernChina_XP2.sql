-- =============================================================
-- 现代中国 : 风云变幻(Expansion2) 专属补丁
-- =============================================================

-- 红军沿用线列步兵的战略资源消耗
INSERT INTO Units_XP2 (UnitType, ResourceCost)
  SELECT 'UNIT_RED_ARMY', ResourceCost FROM Units_XP2 WHERE UnitType = 'UNIT_LINE_INFANTRY';

-- Leader-specific Gathering Storm rows live under Data/Leaders/<Leader>/.
