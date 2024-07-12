#!/bin/bash

# set variables
OMADA_URL="https://172.16.131.26:8043"
UNAME="apiuser"
PASSWD="********"

# get controller id from the API
CONTROLLER_ID="$(curl -sk "${OMADA_URL}/api/info" | jq -r .result.omadacId)"

# login, get token, set & use cookies
#echo -e ' \n ------- login, get token, set & use cookies ------------ \n'
TOKEN="$(curl -sk -X POST -c "/tmp/omada-cookies.txt" -b "/tmp/omada-cookies.txt" -H "Content-Type: application/json" "${OMADA_URL}/${CONTROLLER_ID}/api/v2/login" -d '{"username": "'"${UNAME}"'", "password": "'"${PASSWD}"'"}' | jq -r .result.token)"
#echo "TOKEN - " $TOKEN
# once logged in, make sure you add the following header on additional API calls:
# -H "Csrf-Token: ${TOKEN}"

# validate login
##echo -e ' \n ------- validate login ------------ \n'
##curl -sk -X GET -b "/tmp/omada-cookies.txt" -H "Content-Type: application/json" -H "Csrf-Token: ${TOKEN}" "${OMADA_URL}/${CONTROLLER_ID}/api/v2/loginStatus?token=${TOKEN}" | jq .

### Get List of Sites and select SiteKey
SiteIdArray=($(curl -sk -X GET -b "/tmp/omada-cookies.txt" -H "Content-Type: application/json" -H "Csrf-Token: ${TOKEN}" "${OMADA_URL}/${CONTROLLER_ID}/api/v2/users/current" | jq  -r '.result.privilege.sites[] | .key ' ))
#SiteIdArray=$(curl -sk -X GET -b "/tmp/omada-cookies.txt" -H "Content-Type: application/json" -H "Csrf-Token: ${TOKEN}" "${OMADA_URL}/${CONTROLLER_ID}/api/v2/users/current" | jq  -r '.result.privilege.sites[] | .key ' )

case "$1" in
    "-sites")
         curl -sk -X GET -b "/tmp/omada-cookies.txt" -H "Content-Type: application/json" -H "Csrf-Token: ${TOKEN}" "${OMADA_URL}/${CONTROLLER_ID}/api/v2/users/current" | jq .
    ;;
    "-device")
    # Get the List of the Devices On One Site
    #echo -e ' \n ------- Get the List of the Devices On One Site  ------------ \n'
    printf  "{\n \"result\": [ \n"
    for SiteID in "${SiteIdArray[@]}"
    do
        curl -sk -X GET -b "/tmp/omada-cookies.txt" -H "Content-Type: application/json" -H "Csrf-Token: ${TOKEN}" "${OMADA_URL}/${CONTROLLER_ID}/api/v2/sites/$SiteID/devices" |  jq -jr '.result[] |  { name, ip, uptime, uptimeLong, statusCategory, status, site }'
    done
    printf  "]\n }\n"
    # uptimeLong  не должен быть меньше 10 минут
    # statusCategory The promlem if 0 - means Disconnected; 3 means Heartbeat Missed; 4 means Isolated.
    # status The problem if - 0 means Disconnected; and from 1 to 41
    ;;

    "-wifi")
    # Get the Wifi Summary
    #echo -e ' \n ------- Get the Wifi Summary  ------------ \n'
    printf  "{\n \"result\": [ \n"
    for SiteID in "${SiteIdArray[@]}"
    do
        curl -sk -X GET -b "/tmp/omada-cookies.txt" -H "Content-Type: application/json" -H "Csrf-Token: ${TOKEN}" "${OMADA_URL}/${CONTROLLER_ID}/api/v2/sites/$SiteID/dashboard/overviewDiagram" |  jq -jr '.result | { totalApNum, connectedApNum, totalClientNum, wirelessClientNum } '
    done
    printf  "]\n }\n"
    # - connectedApNum  не должно уменьшатся
    # - wirelessClientNum графики
    ;;

#    *)
#    echo "kurwa parameters"
esac
