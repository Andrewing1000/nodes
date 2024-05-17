import 'package:flutter/material.dart';
import 'package:nodes/models.dart';

class RenderedBoard extends StatefulWidget{
  const RenderedBoard({super.key});

  @override
  State createState(){
    return RendererBoardState();
  }
}

class RendererBoardState extends State<RenderedBoard>{

  List<Node> nodes = [];
  List<Edge> edges = [];

  Node? selected = null;
  Edge? selectedE = null;

  int mode = 0;
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      home: Scaffold(

        body: Stack(
          children: [
            CustomPaint(
              painter: Renderer(nodes: nodes, edges: edges),
            ),

            GestureDetector(
              onPanUpdate: (event){
                setState(() {
                  final selectedE = this.selectedE;
                  final selectedN = this.selected;
                  if(selectedE != null){
                    Offset point = Offset(event.globalPosition.dx,event.globalPosition.dy);
                    selectedE.moveRef(point);
                  }
                  else if(selectedN != null){
                    Offset point = Offset(event.globalPosition.dx,event.globalPosition.dy);

                    double difx = point.dx - selectedN.x;
                    double dify = point.dy - selectedN.y;

                    selectedN.x = point.dx;
                    selectedN.y = point.dy;
                    for(Edge edge in edges){
                      if( edge.nodeA == selectedN ||
                          edge.nodeB == selectedN){

                        Offset ref = edge.ref;

                        edge.moveRef(Offset(ref.dx+difx, ref.dy+dify));
                      }
                    }


                  }
                });
              },

              onTapDown: (event){
                setState(() {
                  double x = event.globalPosition.dx;
                  double y = event.globalPosition.dy;

                  if(mode != 0){
                    for(Edge edge in edges){
                      if(edge.isInside(x, y)){
                        selectedE?.deSelect();
                        selectedE = edge;
                        selectedE?.select();
                        return;
                      }
                    }
                    selectedE?.deSelect();
                    selectedE = null;
                  }
                  else{
                    for(Node node in nodes){
                      if(node.isInside(x, y)){
                        if(selected != null){

                          if(selected == node){

                            return;
                          }

                          edges.add(Edge(nodeA: selected??node, nodeB: node));
                          selected?.deSelect();
                          selected = null;
                        }
                        else{
                          selected = node;
                          node.select();
                        }
                        return;
                      }
                    }

                    if(selected != null){
                      selected?.deSelect();
                      selected = null;
                      return;
                    }
                    nodes.add(Node(x: x, y: y, R: 30));
                  }
                });
              },
            )
          ],
        ),


        bottomNavigationBar: BottomAppBar(
          child: Row(
            children: [

              IconButton(
                  onPressed: (){
                    setState(() {
                      mode = (mode+1)%2;

                      selected?.deSelect();
                      selectedE?.deSelect();

                      selected = null;
                      selectedE = null;
                    });
                  },
                  icon: CircleAvatar(
                    child: Icon(Icons.linear_scale, color: Colors.white,),
                    backgroundColor: mode==0? Color.fromARGB(200, 0, 0, 0) : Color.fromARGB(100, 0, 0, 0),
                  ),
              ),


              IconButton(

                  onPressed: (){
                    setState(() {
                      mode = (mode+1)%2;

                      selected?.deSelect();
                      selectedE?.deSelect();

                      selected = null;
                      selectedE = null;
                    });

                  },
                  icon: CircleAvatar(
                    child: Icon(Icons.circle_outlined, color: Colors.white,),
                    backgroundColor: mode>0? Color.fromARGB(200, 0, 0, 0) : Color.fromARGB(100, 0, 0, 0),
                  ),
              ),


              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: (){
                          setState(() {
                            nodes.clear();
                            edges.clear();

                            selected = null;
                            selectedE = null;
                          });
                        },
                        icon: Icon(Icons.delete),),


                      IconButton(
                          onPressed: (){
                            setState(() {
                              final selected = this.selected;
                              if(selected != null){
                                selected.deSelect();
                                nodes.remove(selected);

                                List<Edge> list = [];
                                for(Edge edge in edges){
                                  if(edge.nodeA != selected && edge.nodeB != selected){
                                    list.add(edge);
                                  }
                                }
                                edges = list;
                                this.selected = null;
                              }

                              final selectedE = this.selectedE;
                              if(selectedE != null){
                                selectedE.deSelect();
                                edges.remove(selectedE);
                                this.selectedE = null;
                              }
                            });
                          },
                          icon: Icon(Icons.clear)
                      ),
                    ],
                  ),
                ),
              ),




            ],
          ),
        ),
      ),
    );
  }
}


class Renderer extends CustomPainter{

  List<Node> nodes;
  List<Edge> edges;

  Renderer({required this.nodes, required this.edges});

  @override
  void paint(Canvas canvas, Size size) {
    for(Node node in nodes){
      node.draw(canvas);
    }

    for(Edge edge in edges){
      edge.draw(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }}