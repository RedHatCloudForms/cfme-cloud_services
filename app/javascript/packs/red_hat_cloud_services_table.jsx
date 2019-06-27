import React, { useEffect }  from 'react';
import { TablePfProvider, Table, Filter, FormControl, Button, Checkbox, Paginator, PAGINATION_VIEW } from 'patternfly-react'
import { reducer, selectRow } from './reducers'
import { createColumns, setPageWrapper, perPageSelect } from './helper'

export const SortingContext = React.createContext();

const RedHatCloudServicesTable = (props) => {
  const { state, dispatch } = props;

  useEffect(() => {
    dispatch({ type: 'setColumns', columns: createColumns(false, true, props.columns, dispatch, props.selectRow) });
  }, [])

  const setPage = setPageWrapper(state, dispatch);
  const { PfProvider, Body, Header } = Table;

  return (
    <SortingContext.Provider value={{sortOrderAsc: state.sortOrderAsc, sortableColumnProperty: state.sortableColumnProperty}}>
      <PfProvider
         striped
         bordered
         columns={state.columns}
         dataTable
         hover
         className="generic-preview-table"
       >
         <Header />
         <Body
           rows={props.rows}
           rowKey={'id'}
         />
      </PfProvider>
      <Paginator
        viewType={PAGINATION_VIEW.TABLE}
        pagination={state.pagination}
        itemCount={state.total}
        onPageSet={setPage()}
        onPerPageSelect={perPageSelect(state.pagination, setPage)}
      />
    </SortingContext.Provider>
  );
};

export default RedHatCloudServicesTable;
