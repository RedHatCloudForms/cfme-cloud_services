import React, { useState, useEffect, useReducer }  from 'react';
import { TablePfProvider, Table, Filter, FormControl, Button, Checkbox, Paginator, ToastNotification, PAGINATION_VIEW } from 'patternfly-react'
import orderBy from 'lodash/orderBy'
import RedHatCloudServicesTable from './red_hat_cloud_services_table';
import { reducer, selectRow } from './reducers';
import {  setPageWrapper, paginate } from './helper'

const filterFields = [
  {
    id: 'name',
    title: __('Name'),
    placeholder: 'Filter by Name',
    filterType: 'text'
  },
  {
    id: 'type',
    title: __('Type'),
    placeholder: 'Filter by Provider Type',
    filterType: 'text'
  }
];

const columns = [
  {
    label: __('Name'),
    property: 'name'
  },
  {
    label: __('Type'),
    property: 'type'
  },
  {
    label: __('Action'),
    property: 'action'
  },
];

const RedHatCloudServicesList = () => {
    const [state, dispatch] = useReducer(reducer, {
      sortableColumnProperty: 'name',
      currentFilterType: filterFields[0],
      currentValue: '',
      rows: [],
      showToast: false,
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
    const showToast = (visible) => (
      visible
      ? <ToastNotification style={{width: '100%'}} type='info' onDismiss={() => dispatch({type: 'setToastVisibility', showToast: false})}>{__('Synchronization task has been initiated.')}</ToastNotification>
      : null
    )


    useEffect(() => {
      let labelTable = {};
      API.options('/api/providers').then(options => {
        labelTable = options.data.supported_providers.reduce((obj, item) => (obj[item.type] = item.title, obj) ,{});
      }).then(
        API.get('/api/providers?expand=resources').then(data => {
          const rows = data.resources.map( (item) => ({
            id: item.id,
            name: item.name,
            type: labelTable[item.type] || __('Unknown'),
            action: <Button onClick={() => dispatch({type: 'setToastVisibility', showToast: true})}>Synchronize</Button>,
            selected: false,
          }))
          dispatch({type: 'setRows', rows: orderBy(rows, 'name', 'asc')})
        })
      );

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
          Global Synchronization
        </h1>
        <div>
          <p>
            Here is text explaining what will happen when you click on button below
          </p>
          <div class="form-group">
            <button class="btn btn-default" type="button" id="upload-selected">{__('Synchronize this Platform to Cloud')}</button>
          </div>
        </div>
        <h1>
          Provider Synchronization
        </h1>
        {showToast(state.showToast)}

        <div className="row toolbar-pf table-view-pf-toolbar">
          <form className="toolbar-pf-actions">
            <div className="form-group toolbar-pf-filter">
              <Filter>
                <Filter.TypeSelector
                  filterTypes={filterFields}
                  currentFilterType={currentFilterType}
                  onFilterTypeSelected={(filterType) => {
                    if (currentFilterType !== filterType) {
                      dispatch({ type: 'setFilter', value: '', filterType: filterType});
                    }
                  }}
                />
                <FormControl
                  type={currentFilterType.filterType}
                  value={currentValue}
                  placeholder={currentFilterType.placeholder}
                  onChange={({ target: { value: filterValue } }) => {
                    dispatch({ type: 'setFilterValue', value: filterValue});
                  }}
                />
              </Filter>
            </div>
            <div class="form-group">
              <button class="btn btn-default" type="button" id="Synchronize" disabled={rows.filter(row => row.selected == true).length == 0}>{__('Synchronize')}</button>
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

export default RedHatCloudServicesList;
