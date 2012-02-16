create or replace function dbo.KMLRoute()
returns xml
begin
    declare @result xml;
    declare @placemarks xml; 
    declare @route xml;
    declare @tpName varchar(128);
    declare @trkName xml;
    declare @description xml;
    declare @style xml;
    declare @styleNumber integer;
    
    
    set @tpName = (select name from dbo.palm_Salesman where salesman_id = @salesman_id);
    set @trkName = @tpName + ' ' + cast(date(@ddate) as varchar(10));
    
    if exists(select * from #tracking) then             
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
                         
    end if;
    
    set @style = dbo.kmlStyle(null,1);
    set @styleNumber = mod((select count(*)
                              from sales.salesman
                             where salesman_group = (select salesman_group
                                                       from sales.salesman s
                                                      where id = @salesman_id)
                               and id <= @salesman_id),7);
    
    if exists (select * from #waypoint) then
        set @placemarks = (select xmlagg(xmlelement('Placemark', xmlelement('name', name)
                                                               , xmlelement('description',cast('<![CDATA['
                                                                                         +'<font size="2">'+address+'</font><br>'
                                                                                         +'<font color="red">'+ cast(cast(ts as time) as varchar(5))+'</font><br>'
                                                                                         + ' Заказов='+cast(orderCnt as varchar(12))
                                                                                         + ' сумма=' + cast(orderSumm as varchar(16))
                                                                                         + ']]>' as xml))
                                                                , xmlelement('styleUrl','#Style'+cast(@styleNumber as varchar(12)))
                                                                , xmlelement('Point', xmlelement('coordinates', cast(longitude as varchar(24))+','+cast(latitude as varchar(24))))) order by ts)
                      from #waypoint);
                      


    end if;
     
    if exists (select * from #tracking) then              
        set @route = (select xmlelement('Placemark', xmlelement('name',@trkName)
                                                   , xmlelement('styleUrl','#Style'+cast(@styleNumber as varchar(12)))
                                                   , xmlelement('LineString', xmlelement('coordinates', list(cast(longitude as varchar(24))+','+cast(latitude as varchar(24)),' ' order by ts)))
                                                                                                                        
                                                   )
                      from #tracking);
                      
        set @route = @route + (select top 1 xmlelement('Placemark', xmlelement('name','Начало маршрута')
                                                                  , xmlelement('description',cast('<![CDATA['
                                                                                                 +'Начало маршрута ТП '+ @tpName + ' '+ cast(cast(ts as time) as varchar(5))
                                                                                                 + ']]>' as xml))
                                                                  , xmlelement('styleUrl','#RouteBegin')
                                                                  , xmlelement('Point', xmlelement('coordinates', cast(longitude as varchar(24))+','+cast(latitude as varchar(24)))))
                                 from #tracking
                                order by ts)
                            + (select top 1 xmlelement('Placemark', xmlelement('name','Конец маршрута')
                                                                  , xmlelement('description',cast('<![CDATA['
                                                                                                 +'Конец маршрута ТП '+ @tpName + ' '+ cast(cast(ts as time) as varchar(5))
                                                                                                 + ']]>' as xml))
                                                                  , xmlelement('styleUrl','#RouteEnd')
                                                                  , xmlelement('Point', xmlelement('coordinates', cast(longitude as varchar(24))+','+cast(latitude as varchar(24)))))
                                 from #tracking
                                order by ts desc)
    end if;
                  
    
    set @result = dbo.KMLRootTag( xmlelement('Document', @style
                                                       , xmlelement('name',@trkName)
                                                       , xmlelement('description',@description)
                                                       , xmlelement('Folder', xmlelement('name','Торговые точки')
                                                                             ,@placemarks)
                                                       , xmlelement('Folder', xmlelement('name','Маршрут')
                                                                            , @route)));

    return @result;
end
;


