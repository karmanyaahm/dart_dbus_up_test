import 'dart:io';
import 'package:desktop_notifications/desktop_notifications.dart';
import 'package:dbus/dbus.dart';

class Handler extends DBusObject {
  int lastMessageTime;
  NotificationsClient notific_client;

  Handler(DBusClient c) : super(DBusObjectPath('/org/unifiedpush/Connector')) {
    lastMessageTime = DateTime.now().millisecondsSinceEpoch;
    notific_client = NotificationsClient(bus: c);
    notific_client.notify('starting listening', expireTimeoutMs: 10000);
  }

  Future<void> close() async {
    await notific_client.close();
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.unifiedpush.Connector1') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    switch (methodCall.name) {
      case 'NewEndpoint':
        print('got new endpoint');
        print(methodCall.values);
        break;
      case 'Message':
        print(methodCall.values);
        lastMessageTime = DateTime.now().millisecondsSinceEpoch;
        await notific_client.notify(methodCall.values[1].toNative().toString(),
            expireTimeoutMs: 10000);
        break;

      case 'Unregistered':
        print('unregister');
        exit(1);
        break;
      default:
        print(methodCall.name);
        break;
    }
    //return DBusMethodSuccessResponse([]);
  }

  @override
  List<DBusIntrospectInterface> introspect() {
    return [
      DBusIntrospectInterface('org.unifiedpush.Connector1', methods: [
        DBusIntrospectMethod(
          'Message',
          args: [
            DBusIntrospectArgument(
                '1', DBusSignature('string'), DBusArgumentDirection.in_),
            DBusIntrospectArgument(
                '2', DBusSignature('string'), DBusArgumentDirection.in_),
            DBusIntrospectArgument(
                '3', DBusSignature('string'), DBusArgumentDirection.in_),
          ],
        )
      ], properties: [])
    ];
  }
}
