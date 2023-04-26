import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';
import 'items.dart';
import 'selector.dart';
import 'aspect.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  _getHome() {
    return FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const CircularProgressIndicator();
            default:
              if (snapshot.hasError)
                return Text('Error: ${snapshot.error}');
              else {
                List items = snapshot.data.getStringList("items") ?? [];

                if (items == null || items.isEmpty) {
                  return ProductSelector(standAlone: false, data: loadData());
                } else {
                  return HomePage(prefs: snapshot.data);
                }
              }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ImporTAX',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: _getHome(),
      routes: {"/home": (context) => HomePage()},
    );
  }
}

TextStyle bigger = TextStyle(fontSize: 18.0);
TextStyle numStyle = TextStyle(fontFamily: 'Montserrat');
TextStyle sub = TextStyle(fontFamily: 'Montserrat', color: Colors.black54);

Widget buildButton(String _tag, void _func(), double t, double b) {
  return Padding(
      padding: EdgeInsets.only(top: t, bottom: b),
      child: ElevatedButton(
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(_tag, style: TextStyle(fontSize: 16.0))),
        onPressed: _func,
      ));
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.prefs}) : super(key: key) {
    this.items = prefs.getStringList('items') ?? [];
    this.items = jsonTOItems(items);
  }

  List items;
  final SharedPreferences prefs;

  @override
  _HomePageState createState() => _HomePageState();

  List<Summary> jsonTOItems(List items) {
    return items.map((e) => Summary.fromJson(jsonDecode(e))).toList();
  }

  List<String> itemsTOJson(List i) {
    return i.map((e) => jsonEncode(e)).toList();
  }
}

class _HomePageState extends State<HomePage> {
  void _agregarProducto(bool standAlone) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProductSelector(
                  standAlone: standAlone,
                  data: loadData(),
                ),
            fullscreenDialog: true));
  }

  num _total = 0;
  List _cifs = [];
  List _impts = [];

  @override
  void initState() {
    print("REACHED");

    _calculateTotal();

    super.initState();
  }

  void _calculateTotal() {
    num tmp = 0;
    List<Cif> cifs = [];
    List<Impuesto> impts = [];

    for (var i = 0; i < widget.items.length; i++) {
      tmp = tmp + widget.items[i].total;
      cifs.add(widget.items[i].cif);
      impts.add(widget.items[i].impuesto);
    }
    setState(() {
      _total = tmp;
      _cifs = cifs;
      _impts = impts;
    });
  }

  Widget _buildtitle() {
    if (_total != 0) {
      return Text("\$ " + f.format(_total),
          style: numStyle.copyWith(fontSize: 18));
    } else {
      return Text("ImporTAX");
    }
  }

  Widget _buildImpuesto() {
    if (widget.items.length >= 2) {
      Impuesto _impTotal = Impuesto.from(_impts);

      if (_impTotal.total != 0) {
        return Padding(
          padding:
              EdgeInsets.only(top: 16.0, bottom: 8, left: 16.0, right: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Expanded(
                child: Text(
                  "Impuesto",
                  style: bigger.copyWith(color: Colors.blue),
                ),
              ),
              Text(
                f.format(_impTotal.total),
                style: sub.copyWith(fontSize: 18.0, color: Colors.blue),
              )
            ],
          ),
        );
      }
    } else if (widget.items.isEmpty) {
      return Padding(
        padding:
            EdgeInsets.only(top: 32.0, bottom: 16.0, left: 16.0, right: 16.0),
        child: Text(
          "Oh, no!",
          style: TextStyle(fontSize: 24.0),
        ),
      );
    }
  }

  Widget _buildCIF() {
    if (widget.items.isEmpty) {
      return Padding(
          padding:
              EdgeInsets.only(top: 0.0, bottom: 8.0, left: 16.0, right: 16.0),
          child: Text(
              "Aún no se ha escogido ningún producto, para empezar a calcular elige un producto"));
    } else if (widget.items.length >= 2) {
      Cif _cifTotal = Cif.from(_cifs);

      if (_cifTotal.total != 0) {
        return Padding(
          padding:
              EdgeInsets.only(top: 8.0, bottom: 0, left: 16.0, right: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "CIF",
                      style: bigger.copyWith(color: Colors.green),
                    ),
                    Text("Sin impuesto", style: sub)
                  ],
                ),
              ),
              Text(f.format(_cifTotal.total),
                  style: sub.copyWith(fontSize: 18.0, color: Colors.green))
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String removalP = widget.prefs.getString('deletePiD') ?? null;
    String removalS = widget.prefs.getString('deleteSiD') ?? null;

    if (removalP != null && removalS != null) {
      Summary s =
          widget.items.firstWhere((s) => s.id == removalS, orElse: () => null);
      if (s != null) {
        if (s.productos.length == 1) {
          widget.items.remove(s);
        } else {
          int i = widget.items.indexOf(s);
          s.productos.removeWhere((p) => p.id == removalP);
          widget.items[i] = s;
        }
        widget.prefs.setStringList('item', widget.itemsTOJson(widget.items));
        _calculateTotal();
      }
    }

    return Scaffold(
        body: CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          title: _buildtitle(),
          pinned: true,
        ),
        SliverToBoxAdapter(child: _buildImpuesto()),
        SliverToBoxAdapter(
          child: _buildCIF(),
        ),
        SliverPadding(
          padding: (widget.items.length == 1 &&
                  widget.items[0].productos.length == 1)
              ? EdgeInsets.only(bottom: 12.0)
              : EdgeInsets.all(12.0),
          sliver: SliverList(
              delegate:
                  SliverChildBuilderDelegate((BuildContext context, int i) {
            if (widget.items.length == 1) {
              if (widget.items[0].productos.length == 1) {
                return buildDetail(widget.items[0].productos[0], true, context,
                    widget.prefs, widget.items[0].id);
              } else {
                return Group(widget.items[0], widget.prefs);
              }
            } else {
              return Group(widget.items[i], widget.prefs);
            }
          }, childCount: widget.items.length)),
        ),
        SliverToBoxAdapter(
          child: Padding(
              padding: EdgeInsets.only(top: 0.0, right: 12.0, left: 12.0),
              child: buildButton("Agregar Producto", () {
                _agregarProducto(false);
              }, 8, 0)),
        ),
        SliverToBoxAdapter(
          child: Opacity(
            opacity: (widget.items.isEmpty) ? 0 : 1,
            child: TextButton(
              onPressed: () {
                _agregarProducto(false);
                widget.items.clear();
                _calculateTotal();
                widget.prefs.setStringList('items', []);
              },
              child: Text(
                'o empezar de cero',
                style: TextStyle(color: Colors.red[300]),
              ),
            ),
          ),
        )
      ],
    ));
  }
}
