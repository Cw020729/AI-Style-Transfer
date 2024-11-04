import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:emoji_selector/emoji_selector.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fyp_image_transfer/Model/TextObject.dart';
import 'package:fyp_image_transfer/Model/EmojiObject.dart';

class Transfer extends StatefulWidget {
  const Transfer({super.key});

  @override
  State<Transfer> createState() => _TransferState();
}

class _TransferState extends State<Transfer> {
  ScreenshotController screenshotController = ScreenshotController();
  // Define ImagePicker
  final ImagePicker picker = ImagePicker();

  List<TextObject> textObjects = [];
  List<EmojiObject> emojiObjects = [];


  // Tflite Model info
  final String stylePredictorPath = "assets/predict-model.tflite";
  final String styleTransformerPath = "assets/transform-model.tflite";
  late final Interpreter predictorInterpreter;
  late final Interpreter transformerInterpreter;
  bool notLoaded = true;
  late final int transformerInputImageSize;
  late final int predictorInputImageSize;
  late final int featuresStylizedSize;
  double styleBlendingRatio = 0.5;




  // Content and Style Image info
  late File contentImageFile;
  List<File> styleFile = [];

  File transferredStyleFile = File("");

  List<String> styleUrls = [
    "assets/starry_night_style.jpeg",
    "assets/the_scream_style.jpg",
    "assets/guernica_style.jpg",
  ];

  List<String> displayStyleImageUrls = [
    "assets/none.png",
    "assets/starry_night.png",
    "assets/the_scream.png",
    "assets/guernica.png",
    "assets/own_style.png"
  ];

  List<String> imageTitle = [
    "None",
    "Starry Night",
    "The Scream",
    "Guernica",
    "Own Style"
  ];


  // Loading overlay
  bool showLoadingOverlay = false;
  String loadingText = "";
  String loadingPercentage = "";
  double linearProcessValue = 0;

  //cancel overlay
  bool showCancelOverlay = false;

  //Save image alert
  bool isImageSave = false;

  //Transfer Process
  bool isTransferringImage = false;

  @override
  void initState() {
    super.initState();
    loadStyleImagesToFile(styleUrls);
    loadModel();
  }


