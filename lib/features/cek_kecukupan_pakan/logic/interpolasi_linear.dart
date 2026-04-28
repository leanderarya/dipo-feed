class TitikLinear {
  final double x;
  final double y;

  const TitikLinear({
    required this.x,
    required this.y,
  });
}

double interpolasiLinear({
  required double x,
  required double x1,
  required double y1,
  required double x2,
  required double y2,
}) {
  return y1 + ((x - x1) * (y2 - y1) / (x2 - x1));
}

double interpolasiDariTitik({
  required List<TitikLinear> titik,
  required double xTarget,
}) {
  if (titik.length < 2) {
    throw ArgumentError('Minimal dibutuhkan dua titik untuk interpolasi.');
  }

  final titikTerurut = [...titik]..sort((a, b) => a.x.compareTo(b.x));

  for (final item in titikTerurut) {
    if (item.x == xTarget) {
      return item.y;
    }
  }

  if (xTarget <= titikTerurut.first.x) {
    final kiri = titikTerurut[0];
    final kanan = titikTerurut[1];
    return interpolasiLinear(
      x: xTarget,
      x1: kiri.x,
      y1: kiri.y,
      x2: kanan.x,
      y2: kanan.y,
    );
  }

  if (xTarget >= titikTerurut.last.x) {
    final kiri = titikTerurut[titikTerurut.length - 2];
    final kanan = titikTerurut.last;
    return interpolasiLinear(
      x: xTarget,
      x1: kiri.x,
      y1: kiri.y,
      x2: kanan.x,
      y2: kanan.y,
    );
  }

  for (var i = 0; i < titikTerurut.length - 1; i++) {
    final kiri = titikTerurut[i];
    final kanan = titikTerurut[i + 1];

    if (xTarget >= kiri.x && xTarget <= kanan.x) {
      return interpolasiLinear(
        x: xTarget,
        x1: kiri.x,
        y1: kiri.y,
        x2: kanan.x,
        y2: kanan.y,
      );
    }
  }

  throw StateError('Tidak dapat menentukan titik interpolasi.');
}
