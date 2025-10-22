import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:easy_git/features/repositories/presentation/providers/repositories_provider.dart';

void main() {
  group('RepositoriesProvider', () {
    test('initial state is empty AsyncValue', () {
      final container = ProviderContainer();
      final provider = container.read(repositoriesProvider);

      expect(provider, isA<AsyncValue<List<String>>>());
      expect(provider.value, isEmpty);
    });

    test('SelectionModeProvider initial state is false', () {
      final container = ProviderContainer();
      final selectionMode = container.read(selectionModeProvider);

      expect(selectionMode, false);
    });

    test('SelectionModeProvider toggle works', () {
      final container = ProviderContainer();

      container.read(selectionModeProvider.notifier).toggle();
      expect(container.read(selectionModeProvider), true);

      container.read(selectionModeProvider.notifier).toggle();
      expect(container.read(selectionModeProvider), false);
    });

    test('SelectedRepositoriesProvider initial state is empty set', () {
      final container = ProviderContainer();
      final selected = container.read(selectedRepositoriesProvider);

      expect(selected, isEmpty);
      expect(selected, isA<Set<String>>());
    });

    test('SelectedRepositoriesProvider toggle adds and removes paths', () {
      final container = ProviderContainer();
      final notifier = container.read(selectedRepositoriesProvider.notifier);

      notifier.toggle('/path1');
      expect(container.read(selectedRepositoriesProvider), {'/path1'});

      notifier.toggle('/path2');
      expect(container.read(selectedRepositoriesProvider), {'/path1', '/path2'});

      notifier.toggle('/path1');
      expect(container.read(selectedRepositoriesProvider), {'/path2'});
    });

    test('SelectedRepositoriesProvider clear works', () {
      final container = ProviderContainer();
      final notifier = container.read(selectedRepositoriesProvider.notifier);

      notifier.toggle('/path1');
      notifier.toggle('/path2');
      expect(container.read(selectedRepositoriesProvider).length, 2);

      notifier.clear();
      expect(container.read(selectedRepositoriesProvider), isEmpty);
    });

    test('SelectedRepositoriesProvider selectAll works', () {
      final container = ProviderContainer();
      final notifier = container.read(selectedRepositoriesProvider.notifier);

      final paths = ['/path1', '/path2', '/path3'];
      notifier.selectAll(paths);

      expect(container.read(selectedRepositoriesProvider).length, 3);
      expect(container.read(selectedRepositoriesProvider), containsAll(paths));
    });

    test('SelectedPathProvider initial state is null', () {
      final container = ProviderContainer();
      final selectedPath = container.read(selectedPathProvider);

      expect(selectedPath, isNull);
    });

    test('SelectedPathProvider set works', () {
      final container = ProviderContainer();

      container.read(selectedPathProvider.notifier).set('/test/path');
      expect(container.read(selectedPathProvider), '/test/path');

      container.read(selectedPathProvider.notifier).set(null);
      expect(container.read(selectedPathProvider), isNull);
    });
  });
}
