Dưới đây là bản dịch tiếng Việt của tài liệu "15 Must-Know CAP Theorem Interview Questions in 2026" dựa trên nguồn từ GitHub mà bạn cung cấp. Tôi đã định dạng nó dưới dạng file `README.md` để bạn có thể sử dụng ngay.

# 15 Câu Hỏi Phỏng Vấn Về Định Lý CAP Cần Biết (Phiên bản 2026)

Tài liệu này tổng hợp các câu hỏi và câu trả lời phỏng vấn quan trọng về Định lý CAP, giúp bạn chuẩn bị cho các buổi phỏng vấn về kiến trúc phần mềm và thiết kế hệ thống.

---

### 1. Định lý CAP là gì và tại sao nó quan trọng đối với hệ thống phân tán?

**Định lý CAP**, được Eric Brewer đề xuất vào năm 2000, là một nguyên tắc cơ bản cho các **hệ thống phân tán**. Nó khẳng định rằng trong ba thuộc tính tiềm năng của hệ thống - **Consistency** (Tính nhất quán), **Availability** (Tính sẵn sàng), và **Partition Tolerance** (Khả năng chịu lỗi phân vùng) - một hệ thống phân tán không thể đảm bảo đồng thời cả ba.

#### Ba Thuộc Tính:

- **Consistency (C):** Tất cả các node trong hệ thống đều có cùng một dữ liệu tại cùng một thời điểm. Mọi dữ liệu được ghi vào hệ thống phải hiển thị ngay lập tức với tất cả các node.
- **Availability (A):** Mọi yêu cầu gửi đến hệ thống đều nhận được phản hồi, dù là dữ liệu được yêu cầu hay thông báo lỗi.
- **Partition Tolerance (P):** Hệ thống vẫn tiếp tục hoạt động bất chấp việc phân vùng mạng (ví dụ: mất tin nhắn hoặc một phần mạng bị hỏng).

#### Các sự đánh đổi (Trade-offs):

- **Hệ thống CP:** Ưu tiên Nhất quán và Chịu lỗi phân vùng. Thường thấy trong các RDBMS truyền thống nơi tính toàn vẹn dữ liệu là sống còn.
- **Hệ thống AP:** Ưu tiên Sẵn sàng và Chịu lỗi phân vùng. Thường thấy ở DynamoDB hoặc các NoSQL database chú trọng tính sẵn sàng cao.
- **Hệ thống CA:** Đảm bảo Nhất quán và Sẵn sàng nhưng không chịu được lỗi phân vùng. Thực tế ít được coi là hệ thống phân tán thực thụ vì chúng không thể hoạt động nếu mạng bị ngắt.

---

### 2. Định lý CAP định nghĩa "Consistency" (Tính nhất quán) như thế nào trong bối cảnh hệ thống phân tán?

Trong bối cảnh này, Consistency nhấn mạnh rằng tất cả các node trong hệ thống phải **phản ánh lần ghi (write) gần nhất**. Tuy nhiên, khi có sự cố phân vùng mạng (P), ta phải chọn giữa Availability và Consistency, dẫn đến hai mô hình chính:

- **Eventual Consistency (Nhất quán cuối cùng):** Các cập nhật sẽ lan truyền đến tất cả các node _sau một khoảng thời gian_. Hệ thống có thể không phản ánh ngay lập tức thay đổi mới nhất nhưng cuối cùng sẽ nhất quán.
- **Strong Consistency (Nhất quán mạnh):** Đảm bảo tất cả các node luôn có phiên bản dữ liệu mới nhất tại mọi thời điểm. Cách này ưu tiên Consistency hơn Availability khi mạng bị lỗi.

---

### 3. "Availability" (Tính sẵn sàng) nghĩa là gì trong Định lý CAP?

**Availability** đề cập đến khả năng của hệ thống trong việc **xử lý và phản hồi yêu cầu của người dùng một cách kịp thời**, ngay cả khi một số thành phần hoặc node bị lỗi.

Một hệ thống được thiết kế cho tính sẵn sàng cao đảm bảo rằng nó luôn hoạt động và phục vụ yêu cầu tốt nhất có thể, bất chấp lỗi mạng. Trong kịch bản phân vùng mạng, hệ thống phải chọn: ngừng cho phép ghi để giữ dữ liệu đúng (CP) hoặc vẫn cho phép ghi nhưng chấp nhận dữ liệu có thể bị lệch tạm thời (AP).

