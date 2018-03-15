create procedure dbo.testme @keyval int
as
	select (case when @keyval = 10 then 20 else 0 end) as fldVal