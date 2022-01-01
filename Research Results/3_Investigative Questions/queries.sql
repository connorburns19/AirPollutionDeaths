drop view if exists IQ1_WorldDeathsAndEmissions cascade;
drop view if exists IQ1_WorldConsecutiveDeathsAndEmissions cascade;
drop view if exists IQ1_Percent_DeathsEmissions_ConsecutiveYears_Increase cascade;
drop view if exists IQ1_followup_AllDeaths cascade;
drop view if exists IQ1_followup_AllConsecutiveDeaths cascade;
drop view if exists IQ1_followup_AllDeathsPer100KAndPopulation cascade;
drop view if exists IQ1_followup_AllDeathsActualAmount cascade;
drop view if exists IQ1_followup_AllDeaths1990to2017 cascade;
drop view if exists IQ2_AverageDeathsBySDI cascade;
drop view if exists IQ2_followup_SDI_Deaths_Percent_Change cascade;
drop view if exists IQ3_PopulationAndEmissions cascade;
drop view if exists IQ3_ConsecutivePopulatioAndEmissions cascade;
drop view if exists IQ3_Percent_PopulationEmissions_ConsecutiveYears_Increase cascade;
drop view if exists IQ3_followup_AvgTonnesPerCapita cascade;

-- investigative question 1:
CREATE VIEW IQ1_WorldDeathsAndEmissions AS
SELECT PollutionDeathsByLocation.location, PollutionDeathsByLocation.year, CAST (PollutionDeathsByLocation.totalDeathsPer100K as FLOAT), 
Emissions.tonnes FROM PollutionDeathsByLocation JOIN Emissions ON 
PollutionDeathsByLocation.location = Emissions.location AND 
PollutionDeathsByLocation.year = Emissions.year AND PollutionDeathsByLocation.location = 'World';

CREATE VIEW IQ1_WorldConsecutiveDeathsAndEmissions As 
SELECT p1.location, p1.year as year1, p2.year as year2, 
100 * ((CAST (p2.totalDeathsPer100K as FLOAT) - CAST (p1.totalDeathsPer100K as FLOAT)) / CAST (p1.totalDeathsPer100K AS FLOAT)) 
as DeathsPercentChange, 
100 * ((p2.tonnes - p1.tonnes)/ p1.tonnes) 
as EmissionsPercentChange 
FROM IQ1_WorldDeathsAndEmissions p1, IQ1_WorldDeathsAndEmissions p2 WHERE p1.location = p2.location AND p1.year + 1 = p2.year;

CREATE VIEW IQ1_Percent_DeathsEmissions_ConsecutiveYears_Increase as
SELECT 100 * (CAST ((SELECT count(*) FROM IQ1_WorldConsecutiveDeathsAndEmissions WHERE DeathsPercentChange > 0 AND emissionspercentchange > 0) AS FLOAT)
 / CAST ((SELECT count(*) FROM IQ1_WorldConsecutiveDeathsAndEmissions WHERE emissionspercentchange > 0 ) AS FLOAT)) as percentage;


-- FOLLOW UP ---
---Surprised to find that every year the total pollution deaths of the world decreases. They never increase or stay the same.
-- We are curious if this is due to the highly developed countries having better health care, so we are going to view
-- deathspercent change of all locations and entities, including SDIRank. For this follow up, we do not care about emissions, we just
-- want to see the change in deaths per year for everything.

CREATE VIEW IQ1_followup_AllDeaths AS
SELECT * 
FROM (SELECT location as entity, year, CAST(totalDeathsPer100k as FLOAT) FROM PollutionDeathsByLocation) sub UNION
 (SELECT sdiRank as entity, year, CAST(totalDeathsPer100k as FLOAT) FROM PollutionDeathsBySDI);


CREATE VIEW IQ1_followup_AllConsecutiveDeaths As 
SELECT p1.entity, p1.year as year1, p2.year as year2, 
100 * ((CAST (p2.totalDeathsPer100K as FLOAT) - CAST (p1.totalDeathsPer100K as FLOAT)) / CAST (p1.totalDeathsPer100K AS FLOAT)) 
as DeathsPercentChange
FROM IQ1_followup_AllDeaths p1, IQ1_followup_AllDeaths p2 WHERE p1.entity = p2.entity AND p1.year + 1 = p2.year;


--Very surprised that the deaths almost always decrease for any entity.

-- FOLLOW UP ---
--All this talk of death got us thinking.... How many people in the entire World have died from air pollution between 1990 and 2017??
CREATE VIEW IQ1_followup_AllDeathsPer100KAndPopulation as
SELECT population.location, population.year, population.popValue, totalDeathsPer100K, outdoorDeathsPer100K, indoorDeathsPer100K, ozoneDeathsPer100K 
FROM PollutionDeathsByLocation JOIN Population ON PollutionDeathsByLocation.location = Population.location 
AND PollutionDeathsByLocation.year = Population.year AND population.location = 'World';

CREATE VIEW IQ1_followup_AllDeathsActualAmount as 
SELECT location, year, (CAST(popValue as FLOAT) / 100) * totalDeathsPer100K as totalDeaths,
((CAST(popValue as FLOAT) / 100) * totalDeathsPer100K / CAST(popValue as FLOAT) / 100) * 100  as totalDeathsPercentageOfPopulation, 
(CAST(popValue as FLOAT) / 100) * outdoorDeathsPer100K as totalOutdoorDeaths,
(CAST(popValue as FLOAT) / 100) * indoorDeathsPer100K as totalIndoorDeaths,
(CAST(popValue as FLOAT) / 100) * ozoneDeathsPer100K as totalOzoneDeaths
FROM IQ1_followup_AllDeathsPer100KAndPopulation;

 -- Now want to find actual number value:
