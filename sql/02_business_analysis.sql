-- Doanh thu và nhu cầu taxi thay đổi thế nào theo giờ, ngày và khu vực? Khu vực nào có nhu cầu cao?


-- Doanh thu: 108771809.89 và tổng số chuyến taxi trong vòng 1 tháng
select round(sum(total_amount)::numeric,2) as revenue, count(*) as total_trip
from trips_clean
where is_valid_trip = True;
-- 108 771 809,89 đô la trong tháng 1/2026 với khoảng 3648273 chuyến đi taxi 
select is_valid_trip, count(*) trip_record,round(count(*)*100.0/(select count(*) from trips_clean),2) as pct_tripRecord
from trips_clean
group by is_valid_trip;

-- Câu 1: Doanh thu và nhu cầu taxi thay đổi như thể nào theo GIỜ, NGÀY và KHU VỰC
-- Doanh thu theo giờ: Tìm doanh thu của từng 1 giờ cụ thể với tổng chuyến đi và tổng doanh thu
select extract(hour from tpep_pickup_datetime) as hour, 
		round(sum(total_amount):: numeric,2) as total_revenue,
		count(*) as total_trip,
		round(sum(total_amount)::numeric/(select sum(total_amount)::numeric from trips_clean
									where is_valid_trip=true)*100.0,2) as pct_revenue
from trips_clean
where is_valid_trip=true
group by extract(hour from tpep_pickup_datetime)
order by total_revenue desc, total_trip desc, pct_revenue desc;
-- Trong tháng 1/2026, nhu cầu taxi và doanh thu tập trung nhiều vào khung giờ từ 15:00 đến 19:00,
-- cho thấy hoạt động taxi có xu hướng tăng cao vào buổi chiều và đầu buổi tối


-- Doanh thu theo ngày: Tìm doanh thu của từng 1 ngày cụ thể với tổng chuyến đi và tổng doanh thu
select extract(day from tpep_pickup_datetime) as day, 
		round(sum(total_amount):: numeric,2) as total_revenue,
		count(*) as total_trip,
		round(sum(total_amount)::numeric/(select sum(total_amount)::numeric from trips_clean
									where is_valid_trip=true)*100.0,2) as pct_revenue,
		round(sum(total_amount)::numeric / count(*), 2) as avg_revenue_per_trip
