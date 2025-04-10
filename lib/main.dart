import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

void main() {
  runApp(
    BlocProvider(
      create: (context) => EmployeeBloc(),
      child: const MaterialApp(home: InfiniteScrollWithBloc()),
    ),
  );
}

class InfiniteScrollWithBloc extends StatefulWidget {
  const InfiniteScrollWithBloc({super.key});

  @override
  State<InfiniteScrollWithBloc> createState() => _InfiniteScrollWithBlocState();
}

class _InfiniteScrollWithBlocState extends State<InfiniteScrollWithBloc> {
  late EmployeeDataSource _dataSource;
  bool _hasLoadedInitially = false;

  @override
  void initState() {
    super.initState();
    _dataSource = EmployeeDataSource(context);
    BlocProvider.of<EmployeeBloc>(
      context,
    ).add(FetchEmployees(startIndex: 0, count: 20));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Infinite Scroll with Bloc')),
      body: BlocListener<EmployeeBloc, EmployeeState>(
        listener: (context, state) {
          if (!_hasLoadedInitially && state is EmployeeLoaded) {
            _dataSource.addMoreRows(state.employees);
            if (!_hasLoadedInitially) {
              setState(() {
                _hasLoadedInitially = true;
              });
            }
          }
        },
        child:
            _hasLoadedInitially
                ? SfDataGrid(
                  source: _dataSource,
                  columnWidthMode: ColumnWidthMode.fill,
                  loadMoreViewBuilder: (context, loadMoreRows) {
                    Future<String> loadRows() async {
                      await loadMoreRows();
                      return Future<String>.value('Completed');
                    }

                    return FutureBuilder<String>(
                      future: loadRows(),
                      initialData: 'loading',
                      builder: (context, snapshot) {
                        if (snapshot.data == 'loading') {
                          return Container(
                            height: 60.0,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: BorderDirectional(
                                top: BorderSide(
                                  width: 1.0,
                                  color: Color.fromRGBO(0, 0, 0, 0.26),
                                ),
                              ),
                            ),
                            child: const CircularProgressIndicator(),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    );
                  },
                  columns: [
                    GridColumn(
                      columnName: 'id',
                      label: Container(
                        padding: EdgeInsets.all(16.0),
                        alignment: Alignment.center,
                        child: Text('ID'),
                      ),
                    ),
                    GridColumn(
                      columnName: 'name',
                      label: Container(
                        padding: EdgeInsets.all(8.0),
                        alignment: Alignment.center,
                        child: Text('Name'),
                      ),
                    ),
                    GridColumn(
                      columnName: 'designation',
                      label: Container(
                        padding: EdgeInsets.all(8.0),
                        alignment: Alignment.center,
                        child: Text(
                          'Designation',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    GridColumn(
                      columnName: 'salary',
                      label: Container(
                        padding: EdgeInsets.all(8.0),
                        alignment: Alignment.center,
                        child: Text('Salary'),
                      ),
                    ),
                  ],
                )
                : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

// -----------------------------
// Employee DataSource
// -----------------------------
class EmployeeDataSource extends DataGridSource {
  final BuildContext context;
  final List<Employee> _employees = [];
  final List<DataGridRow> _rows = [];

  EmployeeDataSource(this.context);

  @override
  List<DataGridRow> get rows => _rows;

  void addMoreRows(List<Employee> newEmployees) {
    _employees.addAll(newEmployees);
    _rows.addAll(
      newEmployees.map(
        (e) => DataGridRow(
          cells: [
            DataGridCell<int>(columnName: 'id', value: e.id),
            DataGridCell<String>(columnName: 'name', value: e.name),
            DataGridCell<String>(
              columnName: 'designation',
              value: e.designation,
            ),
            DataGridCell<int>(columnName: 'salary', value: e.salary),
          ],
        ),
      ),
    );
    notifyListeners();
  }

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells:
          row.getCells().map((e) {
            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8.0),
              child: Text(e.value.toString()),
            );
          }).toList(),
    );
  }

  @override
  Future<void> handleLoadMoreRows() async {
    final currentLength = _employees.length;

    final completer = Completer<void>();

    // Listen to the EmployeeBloc's stream to respond to loading results.
    final subscription = BlocProvider.of<EmployeeBloc>(context).stream.listen((
      state,
    ) {
      if (state is EmployeeLoaded) {
        // Add the newly fetched employees to the DataGrid source.
        addMoreRows(state.employees);
        completer.complete();
      } else if (state is EmployeeError) {
        completer.completeError(state.error);
      }
    });

    BlocProvider.of<EmployeeBloc>(
      context,
    ).add(FetchEmployees(startIndex: currentLength, count: 20));

    await completer.future;
    await subscription.cancel();
  }
}

// -----------------------------
// Employee Model
// -----------------------------
class Employee {
  final int id;
  final String name;
  final String designation;
  final int salary;

  Employee(this.id, this.name, this.designation, this.salary);
}

// -----------------------------
// Bloc Definitions
// -----------------------------
abstract class EmployeeEvent {}

class FetchEmployees extends EmployeeEvent {
  final int startIndex;
  final int count;

  FetchEmployees({required this.startIndex, required this.count});
}

abstract class EmployeeState {}

class EmployeeInitial extends EmployeeState {}

class EmployeeLoaded extends EmployeeState {
  final List<Employee> employees;

  EmployeeLoaded({required this.employees});
}

class EmployeeError extends EmployeeState {
  final String error;

  EmployeeError({required this.error});
}

class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  final int totalCount = 1000;
  final List<String> names = [
    'Alice',
    'Bob',
    'Charlie',
    'David',
    'Emma',
    'Frank',
    'Grace',
    'Hannah',
    'Isaac',
    'Jack',
    'Karen',
    'Leo',
    'Mona',
    'Nate',
    'Olivia',
  ];
  final List<String> designations = [
    'Engineer',
    'Manager',
    'Designer',
    'Developer',
    'Analyst',
  ];

  EmployeeBloc() : super(EmployeeInitial()) {
    on<FetchEmployees>((event, emit) async {
      try {
        await Future.delayed(const Duration(seconds: 1));
        int endIndex = (event.startIndex + event.count).clamp(0, totalCount);
        final random = Random();
        final employees = List.generate(endIndex - event.startIndex, (i) {
          return Employee(
            event.startIndex + i + 1,
            names[random.nextInt(names.length)],
            designations[random.nextInt(designations.length)],
            3000 + random.nextInt(2000),
          );
        });
        emit(EmployeeLoaded(employees: employees));
      } catch (e) {
        emit(EmployeeError(error: e.toString()));
      }
    });
  }
}
