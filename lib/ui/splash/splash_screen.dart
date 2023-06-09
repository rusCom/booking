import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

import '../../models/main_application.dart';
import '../../models/profile.dart';
import '../../services/geo_service.dart';
import '../../services/map_markers_service.dart';
import '../main_screen.dart';
import '../profile/profile_login_screen.dart';
import '../utils/core.dart';
import '../widgets/background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final String TAG = (SplashScreen).toString(); // ignore: non_constant_identifier_names
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String state = "init";
  double posLogoBottom = 0;
  double posLogoLeft = 0;
  final Widget background = const Background();

  late Animation<double> _logoScaleAnimation;
  late AnimationController _logoScaleAnimationController;

  late Animation<double> _logoMoveAnimationBottom, _logoMoveAnimationLeft;
  late AnimationController _logoMoveAnimationControllerBottom, _logoMoveAnimationControllerLeft;

  startTime() async {
    DebugPrint().log(TAG, "startTime", "start MainApplication().init(context)");
    await MainApplication().init(context);
    if (!mounted) return;
    await MapMarkersService().init(context);
    DebugPrint().log(TAG, "startTime", "start profileAuth()");
    await profileAuth();
  }

  profileAuth() async {
    bool isAuth = await Profile().auth();
    if (isAuth) {
      DebugPrint().log(TAG, "profileAuth", "success");
      MainApplication().nearbyRoutePoint = (await GeoService().nearby())!;
      setState(() {
        state = "main";
      });
    } else {
      setState(() {
        state = "login";
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _logoScaleAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    Tween _logoScaleTween = Tween<double>(begin: 1, end: 0.8);
    _logoScaleAnimation = _logoScaleTween.animate(_logoScaleAnimationController) as Animation<double>;
    _logoScaleAnimationController.forward();
    _logoScaleAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        // DebugPrint().log(TAG, "logoScaleAnimationController.StatusListener", "AnimationStatus.completed state = $state");
        if (state == "init") {
          _logoScaleAnimationController.forward();
        } else if (state == "main") {
          Navigator.pushReplacement(
              context, PageTransition(type: PageTransitionType.fade, child: MainScreen(), duration: const Duration(seconds: 2)));
          // MainApplication().startTimer();
        } else {
          _logoMoveAnimationControllerBottom.forward();
          _logoMoveAnimationControllerLeft.forward();
        }
      } else if (status == AnimationStatus.completed) _logoScaleAnimationController.reverse();
    });

    startTime();
    initLogoMove();
  }

  initLogoMove() {
    int moveDuration = 500;
    _logoMoveAnimationControllerBottom = AnimationController(vsync: this, duration: Duration(milliseconds: moveDuration));
    Tween _logoMoveTweenBottom = Tween<double>(begin: 1 / 3, end: 1 - 1 / 3);
    _logoMoveAnimationBottom = _logoMoveTweenBottom.animate(_logoMoveAnimationControllerBottom) as Animation<double>;
    _logoMoveAnimationBottom.addListener(() {
      setState(() {});
    });

    _logoMoveAnimationControllerLeft = AnimationController(vsync: this, duration: Duration(milliseconds: moveDuration));
    Tween _logoMoveTweenLeft = Tween<double>(begin: 1 / 4, end: 1 / 2.5);
    _logoMoveAnimationLeft = _logoMoveTweenLeft.animate(_logoMoveAnimationControllerLeft) as Animation<double>;
    _logoMoveAnimationLeft.addListener(() {
      setState(() {});
    });

    _logoMoveAnimationControllerLeft.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacement(context,
            PageTransition(type: PageTransitionType.fade, child: ProfileLoginScreen(background: background), duration: const Duration(seconds: 1)));
        // Navigator.pushReplacement(context, PageTransition(type: PageTransitionType.fade, child: ProfileRegistrationScreen(background: background),duration: Duration(seconds: 2)));
      }
    });
  }

  @override
  void dispose() {
    _logoMoveAnimationControllerBottom?.dispose();
    _logoMoveAnimationControllerLeft?.dispose();
    _logoScaleAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: <Widget>[
          background,
          Positioned(
            bottom: MediaQuery.of(context).size.height * _logoMoveAnimationBottom.value,
            left: MediaQuery.of(context).size.width * _logoMoveAnimationLeft.value,
            child: ScaleTransition(
              scale: _logoScaleAnimation,
              child: Image.asset(
                "assets/images/splash_logo.png",
                width: MediaQuery.of(context).size.width / 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
