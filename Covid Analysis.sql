/* 
Exploratory Analysis of COVID-19 Data Spanning Between January 1st, 2020 to June 14th, 2022. 
Skills used: Logical operations, Data type conversions, Aggregate functions, Windows functions, Joins, CTE, Temp Table, Creating views. 
*/

--Exploring data of interest
SELECT 
	location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL --remove data for grouped countries e.g "World"
ORDER BY
	location, 
	date

--Infection Rate (likelihood of contracting COVID-19)
SELECT 
	location, 
	date, 
	total_cases, 
	population,
	(total_cases/population)*100 AS infection_rate
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY
	location, 
	date

--Death Rate (likelihood of dying of COVID-19 if contracted)
SELECT 
	location, 
	date, 
	total_deaths,
	total_cases, 
	(total_deaths/total_cases)*100 AS death_rate
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY
	location, 
	date

--Highest infection rate for each country
SELECT 
	location, 
	population, 
	MAX(total_cases) as highest_infection_count, 
	MAX(total_cases/population)*100 AS infection_rate
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY 
	location, 
	population
ORDER BY infection_rate DESC

--Total deaths by Countries 
SELECT 
	location, 
	MAX(cast(total_deaths AS int)) as total_death_count
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY total_death_count DESC

--BY CONTINENTS
--Total deaths by continents 
SELECT 
	location AS continent, -- selecting continent does not accurately combine cananda and USA in North America
	MAX(cast(total_deaths AS int)) as total_death_count
FROM PortfolioProjects..CovidDeaths
WHERE 
	continent IS NULL --retain data for grouped countries e.g "Africa"
	AND location NOT IN ('World', 'Upper middle income', 'High income','Lower middle income','European Union','Low income',
	'International') --remove non-continental classification"
GROUP BY location
ORDER BY total_death_count DESC

--Total deaths by continents (incorrect but drills down)
SELECT 
	continent, 
	MAX(cast(total_deaths AS int)) as total_death_count
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC

-- BY GLOBAL
-- DeathRate for new cases in the world 
SELECT 
	date, 
	SUM(new_cases) AS total_cases, 
	SUM(cast(new_deaths as INT)) AS total_deaths, 
	SUM(cast(new_deaths as INT))/SUM(new_cases)*100 AS death_rate
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY date DESC

-- Running vaccination count per location
SELECT 
	cd.continent, 
	cd.location, 
	cd.date, 
	cd.population, 
	cv.new_vaccinations, 
	SUM(cast(cv.new_vaccinations as bigint)) OVER (PARTITION BY cd.Location ORDER BY cd.location, cd.date) as running_vaccination_count
FROM PortfolioProjects..CovidDeaths as cd
INNER JOIN PortfolioProjects..CovidVac as cv
	ON cd.location=cv.location
	AND cd.date=cv.date
WHERE cd.continent is not null 
ORDER BY 
	cd.location, 
	cd.date

-- Putting Running vaccination count per location into View
DROP VIEW IF EXISTS vaccination_running_count;
CREATE VIEW vaccination_running_count AS
	SELECT 
		cd.continent, 
		cd.location, 
		cd.date, 
		cd.population, 
		cv.new_vaccinations, 
		SUM(cast(cv.new_vaccinations AS bigint)) OVER (PARTITION BY cd.Location ORDER BY cd.location, cd.date) as running_vaccination_count
	FROM PortfolioProjects..CovidDeaths as cd
	INNER JOIN PortfolioProjects..CovidVac as cv
		ON cd.location=cv.location
		AND cd.date=cv.date
	WHERE cd.continent is not null

--Running vaccination percent per location - Using CTE
WITH VacPop 
AS (
	SELECT 
		cd.continent, 
		cd.location, 
		cd.date, 
		cd.population, 
		cv.new_vaccinations, 
		SUM(cast(cv.new_vaccinations AS bigint)) OVER (PARTITION BY cd.Location ORDER BY cd.location, cd.date) as running_vaccination_count
	FROM PortfolioProjects..CovidDeaths as cd
	INNER JOIN PortfolioProjects..CovidVac as cv
		ON cd.location=cv.location
		AND cd.date=cv.date
	WHERE cd.continent is not null
	)
Select 
	*, 
	(running_vaccination_count/population)*100 as running_vaccination_rate
FROM VacPop



--Running vaccination percent per location - Using Temp table
DROP TABLE IF EXISTS #vaccination_rate
CREATE TABLE #vaccination_rate
	(
	continent nvarchar(255),
	location nvarchar(255),
	late datetime,
	population numeric,
	new_vaccinations numeric, 
	running_vaccination_count numeric
	)
INSERT INTO #vaccination_rate
	SELECT 
		cd.continent, 
		cd.location, 
		cd.date, 
		cd.population, 
		cv.new_vaccinations, 
		SUM(cast(cv.new_vaccinations AS bigint)) OVER (PARTITION BY cd.Location ORDER BY cd.location, cd.date) as running_vaccination_count
	FROM PortfolioProjects..CovidDeaths as cd
	INNER JOIN PortfolioProjects..CovidVac as cv
		ON cd.location=cv.location
		AND cd.date=cv.date
	WHERE cd.continent is not null

Select 
	*, 
	(running_vaccination_count/population)*100 as running_vaccination_rate
FROM #vaccination_rate
