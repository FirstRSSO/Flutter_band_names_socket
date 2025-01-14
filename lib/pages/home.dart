import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [
    // Band(id: '1', name: 'Metallica', votes: 5),
    // Band(id: '2', name: 'Queen', votes: 5),
    // Band(id: '3', name: 'Heroes del silencio', votes: 5),
    // Band(id: '4', name: 'BonJovi', votes: 5),
  ];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.on('active-bands', _handleActiveBands);

    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    bands = (payload as List).map((band) => Band.fromMap(band)).toList();
    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);
    //Provider.of(context)
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'BandNames',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: (socketService.serverStatus == ServerStatus.Offline)
                ? const Icon(Icons.offline_bolt, color: Colors.red)
                : Icon(Icons.check_circle, color: Colors.blue[300]),
            // (socketService.serverStatus == ServerStatus.Offline)
            // ? Icon(Icons.check_circle, color: Colors.blue[300]),
            // : Icon(Icons.offline_bolt, color: Colors.red),
            // Icon(Icons.check_circle, color: Colors.blue[300]),
          )
        ],
      ),
      body: Column(
        children: [
          _showGraph(),
          Expanded(
            child: ListView.builder(
                itemCount: bands.length,
                itemBuilder: (BuildContext context, int index) {
                  return _bandTile(bands[index]);
                }),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addNewBand,
        elevation: 1,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _bandTile(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);
    return Dismissible(
      key: Key(band.id ?? 'No key'),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) =>
          socketService.socket.emit('delete-band', {'id': band.id}),
      background: Container(
        padding: const EdgeInsets.only(left: 8.0),
        color: Colors.red,
        child: const Align(
            alignment: Alignment.centerLeft, child: Text('Delete Band')),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            band.name != null && band.name!.length >= 2
                ? band.name!.substring(0, 2)
                : 'NA', // Manejo del caso donde el nombre sea nulo o menor a 2 caracteres
          ),
        ),
        title: Text(
          band.name ??
              'Sin nombre', // Muestra un texto predeterminado si el nombre es nulo
        ),
        trailing: Text(
          '${band.votes}',
          style: const TextStyle(fontSize: 20),
        ),
        onTap: () => socketService.socket.emit('vote-band', {
          'id': band.id
        }), // Muestra los votos, asegurándote de que votes no sea nulo
      ),
    );
  }

  addNewBand() {
    final TextEditingController textcontroller = new TextEditingController();
    // showDialog(
    //   context: context,
    //   builder: (context) {
    //     return AlertDialog(
    //       title: const Text('New Band name:'),
    //       content: TextField(
    //         controller: textcontroller,
    //       ),
    //       actions: [
    //         MaterialButton(
    //           child: Text('Add'),
    //           elevation: 5,
    //           textColor: Colors.blue,
    //           onPressed: () => addBandToList(textcontroller.text),
    //         )
    //       ],
    //     );
    //   },
    // );

    showCupertinoDialog(
      context: context,
      builder: (_) {
        return CupertinoAlertDialog(
          title: const Text('New Band name'),
          content: CupertinoTextField(
            controller: textcontroller,
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Add'),
              onPressed: () => addBandToList(textcontroller.text),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Dismiss'),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  void addBandToList(String name) {
    if (name.length > 1) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.emit('add-band', {'name': name});
    }
    Navigator.pop(context);
  }

  Widget _showGraph() {
  // Crear el dataMap dinámicamente basado en la lista de bandas
  Map<String, double> dataMap = {
    for (var band in bands)
      if (band.name != null && band.votes != null)
        band.name!: band.votes!.toDouble(),
  };

  // Comprobar si el dataMap tiene datos antes de renderizar el gráfico
  if (dataMap.isEmpty) {
    return const Center(
      child: Text(
        "No hay datos para mostrar",
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  return Container(
    width: double.infinity,
    height: 200,
    child: PieChart(
      dataMap: dataMap,
      chartType: ChartType.ring,
      legendOptions: LegendOptions(
        showLegends: true,
        legendPosition: LegendPosition.right,
      ),
      chartValuesOptions: ChartValuesOptions(
        showChartValuesInPercentage: true,
      ),
    ),
  );
}
}
