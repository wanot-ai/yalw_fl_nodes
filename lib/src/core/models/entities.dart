import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

import 'package:fl_nodes/fl_nodes.dart';
import 'package:fl_nodes/src/core/controllers/node_editor/project.dart';
import 'package:fl_nodes/src/core/controllers/node_editor/runner.dart';

typedef FromTo = ({String from, String to, String fromPort, String toPort});

/// A class representing the state of a link.
class LinkState {
  final bool isHovered; // Not saved as it is only used during rendering

  LinkState({
    this.isHovered = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkState &&
          runtimeType == other.runtimeType &&
          isHovered == other.isHovered;

  @override
  int get hashCode => isHovered.hashCode;
}

/// A link is a connection between two ports.
final class Link {
  final String id;
  final FromTo fromTo;
  final LinkState state = LinkState();

  Link({
    required this.id,
    required this.fromTo,
  });

  Link copyWith({
    String? id,
    FromTo? fromTo,
    List<Offset>? joints,
  }) {
    return Link(
      id: id ?? this.id,
      fromTo: fromTo ?? this.fromTo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': fromTo.from,
      'to': fromTo.to,
      'fromPort': fromTo.fromPort,
      'toPort': fromTo.toPort,
    };
  }

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      id: json['id'],
      fromTo: (
        from: json['from'],
        to: json['to'],
        fromPort: json['fromPort'],
        toPort: json['toPort'],
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Link &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fromTo == other.fromTo;

  @override
  int get hashCode => id.hashCode ^ fromTo.hashCode;
}

class TempLink {
  final FlLinkStyle style;
  final Offset from;
  final Offset to;

  TempLink({
    required this.style,
    required this.from,
    required this.to,
  });
}

enum PortDirection { input, output }

enum PortType { data, control }

/// A port prototype is the blueprint for a port instance.
///
/// It defines the name, data type, direction, and if it allows multiple links.
abstract class PortPrototype {
  final String idName;
  final String displayName;
  final FlPortStyle style;
  final Type dataType;
  final PortDirection direction;
  final PortType type;

  PortPrototype({
    required this.idName,
    required this.displayName,
    this.style = const FlPortStyle(),
    this.dataType = dynamic,
    required this.direction,
    required this.type,
  });
}

class DataInputPortPrototype extends PortPrototype {
  DataInputPortPrototype({
    required super.idName,
    required super.displayName,
    super.style,
    super.dataType,
  }) : super(direction: PortDirection.input, type: PortType.data);
}

class DataOutputPortPrototype extends PortPrototype {
  DataOutputPortPrototype({
    required super.idName,
    required super.displayName,
    super.style,
    super.dataType,
  }) : super(direction: PortDirection.output, type: PortType.data);
}

class ControlInputPortPrototype extends PortPrototype {
  ControlInputPortPrototype({
    required super.idName,
    required super.displayName,
    super.style,
  }) : super(direction: PortDirection.input, type: PortType.control);
}

class ControlOutputPortPrototype extends PortPrototype {
  ControlOutputPortPrototype({
    required super.idName,
    required super.displayName,
    super.style,
  }) : super(direction: PortDirection.output, type: PortType.control);
}

/// A port is a connection point on a node.
///
/// In addition to the prototype, it holds the data, links, and offset.
final class PortInstance {
  final PortPrototype prototype;
  dynamic data; // Not saved as it is only used during in graph execution
  Set<Link> links = {};
  Offset offset; // Determined by Flutter
  final GlobalKey key = GlobalKey(); // Determined by Flutter

  PortInstance({
    required this.prototype,
    this.offset = Offset.zero,
  });

  Map<String, dynamic> toJson() {
    return {
      'idName': prototype.idName,
      'links': links.map((link) => link.toJson()).toList(),
    };
  }

  factory PortInstance.fromJson(
    Map<String, dynamic> json,
    Map<String, PortPrototype> portPrototypes,
  ) {
    if (!portPrototypes.containsKey(json['idName'].toString())) {
      throw Exception('Port prototype not found');
    }

    final prototype = portPrototypes[json['idName'].toString()]!;

    final instance = PortInstance(prototype: prototype);

    instance.links = (json['links'] as List<dynamic>)
        .map((linkJson) => Link.fromJson(linkJson))
        .toSet();

    return instance;
  }

  PortInstance copyWith({
    dynamic data,
    Set<Link>? links,
    Offset? offset,
  }) {
    final instance = PortInstance(
      prototype: prototype,
      offset: offset ?? this.offset,
    );

    instance.links = links ?? this.links;

    return instance;
  }
}

typedef OnVisualizerTap = Function(
  dynamic data,
  Function(dynamic data) setData,
);

typedef EditorBuilder = Widget Function(
  BuildContext context,
  Function() removeOverlay,
  dynamic data,
  Function(dynamic data, {required FieldEventType eventType}) setData,
);

/// A field prototype is the blueprint for a field instance.
///
/// It is used to store variables for use in the onExecute function of a node.
/// If explicitly allowed, the user can change the value of the field.
class FieldPrototype {
  final String idName;
  final String displayName;
  final FlFieldStyle style;
  final Type dataType;
  final dynamic defaultData;
  final Widget Function(dynamic data) visualizerBuilder;
  final OnVisualizerTap? onVisualizerTap;
  final EditorBuilder? editorBuilder;

  FieldPrototype({
    required this.idName,
    this.displayName = '',
    this.style = const FlFieldStyle(),
    this.dataType = dynamic,
    this.defaultData,
    required this.visualizerBuilder,
    this.onVisualizerTap,
    this.editorBuilder,
  }) : assert(onVisualizerTap != null || editorBuilder != null);
}

/// A field is a variable that can be used in the onExecute function of a node.
///
/// In addition to the prototype, it holds the data.
class FieldInstance {
  final FieldPrototype prototype;
  final editorOverlayController = OverlayPortalController();
  dynamic data;
  final GlobalKey key = GlobalKey(); // Determined by Flutter

  FieldInstance({
    required this.prototype,
    required this.data,
  });

  Map<String, dynamic> toJson(Map<String, DataHandler> dataHandlers) {
    return {
      'idName': prototype.idName,
      'data': dataHandlers[prototype.dataType.toString()]?.toJson(data),
    };
  }

  factory FieldInstance.fromJson(
    Map<String, dynamic> json,
    Map<String, FieldPrototype> fieldPrototypes,
    Map<String, DataHandler> dataHandlers,
  ) {
    if (!fieldPrototypes.containsKey(json['idName'].toString())) {
      throw Exception('Field prototype not found');
    }

    final prototype = fieldPrototypes[json['idName'].toString()]!;

    return FieldInstance(
      prototype: prototype,
      data: json['data'] != 'null'
          ? dataHandlers[prototype.dataType.toString()]?.fromJson(json['data'])
          : null,
    );
  }

  FieldInstance copyWith({dynamic data}) {
    return FieldInstance(prototype: prototype, data: data ?? this.data);
  }
}

/// A node prototype is the blueprint for a node instance.
///
/// It defines the name, description, color, ports, fields, and onExecute function.
final class NodePrototype {
  final String idName;
  final String displayName;
  final String description;
  final FlNodeStyleBuilder styleBuilder;
  final List<PortPrototype> ports;
  final List<FieldPrototype> fields;
  final OnExecute onExecute;

  NodePrototype({
    required this.idName,
    required this.displayName,
    this.description = '',
    this.styleBuilder = defaultNodeStyle,
    this.ports = const [],
    this.fields = const [],
    required this.onExecute,
  });
}

/// The state of a node widget.
final class NodeState {
  bool isSelected; // Not saved as it is only used during rendering
  bool isCollapsed; // Saved

  NodeState({
    this.isSelected = false,
    this.isCollapsed = false,
  });

  factory NodeState.fromJson(Map<String, dynamic> json) {
    return NodeState(
      isSelected: json['isSelected'],
      isCollapsed: json['isCollapsed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isSelected': isSelected,
      'isCollapsed': isCollapsed,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeState &&
          runtimeType == other.runtimeType &&
          isSelected == other.isSelected &&
          isCollapsed == other.isCollapsed;

  @override
  int get hashCode => isSelected.hashCode ^ isCollapsed.hashCode;
}

/// A node is a component in the node editor.
///
/// It holds the instances of the ports and fields, the offset, the data and the state.
final class NodeInstance {
  final String id; // Stored to acceleate lookups

  // The resolved style for the node.
  late FlNodeStyle builtStyle;
  late FlNodeHeaderStyle builtHeaderStyle;

  final NodePrototype prototype;
  final Map<String, PortInstance> ports;
  final Map<String, PortInstance> dynamicPorts = {};
  final Map<String, FieldInstance> fields;
  final NodeState state = NodeState();
  final Function(NodeInstance node) onRendered;
  Offset offset; // User or system defined offset
  final GlobalKey key = GlobalKey(); // Determined by Flutter

  NodeInstance({
    required this.id,
    required this.prototype,
    required this.ports,
    required this.fields,
    required this.onRendered,
    this.offset = Offset.zero,
  });

  NodeInstance copyWith({
    String? id,
    Color? color,
    Map<String, PortInstance>? ports,
    Map<String, FieldInstance>? fields,
    NodeState? state,
    Function(NodeInstance node)? onRendered,
    Offset? offset,
  }) {
    return NodeInstance(
      id: id ?? this.id,
      prototype: prototype,
      ports: ports ?? this.ports,
      fields: fields ?? this.fields,
      onRendered: onRendered ?? this.onRendered,
      offset: offset ?? this.offset,
    );
  }

  Map<String, dynamic> toJson(Map<String, DataHandler> dataHandlers) {
    return {
      'id': id,
      'idName': prototype.idName,
      'ports': ports.map((k, v) => MapEntry(k, v.toJson())),
      // NEW: serialize dynamic ports too.
      'dynamicPorts': dynamicPorts.map((k, v) => MapEntry(k, v.toJson())),
      'fields': fields.map((k, v) => MapEntry(k, v.toJson(dataHandlers))),
      'state': state.toJson(),
      'offset': [offset.dx, offset.dy],
    };
  }

  Map<String, PortInstance> get allPorts => {...ports, ...dynamicPorts};

  factory NodeInstance.fromJson(
    Map<String, dynamic> json, {
    required Map<String, NodePrototype> nodePrototypes,
    required Function(NodeInstance node) onRenderedCallback,
    required Map<String, DataHandler> dataHandlers,
  }) {
    if (!nodePrototypes.containsKey(json['idName'].toString())) {
      throw Exception('Node prototype not found');
    }

    final prototype = nodePrototypes[json['idName'].toString()]!;

    final portPrototypes = Map.fromEntries(
      prototype.ports.map(
        (prototype) => MapEntry(prototype.idName, prototype),
      ),
    );

    final ports = (json['ports'] as Map<String, dynamic>).map(
      (id, portJson) {
        return MapEntry(
          id,
          PortInstance.fromJson(portJson, portPrototypes),
        );
      },
    );

    final fieldPrototypes = Map.fromEntries(
      prototype.fields.map(
        (prototype) => MapEntry(prototype.idName, prototype),
      ),
    );

    final fields = (json['fields'] as Map<String, dynamic>).map(
      (id, fieldJson) {
        return MapEntry(
          id,
          FieldInstance.fromJson(fieldJson, fieldPrototypes, dataHandlers),
        );
      },
    );

    final instance = NodeInstance(
      id: json['id'],
      prototype: prototype,
      ports: ports,
      fields: fields,
      onRendered: onRenderedCallback,
      offset: Offset(json['offset'][0], json['offset'][1]),
    );

    final state = NodeState.fromJson(json['state']);
    instance.state.isSelected = state.isSelected;
    instance.state.isCollapsed = state.isCollapsed;

    // NEW: load dynamic ports if available.
    if (json.containsKey('dynamicPorts')) {
      final dynPortsJson = json['dynamicPorts'] as Map<String, dynamic>;
      // We reuse the same portPrototypes mapping for deserialization.
      instance.dynamicPorts.addAll(dynPortsJson.map(
        (id, portJson) => MapEntry(
          id,
          PortInstance.fromJson(portJson, portPrototypes),
        ),
      ));
    }

    return instance;
  }

  // NEW: Optional helper to add a dynamic port.
  void addDynamicPort(PortPrototype portPrototype) {
    final dynamicPortId = UniqueKey().toString();
    dynamicPorts[dynamicPortId] = PortInstance(prototype: portPrototype);
  }

  // NEW: Optional helper to remove a dynamic port by its key.
  void removeDynamicPort(String dynamicPortId) {
    dynamicPorts.remove(dynamicPortId);
  }
}

PortInstance createPort(String idName, PortPrototype prototype) {
  return PortInstance(prototype: prototype);
}

FieldInstance createField(String idName, FieldPrototype prototype) {
  return FieldInstance(prototype: prototype, data: prototype.defaultData);
}

NodeInstance createNode(
  NodePrototype prototype, {
  required FlNodeEditorController controller,
  required Offset offset,
}) {
  return NodeInstance(
    id: const Uuid().v4(),
    prototype: prototype,
    ports: Map.fromEntries(
      prototype.ports.map((prototype) {
        final instance = createPort(prototype.idName, prototype);
        return MapEntry(prototype.idName, instance);
      }),
    ),
    fields: Map.fromEntries(
      prototype.fields.map((prototype) {
        final instance = createField(prototype.idName, prototype);
        return MapEntry(prototype.idName, instance);
      }),
    ),
    onRendered: controller.onRenderedCallback,
    offset: offset,
  );
}
