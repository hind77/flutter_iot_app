import time
import json
import random
import paho.mqtt.client as mqtt

# Configuration
BROKER = "broker.hivemq.com"
PORT = 1883
TOPIC_PREFIX = "hind_iot_demo/001/sensors" # Changed to unique topic

client = mqtt.Client()

def on_connect(client, userdata, flags, rc):
    print(f"Connected with result code {rc}")
    # Subscribe to commands
    cmd_topic = f"hind_iot_demo/001/commands/#"
    client.subscribe(cmd_topic)
    print(f"Subscribed to commands: {cmd_topic}")

def on_message(client, userdata, msg):
    payload = msg.payload.decode()
    topic = msg.topic
    print(f"ACTUATOR COMMAND RECEIVED: {topic} -> {payload}")
    
    # Extract actuator ID from topic: hind_iot_demo/001/commands/ACTUATOR_ID
    # We can use this to adjust simulation base values later if needed
    if "kitchen_fan" in topic:
        print(f"FAN STATUS UPDATED: {payload}")
    elif "living_room_light" in topic:
        print(f"LIGHT STATUS UPDATED: {payload}")
    elif "ac_unit" in topic:
        print(f"AC UNIT STATUS UPDATED: {payload}")

client.on_connect = on_connect
client.on_message = on_message
client.loop_start()

def simulate_sensors():
    print(f"Connecting to {BROKER}...")
    client.connect(BROKER, PORT, 60)
    
    sensors = {
        "temperature": {"unit": "°C", "base": 22.0, "range": 5.0},
        "humidity": {"unit": "%", "base": 45.0, "range": 10.0},
        "pressure": {"unit": "hPa", "base": 1013.0, "range": 2.0},
    }

    print("Sending live sensor data. Press Ctrl+C to stop.")
    try:
        while True:
            for s_type, config in sensors.items():
                val = config["base"] + (random.random() * config["range"])
                status = "normal"
                if val > config["base"] + (config["range"] * 0.8):
                    status = "warning"
                
                payload = {
                    "value": round(val, 1),
                    "unit": config["unit"],
                    "status": status
                }
                
                topic = f"{TOPIC_PREFIX}/{s_type}"
                client.publish(topic, json.dumps(payload))
                print(f"Published to {topic}: {payload}")
            
            # Motion is binary
            motion_payload = {
                "value": 1 if random.random() > 0.8 else 0,
                "unit": "None",
                "status": "normal"
            }
            client.publish(f"{TOPIC_PREFIX}/motion", json.dumps(motion_payload))
            
            time.sleep(3)
    except KeyboardInterrupt:
        print("Stopping simulation...")
        client.disconnect()

if __name__ == "__main__":
    simulate_sensors()
