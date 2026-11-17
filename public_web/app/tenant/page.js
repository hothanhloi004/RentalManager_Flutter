'use client';
import { useState } from 'react';
import { db } from '../../lib/firebase';
import { collectionGroup, getDocs, doc, getDoc, collection, addDoc, serverTimestamp } from 'firebase/firestore';

function formatMoney(n) { return new Intl.NumberFormat('vi-VN').format(Math.round(n || 0)); }

function normalizeVietQrBankId(code) {
    const normalized = String(code || '').trim().toUpperCase();
    if (/^\d+$/.test(normalized)) return normalized;
    const banks = {
        MB: '970422', MBBANK: '970422',
        VCB: '970436', VIETCOMBANK: '970436',
        TCB: '970407', TECHCOMBANK: '970407',
        BIDV: '970418',
        CTG: '970415', VIETINBANK: '970415',
        ACB: '970416',
        VPB: '970432', VPBANK: '970432',
        VIB: '970441',
        TPB: '970423', TPBANK: '970423',
        STB: '970403', SACOMBANK: '970403',
        HDB: '970437', HDBANK: '970437',
        OCB: '970448',
    };
    return banks[normalized] || normalized;
}

function parseMonthSortKey(month) {
    const str = String(month || '').trim();
    if (str.includes('/')) {
        const [m, y] = str.split('/');
        return `${y || '0000'}-${String(m || '00').padStart(2, '0')}`;
    }
    return str;
}

const vi2ascii = (str) => (str || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/\u0111/g, 'd').replace(/\u0110/g, 'D')
    .replace(/\u01b0/g, 'u').replace(/\u01af/g, 'U')
    .replace(/\u01a1/g, 'o').replace(/\u01a0/g, 'O')
    .replace(/\u1ea1/g, 'a').replace(/\u1eb9/g, 'e')
    .replace(/[^\x00-\x7F]/g, '?');

async function downloadBillReceiptPDF(bill, tenantName, settings) {
    const { default: jsPDF } = await import('jspdf');
    const { default: autoTable } = await import('jspdf-autotable');

    const docPdf = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });
    const status = String(bill.paymentStatus || '').trim().toUpperCase();
    const isPaid = status === 'DA_THANH_TOAN' || status === 'PAID';
    const remaining = Math.max((bill.totalAmount || 0) - (bill.paidAmount || 0), 0);

    docPdf.setFillColor(79, 70, 229);
    docPdf.rect(0, 0, 210, 28, 'F');
    docPdf.setTextColor(255, 255, 255);
    docPdf.setFont('helvetica', 'bold');
    docPdf.setFontSize(15);
    docPdf.text(isPaid ? 'BIEN LAI XAC NHAN THANH TOAN' : 'PHIEU BAO TIEN PHONG TRO', 14, 12);
    docPdf.setFont('helvetica', 'normal');
    docPdf.setFontSize(9);
    docPdf.text(
        `${vi2ascii(settings?.hostelName || 'Khu nha tro')}  |  Ky hoa don: Thang ${bill.month}  |  Xuat ngay: ${new Date().toLocaleDateString('vi-VN')}`,
        14,
        21
    );

    docPdf.setTextColor(30, 41, 59);
    docPdf.setFont('helvetica', 'bold');
    docPdf.setFontSize(10);
    docPdf.text(`Phong: ${vi2ascii(bill.roomName || 'Phong tro')}`, 14, 38);
    docPdf.text(`Khach thue: ${vi2ascii(tenantName || 'Khach thue')}`, 14, 44);
    docPdf.text(`Trang thai: ${isPaid ? 'DA THANH TOAN DU' : remaining < bill.totalAmount ? 'DONG THIEU' : 'CHUA THANH TOAN'}`, 120, 38);
    if (settings?.landlordPhone) {
        docPdf.setFont('helvetica', 'normal');
        docPdf.text(`SDT Chu tro: ${settings.landlordPhone}`, 120, 44);
    }

    const rows = [
        ['1', 'Tien thue phong', '1 thang', `${formatMoney(bill.rentAmount)} d`],
        [
            '2',
            'Tien dien',
            `Cu: ${bill.oldElectric || 0} -> Moi: ${bill.newElectric || 0} (${bill.electricUsed || 0} kWh x ${formatMoney(bill.electricPrice)})`,
            `${formatMoney(bill.electricAmount)} d`
        ],
        [
            '3',
            'Tien nuoc',
            `Cu: ${bill.oldWater || 0} -> Moi: ${bill.newWater || 0} (${bill.waterUsed || 0} m3 x ${formatMoney(bill.waterPrice)})`,
            `${formatMoney(bill.waterAmount)} d`
        ],
    ];
    if ((bill.serviceAmount || 0) > 0) {
        rows.push(['4', 'Phi dich vu chung (Wifi, rac, ve sinh)', 'Tron goi', `${formatMoney(bill.serviceAmount)} d`]);
    }

    autoTable(docPdf, {
        startY: 50,
        head: [['#', 'Khoan muc', 'Chi tiet chi so / Dien giai', 'Thanh tien']],
        body: rows,
        theme: 'grid',
        headStyles: { fillColor: [79, 70, 229], textColor: 255, fontStyle: 'bold', fontSize: 9 },
        bodyStyles: { fontSize: 9, textColor: [30, 41, 59] },
        columnStyles: {
            0: { cellWidth: 12, halign: 'center' },
            1: { cellWidth: 48, fontStyle: 'bold' },
            2: { cellWidth: 85 },
            3: { cellWidth: 37, halign: 'right', fontStyle: 'bold' },
        },
    });

    const finalY = (docPdf.lastAutoTable?.finalY || 95) + 10;
    docPdf.setFont('helvetica', 'bold');
    docPdf.setFontSize(11);
    docPdf.text(`TONG CONG HOA DON: ${formatMoney(bill.totalAmount)} d`, 14, finalY);
    docPdf.setTextColor(22, 163, 74);
    docPdf.text(`DA THANH TOAN: ${formatMoney(isPaid ? bill.totalAmount : bill.paidAmount)} d`, 14, finalY + 7);
    docPdf.setTextColor(220, 38, 38);
    docPdf.text(`CON NO: ${formatMoney(isPaid ? 0 : remaining)} d`, 14, finalY + 14);

    docPdf.save(`hoa-don-${vi2ascii(bill.roomName || 'phong').replace(/\s+/g, '-')}-${String(bill.month || '').replace('/', '-')}.pdf`);
}

