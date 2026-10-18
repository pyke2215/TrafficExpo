# Kiến trúc

Bản mô tả kiến trúc đầy đủ: [Kiến trúc AI phát hiện vi phạm giao thông](./Kiến%20trúc%20AI%20phát%20hiện%20vi%20phạm%20giao%20thông.md).

Luồng chính:

```
Camera → Perception → Scene graph (valid_time, TTL)
App (xe, tài xế, GPS/IMU) → inject → Belief
  ├→ [A] Risk predictor → điểm nguy cơ
  └→ [B] Automaton + circuit → priority resolver → Verdict
Văn bản luật → parser / drafter → overlap gate + test → compiler → package
```

Phân chia chạy ở đâu:

| Trên thiết bị (`client/`) | Trên server (`server/`, `legal/`) |
|---|---|
| Perception, scene graph, belief | Biên dịch luật, overlap gate, regression |
| Runtime nhánh B, cảnh báo theo template | Registry package (bitemporal), phân phối |
| Risk nhẹ | LLM explainer và soạn nháp rule |
| Log ký số | Audit, huấn luyện, active learning |

Cách gán biển, đèn, làn và vạch trên một ảnh: [Gán nhãn ảnh cho lớp luật](./gan-nhan-anh.md).

Quyết định kiến trúc ghi trong [`adr/`](./adr/).