---

### 4. Giải thích "Partition Tolerance" (Khả năng chịu lỗi phân vùng) theo Định lý CAP?

**Partition tolerance** là khả năng hệ thống phân tán vẫn hoạt động bình thường ngay cả khi giao tiếp giữa các thành phần hệ thống (các node) bị **chia cắt** hoặc gián đoạn.

Đây là yếu tố bắt buộc đối với các hệ thống phân tán chạy trên mạng không tin cậy (nơi việc đứt cáp hay nghẽn mạng là điều chắc chắn xảy ra).

- **Ví dụ:** Các công cụ cộng tác thời gian thực như Google Docs thường ưu tiên Availability hơn Consistency tuyệt đối (chấp nhận xung đột văn bản tạm thời).

---

### 5. Cho ví dụ về một hệ thống thực tế ưu tiên Consistency hơn Availability (CP System)?

Một ví dụ điển hình là các cơ sở dữ liệu quan hệ như **MySQL** hoặc **PostgreSQL** ở cấu hình mặc định.
Khi gặp sự cố phân vùng mạng, các hệ thống này thà từ chối phục vụ (hy sinh Availability) còn hơn là trả về dữ liệu sai lệch. Điều này phù hợp với:

- **Hệ thống Ngân hàng:** Cần dữ liệu tuyệt đối chính xác cho giao dịch.
- **Thương mại điện tử (Flash sales):** Tránh việc bán quá số lượng hàng tồn kho.

---

### 6. Bạn có thể nêu tên một hệ thống ưu tiên Availability hơn Consistency (AP System)?

**Apache Cassandra** là ví dụ điển hình của hệ thống "AP". Nó ưu tiên tính sẵn sàng cao và chịu lỗi phân vùng, chấp nhận hy sinh tính nhất quán logic tạm thời.

- Kiến trúc Peer-to-Peer không có node trung tâm.
- Cho phép "Tunable Consistency" (Tính nhất quán có thể điều chỉnh).

---

### 7. "Eventual Consistency" (Nhất quán cuối cùng) nghĩa là gì trong Định lý CAP?

Nghĩa là nếu không có cập nhật mới nào, sau một khoảng thời gian, tất cả các bản sao (replicas) trong hệ thống sẽ đồng bộ về cùng một trạng thái.

- **Ví dụ Giỏ hàng Amazon:** Hai người cùng thêm món hàng cuối cùng vào giỏ. Hệ thống cho phép cả hai (Availability), nhưng khi thanh toán (Checkout), hệ thống mới giải quyết xung đột và chỉ cho một người mua (Eventual Consistency).

---

### 8. Bạn phải đánh đổi những gì trong thiết kế hệ thống phân tán do Định lý CAP?

Do không thể có cả 3 (C, A, P), bạn phải chọn:

1.  **Hệ thống CP (Consistency + Partition Tolerance):**
    - _Đánh đổi:_ Hệ thống có thể trở nên không khả dụng (unavailable) nếu không kết nối được với đa số các node.
    - _Dùng khi:_ Dữ liệu toàn vẹn là quan trọng nhất (Bank, RDBMS).
2.  **Hệ thống AP (Availability + Partition Tolerance):**
    - _Đánh đổi:_ Hy sinh tính nhất quán. Các node khác nhau có thể trả về dữ liệu khác nhau tại cùng một thời điểm.
    - _Dùng khi:_ Cần hiệu năng cao, real-time data, chấp nhận sai lệch nhỏ (Social media, Cassandra).

---

### 9. Bạn sẽ thiết kế một hệ thống yêu cầu High Availability như thế nào và đánh đổi ra sao?

Khi thiết kế cho **High Availability**, bạn đang xây dựng một hệ thống **AP**.

- **Trọng tâm:** Hệ thống luôn hoạt động dù mạng bị chia cắt.
- **Hệ quả:** Dữ liệu sẽ không nhất quán ngay lập tức (Eventual Consistency).
- **Công nghệ:** Sử dụng Apache Cassandra, Riak, hoặc DynamoDB.

---

### 10. Nếu hệ thống đang gặp sự cố phân vùng (network partition), bạn có thể dùng chiến lược nào để duy trì dịch vụ?

