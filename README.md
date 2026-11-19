# 🚕 NYC Yellow Taxi Analytics — Phân tích Vận hành & Tối ưu Doanh thu (01/2026)


> **Tóm tắt nhanh (Executive Summary):** Dự án phân tích dữ liệu End-to-End trên **3,72 triệu bản ghi chuyến xe taxi thực tế** tại thành phố New York (tháng 01/2026). Dự án giải quyết bài toán kiểm soát chất lượng dữ liệu giao dịch quy mô lớn, xây dựng mô hình **Star Schema** chuẩn hóa.

---

## 📋 Mục lục
1. [Bối cảnh & Bài toán Kinh doanh](#1-bối-cảnh--bài-toán-kinh-doanh-business-problem)
2. [Giới thiệu Dữ liệu](#2-giới-thiệu-dữ-liệu-data-overview)
3. [Quy trình Thực hiện & Đối soát Dữ liệu](#3-quy-trình-thực-hiện-end-to-end-pipeline)
4. [Cấu trúc Thư mục Dự án](#4-cấu-trúc-thư-mục-dự-án)
5. [Từ điển KPI & Công thức DAX](#5-từ-điển-kpi--thư-viện-dax-measures)
6. [Phát hiện Kinh doanh Cốt lõi (Key Insights)](#6-phát-hiện-kinh-doanh-cốt-lõi-key-business-insights)
7. [Khuyến nghị Hành động (Recommendations)](#7-khuyến-nghị-hành-động-actionable-recommendations)

---

## 1. Bối cảnh & Bài toán Kinh doanh (Business Problem)

Một đơn vị vận hành đội xe taxi tại thành phố New York đang đối mặt với tình trạng mất cân đối cung – cầu giữa các quận (Boroughs) và ùn tắc kéo dài tại trung tâm Manhattan làm bào mòn thu nhập thực tế theo giờ của tài xế. Ban quản trị cần hệ thống phân tích dữ liệu để trả lời 4 câu hỏi cốt lõi:

* **Chất lượng dữ liệu (Data Governance):** Bao nhiêu phần trăm dữ liệu thô bị nhiễu bởi các giao dịch hoàn hủy (Reversal), dữ liệu khuyết có cấu trúc (Structural Nulls) và lỗi đồng hồ đo quãng đường/thời gian?
* **Hiệu suất sinh lời theo khu vực:** Điểm đón nào mang lại **`Revenue per Trip Hour` ($/giờ)** cao nhất thay vì chỉ nhìn vào giá cước mỗi chuyến?
* **Bài toán Sân bay vs. Nội đô:** Chạy đường dài từ sân bay (JFK, LaGuardia) có hiệu quả kinh tế theo thời gian cao hơn chạy quay vòng nhanh tại Manhattan không?
* **Nhịp điệu thời gian & Rủi ro ngoại cảnh:** Doanh thu và nhu cầu biến động như thế nào theo khung giờ, thứ trong tuần và sự kiện thời tiết cực đoan?

---

## 2. Giới thiệu Dữ liệu (Data Overview)

Nguồn dữ liệu chính thức từ **[NYC Taxi & Limousine Commission (TLC) Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)** — Giai đoạn **01/01/2026 – 31/01/2026**:

### Bảng 1: `yellow_tripdata_2026-01.parquet` (`3.724.889 dòng × 20 cột`)
| Nhóm trường dữ liệu | Các cột chính | Mô tả nghiệp vụ |
| :--- | :--- | :--- |
| **Định danh & Thời gian** | `VendorID`, `tpep_pickup_datetime`, `tpep_dropoff_datetime` | Mã nhà cung cấp thiết bị, thời điểm đón và trả khách |
| **Hành trình & Địa lý** | `PULocationID`, `DOLocationID`, `trip_distance`, `passenger_count` | Mã khu vực đón/trả khách, quãng đường (dặm), số hành khách |
| **Cước & Thanh toán** | `RatecodeID`, `payment_type`, `store_and_fwd_flag` | Biểu giá (Standard, JFK, Negotiated...) và hình thức thanh toán (Credit card, Cash, Flex Fare, Dispute...) |
| **Cấu phần Tài chính** | `fare_amount`, `tip_amount`, `tolls_amount`, `extra`, `mta_tax`, `congestion_surcharge`, `Airport_fee`, `cbd_congestion_fee`, `total_amount` | Giá cước đồng hồ gốc, tiền tip, cầu đường, các khoản phụ phí/thuế và tổng hóa đơn thanh toán |

### Bảng 2: `taxi_zone_lookup.csv` (`265 dòng × 4 cột`)
* `LocationID` (Khóa chính – Primary Key): Mã định danh duy nhất cho 265 khu vực của NYC TLC.
* `Borough`: Quận hành chính (`Manhattan`, `Queens`, `Brooklyn`, `Bronx`, `Staten Island`, `EWR`, `Unknown`).
* `Zone`: Tên khu vực đón/trả chi tiết (VD: `Upper East Side South`, `Midtown Center`, `JFK Airport`).
* `service_zone`: Phân loại vùng dịch vụ (`Yellow Zone`, `Boro Zone`, `Airports`, `EWR`).

---

## 3. Quy trình Thực hiện (End-to-End Pipeline)

```text
[NYC TLC Raw Files] ──▶ [Python: EDA & Data Cleaning] ──▶ [PostgreSQL: Constraints & SQL] ──▶ [Power BI: Star Schema & DAX]
 (Parquet & CSV)         (01 -> 04 Jupyter Notebooks)      (FK, Flags, Window Functions)       (3-Page Interactive Report)
```

### Chi tiết 5 giai đoạn xử lý
1. **Giai đoạn 1 — Khám phá dữ liệu (`notebook/01_data_exploration.ipynb`):** Kiểm tra kích thước, kiểu dữ liệu, phân phối `describe()`, phát hiện các giá trị bất thường về thời gian (`<= 0` phút hoặc `> 24` giờ), quãng đường (`0` dặm hoặc `> 100` dặm) và giao dịch mang giá trị âm.
2. **Giai đoạn 2 — Kiểm toán Chất lượng Dữ liệu (`notebook/02_data_quality_checks.ipynb`):**
   * **Phát hiện NULL có cấu trúc:** Chính xác **1.088.058 dòng (29,21%)** bị `NULL` đồng thời ở 5 cột (`passenger_count`, `RatecodeID`, `store_and_fwd_flag`, `congestion_surcharge`, `Airport_fee`). Kiểm tra chéo xác nhận **100% khớp với `payment_type = 0` (Flex Fare trip)** — không phải lỗi hỏng dữ liệu nên giữ lại để không mất 30% doanh thu.
   * **Đối soát giao dịch âm (Reversal Pairs):** Kiểm tra **39.984 dòng có `total_amount < 0`** bằng phương pháp ghép cặp đối xứng (`VendorID`, `pickup`, `dropoff`, `PU`, `DO`, `|total_amount|`), chứng minh phần lớn là các cặp giao dịch hủy/tranh chấp (`payment_type = 4`).
3. **Giai đoạn 3 — Tiền xử lý (`notebook/03_data_preprocessing.ipynb`):** Tạo cột `trip_duration_minutes`; loại bỏ **5.230 bản ghi lỗi cứng** gồm `4.277` dòng âm đơn lẻ không có cặp đối xứng, `873` dòng vận tốc bất khả thi (`> 80 mph`) và `80` dòng thanh toán thẻ/tiền mặt có `total_amount = 0`.
4. **Giai đoạn 4 — Xây dựng CSDL & Phân tích SQL (`notebook/04_load_to_postgreSQL.ipynb` & `sql/`):**
   * Nạp **3.719.659 bản ghi** sạch vào PostgreSQL theo từng lô (`chunk_size = 100.000`).
   * Chuẩn hóa tên cột `snake_case`, kiểm tra toàn vẹn tham chiếu và tạo `Primary Key` / `Foreign Key` giữa `trips_clean` và `taxi_zones`.
   * Tạo cột `is_flex_fare` (Generated Column) và đánh dấu `is_valid_trip = FALSE` cho **71.386 bản ghi Reversal (1,92%)**, giữ lại **3.648.273 chuyến hợp lệ (98,08%)**.
   * Viết truy vấn SQL phân tích theo giờ, thứ, khu vực, khung giờ vàng sân bay (`ROW_NUMBER() OVER`) và điều tra đột biến ngày 25–26/01.
5. **Giai đoạn 5 — Mô hình hóa Star Schema & Power BI (`powerbi/nyc_taxi_analytics.pbix`):**
   * Thiết kế mô hình **Star Schema** gồm Fact `trips_clean` nối `N:1` với Dimension `taxi_zones` và `Dim_Date` (khóa chuẩn 31 ngày tháng 01/2026).
   * Tách biệt lớp lọc **Tài chính** (`is_valid_trip = TRUE`) và lớp lọc **Hiệu suất Vận hành** (`trip_distance > 0`, `1 <= trip_duration_minutes <= 180`) trong DAX.

### Bảng Đối soát Dữ liệu (`N_raw = N_valid + N_invalid`)

| Giai đoạn / Trạng thái bản ghi | Số lượng dòng | Tỷ lệ (%) | Phương pháp xử lý |
| :--- | ---: | ---: | :--- |
| **Dữ liệu thô ban đầu (`yellow_tripdata_2026-01`)** | **3.724.889** | **100,00%** | Nguồn chính thức NYC TLC |
| Loại bỏ ở bước Python (`03_data_preprocessing`) | 5.230 | 0,14% | `4.277` dòng âm mồ côi, `873` tốc độ > 80 mph, `80` lỗi `total = 0` |
| **Nạp vào PostgreSQL (`trips_clean`)** | **3.719.659** | **99,86%** | Thiết lập khóa ngoại với `taxi_zones` (265 zones) |
| Giao dịch đảo / tranh chấp (`is_valid_trip = FALSE`) | 71.386 | 1,92% | Lưu vết lịch sử, loại khỏi tính toán doanh thu |
| **Chuyến đi hợp lệ (`is_valid_trip = TRUE`)** | **3.648.273** | **98,08%** | Cơ sở tính **Total Revenue ($108.771.809,89)** |
| *Trong đó: Nhóm Flex Fare (`payment_type = 0`)* | *1.087.691* | *29,81%* | *NULL có cấu trúc ở 5 cột đồng hồ; gắn cờ `is_flex_fare`* |

---

## 4. Cấu trúc Thư mục Dự án

```text
NYC-Taxi-Project/
├── data/                          
├── notebook/
│   ├── 01_data_exploration.ipynb   # Khám phá phân phối & phát hiện bất thường
│   ├── 02_data_quality_checks.ipynb# Kiểm toán NULL có cấu trúc & đối xứng dòng âm
│   ├── 03_data_preprocessing.ipynb # Làm sạch dữ liệu & tạo cột trip_duration_minutes
│   └── 04_load_to_postgreSQL.ipynb # Nạp dữ liệu theo chunk vào PostgreSQL
├── sql/
│   ├── 01_exploratory_analysis.sql # Chuẩn hóa schema, khóa ngoại & tạo cờ is_valid_trip
│   └── 02_business_analysis.sql    # Truy vấn phân tích KPI, sân bay & sự kiện ngày 25-26/01
├── powerbi/
│   ├── nyc_taxi_analytics.pbix     # File báo cáo tương tác 3 trang
│   └── screenshots/                # Ảnh chụp Dashboard & Star Schema Model View
├── .gitignore
└── README.md
```

---

## 5. Từ điển KPI & Thư viện DAX Measures

### Bảng Định nghĩa KPI (KPI Dictionary)
| Chỉ số KPI | Định nghĩa Nghiệp vụ | Quy tắc tính & Lọc bảo vệ |
| :--- | :--- | :--- |
| **Total Revenue** | Tổng thanh toán thực thu từ các chuyến hợp lệ (gồm cước gốc, tip, thuế, phụ phí). | `SUM(total_amount)` với `is_valid_trip = TRUE` |
| **Base Fare / Tip / Surcharges** | Tách bạch doanh thu thành 3 cấu phần: Cước gốc (`fare_amount`), Tiền tip (`tip_amount`) và Thuế/Phụ phí (`Total - Base - Tip`). | Áp dụng trên tập `is_valid_trip = TRUE` |
| **Total Trips** | Tổng số chuyến đi hợp lệ về mặt tài chính. | `COUNTROWS(trips_clean)` với `is_valid_trip = TRUE` |
| **Avg Revenue / Trip** | Giá trị thanh toán bình quân trên mỗi chuyến đi. | `DIVIDE([Total_Revenue], [Total Trip], 0)` |
| **Airport Revenue Share** | Tỷ trọng doanh thu từ các chuyến có **điểm đón** tại JFK hoặc LaGuardia (`service_zone = "Airports"`). | Dùng `REMOVEFILTERS` ở mẫu số & `COALESCE(..., 0)` |
| **Revenue per Trip Hour ($/hr)** | Hiệu suất doanh thu trên mỗi giờ xe lăn bánh có khách (tỷ số của tổng, không lấy trung bình từng chuyến). | Lọc `is_valid_trip = TRUE`, `trip_distance > 0`, `1 <= duration <= 180` |
| **Avg Trip Duration (Mins)** | Thời gian di chuyển trung bình mỗi chuyến (đơn vị: Phút). | Lọc `is_valid_trip = TRUE`, `trip_distance > 0`, `1 <= duration <= 180` |
| **Avg Daily Revenue ($/day)** | Doanh thu bình quân mỗi ngày thực tế, khử sai lệch do tháng 01/2026 có 5 ngày Thứ Năm–Thứ Bảy và 4 ngày Chủ Nhật–Thứ Tư. | `AVERAGEX(VALUES(Dim_Date[Date]), [Total_Revenue])` |

### Các công thức DAX cốt lõi (`All_Measures` & `Dim_Date`)

```dax
-- 1. Bảng Dimension Thời gian (Star Schema)
Dim_Date = 
ADDCOLUMNS(
    CALENDAR(DATE(2026, 1, 1), DATE(2026, 1, 31)),
    "Day", DAY([Date]),
    "DayOfWeekNum", WEEKDAY([Date], 2),
    "DayOfName", FORMAT([Date], "dddd"),
    "IsWeekend", IF(WEEKDAY([Date], 2) >= 6, "Weekend", "Weekday")
)

-- 2. Nhóm Measures Tài chính & Sản lượng
Total_Revenue = CALCULATE(SUM('public trips_clean'[total_amount]), 'public trips_clean'[is_valid_trip] = TRUE())
Total Trip = CALCULATE(count('public trips_clean'[vendorid]),'public trips_clean'[is_valid_trip]=TRUE()) 
avgValue_perTrip = DIVIDE([Total_Revenue], [Total Trip], 0)

-- 3. Cấu phần Doanh thu (Revenue Breakdown)
Base Fare = CALCULATE(SUM('public trips_clean'[fare_amount]), 'public trips_clean'[is_valid_trip] = TRUE())
Tip Amount = CALCULATE(SUM('public trips_clean'[tip_amount]), 'public trips_clean'[is_valid_trip] = TRUE())
Surcharges & Taxes = [Total_Revenue] - [Base Fare] - [Tip Amount]

-- 4. Tỷ trọng Sân bay & Trung bình ngày
Airport Revenue Share = 
COALESCE(
    DIVIDE(
    CALCULATE(
        [Total_Revenue],'public taxi_zones'[service_zone]="Airports"
        ),
        CALCULATE(
            [Total_Revenue],
            REMOVEFILTERS('public taxi_zones'[service_zone],'public taxi_zones'[borough],'public taxi_zones'[zone])
                )
            ),
            0
        )

Avg Daily Revenue = AVERAGEX(VALUES('Dim_Date'[Date]), [Total_Revenue])

-- 5. Hiệu suất Vận hành (Operational Efficiency)
Avg Trip Duration = 
CALCULATE(
    AVERAGE('public trips_clean'[trip_duration_minutes]),
    'public trips_clean'[is_valid_trip] = TRUE(),
    'public trips_clean'[trip_distance] > 0,
    'public trips_clean'[trip_duration_minutes] >= 1,
    'public trips_clean'[trip_duration_minutes] <= 180
)

Revenue per Trip Hour = 
CALCULATE(
    DIVIDE([Total_Revenue], SUM('public trips_clean'[trip_duration_minutes]) / 60.0, 0),
    'public trips_clean'[is_valid_trip] = TRUE(),
    'public trips_clean'[trip_distance] > 0,
    'public trips_clean'[trip_duration_minutes] >= 1,
    'public trips_clean'[trip_duration_minutes] <= 180
)
```

---



## 6. Phát hiện Kinh doanh Cốt lõi (Key Business Insights)
Tổng quan: Tình hình Nyc taxi ở tháng 1:
* $108 771 809,89 trong tháng 1/2026 với khoảng 3648273 chuyến đi taxi
* Nhu cầu taxi và doanh thu tập trung nhiều vào khung giờ từ 15:00 đến 19:00,cho thấy hoạt động taxi có xu hướng tăng cao vào buổi chiều và đầu buổi tối
* Manhattan vùng Upper East Side(Yellow Zone) có số lượng chuyến đi nhiều nhất: (157526,151661) với tổng doan thu (3432837.13,3440591.10) chiếm khoảng 6.32% tỉ lệ doanh thu
* Mahattan: Midtown Center có số lượng chuyến đi khoảng 143432 với tổng doanh thu 3864622.38 chiếm 3.55 
* Queens: JFK Airports có số chuyến đi gần bằng 138506 với tổng doanh thu 11095675.54 chiếm khoảng 10.20% tỉ lệ doanh thu
* Queens:  LaGuardia Airport có số chuyến đi gần bằng 81400 với tổng doanh thu 5659540.12 chiếm khoảng 5.20% tỉ lệ doanh thu
* Manhattan có số lượng chuyến đi và doanh thu nhiều nhất trong khoảng từ 15h đến 21h
* Chuyến đi từ sân bay JFK Airport có nhiều chuyến nhất vào khoảng 15h đến 22h
* Chuyến đi từ sân bay LaGuardia Airport có nhiều chuyến nhất vào khoảng 14h đến 21h
**--> 3 vùng Manhattan đứng đầu chiếm 9,87% tỉ trọng doanh thu trong tháng 1**
**--> Chỉ với 2 sân bay thuộc Queens Chiếm tới 15.40 tổng doanh thu tháng 1**
* Phương thức credit card chiếm phần lớn số lượng các phương thức thanh toán khác: 2248934 (61.64%)
* Standard rate có số chuyến lớn nhất, chiếm 63.69% tổng số dòng trong kết quả.
**--> Điều này cho thấy phần lớn chuyến taxi được ghi nhận theo mức giá tiêu chuẩn.**
  
1. **Nghịch lý Giá cước vs. Hiệu suất Giờ tại Manhattan (Penn Station vs. Upper East Side):**
   * Dù khu vực **Penn Station / Madison Sq West** có giá trị bình quân mỗi chuyến (**`$25,86`**) cao hơn **Upper East Side South** (**`$21,79`**), nhưng tình trạng ùn tắc quanh nhà ga kéo hiệu suất **`Revenue per Trip Hour`** của Penn Station xuống còn **`$97,63/giờ`** — thấp hơn **9,0%** so với **Upper East Side South (`$107,28/giờ`)** và **Lincoln Square East (`$107,57/giờ`)**.
2. **Sân bay là "Mỏ vàng" về Hiệu suất Sinh lời theo Thời gian:**
   * Hai sân bay **JFK** và **LaGuardia** chỉ chiếm **6,03% tổng lượng chuyến** (`219.906` chuyến) nhưng đóng góp **15,40% tổng doanh thu (`$16,76M`)**.
   * **JFK Airport** dẫn đầu nhóm điểm nóng với **`$124,30/giờ lăn bánh`** (cao hơn **+20,2%** so với trung bình toàn thành phố là **`$103,43/giờ`**), giá trị bình quân **`$80,11/chuyến`**. Khung giờ vàng đón khách tại sân bay rơi vào **15:00–22:00** (JFK) và **14:00–21:00** (LaGuardia).
3. **Vùng trũng hiệu suất tại các quận ngoại vi (Brooklyn & Bronx):**
   * **Brooklyn** và **Bronx** có thời gian di chuyển kéo dài (**30–38 phút/chuyến**) nhưng **`Revenue per Trip Hour`** chỉ đạt khoảng **`$58–$72/giờ`**, bằng một nửa so với Queens và Manhattan.
4. **Nhịp điệu tuần thực tế sau khi khử sai lệch lịch tháng 01/2026:**
   * Khi chuẩn hóa bằng **`Avg Daily Revenue`**, **Thứ Năm (`$4,0M/ngày`)** và **Thứ Sáu (`$3,8M/ngày`)** dẫn đầu tuần; **Thứ Ba (`$3,7M/ngày`)** và **Thứ Tư (`$3,8M/ngày`)** đạt mức tương đương **Thứ Bảy (`$3,7M/ngày`)**, trong khi **Chủ Nhật (`$2,6M/ngày`)** thấp nhất tuần.
5. **Định lượng tác động của Cơn bão tuyết ngày 25–26/01/2026:**
   * Cú sụt giảm sâu ngày 25–26/01 phản ánh chính xác cơn bão tuyết lớn tại New York ([NYC Emergency Management](https://www.nyc.gov/site/em/about/press-releases/20260123_pr_nycem_issues-hazardous-travel-advisory.page), [National Weather Service](https://www.weather.gov/okx/20260125_26)) khiến [sân bay LaGuardia tạm đóng cửa chiều 25/01](https://en.wikipedia.org/wiki/January_23%E2%80%9327,_2026_North_American_winter_storm).
   * Lượng chuyến rơi **-69,1%** từ Thứ Bảy 24/01 (`142.474` chuyến – `$3,79M`) xuống Chủ Nhật 25/01 (`44.085` chuyến – `$1,30M`). Ngay sau bão vào Thứ Ba 27/01, số chuyến phục hồi lên `119.929` chuyến kèm **`Avg Revenue / Trip` tăng vọt +32,4% lên `$35,25`** (đẩy doanh thu lên đỉnh tháng **`$4,23M`** ngày 27/01 và **`$4,43M`** ngày 28/01).

---

## 7. Khuyến nghị Hành động (Actionable Recommendations)

1. **Tái phân bổ đội xe nội đô giờ cao điểm chiều (`15:00 – 21:00`):** Hướng dẫn tài xế ưu tiên khai thác các chuyến quay vòng nhanh tại trục **Upper East Side South/North** và **Lincoln Square East (`$105–$108/giờ`)** thay vì xếp hàng tại nút thắt kẹt xe **Penn Station (`$97,63/giờ`)**.
2. **Tập trung năng lực đón khách tại Cửa ngõ Sân bay theo khung giờ vàng:** Bố trí ca trực đón khách tại **LaGuardia (`14:00 – 21:00`)** và **JFK (`15:00 – 22:00`)** nhằm tối đa hóa hiệu suất **`$124,30/giờ`**.

