import 'package:flutter/material.dart';
import 'package:nodes/models.dart';  // Assuming models.dart contains your Node and Edge classes
import 'dart:async';

import 'DFA.dart';

class RenderedBoard extends StatefulWidget {
  const RenderedBoard({super.key});

  @override
  State createState() {
    return RendererBoardState();
  }
}

class RendererBoardState extends State<RenderedBoard> {
  DFA dfa = DFA("1011");  // Initialize with a binary string
  Node? selected = null;
  Edge? selectedE = null;
  int mode = 0;
  int connectionInput = 0;  // Default connection input is 0
  bool creatingSelfEdge = false;  // Flag for creating self-edges
  bool isValidationRunning = false;

  void startValidation() async {
    setState(() {
      isValidationRunning = true;
    });

    bool isValid = true;

    for (int i = 0; i < dfa.nodes.length; i++) {
      Node currentNode = dfa.nodes[i];

      if (dfa.transferF[i][0] == null || dfa.transferF[i][1] == null) {
        isValid = false;
        break;
      }

      if (dfa.transferF[i][0] != null) {
        Node nextNode = dfa.nodes[dfa.transferF[i][0]!];
        String nextState0 = nextNode.label;
        String expectedState0 = currentNode.label == "_" ? "0" : currentNode.label + '0';
        if (expectedState0.length > dfa.nodes.length - 1) expectedState0 = expectedState0.substring(1);
        if (nextState0 != expectedState0 && nextState0 != currentNode.label) {
          isValid = false;
          break;
        }
      }

      if (dfa.transferF[i][1] != null) {
        Node nextNode = dfa.nodes[dfa.transferF[i][1]!];
        String nextState1 = nextNode.label;
        String expectedState1 = currentNode.label == "_" ? "1" : currentNode.label + '1';
        if (expectedState1.length > dfa.nodes.length - 1) expectedState1 = expectedState1.substring(1);
        if (nextState1 != expectedState1 && nextState1 != currentNode.label) {
          isValid = false;
          break;
        }
      }
    }

    setState(() {
      isValidationRunning = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Resultado de Validación"),
        content: Text(isValid ? "¡La solución es correcta!" : "La solución es incorrecta."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomPaint(
            painter: Renderer(dfa: dfa),
          ),
          GestureDetector(
            onPanUpdate: (event) {
              setState(() {
                final selectedE = this.selectedE;
                final selectedN = this.selected;
                if (selectedE != null) {
                  Offset point = Offset(event.localPosition.dx, event.localPosition.dy);
                  selectedE.moveRef(point);
                } else if (selectedN != null) {
                  Offset point = Offset(event.localPosition.dx, event.localPosition.dy);
                  double difx = point.dx - selectedN.x;
                  double dify = point.dy - selectedN.y;
                  selectedN.x = point.dx;
                  selectedN.y = point.dy;
                  for (Edge edge in dfa.edges) {
                    if (edge.nodeA == selectedN || edge.nodeB == selectedN) {
                      Offset ref = edge.ref;
                      edge.moveRef(Offset(ref.dx + difx, ref.dy + dify));
                    }
                  }
                }
              });
            },
            onTapDown: (event) {
              setState(() {
                double x = event.localPosition.dx;
                double y = event.localPosition.dy;

                if (creatingSelfEdge && selected != null) {
                  dfa.connect(selected!.index, selected!.index, connectionInput);
                  creatingSelfEdge = false;
                  selected?.deSelect();
                  selected = null;
                  return;
                }

                if (mode != 0) {
                  for (Edge edge in dfa.edges) {
                    if (edge.isInside(x, y)) {
                      selectedE?.deSelect();
                      selectedE = edge;
                      selectedE?.select();
                      return;
                    }
                  }
                  selectedE?.deSelect();
                  selectedE = null;
                } else {
                  for (Node node in dfa.nodes) {
                    if (node.isInside(x, y)) {
                      if (selected != null) {
                        if (selected == node) {
                          return;
                        }
                        dfa.connect(selected!.index, node.index, connectionInput);
                        selected?.deSelect();
                        selected = null;
                      } else {
                        selected = node;
                        node.select();
                      }
                      return;
                    }
                  }
                  if (selected != null) {
                    selected?.deSelect();
                    selected = null;
                    return;
                  }
                  // Add next invisible node to the screen
                  Node? nextNode = dfa.nodes.firstWhereOrNull((node) => !node.isVisible);
                  if (nextNode != null) {
                    nextNode.x = x;
                    nextNode.y = y;
                    dfa.setNodeVisible(nextNode.index, true);
                  }
                }
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  mode = (mode + 1) % 2;
                  selected?.deSelect();
                  selectedE?.deSelect();
                  selected = null;
                  selectedE = null;
                });
              },
              icon: CircleAvatar(
                child: Icon(Icons.linear_scale, color: Colors.white),
                backgroundColor: mode == 0 ? Color.fromARGB(200, 0, 0, 0) : Color.fromARGB(100, 0, 0, 0),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  mode = (mode + 1) % 2;
                  selected?.deSelect();
                  selectedE?.deSelect();
                  selected = null;
                  selectedE = null;
                });
              },
              icon: CircleAvatar(
                child: Icon(Icons.circle_outlined, color: Colors.white),
                backgroundColor: mode > 0 ? Color.fromARGB(200, 0, 0, 0) : Color.fromARGB(100, 0, 0, 0),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  dfa.nodes.forEach((node) {
                    node.isVisible = false;
                  });
                  dfa.edges.clear();
                  selected = null;
                  selectedE = null;
                });
              },
              icon: Icon(Icons.delete),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  if (selected != null) {
                    dfa.setNodeVisible(selected!.index, false);
                    selected = null;
                  }
                  if (selectedE != null) {
                    dfa.removeEdge(selectedE!.nodeA.index, int.parse(selectedE!.label));
                    selectedE = null;
                  }
                });
              },
              icon: Icon(Icons.clear),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  creatingSelfEdge = !creatingSelfEdge;
                });
              },
              icon: CircleAvatar(
                child: Icon(Icons.loop, color: Colors.white),
                backgroundColor: creatingSelfEdge ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 30),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                connectionInput = 0;
              });
            },
            child: Text('0'),
            backgroundColor: connectionInput == 0 ? Colors.greenAccent : Colors.grey,
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                connectionInput = 1;
              });
            },
            child: Text('1'),
            backgroundColor: connectionInput == 1 ? Colors.greenAccent : Colors.grey,
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              startValidation();
            },
            child: Icon(Icons.check),
            backgroundColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}

class Renderer extends CustomPainter {
  DFA dfa;

  Renderer({required this.dfa});

  @override
  void paint(Canvas canvas, Size size) {
    dfa.draw(canvas);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (E element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
