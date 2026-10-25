import 'package:cloud_firestore/cloud_firestore.dart';

/// Per-user document store for synced metadata. Every path is scoped to
/// `users/{uid}`; security rules (firestore.rules) enforce the same.
abstract interface class RemoteStore {
  Future<Map<String, Map<String, Object?>>> list(String uid, String collection);

  Future<void> putAll(
    String uid,
    String collection,
    Map<String, Map<String, Object?>> docs,
  );

  /// Deletes every synced record of the user (account deletion).
  Future<void> deleteUserData(String uid);
}

class FirestoreRemoteStore implements RemoteStore {
  FirestoreRemoteStore(this._db);

  final FirebaseFirestore _db;

  static const collections = ['playlists', 'favorites', 'settings'];

  CollectionReference<Map<String, dynamic>> _col(String uid, String c) =>
      _db.collection('users').doc(uid).collection(c);

  @override
  Future<Map<String, Map<String, Object?>>> list(
    String uid,
    String collection,
  ) async {
    final snap = await _col(uid, collection).get();
    return {for (final d in snap.docs) d.id: d.data()};
  }

  @override
  Future<void> putAll(
    String uid,
    String collection,
    Map<String, Map<String, Object?>> docs,
  ) async {
    final entries = docs.entries.toList();
    // Firestore batches hold at most 500 writes.
    for (var i = 0; i < entries.length; i += 400) {
      final batch = _db.batch();
      for (final e in entries.skip(i).take(400)) {
        batch.set(_col(uid, collection).doc(e.key), e.value);
      }
      await batch.commit();
    }
  }

  @override
  Future<void> deleteUserData(String uid) async {
    for (final c in collections) {
      final snap = await _col(uid, c).get();
      for (var i = 0; i < snap.docs.length; i += 400) {
        final batch = _db.batch();
        for (final d in snap.docs.skip(i).take(400)) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
    }
  }
}

class InMemoryRemoteStore implements RemoteStore {
  final Map<String, Map<String, Map<String, Map<String, Object?>>>> data = {};

  @override
  Future<Map<String, Map<String, Object?>>> list(
    String uid,
    String collection,
  ) async => {...?data[uid]?[collection]};

  @override
  Future<void> putAll(
    String uid,
    String collection,
    Map<String, Map<String, Object?>> docs,
  ) async {
    data
        .putIfAbsent(uid, () => {})
        .putIfAbsent(collection, () => {})
        .addAll(docs);
  }

  @override
  Future<void> deleteUserData(String uid) async => data.remove(uid);
}
