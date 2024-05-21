--1
SELECT P.ProductID, P.Name,P.Color, P.ListPrice,P.Size
FROM Production.Product AS p
  LEFT JOIN Sales.SalesOrderDetail AS S ON P.ProductID= S.ProductID
WHERE S.ProductID IS NULL
ORDER BY p.ProductID

--2
SELECT c.CustomerID, ISNULL(p.LastName,'Unknown')AS LastName, ISNULL(P.FirstName,'Unknown') AS FirstName
FROM Sales.Customer AS c
  LEFT JOIN Sales.SalesOrderHeader AS s ON c.CustomerID= s.CustomerID
  LEFT JOIN Person.Person AS p ON c.CustomerID= p.BusinessEntityID
WHERE s.CustomerID is null
ORDER BY C.CustomerID 

--3
SELECT TOP 10 s.CustomerID, p.FirstName,p.LastName, COUNT(s.salesorderid) AS CountOfOrders
FROM Sales.SalesOrderHeader AS s
   JOIN Sales.Customer AS c ON s.CustomerID=c.CustomerID
   JOIN Person.Person AS p ON c.PersonID=p.BusinessEntityID
GROUP BY s.CustomerID, p.FirstName, p.LastName
ORDER BY CountOfOrders DESC, S.CustomerID

--4
SELECT p.FirstName,p.LastName, e.JobTitle, e.HireDate,
   COUNT(*) OVER(partition by e.Jobtitle) AS CountOfTitle
FROM Person.Person AS p 
   JOIN HumanResources.Employee AS e ON p.BusinessEntityID= e.BusinessEntityID

--5
WITH table1
AS
(
  SELECT o.SalesOrderID, c.CustomerID, p.LastName, p.FirstName, o.orderdate,
	RANK()OVER(PARTITION BY c.customerid ORDER BY o.OrderDate DESC)AS RN,
	LAG(o.orderdate)OVER(PARTITION BY c.customerid ORDER BY o.orderdate ASC) AS PreviousOrder
  FROM Sales.SalesOrderHeader AS o LEFT JOIN Sales.Customer AS c ON o.CustomerID=c.CustomerID
							      LEFT JOIN Person.Person AS p ON p.BusinessEntityID=c.PersonID
)

SELECT SalesOrderID, CustomerID, LastName, FirstName, OrderDate AS LastOrder, PreviousOrder
FROM table1
WHERE RN=1


--6
WITH SumO
AS
(
  SELECT 
    YEAR(OH.OrderDate) AS Y, OD.SalesOrderID,P.LastName,P.FirstName,
    SUM(OD.UnitPrice * (1 - OD.UnitPriceDiscount) * OD.OrderQty) OVER (PARTITION BY OD.SalesOrderID) AS Total
  FROM Sales.SalesOrderDetail AS OD
    LEFT JOIN Sales.SalesOrderHeader AS OH ON OD.SalesOrderID = OH.SalesOrderID
    LEFT JOIN Sales.Customer AS C ON C.CustomerID = OH.CustomerID
    LEFT JOIN  Person.Person AS P ON P.BusinessEntityID = C.PersonID
),
MaxPrice AS (
  SELECT *,
    DENSE_RANK() OVER (PARTITION BY Y ORDER BY TOTAL DESC) AS RN
  FROM SumO
)
SELECT DISTINCT O.Y AS [Year],O.SalesOrderID,O.LastName,O.FirstName,FORMAT(O.Total, '#,#.0') AS Total
FROM MaxPrice AS O
WHERE O.RN = 1
ORDER BY O.Y


--7
SELECT *
FROM (SELECT YEAR(s.OrderDate) AS [year], MONTH(s.OrderDate) AS [month], s.SalesOrderID
      FROM Sales.SalesOrderHeader AS s ) AS o
 PIVOT (COUNT(salesorderid) FOR [year] in ([2011],[2012],[2013],[2014])) AS pvt
ORDER BY 1


--8
WITH TBL 
AS
( 
   SELECT YEAR(OrderDate) AS YY, MONTH(OrderDate) AS MM, SUM(UnitPrice) AS Sum_Price 
   FROM Sales.SalesOrderHeader OH 
     left JOIN Sales.SalesOrderDetail O ON O.SalesOrderID = OH.SalesOrderID
   GROUP BY YEAR(OrderDate), MONTH(OrderDate)
),
TBL2 
AS
( 
   SELECT *,
       SUM(Sum_Price)OVER(PARTITION BY YY ORDER BY MM ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumSum,
       ROW_NUMBER()OVER(PARTITION BY YY ORDER BY MM) AS RN 	
   FROM TBL
), 
TBL3 
AS
( 
    SELECT YY , CAST(MM AS VARCHAR) AS MM, Sum_Price, CumSum, RN 
	FROM TBL2 	
    UNION  	
	SELECT YEAR(OrderDate) AS 'YEAR', 'Grand_Total', NULL, SUM(UnitPrice) AS SUM_Price, 13 	
    FROM Sales.SalesOrderHeader OH JOIN Sales.SalesOrderDetail O ON O.SalesOrderID = OH.SalesOrderID 
    GROUP BY YEAR(OrderDate) 	
    UNION 	
	SELECT 3000, 'Grand_Total', NULL, SUM(UnitPrice) AS Sum_Price, 100 
    FROM Sales.SalesOrderHeader OH JOIN Sales.SalesOrderDetail O ON O.SalesOrderID = OH.SalesOrderID
)
SELECT YY as [Year], MM as [Month], Sum_Price, CumSum 
FROM TBL3
ORDER BY YY, RN

--9
WITH OrderByHireDate
AS
(
    SELECT d.Name AS DepartmentName, e.BusinessEntityID AS EmployeesID, p.FirstName + ' ' + p.LastName AS EmployeesFullName, h.StartDate AS HireDate,
        LEAD(h.StartDate) OVER (PARTITION BY d.Name ORDER BY h.StartDate DESC) AS PreviousHireDate,
        LEAD(p.FirstName + ' ' + p.LastName) OVER (PARTITION BY d.Name ORDER BY h.StartDate DESC) AS PreviousEmpName
    FROM HumanResources.Department AS d 
    LEFT JOIN HumanResources.EmployeeDepartmentHistory AS h ON d.DepartmentID = h.DepartmentID
    LEFT JOIN HumanResources.Employee AS e ON e.BusinessEntityID = h.BusinessEntityID
    LEFT JOIN Person.Person AS p ON p.BusinessEntityID = e.BusinessEntityID
)
SELECT 
    DepartmentName, EmployeesID, EmployeesFullName,  HireDate,
    DATEDIFF(MONTH, HireDate, GETDATE()) AS Seniority, PreviousEmpName,PreviousHireDate,
    DATEDIFF(DAY, PreviousHireDate, HireDate) AS DiffDays
FROM OrderByHireDate
ORDER BY DepartmentName


--10
SELECT HireDate, DepartmentID,
       STRING_AGG(CONCAT(e.BusinessEntityID,' ',LastName, ' ', FirstName), ' - ') AS TeamEmployees
FROM 
    HumanResources.Employee AS E
    LEFT JOIN HumanResources.EmployeeDepartmentHistory AS D ON D.BusinessEntityID=E.BusinessEntityID
    LEFT JOIN Person.Person AS P ON P.BusinessEntityID=E.BusinessEntityID
WHERE EndDate IS NULL
GROUP BY HireDate, DepartmentID
ORDER BY HireDate DESC, DepartmentID;



