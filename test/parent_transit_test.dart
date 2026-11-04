import 'package:flutter_test/flutter_test.dart';
import 'package:intelli_attend_faculty/Presentation/Features/Parent/Controllers/parent_controller.dart';
import 'package:intelli_attend_faculty/Presentation/Features/Parent/Models/parent_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Parent Bus RFID Transit Tests', () {
    test('Default normal state: Child is not on bus', () {
      final controller = ParentController();
      expect(controller.isChildOnBus, isFalse);
      expect(controller.activeChildTransit, isNotNull);
      expect(controller.activeChildTransit!.isOnBus, isFalse);
    });

    test('Student enters bus & taps RFID: Map transit starts', () {
      final controller = ParentController();
      controller.tapRfidBoardBus('child_1');

      expect(controller.isChildOnBus, isTrue);
      final transit = controller.activeChildTransit!;
      expect(transit.isOnBus, isTrue);
      expect(transit.busNumber, equals('Bus #14'));
      expect(transit.vehiclePlate, equals('KA-04-E-2048'));
      expect(transit.driverName, equals('Ramesh Sharma'));
      expect(transit.rfidCardNumber, equals('RFID-88391-A'));
      expect(transit.estimatedMinutes, equals(14));
      expect(transit.remainingKm, equals(4.8));

      // Student taps RFID on exit/deboard
      controller.tapRfidDeboardBus('child_1');
      expect(controller.isChildOnBus, isFalse);
    });

    test('Multi-child switcher preserves individual transit states', () {
      final controller = ParentController();
      controller.tapRfidBoardBus('child_1');
      expect(controller.isChildIdOnBus('child_1'), isTrue);
      expect(controller.isChildIdOnBus('child_2'), isFalse);

      controller.switchChild('child_2');
      expect(controller.isChildOnBus, isFalse);

      controller.switchChild('child_1');
      expect(controller.isChildOnBus, isTrue);
    });
  });
}

