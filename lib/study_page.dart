import 'package:flutter/material.dart';
import 'service/alarm_service.dart';

class StudyDemoPage extends StatefulWidget {
  @override
  _StudyDemoPageState createState() => _StudyDemoPageState();
}

class _StudyDemoPageState extends State<StudyDemoPage> {
  final String currentWord = "Cấu trúc dữ liệu (Data Structure)";

  void _handleSchedule(int seconds, String label) {
    AlarmService.schedule(currentWord, seconds);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Đã lên lịch: $label"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Học tập Offline")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Text(
                  currentWord,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 40),

            // Nút Test nhanh
            ElevatedButton.icon(
              icon: Icon(Icons.timer),
              label: Text("Test nhanh (10 giây) - Sau đó hãy Kill App"),
              onPressed: () => _handleSchedule(5, "10 giây tới"),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
            ),

            SizedBox(height: 15),

            // Nút Chưa thuộc
            ElevatedButton(
              child: Text("CHƯA THUỘC (Nhắc lại sau 15p)"),
              onPressed: () => _handleSchedule( 10, "15 phút tới"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50)
              ),
            ),

            SizedBox(height: 15),

            // Nút Đã thuộc
            ElevatedButton(
              child: Text("ĐÃ THUỘC (Nhắc lại sau 2 giờ)"),
              onPressed: () => _handleSchedule(2 * 60 * 60, "2 giờ tới"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50)
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Text(
                "Lưu ý: Sau khi bấm nút 10 giây, bạn hãy vuốt tắt app hoàn toàn để kiểm tra tính năng Kill-app notification.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
    );
  }
}