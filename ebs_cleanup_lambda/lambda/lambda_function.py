
import boto3
import logging
from datetime import datetime, timezone, timedelta

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    ec2_global = boto3.client('ec2')
    regions = [r['RegionName'] for r in ec2_global.describe_regions()['Regions']]
    now = datetime.now(timezone.utc)
    threshold = now - timedelta(days=7)

    for region in regions:
        logger.info(f"Checking region: {region}")
        ec2 = boto3.client('ec2', region_name=region)
        
        try:
            volumes = ec2.describe_volumes(Filters=[{'Name': 'status', 'Values': ['available']}])['Volumes']
        except Exception as e:
            logger.error(f"Failed to get volumes in {region}: {str(e)}")
            continue

        for volume in volumes:
            vol_id = volume['VolumeId']
            created = volume['CreateTime']

            if created < threshold:
                logger.info(f"📦 Old available volume found: {vol_id} (Created: {created})")

                try:
                    snapshot = ec2.create_snapshot(
                        VolumeId=vol_id,
                        Description=f"Snapshot before deleting {vol_id}"
                    )
                    snapshot_id = snapshot['SnapshotId']
                    logger.info(f"📸 Snapshot created: {snapshot_id}")
                except Exception as e:
                    logger.error(f"❌ Failed snapshot for {vol_id}: {str(e)}")
                    continue

                try:
                    ec2.delete_volume(VolumeId=vol_id)
                    logger.info(f"🗑️ Deleted volume: {vol_id}")
                except Exception as e:
                    logger.error(f"❌ Failed to delete volume {vol_id}: {str(e)}")

    return {"status": "done"}
