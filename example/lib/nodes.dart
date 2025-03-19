import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:fl_nodes/fl_nodes.dart';

import './widgets/json_editor.dart';

enum Operator { add, subtract, multiply, divide }

enum Comparator { equal, notEqual, greater, greaterEqual, less, lessEqual }

final FlPortStyle outputDataPortStyle = FlPortStyle(
  color: Colors.orange,
  shape: FlPortShape.circle,
  linkStyleBuilder: (state) => const FlLinkStyle(
    gradient: LinearGradient(
      colors: [Colors.orange, Colors.purple],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    lineWidth: 3.0,
    drawMode: FlLinkDrawMode.solid,
    curveType: FlLinkCurveType.bezier,
  ),
);

const FlPortStyle inputDataPortStyle = FlPortStyle(
  color: Colors.purple,
  shape: FlPortShape.circle,
);

const encoder = JsonEncoder.withIndent('  ');
const decoder = JsonDecoder();
//
// Helper for building header styles (now passing IconData)
//
FlNodeHeaderStyle buildHeaderStyle({
  required Color headerColor,
  required bool isCollapsed,
  EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  TextStyle textStyle =
      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
}) {
  return FlNodeHeaderStyle(
    padding: padding,
    decoration: BoxDecoration(
      color: headerColor,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(7),
        topRight: const Radius.circular(7),
        bottomLeft: Radius.circular(isCollapsed ? 7 : 0),
        bottomRight: Radius.circular(isCollapsed ? 7 : 0),
      ),
    ),
    textStyle: textStyle,
    icon: isCollapsed ? Icons.expand_more : Icons.expand_less,
  );
}

//
// Node: convert_text_openai_format
// This node takes a text input and converts it to an OpenAI message format.
// It does not require any adjustable parameters.
//
NodePrototype convertTextOpenAiFormatNode() {
  return NodePrototype(
    idName: 'convert_text_openai_format',
    displayName: 'Convert Text to OpenAI Format',
    description: 'Converts plain text to OpenAI message format.',
    ports: [
      DataInputPortPrototype(
        idName: 'text',
        displayName: 'Text',
        dataType: String,
        style: inputDataPortStyle,
      ),
      DataOutputPortPrototype(
        idName: 'messages',
        displayName: 'Messages',
        dataType: List,
        style: outputDataPortStyle,
      ),
    ],
    fields: [],
    onExecute: (ports, fields, state, f, p) async {
      // Not executed in the editor.
    },
    styleBuilder: (state) => FlNodeStyle(
      decoration: BoxDecoration(
        color: Colors.lightBlueAccent,
        borderRadius: BorderRadius.circular(7),
      ),
      headerStyleBuilder: (state) => buildHeaderStyle(
        headerColor: Colors.blue,
        isCollapsed: state.isCollapsed,
      ),
    ),
  );
}

//
// Node: format
// This node formats and validates output using provided schemas.
// Its parameters are "expected_schema" and "desired_schema".
//
NodePrototype formatNode() {
  return NodePrototype(
    idName: 'format',
    displayName: 'Format Output',
    description:
        'Formats and validates output using provided schema definitions.',
    ports: [
      DataInputPortPrototype(
        idName: 'input',
        displayName: 'Input',
        dataType: Map,
        style: inputDataPortStyle,
      ),
      DataOutputPortPrototype(
        idName: 'result',
        displayName: 'Result',
        dataType: Map,
        style: outputDataPortStyle,
      ),
    ],
    fields: [
      FieldPrototype(
        idName: 'expected_schema',
        displayName: 'Expected Schema',
        dataType: Map,
        defaultData: {},
        visualizerBuilder: (data) {
          // Get a more formatted preview for maps and lists
          String getPreview(dynamic value) {
            if (value is Map) {
              return '{${value.length} fields}';
            } else if (value is List) {
              return '[${value.length} items]';
            } else if (value is String && value.length > 30) {
              return '"${value.substring(0, 27)}..."';
            } else {
              return value.toString();
            }
          }

          return Text(
            getPreview(data),
            style: const TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          );
        },
        editorBuilder: (context, removeOverlay, data, setData) =>
            ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: JsonEditorField(
            initialValue: encoder.convert(data),
            onChanged: (value) {
              try {
                final parsed = jsonDecode(value);
                // Use FieldEventType.submit to ensure the framework recognizes this as a final value
                setData(parsed, eventType: FieldEventType.submit);
              } catch (e) {
                print('Invalid JSON: $e');
              }
            },
          ),
        ),
      ),
      FieldPrototype(
          idName: 'desired_schema',
          displayName: 'Desired Schema',
          dataType: Map,
          defaultData: {},
          visualizerBuilder: (data) {
            // Get a more formatted preview for maps and lists
            String getPreview(dynamic value) {
              if (value is Map) {
                return '{${value.length} fields}';
              } else if (value is List) {
                return '[${value.length} items]';
              } else if (value is String && value.length > 30) {
                return '"${value.substring(0, 27)}..."';
              } else {
                return value.toString();
              }
            }

            return Text(
              getPreview(data),
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            );
          },
          editorBuilder: (context, removeOverlay, data, setData) =>
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: JsonEditorField(
                  initialValue: encoder.convert(data),
                  onChanged: (value) {
                    try {
                      final parsed = jsonDecode(value);
                      // Use FieldEventType.submit to ensure the framework recognizes this as a final value
                      setData(parsed, eventType: FieldEventType.submit);
                    } catch (e) {
                      print('Invalid JSON: $e');
                    }
                  },
                ),
              )),
    ],
    onExecute: (ports, fields, state, f, p) async {
      // Not executed in the editor.
    },
    styleBuilder: (state) => FlNodeStyle(
      decoration: BoxDecoration(
        color: Colors.tealAccent,
        borderRadius: BorderRadius.circular(7),
      ),
      headerStyleBuilder: (state) => buildHeaderStyle(
        headerColor: Colors.teal,
        isCollapsed: state.isCollapsed,
      ),
    ),
  );
}

