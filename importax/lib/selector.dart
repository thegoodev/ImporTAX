import 'main.dart';
import 'items.dart';
import 'aspect.dart';
import 'search.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

///Duhh
///
///
///Opens de bottom modal Bottom Sheet to select the freaking product
void select(Map element, BuildContext context, bool standAlone){
        showModalBottomSheet(
          context: context,
          builder: (c){
            List elements = element["productos"];
            var producto = elements[0];
            if(elements.length == 1){
              return ProductEditor(
                selection: Item(
                  nombre: element["nombre"],
                  partida: element["partida"],
                  fixed: producto["fixed"],
                  unidad: producto["unidad"],
                  seguro: producto["seguro"],
                  isc: producto["isc"],
                  av:producto["av"],
                  tasa: producto["tasa"]
                ),
                standAlone: standAlone
              );
            }else{
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: elements.map((l)=> 
                  ListTile(
                    title: Text(l["tipo"]),
                    onTap: (){
                      showModalBottomSheet(context: c, builder: (c){
                       return ProductEditor(
                        selection: Item(
                          nombre: l["tipo"],
                          partida: element["partida"],
                          fixed: l["fixed"],
                          unidad: l["unidad"],
                          seguro: l["seguro"],
                          isc: l["isc"],
                          av: l["av"],
                          tasa: l["tasa"]
                        ),
                        standAlone: standAlone
                      );
                      });
                    },
                  )).toList(),
              );
            }
          }
        );
      }

class ProductSelector extends StatefulWidget{

  ProductSelector({this.standAlone, this.data});

  final bool standAlone;
  final Future<Map> data;

  @override
  _SelectorState createState() => _SelectorState();
}

class _SelectorState extends State<ProductSelector>{

  String _lastSelected;

  void openSection(Map section){

    var sid = section["id"];

    if(section != null){

      List chapters = section["capitulos"];
      List productos = [];

      Widget buildList(){
        if(chapters.length == 1){

          List childs = chapters[0]["children"];
          productos = childs;

          return ListView.builder(
            itemCount: childs.length,
            itemBuilder: (BuildContext c, int i){
              return ListTile(
                title: Text(childs[i]["nombre"], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                subtitle: Text(childs[i]["partida"],style: TextStyle(fontSize: 16)),
                onTap: (){select(childs[i], context, widget.standAlone);},
              );
            }
          );

        }else{

          return ListView.builder(
            itemCount: chapters.length,
            itemBuilder: (BuildContext c, int i){

              var curr = chapters[i];
              List childs = curr["children"];

              return ExpansionTile(
                title: Text(curr["nombre"]),
                children: childs.map(
                  (e){
                    productos.add(e);
                    return ListTile(
                    title: Text(e["nombre"], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                    subtitle: Text(e["partida"],style: TextStyle(fontSize: 16)),
                    onTap: (){select(e, context, widget.standAlone);});}
                  ).toList(),
              );
            },
          );
          
        }
      }

      Navigator.push(context, MaterialPageRoute(
        builder: (context)=> Scaffold(
          appBar: AppBar(
            title: Text(section["seccion"], maxLines: 1,),
            actions: <Widget>[
              IconButton(
                tooltip: 'busqueda',
                icon: const Icon(Icons.search),
                onPressed: () async {
                  final String selected = await showSearch<String>(
                    context: context,
                    delegate: SearchProdDelegate(data: productos, prefs: await SharedPreferences.getInstance(), id: sid),
                  );
                  if (selected != null && selected != _lastSelected) {
                    setState(() {
                      _lastSelected = selected;
                    });
                  }
                },
              ),
         ],),
          body: buildList()
        )
      ));
    }else{
      //TODO: ERROR FATAL
    }
  }

  FutureBuilder body(){
    return FutureBuilder(
      future: widget.data,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return Text('Press button to start.');
          case ConnectionState.active:
          case ConnectionState.waiting:
            return Text('Cargando...');
          case ConnectionState.done:
            if (snapshot.hasError){
              return Text('Error: ${snapshot.error}');
            }else{

              Map info = snapshot.data;

              List secciones = info["secciones"];
              List productos = info["productos"];

              return ListView.separated(
                separatorBuilder: (BuildContext context, int index) => Divider(height: 20,color: Colors.black,),
                itemBuilder: (BuildContext c, int i){
                  var section = productos.firstWhere((var secc)=>(secc["id"]==secciones[i]["id"]), orElse: ()=> null);
                  return ListTile(
                    title: Text(secciones[i]["nombre"]),
                    onTap: (){openSection(section);},
                  );
                },
                itemCount: secciones.length,
              );
              
            }
        }
        return null; // unreachable
      },
    );
  }

  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: AppBar(
         title: Text("Busca un producto"),
         actions: <Widget>[
           IconButton(
            tooltip: 'busqueda',
            icon: const Icon(Icons.search),
            onPressed: () async {
              final String selected = await showSearch<String>(
                context: context,
                delegate: SearchArancelDelegate(data: await widget.data, prefs: await SharedPreferences.getInstance()),
              );
              if (selected != null && selected != _lastSelected) {
                setState(() {
                  _lastSelected = selected;
                });
              }
            },
          ),
         ],
      ),
      body: Center(child: body())
    );
  }
}

