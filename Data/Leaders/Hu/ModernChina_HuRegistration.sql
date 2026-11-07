-- =============================================================
-- Hu Jintao: leader registration
-- =============================================================

INSERT INTO CivilizationLeaders (CivilizationType, LeaderType, CapitalName) VALUES
  ('CIVILIZATION_MODERN_CHINA', 'LEADER_HU', 'LOC_CITY_NAME_MC_1');

INSERT INTO Leaders (LeaderType, Name, Sex, InheritFrom, SceneLayers) VALUES
  ('LEADER_HU', 'LOC_LEADER_HU_NAME', 'Male', 'LEADER_DEFAULT', 4);

-- Reuse Qin Shi Huang's quote audio until dedicated voice assets exist.
INSERT INTO LeaderQuotes (LeaderType, Quote, QuoteAudio)
  SELECT 'LEADER_HU', 'LOC_LEADER_HU_QUOTE', QuoteAudio
  FROM LeaderQuotes WHERE LeaderType = 'LEADER_QIN';

INSERT INTO Traits (TraitType, Name, Description) VALUES
  ('TRAIT_LEADER_HU_SCIENTIFIC_OUTLOOK',
   'LOC_TRAIT_LEADER_HU_SCIENTIFIC_OUTLOOK_NAME',
   'LOC_TRAIT_LEADER_HU_SCIENTIFIC_OUTLOOK_DESCRIPTION');

INSERT INTO LeaderTraits (LeaderType, TraitType) VALUES
  ('LEADER_HU', 'TRAIT_LEADER_HU_SCIENTIFIC_OUTLOOK'),
  ('LEADER_HU', 'TRAIT_LEADER_SCIENCE_MAJOR_CIV'),
  ('LEADER_HU', 'TRAIT_LEADER_LOW_RELIGIOUS_PREFERENCE');

INSERT INTO HistoricalAgendas (LeaderType, AgendaType) VALUES
  ('LEADER_HU', 'AGENDA_TECHNOPHILE');

-- The portrait is Hu-specific; the background remains a temporary placeholder
-- until dedicated background artwork is supplied.
INSERT INTO LoadingInfo
  (LeaderType, ForegroundImage, BackgroundImage, LeaderText, PlayDawnOfManAudio)
VALUES
  ('LEADER_HU',
   'LEADER_HU_NEUTRAL',
   'LEADER_QIAN_XUESEN_BACKGROUND',
   'LOC_LOADING_INFO_LEADER_HU',
   0);

INSERT INTO DiplomacyInfo (Type, BackgroundImage) VALUES
  ('LEADER_HU', 'LEADER_QIAN_XUESEN_BACKGROUND');
