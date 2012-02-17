create or replace function dbo.mainGPSRoute(in @offset integer)
returns xml
begin
    declare @result xml;
    declare @style xml;

    --set @style = dbo.kmlStyle(null,1);
    
    
    for lloops as ccurs cursor for select distinct
                                          s.id as c_site_id,
                                          s.name as c_site_name
                                     from sales.salesman_group sg join dbo.site s on sg.site = s.id
                                    order by c_site_name
    do

        set @result = @result+ '<div><font size="4">'+c_site_name + '</font></div><ul>';
    
        for lloop as ccur cursor for select sg.id as c_id,
                                            sg.name as c_name
                                       from sales.salesman_group sg
                                      where site = c_site_id
                                      order by c_site_name, c_name
        do
            set @result = @result + '<li>'
                                  + '<a href="'
                                  + '?q='  
                                  + 'https://asa0.unact.ru/kml/b'+cast(c_id as varchar(12))+'/'+cast(@offset as varchar(12))+'">'
                                  + c_name
                                  + '</a></li>';
        end for;
        
        set @result = @result + '</ul>'
                                                    
    end for;
    
    set @result = dbo.KMLRootTag( xmlelement('Document', @style
                                                       , xmlelement('name', 'Работа ТП')
                                                       , xmlelement('description',cast('<div xmlns="http://www.w3.org/1999/xhtml">'
                                                                                  + '<div>'
                                                                                  +'<font size="4" color="blue">'
                                                                                  + 'Выберите бригаду'
                                                                                  + '</font>'
                                                                                  +'</div>'
                                                                                  + @result
                                                                                  + '</div>' as xml))));
    
    return @result;
    
end
;