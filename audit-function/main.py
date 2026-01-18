import os
import functions_framework
from google.cloud import compute_v1
from google.cloud.sql.connector import Connector, IPTypes
import sqlalchemy

PROJECT_ID = os.environ.get("PROJECT_ID", "zetta-online-project")
INSTANCE_CONNECTION_NAME = os.environ.get("INSTANCE_CONNECTION_NAME", "zetta-online-project:europe-west3:ha-postgres")
DB_USER = os.environ.get("DB_USER", "root")
DB_PASS = os.environ.get("DB_PASS", "won't-say")
DB_NAME = os.environ.get("DB_NAME", "no-such-db")

def getconn():
    with Connector() as connector:
        conn = connector.connect(
            INSTANCE_CONNECTION_NAME,
            "pg8000",
            user=DB_USER,
            password=DB_PASS,
            db=DB_NAME,
            ip_type=IPTypes.PRIVATE 
        )
    return conn

pool = sqlalchemy.create_engine(
    "postgresql+pg8000://",
    creator=getconn,
)

@functions_framework.http
def list_vpcs_and_subnets(request):
    """Lists all VPCs and Subnets and saves them to Cloud SQL."""
    
    audit_results = []
    
    network_client = compute_v1.NetworksClient()
    subnetwork_client = compute_v1.SubnetworksClient()

    try:
        request_vpcs = compute_v1.ListNetworksRequest(project=PROJECT_ID)
        for network in network_client.list(request=request_vpcs):
            vpc_name = network.name
            print(f"Found VPC: {vpc_name}")

            request_subnets = compute_v1.AggregatedListSubnetworksRequest(project=PROJECT_ID)
            for region, subnets_scoped_list in subnetwork_client.aggregated_list(request=request_subnets):
                if subnets_scoped_list.subnetworks:
                    for subnet in subnets_scoped_list.subnetworks:
                        if subnet.network == network.self_link:
                            record = {
                                "vpc_name": vpc_name,
                                "subnet_name": subnet.name,
                                "region": region.split("/")[-1],
                                "cidr": subnet.ip_cidr_range
                            }
                            audit_results.append(record)

        if audit_results:
            with pool.connect() as db_conn:
                insert_stmt = sqlalchemy.text(
                    "INSERT INTO cloud_audit (vpc_name, subnet_name, region, ip_cidr_range) "
                    "VALUES (:vpc_name, :subnet_name, :region, :cidr)"
                )
                
                db_conn.execute(insert_stmt, audit_results)
                db_conn.commit()
                
        return f"Successfully audited {len(audit_results)} subnets.", 200

    except Exception as e:
        print(f"Error: {e}")
        return f"Audit failed: {e}", 500