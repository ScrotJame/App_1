import 'package:cloud_firestore/cloud_firestore.dart';

class CloudService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Upload backup — dùng backupKey của user làm document ID
  Future<bool> uploadBackup(String backupKey, String jsonData) async {
    try {
      await _db.collection('backups').doc(backupKey).set({
        'data': jsonData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      //print('Upload backup thành công cho key: $backupKey');
      return true;
    } catch (e, stackTrace) {
      //print('Lỗi uploadBackup - $e\n$stackTrace');
      rethrow;
    }
  }

  /// Download backup theo backupKey
  Future<String?> downloadBackup(String backupKey) async {
    try {
      final doc = await _db.collection('backups').doc(backupKey).get();
      if (!doc.exists) {
        //print(' Không tìm thấy document cho key: $backupKey');
        return null;
      }
      return (doc.data() as Map<String, dynamic>)['data'] as String?;
    } catch (e, stackTrace) {
      //print(' Lỗi downloadBackup - $e\n$stackTrace');
      rethrow;
    }
  }
}