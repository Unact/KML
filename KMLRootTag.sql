create or replace function dbo.KMLRootTag(in @kml xml)
returns xml
begin
    declare @result xml;
    
    set @result = xmlelement('kml', xmlattributes('http://www.opengis.net/kml/2.2' as "xmlns"
                                                  ,'http://www.google.com/kml/ext/2.2' as "xmlns:gx")
                                                  ,@kml);
                                                  
     set @result = '<?xml version="1.0" encoding="utf-8"?>'+ csconvert(@result,'utf-8','windows-1251');
    
    return @result;
    
end
;
