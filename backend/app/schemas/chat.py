from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict


class ChatSendRequest(BaseModel):
    message: str


class ChatMessageOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    role: Literal["user", "assistant"]
    content: str
    created_at: datetime


class ChatResponse(BaseModel):
    reply: str
