SELECT * from 
PortfolioProject..CovidDeaths
where continent is not null
Order by 3,4;


SELECT * from 
PortfolioProject..CovidVaccinations
Order by 3,4;

--SELECT THE DATA WE ARE GOING TO USE
SELECT location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2;

--Looking at our total cases vs total deaths
--Shows the likelihood of dying if you contact covid in your country
SELECT location, date,total_cases, total_deaths, (total_deaths / total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%states%'
and continent is not null
order by 1,2;

--Looking at total cases vs population
--Shows what percentage of the population got covid
SELECT location, date, population, total_cases, (total_cases / population)*100 as CasesPercentage
from PortfolioProject..CovidDeaths
where location like '%states%'
and continent is not null
order by 1,2;


--Lookingat countries with the highest infection rate compared to their population
SELECT location,population, max(total_cases) as HighestInfectCount, max((total_cases / population))*100 as PercentagePopulationInfected
from PortfolioProject..CovidDeaths
--where location like '%kenya'
where continent is not null
group by location, population
order by PercentagePopulationInfected desc;

--Showing countries with the highest death per population
-- casted the total death as int because in the data it is set as varchar

SELECT location, max(cast(total_deaths as int)) as TotalDeath
from PortfolioProject..CovidDeaths
where continent is not null
group by location
order by TotalDeath desc;

--LETS BREAK DOWN THINGS BY CONTINENT

SELECT continent, max(cast(total_deaths as int)) as TotalDeath
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by TotalDeath desc;

--The correct way for the above query would be;
SELECT location, max(cast(total_deaths as int)) as TotalDeath
from PortfolioProject..CovidDeaths
where continent is null
group by location
order by TotalDeath desc;


--GLOBAL NUMBERS


select --date, 
SUM(new_cases) as total_cases,
SUM(cast(new_deaths as int)) as total_deaths,
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null 
--group by date
order by 1,2;


--JOINING THE 2 TABLES
--Looking at the total cases vs vaccinations

select dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
SUM(convert(int,vac.new_vaccinations)) OVER(partition by dea.location order by dea.location, dea.date) as RollingPeoleVaccinated
from PortfolioProject..CovidDeaths dea  
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Looking at the percentage of people that are vaccinated using the above query
--USE CTE
with PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) as
	( 
	select dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
	SUM(convert(int,vac.new_vaccinations)) OVER(partition by dea.location order by dea.location, dea.date) as RollingPeoleVaccinated
	from PortfolioProject..CovidDeaths dea  
	join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
	)
	--order by 2,3)
select *, (RollingPeopleVaccinated/population)*100
from PopVsVac


--TEMP TABLE
--LET'S EXACTLY THE ABOVE BUT NOW USING TEMP TABLE

drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)


insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
	SUM(convert(int,vac.new_vaccinations)) OVER(partition by dea.location order by dea.location, dea.date) as RollingPeoleVaccinated
	from PortfolioProject..CovidDeaths dea  
	join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
	order by 2,3

select *, (RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated


-- Creating View to store data for later visualizations


Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 