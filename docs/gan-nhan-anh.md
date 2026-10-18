# Gán nhãn ảnh cho lớp luật

Nhãn ghi thứ nhìn thấy trong một khung hình. Lớp luật đọc các trường này rồi mới quyết định biển hoặc đèn có ràng buộc xe đang chạy hay không. Trên ảnh không ghi “vi phạm”, không ghi “biển này áp dụng cho xe mình”.

Camera sản phẩm nhìn về phía trước, gắn tay lái hoặc kính. Xe mình thường không có trong khung. Tốc độ lấy từ GPS của điện thoại, không nhìn từ ảnh.

Mã biển dưới đây theo bộ điều kiện xe máy trong `legal/rules/xe_may/phat_hien.md`. Đọc không ra mã thì ghi `unknown`. Không đoán.

## Bốn việc dễ gán thiếu

Chỉ đánh dấu làn xe mình thì đủ với biển áp cho cả chiều đi, như P.102 hay P.127 một con số. Không đủ với biển phân làn, trần tốc độ theo làn, đèn trên từng làn, và lúc xe đè vạch. Những trường hợp đó cần mọi làn cùng chiều mà biển hoặc đèn đang nói tới, cộng với vạch nằm giữa chúng.

Biển phân làn là một hộp, bên trong có nhiều ô xếp từ trái sang phải. Mỗi ô là một làn trên mặt biển: hướng đi, loại xe, hoặc số tốc độ của ô đó. Ô chỉ được nối với một làn trên đường khi số ô khớp số làn cùng chiều đang thấy và thứ tự không lệch. Lệch hoặc khuất thì để mối nối trống.

Biển “làn nào, xe nào” ghi loại xe vào đúng ô hoặc đúng làn, đúng hình vẽ trên biển. P.104 là mô tô. P.111a là xe gắn máy. Hai mã này không suy ra cho nhau.

Xe chạy giữa hai làn thì điểm mốc nằm trên vạch. Không chọn một làn làm làn của xe. Hai làn kề đều được nối với điểm mốc, và vạch ở giữa ghi là xe đang đè.

Không cần thấy thân xe mình. Yếu tố bắt buộc là một điểm trên mặt đường, chỗ bánh xe đang đặt. Với camera nhìn trước, người gán chấm điểm đó ở giữa bề ngang, trên mặt đường sát mép dưới ảnh. Gương, tay lái hoặc mép yên lọt vào khung thì bỏ qua, không đóng hộp thành một xe.

## Điểm mốc và làn

Mỗi ảnh có một điểm `diem_xe`. Không thấy mặt đường dưới camera thì để `unknown`. Khi đó không làn nào được đánh là làn xe mình.

`lane_id` là tên trong ảnh này để biển, đèn và xe khác trỏ tới. Sang ảnh khác tên đó không còn nghĩa. Thứ tự pháp lý nằm ở `thu_tu`.

Mỗi làn cùng chiều đếm từ lề phải vào tim đường: `1` sát lề phải, `2` là làn bên trái của nó. Làn ngược chiều đếm lại từ đầu. Chỉ ghi `thu_tu` khi thấy mép phải hoặc vạch đủ để biết làn nào sát lề.

| Trường làn | Ý nghĩa |
|---|---|
| `id` | Tên để nhãn khác trỏ tới, chỉ trong ảnh này |
| `thu_tu` | 1, 2, 3… trong một chiều, từ lề phải vào tim |
| `chieu` | `cung_chieu` hoặc `nguoc_chieu` |
| `danh_cho` | Chữ hoặc hình sơn trong làn: buýt, xe đạp, xe máy, ô tô. Không có thì trống |
| `ke_diem_moc` | Điểm mốc chạm làn này. Xe nằm giữa hai làn thì cả hai làn đều đúng |

Vạch là một polyline từ đầu đến cuối đoạn còn nhìn thấy, kể cả khoảng trống của vạch đứt. Thẳng thì 2 điểm. Cong thì thêm điểm, vẫn một nhãn. Không vẽ từng nét đứt.

| Trường vạch | Ý nghĩa |
|---|---|
| `ma` | 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 3.2, 3.3, 6.2, 7.1, 7.3, hoặc `unknown` |
| `mau` | Vàng hoặc trắng |
| `net` | Liền, đứt, đôi liền, một liền một đứt, liền rộng, đứt rộng |
| `phia_lien` | Với 1.4 và 2.4: bên trái hay bên phải theo hướng xe đi là nét liền |
| `diem_moc_tren_vach` | Điểm mốc đang nằm trên vạch này |

