# Thành viên nhóm: 
Hồ Thanh Lợi - 2224802010842
Nguyễn Dương Quốc - 2224802010878
Nguyễn Quang Hưng - 2224802010188

# Rental Manager - Hệ thống quản lý nhà trọ

Rental Manager là hệ thống hỗ trợ quản lý nhà trọ được xây dựng bằng Flutter và Web. Ứng dụng giúp chủ trọ quản lý phòng, khách thuê, hợp đồng, hóa đơn, thanh toán và thống kê doanh thu. Ngoài ra, hệ thống còn có website hỗ trợ người thuê xem phòng trống, gửi yêu cầu liên hệ và tra cứu hóa đơn.

## Công nghệ sử dụng

- Flutter / Dart: xây dựng ứng dụng di động cho chủ trọ.
- Firebase Authentication: đăng nhập bằng Google hoặc email.
- Cloud Firestore: lưu trữ và đồng bộ dữ liệu theo thời gian thực.
- Firebase Storage: lưu trữ hình ảnh phòng và hình ảnh liên quan.
- Next.js / React: xây dựng website public và trang quản trị web.
- Tailwind CSS: thiết kế giao diện website.
- VietQR: tạo mã QR thanh toán hóa đơn.

## Chức năng chính

### Ứng dụng Flutter

- Đăng nhập bằng Google hoặc email.
- Quản lý phòng trọ.
- Quản lý khách thuê.
- Quản lý hợp đồng thuê phòng.
- Chốt chỉ số điện nước.
- Tạo hóa đơn tháng.
- Ghi nhận thanh toán.
- Tạo mã QR thanh toán.
- Xuất hoặc chia sẻ hóa đơn.
- Thống kê doanh thu và công nợ.
- Quản lý tài sản trong phòng.
- Nhận yêu cầu xem phòng từ website.
- Cài đặt đơn giá, thông tin chủ trọ và thông tin thanh toán.

### Website

- Xem danh sách phòng trống.
- Tìm kiếm và lọc phòng theo tiêu chí.
- Xem chi tiết phòng.
- Gửi yêu cầu liên hệ xem phòng.
- Tra cứu hóa đơn bằng số điện thoại.
- Xem nhanh dữ liệu quản trị trên trang web admin.

## Cấu trúc dữ liệu chính

Hệ thống sử dụng Firebase Firestore với các nhóm dữ liệu chính:

- rooms
- tenants
- contracts
- bills
- payments
- settings
- assets
- inquiries / requests

Dữ liệu của mỗi chủ trọ được phân tách theo tài khoản người dùng thông qua cấu trúc `users/{uid}`.
