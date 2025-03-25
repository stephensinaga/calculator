import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:math_expressions/math_expressions.dart';
import '../models/history_model.dart';

class CalculatorScreen extends StatefulWidget {
  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String input = "";
  String result = "0";
  late Box<HistoryModel> historyBox;

  List<String> buttons = [
    '√', 'log', '^', 'C',
    '7', '8', '9', '÷', 
    '4', '5', '6', '×', 
    '1', '2', '3', '−', 
    '⌫', '0', '.', '+',
    '(', ')', '%', '='
  ];

  @override
  void initState() {
    super.initState();
    historyBox = Hive.box<HistoryModel>('history');
  }

  void onButtonClick(String value) {
    setState(() {
      if (value == "C") {
        input = "";
        result = "0";
      } else if (value == "⌫") {
        if (input.isNotEmpty) {
          input = input.substring(0, input.length - 1);
          result = input.isEmpty ? "0" : evalExpression(input);
        }
      } else if (value == "=") {
        try {
          if (input.isNotEmpty) {
            result = evalExpression(input);

            // Cek apakah input mengandung operator
            if (result != "Error" && RegExp(r'[+\-×÷^]').hasMatch(input)) {
              historyBox.add(HistoryModel(operation: input, result: result));
            }

            input = result;
          }
        } catch (e) {
          result = "Error";
        }
      } else if (value == "√") {
        input += "√(";
      } else if (value == "log") {
        input += "log(";
      } else {
        // Tangani kasus angka negatif di awal
        if (input.isEmpty && value == "−") {
          input = "-";
        } else {
          input += value;
        }
        result = evalExpression(input);
      }
    });
  }

  String evalExpression(String expression) {
    try {
      if (expression.isEmpty) return "0";

      // Cek apakah ekspresi diakhiri dengan operator (tidak valid)
      if (RegExp(r'[+\-×÷^]$').hasMatch(expression)) return "Error";

      // Perbaiki ekspresi sebelum dievaluasi
      expression = expression
          .replaceAll("×", "*")
          .replaceAll("÷", "/")
          .replaceAllMapped(
              RegExp(r'(\d+)%'), (match) => "(${match.group(1)}/100)")
          .replaceAll("√", "sqrt")
          .replaceAll("−", "-")
          .replaceAllMapped(
              RegExp(r'log\(([^)]+)\)'),
              (match) => "(ln(${match.group(1)}))/ln(10)");

      // 🔹 Tangani input angka tanpa operator, langsung return
      if (RegExp(r'^\d+(\.\d+)?$').hasMatch(expression)) return expression;

      // 🔹 Perbaiki angka negatif di awal ekspresi
      if (expression.startsWith('-')) {
        expression = "0$expression";
      }

      // 🔹 Perbaiki angka negatif dalam tanda kurung
      expression = expression.replaceAllMapped(
          RegExp(r'\((-\d+)\)'), (match) => "(0${match.group(1)})"
      );

      Parser p = Parser();
      Expression exp = p.parse(expression);
      ContextModel cm = ContextModel();

      double evalResult = exp.evaluate(EvaluationType.REAL, cm);

      // Format hasil agar tidak ada nol berlebihan setelah desimal
      return evalResult.toString().replaceAll(RegExp(r'\.0+$'), '');
    } catch (e) {
      return "Error";
    }
  }

  void deleteHistory(int index) {
    setState(() {
      historyBox.deleteAt(index);
    });
  }

  void showHistoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            children: [
              const Text(
                "History",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: historyBox.listenable(),
                  builder: (context, Box<HistoryModel> box, _) {
                    if (box.isEmpty) {
                      return const Center(child: Text("No history yet"));
                    }
                    return ListView.builder(
                      itemCount: box.length,
                      itemBuilder: (context, index) {
                        var item = box.getAt(index);
                        return ListTile(
                          title: Text("${item?.operation} = ${item?.result}"),
                          onLongPress: () => deleteHistory(index),
                          onTap: () {
                            setState(() {
                              input = item?.operation ?? "";
                              result = evalExpression(input);
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calculator"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => showHistoryModal(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // **History (4 history terakhir)**
          SizedBox(
            width: double.infinity,
            child: ValueListenableBuilder(
              valueListenable: historyBox.listenable(),
              builder: (context, Box<HistoryModel> box, _) {
                List<HistoryModel> recentHistory =
                    box.values.toList().reversed.take(4).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min, // **Supaya tidak memaksa ukuran besar**
                  children: recentHistory.isNotEmpty
                      ? recentHistory.map((item) {
                          return Text(
                            "${item.operation} = ${item.result}",
                            style: const TextStyle(fontSize: 18, color: Colors.grey),
                            textAlign: TextAlign.right,
                          );
                        }).toList()
                      : [const Text("No history yet", style: TextStyle(fontSize: 18, color: Colors.grey))],
                );
              },
            ),
          ),

          // **Hasil perhitungan (Sedikit ke bawah)**
          const SizedBox(height: 20), // Tambah jarak ke bawah
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.bottomRight,
            child: Text(
              result,
              style: const TextStyle(fontSize: 28, color: Colors.black),
            ),
          ),

          // **Input ekspresi yang sedang diketik**
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.bottomRight,
            child: Text(
              input,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 20), // Tambah jarak ke tombol

          // **Grid tombol kalkulator**
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(), // Nonaktifkan scroll agar tidak bentrok
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4 colomn
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.3, // Perbesar tombol sedikit
                ),
                itemCount: buttons.length,
                itemBuilder: (context, index) {
                  String buttonText = buttons[index];

                  return TextButton(
                    onPressed: () => onButtonClick(buttonText),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                       backgroundColor: buttonText == '⌫' ? Colors.orange : Colors.grey[200], // Warna khusus untuk '⌫'
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: buttonText == '⌫' ? Colors.white : Colors.black
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
  