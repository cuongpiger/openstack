import openstack
from openstack.connection import Connection

conn: Connection = openstack.connect(cloud='openstack')

record: object
for record in conn.list_flavors():
    print(record)
