from datetime import datetime, timezone

import httpx

OPEN_METEO_FORECAST_URL = "https://api.open-meteo.com/v1/forecast"


class WeatherServiceError(Exception):
    pass


async def fetch_current_conditions(lat: float, lng: float) -> dict:
    """Fetch current temperature, humidity, and rainfall for a coordinate via Open-Meteo."""
    params = {
        "latitude": lat,
        "longitude": lng,
        "current": "temperature_2m,relative_humidity_2m,precipitation",
        "timezone": "auto",
    }

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(OPEN_METEO_FORECAST_URL, params=params)
            response.raise_for_status()
    except httpx.HTTPError as exc:
        raise WeatherServiceError(f"Open-Meteo request failed: {exc}") from exc

    current = response.json().get("current")
    if current is None:
        raise WeatherServiceError("Open-Meteo response missing 'current' data")

    return {
        "temperature": current["temperature_2m"],
        "humidity": current["relative_humidity_2m"],
        "rainfall": current["precipitation"],
        "fetched_at": datetime.now(timezone.utc),
    }
