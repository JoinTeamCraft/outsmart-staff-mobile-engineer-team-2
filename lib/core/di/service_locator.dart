import 'package:get_it/get_it.dart';

import '../network/api_client.dart';
import '../../features/lessons/data/lesson_repository.dart';
import '../../features/quiz/data/quiz_repository.dart';

/// Global service locator (get_it) instance.
final GetIt locator = GetIt.instance;

/// Registers app-wide dependencies. Called once from `main()` before `runApp`.
///
/// Repositories (OU-1) depend on the shared [ApiClient]; both are lazy
/// singletons so nothing is constructed until first used. Registering the
/// repositories here — rather than constructing them ad hoc — keeps the data
/// layer swappable (e.g. a failure-injecting [ApiClient] in tests, OU-23).
void setupLocator() {
  locator
    ..registerLazySingleton<ApiClient>(() => ApiClient())
    ..registerLazySingleton<LessonRepository>(
      () => LessonRepository(locator<ApiClient>()),
    )
    ..registerLazySingleton<QuizRepository>(
      () => QuizRepository(locator<ApiClient>()),
    );
}
