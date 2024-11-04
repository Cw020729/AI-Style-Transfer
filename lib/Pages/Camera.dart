import 'dart:async';


import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  const Camera({Key? key, required this.cameras}) : super(key: key);

  @override
  State<Camera> createState() => _CameraState();
}

class _CameraState extends State<Camera> with WidgetsBindingObserver {
  //camera option
  final ImagePicker picker = ImagePicker();
  late CameraController cameraController;
  late Future<void> cameraValue;
  late XFile? image;
  bool istakingPicture = false;
  int cameraSwap = 0;
  bool isFlashOn = false;


  //count down timer
  int timerTime = 0;
  Duration timerDuration = Duration(seconds: 0);
  late Timer pictureTimer;
  late Timer countDownTimer;



  @override
  void initState() {
    startCamera(0);
    super.initState();
  }


  Future pickImageFromGallery() async {
    image= await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      cameraController.dispose();
      final result = await Navigator.pushNamed(
        context,
        '/image',
        arguments: image,
      );
      if (result != null){
        setState(() {
          startCamera(cameraSwap);
        });
      }
    }
  }

  void startCamera(int camera) {
    cameraController = CameraController(
      widget.cameras[camera],
      ResolutionPreset.high,
      enableAudio: false,
    );
    cameraValue = cameraController.initialize();
  }


  void takePicture()async{
    if(cameraController.value.isTakingPicture || !cameraController.value.isInitialized){
      return;
    }
    if (isFlashOn){
      await cameraController.setFlashMode(FlashMode.torch);
    }else{
      await cameraController.setFlashMode(FlashMode.off);
    }
    image = await cameraController.takePicture();
    if (cameraController.value.flashMode == FlashMode.torch){
      cameraController.setFlashMode(FlashMode.off);
    }

    Navigator.of(context).pop();
    final result = await Navigator.pushNamed(
      context,
      '/image',
      arguments: image,
    );
    if (result != null){
      setState(() {
        startCamera(cameraSwap);
      });
    }
  }

  void swapCamera(){
    if (cameraSwap == 0 ){
      cameraSwap = 1;
    }else{
      cameraSwap = 0;
    }
    startCamera(cameraSwap);
  }

  void startTimer() {
    final originalSecond = timerDuration.inSeconds;
    countDownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => setCountDown(originalSecond));
  }

  void setCountDown(int originalSecond) {
    const reduceSecondsBy = 1;
    setState(() {
      final seconds = timerDuration.inSeconds - reduceSecondsBy;
      if (seconds < 0) {
        countDownTimer.cancel();
        timerDuration = Duration (seconds: originalSecond);
        setState(() {
        });
      } else {
        timerDuration = Duration(seconds: seconds);
      }
    });
  }

  Widget getTimerIcon(int timer){
    switch (timer){
      case 0:
        return Icon(
          Icons.timer_off_outlined,
          size: 35,
          color: Colors.black,
        );
      case 3:
        return Icon(
          Icons.timer_3_outlined,
          size: 35,
          color: Colors.black,
        );
      case 10:
        return Icon(
          Icons.timer_10_outlined,
          size: 35,
          color: Colors.black,
        );
      default:
        return Icon(
          Icons.timer_off_outlined,
          size: 35,
          color: Colors.black,
        );
    }
  }

  int setTimer(int timer){
    switch (timer) {
      case 0:
        return 3;
      case 3:
        return 10;
      case 10:
        return 0;
      default:
        return 0;
    }
  }

  Widget getFlashIcon(bool isFlashOn){
    if (isFlashOn){
      return Icon(
        Icons.flash_on,
        size: 35,
        color: Colors.black,
      );
    }else{
      return Icon(
        Icons.flash_off,
        size: 35,
        color: Colors.black,
      );
    }
  }

  void showHelpDialog(){
    showDialog(
        context: context,
        builder: (context) => new AlertDialog(
          content: Container(
            height: 600,
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    IconButton(
                        onPressed: (){
                          setState(() {
                            Navigator.of(context).pop();
                          });
                        },
                        icon: Icon(
                          Icons.close,
                          size: 35,
                        )),
                  ],
                ),
                Image(image: AssetImage("assets/tutorial_1.png")),
              ],
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final seconds = timerDuration.inSeconds.remainder(60);

    return WillPopScope(
      onWillPop: () async{
        if(istakingPicture){
          setState(() {
            istakingPicture = !istakingPicture;
            countDownTimer.cancel();
            pictureTimer.cancel();
            timerDuration = Duration(seconds: timerTime);
          });
          return false;
        }else{
          Navigator.of(context).pop();
          return false;
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true, // Extend body behind the app bar
        appBar:
        PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: <Widget>[
              if (!istakingPicture)
              Row(
                children: <Widget>[
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.fromRGBO(255, 255, 255, 0.7), // Background color of the border
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          swapCamera();
                        });
                      },
                      icon: Icon(
                        Icons.cameraswitch,
                        size: 35,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.fromRGBO(255, 255, 255, 0.7), // Background color of the border
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          timerDuration = Duration(seconds: setTimer(timerTime));
                          timerTime = setTimer(timerTime);
                        });
                      },
                      icon: getTimerIcon(timerTime)
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.fromRGBO(255, 255, 255, 0.7), // Background color of the border
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          isFlashOn = !isFlashOn;
                        });
                      },
                      icon: getFlashIcon(isFlashOn),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.fromRGBO(255, 255, 255, 0.7), // Background color of the border
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          showHelpDialog();
                        });
                      },
                      icon: Icon(
                        Icons.help,
                        size: 35,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                ],
              ),
            ],
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            if (!istakingPicture)
            Expanded(
              flex: 1,
              child: FloatingActionButton(
                backgroundColor: Color.fromRGBO(255, 255, 255, 0.7),
                shape: CircleBorder(),
                onPressed: () {
                  pickImageFromGallery();
                },
                child: Icon(
                  Icons.image,
                  size: 40,
                  color: Colors.black,
                ),
              ),
            ),
            if(istakingPicture)
            Expanded(
              flex: 1,
              child: Text(""),
            ),
            if(!istakingPicture)
            Expanded(
              flex: 1,
              child: SizedBox(
                width: 100, // Adjust width as needed
                height: 100, // Adjust height as needed
                child: FloatingActionButton(
                  backgroundColor: Color.fromRGBO(255, 255, 255, 0.7),
                  shape: CircleBorder(),
                  onPressed: () async{
                    setState(() {
                      istakingPicture = !istakingPicture;
                    });
                      startTimer();
                      pictureTimer = Timer.periodic(Duration(seconds: timerTime), (timer) {
                        takePicture();
                        showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) => new AlertDialog(
                            title: Text("Processing Image"),
                            content: LinearProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1573FE)),
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              minHeight: 15,
                              backgroundColor: Colors.grey,
                            ),
                          ),
                        );
                        timer.cancel();
                        istakingPicture = false;
                      }
                      );
                  },
                  child: Icon(
                    Icons.camera,
                    size: 80,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            if(istakingPicture)
            Expanded(
              flex: 1,
              child: SizedBox(
                width: 100, // Adjust width as needed
                height: 100, // Adjust height as needed
                child: FloatingActionButton(
                  backgroundColor: Color.fromRGBO(255, 255, 255, 0.7),
                  shape: CircleBorder(),
                  onPressed: () {
                    setState(() {
                      istakingPicture = !istakingPicture;
                      countDownTimer.cancel();
                      pictureTimer.cancel();
                      timerDuration = Duration(seconds: timerTime);
                    });
                  },
                  child: Icon(
                    Icons.stop,
                    size: 80,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(""),
            )
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: Stack(
          children: [
            FutureBuilder(
                future: cameraValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return SizedBox(
                        width: size.width,
                        height: size.height,
                        child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: 100,
                              child: CameraPreview(cameraController),
                            )));
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                }),
            if(istakingPicture)
            Center(
              child: Text(
                '$seconds',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 50),
              ),
            ),
        ]),
      ),
    );
  }
}