//
// Node: guided_completion
// This node generates a response based on a provided response schema.
// Its parameters include model, temperature, max_tokens, and response_scheme.
//
NodePrototype guidedCompletionNode() {
  return NodePrototype(
    idName: 'vertex.guided_completion',
    displayName: 'Vertex Guided Completion',
    description:
        '[VertexAI] Generates a response based on a provided response schema.',
    ports: [
      DataInputPortPrototype(
        idName: 'messages',
        displayName: 'Messages',
        dataType: List,
        style: inputDataPortStyle,
      ),
      DataOutputPortPrototype(
        idName: 'response',
        displayName: 'Response',
        dataType: Map,
        style: outputDataPortStyle,
      ),
    ],
    fields: [
      FieldPrototype(
        idName: 'model',
        displayName: 'Model',
        dataType: String,
        defaultData: "gemini-1.5-flash-002",
        visualizerBuilder: (data) =>
            Text(data, style: const TextStyle(color: Colors.white)),
        editorBuilder: (context, removeOverlay, data, setData) =>
            ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: TextFormField(
            initialValue: data,
            onFieldSubmitted: (value) {
              setData(value, eventType: FieldEventType.submit);
              removeOverlay();
            },
          ),
        ),
      ),
      FieldPrototype(
        idName: 'temperature',
        displayName: 'Temperature',
        dataType: double,
        defaultData: 0.1,
        visualizerBuilder: (data) =>
            Text(data.toString(), style: const TextStyle(color: Colors.white)),
        editorBuilder: (context, removeOverlay, data, setData) =>
            ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: TextFormField(
            initialValue: data.toString(),
            keyboardType: TextInputType.number,
            onFieldSubmitted: (value) {
              final parsed = double.tryParse(value) ?? 0.1;
              setData(parsed, eventType: FieldEventType.submit);
              removeOverlay();
            },
          ),
        ),
      ),
      FieldPrototype(
        idName: 'max_tokens',
        displayName: 'Max Tokens',
        dataType: int,
        defaultData: 2048,
        visualizerBuilder: (data) =>
            Text(data.toString(), style: const TextStyle(color: Colors.white)),
        editorBuilder: (context, removeOverlay, data, setData) =>
            ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: TextFormField(
            initialValue: data.toString(),
            keyboardType: TextInputType.number,
            onFieldSubmitted: (value) {
              final parsed = int.tryParse(value) ?? 2048;
              setData(parsed, eventType: FieldEventType.submit);
              removeOverlay();
            },
          ),
        ),
      ),
      FieldPrototype(
        idName: 'system_message',
        displayName: 'System Prompt',
        dataType: String,
        defaultData: "",
        visualizerBuilder: (data) => ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120, maxHeight: 40),
          child: Text(
            data,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        editorBuilder: (context, removeOverlay, data, setData) {
          // Use focusnode for updating values
          final focusNode = FocusNode();
          final textController = TextEditingController(text: data);

          focusNode.addListener(() {
            if (!focusNode.hasFocus) {
              // The TextFormField has lost focus.  Submit the data.
              setData(textController.text, eventType: FieldEventType.submit);
              removeOverlay(); // Close the editor
            }
          });

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: TextFormField(
              controller: textController, // Use the controller
              focusNode: focusNode, // Assign the FocusNode
              maxLines: null, // Allow multiple lines
            ),
          );
        },
      ),
      FieldPrototype(
        idName: 'response_scheme',
        displayName: 'Response Scheme',
        dataType: Map,
        defaultData: {},
        visualizerBuilder: (data) {
          // Get a more formatted preview for maps and lists
          String getPreview(dynamic value) {
            if (value is Map) {
              return '{${value.length} fields}';
            } else if (value is List) {
              return '[${value.length} items]';
            } else if (value is String && value.length > 30) {
              return '"${value.substring(0, 27)}..."';
            } else {
              return value.toString();
            }
          }

          return Text(
            getPreview(data),
            style: const TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          );
        },
        editorBuilder: (context, removeOverlay, data, setData) =>
            ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: JsonEditorField(
            initialValue: encoder.convert(data),
            onChanged: (value) {
              try {
                final parsed = jsonDecode(value);
                // Use FieldEventType.submit to ensure the framework recognizes this as a final value
                setData(parsed, eventType: FieldEventType.submit);
              } catch (e) {
                print('Invalid JSON: $e');
              }
            },
          ),
        ),
      ),
    ],
    onExecute: (ports, fields, state, f, p) async {
      // Not executed in the editor.
    },
    styleBuilder: (state) => FlNodeStyle(
      decoration: BoxDecoration(
        color: Colors.pinkAccent,
        borderRadius: BorderRadius.circular(7),
      ),
      headerStyleBuilder: (state) => buildHeaderStyle(
        headerColor: Colors.pink,
        isCollapsed: state.isCollapsed,
      ),
    ),
  );
}

