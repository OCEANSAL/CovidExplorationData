-- Percentage of Deaths in Morocco

SELECT Location, date, total_cases,total_deaths,(total_deaths/total_cases)*100 AS DeathPercentage
FROM Portfolio..CovidDeaths
WHERE location = 'morocco'
ORDER BY DeathPercentage DESC;

-- Percentage of Covid Infection 

SELECT Location, date, population,total_cases,(total_cases/population)*100 AS InfecteesPercentage
FROM Portfolio..CovidDeaths
--WHERE location = 'morocco'
ORDER BY 1,2;

--Countries with the highest infection count by country

SELECT Location, population,max(total_cases) AS HighestInfectionCount,format(Max((total_cases/population)*100),'N3') + '%' AS HighestInfecteesPercentage
FROM Portfolio..CovidDeaths
GROUP BY location,Population
ORDER BY HighestInfecteesPercentage DESC;

--Countries with the highest Death count by country

SELECT Location,max(cast(total_deaths as int)) AS HighestdeathCount,format(Max((total_deaths/population)*100),'N3') + '%' AS HighestDeathPercentage
FROM Portfolio..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY HighestDeathPercentage DESC ;

-- By continent

SELECT continent, sum(cast(total_deaths as int)) AS TotalDeaths,format((Sum(cast(total_deaths as int))/sum(population)*100),'N3') + '%' AS TotalDeathsPercentage
FROM Portfolio..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathsPercentage DESC;


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Total_vac
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3 DESC;

--using CTE to perform Calculation on Partition By in previous query

With popvsVac (continent, location, date, population, new_vaccinations,Total_vac)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Total_vac
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
)

SELECT *, format((Total_vac/population)*100,'N3')+'%' AS RollingPeopleVac
FROM popvsVac

--Temp table

DROP Table if exists #PopulationVaccinated
CREATE TABLE #PopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
Date datetime,
population numeric,
New_Vaccinations numeric,
Total_vac numeric
)

INSERT INTO #PopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Total_vac
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (Total_vac/population)*100
FROM #PopulationVaccinated

-- Creating View to store data for later visualizations

USE Portfolio
GO
CREATE VIEW PercentPopVac AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Total_vac
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
