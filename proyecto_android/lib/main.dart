import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        home: MyHomePage(),
      ),
    ),
  );
}

class MyAppState extends ChangeNotifier {
  var pokemonesCapturados = <Map<String, dynamic>>[];

  void agregarPokemonCapturado(Map<String, dynamic> pokemon) {
    pokemonesCapturados.add(pokemon);
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = PokeBusqueda();
        break;
      case 1:
        page = PokeMap();
        break;
      case 2:
        page = PokeCapturadosPage();
        break;
      default:
        throw UnimplementedError('Esta vista no existe');
    }

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: false,
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.search),
                  label: Text('Pokedex'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.map),
                  label: Text('Poke-Mapa'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.catching_pokemon),
                  label: Text('Capturados'),
                ),
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) {
                setState(() {
                  selectedIndex = value;
                });
              },
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: page,
            ),
          ),
        ],
      ),
    );
  }
}

class PokeBusqueda extends StatefulWidget {
  @override
  PokeBusquedaState createState() => PokeBusquedaState();
}

class PokeBusquedaState extends State<PokeBusqueda> {
  TextEditingController controller = TextEditingController();
  String pokemonName = "";
  String pokemonGif = "";
  String pokemonWeight = "";
  String pokemonHeight = "";
  String pokeError = "";

  void requestPokemon() async {
    try {
      var response = await http.post(
        Uri.parse('https://ngft24cd-3000.use2.devtunnels.ms/pokemon'),
        headers: {'Content-Type': 'text/plain'},
        body: controller.text,
      );
      var data = jsonDecode(response.body);
      if (response.statusCode == 404) {
        setState(() {
          pokemonName = 'Pokemon no encontrado.';
          pokemonGif = '';
          pokemonWeight = '';
          pokemonHeight = '';
          pokeError = '';
        });
      }
      if (response.statusCode == 200) {
        setState(() {
          pokemonName = data['nombre'];
          pokemonGif = data['img'];
          pokemonWeight = data['peso'].toString();
          pokemonHeight = data['altura'].toString();
          pokeError = '';
        });
      }
    } catch (e) {
      setState(() {
        pokemonName = 'El servidor no está funcionando.';
        pokeError = 'Verifique su conexion a internet e intentelo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Pokedex'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Nombre o ID de Pokemon...',
              ),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: requestPokemon,
            child: Text('Buscar Pokemon'),
          ),
          SizedBox(height: 20),
          Text(pokemonName.toUpperCase()),
          SizedBox(height: 10),
          pokemonGif != "" ? Image.network(pokemonGif) : Text(''),
          pokemonHeight != "" ? Text("Altura: $pokemonHeight") : Text(''),
          pokemonWeight != "" ? Text("Peso: $pokemonWeight") : Text(''),
          Text(pokeError)
        ],
      ),
    );
  }
}

class PokeMap extends StatefulWidget {
  @override
  PokeMapState createState() => PokeMapState();
}