  void showPickEmojiDialog(Offset emojiPosition){
    showDialog(
        context: context,
        builder: (BuildContext context){
          return Dialog(
            child: Container(
              width: 500, // specify your desired width here
              height: 450, // specify your desired height here
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text("Pick an Emoji"),
                  ),
                  Expanded(
                    child: EmojiSelector(
                      padding: const EdgeInsets.all(20),
                      onSelected: (emoji) {
                        setState(() {
                          emojiObjects.add(EmojiObject(emojiPosition: emojiPosition, emojiData: emoji));
                          Navigator.of(context).pop();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  // build Emoji Object in the List
  Widget buildEmojiObject(int index){
    Widget emojiWidget = Positioned(
      top: emojiObjects[index].emojiPosition.dy,
      left: emojiObjects[index].emojiPosition.dx,
      child: Center(
        child: TapRegion(
          onTapInside: (tap){
            setState(() {
              emojiObjects[index].isChangingEmoji = true;
            });
          },
          onTapOutside: (tap) {
            setState(() {
              emojiObjects[index].isChangingEmoji = false;
            });
          },
          child: GestureDetector(
              onPanUpdate: (details) {
                emojiObjects[index].isChangingEmoji = false;
                emojiObjects[index].emojiPosition += details.delta;
                setState(() {});
              },
              child: emojiObjects[index].isChangingEmoji
                  ? Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black12.withOpacity(0.3)),
                  color: Colors.black12.withOpacity(0.3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          IconButton(
                              onPressed: (){
                                setState(() {
                                  deleteEmojiObject(emojiObjects[index]);
                                });
                              },
                              icon: Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                                size: 30,
                              )
                          ),
                        ]
                    ),
                    Text(
                      emojiObjects[index].emojiData.char,
                      style: TextStyle(
                        fontSize: emojiObjects[index].size,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        GestureDetector(
                          onLongPress: (){
                              emojiObjects[index].isEditingSize = true;
                              minusEmojiSize(emojiObjects[index]);
                          },
                            onLongPressUp: (){
                                emojiObjects[index].isEditingSize = false;
                                minusEmojiSize(emojiObjects[index]);
                            },
                          onTap: (){
                              emojiObjects[index].isEditingSize = true;
                              minusEmojiSize(emojiObjects[index]);
                              emojiObjects[index].isEditingSize = false;
                          },
                          child: Icon(
                                Icons.remove_circle,
                                size: 30,
                                color: Colors.black,
                              )
                          ),
                        GestureDetector(
                            onLongPress: (){
                                emojiObjects[index].isEditingSize = true;
                                addEmojiSize(emojiObjects[index]);
                            },
                            onLongPressUp: (){
                              emojiObjects[index].isEditingSize = false;
                            },
                            onTap: (){
                                emojiObjects[index].isEditingSize = true;
                                addEmojiSize(emojiObjects[index]);
                                emojiObjects[index].isEditingSize = false;
                            },
                          child: Icon(
                            Icons.add_circle,
                            size: 30,
                            color: Colors.black,
                          )
                        ),
                      ],
                    )
                  ],
                ),
              )
                  : Container(
                    padding:EdgeInsets.all(20),
                    child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                    SizedBox(
                      height:50,
                    ),
                    Text(
                      emojiObjects[index].emojiData.char,
                      style: TextStyle(
                        fontSize: emojiObjects[index].size,
                      ),
                    ),
                                    ],
                                  ),
                  )
          ),
        ),
      ),
    );
    return emojiWidget;
  }

  void minusEmojiSize(EmojiObject emojiObject){
    setState(() {
      emojiObject.size -= 1;
    });
    //on long press
    Timer.periodic(Duration(milliseconds: 200), (timer) {
      if (emojiObject.size > 20 && emojiObject.isEditingSize){
        setState(() {
          emojiObject.size -= 1;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void addEmojiSize(EmojiObject emojiObject){
    setState(() {
      emojiObject.size += 1;
    });
    Timer.periodic(Duration(milliseconds: 200), (timer) {
      // Check condition and update emojiSize
      if (emojiObject.size < 100 && emojiObject.isEditingSize) {
        setState(() {
          emojiObject.size += 1;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Widget buildTextObject(int index){
    Widget textWidget = Positioned(
      top: textObjects[index].textPosition.dy,
      left: textObjects[index].textPosition.dx,
      child: Center(
        child: TapRegion(
          onTapInside: (tap){
            setState(() {
              textObjects[index].isChangingText = true;
            });
          },
          onTapOutside: (tap) {
            if(!textObjects[index].isChangingColor){
            setState(() {
              if (isTextEmpty(textObjects[index])) {
                deleteTextObject(textObjects[index]);
              } else if (!isTextEmpty(textObjects[index])) {
                textObjects[index].isChangingText = false;
              }
            });
          }},
          child: GestureDetector(
            onPanUpdate: (details) {
              if  (textObjects[index].text.isNotEmpty){
                textObjects[index].isChangingText = false;
              }
                textObjects[index].textPosition += details.delta;
                setState(() {});
            },
            child: textObjects[index].isChangingText
                ? Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black12.withOpacity(0.3)),
                  color: Colors.black12.withOpacity(0.3),
                ),
                  width: 200,
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          GestureDetector(
                            onTap: (){
                              textObjects[index].isChangingColor = true;
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context){
                                    return AlertDialog(
                                      title: Text("Pick a color"),
                                      content: ColorPicker(
                                        pickerColor: textObjects[index].color,
                                        onColorChanged: (changedColor){
                                          setState(() {
                                            textObjects[index].color = changedColor;
                                          });
                                        },
                                      ),
                                      actions: [
                                        TextButton(onPressed: (){
                                          Navigator.of(context).pop();
                                          textObjects[index].isChangingColor = false;
                                        },
                                            child: Text("Done"))
                                      ],
                                    );
                                  }
                              ).then((onValue){
                                if(onValue == null){
                                  textObjects[index].isChangingColor = false;
                                }
                              });
                            },
                            child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: textObjects[index].color,
                              )
                            ),
                          ),
                          IconButton(
                              onPressed: (){
                                setState(() {
                                  deleteTextObject(textObjects[index]);
                                });
                              },
                              icon: Icon(
                                  Icons.delete,
                                color: Colors.redAccent,
                                size: 30,
                              )
                          ),
                        ]
                      ),
                      TextField(
                        onSubmitted: (value){
                          setState(() {
                            textObjects[index].text = value;
                            textObjects[index].isChangingText = false;
                          });
                        },
                              autofocus: true,
                              controller: TextEditingController(text: textObjects[index].text),
                              style: TextStyle(
                                fontSize: textObjects[index].size,
                                color: textObjects[index].color,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Type Your Text',
                              ),
                              onChanged: (value) {
                                textObjects[index].text = value;
                              },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          GestureDetector(
                            onLongPress: (){
                              textObjects[index].isEditingSize = true;
                              minusTextSize(textObjects[index]);
                            },
                              onLongPressUp: (){
                                textObjects[index].isEditingSize = false;
                              },
                              onTap: () async{
                                textObjects[index].isEditingSize = true;
                                minusTextSize(textObjects[index]);
                                textObjects[index].isEditingSize = false;
                              },
                            child: Icon(
                                  Icons.remove_circle,
                                  size: 30,
                                  color: Colors.black,
                                )
                          ),
                          GestureDetector(
                              onLongPress: (){
                                textObjects[index].isEditingSize = true;
                                addTextSize(textObjects[index]);
                              },
                              onLongPressUp: (){
                                textObjects[index].isEditingSize = false;
                              },
                              onTap: (){
                                textObjects[index].isEditingSize = true;
                                addTextSize(textObjects[index]);
                                textObjects[index].isEditingSize = false;
                              },
                            child: Icon(
                              Icons.add_circle,
                              size: 30,
                              color: Colors.black,
                            )
                          ),
                        ],
                      )
                    ],
                  ),
                )
                : Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                  SizedBox(
                    height:75,
                  ),
                  Text(
                    textObjects[index].text,
                    style: TextStyle(
                      fontSize: textObjects[index].size,
                      color: textObjects[index].color,
                    ),
                  ),
                                ],
                              ),
                )
          ),
        ),
      ),
    );
    return textWidget;
  }

  void deleteEmojiObject(EmojiObject emojiObject){
    emojiObjects.remove(emojiObject);
  }

  void deleteTextObject(TextObject textObject){
    textObjects.remove(textObject);
  }

  void addTextObject(TextObject textObject){
    if (textObjects.isEmpty || textObjects.last.text.isNotEmpty){
      textObjects.add(textObject);
    }
  }

  void addTextSize(TextObject textObject){
    setState(() {
      textObject.size += 1;
    });
    Timer.periodic(Duration(milliseconds: 200), (timer) {
      // Check condition and update emojiSize
      if (textObject.size < 100 && textObject.isEditingSize){
        setState(() {
          textObject.size += 1;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void minusTextSize(TextObject textObject){
    setState(() {
      textObject.size -= 1;
    });
    Timer.periodic(Duration(milliseconds: 200), (timer) {
      // Check condition and update emojiSize
      if (textObject.size > 10 && textObject.isEditingSize){
        setState(() {
          textObject.size -= 1;
        });
      } else {
        timer.cancel();
      }
    });
  }

  bool isTextEmpty(TextObject textObject){
    return textObject.text.isEmpty;
  }

  void saveImage(Size phoneSize) async {
    screenshotController.captureFromWidget(buildImageWidget(phoneSize)).then((captureImage) async{
      try {
        // Request permission to save image
        ImageGallerySaver.saveImage(captureImage);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Image saved to gallery'),
        ));
      } catch (e) {
        print('Error saving image: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save image'),
        ));
      }
    });
  }

  void shareImage(Size phoneSize, BuildContext context) async {
    screenshotController.captureFromWidget(buildImageWidget(phoneSize)).then((captureImage) async{
      XFile image = XFile.fromData(
        captureImage,
        mimeType: 'image/png'
      );
      Navigator.of(context).pop();
      await Share.shareXFiles([image], text: 'Great picture');

    });
  }


  void loadStyleImagesToFile(List<String> styleUrls) async {
    for (int a = 0; a < styleUrls.length; a++) {
      ByteData imageData = await rootBundle.load(styleUrls[a]);
      Uint8List imageBytes = imageData.buffer.asUint8List();
      String fileName = styleUrls[a].replaceAll("assets/", "");
      File imageFile = await writeTempFile(imageBytes, fileName);
      styleFile.add(imageFile);
    }
  }

  Future<File> writeTempFile(Uint8List bytes, String fileName) async {
    Directory tempDir = await getTemporaryDirectory();
    File tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  Future<void> loadModel() async {
    predictorInterpreter = await Interpreter.fromAsset(stylePredictorPath);
    transformerInterpreter = await Interpreter.fromAsset(styleTransformerPath);

    // Save the input and output dimensions of both models to preprocess later the input images
    transformerInputImageSize = transformerInterpreter.getInputTensor(0).shape[1];
    predictorInputImageSize = predictorInterpreter.getInputTensor(0).shape[1];
    featuresStylizedSize = predictorInterpreter.getOutputTensor(0).shape[3];
    notLoaded = false;
  }

  img.Image convertFileToImage(File file) {
    img.Image image = img.decodeImage(file.readAsBytesSync())!;
    return image;
  }

  img.Image preprocessImage(img.Image image, height, width) {
    img.Image resizedImage = img.copyResize(image, height: height, width: width);
    resizedImage = resizedImage.convert(format: img.Format.float32);
    return resizedImage;
  }


  Future<File> transferingImage(img.Image predictStyleImage, img.Image predictContentImage, img.Image transferContentImage, int width, int height) async {


    // Predicting Style
    var stylePredictOutput = List.filled(featuresStylizedSize, 0.0).reshape([1, 1, 1, featuresStylizedSize]);
    predictorInterpreter.run(predictStyleImage.toUint8List(), stylePredictOutput);

    var contentPredictOutput = List.filled(featuresStylizedSize, 0.0).reshape([1, 1, 1, featuresStylizedSize]);
    predictorInterpreter.run(predictContentImage.toUint8List(), contentPredictOutput);

    //Blending Style
    for (int i = 0; i < featuresStylizedSize; i++) {
      stylePredictOutput[0][0][0][i] = contentPredictOutput[0][0][0][i] * (1 - styleBlendingRatio) + stylePredictOutput[0][0][0][i] * styleBlendingRatio;
    }

    var transferInputs = [transferContentImage.toUint8List(), stylePredictOutput];
    var transferOutputs = Map<int, Object>();
    var outputData = List.filled(transformerInputImageSize * transformerInputImageSize * 3, 0.0).reshape([1, transformerInputImageSize, transformerInputImageSize, 3]);
    transferOutputs[0] = outputData;

    // Transforming Style
    transformerInterpreter.runForMultipleInputs(transferInputs, transferOutputs);


    // Converting transformation to image
    var transferredImage = convertFromArrayToImage(outputData, transformerInputImageSize);
    transferredImage = img.copyResize(transferredImage, width: width, height: height);
    // Define the file name and location
    Directory tempDir = await getTemporaryDirectory();
    String outputFile = "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";
    // Saving results
    await img.encodeImageFile(outputFile, transferredImage);
    return File(outputFile);
  }

  img.Image convertFromArrayToImage(List<dynamic> imageArray, int inputSize) {
    Uint8List bytes =
    Uint8List.fromList(List.filled(inputSize * inputSize * 3, 0));

    for (int x = 0; x < inputSize; x++) {
      for (int y = 0; y < inputSize; y++) {
        int pixelIndex = (x * inputSize + y) * 3;
        bytes[pixelIndex] = (imageArray[0][x][y][0] * 255).toInt();
        bytes[pixelIndex + 1] = (imageArray[0][x][y][1] * 255).toInt();
        bytes[pixelIndex + 2] = (imageArray[0][x][y][2] * 255).toInt();
      }
    }

    img.Image newImage = img.Image.fromBytes(width: inputSize, height: inputSize, bytes: bytes.buffer);
    return newImage;
  }

  Future<String> pickStyleImage() async {
    XFile? ownStyleImage = await picker.pickImage(source: ImageSource.gallery);
    if (ownStyleImage != null) {
      return ownStyleImage.path;
    } else {
      return "";
    }
  }

  SizedBox buildImageWidget(Size phoneSize) {
    return SizedBox(
      width: phoneSize.width,
      height: phoneSize.height * 0.70,
      child: Stack(
        children: <Widget> [
          Positioned.fill(
            child: transferredStyleFile.path.isEmpty && contentImageFile.path.isNotEmpty
                ? Image.file(
              contentImageFile,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            )
                : Image.file(
              transferredStyleFile,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          for(int a = 0; a< textObjects.length; a++)
            buildTextObject(a),
          for(int a = 0; a < emojiObjects.length; a++)
            buildEmojiObject(a)
        ],
      ),
    );
  }

  Future showSaveDialog(Size size){
    return showDialog(
        context: context,
        builder: (context) => new AlertDialog(
          title: Text("Do you want to save the image"),
          actions: [
            TextButton(
                onPressed: (){
                  Navigator.of(context).pop();
                  Navigator.of(context).pop("refresh");
                },
                child: Text("No")
            ),
            TextButton(onPressed: (){
              saveImage(size);
              Navigator.of(context).pop();
              Navigator.of(context).pop("refresh");
            }, child: Text("Yes")),
          ],
        )
    );
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
                Image(image: AssetImage("assets/tutorial_2.png")),
              ],
            ),
          ),
        ));
  }

  Future<File> preprocessFile(File imageFile) async{
    img.Image image = img.decodeImage(imageFile.readAsBytesSync())!;
    Directory tempDir = await getTemporaryDirectory();
    String outputFile = "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";
    imageFile = File(outputFile);
    await imageFile.writeAsBytes(img.encodeJpg(image));
    return imageFile;
  }

  @override
  Widget build(BuildContext context) {
    final phoneSize = MediaQuery.of(context).size;
    final XFile? image = ModalRoute.of(context)?.settings.arguments as XFile?;
    if (image != null) {
        contentImageFile = File(image.path);
    }

    return WillPopScope(
      onWillPop: () async{
        if(!isTransferringImage){
          if(!isImageSave){
            showSaveDialog(phoneSize);
            return false;
          }else{
            Navigator.of(context).pop("refresh");
            return false;
          }
        }else {
          setState(() {
             showLoadingOverlay = false;
             isTransferringImage = false;
             showCancelOverlay = true;
          });
          return false;
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: <Widget>[
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
                        if(!showCancelOverlay && !showLoadingOverlay){
                          showPickEmojiDialog(Offset(phoneSize.width*0.5, phoneSize.height*0.3));
                        }
                      },
                      icon: Icon(
                        Icons.emoji_emotions,
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
                        if(!showCancelOverlay && !showLoadingOverlay){
                          setState(() {
                            addTextObject(TextObject(textPosition: Offset(phoneSize.width*0.5, phoneSize.height*0.3)));
                          });
                        }
                      },
                      icon: Icon(
                        Icons.text_fields,
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
                        if(!showCancelOverlay && !showLoadingOverlay){
                          setState(() {
                            saveImage(phoneSize);
                            isImageSave = true;
                          });
                        }
                      },
                      icon: Icon(
                        Icons.download,
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
                        if(!showCancelOverlay && !showLoadingOverlay){
                          setState(() {
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
                            shareImage(phoneSize, context);
                          });
                        }
                      },
                      icon: Icon(
                        Icons.share,
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
        body: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                buildImageWidget(phoneSize),
                Padding(
                    padding: EdgeInsets.only(left: 25, top: 10),
                    child: Text("Style Blending Ratio (Transfer Again to Apply)")
                ),
                Slider(
                    value: styleBlendingRatio,
                    max: 1,
                    divisions: 10,
                    label: "${styleBlendingRatio*100}%",
                    onChanged: (double value){
                      setState(() {
                        styleBlendingRatio = value;
                      });
                    }
                    ),
                SizedBox(
                  width: phoneSize.width,
                  height: phoneSize.height * 0.20,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: displayStyleImageUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (!notLoaded) {
                                  var styleFile = File("");
                                  if (index == 0){
                                    setState(() {
                                      transferredStyleFile = File("");
                                    });
                                  }
                                  else if (contentImageFile.path.isNotEmpty &&
                                      index < displayStyleImageUrls.length - 1) {
                                    styleFile = this.styleFile[index-1];
                                  } else {
                                    Future<String> pickedImagePath =
                                    pickStyleImage();
                                    String imagePathResult =
                                    await pickedImagePath;
                                    styleFile = await preprocessFile(File(imagePathResult));
                                  }
                                  if (styleFile.path.isNotEmpty) {
                                    setState(() {
                                      isTransferringImage = true;
                                      showLoadingOverlay = true;
                                      loadingText = "Converting File to Image";
                                      loadingPercentage = "30%";
                                      linearProcessValue = 0.3;
                                    });

                                    SchedulerBinding.instance
                                        .addPostFrameCallback((_) async {
                                      contentImageFile = await preprocessFile(contentImageFile);
                                      var styleImage =
                                      convertFileToImage(styleFile);
                                      var contentImage =
                                      convertFileToImage(contentImageFile);
                                      setState(() {
                                        loadingText = "Resizing Image";
                                        loadingPercentage = "50%";
                                        linearProcessValue = 0.5;
                                      });
                                      SchedulerBinding.instance
                                          .addPostFrameCallback((_) async {
                                        img.Image processedInput =
                                        preprocessImage(contentImage,
                                            transformerInputImageSize, transformerInputImageSize);
                                        img.Image processedContent =
                                        preprocessImage(contentImage, predictorInputImageSize, predictorInputImageSize);
                                        img.Image processedStyle =
                                        preprocessImage(styleImage,
                                            predictorInputImageSize, predictorInputImageSize);
                                        setState(() {
                                          loadingText = "Transferring Image";
                                          loadingPercentage = "70%";
                                          linearProcessValue = 0.7;
                                        });
                                        SchedulerBinding.instance
                                            .addPostFrameCallback((_) async {
                                          File result = await transferingImage(
                                              processedStyle,
                                              processedContent,
                                              processedInput,
                                              contentImage.width,
                                              contentImage.height);
                                          if(isTransferringImage){
                                            setState(() {
                                              isTransferringImage = false;
                                              showLoadingOverlay = false;
                                              transferredStyleFile = result;
                                            });
                                          }else{
                                            setState(() {
                                              showCancelOverlay = false;
                                            });
                                          }
                                        });
                                      });
                                    });
                                  }
                                }
                              },
                              child: Image.asset(
                                displayStyleImageUrls[index],
                              ),
                            ),
                            Text(imageTitle[index]),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (showLoadingOverlay)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          color: Colors.white,
                        ),
                        width: phoneSize.width * 0.8,
                        height: phoneSize.height * 0.2,
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              loadingText,
                              style: GoogleFonts.poppins(
                                  textStyle: TextStyle(fontSize: 18)),
                            ),
                            LinearProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1573FE)),
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              value: linearProcessValue,
                              minHeight: 15,
                              semanticsLabel: 'Linear progress indicator',
                            ),
                            Text(
                              loadingPercentage,
                              style: GoogleFonts.poppins(
                                  textStyle: TextStyle(fontSize: 18)),
                            ),
                          ],
                        ),
                      )),
                ),
              ),
            if (showCancelOverlay)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          color: Colors.white,
                        ),
                        width: phoneSize.width * 0.8,
                        height: phoneSize.height * 0.2,
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              "Cancelling",
                              style: GoogleFonts.poppins(
                                  textStyle: TextStyle(fontSize: 18)),
                            ),
                            LinearProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1573FE)),
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              minHeight: 15,
                              semanticsLabel: 'Linear progress indicator',
                            ),
                          ],
                        ),
                      )),
                ),
              )
          ],
        ),
      ),
    );
  }
}

