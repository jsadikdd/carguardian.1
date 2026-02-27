import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vehicle_model.dart';
import '../models/damage_report_model.dart';
import '../models/service_record_model.dart';

class FirestoreService {
  static final _db   = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _uid => _auth.currentUser!.uid;

  // Reference shortcuts
  static CollectionReference get _fleet =>
      _db.collection('users').doc(_uid).collection('fleet');

  static DocumentReference _vehicleDoc(String vid) => _fleet.doc(vid);

  static CollectionReference _damageReports(String vid) =>
      _vehicleDoc(vid).collection('damageReports');

  static CollectionReference _serviceRecords(String vid) =>
      _vehicleDoc(vid).collection('serviceRecords');

  // ── VEHICLES ─────────────────────────────────────────────────────────────

  Stream<List<Vehicle>> streamVehicles() => _fleet.snapshots().map(
    (snap) => snap.docs
        .map((d) => Vehicle.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList(),
  );

  Future<String> addVehicle(Vehicle vehicle) async {
    final ref = await _fleet.add(vehicle.toMap()
      ..['created_at'] = DateTime.now().toIso8601String());
    return ref.id;
  }

  Future<void> updateVehicle(Vehicle vehicle) =>
      _vehicleDoc(vehicle.id).update(vehicle.toMap());

  Future<void> deleteVehicle(String vehicleId) async {
    // Delete all sub-collections first
    final batch = _db.batch();
    final reports  = await _damageReports(vehicleId).get();
    final services = await _serviceRecords(vehicleId).get();
    for (final doc in [...reports.docs, ...services.docs]) {
      batch.delete(doc.reference);
    }
    batch.delete(_vehicleDoc(vehicleId));
    await batch.commit();
  }

  // ── DAMAGE REPORTS ────────────────────────────────────────────────────────

  Stream<List<DamageReport>> streamDamageReports(String vehicleId) =>
      _damageReports(vehicleId)
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => DamageReport.fromMap(d.data() as Map<String, dynamic>))
              .toList());

  // ── SERVICE RECORDS ───────────────────────────────────────────────────────

  Stream<List<ServiceRecord>> streamServiceRecords(String vehicleId) =>
      _serviceRecords(vehicleId)
          .orderBy('service_date', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => ServiceRecord.fromMap(d.data() as Map<String, dynamic>))
              .toList());
}
