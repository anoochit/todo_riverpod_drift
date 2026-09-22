// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ThemeModeState)
final themeModeStateProvider = ThemeModeStateProvider._();

final class ThemeModeStateProvider
    extends $NotifierProvider<ThemeModeState, ThemeMode> {
  ThemeModeStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeStateHash();

  @$internal
  @override
  ThemeModeState create() => ThemeModeState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeStateHash() => r'ae75cbf4ba602695e35801bf228fa3a9bd7812e0';

abstract class _$ThemeModeState extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
