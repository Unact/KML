create or replace function dbo.KMLRoute()
returns xml
begin
    declare @result xml;
    declare @placemarks xml;
    declare @route xml;
    declare @trkName varchar(128);
    declare @description long varchar;
    declare @style xml;
    
    set @trkName = (select name from dbo.palm_Salesman where salesman_id = @salesman_id) + ' '
                 + cast(date(@ddate) as varchar(10));
                 
    set @description = 'какое-то описание пусть будет';
    
    set @style = '';
    
    
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
                  
    set @route = (select xmlelement('Placemark',xmlelement('name',@trkName)
                                               ,xmlelement('LineString',xmlelement('coordinates', list(cast(longitude as varchar(24))+','+cast(latitude as varchar(24)),' ' order by ts))
                                               ))
                  from #tracking);
                  
    
    set @result = xmlelement('kml', xmlattributes('http://www.opengis.net/kml/2.2' as "xmlns"
                                                  ,'http://www.google.com/kml/ext/2.2' as "xmlns:gx")
                                  , xmlelement('Document', xmlelement('name',@trkName)
                                                         , xmlelement('description',@description)
                                                         , @style, @placemarks, @route));

    set @result = '<?xml version="1.0" encoding="utf-8"?>'+ csconvert(@result,'utf-8','windows-1251');

    return @result;
end
;


