import 'dart:io';

import 'package:dbus/dbus.dart';
import 'handler.dart';

const myname = 'cc.malhotra.karmanyaah.test';
void main(List<String> arguments) async {
  var client = DBusClient.session();
  print('Dbus connected');

  var h = Handler(client);
  print('Handler started');
  sleep(Duration(milliseconds: 200));
  await client.registerObject(h);
//prints auto

  if (Platform.environment['VARIABLE'] == 'true') {
    await acquireName(client, myname, {DBusRequestNameFlag.doNotQueue});

    print('Running in background');
    var timeout = false;
    // ignore: unawaited_futures
    Future.delayed(Duration(seconds: 20)).whenComplete(() => timeout = true);
    while (!timeout &&
        // last message was less than 1000 ms ago
        DateTime.now().millisecondsSinceEpoch - h.lastMessageTime < 5000) {
      //wait to receive all queued messages
      await Future.delayed(Duration(milliseconds: 10));
    }
    print(timeout);
    print(h.lastMessageTime);
    //its been 100 milliseconds since last call

    await h.close();
    await client.close();
    exit(0);
  }

  await acquireName(client, myname, {});

  var names = await client.listNames();
  var distributors = <String>[];
  var distributor = '';
  names.forEach((name) {
    if (name.startsWith('org.unifiedpush.Distributor')) distributors.add(name);
  });
  if (distributors.isEmpty) {
    print('no distributor available');
    exit(1);
  } else if (distributors.length == 1) {
    distributor = distributors[0];
  } else {
    distributors.asMap().forEach((n, e) => print(n.toString() + ' ' + e));
    distributor = distributors[int.parse(stdin.readLineSync())];
  }
  print(distributor);

  var object = DBusRemoteObject(
      client, distributor, DBusObjectPath('/org/unifiedpush/Distributor'));

  var values = [
    DBusString(myname), // App name
    DBusString('1243aaa'),
  ];
  var result = await object.callMethod(
      'org.unifiedpush.Distributor1', 'Register', values);
  print(result);

  while (true) {
    print('completed initial, sleeping for 1 minute');
    await Future.delayed(Duration(minutes: 1));
  }
  //var hostname1 = OrgFreeDesktopHostname1(client, 'org.freedesktop.hostname1');
  //var hostname = await hostname1.getHostname();
  //print('hostname: $hostname');
  await client.close();
  await h.close();
}

Future<void> acquireName(
    DBusClient client, String name, Set<DBusRequestNameFlag> flags) async {
  var result = await client.requestName(name, flags: flags);
  switch (result) {
    case DBusRequestNameReply.primaryOwner:
      print('Now the owner of name $name');
      break;
    case DBusRequestNameReply.inQueue:
      print('In queue to own name $name');
      sleep(Duration(seconds: 2));
      await acquireName(client, name, flags);
      break;
    case DBusRequestNameReply.exists:
      print('Unable to own name $name, already in use');
      exit(1);
      break;
    case DBusRequestNameReply.alreadyOwner:
      print('Already the owner of name $name');
      break;
  }
}
