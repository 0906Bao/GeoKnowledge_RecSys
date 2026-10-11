# GeoKnowledge & RecSys

Ứng dụng học hình học phẳng bằng tiếng Việt: Flask + Neo4j, không sử dụng SQL.

## Chức năng
- Tra cứu 8 nhóm hình: tứ giác, hình thang, hình thang cân, hình thang vuông, hình bình hành, hình chữ nhật, hình thoi, hình vuông.
- Mỗi khái niệm có định nghĩa, tính chất/dấu hiệu nhận biết, định lý, công thức, mẹo học và bài tập mẫu.
- Đồ thị phân cấp tương tác; cạnh `IS_A` đi từ hình con đến hình cha, chỉ lưu quan hệ cha trực tiếp để sơ đồ không rối. Quan hệ gián tiếp được suy ra qua đường đi.
- Luyện tập trắc nghiệm và nhập đáp án; phản hồi đáp án/lời giải; gợi ý bài cùng khái niệm theo mức độ.
- Trang quản lý nội dung; không yêu cầu tài khoản và không lưu lịch sử làm bài dài hạn.

## Chạy trên Windows
1. Cài Python 3.10+ và chạy DBMS trong Neo4j Desktop.
2. Tạo/khởi động database trong DBMS. Neo4j Desktop 2.2 là phiên bản ứng dụng Desktop; hãy xem phiên bản Neo4j Server bên trong DBMS nếu gặp lỗi Cypher.
3. Sao chép `.env.example` thành `.env` và đặt mật khẩu đúng.
4. Trong Neo4j Browser, chạy `cypher/schema.cypher`, sau đó chạy toàn bộ `cypher/seed.cypher`.
5. Trong thư mục dự án:
   ```powershell
   py -m venv .venv
   .\.venv\Scripts\Activate.ps1
   pip install -r requirements.txt
   python app.py
   ```
6. Mở http://127.0.0.1:5000

## Cấu hình
`.env` hỗ trợ `NEO4J_URI`, `NEO4J_USER`, `NEO4J_PASSWORD`, `NEO4J_DATABASE`, `FLASK_SECRET_KEY`, `FLASK_DEBUG`, `FLASK_HOST`, `FLASK_PORT`.

## Mô hình dữ liệu Neo4j
Nhãn: `Concept`, `Property`, `Theorem`, `Formula`, `Tip`, `Exercise`.
Quan hệ: `IS_A`, `HAS_PROPERTY`, `HAS_THEOREM`, `HAS_FORMULA`, `HAS_TIP`, `HAS_EXERCISE`, `APPLIES_TO`, `REQUIRES_PREREQUISITE`.

## Ghi chú nội dung
Dữ liệu là bộ khởi đầu phục vụ phát triển; cần giáo viên đối chiếu câu chữ, phạm vi định nghĩa hình thang và nội dung bài tập với đúng ấn bản SGK trước khi dùng chính thức. Hệ thống chấm tự luận bằng so khớp chuỗi đã chuẩn hóa, chưa đánh giá được chứng minh hình học mở. Trang `/admin` chưa có đăng nhập/phân quyền; chỉ chạy cục bộ hoặc mạng tin cậy.