class ProductEditor extends StatefulWidget{
  ProductEditor({this.selection, this.standAlone});

  final Item selection;
  final bool standAlone;

  @override
  _EditorState createState() => _EditorState();
}

class _EditorState extends State<ProductEditor>{

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final unitsController = TextEditingController(text: "1");

  final _formKey = GlobalKey<FormState>();

  TextStyle _hintStyle = TextStyle(fontFamily: 'Montserrat', fontSize: 16.0);


  InputDecoration _defaultDecoration(String hint, String suffix){
    return InputDecoration(
      contentPadding: EdgeInsets.only(bottom: 8.0, top: 4),
      hintStyle: _hintStyle,
      hintText: hint,
      suffixText: suffix,
    );
  }

  String _notEmpty(String value){
    if(value.isEmpty){
      return 'Este campo no puede estar vacío';
    }else{
      return null;
    }
  }

  Widget _buildForm(){

    widget.selection.nombre = widget.selection.nombre.replaceAll("-", " ").trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        BlockContainer(
          border: false,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(widget.selection.nombre, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(widget.selection.partida, style: TextStyle(fontSize: 16,color: Colors.black54))
,            ],
          ),
        ),
        BlockContainer(
          border: false,
          icon: Icon(Icons.monetization_on, color: Colors.black54,),
          body: TextFormField(
            controller: priceController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: _notEmpty,
            decoration: _defaultDecoration('Precio en dólares', 'USD')
          ),
        ),
        BlockContainer(
          border: false,
          icon: Icon(Icons.sort, color: Colors.black54,),
          body: TextFormField(
            controller: unitsController,
            keyboardType: TextInputType.number,
            validator: _notEmpty,
            decoration: _defaultDecoration('Unidades', (widget.selection.unidad == "U")?"unidad(es)":widget.selection.unidad),
          ),
        )
      ],
    );
  }

  void _agregar() async {
    if(_formKey.currentState.validate()){

      num _units = num.parse(unitsController.text);
      num _price = num.parse(priceController.text);

      Producto product = Producto(widget.selection, _units, _price);
      
      //2930301000

      SharedPreferences prefs = await SharedPreferences.getInstance();

      List<String> items = prefs.getStringList('items')??[];

      if(items != null){
        if(items.isEmpty){

          items.add(jsonEncode(Summary(product)));
          prefs.setStringList('items', items );

        }else{
          if(product.info.fixed == false){

            bool found = false;

            for(var i = 0; i < items.length; i++){
              Summary curr = Summary.fromJson(jsonDecode(items[i]));

              bool first = product.info.av == curr.avPCT;
              bool second = product.info.isc == curr.iscPCT;
              bool third = product.info.seguro ==curr.seguroPCT;

              if(first && second  && third){
                curr.increase(product);
                items[i] = jsonEncode(curr);
                prefs.setStringList('items', items);
                found = true;
              }
            }

            if(!found){
              items.add(jsonEncode(Summary(product)));
              prefs.setStringList('items', items);
            }
          }else{
            items.add(jsonEncode(Summary(product)));
            prefs.setStringList('items', items);
          }
          
        }
      }else{
        items = [jsonEncode(Summary(product))];
        prefs.setStringList('items', items);
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (BuildContext context) => HomePage(prefs: prefs)),
        ModalRoute.withName('/home'),
      );

    }
  }

  Widget _buildSingle(){
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildForm(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: buildButton("Agregar", _agregar, 16, 8),
            )  
          ],
        ),
    );
  }

  @override
  void dispose(){
    nameController.dispose();
    priceController.dispose();
    unitsController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    return SingleChildScrollView(
      child: _buildSingle(),
    );
  }
}