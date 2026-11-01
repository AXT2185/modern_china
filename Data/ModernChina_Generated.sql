-- =============================================================
-- 现代中国 : 由数据库动态生成的挂载（随规则集自适应）
--   1) 红军：你每拥有一种战略资源，+2 战斗力
-- =============================================================

-- 每种战略资源一个 Owner 条件组
INSERT INTO RequirementSets (RequirementSetId, RequirementSetType)
  SELECT DISTINCT 'MC_REQSET_OWNS_' || ResourceType, 'REQUIREMENTSET_TEST_ALL'
  FROM Resources WHERE ResourceClassType = 'RESOURCECLASS_STRATEGIC';

INSERT INTO Requirements (RequirementId, RequirementType)
  SELECT DISTINCT 'MC_REQ_OWNS_' || ResourceType, 'REQUIREMENT_PLAYER_HAS_RESOURCE_OWNED'
  FROM Resources WHERE ResourceClassType = 'RESOURCECLASS_STRATEGIC';

INSERT INTO RequirementArguments (RequirementId, Name, Value)
  SELECT DISTINCT 'MC_REQ_OWNS_' || ResourceType, 'ResourceType', ResourceType
  FROM Resources WHERE ResourceClassType = 'RESOURCECLASS_STRATEGIC';

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId)
  SELECT DISTINCT 'MC_REQSET_OWNS_' || ResourceType, 'MC_REQ_OWNS_' || ResourceType
  FROM Resources WHERE ResourceClassType = 'RESOURCECLASS_STRATEGIC';

-- 每条资源的战斗力加成（只作用于红军）
INSERT INTO Modifiers (ModifierId, ModifierType, OwnerRequirementSetId, SubjectRequirementSetId)
  SELECT DISTINCT 'MC_RED_ARMY_STRATEGIC_' || ResourceType,
                  'MODIFIER_PLAYER_UNITS_ADJUST_COMBAT_STRENGTH',
                  'MC_REQSET_OWNS_' || ResourceType,
                  'MC_REQSET_UNIT_IS_RED_ARMY'
  FROM Resources WHERE ResourceClassType = 'RESOURCECLASS_STRATEGIC';

INSERT INTO ModifierArguments (ModifierId, Name, Value)
  SELECT DISTINCT 'MC_RED_ARMY_STRATEGIC_' || ResourceType, 'Amount', '2'
  FROM Resources WHERE ResourceClassType = 'RESOURCECLASS_STRATEGIC';

INSERT INTO TraitModifiers (TraitType, ModifierId)
  SELECT DISTINCT 'TRAIT_CIVILIZATION_RED_ARMY', 'MC_RED_ARMY_STRATEGIC_' || ResourceType
  FROM Resources WHERE ResourceClassType = 'RESOURCECLASS_STRATEGIC';