class PokeMapState extends State<PokeMap> {
  final markers = <MarkerId, Marker>{};
  final circles = <CircleId, Circle>{};
  final Completer<GoogleMapController> controller = Completer<GoogleMapController>();
  Position? _currentPosition;
  double _radarRadius = 0;
  Timer? _radarTimer;
  Timer? _pokeTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startRadarEffect();
    _startPokeRandom();
  }

  @override
  void dispose() {
    _radarTimer?.cancel();
    _pokeTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    _currentPosition = await LocationHandler.getCurrentPosition();
    if (_currentPosition != null) {
      LatLng currentLatLng =
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      final GoogleMapController mapController = await controller.future;
      mapController.animateCamera(CameraUpdate.newLatLngZoom(currentLatLng, 17));
    }
    Geolocator.getPositionStream().listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  void _startPokeRandom() {
    _pokeTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      var locationData = jsonEncode({
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude
      });
      try {
        var response = await http.post(
          Uri.parse('https://ngft24cd-3001.use2.devtunnels.ms/localizacion'),
          headers: {'Content-Type': 'application/json'},
          body: locationData,
        );
        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          if (mounted) {
            marcarPokemon(data['lat'], data['lng'], data['pokemonData']);
          }
        }
      } catch (e) {
        print('Error en la solicitud: $e');
      }
    });
  }

  Future<Uint8List> _convertImageUrlToBytes(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    final bytes = response.bodyBytes;
    return bytes;
  }

  void marcarPokemon(double lat, double lng, Map<String, dynamic> pokemonData) async {
    final markerId = MarkerId('pokemon_${pokemonData['id']}');
    final iconBytes = await _convertImageUrlToBytes(pokemonData['img']);

    final marker = Marker(
      markerId: markerId,
      position: LatLng(lat, lng),
      icon: BitmapDescriptor.fromBytes(iconBytes),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext modalContext) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: Image.memory(iconBytes, width: 50, height: 50),
                  title: Text(pokemonData['nombre'].toUpperCase()),
                  subtitle: Text("ID: ${pokemonData['id']}"),
                ),
                ElevatedButton(
                  child: Text("Capturar"),
                  onPressed: () {
                    Navigator.pop(modalContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CapturaPage(pokemonData, markerId, eliminarMarker),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
    if (mounted) {
      setState(() {
        markers[markerId] = marker;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Un Pokémon ha aparecido cerca!'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void capturarPokemon(Map<String, dynamic> pokemonData) {
    var appState = context.read<MyAppState>();
    appState.agregarPokemonCapturado(pokemonData);
  }

  void eliminarMarker(MarkerId markerId) {
    setState(() {
      markers.remove(markerId);
    });
  }

  void _startRadarEffect() {
    _radarTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          if (_currentPosition != null) {
            _radarRadius += 1;
            if (_radarRadius > 30) {
              _radarRadius = 0;
            }
            _updateRadarEffect(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
          }
        });
      }
    });
  }

  void _updateRadarEffect(LatLng position) {
    final circleId = CircleId('radar_effect');
    final radarCircle = Circle(
      circleId: circleId,
      center: position,
      radius: _radarRadius,
      strokeColor: Colors.blue.withOpacity(0.5),
      fillColor: Colors.blue.withOpacity(0.1),
      strokeWidth: 1,
    );
    if (mounted) {
      setState(() {
        circles[circleId] = radarCircle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PokeMapa'),
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController mapController) {
          controller.complete(mapController);
        },
        markers: Set<Marker>.of(markers.values),
        circles: Set<Circle>.of(circles.values),
        initialCameraPosition: CameraPosition(
          target: LatLng(0, 0),
          zoom: 17,
        ),
        myLocationEnabled: true,
      ),
    );
  }
}

class CapturaPage extends StatefulWidget {
  final Map<String, dynamic> pokemonData;
  final MarkerId markerId;
  final Function(MarkerId) onMarkerCaptured;

  CapturaPage(this.pokemonData, this.markerId, this.onMarkerCaptured);
  @override
  CapturaPageState createState() => CapturaPageState();
}

class CapturaPageState extends State<CapturaPage> {
  bool pokemonCapturado = false;

  @override
  void initState() {
    super.initState();
    accelerometerEvents.listen((AccelerometerEvent event) {
      if ((event.x.abs() > 15.0 || event.y.abs() > 15.0 || event.z.abs() > 15.0) && !pokemonCapturado) {
        capturarPokemon();
      }
    });
  }

  List<Map<String, dynamic>> pokemonCapturados = [];

  void capturarPokemon() {
    var appState = context.read<MyAppState>();
    setState(() {
      pokemonCapturado = true;
      pokemonCapturados.add(widget.pokemonData);
      appState.agregarPokemonCapturado(widget.pokemonData);
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("${widget.pokemonData['nombre'].toUpperCase()} ha sido capturado!"),
      duration: Duration(seconds: 2),
    ));

    widget.onMarkerCaptured(widget.markerId);

    Future.delayed(Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Capturar ${widget.pokemonData['nombre']}")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text("Mueve tu dispositivo bruscamente para capturar a ${widget.pokemonData['nombre'].toUpperCase()}"),
            Image.network(widget.pokemonData['img']),
            SizedBox(height: 20),
            if (!pokemonCapturado)
              Text("¡Listo para capturar!")
            else
              Text("${widget.pokemonData['nombre'].toUpperCase()} ha sido capturado!"),
          ],
        ),
      ),
    );
  }
}

class PokeCapturadosPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    if (appState.pokemonesCapturados.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("PokeCapturas")),
        body: Center(
          child: Text(
            'No has capturado ningún Pokémon.',
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text("PokeCapturas")),
      body: ListView(
        children: [
          for (var pokemon in appState.pokemonesCapturados)
            ListTile(
              leading: Image.network(pokemon['img']),
              title: Text(pokemon['nombre'].toUpperCase()),
              subtitle: Text("ID: ${pokemon['id']}"),
            ),
        ],
      ),
    );
  }
}

class LocationHandler {
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error(
          'Los servicios de localización están deshabilitados.');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Los permisos de ubicación fueron denegados');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Los permisos de ubicación están permanentemente denegados');
    }
    return await Geolocator.getCurrentPosition();
  }
}