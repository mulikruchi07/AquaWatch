import os
import time
import random
from supabase import create_client, Client

# --- Supabase Configuration ---
# Replace with your actual Supabase URL and anon key
# You can find these in your Supabase Project Settings -> API
SUPABASE_URL = "https://himkdnnczzfzmwmjxlaa.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpbWtkbm5jenpmem13bWp4bGFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyNTg0NjcsImV4cCI6MjA2NjgzNDQ2N30.Rib26sSBExk_22UxcZrssaT0tWNk1mN0ghJtvK4svWw"

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# --- Configuration for Data Simulation ---
# The ESP ID should match what your Flutter app is listening for.
# In your Flutter code, it defaults to '017' for testing if no user is logged in.
ESP_ID_TO_SIMULATE = "413"
SEND_INTERVAL_SECONDS = 1 # Send data every 5 seconds

def generate_random_data():
    """Generates random TDS and water level values."""
    # Simulate TDS value between 0 and 500 ppm
    tds = round(random.uniform(50, 400), 2)
    # Simulate water level between 0.0 and 1.0 (0% to 100%)
    water_level = round(random.uniform(0.05, 0.95), 2)
    return tds, water_level

def send_data_to_supabase(tds_value: float, water_level: float, esp_id: str):
    """Sends the generated data to the 'esp_data' table in Supabase."""
    try:
        data = {
            "esp_id": esp_id,
            "tds_value": tds_value,
            "water_level": water_level,
            # Supabase will automatically add 'created_at' if it's a timestamp column
        }
        response = supabase.table("esp_data").insert(data).execute()

        # Check for errors in the response
        if response.data:
            print(f"✅ Data sent successfully for ESP ID '{esp_id}': {data}")
        else:
            print(f"❌ Failed to send data: {response.error}")

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    print("Starting Supabase data simulation...")
    print(f"Data will be sent for ESP ID: {ESP_ID_TO_SIMULATE}")
    print(f"Sending data every {SEND_INTERVAL_SECONDS} seconds. Press Ctrl+C to stop.")

    while True:
        tds, water_level = generate_random_data()
        send_data_to_supabase(tds, water_level, ESP_ID_TO_SIMULATE)
        time.sleep(SEND_INTERVAL_SECONDS)