function VietQRImage({ bankCode, bankAccount, accountName, amount, content }) {
    const bankId = normalizeVietQrBankId(bankCode);
    const ownerName = encodeURIComponent(accountName || 'Chu Tro');
    const qrUrl = `https://img.vietqr.io/image/${bankId}-${String(bankAccount || '').trim()}-compact2.png?amount=${Math.round(amount || 0)}&addInfo=${encodeURIComponent(content)}&accountName=${ownerName}`;
    return (
        <div className="flex flex-col items-center justify-center p-4 bg-white border border-slate-200 rounded-2xl shadow-sm">
            <img src={qrUrl} alt="VietQR" className="w-56 h-56 object-contain rounded-xl" />
            <p className="text-xs text-slate-500 mt-2 text-center">Quét mã bằng ứng dụng Ngân hàng để chuyển khoản ngay</p>
            <p className="text-xs text-indigo-600 font-semibold mt-1">{formatMoney(amount)}đ – {content}</p>
            <p className="text-[10px] text-amber-600 font-medium mt-3 bg-amber-50 px-3 py-1.5 rounded-lg border border-amber-100 text-center">
                ⚠️ Sau khi chuyển khoản, vui lòng chờ chủ nhà xác nhận trên ứng dụng để cập nhật trạng thái hóa đơn.
            </p>
        </div>
    );
}

function BillCard({ bill, tenantName, settings }) {
    const [showQR, setShowQR] = useState(false);
    const status = String(bill.paymentStatus || '').trim().toUpperCase();
    const isFullyPaid = status === 'DA_THANH_TOAN' || status === 'PAID';
    const remaining = Math.max((bill.totalAmount || 0) - (bill.paidAmount || 0), 0);
    const isPartial = !isFullyPaid && (status === 'DONG_THIEU' || status === 'PARTIAL' || (bill.paidAmount || 0) > 0);
    const label = isFullyPaid ? 'Đã thanh toán' : isPartial ? 'Đóng thiếu' : 'Chưa trả';
    const labelClass = isFullyPaid
        ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
        : isPartial
            ? 'bg-orange-50 text-orange-600 border-orange-200'
            : 'bg-red-50 text-red-600 border-red-200';

    return (
        <div className={`bg-white border rounded-2xl shadow-sm overflow-hidden transition-all ${isFullyPaid ? 'border-slate-200' : 'border-indigo-200'}`}>
            {/* Header */}
            <div className="px-6 py-5 flex justify-between items-start border-b border-slate-100">
                <div>
                    <div className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-1 flex items-center gap-1.5">
                        <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>
                        Tháng {bill.month}
                    </div>
                    <div className="font-bold text-slate-800 text-lg">{bill.roomName || 'Phòng của bạn'}</div>
                </div>
                <span className={`text-[11px] font-bold px-3 py-1 rounded-full border ${labelClass}`}>{label}</span>
            </div>

            {/* Breakdown */}
            <div className="px-6 py-4 space-y-2.5">
                {bill.rentAmount > 0 && (
                    <div className="flex justify-between text-sm text-slate-600">
                        <span>Tiền phòng</span>
                        <span className="font-semibold text-slate-800">{formatMoney(bill.rentAmount)}đ</span>
                    </div>
                )}
                <div className="flex justify-between text-sm text-slate-600">
                    <span>
                        Tiền điện <span className="text-xs text-slate-400">(Cũ: {bill.oldElectric ?? 0} → Mới: {bill.newElectric ?? 0} · {bill.electricUsed || 0} kWh)</span>
                    </span>
                    <span className="font-semibold text-slate-800">{formatMoney(bill.electricAmount)}đ</span>
                </div>
                <div className="flex justify-between text-sm text-slate-600">
                    <span>
                        Tiền nước <span className="text-xs text-slate-400">(Cũ: {bill.oldWater ?? 0} → Mới: {bill.newWater ?? 0} · {bill.waterUsed || 0} m³)</span>
                    </span>
                    <span className="font-semibold text-slate-800">{formatMoney(bill.waterAmount)}đ</span>
                </div>
                {bill.wifiAmount > 0 && <div className="flex justify-between text-sm text-slate-600"><span>Wi-Fi</span><span className="font-semibold">{formatMoney(bill.wifiAmount)}đ</span></div>}
                {bill.serviceAmount > 0 && <div className="flex justify-between text-sm text-slate-600"><span>Phí dịch vụ chung</span><span className="font-semibold text-slate-800">{formatMoney(bill.serviceAmount)}đ</span></div>}
                {bill.trashAmount > 0 && <div className="flex justify-between text-sm text-slate-600"><span>Rác</span><span className="font-semibold">{formatMoney(bill.trashAmount)}đ</span></div>}

                <div className="border-t border-slate-100 pt-2.5 mt-2 flex justify-between text-base font-bold text-slate-800">
                    <span>Tổng cộng</span>
                    <span className="text-indigo-700">{formatMoney(bill.totalAmount)}đ</span>
                </div>
                <div className="flex justify-between text-xs font-bold text-emerald-600">
                    <span>Đã thanh toán</span>
                    <span>{formatMoney(isFullyPaid ? bill.totalAmount : bill.paidAmount)}đ</span>
                </div>
                {!isFullyPaid && (
                    <div className="flex justify-between text-sm font-bold text-red-600">
                        <span>Còn lại cần trả</span>
                        <span>{formatMoney(remaining)}đ</span>
                    </div>
                )}
                {bill.dueDate && (
                    <div className="text-xs text-slate-400 pt-1">
                        Hạn thanh toán: {new Date(bill.dueDate).toLocaleDateString('vi-VN')}
                        {isFullyPaid && bill.paidAt ? ` · Đã tất toán ngày ${new Date(bill.paidAt).toLocaleDateString('vi-VN')}` : ''}
                    </div>
                )}
            </div>

            {/* Actions */}
            <div className="px-6 pb-6 pt-2 flex flex-col gap-2.5">
                <div className="flex gap-2">
                    {!isFullyPaid && settings?.bankCode && settings?.bankAccount && (
                        <button
                            onClick={() => setShowQR(v => !v)}
                            className={`flex-1 py-3 rounded-xl font-bold text-xs sm:text-sm flex items-center justify-center gap-2 transition-all shadow-sm ${showQR
                                ? 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                                : 'bg-indigo-600 text-white hover:bg-indigo-700'
                                }`}
                        >
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" /></svg>
                            {showQR ? 'Ẩn mã VietQR' : 'Thanh toán VietQR'}
                        </button>
                    )}
                    <button
                        onClick={() => downloadBillReceiptPDF(bill, tenantName, settings)}
                        className="flex-1 py-3 rounded-xl font-bold text-xs sm:text-sm border border-slate-200 text-slate-700 hover:bg-slate-50 flex items-center justify-center gap-1.5 transition-colors"
                    >
                        <svg className="w-4 h-4 text-rose-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" /></svg>
                        {isFullyPaid ? 'Tải Biên lai PDF' : 'Tải Phiếu báo PDF'}
                    </button>
                </div>

                {showQR && !isFullyPaid && settings?.bankCode && settings?.bankAccount && (
                    <div className="mt-2">
                        <VietQRImage
                            bankCode={settings.bankCode}
                            bankAccount={settings.bankAccount}
                            accountName={settings.landlordName}
                            amount={isPartial ? remaining : bill.totalAmount}
                            content={`Thanh toan ${bill.roomName || 'Phong tro'} ${bill.month}`}
                        />
                    </div>
                )}
            </div>
        </div>
    );
}

