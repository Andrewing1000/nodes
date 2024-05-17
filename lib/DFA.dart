
import 'dart:ui';

import 'models.dart';
class DFA {
  List<Node> nodes;
  List<Edge> edges;
  List<List<int?>> transferF;

  DFA(String s)
      : nodes = [],
        edges = [],
        transferF = List.generate(s.length + 1, (_) => List.filled(2, null)) {
    // Initialize nodes
    double initialX = 100;
    double initialY = 100;
    double spacing = 100; // Spacing to account for the radius

    nodes.add(Node(x: initialX, y: initialY, R: 30, label: "_", isInitial: true, index: 0));
    for (int i = 0; i < s.length; i++) {
      nodes.add(Node(x: initialX + (i + 1) * spacing, y: initialY, R: 30, label: s.substring(0, i + 1), index: i + 1));
    }
    nodes.last.isFinal = true; // Mark the final node
  }

  void connect(int a, int b, int input) {
    // Remove existing edge with the same input if any
    edges.removeWhere((edge) => edge.nodeA.index == a && edge.label == input.toString());

    // Create new edge and update transfer function
    edges.add(Edge(nodeA: nodes[a], nodeB: nodes[b], label: input.toString()));
    transferF[a][input] = b;
  }

  void removeEdge(int a, int input) {
    // Remove the edge and update the transfer function
    edges.removeWhere((edge) => edge.nodeA.index == a && edge.label == input.toString());
    transferF[a][input] = null;
  }

  void setNodeVisible(int index, bool visible) {
    if (index >= 0 && index < nodes.length) {
      nodes[index].isVisible = visible;
      if (!visible) {
        // Remove all edges connected to this node
        edges.removeWhere((edge) => edge.nodeA.index == index || edge.nodeB.index == index);

        // Update the transfer function
        for (int i = 0; i < transferF.length; i++) {
          if (transferF[i][0] == index) transferF[i][0] = null;
          if (transferF[i][1] == index) transferF[i][1] = null;
        }
      }
    }
  }

  void makeAllNodesVisible() {
    for (var node in nodes) {
      node.isVisible = true;
    }
  }

  void makeAllNodesInvisible() {
    for (var node in nodes) {
      node.isVisible = false;
    }
    edges.clear();
    for (int i = 0; i < transferF.length; i++) {
      transferF[i][0] = null;
      transferF[i][1] = null;
    }
  }

  bool solutionValidator() {
    for (int i = 0; i < nodes.length; i++) {
      String currentState = nodes[i].label;
      if (transferF[i][0] != null) {
        String nextState0 = nodes[transferF[i][0]!].label;
        String expectedState0 = currentState == "_" ? "0" : currentState + '0';
        if (expectedState0.length > nodes.length - 1) expectedState0 = expectedState0.substring(1);
        if (nextState0 != expectedState0 && nextState0 != currentState) {
          return false;
        }
      }
      if (transferF[i][1] != null) {
        String nextState1 = nodes[transferF[i][1]!].label;
        String expectedState1 = currentState == "_" ? "1" : currentState + '1';
        if (expectedState1.length > nodes.length - 1) expectedState1 = expectedState1.substring(1);
        if (nextState1 != expectedState1 && nextState1 != currentState) {
          return false;
        }
      }
    }
    return true;
  }

  void draw(Canvas canvas) {
    // Draw edges first
    for (var edge in edges) {
      edge.draw(canvas);
    }

    // Draw nodes on top of edges
    for (var node in nodes) {
      node.draw(canvas);
    }
  }
}
