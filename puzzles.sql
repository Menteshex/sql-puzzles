-- Puzzle #1
select c1.Item, c2.Item
  from Cart1 c1 full outer join Cart2 c2
    on c1.Item = c2.Item;


-- Puzzle #2
select *,
       case 
        when managerid is null then 0
        when managerid = 1001 then 1
        when managerid = 2002 then 2
       end as depth
  from employees;

with levels (employeeid, managerid, jobtitle, salary, depth) as 
  (select employeeid, managerid, jobtitle, salary, 0 as depth
     from employees
    where JobTitle = 'President'
     union ALL
   select e.employeeid, e.managerid, e.jobtitle, e.salary, depth + 1
     from employees e join levels l on e.managerid=l.employeeID
  )
select *
  from levels;

-- Puzzle #3 ??? --
DROP TABLE IF EXISTS EmployeePayRecords;
GO

CREATE TABLE EmployeePayRecords
(
EmployeeID  INTEGER not null,
FiscalYear  INTEGER CHECK (FiscalYear <= year(getdate())),
StartDate   DATE,
EndDate     DATE CHECK (EndDate <= getdate()),
PayRate     MONEY not null
);
GO

-- Puzzle #4
select *
  from orders
 where customerid in (select customerid from orders
                      where deliverystate = 'CA') 
       and deliverystate = 'TX';

-- Puzzle #5
select CustomerId, cellular, work, home
  from (
select CustomerId, type, phonenumber
  from phonedirectory
) as st
PIVOT
( max(phonenumber)
  for type in (cellular, work, home)
) as pt

-- Puzzle #6
select *
  from workflowsteps
 where completiondate is null

select * 
  from workflowsteps
 group by workflow, stepnumber, completiondate
having count(*) = count(*) - count(completiondate)

-- Puzzle #7
select candidateid
  from candidates
 where occupation in (select * from requirements)
 group by candidateid

select candidateid
  from candidates c join requirements r
    on c.occupation=r.requirement
 group by candidateid

-- Puzzle #8
select workflow, case1 + case2 + case3 as passed
  from workflowcases; 

-- Puzzle #9
with cte1 AS
        (
         select e1.Employeeid, e1.License
           from Employees e1 cross JOIN Employees e2
        ),
     cte2 as 
        (
         select distinct t1.EmployeeID, t1.license
           from cte1 t1 join Employees t2
             on t1.License = t2.License and t1.EmployeeID <> t2.EmployeeID
        ),
     cte3 AS
        (
         select distinct c.EmployeeID, 
                count(e.License) over (partition by c.employeeid) as count_license
           from cte2 c join Employees e
             on c.EmployeeID = e.EmployeeID and c.License <> e.License
        ),
     cte4 AS
        (
         select EmployeeID, count_license, 
                count(EmployeeID) over (partition by count_license) as count_employeeid
           from cte3
        )
    select EmployeeID, count_license
      from cte4
     where count_employeeid > 1;

-- Puzzle #10
select avg(integervalue) as mean,
       ((select max(integervalue) 
           from (select top 50 percent integervalue 
                   from sampledata order by integervalue)as a)
        +
       (select min(integervalue) 
          from (select top 50 percent integervalue 
                  from sampledata order by integervalue desc)as b))/2 as median,
       (select top 1 count(*) from sampledata 
         group by integervalue
         order by count(*) desc) as mode,
       max(integervalue) - min(integervalue) as range
  from sampledata;

-- Puzzle #11 --
with cte1 AS
      (
       select tc1.TestCase as tc1, tc2.TestCase as tc2 
         from TestCases tc1 cross join TestCases tc2
      ),
     cte2 AS
      (
       select c.tc1, c.tc2, tc.TestCase as tc3
         from cte1 c cross join TestCases tc
        where c.tc1 <> c.tc2 and c.tc2 <> tc.TestCase and c.tc1 <> tc.TestCase 
      ),
     cte3 AS
      (
       select tc1 + ',' + tc2 + ',' + tc3 as letters from cte2
      )
    select letters as 'Output', rank() over (order by letters) as 'Row Number'
      from cte3;

-- Puzzle #12 
with cte1 AS
        (
         select Workflow, executiondate, 
                lag(executiondate) over (partition by workflow order by workflow) as laggy
           from ProcessLog
        ),
     cte2 AS
        (
         select Workflow,
                sum(cast(cast(executiondate as datetime) 
                - cast(laggy as datetime) as int))/count(laggy) as res
           from cte1
          group by Workflow
        )
    select Workflow, res as 'Average Days'
      from cte2;

