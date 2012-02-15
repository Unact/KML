create or replace function dbo.unitGPSRoute()
returns xml
begin
    declare @result xml;
    declare @name varchar(128);
    declare @description xml;
    declare @href long varchar;
    
    set @name = (select name from sales.salesman_group where id = @unit_id)
              + cast(date(@ddate) as varchar(10));
    
    for lloop as ccur cursor for select salesman_id as c_salesman_id,
                                        name as c_name
                                   from sales.salesman
                                  where salesman_group = @unit_id
    do
    
        set @href = 'https://asa0.unact.ru/kml/'+cast(c_salesman_id as varchar(12))
                  + '/' + cast(@offset as varchar(12));
    
        set @result = @result + xmlelement('NetworkLink', xmlelement('name', c_name)
                                                        , xmlelement('Link', xmlelement('refreshMode','onInterval')
                                                                           , xmlelement('refreshInterval',60)
                                                                           , xmlelement('href', @href)));
                                                                           
    end for;
    
    set @result = dbo.KMLRootTag(xmlelement('Document', xmlelement('name',@name)
                                                      , xmlelement('Placemark', xmlelement('name', 'Юг')
                                                                              , xmlelement('description',cast('<![CDATA['
                                                                                         +'<font color="blue">'+'Склад "Север"'+'</font><br>'
                                                                                         + ']]>' as xml))
                                                                              , xmlelement('Point', xmlelement('coordinates', '37.501284,55.84291')))
                                                      , xmlelement('Placemark', xmlelement('name', 'Юг')
                                                                              , xmlelement('description',cast('<![CDATA['
                                                                                         +'<font color="blue">'+'Склад "Юг"'+'</font><br>'
                                                                                         + ']]>' as xml))
                                                                              , xmlelement('Point', xmlelement('coordinates', '37.801208,55.468346')))
                                                      , @result));
    

    
    return @result;
    
end
;