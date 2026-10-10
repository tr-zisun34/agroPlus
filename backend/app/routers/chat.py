import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_farmer
from app.db.session import get_db
from app.models.chat_message import ChatMessage
from app.models.farm import Farm
from app.models.farmer import Farmer
from app.schemas.chat import ChatMessageOut, ChatResponse, ChatSendRequest
from app.services.chat_agent_service import run_chat_agent

router = APIRouter(prefix="/farms", tags=["chat"])


def _get_owned_farm(farm_id: uuid.UUID, farmer: Farmer, db: Session) -> Farm:
    farm = db.query(Farm).filter(Farm.id == farm_id, Farm.farmer_id == farmer.id).first()
    if farm is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Farm not found")
    return farm


def _get_history(farm_id: uuid.UUID, db: Session) -> list[ChatMessage]:
    return db.query(ChatMessage).filter(ChatMessage.farm_id == farm_id).order_by(ChatMessage.created_at).all()


@router.get("/{farm_id}/chat/messages", response_model=list[ChatMessageOut])
def list_chat_messages(
    farm_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_farmer: Farmer = Depends(get_current_farmer),
):
    _get_owned_farm(farm_id, current_farmer, db)
    return _get_history(farm_id, db)


@router.delete("/{farm_id}/chat/messages", status_code=status.HTTP_204_NO_CONTENT)
def clear_chat_messages(
    farm_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_farmer: Farmer = Depends(get_current_farmer),
):
    """Each farm keeps exactly one ongoing chat thread — this replaces it with a blank one."""
    _get_owned_farm(farm_id, current_farmer, db)
    db.query(ChatMessage).filter(ChatMessage.farm_id == farm_id).delete()
    db.commit()


@router.post("/{farm_id}/chat", response_model=ChatResponse)
async def chat(
    farm_id: uuid.UUID,
    payload: ChatSendRequest,
    db: Session = Depends(get_db),
    current_farmer: Farmer = Depends(get_current_farmer),
):
    farm = _get_owned_farm(farm_id, current_farmer, db)

    history = [{"role": m.role, "content": m.content} for m in _get_history(farm_id, db)]
    history.append({"role": "user", "content": payload.message})

    reply = await run_chat_agent(farm, history, db)

    db.add(ChatMessage(farm_id=farm.id, role="user", content=payload.message))
    db.add(ChatMessage(farm_id=farm.id, role="assistant", content=reply))
    db.commit()

    return ChatResponse(reply=reply)
