#!/bin/bash
# Thermal Monitor Daemon
# Runs powermetrics and writes thermal pressure to a file

OUTPUT_FILE="/tmp/mac-throttle-thermal-state"

while true; do
    # Run powermetrics for one sample and extract thermal pressure
    THERMAL_OUTPUT=$(powermetrics -s thermal -n 1 -i 1 2>/dev/null | grep -i "Current pressure level")

    # Extract the pressure level (Nominal, Moderate, Heavy, Critical)
    # Note: "trapping" and "sleeping" from powermetrics are both mapped to "critical"
    if echo "$THERMAL_OUTPUT" | grep -qi "sleeping"; then
        PRESSURE="critical"
    elif echo "$THERMAL_OUTPUT" | grep -qi "trapping"; then
        PRESSURE="critical"
    elif echo "$THERMAL_OUTPUT" | grep -qi "heavy"; then
        PRESSURE="heavy"
    elif echo "$THERMAL_OUTPUT" | grep -qi "moderate"; then
        PRESSURE="moderate"
    elif echo "$THERMAL_OUTPUT" | grep -qi "nominal"; then
        PRESSURE="nominal"
    else
        PRESSURE="unknown"
    fi

    # Write timestamp and pressure to file
    echo "{\"pressure\":\"$PRESSURE\",\"timestamp\":$(date +%s)}" > "$OUTPUT_FILE"

    # Make readable by all users
    chmod 644 "$OUTPUT_FILE"

    # Wait before next sample
    sleep 3
done
