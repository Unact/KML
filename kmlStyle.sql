create or replace function dbo.kmlStyle(in @url long varchar)
returns xml
begin
    declare @result xml;
    
    --declare
    
    set @result = 
  '<Style id="tpLS1">
    <LineStyle>
        <color>1f0000ff</color> 
        <colorMode>normal</colorMode> 
        <width>1</width>                          
    </LineStyle>
    </Style>
    <Style id="tpLS2">
    <LineStyle>
        <color>1f00ddff</color> 
        <colorMode>normal</colorMode> 
        <width>1</width>                          
    </LineStyle>
    </Style>
    <Style id = "IS1">
    <IconStyle>
  <color>ffffffff</color>  
  <colorMode>normal</colorMode>
  </IconStyle>
  </Style>';
    
    set @result = dbo.KMLRootTag(@result);
    

    return @result;

end
;