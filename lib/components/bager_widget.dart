import 'package:flutter/cupertino.dart';

class BagerWidget extends StatelessWidget {
  final String? label;

  const BagerWidget({super.key,
    this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(),
      child: Text(label!),
    );
  }
}
