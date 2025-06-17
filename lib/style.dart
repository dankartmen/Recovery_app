// Общие цвета
import 'package:flutter/material.dart';

const primaryGradient = LinearGradient(
  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const cardColor = Color(0xFFF5F7FB);
const textColor = Color(0xFF333333);
const secondaryTextColor = Color(0xFF666666);

AppBar buildAppBar(String title, {List<Widget>? actions}) {
  return AppBar(
    title: Text(title, style: TextStyle(color: Colors.white)),
    flexibleSpace: Container(
      decoration: BoxDecoration(gradient: primaryGradient),
    ),
    actions: actions,
    iconTheme: IconThemeData(color: Colors.white),
  );
}

Card buildCard({required Widget child, EdgeInsets? padding}) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
  );
}

ElevatedButton primaryButton({
  required String text,
  required VoidCallback onPressed,
}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Color(0xFF6A11CB),
    ),
    child: Text(text, style: TextStyle(fontSize: 16)),
  );
}
