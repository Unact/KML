create or replace function dbo.KMLRoute(in @salesman_id integer, in @callType integer default 0)
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
        set @description = cast('<div xmlns="http://www.w3.org/1999/xhtml">'
                         +'<ul>'
                         +'<li><font color="red">'
                         +'Начало: '+cast(cast((select min(ts) from #tracking) as time) as varchar(5))+' '
                         +'</font></li>'
                         + '<li><font color="blue">'
                         +'Конец: '+cast(cast((select max(ts) from #tracking) as time) as varchar(5))+' '
                         +'</font></li>'
                         +'<li><font color="green">'
                         +'Заказов: '+ cast((select sum(orderCnt) from #waypoint) as varchar(12))+' '
                         +'</font></li>'
                         +'<li><font color="purple">'
                         +'На сумму: '+ cast((select sum(orderSumm) from #waypoint) as varchar(12))+' '
                         +'</font></li>'
                         +'</ul>'
                         + '</div>' as xml);
                         
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
                                                               , xmlelement('description',cast('<div xmlns="http://www.w3.org/1999/xhtml">'
                                                                                         +'<div><font size="2">'+address+'</font></div>'
                                                                                         +'<div><font color="red">'+ cast(cast(ts as time) as varchar(5))+'</font></div>'
                                                                                         + '<ul>'
                                                                                         + '<li>Заказов='+cast(orderCnt as varchar(12))+'</li>'
                                                                                         + '<li>сумма=' + cast(orderSumm as varchar(16))+'</li>'
                                                                                         + '</ul>'
                                                                                         + '</div>' as xml))
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
                                                                  , xmlelement('description',cast('<div xmlns="http://www.w3.org/1999/xhtml">'
                                                                                                 +'Начало маршрута ТП '+ @tpName + ' '+ cast(cast(ts as time) as varchar(5))
                                                                                                 + '</div>' as xml))
                                                                  , xmlelement('styleUrl','#RouteBegin'+cast(@styleNumber as varchar(12)))
                                                                  , xmlelement('Point', xmlelement('coordinates', cast(longitude as varchar(24))+','+cast(latitude as varchar(24)))))
                                 from #tracking
                                order by ts)
                            + (select top 1 xmlelement('Placemark', xmlelement('name','Конец маршрута')
                                                                  , xmlelement('description',cast('<div xmlns="http://www.w3.org/1999/xhtml">'
                                                                                                 +'Конец маршрута ТП '+ @tpName + ' '+ cast(cast(ts as time) as varchar(5))
                                                                                                 + '</div>' as xml))
                                                                  , xmlelement('styleUrl','#RouteEnd'+cast(@styleNumber as varchar(12)))
                                                                  , xmlelement('Point', xmlelement('coordinates', cast(longitude as varchar(24))+','+cast(latitude as varchar(24)))))
                                 from #tracking
                                order by ts desc)
    end if;
               

    set @result = xmlelement(if @callType = 0 then 'Document' else 'Folder' endif, if @callType = 0 then @style else '' endif
                                                                                 , xmlelement('name',@trkName)
                                                                                 , xmlelement('description',@description)
                                                                                 , xmlelement('Folder', xmlelement('name','Торговые точки')
                                                                                                      , @placemarks)
                                                                                 , xmlelement('Folder', xmlelement('name','Маршрут')
                                                                                                      , @route));
    if @callType = 0 then
        set @result = dbo.KMLRootTag(@result);
    end if;

    return @result;
end
;


