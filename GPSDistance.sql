create or replace function dbo.GPSDistance(in @lat1 decimal(13,10), in @lon1 decimal(13,10), in @lat2 decimal(13,10), in @lon2 decimal(13,10))
returns decimal(18,2)
begin
    declare @result decimal(18,2);
    declare @pi decimal(13,10);
    
    set @pi = 3.1415;
    
    set @result = sqrt(power((@lat2-@lat1)*111197,2)+power((@lon2-@lon1)*111197* cos(@lat1*@pi/180),2)); 
    
    
    return @result;
    
end
;