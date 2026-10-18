# Lộ trình triển khai: Hệ thống AI phát hiện vi phạm và cảnh báo giao thông

> Tài liệu đi kèm bản mind map kiến trúc: https://claude.ai/artifact/QNmcJaK4o9wTMXYMqYuou1
> Mọi mốc thời gian là **ước lượng thô**, phụ thuộc quy mô đội ngũ và thiết bị mục tiêu. Mọi tên công cụ, phiên bản, giấy phép cần được kiểm tra lại tại thời điểm chọn.

---

## 1. Mục tiêu và nguyên tắc

**Mục tiêu:** từ camera trên điện thoại hoặc kính AR, trích xuất ngữ cảnh giao thông (biển báo, vạch, đèn, phương tiện), đối chiếu với luật đang áp dụng để (a) cảnh báo nguy cơ, (b) xác định vi phạm, (c) đưa chỉ dẫn.

**Nguyên tắc thiết kế (rút ra từ phần thảo luận kiến trúc):**

1. **Tách hai nhánh.** Nhánh A (nguy cơ) dùng deep learning, chấp nhận xác suất. Nhánh B (kết luận vi phạm) dùng logic symbolic biên dịch sẵn, deterministic, audit được.
2. **Luật là dữ liệu có thời gian.** Mỗi rule mang `valid_from`, `valid_to`, `transaction_time` và phạm vi địa lý. Vi phạm xét theo luật có hiệu lực tại thời điểm xảy ra.
3. **Tới hạn thì chạy tại máy.** Mọi đường cảnh báo an toàn không phụ thuộc mạng. Server lo biên dịch luật, LLM, huấn luyện, kiểm toán.
4. **Self inject, context perceive.** Thông tin xe, tài xế, GPS/IMU do app cung cấp, không detect. Chỉ phần thế giới xung quanh đi qua perception.
5. **LLM không ra quyết định pháp lý.** LLM chỉ soạn nháp rule (có luật sư duyệt) và diễn đạt lại verdict.
6. **Phạm vi hẹp trước, mở rộng sau.** Rule chưa hình thức hoá phải chuyển cho người xem, không được mặc định "không vi phạm".

---

## 2. Kiến trúc tóm tắt

```
Camera → Perception (DL) → Scene graph (valid_time, TTL) ┐
App self info (xe, tài xế, GPS/IMU) ─── inject ──────────┴→ Belief vector x(t)
                                                           ├→ [A] Risk predictor → Risk score ┐
                                                           └→ [B] Grounding → Automaton + circuit
                                                                  → Priority resolver → Verdict ┤→ LLM explainer → Output
Văn bản luật → Parser/LLM → Overlap gate + test → Rule compiler → Compiled package ⇒ [B]
Human review ⇒ cập nhật luật + nhãn huấn luyện
```

**Phân chia client / server**

| Client (điện thoại, kính AR) | Server |
|---|---|
| Capture, self info | Biên dịch luật (parser, overlap gate, regression test) |
| Perception ra scene graph (model nhẹ) | Package registry có version bitemporal |
| Runtime nhánh B (automaton, circuit, ma trận ưu tiên) | LLM explainer, soạn rule (bất đồng bộ) |
| Risk nhẹ, cảnh báo bằng template | Audit log, huấn luyện lại, active learning |
| Log ký số (verdict, version rule, hash bằng chứng) | Phân phối package luật xuống client |

---

## 3. Bối cảnh pháp lý cần đưa vào kế hoạch

Các điểm dưới đây rút từ kết quả tra cứu ngày 10/10/2026, **cần xác minh lại bằng văn bản chính thức** trước khi nạp vào hệ thống.

- Luật Trật tự, an toàn giao thông đường bộ số 36/2024/QH15 đã được sửa đổi, bổ sung bởi Luật số 118/2025/QH15.
- Nghị định 168/2024/NĐ-CP (xử phạt vi phạm hành chính trong lĩnh vực giao thông đường bộ, trừ điểm giấy phép lái xe) đang có văn bản sửa đổi. Kết quả tìm kiếm cho thấy cả dự thảo lẫn một bản tiếng Anh mang số 238/2026. Cần kiểm tra tình trạng và ngày hiệu lực của bản chính thức.
- **Luật khác nhau theo địa phương.** Hà Nội có Nghị quyết 56/2026/NQ-HĐND quy định mức phạt cao hơn Nghị định 168/2024 cho một số hành vi.

Nguồn tham khảo ban đầu (chỉ để dò, không thay văn bản gốc):