-- Puzzle #13
with a as 
      (
       select sum(quantityadjustment) as inventory, 1 as j
       from inventory
       where day(inventorydate) < 2
      ),
     b as 
      (
       select sum(quantityadjustment) as inventory, 2 as j
       from inventory
       where day(inventorydate) < 3
      ),
     c as 
      (
       select sum(quantityadjustment) as inventory, 3 as j
       from inventory
       where day(inventorydate) < 4
      ),
     d as 
      (
       select sum(quantityadjustment) as inventory, 4 as j
       from inventory
       where day(inventorydate) < 5
      ),
     e as 
      (
       select sum(quantityadjustment) as inventory, 5 as j
       from inventory
       where day(inventorydate) < 6
      )
    select inventorydate, quantityadjustment, inventory
    from a, inventory i
    where a.j = day(inventorydate)
    union
    select inventorydate, quantityadjustment, inventory
    from b, inventory i
    where b.j = day(inventorydate)
    union
    select inventorydate, quantityadjustment, inventory
    from c, inventory i
    where c.j = day(inventorydate)
    union
    select inventorydate, quantityadjustment, inventory
    from d, inventory i
    where d.j = day(inventorydate)
    union
    select inventorydate, quantityadjustment, inventory
    from e, inventory i
    where e.j = day(inventorydate)
    order by inventorydate

select *, sum(quantityadjustment) over (order by inventorydate) as inventory
  from inventory;

-- Puzzle #14
with bra AS
        (
         select workflow
           from processlog
          where status = 'Complete'
         EXCEPT
         select workflow from processlog
          where status <> 'Complete'
        ),
     fox as 
        (
         select workflow
           from processlog
          where status = 'Error'
         EXCEPT
         select workflow from processlog
          where status <> 'Error'
        ),
     cha AS
        (
         select workflow
           from processlog
          where status = 'Complete' 
         intersect
         select workflow from processlog
          where status = 'Error'
         union
         select workflow
           from processlog
          where status = 'Error' 
         intersect
         select workflow from processlog
          where status = 'Running'
        ),
     del as 
        (
         select workflow
           from processlog
          where status = 'Complete' 
         intersect
         select workflow from processlog
          where status = 'Running'
        )
    select *, 'Complete' as status from bra
    UNION
    select *, 'Error' as status from fox
    union
    select *, 'Indeterminate' as status from cha
    UNION
    select *, 'Running' as status from del;

-- Puzzle #15
with a as
        (
         select string from dmltable
          where sequencenumber = 1
        ),
     b as
        (
         select string from dmltable
          where sequencenumber = 2
        ),
     c as
        (
         select string from dmltable
          where sequencenumber = 3
        ),
     d as
        (
         select string from dmltable
          where sequencenumber = 4
        ),
     e as
        (
         select string from dmltable
          where sequencenumber = 5
        ),
     f as
        (
         select string from dmltable
          where sequencenumber = 6
        ),
     g as
        (
         select string from dmltable
          where sequencenumber = 7
        ),
     h as
        (
         select string from dmltable
          where sequencenumber = 8
        ),
     i as
        (
         select string from dmltable
          where sequencenumber = 9
        )
    select a.string + ' ' + b.string + ', ' + c.string + ', ' + d.string + ' ' + e.string + ' ' + 
           f.string + ' ' + g.string + ' ' + h.string + ' ' + i.string as string
      from a, b, c, d, e, f, g, h, i;


-- Puzzle #16 ???
with a AS
      (
       select a.playera, a.playerb, a.Score
         from playerscores a join playerscores b
           on a.playera = b.playerb and a.playerb = b.playera
      ),
     b AS
      (
       select top 1 a.playera, a.playerb, sum(a.score) over (order by a.playera desc) as sumofscore
         from playerscores a join playerscores b
           on a.playera = b.playerb and a.playerb = b.playera
        group by a.playera, a.playerb, a.score
        order by a.playera
      )
  select playera, playerb, sum(score) as sumofscore
    from playerscores
   group by playera, playerb
  EXCEPT
  select * from a
  union
  select * from b;

with cte_a AS
      (
       select a.playera, a.playerb, sum(a.score) over (order by a.playera desc) as sumofscore
         from playerscores a join playerscores b
           on a.playera = b.playerb and a.playerb = b.playera       -- 125 140
      ),
     cte_b AS
      (
       select sum(a.score) as sumofscore
         from playerscores a join playerscores b                -- 140
           on a.playera = b.playerb and a.playerb = b.playera
      ),
     cte_c AS
      (
       select a.playera, a.playerb, a.sumofscore                -- ... 140
         from cte_a a join cte_b b
           on a.sumofscore = b.sumofscore
      )
  select playera, playerb, score as sumofscore
    from playerscores
  EXCEPT
  select a.playera, a.playerb, a.score as sumofscore
    from playerscores a join playerscores b
      on a.playera = b.playerb and a.playerb = b.playera 
  union
  select * from cte_c;
--???--
with cte_a AS
      (
       select a.playera playera1, a.playerb playerb1, a.score score1,
              b.playera playera2, b.playerb playerb2, b.score score2,
              a.score + b.score as sumofscore
         from playerscores a join playerscores b
           on a.playera = b.playerb and a.playerb = b.playera       -- 225 140
      ),
     cte_b AS
      (
       select a.playera1, a.playerb1, a.sumofscore
         from cte_a a join PlayerScores b
         on a.playera2 = b.playera and a.playerb2 <> b.playerb
      )
  select playera 'Player A', playerb 'Player B', Score
    from playerscores
  EXCEPT
  select playera1, playerb1, score1 
    from cte_a
  union
  select playera1, playerb1, sumofscore 
    from cte_b;
  
