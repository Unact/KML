create or replace function dbo.KMLRoute()
returns xml
begin
    declare @result xml;
    declare @placemarks xml; 
    declare @route xml;
    declare @trkName xml;
    declare @description xml;
    declare @style xml;
    
    set @trkName = (select name from dbo.palm_Salesman where salesman_id = @salesman_id) + ' '
                 + cast(date(@ddate) as varchar(10));
                 
    set @description = cast('<![CDATA['
                     +'<br>'
                     +'<font color="red">'
                     +'Начало: '+cast(cast((select min(ts) from #tracking) as time) as varchar(5))
                     +'</font>'+'<br>'
                     + '<font color="blue">'
                     +'Конец: '+cast(cast((select max(ts) from #tracking) as time) as varchar(5))
                     +'</font>'+'<br>'
                     +'<font color="green">'
                     +'Заказов: '+ cast((select sum(orderCnt) from #waypoint) as varchar(12))
                     +'</font>'+'<br>'
                     +'<font color="purple">'
                     +'На сумму: '+ cast((select sum(orderSumm) from #waypoint) as varchar(12))
                     +'<br><br>'
                     + ']]>' as xml);
    
    set @style = '';
    
    
    if exists (select * from #waypoint) then
        set @placemarks = (select xmlagg(xmlelement('Placemark', xmlelement('name', name)
                                                               , xmlelement('description',cast(
                                                                                         '<![CDATA['
                                                                                         +'<font size="2">'+address+'</font><br>'
                                                                                         +'<font color="red">'+ cast(cast(ts as time) as varchar(5))+'</font><br>'
                                                                                         + ' Заказов='+cast(orderCnt as varchar(12))
                                                                                         + ' сумма=' + cast(orderSumm as varchar(16))
                                                                                         + ']]>' as xml))
                                                                , xmlelement('gx:TimeStamp',xmlelement('when','2012-02-13'))
                                                                , xmlelement('Point', xmlelement('coordinates', cast(longitude as varchar(24))+','+cast(latitude as varchar(24))))) order by ts)
                      from #waypoint);
    end if;
     
    if exists (select * from #tracking) then              
        set @route = (select xmlelement('Placemark',xmlelement('name',@trkName)
                                                   ,xmlelement('LineString',xmlelement('coordinates', list(cast(longitude as varchar(24))+','+cast(latitude as varchar(24)),' ' order by ts))
                                                   ))
                      from #tracking);
    end if;
                  
    
    set @result = dbo.KMLRootTag( xmlelement('Document', xmlelement('name',@trkName)
                                                       , xmlelement('description',@description)
                                                       , @style, @placemarks, @route));

    return @result;
end
;


