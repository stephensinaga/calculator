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
    '⌫', '0', '=', '+'
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
          result = evalExpression(input);
          historyBox.add(HistoryModel(operation: input, result: result));
          input = result;
        } catch (e) {
          result = "Error";
        }
      } else if (value == "√") {
        if (input.isNotEmpty) {
          input = "sqrt($input)";
          result = evalExpression(input);
        }
      } else if (value == "log") {
        if (input.isNotEmpty) {
          input = "log($input)";
          result = evalExpression(input);
        }
      } else if (value == "^") {
        if (input.isNotEmpty) {
          input += "^";  // Menambah operator pangkat
        }
      } else {
        if (input.isEmpty && (value == "÷" || value == "×" || value == "+")) return;

        // Gunakan simbol estetis yang dikonversi sebelum evaluasi
        if (value == "−") value = "-";
        if (value == "÷") value = "/";
        if (value == "×") value = "*";

        input += value;
        result = evalExpression(input);
      }
    });
  }

  String evalExpression(String expression) {
    try {
      if (expression.isEmpty) return "0";
      if ("+-*/^".contains(expression[expression.length - 1])) return "Error"; // Cegah operator di akhir

      // Ganti simbol estetis dengan yang dapat diproses oleh Math Expressions
      expression = expression.replaceAll("−", "-");
      expression = expression.replaceAll("÷", "/");
      expression = expression.replaceAll("×", "*");
      expression = expression.replaceAll("√", "sqrt");

      // Perbaiki log(x) agar tidak merusak ekspresi lain
      expression = expression.replaceAllMapped(
        RegExp(r'log\(([^)]+)\)'), 
        (match) => "(ln(${match.group(1)}))/ln(10)"
      );

      Parser p = Parser();
      Expression exp = p.parse(expression);
      ContextModel cm = ContextModel();
      double evalResult = exp.evaluate(EvaluationType.REAL, cm);

      return evalResult.toStringAsFixed(evalResult.truncateToDouble() == evalResult ? 0 : 2);
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
                          onLongPress: () => deleteHistory(index), // Hapus dengan tekan lama
                          onTap: () {
                            setState(() {
                              input = item?.operation ?? ""; // Hanya operasi tanpa hasil
                              result = evalExpression(input); // Preview hasil otomatis diperbarui
                            });
                            Navigator.pop(context); // Tutup modal setelah memilih history
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
        title: const Text("Flutter Calculator"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => showHistoryModal(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // History (3 history terakhir)
          Container(
            height: 100, // Tentukan tinggi agar tidak terlalu besar
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ValueListenableBuilder(
              valueListenable: historyBox.listenable(),
              builder: (context, Box<HistoryModel> box, _) {
                if (box.isEmpty) {
                  return const Center(child: Text("No history yet"));
                }
                return ListView.builder(
                  itemCount: box.length < 3 ? box.length : 3, // Tampilkan max 3 history terakhir
                  itemBuilder: (context, index) {
                    var item = box.getAt(box.length - 1 - index); // Ambil dari yang terbaru
                    return Text(
                      "${item?.operation} = ${item?.result}",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.right,
                    );
                  },
                );
              },
            ),
          ),
          // Preview hasil (sebelum `=` ditekan)
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.bottomRight,
            child: Text(
              result,
              style: const TextStyle(fontSize: 24, color: Colors.grey),
            ),
          ),

          // Input yang sedang diketik
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.bottomRight,
            child: Text(
              input,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),

          const Spacer(), // Spacer agar tombol tetap di bawah
          // Grid tombol

          Container(
            padding: const EdgeInsets.all(8),
            child: GridView.builder(
              shrinkWrap: true, // Penting agar tidak mengambil seluruh layar
              physics: const NeverScrollableScrollPhysics(), // Matikan scroll agar tetap di bawah
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemCount: buttons.length,
              itemBuilder: (context, index) {
                return ElevatedButton(
                  onPressed: () => onButtonClick(buttons[index]),
                  child: Text(buttons[index], style: const TextStyle(fontSize: 24)),
                );
              },
            ),
          ),
        ],
      )
    );
  }
}
