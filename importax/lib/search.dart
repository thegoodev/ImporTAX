import 'package:flutter/material.dart';
import 'aspect.dart';
import 'selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchArancelDelegate extends SearchDelegate<String> {
  SearchArancelDelegate({this.data, this.prefs});

  //Toda la información en la que va a buscar
  Map data;
  SharedPreferences prefs;

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: AnimatedIcon(
        //May not animated?
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    bool find(e) =>
        "${e["nombre"]}".contains(query.toUpperCase()) ||
        "${e["nombre"]}".contains(query);
    List _secc = data["secciones"]
        .where((e) => find(e))
        .map((e) => "${e["nombre"]}")
        .toList();
    List _prod = data["allProductos"]
        .where((e) => find(e))
        .map((e) => "${e["nombre"]}")
        .toList();

    _secc.addAll(_prod);

    final suggestions = query.isEmpty ? getHistory("history", prefs) : _prod;

    return _SuggestionList(
      query: query,
      suggestions: suggestions,
      onSelected: (String suggestion) {
        query = suggestion;
        showResults(context);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final searched = query;
    addToHistory("history", searched, prefs);
    bool find(e) =>
        "${e["nombre"]}".contains(query.toUpperCase()) ||
        "${e["nombre"]}".contains(query);
    List results = data["allProductos"].where((e) => find(e)).toList();

    if (searched == null) {
      return Center(
        child: Text(
          '\"$query\"\n no se ha encontrado.\nIntente otra vez.', //Placeholder text
          textAlign: TextAlign.center,
        ),
      );
    }
    return _ResultList(
      results: results,
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    //Muestra la X para borrar el contenido
    return <Widget>[
      query.isEmpty
          ? SizedBox(
              width: 1,
              height: 1,
            )
          : IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.clear),
              onPressed: () {
                query = '';
                showSuggestions(context);
              },
            )
    ];
  }
}

class SearchProdDelegate extends SearchDelegate<String> {
  SearchProdDelegate({this.data, this.prefs, this.id});

  //Toda la información en la que va a buscar
  List data;
  SharedPreferences prefs;
  String id;

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: AnimatedIcon(
        //May not animated?
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    bool find(e) =>
        "${e["nombre"]}".contains(query.toUpperCase()) ||
        "${e["nombre"]}".contains(query);
    List _prod =
        data.where((e) => find(e)).map((e) => "${e["nombre"]}").toList();

    final suggestions = query.isEmpty ? getHistory("history$id", prefs) : _prod;

    return _SuggestionList(
      query: query,
      suggestions: suggestions,
      onSelected: (String suggestion) {
        query = suggestion;
        showResults(context);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final searched = query;
    bool find(e) => "${e["nombre"]}".contains(query);
    List results = data.where((e) => find(e)).toList();

    if (searched == null) {
      return Center(
        child: Text(
          '\"$query\"\n no se ha encontrado.\nIntente otra vez.', //Placeholder text
          textAlign: TextAlign.center,
        ),
      );
    }

    addToHistory("history$id", searched, prefs);

    return _ResultList(
      results: results,
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    //Muestra la X para borrar el contenido
    return <Widget>[
      query.isEmpty
          ? SizedBox(
              width: 1,
              height: 1,
            )
          : IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.clear),
              onPressed: () {
                query = '';
                showSuggestions(context);
              },
            )
    ];
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({this.results});

  final List results;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (BuildContext context, int i) {
        final result = results[i];

        int max = 1;
        String head = result["nombre"];
        String description = result["subcat"];

        if (description == "ninguna") {
          head = result["nombre"];
          description = "No hay descripción disponible";
          max = 100;
        }

        return BlockContainer(
          border: false,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(head,
                  maxLines: max,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(result["partida"],
                  style: TextStyle(fontSize: 16, color: Colors.black54)),
              Text(description, style: TextStyle(fontSize: 16))
            ],
          ),
          onTap: () {
            select(result, context, false);
          },
        );
      },
    );
  }
}

List<String> getHistory(String key, SharedPreferences prefs) {
  List<String> history = prefs.getStringList(key) ?? [];

  return history;
}

void addToHistory(String key, String e, SharedPreferences prefs) {
  List<String> history = prefs.getStringList(key) ?? [];

  List<String> unique = [];

  history.add(e);

  for (var h in history) {
    if (!unique.contains(h)) {
      unique.add(h);
    }
  }

  prefs.setStringList(key, unique);
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({this.suggestions, this.query, this.onSelected});

  final List suggestions;
  final String query;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (BuildContext context, int i) {
        final String suggestion = suggestions[i];
        int z = 0;
        if (query.isNotEmpty) {
          if (suggestion.indexOf(query) == -1) {
            z = suggestion.indexOf(query.toUpperCase());
          } else {
            z = suggestion.indexOf(query);
          }
        }
        return ListTile(
          leading: query.isEmpty ? const Icon(Icons.history) : const Icon(null),
          title: RichText(
            text: TextSpan(
              text: suggestion.substring(0, z),
              style: theme.textTheme.labelSmall,
              children: <TextSpan>[
                TextSpan(
                  text: suggestion.substring(z, z + query.length),
                  style: theme.textTheme.labelSmall
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: suggestion.substring(z + query.length),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          onTap: () {
            onSelected(suggestion);
          },
        );
      },
    );
  }
}
