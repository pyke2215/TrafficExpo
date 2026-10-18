# Dataset

Chỉ train thứ không viết thành công thức được. Hình học, Kalman và hysteresis không có dữ liệu ở thư mục này.

Ảnh và video nằm trong `raw/`. Thư mục đó không đưa vào git. Danh mục nguồn: `sources.yaml`.

| Việc | Chỗ | Ghi chú |
|---|---|---|
| Đọc loại biển và giá trị | `raw/vn-82` | 82 lớp biển Việt Nam, YOLO, CC BY 4.0. Đây là bộ ảnh duy nhất đang dùng để train |
| Gán nhãn xe, người, đèn, vạch | `raw/journeys/` | Bốn video hành trình, giấy phép mở. Tải lại bằng `clone.ps1` |
| Dashcam Việt Nam | `raw/roadbuddy/frames` | 3.843 ảnh JPG từ RoadBuddy, khoảng 3,3 GB. CC BY-NC 4.0. Bộ này không có file video |

Bốn video, tổng khoảng 51 MB:

- `hue-motorcycle.webm` — xe máy gần Huế, 1920×1080, khoảng 68 giây. CC BY-SA 4.0, tác giả RG72. Đây là clip Việt Nam duy nhất.
- `mixkit-25275-pov-motorcycle.mp4` — góc nhìn người lái, 1280×720, 25 giây. Không phải đường Việt Nam.
- `mixkit-31974-pov-motorcycle.mp4` — góc nhìn người lái, 1280×720, 21 giây. Không phải đường Việt Nam.
- `pexels-19581985-motorcycle.mp4` — ngồi sau người lái trên đường đô thị, 1920×1080, 10 giây.

Hành trình xe máy Việt Nam có giấy phép mở gần như chỉ có clip Huế. Ba clip còn lại ngắn và không phải đường Việt Nam, dùng để thử cách gán nhãn. Đoạn đường dài hơn thì tự quay.

`raw/zips/` vẫn còn `Data_SSD_Last.zip` và `Segmentation_Dataset.zip` của hai bộ đã bỏ. Xóa hai file đó nếu muốn lấy lại khoảng 2,3 GB.
