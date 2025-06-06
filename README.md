# How to use Bloc for infinite scroll in Flutter DataTable (SfDataGrid)?.

In this article, we will show how to use Bloc for infinite scroll in [Flutter DataTable](https://www.syncfusion.com/flutter-widgets/flutter-datagrid).

Step 1- Set up your BLoC architecture:

Start by creating the Bloc that listens for events. When an event is triggered, it emits either a loaded state with a list of Employee objects or an error state in case of failure. Wrap your SfDataGrid in a BlocListener to respond to state changes. When the EmployeeLoaded state is emitted for the first time, set a flag variable to prevent multiple triggers.

```dart
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
```

Step 2- Enable infinite scroll:

Override the [handleLoadMoreRows()](https://pub.dev/documentation/syncfusion_flutter_datagrid/latest/datagrid/DataGridSource/handleLoadMoreRows.html) method in your DataGridSource to fetch additional data when the user scrolls near the bottom of the grid. Use a Completer along with a Bloc stream listener to wait for new data and update the grid accordingly. The SfDataGrid widget provides the [loadMoreViewBuilder](https://pub.dev/documentation/syncfusion_flutter_datagrid/latest/datagrid/SfDataGrid/loadMoreViewBuilder.html) callback, which can be used to display a loading spinner while more rows are being fetched. This builder invokes loadMoreRows(), triggering the actual data-fetching process. When listening to the Bloc stream inside handleLoadMoreRows(), always cancel the subscription after the Future completes to avoid memory leaks.

```dart
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
```

You can download this example on [GitHub](https://github.com/SyncfusionExamples/How-to-use-Bloc-for-infinite-scroll-in-Flutter-DataTable).