from trips_clean
where is_valid_trip=true
group by extract(day from tpep_pickup_datetime)
order by total_revenue desc, total_trip desc, pct_revenue desc;
--- Trong 1 tháng các ngày gần cuối tháng có xu hướng tăng doanh thu và số lượng chuyến đi
-- Xu hướng bị ảnh hưởng mạnh bởi cơn bão tuyết ngày 25–26/01 (-69,1% số chuyến) và 
-- hiệu ứng phục hồi nhu cầu dồn nén ngày 27–28/01 ($4,22M – $4,43M/ngày, Avg Revenue/Trip tăng vọt lên $35,25



-- Câu 2: Khu vực nào có nhu cầu cao nhất, doanh thu và số lượng
select tc.PULocationID as ID,
		tz.borough as Borough,
		tz.zone as Zone,
		tz.service_zone as service_zone,
		round(sum(tc.total_amount)::numeric,2) as total_revenue,
		count(*) as total_trip,
		round(sum(tc.total_amount)::numeric/(select sum(total_amount)::numeric from trips_clean
										where is_valid_trip=true)*100.0,2) as pct_revenue
from trips_clean as tc
join taxi_zones as tz
	on tc.PULocationID=tz.locationid
where tc.is_valid_trip = True
group by tc.PULocationID,tz.borough,tz.zone,tz.service_zone
order by total_trip desc,total_revenue desc, pct_revenue desc;

-- Manhattan vùng South(Yellow Zone) có số lượng chuyến đi nhiều nhất: 160168 với tổng doan thu 3432837.13 chiếm khoảng 3.16% tỉ lệ doanh thu
-- Queens thuộc JFK Airports có số chuyến đi gần bằng 151898 với tổng doanh thu 11095675.54 chiếm khoảng 10.20% tỉ lệ doanh thu


select
		tz.borough as Borough,
		round(sum(tc.total_amount)::numeric,2) as total_revenue,
		count(*) as total_trip,
		round(sum(tc.total_amount)::numeric/(select sum(total_amount)::numeric from trips_clean
										where is_valid_trip=true)*100.0,3) as pct_revenue,
		round(count(*)*100.0/(select count(*) from trips_clean where is_valid_trip=true),2) as pct_totalTrip							
from trips_clean as tc
join taxi_zones as tz
	on tc.PULocationID=tz.locationid
where tc.is_valid_trip = True
group by tz.borough
order by total_revenue desc, total_trip desc;

-- Trong tháng 1/2026 Mahattan chiếm phần lớn số lượng chuyến đi 3125550(85.67%) với tổng doanh thu 80706929.21(74.198%)
-- Xếp thứ 2 là Queens chiếm số lượng chuyến đi thứ 2 sau Mahattan 324467(8.89%) với tổng doanh thu 20884052.65(19.200%)
-- => Manhattan đang là thị trường chiếm phần lớn lượng đi xuất phát bỏ xa vị trí thứ 2 là Queens
with cte_Manhattan as 
(
	select tz.borough, round(sum(tc.total_amount)::numeric,2) as total_revenue, count(*) as total_trip
	from trips_clean as tc
	join taxi_zones as tz
		on tc.PULocationID=tz.locationid
	where tc.is_valid_trip = True and tz.borough='Manhattan'
	group by  tz.borough

)
select tz.borough,
		extract(hour from tpep_pickup_datetime ) as hour,
		round(sum(tc.total_amount)::numeric) as total_revenue,
		count(*) as total_trip,
		round(sum(tc.total_amount)::numeric*100.0/(select total_revenue from cte_Manhattan),2) as pct_revHour,
		round(count(*)*100.0/(select total_trip from cte_Manhattan),2) as pct_totaTripHour
from trips_clean as tc
join taxi_zones as tz
	on tc.PULocationID=tz.locationid
where tc.is_valid_trip = True and tz.borough='Manhattan'
group by extract(hour from tpep_pickup_datetime), tz.borough
order by total_revenue desc, total_trip desc;
-- Manhattan có số lượng chuyến đi và doanh thu nhiều nhất trong khoảng từ 16h đến 21h


-----------------------------------------------------------------------------------------
select 
		tz.borough as Borough,
		tz.service_zone as service_zone,
		round(sum(tc.total_amount)::numeric,2) as total_revenue,
		count(*) as total_trip,
		round(sum(tc.total_amount)::numeric/(select sum(total_amount)::numeric from trips_clean
										where is_valid_trip=true)*100.0,3) as pct_revenue,
		round(count(*)*100.0/(select count(*) from trips_clean where is_valid_trip=true),2) as pct_totalTrip
from trips_clean as tc
join taxi_zones as tz
	on tc.PULocationID=tz.locationid
where tz.service_zone='Airports' and  tc.is_valid_trip = True
group by tz.borough,tz.service_zone
order by total_revenue desc, total_trip desc;



-- Các chuyến xe từ sân bay có tổng doanh thu chuyến đi khoảng 16755215.66 (15.404%) và tổng số lượng chuyến đi 219906 (6.03%)
-- Trong đó JFK Airport chiếm 10.201% doanh thu và 3.80% số lượng chuyến đi 
-- LaGuardia Airport chiếm 5.203% doanh thu và 2.23% số lượng chuyến đi
-- Các chuyến đón khách tại khu vực sân bay chỉ chiếm khoảng 6.03% tổng số chuyến nhưng đóng góp khoảng 15.404% tổng doanh thu. 
-- Điều này cho thấy nhóm chuyến Airport có giá trị tiền trung bình mỗi chuyến cao hơn đáng kể so với mức trung bình toàn bộ dữ liệu.

select tc.PULocationID as ID,
		tz.borough as Borough,
		tz.zone as Zone,
		extract(hour from tpep_pickup_datetime) as hour,
		round(sum(tc.total_amount)::numeric,2) as total_revenue,
		count(*) as total_trip,
		round(sum(tc.total_amount)::numeric/(select sum(total_amount)::numeric from trips_clean
										where is_valid_trip=true)*100.0,3) as pct_revenue,
		round(count(*)*100.0/(select count(*) from trips_clean where is_valid_trip=true),2) as pct_totalTrip,
		row_number() over(partition by tc.PULocationID,tz.borough,tz.zone order by count(*) desc) as rank_hour
from trips_clean as tc
join taxi_zones as tz
	on tc.PULocationID=tz.locationid
where tz.service_zone='Airports' and  tc.is_valid_trip = True
group by tc.PULocationID,tz.borough,tz.zone,extract(hour from tpep_pickup_datetime)
order by tc.PULocationID, rank_hour;
-- Chuyến đi từ sân bay JFK Airport có nhiều chuyến nhất vào khoảng 15h đến 22h
-- Chuyến đi từ sân bay LaGuardia Airport có nhiều chuyến nhất vào khoảng 14h đến 21h




select payment_type,
	   count(*) as total_eachPayment,
	   round((count(*)*100.0)/(select count(*) from trips_clean where is_valid_trip=true),2) as pct_payment
from trips_clean
where is_valid_trip = True
group by payment_type
order by total_eachPayment desc;
-- 0 = 29.81 
-- 1 = 61.64
-- 2 = 8.13
-- 3 = 0.22
-- 4 = 0.20
-- Phương thức credit card chiếm phần lớn số lượng các phương thức thanh toán khác: 2248934 (61.64%,) xếp vị trí 
-- thứ 2 là phương thức thanh toán = 0 Flex Fare Trip 1087691 (29.81%) và các vị trí tiếp theo lần lượt là 
-- phương thức 2,4,3



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


select ratecodeid, count(*) as total_trip,
round(
        count(*) * 100.0 /
        (select count(*)
         from trips_clean
         where is_valid_trip = true),
        2
    ) AS pct_trip
from trips_clean
 where is_valid_trip = true
group by ratecodeid;
-- Standard rate có số chuyến lớn nhất, chiếm 63.69% tổng số dòng trong kết quả.
-- Điều này cho thấy phần lớn chuyến taxi được ghi nhận theo mức giá tiêu chuẩn.

-- 29.81% số chuyến có ratecodeid = NULL, và theo kết quả kiểm tra trước đó, toàn bộ thuộc payment_type = 0 (Flex Fare).
