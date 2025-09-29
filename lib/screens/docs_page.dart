import 'package:flutter/material.dart';

class DocsPage extends StatefulWidget {
  DocsPage({super.key});

  final docs = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  @override
  State<DocsPage> createState() => _DocsPageState();
}

class _DocsPageState extends State<DocsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: Scrollbar(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: widget.docs.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      child: ListTile(
                        title: Text('Documento ${widget.docs[index]}'),
                        subtitle:
                            Text('Dettagli del documento ${widget.docs[index]}'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () { //TO DO Scanner del documento con NFC, aggiunta alla lista, caricato sul database in modo cryptato
          setState(() {
            widget.docs.add(widget.docs.length + 1);
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}