-- Puzzle #17
with a (num, productdescription, quantity, coun) AS
      (
       select row_number() over (order by quantity desc) as num, 
              productdescription, quantity, 1 as coun
         from ungroup 
       union ALL
       select num, productdescription, quantity, coun + 1
         from a
        where coun < quantity
      )
    select productdescription, 1 as qauntity
      from a
     order by num

with a (productdescription, quantity, coun) AS
      (
       select productdescription, quantity, 1 as coun
         from ungroup 
       union ALL
       select productdescription, quantity, coun + 1
         from a
        where coun < quantity
      )
    select productdescription, 1 as quantity
      from a
     order by productdescription

-- Puzzle #18
-- Create temporary table
declare 
@coun int

set @coun = 1

drop table if exists #tempo1

select @coun as numbers
  into #tempo1

      while (@coun < (select max(seatnumber) from seatingchart))
      BEGIN
      set @coun += 1

      insert into #tempo1 values(@coun)

      END;

-- Gaps
with numb AS
      (
       select case
                when numbers in (select seatnumber from seatingchart)
                  then null else numbers 
              end as numbers,
              numbers as anothernum
         from #tempo1
      ),
     startgap AS
      (
       select case
                when anothernum = (select min(numbers) from numb) and numbers is not null
                  then anothernum
                when numbers is null
                  then lead(numbers) over (order by anothernum)
              end as gapstart
         from numb
      ),
     endgap AS
      (
       select case
                --when anothernum = (select max(numbers) from numb) and numbers is not null
                --  then anothernum
                when numbers is null 
                  then lag(numbers) over (order by anothernum)
              end as gapend
         from numb
      )
    select t1.gapstart 'Gap Start', t2.gapend 'Gap End'
      from (select s.gapstart, 
                    ROW_NUMBER() over (order by gapstart) as joiner
              from startgap s) t1 full outer JOIN
           (select e.gapend, 
                    ROW_NUMBER() over (order by gapend) as joiner
              from endgap e
           ) t2
        on t1.joiner = t2.joiner
     where t1.gapstart is not null and t2.gapend is not null;

-- Total Missing Numbers
with cte AS
      (
       select numbers from #tempo1
       EXCEPT
       select seatnumber from seatingchart
      )
    select count(*) as 'Total Missing Numbers' from cte;

-- Evens & odds
select 'Even Numbers' 'Type', 
       sum(case 
           when seatnumber % 2 = 0 then 1
           else 0
           END) 'Count'
  from seatingchart
union all
select 'Odd Numbers', 
       sum(case 
           when seatnumber % 2 != 0 then 1
           else 0
           END)
  from seatingchart;

-- Puzzle #19
select StartDate, EndDate from TimePeriods
EXCEPT
select a.StartDate, a.EndDate
  from TimePeriods a join TimePeriods b
    on b.EndDate > a.StartDate and b.EndDate < a.EndDate
EXCEPT
select b.StartDate, b.EndDate
  from TimePeriods a join TimePeriods b
    on b.EndDate > a.StartDate and b.EndDate < a.EndDate
UNION
select a.StartDate, b.EndDate
  from TimePeriods a join TimePeriods b
    on b.StartDate > a.StartDate and b.StartDate < a.EndDate

-- Puzzle #20
select productid, unitprice, effectivedate
  from ValidPrices a 
  join (select max(effectivedate) maxdate
          from ValidPrices
         group by productid) b
    on a.effectivedate = b.maxdate;

-- Puzzle #21
with cte AS
        (
         select CustomerID, state, orderdate, avg(amount) over (partition by customerid) as avg_amount
           from orders
        ),
     cte2 as
        (
         select CustomerID, orderdate, state, avg(avg_amount) over (partition by orderdate) as average
           from cte
        )
    select CustomerID, average, orderdate, state
      from cte2
     where average > 100
     group by customerid, average, orderdate, state;

-- Puzzle #22
with cte AS
      (
       select WorkFlow, logmessage, occurrences, 
              rank() over (PARTITION by logmessage order by occurrences desc) as occ_rank
         from ProcessLog
      )
    select WorkFlow, logmessage
      from cte
     where occ_rank = 1
     order by WorkFlow;

-- Puzzle #23
select *, case 
            when score > percentile_cont(0.5) within group (order by score) over ()
              then 1
            else 2
          end as halfs
  from PlayerScores
 order by score desc;

-- Puzzle #24
with cte_a AS
        (
         select rowid, 1 as nums from sampledata
        ),
     cte_b as
        (
         select rowid, nums,
                ROW_NUMBER() over (order by rowid) as numbers 
           from cte_a
        )
    select rowid, numbers 
      from cte_b
     where numbers between 10 and 20;

