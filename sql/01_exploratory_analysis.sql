
-- Kiểm tra cấu trúc bảng
select column_name, data_type
from information_schema.columns
where table_name='trips_clean'
order by ordinal_position;

select column_name,data_type
from information_schema.columns
where table_name='taxi_zones'
order by ordinal_position;

-- Kiểm tra kích thước dữ liệu (3719659, 21) bảng trips_clean
select  count(*)
from trips_clean;
-- 265 rows × 4 columns taxi zones
SELECT COUNT(*) AS total_zones
FROM taxi_zones;

-- Kiểm tra tổng quan bộ dữ liệu sau khi nạp
select *
from taxi_zones
limit 10;

select *
from trips_clean
limit 10;

-- Đổi tên cột thành chữ viết thường
alter table public.taxi_zones
rename column "LocationID" to locationid;

alter table public.taxi_zones
rename column "Borough" to borough;

alter table public.taxi_zones
rename column Zone to zone;

-- Đổi tên cột trips_clean thành chữ thường
alter table public.trips_clean
rename column "VendorID" to vendorid;

alter table public.trips_clean
rename column "RatecodeID" to ratecodeID;

alter table public.trips_clean
rename column "PULocationID" to pulocationid;

alter table public.trips_clean
rename column "DOLocationID" to dolocationid;

alter table public.trips_clean
rename column "Airport_fee" to airport_fee;

-- Thiết lập khóa cho bảng taxi_zones
select count(*),count(distinct(locationid)) as unique_lo
from taxi_zones;

alter table taxi_zones
add constraint pk_taxi_zones
primary key(locationid);

-- Tạo khóa ngoại
-- Trước tiên phải kiểm tra các hàng của trips clean có tham chiếu tới taxi zones ko
select count(*)
from trips_clean as tc
left join taxi_zones as tz
	on tc.pulocationid = tz.locationid
where tz.locationid is null;

-------------------------------

select count(*)
from trips_clean as tc
left join taxi_zones as tz
	on tc.dolocationid = tz.locationid
where tz.locationid is null;

-- Qua kiểm tra thấy các hàng của cột đón và trả khách đều tham chiếu tới cột locationID của bảng taxi_zones
-- Tạo khóa ngoại foreign key
alter table trips_clean
add constraint fk_pulocation
foreign key(pulocationid) references taxi_zones(locationid);

alter table trips_clean
add constraint fk_dolocation
foreign key(dolocationid) references taxi_zones(locationid);


-- Tạo cờ đánh dấu cho các chuyến đi có điều kiện
-- 1 Chuyến đi có payment_type=0 (is_flex_fare) = 10880558
-- 2 Chuyến đi có 2 dòng dữ liệu đối nhau có thể do là chuyến reversal (Chuyến đi bị hủy, tranh chấp...)
-- Tao nhung chuyen co valid trip
-- 1. Chuyến đi có payment_type=0 (is_flex_fare) = 1088058
select count(*) as flexfare
from trips_clean
where payment_type=0;

alter table trips_clean
add column is_flex_fare boolean
generated always as (payment_type= 0) stored;

-- 2 Chuyến đi có 2 dòng dữ liệu đối nhau có thể do là chuyến reversal (Chuyến đi bị hủy, tranh chấp...)
-- 3 Khi đã có reversal trip thì tạo các chuyến là is_valid_trip
alter table trips_clean
add column is_valid_trip boolean;


select count(*)*2
from (
select vendorid,tpep_pickup_datetime, tpep_dropoff_datetime, pulocationid, dolocationid, count(*) as valid_trip
from trips_clean
group by vendorid,tpep_pickup_datetime, tpep_dropoff_datetime, pulocationid, dolocationid
having count(*)=2 and sum(total_amount)=0 and 
		max(total_amount)>0 and min(total_amount)<0)
where valid_trip=2;
-- Tổng số chuyến reversal: 71386

--  Thiết lập true cho các cột là valid trip
update trips_clean as tc1
set is_valid_trip= false
from (select vendorid,
        	tpep_pickup_datetime,
        	tpep_dropoff_datetime,
        	pulocationid,
        	dolocationid,
			count(*)
		from trips_clean
		group by vendorid,
		        tpep_pickup_datetime,
		        tpep_dropoff_datetime,
		        pulocationid,
		        dolocationid
		having count(*)=2 and sum(total_amount)=0 and 
		max(total_amount)>0 and min(total_amount)<0 ) as tc2
where tc1.vendorid= tc2.vendorid and
	tc1.tpep_pickup_datetime= tc2.tpep_pickup_datetime and
	tc1.tpep_dropoff_datetime= tc2.tpep_dropoff_datetime and
	tc1.pulocationid= tc2.pulocationid and
	tc1.dolocationid= tc2.dolocationid;

-- Thiết lập các cột còn lại là False
update trips_clean 
set is_valid_trip=true
where is_valid_trip is null;

-- Kiểm tra lại dữ liệu
select is_valid_trip , count(*)
from trips_clean
group by is_valid_trip

-- False: 71386
-- True: 3648273

-- Chuyển các giá trị null trong bảng zones thành Unknown
update taxi_zones
set borough = coalesce(borough,'Unknown'),
	zone = coalesce(zone,'Unknown'),
	service_zone = coalesce(service_zone,'Unknown')
where borough is null or 
	zone is null or 
	service_zone is null;


-- The final rate code in effect at the end of the trip. 
-- 1 = Standard rate 
-- 2 = JFK 
-- 3 = Newark 
-- 4 = Nassau or Westchester 
-- 5 = Negotiated fare 
-- 6 = Group ride 
-- 99 = Null/unknown 
-- Update them cot để dễ dàng phân biệt và chuẩn hóa dữ liếu
ALTER TABLE trips_clean
ADD COLUMN rate_code_name TEXT;

UPDATE trips_clean
SET rate_code_name =
    CASE
        WHEN ratecodeid = 1 THEN 'Standard rate'
        WHEN ratecodeid = 2 THEN 'JFK'
        WHEN ratecodeid = 3 THEN 'Newark'
        WHEN ratecodeid = 4 THEN 'Nassau or Westchester'
        WHEN ratecodeid = 5 THEN 'Negotiated fare'
        WHEN ratecodeid = 6 THEN 'Group ride'
        WHEN ratecodeid = 99 THEN 'Unknown'
        WHEN ratecodeid IS NULL THEN 'Not recorded'
        ELSE 'Other'
    END;