## Trường chung của mọi biển

Biển dùng một hộp quanh mặt biển. Biển phụ dính liền thì ghi trong `bien_phu`, không tách thành biển cấm riêng.

| Trường | Ghi gì |
|---|---|
| `ma` | P.127, R.411, R.403e… hoặc `unknown` |
| `dang` | `mot_lenh`, `phan_lan`, `het_lenh`, `canh_bao` |
| `gia_tri` | Số km/h hoặc số mét nếu biển chỉ có một số |
| `doi_tuong` | Hình xe trên biển: mô tô, xe gắn máy, ô tô, tải, buýt, xe đạp, người đi bộ. Nhiều hình thì ghi hết. Không có hình thì trống |
| `huong` | Thẳng, trái, phải, quay đầu. Nhiều hướng thì ghi hết |
| `cam` | Đúng nếu biển cấm hướng hoặc cấm loại xe đó. Biển bắt buộc đi theo hướng thì để sai |
| `lap` | Cố định trên cột, hay biển tạm |
| `huong_mat` | Quay vào camera, quay đi, hay quay ngang |
| `pham_vi` | `chieu_di` nếu biển cho cả chiều. `tung_lan` nếu có nhiều ô |
| `o_lan` | Các ô từ trái sang phải trên mặt biển. Trống nếu biển không chia ô |
| `bien_phu` | Giờ, loại xe, hướng, khoảng cách. Cấm theo giờ chỉ khi đọc được biển phụ S.508 |
| `vach_dung_id` | Vạch 7.1 đi cùng biển dừng, nếu cùng thấy |
| `khop` | Nối từng ô với `lane_id` trên đường. Chỉ điền khi số ô và thứ tự khớp phần đường đang thấy |

Một ô trong `o_lan`:

| Trường ô | Ghi gì |
|---|---|
| `thu_tu_tren_bien` | 1 là ô trái nhất trên mặt biển |
| `huong` | Mũi tên của ô |
| `doi_tuong` | Xe được vẽ trong ô, hoặc xe bị gạch trong ô |
| `cam` | Ô đang cấm những xe hoặc những hướng đó |
| `toc_do` | Số km/h của ô, nếu có |
| `lane_id` | Làn trên đường khớp ô này. Không khớp thì trống |

## Các dạng biển

### Cấm vào

| Mã | Nhìn thấy | Trường cần có |
|---|---|---|
| P.101 | Cấm cả hai hướng | `pham_vi: chieu_di`. Có rào chắn phía sau thì ghi thêm vật cản, không đổi mã biển |
| P.102 | Cấm đi vào theo chiều biển | `huong_mat` bắt buộc. Biển quay đi thì không dùng cho chiều xe mình |

### Cấm theo loại xe

Ghi đúng hình trên biển vào `doi_tuong`. Biển cấm ô tô, tải, buýt, taxi vẫn gán, để lớp luật bỏ qua với xe máy.

| Mã | Hình trên biển | Với xe máy |
|---|---|---|
| P.104 | Mô tô | Chỉ mô tô. Không suy ra xe gắn máy |
| P.105 | Ô tô và mô tô | Mô tô |
| P.111a | Xe gắn máy | Chỉ xe gắn máy. Không suy ra mô tô |
| Cấm ô tô, tải, khách, buýt | Đúng loại đó | Vẫn gán nhãn. Luật xe máy không dùng để kết luận |

Chưa tách được mô tô với xe gắn máy trên biển thì `ma: unknown`, không ghi P.104 hay P.111a.

### Cấm hướng và bắt buộc hướng

| Mã | Nội dung | Trường |
|---|---|---|
| P.123a / P.123b | Cấm rẽ trái / cấm rẽ phải tại chỗ đặt biển | `huong`, `cam: đúng` |
| P.124a, c, d | Cấm quay đầu, hoặc cấm quay đầu kèm cấm rẽ, cho cả xe máy | `huong` gồm quay đầu và hướng rẽ nếu có |
| P.124b, e, f | Chỉ cấm ô tô quay đầu hoặc ô tô rẽ | `doi_tuong: o_to` |
| P.136 đến P.139 | Cấm thẳng, cấm rẽ, hoặc cấm một tổ hợp | Liệt kê hết hướng bị cấm |
| R.301 | Phải đi theo hướng mũi tên | `cam: sai`, `huong` là hướng được đi |
| R.122 | Phải dừng | `vach_dung_id` nếu thấy vạch 7.1 |

### Tốc độ

