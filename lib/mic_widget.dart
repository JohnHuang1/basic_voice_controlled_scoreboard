import 'package:flutter/material.dart';

class MicWidget extends StatefulWidget {
  final bool expanded;

  const MicWidget({Key? key, required this.expanded}) : super(key: key);

  @override
  _MicWidgetState createState() => _MicWidgetState();
}

class _MicWidgetState extends State<MicWidget>
    with TickerProviderStateMixin {
  late AnimationController showController;
  late AnimationController repeatController;

  @override
  void initState() {
    super.initState();
    showController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    repeatController = AnimationController(vsync: this, duration: Duration(milliseconds: 1500));
  }

  @override
  void didUpdateWidget(covariant MicWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded) {
      showController.forward();
    } else {
      repeatController.stop();
      showController.reverse();
    }
  }

  @override
  void dispose() {
    super.dispose();
    showController.dispose();
    repeatController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(parent: showController, curve: Curves.easeInOut),
      )..addStatusListener((status) {
        if(status == AnimationStatus.completed){
          repeatController.forward();
        }
      }),
      child: ScaleTransition(
        scale: Tween(
          begin: 1.0,
          end: 1.2,
        ).animate(
          CurvedAnimation(parent: repeatController, curve: Curves.easeInOut)
        )..addStatusListener((status) {
          if(status==AnimationStatus.completed){
            repeatController.reverse();
          } else if(status == AnimationStatus.dismissed){
            repeatController.forward();
          }
        }),
        child: Container(
          child: Icon(
            Icons.mic,
            size: 140,
              color: Colors.white,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.all(10),
        )
      ),
    );
  }
}
