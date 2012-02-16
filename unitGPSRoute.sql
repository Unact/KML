create or replace function dbo.unitGPSRoute()
returns xml
begin
    declare @result xml;
    declare @name varchar(128);
    declare @description xml;
    declare @refresh xml;
    declare @style xml;
    declare @href long varchar;
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
    
    set @description =  cast('<![CDATA['
                         +'<br>'
                         +'<font color="blue">'
                         +'Посещено точек: '+ cast(@buyerCnt as varchar(12))
                         +'</font>'+'<br>'
                         +'<font color="blue">'
                         +'Всего заказов: '+ cast(@orderCnt as varchar(12))
                         +'</font>'+'<br>'
                         +'<font color="purple">'
                         +'На сумму: '+ cast(@orderSumm as varchar(12))
                         +'<br><br>'
                         + ']]>' as xml);
              
    if @offset = 0  then
        set @refresh = xmlelement('refreshMode','onInterval')+xmlelement('refreshInterval',60);
    else
        set @refresh = xmlelement('refreshMode','onInterval')+xmlelement('refreshInterval',60000); 
    end if;
    
    for lloop as ccur cursor for select salesman_id as c_salesman_id,
                                        name as c_name
                                   from sales.salesman
                                  where salesman_group = @unit_id
    do
    
        set @href = 'https://asa0.unact.ru/kml/'+cast(c_salesman_id as varchar(12))
                  + '/' + cast(@offset as varchar(12));
    
        set @result = @result + xmlelement('NetworkLink', xmlelement('name', c_name)
                                                        , xmlelement('Link', @refresh
                                                                           , xmlelement('href', @href)));
                                                                           
    end for;
    
    set @result = dbo.KMLRootTag(xmlelement('Document', @style
                                                      , xmlelement('name',@name)
                                                      , xmlelement('description', @description)
                                                      , xmlelement('Placemark', xmlelement('name', 'Север')
                                                                              , xmlelement('description',cast('<![CDATA['
                                                                                         +'<font color="blue">'+'Склад "Север"'+'</font><br>'
                                                                                         + ']]>' as xml))
                                                                              , xmlelement('styleUrl','#Storage')
                                                                              , xmlelement('Point', xmlelement('coordinates', '37.501284,55.84291')))
                                                      , xmlelement('Placemark', xmlelement('name', 'Юг')
                                                                              , xmlelement('description',cast('<![CDATA['
                                                                                         +'<font color="blue">'+'Склад "Юг"'+'</font><br>'
                                                                                         + ']]>' as xml))
                                                                              , xmlelement('styleUrl','#Storage')  
                                                                              , xmlelement('Point', xmlelement('coordinates', '37.729269,55.472572')))
                                                      , @result));
    

    
    return @result;
    
end
;