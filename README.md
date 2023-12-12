|#|Command|Description|Note|
|-|-|-|-|
|1|`openstack server add port <server> <port>`|Add port to server||
|2|`openstack image create --disk-format qcow2 --container-format bare --public --file <PATH_TO_QCOW2_FILE> <IMAGE_NAME>`|Create a Glance image||
|3|`openstack stack update --rollback enabled --existing --wait $STACK_IDENT`|Stack rollback update with UUID or name.||
