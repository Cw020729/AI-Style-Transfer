import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';


class Tutorial1 extends StatefulWidget {
  @override
  State<Tutorial1> createState() => _Tutorial1State();
}

class _Tutorial1State extends State<Tutorial1> {

  int pageNumber = 1;
  int totalTutorialPage = 4;
  late String imagePath;

  void setImagePath(){
    imagePath =  "assets/tutorial_${pageNumber}.png";
  }

  @override
  Widget build(BuildContext context) {
    setImagePath();
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          Visibility(
            visible: pageNumber == totalTutorialPage,
            child: Container(
              margin: EdgeInsets.fromLTRB(0, 0, 20, 0),
              child: TextButton(
                  onPressed: (){
                    Navigator.pushNamed(context, '/camera');
                  },
                  child: Text(
                    "START",
                    style: GoogleFonts.roboto(
                      textStyle : TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      )
                    ),
                  ),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    Color(0xFF1573FE),
                  ),
                  shape: MaterialStateProperty.all<OutlinedBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: Color(0xFF1573FE),
                        width: 1,
                      ),
                    ),
                ),
                  minimumSize: MaterialStateProperty.all<Size>(
                    Size(120, 20)
                  ),
              ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(
              "Let's Get Started",
              style: GoogleFonts.poppins(
                textStyle : TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w600,
                )
              ),
            ),
            Container(
              margin: EdgeInsets.only(bottom: 20),
              child: Image(
                  image: AssetImage(imagePath)
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Visibility(
                    visible: pageNumber > 1,
                    child: IconButton(
                        onPressed: () {
                          setState(() {
                            pageNumber -= 1;
                          });
                        },
                        icon: Icon(
                          Icons.arrow_back,
                          size: 30,
                        ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      '$pageNumber/$totalTutorialPage',
                      style: GoogleFonts.roboto(
                        textStyle : TextStyle(
                          fontSize: 20,

                        )
                      ),
                    ),
                  ),
                ),

                Expanded(
                  flex:1,
                  child: Visibility(
                    visible: pageNumber < totalTutorialPage,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          pageNumber += 1;
                        });
                      },
                      icon: Icon(
                        Icons.arrow_forward,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      )
    );
  }
}

