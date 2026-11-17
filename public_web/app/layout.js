import "./globals.css";
import Navbar from "./components/Navbar";

export const metadata = {
  title: "Rental Manager – Quản lý Nhà Trọ Thông Minh",
  description: "Nền tảng quản lý và tìm kiếm phòng trọ toàn diện. Dữ liệu từ App Flutter đồng bộ lên Web thời gian thực. Tra cứu hoá đơn, tìm phòng trống, xem bản đồ giá thuê Việt Nam.",
  keywords: ["nhà trọ", "phòng trọ", "quản lý nhà trọ", "tìm phòng trọ", "rental manager", "phòng trống cho thuê", "hoá đơn phòng trọ"],
  authors: [{ name: "Rental Manager" }],
  openGraph: {
    title: "Rental Manager – Quản lý Nhà Trọ Thông Minh",
    description: "Tìm phòng trống, tra hoá đơn, xem bản đồ giá thuê toàn quốc. Hoàn toàn miễn phí.",
    type: "website",
    locale: "vi_VN",
    siteName: "Rental Manager",
  },
  twitter: {
    card: "summary_large_image",
    title: "Rental Manager – Quản lý Nhà Trọ Thông Minh",
    description: "Tìm phòng trống, tra hoá đơn, xem bản đồ giá thuê toàn quốc.",
  },
};

export const viewport = {
  width: 'device-width',
  initialScale: 1,
};

export default function RootLayout({ children }) {
  return (
    <html lang="vi" suppressHydrationWarning>
      <body className="bg-slate-50 text-slate-900 min-h-screen">
        <Navbar />
        <main className="pt-16">{children}</main>
      </body>
    </html>
  );
}
