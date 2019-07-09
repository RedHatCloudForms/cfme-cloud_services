import React from 'react';
import { Button } from 'patternfly-react'

const RedHatCloudServicesRedirect = () => {
  return (
    <div>
      <h1>
        Services
      </h1>
      <p>
        Explore our Software-as-a-Services offerings at <a href='https://cloud.redhat.com/'>cloud.redhat.com</a>.
      </p>
      <Button href='https://cloud.redhat.com/'>
        Take me there
      </Button>
    </div>
  )
}

export default RedHatCloudServicesRedirect;
