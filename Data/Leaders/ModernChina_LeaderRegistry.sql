-- =============================================================
-- 现代中国 : 领袖「毛」
-- =============================================================

INSERT INTO CivilizationLeaders (CivilizationType, LeaderType, CapitalName) VALUES
  ('CIVILIZATION_MODERN_CHINA', 'LEADER_MAO', 'LOC_CITY_NAME_MC_1'),
  ('CIVILIZATION_MODERN_CHINA', 'LEADER_QIAN_XUESEN', 'LOC_CITY_NAME_MC_1');

INSERT INTO Leaders (LeaderType, Name, Sex, InheritFrom, SceneLayers) VALUES
  ('LEADER_MAO', 'LOC_LEADER_MAO_NAME', 'Male', 'LEADER_DEFAULT', 4),
  ('LEADER_QIAN_XUESEN', 'LOC_LEADER_QIAN_XUESEN_NAME', 'Male', 'LEADER_DEFAULT', 4);

-- 语音复用秦始皇语录音频（避免指到不存在的音频文件）
INSERT INTO LeaderQuotes (LeaderType, Quote, QuoteAudio)
  SELECT 'LEADER_MAO', 'LOC_LEADER_MAO_QUOTE', QuoteAudio
  FROM LeaderQuotes WHERE LeaderType = 'LEADER_QIN';

INSERT INTO LeaderQuotes (LeaderType, Quote, QuoteAudio)
  SELECT 'LEADER_QIAN_XUESEN', 'LOC_LEADER_QIAN_XUESEN_QUOTE', QuoteAudio
  FROM LeaderQuotes WHERE LeaderType = 'LEADER_QIN';

INSERT INTO Traits (TraitType, Name, Description) VALUES
  ('TRAIT_LEADER_MAO_REBUILD_CHINA',
   'LOC_TRAIT_LEADER_MAO_REBUILD_CHINA_NAME',
   'LOC_TRAIT_LEADER_MAO_REBUILD_CHINA_DESCRIPTION'),
  ('TRAIT_LEADER_MAO_GOVERNOR_ZHU',
   'LOC_GOVERNOR_ZHU_NAME',
   'LOC_GOVERNOR_ZHU_DESCRIPTION'),
  ('TRAIT_LEADER_QIAN_STRATEGIC_SCIENTIST',
   'LOC_TRAIT_LEADER_QIAN_STRATEGIC_SCIENTIST_NAME',
   'LOC_TRAIT_LEADER_QIAN_STRATEGIC_SCIENTIST_DESCRIPTION'),
  ('TRAIT_AGENDA_MAO', NULL, NULL);

INSERT INTO LeaderTraits (LeaderType, TraitType) VALUES
  ('LEADER_MAO', 'TRAIT_LEADER_MAO_REBUILD_CHINA'),
  ('LEADER_MAO', 'TRAIT_LEADER_MAO_GOVERNOR_ZHU'),
  ('LEADER_MAO', 'TRAIT_LEADER_LOW_RELIGIOUS_PREFERENCE'),
  ('LEADER_QIAN_XUESEN', 'TRAIT_LEADER_QIAN_STRATEGIC_SCIENTIST'),
  ('LEADER_QIAN_XUESEN', 'TRAIT_LEADER_SCIENCE_MAJOR_CIV'),
  ('LEADER_QIAN_XUESEN', 'TRAIT_LEADER_LOW_RELIGIOUS_PREFERENCE');

-- -------------------------------------------------------------
-- 议程
-- -------------------------------------------------------------
INSERT INTO Agendas (AgendaType, Name, Description) VALUES
  ('AGENDA_MAO', 'LOC_AGENDA_MAO_NAME', 'LOC_AGENDA_MAO_DESCRIPTION');

INSERT INTO HistoricalAgendas (LeaderType, AgendaType) VALUES
  ('LEADER_MAO', 'AGENDA_MAO'),
  ('LEADER_QIAN_XUESEN', 'AGENDA_TECHNOPHILE');

INSERT INTO ExclusiveAgendas (AgendaOne, AgendaTwo) VALUES
  ('AGENDA_MAO', 'AGENDA_EXPLOITATIVE'),
  ('AGENDA_MAO', 'AGENDA_ENVIRONMENTALIST');

INSERT INTO AgendaTraits (AgendaType, TraitType) VALUES
  ('AGENDA_MAO', 'TRAIT_AGENDA_MAO');

-- -------------------------------------------------------------
-- 载入界面 / 外交界面
-- -------------------------------------------------------------
INSERT INTO LoadingInfo (LeaderType, ForegroundImage, BackgroundImage, LeaderText, PlayDawnOfManAudio) VALUES
  ('LEADER_MAO', 'LEADER_MAO_NEUTRAL', 'LEADER_MAO_BACKGROUND', 'LOC_LOADING_INFO_LEADER_MAO', 0),
  ('LEADER_QIAN_XUESEN', 'LEADER_QIAN_XUESEN_NEUTRAL', 'LEADER_QIAN_XUESEN_BACKGROUND', 'LOC_LOADING_INFO_LEADER_QIAN_XUESEN', 0);

INSERT INTO DiplomacyInfo (Type, BackgroundImage) VALUES
  ('LEADER_MAO', 'LEADER_MAO_BACKGROUND'),
  ('LEADER_QIAN_XUESEN', 'LEADER_QIAN_XUESEN_BACKGROUND');
