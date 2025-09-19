import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin localNoti =
    FlutterLocalNotificationsPlugin();

Future<void> initLocalNoti() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: androidInit);
  await localNoti.initialize(settings);

  // Android 13+ 알림 권한 요청
  final android = localNoti
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  final granted = await android?.requestNotificationsPermission() ?? false;
  debugPrint('POST_NOTIFICATIONS granted: $granted');

  // 채널 생성(안드로이드)
  const androidChannel = AndroidNotificationChannel(
    'todo_channel',
    'ToDo 알림',
    description: '마감 알림 채널',
    importance: Importance.max,
  );
  await android?.createNotificationChannel(androidChannel);

  // 앱/채널이 OS에서 차단됐는지 점검
  final enabled = await android?.areNotificationsEnabled();
  debugPrint('areNotificationsEnabled: $enabled');
}

/// [푸쉬 알림 보내기]
Future<void> scheduleDeadlineNotification({
  required String todoDocId,
  required String title,
  required DateTime due, // 사용자가 설정한 시간
}) async {
  // 1) 알림 ID는 항상 "양수"로 고정
  final int notifId = todoDocId.hashCode & 0x7fffffff;

  // 2) 타임존 변환 + 과거시각 보호(최소 5초 뒤로)
  var when = tz.TZDateTime.from(due, tz.local);
  final now = tz.TZDateTime.now(tz.local);
  if (!when.isAfter(now)) {
    when = now.add(const Duration(seconds: 5));
  }

  // 3) Android 12+ exact 권한 이슈 회피: inexact 모드 사용
  await localNoti.zonedSchedule(
    notifId,
    '마감 알림',
    '$title 마감 시간이 되었어요!',
    when,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'todo_channel',
        'ToDo 알림',
        channelDescription: '마감 알림 채널',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );
}
