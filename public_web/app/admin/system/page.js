'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { db, auth } from '../../../lib/firebase';
import { GoogleAuthProvider, onAuthStateChanged, signInWithPopup, signOut } from 'firebase/auth';
import { collectionGroup, deleteDoc, doc, getDoc, getDocs, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';

const ADMIN_EMAILS = (process.env.NEXT_PUBLIC_SYSTEM_ADMIN_EMAILS || '')
    .split(',')
    .map(email => email.trim().toLowerCase())
    .filter(Boolean);

const money = new Intl.NumberFormat('vi-VN');

function ownerUidFromPath(path, collectionName) {
    const parts = path.split('/');
    const index = parts.lastIndexOf(collectionName);
    return index > 0 ? parts[index - 1] : '';
}

function isVacant(room) {
    const status = String(room?.status || '').trim().toUpperCase();
    return ['TRONG', 'EMPTY', 'AVAILABLE'].includes(status);
}

function isActiveContract(contract) {
    const status = String(contract?.status || '').trim().toUpperCase();
    return ['HIEU_LUC', 'DANG_HIEU_LUC', 'ACTIVE'].includes(status);
}

function isPaidBill(bill) {
    const status = String(bill?.paymentStatus || '').trim().toUpperCase();
    return ['DA_THANH_TOAN', 'PAID'].includes(status);
}

function StatCard({ label, value, sub, tone = 'indigo' }) {
    const toneMap = {
        indigo: 'bg-indigo-50 text-indigo-700 border-indigo-100',
        emerald: 'bg-emerald-50 text-emerald-700 border-emerald-100',
        amber: 'bg-amber-50 text-amber-700 border-amber-100',
        rose: 'bg-rose-50 text-rose-700 border-rose-100',
        slate: 'bg-slate-50 text-slate-700 border-slate-100',
    };
    return (
        <div className={`rounded-2xl border p-5 ${toneMap[tone] || toneMap.indigo}`}>
            <div className="text-xs font-bold uppercase tracking-wide opacity-75">{label}</div>
            <div className="mt-2 text-3xl font-black">{value}</div>
            {sub && <div className="mt-1 text-xs font-semibold opacity-75">{sub}</div>}
        </div>
    );
}

export default function SystemAdminPage() {
    const [user, setUser] = useState(null);
    const [authLoading, setAuthLoading] = useState(true);
    const [roleLoading, setRoleLoading] = useState(false);
    const [isAdmin, setIsAdmin] = useState(false);
    const [roleInfo, setRoleInfo] = useState(null);
    const [activeTab, setActiveTab] = useState('overview');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [rooms, setRooms] = useState([]);
    const [tenants, setTenants] = useState([]);
    const [contracts, setContracts] = useState([]);
    const [bills, setBills] = useState([]);
    const [payments, setPayments] = useState([]);
    const [inquiries, setInquiries] = useState([]);
    const [landlords, setLandlords] = useState({});
    const [rolesMap, setRolesMap] = useState({});
    const [deleteConfirm, setDeleteConfirm] = useState(null); // { room, inputVal }

    async function fetchSystemData() {
        setLoading(true);
        setError('');
        try {
            const [roomSnap, tenantSnap, contractSnap, billSnap, paymentSnap, inquirySnap] = await Promise.all([
                getDocs(collectionGroup(db, 'rooms')),
                getDocs(collectionGroup(db, 'tenants')),
                getDocs(collectionGroup(db, 'contracts')),
                getDocs(collectionGroup(db, 'bills')),
                getDocs(collectionGroup(db, 'payments')),
                getDocs(collectionGroup(db, 'requests')),
            ]);

            const nextRooms = roomSnap.docs.map(d => ({ id: d.id, ownerUid: ownerUidFromPath(d.ref.path, 'rooms'), path: d.ref.path, ref: d.ref, ...d.data() }));
            const nextTenants = tenantSnap.docs.map(d => ({ id: d.id, ownerUid: ownerUidFromPath(d.ref.path, 'tenants'), path: d.ref.path, ...d.data() }));
            const nextContracts = contractSnap.docs.map(d => ({ id: d.id, ownerUid: ownerUidFromPath(d.ref.path, 'contracts'), path: d.ref.path, ...d.data() }));
            const nextBills = billSnap.docs.map(d => ({ id: d.id, ownerUid: ownerUidFromPath(d.ref.path, 'bills'), path: d.ref.path, ...d.data() }));
            const nextPayments = paymentSnap.docs.map(d => ({ id: d.id, ownerUid: ownerUidFromPath(d.ref.path, 'payments'), path: d.ref.path, ...d.data() }));
            const nextInquiries = inquirySnap.docs.map(d => ({ id: d.id, ownerUid: ownerUidFromPath(d.ref.path, 'requests'), path: d.ref.path, ref: d.ref, ...d.data() }));

            const ownerIds = [...new Set([
                ...nextRooms.map(r => r.ownerUid),
                ...nextTenants.map(t => t.ownerUid),
                ...nextContracts.map(c => c.ownerUid),
                ...nextBills.map(b => b.ownerUid),
                ...nextInquiries.map(i => i.ownerUid),
            ].filter(Boolean))];

            const settingsEntries = await Promise.all(ownerIds.map(async uid => {
                try {
                    const snap = await getDoc(doc(db, `users/${uid}/settings/config`));
                    return [uid, snap.exists() ? snap.data() : {}];
                } catch {
                    return [uid, {}];
                }
            }));

            const rolesEntries = await Promise.all(ownerIds.map(async uid => {
                try {
                    const snap = await getDoc(doc(db, `roles/${uid}`));
                    return [uid, snap.exists() ? snap.data() : { role: 'LANDLORD', active: true }];
                } catch {
                    return [uid, { role: 'LANDLORD', active: true }];
                }
            }));

            setRooms(nextRooms);
            setTenants(nextTenants);
            setContracts(nextContracts);
            setBills(nextBills);
            setPayments(nextPayments);
            setInquiries(nextInquiries.sort((a, b) => (b.createdAt?.toMillis?.() || 0) - (a.createdAt?.toMillis?.() || 0)));
            setLandlords(Object.fromEntries(settingsEntries));
            setRolesMap(Object.fromEntries(rolesEntries));
        } catch (e) {
            setError(e.message || 'Không tải được dữ liệu Admin.');
        } finally {
            setLoading(false);
        }
    }

    useEffect(() => {
        const unsub = onAuthStateChanged(auth, async currentUser => {
            setUser(currentUser);
            setAuthLoading(false);
            setIsAdmin(false);
            setRoleInfo(null);
            if (!currentUser) return;

            setRoleLoading(true);
            try {
                const emailAllowed = ADMIN_EMAILS.includes(String(currentUser.email || '').toLowerCase());
                const roleSnap = await getDoc(doc(db, `roles/${currentUser.uid}`));
                const roleData = roleSnap.exists() ? roleSnap.data() : null;
                const roleAllowed = roleData?.active === true && ['ADMIN', 'SUPER_ADMIN'].includes(String(roleData?.role || '').toUpperCase());
                setRoleInfo(roleData);
                setIsAdmin(emailAllowed || roleAllowed);
                if (emailAllowed || roleAllowed) fetchSystemData();
            } catch (e) {
                setError(e.message || 'Không kiểm tra được quyền Admin.');
            } finally {
                setRoleLoading(false);
            }
        });
        return () => unsub();
    }, []);

    const handleGoogleSignIn = async () => {
        const provider = new GoogleAuthProvider();
        provider.setCustomParameters({ prompt: 'select_account' });
        await signInWithPopup(auth, provider);
    };

    const paymentsByBill = useMemo(() => {
        const map = {};
        payments.forEach(payment => {
            const billId = String(payment.billId || '');
            if (!billId) return;
            map[billId] = (map[billId] || 0) + (Number(payment.amount) || 0);
        });
        return map;
    }, [payments]);

    const enrichedBills = useMemo(() => bills.map(bill => {
        const key = String(bill.billId || bill.id);
        const paid = paymentsByBill[key] || 0;
        const total = Number(bill.totalAmount) || 0;
        return { ...bill, paidAmount: isPaidBill(bill) ? total : paid, debtAmount: Math.max(total - paid, 0) };
    }), [bills, paymentsByBill]);

    const ownerStats = useMemo(() => {
        const map = {};
        const ensure = uid => {
            if (!map[uid]) {
                const setting = landlords[uid] || {};
                const roleDoc = rolesMap[uid] || {};
                const isBlocked = roleDoc.active === false || setting.isBlocked === true;
                map[uid] = {
                    uid,
                    hostelName: setting.hostelName || setting.motelName || 'Chưa đặt tên',
                    landlordName: setting.landlordName || setting.ownerName || 'Chủ trọ',
                    phone: setting.landlordPhone || setting.ownerPhone || '',
                    isBlocked,
                    role: roleDoc.role || 'LANDLORD',
                    rooms: 0,
                    publicRooms: 0,
                    tenants: 0,
                    contracts: 0,
                    bills: 0,
                    debt: 0,
                };
            }
            return map[uid];
        };

        rooms.forEach(room => {
            const item = ensure(room.ownerUid);
            item.rooms += 1;
            if (isVacant(room) && room.adminHidden !== true) item.publicRooms += 1;
        });
        tenants.forEach(tenant => ensure(tenant.ownerUid).tenants += 1);
        contracts.forEach(contract => {
            if (isActiveContract(contract)) ensure(contract.ownerUid).contracts += 1;
        });
        enrichedBills.forEach(bill => {
            const item = ensure(bill.ownerUid);
            item.bills += 1;
            if (!isPaidBill(bill)) item.debt += bill.debtAmount;
        });
        inquiries.forEach(inquiry => ensure(inquiry.ownerUid));
        return Object.values(map).sort((a, b) => b.rooms - a.rooms);
    }, [rooms, tenants, contracts, enrichedBills, inquiries, landlords, rolesMap]);

    const stats = useMemo(() => {
        const totalDebt = enrichedBills.filter(b => !isPaidBill(b)).reduce((sum, b) => sum + b.debtAmount, 0);
        const revenue = enrichedBills.filter(isPaidBill).reduce((sum, b) => sum + (Number(b.totalAmount) || 0), 0);
        return {
            landlords: ownerStats.length,
            rooms: rooms.length,
            publicRooms: rooms.filter(r => isVacant(r) && r.adminHidden !== true).length,
            tenants: tenants.length,
            activeContracts: contracts.filter(isActiveContract).length,
            bills: bills.length,
            revenue,
            debt: totalDebt,
            inquiries: inquiries.length,
        };
    }, [ownerStats, rooms, tenants, contracts, bills, enrichedBills, inquiries]);

    const toggleRoomVisibility = async (room) => {
        const nextHidden = room.adminHidden !== true;
        await updateDoc(room.ref, {
            adminHidden: nextHidden,
            adminReviewedAt: serverTimestamp(),
            adminReviewedBy: user?.uid || '',
        });
        setRooms(prev => prev.map(r => r.path === room.path ? { ...r, adminHidden: nextHidden } : r));
    };

    const deleteRoomByAdmin = (room) => {
        setDeleteConfirm({ room, inputVal: '', deleting: false, error: '' });
    };

    const confirmDelete = async () => {
        const { room, inputVal } = deleteConfirm;
        const roomLabel = room.roomName || room.name || room.id;
        if (inputVal.trim() !== roomLabel.trim()) {
            setDeleteConfirm(prev => ({ ...prev, error: `Tên không khớp. Vui lòng gõ đúng: "${roomLabel}"` }));
            return;
        }
        setDeleteConfirm(prev => ({ ...prev, deleting: true, error: '' }));
        try {
            await deleteDoc(room.ref);
            setRooms(prev => prev.filter(r => r.path !== room.path));
            setDeleteConfirm(null);
        } catch (err) {
            setDeleteConfirm(prev => ({ ...prev, deleting: false, error: 'Lỗi: ' + err.message }));
        }
    };

    const toggleLandlordAccount = async (landlord) => {
        const nextActive = landlord.isBlocked; // if blocked (active=false), nextActive = true
        const actionText = nextActive ? 'MỞ KHÓA' : 'KHÓA';
        if (!confirm(`Bạn có chắc chắn muốn ${actionText} tài khoản chủ trọ "${landlord.hostelName}" (UID: ${landlord.uid})?`)) return;
        try {
            await setDoc(doc(db, `roles/${landlord.uid}`), {
                role: landlord.role || 'LANDLORD',
                active: nextActive,
                updatedAt: serverTimestamp(),
                updatedBy: user?.uid || '',
            }, { merge: true });

            await setDoc(doc(db, `users/${landlord.uid}/settings/config`), {
                isBlocked: !nextActive,
                updatedAt: serverTimestamp(),
            }, { merge: true });

            setRolesMap(prev => ({ ...prev, [landlord.uid]: { ...prev[landlord.uid], active: nextActive } }));
            setLandlords(prev => ({ ...prev, [landlord.uid]: { ...prev[landlord.uid], isBlocked: !nextActive } }));
            alert(`Đã ${actionText} tài khoản thành công!`);
        } catch (err) {
            alert(`Lỗi khi ${actionText} tài khoản: ` + err.message);
        }
    };

    const editLandlordInfo = async (landlord) => {
        const newHostelName = prompt('Nhập Tên Nhà Trọ mới cho chủ trọ này:', landlord.hostelName);
        if (newHostelName === null) return;
        const newPhone = prompt('Nhập Số Điện Thoại liên hệ mới:', landlord.phone);
        if (newPhone === null) return;

        try {
            await setDoc(doc(db, `users/${landlord.uid}/settings/config`), {
                hostelName: newHostelName.trim(),
                landlordPhone: newPhone.trim(),
                updatedAt: serverTimestamp(),
                updatedBy: user?.uid || '',
            }, { merge: true });

            setLandlords(prev => ({
                ...prev,
                [landlord.uid]: {
                    ...prev[landlord.uid],
                    hostelName: newHostelName.trim(),
                    landlordPhone: newPhone.trim(),
                }
            }));
            alert('Đã cập nhật thông tin hỗ trợ chủ trọ thành công!');
        } catch (err) {
            alert('Lỗi cập nhật: ' + err.message);
        }
    };

    const markInquiryStatus = async (inquiry, status) => {
        await updateDoc(inquiry.ref, {
            adminStatus: status,
            adminReviewedAt: serverTimestamp(),
            adminReviewedBy: user?.uid || '',
        });
        setInquiries(prev => prev.map(item => item.path === inquiry.path ? { ...item, adminStatus: status } : item));
    };

    if (authLoading || roleLoading) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-slate-50">
                <div className="h-10 w-10 rounded-full border-4 border-indigo-100 border-t-indigo-600 animate-spin" />
            </div>
        );
    }

    if (!user) {
        return (
            <div className="min-h-screen bg-slate-50 flex items-center justify-center px-4">
                <div className="max-w-md w-full bg-white rounded-3xl border border-slate-200 p-8 text-center shadow-xl">
                    <div className="mx-auto mb-5 h-14 w-14 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center font-black text-xl">A</div>
                    <h1 className="text-2xl font-black text-slate-900">Admin hệ thống</h1>
                    <p className="mt-2 text-sm text-slate-500">Đăng nhập bằng tài khoản được cấp quyền Admin để quản trị toàn nền tảng Rental Manager.</p>
                    <button onClick={handleGoogleSignIn} className="mt-6 w-full rounded-xl bg-indigo-600 px-5 py-3 font-bold text-white hover:bg-indigo-700 transition-colors">
                        Đăng nhập Google
                    </button>
                </div>
            </div>
        );
    }

    if (!isAdmin) {
        return (
            <div className="min-h-screen bg-slate-50 flex items-center justify-center px-4">
                <div className="max-w-lg w-full bg-white rounded-3xl border border-rose-100 p-8 text-center shadow-xl">
                    <div className="mx-auto mb-5 h-14 w-14 rounded-2xl bg-rose-50 text-rose-600 flex items-center justify-center font-black text-xl">!</div>
                    <h1 className="text-2xl font-black text-slate-900">Tài khoản chưa có quyền Admin</h1>
                    <p className="mt-2 text-sm text-slate-500">
                        Tài khoản Google <span className="font-semibold text-slate-700">{user.email}</span> không nằm trong danh sách Quản trị viên hệ thống (<span className="font-mono text-slate-700">NEXT_PUBLIC_SYSTEM_ADMIN_EMAILS</span>) hoặc chưa được cấp quyền trong <span className="font-mono text-slate-700">roles/{user.uid}</span>.
                    </p>
                    {roleInfo && <pre className="mt-4 text-left bg-slate-50 rounded-xl p-3 text-xs text-slate-500 overflow-auto">{JSON.stringify(roleInfo, null, 2)}</pre>}
                    <div className="mt-6 flex flex-col sm:flex-row gap-3">
                        <button onClick={() => signOut(auth)} className="flex-1 rounded-xl border border-slate-200 px-5 py-3 font-bold text-slate-600 hover:bg-slate-50">Đổi tài khoản Google</button>
                        <Link href="/admin" className="flex-1 rounded-xl bg-indigo-600 px-5 py-3 font-bold text-white hover:bg-indigo-700">Về Kênh Chủ Trọ</Link>
                    </div>
                </div>
            </div>
        );
    }

    const reportInquiries = inquiries.filter(i => i.type === 'REPORT' || i.adminStatus === 'REPORTED');
    const recentInquiries = inquiries.filter(i => i.type !== 'REPORT').slice(0, 12);
    const debtBills = enrichedBills.filter(b => !isPaidBill(b)).sort((a, b) => b.debtAmount - a.debtAmount).slice(0, 20);
    const visibleRooms = rooms.slice().sort((a, b) => String(a.roomName || '').localeCompare(String(b.roomName || ''), 'vi'));

    return (
        <div className="min-h-screen bg-slate-50 text-slate-900">

            {/* ── Safe Delete Modal ───────────────────────────── */}
            {deleteConfirm && (() => {
                const roomLabel = deleteConfirm.room?.roomName || deleteConfirm.room?.name || deleteConfirm.room?.id || '';
                return (
                    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
                        <div className="bg-white rounded-3xl shadow-2xl w-full max-w-md p-8">
                            <div className="flex items-center gap-3 mb-5">
                                <div className="w-11 h-11 rounded-2xl bg-rose-50 text-rose-600 flex items-center justify-center flex-shrink-0">
                                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                                </div>
                                <div>
                                    <h2 className="text-lg font-black text-slate-900">Xóa phòng vĩnh viễn</h2>
                                    <p className="text-xs text-slate-400">Hành động này không thể hoàn tác</p>
                                </div>
                            </div>

                            <div className="rounded-2xl bg-rose-50 border border-rose-100 p-4 mb-5 text-sm text-rose-700">
                                ⚠️ Phòng sẽ bị <strong>xóa vĩnh viễn khỏi Firestore</strong>, bao gồm cả trong App Flutter của chủ trọ. Dữ liệu <strong>không thể khôi phục</strong>.
                            </div>

                            <p className="text-sm text-slate-600 mb-2">
                                Để xác nhận, hãy gõ chính xác tên phòng:
                            </p>
                            <div className="bg-slate-100 rounded-xl px-4 py-2 font-mono text-sm text-slate-800 font-bold mb-3 select-all">
                                {roomLabel}
                            </div>

                            <input
                                type="text"
                                autoFocus
                                value={deleteConfirm.inputVal}
                                onChange={e => setDeleteConfirm(prev => ({ ...prev, inputVal: e.target.value, error: '' }))}
                                onKeyDown={e => e.key === 'Enter' && confirmDelete()}
                                placeholder="Gõ tên phòng vào đây..."
                                className="w-full px-4 py-3 border-2 border-slate-200 rounded-xl text-sm focus:outline-none focus:border-rose-400 transition-colors mb-2"
                            />
                            {deleteConfirm.error && (
                                <p className="text-xs text-rose-600 font-semibold mb-3">{deleteConfirm.error}</p>
                            )}

                            <div className="flex gap-3 mt-4">
                                <button
                                    onClick={() => setDeleteConfirm(null)}
                                    disabled={deleteConfirm.deleting}
                                    className="flex-1 rounded-xl border border-slate-200 px-4 py-3 font-bold text-slate-600 hover:bg-slate-50 disabled:opacity-50"
                                >
                                    Hủy bỏ
                                </button>
                                <button
                                    onClick={confirmDelete}
                                    disabled={deleteConfirm.deleting || deleteConfirm.inputVal.trim() !== roomLabel.trim()}
                                    className="flex-1 rounded-xl bg-rose-600 hover:bg-rose-700 disabled:bg-rose-300 px-4 py-3 font-bold text-white transition-colors"
                                >
                                    {deleteConfirm.deleting ? 'Đang xóa...' : 'Xóa vĩnh viễn'}
                                </button>
                            </div>
                        </div>
                    </div>
                );
            })()}
            <header className="sticky top-16 z-30 bg-white/95 backdrop-blur border-b border-slate-200">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4 flex flex-col lg:flex-row gap-4 justify-between">
                    <div>
                        <div className="text-xs font-black uppercase tracking-widest text-indigo-600">System Admin</div>
                        <h1 className="text-2xl sm:text-3xl font-black text-slate-900">Quản trị toàn nền tảng Rental Manager</h1>
                        <p className="mt-1 text-sm text-slate-500">Đăng nhập: {user.email}</p>
                    </div>
                    <div className="flex flex-wrap gap-2 items-center">
                        {['overview', 'landlords', 'rooms', 'reports', 'inquiries', 'billing'].map(tab => (
                            <button
                                key={tab}
                                onClick={() => setActiveTab(tab)}
                                className={`rounded-xl px-4 py-2 text-sm font-bold transition-colors ${activeTab === tab ? 'bg-indigo-600 text-white' : 'bg-white border border-slate-200 text-slate-600 hover:bg-slate-50'}`}
                            >
                                {{
                                    overview: 'Tổng quan',
                                    landlords: 'Chủ trọ & Tài khoản',
                                    rooms: 'Kiểm duyệt & Xóa phòng',
                                    reports: `Báo cáo vi phạm (${reportInquiries.length})`,
                                    inquiries: 'Yêu cầu khách & Sửa chữa',
                                    billing: 'Hóa đơn',
                                }[tab]}
                            </button>
                        ))}
                        <button onClick={fetchSystemData} className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-bold text-slate-600 hover:bg-slate-50">
                            Làm mới
                        </button>
                        <button onClick={() => signOut(auth)} className="rounded-xl border border-rose-200 bg-rose-50 px-4 py-2 text-sm font-bold text-rose-600 hover:bg-rose-100">
                            Đăng xuất
                        </button>
                    </div>
                </div>
            </header>

            <main className="max-w-7xl mx-auto px-4 sm:px-6 py-8">
                {error && <div className="mb-6 rounded-2xl border border-rose-200 bg-rose-50 p-4 text-sm font-semibold text-rose-700">{error}</div>}
                {loading && <div className="mb-6 rounded-2xl border border-indigo-100 bg-indigo-50 p-4 text-sm font-semibold text-indigo-700">Đang tải dữ liệu toàn hệ thống...</div>}

                {activeTab === 'overview' && (
                    <div className="space-y-8">
                        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                            <StatCard label="Chủ trọ" value={stats.landlords} sub="tài khoản có dữ liệu" />
                            <StatCard label="Phòng công khai" value={`${stats.publicRooms}/${stats.rooms}`} sub="đang trống và không bị ẩn" tone="emerald" />
                            <StatCard label="Hợp đồng hiệu lực" value={stats.activeContracts} sub={`${stats.tenants} khách thuê`} tone="slate" />
                            <StatCard label="Yêu cầu liên hệ" value={stats.inquiries} sub="từ website public" tone="amber" />
                            <StatCard label="Hóa đơn" value={stats.bills} sub="toàn hệ thống" tone="slate" />
                            <StatCard label="Doanh thu đã thu" value={`${money.format(stats.revenue)}đ`} tone="emerald" />
                            <StatCard label="Công nợ" value={`${money.format(stats.debt)}đ`} tone="rose" />
                            <StatCard label="Phòng bị ẩn" value={rooms.filter(r => r.adminHidden === true).length} sub="do Admin kiểm duyệt" tone="amber" />
                        </div>

                        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                            <section className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                                <div className="px-5 py-4 border-b border-slate-100">
                                    <h2 className="font-black text-slate-800">Chủ trọ nổi bật</h2>
                                </div>
                                <div className="divide-y divide-slate-100">
                                    {ownerStats.slice(0, 6).map(item => (
                                        <div key={item.uid} className="p-5 flex items-center justify-between gap-4">
                                            <div>
                                                <div className="font-bold text-slate-900 flex items-center gap-2">
                                                    {item.hostelName}
                                                    {item.isBlocked && <span className="text-[10px] bg-rose-100 text-rose-700 px-2 py-0.5 rounded-full font-bold">ĐÃ KHÓA</span>}
                                                </div>
                                                <div className="text-sm text-slate-500">{item.landlordName} · {item.phone || item.uid}</div>
                                            </div>
                                            <div className="text-right text-sm">
                                                <div className="font-black text-indigo-600">{item.rooms} phòng</div>
                                                <div className="text-rose-600 font-semibold">{money.format(item.debt)}đ nợ</div>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            </section>

                            <section className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                                <div className="px-5 py-4 border-b border-slate-100">
                                    <h2 className="font-black text-slate-800">Yêu cầu mới</h2>
                                </div>
                                <div className="divide-y divide-slate-100">
                                    {recentInquiries.slice(0, 6).map(inq => (
                                        <div key={inq.path} className="p-5">
                                            <div className="flex items-start justify-between gap-4">
                                                <div>
                                                    <div className="font-bold text-slate-900">{inq.name || 'Khách'}</div>
                                                    <div className="text-sm text-slate-500">{inq.phone} · {inq.roomName || 'Phòng quan tâm'}</div>
                                                </div>
                                                <span className="rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-bold text-slate-500">{inq.adminStatus || inq.status || 'NEW'}</span>
                                            </div>
                                            {inq.note && <p className="mt-2 text-sm text-slate-500 line-clamp-2">{inq.note}</p>}
                                        </div>
                                    ))}
                                    {recentInquiries.length === 0 && <div className="p-8 text-center text-sm text-slate-400">Chưa có yêu cầu.</div>}
                                </div>
                            </section>
                        </div>
                    </div>
                )}

                {activeTab === 'landlords' && (
                    <section className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                        <div className="px-5 py-4 border-b border-slate-100 flex justify-between items-center">
                            <div>
                                <h2 className="font-black text-slate-800">Quản lý Tài khoản & Chủ trọ</h2>
                                <p className="text-xs text-slate-500 mt-1">Admin có thể khóa/mở khóa tài khoản hoặc hỗ trợ chỉnh sửa thông tin khi chủ trọ gặp sự cố đăng nhập.</p>
                            </div>
                            <span className="text-xs font-bold text-slate-500">{ownerStats.length} chủ trọ</span>
                        </div>
                        <div className="overflow-x-auto">
                            <table className="w-full text-sm">
                                <thead className="bg-slate-50 text-left text-xs uppercase text-slate-500">
                                    <tr>
                                        <th className="px-5 py-3">Chủ trọ / nhà trọ</th>
                                        <th className="px-5 py-3">UID</th>
                                        <th className="px-5 py-3 text-center">Trạng thái acc</th>
                                        <th className="px-5 py-3 text-right">Phòng</th>
                                        <th className="px-5 py-3 text-right">Công nợ</th>
                                        <th className="px-5 py-3 text-right">Thao tác Admin</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-slate-100">
                                    {ownerStats.map(item => (
                                        <tr key={item.uid} className="hover:bg-slate-50">
                                            <td className="px-5 py-4">
                                                <div className="font-bold text-slate-900">{item.hostelName}</div>
                                                <div className="text-xs text-slate-500">{item.landlordName} {item.phone && `· ${item.phone}`}</div>
                                            </td>
                                            <td className="px-5 py-4 font-mono text-xs text-slate-500 max-w-[120px] truncate">{item.uid}</td>
                                            <td className="px-5 py-4 text-center">
                                                {item.isBlocked ? (
                                                    <span className="rounded-full bg-rose-50 border border-rose-200 text-rose-700 px-2.5 py-1 text-xs font-bold">Đã Khóa</span>
                                                ) : (
                                                    <span className="rounded-full bg-emerald-50 border border-emerald-200 text-emerald-700 px-2.5 py-1 text-xs font-bold">Hoạt động</span>
                                                )}
                                            </td>
                                            <td className="px-5 py-4 text-right font-bold">{item.rooms}</td>
                                            <td className="px-5 py-4 text-right font-bold text-rose-600">{money.format(item.debt)}đ</td>
                                            <td className="px-5 py-4 text-right">
                                                <div className="flex justify-end gap-2">
                                                    <button onClick={() => editLandlordInfo(item)} className="rounded-xl border border-slate-200 bg-white px-3 py-1.5 text-xs font-bold text-slate-700 hover:bg-slate-100">
                                                        Hỗ trợ sửa
                                                    </button>
                                                    <button onClick={() => toggleLandlordAccount(item)} className={`rounded-xl px-3 py-1.5 text-xs font-bold ${item.isBlocked ? 'bg-emerald-600 text-white hover:bg-emerald-700' : 'bg-rose-600 text-white hover:bg-rose-700'}`}>
                                                        {item.isBlocked ? 'Mở khóa' : 'Khóa acc'}
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </section>
                )}

                {activeTab === 'rooms' && (
                    <section className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                        <div className="px-5 py-4 border-b border-slate-100 flex justify-between items-center">
                            <div>
                                <h2 className="font-black text-slate-800">Kiểm duyệt & Xóa phòng</h2>
                                <p className="text-xs text-slate-500 mt-1">Admin có thể ẩn phòng khỏi trang public hoặc xóa hẳn phòng rác/vi phạm.</p>
                            </div>
                            <span className="text-xs font-bold text-slate-500">{visibleRooms.length} phòng</span>
                        </div>
                        <div className="overflow-x-auto">
                            <table className="w-full text-sm">
                                <thead className="bg-slate-50 text-left text-xs uppercase text-slate-500">
                                    <tr>
                                        <th className="px-5 py-3">Phòng</th>
                                        <th className="px-5 py-3">Chủ trọ</th>
                                        <th className="px-5 py-3">Trạng thái</th>
                                        <th className="px-5 py-3 text-right">Giá</th>
                                        <th className="px-5 py-3 text-right">Thao tác Admin</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-slate-100">
                                    {visibleRooms.map(room => {
                                        const landlord = landlords[room.ownerUid] || {};
                                        const publicVisible = isVacant(room) && room.adminHidden !== true;
                                        return (
                                            <tr key={room.path} className="hover:bg-slate-50">
                                                <td className="px-5 py-4">
                                                    <div className="font-bold text-slate-900">{room.roomName || room.name || room.id}</div>
                                                    <div className="text-xs text-slate-500">{room.note || room.path}</div>
                                                </td>
                                                <td className="px-5 py-4">
                                                    <div className="font-semibold text-slate-700">{landlord.hostelName || landlord.landlordName || 'Chưa cấu hình'}</div>
                                                    <div className="text-xs text-slate-400 font-mono max-w-[120px] truncate">{room.ownerUid}</div>
                                                </td>
                                                <td className="px-5 py-4">
                                                    <span className={`rounded-full px-2.5 py-1 text-xs font-bold ${isVacant(room) ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-600'}`}>{room.status || 'TRONG'}</span>
                                                </td>
                                                <td className="px-5 py-4 text-right font-mono font-bold">{money.format(room.price || 0)}đ</td>
                                                <td className="px-5 py-4 text-right">
                                                    <div className="flex justify-end gap-2">
                                                        <button onClick={() => toggleRoomVisibility(room)} className={`rounded-xl px-3 py-1.5 text-xs font-bold ${publicVisible ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' : 'bg-amber-50 text-amber-700 border border-amber-200'}`}>
                                                            {room.adminHidden === true ? 'Đang ẩn' : 'Đang hiện'}
                                                        </button>
                                                        <button onClick={() => deleteRoomByAdmin(room)} className="rounded-xl bg-rose-600 hover:bg-rose-700 text-white px-3 py-1.5 text-xs font-bold">
                                                            Xóa phòng
                                                        </button>
                                                    </div>
                                                </td>
                                            </tr>
                                        );
                                    })}
                                </tbody>
                            </table>
                        </div>
                    </section>
                )}

                {activeTab === 'reports' && (
                    <section className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
                        {reportInquiries.map(rep => {
                            const landlord = landlords[rep.ownerUid] || {};
                            const targetRoom = rooms.find(r => r.ownerUid === rep.ownerUid && (r.id === rep.roomDocId || r.id === rep.roomId || r.roomName === rep.roomName));
                            return (
                                <div key={rep.path} className="bg-white rounded-2xl border border-rose-200 p-5 shadow-sm">
                                    <div className="flex justify-between gap-3">
                                        <div>
                                            <div className="font-black text-rose-700">🚩 Báo cáo phòng vi phạm</div>
                                            <div className="text-xs text-slate-400 mt-0.5">{rep.createdAt?.toDate?.()?.toLocaleString?.('vi-VN') || 'Mới gửi'}</div>
                                        </div>
                                        <span className="h-fit rounded-full bg-rose-50 border border-rose-200 px-2.5 py-1 text-[11px] font-bold text-rose-600">
                                            {rep.adminStatus || 'REPORTED'}
                                        </span>
                                    </div>
                                    <div className="mt-4 rounded-xl bg-slate-50 border border-slate-100 p-3 text-sm">
                                        <div className="font-bold text-slate-800">{rep.roomName || 'Phòng bị báo cáo'}</div>
                                        <div className="text-xs text-slate-500">Chủ trọ: {landlord.hostelName || landlord.landlordName || rep.ownerUid}</div>
                                    </div>
                                    <p className="mt-3 text-sm text-slate-700 font-medium">Lý do: &ldquo;{rep.note}&rdquo;</p>
                                    <div className="mt-4 flex gap-2">
                                        {targetRoom && (
                                            <button
                                                onClick={() => toggleRoomVisibility(targetRoom)}
                                                className="flex-1 rounded-xl bg-amber-50 hover:bg-amber-100 px-3 py-2 text-xs font-bold text-amber-800 border border-amber-200"
                                            >
                                                {targetRoom.adminHidden ? 'Hiện lại phòng' : 'Ẩn phòng ngay'}
                                            </button>
                                        )}
                                        <button
                                            onClick={() => markInquiryStatus(rep, 'RESOLVED')}
                                            className="flex-1 rounded-xl bg-emerald-50 hover:bg-emerald-100 px-3 py-2 text-xs font-bold text-emerald-700 border border-emerald-200"
                                        >
                                            Đã xử lý
                                        </button>
                                    </div>
                                </div>
                            );
                        })}
                        {reportInquiries.length === 0 && (
                            <div className="col-span-full rounded-2xl border border-slate-200 bg-white p-10 text-center text-slate-400">
                                Chưa có báo cáo vi phạm nào từ người dùng.
                            </div>
                        )}
                    </section>
                )}

                {activeTab === 'inquiries' && (
                    <section className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
                        {recentInquiries.map(inq => {
                            const landlord = landlords[inq.ownerUid] || {};
                            return (
                                <div key={inq.path} className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm">
                                    <div className="flex justify-between gap-3">
                                        <div>
                                            <div className="font-black text-slate-900">{inq.name || 'Khách'}</div>
                                            <a href={`tel:${inq.phone}`} className="text-sm font-bold text-indigo-600">{inq.phone}</a>
                                        </div>
                                        <span className="h-fit rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-bold text-slate-500">{inq.adminStatus || inq.status || 'NEW'}</span>
                                    </div>
                                    <div className="mt-4 rounded-xl bg-slate-50 border border-slate-100 p-3 text-sm">
                                        <div className="font-bold text-slate-800">{inq.roomName || 'Phòng quan tâm'}</div>
                                        <div className="text-xs text-slate-500">{landlord.hostelName || landlord.landlordName || inq.ownerUid}</div>
                                    </div>
                                    {inq.note && <p className="mt-3 text-sm text-slate-500">{inq.note}</p>}
                                    <div className="mt-4 flex gap-2">
                                        <button onClick={() => markInquiryStatus(inq, 'REVIEWED')} className="flex-1 rounded-xl bg-indigo-50 px-3 py-2 text-xs font-bold text-indigo-700 border border-indigo-100">Đã xem</button>
                                        <button onClick={() => markInquiryStatus(inq, 'ARCHIVED')} className="flex-1 rounded-xl bg-slate-50 px-3 py-2 text-xs font-bold text-slate-600 border border-slate-200">Lưu trữ</button>
                                    </div>
                                </div>
                            );
                        })}
                        {recentInquiries.length === 0 && <div className="col-span-full rounded-2xl border border-slate-200 bg-white p-10 text-center text-slate-400">Chưa có yêu cầu liên hệ.</div>}
                    </section>
                )}

                {activeTab === 'billing' && (
                    <section className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                        <div className="px-5 py-4 border-b border-slate-100 flex justify-between items-center">
                            <h2 className="font-black text-slate-800">Hóa đơn còn nợ toàn hệ thống</h2>
                            <span className="text-xs font-bold text-rose-600">{debtBills.length} hóa đơn hiển thị</span>
                        </div>
                        <div className="overflow-x-auto">
                            <table className="w-full text-sm">
                                <thead className="bg-slate-50 text-left text-xs uppercase text-slate-500">
                                    <tr>
                                        <th className="px-5 py-3">Tháng</th>
                                        <th className="px-5 py-3">Chủ trọ</th>
                                        <th className="px-5 py-3">Hợp đồng</th>
                                        <th className="px-5 py-3 text-right">Tổng hóa đơn</th>
                                        <th className="px-5 py-3 text-right">Đã trả</th>
                                        <th className="px-5 py-3 text-right">Còn nợ</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-slate-100">
                                    {debtBills.map(bill => {
                                        const landlord = landlords[bill.ownerUid] || {};
                                        return (
                                            <tr key={bill.path} className="hover:bg-slate-50">
                                                <td className="px-5 py-4 font-bold">{bill.month || ''}</td>
                                                <td className="px-5 py-4">{landlord.hostelName || landlord.landlordName || bill.ownerUid}</td>
                                                <td className="px-5 py-4 font-mono text-xs text-slate-500">{bill.contractId || bill.id}</td>
                                                <td className="px-5 py-4 text-right font-mono">{money.format(bill.totalAmount || 0)}đ</td>
                                                <td className="px-5 py-4 text-right font-mono text-emerald-600">{money.format(bill.paidAmount || 0)}đ</td>
                                                <td className="px-5 py-4 text-right font-mono font-black text-rose-600">{money.format(bill.debtAmount || 0)}đ</td>
                                            </tr>
                                        );
                                    })}
                                    {debtBills.length === 0 && <tr><td colSpan="6" className="px-5 py-10 text-center text-slate-400">Không có hóa đơn nợ.</td></tr>}
                                </tbody>
                            </table>
                        </div>
                    </section>
                )}
            </main>
        </div>
    );
}