-- Puzzle #25
with cte_a as 
        (
         select OrderID, customerid, ordercount,
                rank() over (partition by customerid order by ordercount desc) as rn
           from orders
        ),
     cte_b as
        (
         select *
           from cte_a
          where rn = 1
        )
    select o.CustomerID, vendor
      from orders o join cte_b b
        on o.OrderID = b.OrderID;

-- Puzzle #26
with cte1 as 
        (
         select year, sum(amount) as sum_amount 
           from Sales
          group by year
        ),
     cte2 AS
        (
         select [2019], [2020], [2021], [2022]
           from (
         select year, format(cast(sum_amount as decimal), 'c', 'en-US') as amount
           from cte1
         ) as st
         PIVOT
         ( max(amount)
           for year in ([2019], [2020], [2021], [2022])
         ) as pt
        )
     select *
       from cte2;

-- Puzzle #27
with cte AS
        (
         select IntegerValue, ROW_NUMBER() over (partition by integervalue order by integervalue) as ranks 
           from SampleData
        ),
     cte2 AS
        (
         select IntegerValue, ranks 
           from cte
          where ranks > 1
        )
     delete from cte2;

select * from SampleData;

-- Puzzle #28
select rownumber, 
       max(testcase) over (order by rownumber) as tc_without_gaps 
  from gaps;

select rownumber, max(testcase) over (partition by tc_numbers) as tc_without_gaps
from (
      select rownumber, testcase, 
             count(testcase) over (order by rownumber) as tc_numbers 
        from gaps
     ) as t1;

-- Puzzle #29
with cte_a AS
        (
         select StepNumber, TestCase, [Status],
                lag([status]) over (order by stepnumber) as lag_status
           from groupings
        ),
     cte_b as
        (
         select StepNumber, TestCase, [Status], lag_status,
                sum(case 
                      when [status] = lag_status
                        then 0
                      else 1
                    end) over (order by stepnumber) as lagsum
           from cte_a
        ),
     cte_c as
        (
         select min(StepNumber) over (partition by lagsum) as minstep, 
                max(StepNumber) over (partition by lagsum) as maxstep, 
                [Status], lagsum
           from cte_b
          group by [Status], lagsum, StepNumber
        )
    select minstep 'Min Step Number', maxstep 'Max Step Number', 
           [Status], count(lagsum) 'Consecutive Count'
      from cte_c
     group by minstep, maxstep, [Status];

-- Puzzle #30
select * from Products;
alter table products add somecolumn as (0/0);

-- Puzzle #31
with cte as
        (
         select *, 
                ROW_NUMBER() over (order by integervalue desc) as rn
           from SampleData
        )
    select * from cte
     where rn = 2;

select *
  from (
        select *, 
               ROW_NUMBER() over (order by integervalue desc) as rn
          from SampleData
       ) t1
 where rn = 2;

-- Puzzle #32
with cte AS
        (
         select spacemanid
           from personel
          where missioncount in (select min(missioncount) over (partition by jobdescription) as 'Least Experienced'
                                   from personel)
        ),
     cte2 AS
        (
         select spacemanid
           from personel
          where missioncount in (select max(missioncount) over (partition by jobdescription) as 'Most Experienced'
                                   from personel)
        ),
     cte3 AS
        (
         select p.jobdescription, c1.spacemanid
           from personel p join cte c1
             on p.spacemanid = c1.spacemanid
        ),
     cte4 AS
        (
         select p.jobdescription, c2.spacemanid
           from personel p join cte2 c2
             on p.spacemanid = c2.spacemanid
        )
    select c3.jobdescription, c3.spacemanid as 'Least Experienced', c4.spacemanid as 'Most Experienced'
      from cte3 c3 join cte4 c4
        on c3.jobdescription = c4.jobdescription;

-- Puzzle #33
with cte AS
        (
         select productid,
                max(DaysToManufacture) as maxs
           from ManufacturingTimes
          group by ProductID
        )
    select o.OrderID, o.ProductID
      from OrderFulfillments o join cte c
        on o.ProductID = c.ProductID
     where o.DaysToBuild >= c.maxs;

select o.OrderID, o.ProductID
  from OrderFulfillments o 
  join (select productid,
               max(DaysToManufacture) as maxs
          from ManufacturingTimes
         group by ProductID
       ) p
    on o.ProductID = p.ProductID
 where o.DaysToBuild >= p.maxs;

-- Puzzle #34
select * from Orders
EXCEPT
select * from Orders
 where CustomerID = 1001
       and Amount = 50;

-- Puzzle #35
select salesrepid 
  from Orders
 group by salesrepid
having count(*) < 2;

with cte_a AS
        (
         select * from Orders
          where salestype = 'International'
        ),
     cte_b AS
        (
         select * from Orders
          where salestype = 'Domestic'
        ),
     cte_c AS
        (
         select a.invoiceid, a.salesrepid, a.amount, a.salestype
           from cte_a a join cte_b b
             on a.salesrepid = b.salesrepid
         union ALL
         select b.invoiceid, b.salesrepid, b.amount, b.salestype
           from cte_a a join cte_b b
             on a.salesrepid = b.salesrepid
        )
     select * from orders
     EXCEPT
     select * from cte_c;

