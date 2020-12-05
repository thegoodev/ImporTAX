import 'main.dart';
import 'items.dart';
import 'selector.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'data.dart';

var f = new NumberFormat("#,##0.00", "en_US");

TextStyle numStyle = TextStyle(fontFamily: 'Montserrat');

enum DeleteAction {
  cancel,
  agree,
}

class Product extends StatefulWidget{
  Product({this.producto, this.single, this.prefs, this.sumId});

  final Producto producto;
  final bool single;
  final SharedPreferences prefs;
  final String sumId;

  @override
  ProductState createState() => new ProductState();
}

class ProductState extends State<Product>{
  
  final TextStyle _cifStyle = TextStyle(color: Colors.green, fontSize: 16.0);

  Widget _title(){
    return Text(
      widget.producto.info.nombre,
      style: TextStyle(fontSize: 18.0),
    );
  }

  Widget _subTitle(){
    return Text(
      widget.producto.productDescription(),
      style: numStyle.copyWith(color: Colors.black38),
    );
  }

  Widget _cif(bool single){
    return Text(
      (single)?f.format(widget.producto.cif.total):widget.producto.cif.getValNi(),
      style: (single)?_cifStyle: _cifStyle.copyWith(color: Colors.black38),
    );
  }

  @override
  Widget build(BuildContext context){
    return BlockContainer(
      key: UniqueKey(),
      border: !widget.single,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _title(),
          _subTitle()
      ]),
      trailing: _cif(!widget.single),
      onTap: (){Navigator.push(context, MaterialPageRoute(
        builder: (context) => Detail(widget.producto, widget.prefs, widget.sumId)
      ));},
    );
  }
}

class Header extends StatefulWidget{
  Header({this.sumary});

  final Summary sumary;

  @override
  HeaderState createState() => new HeaderState();
}

class HeaderState extends State<Header>{

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(top: 8.0, bottom: 8.0, left: 16.0, right: 16.0),
        decoration: BoxDecoration(
          border: BorderDirectional(
            bottom: BorderSide(color: Colors.black12, width: 1.5),
          )
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Expanded(
              child: Text(
                f.format(widget.sumary.total),
                style: numStyle.copyWith(fontSize: 16, color: Colors.black38),
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                f.format(widget.sumary.impuesto.total),
                style: numStyle.copyWith(fontSize: 16,color: Colors.blue)
            ),
            ),
            Text(
              f.format(widget.sumary.cif.total),
              style: numStyle.copyWith(fontSize: 16,color: Colors.green)
            ),
        ],
        ),
      );
  }
}

class Group extends StatefulWidget{
  Group(this.summary, this.prefs);

  final Summary summary;
  final SharedPreferences prefs;

  @override
    GroupState createState() => new GroupState();
}

class GroupState extends State<Group>{
  @override
  Widget build(BuildContext context) {

      Widget body = Text("Nadie debe ver esto");

      if(widget.summary.productos.length == 1){

        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Header(sumary: widget.summary),
            Product(producto: widget.summary.productos[0], single: true, prefs: widget.prefs, sumId: widget.summary.id,)
          ],
        );

      }else{
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Header(sumary: widget.summary),
            ListBody(
              children: widget.summary.productos.map((p)=>Product(producto: p, single: false, prefs: widget.prefs, sumId: widget.summary.id,)).toList(),
            )
          ],
        );
      }

      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black26
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: body,
      ));
    }
}

class BlockContainer extends StatelessWidget{
  BlockContainer({Key key, @required this.body, this.icon, this.trailing, this.onTap, this.border}): super(key: key);

  final Widget body;
  final Icon icon;
  final Widget trailing;
  final Function onTap;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 4.0),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(left: 8.0, right: (icon==null)?0.0:8.0),
            child: icon
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 8.0, right: 16, bottom: 12.0,top: 8.0),
              decoration: border?BoxDecoration(
                border: BorderDirectional(
                bottom: BorderSide(color: Colors.black12),
              )):BoxDecoration(),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: body
                  ),
                  (trailing == null)?SizedBox(height: 1.0, width:1.0):trailing
                ],
              ),
            ),
          )
        ],
      ),
    )
    );
  }
}

class Detail extends StatefulWidget{
  Detail(this.producto,this.prefs, this.sumId);

 final Producto producto;
 final SharedPreferences prefs;
 final String sumId;

  @override
  DetailState createState() => DetailState();
}