| Dạng | Nhìn thấy | Trường |
|---|---|---|
| P.127 | Một số, cả chiều | `gia_tri`, `pham_vi: chieu_di` |
| P.127a | Trần ban đêm | `gia_tri`, `gio: dem` |
| P.127b, P.127c | Nhiều số theo làn, hoặc theo loại xe trên làn | `dang: phan_lan`, mỗi ô một `toc_do` và `doi_tuong` nếu có hình xe |
| Hết hạn chế tốc độ | Gạch chéo một số | `dang: het_lenh`, `gia_tri` là số bị hết hạn |
| Không thấy số | Biển tốc độ mờ | `ma: unknown`. Không điền số |

P.127b và P.127c trong bộ luật xe máy đều là trần theo làn hoặc theo loại xe trên làn. Số của ô nào thì để trong ô đó. Xe đè vạch thì không gán số của một ô cho xe.

### Phân làn và làn dành riêng

Biển vẽ nhiều làn trên một mặt, vn-82 gọi là biển phân làn. Mỗi mũi tên hoặc mỗi loại xe là một ô, trái sang phải.

Ví dụ mặt biển ba ô: ô trái mũi tên thẳng cho ô tô, ô giữa thẳng cho xe máy, ô phải rẽ phải. `o_lan` có ba phần tử. Đường phía dưới cũng có đúng ba làn cùng chiều và biển treo đối diện các làn đó thì `khop` nối ô 1 với làn `thu_tu` tương ứng. Thấy hai làn, hoặc biển nằm lệch, thì `lane_id` của mọi ô để trống.

| Dạng | Cách gán |
|---|---|
| Hướng đi trên từng làn | `dang: phan_lan`. Mỗi ô một hoặc nhiều `huong` |
| Làn nào được đi loại xe nào | `doi_tuong` của từng ô. Xe bị gạch trong ô thì `cam: đúng` |
| R.403a, c, d, g, h, k | Đường hoặc làn cho ô tô, buýt hoặc xe bốn bánh. `doi_tuong` là loại được vẽ. `pham_vi: tung_lan` chỉ khi biển hoặc vạch chỉ một làn |
| R.403e | Dành cho xe máy |
| R.403b, f | Ô tô và xe máy, hoặc xe máy và xe đạp |
| Chữ sơn trong làn, như làn buýt | Không phải biển. Ghi `danh_cho` trên polygon làn. Vạch 2.3 vẫn là polyline mép làn |
| Biển bên lề không chỉ rõ làn | `pham_vi: chieu_di`, `o_lan` trống |

### Dừng, đỗ, vượt, khoảng cách

| Mã | Trường thêm |
|---|---|
| P.130 | Cấm dừng và cấm đỗ. `pham_vi: chieu_di` trừ khi biển phụ chỉ một phía |
| P.131 | Chỉ cấm đỗ |
| Cấm đỗ ngày lẻ, ngày chẵn | `gio` hoặc lịch trên biển phụ. Không đọc được lịch thì `unknown` |
| P.125 | Cấm vượt. Hiệu lực đến nút tiếp theo hoặc đến biển hết cấm. Một ảnh không ghi đoạn đó đã hết |
| P.121 | `gia_tri` là số mét |

Vạch 6.2 vàng liền ở mép đường là cấm dừng và cấm đỗ. Đó là nhãn vạch, không phải biển.

### Biển đổi cách hiểu cả con đường

Những biển này không gắn một `lane_id`. Chúng cho biết cách đếm làn và cách lấy trần tốc độ khi không có P.127.

| Dạng | Trường |
|---|---|
| Bắt đầu khu đông dân cư | `dang: mot_lenh`. Chỉ có nghĩa khi sau này thấy biển hết. Một ảnh không tự ghi “đang ở trong khu dân cư” nếu không thấy biển bắt đầu |
| Hết khu đông dân cư | `dang: het_lenh` |
| Đường một chiều | `dang: mot_lenh`. Làn ngược chiều trên ảnh phải trống hoặc không có |
| Đường đôi | Có dải phân cách. Làn ngược chiều vẫn gán, `chieu: nguoc_chieu` |
| Hết mọi lệnh cấm | `dang: het_lenh` |

### Biển phụ

Gắn vào biển chính. Một biển chính có thể có nhiều biển phụ.

| Loại nhìn thấy | Ghi vào `bien_phu` |
|---|---|
| Khung giờ, mã S.508 | `loai: gio`, `noi_dung` là giờ đọc được |
| Hình loại xe | `loai: loai_xe`, `doi_tuong` |
| Mũi tên chỉ bên trái hoặc bên phải đường | `loai: huong` |
| Cự ly có hiệu lực | `loai: khoang_cach`, `gia_tri` mét |
| Phụ mờ | `loai: unknown` |

