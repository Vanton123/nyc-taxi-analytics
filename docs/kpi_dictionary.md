# 📖 Từ điển KPI & Quy chuẩn Chất lượng Dữ liệu — NYC Taxi Analytics (01/2026)

Tài liệu này chuẩn hóa định nghĩa nghiệp vụ, công thức tính toán, đơn vị hiển thị và các quy tắc kiểm soát chất lượng dữ liệu được áp dụng đồng bộ giữa **PostgreSQL** và **Power BI**.

---

## 1. Nhóm Chỉ số Tài chính & Sản lượng (Financial & Volume KPIs)

| Tên KPI | Định nghĩa Nghiệp vụ | Công thức / Logic tính | Phạm vi & Bộ lọc | Định dạng |
| :--- | :--- | :--- | :--- | :--- |
| **Total Revenue** | Tổng số tiền khách hàng thực trả qua các chuyến hợp lệ (bao gồm cước gốc, tiền tip, phí cầu đường, phụ phí và thuế). | `SUM(trips_clean[total_amount])` | `is_valid_trip = TRUE`, `01/01/2026 – 31/01/2026` | Currency (`$`), 0 số lẻ \vert{} \vert{} **Base Fare** \vert{} Doanh thu giá cước đồng hồ thuần túy tính theo quãng đường và thời gian, tách biệt khỏi tiền tip và thuế thu hộ. \vert{} `SUM(trips_clean[fare_amount])` \vert{} `is_valid_trip = TRUE`, `01/01/2026 – 31/01/2026` \vert{} Currency (`$`), 0 số lẻ |
| **Tip Amount** | Tiền thưởng khách trả cho tài xế qua thẻ tín dụng/ứng dụng *(Lưu ý: Tiền tip trả bằng tiền mặt không được đồng hồ ghi nhận nên có giá trị `$0`)*. | `SUM(trips_clean[tip_amount])` | `is_valid_trip = TRUE`, `01/01/2026 – 31/01/2026` | Currency (`$`), 0 số lẻ \vert{} \vert{} **Surcharges & Taxes** \vert{} Tổng các khoản phụ phí giờ cao điểm (`extra`), thuế (`mta_tax`), phụ phí cải thiện, phí kẹt xe (`congestion_surcharge`, `cbd_congestion_fee`), phí sân bay và cầu đường. \vert{} `[Total_Revenue] - [Base Fare] - [Tip Amount]` \vert{} `is_valid_trip = TRUE`, `01/01/2026 – 31/01/2026` \vert{} Currency (`$`), 0 số lẻ |
| **Total Trips** | Tổng số chuyến đi hợp lệ về mặt tài chính (đã loại bỏ các cặp giao dịch đảo/tranh chấp). | `COUNTROWS(trips_clean)` | `is_valid_trip = TRUE`, `01/01/2026 – 31/01/2026` | Whole number (có dấu `,`) |
| **Avg Revenue / Trip** | Giá trị thanh toán trung bình trên mỗi chuyến đi *(phân biệt rõ với `Avg Base Fare` chỉ tính trên `fare_amount`)*. | `DIVIDE([Total_Revenue], [Total Trip], 0)` | `is_valid_trip = TRUE` | Currency (`$`), 2 số lẻ |
| **Airport Revenue Share** | Tỷ trọng doanh thu từ các chuyến đi có **điểm đón khách (`PULocationID`)** nằm tại sân bay JFK hoặc LaGuardia (`service_zone = "Airports"`). | `Doanh thu đón tại Sân bay / Tổng doanh thu` | Mẫu số dùng `REMOVEFILTERS` trên `service_zone` & `zone`; bọc `COALESCE(..., 0)` | Percentage (`%`), 2 số lẻ |

---

## 2. Nhóm Chỉ số Hiệu suất Vận hành & Thời gian (Operational & Temporal KPIs)

| Tên KPI | Định nghĩa Nghiệp vụ | Công thức / Logic tính | Bộ lọc Bảo vệ (Guardrails) | Định dạng |
| :--- | :--- | :--- | :--- | :--- |
| **Revenue per Trip Hour ($/hr)** | Doanh thu bình quân tạo ra trên mỗi giờ xe lăn bánh có khách. Tính bằng *tỷ số của tổng* (Ratio of Sums), không tính trung bình cộng của từng chuyến để tránh sai lệch trọng số từ các chuyến siêu ngắn. | `SUM(total_amount) / (SUM(trip_duration_minutes) / 60.0)` | `is_valid_trip = TRUE`, `trip_distance > 0`, `1 <= trip_duration_minutes <= 180` | Currency (`$`), 2 số lẻ \vert{} \vert{} **Avg Trip Duration (Mins)** \vert{} Thời gian di chuyển trung bình của một chuyến đi hợp lệ về mặt vận hành (tính bằng Phút). \vert{} `AVERAGE(trips_clean[trip_duration_minutes])` \vert{} `is_valid_trip = TRUE`, `trip_distance > 0`, `1 <= trip_duration_minutes <= 180` \vert{} Decimal, 1 số lẻ \vert{} \vert{} **Avg Daily Revenue ($/day)** \vert{} Doanh thu trung bình mỗi ngày thực tế trong nhóm, giúp khử sai lệch lịch do tháng 01/2026 có 5 ngày Thứ Năm–Thứ Bảy nhưng chỉ có 4 ngày Chủ Nhật–Thứ Tư. \vert{} `AVERAGEX(VALUES(Dim_Date[Date]), [Total_Revenue])` \vert{} Liên kết qua `Dim_Date` (`01/01/2026 – 31/01/2026`) \vert{} Currency (`$`), 0 số lẻ |

---

## 3. Quy tắc Kiểm soát Chất lượng Dữ liệu (Data Quality Rules)

1. **Nhận diện Giao dịch đảo (`is_valid_trip`):**
   * Các chuyến bị hủy hoặc tranh chấp được hệ thống ghi nhận bằng cách giữ dòng dương gốc và thêm một dòng âm đối xứng.
   * Quy tắc SQL: Gom nhóm theo `(vendorid, tpep_pickup_datetime, tpep_dropoff_datetime, pulocationid, dolocationid)` có `COUNT(*) = 2`, `SUM(total_amount) = 0`, `MAX(total_amount) > 0` và `MIN(total_amount) < 0` → gắn cờ `is_valid_trip = FALSE` (`71.386` dòng / `1,92%`).
2. **Xử lý Khuyết dữ liệu có cấu trúc (`is_flex_fare`):**
   * `1.088.058` dòng dữ liệu thô (`1.087.691` chuyến hợp lệ) bị `NULL` đồng thời ở 5 cột (`passenger_count`, `RatecodeID`, `store_and_fwd_flag`, `congestion_surcharge`, `Airport_fee`), trùng khớp **100%** với `payment_type = 0` (**Flex Fare trip**).
   * Do dữ liệu cước và vị trí vẫn hợp lệ, nhóm này được giữ lại, gắn cờ `is_flex_fare = TRUE` và gán nhãn `Not recorded` ở cột `rate_code_name`.
3. **Loại bỏ Ngoại lai vật lý & Khóa biên thời gian:**
   * Bước tiền xử lý Python loại bỏ `4.277` dòng âm đơn lẻ không có cặp, `873` dòng tốc độ `> 80 mph` và `80` dòng thẻ/tiền mặt có `total_amount = 0`.
   * Bộ lọc cấp báo cáo Power BI khóa `tpep_pickup_datetime` trong khoảng `[2026-01-01 00:00:00, 2026-02-01 00:00:00)` để loại trừ các chuyến giao thừa ngoài tháng 01/2026.
