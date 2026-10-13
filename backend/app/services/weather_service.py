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


async def fetch_forecast(lat: float, lng: float, days: int = 7) -> list[dict]:
    """Fetch a multi-day forecast (daily high/low temperature and total precipitation) for a
    coordinate via Open-Meteo. Separate from fetch_current_conditions since it reads the
    response's 'daily' block instead of 'current'."""
    params = {
        "latitude": lat,
        "longitude": lng,
        "daily": "temperature_2m_max,temperature_2m_min,precipitation_sum",
        "forecast_days": days,
        "timezone": "auto",
    }

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(OPEN_METEO_FORECAST_URL, params=params)
            response.raise_for_status()
    except httpx.HTTPError as exc:
        raise WeatherServiceError(f"Open-Meteo request failed: {exc}") from exc

    daily = response.json().get("daily")
    if daily is None:
        raise WeatherServiceError("Open-Meteo response missing 'daily' data")

    return [
        {
            "date": date,
            "temp_max_c": temp_max,
            "temp_min_c": temp_min,
            "precipitation_mm": precipitation,
        }
        for date, temp_max, temp_min, precipitation in zip(
            daily["time"],
            daily["temperature_2m_max"],
            daily["temperature_2m_min"],
            daily["precipitation_sum"],
        )
    ]
