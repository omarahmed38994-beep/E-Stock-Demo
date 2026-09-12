"""
Security utilities: password hashing and JWT issuing/verification.
"""
from datetime import datetime, timedelta
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from passlib.hash import bcrypt
from sqlalchemy.orm import Session

from app.config import settings
from app.database.connection import get_db
from app.database.models import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")


def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.verify(plain, hashed)


def hash_password(plain: str) -> str:
    return bcrypt.hash(plain)


def create_access_token(data: dict, expires_minutes: Optional[int] = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(
        minutes=expires_minutes or settings.jwt_expire_minutes
    )
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired session token",
            headers={"WWW-Authenticate": "Bearer"},
        )


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    payload = decode_token(token)
    user_id = payload.get("sub")
    if user_id is None:
        raise HTTPException(status_code=401, detail="Invalid session token")
    user = db.query(User).filter(User.id == int(user_id)).first()
    if user is None or user.status != "Active":
        raise HTTPException(status_code=401, detail="User not found or inactive")
    return user


def require_roles(*roles: str):
    """Dependency factory for role-based access control on endpoints."""
    def checker(user: User = Depends(get_current_user)) -> User:
        if user.role not in roles and user.role != "Owner":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Role '{user.role}' is not permitted to access this resource",
            )
        return user
    return checker


def scoped_branch_ids(user: User, db: Session) -> Optional[list]:
    """
    Returns the list of branch_ids a user is allowed to see, or None meaning
    'all branches' (Owner, General Manager, Accountant, Auditor, Inventory
    Manager all see the whole company; Branch Manager is scoped to their
    own branch).
    """
    if user.role == "Branch Manager" and user.branch_id:
        return [user.branch_id]
    return None
