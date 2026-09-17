import 'package:flutter_test/flutter_test.dart';

import 'package:kanu/config.dart' as cfg;

void main() {
  test('root URL points to the KANU PWA', () {
    expect(cfg.rootUrl.host, 'kanu-rencontres.com');
  });
}
