import React from 'react';
import { Button } from 'patternfly-react'

const RedHatCloudServicesRedirect = () => {
  return (
    <div id='red_hat_cloud_services_redirect'>
      <h1>
        {__('Services')}
      </h1>
      <p id='red_hat_cloud_services_redirect_info'>
        {__('Explore our Software-as-a-Services offerings at ')} <a href='https://cloud.redhat.com/'>cloud.redhat.com</a>.
      </p>
      <Button href='https://cloud.redhat.com/'>
        {__('Take me there')}
      </Button>
    </div>
  )
}

export default RedHatCloudServicesRedirect;