NodePrototype guidedCompletionNodeOAI() {
  return NodePrototype(
    idName: 'oai.guided_completion',
    displayName: 'OpenAI Guided Completion',
    description:
        '[VertexAI] Generates a response based on a provided response schema.',
    ports: [
      DataInputPortPrototype(
        idName: 'messages',
        displayName: 'Messages',
        dataType: List,
        style: inputDataPortStyle,
      ),
      DataOutputPortPrototype(
        idName: 'response',
        displayName: 'Response',
        dataType: Map,
        style: outputDataPortStyle,
      ),
    ],
    fields: [
      FieldPrototype(
        idName: 'model',
        displayName: 'Model',
        dataType: String,
        defaultData: "chatgpt-4o-latest",
        visualizerBuilder: (data) =>
            Text(data, style: const TextStyle(color: Colors.white)),
        editorBuilder: (context, removeOverlay, data, setData) =>
            ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: TextFormField(
            initialValue: data,
            onFieldSubmitted: (value) {
              setData(value, eventType: FieldEventType.submit);
              removeOverlay();
            },
          ),
        ),
      ),
      FieldPrototype(
        idName: 'temperature',
        displayName: 'Temperature',
        dataType: double,
        defaultData: 0.1,
        visualizerBuilder: (data) =>
            Text(data.toString(), style: const TextStyle(color: Colors.white)),
        editorBuilder: (context, removeOverlay, data, setData) =>
            ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: TextFormField(
            initialValue: data.toString(),
            keyboardType: TextInputType.number,
            onFieldSubmitted: (value) {
              final parsed = double.tryParse(value) ?? 0.1;
              setData(parsed, eventType: FieldEventType.submit);
              removeOverlay();
            },
          ),
        ),
      ),
      FieldPrototype(
        idName: 'max_tokens',
        displayName: 'Max Tokens',
        dataType: int,
        defaultData: 2048,
        visualizerBuilder: (data) =>
            Text(data.toString(), style: const TextStyle(color: Colors.white)),
        editorBuilder: (context, removeOverlay, data, setData) =>
            ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: TextFormField(
            initialValue: data.toString(),
            keyboardType: TextInputType.number,
            onFieldSubmitted: (value) {
              final parsed = int.tryParse(value) ?? 2048;
              setData(parsed, eventType: FieldEventType.submit);
              removeOverlay();
            },
          ),
        ),
      ),
      FieldPrototype(
        idName: 'response_format',
        displayName: 'Response Format',
        dataType: Map,
        defaultData: {},
        visualizerBuilder: (data) {
          // Get a more formatted preview for maps and lists
          String getPreview(dynamic value) {
            if (value is Map) {
              return '{${value.length} fields}';
            } else if (value is List) {
              return '[${value.length} items]';
            } else if (value is String && value.length > 30) {
              return '"${value.substring(0, 27)}..."';
            } else {
              return value.toString();
            }
          }

          return Text(
            getPreview(data),
            style: const TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          );
        },
        editorBuilder: (context, removeOverlay, data, setData) =>
            ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: JsonEditorField(
            initialValue: encoder.convert(data),
            onChanged: (value) {
              try {
                final parsed = jsonDecode(value);
                // Use FieldEventType.submit to ensure the framework recognizes this as a final value
                setData(parsed, eventType: FieldEventType.submit);
              } catch (e) {
                print('Invalid JSON: $e');
              }
            },
          ),
        ),
      ),
    ],
    onExecute: (ports, fields, state, f, p) async {
      // Not executed in the editor.
    },
    styleBuilder: (state) => FlNodeStyle(
      decoration: BoxDecoration(
        color: Colors.pinkAccent,
        borderRadius: BorderRadius.circular(7),
      ),
      headerStyleBuilder: (state) => buildHeaderStyle(
        headerColor: Colors.pink,
        isCollapsed: state.isCollapsed,
      ),
    ),
  );
}

