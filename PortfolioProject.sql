SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Looking at the Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract COVID in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like 'germany'
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows the percentage of population who got COVID
SELECT Location, date, total_cases, population, (total_cases/population)*100 as CasesPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like 'germany'
ORDER BY 1,2


-- Looking at percentage of popluation that got infected by COVID
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY Location, population
ORDER BY PercentPopulationInfected DESC



-- Looking at percentage of popluation that died because of COVID
SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Filters by continent
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is NULL					-- <-- here is the change
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Global numbers for each date (by delecting "date" from SELECT and GROUP BY one gets the total numbers indepent from date
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL	
GROUP BY date
ORDER BY 1,2

-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as accum_vaccinations_per_country
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac. location
	and dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 2,3


-- Use CTE

WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, accum_vaccinations_per_country)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
  dea.date) as accum_vaccinations_per_country
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac. location
	and dea.date = vac.date
WHERE dea.continent is not NULL
-- ORDER BY 2,3
)
Select *, (accum_vaccinations_per_country/Population)*100 as PercentVaccinated		-- now one can access a column which is defined one step before.
From PopvsVac																		-- this was not possible since then


-- TEMP TABLE (creates a temporary table, which then columns can be selected from)

DROP TABLE IF exists #PercentPopulationVaccinated		-- delets the temporary table, if it already exists
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
accum_vaccinations_per_country numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
  dea.date) as accum_vaccinations_per_country
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac. location
	and dea.date = vac.date
WHERE dea.continent is not NULL
-- ORDER BY 2,3

Select *, (accum_vaccinations_per_country/Population)*100 as PercentVaccinated		-- now one can access a column which is defined one step before.
From #PercentPopulationVaccinated													-- this was not possible since then


-- Creating View to store data for later visualizations (this stores the temporary table permanentely)

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
  dea.date) as accum_vaccinations_per_country
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac. location
	and dea.date = vac.date
WHERE dea.continent is not NULL
-- ORDER BY 2,3

Select *
From PercentPopulationVaccinated