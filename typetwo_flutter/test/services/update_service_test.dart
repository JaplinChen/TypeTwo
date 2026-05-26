import 'package:flutter_test/flutter_test.dart';
import 'package:typetwo/services/update_service.dart';
import 'package:typetwo/models/app_constants.dart';

void main() {
  test('kAppVersion is 1.0.14', () => expect(kAppVersion, '1.0.14'));

  group('version comparison', () {
    test('patch bump is newer',
        () => expect(UpdateService.isNewer('1.0.10', '1.0.9'), true));
    test('minor bump is newer',
        () => expect(UpdateService.isNewer('1.1.0', '1.0.9'), true));
    test('major bump is newer',
        () => expect(UpdateService.isNewer('2.0.0', '1.0.9'), true));
    test('same is not newer',
        () => expect(UpdateService.isNewer('1.0.9', '1.0.9'), false));
    test('older patch is not newer',
        () => expect(UpdateService.isNewer('1.0.8', '1.0.9'), false));
    test('older major is not newer',
        () => expect(UpdateService.isNewer('0.9.99', '1.0.9'), false));
  });
}
