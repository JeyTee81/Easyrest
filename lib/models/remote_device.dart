import 'dart:io';

class RemoteDevice {
  final String id;
  String name;
  final String ip;
  final Socket socket;
  bool isConnected;

  RemoteDevice({
    required this.id,
    required this.name,
    required this.ip,
    required this.socket,
    required this.isConnected,
  });
}