- https://thuvienphapluat.vn/phap-luat/chu-de/vi-pham-giao-thong
- https://thuvienphapluat.vn/van-ban/EN/Vi-pham-hanh-chinh/Decree-238-2026-ND-CP-amendments-to-Decree-168-2024-ND-CP/726899/tieng-anh.aspx
- https://lsvn.vn/chu-tich-truong-cong-an-xa-duoc-de-xuat-tang-tham-quyen-xu-phat-vi-pham-giao-thong-a172591.html
- https://ketoananpha.vn/nghi-quyet-56-2026-nq-hdnd

**Hệ quả thiết kế:** rule phải có thêm trường `jurisdiction` (địa lý). Client dùng GPS để chọn đúng bộ rule và đúng version theo thời điểm sự kiện.

---

## 4. Lộ trình theo giai đoạn

### Giai đoạn 0 — Phạm vi và pháp lý (ước lượng 2–4 tuần)

**Mục tiêu:** chốt phạm vi hẹp và chế độ vận hành (chỉ cảnh báo).

**Hoạt động**
- Chọn 3–5 loại vi phạm rõ ràng, ít nhập nhằng (ví dụ: đèn đỏ, vạch liền, biển cấm vượt, tốc độ).
- Xây bộ **predicate vocabulary** dùng chung giữa scene graph và luật.
- Liệt kê văn bản nguồn cần dùng, kể cả văn bản địa phương.
- Đánh giá quyền riêng tư (hình ảnh người khác, biển số) và nơi lưu dữ liệu.
- Xác định thiết bị mục tiêu (dòng điện thoại, kính AR) và ngân sách độ trễ, pin, nhiệt.

**Sản phẩm:** tài liệu phạm vi, danh sách predicate, danh sách văn bản nguồn, đánh giá quyền riêng tư.

**Tiêu chí qua cổng:** luật sư xác nhận phạm vi; thống nhất rằng giai đoạn đầu chỉ cảnh báo, chưa dùng làm căn cứ xử phạt.

### Giai đoạn 1 — Perception nền (ước lượng 6–10 tuần)

**Mục tiêu:** nhận diện biển báo, vạch kẻ, đèn, phương tiện trong điều kiện giao thông Việt Nam.

**Hoạt động**
- Thu thập và gán nhãn video thực địa (nhiều thời điểm, thời tiết, góc camera).
- Huấn luyện detector và segmentation cho vạch kẻ; tích hợp tracker.
- Nén model, chạy thử trên thiết bị mục tiêu.
- Dựng scene graph có `valid_time`, TTL và quan hệ hình học cơ bản.

**Sản phẩm:** dataset có phiên bản, model chạy trên máy, scene graph streaming.

**Tiêu chí qua cổng:** đạt ngưỡng chất lượng đã đặt ra trên thiết bị thật; đo cả nhiệt độ và pin khi chạy liên tục. Nếu GNN quan hệ quá nặng, dùng quan hệ hình học trên máy và để server tinh chỉnh sau.

### Giai đoạn 2 — Lớp luật MVP (chạy song song Giai đoạn 1)

**Mục tiêu:** hình thức hoá tập rule của Giai đoạn 0 thành dạng tính toán được.

**Hoạt động**
- Pipeline: tách điều/khoản/điểm → LLM hỗ trợ trích vai trò ngữ nghĩa → sinh rule → luật sư duyệt.
- Rule tuple: `(φ, ℓ, E, τ, valid_from, valid_to, transaction_time, jurisdiction)`.
- Cài **overlap gate**: `C = AᵀA`, phân loại SUBSUMPTION / CONFLICTING / COMPATIBLE; cặp cần ưu tiên mà chưa khai báo thì chặn deploy.
- Xây rule compiler ra gói gồm mạng lọc predicate, automaton, ma trận ưu tiên `M`, hàm `f_j`.
- Dựng bộ **regression test** từ các tình huống có đáp án chuẩn.

**Sản phẩm:** rule base có version, compiler, overlap gate, bộ test.

**Tiêu chí qua cổng:** luật sư duyệt từng rule; bộ test lịch sử xanh; mọi cặp rule giao nhau đều có quan hệ ưu tiên hoặc được phân loại COMPATIBLE.

### Giai đoạn 3 — Runtime nhánh B trên client (ước lượng 4–6 tuần)

**Mục tiêu:** chạy suy luận pháp lý tại máy, không cần mạng.

