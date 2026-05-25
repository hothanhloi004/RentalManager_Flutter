from pathlib import Path

p = Path(r"d:\TAILIEU\RentalManager_Flutter\lib\services\firebase_service.dart")
lines = p.read_bytes().decode("utf-8", errors="replace").splitlines()
out = []
for line in lines:
    if "googleUser == null" in line:
        out.append(
            "      if (googleUser == null) throw Exception('Ng\\u01b0\\u1eddi d\\u00f9ng \\u0111\\u00e3 h\\u1ee7y \\u0111\\u0103ng nh\\u1eadp');"
        )
    elif "M?t l?n GET" in line or "Một lần" in line or "" in line and "GET" in line and "fetchRoomsOnce" in "".join(out[-2:]):
        out.append("  /// Mot lan GET — man bao cao (khong giu stream listener).")
    elif line.strip().startswith("// H") and "tr" in line:
        out.append("    // Ho tro ca 2 dinh dang: yyyy-MM (Android) va MM/yyyy (Flutter)")
    elif "C?p nh?t ch" in line or "Cập nhật" in line and "h?p" in line:
        out.append("    // Cap nhat chi so dien nuoc cuoi cung vao hop dong")
    elif line.strip().startswith("// 1. L"):
        out.append("    // 1. Lay tat ca hop dong dang hieu luc")
    elif line.strip().startswith("// 2. L"):
        out.append("    // 2. Lay cac hoa don da ton tai trong thang nay")
    else:
        # strip replacement char lines that break parser in strings only
        if "\ufffd" in line:
            continue
        out.append(line)

p.write_text("\n".join(out) + "\n", encoding="utf-8")
print("fixed", len(lines), "->", len(out))
