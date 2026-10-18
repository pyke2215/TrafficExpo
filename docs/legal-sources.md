# Nguồn pháp lý và cách theo dõi thay đổi

Phạm vi hiện tại là Việt Nam. Không chia rule theo quốc gia hay theo địa phương.

Rule chia theo phương tiện. Gói đầu tiên là xe máy hai bánh: [`legal/rules/xe_may/phat_hien.md`](../legal/rules/xe_may/phat_hien.md). Mục lục: [`legal/sources/tong_hop_phat_hien.md`](../legal/sources/tong_hop_phat_hien.md). Danh mục văn bản: [`legal/sources/catalog.yaml`](../legal/sources/catalog.yaml).

Chỉ đưa vào rule những điều kiện dùng để nhận ra và xếp loại vi phạm. Không tổng hợp mức phạt, điểm giấy phép, thẩm quyền xử phạt.

Văn bản gốc và metadata (số hiệu, ngày hiệu lực) để ở [`legal/sources/`](../legal/sources/).

Rule đã hình thức hoá để ở [`legal/rules/`](../legal/rules/), mỗi thư mục một loại phương tiện. Hiện có `xe_may/`.

Ưu tiên giữa các rule khai báo ở [`legal/priorities/`](../legal/priorities/) và phải được luật sư duyệt trước khi deploy.

## Theo dõi thay đổi

1. Thêm bản gốc vào `legal/sources/` kèm số hiệu và ngày hiệu lực. Không sửa đè bản đã dùng để biên dịch. Ghi rõ rule áp dụng cho loại phương tiện nào.
2. Mỗi lần luật đổi thì tạo version mới, có `valid_from`, `valid_to` và `transaction_time`.
3. Cặp rule giao nhau phải có quan hệ ưu tiên đã khai báo, hoặc được overlap gate phân loại là tương thích. Thiếu khai báo thì chặn deploy.
4. Package chỉ được đóng gói và ký sau khi qua overlap gate và bộ test trong [`legal/tests/`](../legal/tests/).
5. Client chọn version theo thời điểm sự kiện và theo loại phương tiện, không theo thời điểm cài app.

Bối cảnh văn bản đang được rà soát ghi ở [lộ trình, mục 3](./traffic_ai_roadmap.md). Cần đối chiếu văn bản chính thức trước khi nạp vào hệ thống.
