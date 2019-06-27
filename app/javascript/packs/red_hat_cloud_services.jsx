import React, { useState, useEffect, useReducer }  from 'react';
import { TablePfProvider, Table, Filter, FormControl, Button, Checkbox, Paginator, PAGINATION_VIEW } from 'patternfly-react'
import orderBy from 'lodash/orderBy'
import RedHatCloudServicesTable from './red_hat_cloud_services_table';
import { reducer, selectRow } from './reducers';
import {  setPageWrapper, paginate } from './helper'

const filterFields = [
  {
    id: 'name',
    title: 'Name',
    placeholder: 'Filter by Name',
    filterType: 'text'
  },
  {
    id: 'type',
    title: 'Type',
    placeholder: 'Filter by Provider Type',
    filterType: 'text'
  }
];

const columns = [
  {
    label: 'Name',
    property: 'name'
  },
  {
    label: 'Type',
    property: 'type'
  },
  {
    label: 'Action',
    property: 'action'
  },
];


const RedHatCloudServices = (_props) => {
    const [state, dispatch] = useReducer(reducer, {
      sortableColumnProperty: 'name',
      currentFilterType: filterFields[0],
      currentValue: '',
      rows: [],
      sortOrderAsc: true,
      columns: [],
      pagination: {
        page: 1,
        perPage: 10,
        perPageOptions: [10, 25, 50, 100]
      },
      total: 0,
    });

    const { currentFilterType, currentValue, rows, pagination } = state;
    const setPage = setPageWrapper(state, dispatch);

    useEffect(() => {
      API.get('/api/providers?expand=resources').then(data => {
        const rows = data.resources.map( (item) => ({
          id: item.id,
          name: item.name,
          type: item.type,
          action: <Button>Synchronize</Button>,
          selected: false,
        }))
        dispatch({type: 'setRows', rows: orderBy(rows, 'name', 'asc')})
      });
    }, [])

    useEffect(() => {
      setPage()(pagination.page);
    }, [rows])

    useEffect(() => {
      dispatch({type: 'setTotal', total: rows.filter(row => row[currentFilterType.id].toLowerCase().includes(currentValue.toLowerCase())).length});
    }, [pagination])

    useEffect(() => {
      dispatch({type: 'setTotal', total: rows.filter(row => row[currentFilterType.id].toLowerCase().includes(currentValue.toLowerCase())).length});
    }, [currentValue])

    const filteredRows = rows.filter(row => row[currentFilterType.id].toLowerCase().includes(currentValue.toLowerCase()));
    const pagedRows = paginate(pagination, filteredRows);
    return (
      <div>
        <h1>
        Red Hat Cloud Services
        </h1>
        <div className="row toolbar-pf table-view-pf-toolbar">
          <form className="toolbar-pf-actions">
            <div className="form-group toolbar-pf-filter">
              <Filter>
                <Filter.TypeSelector
                  filterTypes={filterFields}
                  currentFilterType={currentFilterType}
                  onFilterTypeSelected={(filterType) => {
                    if (currentFilterType !== filterType) {
                      dispatch({ type: 'setFilterValue', value: ''});
                      dispatch({ type: 'setFilterType', filterType: filterType});
                    }
                  }}
                />
                <FormControl
                  type={currentFilterType.filterType}
                  value={currentValue}
                  placeholder={currentFilterType.placeholder}
                  onChange={({ target: { value: filterValue } }) => {
                    // setCurrentValue(filterValue);
                    dispatch({ type: 'setFilterValue', value: filterValue});
                  }}
                />
              </Filter>
            </div>
            <div class="form-group">
              <button class="btn btn-default" type="button" id="upload-selected">Upload</button>
              <button class="btn btn-default" type="button" id="Synchronize" disabled>Synchronize</button>
            </div>
          </form>
        </div>
        <RedHatCloudServicesTable
          columns={columns}
          rows={pagedRows}
          dispatch={dispatch}
          state={state}
        />
      </div>
    );
};

export default RedHatCloudServices;