-- Puzzle #36
with cte1 as
        (
         select b.DepartureCity bDepartureCity, b.ArrivalCity bArrivalCity, 
                a.DepartureCity aDepartureCity, a.ArrivalCity aArrivalCity, 
                b.cost bcost, a.Cost acost
           from Graph a join graph b
             on a.DepartureCity = b.ArrivalCity and 
                b.DepartureCity <> a.ArrivalCity
        ),
     cte2 AS
        (
         select b.bDepartureCity bDepartureCity1, b.bArrivalCity bArrivalCity1, 
                b.aDepartureCity aDepartureCity2, b.aArrivalCity aArrivalCity2,
                a.aDepartureCity aDepartureCity3, a.aArrivalCity aArrivalCity3,
                b.bcost bcost1, b.acost acost2, a.acost acost3
           from cte1 a right join cte1 b
             on a.bDepartureCity = b.aDepartureCity or
                a.bArrivalCity = b.aArrivalCity
          where a.aDepartureCity is not null
        )
    select distinct a.bDepartureCity1, a.bArrivalCity1, 
           a.aDepartureCity2, a.aArrivalCity2,
           b.aDepartureCity3, b.aArrivalCity3,
           a.bcost1 + a.acost2 + case when b.acost3 is null then 0 else b.acost3 end sumcost
      from cte2 a left join cte2 b
        on a.aArrivalCity2 = b.aDepartureCity3;

with cte1 as
        (
         select b.DepartureCity bDepartureCity, b.ArrivalCity bArrivalCity, 
                a.DepartureCity aDepartureCity, a.ArrivalCity aArrivalCity, 
                b.cost bcost, a.Cost acost
           from Graph a join graph b
             on a.DepartureCity = b.ArrivalCity and 
                b.DepartureCity <> a.ArrivalCity
        )
    select bDepartureCity, bArrivalCity, 
           aDepartureCity, aArrivalCity, 
           b.DepartureCity, b.ArrivalCity,
           bcost + acost + case when b.cost is null then 0 else b.cost end sumcost
      from cte1 a left join graph b
        on a.aArrivalCity = b.DepartureCity 
     where a.bDepartureCity = 'Austin';

-- Puzzle #37
select *, 
       dense_rank() over (order by distributor, facility, zone) as criteriaid
  from groupcriteria;

-- Puzzle #38
with cte1 as 
        (
         select Region, Distributor, Sales
           from RegionSales
          WHERE Distributor = 'ACE'
        ),
     cte2 as 
        (
         select Region, Distributor, Sales
           from RegionSales
          WHERE Distributor = 'ACME'
        ),
     cte3 as 
        (
         select Region, Distributor, Sales
           from RegionSales
          WHERE Distributor = 'Direct Parts'
        ),
     cte4 AS
        (
         select b.Region, Distributor, Sales
           from cte1 a right join (select distinct Region
                                   from RegionSales) b
             on a.Region = b.Region
        ),
     cte5 AS
        (
         select b.Region, Distributor, Sales
           from cte2 a right join (select distinct Region
                                   from RegionSales) b
             on a.Region = b.Region
        ),
     cte6 AS
        (
         select b.Region, Distributor, Sales
           from cte3 a right join (select distinct Region
                                   from RegionSales) b
             on a.Region = b.Region
        )
    select Region, case
                     when Distributor is null  
                       then (select top 1 Distributor from cte4 where Distributor is not null)
                     else Distributor
                   end Distributor, case 
                                      when Sales is null
                                        then 0
                                      else Sales
                                    end Sales 
      from cte4
    union ALL
    select Region, 
           case
             when Distributor is null  
               then (select top 1 Distributor from cte5 where Distributor is not null)
             else Distributor
           end Distributor, 
           case 
             when Sales is null
               then 0
             else Sales
           end Sales 
      from cte5
    union ALL
    select Region, 
           case
             when Distributor is null  
               then (select top 1 Distributor from cte6 where Distributor is not null)
             else Distributor
           end Distributor, 
           case 
             when Sales is null
               then 0
             else Sales
           end Sales
      from cte6;

-- Puzzle #39
select pn as 'Prime Numbers'
  from (
        select case 
                 when integervalue % 2 <> 0 and integervalue % 3 <> 0 and integervalue > 1 or integervalue = 2 or integervalue = 3
                   then integervalue
               end as pn
          from SampleData
       ) t
 where pn is not null;

-- Puzzle #40
with cte1 AS
        (
         select city, row_number() over (order by city) as numbers
           from sortorder
        ),
     cte2 AS
        (
         select city, numbers
           from cte1
          where numbers % 2 = 0
        ),
     cte3 AS
        (
         select city, numbers
           from cte1
          where numbers % 2 <> 0
        )
    select city
      from cte2
    UNION all
    select city
      from cte3;

