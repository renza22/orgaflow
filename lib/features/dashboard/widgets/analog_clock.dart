import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class AnalogClock extends StatefulWidget {
  const AnalogClock({super.key});

  @override
  State<AnalogClock> createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 2),
        color: Colors.white,
      ),
      child: CustomPaint(
        painter: ClockPainter(_currentTime),
      ),
    );
  }
}

class ClockPainter extends CustomPainter {
  final DateTime dateTime;

  ClockPainter(this.dateTime);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final center = Offset(centerX, centerY);
    final radius = min(centerX, centerY);

    // Hour hand
    final hourAngle = (dateTime.hour % 12 + dateTime.minute / 60) * 30 * pi / 180;
    final hourHandX = centerX + radius * 0.4 * sin(hourAngle);
    final hourHandY = centerY - radius * 0.4 * cos(hourAngle);
    canvas.drawLine(
      center,
      Offset(hourHandX, hourHandY),
      Paint()
        ..color = Colors.black
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Minute hand
    final minuteAngle = dateTime.minute * 6 * pi / 180;
    final minuteHandX = centerX + radius * 0.6 * sin(minuteAngle);
    final minuteHandY = centerY - radius * 0.6 * cos(minuteAngle);
    canvas.drawLine(
      center,
      Offset(minuteHandX, minuteHandY),
      Paint()
        ..color = Colors.black
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Second hand
    final secondAngle = dateTime.second * 6 * pi / 180;
    final secondHandX = centerX + radius * 0.7 * sin(secondAngle);
    final secondHandY = centerY - radius * 0.7 * cos(secondAngle);
    canvas.drawLine(
      center,
      Offset(secondHandX, secondHandY),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );

    // Center dot
    canvas.drawCircle(center, 4, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(ClockPainter oldDelegate) => true;
}
