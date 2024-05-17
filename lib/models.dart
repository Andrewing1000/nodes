import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math';

class Node {
  double x;
  double y;
  double dx;
  double dy;
  double r;
  double R;
  double t;
  String label;
  Color color;
  bool selected = false;
  bool isInitial;
  bool isFinal;
  bool isVisible; // Add visibility flag
  int index;

  static const Color colorNormal = Colors.black;
  static const Color colorSelected = Colors.greenAccent;
  static const Color colorInitial = Colors.orange;
  static const Color colorFinal = Colors.red;

  Node({
    required this.x,
    required this.y,
    this.dx = 0,
    this.dy = 0,
    this.R = 30, // Set default radius to 30
    this.t = 0,
    this.label = '',
    this.isInitial = false,
    this.isFinal = false,
    this.isVisible = false, // Initialize visibility
    required this.index,
  })  : r = R,
        color = colorNormal;

  double getDistanceToCenter(double x, double y) {
    double dx = pow(this.x - x, 2).toDouble();
    double dy = pow(this.y - y, 2).toDouble();

    return sqrt(dx + dy);
  }

  double getDistanceToBorder(double x, double y) {
    return getDistanceToCenter(x, y) - r;
  }

  bool isInside(double x, double y) {
    return getDistanceToBorder(x, y) <= 0;
  }

  void select() {
    selected = true;
  }

  void deSelect() {
    selected = false;
  }

  void update() {}

  void toggleVisibility() {
    isVisible = !isVisible;
  }

  void draw(Canvas canvas) {
    if (!isVisible) return; // Do not draw if not visible

    Paint paint = Paint();
    paint.color = selected ? colorSelected : colorNormal;
    paint.strokeWidth = isInitial || isFinal ? 10 : 0;
    paint.style = isInitial || isFinal ? PaintingStyle.stroke : PaintingStyle.fill;

    if (isInitial) {
      paint.color = colorInitial;
    } else if (isFinal) {
      paint.color = colorFinal;
    }

    canvas.drawCircle(Offset(x, y), r, paint);

    if(isInitial || isFinal){
      paint.color = selected ? colorSelected : colorNormal;
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), r, paint);
    }


    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: r / 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }
}


class Edge {
  Node nodeA;
  Node nodeB;
  Offset a;
  Offset b;
  Offset ref;
  bool isLine = false;
  bool selected = false;
  String label;
  bool isSelfConnection;

  Edge({
    required this.nodeA,
    required this.nodeB,
    this.label = '',
    this.isSelfConnection = false,  // Initialize self-connection flag
  })  : a = Offset(nodeA.x, nodeA.y),
        b = Offset(nodeB.x, nodeB.y),
        ref = Offset((nodeA.x + nodeB.x) / 2, (nodeA.y + nodeB.y) / 2);

  double norm(Offset point) {
    double x = point.dx;
    double y = point.dy;
    return sqrt(pow(x, 2) + pow(y, 2));
  }

  Offset add(Offset a, Offset b) {
    return Offset(a.dx + b.dx, a.dy + b.dy);
  }

  Offset multiply(double k, Offset b) {
    return Offset(b.dx * k, b.dy * k);
  }

  Offset minus(Offset a, Offset b) {
    return add(a, multiply(-1, b));
  }

  Offset unitary(Offset vector) {
    double vectorNorm = norm(vector);

    if (vectorNorm.abs() < 1e-6) {
      throw 'Unitary vector for 0 not allowed';
    }

    return multiply(1 / vectorNorm, vector);
  }

  Offset cRotation(Offset vector) {
    return Offset(vector.dy, -vector.dx);
  }

  double dot(Offset a, Offset b) {
    return a.dx * b.dx + a.dy * b.dy;
  }

  Offset getP() {
    return multiply(1 / 2, add(b, a));
  }

  Offset getDir() {
    Offset dif = minus(b, a);
    return unitary(dif);
  }

  Offset getDirT() {
    return cRotation(getDir());
  }

  double getD(Offset point) {
    Offset dir = getDir();
    Offset dirP = getDirT();
    Offset p = getP();

    Offset rel = minus(point, p);

    double l = norm(minus(b, a)) / 2;
    double h = dot(rel, dirP).abs();
    double w = dot(rel, dir).abs();

    return (pow(l, 2) - pow(h, 2) - pow(w, 2)) / (2 * h);
  }

  void moveRef(Offset point) {
    if (norm(minus(a, point)) < 0.95 * nodeA.R) {
      return;
    }

    if (norm(minus(b, point)) < 0.95 * nodeB.R) {
      return;
    }

    double d = getD(point);
    if (d >= 0) {
      ref = point;
    }
  }

  Offset getCenter() {
    double k = 1;

    Offset p = getP();
    Offset rel = minus(ref, p);

    double ind = dot(getDirT(), rel);
    if (ind < 0) {
      k = -1;
    } else if (ind.abs() < 1e-6) {
      return getP();
    }

    return minus(getP(), multiply(k * getD(ref), getDirT()));
  }

  double getRadius() {
    Offset rad = minus(a, getCenter());
    return norm(rad);
  }

