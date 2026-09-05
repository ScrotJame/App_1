import 'package:flutter/material.dart';

PreferredSizeWidget SimpleAppBar(String title) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    leading: null,
    automaticallyImplyLeading: false,
    title: Text(title,
        style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18)),
    centerTitle: true,
  );
}