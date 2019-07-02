import orderBy from 'lodash/orderBy'

export const sortColumn = ({sortableColumnProperty, rows, sortOrderAsc}, {property}) => {
  const asc = sortableColumnProperty === property ? !sortOrderAsc : true;
  return {
    rows: orderBy(rows, property, asc ? 'asc' : 'desc'),
    sortableColumnProperty: property,
    sortOrderAsc: asc,
  }
}

export const selectRow = ({rows, ...rest}, {selectedRow}) => ({
  ...rest,
  rows: rows.map(item => selectedRow.id === item.id ? {...selectedRow, selected: !selectedRow.selected} : item)
});

export const reducer = (state, action) => {
  switch (action.type) {
    case 'setColumns':
      return {...state, columns: action.columns}
    case 'setRows':
      return {...state, rows: [...action.rows]}
    case 'setFilter':
      return {...state, currentValue: action.value, currentFilterType: action.filterType}
    case 'setFilterValue':
      return {...state, currentValue: action.value}
    case 'sortColumn':
      return {...state, ...sortColumn(state, action)};
    case 'selectRow':
      return {...state, ...selectRow(state, action)};
    case 'setPagination':
      return {...state, pagination: action.pagination};
    case 'setTotal':
      return {...state, total: action.total}
    case 'setToastVisibility':
      return {...state, showToast: action.showToast}
    default:
      throw 'Unknown action'

  }
}
