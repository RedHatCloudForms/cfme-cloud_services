import React, { useContext }  from 'react';
import { Table, TableCheckbox } from 'patternfly-react'
import { SortingContext } from './red_hat_cloud_services_table'

const headerFormat = value => <Table.Heading>{value}</Table.Heading>;

const cellFormat = (value, { rowData: { selected } }) => (
    <Table.Cell className={`clickable ${selected ? 'selected' : ''}`}>
      {value}
    </Table.Cell>
  );

const actionFormat = (value, { rowData: { selected } }) => (
    <Table.Actions className={`clickable ${selected ? 'selected' : ''}`}>
      {value}
    </Table.Actions>
  );


const sortableHeaderFormat = (onSort, { column: { header: { label } }, property }) => {
  const {sortOrderAsc, sortableColumnProperty} = useContext(SortingContext);
  return (
    <Table.Heading
      onClick={() => onSort(property)}
      sort={property === sortableColumnProperty}
      sortDirection={sortOrderAsc ? 'asc' : 'desc'}
      className="clickable"
    >
      {label}
    </Table.Heading>
  )
};
const sortableHeaderFormater = (value, columnProps, dispatch) => sortableHeaderFormat(
  property => dispatch({type: 'sortColumn', property}),
  columnProps,
);
export const createColumns = (showIcon, showSelect, columns, dispatch) => {
    let result = [];
    if (showIcon) {
      result = [{
        propery: 'icon',
        header: {
          label: '',
          formatters: [headerFormat],
        },
      },
      ...result];
    }
    if (showSelect) {
      result = [
        {
          propery: 'select',
          header: {
            label: '',
            formatters: [headerFormat],
          },
          cell: {
            formatters: [
              (value, { rowData }) => (
                <Table.Cell
                  onClick={(event) => {
                    event.stopPropagation();
                  }}
                  className={`clickable ${rowData.selected ? 'selected' : ''}`}
                >
                  <TableCheckbox
                    className="cell-middle"
                    checked={!!rowData.selected}
                    onClick={event => event.stopPropagation()}
                    onChange={() =>  dispatch({type: 'selectRow', selectedRow: rowData}) }
                  />
                </Table.Cell>
              ),
            ],
          },
        },
        ...result,
      ];
    }
    result = [
      ...result,
      ...columns.map(({ property, label }) => ({
        property,
        header: {
          label,
          formatters: [(value, columnProps) => sortableHeaderFormater(value, columnProps, dispatch)],
        },
        cell: {
          formatters: [property === 'action' ? actionFormat : cellFormat],
        },
      })),
    ];
    return result;
};

export const setPageWrapper = (state, dispatch) => (pagination = {...state.pagination}) => (page) => {
  const newPagination = {
    ...pagination,
    page
  };
  const limit = newPagination.perPage;
  const offset = newPagination.perPage * (newPagination.page - 1);
  dispatch({ type: 'setPagination', pagination: newPagination });
};

export const perPageSelect = (pagination, setPage) => (perPage,_e) => {
  setPage({...pagination, perPage, page: 1 })(1);
};

export const paginate = (pagination, rows) => {
  const limit = pagination.perPage;
  const offset = pagination.perPage * (pagination.page - 1);
  return rows.slice(offset, offset + limit);
}
