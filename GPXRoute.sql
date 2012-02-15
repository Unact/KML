create or replace function dbo.GPXRoute()
returns xml
begin
    declare @result xml;
    
    declare @trk xml;
    declare @wpt xml;
    declare @trkName varchar(128);
    declare @minlat decimal(13,10);
    declare @minlon decimal(13,10);
    declare @maxlat decimal(13,10);
    declare @maxlon decimal(13,10);
    declare @boundsShift decimal(13,10);
    
    set @wpt = (select xmlagg(xmlelement('wpt', xmlattributes(latitude as "lat", longitude as "lon")
                                              , xmlelement('name', name+'('+address+')')
                                              , xmlelement('desc', cast(cast(ts as time) as varchar(5))
                                                                  + ' Заказов='+cast(orderCnt as varchar(12))
                                                                  + ' сумма=' + cast(orderSumm as varchar(16)))) order by ts)
                  from #waypoint);
                                                                  
    set @trkName = (select name from dbo.palm_Salesman where salesman_id = @salesman_id) + ' '
                 + cast(date(@ddate) as varchar(10));
                 
    set @trk = (select xmlelement('trk',xmlelement('name',@trkName)
                                        ,xmlelement('trkseg'
                                            ,xmlagg(xmlelement('trkpt',xmlattributes(latitude as "lat", longitude as "lon")
                                                ,xmlelement('time',dbo.datetime2XML(ts))) order by ts)))
                  from #tracking);
                  

       
    -- bounds   
    set @boundsShift = 0.1;   
    set @minlat = lesser((select min(latitude) from #tracking), (select min(latitude) from #waypoint));
    set @minlon = lesser((select min(longitude) from #tracking), (select min(longitude) from #waypoint));
    set @maxlat = greater((select max(latitude) from #tracking), (select max(latitude) from #waypoint));
    set @maxlon = greater((select max(longitude) from #tracking), (select max(longitude) from #waypoint));
    

    set @result  = xmlelement('gpx', xmlattributes('http://www.topografix.com/GPX/1/1' as "xmlns",
                                                   'http://www.w3.org/2001/XMLSchema-instance' as "xmlns:xsi",
                                                   'CatSQL' as "creator",
                                                   '1.1' as "version",
                                                   'http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd' as "xsi:schemaLocation")
                                    , xmlelement('metadata', xmlelement('link', xmlattributes('https://system.unact.ru' as "href")
                                                                              , xmlelement('text','Salesman track collection'))
                                                           , xmlelement('time',dbo.datetime2XML(@ddate))
                                                           , xmlelement('bounds', xmlattributes(@minlat - @boundsShift as "minlat",
                                                                                                @minlon - @boundsShift as "minlon",
                                                                                                @maxlat + @boundsShift as "maxlat",
                                                                                                @maxlon + @boundsShift as "maxlon"))
                                                                                                )
                                    , @wpt, @trk);



    set @result = '<?xml version="1.0" encoding="utf-8"?>'+ csconvert(@result,'utf-8','windows-1251');

    return @result;

end
;