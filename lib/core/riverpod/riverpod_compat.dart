import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Совместимость с классическими типами Riverpod
export 'package:flutter_riverpod/flutter_riverpod.dart';

/// Тип для Reader функции
typedef Reader = T Function<T>(ProviderListenable<T> provider);

/// Расширение для Ref с синхронным чтением
extension RefX on Ref {
  /// Синхронное чтение провайдера
  T readSync<T>(ProviderListenable<T> provider) => read(provider);
}
