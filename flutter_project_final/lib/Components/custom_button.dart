import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
   CustomButton({super.key, 
   required this.width, 
   required this.height,
   required this.onTap,
    required this.buttonName, 
     this.fontSize,
      this.ButtonColor,
       this.fontColor, 
      });
  final double width,height;
  final String buttonName;
  final Function() onTap;
  final Color? ButtonColor;
  final Color? fontColor;
  final double? fontSize;


  @override
  Widget build(BuildContext context) {
    return GestureDetector (
      onTap: onTap,
      child:  Container(
              height:height,
              width: width,
              decoration: BoxDecoration(
                color: ButtonColor!=null? ButtonColor:const Color.fromARGB(255, 248, 240, 240) ,
                borderRadius: BorderRadius.circular(30),
                // border: Border.all(color: Colors.white),
              ),
              child:  Center(child: Text(buttonName,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: fontColor,
              ),
              ),
              ),
              
            ),
    );
  }
}