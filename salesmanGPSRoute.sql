create or replace function dbo.salesmanGPSRoute()
returns xml
begin
    declare @result xml;

    
    create local temporary table #tracking(latitude decimal(13,10),
                                           longitude decimal(13,10),
                                           ts datetime,
                                           accuracy decimal(18,2));
                                            
    create local temporary table #waypoint(buyer integer,
                                           partner integer,
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
                                            


    -- route     
    insert into #waypoint with auto name   
    select min(b.id) as buyer,
           p.id as partner,
           p.name as name,
           min(b.loadto) as address,
           count(*) as orderCnt,
           sum(totalCost) as orderSumm,
           max(o.device_ts) as ts,
           pu.latitude as latitude,
           pu.longitude as longitude
      from dbo.pre_order o join dbo.buyers b on o.client = b.id
                           join dbo.partners p on b.partner = p.id
                           left outer join dbo.placeunload pu on b.placeunload_id = pu.id
     where o.salesman = @salesman_id
       and o.cts >= @ddate
       and o.cts < @ddate + 1
     group by p.id, p.name, pu.latitude, pu.longitude;
     
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
    
    drop table #tracking;
    drop  table #waypoint;

    return @result;
    
end
;