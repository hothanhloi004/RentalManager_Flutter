from pathlib import Path
p = Path(r"d:\TAILIEU\RentalManager_Flutter\lib\screens\room\room_detail_screen.dart")
lines = p.read_text(encoding="utf-8").splitlines()
out = []
for line in lines:
    if "_infoRow(Icons.square_foot" in line:
        out.append("              _infoRow(Icons.square_foot_rounded, 'Ph\\u00f2ng di\\u1ec7n t\\u00edch \\${_currentRoom.area} m\\u00b2'),")
    elif "child: Text('+ T" in line or "tao_hd" in line.lower():
        out.append("                    child: const Text('+ T\\u1ea1o h\\u1ee3p \\u0111\\u1ed3ng cho ph\\u00f2ng n\\u00e0y', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),")
    elif "label = 'Tr" in line and "isVacant" not in line:
        out.append("      label = '\\u1ed1ng';")
    elif "label = 'B" in line and "isMaintenance" not in line:
        out.append("      label = '\\u1ea3o tr\\u00ec';")
    elif "label = '" in line and "else" not in line and "late String" not in line and "if (isVacant)" not in line and "else if" not in line:
        if "991B1B" in "".join(lines[max(0,len(out)-3):]):
            out.append("      label = '\\u0110ang thu\\u00ea';")
        else:
            out.append(line)
    elif "_infoRow(Icons.person_rounded" in line:
        out.append("            _infoRow(Icons.person_rounded, isRented ? '\\u0110ang c\\u00f3 ng\\u01b0\\u1eddi thu\\u00ea' : 'Ch\\u01b0a c\\u00f3 ng\\u01b0\\u1eddi thu\\u00ea'),")
    else:
        out.append(line)
p.write_text("\n".join(out) + "\n", encoding="utf-8")
print("patched")
