import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/storage/database_service.dart'; // Додали імпорт

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Services
  sl.registerLazySingleton(() => DatabaseService()); // Реєструємо сервіс бази даних
  
  // Далі будуть репозиторії та кубіти...
}