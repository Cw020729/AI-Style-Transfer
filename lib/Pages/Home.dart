import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Home extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return Scaffold(
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget> [
                  Image(
                      image: AssetImage('assets/home_image_1.png')
                  ),
                  SizedBox(width: 50),
                  Image(
                      image: AssetImage('assets/home_image_2.png')
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Image(
                      image: AssetImage('assets/home_arrow_right.png')
                  ),
                  Container(
                    padding: EdgeInsets.only(top:50),
                    margin: EdgeInsets.only(bottom: 30),
                    child: Image(
                        image: AssetImage('assets/home_image_3.png')
                    ),
                  ),
                  Image(
                      image: AssetImage('assets/home_arrow_left.png')
                  ),
                ],
              ),
              Text(
                "Welcome to",
                style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 4),
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.25),
                        ),
                      ],
                    )
                ),
              ),
              Text(
                "AI Style Tranfer",
                style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 4),
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.25),
                        ),
                      ],
                    )
                ),
              ),
              Text(
                "Application",
                style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 4),
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.25),
                        ),
                      ],
                    )
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: TextButton(
                  onPressed: (){
                    Navigator.pushNamed(context, '/tutorial');
                  },
                  child: Text(
                    "START TUTORIAL",
                    style: GoogleFonts.roboto(
                      textStyle : TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                        Color(0xFF1573FE),
                      ),
                      minimumSize: WidgetStateProperty.all<Size>(
                        Size(350, 50),
                      ),
                      shape: WidgetStateProperty.all<OutlinedBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: Color(0xFF1573FE),
                            width: 1,
                          ),
                        ),
                      )
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Already used before? ",
                    style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400
                        )
                    ),
                  ),
                  TextButton(
                    onPressed: (){
                      Navigator.pushNamed(context, '/camera');
                    },
                    child: Text(
                      "Skip tutorial",
                      style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF1573FE),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF1573FE),
                        ),
                      ),
                    ),
                    style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all<Color>(
                            Colors.transparent
                        )
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