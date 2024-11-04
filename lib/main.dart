import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:fyp_image_transfer/pages/Tutorial.dart';
import 'package:fyp_image_transfer/pages/Home.dart';
import 'package:fyp_image_transfer/pages/Camera.dart';
import 'package:fyp_image_transfer/pages/Image.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: "/home",
    routes: {
      '/home': (context) => Home(),
      '/tutorial': (context) => Tutorial1(),
      '/camera' : (context) => Camera(cameras: cameras),
      '/image' : (context) => Transfer(),
    },
  ));
}




