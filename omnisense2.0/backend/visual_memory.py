import json
import os
import urllib.request
from datetime import datetime
import database

def extract_and_save_visual_memories(image_base64: str, mime_type: str, gemini_model: str, api_key: str):
    """
    Analyzes captured camera frame for personal objects and automatically logs their locations into SQLite DB.
    """
    if not api_key:
        return

    prompt_text = (
        "Identify any key personal objects visible in this image (such as watch, keys, glasses, wallet, phone, bag, medicine, laptop, cup, umbrella). "
        "For each item, describe its specific location in 1 short sentence. "
        "Return strictly valid JSON format like: [{\"item\": \"watch\", \"location\": \"on the study table next to the laptop\"}]"
    )

    request_body = {
        "contents": [
            {
                "parts": [
                    {
                        "inline_data": {
                            "mime_type": mime_type,
                            "data": image_base64,
                        }
                    },
                    {
                        "text": prompt_text
                    },
                ]
            }
        ]
    }

    endpoint = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"{gemini_model}:generateContent"
    )

    try:
        request = urllib.request.Request(
            endpoint,
            data=json.dumps(request_body).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "x-goog-api-key": api_key,
            },
            method="POST",
        )
        with urllib.request.urlopen(request, timeout=15) as response:
            result = json.loads(response.read().decode("utf-8"))
            
        raw_text = result["candidates"][0]["content"]["parts"][0]["text"].strip()
        
        # Clean JSON block if markdown ticks exist
        if "```json" in raw_text:
            raw_text = raw_text.split("```json")[1].split("```")[0].strip()
        elif "```" in raw_text:
            raw_text = raw_text.split("```")[1].split("```")[0].strip()

        items = json.loads(raw_text)
        now_str = datetime.now().strftime("%I:%M %p")
        
        if isinstance(items, list):
            for entry in items:
                item_name = str(entry.get("item", "")).strip().lower()
                location = str(entry.get("location", "")).strip()
                if item_name and location:
                    content = f"{item_name.capitalize()} was seen {location} at {now_str}."
                    database.store_memory(
                        key_concept=item_name,
                        content=content,
                        category="visual_observation"
                    )
                    print(f"Logged Visual Memory: {item_name} -> {content}")

    except Exception as e:
        print(f"Visual memory observation log skipped: {e}")
