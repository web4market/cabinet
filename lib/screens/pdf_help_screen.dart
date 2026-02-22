import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:flutter/services.dart'; // Для rootBundle
import 'package:path_provider/path_provider.dart'; // Для getTemporaryDirectory

class PdfHelpScreen extends StatefulWidget {
  @override
  _PdfHelpScreenState createState() => _PdfHelpScreenState();
}

class _PdfHelpScreenState extends State<PdfHelpScreen> {
  String? _pdfPath;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    // Копируем PDF из assets во временную папку
    final bytes = await rootBundle.load('assets/pdf/user_manual.pdf');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/user_manual.pdf');
    await file.writeAsBytes(bytes.buffer.asUint8List());

    setState(() {
      _pdfPath = file.path;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Руководство пользователя'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: _totalPages > 0
            ? PreferredSize(
          preferredSize: Size.fromHeight(30),
          child: Container(
            color: Colors.blue.shade700,
            child: Center(
              child: Text(
                'Страница ${_currentPage + 1} из $_totalPages',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        )
            : null,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : PDFView(
        filePath: _pdfPath,
        onRender: (pages) {
          setState(() {
            _totalPages = pages!;
          });
        },
        onViewCreated: (controller) {
          // Контроллер для навигации по страницам
        },
        onPageChanged: (currentPage, totalPages) {
          setState(() {
            _currentPage = currentPage ?? 0;
          });
        },
      ),
    );
  }
}