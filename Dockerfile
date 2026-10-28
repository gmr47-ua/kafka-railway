FROM apache/kafka:3.9.0

USER root
RUN cat > /opt/init-kafka.sh <<'EOF'
#!/bin/bash
set -e

BS=localhost:19092
T=/opt/kafka/bin/kafka-topics.sh

/__cacert_entrypoint.sh /etc/kafka/docker/run &
KAFKA_PID=$!

echo "Esperando a Kafka..."
until $T --bootstrap-server $BS --list >/dev/null 2>&1; do
  kill -0 $KAFKA_PID 2>/dev/null || { echo "Kafka se detuvo" >&2; exit 1; }
  sleep 2
done

$T --bootstrap-server $BS --create --if-not-exists --topic irrigation.requests --partitions 3 --replication-factor 1
$T --bootstrap-server $BS --create --if-not-exists --topic ws.commands --partitions 1 --replication-factor 1
$T --bootstrap-server $BS --create --if-not-exists --topic ws.telemetry --partitions 3 --replication-factor 1 --config retention.ms=3600000
$T --bootstrap-server $BS --create --if-not-exists --topic system.notifications --partitions 3 --replication-factor 1

echo "Topics creados:"
$T --bootstrap-server $BS --list

wait $KAFKA_PID
EOF
RUN chmod +x /opt/init-kafka.sh
USER appuser

ENTRYPOINT ["/opt/init-kafka.sh"]