Có 3 mẫu chiến lược chính (Brewer's Conjecture):

1.  **Mẫu CA:** Giả định mạng ổn định, nhưng khi có Partition thì hệ thống sẽ dừng.
2.  **Mẫu CP:** Ưu tiên nhất quán. Hệ thống sẽ báo lỗi hoặc offline khi có sự cố mạng.
3.  **Mẫu AP:** Ưu tiên sẵn sàng. Hệ thống tiếp tục phục vụ request nhưng có thể trả về dữ liệu cũ (stale data).

_Code ví dụ (Python logic):_ Khi đọc từ replica, nếu lỗi mạng, hệ thống AP có thể fallback về local cache để trả lời người dùng thay vì báo lỗi.

---

### 11. Dựa trên Định lý CAP, bạn tiếp cận việc xây dựng hệ thống xử lý giao dịch tài chính nhạy cảm như thế nào?

Với giao dịch tài chính, **Consistency là tối quan trọng**. Không thể hy sinh tính đúng đắn của dữ liệu.

- **Chiến lược:** Sử dụng các cơ chế đồng bộ mạnh như **Write-Ahead Log (WAL)** hoặc **Quorum-based mechanisms** (Cơ chế dựa trên túc số).
- **Quorum:** Đảm bảo một giao dịch chỉ thành công khi đa số (majority) các node xác nhận đã ghi dữ liệu.

---

### 12. Mô tả kịch bản một hệ thống chuyển từ CA sang AP do tác động bên ngoài?

**Kịch bản: Nền tảng Thương mại điện tử**.

- **Bình thường (CA Mode):** Hệ thống hoạt động ổn định, đảm bảo tính nhất quán mạnh (Strong Consistency) cho giỏ hàng. Người dùng luôn thấy dữ liệu mới nhất.
- **Khi mạng lỗi (Chuyển sang AP Mode):** Để tránh việc khách hàng không thể mua sắm, hệ thống tạm thời nới lỏng tính nhất quán. Ví dụ: Cho phép thêm hàng vào giỏ dù kho chưa kịp đồng bộ, chấp nhận rủi ro hiển thị sai tồn kho tạm thời để giữ chân khách hàng (Availability).

---

### 13. Quorums giúp đạt được Consistency hoặc Availability như thế nào?

**Quorum** là số lượng node tối thiểu cần thiết để đồng ý thực hiện một thao tác.

- **Read Quorum (R) & Write Quorum (W):**
  - Để có **Strong Consistency**: Cần thiết lập sao cho $R + W > N$ (Tổng số node). Đảm bảo người đọc luôn thấy dữ liệu mới nhất. Điều này có thể làm giảm Availability (mô hình CP).
  - Để có **High Availability**: Giảm yêu cầu Quorum xuống, cho phép ghi nhận dữ liệu nhanh hơn nhưng có thể gây xung đột (mô hình AP).

---

### 14. Các database hiện đại như Cassandra hay DynamoDB giải quyết thách thức của CAP như thế nào?

Chúng không cố gắng phá vỡ định lý CAP mà cung cấp sự linh hoạt (Tunable Consistency).

- **Cassandra:** Cho phép chỉnh `Consistency Level` cho từng câu lệnh query (ví dụ: chọn `ONE`, `QUORUM`, hay `ALL`).
- **DynamoDB:** Cung cấp tùy chọn `ConsistentRead` (True/False). Bạn có thể chọn đọc dữ liệu nhất quán mạnh (tốn nhiều chi phí hơn, rủi ro Availability hơn) hoặc đọc dữ liệu nhất quán cuối cùng (nhanh hơn, rẻ hơn).

---

### 15. Giải thích vai trò của Idempotency (Tính lũy đẳng) và Commutativity (Tính giao hoán) trong thiết kế chịu ảnh hưởng của CAP?

Trong các hệ thống phân tán (đặc biệt là AP), các thao tác có thể bị lặp lại hoặc đến không đúng thứ tự do lỗi mạng.

- **Idempotency (Tính lũy đẳng):** Đảm bảo thực hiện một thao tác nhiều lần vẫn cho ra cùng một kết quả (ví dụ: thử lại lệnh thanh toán không bị trừ tiền 2 lần).
- **Commutativity (Tính giao hoán):** Đảm bảo thứ tự thực hiện không ảnh hưởng kết quả cuối cùng. Điều này rất quan trọng để các node đồng bộ dữ liệu (convergence) trong mô hình Eventual Consistency.

---

_Nguồn: GitHub - Devinterview-io/cap-theorem-interview-questions_

```

```
