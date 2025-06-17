// Общие цвета
import 'package:flutter/material.dart';

// Цветовая схема для медицинского приложения
const healthPrimaryColor = Color(0xFF2E7D32); // Глубокий зеленый
const healthSecondaryColor = Color(0xFF0288D1); // Профессиональный синий
const healthBackgroundColor = Color(0xFFF0F9FF); // Светло-голубой фон
const healthTextColor = Color(0xFF37474F); // Темно-серый для текста
const healthSecondaryTextColor = Color(
  0xFF607D8B,
); // Серый для второстепенного текста
const healthDividerColor = Color(0xFFB0BEC5); // Цвет разделителей

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

// Стиль текстовых полей для медицинской темы
InputDecoration buildHealthInputDecoration(String labelText, {IconData? icon}) {
  return InputDecoration(
    labelText: labelText,
    labelStyle: const TextStyle(color: healthSecondaryTextColor),
    prefixIcon:
        icon != null
            ? Icon(icon, color: healthSecondaryColor.withOpacity(0.7))
            : null,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: healthPrimaryColor, width: 1.5),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
  );
}
