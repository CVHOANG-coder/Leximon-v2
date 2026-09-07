import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/core/services/app_tracking_transparency_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  Future<void> noDelay(Duration _) async {}

  test('does not request ATT after the user has already decided', () async {
    var requestCount = 0;

    final status = await AppTrackingTransparencyService.requestWhenActive(
      readStatus: () async => PermissionStatus.permanentlyDenied,
      requestPermission: () async {
        requestCount += 1;
        return PermissionStatus.permanentlyDenied;
      },
      waitUntilResumed: () async {},
      isResumed: () => true,
      delay: noDelay,
    );

    expect(status, PermissionStatus.permanentlyDenied);
    expect(requestCount, 0);
  });

  test('waits for the app to be active before requesting ATT', () async {
    var resumed = false;
    var waitCount = 0;
    var requestCount = 0;

    final status = await AppTrackingTransparencyService.requestWhenActive(
      readStatus: () async => PermissionStatus.denied,
      requestPermission: () async {
        requestCount += 1;
        return PermissionStatus.granted;
      },
      waitUntilResumed: () async {
        waitCount += 1;
        resumed = true;
      },
      isResumed: () => resumed,
      delay: noDelay,
    );

    expect(status, PermissionStatus.granted);
    expect(waitCount, 1);
    expect(requestCount, 1);
  });

  test('retries when iOS leaves ATT undetermined', () async {
    var requestCount = 0;

    final status = await AppTrackingTransparencyService.requestWhenActive(
      readStatus: () async => PermissionStatus.denied,
      requestPermission: () async {
        requestCount += 1;
        return requestCount == 1
            ? PermissionStatus.denied
            : PermissionStatus.granted;
      },
      waitUntilResumed: () async {},
      isResumed: () => true,
      delay: noDelay,
    );

    expect(status, PermissionStatus.granted);
    expect(requestCount, 2);
  });

  test('does not spend an attempt while the app is inactive', () async {
    var resumed = true;
    var delayCount = 0;
    var requestCount = 0;

    final status = await AppTrackingTransparencyService.requestWhenActive(
      readStatus: () async => PermissionStatus.denied,
      requestPermission: () async {
        requestCount += 1;
        return PermissionStatus.granted;
      },
      waitUntilResumed: () async {
        resumed = true;
      },
      isResumed: () => resumed,
      delay: (_) async {
        delayCount += 1;
        if (delayCount == 1) resumed = false;
      },
    );

    expect(status, PermissionStatus.granted);
    expect(delayCount, 2);
    expect(requestCount, 1);
  });
}
