# app/main.py
from fastapi import FastAPI
from app.database import engine, Base
from app.routers import auth

# Import all models so SQLAlchemy knows about them
from app.models import user, menu, timeslot, order, payment

# Create tables if they don't exist
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="College Pre-Order App",
    description="API for students, bakers and admin to manage pre-ordering food.",
    version="1.0.0"
)

# Include routers
app.include_router(auth.router)