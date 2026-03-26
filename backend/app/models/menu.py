from sqlalchemy import Column, Integer, String, Float
from app.database import Base

class Menu(Base):
    __tablename__ = "menu"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    price = Column(Float, nullable=False)
    available = Column(Integer, default=0)