from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.database.models import User
from app.security import get_current_user
from app.schemas.schemas import AssistantQuery, AssistantResponse
from app.services.assistant_service import answer_question

router = APIRouter(prefix="/assistant", tags=["AI Assistant"])


@router.post("/query", response_model=AssistantResponse)
def query_assistant(payload: AssistantQuery, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    result = answer_question(db, payload.question)
    return AssistantResponse(**result)
