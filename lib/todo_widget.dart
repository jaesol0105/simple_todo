import 'package:flutter/material.dart';

class TodoWidget extends StatelessWidget {
  TodoWidget({required this.content, required this.isDone});

  String content;
  bool isDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              shape: BoxShape.circle,
              color: isDone ? Colors.blue : null,
            ),
            child: isDone
                ? Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          SizedBox(width: 20),
          Expanded(child: Text(content)),
          SizedBox(width: 20),
        ],
      ),
    );
  }
}
