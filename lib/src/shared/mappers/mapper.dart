abstract class Mapper<TFrom, TTo> {
  const Mapper();

  TTo map(TFrom input);
}
