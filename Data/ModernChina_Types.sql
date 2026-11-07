-- =============================================================
-- 现代中国 (Modern China) : Type 注册
-- 一切实体必须先在此注册
-- =============================================================

INSERT INTO Types (Type, Kind) VALUES
  ('CIVILIZATION_MODERN_CHINA',                    'KIND_CIVILIZATION'),
  ('LEADER_MAO',                                   'KIND_LEADER'),
  ('LEADER_QIAN_XUESEN',                           'KIND_LEADER'),
  ('LEADER_HU',                                    'KIND_LEADER'),
  ('TRAIT_CIVILIZATION_CHINESE_CHARACTERISTICS',   'KIND_TRAIT'),
  ('TRAIT_CIVILIZATION_CONGRESS',                  'KIND_TRAIT'),
  ('TRAIT_CIVILIZATION_RED_ARMY',                  'KIND_TRAIT'),
  ('TRAIT_LEADER_MAO_REBUILD_CHINA',               'KIND_TRAIT'),
  ('TRAIT_LEADER_MAO_GOVERNOR_ZHU',                'KIND_TRAIT'),
  ('TRAIT_LEADER_QIAN_STRATEGIC_SCIENTIST',        'KIND_TRAIT'),
  ('TRAIT_LEADER_HU_SCIENTIFIC_OUTLOOK',           'KIND_TRAIT'),
  ('TRAIT_AGENDA_MAO',                             'KIND_TRAIT'),
  ('DISTRICT_CONGRESS',                            'KIND_DISTRICT'),
  ('UNIT_RED_ARMY',                                'KIND_UNIT'),
  ('ABILITY_RED_ARMY',                             'KIND_ABILITY'),
  ('ABILITY_MC_ZHU_MILITARY_MOVEMENT',             'KIND_ABILITY'),
  ('ABILITY_MC_ZHU_BUILDER_MOVEMENT',              'KIND_ABILITY'),
  ('BUILDING_QIAN_MECHANICS_CLASS',                'KIND_BUILDING'),
  ('DISTRICT_HU_NEIGHBORHOOD',                     'KIND_DISTRICT'),
  ('BUILDING_HU_NEIGHBORHOOD_ARENA',               'KIND_BUILDING'),
  ('BUILDING_HU_NEIGHBORHOOD_ZOO',                 'KIND_BUILDING'),
  ('BUILDING_HU_NEIGHBORHOOD_STADIUM',             'KIND_BUILDING'),
  ('BUILDING_HU_NEIGHBORHOOD_AMPHITHEATER',        'KIND_BUILDING'),
  ('BUILDING_HU_NEIGHBORHOOD_MUSEUM_ART',          'KIND_BUILDING'),
  ('BUILDING_HU_NEIGHBORHOOD_MUSEUM_ARTIFACT',     'KIND_BUILDING'),
  ('BUILDING_HU_NEIGHBORHOOD_BROADCAST_CENTER',    'KIND_BUILDING'),
  ('PROJECT_MC_WORK_ECONOMY',                      'KIND_PROJECT'),
  ('PROJECT_MC_WORK_CULTURE',                      'KIND_PROJECT'),
  ('PROJECT_MC_WORK_TECH',                         'KIND_PROJECT');

-- 红军专用能力标签（把单位与能力用同一个 CLASS_tag 绑定）
INSERT INTO Tags (Tag, Vocabulary) VALUES
  ('CLASS_MC_RED_ARMY', 'ABILITY_CLASS');
