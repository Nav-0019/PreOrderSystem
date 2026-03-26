from fastapi import Depends, HTTPException
from jose import jwt
from app.core.security import SECRET_KEY, ALGORITHM

def role_required(required_role: str):
    def wrapper(token: str):
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            if payload.get("role") != required_role:
                raise HTTPException(status_code=403, detail="Access denied")
        except:
            raise HTTPException(status_code=401, detail="Invalid token")
    return wrapper