**Hoạt động**
- Nạp compiled package, chọn đúng version theo thời điểm sự kiện và theo GPS (jurisdiction).
- Instance hoá automaton theo cặp (chủ thể, rule); xử lý vòng đời với ba trigger: trạng thái kết thúc, rời geofence chưa đủ điều kiện, quá TTL do mất tracking.
- Ghi log ký số: verdict, version rule, đầu vào, hash bằng chứng.
- **Replay** video có nhãn để đối chiếu verdict với đáp án chuẩn.

**Sản phẩm:** engine chạy trên máy, định dạng log, công cụ replay.

**Tiêu chí qua cổng:** verdict khớp đáp án trên bộ replay; chạy được offline; mọi verdict lần lại được từng bước.

### Giai đoạn 4 — Nhánh nguy cơ, LLM và đồng bộ (ước lượng 6–8 tuần)

**Mục tiêu:** hoàn thiện trải nghiệm cảnh báo và giải thích.

**Hoạt động**
- Huấn luyện risk model nhẹ (dự đoán quỹ đạo, khả năng vi phạm trong vài giây tới).
- Cảnh báo tới hạn bằng template trên máy; LLM giải thích gọi bất đồng bộ.
- Đồng bộ: package luật đi xuống, log và scene graph đi lên; cơ chế cập nhật package khi có mạng.
- Guardrail LLM: chỉ diễn đạt lại verdict và chuỗi bằng chứng, không thêm fact.

**Sản phẩm:** risk model, dịch vụ LLM explainer, đồng bộ hai chiều.

**Tiêu chí qua cổng:** cảnh báo tới hạn đạt mục tiêu độ trễ khi không có mạng; LLM không đưa ra thông tin ngoài chuỗi bằng chứng (kiểm bằng bộ test).

### Giai đoạn 5 — Pilot có kiểm soát và mở rộng (liên tục)

**Mục tiêu:** đo ngoài thực địa, học từ sai sót, mở rộng phạm vi luật.

**Hoạt động**
- Pilot với nhóm người dùng giới hạn; thu thập phản hồi và các ca bị gắn cờ.
- Active learning: ưu tiên gán nhãn các ca perception thiếu tin cậy.
- Hiệu chỉnh TTL và ngưỡng theo chất lượng tracker thực tế.
- Mở rộng rule theo độ phủ: đo tỷ lệ tình huống thực tế được rule bao phủ.
- Quy trình cập nhật luật chạy thông suốt (xem mục 7).
- Cân nhắc huấn luyện đầu–cuối qua circuit khả vi (Scallop-style) nếu có đủ dữ liệu có nhãn.

**Tiêu chí qua cổng:** tỷ lệ báo sai và bỏ sót ở mức chấp nhận được đã thoả thuận; quy trình cập nhật luật đã diễn tập ít nhất một lần.

> **Về chế độ kết luận vi phạm có hệ quả pháp lý:** chỉ cân nhắc sau pilot, khi đã lần lại được từng phán quyết cùng version luật và có tư vấn pháp lý.

---

## 5. Tech stack gợi ý

| Lớp | Lựa chọn tham khảo | Ghi chú |
|---|---|---|
| Detect, segmentation | Họ YOLO, RT-DETR, model segmentation cho vạch | Kiểm tra giấy phép từng thư viện nếu dùng thương mại |
| Tracking | ByteTrack | Nhẹ, phù hợp realtime |
| Suy luận trên máy | Core ML (iOS), LiteRT/TFLite, ONNX Runtime Mobile, NCNN | Chọn theo NPU của thiết bị thật |
| Scene graph (client) | Cấu trúc in-memory có TTL | Chỉ giữ cửa sổ thời gian gần |
| Rule engine (nhánh B) | Clingo (ASP), Soufflé (Datalog), Z3 (SMT), rule engine kiểu Rete | Chọn theo đặc thù luật; Rete chỉ là một lựa chọn |
| Server | Python + FastAPI, PostgreSQL, object storage | Dùng kiểu range của PostgreSQL để mô hình hoá hai trục thời gian |
| Graph DB (tuỳ chọn) | Neo4j | Chỉ cần nếu làm agent truy vấn scene graph phía server |
| LLM server | Mô hình tự host hoặc API, có template và guardrail | Không cho phép thêm fact ngoài verdict |
| Đồng bộ | gRPC/Protobuf, chữ ký số cho log | Package luật phải có version và hash |
| MLOps | Theo dõi thí nghiệm, CI chạy regression luật | Mỗi lần đổi luật đều phải chạy bộ test |

**Bảng chọn rule engine**

