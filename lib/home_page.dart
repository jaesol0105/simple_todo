import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_todo/noti.dart';
import 'package:flutter_todo/todo.dart';
import 'package:flutter_todo/todo_widget.dart';
import 'package:timezone/timezone.dart' as tz;

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final textController = TextEditingController();

  List<Todo> todoList = [];

  @override
  void initState() {
    super.initState();
    loadTodos();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  /// [TODO 불러오기]
  void loadTodos() async {
    final firestore = FirebaseFirestore.instance;
    final colRef = firestore.collection('todos');

    var query = colRef.orderBy('createdAt', descending: true);
    query = query.where(
      'uid',
      isEqualTo: FirebaseAuth.instance.currentUser?.uid,
    );
    final querySnapshot = await query.get();
    final documents = querySnapshot.docs;

    List<Todo> newTodoList = [];

    for (var i = 0; i < documents.length; i++) {
      final document = documents[i];
      final data = document.data();
      newTodoList.add(
        Todo(id: document.id, title: data['title'], isDone: data['isDone']),
      );
    }

    setState(() {
      todoList = newTodoList;
    });
  }

  /// [TODO 생성]
  void onCreate() async {
    if (textController.text.trim().isNotEmpty) {
      final firestore = FirebaseFirestore.instance;
      final colRef = firestore.collection('todos');
      final docRef = colRef.doc();
      await docRef.set({
        'title': textController.text,
        'isDone': false,
        'createdAt': DateTime.now().toIso8601String(),
        'dueAt': null, // 생성시 미설정 null
        'uid': FirebaseAuth.instance.currentUser?.uid,
      });
      loadTodos();
      textController.clear();
    }
  }

  /// [TODO 마감일 설정]
  Future<void> pickAndSetDeadline(Todo item) async {
    final now = DateTime.now();
    // DatePicker
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;

    // TimePicker
    final timeOfDay = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
    );
    if (timeOfDay == null) return;

    final due = DateTime(
      date.year,
      date.month,
      date.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    // Firestore에 마감일 저장
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('todos').doc(item.id).update({
      'dueAt': due.toIso8601String(),
    });

    // 로컬 알림 스케줄 설정
    await scheduleDeadlineNotification(
      todoDocId: item.id,
      title: item.title,
      due: due,
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('마감 알림 예약: ${fmt(due)}')));
    }

    loadTodos();
  }

  /// [날짜 포맷팅]
  String fmt(DateTime dt) {
    final local = tz.TZDateTime.from(dt, tz.local);
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(title: Text("TO DO", style: TextStyle(fontSize: 18))),
        body: ListView.separated(
          // bottomSheet 영역에 가리지 않게 아래는 넉넉히!
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 200),
          itemCount: todoList.length,
          // 함수에서 반환하는 코드(return)만 있다면 화살표 함수로!
          separatorBuilder: (context, index) => SizedBox(height: 10),
          itemBuilder: (context, index) {
            Todo item = todoList[index];
            return Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    /// [TODO 완료 업데이트]
                    onTap: () async {
                      final firestore = FirebaseFirestore.instance;
                      final colRef = firestore.collection('todos');
                      final docRef = colRef.doc(item.id);
                      await docRef.update({'isDone': !item.isDone});
                      loadTodos();
                    },

                    /// [TODO 삭제]
                    onLongPress: () async {
                      bool result = await showCupertinoDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text("삭제 하시겠습니까?"),
                          actions: [
                            CupertinoDialogAction(
                              onPressed: () {
                                Navigator.pop(context, false);
                              },
                              child: const Text(
                                "취소",
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                            CupertinoDialogAction(
                              onPressed: () {
                                Navigator.pop(context, true);
                              },
                              child: const Text(
                                "삭제",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (result) {
                        final firestore = FirebaseFirestore.instance;
                        final colRef = firestore.collection('todos');
                        final docRef = colRef.doc(item.id);
                        await docRef.delete();
                        loadTodos();
                      }
                    },
                    child: TodoWidget(content: item.title, isDone: item.isDone),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.event),
                  onPressed: () => pickAndSetDeadline(item),
                  tooltip: '마감일 설정',
                ),
              ],
            );
          },
        ),
        bottomSheet: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: textController,
                maxLines: 1,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onCreate(),
                decoration: InputDecoration(
                  hintText: "Add Item",
                  border: InputBorder.none,
                  fillColor: Colors.blue.withValues(alpha: 0.1),
                  filled: true,
                  suffixIcon: GestureDetector(
                    onTap: onCreate,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                  suffixIconConstraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: () async {
                  await localNoti.cancelAll();

                  // 2) 10초 뒤로 스케줄
                  final when = tz.TZDateTime.now(
                    tz.local,
                  ).add(const Duration(seconds: 10));
                  await localNoti.zonedSchedule(
                    7777,
                    '60초 뒤',
                    'inexact 테스트',
                    when,
                    const NotificationDetails(
                      android: AndroidNotificationDetails(
                        'todo_channel',
                        'ToDo 알림',
                        channelDescription: '테스트',
                        importance: Importance.max,
                        priority: Priority.high,
                        icon: '@mipmap/ic_launcher',
                      ),
                    ),
                    androidScheduleMode:
                        AndroidScheduleMode.inexactAllowWhileIdle, // ✅ 이걸로 대체
                    // matchDateTimeComponents: 생략 (일회성은 쓰지 않음)
                  );

                  // 3) 등록 확인
                  final pending = await localNoti.pendingNotificationRequests();
                  debugPrint(
                    'PENDING=${pending.length} -> ${pending.map((e) => e.id).toList()}',
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('10초 뒤 알림 예약됨')),
                    );
                  }
                },
                child: const Text('10초 뒤 알림 테스트'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
