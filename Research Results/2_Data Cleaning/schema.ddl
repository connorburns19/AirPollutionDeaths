drop table if exists Population cascade;
drop table if exists Emissions cascade;
drop table if exists PollutionDeathsByLocation cascade;
drop table if exists PollutionDeathsBySDI cascade;
drop table if exists temp_pop cascade;
drop table if exists temp_pollution_deaths cascade;
drop table if exists temp_emissions cascade;
drop view if exists ValidEmissions cascade;
drop view if exists ValidPollutionDeaths cascade;
drop schema if exists PopulationAndPollution cascade; 
create schema PopulationAndPollution;
set search_path to PopulationAndPollution;

---A tuple in this relation represents the population of any geographical location (”World” is also a location), in thousands.
---location represents the geographical location, year represents the year and popValue represents the population in
---thousands.
CREATE TABLE Population (
	location TEXT NOT NULL,
    year INT NOT NULL,
    popValue INT NOT NULL,
	PRIMARY KEY (location, year),
    check (popValue >= 0),
    check (year >= 0)
);

---A tuple in this relation represents a source of CO2 emissions during a particular year. location is
-- the body which the emissions stemmed from. This can be a country, geographical region, or another
-- source, such as international transport. year is the year which the emissions happened. tonnes is the
--amount of emissions, in tonnes.
CREATE TABLE Emissions (
	location TEXT NOT NULL,
	year INT NOT NULL,
	tonnes FLOAT NOT NULL,
	PRIMARY KEY (location, year),
    FOREIGN KEY(location, year) REFERENCES Population(location, year),
    check (year >= 0),
    check (tonnes >= 0)
);

---A tuple in this relation represents the deaths due to all types of pollution in a particular year. location
---represents where the deaths occurred. This can be a country or a geographical region. year is the year
---which the deaths occurred. totalDeathsPer100K is the number of total deaths due to all types of pollution, per
---100 thousand people. The other attributes describe the type of pollution specifically, rather then them
---all.
CREATE TABLE PollutionDeathsByLocation (
	location TEXT NOT NULL,
    year INT NOT NULL,
    totalDeathsPer100K INT NOT NULL,
    outdoorDeathsPer100K INT NOT NULL,
    indoorDeathsPer100K INT NOT NULL,
    ozoneDeathsPer100K INT NOT NULL,
	PRIMARY KEY (location, year),
    FOREIGN KEY(location, year) REFERENCES Population(location, year),
    check (year >= 0),
    check (totalDeathsPer100K >= 0),
    check (outdoorDeathsPer100K >= 0),
    check (indoorDeathsPer100K >= 0),
    check (ozoneDeathsPer100K >= 0)
);

---A tuple in this relation represents the deaths due to all types of pollution, by the Spatial Data Infrastructure of where the death occurred. sdiRank is the SDI rank value from the set{”Low”, ”Low-middle”,
---”High-middle”, ”High”} year is the year which the deaths occurred. totalDeathsPer100K is the number of total
---deaths due to all types of pollution, per 100 thousand people. The other attributes describe the type
---of pollution specifically, rather then them all.
CREATE TABLE PollutionDeathsBySDI (
	sdiRank TEXT NOT NULL,
    year INT NOT NULL,
    totalDeathsPer100K INT NOT NULL,
    outdoorDeathsPer100K INT NOT NULL,
    indoorDeathsPer100K INT NOT NULL,
    ozoneDeathsPer100K INT NOT NULL,
	PRIMARY KEY (sdiRank, year),
    CHECK (sdiRank = 'Low SDI' or sdiRank ='Low-middle SDI' or sdiRank = 'Middle SDI' or sdiRank = 'High-middle SDI' or sdiRank = 'High SDI'),
    check (year >= 0),
    check (totalDeathsPer100K >= 0),
    check (outdoorDeathsPer100K >= 0),
    check (indoorDeathsPer100K >= 0),
    check (ozoneDeathsPer100K >= 0)
);




---BELOW THIS IS HELPER TABLES AND VIEWS IN ORDER TO CLEAN THE DATA AND IMPORT THE DATA INTO THE SCHEMA






---A temporary table used to copy data from the population csv and used to run queries to cleanup the data.
CREATE temporary table temp_pop (
    id int not null,
    location text not null,
    varID int not null,
    variant text not null,
    year int not null,
    midPeriod float not null,
    males float,
    females float,
    totalPopulation float not null,
    density float not null
);

\copy temp_pop from population-sample-data.csv with csv  


---A temporary table used to copy data from the emissions csv and used to run queries to cleanup the data.
CREATE temporary table temp_emissions (
    entity TEXT NOT NULL,
    code TEXT,
    year INT NOT NULL,
    annualEmissions FLOAT NOT NULL
);

\copy temp_emissions from co2-emissions-sample-data.csv with csv

---A temporary table used to copy data from the pollution csv and used to run queries to cleanup the data.
CREATE temporary table temp_pollution_deaths (
    entity text not null, 
    code text, 
    year int not null, 
    airPollutionDeathsPer100K float not null, 
    indoor float not null, 
    outdoor float not null, 
    ozone float not null
);

\copy temp_pollution_deaths from death-rates-from-air-pollution-sample-data.csv with csv

---We select for variant medium because we only want one population variant.
insert into Population select distinct location, year, totalPopulation from temp_pop where variant='Medium' group by location, year, temp_pop.totalpopulation;

/* Create Views to cleanup data and enforce foreign key constraints and insert into respective table: */

---View which contains emissions of keys that also exist in the population table.
CREATE VIEW ValidEmissions as SELECT temp_emissions.entity, 
temp_emissions.year, temp_emissions.annualEmissions FROM 
temp_emissions JOIN population on temp_emissions.entity = population.location 
AND temp_emissions.year = population.year;

insert into emissions select entity, year, annualEmissions from ValidEmissions;

insert into PollutionDeathsBySDI select entity, year, airPollutionDeathsPer100K, indoor, outdoor, ozone from temp_pollution_deaths WHERE entity='Low SDI' OR entity='Low-middle SDI' OR entity='Middle SDI' OR entity='Middle SDI' OR entity='High-middle SDI' OR entity='High SDI'; 

---View which contains pollution deaths of keys that also exist in the population table.
CREATE VIEW ValidPollutionDeaths as SELECT temp_pollution_deaths.entity, 
temp_pollution_deaths.year, temp_pollution_deaths.airpollutiondeathsper100k, outdoor, indoor, ozone FROM 
temp_pollution_deaths JOIN population on temp_pollution_deaths.entity = population.location 
AND temp_pollution_deaths.year = population.year;


insert into PollutionDeathsByLocation select entity, year, airPollutionDeathsPer100K, indoor, outdoor, ozone from ValidPollutionDeaths;

/* Drop temporary tables and views that are no longer needed or wanted in the schema: */


drop table if exists temp_pop cascade;
drop table if exists temp_pollution_deaths cascade;
drop table if exists temp_emissions cascade;
drop view if exists ValidEmissions cascade;
drop view if exists ValidPollutionDeaths cascade;