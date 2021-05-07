import 'dart:async';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'totp.dart';
import 'base32.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A Google Authenticator developed with flutter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Google Authenticator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int leftTime = 30;
  var _names = <String>[];
  var _codes = <String>[];

  @override
  void initState() {
    super.initState();
    _retrieveData();
    Timer.periodic(Duration(milliseconds: 1000), (timer) {
      leftTime = new DateTime.now().second % 30;
      _retrieveData();
    });
  }

  Future<void> _retrieveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var keys = prefs.getKeys();
    setState(() {
      _names.clear();
      _codes.clear();
      keys.forEach((element) {
        _names.add(element);
        _codes.add(prefs.getString(element));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Container(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20.0),
          itemCount: _names.isEmpty ? 1 : _names.length,
          itemBuilder: (context, index) {
            if (_names.isEmpty) {
              return ElevatedButton(
                child: Text("Add your Authenticator code"),
                onPressed: _showMyDialog,
              );
            }
            return GestureDetector(
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: TOTP(_codes[index]).now()));
                },
                onLongPress: () async {
                  _delCode(_names[index]);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _names[index],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(TOTP(_codes[index]).now(),
                            style: Theme.of(context).textTheme.headline4),
                        CircularProgressIndicator(
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(Colors.blue),
                          value: leftTime / 30,
                        ),
                      ],
                    ),
                  ],
                ));
          },
          separatorBuilder: (context, index) => Divider(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showMyDialog,
        tooltip: 'Add your Authenticator code',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<void> _showMyDialog() async {
    String name = "";
    String code = "";
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add your Authenticator code'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextFormField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Enter your code name',
                        ),
                        validator: (String value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter code name';
                          }
                          name = value;
                          return null;
                        },
                      ),
                      TextFormField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Enter your auth code',
                        ),
                        validator: (String value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter auth code';
                          }
                          if (!base32.isValid(value)) {
                            return 'The code you entered cannot be parsed';
                          }
                          code = value;
                          return null;
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState.validate()) {
                                _addCode(name, code);
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('Submit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _addCode(String key, value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  _delCode(String key) async {
    if (await confirm(context,
        title: Text('Do you want to delete this auth code?'))) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove(key);
      _retrieveData();
    }
  }
}
