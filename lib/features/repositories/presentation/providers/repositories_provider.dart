import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../src/rust/api/git.dart' as rust_api;
import '../../../../src/rust/models/repository.dart';

part 'repositories_provider.g.dart';

@riverpod
class SelectedPath extends _$SelectedPath {
  @override
  String? build() => null;
  void set(String? path) => state = path;
}

@riverpod
class Repositories extends _$Repositories {
  @override
  AsyncValue<List<String>> build() => const AsyncValue.data([]);

  Future<void> scan(String path) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => rust_api.scanRepositories(rootPath: path));
  }
}

@riverpod
Future<List<RepositoryInfo>> repositoriesInfo(Ref ref) async {
  final repoPathsAsync = ref.watch(repositoriesProvider);

  return await repoPathsAsync.when(
    data: (repoPaths) async {
      if (repoPaths.isEmpty) return [];
      try {
        return await rust_api.getMultipleRepositoryInfo(paths: repoPaths);
      } catch (e) {
        return [];
      }
    },
    loading: () async => [],
    error: (_, _) async => [],
  );
}

@riverpod
class SelectionMode extends _$SelectionMode {
  @override
  bool build() => false;
  void toggle() => state = !state;
  void set(bool value) => state = value;
}

@riverpod
class SelectedRepositories extends _$SelectedRepositories {
  @override
  Set<String> build() => {};

  void toggle(String path) {
    if (state.contains(path)) {
      state = {...state}..remove(path);
    } else {
      state = {...state, path};
    }
  }

  void clear() => state = {};
  void selectAll(List<String> paths) => state = Set.from(paths);
}