| Engine | Hợp khi |
|---|---|
| Rete / rule engine | Nhiều rule, fact đổi liên tục, cần cập nhật incremental |
| Datalog | Quan hệ đệ quy, suy diễn trên đồ thị lớn |
| ASP (Clingo) | Luật có ngoại lệ, mặc định, xung đột (defeasible) |
| SMT (Z3) | Ràng buộc số học (tốc độ, khoảng cách) cần chứng minh |
| Circuit khả vi (Scallop) | Muốn huấn luyện đầu–cuối qua phần luật |

---

## 6. Chỉ số đánh giá

| Nhóm | Chỉ số |
|---|---|
| Perception | Độ chính xác detect biển/vạch/đèn theo điều kiện (ngày/đêm/mưa); độ ổn định ID của tracker |
| Quan hệ | Độ chính xác các predicate hình học (cắt vạch, trong vùng biển) |
| Kết luận (nhánh B) | Tỷ lệ verdict đúng trên bộ replay; tỷ lệ ca chuyển cho người xem; tính tái lập từ log |
| Nguy cơ (nhánh A) | Độ chính xác dự báo, tỷ lệ báo sai gây phiền người dùng |
| Hệ thống | Độ trễ đầu–cuối, mức tiêu thụ pin và nhiệt, tỷ lệ hoạt động khi offline |
| Pháp lý | Tỷ lệ rule được luật sư duyệt; thời gian từ khi luật đổi tới khi package mới được phát hành |

---

## 7. Quy trình cập nhật luật

1. Phát hiện văn bản mới hoặc sửa đổi (kể cả văn bản địa phương).
2. LLM soạn nháp rule; luật sư xác định `valid_from`, `valid_to`, `jurisdiction`.
3. Chạy **overlap gate**: cặp rule giao nhau chưa có quan hệ ưu tiên thì chặn.
4. Chạy **regression test** trên tình huống lịch sử; so kết quả với phiên bản trước.
5. Biên dịch, ký và đưa lên package registry với version mới.
6. Client tải về khi có mạng; vẫn giữ các version cũ để xét vi phạm theo thời điểm xảy ra.
7. Lưu `transaction_time` để biết hệ thống biết về thay đổi từ khi nào.

---

## 8. Rủi ro chính và giảm thiểu

| Rủi ro | Giảm thiểu |
|---|---|
| Văn bản luật đổi liên tục và khác theo địa phương | Bitemporal + `jurisdiction`; quy trình cập nhật có gate tự động |
| Dữ liệu biển báo, vạch kẻ trong nước có đặc thù | Đầu tư dataset Việt Nam sớm; active learning |
| Thiết bị yếu (đặc biệt kính AR) | Đo trên thiết bị thật từ Giai đoạn 1; phương án quan hệ hình học nhẹ |
| Báo sai gây phiền hoặc nguy hiểm | Cảnh báo bằng ngưỡng; ca mơ hồ chuyển cho người; đo tỷ lệ báo sai |
| Rule chưa phủ hết tình huống | Rule chưa hình thức hoá thì chuyển người xem; đo độ phủ |
| Quyền riêng tư (người xung quanh, biển số) | Ưu tiên gửi scene graph thay vì video; chính sách lưu trữ rõ ràng |
| Hệ quả pháp lý của kết luận vi phạm | Giai đoạn đầu chỉ cảnh báo; log ký số; tư vấn pháp lý trước khi nâng cấp chế độ |
| Bằng chứng về hiệu quả hệ lai LLM + solver đến từ luật thuế, chưa phải giao thông | Tự đánh giá trên dữ liệu giao thông của mình trước khi cam kết |

---

## 9. Câu hỏi mở cần chốt sớm

1. Thiết bị kính AR cụ thể nào sẽ là mục tiêu (quyết định mức nén model)?
2. Chế độ vận hành cuối cùng: cảnh báo cho người lái, ghi nhận vi phạm của người khác, hay cả hai?
3. Phạm vi địa lý của giai đoạn đầu (một thành phố hay toàn quốc)?
4. Chính sách lưu trữ và chia sẻ dữ liệu hình ảnh, và ai là bên chịu trách nhiệm pháp lý.
5. Nguồn dữ liệu luật chính thức dùng để nạp và cách theo dõi thay đổi.

---

## 10. Tài liệu tham khảo kỹ thuật

- SGTA — Scene-Graph Traffic Agent: https://arxiv.org/abs/2604.03697
- Scallop — lập trình neurosymbolic khả vi: https://arxiv.org/abs/2304.04812
- Language Models and Logic Programs for Trustworthy Tax Reasoning: https://arxiv.org/abs/2508.21051
- Thuật toán Rete: https://en.wikipedia.org/wiki/Rete_algorithm
