from pathlib import Path

p = Path(__file__).resolve().parent.parent / "lib/screens/bill/bill_list_screen.dart"
t = p.read_text(encoding="utf-8")
replacements = [
    ("Tạo hàng lạt", "Tạo hàng loạt"),
    ("Ghi lẻ / Chốt", "Ghi chỉ số / Chốt"),
    ("Tìm theo phòng hặc tháng", "Tìm theo phòng hoặc tháng"),
    ("Phòng ?", "Phòng không rõ"),
]
for a, b in replacements:
    t = t.replace(a, b)
p.write_text(t, encoding="utf-8")
print("ok")
