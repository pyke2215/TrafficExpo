# Kiến trúc AI phát hiện vi phạm giao thông

Mind map tương tác — perception, scene graph, legal knowledge layer, neuro-symbolic reasoning. Bấm vào tiêu đề để mở/đóng từng phần. DL = dùng deep learning · SYM = thuần toán/logic, không học · LLM = mô hình ngôn ngữ.

0\. Tổng quan luồng 6 lớp

Camera → [Perception/Scene Graph](#l1) → [Grounding](#grounding) ⇐ [Legal Knowledge Layer](#l2) ⇐ Văn bản luật

Grounding → [Neuro-symbolic Reasoning Engine](#l3) → [LLM Explainer](#l4) → Verdict cho người dùng

Triết lý cốt lõi: tách **neural** (chỗ quan hệ chưa biết trước, phải học từ dữ liệu — thị giác, ngôn ngữ) khỏi **symbolic** (chỗ quan hệ đã biết chính xác — luật), để quyết định pháp lý cuối luôn [audit được](#t-audit). Toàn bộ hệ còn phải xử lý đúng chiều thời gian thực và cập nhật luật — xem mục 8, lời giải [bitemporal](#t-validtime). Sau khi tách nhánh nguy cơ (DL) khỏi nhánh kết luận (symbolic), xem sơ đồ module đầy đủ ở [mục 9](#split), và cách chia client/server ở [mục 10](#deploy).

1\. Perception → Scene Graph DL

Biến video thô thành [scene graph](#t-scenegraph) có cấu trúc: objects\[\], static_elements\[\] (biển báo/vạch), relations\[\] (quan hệ không gian-thời gian).

Backbone detector DL

CNN/Transformer thị giác (YOLO, DETR) + segmentation cho vạch kẻ. Phát hiện object, biển báo, vạch, xuất bbox + class.

Multi-object tracker DL

ByteTrack/DeepSORT — mạng re-identification embedding gán ID xuyên frame, tính quỹ đạo và vận tốc.

📷 Self info vs context — theo loại camera

Camera gắn trên xe/kính/điện thoại + app biết trước biển số, loại xe, tài xế → **self không cần detect**, inject thẳng vào belief vector `x(t)`, bỏ qua perception cho riêng phần này. Camera cố định (roadside) vẫn phải detect + track *mọi* xe qua, kể cả việc xác định "xe nào đang quan tâm".

|  | Camera cố định | Camera trên người dùng |
| --- | --- | --- |
| Automaton cho | mọi xe qua (nhiều instance) | chủ yếu self (ít, dài hơi) |
| Zone-exit check | suy luận từ pixel | so toạ độ GPS — rẻ, chắc hơn |
| `is_emergency_vehicle(self)` | LLM visual-check, confidence thấp | fact từ đăng ký xe, chắc chắn |

Relation head (GNN + attention) DL

Message-passing giữa node/edge để dự đoán quan hệ (vd "crossed", "within_zone_of") — cần vì dự đoán cục bộ từng cặp bỏ qua ngữ cảnh xung quanh, còn suy luận đồng thời giải quyết được sự mơ hồ đó.

Agentic alternative hiện đại: để scene graph nằm trong graph DB (Neo4j), LLM phát [truy vấn Cypher](#t-cypher) thay vì đọc caption — xem [SGTA (arXiv 2604.03697)](https://arxiv.org/abs/2604.03697).

{ "objects":\[{"id":"v1","track":\[{"t":40.0,"x":12.3,"lane":"L2"}\]}\], "static_elements":\[{"id":"line_1","type":"lane_marking","style":"solid"}\], "relations":\[{"subject":"v1","predicate":"crossed","object":"line_1","t":42.3}\] }

⏱ Realtime: temporal graph, không phải batch

Mỗi node/edge mang [valid_time](#t-validtime) riêng (vd `speed_limit(zone_5,60,valid=[t1,t2])`) — context thay đổi khi xe di chuyển chỉ là tra lọc theo khoảng hiệu lực, không phải suy luận lại.

[TTL/sliding window](#t-ttl) loại bỏ thực thể quá cũ khỏi graph đang hoạt động, tránh phình bộ nhớ.

Automaton được **instance hoá theo từng cặp (xe, rule)** — tạo khi xe vào vùng áp dụng, huỷ/archive khi rời vùng hoặc rule đã resolve — không phải một graph toàn cục duy nhất.

2\. Legal Knowledge Layer compiled offline

Biến văn bản luật thành [logic tính toán được](#t-dcl) — **chạy một lần** khi luật thay đổi, không phải mỗi request.

Document parser / chunker

Tách theo điều, khoản, điểm.

Semantic role extraction LLM hỗ trợ, 1 lần

Xác định chủ thể, hành vi, điều kiện, ngoại lệ — theo pipeline 4 bước kiểu S4L (trích xuất vai trò → hoàn thiện ngữ cảnh → ánh xạ logic → định dạng).

Logic formalizer

Sinh rule Prolog/ASP với [deontic modal](#t-ddl) (nghĩa vụ/cấm/miễn trừ):

violation(overtaking, V) :- crossed(V, solid_line, T), within_zone_of(V, sign(no_overtake), T), not exception(emergency_vehicle, V).

Conflict / priority resolver

Gán quan hệ ưu tiên ([superiority relation](#t-superiority)) giữa các rule xung đột — hiện thực hoá nguyên tắc *lex specialis derogat legi generali*.

**Phát hiện overlap tự động** bằng chính ma trận `A`, chạy như một gate khi deploy rule mới:

C = Aᵀ·A // C\[i,j\] = số predicate chung giữa rule i, j for (i,j) với C\[i,j\] > 0: nếu antecedent_j ⊆ antecedent_i → SUBSUMPTION (cần priority) nếu cùng mô tả 1 hành vi → CONFLICTING (cần priority) else → COMPATIBLE (không cần) nếu cần priority mà M\[i,j\]=M\[j,i\]=0 → chặn deploy, báo luật sư

Human validation + KG builder

Luật sư review trước khi ghi triples vào knowledge graph — bắt buộc, không tuỳ chọn.

⏱ Cập nhật luật: rule tuple mang theo thời gian

r_j = ( φ_j, ℓ_j, E_j, τ_j, valid_from, valid_to, ← ngày luật có hiệu lực pháp lý transaction_time ) ← ngày hệ thống ghi nhận bản vá

Vi phạm tại thời điểm *t* được xét theo rule có `valid_from ≤ t < valid_to` — không dùng luật mới nhất cho vụ việc cũ.

Thêm rule mới = vá cục bộ vào mạng đã biên dịch (thuộc tính incremental của Rete), kèm 2 bước bắt buộc: khai báo quan hệ ưu tiên với mọi rule giao nhau predicate, và chạy regression test trên case lịch sử đã có verdict chuẩn trước khi deploy.

3\. Biên dịch thành 5 cấu trúc toán học compile-time

| Ký hiệu | Dạng toán học | Vai trò |
| --- | --- | --- |
| `P` | Tập hợp | từ vựng predicate chung |
| `A` | Ma trận predicate×rule | lọc rule ứng viên ([alpha match](#t-alpha)) |
| `f_j(x)` | Hàm/circuit (×,+) | tính xác suất vi phạm |
| `Automaton_j` | Máy trạng thái hữu hạn | xử lý thứ tự thời gian |
| `M` | Ma trận quan hệ thứ tự | giải xung đột đa-rule |

Cơ chế biên dịch rule→network để tránh quét lại toàn bộ rule base mỗi sự kiện bắt nguồn từ [thuật toán Rete](https://en.wikipedia.org/wiki/Rete_algorithm) (Forgy, 1970s): compile-time dựng discrimination network, runtime chỉ lan truyền thay đổi. Rete chỉ là một lựa chọn engine — có thể thay bằng Datalog/ASP/SMT, xem [mục 9](#split).

4\. Grounding / Alignment

Unification engine: khớp predicate name + type + time-window giữa scene graph và tiền đề luật. Không dùng similarity ngôn ngữ mờ — trừ fallback.

Fallback khi không khớp chính xác DL

Embedding model (KG/sentence embedding) tìm predicate luật gần nhất — luôn gắn cờ "cần review", không tự ra verdict.

5\. Neuro-symbolic Reasoning Engine

Fact ingestion

Nạp belief vector `x(t) ∈ [0,1]ⁿ` từ sự kiện scene graph.

LLM fact-completion agent LLM

Suy luận predicate còn thiếu mà rule hình học không tự xác định được (vd nhận diện xe ưu tiên qua hình ảnh).

Symbolic solver (ASP/Prolog) SYM

Giải model thoả rule + fact — deterministic, audit được.

Defeasible conflict resolver SYM

Áp ma trận `M`: loại rule bị đè dù xác suất cao hơn.

⏱ Vòng đời automaton instance

Mỗi instance (subject, rule) có 3 trigger archive — hai đầu deterministic (thuộc chính δ), một mang tính heuristic:

① state ∈ TERMINAL → archive ngay, emit verdict nếu accept ② ra khỏi geofence chưa đủ điều kiện → archive "incomplete" ③ idle = now − last_seen_t > TTL → archive "tracking_lost"

Với camera ego, ② dùng GPS app cung cấp (so toạ độ) thay vì suy luận pixel — rẻ và chắc hơn; ③ hiếm khi cần cho self vì self luôn "trong khung hình" (camera gắn trên chính nó).

**Ví dụ số đầy đủ** (R1 cụ thể "cấm vượt" ≻ R2 chung "sai làn"):

x = \[p1=0.97, p2=0.99, p3=0.12\] (p3 = là xe ưu tiên?) Alpha match: match\[R1\]=2=|R1| ✓ match\[R2\]=1=|R2| ✓ Circuit: f_R1 = p1·p2·(1-p3) ≈ 0.845 f_R2 = p1·(1-p3) ≈ 0.854 Priority: M\[R1,R2\]=1 → loại R2 dù f_R2 cao hơn Verdict: R1, confidence 0.845

Trường phái hiện đại — [differentiable circuit](#t-circuit): thay vì fact nhị phân, lan truyền *xác suất* qua circuit bằng [provenance semiring](#t-semiring), cho phép gradient từ lỗi verdict lan ngược về tận trọng số backbone detector để huấn luyện đầu-cuối. Xem [Scallop (arXiv 2304.04812)](https://arxiv.org/abs/2304.04812).

6\. LLM Explainer LLM

Generation có ràng buộc: đọc verdict JSON + evidence_trail, sinh giải thích ngôn ngữ tự nhiên kèm trích dẫn điều luật. Guardrail đảm bảo không thêm fact ngoài evidence_trail.

7\. Phân vùng Neural vs Symbolic

**Cần Neural** (quan hệ chưa biết trước): backbone + tracker, GNN quan hệ, grounding fallback, LLM explainer.

**Chỉ Symbolic** (quan hệ đã biết từ luật): legal KG, alpha match, automaton, conflict resolver.

Không nên nén luật vào attention/mạng học — Kautz phân loại nhiều mức tích hợp neuro-symbolic (Symbolic\[Neuro\] → Neuro:Symbolic→Neuro); mức càng chặt càng khó audit. Compliance team audit được một rule đang fire trong lớp symbolic, không audit được quyết định của mô hình hộp đen.

8\. Realtime & cập nhật luật — lời giải chung: bitemporal SYM

Hai vấn đề tưởng khác nhau — ngữ cảnh thị giác đổi liên tục, và luật được sửa đổi theo thời gian — thực ra cùng một bài toán database kinh điển: mỗi dữ kiện cần 2 trục thời gian tách biệt.

| Trục | Ý nghĩa | Áp dụng cho scene graph | Áp dụng cho luật |
| --- | --- | --- | --- |
| [valid_time](#t-validtime) | Khi nào đúng ngoài đời | Biển/zone/đèn đang hiệu lực tại chỗ | Ngày điều luật có hiệu lực pháp lý |
| [transaction_time](#t-txtime) | Khi hệ thống ghi nhận | Lúc perception detect được | Lúc hệ thống cập nhật bản vá rule |

**Khả thi hình thức hoá "toàn bộ luật một lần"?** Không, và không cần — rollout theo độ phủ (ưu tiên case phổ biến/rõ ràng trước), predicate/case chưa hình thức hoá luôn escalate cho người thay vì mặc định "không vi phạm".

9\. Kiến trúc sau khi tách nhánh A: DL B: SYM

Camera → Perception (DL) → Scene graph (time) ⇒ Belief vector x(t) ⇐ App self info (inject)

x(t) ⇒ **A** Risk predictor → Risk score ┐

x(t) ⇒ **B** Grounding → Automaton + circuit → Priority resolver → Verdict ┤→ LLM explainer → Output

Văn bản luật ⇒ Parser/LLM → Overlap gate + test → Rule compiler → Compiled package ⇒ B

Dùng chung DL

Perception (detect, track, GNN quan hệ) → scene graph có [valid_time](#t-validtime)/TTL. Hợp với self info từ app (xe, tài xế, GPS/IMU) thành belief vector `x(t)`; self được inject, không detect.

Nhánh A — nguy cơ DL

Risk predictor (dự đoán quỹ đạo/VLM) → risk score xác suất. Phục vụ cảnh báo sớm, chấp nhận sai số, **không** làm căn cứ xử phạt.

Nhánh B — kết luận vi phạm SYM

Grounding → automaton + circuit `f_j(x)` → priority resolver (ma trận `M`) → verdict. Không có trọng số học được, audit được từng phép tính.

Offline — biên dịch luật người + LLM

Parser + LLM soạn rule (luật sư review) → overlap gate + regression test → rule compiler (version bitemporal) → compiled package cấp cho nhánh B. Human review phản hồi về luật và nhãn huấn luyện.

LLM explainer / composer LLM

Gộp cảnh báo sớm (A) + kết luận (B) + chỉ dẫn; chỉ diễn đạt lại kết quả đã có, không thêm fact.

**Chọn engine cho nhánh B** — Rete chỉ là một lựa chọn, không phải cốt lõi; cốt lõi là symbolic, biên dịch sẵn, deterministic, audit được:

| Engine | Hợp khi |
| --- | --- |
| Rete / rule engine | Nhiều rule, fact đổi liên tục, cần incremental |
| Datalog | Quan hệ đệ quy, suy diễn trên graph lớn |
| ASP (Clingo) | Ngoại lệ, mặc định, xung đột (defeasible) |
| SMT (Z3) | Ràng buộc số học (tốc độ, khoảng cách) cần chứng minh |
| Circuit khả vi (Scallop) | Muốn train đầu-cuối qua phần luật |

Cơ sở: các nghiên cứu 2026 về luật thuế cho thấy hệ lai LLM + solver symbolic đáng tin và tổng quát hoá tốt hơn LLM nguyên khối — lưu ý bằng chứng này đến từ luật thuế, chưa phải luật giao thông kèm thị giác. Xem [Language Models and Logic Programs for Trustworthy Tax Reasoning (arXiv 2508.21051)](https://arxiv.org/abs/2508.21051).

10\. Triển khai client / server

**Quy tắc:** cái gì cần ngay và an toàn thì ở client; cái gì nặng, tập trung hoặc cần kiểm toán thì ở server. Mọi đường cảnh báo tới hạn không được phụ thuộc mạng.

Client (điện thoại / kính AR) DL nhẹ SYM

Capture + self info (camera, GPS/IMU, hồ sơ xe) → perception ra scene graph (model nhẹ trên NPU) → **runtime nhánh B** (automaton, circuit, ma trận `M`) → risk nhẹ + cảnh báo tại chỗ bằng template → log ký số (verdict + version rule + hash bằng chứng).

Compiled package nhỏ nên tải về máy được: chạy offline, latency thấp, dữ liệu thô không rời thiết bị. Client chọn package theo `valid_from/valid_to` kể cả khi offline.

Server LLM

Biên dịch luật (parser, overlap gate, regression test) → package registry có version bitemporal → phát hành xuống client. LLM explainer và soạn rule gọi bất đồng bộ. Audit log + huấn luyện lại / active learning từ dữ liệu client gửi lên.

Luồng đồng bộ

server → client : package luật (versioned) client → server : scene graph / verdict + hash (async) client ⇄ server : yêu cầu giải thích LLM (async)

Gửi scene graph (vài KB có cấu trúc) thay vì video giúp tiết kiệm băng thông và bảo vệ quyền riêng tư người xung quanh.

Điểm cần cẩn trọng

- **Sức mạnh thiết bị:** detect/track/GNN trên điện thoại có NPU khả thi; kính AR rất tuỳ máy (nhiệt, pin). Cần đo thực tế; nếu GNN quá nặng, dùng quan hệ hình học trên máy và để server tinh chỉnh.
- **Bằng chứng pháp lý:** ghi version rule, đầu vào và hash bằng chứng, ký số rồi đồng bộ.
- **Đồng bộ version:** client tự cập nhật package khi có mạng.

📖 Thuật ngữ

Scene graph

Biểu diễn đồ thị: object/biển báo/vạch là node, quan hệ không gian-thời gian là edge.

Logic tính toán được (computable law)

Luật được hình thức hoá thành predicate/rule máy xử lý được, thay vì chỉ là văn bản.

Defeasible Deontic Logic

Logic mô hình nghĩa vụ/cấm/cho phép, có cơ chế xử lý ngoại lệ và xung đột giữa các luật.

Superiority relation

Quan hệ ưu tiên giữa hai rule xung đột — rule nào thắng khi cả hai cùng fire.

Alpha match

Bước lọc nhanh rule ứng viên bằng cách tra ma trận/mạng đã biên dịch, không quét toàn bộ rule base.

Truy vấn Cypher

Ngôn ngữ truy vấn đồ thị (Neo4j) — agent dùng để duyệt scene graph thay vì đọc text thô.

Arithmetic / probabilistic circuit

Mạch tính gồm cổng nhân/cộng, biên dịch từ công thức logic, nhận xác suất predicate làm input.

Provenance semiring

Khung đại số cho phép lan truyền xác suất/gradient xuyên một chương trình logic.

Audit được

Có thể lần lại từng bước suy luận dẫn đến quyết định cuối — yêu cầu bắt buộc cho quyết định pháp lý.

valid_time

Khoảng thời gian một dữ kiện/quy định thực sự đúng ngoài đời (không phải lúc hệ thống biết về nó).

transaction_time

Thời điểm hệ thống ghi nhận/cập nhật một dữ kiện — trục thời gian thứ hai trong mô hình bitemporal.

TTL / sliding window

Cơ chế loại bỏ thực thể quá cũ khỏi bộ nhớ đang hoạt động, chuẩn trong xử lý luồng sự kiện (complex event processing).

🔗 Nguồn tham khảo

[SGTA — Scene-Graph Traffic Agent (arXiv 2604.03697)](https://arxiv.org/abs/2604.03697)

[Scallop — Neurosymbolic Programming (arXiv 2304.04812)](https://arxiv.org/abs/2304.04812)

[Rete algorithm (Wikipedia)](https://en.wikipedia.org/wiki/Rete_algorithm)

Mind map tổng hợp từ phiên thiết kế kiến trúc — bấm tiêu đề để mở/đóng, bấm thuật ngữ để nhảy tới định nghĩa.