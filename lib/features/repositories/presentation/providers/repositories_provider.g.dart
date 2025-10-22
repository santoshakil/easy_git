// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repositories_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedPath)
const selectedPathProvider = SelectedPathProvider._();

final class SelectedPathProvider
    extends $NotifierProvider<SelectedPath, String?> {
  const SelectedPathProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedPathProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedPathHash();

  @$internal
  @override
  SelectedPath create() => SelectedPath();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedPathHash() => r'331dc93768e8b01fa0a55008ecb38b20e5cc815b';

abstract class _$SelectedPath extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(Repositories)
const repositoriesProvider = RepositoriesProvider._();

final class RepositoriesProvider
    extends $NotifierProvider<Repositories, AsyncValue<List<String>>> {
  const RepositoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'repositoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$repositoriesHash();

  @$internal
  @override
  Repositories create() => Repositories();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<String>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<String>>>(value),
    );
  }
}

String _$repositoriesHash() => r'0249fbcb9a30a62df000b5a4c6c90ce85fe4c5d0';

abstract class _$Repositories extends $Notifier<AsyncValue<List<String>>> {
  AsyncValue<List<String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<String>>, AsyncValue<List<String>>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, AsyncValue<List<String>>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(repositoriesInfo)
const repositoriesInfoProvider = RepositoriesInfoProvider._();

final class RepositoriesInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RepositoryInfo>>,
          List<RepositoryInfo>,
          FutureOr<List<RepositoryInfo>>
        >
    with
        $FutureModifier<List<RepositoryInfo>>,
        $FutureProvider<List<RepositoryInfo>> {
  const RepositoriesInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'repositoriesInfoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$repositoriesInfoHash();

  @$internal
  @override
  $FutureProviderElement<List<RepositoryInfo>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RepositoryInfo>> create(Ref ref) {
    return repositoriesInfo(ref);
  }
}

String _$repositoriesInfoHash() => r'067968e9c5dc30e81c5584b2773b5303b5b1608d';

@ProviderFor(SelectionMode)
const selectionModeProvider = SelectionModeProvider._();

final class SelectionModeProvider
    extends $NotifierProvider<SelectionMode, bool> {
  const SelectionModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectionModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectionModeHash();

  @$internal
  @override
  SelectionMode create() => SelectionMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$selectionModeHash() => r'3e0ad13b026348f083db2371a3b7f641773e9fb7';

abstract class _$SelectionMode extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(SelectedRepositories)
const selectedRepositoriesProvider = SelectedRepositoriesProvider._();

final class SelectedRepositoriesProvider
    extends $NotifierProvider<SelectedRepositories, Set<String>> {
  const SelectedRepositoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedRepositoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedRepositoriesHash();

  @$internal
  @override
  SelectedRepositories create() => SelectedRepositories();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$selectedRepositoriesHash() =>
    r'd007e1fb073b01bcf52fba3abac28e3682a8c975';

abstract class _$SelectedRepositories extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
