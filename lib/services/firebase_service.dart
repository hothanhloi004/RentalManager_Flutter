import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/room_model.dart';
import '../models/tenant_model.dart';
import '../models/contract_model.dart';
import '../models/bill_model.dart';
import '../models/setting_model.dart';
import '../models/asset_model.dart';
import '../models/payment_model.dart';

class MeterReading {
  final int electric;
  final int water;

  const MeterReading({this.electric = 0, this.water = 0});
}

class FirebaseService {
  final _auth = FirebaseAuth.instance;
  final _fs = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: '854957572297-j14ht4gfnplc0pefgrb1ksp7vuis92iu.apps.googleusercontent.com',
  );

  String get uid => _auth.currentUser!.uid;
  String get base => 'users/$uid/';

  // -- AUTH ----------------------------------------------------------
  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim().toLowerCase(), password: password);

  Future<void> register(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email.trim().toLowerCase(), password: password);

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      await _auth.signInWithPopup(googleProvider);
    } else {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Ng\u01b0\u1eddi d\u00f9ng \u0111\u00e3 h\u1ee7y \u0111\u0103ng nh\u1eadp');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) await _googleSignIn.signOut();
  }

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // -- ROOMS ---------------------------------------------------------
  Stream<List<Room>> getRooms() =>
      _fs.collection('${base}rooms').snapshots().map((s) =>
          s.docs.map((d) => Room.fromFirestore(d.data(), d.id)).toList());

  Future<void> addRoom(Room room) => _fs.collection('${base}rooms').add(room.toMap());
  Future<void> updateRoom(Room room) => _fs.collection('${base}rooms').doc(room.id).set(room.toMap());

  Future<void> updateRoomImageUrl(String roomId, String imageUrl) async {
    final roomRef = await _roomRefByKey(roomId);
    await roomRef.set({'imageUrl': imageUrl}, SetOptions(merge: true));
  }
  Future<void> deleteRoom(String id) async {
    final roomRef = await _roomRefByKey(id);
    final roomDoc = await roomRef.get();
    if (roomDoc.exists && Room.fromFirestore(roomDoc.data()!, roomDoc.id).isRented) {
      throw Exception('Không thể xóa phòng đang thuê');
    }
    if (await roomHasActiveContract(id)) {
      throw Exception('Không thể xóa phòng đang có hợp đồng hiệu lực');
    }
    await roomRef.delete();
  }

  Future<bool> roomHasActiveContract(String roomId) async {
    final roomRef = await _roomRefByKey(roomId);
    final roomDoc = await roomRef.get();
    final roomKeys = <String>{roomId};
    if (roomDoc.exists && roomDoc.data() != null) {
      final room = Room.fromFirestore(roomDoc.data()!, roomDoc.id);
      roomKeys.add(room.id);
      roomKeys.add(room.roomKey);
    }
    final snap = await _fs.collection('${base}contracts').get();
    return snap.docs.any((doc) {
      final contract = Contract.fromFirestore(doc.data(), doc.id);
      return roomKeys.contains(contract.roomId) && contract.isActive;
    });
  }

  // -- TENANTS -------------------------------------------------------
  Stream<List<Tenant>> getTenants() =>
      _fs.collection('${base}tenants').snapshots().map((s) =>
          s.docs.map((d) => Tenant.fromFirestore(d.data(), d.id)).toList());

  Future<void> addTenant(Tenant t) => _fs.collection('${base}tenants').add(t.toMap());
  Future<void> updateTenant(Tenant t) => _fs.collection('${base}tenants').doc(t.id).set(t.toMap());
  Future<void> updateTenantImageUrls(String tenantId, List<String> imageUrls) async {
    final tenantRef = await _tenantRefByKey(tenantId);
    await tenantRef.set({'imageUrls': imageUrls}, SetOptions(merge: true));
  }

  Future<void> deleteTenant(String id) async {
    if (await tenantHasActiveContract(id)) {
      throw Exception('Kh\u00f4ng th\u1ec3 x\u00f3a kh\u00e1ch \u0111ang c\u00f3 h\u1ee3p \u0111\u1ed3ng hi\u1ec7u l\u1ef1c');
    }
    final tenantRef = await _tenantRefByKey(id);
    await tenantRef.delete();
  }

  Future<bool> tenantHasActiveContract(String tenantId) async {
    final tenantRef = await _tenantRefByKey(tenantId);
    final tenantDoc = await tenantRef.get();
    final tenantKeys = <String>{tenantId};
    if (tenantDoc.exists && tenantDoc.data() != null) {
      final tenant = Tenant.fromFirestore(tenantDoc.data()!, tenantDoc.id);
      tenantKeys.add(tenant.id);
      tenantKeys.add(tenant.tenantKey);
    }
    final snap = await _fs.collection('${base}contracts').get();
    return snap.docs.any((doc) {
      final data = doc.data();
      final contract = Contract.fromFirestore(data, doc.id);
      return tenantKeys.contains(contract.tenantId) && contract.isActive;
    });
  }

  // -- CONTRACTS -----------------------------------------------------
  Stream<List<Contract>> getContracts() =>
      _fs.collection('${base}contracts').snapshots().map((s) =>
          s.docs.map((d) => Contract.fromFirestore(d.data(), d.id)).toList());

  Future<void> addContract(Contract c) async {
    final batch = _fs.batch();
    final contractRef = _fs.collection('${base}contracts').doc();
    batch.set(contractRef, {...c.toMap(), 'contractId': contractRef.id});
    final roomRef = await _roomRefByKey(c.roomId);
    final tenantRef = await _tenantRefByKey(c.tenantId);
    batch.update(roomRef, {'status': 'DANG_THUE'});
    batch.update(tenantRef, {
      'roomId': c.roomId,
      'deposit': c.deposit,
      'moveInDate': c.startDate,
    });
    await batch.commit();
  }

  Future<void> endContract(String contractId, {String nextRoomStatus = 'TRONG'}) async {
    final contractRef = await _contractRefByKey(contractId);
    final doc = await contractRef.get();
    final roomId = doc.data()?['roomId']?.toString();
    final tenantId = doc.data()?['tenantId']?.toString();
    final batch = _fs.batch();
    batch.update(contractRef, {
      'status': 'KET_THUC',
      'endDate': DateTime.now().millisecondsSinceEpoch,
    });
    if (roomId != null) {
      final roomRef = await _roomRefByKey(roomId);
      batch.update(roomRef, {'status': nextRoomStatus});
    }
    if (tenantId != null) {
      final tenantRef = await _tenantRefByKey(tenantId);
      batch.update(tenantRef, {'roomId': ''});
    }
    await batch.commit();
  }

  Future<void> updateContractServices(String contractId, bool useWifi, bool useTrash, bool useServiceFee) async {
    final contractRef = await _contractRefByKey(contractId);
    await contractRef.update({
      'useWifi': useWifi,
      'useTrash': useTrash,
      'useServiceFee': useServiceFee,
    });
  }

  Future<MeterReading> getLastMeterForRoom(String roomId) async {
    final roomRef = await _roomRefByKey(roomId);
    final roomDoc = await roomRef.get();
    final roomKeys = <String>{roomId};
    if (roomDoc.exists && roomDoc.data() != null) {
      final room = Room.fromFirestore(roomDoc.data()!, roomDoc.id);
      roomKeys.add(room.id);
      roomKeys.add(room.roomKey);
    }

    final contractsSnap = await _fs.collection('${base}contracts').get();
    final contractKeys = <String>{};
    for (final doc in contractsSnap.docs) {
      final contract = Contract.fromFirestore(doc.data(), doc.id);
      if (roomKeys.contains(contract.roomId)) {
        contractKeys.add(contract.id);
        contractKeys.add(contract.contractKey);
      }
    }
    if (contractKeys.isEmpty) return const MeterReading();

    final billsSnap = await _fs.collection('${base}bills').get();
    Bill? latest;
    for (final doc in billsSnap.docs) {
      final bill = Bill.fromFirestore(doc.data(), doc.id);
      if (!contractKeys.contains(bill.contractId) || !bill.meterUpdated) continue;
      if (latest == null || _billSortValue(bill) > _billSortValue(latest)) {
        latest = bill;
      }
    }
    if (latest == null) return const MeterReading();
    return MeterReading(electric: latest.newElectric, water: latest.newWater);
  }

  // -- BILLS ---------------------------------------------------------
  Stream<List<Bill>> getBills() =>
      _fs.collection('${base}bills').snapshots().map((s) =>
          s.docs.map((d) => Bill.fromFirestore(d.data(), d.id)).toList());

  Stream<List<Bill>> getBillsByMonth(String monthStr) {
    // Ho tro ca 2 dinh dang: yyyy-MM (Android) va MM/yyyy (Flutter)
    final months = _monthVariants(monthStr);
    
    return _fs.collection('${base}bills')
        .where('month', whereIn: months)
        .snapshots()
        .map((s) => s.docs.map((d) => Bill.fromFirestore(d.data(), d.id)).toList());
  }

  Future<void> addBill(Bill b) async {
    final months = _monthVariants(b.month);
    final contractRef = await _contractRefByKey(b.contractId);
    final contractDoc = await contractRef.get();
    final contractKeys = <String>{b.contractId};
    if (contractDoc.exists && contractDoc.data() != null) {
      final contract = Contract.fromFirestore(contractDoc.data()!, contractDoc.id);
      contractKeys.add(contract.id);
      contractKeys.add(contract.contractKey);
    }
    final existing = await _fs
        .collection('${base}bills')
        .where('month', whereIn: months)
        .get();
    final hasExisting = existing.docs.any((d) => contractKeys.contains((d.data()['contractId'] ?? '').toString()));
    if (hasExisting) {
      throw Exception('Hóa đơn tháng này đã tồn tại');
    }
    final doc = _fs.collection('${base}bills').doc();
    await doc.set({...b.toMap(), 'billId': doc.id});
    // Cap nhat chi so dien nuoc cuoi cung vao hop dong
    await contractRef.update({
      'lastElectric': b.newElectric,
      'lastWater': b.newWater,
    });
  }

  Future<void> updateBillStatus(String billId, String status) =>
      _fs.collection('${base}bills').doc(billId).update({
        'paymentStatus': status,
        'paidAt': status == 'DA_THANH_TOAN' ? DateTime.now().millisecondsSinceEpoch : null,
      });

  Stream<List<Payment>> getPayments() =>
      _fs.collection('${base}payments').snapshots().map((s) =>
          s.docs.map((d) => Payment.fromFirestore(d.data(), d.id)).toList());

  Future<void> addPayment(Bill bill, double amount, double alreadyPaid) async {
    final remaining = bill.totalAmount - alreadyPaid;
    if (amount <= 0) throw Exception('Số tiền thu phải lớn hơn 0');
    if (amount > remaining) throw Exception('Số tiền vượt quá số còn nợ');

    final paymentTime = DateTime.now().millisecondsSinceEpoch;
    final newTotalPaid = alreadyPaid + amount;
    final status = newTotalPaid >= bill.totalAmount ? 'DA_THANH_TOAN' : 'DONG_THIEU';

    final batch = _fs.batch();
    batch.set(_fs.collection('${base}payments').doc(), Payment(
      id: '',
      billId: bill.paymentKey,
      amount: amount,
      paymentDate: paymentTime,
    ).toMap());
    batch.update(_fs.collection('${base}bills').doc(bill.id), {
      'paymentStatus': status,
      'paidAt': status == 'DA_THANH_TOAN' ? paymentTime : null,
    });
    await batch.commit();
  }

  Future<void> updateBillMeter(Bill bill, int newElectric, int newWater) async {
    final electricUsed = newElectric - bill.oldElectric;
    final waterUsed = newWater - bill.oldWater;
    final total = bill.rentPrice +
        bill.serviceFee +
        electricUsed * bill.electricPrice +
        waterUsed * bill.waterPrice;
    final batch = _fs.batch();
    batch.update(_fs.collection('${base}bills').doc(bill.id), {
      'newElectric': newElectric,
      'electricUsed': electricUsed,
      'newWater': newWater,
      'waterUsed': waterUsed,
      'totalAmount': total,
      'meterUpdated': true,
    });
    final contractRef = await _contractRefByKey(bill.contractId);
    batch.update(contractRef, {
      'lastElectric': newElectric,
      'lastWater': newWater,
    });
    await batch.commit();
  }

  Future<void> deleteBill(String id) => _fs.collection('${base}bills').doc(id).delete();

  Future<int> bulkCreateBills(String monthStr, Setting settings) async {
    // 1. Lay tat ca hop dong dang hieu luc
    final contractsSnap = await _fs.collection('${base}contracts').get();
    final contracts = contractsSnap.docs
        .map((d) => Contract.fromFirestore(d.data(), d.id))
        .where((c) => c.isActive)
        .toList();
    
    // 2. Lay cac hoa don da ton tai trong thang nay
    final months = _monthVariants(monthStr);
    final existingBillsSnap = await _fs
        .collection('${base}bills')
        .where('month', whereIn: months)
        .get();
    final existingContractIds = existingBillsSnap.docs.map((d) => (d.data()['contractId'] ?? '').toString()).toSet();
    
    int count = 0;
    final batch = _fs.batch();
    
    for (var c in contracts) {
      final contractKeys = {c.id, c.contractKey};
      if (existingContractIds.intersection(contractKeys).isEmpty) {
        final billRef = _fs.collection('${base}bills').doc();
        final serviceFee = (c.useWifi ? settings.wifiPrice : 0) +
                          (c.useTrash ? settings.trashFee : 0) +
                          (c.useServiceFee ? settings.serviceFee : 0);
        
        final b = Bill(
          id: '',
          contractId: c.contractKey,
          month: monthStr,
          oldElectric: c.lastElectric,
          newElectric: c.lastElectric,
          electricUsed: 0,
          oldWater: c.lastWater,
          newWater: c.lastWater,
          waterUsed: 0,
          electricPrice: settings.electricPrice,
          waterPrice: settings.waterPrice,
          rentPrice: c.rentPrice,
          serviceFee: serviceFee.toDouble(),
          totalAmount: c.rentPrice + serviceFee.toDouble(),
          paymentStatus: 'CHUA_THANH_TOAN',
          dueDate: DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch,
          meterUpdated: false,
        );
        batch.set(billRef, {...b.toMap(), 'billId': billRef.id});
        count++;
      }
    }
    
    if (count > 0) await batch.commit();
    return count;
  }

  List<String> _monthVariants(String month) {
    final parts = month.contains('/') ? month.split('/') : month.split('-');
    if (parts.length != 2) return [month];
    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    if (first == null || second == null) return [month];

    final year = month.contains('/') ? second : first;
    final monthNumber = month.contains('/') ? first : second;
    final paddedMonth = monthNumber.toString().padLeft(2, '0');
    return {
      month,
      '$year-$paddedMonth',
      '$year-$monthNumber',
      '$paddedMonth/$year',
      '$monthNumber/$year',
    }.toList();
  }

  int _billSortValue(Bill bill) {
    final normalized = _monthVariants(bill.month)
        .firstWhere((m) => m.contains('-') && m.split('-').first.length == 4, orElse: () => bill.month);
    final parts = normalized.split('-');
    if (parts.length == 2) {
      final year = int.tryParse(parts[0]) ?? 0;
      final month = int.tryParse(parts[1]) ?? 0;
      return year * 100 + month;
    }
    return bill.dueDate;
  }

  Future<DocumentReference<Map<String, dynamic>>> _contractRefByKey(String key) async {
    final direct = _fs.collection('${base}contracts').doc(key);
    final directDoc = await direct.get();
    if (directDoc.exists) return direct;

    final byString = await _fs
        .collection('${base}contracts')
        .where('contractId', isEqualTo: key)
        .limit(1)
        .get();
    if (byString.docs.isNotEmpty) return byString.docs.first.reference;

    final keyAsInt = int.tryParse(key);
    if (keyAsInt != null) {
      final byInt = await _fs
          .collection('${base}contracts')
          .where('contractId', isEqualTo: keyAsInt)
          .limit(1)
          .get();
      if (byInt.docs.isNotEmpty) return byInt.docs.first.reference;
    }

    return direct;
  }

  Future<DocumentReference<Map<String, dynamic>>> _roomRefByKey(String key) async {
    final direct = _fs.collection('${base}rooms').doc(key);
    final directDoc = await direct.get();
    if (directDoc.exists) return direct;

    final byString = await _fs.collection('${base}rooms').where('roomId', isEqualTo: key).limit(1).get();
    if (byString.docs.isNotEmpty) return byString.docs.first.reference;

    final keyAsInt = int.tryParse(key);
    if (keyAsInt != null) {
      final byInt = await _fs.collection('${base}rooms').where('roomId', isEqualTo: keyAsInt).limit(1).get();
      if (byInt.docs.isNotEmpty) return byInt.docs.first.reference;
    }

    return direct;
  }

  Future<List<Object>> _roomKeyVariants(String key) async {
    final values = <Object>{};

    void addVariant(String value) {
      if (value.isEmpty) return;
      values.add(value);
      final asInt = int.tryParse(value);
      if (asInt != null) values.add(asInt);
    }

    addVariant(key);
    final roomRef = await _roomRefByKey(key);
    final roomDoc = await roomRef.get();
    if (roomDoc.exists && roomDoc.data() != null) {
      final room = Room.fromFirestore(roomDoc.data()!, roomDoc.id);
      addVariant(room.id);
      addVariant(room.roomKey);
    }
    return values.isEmpty ? <Object>[''] : values.toList();
  }

  Future<DocumentReference<Map<String, dynamic>>> _tenantRefByKey(String key) async {
    final direct = _fs.collection('${base}tenants').doc(key);
    final directDoc = await direct.get();
    if (directDoc.exists) return direct;

    final byString = await _fs.collection('${base}tenants').where('tenantId', isEqualTo: key).limit(1).get();
    if (byString.docs.isNotEmpty) return byString.docs.first.reference;

    final keyAsInt = int.tryParse(key);
    if (keyAsInt != null) {
      final byInt = await _fs.collection('${base}tenants').where('tenantId', isEqualTo: keyAsInt).limit(1).get();
      if (byInt.docs.isNotEmpty) return byInt.docs.first.reference;
    }

    return direct;
  }

  // -- SETTINGS ------------------------------------------------------
  Future<Setting> getSettings() async {
    try {
      final doc = await _fs.doc('${base}settings/config').get();
      if (doc.exists && doc.data() != null) {
        return Setting.fromFirestore(doc.data()!);
      }
    } catch (e) {
      debugPrint('getSettings error: $e');
    }
    return Setting();
  }

  Stream<Setting> getSettingsStream() => _fs.doc('${base}settings/config').snapshots().map((doc) {
        try {
          if (doc.exists && doc.data() != null) {
            return Setting.fromFirestore(doc.data()!);
          }
        } catch (e) {
          debugPrint('getSettingsStream error: $e');
        }
        return Setting();
      });

  Future<void> saveSettings(Setting s) =>
      _fs.doc('${base}settings/config').set(s.toMap(), SetOptions(merge: true));

  // -- ASSETS --------------------------------------------------------
  Stream<List<Asset>> getAssetsByRoom(String roomId) async* {
    final roomKeys = await _roomKeyVariants(roomId);
    yield* _fs.collection('${base}assets')
        .where('roomId', whereIn: roomKeys)
        .snapshots()
        .map((s) => s.docs.map((d) => Asset.fromFirestore(d.data(), d.id)).toList());
  }

  Future<void> addAsset(Asset a) => _fs.collection('${base}assets').add(a.toMap());
  Future<void> updateAsset(Asset a) => _fs.collection('${base}assets').doc(a.id).set(a.toMap());
  Future<void> deleteAsset(String id) => _fs.collection('${base}assets').doc(id).delete();
}
