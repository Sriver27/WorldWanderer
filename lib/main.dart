import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

void main() {
  runApp(RestCountriesApp());
}

class RestCountriesApp extends StatefulWidget {
  @override
  _RestCountriesAppState createState() => _RestCountriesAppState();
}

class _RestCountriesAppState extends State<RestCountriesApp>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> countries = [];
  List<Map<String, dynamic>> filteredCountries = [];
  final searchController = TextEditingController();
  // bool isSearchPressed = false;
  ValueNotifier<bool> isSearchPressed = ValueNotifier<bool>(false);

  final FocusNode inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    fetchCountries();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> fetchCountries() async {
    final response =
        await http.get(Uri.parse('https://restcountries.com/v3.1/all'));

    if (response.statusCode == 200) {
      final decodedResponse = json.decode(response.body) as List<dynamic>;
      List<Map<String, dynamic>> countriesList = [];

      for (final country in decodedResponse) {
        final name = country['name']['common'];
        final capital =
            country['capital'] != null ? country['capital'][0] : 'N/A';
        final currencies = country['currencies'] != null
            ? country['currencies']
                .values
                .map((currency) => currency['name'])
                .toList()
            : ['N/A'];

        final region = country['region'] ?? 'N/A';
        final languages = country['languages'] != null
            ? country['languages'].values.toList()
            : ['N/A'];
        final population = country['population'] ?? 'N/A';
        final flag = country['flags']['png'] ?? '';

        countriesList.add({
          'name': name,
          'capital': capital,
          'currencies': currencies,
          'region': region,
          'languages': languages,
          'population': population,
          'flag': flag,
        });
      }

      setState(() {
        countries = countriesList;
        filteredCountries = countriesList;
      });
    } else {
      print('Failed to fetch countries. Error: ${response.statusCode}');
    }
  }

  void filterCountries(String query) {
    final lowerCaseQuery = query.toLowerCase();
    setState(() {
      filteredCountries = countries.where((country) {
        final name = country['name'].toLowerCase();
        final capital = country['capital'].toLowerCase();
        final languages =
            country['languages'].map((lang) => lang.toLowerCase()).toList();
        final currencies = country['currencies']
            .map((currency) => currency.toLowerCase())
            .toList();

        return name.contains(lowerCaseQuery) ||
            capital.contains(lowerCaseQuery) ||
            languages.contains(lowerCaseQuery) ||
            currencies.contains(lowerCaseQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Center(
              child: Text(
            'WorldWanderer',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 30,
            ),
          )),
          backgroundColor: Colors.black,
          //add a background image to the appbar
          flexibleSpace: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                opacity: 0.7,
                image: AssetImage('assets/bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'Countries Data',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 18.0),
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: isSearchPressed,
                          builder: (context, value, child) {
                            return Visibility(
                              visible: !value,
                              child: GestureDetector(
                                onTap: () {
                                  isSearchPressed.value = true;
                                  inputFocusNode.requestFocus();
                                },
                                child: Icon(Icons.search_outlined),
                              ),
                            );
                          },
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: isSearchPressed,
                          builder: (context, value, child) {
                            return AnimatedOpacity(
                              opacity: value ? 1.0 : 0.0,
                              duration: Duration(milliseconds: 300),
                              child: IgnorePointer(
                                ignoring: !value,
                                child: TextField(
                                  focusNode: inputFocusNode,
                                  controller: searchController,
                                  cursorHeight: 23,
                                  enabled: true,
                                  onChanged: (value) {
                                    filterCountries(value);
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Search',
                                    prefixIcon: Icon(Icons.search_outlined),
                                    suffixIcon: searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(Icons.cancel),
                                            onPressed: () {
                                              searchController.clear();
                                              filterCountries('');
                                              inputFocusNode.unfocus();
                                            },
                                          )
                                        : null,
                                    iconColor: Colors.green[600],
                                    border: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(12.0)),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
                child: ListView.builder(
              itemCount: filteredCountries.length,
              itemBuilder: (context, index) {
                final country = filteredCountries[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Card(
                    child: FutureBuilder(
                      future: Future.delayed(
                          Duration(seconds: 1)), // Simulating delay
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: ListTile(
                              leading: ShimmerCircle(radius: 25),
                              title: ShimmerRectangle(width: 150, height: 16),
                              subtitle:
                                  ShimmerRectangle(width: 100, height: 12),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return ListTile(
                            title: Text('Error retrieving data'),
                          );
                        } else {
                          return ExpansionTile(
                            leading: Image.network(
                              country['flag'],
                              width: 50,
                              height: 50,
                            ),
                            title: Text(
                              country['name'],
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Capital: ${country['capital']}',
                              style: TextStyle(
                                fontSize: 19,
                                color: Colors.grey[600],
                              ),
                            ),
                            children: [
                              ListTile(
                                title: Text(
                                  'Region: ${country['region']}',
                                  style: TextStyle(
                                    fontSize: 19,
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Population: ${country['population']}',
                                  style: TextStyle(
                                    fontSize: 19,
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Languages: ${country['languages'].join(', ')}',
                                  style: TextStyle(
                                    fontSize: 19,
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Currencies: ${country['currencies'].join(', ')}',
                                  style: TextStyle(
                                    fontSize: 19,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            )),
          ],
        ),
      ),
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  final double radius;

  const ShimmerCircle({required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
    );
  }
}

class ShimmerRectangle extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerRectangle({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