  bool isInside(double x, double y) {
    Offset point = Offset(x, y);
    if (isSelfConnection) {
      // Check if the point is inside the self-loop

        // Draw the self-loop circle
      double dx = point.dx - (a.dx+30);
      double dy = point.dy - (a.dy-30);

      double rad = sqrt(dx * dx + dy * dy);
      return (rad - 30).abs() <= 10; // Adjust as needed for accuracy
    }
    if (isLine) {
      double d = dot(minus(point, a), getDirT());
      if (d.abs() < 10) {
        if (x <= min(a.dx, b.dx) || x >= max(a.dx, b.dx)) {
          return false;
        }
        if (y <= min(a.dy, b.dy) || x >= max(a.dy, b.dy)) {
          return false;
        }
        print("inside");
        return true;
      }
      return false;
    } else {
      double d = norm(minus(point, getCenter()));
      if ((d - getRadius()).abs() < 10) {
        print("inside");
        return true;
      } else {
        return false;
      }
    }
  }

  void select() {
    selected = true;
  }

  void deSelect() {
    selected = false;
  }

  void draw(Canvas canvas) {
    a = Offset(nodeA.x, nodeA.y);
    b = Offset(nodeB.x, nodeB.y);

    Paint paint = Paint();
    paint.color = selected ? Colors.greenAccent : Colors.black;
    paint.strokeWidth = 5;
    paint.style = PaintingStyle.stroke;


    if(nodeA == nodeB){
      isSelfConnection = true;
    }
    else{
      isSelfConnection = false;
    }


    if (isSelfConnection) {
      // Draw self-loop
      double radius = 30;  // Radius of the self-loop
      Offset center = Offset(a.dx + radius, a.dy - radius);  // Center of the self-loop

      // Draw the self-loop circle
      canvas.drawCircle(center, radius, paint);

      // Draw the arrow within the self-loop
      // Draw the label in the center of the self-loop

      drawLabel(canvas, center);
      return;
    }

    if (getCenter() == getP() || getRadius() > 1000) {
      isLine = true;
      canvas.drawLine(a, b, paint);
      drawArrow(canvas, paint, a, b);
      drawLabel(canvas, getP());
      return;
    }

    isLine = false;

    Rect rect = Rect.fromCircle(center: getCenter(), radius: getRadius());

    Offset ra = minus(a, getCenter());
    double beginAngle = atan2(ra.dy, ra.dx);

    Offset rb = minus(b, getCenter());
    double endAngle = atan2(rb.dy, rb.dx);

    double sweep = endAngle - beginAngle;
    if (sweep < 0) {
      sweep += 2 * pi;
    }
    if (sweep > pi) {
      sweep -= 2 * pi;
    }

    canvas.drawArc(rect, beginAngle, sweep, false, paint);

    // Draw the arrow within the arc
    drawArrowWithinArc(canvas, paint, rect, beginAngle, sweep);
    drawLabel(canvas, getP());
  }

  void drawArrowWithinArc(Canvas canvas, Paint paint, Rect rect, double beginAngle, double sweep) {
    // Calculate the midpoint angle of the arc
    double midAngle = beginAngle + sweep / 2;
    if (midAngle > 2 * pi) {
      midAngle -= 2 * pi;
    }

    // Calculate the midpoint of the arc
    Offset center = rect.center;
    double radius = rect.width / 2;
    Offset midPoint = Offset(
      center.dx + radius * cos(midAngle),
      center.dy + radius * sin(midAngle),
    );

    // Calculate the direction of the arrow
    Offset dir = unitary(minus(a, b));
    Offset perp = Offset(-dir.dy, dir.dx);

    // Calculate points for the arrow
    double arrowLength = 15;
    double arrowWidth = 10;
    Offset arrowTip = midPoint;
    Offset arrowBase1 = add(midPoint, multiply(arrowWidth / 2, perp));
    Offset arrowBase2 = add(midPoint, multiply(-arrowWidth / 2, perp));
    Offset arrowTail = add(midPoint, multiply(-arrowLength, dir));

    // Draw the arrow
    Path arrowPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(arrowBase1.dx, arrowBase1.dy)
      ..lineTo(arrowTail.dx, arrowTail.dy)
      ..lineTo(arrowBase2.dx, arrowBase2.dy)
      ..close();

    canvas.drawPath(arrowPath, paint);
  }

  void drawArrow(Canvas canvas, Paint paint, Offset start, Offset end) {
    // Calculate the midpoint
    Offset midPoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    Offset dir = unitary(minus(end, start));
    Offset perp = cRotation(dir);

    // Calculate points for the arrow
    double arrowLength = 15;
    double arrowWidth = 10;
    Offset arrowTip = add(midPoint, multiply(arrowLength, dir));
    Offset arrowBase1 = add(midPoint, multiply(arrowWidth / 2, perp));
    Offset arrowBase2 = add(midPoint, multiply(-arrowWidth / 2, perp));

    // Draw the arrow
    Path arrowPath = Path()
      ..moveTo(midPoint.dx, midPoint.dy)
      ..lineTo(arrowBase1.dx, arrowBase1.dy)
      ..lineTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(arrowBase2.dx, arrowBase2.dy)
      ..close();

    canvas.drawPath(arrowPath, paint);
  }

  void drawLabel(Canvas canvas, Offset position) {
    // Draw the label

    if(label.toString() == '1'){
      position = Offset(position .dx + 5, position .dy);
    }
    else{
      position  = Offset(position .dx - 5, position .dy);
    }


    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
    );
  }
}