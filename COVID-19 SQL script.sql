-- Import data into SQL and check if they are correct
SELECT *
  FROM [PortfolioProject].[dbo].[CovidDeaths]
  -- Excluding the data where continent is null
  WHERE continent <>''
  ORDER BY 3,4

--SELECT *
--FROM [PortfolioProject].[dbo].[CovidVaccinations]
--ORDER BY 3,4

-- Select data that I want to analyze, ordered by location and date
SELECT location,date,total_cases, new_cases, total_deaths, population
  FROM [PortfolioProject].[dbo].[CovidDeaths]
  WHERE continent <>''
  ORDER BY 1,2

-- Total deaths vs total cases and death percentage
-- Shows likelihood of death if one contracts COVID-19 in Canada
SELECT location,date,total_cases, total_deaths,
  -- Convert data type
  (CONVERT(float,total_deaths)/NULLIF(CONVERT(float,total_cases),0))*100 AS Death_Percentage
  FROM [PortfolioProject].[dbo].[CovidDeaths]
  -- Looking for data in Canada
  WHERE location = 'Canada'
  ORDER BY 1,2

-- Total cases vs population
-- Shows the percentage of population contracting COVID-19 in Canada
SELECT location,date,total_cases, population,
  -- Convert data type
  (CONVERT(float,total_cases)/NULLIF(CONVERT(float,population),0))*100 AS Infection_Rate
  FROM [PortfolioProject].[dbo].[CovidDeaths]
  -- Looking for data in Canada
  WHERE location = 'Canada'
  ORDER BY 1,2

-- Looking for countries with highest infection count and highest infection rate compared to population
SELECT location, population, MAX((CONVERT(float,total_cases))) AS Highest_Infection_Count,
  -- Convert data type
  MAX((CONVERT(float,total_cases)/NULLIF(CONVERT(float,population),0)))*100 AS Highest_Infection_Rate
  FROM [PortfolioProject].[dbo].[CovidDeaths]
  WHERE continent <>''
  Group by location, population
  ORDER BY 4 DESC
  -- Canada is in the 73th place

-- Looking for countries with highest death count
SELECT location, population, MAX((CONVERT(float,total_deaths))) AS Highest_Death_Count
  FROM [PortfolioProject].[dbo].[CovidDeaths]
  WHERE continent <>''
  Group by location, population
  ORDER BY 3 DESC

-- Looking for countries with highest death rate compared to population
SELECT location, population, 
  -- Convert data type
  MAX((CONVERT(float,total_deaths)/NULLIF(CONVERT(float,population),0)))*100 AS Highest_Death_Rate
  FROM [PortfolioProject].[dbo].[CovidDeaths]
  WHERE continent <>''
  Group by location, population
  ORDER BY 3 DESC

-- Breaking down death count by continent

-- Continents with the highet death rate per population
SELECT continent, MAX((CONVERT(float,total_deaths))) AS Highest_Death_Count
  FROM [PortfolioProject].[dbo].[CovidDeaths]
  WHERE continent <> ''
  Group by continent
  ORDER BY 2 DESC

-- Global numbers
SELECT date,SUM(CONVERT(int,new_cases)) AS Global_Cases, SUM(CONVERT(int,new_deaths)) AS Global_, 
  SUM(CONVERT(float, new_deaths))/NULLIF(SUM(CONVERT(float, new_cases)),0)*100 AS Global_Death_Percentage
  FROM [PortfolioProject].[dbo].[CovidDeaths]
  WHERE continent <> ' '
  GROUP BY date
  ORDER BY 1,2

SELECT SUM(CONVERT(int,new_cases)) AS Global_Cases, SUM(CONVERT(int,new_deaths)) AS Global_, 
  SUM(CONVERT(float, new_deaths))/NULLIF(SUM(CONVERT(float, new_cases)),0)*100 AS Global_Death_Percentage
  FROM [PortfolioProject].[dbo].[CovidDeaths]
  WHERE continent <> ' '
  ORDER BY 1,2

-- Total population vs vaccinations
SELECT Death.continent, Death.location, Death.date, Death.population, Vac.new_vaccinations,
  SUM(CONVERT(int,Vac.new_vaccinations)) 
  OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS Rolling_Vaccinated_Count
  FROM [PortfolioProject].[dbo].[CovidDeaths] AS Death
  JOIN [PortfolioProject].[dbo].[CovidVaccinations] AS Vac
  ON Death.location = Vac.location
  and Death.date = Vac.date
  WHERE Death.continent <> ' '
  ORDER BY 2,3
-- Firt day COVID vaccination was exercised in Canada was 2020-12-15 with a number 718


-- Use CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, Rolling_Vaccinated_Count)
AS
(
SELECT Death.continent, Death.location, Death.date, Death.population, Vac.new_vaccinations,
  SUM(CONVERT(int,Vac.new_vaccinations)) 
  OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS Rolling_Vaccinated_Count
  FROM [PortfolioProject].[dbo].[CovidDeaths] AS Death
  JOIN [PortfolioProject].[dbo].[CovidVaccinations] AS Vac
  ON Death.location = Vac.location
  and Death.date = Vac.date
  WHERE Death.continent <> ' '
  -- ORDER BY 2,3
  )
SELECT *, 
  IIF(CONVERT(float, population)=0, Null,(Rolling_Vaccinated_Count/CONVERT(float, population)) *100) AS Rolling_Vaccinated_Rate
FROM PopvsVac


-- Temp Table
DROP TABLE if EXISTS #PercentagePopulationVaccinated
CREATE TABLE #PercentagePopulationVaccinated
 ( 
  continent nvarchar(255),
  location nvarchar(255),
  date datetime,
  population varchar(50),
  new_vaccinations varchar(50),
  Rolling_Vaccinated_Count numeric
  )
INSERT INTO #PercentagePopulationVaccinated
SELECT Death.continent, Death.location, Death.date, Death.population, Vac.new_vaccinations,
  SUM(CONVERT(int,Vac.new_vaccinations)) 
  OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS Rolling_Vaccinated_Count
  FROM [PortfolioProject].[dbo].[CovidDeaths] AS Death
  JOIN [PortfolioProject].[dbo].[CovidVaccinations] AS Vac
  ON Death.location = Vac.location
  and Death.date = Vac.date
  WHERE Death.continent <> ' '
  -- ORDER BY 2,3
  SELECT *, 
  IIF(CONVERT(float, population)=0, Null,(Rolling_Vaccinated_Count/CONVERT(float, population)) *100) AS Rolling_Vaccinated_Rate
FROM #PercentagePopulationVaccinated

-- Creating view to store data for later visualizations
CREATE VIEW PercentagePopulationVaccinated AS
SELECT Death.continent, Death.location, Death.date, Death.population, Vac.new_vaccinations,
  SUM(CONVERT(int,Vac.new_vaccinations)) 
  OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS Rolling_Vaccinated_Count
  FROM [PortfolioProject].[dbo].[CovidDeaths] AS Death
  JOIN [PortfolioProject].[dbo].[CovidVaccinations] AS Vac
  ON Death.location = Vac.location
  and Death.date = Vac.date
  WHERE Death.continent <> ' '
  --ORDER BY 2,3


 SELECT *
 FROM PercentagePopulationVaccinated