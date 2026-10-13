"""Farm assistant chat agent — wraps the recommendation_service tools (anticipated by that
module's docstring) in an OpenAI function-calling loop, grounded in one farm's own saved data
(soil reading, current recommendation, crop economics) rather than general crop knowledge.
"""

import asyncio
import json

from openai import OpenAI
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.farm import Farm
from app.models.recommendation import Recommendation
from app.services.recommendation_service import (
    crops_at_rotation_limit,
    get_all_crop_scores,
    get_crop_detail,
    get_profit_estimate,
    get_recommendation_explanation,
    get_soil_reading,
)
from app.services.weather_service import WeatherServiceError, fetch_current_conditions, fetch_forecast

MODEL = "gpt-4o-mini"
MAX_TOOL_ROUNDS = 5

_client: OpenAI | None = None


def _get_client() -> OpenAI:
    global _client
    if _client is None:
        _client = OpenAI(api_key=settings.OPENAI_API_KEY)
    return _client


TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "get_soil_reading",
            "description": "Get this farm's most recent composite soil reading (N, P, K, pH), "
            "averaged across its saved sample points. Returns a 'no reading yet' note if the "
            "farmer hasn't completed a soil sample.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_live_weather",
            "description": "Get current temperature, humidity, and rainfall for this farm's district.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_current_recommendation",
            "description": "Get the top-3 crops currently recommended for this farm (the same "
            "list shown on the farm's dashboard), each with its confidence, yield estimate, and "
            "net profit estimate. Returns a 'no recommendation yet' note if the farmer hasn't "
            "completed a soil sample.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_crop_detail",
            "description": "Get the full harvest economics breakdown for one specific crop on "
            "this farm: growing season, expected yield, market price, seed cost, itemized "
            "fertilizer cost, other costs, total cost, gross revenue, and net profit.",
            "parameters": {
                "type": "object",
                "properties": {
                    "crop": {
                        "type": "string",
                        "description": "Crop name, e.g. 'rice', 'mungbean', 'mango'.",
                    }
                },
                "required": ["crop"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_other_crop_options",
            "description": "Get every crop the recommendation model supports for this farm's "
            "soil and weather — not just the saved top-3 — each with its model confidence, "
            "yield estimate, and net profit. Use this when the farmer asks for alternatives or "
            "crops beyond the top-3 recommendation. Requires a saved soil reading and working "
            "weather data; returns a note if either is unavailable.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_recommendation_explanation",
            "description": "Get why a crop scored the way it did for this farm: its actual "
            "soil/weather values compared against the typical range for that crop (from the "
            "model's training data), plus which inputs the model weighs most heavily overall. "
            "Use this when the farmer asks 'why rice?' or 'why does X suit my land?'. Requires "
            "a saved soil reading and working weather data; returns a note if either is "
            "unavailable.",
            "parameters": {
                "type": "object",
                "properties": {
                    "crop": {
                        "type": "string",
                        "description": "Crop name to explain, e.g. 'rice', 'mungbean'.",
                    }
                },
                "required": ["crop"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_weather_forecast",
            "description": "Get the next 7 days' forecast (daily high/low temperature and "
            "total precipitation) for this farm's district. Use this for questions about "
            "upcoming weather, rain, or planting/harvest timing this week — get_live_weather "
            "only covers right now, not what's coming.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
]


def _build_system_prompt(farm: Farm) -> str:
    previous_crops = ", ".join(c for c in (farm.previous_crop_1, farm.previous_crop_2) if c) or "none recorded"
    return (
        "You are AgroPlus's farm assistant, helping a Bangladeshi farmer understand their farm's "
        "soil, weather, and crop recommendations. You are chatting about one specific farm:\n"
        f"- Farm name: {farm.farm_name}\n"
        f"- District: {farm.district.name}\n"
        f"- Size: {farm.size_acres} acres\n"
        f"- Soil type: {farm.soil_type}\n"
        f"- Water availability: {farm.water_availability}\n"
        f"- Target season: {farm.target_season}\n"
        f"- Budget: {farm.budget} BDT\n"
        f"- Cropping pattern: {farm.cropping_pattern}\n"
        f"- Last two crops harvested here (most recent first): {previous_crops}\n\n"
        "Use the provided tools to fetch this farm's actual soil reading, weather, "
        "recommendation, and crop economics data rather than guessing. Only state numbers that "
        "came from a tool call. Never assume a prerequisite (like 'you need to add a soil "
        "sample first') without checking — call the relevant tool and let its 'unavailable' "
        "status tell you that, rather than guessing it. If the farmer asks for crop suggestions "
        "beyond the saved top-3, or for alternatives, or 'what else could I grow', always call "
        "get_other_crop_options before replying — do not assume more data is needed. A crop is "
        "never recommended a third time in a row on the same land — if the farmer asks why a "
        "familiar crop is missing, that rotation rule (shown above) is usually why. If "
        "cropping_pattern is 'double' or 'triple', get_current_recommendation returns a "
        "season-sequenced plan (one crop per season) rather than ranked alternatives — present "
        "it that way, by season, not as a ranked top-3. Keep answers short and practical. Reply "
        "in the same language the farmer is writing in."
    )


def _run_get_soil_reading(farm: Farm, db: Session) -> dict:
    reading = get_soil_reading(farm.id, db)
    if reading is None:
        return {"status": "unavailable", "note": "No soil reading saved yet for this farm."}
    return {"status": "ok", "reading": reading}


async def _run_get_live_weather(farm: Farm) -> dict:
    if farm.district.center_lat is None or farm.district.center_lng is None:
        return {"status": "unavailable", "note": "No coordinates on file for this district."}
    try:
        conditions = await fetch_current_conditions(farm.district.center_lat, farm.district.center_lng)
    except WeatherServiceError:
        return {"status": "unavailable", "note": "Weather service request failed."}
    return {
        "status": "ok",
        "temperature_c": conditions["temperature"],
        "humidity_percent": conditions["humidity"],
        "rainfall_mm": conditions["rainfall"],
    }


def _run_get_current_recommendation(farm: Farm, db: Session) -> dict:
    recommendation = (
        db.query(Recommendation)
        .filter(Recommendation.farm_id == farm.id)
        .order_by(Recommendation.created_at.desc())
        .first()
    )
    if recommendation is None or recommendation.status != "complete" or not recommendation.top_crops:
        return {"status": "unavailable", "note": "No completed recommendation yet for this farm."}
    return {
        "status": "ok",
        "top_crops": [
            {
                "rank": c.rank,
                "crop": c.crop,
                "confidence": c.confidence,
                "yield_estimate_kg": c.yield_estimate,
                "net_profit_bdt": c.net_profit,
                "season": c.season,
                "rotation_note": c.rotation_note,
            }
            for c in recommendation.top_crops
        ],
    }


def _run_get_crop_detail(farm: Farm, crop: str, db: Session) -> dict:
    detail = get_crop_detail(crop=crop, size_acres=farm.size_acres, db=db)
    if detail is None:
        return {"status": "unavailable", "note": f"No economics data available for '{crop}'."}
    return {"status": "ok", "detail": detail}


async def _run_get_other_crop_options(farm: Farm, db: Session) -> dict:
    reading = get_soil_reading(farm.id, db)
    if reading is None:
        return {"status": "unavailable", "note": "No soil reading saved yet for this farm."}
    if farm.district.center_lat is None or farm.district.center_lng is None:
        return {"status": "unavailable", "note": "No coordinates on file for this district."}
    try:
        conditions = await fetch_current_conditions(farm.district.center_lat, farm.district.center_lng)
    except WeatherServiceError:
        return {"status": "unavailable", "note": "Weather service request failed."}

    scores = get_all_crop_scores(
        n=reading["n"],
        p=reading["p"],
        k=reading["k"],
        temperature=conditions["temperature"],
        humidity=conditions["humidity"],
        ph=reading["ph"],
        rainfall=conditions["rainfall"],
        exclude_crops=crops_at_rotation_limit([farm.previous_crop_1, farm.previous_crop_2]),
    )
    options = []
    for item in scores:
        profit = get_profit_estimate(crop=item["crop"], size_acres=farm.size_acres, db=db)
        options.append(
            {
                "crop": item["crop"],
                "confidence": item["confidence"],
                "yield_estimate_kg": profit["yield_estimate"] if profit else None,
                "net_profit_bdt": profit["net_profit"] if profit else None,
            }
        )
    return {"status": "ok", "crops_ranked_by_confidence": options}


async def _run_get_recommendation_explanation(farm: Farm, crop: str, db: Session) -> dict:
    reading = get_soil_reading(farm.id, db)
    if reading is None:
        return {"status": "unavailable", "note": "No soil reading saved yet for this farm."}
    if farm.district.center_lat is None or farm.district.center_lng is None:
        return {"status": "unavailable", "note": "No coordinates on file for this district."}
    try:
        conditions = await fetch_current_conditions(farm.district.center_lat, farm.district.center_lng)
    except WeatherServiceError:
        return {"status": "unavailable", "note": "Weather service request failed."}

    explanation = get_recommendation_explanation(
        crop=crop,
        n=reading["n"],
        p=reading["p"],
        k=reading["k"],
        temperature=conditions["temperature"],
        humidity=conditions["humidity"],
        ph=reading["ph"],
        rainfall=conditions["rainfall"],
    )
    if explanation is None:
        return {"status": "unavailable", "note": f"'{crop}' isn't a crop the model recognizes."}
    return {"status": "ok", "explanation": explanation}


async def _run_get_weather_forecast(farm: Farm) -> dict:
    if farm.district.center_lat is None or farm.district.center_lng is None:
        return {"status": "unavailable", "note": "No coordinates on file for this district."}
    try:
        forecast = await fetch_forecast(farm.district.center_lat, farm.district.center_lng)
    except WeatherServiceError:
        return {"status": "unavailable", "note": "Weather service request failed."}
    return {"status": "ok", "forecast": forecast}


async def _dispatch_tool_call(name: str, arguments: dict, farm: Farm, db: Session) -> dict:
    if name == "get_soil_reading":
        return _run_get_soil_reading(farm, db)
    if name == "get_live_weather":
        return await _run_get_live_weather(farm)
    if name == "get_current_recommendation":
        return _run_get_current_recommendation(farm, db)
    if name == "get_crop_detail":
        return _run_get_crop_detail(farm, arguments.get("crop", ""), db)
    if name == "get_other_crop_options":
        return await _run_get_other_crop_options(farm, db)
    if name == "get_weather_forecast":
        return await _run_get_weather_forecast(farm)
    if name == "get_recommendation_explanation":
        return await _run_get_recommendation_explanation(farm, arguments.get("crop", ""), db)
    return {"status": "error", "note": f"Unknown tool '{name}'."}


async def run_chat_agent(farm: Farm, history: list[dict], db: Session) -> str:
    """history: list of {"role": "user"|"assistant", "content": str}, oldest first."""
    messages: list[dict] = [{"role": "system", "content": _build_system_prompt(farm)}]
    messages.extend(history)

    client = _get_client()

    for _ in range(MAX_TOOL_ROUNDS):
        response = await asyncio.to_thread(
            client.chat.completions.create,
            model=MODEL,
            messages=messages,
            tools=TOOLS,
            temperature=0,
        )
        message = response.choices[0].message

        if not message.tool_calls:
            return message.content or ""

        messages.append(
            {
                "role": "assistant",
                "content": message.content,
                "tool_calls": [
                    {
                        "id": tc.id,
                        "type": "function",
                        "function": {"name": tc.function.name, "arguments": tc.function.arguments},
                    }
                    for tc in message.tool_calls
                ],
            }
        )

        for tool_call in message.tool_calls:
            try:
                arguments = json.loads(tool_call.function.arguments or "{}")
            except json.JSONDecodeError:
                arguments = {}
            result = await _dispatch_tool_call(tool_call.function.name, arguments, farm, db)
            messages.append(
                {
                    "role": "tool",
                    "tool_call_id": tool_call.id,
                    "content": json.dumps(result, default=str),
                }
            )

    return "Sorry, I'm having trouble pulling that information together right now. Please try again."
