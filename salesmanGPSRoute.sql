create or replace function dbo.salesmanGPSRoute(in @url long varchar)
returns xml
begin
    declare @offset integer;
    declare @type varchar(128);
    declare @varName varchar(128);
    declare @varValue varchar(128);
    declare @i integer;
    
    declare @result xml;
    
    create variable @salesman_id integer;
    create variable @ddate datetime;
    
    message 'dbo.salesmanGPSRoute @url =', @url;


    
    create local temporary table #tracking(latitude decimal(13,10),
                                           longitude decimal(13,10),
                                           ts datetime,
                                           accuracy decimal(18,2));
                                            
    create local temporary table #waypoint(buyer integer,
                                           name varchar(255),
                                           address varchar(1024),
                                           latitude decimal(13,10),
                                           longitude decimal(13,10),
                                           inRoute integer default 0,
                                           orderCnt integer default 0,
                                           orderSumm decimal(18,2) default 0,
                                           encCnt integer default 0,
                                           encSumm decimal(18,2) default 0,
                                           ts datetime,
                                           primary key(buyer));
                                            
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
        end case;
        
        set @varName = next_http_variable(@varName);
        
    end loop;
    
    if length(@url)<>0 then
        set @i = locate(@url,'/');
        if @i<>0 then
            if isnumeric(left(@url,@i-1))=1 then
                set @salesman_id = cast(left(@url,@i-1) as integer);
            end if;
            if isnumeric(substring(@url,@i+1))=1 then
                set @offset = cast(substring(@url,@i+1) as integer);
            end if
        else
            if isnumeric(@url)=1 then
                set @salesman_id = cast(@url as integer);
            end if   
        end if;
    end if;
    

    if @offset is null then set @offset = 0 end if;
    if @type is null then set @type = 'kml' end if;
    
    set @ddate = today() - @offset;
    

    -- route

       
    insert into #waypoint with auto name   
    select p.id as buyer,
           p.name as name,
           min(b.loadto) as address,
           count(*) as orderCnt,
           sum(totalCost) as orderSumm,
           max(device_ts) as ts,
           isnull(ga.latitude,pu.latitude) as latitude,
           isnull(ga.longitude,pu.longitude) as longitude
      from dbo.pre_order o join dbo.buyers b on o.client = b.id
                           join dbo.partners p on b.partner = p.id
                           left outer join dbo.geoaddress ga on b.geoaddressid = ga.id
                           left outer join dbo.placeunload pu on b.placeunload_id = pu.id
     where o.salesman = @salesman_id
       and o.cts >= @ddate
       and o.cts < @ddate + 1
     group by p.id, p.name, ga.latitude, pu.latitude, ga.longitude, pu.longitude;
     
    delete from #waypoint
      where latitude is null;
    

                  
    
    -- tracking
    insert into #tracking with auto name
    select gp.longitude,
           gp.latitude,
           gp.device_ts as ts,
           gp.accuracy
      from geo.position gp 
     where gp.entity = @salesman_id
       and gp.device_ts >= dateadd(hh, 7, @ddate)
       and gp.device_ts < dateadd(hh, 20, @ddate);
       
    -- Если расстояние между точкой треккинга и точкой где заказ сделан
    -- меньше точности трекекинга, то для треккинга берем координаты точки из заказа
    /*
    update #tracking
       set latitude = #w.latitude,
           longitude = #w.longitude
      from #tracking #t, #waypoint #w
     where dbo.GPSDistance(#t.latitude, #t.longitude, #w.latitude, #w.longitude) < #t.accuracy;
     */
     

    -- result
    if @type = 'gpx' then
        set @result = dbo.GPXRoute();
    elseif @type = 'kml' then
        set @result = dbo.KMLRoute();
    end if;

    return @result;
    
end
;