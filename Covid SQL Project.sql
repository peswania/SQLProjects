--SELECT *
--FROM dbo.CovidDeaths
--ORDER BY 3,4

--SELECT *
--FROM dbo.CovidVaccinations
--ORDER BY 3,4

-- Select data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM dbo.CovidDeaths
ORDER BY 1,2

-- Total Cases vs Total Deaths

ALTER Table dbo.CovidDeaths
ALTER Column total_cases float;

ALTER Table dbo.CovidDeaths
ALTER Column total_deaths float;

UPDATE dbo.CovidDeaths
SET Date = CONVERT(DATE, Date, 105);

Select Location, date, total_cases, total_deaths, (total_deaths * 100) / NULLIF(total_cases, 0) as DeathPercentage
FROM dbo.CovidDeaths
ORDER BY 1,2

Select Location, date, total_cases, total_deaths, (total_deaths * 100) / NULLIF(total_cases, 0) as DeathPercentage
FROM dbo.CovidDeaths
WHERE Location = 'Pakistan'
ORDER BY 1,2

-- Looking at Total Cases vs Population
ALTER Table dbo.CovidDeaths
ALTER Column population float;

Select Location, date, total_cases, population , (total_cases/population)*100 as CasesPercentage
FROM dbo.CovidDeaths
WHERE Location like '%states%'
ORDER BY 1,2

--Looking at countries with highest infection rate compared to population
Select Location, Population, MAX(total_cases) as HighestInfectionCountry,  MAX((total_cases/NULLIF(population,0)))*100 as PercentPopulationInfected
FROM dbo.CovidDeaths
--WHERE Location like '%states%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

UPDATE dbo.CovidDeaths
SET Total_Cases = NULLIF(Total_Cases, 0),
    Total_Deaths = NULLIF(Total_Deaths, 0);

UPDATE dbo.CovidDeaths
SET population = NULLIF(population, 0);

UPDATE dbo.CovidDeaths
SET continent = NULL
WHERE continent = '';

--Showing countries with the highest death count per population
Select Location, MAX(total_deaths) AS TotalDeathCount
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Lets break things down by continent
-- Showing the continents with highest death count
Select Continent, MAX(total_deaths) AS TotalDeathCount
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Continent
ORDER BY TotalDeathCount DESC

Select Location, MAX(total_deaths) AS TotalDeathCount
FROM dbo.CovidDeaths
WHERE continent IS NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS
Select date, SUM(CONVERT(INT, new_cases)) AS TotalNewCases
FROM dbo.CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY date
ORDER BY date

SELECT
    date,
    SUM(CAST(new_cases AS INT)) AS TotalNewCases
FROM dbo.CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY date
ORDER BY date;

SELECT
    date,
    SUM(CAST(new_cases AS INT)) as total_cases,
	SUM(CAST(new_deaths AS INT)) as total_deaths,
	SUM(CAST(new_deaths AS INT))/SUM(CAST(new_cases AS INT))*100 as DeathPercentage
FROM dbo.CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY date
ORDER BY date;

SELECT
    SUM(CAST(new_cases AS INT)) as total_cases,
	SUM(CAST(new_deaths AS INT)) as total_deaths,
	SUM(CAST(new_deaths AS INT)) /  SUM(CAST(new_cases AS INT)) * 100 AS DeathPercentage
FROM dbo.CovidDeaths
WHERE Continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

UPDATE dbo.CovidDeaths
SET 
    new_cases = NULLIF(new_cases, 0),
    new_deaths = NULLIF(new_deaths, 0);

SELECT
    SUM(CASE
        WHEN ISNUMERIC(new_cases) = 1 THEN CAST(new_cases AS DECIMAL)
        ELSE 0
    END) as total_cases,
    SUM(CASE
        WHEN ISNUMERIC(new_deaths) = 1 THEN CAST(new_deaths AS DECIMAL)
        ELSE 0
    END) as total_deaths,
    CASE
        WHEN SUM(CASE
            WHEN ISNUMERIC(new_cases) = 1 THEN CAST(new_cases AS DECIMAL)
            ELSE 0
        END) = 0 THEN NULL
        ELSE 100.0 * SUM(CASE
            WHEN ISNUMERIC(new_deaths) = 1 THEN CAST(new_deaths AS DECIMAL)
            ELSE 0
        END) /
        SUM(CASE
            WHEN ISNUMERIC(new_cases) = 1 THEN CAST(new_cases AS DECIMAL)
            ELSE 0
        END)
    END as DeathPercentage
FROM dbo.CovidDeaths
WHERE Continent IS NOT NULL;

UPDATE dbo.CovidVaccinations
SET Date = CONVERT(DATE, Date, 105);

--Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vacc
	ON dea.location = vacc.location 
	AND dea.date = vacc.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- USE CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as 
-- ROLLING TOTAL OF VACCINATIONS TO SHOW TOTAL COUNT
(
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations,
SUM(vacc.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingCountPeopleVaccinated
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vacc
	ON dea.location = vacc.location 
	AND dea.date = vacc.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

ALTER Table dbo.CovidVaccinations
ALTER Column new_vaccinations float;


-- TEMP Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric, 
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations,
SUM(vacc.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingCountPeopleVaccinated
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vacc
	ON dea.location = vacc.location 
	AND dea.date = vacc.date
-- ORDER BY 2,3
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- CREATING VIEW TO STORE DATA FOR LATER VISUALISATION

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations,
SUM(vacc.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingCountPeopleVaccinated
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vacc
	ON dea.location = vacc.location 
	AND dea.date = vacc.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3