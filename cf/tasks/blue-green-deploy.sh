#!/bin/bash

set -e

version=`cat version/number`

app_name=${CF_APP_NAME}-${version}

green_app_route=${CF_HOSTNAME}-${version}
green_app_route="${green_app_route//./_}"

cf login -a $CF_API -u $CF_USERNAME -p $CF_PASSWORD -o $CF_ORGANIZATION -s $CF_SPACE

cf push $app_name -f app/${CF_MANIFEST} -p artifact/*.* -n $green_app_route

cf map-route $app_name $CF_DOMAIN --hostname $CF_HOSTNAME


# Get the org's spaces url
spaces_url=`cf curl /v2/organizations | jq -r '.resources[].entity | select(.name=="'"$CF_ORGANIZATION"'") | .spaces_url'`

echo "spaces_url: shows spaces in the org: ${spaces_url}"

# Get the spaces domain url
domains_url=`cf curl $spaces_url | jq -r '.resources[].entity | select(.name=="'"$CF_SPACE"'") | .domains_url'`

echo "domains_url: shows the domains in the space: ${domains_url}"

# get the guid for the domain
domain_guid=`cf curl $domains_url | jq -r '.resources[] | select(.entity.name=="'"$CF_DOMAIN"'") | .metadata.guid'`

echo "domain_guid is used to ensure we select the route in the correct domain: ${domain_guid}"

# get the routes_url for the space
routes_url=`cf curl $spaces_url |  jq -r '.resources[].entity | select(.name=="'"$CF_SPACE"'") | .routes_url'`

echo "routes_url: shows the routes in the space: ${routes_url}"

# get the apps on on the route in the domain
apps_url=`cf curl $routes_url | jq -r '.resources[].entity | select(.host=="'"$CF_HOSTNAME"'") | select(.domain_guid=="'"$domain_guid"'") | .apps_url'`

# Fetch the app names assigned to the hostname
app_names=`(cf curl $apps_url | jq -r '.resources[].entity.name')`

for name in $app_names; do
    if [ "$name" != "$app_name" ]
    then
      # TO DO: clean up blue

      echo "***Inside Clean Up*** $name *** $routes_url"

      cf unmap-route   $name  $routes_url --hostname $CF_HOSTNAME

      cf delete $name -f

    fi
done
