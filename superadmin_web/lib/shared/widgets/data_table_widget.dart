import 'package:flutter/material.dart';

class DataTableWidget extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  final void Function(int index)? onRowTap;

  const DataTableWidget({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w600,
          ),
          dataTextStyle: Theme.of(context).textTheme.bodyMedium,
          dividerThickness: 1,
          showCheckboxColumn: false,
          columns: columns
              .map((c) => DataColumn(
                    label: Text(c),
                  ))
              .toList(),
          rows: rows.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final row = entry.value;
                  return DataRow(
                    onSelectChanged: onRowTap != null ? (_) => onRowTap!(index) : null,
                    cells: row.map((cell) => DataCell(
                      // Wrap in GestureDetector to ensure taps propagate properly for complex cells
                      onRowTap != null ? IgnorePointer(child: cell) : cell
                    )).toList(),
                  );
                },
              ).toList(),
        ),
      ),
    );
  }
}