-- Puzzle #41 ???
with cte AS
      (
       select associate1, row_number() over (order by (select null)) rn1
         from Associates
       union
       select associate2, row_number() over (order by (select null)) rn2
         from Associates
      )
    select distinct Associate1, 
           case when rn1 < 5 then 1 else 2 end [number]
      from cte;

with cte1 AS
      (
       select associate1, LEFT(Associate1, 1) lft1,
              CHAR(64 + row_number() over (order by (select null))) Letters
         from Associates
        group by Associate1
      ),
     cte2 AS
      (
       select associate2, LEFT(Associate2, 1) lft2,
              CHAR(64 + row_number() over (order by (select null))) Letters
         from Associates
        group by Associate2
      ),
     cte3 AS
      (
       select associate1,
              case
                when lft1 = Letters
                  then 1
                else 2
              end [grouping]
         from cte1
      ),
     cte4 AS
      (
       select associate2,
              case
                when lft2 = lead(Letters) over (order by (select null))
                  then 1
                else 2
              end [grouping]
         from cte2
      )
    select * from cte3
    union
    select * from cte4;

with cte1 AS
      (
       select associate1, LEFT(Associate1, 1) lft1,
              CHAR(64 + row_number() over (order by (select null))) Letters,
              case
                when LEFT(Associate1, 1) in (select CHAR(64 + row_number() over (order by (select null))) 
                                               from Associates 
                                              group by Associate1)
                  then 1
                else 2
              end [grouping]
         from Associates
        group by Associate1
      ),
     cte2 AS
      (
       select associate2, LEFT(Associate2, 1) lft2,
              CHAR(64 + row_number() over (order by (select null))) Letters,
              case
                when LEFT(Associate2, 1) in (select CHAR(64 + row_number() over (order by (select null))) 
                                               from Associates 
                                              group by Associate2)
                  then 1
                else 2
              end [grouping]
         from Associates
        group by Associate2
      )
    select associate1, [grouping] from cte1
    union
    select associate2, [grouping] from cte2;

-- Puzzle #42
with cte1 AS
      (
       select a.Friend1, a.Friend2
         from Friends a join Friends b
           on a.Friend1 = b.Friend2
       union all
       select b.Friend1, a.Friend2
         from Friends a join Friends b
           on a.Friend1 = b.Friend2
       union all
       select b.Friend1, b.Friend2
         from Friends a join Friends b
           on a.Friend1 = b.Friend2
      ),
     cte2 as
      (
       select Friend1, Friend2 from Friends
       EXCEPT
       select Friend1, Friend2 from cte1
      )
    select Friend1, Friend2, count(*) 'Mutual Friends' from cte1
    group by Friend1, Friend2
    union
    select Friend1, Friend2, 0 mf from cte2;

-- Puzzle #43
select [order], customerid, quantity, 
       min(quantity) over (partition by customerid order by [order]) as Min_Value
  from CustomerOrders;

-- Puzzle #44
with cte AS
        (
         select customerid, balancedate startdate, amount,
                cast(cast(lag(balancedate) over (partition by customerid order by balancedate desc) as datetime) - 1 as date) enddatelag
           from Balances
        )
    select customerid, startdate, 
           case
             when enddatelag is null
               then '9999-12-31'
             else enddatelag
           end enddate, 
           amount
      from cte;

-- Puzzle #45
select --a.CustomerID, a.StartDate, a.EndDate, a.Amount,
       b.CustomerID, b.StartDate, b.EndDate, b.Amount
  from Balances a join Balances b
    on a.StartDate > b.StartDate and a.StartDate < b.EndDate
 group by b.CustomerID, b.StartDate, b.EndDate, b.Amount;

-- Puzzle #46
with cte_a AS
        (
         select accountid, count(case when balance < 0 then 1 end) count_balance
           from AccountBalances
          group by accountid
        ),
     cte_b AS
        (
         select accountid, count(accountid) count_account
           from AccountBalances
          group by accountid
        )
    select b.accountid 
      from cte_a a join cte_b b
        on a.count_balance = b.count_account and a.accountid = b. accountid;

-- Puzzle #47
with cte1 AS
        (
         select scheduleid, 'Work' activityname, starttime, null endtime from Schedule where ScheduleId = 'B'
         union all
         select scheduleid, 'Work' activityname, null starttime, endtime from Schedule
         union all
         select scheduleid, activityname, starttime, endtime from Activity
         union all
         select scheduleid, activityname,  
                newstarttime, newendtime 
           from (
             select scheduleid, 'Work' activityname,
                    lag(EndTime) over (partition by scheduleid order by endtime) newstarttime, 
                    starttime newendtime 
               from Activity
           ) t1
          where newstarttime is not null
        )
         select scheduleid, activityname, 
                case 
                  when starttime is null 
                    then lag(endtime) over (partition by scheduleid order by endtime) 
                  else StartTime 
                end 'Start Time', 
                case 
                  when endtime is null 
                    then lead(starttime) over (partition by scheduleid order by starttime) 
                  else endtime 
                end 'End Time'
           from cte1
          order by ScheduleId, 'End Time'

