import 'dart:ui';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class Node{
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


  static const Color colorNormal = Colors.black;
  static const Color colorSelected = Colors.greenAccent;

  Node({required this.x,
        required this.y,
        this.dx = 0,
        this.dy = 0,
        required this.R,
        this.t = 0,
        this.label = '',
  }):
  r = R,
  color = colorNormal;


  double getDistanceToCenter(double x, double y){
    double dx = pow(this.x - x, 2).toDouble();
    double dy = pow(this.y - y, 2).toDouble();

    return sqrt(dx + dy);
  }

  double getDistanceToBorder(double x, double y){
    return getDistanceToCenter(x, y) - r;
  }

  bool isInside(double x, double y){
    return getDistanceToBorder(x, y) <= 0;
  }

  void select(){
    selected = true;
  }

  void deSelect(){
    selected = false;
  }

  void update(){

  }

  void draw(Canvas canvas){

    Paint paint = Paint();
    if(this.selected) {
      paint.color = colorSelected;
    }
    else {
      paint.color = colorNormal;
    }
    paint.strokeWidth = 0;
    paint.style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), r, paint);
  }

}


class Edge{

  Node nodeA;
  Node nodeB;
  Offset a;
  Offset b;
  Offset ref;
  bool isLine = false;
  bool selected = false;

  Edge({
        required this.nodeA,
        required this.nodeB,}):
  a = Offset(nodeA.x, nodeA.y),
  b = Offset(nodeB.x, nodeB.y),
  ref = Offset((nodeA.x+nodeB.x)/2,(nodeA.y+nodeB.y)/2);


  double norm(Offset point){
    double x = point.dx;
    double y = point.dy;
    return sqrt(pow(x, 2) + pow(y, 2));
  }

  Offset add(Offset a, Offset b){
    return Offset(a.dx + b.dx, a.dy + b.dy);
  }

  Offset multiply(double k, Offset b){
    return Offset(b.dx*k, b.dy*k);
  }

  Offset minus(Offset a, Offset b){
    return add(a, multiply(-1, b));
  }

  Offset unitary(Offset vector){
    double vectorNorm  = norm(vector);

    if(vectorNorm.abs() < 1e-6){
      throw 'Unitary vector for 0 not allowed';
    }

    return(multiply(1/vectorNorm, vector));
  }

  Offset cRotation(Offset vector){
    return Offset(vector.dy, -vector.dx);
  }

  double dot(Offset a, Offset b){
    return a.dx*b.dx + a.dy*b.dy;
  }

  Offset getP(){
    return multiply(1/2, add(b, a));
  }

  Offset getDir(){
    Offset dif = minus(b, a);
    return unitary(dif);
  }

  Offset getDirT(){
    return cRotation(getDir());
  }

  double getD(Offset point){

    Offset dir = getDir();
    Offset dirP = getDirT();
    Offset p = getP();

    Offset rel = minus(point, p);

    double l = norm(minus(b, a))/2;
    double h = dot(rel, dirP).abs();
    double w = dot(rel, dir).abs();

    return (pow(l,2) - pow(h,2) - pow(w, 2))/(2*h);
  }

  void moveRef(Offset point){

    if(norm(minus(a, point)) < 0.95*nodeA.R){
      return;
    }

    if(norm(minus(b, point)) < 0.95*nodeB.R){
      return;
    }

    double d = getD(point);
    if(d >= 0){
      ref = point;
    }
  }

  Offset getCenter(){
    double k = 1;

    Offset p = getP();
    Offset rel = minus(ref, p);

    double ind = dot(getDirT(), rel);
    if(ind < 0){
      k = -1;
    }
    else if(ind.abs() < 1e-6){
      return getP();
    }


    return minus(getP(), multiply(k*getD(ref), getDirT()));
  }

  double getRadius(){
    Offset rad = minus(a, getCenter());
    return norm(rad);
  }

  bool isInside(double x, double y){
    Offset point = Offset(x, y);
    if(isLine){
      double d = dot(minus(point, a), getDirT());
      if(d.abs() < 10){
        if(x <= min(a.dx, b.dx) || x >= max(a.dx, b.dx)){
          return false;
        }
        if(y <= min(a.dy, b.dy) || x >= max(a.dy, b.dy)){
          return false;
        }
        print("inside");
        return true;
      }
      return false;
    }
    else{
      double d = norm(minus(point, getCenter()));
      if((d - getRadius()).abs() < 10){
        print("inside");
        return true;
      }
      else{
        return false;
      }
    }
  }



  void select(){
    selected = true;
  }

  void deSelect(){
    selected = false;
  }

  void draw(Canvas canvas){
    a = Offset(nodeA.x, nodeA.y);
    b = Offset(nodeB.x, nodeB.y);


    Paint paint = Paint();
    paint.color = selected? Colors.greenAccent: Colors.black;
    paint.strokeWidth = 5;
    paint.style = PaintingStyle.stroke;

    if(getCenter() == getP() || getRadius() > 1000){
      isLine = true;
      canvas.drawLine(a, b, paint);
      return;
    }

    isLine = false;

    Rect rect = Rect.fromCircle(center: getCenter(), radius: getRadius());

    Offset ra = minus(a, getCenter());
    double beginAngle = atan2(ra.dy, ra.dx);

    if(beginAngle < 0){
      beginAngle = beginAngle.abs();
    }
    else{
      beginAngle = 2*pi - beginAngle;
    }

    // double yy = getRadius()*sin(-beginAngle);
    // double xx = getRadius()*cos(-beginAngle);
    // canvas.drawLine(getCenter(), add(getCenter(), Offset(xx, yy)), paint);

    Offset rb = minus(b, getCenter());
    double endAngle = atan2(rb.dy, rb.dx);
    if(endAngle < 0){
      endAngle = endAngle.abs();
    }
    else{
      endAngle = 2*pi - endAngle;
    }

    Offset rm = minus(ref, getCenter());
    double middleAngle = atan2(rm.dy, rm.dx);
    if(middleAngle < 0){
      middleAngle = middleAngle.abs();
    }
    else{
      middleAngle = 2*pi - middleAngle;
    }

    double sweep =  endAngle - beginAngle;


    if(sweep.abs() <= pi){
      //canvas.drawArc(rect, max(endAngle, beginAngle), sweep.abs(), false, paint);
      //canvas.drawArc(rect, 0, 2*pi, false, paint);
      canvas.drawArc(rect, -beginAngle, sweep.abs(), false, paint);
    }
    else{
      canvas.drawArc(rect, -endAngle, (2*pi - sweep.abs()), false, paint);
    }



  }

}