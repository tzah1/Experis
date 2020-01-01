----- PROJECT PART A
--------TASK 1
-----Building the 'base view' (Contains all data from Orders AND Order.D) which gonna have info connected from supported tables
--go; STAGE 1

create function dbo.isshipped(@a datetime) --- i know its 'overKill' but i wanted to use more tooles for the pro.
returns bit
as
begin
	declare @res_isshipped bit
	if @a < getdate()
		begin
			set @res_isshipped = 1
		end
		else 
			set @res_isshipped = 0
return @res_isshipped
end

alter view vw_base  --- I could choose To declare sum parameters but, didnt sow the need for now (exmple -  declare @vat flooat = 1.17)
as

select 'H'																									as HeaderFlag, 
		o.OrderID, o.OrderDate, o.RequiredDate,o.ShipCity,o.ShipCountry, o.ShippedDate, dbo.isshipped(o.ShippedDate) as IsShipped, 
																											o.ShipRegion,
		sum(od.UnitPrice*od.Quantity)																		as Tot_order_Bruto, 
		sum(od.UnitPrice*od.Quantity*(1-od.Discount))														as  Tot_order_Net, 
		'L'																									as LineFlag, 
		row_number() over(order by o.orderid)																as Order_Line_Num, 
		od.Quantity, od.UnitPrice															                as UnitPrice_Bruto,  
		od.UnitPrice*(1-od.Discount)															            as UnitPrice_Neto,
		od.UnitPrice*od.Quantity        																	as Total_Line_Bruto, 
		od.Quantity*od.UnitPrice*(1-od.Discount)												     		as Total_Line_Net, 
		1.17																								as VAT, 
		sum(od.Quantity*od.UnitPrice*(1-od.Discount))*1.17													as Total_Line_WithVat ,
		od.Quantity*od.UnitPrice*(1-od.Discount)/sumOR.m                                                    as Perc_Line_Total_Bruto,
		od.ProductID, o.EmployeeID,o.CustomerID,sumOR.m
		

from [Order Details] od left join Orders o on o.OrderID = od.OrderID 
						left join (select orderid, sum(Quantity*UnitPrice*(1-Discount)) as m from [Order Details] -- drived table for saclar avaloation of sum order
									group by OrderID) sumOR on sumor.orderid = o.OrderID
group by o.OrderID, o.OrderDate, o.RequiredDate, o.ShippedDate, o.ShipRegion, 
		od.Quantity, od.UnitPrice, od.Discount, od.OrderID, od.ProductID, o.EmployeeID,o.CustomerID,
		o.ShipCity,o.ShipCountry,sumOR.m, sumor.orderid


										alter function dbo.reportsTo(@b int) ---- WHO IS THE MENAGER ?
										returns varchar(max)
										as
											begin
												if @b =(select em1.EmployeeID from Employees em1 where @b = em1.EmployeeID	)
													begin
													  declare @res varchar(max) = (select  em.FirstName+' '+em.LastName 
																					from Employees em 
																					where em.EmployeeID = @b )
													end 
													else set @res = 'CEO'
										return @res
										end

	--go; STAGE 2 
	-- Creating a view to contain all data in ONE view - 'comprensive' 
	
alter view vw_FullD
as
	select 'H'	as HeaderFlag, vw1.OrderID, vw1.OrderDate, vw1.RequiredDate, c.CompanyName as customerName, c.ContactName as customerCon_Name, c.Country as buying_country,
			vw1.ShipCity, vw1.ShipCountry, vw1.ShippedDate, vw1.IsShipped, vw1.ShipRegion, s.CompanyName as Supllier_Name, s.ContactName as Supllier_con_Name,
			e.FirstName+' ' +e.LastName as EmpFullName, e.ReportsTo as ManagerID 
			, dbo.reportsTo(e.ReportsTo) as ManagerName
			
			,vw1.Tot_order_Bruto, vw1.Tot_order_Net, vw1.LineFlag, vw1.Order_Line_Num, p.ProductName, cat.CategoryName, cat.Description,
			vw1.quantity, vw1.UnitPrice_Bruto, vw1.UnitPrice_Neto, vw1.Total_Line_Bruto, vw1.Total_Line_Net, vw1.VAT, vw1.Total_Line_WithVat,
			vw1.Perc_Line_Total_Bruto,
			sum(vw1.Perc_Line_Total_Bruto) over (partition by vw1.orderid order by vw1.Order_Line_Num )		as Perc_Line_Total_ACCU
			
	from vw_base vw1 left join Products p on p.ProductID = vw1.productid 
					left join Suppliers s on p.SupplierID = s.SupplierID
					left join Customers c on vw1.customerid = c.CustomerID
					left join Employees e on e.EmployeeID = vw1.employeeid
					left join Categories cat on p.CategoryID = cat.CategoryID
