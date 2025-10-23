import 'package:get_it/get_it.dart';
import '../data/repositories/user_profile_repository_impl.dart';
import '../domain/repositories/user_profile_repository.dart';
import '../domain/usecases/user_profile_usecase.dart';
import '../presentation/viewmodels/user_profile_viewmodel.dart';
import '../presentation/viewmodels/auth_viewmodel.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  // Repositories
  getIt.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepositoryImpl(),
  );

  // Use Cases
  getIt.registerLazySingleton(
    () => UserProfileUseCase(getIt<UserProfileRepository>()),
  );

  // ViewModels - Using lazy factory for better performance
  getIt.registerLazySingleton(
    () => UserProfileViewModel(getIt<UserProfileUseCase>()),
  );

  getIt.registerLazySingleton(
    () => AuthViewModel(),
  );
}
