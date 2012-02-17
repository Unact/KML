create or replace function dbo.unitGPSRouteN()
returns xml
begin
    declare @result xml;
    declare @refresh xml;
    declare @href long varchar;
    declare @style xml;
    
    if @offset = 0  then
        set @refresh = xmlelement('refreshMode','onInterval')+xmlelement('refreshInterval',60);
    else
        set @refresh = xmlelement('refreshMode','onInterval')+xmlelement('refreshInterval',60000); 
    end if;
    
    set @style = dbo.kmlStyle(null,1);
    
    set @href = 'https://asa0.unact.ru/kml/n'+cast(@unit_id as varchar(12))+'/'+cast(@offset as varchar(12));
    
    set @result = xmlelement('NetworkLink', xmlelement('Link', @refresh
                                                             , xmlelement('href',@href)));
                                                             
    set @result = dbo.KMLRootTag(xmlelement('Document', @style
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