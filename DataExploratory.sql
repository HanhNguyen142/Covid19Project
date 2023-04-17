-- View data from CovidDeath$
SELECT * FROM Portfolio_Covid19..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 3, 4

--View new cases, total cases, population and total deaths order by location and date
SELECT location, date, new_cases, total_cases, population, total_deaths FROM Portfolio_Covid19..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY location, date



--Total case vs total death in Vietnam
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths as float) / total_cases)*100 as DeathPercentage 
FROM Portfolio_Covid19..CovidDeaths$
WHERE location LIKE 'Viet%'
AND continent IS NOT NULL
ORDER BY location, date

-- Total cases vs population in Vietnam order by date
SELECT location, date, total_cases, population, (total_cases/population)*100 as InfectionPercentage
FROM Portfolio_Covid19..CovidDeaths$
WHERE location LIKE 'Viet%'
AND continent IS NOT NULL
ORDER BY location, date

-- Highest Infection rate
SELECT location, population, MAX(CAST(total_cases AS int)) as HighestInfectionCount, MAX((CAST(total_cases AS int)/population))*100 as InfectionPercentage
FROM Portfolio_Covid19..CovidDeaths$
--WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY InfectionPercentage desc

-- Highest deathrate rate
SELECT location, population, MAX(CAST(total_deaths AS int)) as HighestDeathsCount, MAX((CAST(total_deaths AS int)/CAST(population AS int)))*100 as DeathsPercentage
FROM Portfolio_Covid19..CovidDeaths$
--WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY DeathsPercentage desc

--Showing continents which the highest death count per poplulation
SELECT continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM Portfolio_Covid19..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount

-- Global total cases, total deaths and death percentage
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage
FROM Portfolio_Covid19..CovidDeaths$
WHERE continent IS NOT NULL

-- View data in CovidVaccination$ table
SELECT * FROM Portfolio_Covid19..CovidVaccinations$

-- Cummulative vaccinated number group by location
SELECT de.continent, de.location, va.date, de.population, va.new_vaccinations,
SUM(CONVERT(bigint, va.new_vaccinations)) OVER (PARTITION BY de.location ORDER BY de.date) as RollingPeopleVaccinated
FROM Portfolio_Covid19..CovidVaccinations$ AS va
JOIN Portfolio_Covid19..CovidDeaths$  AS de
ON va.location = de.location
AND va.date = de.date
WHERE de.continent IS NOT NULL
ORDER BY de.location, de.date

-- Vaccinated percentage 
WITH mycte AS (
SELECT de.continent, de.location, va.date, de.population, va.new_vaccinations,
SUM(CONVERT(bigint, va.new_vaccinations)) OVER (PARTITION BY de.location ORDER BY de.date) as RollingPeopleVaccinated
FROM Portfolio_Covid19..CovidVaccinations$ AS va
JOIN Portfolio_Covid19..CovidDeaths$  AS de
ON va.location = de.location
AND va.date = de.date
WHERE de.continent IS NOT NULL)
SELECT *, (RollingPeopleVaccinated/population)*100 as vacpercentages FROM mycte

---- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255), Location nvarchar(255), date datetime, 
population numeric, new_vaccinations numeric, RollingPeopleVaccinated numeric)

INSERT INTO	#PercentPopulationVaccinated
SELECT de.continent, de.location, va.date, de.population, va.new_vaccinations,
SUM(CONVERT(bigint, va.new_vaccinations)) OVER (PARTITION BY de.location ORDER BY de.date) as RollingPeopleVaccinated
FROM Portfolio_Covid19..CovidVaccinations$ AS va
JOIN Portfolio_Covid19..CovidDeaths$  AS de
ON va.location = de.location
AND va.date = de.date
WHERE de.continent IS NOT NULL
ORDER BY de.location, de.date

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated

-- Creating view
CREATE VIEW PercentPopulationVaccinated as
SELECT de.continent, de.location, va.date, de.population, va.new_vaccinations,
SUM(CONVERT(bigint, va.new_vaccinations)) OVER (PARTITION BY de.location ORDER BY de.date) as RollingPeopleVaccinated
FROM Portfolio_Covid19..CovidVaccinations$ AS va
JOIN Portfolio_Covid19..CovidDeaths$  AS de
ON va.location = de.location
AND va.date = de.date
WHERE de.continent IS NOT NULL