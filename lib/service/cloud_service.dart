import 'package:cloud_firestore/cloud_firestore.dart';

class CloudService {
  // Biến đại diện cho database trên Firebase
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Hàm đẩy JSON lên mây
  Future<bool> uploadBackup(String key, String jsonData) async {
    try {
      await _db.collection('backups').doc(key).set({
        'data': jsonData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Đã đẩy dữ liệu thành công với mã: $key');
      return true;
    } catch (e) {
      print('Lỗi đẩy dữ liệu: $e');
      return false;
    }
  }

  // Hàm nhập Key để kéo JSON về
  Future<String?> downloadBackup(String key) async {
    try {
      DocumentSnapshot doc = await _db.collection('backups').doc(key).get();

      if (doc.exists) {
        final mapData = doc.data() as Map<String, dynamic>;
        print('Đã tìm thấy dữ liệu cho mã: $key');
        return mapData['data'] as String;
      } else {
        print('Không tìm thấy dữ liệu nào với mã: $key');
        return null;
      }
    } catch (e) {
      print('Lỗi tải dữ liệu: $e');
      return null;
    }
  }
}