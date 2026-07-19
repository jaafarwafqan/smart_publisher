import 'mapper.dart';

class MapperFactory {
  const MapperFactory();

  TTo map<TFrom, TTo>(Mapper<TFrom, TTo> mapper, TFrom input) {
    return mapper.map(input);
  }
}
