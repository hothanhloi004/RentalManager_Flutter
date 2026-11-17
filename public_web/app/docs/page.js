'use client';

import Link from 'next/link';

export default function DocsPage() {
    return (
        <div className="min-h-screen bg-slate-50 text-slate-900 font-sans">
            {/* Header */}
            <div className="bg-white border-b border-slate-200 px-6 py-12 text-center shadow-sm">
                <div className="inline-flex items-center gap-2 bg-indigo-50 border border-indigo-100 rounded-full px-4 py-1.5 text-xs text-indigo-700 font-bold mb-4">
                    📚 Tài liệu Đồ án Tốt nghiệp
                </div>
                <h1 className="text-4xl md:text-5xl font-black text-slate-900 tracking-tight mb-3">
                    Rental Manager Documentation
                </h1>
                <p className="text-slate-500 max-w-2xl mx-auto text-sm md:text-base">
                    Tổng quan Kiến trúc Nền tảng, Mô hình Phân quyền 3 Vai trò, Sơ đồ Luồng Dữ liệu và Hướng dẫn Thao tác Demo cho Hội đồng Phản biện.
                </p>
            </div>

            <div className="max-w-5xl mx-auto px-4 py-10 space-y-10">
                {/* 1. System Tech Stack */}
                <section className="bg-white rounded-3xl border border-slate-200 p-8 shadow-sm">
                    <div className="flex items-center gap-3 mb-6">
                        <div className="w-10 h-10 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center font-black text-lg">1</div>
                        <div>
                            <h2 className="text-xl font-extrabold text-slate-900">Công nghệ & Kiến trúc Hệ thống</h2>
                            <p className="text-xs text-slate-500">Tech Stack & Frameworks</p>
                        </div>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
                        <div className="rounded-2xl border border-slate-100 bg-slate-50 p-5">
                            <div className="text-xs font-bold text-indigo-600 uppercase tracking-wide mb-1">Mobile Application</div>
                            <h3 className="font-bold text-slate-900 text-lg mb-2">Flutter (Dart)</h3>
                            <p className="text-xs text-slate-500 leading-relaxed">
                                Dành cho Chủ trọ quản lý nghiệp vụ vận hành hằng ngày: Quản lý phòng, lập hợp đồng, chốt chỉ số điện nước, sinh hóa đơn và tạo mã VietQR.
                            </p>
                        </div>
                        <div className="rounded-2xl border border-slate-100 bg-slate-50 p-5">
                            <div className="text-xs font-bold text-sky-600 uppercase tracking-wide mb-1">Web Platform</div>
                            <h3 className="font-bold text-slate-900 text-lg mb-2">Next.js 16 (React & Tailwind)</h3>
                            <p className="text-xs text-slate-500 leading-relaxed">
                                Website Public cho khách tìm phòng, tra hóa đơn, bản đồ giá thuê Việt Nam và Cổng Quản trị Hệ thống (System Admin Dashboard).
                            </p>
                        </div>
                        <div className="rounded-2xl border border-slate-100 bg-slate-50 p-5">
                            <div className="text-xs font-bold text-emerald-600 uppercase tracking-wide mb-1">Cloud Backend & AI</div>
                            <h3 className="font-bold text-slate-900 text-lg mb-2">Firebase & Gemini AI</h3>
                            <p className="text-xs text-slate-500 leading-relaxed">
                                Đồng bộ Firestore Realtime thời gian thực, Firebase Authentication và tích hợp Trợ lý Trí tuệ Nhân tạo Google Gemini 2.5 cho phân tích tài chính.
                            </p>
                        </div>
                    </div>
                </section>

                {/* 2. Three Role Architecture */}
                <section className="bg-white rounded-3xl border border-slate-200 p-8 shadow-sm">
                    <div className="flex items-center gap-3 mb-6">
                        <div className="w-10 h-10 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center font-black text-lg">2</div>
                        <div>
                            <h2 className="text-xl font-extrabold text-slate-900">Mô hình Phân quyền 3 Vai trò</h2>
                            <p className="text-xs text-slate-500">Multi-role Access Control Model</p>
                        </div>
                    </div>

                    <div className="space-y-4 text-sm">
                        <div className="rounded-2xl border border-indigo-100 bg-indigo-50/50 p-5 flex flex-col md:flex-row gap-4 items-start md:items-center justify-between">
                            <div>
                                <span className="inline-block rounded-full bg-indigo-600 text-white px-3 py-1 text-xs font-bold mb-2">Role 1: Người thuê / Khách vãng lai</span>
                                <h3 className="font-bold text-slate-900 text-base">Website Công Khai (Public Portal)</h3>
                                <p className="text-xs text-slate-600 mt-1">Tìm phòng trống theo khu vực & giá, xem bản đồ giá thuê toàn quốc, tra cứu hóa đơn bằng số điện thoại và quét mã chuyển khoản VietQR.</p>
                            </div>
                            <Link href="/rooms" className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl text-xs flex-shrink-0">Thử nghiệm Public →</Link>
                        </div>

                        <div className="rounded-2xl border border-emerald-100 bg-emerald-50/50 p-5 flex flex-col md:flex-row gap-4 items-start md:items-center justify-between">
                            <div>
                                <span className="inline-block rounded-full bg-emerald-600 text-white px-3 py-1 text-xs font-bold mb-2">Role 2: Chủ trọ (Landlord)</span>
                                <h3 className="font-bold text-slate-900 text-base">App Flutter Mobile & Web Admin Chủ Trọ</h3>
                                <p className="text-xs text-slate-600 mt-1">Vận hành nghiệp vụ phòng trọ, chốt chỉ số điện nước, lập hợp đồng, xuất báo cáo doanh thu Excel/PDF và trợ lý Gemini AI tư vấn kinh doanh.</p>
                            </div>
                            <Link href="/admin" className="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-xs flex-shrink-0">Thử nghiệm Admin Chủ trọ →</Link>
                        </div>

                        <div className="rounded-2xl border border-rose-100 bg-rose-50/50 p-5 flex flex-col md:flex-row gap-4 items-start md:items-center justify-between">
                            <div>
                                <span className="inline-block rounded-full bg-rose-600 text-white px-3 py-1 text-xs font-bold mb-2">Role 3: Admin Hệ Thống (System Admin)</span>
                                <h3 className="font-bold text-slate-900 text-base">Web Quản trị Toàn Nền tảng (/admin/system)</h3>
                                <p className="text-xs text-slate-600 mt-1">Quản lý danh sách tất cả các chủ trọ, duyệt/ẩn các phòng trọ đăng web, hỗ trợ sửa thông tin chủ trọ, xóa phòng vi phạm và theo dõi tổng nợ cước toàn sàn.</p>
                            </div>
                            <Link href="/admin/system" className="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white font-bold rounded-xl text-xs flex-shrink-0">Thử nghiệm Admin Hệ thống →</Link>
                        </div>
                    </div>
                </section>

                {/* 3. Demo Walkthrough Checklist for Defense */}
                <section className="bg-white rounded-3xl border border-slate-200 p-8 shadow-sm">
                    <div className="flex items-center gap-3 mb-6">
                        <div className="w-10 h-10 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center font-black text-lg">3</div>
                        <div>
                            <h2 className="text-xl font-extrabold text-slate-900">Kịch bản Demo khi Phản biện Đồ án</h2>
                            <p className="text-xs text-slate-500">Recommended Presentation Steps</p>
                        </div>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
                        <div className="border border-slate-200 rounded-2xl p-5 bg-slate-50/50 space-y-2">
                            <div className="font-black text-slate-900 text-sm text-indigo-600">Bước 1: Trình bày phía Khách thuê</div>
                            <ul className="space-y-1.5 text-slate-600 list-disc list-inside">
                                <li>Mở <strong className="text-slate-800">Trang chủ (/)</strong> xem thống kê Realtime kết nối từ Firebase.</li>
                                <li>Vào <strong className="text-slate-800">Bản đồ giá (/map)</strong> để minh họa heatmap giá thuê phòng các tỉnh thành.</li>
                                <li>Vào <strong className="text-slate-800">Danh sách phòng (/rooms)</strong> tìm phòng theo giá và gửi form Liên hệ xem phòng.</li>
                                <li>Vào <strong className="text-slate-800">Tra hóa đơn (/tenant)</strong> nhập SĐT khách thuê để tra cứu tiền trọ và hiện mã VietQR tự động.</li>
                            </ul>
                        </div>

                        <div className="border border-slate-200 rounded-2xl p-5 bg-slate-50/50 space-y-2">
                            <div className="font-black text-slate-900 text-sm text-indigo-600">Bước 2: Trình bày phía Chủ trọ & Admin</div>
                            <ul className="space-y-1.5 text-slate-600 list-disc list-inside">
                                <li>Mở <strong className="text-slate-800">App Flutter</strong> minh họa chốt điện nước, thêm phòng và hợp đồng.</li>
                                <li>Mở <strong className="text-slate-800">Web Admin Chủ trọ (/admin)</strong> dùng Gemini AI phân tích doanh thu và xuất file Excel / PDF.</li>
                                <li>Mở <strong className="text-slate-800">Web Admin Hệ thống (/admin/system)</strong> minh họa kiểm duyệt ẩn/hiện phòng, khóa/mở khóa account chủ trọ và theo dõi tổng nợ.</li>
                            </ul>
                        </div>
                    </div>
                </section>
            </div>
        </div>
    );
}
