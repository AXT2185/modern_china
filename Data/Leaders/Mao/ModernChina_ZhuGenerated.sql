-- =============================================================
-- Mao / Zhu: generated rows that depend on the loaded unit and building set
--   左1 游击敌后: only combat units trained by Zhu's city gain +1 movement
--   中2 军民结合: enable Faith purchases for every combat unit class
--   左3 军工建设: all Encampment / Industrial Zone buildings get +50% production
-- =============================================================

-- -------------------------------------------------------------
-- 左1 游击敌后: grant the ability only to combat units.
-- The city-grant modifier itself is attached to the promotion in the XML.
-- -------------------------------------------------------------
INSERT OR REPLACE INTO TypeTags (Type, Tag)
  SELECT DISTINCT 'ABILITY_MC_ZHU_MILITARY_MOVEMENT', tt.Tag
  FROM TypeTags tt
  JOIN Units u ON u.UnitType = tt.Type
  WHERE tt.Tag LIKE 'CLASS_%'
    AND u.Combat > 0;

-- -------------------------------------------------------------
-- 中2 军民结合: enable Faith purchases for each combat unit class.
-- -------------------------------------------------------------
INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
  SELECT DISTINCT 'MC_ZHU_FAITHBUY_' || REPLACE(tt.Tag, 'CLASS_', ''),
         'MODIFIER_PLAYER_CITIES_ENABLE_UNIT_FAITH_PURCHASE',
         'MC_REQSET_CITY_HAS_PROMO_JUNMIN'
  FROM TypeTags tt
  JOIN Units u ON u.UnitType = tt.Type
  WHERE tt.Tag LIKE 'CLASS_%'
    AND u.Combat > 0
    AND u.FormationClass IN ('FORMATION_CLASS_LAND_COMBAT', 'FORMATION_CLASS_NAVAL', 'FORMATION_CLASS_AIR');

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
  SELECT DISTINCT 'MC_ZHU_FAITHBUY_' || REPLACE(tt.Tag, 'CLASS_', ''), 'Tag', tt.Tag
  FROM TypeTags tt
  JOIN Units u ON u.UnitType = tt.Type
  WHERE tt.Tag LIKE 'CLASS_%'
    AND u.Combat > 0
    AND u.FormationClass IN ('FORMATION_CLASS_LAND_COMBAT', 'FORMATION_CLASS_NAVAL', 'FORMATION_CLASS_AIR');

INSERT OR REPLACE INTO GovernorPromotionModifiers (GovernorPromotionType, ModifierId)
  SELECT DISTINCT 'GOVERNOR_PROMOTION_ZHU_JUNMIN', 'MC_ZHU_FAITHBUY_' || REPLACE(tt.Tag, 'CLASS_', '')
  FROM TypeTags tt
  JOIN Units u ON u.UnitType = tt.Type
  WHERE tt.Tag LIKE 'CLASS_%'
    AND u.Combat > 0
    AND u.FormationClass IN ('FORMATION_CLASS_LAND_COMBAT', 'FORMATION_CLASS_NAVAL', 'FORMATION_CLASS_AIR');

-- -------------------------------------------------------------
-- 左3 军工建设: Encampment / Industrial Zone buildings +50%.
-- -------------------------------------------------------------
INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
  SELECT DISTINCT 'MC_ZHU_BLD_' || REPLACE(BuildingType, 'BUILDING_', ''),
         'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_PRODUCTION',
         'MC_REQSET_CITY_HAS_PROMO_JUNGONG'
  FROM Buildings
  WHERE PrereqDistrict IN ('DISTRICT_ENCAMPMENT', 'DISTRICT_INDUSTRIAL_ZONE');

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
  SELECT DISTINCT 'MC_ZHU_BLD_' || REPLACE(BuildingType, 'BUILDING_', ''), 'BuildingType', BuildingType
  FROM Buildings
  WHERE PrereqDistrict IN ('DISTRICT_ENCAMPMENT', 'DISTRICT_INDUSTRIAL_ZONE');

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
  SELECT DISTINCT 'MC_ZHU_BLD_' || REPLACE(BuildingType, 'BUILDING_', ''), 'Amount', '50'
  FROM Buildings
  WHERE PrereqDistrict IN ('DISTRICT_ENCAMPMENT', 'DISTRICT_INDUSTRIAL_ZONE');

INSERT OR REPLACE INTO GovernorPromotionModifiers (GovernorPromotionType, ModifierId)
  SELECT DISTINCT 'GOVERNOR_PROMOTION_ZHU_JUNGONG', 'MC_ZHU_BLD_' || REPLACE(BuildingType, 'BUILDING_', '')
  FROM Buildings
  WHERE PrereqDistrict IN ('DISTRICT_ENCAMPMENT', 'DISTRICT_INDUSTRIAL_ZONE');
