import 'package:flutter/material.dart';
import 'dart:io';

import '../models/person.dart';

class PersonAvatar extends StatelessWidget {
  final Person person;
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final bool emojiAsIcon; // ใหม่: แสดง emoji เป็น icon ปกติ

  const PersonAvatar({
    super.key,
    required this.person,
    this.size = 40.0,
    this.showBorder = true,
    this.borderColor,
    this.emojiAsIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    // ถ้าไม่มีรูปโปรไฟล์ และต้องการแสดง emoji เป็น icon
    if (!person.hasProfilePicture && emojiAsIcon) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            person.avatar,
            style: TextStyle(fontSize: size * 0.8),
          ),
        ),
      );
    }

    // แสดงแบบวงกลม (สำหรับรูปโปรไฟล์หรือ emoji ที่ต้องการกรอบ)
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: borderColor ?? Colors.grey.shade300,
                width: 1,
              )
            : null,
      ),
      child: ClipOval(
        child: person.hasProfilePicture
            ? Image.file(
                File(person.imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade100,
                    child: Center(
                      child: Text(
                        person.avatar,
                        style: TextStyle(fontSize: size * 0.5),
                      ),
                    ),
                  );
                },
              )
            : Container(
                color: Colors.grey.shade100,
                child: Center(
                  child: Text(
                    person.avatar,
                    style: TextStyle(fontSize: size * 0.5),
                  ),
                ),
              ),
      ),
    );
  }
}