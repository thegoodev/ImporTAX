import 'aspect.dart';
import 'dart:math';

const chars = "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

String randomString(int strlen) {
  Random rnd = new Random();
  String result = "";
  for (var i = 0; i < strlen; i++) {
    result += chars[rnd.nextInt(chars.length)];
  }
  return result;
}

class Impuesto{

  String message;
  num total = 0, adValorem = 0, igv = 0, percepcion = 0, isc = 0;

  Impuesto(this.total,this.adValorem,this.igv,this.isc);

  Impuesto.pct(num avPct, num iscPct, num cif){
    if(cif > 200){
      adValorem = cif*(avPct);
      igv = cif*0.18;
      isc = cif*(iscPct);
      percepcion = cif*(0.035);
      total = adValorem+igv+isc+percepcion;
    }else{
      igv = cif*0.18;
      percepcion = cif*(0.035);
      total = adValorem+igv+isc+percepcion;
      message = "No se cobra impuesto por montos menores a 200 USD";
    }
  }

  Impuesto.fixed(num isc, num unidades, String unidad){
    this.total = isc*unidades;
    message = "Impuesto de monto fijo calculado por $unidad";
  }

  Impuesto.from(Iterable args){
    this.total = 0;
    this.adValorem = 0;
    this.isc = 0;
    this.igv = 0;

    for(Impuesto _temp in args){
      total += _temp.total;
      adValorem += _temp.adValorem;
      isc += _temp.igv;
      igv += _temp.isc;
    }
 
  }

  Impuesto.fromJson(Map<String, dynamic> json)
    : total = json["total"],
      adValorem = json["adValorem"],
      igv = json["igv"],
      percepcion = json["percepcion"],
      isc = json["isc"],
      message = json["message"];

  Map<String, dynamic> toJson() =>{
    "total" : total,
    "adValorem": adValorem,
    "igv" : igv,
    "percepcion" : percepcion,
    "message": message,
    "isc": isc
  };

  Impuesto add(Impuesto first, Impuesto second) => Impuesto(first.total+second.total,first.adValorem+second.adValorem,first.igv+second.igv,first.isc+second.isc);

  String getTotalStr() => total.toStringAsFixed(2);

  num getPercep() => 3.5;
}

class Cif{
  num ni, seguro, total, pct;

  Cif(this.ni, this.pct){ seguro = ni*pct; total = ni+seguro; }

  Cif.from(Iterable i){
    num tmp = 0;

    for(Cif c in i){
      tmp = tmp + c.ni ;
    }

    ni = tmp;
    pct = i.elementAt(0).pct;
    
    seguro = ni*pct;
    total = ni+seguro;

  }

  Cif.fromJson(Map<String, dynamic> json)
    : ni = json["ni"],
      seguro = json["seguro"],
      total = json["total"],
      pct = json["pct"];

  Map<String, dynamic> toJson() =>{
    "ni" : ni,
    "seguro": seguro,
    "total" : total,
    "pct" : pct,
  };

  num getNi() => ni;
  void setNi(num n){ ni = n;}
  String getValNi() => f.format(ni);

  num getSeguro() => seguro;
  void setSeguro(num pct){ seguro = pct*ni;}
  String getValSeguro() => f.format(seguro);

}

class Item{

  bool fixed;
  String nombre, partida, unidad;
  num av, isc, seguro, tasa;

  Item({this.fixed, this.nombre, this.partida, this.unidad,
        this.av, this.isc, this.seguro, this.tasa});
  
  Item.fromJson(Map<String, dynamic> json)
    : fixed = json["fixed"],
      nombre = json["nombre"],
      partida = json["partida"],
      unidad = json["unidad"],
      av = json["av"],
      isc = json["isc"],
      seguro = json["seguro"],
      tasa = json["tasa"];

  Map<String, dynamic> toJson() =>{
    "fixed" : fixed,
    "nombre": nombre,
    "partida": partida,
    "unidad": unidad,
    "av": av,
    "isc": isc,
    "seguro": seguro,
    "tasa": tasa,
  };  
}

class Summary {
  
  Cif cif;
  String id;
  bool fixed;
  List productos;
  Impuesto impuesto;
  num total, seguroPCT, avPCT, iscPCT;
  
  Summary(Producto producto){
    productos = [producto];

    cif = producto.cif;
    impuesto = producto.impt;
    
    avPCT = producto.info.av;
    iscPCT = producto.info.isc;
    fixed = producto.info.fixed;
    seguroPCT = producto.info.seguro;

    total = producto.total;

    id = "s" + randomString(9);
  }

  Summary.blank(){
    total = 0;
    impuesto = Impuesto(0, 0, 0, 0);
    cif = Cif(0,0);
    productos = [];

    avPCT = 0;
    iscPCT = 0;
    id = "s" + randomString(9);
    fixed = false;
    seguroPCT = 0;
    
  }

  Summary.from(this.productos){
    id = "s" + randomString(9);
    impuesto = _sumImpuestos(productos);
    cif = sumCifs(productos);
    total = _sumImpuestos(productos).total + sumCifs(productos).total;
  }
  
  Summary.fromJson(Map<String, dynamic> json)
    : cif = Cif.fromJson(json["cif"]),
      fixed = json["fixed"],
      impuesto = Impuesto.fromJson(json["impuesto"]),
      productos = json["productos"].map((e)=>Producto.fromJson(e)).toList(),
      total = json["total"],
      seguroPCT = json["seguroPCT"],
      avPCT = json["avPCT"],
      iscPCT = json["iscPCT"],
      id = json["id"];

  static Cif sumCifs(Iterable i){
    num tmp = 0;
    for(Producto n in i){
      tmp += n.cif.getNi();
    }
    return Cif(tmp, i.elementAt(0).cif.pct);
  }

  static Impuesto _sumImpuestos(Iterable i){
    return Impuesto.from(i.map((f)=>f.impt).toList());
  }

  void increase(Producto item){
    productos.add(item);
    this.impuesto = _sumImpuestos(productos);
    this.cif = sumCifs(productos);
    this.total = impuesto.total + cif.total;
  }

  Map<String, dynamic> toJson() =>{
    "cif" : cif,
    "fixed": fixed,
    "impuesto" : impuesto,
    "productos" : productos,
    "total" : total,
    "seguroPCT": seguroPCT,
    "avPCT" : avPCT,
    "iscPCT": iscPCT,
    "id": id
  };
  
  num getTotal() => total;
  String getValTotal() => total.toStringAsFixed(2);
}

class Producto {

  Cif cif;
  String id;
  Item info;
  Impuesto impt;
  num unidades, precio, total;

  Producto(this.info, this.unidades, this.precio){
    cif = Cif(unidades*precio, info.seguro);
    if(info.fixed){
      impt = Impuesto.fixed(info.isc, unidades, info.unidad);
    }else{
      impt = Impuesto.pct(info.av, info.isc, cif.total);
    }
    total = cif.total + impt.total;
    id = "p"+randomString(9);
  }

  Producto.fromJson(Map<String, dynamic> json)
    : cif = Cif.fromJson(json["cif"]),
      info = Item.fromJson(json["info"]),
      impt = Impuesto.fromJson(json["impt"]),
      unidades = json["unidades"],
      precio = json["precio"],
      total = json["total"],
      id = json["id"];

  Map<String, dynamic> toJson() =>{
    "cif" : cif,
    "info": info,
    "impt": impt,
    "unidades": unidades,
    "precio": precio,
    "total": total,
    "id": id
  };

  String productDescription() => "$precio USD x $unidades";

  //TODO: add category icon Maybe(?

  /*Icon categoryIcon(){

  }*/

}