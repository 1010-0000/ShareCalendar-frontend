import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskService {
  final DatabaseReference database = FirebaseDatabase.instance.ref();

  // 현재 사용자 ID 가져오기
  String _getCurrentUserId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("로그인된 사용자가 없습니다.");
    }
    return currentUser.uid;
  }

  // 할 일 조회 (특정 날짜)
  Future<Map<String, dynamic>?> fetchTask(String date) async {
    String userId = _getCurrentUserId();

    try {
      final taskSnapshot = await database.child('tasks/$userId/$date').get();
      if (!taskSnapshot.exists || taskSnapshot.value == null) {
        return null;
      }

      return Map<String, dynamic>.from(taskSnapshot.value as Map);
    } catch (e) {
      print("할 일 조회 중 오류 발생: $e");
      throw Exception("할 일을 조회할 수 없습니다.");
    }
  }

  // 할 일 모두 조회
  Future<Map<String, Map<String, dynamic>>?> fetchAllTask() async {
    String userId = _getCurrentUserId();

    try {
      final taskSnapshot = await database.child('tasks/$userId').get();
      if (!taskSnapshot.exists || taskSnapshot.value == null) {
        return null;
      }

      // 데이터 변환
      final Map<String, dynamic> tasksByDate =
      Map<String, dynamic>.from(taskSnapshot.value as Map);

      // 날짜별 단일 할 일 데이터를 반환
      return tasksByDate.map((date, task) {
        return MapEntry(date, Map<String, dynamic>.from(task as Map));
      });

    } catch (e) {
      print("할 일 조회 중 오류 발생: $e");
      throw Exception("할 일을 조회할 수 없습니다.");
    }
  }

  // 할 일 추가 (set 사용) + 저장된 데이터 반환
  Future<Map<String, dynamic>> addTask(String date, String title, String description) async {
    String userId = _getCurrentUserId();

    try {
      await database.child('tasks/$userId/$date').set({
        'title': title,
        'description': description,
        'priority': '보통', // 기본값
        'status': '대기 중', // 기본값
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 저장된 데이터 반환
      final savedTask = await fetchTask(date);
      if (savedTask == null) throw Exception("데이터를 저장했으나 불러오지 못했습니다.");
      return savedTask;
    } catch (e) {
      print("할 일 추가 중 오류 발생: $e");
      throw Exception("할 일을 추가할 수 없습니다.");
    }
  }

  // 할 일 수정 (update 사용) + 저장된 데이터 반환
  Future<Map<String, dynamic>> updateTask(String date, Map<String, dynamic> updatedFields) async {
    String userId = _getCurrentUserId();

    try {
      await database.child('tasks/$userId/$date').update(updatedFields);

      // 수정된 데이터 반환
      final updatedTask = await fetchTask(date);
      if (updatedTask == null) throw Exception("데이터를 수정했으나 불러오지 못했습니다.");
      return updatedTask;
    } catch (e) {
      print("할 일 수정 중 오류 발생: $e");
      throw Exception("할 일을 수정할 수 없습니다.");
    }
  }


  // 할 일 삭제
  Future<void> deleteTask(String date) async {
    String userId = _getCurrentUserId();

    try {
      await database.child('tasks/$userId/$date').remove();
    } catch (e) {
      print("할 일 삭제 중 오류 발생: $e");
      throw Exception("할 일을 삭제할 수 없습니다.");
    }
  }
}
