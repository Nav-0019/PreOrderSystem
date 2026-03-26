from sqlalchemy import Column, Integer, ForeignKey, String, DateTime
from app.database import Base
from sqlalchemy.orm import relationship
import datetime

class Order(Base):
    __tablename__ = "orders"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False)
    menu_id = Column(Integer, nullable=False)
    quantity = Column(Integer, default=1)
    status = Column(String, default="pending")  # pending, ready, picked
    created_at = Column(DateTime, default=datetime.datetime.utcnow)