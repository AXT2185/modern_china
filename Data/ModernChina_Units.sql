-- =============================================================
-- 现代中国 : 特色单位「红军」(替代线列步兵)
-- =============================================================

INSERT INTO UnitReplaces (CivUniqueUnitType, ReplacesUnitType) VALUES
  ('UNIT_RED_ARMY', 'UNIT_LINE_INFANTRY');

INSERT INTO UnitAiInfos (UnitType, AiType)
  SELECT 'UNIT_RED_ARMY', AiType FROM UnitAiInfos WHERE UnitType = 'UNIT_LINE_INFANTRY';

INSERT INTO TypeTags (Type, Tag) VALUES
  ('UNIT_RED_ARMY',      'CLASS_MELEE'),
  ('UNIT_RED_ARMY',      'CLASS_MC_RED_ARMY'),
  ('ABILITY_RED_ARMY',   'CLASS_MC_RED_ARMY');

INSERT INTO Units (
  UnitType, Name, Description, Cost, Maintenance, BaseMoves, BaseSightRange, ZoneOfControl,
  Domain, Combat, StrategicResource, FormationClass, PromotionClass, AdvisorType,
  BuildCharges,
  PurchaseYield, MandatoryObsoleteTech, PrereqTech, PrereqCivic, TraitType, PseudoYieldType
)
SELECT
  'UNIT_RED_ARMY',
  'LOC_UNIT_RED_ARMY_NAME',
  'LOC_UNIT_RED_ARMY_DESCRIPTION',
  Cost, Maintenance, 4, BaseSightRange, ZoneOfControl,
  Domain, Combat, StrategicResource, FormationClass, PromotionClass, AdvisorType,
  1,
  PurchaseYield, MandatoryObsoleteTech, NULL, 'CIVIC_THE_ENLIGHTENMENT',
  'TRAIT_CIVILIZATION_RED_ARMY', PseudoYieldType
FROM Units WHERE UnitType = 'UNIT_LINE_INFANTRY';

INSERT INTO UnitUpgrades (Unit, UpgradeUnit) VALUES
  ('UNIT_RED_ARMY', 'UNIT_INFANTRY');

-- -------------------------------------------------------------
-- 单位能力：跨越山脉 / 相邻友军支援加成
-- -------------------------------------------------------------
INSERT INTO UnitAbilities (UnitAbilityType, Name, Description) VALUES
  ('ABILITY_RED_ARMY', 'LOC_ABILITY_RED_ARMY_NAME', 'LOC_ABILITY_RED_ARMY_DESCRIPTION');

INSERT INTO UnitAbilityModifiers (UnitAbilityType, ModifierId) VALUES
  ('ABILITY_RED_ARMY', 'MC_RED_ARMY_SUPPORT_BONUS');

-- -------------------------------------------------------------
-- 红军可用那 1 次建造次数在相邻山脉修建「穿山隧道」
--   （官方 IMPROVEMENT_MOUNTAIN_TUNNEL：AllowImpassableMovement=1 + BuildOnAdjacentPlot=1）
-- -------------------------------------------------------------
INSERT INTO Improvement_ValidBuildUnits (ImprovementType, UnitType) VALUES
  ('IMPROVEMENT_MOUNTAIN_TUNNEL', 'UNIT_RED_ARMY');