//
// (Optional) Node: chat_completion
// This node generates a chat response using LLM chat completion.
// Parameters are defined similarly.
//
NodePrototype chatCompletionNode() {
  return NodePrototype(
    idName: 'vertex.chat_completion',
    displayName: 'Vertex Chat Completion',
    description: 'Generates a chat response using vertexAI chat completion.',
    ports: [
      DataInputPortPrototype(
        idName: 'messages',
        displayName: 'Messages',
        dataType: List,
        style: inputDataPortStyle,
      ),
      DataOutputPortPrototype(
        idName: 'response',
        displayName: 'Response',
        dataType: String,
        style: outputDataPortStyle,
      ),
    ],
    fields: [
      FieldPrototype(
        idName: 'model',
        displayName: 'Model',
        dataType: String,
        defaultData: "",
        visualizerBuilder: (data) =>
            Text(data, style: const TextStyle(color: Colors.white)),
        editorBuilder: (context, removeOverlay, data, setData) =>
            ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: TextFormField(
            initialValue: data,
            onFieldSubmitted: (value) {
              setData(value, eventType: FieldEventType.submit);
              removeOverlay();
            },
          ),
        ),
      ),
      FieldPrototype(
        idName: 'temperature',
        displayName: 'Temperature',
        dataType: double,
        defaultData: 0.2,
        visualizerBuilder: (data) =>
            Text(data.toString(), style: const TextStyle(color: Colors.white)),
        editorBuilder: (context, removeOverlay, data, setData) =>
            ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: TextFormField(
            initialValue: data.toString(),
            keyboardType: TextInputType.number,
            onFieldSubmitted: (value) {
              final parsed = double.tryParse(value) ?? 0.2;
              setData(parsed, eventType: FieldEventType.submit);
              removeOverlay();
            },
          ),
        ),
      ),
      FieldPrototype(
        idName: 'top_p',
        displayName: 'Top P',
        dataType: double,
        defaultData: 1.0,
        visualizerBuilder: (data) =>
            Text(data.toString(), style: const TextStyle(color: Colors.white)),
        editorBuilder: (context, removeOverlay, data, setData) =>
            ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: TextFormField(
            initialValue: data.toString(),
            keyboardType: TextInputType.number,
            onFieldSubmitted: (value) {
              final parsed = double.tryParse(value) ?? 1.0;
              setData(parsed, eventType: FieldEventType.submit);
              removeOverlay();
            },
          ),
        ),
      ),
      FieldPrototype(
        idName: 'max_tokens',
        displayName: 'Max Tokens',
        dataType: int,
        defaultData: 2048,
        visualizerBuilder: (data) =>
            Text(data.toString(), style: const TextStyle(color: Colors.white)),
        editorBuilder: (context, removeOverlay, data, setData) =>
            ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: TextFormField(
            initialValue: data.toString(),
            keyboardType: TextInputType.number,
            onFieldSubmitted: (value) {
              final parsed = int.tryParse(value) ?? 2048;
              setData(parsed, eventType: FieldEventType.submit);
              removeOverlay();
            },
          ),
        ),
      ),
      FieldPrototype(
        idName: 'system_message',
        displayName: 'System Prompt',
        dataType: String,
        defaultData: "",
        visualizerBuilder: (data) => ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120, maxHeight: 40),
          child: Text(
            data,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        editorBuilder: (context, removeOverlay, data, setData) {
          // Use focusnode for updating values
          final focusNode = FocusNode();
          final textController = TextEditingController(text: data);

          focusNode.addListener(() {
            if (!focusNode.hasFocus) {
              // The TextFormField has lost focus.  Submit the data.
              setData(textController.text, eventType: FieldEventType.submit);
              removeOverlay(); // Close the editor
            }
          });

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: TextFormField(
              controller: textController, // Use the controller
              focusNode: focusNode, // Assign the FocusNode
              maxLines: null, // Allow multiple lines
            ),
          );
        },
      ),
    ],
    onExecute: (ports, fields, state, f, p) async {
      // Not executed in the editor.
    },
    styleBuilder: (state) => FlNodeStyle(
      decoration: BoxDecoration(
        color: Colors.greenAccent,
        borderRadius: BorderRadius.circular(7),
      ),
      headerStyleBuilder: (state) => buildHeaderStyle(
        headerColor: Colors.green,
        isCollapsed: state.isCollapsed,
      ),
    ),
  );
}

