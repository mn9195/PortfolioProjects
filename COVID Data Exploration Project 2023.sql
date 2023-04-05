/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
FROM PortfolioProject.dbo.CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY 3, 4

-- SELECT *
-- FROM PortfolioProject.dbo.CovidVaccinations
-- ORDER BY 3, 4

-- Select data that we are going to use in this project
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths AS CD
WHERE Continent IS NOT NULL
ORDER BY 1, 2

-- Looking at the Total Cases Vs. Total Deaths
-- Shows the probability of dying if you contract COVID 19, by country and date
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths AS CD
WHERE Continent IS NOT NULL
ORDER BY 1,2

-- Looking at the Total Cases vs. Population
SELECT location, date, total_cases, population, (total_cases/population)*100 AS CasesPercentage
FROM PortfolioProject.dbo.CovidDeaths AS CD
WHERE Continent IS NOT NULL
ORDER BY 1, 2

-- Which Country has the highest infected population rate to population
SELECT location, population, MAX(total_cases) AS MaxCases, MAX((total_cases/population))*100 AS MaxInfectPopPercent
FROM PortfolioProject.dbo.CovidDeaths AS CD
WHERE Continent IS NOT NULL
GROUP BY location, population
ORDER BY MaxInfectPopPercent DESC

-- Showing the countries with the Higest Death Count per Population
SELECT location, MAX(total_deaths) AS MaxTotalDeaths
FROM PortfolioProject.dbo.CovidDeaths AS CD
WHERE Continent IS NOT NULL AND location like '%france%'
GROUP BY location
ORDER BY MaxTotalDeaths DESC

-- BREAKING DOWN BY CONTINENT
SELECT Continent, MAX(total_deaths) AS MaxTotalDeaths
FROM PortfolioProject.dbo.CovidDeaths AS CD
WHERE Continent IS NOT NULL
GROUP BY Continent
ORDER BY MaxTotalDeaths DESC


-- Showing the continent with the highest Death Count per population
SELECT Continent, MAX(total_deaths) AS MaxTotalDeaths, MAX((total_deaths/population))*100 AS MaxTotalDeathPercent
FROM PortfolioProject.dbo.CovidDeaths AS CD
WHERE Continent IS NOT NULL
GROUP BY Continent
ORDER BY MaxTotalDeathPercent DESC


-- GLOBAL NUMBERS

-- Here we will take a look at the Global Numbers
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths)/NULLIF((SUM(new_cases)),0)*100) AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths AS CD
WHERE Continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- As we can see here, overall, across the world, we have a death percentage of less than a percent
SELECT SUM(new_cases) AS total_new_cases, SUM(new_deaths) AS total_new_deaths, (SUM(new_deaths)/NULLIF((SUM(new_cases)),0)*100) AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths AS CD
WHERE Continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2


-- COVID VACCINATIONS

SELECT *
FROM PortfolioProject.dbo.CovidVaccinations

-- Lets join the 2 databases
SELECT *
FROM PortfolioProject.dbo.CovidVaccinations AS CV
JOIN PortfolioProject.dbo.CovidDeaths AS CD 
    ON CV.location = CD.location
    AND CV.date = CD.date



-- Lets look at the Total Populations vs. Vaccinations
-- Here in the column 'TotalNumVaccByLoc' we have the TOTAL number of Vaccination by location
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CV.new_vaccinations) OVER (PARTITION BY CD.location) AS TotalNumVaccByLoc
FROM PortfolioProject.dbo.CovidDeaths AS CD
JOIN PortfolioProject.dbo.CovidVaccinations AS CV
    ON CD.location = CV.location
    AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY 1,2,3

-- Here in the column 'TotalNumVaccByLoc' we have the PROGRESSION number of Vaccination by location
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CV.new_vaccinations) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS ProgNumVacc
FROM PortfolioProject.dbo.CovidDeaths AS CD
JOIN PortfolioProject.dbo.CovidVaccinations AS CV
    ON CD.location = CV.location
    AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY 2,3



-- WITH CTE, Let's calculate the percentage of the Total Populations vs. Vaccinations 
-- (have to have the exact same number of column in the Selets Sections in the function and the CTE)

WITH PopVsVacc (Continent, location, date, population, new_vaccinations, ProgNumVacc)
AS
(
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CV.new_vaccinations) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS ProgNumVacc
FROM PortfolioProject.dbo.CovidDeaths AS CD
JOIN PortfolioProject.dbo.CovidVaccinations AS CV
    ON CD.location = CV.location
    AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
-- ORDER BY 2,3
)

SELECT *, (ProgNumVacc/population)*100 AS ProgNumVaccPercent
FROM PopVsVacc


-- Let's do the same thing with TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(225),
    Date datetime,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    ProgNumVacc NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CV.new_vaccinations) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS ProgNumVacc
FROM PortfolioProject.dbo.CovidDeaths AS CD
JOIN PortfolioProject.dbo.CovidVaccinations AS CV
    ON CD.location = CV.location
    AND CD.date = CV.date
-- WHERE CD.continent IS NOT NULL
-- ORDER BY 2,3

SELECT *, (ProgNumVacc/population)*100 AS ProgNumVaccPercent
FROM #PercentPopulationVaccinated


-- CREATING VIEW TO STORE DATA FOR LATER VIZUALISATIONS

CREATE VIEW PercentPopulationVaccinatedView AS
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
    SUM(CV.new_vaccinations) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS ProgNumVacc
FROM PortfolioProject.dbo.CovidDeaths AS CD
JOIN PortfolioProject.dbo.CovidVaccinations AS CV
    ON CD.location = CV.location
    AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinatedView