from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.database.models import User, ActivityLog
from app.schemas.schemas import LoginRequest, LoginResponse, UserOut
from app.security import verify_password, create_access_token, get_current_user

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/login", response_model=LoginResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email.lower().strip()).first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if user.status != "Active":
        raise HTTPException(status_code=403, detail="This account is inactive")

    user.last_login = datetime.utcnow()
    db.add(ActivityLog(
        company_id=user.company_id, user_id=user.id, branch_id=user.branch_id,
        action="logged in", entity_type="session", entity_id=user.id,
        description=f"{user.name} logged in",
    ))
    db.commit()

    token = create_access_token({"sub": str(user.id), "role": user.role})
    return LoginResponse(access_token=token, user=UserOut.model_validate(user))


@router.get("/me", response_model=UserOut)
def me(current_user: User = Depends(get_current_user)):
    return UserOut.model_validate(current_user)
