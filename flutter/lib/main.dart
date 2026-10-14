import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/vehicle_model.dart';
import '../models/damage_report_model.dart';
import '../models/service_record_model.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? get _uid => _auth.currentUser?.uid;

  static CollectionReference? get _fleet =>
      _uid == null ? null : _db.collection('users').doc(_uid!).collection('fleet');

  static DocumentReference? _vehicleDoc(String vid) =>
      _uid == null ? null : _db.collection('users').doc(_uid!).collection('fleet').doc(vid);

  static CollectionReference? _damageReports(String vid) =>
      _vehicleDoc(vid) == null ? null : _vehicleDoc(vid)!.collection('damageReports');

  static CollectionReference? _serviceRecords(String vid) =>
      _vehicleDoc(vid) == null ? null : _vehicleDoc(vid)!.collection('serviceRecords');

  // ── VEHICLES ────────────────────────────────────────────────────────────────

  Stream<List<Vehicle>> streamVehicles() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(_uid!)
        .collection('fleet')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Vehicle.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<String> addVehicle(Vehicle vehicle) async {
    if (_uid == null) throw StateError('No authenticated user');
    final ref = await _db
        .collection('users')
        .doc(_uid!)
        .collection('fleet')
        .add(vehicle.toMap()..['created_at'] = DateTime.now().toIso8601String());
    return ref.id;
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    final doc = _vehicleDoc(vehicle.id);
    if (doc == null) throw StateError('No authenticated user');
    await doc.update(vehicle.toMap());
  }

  Future<void> deleteVehicle(String vehicleId) async {
    final doc = _vehicleDoc(vehicleId);
    if (doc == null) throw StateError('No authenticated user');

    final batch = _db.batch();
    final reports = await (doc.collection('damageReports')).get();
    final services = await (doc.collection('serviceRecords')).get();
    for (final d in [...reports.docs, ...services.docs]) {
      batch.delete(d.reference);
    }
    batch.delete(doc);
    await batch.commit();
  }

  // ── DAMAGE REPORTS ─────────────────────────────────────────────────────────────

  Stream<List<DamageReport>> streamDamageReports(String vehicleId) {
    final damageReports = _damageReports(vehicleId);
    if (damageReports == null) return Stream.value([]);

    return damageReports
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => DamageReport.fromMap(d.data() as Map<String, dynamic>))
            .toList());
  }

  // ── SERVICE RECORDS ───────────────────────────────────────────────────────────

  Stream<List<ServiceRecord>> streamServiceRecords(String vehicleId) {
    final serviceRecords = _serviceRecords(vehicleId);
    if (serviceRecords == null) return Stream.value([]);

    return serviceRecords
        .orderBy('service_date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ServiceRecord.fromMap(d.data() as Map<String, dynamic>))
            .toList());
  }
}


"}]}  
{