CREATE VIEW IQ1_followup_AllDeaths1990to2017 as
SELECT sum(totalDeaths) as allDeaths1990to2017,
sum(totalOutdoorDeaths) as outdoorDeaths1990to2017,
sum(totalIndoorDeaths) as indoorDeaths1990to2017,
sum(totalOzoneDeaths) as ozoneDeaths1990to2017
FROM IQ1_followup_AllDeathsActualAmount;

-- Around 154 million people have died from Air Pollution between 1990 and 2017. Overall all, most deaths were from indoorPollution.



-- investigative question 2:
CREATE VIEW IQ2_AverageDeathsBySDI AS
SELECT sdiRank, AVG(totalDeathsPer100K) as avgTotalDeathsPer100K, AVG(outdoorDeathsPer100K) as 
avgOutdoorDeathsPer100K, AVG(indoorDeathsPer100K) as avgIndoorDeathsPer100K, AVG(ozoneDeathsPer100K) as
avgOzoneDeathsPer100K FROM PollutionDeathsBySDI GROUP BY sdiRank ORDER by avgTotalDeathsPer100K desc;

-- following up: comparing subsequent SDIs average deaths:
-- 
CREATE VIEW IQ2_followup_SDI_Deaths_Percent_Change as
(SELECT ((SELECT avgTotalDeathsPer100K FROM IQ2_AverageDeathsBySDI WHERE sdiRank ='Low-middle SDI') - 
(SELECT avgTotalDeathsPer100K FROM IQ2_AverageDeathsBySDI WHERE sdiRank = 'Low SDI'))
/
(SELECT avgTotalDeathsPer100K FROM IQ2_AverageDeathsBySDI WHERE sdiRank = 'Low SDI') * 100 AS Low_To_LowMiddle_SDI_Percent_Change,

((SELECT avgTotalDeathsPer100K FROM IQ2_AverageDeathsBySDI WHERE sdiRank ='Middle SDI') - 
(SELECT avgTotalDeathsPer100K FROM IQ2_AverageDeathsBySDI WHERE sdiRank = 'Low-middle SDI'))
/
(SELECT avgTotalDeathsPer100K FROM IQ2_AverageDeathsBySDI WHERE sdiRank = 'Low-middle SDI') * 100 AS LowMiddle_To_Middle_SDI_Percent_Change,

((SELECT avgTotalDeathsPer100K FROM IQ2_AverageDeathsBySDI WHERE sdiRank ='High-middle SDI') - 
(SELECT avgTotalDeathsPer100K FROM IQ2_AverageDeathsBySDI WHERE sdiRank = 'Middle SDI'))
/
(SELECT avgTotalDeathsPer100K FROM IQ2_AverageDeathsBySDI WHERE sdiRank = 'Middle SDI') * 100 AS Middle_To_MiddleHigh_SDI_Percent_Change,

((SELECT avgTotalDeathsPer100K FROM IQ2_AverageDeathsBySDI WHERE sdiRank ='High SDI') - 
(SELECT avgTotalDeathsPer100K FROM IQ2_AverageDeathsBySDI WHERE sdiRank = 'High-middle SDI'))
/
(SELECT avgTotalDeathsPer100K FROM IQ2_AverageDeathsBySDI WHERE sdiRank = 'High-middle SDI') * 100 AS MiddleHigh_To_High_SDI_Percent_Change);

-- investigative question 3:
CREATE VIEW IQ3_PopulationAndEmissions AS
SELECT Population.location, Population.year, Population.popvalue, Emissions.tonnes FROM Population 
JOIN Emissions ON Population.location = Emissions.location AND Population.year = Emissions.year AND population.location != 'World';

CREATE VIEW IQ3_ConsecutivePopulatioAndEmissions As 
SELECT p1.location, p1.year as year1, p2.year as year2, 
100 * ((CAST (p2.popvalue as FLOAT) - CAST (p1.popvalue as FLOAT)) / CAST (p1.popvalue AS FLOAT)) as PopulationPercentChange, 
100 * ((p2.tonnes - p1.tonnes)/ p1.tonnes) as EmissionsPercentChange 
FROM IQ3_PopulationAndEmissions p1, IQ3_PopulationAndEmissions p2 WHERE p1.location = p2.location AND p1.year + 1 = p2.year;

CREATE VIEW IQ3_Percent_PopulationEmissions_ConsecutiveYears_Increase as
SELECT 100 * (CAST ((SELECT count(*) FROM IQ3_ConsecutivePopulatioAndEmissions WHERE populationpercentchange > 0 AND emissionspercentchange > 0) AS FLOAT)
 / CAST ((SELECT count(*) FROM IQ3_ConsecutivePopulatioAndEmissions WHERE populationpercentchange > 0 ) AS FLOAT)) as percentage;

 ---Find pollution tonnes per capita. 
CREATE VIEW IQ3_followup_AvgTonnesPerCapita As 
SELECT location, avg(tonnes) / (avg(popValue) * 1000) as AvgTonnesPerCapita
FROM IQ3_PopulationAndEmissions GROUP BY location;