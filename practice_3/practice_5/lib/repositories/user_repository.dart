import '../models/system_user.dart';

abstract class UserRepository {
  Future<List<SystemUser>> getAll();
}