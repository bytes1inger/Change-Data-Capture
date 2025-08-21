# Tested and Untested Configurations

## Tested Configurations

The following configurations have been tested and confirmed working:

### Source Connectors
- `connectors/source-src1.json`: Source connector for src1 database

### Sink Connectors
- `connectors/debezium-sink-users.json`: Sink connector for users table
- `connectors/debezium-sink.json`: Sink connector for orders table

### Scripts
- `generate_orders.sh`: Script to generate test data

## Untested Configurations

The following configurations have not been fully tested:

### Source Connectors
- `connectors/source-src2.json`: Source connector for src2 database
- `connectors/source-src3.json`: Source connector for src3 database

### Sink Connectors
- `connectors/sink-src1.json`: Original sink connector configuration
- `connectors/sink-src1-modified.json`: Modified sink connector configuration
- `connectors/sink-src1-simple.json`: Simplified sink connector configuration
- `connectors/sink-src1-fields.json`: Fields-based sink connector configuration
- `connectors/sink-src2-modified.json`: Modified sink connector for src2
- `connectors/sink-src3-modified.json`: Modified sink connector for src3
- `connectors/sink-debezium.json`: Alternative Debezium sink configuration

## Next Steps

To fully test the multi-source CDC pipeline:

1. Test the source connectors for src2 and src3
2. Verify that data from all three sources is properly merged in the destination database
3. Test the sink connectors with different configurations
4. Implement error handling and monitoring
