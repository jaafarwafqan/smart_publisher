import 'mapper.dart';

class MapperRegistry {
  MapperRegistry() : _mappers = <Type, Object>{};

  final Map<Type, Object> _mappers;

  void register<TFrom, TTo>(Mapper<TFrom, TTo> mapper) {
    _mappers[TFrom] = mapper;
  }

  Mapper<TFrom, TTo>? get<TFrom, TTo>() {
    final mapper = _mappers[TFrom];
    if (mapper == null) {
      return null;
    }

    return mapper as Mapper<TFrom, TTo>;
  }
}