NodePrototype chatCompletionNodeOAI() {
  return NodePrototype(
    idName: 'oai.chat_completion',
    displayName: 'OpenAI Chat Completion',
    description: 'Generates a chat response using vertexAI chat completion.',
    ports: [
      DataInputPortPrototype(
        idName: 'messages',
        displayName: 'Messages',
        dataType: List,
        style: inputDataPortStyle,
      ),
      DataOutputPortPrototype(
        idName: 'response',
        displayName: 'Response',
        dataType: String,
        style: outputDataPortStyle,
      ),
    ],
    fields: [
      FieldPrototype(
        idName: 'model',
        displayName: 'Model',
        dataType: String,
        defaultData: "chatgpt-4o-latest",
        visualizerBuilder: (data) =>
            Text(data, style: const TextStyle(color: Colors.white)),
        editorBuilder: (context, removeOverlay, data, setData) =>
            ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: TextFormField(
            initialValue: data,
            onFieldSubmitted: (value) {
              setData(value, eventType: FieldEventType.submit);
              removeOverlay();
            },
          ),
        ),
      ),
      FieldPrototype(
        idName: 'temperature',
        displayName: 'Temperature',
        dataType: double,
        defaultData: 0.2,
        visualizerBuilder: (data) =>
            Text(data.toString(), style: const TextStyle(color: Colors.white)),
        editorBuilder: (context, removeOverlay, data, setData) =>
            ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: TextFormField(
            initialValue: data.toString(),
            keyboardType: TextInputType.number,
            onFieldSubmitted: (value) {
              final parsed = double.tryParse(value) ?? 0.2;
              setData(parsed, eventType: FieldEventType.submit);
              removeOverlay();
            },
          ),
        ),
      ),
      FieldPrototype(
        idName: 'max_tokens',
        displayName: 'Max Tokens',
        dataType: int,
        defaultData: 2048,
        visualizerBuilder: (data) =>
            Text(data.toString(), style: const TextStyle(color: Colors.white)),
        editorBuilder: (context, removeOverlay, data, setData) =>
            ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: TextFormField(
            initialValue: data.toString(),
            keyboardType: TextInputType.number,
            onFieldSubmitted: (value) {
              final parsed = int.tryParse(value) ?? 2048;
              setData(parsed, eventType: FieldEventType.submit);
              removeOverlay();
            },
          ),
        ),
      ),
    ],
    onExecute: (ports, fields, state, f, p) async {
      // Not executed in the editor.
    },
    styleBuilder: (state) => FlNodeStyle(
      decoration: BoxDecoration(
        color: Colors.greenAccent,
        borderRadius: BorderRadius.circular(7),
      ),
      headerStyleBuilder: (state) => buildHeaderStyle(
        headerColor: Colors.green,
        isCollapsed: state.isCollapsed,
      ),
    ),
  );
}

//
// Register the YALW nodes (only those that define parameters)
//
void registerNodes(BuildContext context, FlNodeEditorController controller) {
  controller.registerNodePrototype(formatNode());
  controller.registerNodePrototype(convertTextOpenAiFormatNode());
  controller.registerNodePrototype(guidedCompletionNode());
  controller.registerNodePrototype(guidedCompletionNodeOAI());
  controller.registerNodePrototype(chatCompletionNode());
  controller.registerNodePrototype(chatCompletionNodeOAI());
}