-- Puzzle #48
with cte1 AS
        (
         select salesid, year, rank() over (partition by salesid order by year desc) rn 
           from Sales
        ),
     cte2 AS
        (
         select salesid, year, rn
           from cte1
          where year = datepart(year from CURRENT_TIMESTAMP) and rn = 1 
        ),
     cte3 AS
        (
         select salesid, year, rn
           from cte1
          where year = datepart(year from CURRENT_TIMESTAMP) - 1 and rn = 2
        ),
     cte4 AS
        (
         select salesid, year, rn
           from cte1
          where year = datepart(year from CURRENT_TIMESTAMP) - 2 and rn = 3
        )
    select a.salesid
      from cte2 a 
      join cte3 b
        on a.SalesID = b.SalesID
      join cte4 c
        on a.SalesID = c.SalesID

-- Puzzle #49
with cte AS
        (
         select name, Weight, LineOrder,
                sum(Weight) over (order by lineorder) sumofweight
           from ElevatorOrder
        )
    select top 1 name
      from cte
     where sumofweight < 2000
     order by sumofweight desc;

-- Puzzle #50 -- summing don't work correctly
with cte1 as
        (     -- table with scores column
         select batterid, pitchnumber, result, 0 as scores
           from Pitches
        ),
     cte2 AS
        (     -- adding scores to scores1 & scores2 columns
         select batterid, pitchnumber, result, scores,
                case
                  when result = 'Ball' then 1
                  else scores
                end scores1,
                case
                  when result = 'Foul' or result = 'Strike' then 1
                  else scores
                end scores2
           from cte1
        ),
      cte3 AS
        (     -- sum of each scores1 & scores2 columns
         select batterid, pitchnumber, result, scores, 
                sum(scores1) over (partition by batterid order by pitchnumber) sumscores1,
                sum(scores2) over (partition by batterid order by pitchnumber) sumscores2
           from cte2
        ),
      cte4 as
        (     -- adding lagscores1 & lagscores2 columns
         select batterid, pitchnumber, result, scores,
                lag(sumscores1) over (partition by batterid order by batterid) lagscores1,
                lag(sumscores2) over (partition by batterid order by batterid) lagscores2,
                sumscores1, sumscores2
           from cte3
        ),
      cte5 AS
        (     -- add cases for lagscores1 & lagscores2 columns
         select batterid, pitchnumber, result, scores,  
                case 
                  when lagscores1 is null then 0
                  else lagscores1
                end lagscores1,
                case 
                  when lagscores2 is null then 0
                  else lagscores2
                end lagscores2, sumscores1, sumscores2
           from cte4
        ),
      cte6 as
        (     -- cast as varchar lagscores1 & lagscores2 columns
         select batterid, pitchnumber, result, scores, 
                cast(lagscores1 as varchar) + ' - ' + cast(lagscores2 as varchar) scr1,
                cast(sumscores1 as varchar) + ' - ' + cast(sumscores2 as varchar) scr2
           from cte5
        )
      select batterid, pitchnumber, result, scr1 'Start Of Pitch Count',
             case
               when result = 'In Play' then 'In Play'
               else scr2
             end 'END Of Pitch Count'
      from cte6;

-- Puzzle #51 ???
DROP TABLE IF EXISTS Assembly;
GO

CREATE TABLE Assembly
(
AssemblyID  INTEGER,
Part        VARCHAR(100),
PRIMARY KEY (AssemblyID, Part)
);
GO

INSERT INTO Assembly VALUES
(1001,'Bolt'),(1001,'Screw'),(2002,'Nut'),
(2002,'Washer'),(3003,'Toggle'),(3003,'Bolt');
GO

alter table dbo.assembly 
add hashbytes_key_of_part as HASHBYTES('SHA2_256', part),
    checksum_key as checksum(assemblyid, part);

select * from assembly;

-- Puzzle #52
DROP TABLE IF EXISTS Phone_Numbers;
GO

CREATE TABLE Phone_Numbers
(
CustomerID INTEGER,
Phone_Number VARCHAR(100),
PRIMARY KEY (CustomerID, Phone_Number),
constraint Number_Checker CHECK (Phone_Number like '([0-9][0-9][0-9])-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]')
);
GO

INSERT INTO Phone_Numbers VALUES
(1001,'(999)-999-9999'),
(2002,'(999)-999-9999'),
(3003,'(999)-999-9999');
GO

select * from Phone_Numbers;