select * -- Works DONE!!
from vw_FullD

--------------------------------------------------------------------------------------- TASK 2
									create procedure OrderId_insert (@orderID int) --- Give me all order details by id of order
									as 
										if @orderID != 0
											begin
											select* 
												from vw_fullD vw2
												where vw2.OrderID = @orderID
											end
											else
												select* 
												from vw_fullD
										return 

									exec OrderId_insert 10258;
------------------------------------------------------------------------------------------ 
-------------- TASK 3

create procedure PrimeTable(@PrimeBYOrder int)
as 
select distinct top 1
				cast(HeaderFlag as nvarchar(max)) as HeaderFlag,
				cast(orderid as nvarchar(max)) as orderid ,
				cast(orderdate as nvarchar(max)) as orderdate,
				cast(RequiredDate as nvarchar(max)) as requireddate ,
				cast(customerName as nvarchar(max)) as cus_name ,
				cast(customerCon_Name as nvarchar(max)) as cus_con_name ,
				cast(buying_country as nvarchar(max)) as country,
				cast(shipcity as nvarchar(max)) as shipcity ,
				cast(ShipCountry as nvarchar(max)) as shipcountry ,
				cast(ShippedDate as nvarchar(max)) as shippeddate,
				cast(IsShipped as nvarchar(max)) as is_shipped ,
				cast(ShipRegion as nvarchar(max)) as ShipRegion ,
				cast(Supllier_Name as nvarchar(max)) as SupllierName ,
				cast(Supllier_con_Name as nvarchar(max)) as Supllier_con_Name,
				cast(EmpFullName as nvarchar(max)) as EmpFullName ,
				cast(ManagerID as nvarchar(max)) as ManagerID ,
				cast(managerName as nvarchar(max)) as managerName ,
				cast(Tot_order_Bruto as nvarchar(max)) as Tot_order_Bruto,
				cast(Tot_order_Net as nvarchar(max)) as Tot_order_Net
				from vw_FullD  
				where orderid = @PrimeBYOrder
union all 
select 
				cast(LineFlag as nvarchar(max)),
				cast(Order_Line_Num as nvarchar(max)),
				null,
				null,
				cast(vw.ProductName as nvarchar(max)),
				cast(vw.CategoryName as nvarchar(max)),
				cast(vw.Description as nvarchar(max)),
				cast(vw.Quantity as nvarchar(max)),
				cast(vw.UnitPrice_Bruto as nvarchar(max)),
				cast(vw.UnitPrice_Neto as nvarchar(max)),
				cast(vw.Total_Line_Bruto as nvarchar(max)),
				cast(vw.Total_Line_Net as nvarchar(max)),
				cast(vw.VAT as nvarchar(max)),
				cast(vw.Total_Line_WithVat as nvarchar(max)),
				cast(vw.Perc_Line_Total_Bruto as nvarchar(max)),
				cast(vw.Perc_Line_Total_ACCU as nvarchar(max)),
				null,
				null,
				null
				from vw_FullD vw
				where orderid = @PrimeBYOrder
				order by HeaderFlag, orderid


exec PrimeTable 10248; ---ENTER YOUR ORDER ID FOR DET. ||||||| DONE STAGE 1