import 'package:flutter/material.dart';

const _privacyPolicyText =
    'Dungeonary không yêu cầu tài khoản và không gửi từ vựng của bạn lên máy '
    'chủ của chúng tôi. Từ vựng, tiến độ học và hồ sơ được lưu trên thiết bị '
    'của bạn.\n\n'
    'Camera và ảnh chỉ được dùng khi bạn quét từ vựng, và văn bản được nhận '
    'dạng ngay trên thiết bị bằng Google ML Kit.\n\n'
    'File sao lưu là JSON không mã hóa và được lưu ở nơi bạn chọn. Hãy cất file '
    'này cẩn thận, vì ai có file cũng đọc được nội dung.\n\n'
    'App có thể kết nối Internet để tải phông chữ từ Google Fonts. Dữ liệu '
    'trong app bị xóa khi bạn gỡ app, trừ khi hệ thống sao lưu của thiết bị '
    'đang bật.';

Future<void> showPrivacyPolicyDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Chính sách riêng tư'),
      content: const SingleChildScrollView(child: Text(_privacyPolicyText)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}