Không có S.508 thì không bịa giờ cấm.

### Biển cảnh báo

Nhóm nguy hiểm, cua, người đi bộ cắt ngang, đường trơn, trẻ em, công trường: `dang: canh_bao`. Vẫn khoanh hộp và ghi mã nếu đọc được. Nhóm này không tự thành một lệnh cấm.

## Các dạng đèn

Mỗi cụm đèn một hộp. Cột có ba đèn cho ba hướng là ba nhãn. Đèn đếm ngược là nhãn phụ của cụm mà nó gắn vào, không thay màu đèn.

| Dạng | Trường |
|---|---|
| Đèn tròn đỏ, vàng hoặc xanh | `mau`. `mui_ten` trống. `huong_mat` quay vào camera hay sang hướng khác |
| Đèn mũi tên | `mau` và `mui_ten`: thẳng, trái, phải, quay đầu |
| Vừa đèn tròn vừa mũi tên khác màu | Hai trạng thái trong cùng cụm, ví dụ đỏ tròn và xanh rẽ phải. Ghi cả hai, không gộp thành một màu |
| Vàng nhấp nháy | `mau: vang`, `nhap_nhay: dung` |
| Đỏ nhấp nháy ở đường sắt | `mau: do`, `nhap_nhay: dung`, `cho: duong_sat`. Thấy chắn hoặc chuông thì ghi thêm, không đổi màu |
| Đèn trên từng làn | Mũi tên xanh hoặc chữ X đỏ treo trên một làn. `dang: theo_lan`, `lane_id` của làn ngay dưới đèn. Không thấy làn dưới đèn thì `lane_id` trống |
| Đèn người đi bộ | Nhãn riêng, `doi_tuong: nguoi_di_bo`, `mau` |
| Số đếm ngược | `giay` là số đang hiện. Không có số thì bỏ |
| Tắt, khuất, chói | `mau: unknown` |
| Người điều khiển giao thông | Nhãn người, `vai_tro: dieu_khien`. Không ghi thành đèn |

Đèn theo làn dùng cùng cách khớp với biển phân làn: một đèn nối một làn khi đèn nằm trên làn đó. Xe đè vạch giữa hai đèn thì không lấy màu của một đèn.

## Xe khác và người

Hộp chữ nhật. Cần họ vì luật còn nhìn xe cùng làn, người trên vạch, người điều khiển giao thông.

| Đối tượng | Trường |
|---|---|
| Xe | `loai`: xe máy, ô tô, buýt, xe đạp, xe ưu tiên. Xe máy không tách mô tô với xe gắn máy nếu ảnh không chỉ ra. `lane_id` khi cả xe nằm trong một làn |
| Người đi bộ | `vai_tro: nguoi_di_bo`. `vach_id` nếu đang trên vạch 7.3 |
| Người trên xe | `xe_id`, `mu`: có, không, hoặc `unknown` |
| Người điều khiển giao thông | `vai_tro: dieu_khien` |

## Một khung hình

Đường một chiều, ba làn. Biển phân làn ba ô treo trước mặt: ô trái thẳng dành ô tô, ô giữa thẳng dành xe máy, ô phải rẽ phải. Điểm mốc nằm trên vạch giữa làn 2 và làn 3.

- Ba làn `cung_chieu`, `thu_tu` 1, 2, 3 từ phải sang trái. Không làn nào một mình là làn xe mình.
- Làn 2 và làn 3 có `ke_diem_moc: đúng`.
- Vạch trắng giữa hai làn đó có `diem_moc_tren_vach: đúng`, `net` đúng loại sơn nhìn thấy.
- Biển một hộp, `dang: phan_lan`, ba ô. Khớp ô với ba làn vì đủ số và biển đối diện đúng các làn.
- Trần tốc độ của ô giữa không gán cho xe, vì điểm mốc chưa nằm trọn trong làn đó.

Cùng biển đó, nhưng điểm mốc nằm hẳn trong làn giữa: chỉ làn đó có `ke_diem_moc`. Ô giữa nối làn đó. Các ô còn lại vẫn gán, vì chuyển làn sang đó sẽ cần.

Biển P.127 một số 50 bên lề, không có ô: `pham_vi: chieu_di`, `o_lan` trống. Vẫn nên gán hết làn cùng chiều nếu thấy, nhưng biển không cần `lane_id`.