Widget showImpuesto(Producto p){
  Impuesto i = p.impt;
 if(i.message == "No se cobra impuesto por montos menores a 200 USD"){
   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: <Widget>[
    BlockContainer(
      border: true,
      body: Text("IGV(18%)", style: sub,),
      trailing: Text(f.format(i.igv)),
    ),
    BlockContainer(
      border: true,
      body: Text("Percepción (3.5%)", style: sub,),
      trailing: Text(f.format(i.percepcion)),
    ),     
   ]);
 }else{
   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: <Widget>[
    BlockContainer(
      border: true,
      body: Text("Ad valorem ("+p.info.av.toString()+"%)",style: sub,),
      trailing: Text(f.format(i.adValorem)),
    ),
    BlockContainer(
      border: true,
      body: Text("IGV(18%)", style: sub,),
      trailing: Text(f.format(i.igv)),
    ),
    BlockContainer(
      border: true,
      body: Text("Impuesto Selectivo al Consumo ("+p.info.isc.toString()+"%)", style: sub,),
      trailing: Text(f.format(i.isc)),
    ),
    BlockContainer(
      border: true,
      body: Text("Percepción (3.5%)", style: sub,),
      trailing: Text(f.format(i.percepcion)),
    ),     
   ]);
 }
}

_launchURL() async {
  const url = 'http://www.aduanet.gob.pe/servlet/AICONSMrestri';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

Widget buildDetail(Producto producto, bool single, BuildContext context, SharedPreferences prefs, String sumID){
    Impuesto i = producto.impt;
    num pctTotal = (producto.info.isc*100 + producto.info.av*100 + 3.5 +18);

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          BlockContainer(
            border: false,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(producto.info.nombre, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(producto.info.partida, style: TextStyle(fontSize: 16,color: Colors.black54))
              ],
            ),
            trailing: (single)?IconButton(icon: Icon(Icons.delete_outline, color: Colors.black38,), onPressed: (){deleteProduct(producto, context, prefs, sumID, single );},): null,
          ),
          Padding(
            padding: EdgeInsets.all(18.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Impuesto '+ '('+pctTotal.toStringAsFixed(2)+'%)', style: bigger.copyWith(color: Colors.blue)),
                Text(i.getTotalStr())
              ],
            )
          ),
          showImpuesto(producto),
          Padding(
            padding: EdgeInsets.all(18.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('CIF'+ '('+(100-pctTotal).toStringAsFixed(2)+'%)', style: bigger.copyWith(color: Colors.green)),
                Text(f.format(producto.cif.total))
              ],
            )
          ),
          BlockContainer(
            border: true,
            body: Text("Seguro de viaje ("+producto.cif.pct.toStringAsFixed(2)+"%)", style: sub,),
            trailing: Text(producto.cif.getValSeguro()),
          ),
          BlockContainer(
            border: true,
            body: Text("Sin Impuesto", style: sub,),
            trailing: Text(producto.cif.getValNi()),
          ),
          Padding(
            padding: EdgeInsets.all(18.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Total', style: bigger),
                Text(f.format(producto.total))
              ],
            )
          ),
          GestureDetector(
            onTap: _launchURL,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  child: Icon(Icons.info_outline, color: Colors.red),
                ),
                Expanded(
                  child: Text("Este producto podría estar restringido, has click aquí para averiguarlo", style: TextStyle(color: Colors.red),),
                )
              ],)
            ),
          )
        ],
      );
  }

void deleteProduct(Producto producto, BuildContext context, SharedPreferences prefs, String sumID, bool single){
  showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text('¿Estás seguro de que quieres borrar \" ${producto.info.nombre}\"?'),
      actions: <Widget>[
        FlatButton(
          child: const Text('ACEPTAR'),
          onPressed: () { Navigator.pop(context, DeleteAction.agree); }
        ),
         FlatButton(
          child: const Text('CANCELAR'),
          onPressed: () { Navigator.pop(context, DeleteAction.cancel); }
        )
      ],
    )
  ).then((value) { // The value passed to Navigator.pop() or null.
      if (value != null) {
        if(value == DeleteAction.agree){
          prefs.setString('deletePiD', producto.id);
          prefs.setString('deleteSiD', sumID);

          if(!single){
            Navigator.pop(context);
          }else{
            prefs.setStringList('items', []);
            Navigator.push(context, MaterialPageRoute( 
              builder: (context)=> ProductSelector(standAlone: false, data: loadData(),),
              fullscreenDialog: true
            ));
          }
        }
      }
  });
}

class DetailState extends State<Detail>{

  Widget _title(){
    return(Text("Detalle"));
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: _title(),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.delete_outline),color: Colors.white, onPressed: (){deleteProduct(widget.producto, context, widget.prefs, widget.sumId, false);},)
        ],
      ),
      body: SingleChildScrollView(
        child: buildDetail(widget.producto, false, context, widget.prefs, widget.sumId),
      )
    );
  }
}