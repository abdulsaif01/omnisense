import database

DEFAULT_MEMORIES = [
    # Indoor & Home Item Placement
    {"key_concept": "keys", "content": "Keys are placed on the kitchen counter near the fruit bowl.", "category": "indoor"},
    {"key_concept": "glasses", "content": "Reading glasses are on the nightstand next to the bedside lamp.", "category": "indoor"},
    {"key_concept": "medicine", "content": "Daily medications are in the top drawer of the bathroom cabinet.", "category": "health"},
    {"key_concept": "charger", "content": "Phone charger is plugged into the wall outlet next to the sofa.", "category": "indoor"},
    {"key_concept": "wallet", "content": "Wallet is inside the front pocket of the black jacket.", "category": "indoor"},
    
    # Outdoor & Navigation Landmarks
    {"key_concept": "home address", "content": "Home address is 123 Main Street. The front gate is painted green.", "category": "outdoor"},
    {"key_concept": "umbrella", "content": "Umbrella is hanging on the coat rack next to the front exit door.", "category": "outdoor"},
    {"key_concept": "parking location", "content": "Car/Vehicle is parked near the main entrance gate on the left side.", "category": "outdoor"},
    {"key_concept": "bus stop", "content": "Nearest bus stop is 50 meters to the right after stepping outside the main gate.", "category": "outdoor"},
    {"key_concept": "emergency contact", "content": "Emergency contact person is reachable at 555-0199.", "category": "health"}
]

def seed_memories():
    database.init_db()
    for mem in DEFAULT_MEMORIES:
        database.store_memory(
            key_concept=mem["key_concept"],
            content=mem["content"],
            category=mem["category"]
        )
    print(f"Successfully seeded {len(DEFAULT_MEMORIES)} indoor & outdoor memories into OmniSense DB.")

if __name__ == "__main__":
    seed_memories()
