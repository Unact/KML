create or replace function dbo.kmlStyle(in @url long varchar, in @callType integer default 0)
returns xml
begin
    declare @result xml;
    
    declare local temporary table #style(id integer,
                                         name varchar(128),
                                         lineColor varchar(64),
                                         lineWidth integer default 3,
                                         iconColor varchar(64),
                                         iconUrl long varchar,
                                         primary key(id));
                                         
    insert into #style with auto name
    select 0 as id,
          '7fff0000' as lineColor,
          '7fff0000' as iconColor,
          'http://maps.google.com/mapfiles/kml/paddle/blu-circle.png' as iconUrl
    union
    select 1, '7feaff7c', '7feaff7c', 'http://maps.google.com/mapfiles/kml/paddle/ltblu-circle.png'
    union
    select 2, '7f0000ff', '7f0000ff', 'http://maps.google.com/mapfiles/kml/paddle/red-circle.png'
    union 
    select 3, '7f141414','7f55ffff','http://maps.google.com/mapfiles/kml/paddle/ylw-circle.png'
    union
    select 4, '7f9b5fff', '7f9b5fff', 'http://maps.google.com/mapfiles/kml/paddle/pink-circle.png'
    union          
    select 5, '7fff5474', '7fff5474', 'http://maps.google.com/mapfiles/kml/paddle/purple-circle.png'
    union
    select 6, '7f080808', '7fffffff', 'http://maps.google.com/mapfiles/kml/paddle/wht-circle.png';
    
    insert into #style with auto name
    select 99 as id,
           'Storage' as name,
           '7fff0000' as lineColor,
           '7fff0000' as iconColor,   
           'http://maps.google.com/mapfiles/kml/pal4/icon6.png' as iconUrl
     union
    select 100,
           'RouteBegin0',
           '7fff0000',
           '7fff0000',   
           'http://maps.google.com/mapfiles/kml/pushpin/blue-pushpin.png'
     union
    select 101,
           'RouteBegin1',
           '7feaff7c',
           '7feaff7c',   
           'http://maps.google.com/mapfiles/kml/pushpin/ltblu-pushpin.png'
      union
    select 102,
           'RouteBegin2',
           '7f0000ff',
           '7f0000ff',   
           'http://maps.google.com/mapfiles/kml/pushpin/red-pushpin.png'
     union    
    select 103,
           'RouteBegin3',
           '7f141414',
           '7f141414',   
           'http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png'
     union    
    select 104,
           'RouteBegin4',
           '7f9b5fff',
           '7f9b5fff',   
           'http://maps.google.com/mapfiles/kml/pushpin/pink-pushpin.png'           
     union    
    select 105,
           'RouteBegin5',
           '7fff5474',
           '7fff5474',   
           'http://maps.google.com/mapfiles/kml/pushpin/purple-pushpin.png'           
     union    
    select 106,
           'RouteBegin6',
           '7f080808',
           '7fffffff', 
           'http://maps.google.com/mapfiles/kml/pushpin/wht-pushpin.png'
     union          
    select 200, 'RouteEnd0', '7fff0000', '7fff0000','http://maps.google.com/mapfiles/kml/paddle/blu-stars.png'
    union
    select 201, 'RouteEnd1', '7feaff7c', '7feaff7c', 'http://maps.google.com/mapfiles/kml/paddle/ltblu-stars.png'
    union
    select 202, 'RouteEnd2', '7f0000ff', '7f0000ff', 'http://maps.google.com/mapfiles/kml/paddle/red-stars.png'
    union 
    select 203, 'RouteEnd3', '7f141414','7f55ffff','http://maps.google.com/mapfiles/kml/paddle/ylw-stars.png'
    union
    select 204, 'RouteEnd4', '7f9b5fff', '7f9b5fff', 'http://maps.google.com/mapfiles/kml/paddle/pink-stars.png'
    union          
    select 205, 'RouteEnd5', '7fff5474', '7fff5474', 'http://maps.google.com/mapfiles/kml/paddle/purple-stars.png'
    union
    select 206, 'RouteEnd6', '7f080808', '7fffffff', 'http://maps.google.com/mapfiles/kml/paddle/wht-stars.png';
    
    set @result = (select xmlagg(xmlelement('Style', xmlattributes(isnull(name,'Style'+cast(id as varchar(12))) as "id")
                                                   , xmlelement('IconStyle', xmlelement('color',iconColor)
                                                                           , xmlelement('colorMode','normal')
                                                                           , xmlelement('Icon',xmlelement('href',iconUrl)))

                                                   , xmlelement('LineStyle', xmlelement('color',lineColor)
                                                                           , xmlelement('colorMode','normal')
                                                                           , xmlelement('width',lineWidth))
                                                                            ))
                     from #style);
                     
    if @callType = 0 then
        set @result = dbo.KMLRootTag(@result);
    end if;

    return @result;

end
;