create or replace function dbo.unitGPSRoute()
returns xml
begin
    declare @result xml;
    declare @name varchar(128);
    declare @description xml;
    declare @style xml;
    declare @orderCnt integer;
    declare @orderSumm decimal(18,2);
    declare @buyerCnt integer;
    
    set @name = (select name from sales.salesman_group where id = @unit_id)
              + cast(date(@ddate) as varchar(10));
              
    set @style = dbo.kmlStyle(null,1);
    
    select count(distinct b.id) as buyerCnt,
           count(*) as orderCnt,
           sum(totalCost) as orderSumm
      into @buyerCnt, @orderCnt, @orderSumm
      from dbo.pre_order o join dbo.buyers b on o.client = b.id
                           join dbo.partners p on b.partner = p.id
                           join dbo.palm_salesman s on o.salesman = s.salesman_id
                           left outer join dbo.placeunload pu on b.placeunload_id = pu.id
     where s.unit_id = @unit_id
       and o.cts >= @ddate
       and o.cts < @ddate + 1;
    
    set @description =  cast('<div xmlns="http://www.w3.org/1999/xhtml">'
                         +'<ul>'
                         +'<li><font color="blue">'
                         +'Посещено точек: '+ cast(@buyerCnt as varchar(12))
                         +'</font></li>'
                         +'<li><font color="blue">'
                         +'Всего заказов: '+ cast(@orderCnt as varchar(12))
                         +'</font></li>'
                         +'<li><font color="purple">'
                         +'На сумму: '+ cast(@orderSumm as varchar(12))
                         +'</font></li>'
                         +'</ul>'
                         + '</div>' as xml);

    
    for lloop as ccur cursor for select salesman_id as c_salesman_id,
                                        name as c_name
                                   from sales.salesman
                                  where salesman_group = @unit_id
    do
    
        set @result = @result + dbo.salesmanGPSRoute(c_salesman_id, 1);
                                                                           
    end for;
    
    set @result = dbo.KMLRootTag(xmlelement('Document', @style
                                                      , xmlelement('name',@name)
                                                      , xmlelement('description', @description)
                                                      , @result));
    

    
    return @result;
    
end
;