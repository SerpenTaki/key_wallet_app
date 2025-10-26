import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String text;
  final void Function()? onTap;
  final Color? color;
  final String subtext;


  const UserTile({super.key, required this.text, required this.subtext, required this.color ,required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.person,
              color: color,
              size: 40,
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(subtext),
              ],
            ),
            const Spacer(),
            Icon(
              defaultTargetPlatform == TargetPlatform.android
                  ? Icons.arrow_forward
                  : Icons.arrow_forward_ios,
            ),
          ],
        ),
      ),
    );
  }
}
