# grep, rg, find, fd — tìm kiếm trong terminal, hiểu từ gốc

> Tài liệu **lý thuyết**: giải thích bốn tool này _là gì_, _chạy thế nào_, và vì
> sao một lệnh search có thể trả về ít hơn sự thật mà không báo. Nó **không** phải
> hướng dẫn cài đặt.
>
> - Cần **lệnh và config** → [`ripgrep.md`](ripgrep.md), [`fd.md`](fd.md).
> - Cần hiểu **RTK** (lớp nén output cho AI agent) → [`rtk.md`](rtk.md).
> - Cần biết **AI agent bị ép dùng `rg`/`fd` ra sao** → [`claude-code.md`](claude-code.md#search-rule-and-guard-hook).
> - Cần **nguồn gốc từng khẳng định** → [`research/search-tools-and-rtk.md`](research/search-tools-and-rtk.md).

---

## 1. TL;DR

- **Có hai bài toán khác nhau.** Tìm _nội dung_ trong file (`grep`, `rg`) và tìm
  _file_ theo tên hay thuộc tính (`find`, `fd`). Đừng lẫn: `grep` không tìm file,
  `find` không đọc nội dung.
- **`grep` và `find` là tool "trung thực tuyệt đối".** Bảo tìm ở đâu thì chúng
  xét hết ở đó: file ẩn, `node_modules/`, `.git/`, tất cả. Chậm và ồn, nhưng
  không bao giờ bỏ sót.
- **`rg` và `fd` là tool "có chính kiến".** Mặc định chúng bỏ qua file bị
  `.gitignore`, file ẩn, và (với `rg`) file nhị phân. Nhờ vậy chúng nhanh và
  output sạch. Cái giá: kết quả rỗng nghĩa là "không _thấy_", chưa chắc là
  "không _có_".
- **Chúng nhanh vì ba lý do cộng lại:** xét ít file hơn (ignore), duyệt cây thư
  mục song song trên nhiều nhân CPU, và (với `rg`) một regex engine tối ưu rất
  kỹ cho việc tìm chuỗi cố định.
- **Luôn có thang leo.** `rg` → `rg -uu`, `fd -H` → `fd -HI -E .git`. Chưa leo
  hết thang thì chưa được nói "không tồn tại".
- **Với AI agent, chuyện này nghiêm trọng hơn với người.** Người thấy kết quả
  rỗng sẽ nghi ngờ; agent thấy kết quả rỗng sẽ kết luận và đi tiếp.

---

## 2. ELI5 (giải thích như cho trẻ con)

Tưởng tượng bạn cần tìm một tờ giấy trong **cả một tòa nhà văn phòng**.

- **`grep -r`** là người đi vào _từng phòng_, mở _từng ngăn kéo_, đọc _từng tờ
  giấy_ — kể cả thùng rác, kho hồ sơ cũ, phòng máy chủ. Chắc chắn không sót,
  nhưng rất lâu, và báo cáo về đầy những thứ bạn không cần.
- **`rg`** là người có tấm bảng ở cửa ghi "những phòng không cần vào" (đó là
  `.gitignore`), không vào các phòng khóa (file ẩn), bỏ qua các thùng chứa toàn
  linh kiện (file nhị phân), và **dẫn theo cả một đội** chia nhau mỗi người một
  tầng. Nhanh hơn nhiều, báo cáo gọn.
- Vấn đề: nếu tờ giấy bạn cần nằm đúng trong một phòng có tên trên tấm bảng,
  người thứ hai sẽ quay về nói "không thấy" — và **không hề nhắc** rằng anh ta đã
  bỏ qua phòng đó.

`find` và `fd` cũng y như vậy, chỉ khác là chúng tìm _tên trên nhãn hồ sơ_ chứ
không đọc nội dung bên trong.

---

## 3. Hai bài toán, bốn tool

|                  | Thế hệ cũ (POSIX, có sẵn mọi nơi) | Thế hệ mới (Rust, phải cài) |
| ---------------- | --------------------------------- | --------------------------- |
| **Tìm nội dung** | `grep`                            | `rg` (ripgrep)              |
| **Tìm file**     | `find`                            | `fd`                        |

Cặp trên cùng một hàng giải cùng một bài toán. Cặp trên cùng một cột chia sẻ
cùng một _triết lý_ — và đó mới là điều đáng hiểu.

### 3.1. `grep` — lọc dòng theo mẫu

`grep` sinh ra ở Bell Labs đầu thập niên 1970, tách ra từ lệnh `g/re/p` của
trình soạn thảo `ed` (**g**lobal / **r**egular **e**xpression / **p**rint). Mô
hình của nó cực kỳ đơn giản: đọc từng dòng, dòng nào khớp mẫu thì in ra.

- **Bản chất là một bộ lọc dòng.** Input là stdin hoặc các file bạn nêu tên.
  Chính vì vậy `cmd | grep foo` là cách dùng tự nhiên nhất của nó.
- **Đệ quy là tính năng thêm vào sau** (`-r`, `-R`). Khi đệ quy, `grep` không
  có khái niệm "file nào nên bỏ qua": nó mở mọi thứ.
- **Hai phương ngữ regex chuẩn POSIX**: BRE (mặc định; `( )` và `{ }` phải có `\`
  đứng trước mới mang nghĩa đặc biệt, và không có phép "hoặc") và ERE
  (`grep -E`; viết thẳng, có `|`). GNU grep nới BRE thêm `\+`, `\?`, `\|`, và có
  `-P` cho cú pháp kiểu Perl. Cả `-r` lẫn `-P` đều là phần mở rộng, không thuộc
  POSIX.
- **GNU grep không hề chậm.** Tác giả gốc của nó giải thích bí quyết là _tránh
  nhìn vào từng byte_ (thuật toán Boyer–Moore nhảy cóc qua input) và _tránh cắt
  input thành dòng_ cho tới khi thật sự có kết quả khớp. Trên một file đơn lẻ,
  `grep` và `rg` thường ngang ngửa nhau.

### 3.2. `rg` — grep cho cây mã nguồn

ripgrep (2016, viết bằng Rust) không cố thay `grep` ở vai trò bộ lọc dòng. Nó
nhắm vào đúng một việc: **tìm trong cả một cây thư mục mã nguồn**. Bốn quyết
định thiết kế làm nên nó:

1. **Đệ quy là mặc định.** `rg foo` tìm trong thư mục hiện tại, không cần `-r`.
2. **Lọc tự động.** Bỏ qua file khớp `.gitignore`, file ẩn, file nhị phân. Trong
   một project thật, phần lớn dung lượng trên đĩa là thứ bạn không viết ra
   (`node_modules/`, `target/`, `.git/`). Không đọc chúng là khoản tiết kiệm lớn
   nhất.
3. **Duyệt song song.** Nhiều luồng cùng đi xuống cây thư mục, mỗi luồng tự tìm
   trong các file nó gặp.
4. **Regex engine dựa trên automata hữu hạn.** Nó đảm bảo thời gian tìm tuyến
   tính theo độ dài input — không có mẫu regex nào làm nó "treo" theo cấp số
   nhân. Cái giá là không hỗ trợ backreference (`\1`) và lookaround (`(?=…)`);
   cần thì bật `-P` để chuyển sang engine PCRE2. Trước khi chạy automata, nó rút
   các _chuỗi cố định_ ra khỏi mẫu và dùng lệnh SIMD của CPU để quét tìm chúng
   thật nhanh, chỉ chạy regex đầy đủ ở những chỗ có khả năng khớp.

### 3.3. `find` — duyệt cây và đánh giá biểu thức

`find` không nhận "mẫu tìm kiếm". Nó nhận một **biểu thức** và đánh giá biểu
thức đó trên _từng entry_ trong cây thư mục:

```sh
find . -type f -name '*.md' -newer README.md -print
#      └─ test ┘ └── test ──┘ └──── test ────┘ └action┘
```

- **Test** trả về đúng/sai (`-name`, `-type`, `-size`, `-perm`, `-newer`…).
- **Action** làm một việc (`-print`, `-delete`, `-exec`…).
- **Toán tử** nối chúng lại (`-a` ngầm định, `-o`, `!`, ngoặc đơn), đánh giá từ
  trái sang phải và dừng sớm như `&&` / `||` trong shell.

Đây là một ngôn ngữ nhỏ, rất mạnh và rất dễ viết sai. Và giống `grep`, `find`
không biết gì về `.gitignore`: muốn bỏ qua `.git/` phải tự viết
`-not -path '*/.git/*'` hoặc `-prune`.

### 3.4. `fd` — find cho 90% trường hợp

`fd` (cũng Rust) áp đúng công thức của ripgrep lên bài toán tìm file — nó dùng
chung thư viện duyệt-cây-có-ignore và thư viện regex với ripgrep:

- **Mẫu là tham số đầu tiên**: `fd readme` thay cho `find . -iname '*readme*'`.
- **Mẫu là regex, khớp với _tên file_** (không phải cả đường dẫn; muốn vậy thì
  `-p`). Muốn glob thì `-g`.
- **Smart case, tôn trọng `.gitignore`, bỏ qua file ẩn, duyệt song song** — y
  như `rg`.
- **Bỏ ngôn ngữ biểu thức.** Thay vào đó là một nhúm cờ cho các nhu cầu phổ biến
  (`-e` phần mở rộng, `-t` loại, `-S` kích thước, `--changed-within`, `-x` chạy
  lệnh). Những thứ hiếm hơn (`-perm`, `-newer file`, `-delete`, biểu thức
  AND/OR tùy ý) thì `fd` không có — lúc đó quay về `find`.

---

## 4. "Search visibility": một lệnh search nhìn thấy gì?

Đây là khái niệm trung tâm. **Search visibility** là _tập file mà lệnh search
thật sự xét tới_. Có ba mức:

| Mức              | Thấy thêm gì                       | `rg`           | `fd`             |
| ---------------- | ---------------------------------- | -------------- | ---------------- |
| **default**      | —                                  | `rg` (bản gốc) | `fd`             |
| **hidden**       | file/thư mục ẩn (bắt đầu bằng `.`) | `rg --hidden`  | `fd -H`          |
| **unrestricted** | cả file bị ignore                  | `rg -uu`       | `fd -HI -E .git` |

Đo thật trên chính repo này (số file được xét):

| Mức          | `rg`                   | `fd`                   |
| ------------ | ---------------------- | ---------------------- |
| default      | 232 (`rg --no-config`) | 232 (`fd`)             |
| hidden       | 255 (`rg`, có config)  | 255 (`fd -H`)          |
| unrestricted | 452 (`rg -uu`)         | 452 (`fd -HI -E .git`) |

Gần **một nửa số file** trong repo không nằm trong tầm nhìn mặc định.

Vài điểm tinh tế:

- **Mức phụ thuộc vào config, không chỉ vào tool.** Trên máy này `rg` đứng sẵn ở
  mức _hidden_ vì file config có `--hidden`; còn `fd` không có file config cho
  cờ nên luôn bắt đầu ở _default_. Cùng một tool, hai máy, hai tầm nhìn.
- **`.git/` là ca đặc biệt.** Nó là thư mục ẩn nhưng thường _không_ nằm trong
  `.gitignore`. Vì vậy bật _hidden_ là dính ngay `.git/`. Cả hai tool đều cần
  một dòng loại trừ riêng cho nó (`--glob=!.git/` trong config ripgrep,
  `.git/` trong `~/.config/fd/ignore`).
- **Có nhiều file ignore, có thứ tự ưu tiên.** Ngoài `.gitignore` còn `.ignore`
  (cả `rg` và `fd` đọc) và `.rgignore` / `.fdignore` (riêng từng tool). File
  riêng của tool thắng `.ignore`, `.ignore` thắng `.gitignore`. Nhờ đó một dòng
  `!thư-mục/` trong `.ignore` có thể "mở lại" thứ mà `.gitignore` đã ẩn — chỉ
  cho việc search, git không hề đọc file này.

### Bốn cách một lệnh search bỏ sót mà không báo

| Nguyên nhân    | Ví dụ thật trong repo này                                   | Cách vượt         |
| -------------- | ----------------------------------------------------------- | ----------------- |
| File bị ignore | `.claude/`, `.rumdl_cache/` nằm trong `.gitignore`          | `-uu` / `-I`      |
| File ẩn        | `.github/`, `.editorconfig` vô hình với `fd` trần           | `--hidden` / `-H` |
| Symlink        | `~/.claude/skills/find-skills` trỏ sang `~/.agents/skills/` | `-L`              |
| File nhị phân  | `rg` dừng khi gặp byte NUL                                  | `-uuu` / `-a`     |

Và một cái bẫy khác loại — không phải bỏ sót mà là **treo**: `rg PATTERN`
_không có đường dẫn_ sẽ đọc stdin nếu stdin là một pipe hay file, thay vì duyệt
thư mục. Trong script hay lệnh ghép, luôn viết `rg PATTERN .`.

### Silent narrowing và signalled truncation

Hai cách một kết quả nhỏ hơn sự thật, cần phân biệt rạch ròi:

- **Silent narrowing** (thu hẹp im lặng): bị bỏ sót mà output không nói gì. Bốn
  nguyên nhân ở bảng trên đều thuộc loại này. Đây là thứ phải thiết kế để tránh.
- **Signalled truncation** (cắt bớt có báo): output bị cắt nhưng ghi rõ "còn N
  kết quả nữa, xem ở đây". `head` thì không báo; RTK thì có
  ([`rtk.md`](rtk.md#what-rtk-can-cost-you)). Loại này chấp nhận được.

### Thang leo (escalation ladder)

Vì thu hẹp là im lặng, kỷ luật phải nằm ở người gọi:

1. Chạy ở mức thường dùng: `rg PATTERN .` · `fd -H PATTERN`.
2. Không ra, ra ít hơn dự đoán, hoặc đích có thể nằm trong vùng bị ignore (output
   build, `.env`, code vendored, thư mục trạng thái của tool) → lên mức
   unrestricted: `rg -uu PATTERN .` · `fd -HI -E .git PATTERN`.
3. Chỉ khi bước 2 vẫn rỗng mới được nói "không tồn tại". Trước đó, câu đúng là
   "không thấy trong các file không bị ignore".

---

## 5. Vì sao `rg` và `fd` nhanh hơn

Xếp theo mức đóng góp trong một project điển hình:

1. **Làm ít việc hơn.** Bỏ qua `node_modules/`, `target/`, `.git/` thường loại
   được phần lớn số byte trên đĩa. Đây là khoản lời lớn nhất, và nó chính là
   mặt kia của đồng xu "search visibility". Bật `-uu` lên là trả lại gần hết
   khoản lời này.
2. **Song song.** `grep -r` và `find` duyệt cây bằng một luồng. `rg` và `fd`
   dùng mọi nhân CPU cho cả việc duyệt lẫn việc tìm.
3. **Engine tìm kiếm** (chỉ `rg`). Rút chuỗi cố định ra khỏi regex rồi quét
   bằng SIMD. Với mẫu là chuỗi thường (`rg -F`), gần như toàn bộ thời gian là
   chạy vòng lặp SIMD đó.

Hệ quả thực tế: so `rg` với `grep` **trên một file duy nhất**, chênh lệch nhỏ.
So trên **một cây mã nguồn có `node_modules/`**, chênh lệch có thể là hàng chục
lần — nhưng phần lớn là do (1), không phải do Rust.

---

## 6. Bảng đối chiếu lệnh

### `grep` → `rg`

| Việc                       | `grep`                              | `rg`                                  |
| -------------------------- | ----------------------------------- | ------------------------------------- |
| Tìm đệ quy                 | `grep -rn foo .`                    | `rg foo .`                            |
| Không phân biệt hoa thường | `grep -ri foo .`                    | `rg -i foo .`                         |
| Chuỗi cố định              | `grep -rF 'a.b' .`                  | `rg -F 'a.b' .`                       |
| Chỉ in tên file            | `grep -rl foo .`                    | `rg -l foo .`                         |
| Chỉ file `.md`             | `grep -rn --include='*.md' foo .`   | `rg -g '*.md' foo .`                  |
| Bỏ một thư mục             | `grep -rn --exclude-dir=dist foo .` | `rg -g '!dist/' foo .`                |
| Nguyên từ                  | `grep -rw foo .`                    | `rg -w foo .`                         |
| Ngữ cảnh 2 dòng            | `grep -rn -C2 foo .`                | `rg -C2 foo .`                        |
| Hoặc                       | `grep -rE 'a\|b' .`                 | `rg 'a\|b' .`                         |
| Lọc một luồng              | `cmd \| grep foo`                   | `cmd \| rg foo` (hoặc cứ dùng `grep`) |

### `find` → `fd`

| Việc                          | `find`                                  | `fd`                        |
| ----------------------------- | --------------------------------------- | --------------------------- |
| Tên chứa "readme"             | `find . -iname '*readme*'`              | `fd -H readme`              |
| Theo phần mở rộng             | `find . -name '*.md'`                   | `fd -H -e md`               |
| Chỉ thư mục                   | `find . -type d -name src`              | `fd -H -t d '^src$'`        |
| Giới hạn độ sâu               | `find . -maxdepth 2 -name '*.toml'`     | `fd -H -d 2 -e toml`        |
| Sửa trong 2 ngày qua          | `find . -mtime -2`                      | `fd -H --changed-within 2d` |
| Lớn hơn 1 MB                  | `find . -size +1M`                      | `fd -H -S +1m`              |
| Chạy lệnh trên từng kết quả   | `find . -name '*.md' -exec wc -l {} \;` | `fd -H -e md -x wc -l`      |
| Chạy một lệnh cho tất cả      | `find . -name '*.md' -exec wc -l {} +`  | `fd -H -e md -X wc -l`      |
| Theo quyền / mới hơn một file | `find . -perm -u+x` · `-newer ref`      | — dùng `find`               |
| Xóa                           | `find . -name '*.tmp' -delete`          | `fd -H -e tmp -x rm`        |

### Khi nào vẫn dùng tool cũ

- **Lọc một luồng hoặc một file có tên**: `grep` là đủ, không có gì để bỏ sót.
- **Cần đảm bảo "mọi file, không ngoại lệ"** và không muốn nhớ cờ: `grep -r`,
  `find`.
- **Script phải chạy ở máy lạ** (container tối giản, server): chỉ `grep` và
  `find` chắc chắn có mặt.
- **Biểu thức `find` phức tạp** mà `fd` không diễn đạt được.
- **`git grep`**: tìm trong đúng các file git đang theo dõi — phạm vi rõ ràng,
  và thường là thứ bạn thật sự muốn hỏi.

---

## 7. Góc nhìn AI agent

Với người dùng, mục 4 là một lưu ý. Với AI agent, nó là một lớp lỗi riêng.

- **Agent search qua shell và tin output.** Kết quả rỗng trở thành một dữ kiện:
  "repo này không có X". Mọi bước sau xây trên dữ kiện đó.
- **Agent quen tay gõ `grep` và `find`.** Trên máy này, trước khi có rule, lịch
  sử ghi 722 lần `grep` so với 92 lần `rg`. Con số gồm cả `cmd | grep`, nên nó
  cho thấy thói quen chứ không đếm riêng `grep -r`.
- **Lớp proxy có thể đổi tool sau lưng agent.** [RTK](rtk.md) tự đổi lệnh để nén
  output. Với `grep` thì vô hại: `rtk grep` vẫn chạy `grep` thật. Nhưng
  `rtk find` _không phải_ `find` — nó là một bản viết lại, có áp dụng ignore và
  bỏ file ẩn. Agent gõ một tool nhìn thấy tất cả, nhận về một tool không nhìn
  thấy tất cả, và không có lý do gì để nghi ngờ:

  | Agent gõ                           | Thực tế chạy | Kết quả |
  | ---------------------------------- | ------------ | ------- |
  | `find . -name settings.local.json` | `find` thật  | 1 file  |
  | cùng lệnh, qua hook                | `rtk find`   | 0       |

Cách giải ở repo này gồm hai nửa:

- **Rule** (`SEARCH.md`): dùng `rg`/`fd`, và leo thang trước khi kết luận.
- **Guard hook**: _từ chối_ `grep -r` và `find`, kèm lời nhắc dùng gì thay. Nó
  không tự đổi lệnh — vì dịch máy móc `grep`→`rg` không an toàn, và vì một lời
  từ chối khiến agent _tự gõ_ `rg`, tức là biết mình đang ở mức visibility nào.

Phân biệt hai loại hook: **rewrite hook** đổi lệnh rồi cho chạy (RTK); **guard
hook** từ chối và nói lý do. Cái đầu tiện nhưng che giấu; cái sau tốn một lượt
nhưng minh bạch.

---

## 8. Ý tưởng bài blog

Ba bài độc lập rút được từ bộ tài liệu này:

1. **"`grep`/`find` vs `rg`/`fd`: nhanh hơn vì làm ít hơn"** — mục 3 và 5, kèm
   bảng đo ở mục 4. Luận điểm: tốc độ và "bỏ sót im lặng" là hai mặt của cùng
   một quyết định thiết kế.
2. **"Kết quả rỗng không có nghĩa là không có"** — mục 4: bốn kiểu silent
   narrowing, cái bẫy stdin, và thang leo.
3. **"Ép AI agent dùng đúng tool search"** — mục 7 cùng [`rtk.md`](rtk.md) và
   [`claude-code.md`](claude-code.md#search-rule-and-guard-hook): rule mềm, guard
   hook, và vì sao _từ chối_ tốt hơn _tự sửa_.

---

## 9. Đọc thêm

- [ripgrep GUIDE](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md) và
  [FAQ](https://github.com/BurntSushi/ripgrep/blob/master/FAQ.md)
- [ripgrep is faster than {grep, ag, git grep, ucg, pt, sift}](https://burntsushi.net/ripgrep/)
  — bài phân tích của tác giả ripgrep
- [fd README](https://github.com/sharkdp/fd#readme)
- [why GNU grep is fast](https://lists.freebsd.org/pipermail/freebsd-current/2010-August/019310.html)
  — thư của Mike Haertel, tác giả gốc GNU grep
- [GNU grep manual](https://www.gnu.org/software/grep/manual/grep.html) ·
  [GNU findutils manual](https://www.gnu.org/software/findutils/manual/html_mono/find.html)
- [`research/search-tools-and-rtk.md`](research/search-tools-and-rtk.md) — ghi
  chú có dẫn nguồn cho các khẳng định trong tài liệu này
