create table CurrExchangeTbl(
rate_date datetime,
rate_dollar decimal(4,3) 
)
go
CREATE proc generate_dates
	@dollar_rate decimal(4,3) 	
as
begin
declare @enddate date = (select distinct max(orderdate) from [Northwind].[dbo].[Orders])
declare @startdate date = (select distinct MIN(orderdate) from [Northwind].[dbo].[Orders])
declare @month int = month(@startdate)
      while @startdate < @enddate
	  begin	       
		   if MONTH(@startdate) != @month
		      set @dollar_rate = @dollar_rate + 0.005
			  set @month = MONTH(@startdate)	  
	       insert into CurrExchangeTbl values(@startdate,@dollar_rate)
		   set @startdate = DATEADD(dd,1,@startdate)
	  end    
		    
end

exec generate_dates 3.245

--drop table CurrExchangeTbl;
-- drop table currncyEX;

select * from CurrExchangeTbl


SELECT YEAR(rate_Date), month(rate_date),MAX(rate_dollar)
FROM CurrExchangeTbl 
GROUP BY YEAR(rate_Date), month(rate_date)
order by 1,2 -- check for valid result set.

