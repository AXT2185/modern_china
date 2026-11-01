-- =============================================================
-- 现代中国 : 总督「朱」晋升中需要按数据库动态展开的部分
--   左1 游击敌后  : 侦察类单位建造速度 (逐个时代)
--   中2 军民结合  : 用信仰购买军事单位 (逐个兵种标签)
--   左3 军工建设  : 军营 / 工业区内的建筑建造速度
-- =============================================================

-- -------------------------------------------------------------
-- 左1 游击敌后：侦察类单位建造速度 +75%
-- -------------------------------------------------------------
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
  SELECT DISTINCT 'MC_ZHU_RECON_' || REPLACE(EraType, 'ERA_', ''),
         'MODIFIER_PLAYER_CITIES_ADJUST_UNIT_TAG_ERA_PRODUCTION',
         'MC_REQSET_CITY_HAS_PROMO_YOUJI'
  FROM Eras;

INSERT INTO ModifierArguments (ModifierId, Name, Value)
  SELECT DISTINCT 'MC_ZHU_RECON_' || REPLACE(EraType, 'ERA_', ''), 'UnitPromotionClass', 'PROMOTION_CLASS_RECON'
  FROM Eras;

INSERT INTO ModifierArguments (ModifierId, Name, Value)
  SELECT DISTINCT 'MC_ZHU_RECON_' || REPLACE(EraType, 'ERA_', ''), 'EraType', EraType
  FROM Eras;

INSERT INTO ModifierArguments (ModifierId, Name, Value)
  SELECT DISTINCT 'MC_ZHU_RECON_' || REPLACE(EraType, 'ERA_', ''), 'Amount', '+75'
  FROM Eras;

INSERT INTO GovernorPromotionModifiers (GovernorPromotionType, ModifierId)
  SELECT DISTINCT 'GOVERNOR_PROMOTION_ZHU_YOUJI', 'MC_ZHU_RECON_' || REPLACE(EraType, 'ERA_', '')
  FROM Eras;

-- -------------------------------------------------------------
-- 中2 军民结合：该城市可用信仰值购买军事单位（按兵种标签展开）
-- -------------------------------------------------------------
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
  SELECT DISTINCT 'MC_ZHU_FAITHBUY_' || REPLACE(tt.Tag, 'CLASS_', ''),
         'MODIFIER_PLAYER_CITIES_ENABLE_UNIT_FAITH_PURCHASE',
         'MC_REQSET_CITY_HAS_PROMO_JUNMIN'
  FROM TypeTags tt
  JOIN Units u ON u.UnitType = tt.Type
  WHERE tt.Tag LIKE 'CLASS_%'
    AND u.Combat > 0
    AND u.FormationClass IN ('FORMATION_CLASS_LAND_COMBAT', 'FORMATION_CLASS_NAVAL', 'FORMATION_CLASS_AIR');

INSERT INTO ModifierArguments (ModifierId, Name, Value)
  SELECT DISTINCT 'MC_ZHU_FAITHBUY_' || REPLACE(tt.Tag, 'CLASS_', ''), 'Tag', tt.Tag
  FROM TypeTags tt
  JOIN Units u ON u.UnitType = tt.Type
  WHERE tt.Tag LIKE 'CLASS_%'
    AND u.Combat > 0
    AND u.FormationClass IN ('FORMATION_CLASS_LAND_COMBAT', 'FORMATION_CLASS_NAVAL', 'FORMATION_CLASS_AIR');

INSERT INTO GovernorPromotionModifiers (GovernorPromotionType, ModifierId)
  SELECT DISTINCT 'GOVERNOR_PROMOTION_ZHU_JUNMIN', 'MC_ZHU_FAITHBUY_' || REPLACE(tt.Tag, 'CLASS_', '')
  FROM TypeTags tt
  JOIN Units u ON u.UnitType = tt.Type
  WHERE tt.Tag LIKE 'CLASS_%'
    AND u.Combat > 0
    AND u.FormationClass IN ('FORMATION_CLASS_LAND_COMBAT', 'FORMATION_CLASS_NAVAL', 'FORMATION_CLASS_AIR');

-- -------------------------------------------------------------
-- 左3 军工建设：军营 / 工业区内的建筑建造速度 +50%
-- -------------------------------------------------------------
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
  SELECT DISTINCT 'MC_ZHU_BLD_' || REPLACE(BuildingType, 'BUILDING_', ''),
         'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_PRODUCTION',
         'MC_REQSET_CITY_HAS_PROMO_JUNGONG'
  FROM Buildings
  WHERE PrereqDistrict IN ('DISTRICT_ENCAMPMENT', 'DISTRICT_INDUSTRIAL_ZONE');

INSERT INTO ModifierArguments (ModifierId, Name, Value)
  SELECT DISTINCT 'MC_ZHU_BLD_' || REPLACE(BuildingType, 'BUILDING_', ''), 'BuildingType', BuildingType
  FROM Buildings
  WHERE PrereqDistrict IN ('DISTRICT_ENCAMPMENT', 'DISTRICT_INDUSTRIAL_ZONE');

INSERT INTO ModifierArguments (ModifierId, Name, Value)
  SELECT DISTINCT 'MC_ZHU_BLD_' || REPLACE(BuildingType, 'BUILDING_', ''), 'Amount', '50'
  FROM Buildings
  WHERE PrereqDistrict IN ('DISTRICT_ENCAMPMENT', 'DISTRICT_INDUSTRIAL_ZONE');

INSERT INTO GovernorPromotionModifiers (GovernorPromotionType, ModifierId)
  SELECT DISTINCT 'GOVERNOR_PROMOTION_ZHU_JUNGONG', 'MC_ZHU_BLD_' || REPLACE(BuildingType, 'BUILDING_', '')
  FROM Buildings
  WHERE PrereqDistrict IN ('DISTRICT_ENCAMPMENT', 'DISTRICT_INDUSTRIAL_ZONE');

-- -------------------------------------------------------------
-- 给 XML 中定义的静态晋升 Modifier 补上「城市拥有该晋升」条件
-- -------------------------------------------------------------
UPDATE Modifiers SET SubjectRequirementSetId = 'MC_REQSET_CITY_HAS_PROMO_JUNGONG'
  WHERE ModifierId IN ('MC_ZHU_ENCAMPMENT_PRODUCTION', 'MC_ZHU_INDUSTRIAL_PRODUCTION');

UPDATE Modifiers SET SubjectRequirementSetId = 'MC_REQSET_CITY_HAS_PROMO_HUNHE'
  WHERE ModifierId LIKE 'MC_ZHU_TRADE_%';

UPDATE Modifiers SET SubjectRequirementSetId = 'MC_REQSET_CITY_HAS_PROMO_GENJUDI'
  WHERE ModifierId = 'MC_ZHU_BUILDER_CHARGE';