-- Puzzle #53
with cte1 AS
        (
         select a.primaryid primaryid1, a.spouseid spouseid1, 
                b.primaryid primaryid2, b.spouseid spouseid2
           from Spouses a join spouses b
             on a.primaryid <> b.primaryid and a.spouseid <> b.spouseid
        ),
     cte2 AS
        (
         select distinct a.primaryid1, a.spouseid1, 
                b.primaryid2, b.spouseid2
           from cte1 a join cte1 b
             on a.spouseid1 = b.primaryid2 and a.primaryid1 = b.spouseid2
        ),
     cte3 AS
        (
         select primaryid1, spouseid1, 
                primaryid2, spouseid2,
                row_number() over (order by primaryid1) rn
           from cte2
        ),
     cte4 AS
        (
         select rn, primaryid1, spouseid1
           from cte3
         union
         select rn, primaryid2, spouseid2
           from cte3
        ),
     cte5 AS
        (
         select rn, primaryid1, spouseid1, 
                count(primaryid1) over (partition by primaryid1 order by rn) count_primaryid
           from cte4
        )
    select rn 'Group ID', primaryid1 'Primary ID', spouseid1 'Spouse ID'
      from cte5
     where count_primaryid = 1
     order by rn;

-- Puzzle #54
with cte1 AS
        (
         select distinct a.ticketid, 
                count(a.ticketid) over (partition by a.ticketid order by a.ticketid) ticket_count
           from LotteryTickets a join WinningNumbers b 
             on a.number = b.number
        ),
     cte2 AS
        (
         select ticketid, ticket_count,
                case 
                  when ticket_count = (select count(number) number_count from WinningNumbers)
                    then 100
                  when ticket_count > 1 and ticket_count < (select count(number) number_count from WinningNumbers)
                    then 10
                end winning
           from cte1
        )
    select format(sum(winning), 'c', 'en-US') total_winning
      from cte2;

-- Puzzle #55
with cte1 AS
        (
         select a.productname, a.quantity --, b.productname, b.quantity
           from productsa a join productsb b
             on a.productname = b.productname and a.quantity = b.quantity
        ),
     cte2 AS
        (
         select a.productname, a.quantity --, b.productname, b.quantity
           from productsa a full outer join productsb b
             on a.productname = b.productname
          where b.productname is null
        ),
     cte3 AS
        (
         select --a.productname, a.quantity, 
                b.productname, b.quantity
           from productsa a full outer join productsb b
             on a.productname = b.productname
          where a.productname is null
        ),
     cte4 AS
        (
         select a.productname, a.quantity --, b.productname, b.quantity
           from productsa a join productsb b
             on a.productname = b.productname and a.quantity <> b.quantity
        ),
     cte5 AS
        (
         select productname, quantity from cte1
         union
         select productname, quantity from cte2
         union
         select productname, quantity from cte3
         union
         select productname, quantity from cte4
        )
    select productname,
           case 
             when productname in (select productname from cte1)
               then 'Matches In both tables'
             when productname in (select productname from cte2)
               then 'Product does not exist in table B'
             when productname in (select productname from cte3)
               then 'Product does not exist in table A'
             when productname in (select productname from cte4)
               then 'Quantity is table A and table B do not match'
           end [type]
      from cte5;

-- Puzzle #56
with cte AS
        (
         select 1 as num
         union ALL
         select num + 1
           from cte
          where num < 10
        )
    select num [number]
      from cte;

-- Puzzle #57
with cte1 as
        (
         select value, 2 qid
           from string_split((select top 1 string from strings order by string), ' ')
         union all
         select value, 1 qid
           from string_split((select top 1 string from strings order by string desc), ' ')
        ),
     cte2 AS
        (
         select ROW_NUMBER() over (partition by b.string order by quoteid) rownumber,
                b.quoteid, b.string, [value] word
           from cte1 a join strings b
             on a.qid = b.quoteid
        )
    select rownumber, quoteid, string, word, 
           --sum(len(word)) over (partition by quoteid order by rownumber) sums,
           CHARINDEX(word, string, len(word)) starts, 
           CHARINDEX(' ', string, CHARINDEX(word, string, len(word))) position,
           count(rownumber) over (partition by quoteid order by quoteid) - 1 totalspaces
      from cte2;

-- Puzzle #58
    -- create temporary table
IF OBJECT_ID('#tempo') IS NULL 
drop table #tempo

select equation, totalsum
  into #tempo
  from Equations

select * from #tempo;

    -- variables & cursor declaration 
DECLARE @equation nvarchar(max), 
        @medium FLOAT, 
        @result nvarchar(max),
        @result2 nvarchar(max)

IF (CURSOR_STATUS('global','db_cursorexp')) = -3
BEGIN
    DECLARE db_cursorexp CURSOR FOR
    select Equation
      from #tempo
END

OPEN db_cursorexp

FETCH NEXT FROM db_cursorexp INTO @equation
    -- while loop and data fetching
while ( @@FETCH_STATUS = 0 )
begin

    set @result = (select equation from #tempo where Equation = @equation)
    set @result2 = 'set @medium = ' + @result

    exec sp_executesql @result2, N'@medium float output', @medium out

    --select @medium

    update #tempo
       set TotalSum = @medium
     where Equation = @equation

    FETCH NEXT FROM db_cursorexp INTO @equation

end;

CLOSE db_cursorexp;

DEALLOCATE db_cursorexp;