export default function TenantPortalPage() {
    const [phone, setPhone] = useState('');
    const [cccdLast4, setCccdLast4] = useState('');
    const [activeTab, setActiveTab] = useState('bills'); // 'bills' | 'payments' | 'contracts' | 'maintenance'
    const [bills, setBills] = useState([]);
    const [paymentHistory, setPaymentHistory] = useState([]);
    const [myContractsList, setMyContractsList] = useState([]);
    const [roomAssetsMap, setRoomAssetsMap] = useState({});
    const [maintenanceList, setMaintenanceList] = useState([]);
    const [settings, setSettings] = useState(null);
    const [landlordUid, setLandlordUid] = useState('');
    const [tenantInfo, setTenantInfo] = useState(null);
    const [tenantName, setTenantName] = useState('');
    const [loading, setLoading] = useState(false);
    const [searched, setSearched] = useState(false);
    const [error, setError] = useState('');

    // Form state for Maintenance Request
    const [repairForm, setRepairForm] = useState({
        roomName: '',
        category: 'Điện / Bóng đèn',
        priority: 'NORMAL',
        description: '',
    });
    const [submittingRepair, setSubmittingRepair] = useState(false);
    const [repairSuccessMsg, setRepairSuccessMsg] = useState('');

    async function handleSearch(e) {
        if (e) e.preventDefault();
        const p = phone.trim();
        if (!p || p.length < 9) {
            setError('Vui lòng nhập số điện thoại hợp lệ (ít nhất 9 số).');
            return;
        }
        setError('');
        setRepairSuccessMsg('');
        setLoading(true);
        setSearched(false);
        setBills([]);
        setPaymentHistory([]);
        setMyContractsList([]);
        setMaintenanceList([]);

        try {
            const cleanInputPhone = p.replace(/\D/g, '');
            const searchSuffix = cleanInputPhone.slice(-9);

            // 1. Find tenants matching this phone across all landlords
            const tenantSnap = await getDocs(collectionGroup(db, 'tenants'));
            const matched = tenantSnap.docs.filter(d => {
                const tPhone = (d.data().phone || '').replace(/\D/g, '');
                return tPhone.length >= 9 && tPhone.endsWith(searchSuffix);
            });

            if (matched.length === 0) {
                setTenantInfo(null);
                setBills([]);
                setSearched(true);
                setLoading(false);
                return;
            }

            const firstTenant = matched[0];
            const firstTenantData = firstTenant.data();
            const storedIdCard = String(firstTenantData.idCard || firstTenantData.cccd || '').replace(/\D/g, '');
            const inputPin = cccdLast4.replace(/\D/g, '');

            // Bảo mật 2 lớp: Nếu hồ sơ khách thuê trên hệ thống có lưu CCCD (>= 4 số), bắt buộc khớp 4 số cuối CCCD
            if (storedIdCard.length >= 4) {
                if (inputPin.length !== 4 || !storedIdCard.endsWith(inputPin)) {
                    setTenantInfo(null);
                    setError('🔒 Bảo mật 2 lớp: Vui lòng nhập chính xác 4 số cuối CCCD của người đứng tên hợp đồng để xem thông tin.');
                    setLoading(false);
                    return;
                }
            }

            setTenantName(firstTenantData.fullName || 'Khách thuê');
            setTenantInfo({ id: firstTenant.id, ...firstTenantData });
            const uid = firstTenant.ref.path.split('/')[1];
            setLandlordUid(uid);

            const tenantKeys = new Set();
            matched.forEach(d => {
                if (d.ref.path.split('/')[1] === uid) {
                    tenantKeys.add(String(d.id));
                    if (d.data().tenantId != null) tenantKeys.add(String(d.data().tenantId));
                    if (d.data().tenantKey != null) tenantKeys.add(String(d.data().tenantKey));
                }
            });

            // 2. Fetch bills, payments, settings, contracts, rooms, assets, maintenance in parallel
            const [billSnap, paymentSnap, sDoc, contractSnap, roomSnap, assetSnap, maintSnap] = await Promise.all([
                getDocs(collection(db, `users/${uid}/bills`)),
                getDocs(collection(db, `users/${uid}/payments`)),
                getDoc(doc(db, `users/${uid}/settings/config`)),
                getDocs(collection(db, `users/${uid}/contracts`)),
                getDocs(collection(db, `users/${uid}/rooms`)),
                getDocs(collection(db, `users/${uid}/assets`)).catch(() => ({ docs: [] })),
                getDocs(collection(db, `users/${uid}/maintenance`)).catch(() => ({ docs: [] })),
            ]);

            if (sDoc.exists()) setSettings(sDoc.data());

            // 3. Rooms map & Assets map
            const roomsDict = {};
            const roomsObjDict = {};
            roomSnap.docs.forEach(r => {
                const data = r.data();
                const rName = data.roomName || data.name || `Phòng ${r.id}`;
                roomsDict[String(r.id)] = rName;
                roomsObjDict[String(r.id)] = { id: r.id, ...data };
                if (data.roomId != null) {
                    roomsDict[String(data.roomId)] = rName;
                    roomsObjDict[String(data.roomId)] = { id: r.id, ...data };
                }
                if (data.roomKey != null) {
                    roomsDict[String(data.roomKey)] = rName;
                    roomsObjDict[String(data.roomKey)] = { id: r.id, ...data };
                }
            });

            const assetsByRoomKey = {};
            assetSnap.docs.forEach(a => {
                const data = a.data();
                const rKey = String(data.roomId ?? '');
                if (!rKey) return;
                if (!assetsByRoomKey[rKey]) assetsByRoomKey[rKey] = [];
                assetsByRoomKey[rKey].push({ id: a.id, ...data });
            });
            setRoomAssetsMap(assetsByRoomKey);

            // 4. Contracts for this tenant
            const myContracts = contractSnap.docs.filter(d => tenantKeys.has(String(d.data().tenantId ?? '')));
            const myContractKeys = new Set();
            const contractsDict = {};
            const parsedContracts = myContracts.map(c => {
                const data = c.data();
                const rKey = String(data.roomId ?? '');
                myContractKeys.add(String(c.id));
                contractsDict[String(c.id)] = rKey;
                if (data.contractId != null) {
                    myContractKeys.add(String(data.contractId));
                    contractsDict[String(data.contractId)] = rKey;
                }
                if (data.contractKey != null) {
                    myContractKeys.add(String(data.contractKey));
                    contractsDict[String(data.contractKey)] = rKey;
                }
                const roomObj = roomsObjDict[rKey];
                const roomAssets = [
                    ...(assetsByRoomKey[rKey] || []),
                    ...(roomObj && roomObj.id !== rKey ? (assetsByRoomKey[String(roomObj.id)] || []) : []),
                ];
                return {
                    id: c.id,
                    ...data,
                    roomName: roomsDict[rKey] || 'Phòng thuê',
                    roomAssets,
                };
            });
            setMyContractsList(parsedContracts);
            if (parsedContracts.length > 0) {
                setRepairForm(prev => ({ ...prev, roomName: parsedContracts[0].roomName }));
            }

            // 5. Payments & Bills
            const paymentsDict = {};
            paymentSnap.docs.forEach(d => {
                const pData = d.data();
                const bId = pData.billId != null ? String(pData.billId) : '';
                if (bId) {
                    paymentsDict[bId] = (paymentsDict[bId] || 0) + (pData.amount || 0);
                }
            });

            const billKeyToBillMeta = {};
            const myBills = billSnap.docs
                .filter(d => myContractKeys.has(String(d.data().contractId ?? '')))
                .map(d => {
                    const b = d.data();
                    const cKey = String(b.contractId ?? '');
                    const rId = contractsDict[cKey];
                    const roomName = roomsDict[rId] || 'Phòng thuê';
                    const electricUsed = Math.max((b.newElectric || 0) - (b.oldElectric || 0), b.electricUsed || 0);
                    const waterUsed = Math.max((b.newWater || 0) - (b.oldWater || 0), b.waterUsed || 0);
                    const electricAmount = electricUsed * (b.electricPrice || 0);
                    const waterAmount = waterUsed * (b.waterPrice || 0);
                    const rentAmount = b.rentPrice || 0;
                    const serviceAmount = b.serviceFee || 0;
                    const paidByKey = (b.billId != null ? paymentsDict[String(b.billId)] : 0) || paymentsDict[String(d.id)] || 0;

                    const meta = { month: b.month, roomName };
                    billKeyToBillMeta[String(d.id)] = meta;
                    if (b.billId != null) billKeyToBillMeta[String(b.billId)] = meta;

                    return {
                        id: d.id,
                        roomName,
                        ...b,
                        electricUsed,
                        waterUsed,
                        electricAmount,
                        waterAmount,
                        rentAmount,
                        serviceAmount,
                        paidAmount: paidByKey,
                    };
                })
                .sort((a, b) => parseMonthSortKey(b.month).localeCompare(parseMonthSortKey(a.month)));

            setBills(myBills);

            // 6. Build detailed Payment History list for this tenant
            const myPayments = paymentSnap.docs
                .map(d => ({ id: d.id, ...d.data() }))
                .filter(pay => billKeyToBillMeta[String(pay.billId ?? '')] != null)
                .map(pay => {
                    const meta = billKeyToBillMeta[String(pay.billId ?? '')];
                    return {
                        ...pay,
                        month: meta.month,
                        roomName: meta.roomName,
                    };
                })
                .sort((a, b) => (b.paymentDate || 0) - (a.paymentDate || 0));

            setPaymentHistory(myPayments);

            // 7. Load Maintenance tickets (from users/{uid}/maintenance + localStorage cache)
            const remoteTickets = maintSnap.docs
                .map(d => ({ id: d.id, ...d.data() }))
                .filter(t => {
                    const tPhone = String(t.phone || '').replace(/\D/g, '');
                    return tPhone.endsWith(searchSuffix) || tenantKeys.has(String(t.tenantId || ''));
                });

            let localTickets = [];
            try {
                const rawLocal = JSON.parse(localStorage.getItem(`tenant_repairs_${searchSuffix}`) || '[]');
                localTickets = Array.isArray(rawLocal) ? rawLocal : [];
            } catch {
                localTickets = [];
            }

            const mergedTicketsMap = new Map();
            localTickets.forEach(t => mergedTicketsMap.set(t.id, t));
            remoteTickets.forEach(t => mergedTicketsMap.set(t.id, t)); // Remote overwrites local so updated status shows!

            const sortedTickets = [...mergedTicketsMap.values()].sort((a, b) => {
                const ta = a.createdAt?.toMillis?.() || a.createdAtMs || 0;
                const tb = b.createdAt?.toMillis?.() || b.createdAtMs || 0;
                return tb - ta;
            });
            setMaintenanceList(sortedTickets);

        } catch (err) {
            setError('Có lỗi xảy ra: ' + err.message);
        } finally {
            setLoading(false);
            setSearched(true);
        }
    }

    async function handleSubmitRepair(e) {
        e.preventDefault();
        if (!repairForm.description.trim() || !landlordUid) return;
        setSubmittingRepair(true);
        setRepairSuccessMsg('');
        try {
            const nowMs = Date.now();
            const payload = {
                type: 'MAINTENANCE',
                roomName: repairForm.roomName || (myContractsList[0]?.roomName ?? 'Phòng thuê'),
                roomId: myContractsList[0]?.roomId ?? '',
                tenantId: tenantInfo?.id ?? '',
                name: tenantName || 'Khách thuê',
                phone: phone.trim(),
                category: repairForm.category,
                priority: repairForm.priority,
                note: `[${repairForm.category}] ${repairForm.description.trim()}`,
                description: repairForm.description.trim(),
                status: 'NEW',
                repairStatus: 'PENDING',
                createdAt: serverTimestamp(),
                createdAtMs: nowMs,
            };

            // Save to inquiries/{uid}/requests (always permitted by Firestore public create rules)
            const docRef = await addDoc(collection(db, `inquiries/${landlordUid}/requests`), payload);

            // Best-effort also write to users/{uid}/maintenance
            try {
                await addDoc(collection(db, `users/${landlordUid}/maintenance`), {
                    ...payload,
                    inquiryId: docRef.id,
                });
            } catch (_) { }

            // Send push notification to Landlord's Flutter App
            try {
                await fetch('/api/notify', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        uid: landlordUid,
                        title: `🔧 Báo sửa chữa (${repairForm.priority === 'URGENT' ? 'Khẩn cấp' : repairForm.category})`,
                        message: `${payload.roomName} - ${tenantName}: ${repairForm.description.trim()}`,
                    }),
                });
            } catch (_) { }

            const newTicket = { id: docRef.id, ...payload };
            setMaintenanceList(prev => [newTicket, ...prev]);

            // Cache in localStorage so tenant sees it immediately even before landlord syncs
            try {
                const suffix = phone.replace(/\D/g, '').slice(-9);
                const key = `tenant_repairs_${suffix}`;
                const existing = JSON.parse(localStorage.getItem(key) || '[]');
                localStorage.setItem(key, JSON.stringify([newTicket, ...existing.slice(0, 19)]));
            } catch (_) { }

            setRepairForm(prev => ({ ...prev, description: '' }));
            setRepairSuccessMsg('Đã gửi yêu cầu sửa chữa thành công! Chủ trọ đã nhận được thông báo.');
        } catch (err) {
            alert('Không thể gửi yêu cầu: ' + err.message);
        } finally {
            setSubmittingRepair(false);
        }
    }

    const unpaid = bills.filter(b => {
        const st = String(b.paymentStatus || '').trim().toUpperCase();
        return st !== 'DA_THANH_TOAN' && st !== 'PAID';
    });
    const totalOwed = unpaid.reduce((s, b) => s + Math.max((b.totalAmount || 0) - (b.paidAmount || 0), 0), 0);
    const totalPaidAllTime = paymentHistory.reduce((s, p) => s + (Number(p.amount) || 0), 0);

    return (
        <div className="min-h-screen bg-slate-50 font-sans pb-24 pt-20">
            {/* Header */}
            <div className="text-center px-6 max-w-2xl mx-auto mb-8">
                <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-indigo-50 text-indigo-600 mb-4 shadow-sm border border-indigo-100">
                    <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.8} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
                </div>
                <h1 className="text-3xl sm:text-4xl font-extrabold mb-3 text-slate-900 tracking-tight">Cổng Thông Tin Người Thuê</h1>
                <p className="text-slate-500 text-sm sm:text-base max-w-lg mx-auto">
                    Tra cứu hóa đơn, theo dõi lịch sử thanh toán, xem hợp đồng điện tử và gửi yêu cầu sửa chữa trực tiếp cho chủ trọ.
                </p>
            </div>

            {/* Search Form */}
            <div className="max-w-xl mx-auto px-4 mb-8">
                <form onSubmit={handleSearch} className="bg-white rounded-2xl shadow-sm border border-slate-200 p-5 sm:p-6">
                    <div className="flex items-center justify-between mb-3">
                        <label className="text-sm font-semibold text-slate-700 flex items-center gap-2">
                            <svg className="w-4 h-4 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" /></svg>
                            Xác thực thông tin khách thuê
                        </label>
                        <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200">
                            🔒 Bảo mật 2 lớp
                        </span>
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-12 gap-3">
                        <div className="sm:col-span-6">
                            <label className="block text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Số điện thoại hợp đồng</label>
                            <input
                                type="tel"
                                value={phone}
                                onChange={e => setPhone(e.target.value)}
                                placeholder="VD: 0901234567"
                                className="w-full px-4 py-3 border border-slate-200 bg-slate-50 rounded-xl text-sm font-medium focus:bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-colors"
                            />
                        </div>
                        <div className="sm:col-span-3">
                            <label className="block text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">4 số cuối CCCD</label>
                            <input
                                type="password"
                                inputMode="numeric"
                                maxLength={4}
                                value={cccdLast4}
                                onChange={e => setCccdLast4(e.target.value.replace(/\D/g, '').slice(0, 4))}
                                placeholder="••••"
                                className="w-full px-4 py-3 border border-slate-200 bg-slate-50 rounded-xl text-sm font-bold tracking-widest text-center focus:bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-colors"
                            />
                        </div>
                        <div className="sm:col-span-3 flex items-end">
                            <button type="submit" disabled={loading} className="w-full py-3 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-60 text-white rounded-xl font-bold text-sm transition-colors flex items-center justify-center gap-2 shadow-sm">
                                {loading ? (
                                    <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                                ) : (
                                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" /></svg>
                                )}
                                Tra cứu
                            </button>
                        </div>
                    </div>
                    <p className="text-[11px] text-slate-400 mt-2.5">
                        Hệ thống đối chiếu đồng thời Số điện thoại và 4 số cuối CCCD trên hợp đồng để bảo vệ quyền riêng tư của người thuê.
                    </p>
                    {error && <p className="text-red-600 bg-red-50 border border-red-100 rounded-xl px-3.5 py-2.5 text-xs mt-3 font-semibold">{error}</p>}
                </form>
            </div>

            {/* Results */}
            {searched && (
                <div className="max-w-3xl mx-auto px-4">
                    {!tenantInfo && bills.length === 0 ? (
                        <div className="bg-white rounded-2xl p-8 text-center border border-slate-200 shadow-sm">
                            <h3 className="font-bold text-slate-800 text-lg mb-2">Không tìm thấy hồ sơ khách thuê</h3>
                            <p className="text-sm text-slate-500">Số điện thoại này chưa được đăng ký trong hệ thống hợp đồng của chủ nhà.</p>
                        </div>
                    ) : (
                        <>
                            {/* Hostel Notice Board (Bảng thông báo khu trọ) */}
                            {settings?.notice && (
                                <div className="mb-6 bg-amber-50 border border-amber-200 rounded-2xl p-4 sm:p-5 flex gap-3.5 items-start shadow-sm">
                                    <div className="p-2 bg-amber-100 text-amber-700 rounded-xl shrink-0 mt-0.5">
                                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z" /></svg>
                                    </div>
                                    <div className="flex-1">
                                        <div className="text-xs font-extrabold uppercase tracking-wider text-amber-800 mb-1">
                                            Bảng thông báo khu trọ · {settings.hostelName || 'Chủ nhà'}
                                        </div>
                                        <p className="text-sm text-amber-900 whitespace-pre-line leading-relaxed font-medium">{settings.notice}</p>
                                    </div>
                                </div>
                            )}

                            {/* Tenant Greeting & Debt Summary */}
                            <div className="bg-white border border-slate-200 rounded-2xl p-5 mb-6 shadow-sm flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                                <div>
                                    <div className="text-xs font-bold uppercase tracking-wider text-indigo-600 mb-0.5">
                                        {settings?.hostelName || 'Khu nhà trọ'}
                                    </div>
                                    <h2 className="text-xl font-extrabold text-slate-900">Xin chào, {tenantName}!</h2>
                                    <p className="text-slate-500 text-xs sm:text-sm mt-0.5">
                                        SĐT: {tenantInfo?.phone} {settings?.landlordPhone ? `· Liên hệ chủ trọ: ${settings.landlordPhone}` : ''}
                                    </p>
                                </div>
                                <div className="flex gap-3">
                                    <div className="bg-emerald-50 border border-emerald-200 rounded-xl px-4 py-2.5 text-right">
                                        <div className="text-[10px] text-emerald-600 font-bold uppercase">Tổng đã đóng</div>
                                        <div className="text-emerald-700 font-black text-base sm:text-lg font-mono">{formatMoney(totalPaidAllTime)}đ</div>
                                    </div>
                                    <div className={`${totalOwed > 0 ? 'bg-red-50 border-red-200' : 'bg-slate-50 border-slate-200'} border rounded-xl px-4 py-2.5 text-right`}>
                                        <div className={`text-[10px] font-bold uppercase ${totalOwed > 0 ? 'text-red-500' : 'text-slate-400'}`}>Dư nợ hiện tại</div>
                                        <div className={`${totalOwed > 0 ? 'text-red-600' : 'text-slate-700'} font-black text-base sm:text-lg font-mono`}>{formatMoney(totalOwed)}đ</div>
                                    </div>
                                </div>
                            </div>

                            {/* Navigation Tabs */}
                            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 mb-6 bg-slate-200/70 p-1.5 rounded-2xl">
                                {[
                                    { id: 'bills', label: `Hóa đơn (${bills.length})` },
                                    { id: 'payments', label: `Lịch sử đóng (${paymentHistory.length})` },
                                    { id: 'contracts', label: `Hợp đồng (${myContractsList.length})` },
                                    { id: 'maintenance', label: `Báo sửa chữa (${maintenanceList.length})` },
                                ].map(tab => (
                                    <button
                                        key={tab.id}
                                        onClick={() => setActiveTab(tab.id)}
                                        className={`py-2.5 px-3 rounded-xl text-xs sm:text-sm font-bold transition-all ${activeTab === tab.id
                                            ? 'bg-white text-indigo-600 shadow-sm'
                                            : 'text-slate-600 hover:text-slate-900'
                                            }`}
                                    >
                                        {tab.label}
                                    </button>
                                ))}
                            </div>

                            {/* TAB 1: BILLS */}
                            {activeTab === 'bills' && (
                                <div className="space-y-4">
                                    {bills.length === 0 ? (
                                        <div className="bg-white rounded-2xl p-8 text-center border border-slate-200 text-slate-500 text-sm">
                                            Chưa có hóa đơn nào được tạo cho hợp đồng của bạn.
                                        </div>
                                    ) : (
                                        bills.map(bill => <BillCard key={bill.id} bill={bill} tenantName={tenantName} settings={settings} />)
                                    )}
                                </div>
                            )}

                            {/* TAB 2: PAYMENT HISTORY */}
                            {activeTab === 'payments' && (
                                <div className="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden">
                                    <div className="px-6 py-4 border-b border-slate-100 flex justify-between items-center">
                                        <div>
                                            <h3 className="font-bold text-slate-800 text-base">Lịch sử giao dịch thanh toán</h3>
                                            <p className="text-xs text-slate-400 mt-0.5">Ghi nhận tự động khi chủ trọ xác nhận thu tiền trên hệ thống</p>
                                        </div>
                                        <span className="text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200 px-3 py-1 rounded-full">
                                            {paymentHistory.length} lần đóng
                                        </span>
                                    </div>
                                    {paymentHistory.length === 0 ? (
                                        <div className="p-10 text-center text-slate-400 text-sm">
                                            Chưa có lịch sử giao dịch thanh toán nào.
                                        </div>
                                    ) : (
                                        <div className="divide-y divide-slate-100">
                                            {paymentHistory.map((pay) => (
                                                <div key={pay.id} className="px-6 py-4 flex items-center justify-between gap-4 hover:bg-slate-50 transition-colors">
                                                    <div className="flex items-center gap-3.5">
                                                        <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold shrink-0">
                                                            ✓
                                                        </div>
                                                        <div>
                                                            <div className="font-bold text-slate-800 text-sm">
                                                                Thanh toán hóa đơn Tháng {pay.month} · {pay.roomName}
                                                            </div>
                                                            <div className="text-xs text-slate-400 mt-0.5">
                                                                Ngày ghi nhận: {pay.paymentDate ? new Date(pay.paymentDate).toLocaleString('vi-VN') : 'Đã ghi nhận'}
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div className="text-right">
                                                        <div className="font-black text-emerald-600 font-mono text-base">
                                                            +{formatMoney(pay.amount)}đ
                                                        </div>
                                                        <span className="text-[10px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded">
                                                            ĐÃ THU
                                                        </span>
                                                    </div>
                                                </div>
                                            ))}
                                        </div>
                                    )}
                                </div>
                            )}

                            {/* TAB 3: CONTRACTS & ROOM ASSETS */}
                            {activeTab === 'contracts' && (
                                <div className="space-y-4">
                                    {myContractsList.length === 0 ? (
                                        <div className="bg-white rounded-2xl p-8 text-center border border-slate-200 text-slate-500 text-sm">
                                            Chưa tìm thấy hợp đồng thuê phòng.
                                        </div>
                                    ) : (
                                        myContractsList.map(c => {
                                            const isActive = ['HIEU_LUC', 'DANG_HIEU_LUC', 'ACTIVE'].includes(String(c.status || '').toUpperCase());
                                            const daysLeft = c.endDate ? Math.ceil((c.endDate - Date.now()) / (1000 * 60 * 60 * 24)) : null;
                                            return (
                                                <div key={c.id} className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                                                    <div className="flex justify-between items-start border-b border-slate-100 pb-4">
                                                        <div>
                                                            <div className="text-xs font-bold text-indigo-600 uppercase tracking-wider">Hợp đồng thuê phòng</div>
                                                            <h3 className="text-xl font-extrabold text-slate-900 mt-0.5">{c.roomName}</h3>
                                                        </div>
                                                        <span className={`text-xs font-bold px-3 py-1 rounded-full border ${isActive ? 'bg-emerald-50 text-emerald-700 border-emerald-200' : 'bg-slate-100 text-slate-600 border-slate-200'}`}>
                                                            {isActive ? 'Đang hiệu lực' : 'Đã kết thúc'}
                                                        </span>
                                                    </div>

                                                    <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 text-sm">
                                                        <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                                                            <div className="text-[11px] text-slate-400 font-bold uppercase">Giá thuê</div>
                                                            <div className="font-extrabold text-slate-800 mt-0.5">{formatMoney(c.rentPrice)}đ/tháng</div>
                                                        </div>
                                                        <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                                                            <div className="text-[11px] text-slate-400 font-bold uppercase">Tiền cọc đang giữ</div>
                                                            <div className="font-extrabold text-indigo-600 mt-0.5">{formatMoney(c.deposit)}đ</div>
                                                        </div>
                                                        <div className="bg-slate-50 p-3 rounded-xl border border-slate-100 col-span-2 sm:col-span-1">
                                                            <div className="text-[11px] text-slate-400 font-bold uppercase">Thời hạn HĐ</div>
                                                            <div className="font-bold text-slate-800 mt-0.5 text-xs">
                                                                {c.startDate ? new Date(c.startDate).toLocaleDateString('vi-VN') : '—'} → {c.endDate ? new Date(c.endDate).toLocaleDateString('vi-VN') : '—'}
                                                            </div>
                                                            {isActive && daysLeft !== null && (
                                                                <div className={`text-[11px] font-bold mt-0.5 ${daysLeft <= 15 ? 'text-amber-600' : 'text-emerald-600'}`}>
                                                                    {daysLeft > 0 ? `Còn ${daysLeft} ngày` : 'Đã đến hạn gia hạn'}
                                                                </div>
                                                            )}
                                                        </div>
                                                    </div>

                                                    <div className="grid grid-cols-2 gap-3 text-xs text-slate-600 bg-slate-50 p-3.5 rounded-xl border border-slate-100">
                                                        <div>⚡ Chỉ số điện bàn giao: <strong className="text-slate-800">{c.initialElectric ?? 0} kWh</strong> (Hiện tại: {c.lastElectric ?? 0})</div>
                                                        <div>💧 Chỉ số nước bàn giao: <strong className="text-slate-800">{c.initialWater ?? 0} m³</strong> (Hiện tại: {c.lastWater ?? 0})</div>
                                                    </div>

                                                    {c.roomAssets && c.roomAssets.length > 0 && (
                                                        <div>
                                                            <div className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-2">
                                                                Thiết bị & Tài sản bàn giao trong phòng ({c.roomAssets.length})
                                                            </div>
                                                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                                                                {c.roomAssets.map(asset => (
                                                                    <div key={asset.id} className="flex items-center justify-between px-3 py-2 bg-slate-50 border border-slate-100 rounded-lg text-xs">
                                                                        <span className="font-bold text-slate-700">{asset.name} (SL: {asset.quantity || 1})</span>
                                                                        <span className="text-emerald-600 font-semibold">{asset.condition || 'Tốt'}</span>
                                                                    </div>
                                                                ))}
                                                            </div>
                                                        </div>
                                                    )}
                                                </div>
                                            );
                                        })
                                    )}
                                </div>
                            )}

                            {/* TAB 4: MAINTENANCE & REPAIR REQUESTS */}
                            {activeTab === 'maintenance' && (
                                <div className="space-y-6">
                                    {/* Submit form */}
                                    <form onSubmit={handleSubmitRepair} className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
                                        <div>
                                            <h3 className="font-bold text-slate-800 text-base">Gửi yêu cầu sửa chữa / Báo sự cố</h3>
                                            <p className="text-xs text-slate-500 mt-0.5">
                                                Thông tin sẽ được gửi trực tiếp tới ứng dụng của Chủ trọ để sắp xếp thợ xử lý.
                                            </p>
                                        </div>

                                        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                                            <div>
                                                <label className="block text-xs font-bold text-slate-600 uppercase mb-1">Phòng</label>
                                                <input
                                                    type="text"
                                                    value={repairForm.roomName}
                                                    onChange={e => setRepairForm(prev => ({ ...prev, roomName: e.target.value }))}
                                                    className="w-full px-3 py-2.5 border border-slate-200 rounded-xl text-sm bg-slate-50 font-semibold"
                                                    required
                                                />
                                            </div>
                                            <div>
                                                <label className="block text-xs font-bold text-slate-600 uppercase mb-1">Hạng mục</label>
                                                <select
                                                    value={repairForm.category}
                                                    onChange={e => setRepairForm(prev => ({ ...prev, category: e.target.value }))}
                                                    className="w-full px-3 py-2.5 border border-slate-200 rounded-xl text-sm bg-white font-medium"
                                                >
                                                    <option value="Điện / Bóng đèn">⚡ Điện / Bóng đèn</option>
                                                    <option value="Nước / Ống nước">💧 Nước / Vòi sen / Ống nước</option>
                                                    <option value="Máy lạnh / Thiết bị">❄️ Máy lạnh / Thiết bị</option>
                                                    <option value="Cửa / Khóa / Cửa sổ">🔑 Cửa / Khóa / Cửa sổ</option>
                                                    <option value="Internet / Wi-Fi">📶 Internet / Wi-Fi</option>
                                                    <option value="Khác">🛠 Khác</option>
                                                </select>
                                            </div>
                                            <div>
                                                <label className="block text-xs font-bold text-slate-600 uppercase mb-1">Mức độ ưu tiên</label>
                                                <select
                                                    value={repairForm.priority}
                                                    onChange={e => setRepairForm(prev => ({ ...prev, priority: e.target.value }))}
                                                    className="w-full px-3 py-2.5 border border-slate-200 rounded-xl text-sm bg-white font-medium"
                                                >
                                                    <option value="NORMAL">🟢 Bình thường</option>
                                                    <option value="URGENT">🔴 Khẩn cấp (Rò nước, chập điện...)</option>
                                                </select>
                                            </div>
                                        </div>

                                        <div>
                                            <label className="block text-xs font-bold text-slate-600 uppercase mb-1">Mô tả chi tiết tình trạng *</label>
                                            <textarea
                                                rows={3}
                                                required
                                                value={repairForm.description}
                                                onChange={e => setRepairForm(prev => ({ ...prev, description: e.target.value }))}
                                                placeholder="Ví dụ: Máy lạnh bật không mát và bị chảy nước ở dàn lạnh, nhờ chủ nhà cho thợ kiểm tra giúp vào buổi chiều..."
                                                className="w-full px-4 py-3 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-none"
                                            />
                                        </div>

                                        {repairSuccessMsg && (
                                            <div className="p-3 bg-emerald-50 border border-emerald-200 text-emerald-700 rounded-xl text-xs font-bold">
                                                ✅ {repairSuccessMsg}
                                            </div>
                                        )}

                                        <button
                                            type="submit"
                                            disabled={submittingRepair}
                                            className="w-full py-3 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-60 text-white rounded-xl font-bold text-sm transition-colors shadow-sm"
                                        >
                                            {submittingRepair ? 'Đang gửi yêu cầu...' : 'Gửi yêu cầu sửa chữa'}
                                        </button>
                                    </form>

                                    {/* Repair Tickets History */}
                                    <div className="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden">
                                        <div className="px-6 py-4 border-b border-slate-100 flex justify-between items-center">
                                            <h3 className="font-bold text-slate-800 text-base">Lịch sử báo sửa chữa của bạn</h3>
                                            <span className="text-xs font-bold text-slate-400">{maintenanceList.length} yêu cầu</span>
                                        </div>
                                        {maintenanceList.length === 0 ? (
                                            <div className="p-8 text-center text-slate-400 text-sm">
                                                Bạn chưa gửi yêu cầu sửa chữa nào.
                                            </div>
                                        ) : (
                                            <div className="divide-y divide-slate-100">
                                                {maintenanceList.map(item => {
                                                    const st = String(item.repairStatus || item.status || 'PENDING').toUpperCase();
                                                    const isDone = st === 'DONE' || st === 'COMPLETED';
                                                    const isInProgress = st === 'IN_PROGRESS' || st === 'PROCESSING';
                                                    const badgeText = isDone ? 'Đã hoàn thành' : isInProgress ? 'Đang sửa chữa' : 'Chờ xử lý';
                                                    const badgeClass = isDone
                                                        ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                                                        : isInProgress
                                                            ? 'bg-sky-50 text-sky-700 border-sky-200'
                                                            : 'bg-amber-50 text-amber-700 border-amber-200';
                                                    return (
                                                        <div key={item.id} className="p-5 space-y-2">
                                                            <div className="flex justify-between items-start gap-2">
                                                                <div className="flex items-center gap-2 flex-wrap">
                                                                    <span className="font-bold text-slate-800 text-sm">{item.category || 'Sửa chữa'}</span>
                                                                    <span className="text-xs text-slate-400">· {item.roomName}</span>
                                                                    {item.priority === 'URGENT' && (
                                                                        <span className="text-[10px] font-bold bg-rose-50 text-rose-600 border border-rose-200 px-2 py-0.5 rounded-full">
                                                                            KHẨN CẤP
                                                                        </span>
                                                                    )}
                                                                </div>
                                                                <span className={`text-[11px] font-bold px-2.5 py-0.5 rounded-full border ${badgeClass}`}>
                                                                    {badgeText}
                                                                </span>
                                                            </div>
                                                            <p className="text-sm text-slate-600">{item.description || item.note}</p>
                                                            {item.landlordReply && (
                                                                <div className="bg-indigo-50 border border-indigo-100 rounded-xl p-3 text-xs text-indigo-900">
                                                                    <strong>💬 Phản hồi từ chủ trọ:</strong> {item.landlordReply}
                                                                </div>
                                                            )}
                                                            <div className="text-[11px] text-slate-400">
                                                                Gửi lúc: {item.createdAt?.toDate?.()?.toLocaleString?.('vi-VN') || (item.createdAtMs ? new Date(item.createdAtMs).toLocaleString('vi-VN') : 'Vừa xong')}
                                                            </div>
                                                        </div>
                                                    );
                                                })}
                                            </div>
                                        )}
                                    </div>
                                </div>
                            )}
                        </>
                    )}
                </div>
            )}
        </div>
    );
}
