/* 
Covid-19 Data exploration between Jan 1st, 2020 to June 14th, 2022. 
Skills used: Data type conversions, Aggregate functions, Windows functions, Joins, CTE, Temp Table, Creating views. 
*/

Select *
from PortfolioProjects..CovidDeaths
where continent is not null 
order by 3,4

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProjects..CovidDeaths
where continent is not null 
Order by 1,2

--Focusing on the US
--Infection Rate

Select Location, date, total_cases, (total_cases/population)*100
AS InfectionRate
From PortfolioProjects..CovidDeaths
where location like '%states'
and continent is not null 
Order by 1,2

--Death Rate

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathRate
From PortfolioProjects..CovidDeaths
where location like '%states'
and continent is not null 
Order by 1,2

--World: Infection rates by countries

Select Location, date, population, total_cases, (total_cases/population)*100 AS InfectionRate
From PortfolioProjects..CovidDeaths
Order by 1,2

--World: Countries with highest infection rate vs population
Select Location, population, max(total_cases) as HighestInfectionCount, max(total_cases/population)*100 AS InfectionRate
From PortfolioProjects..CovidDeaths
where continent is not null 
Group by location, population
Order by InfectionRate DESC

--World: Countries with the highest death count vs population

Select Location, max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProjects..CovidDeaths
where continent is not null 
Group by location
Order by TotalDeathCount DESC

--By Continent
--Continents with the highest death count
Select continent, max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProjects..CovidDeaths
where continent is not null 
Group by continent
Order by TotalDeathCount DESC

-- Looking Globally
-- DeathRate for new cases in the world 
Select date, sum(new_cases) AS TotalNewCases, Sum(cast(new_deaths as INT)) As TotalNewDeaths, 
Sum(cast(new_deaths as INT))/sum(new_cases)*100 AS NewDeathRate
From PortfolioProjects..CovidDeaths
--where location like '%states'
Where continent is not null 
Group by date
Order by 1 desc

-- Running vaccination count vs population
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(cast(cv.new_vaccinations as bigint)) OVER (Partition by cd.Location Order by cd.location, cd.date) as RunningPeopleVaccinated
From PortfolioProjects..CovidDeaths as cd
Join PortfolioProjects..CovidVac as cv
	on cd.location=cv.location
	and cd.date=cv.date
Where cd.continent is not null 
order by 1,2,3

--Using CTE to do calculations on partitioned query
WITH VacPop as (
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(cast(cv.new_vaccinations as bigint)) OVER (Partition by cd.Location Order by cd.location, cd.date) as RunningPeopleVaccinated
From PortfolioProjects..CovidDeaths as cd
Join PortfolioProjects..CovidVac as cv
	on cd.location=cv.location
	and cd.date=cv.date
Where cd.continent is not null )
Select *, (RunningPeopleVaccinated/population)*100 as RunningVaccinationRate
FROM VacPop


--Using Temp Table to do calculations on partitioned query
Drop Table if exists #VaccinationRate
Create table #VaccinationRate
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric, 
RunningPeopleVaccinated numeric
)
INSERT INTO #VaccinationRate
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(cast(cv.new_vaccinations as bigint)) OVER (Partition by cd.Location Order by cd.location, cd.date) as RunningPeopleVaccinated
From PortfolioProjects..CovidDeaths as cd
Join PortfolioProjects..CovidVac as cv
	on cd.location=cv.location
	and cd.date=cv.date
Where cd.continent is not null

Select *, (RunningPeopleVaccinated/population)*100 as RunningVaccinationRate
FROM #VaccinationRate

--View for eventual visualization
CREATE view VaccinationRate as
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(cast(cv.new_vaccinations as bigint)) OVER (Partition by cd.Location Order by cd.location, cd.date) as RunningPeopleVaccinated
From PortfolioProjects..CovidDeaths as cd
Join PortfolioProjects..CovidVac as cv
	on cd.location=cv.location
	and cd.date=cv.date
Where cd.continent is not null




