create or replace function dbo.kml(in @url long varchar)
returns xml
begin
    declare @result xml;
    declare @varName varchar(128);
    declare @varValue varchar(128);
    declare @i integer;
    
    create variable @salesman_id integer;
    create variable @unit_id integer;
    create variable @ddate datetime;
    create variable @offset integer;
    create variable @type varchar(64);

    set @varName = next_http_variable(null);                                        

    while @varName is not null loop
        set @varValue = http_variable(@varName);
        
        case @varName
            when 'salesman' then
                set @salesman_id = cast(@varValue as integer);
            when 'offset' then
                set @offset = cast(@varValue as integer);
            when 'type' then
                set @type = @varValue;
            when 'unit' then
                set @unit_id = cast(varValue as integer);
        end case;
        
        set @varName = next_http_variable(@varName);
        
    end loop;
    
    if length(@url)<>0 then
        set @i = locate(@url,'/');
        if @i<>0 then
            if isnumeric(left(@url,@i-1))=1 then
                set @salesman_id = cast(left(@url,@i-1) as integer);
            elseif left(@url,1) = 'b' and isnumeric(substring(left(@url,@i-1),2)) = 1 then
                set @unit_id = cast(substring(left(@url,@i-1),2) as integer);
            end if;
            if isnumeric(substring(@url,@i+1))=1 then
                set @offset = cast(substring(@url,@i+1) as integer);
            end if
        else
            if isnumeric(@url)=1 then
                set @salesman_id = cast(@url as integer);
            elseif left(@url,1) = 'b' and isnumeric(substring(@url,2)) = 1 then
                set @unit_id = cast(substring(@url,2) as integer);
            end if   
        end if;
    end if;
    

    if @offset is null then set @offset = 0 end if;
    if @type is null then set @type = 'kml' end if;
    
    set @ddate = today() - @offset;
    
    if @salesman_id is not null then
        set @result = dbo.salesmanGPSRoute();
    elseif @unit_id is not null then
        set @result = dbo.unitGPSRoute();
    end if;
    
    return @result;

end
;