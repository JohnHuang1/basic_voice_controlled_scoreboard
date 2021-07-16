import 'package:flutter/material.dart';

class JarvisWidget extends StatefulWidget {
  final bool show;
  final bool mic;

  const JarvisWidget({Key? key, required this.show, required this.mic}) : super(key: key);

  @override
  _JarvisWidgetState createState() => _JarvisWidgetState();
}

class _JarvisWidgetState extends State<JarvisWidget> with TickerProviderStateMixin{
  late AnimationController controller;
  late AnimationController micController;

  @override
  void initState() {
    super.initState();
    micController = AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    controller = AnimationController(vsync: this, duration: Duration(milliseconds: 200));
  }

  @override
  void didUpdateWidget(covariant JarvisWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(widget.show){
      controller.forward();
    } else {
      controller.reverse();
    }
    if(widget.mic){
      micController.forward();
    } else {
      micController.reverse();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    micController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween(
        begin: Offset(0.0, -4.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticInOut)),
      child: ScaleTransition(
        scale: Tween(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(parent: micController, curve: Curves.easeInOut)),
        child: Container(
          child: Text("Jarvis Activated", style: TextStyle(color: Colors.white, fontSize: 30),),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.black.withOpacity(0.6),
          ),
          padding: EdgeInsets.all(30),
          margin: EdgeInsets.all(20),
        )
      )
    );
  }
}
