
# ⚙️ Thư viện DAX Measures — NYC Taxi Analytics

Toàn bộ Measures được tổ chức tập trung trong bảng **`All_Measures`** và chạy trên mô hình **Star Schema** gồm 3 bảng:
* **Fact Table:** `'public trips_clean'`
* **Dimension Tables:** `'public taxi_zones'` (nối `1:N` qua `locationid = pulocationid`) và `'Dim_Date'` (nối `1:N` qua `Date = PickupDate`)

---

## 1. Bảng Dimension Thời gian (`Dim_Date`)

```dax
Dim_Date = 
ADDCOLUMNS(
    CALENDAR(DATE(2026, 1, 1), DATE(2026, 1, 31)),
    "Day", DAY([Date]),
    "DayOfWeekNum", WEEKDAY([Date], 2),
    "DayOfName", FORMAT([Date], "dddd"),
    "IsWeekend", IF(WEEKDAY([Date], 2) >= 6, "Weekend", "Weekday")
)
```
> **Thiết lập bắt buộc:** Đánh dấu `Mark as date table` theo cột `Dim_Date[Date]` và đặt `Sort by column` của `Dim_Date[DayOfName]` theo `Dim_Date[DayOfWeekNum]` để giữ cố định thứ tự `Monday → Sunday`.

---

## 2. Measures Tài chính & Sản lượng Cốt lõi

```dax
Total_Revenue = 
CALCULATE(
    SUM('public trips_clean'[total_amount]),
    'public trips_clean'[is_valid_trip] = TRUE()
)
-- Format: Currency ($), 0 decimal places
```

```dax
Total Trip = 
CALCULATE(
    COUNTROWS('public trips_clean'),
    'public trips_clean'[is_valid_trip] = TRUE()
)
-- Format: Whole number, bật dấu phân cách hàng nghìn
```

```dax
avgValue_perTrip = 
DIVIDE([Total_Revenue], [Total Trip], 0)
-- Format: Currency ($), 2 decimal places
```

---

## 3. Measures Cấu phần Doanh thu (Revenue Breakdown Donut)

```dax
Base Fare = 
CALCULATE(
    SUM('public trips_clean'[fare_amount]),
    'public trips_clean'[is_valid_trip] = TRUE()
)
-- Format: Currency ($), 0 decimal places
```

```dax
Tip Amount = 
CALCULATE(
    SUM('public trips_clean'[tip_amount]),
    'public trips_clean'[is_valid_trip] = TRUE()
)
-- Format: Currency ($), 0 decimal places
```

```dax
Surcharges & Taxes = 
[Total_Revenue] - [Base Fare] - [Tip Amount]
-- Format: Currency ($), 0 decimal places
```

---

## 4. Measures Phân tích Khu vực, Thời gian & Hiệu suất Vận hành

```dax
Airport Revenue Share = 
COALESCE(
    DIVIDE(
        CALCULATE(
            [Total_Revenue],
            'public taxi_zones'[service_zone] = "Airports"
        ),
        CALCULATE(
            [Total_Revenue],
            REMOVEFILTERS(
                'public taxi_zones'[service_zone],
                'public taxi_zones'[zone]
            )
        )
    ),
    0
)
-- Format: Percentage (%), 2 decimal places
```

```dax
Avg Daily Revenue = 
AVERAGEX(
    VALUES('Dim_Date'[Date]),
    [Total_Revenue]
)
-- Format: Currency ($), 0 decimal places
```

```dax
Avg Trip Duration = 
CALCULATE(
    AVERAGE('public trips_clean'[trip_duration_minutes]),
    'public trips_clean'[is_valid_trip] = TRUE(),
    'public trips_clean'[trip_distance] > 0,
    'public trips_clean'[trip_duration_minutes] >= 1,
    'public trips_clean'[trip_duration_minutes] <= 180
)
-- Format: Decimal number, 1 decimal place (Phút)
```

```dax
Revenue per Trip Hour = 
CALCULATE(
    DIVIDE(
        [Total_Revenue],
        SUM('public trips_clean'[trip_duration_minutes]) / 60.0,
        0
    ),
    'public trips_clean'[is_valid_trip] = TRUE(),
    'public trips_clean'[trip_distance] > 0,
    'public trips_clean'[trip_duration_minutes] >= 1,
    'public trips_clean'[trip_duration_minutes] <= 180
)
-- Format: Currency ($), 2 decimal places
```
